// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./NFTBankStorageStructure.sol";

contract NFTBankImpl is NFTBankStorageStructure, INFTBank {
    using BasisPoints for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    function setPreparationMode() external onlyRole(ADMIN_ROLE) {
        mode = Mode.Preparation;
        emit PreparationModeIsOn();
    }

    function setPrivateMode() public onlyRole(ADMIN_ROLE) {
        if (!nftDataImported) revert ShouldImportNFTDataFirst();
        if (
            (mode == Mode.Whitelist) &&
            (whitelistMintStartDate + mintExpirationTime > block.timestamp) &&
            (winners.length != 0)
        ) revert CanNotChangeModeBeforeWhitelistMintExpirationDate();
        mode = Mode.Private;
        emit PrivateModeIsOn();
    }

    function setWhitelistMode() internal onlyRole(ADMIN_ROLE) {
        if (mode == Mode.Whitelist) revert AlreadyInWhitelistMode();
        whitelistMintStartDate = block.timestamp;
        mode = Mode.Whitelist;
        emit WhitelistModeIsOn();
    }

    function setPublicMode() public onlyRole(ADMIN_ROLE) {
        if (
            mode == Mode.Whitelist &&
            whitelistMintStartDate + mintExpirationTime > block.timestamp
        ) revert CanNotChangeModeBeforeWhitelistMintExpirationDate();

        publicMintStartDate = block.timestamp + publicMintStartTimeGap;
        publicMintTotalCount = getNumberOfTotalRemainingNFTs().mulBP(
            publicMintPercentage
        );
        publicModeMaxMintCount =
            _tokenIdIndexes.current() +
            publicMintTotalCount;
        mode = Mode.Public;
        emit PublicModeIsOn();
    }

    function extendPublicMintDuration(uint256 newDuration)
        external
        onlyRole(ADMIN_ROLE)
    {
        uint256 oldDuration = publicMintExpirationTime;
        publicMintExpirationTime = newDuration;
        emit NewPublicMintExpirationTimeWasSet(oldDuration, newDuration);
    }

    function getMode() public view returns (Mode) {
        return mode;
    }

    function getNFTType() public view returns (NFTType) {
        return nftType;
    }

    function importNFTData(
        // addresses[0] = nftCollection
        // addresses[1] = creatorFeeWallet
        address[2] calldata addresses,
        // nftType
        // price
        // publicMintPrice
        // maxMintCount
        // mintExpirationTime
        // publicMintExpirationTime
        // publicMintStartTimeGap
        // publicMintPercentage
        uint256[8] calldata variables,
        uint256[] calldata _nftIds,
        string memory _symbol,
        bytes32 _baseURIHash
    ) external onlyRole(ADMIN_ROLE) {
        if (mode != Mode.Preparation) revert NotInPreparationMode();
        if (nftBankLaunchDate + nftImportExpirationTime > block.timestamp)
            revert CanNotImportDataBeforeNFTImportExpirationTime();

        if (variables[0] == ERC721Token) {
            nftType = NFTType.ERC721;
            symbol = _symbol;
            if (
                IERC721Upgradeable(addresses[0]).supportsInterface(
                    type(IERC721Upgradeable).interfaceId
                )
            ) nftCollection = addresses[0];
            else revert DoesNotSupportIERC721();
        } else if (variables[0] == ERC1155Token) {
            nftType = NFTType.ERC1155;
            if (
                IERC1155Upgradeable(addresses[0]).supportsInterface(
                    type(IERC1155Upgradeable).interfaceId
                )
            ) nftCollection = addresses[0];
            else revert DoesNotSupportIERC1155();
        } else revert NotAValidTokenType();

        creatorFeeWallet = payable(addresses[1]);
        _setupRole(COLLECTION_CREATOR_ROLE, addresses[1]);
        _setupRole(COLLECTION_CREATOR_ROLE, _msgSender());
        _setRoleAdmin(COLLECTION_CREATOR_ROLE, ADMIN_ROLE);

        mintPrice = variables[1];
        publicMintPrice = variables[2];

        if (_nftIds.length < variables[3]) revert NotEnoughNFTsToBeClaimed();
        else maxMintCount = variables[3];

        if (nftIds.length != 0) delete nftIds;

        /// @note may get out of gas
        for (uint256 i; i < _nftIds.length; i++) {
            nftIds.push(_nftIds[i]);
        }

        mintExpirationTime = variables[4];
        publicMintExpirationTime = variables[5];
        publicMintStartTimeGap = variables[6];
        publicMintPercentage = variables[7];

        baseURIHash = _baseURIHash;

        nftDataImported = true;
        emit NFTDataImported(
            addresses,
            variables,
            _nftIds,
            symbol,
            baseURIHash
        );
    }

    function setWhitelistedUsers(
        UserAllocation[] calldata allocations,
        // these should be fixed in every call for each slot
        // numberOfNFTs[0] _numberOfFreeNFTs,
        // numberOfNFTs[1] _numberOfGuaranteedNFTs,
        // numberOfNFTs[2] _numberOfRaceNFTs,
        uint256[3] calldata numberOfNFTs,
        address[] calldata deletedWinners,
        bool lastSlot,
        bool deletePreviousWinners
    ) external onlyRole(ADMIN_ROLE) {
        if (deletePreviousWinners) {
            delete winners;
            totalFreeAllocated = 0;
            totalGuaranteedAllocated = 0;
            setPrivateMode();
        }
        if (mode != Mode.Private) revert NotInPrivateMode();

        if (
            numberOfNFTs[0] + numberOfNFTs[1] + numberOfNFTs[2] >
            getNumberOfTotalRemainingNFTs()
        ) revert TotalAllocationsExceedsMaxMintCount();

        if (deletedWinners.length != 0) _deleteWinners(deletedWinners);

        for (uint256 i = 0; i < allocations.length; i++) {
            delete whitelistedUsers[allocations[i].user].spots;
            delete whitelistedUsers[allocations[i].user].mintedSpots;

            uint256 freeSpots;
            uint256 guaranteedSpots;
            uint256 raceSpots;
            for (uint256 j = 0; j < allocations[i].spots.length; j++) {
                if (allocations[i].spots[j] > guaranteedWithNoDiscountSpot)
                    revert SpotIsIncorrect({
                        user: allocations[i].user,
                        spot: allocations[i].spots[j]
                    });
                else if (allocations[i].spots[j] == raceSpot) {
                    raceSpots++;
                } else if (allocations[i].spots[j] == freeSpot) {
                    totalFreeAllocated++;
                    freeSpots++;
                } else {
                    totalGuaranteedAllocated++;
                    guaranteedSpots++;
                }

                whitelistedUsers[allocations[i].user].spots.push(
                    allocations[i].spots[j]
                );
                whitelistedUsers[allocations[i].user].mintedSpots.push(false);
            }

            uint256 totalNumberOfSpots = freeSpots +
                guaranteedSpots +
                raceSpots;

            if (totalNumberOfSpots > mintCap)
                revert CanNotAllocateMoreThanClaimCap();

            if (allocations[i].freeSpots == freeSpots)
                whitelistedUsers[allocations[i].user].freeSpots = freeSpots;
            else
                revert NumberOfFreeSpotsForUserIsWrong({
                    requested: allocations[i].freeSpots,
                    actual: freeSpots
                });

            if (allocations[i].guaranteedSpots == guaranteedSpots)
                whitelistedUsers[allocations[i].user]
                    .guaranteedSpots = guaranteedSpots;
            else
                revert NumberOfGuaranteedSpotsForUserIsWrong({
                    requested: allocations[i].guaranteedSpots,
                    actual: guaranteedSpots
                });
            if (allocations[i].raceSpots == raceSpots)
                whitelistedUsers[allocations[i].user].raceSpots = raceSpots;
            else
                revert NumberOfRaceSpotsForUserIsWrong({
                    requested: allocations[i].raceSpots,
                    actual: raceSpots
                });

            whitelistedUsers[allocations[i].user].position = allocations[i]
                .position;
            whitelistedUsers[allocations[i].user].bestPrediction = allocations[
                i
            ].bestPrediction;
            whitelistedUsers[allocations[i].user].isWhitelisted = true;
            winners.push(allocations[i].user);
        }

        if (totalFreeAllocated > numberOfNFTs[0])
            revert TotalFreeMintsExceedsFreeNFTs({
                requested: totalFreeAllocated,
                actual: numberOfNFTs[0]
            });
        if (totalGuaranteedAllocated > numberOfNFTs[1])
            revert TotalGuaranteedMintsExceedsGuaranteedNFTs({
                requested: totalGuaranteedAllocated,
                actual: numberOfNFTs[1]
            });

        numberOfFreeNFTs = numberOfNFTs[0];
        numberOfGuaranteedNFTs = numberOfNFTs[1];
        numberOfRaceNFTs = numberOfNFTs[2];

        if (lastSlot) setWhitelistMode();

        emit WinnersAreSet(
            allocations,
            lastSlot,
            deletePreviousWinners,
            deletedWinners
        );
    }

    function _deleteWinners(address[] memory deletedWinners) internal {
        for (uint256 i = 0; i < deletedWinners.length; i++) {
            whitelistedUsers[deletedWinners[i]].isFreezed = true;
        }
    }

    function unfreezeUsers(address[] memory users)
        external
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i; i < users.length; i++)
            whitelistedUsers[users[i]].isFreezed = false;

        emit UsersUnfreezed(users);
    }

    function claim(
        bool[] memory _spots,
        uint256 privateModeClaimCount,
        uint256 publicModeClaimCount
    ) external payable nonReentrant {
        uint256 freeClaimCount;
        uint256 guaranteedClaimCount;
        uint256 raceClaimCount;
        for (uint256 i; i < _spots.length; i++) {
            if (_spots[i]) {
                if (whitelistedUsers[_msgSender()].mintedSpots[i]) {
                    revert SpotIsAlreadyMinted({index: i});
                }

                if (whitelistedUsers[_msgSender()].spots[i] == freeSpot) {
                    freeClaimCount++;
                } else if (
                    whitelistedUsers[_msgSender()].spots[i] ==
                    guaranteedWithNoDiscountSpot
                ) {
                    guaranteedClaimCount++;
                } else if (
                    whitelistedUsers[_msgSender()].spots[i] == raceSpot
                ) {
                    raceClaimCount++;
                }
            }
        }

        uint256 totalClaimFee;
        uint256 extraPaid;
        uint256 launchpadFee;
        uint256[] memory claimedIds;
        if (mode == Mode.Private) {
            if (getNumberOfTotalRemainingNFTs() < privateModeClaimCount)
                revert RequestedPrivateModeClaimCountExceedsTotal();

            totalClaimFee = privateModeClaimCount * mintPrice;

            (extraPaid, launchpadFee) = _tokenPurchase(totalClaimFee);

            claimedIds = _claimToken(_msgSender(), privateModeClaimCount);
        } else if (mode == Mode.Whitelist) {
            if (whitelistMintStartDate + mintExpirationTime < block.timestamp)
                revert ClaimingHasEnded();

            if (!isWhitelisted(_msgSender())) {
                revert NotWhitelisted();
            }
            Mintables memory user = whitelistedUsers[_msgSender()];

            if (user.isFreezed) revert UserIsFreezed();

            if (getNumberOfTotalRemainingRaceNFTs() < raceClaimCount)
                revert RequestedRaceClaimCountExceedsTotal();

            uint256 totalClaimCount = freeClaimCount +
                guaranteedClaimCount +
                raceClaimCount;
            if (getNumberOfTotalRemainingNFTs() < totalClaimCount)
                revert NotEnoughNFTsLeft();

            totalClaimFee = getTotalClaimPrice(
                guaranteedClaimCount,
                raceClaimCount
            );
            (extraPaid, launchpadFee) = _tokenPurchase(totalClaimFee);

            if (freeClaimCount != 0)
                whitelistedUsers[_msgSender()].freeSpotsMinted =
                    user.freeSpotsMinted +
                    freeClaimCount;
            if (guaranteedClaimCount != 0)
                whitelistedUsers[_msgSender()].guaranteedSpotsMinted =
                    user.guaranteedSpotsMinted +
                    guaranteedClaimCount;
            if (raceClaimCount != 0) {
                whitelistedUsers[_msgSender()].raceSpotsMinted =
                    user.raceSpotsMinted +
                    raceClaimCount;
                totalRaceMinted += raceClaimCount;
            }

            for (uint256 i = 0; i < _spots.length; i++) {
                if (_spots[i]) {
                    whitelistedUsers[_msgSender()].mintedSpots[i] = true;
                }
            }

            claimedIds = _claimToken(_msgSender(), totalClaimCount);
        } else if (mode == Mode.Public) {
            if (
                publicMintStartDate + publicMintExpirationTime < block.timestamp
            ) revert PublicMintingIsEnded();
            if (publicMintStartDate > block.timestamp)
                revert PublicMintingNotStartedYet();
            if (getNumberOfTotalRemainingPublicNFTs() < publicModeClaimCount)
                revert RequestedPublicModeClaimCountExceedsTotal();
            if (
                publicModeNFTsMintedCount[_msgSender()] + publicModeClaimCount >
                publicMintCap
            ) {
                revert CanNotMintMoreThanPublicMintCap();
            }

            totalClaimFee = publicModeClaimCount * publicMintPrice;

            (extraPaid, launchpadFee) = _tokenPurchase(totalClaimFee);

            claimedIds = _claimToken(_msgSender(), publicModeClaimCount);

            publicModeNFTsMintedCount[_msgSender()] =
                publicModeNFTsMintedCount[_msgSender()] +
                publicModeClaimCount;
        }

        emit UserClaimed(
            _msgSender(),
            mode,
            totalClaimFee,
            extraPaid,
            launchpadFee,
            _spots,
            privateModeClaimCount,
            publicModeClaimCount,
            claimedIds
        );
    }

    function adminClaim(address user, uint256 amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        _claimToken(user, amount);
    }

    function adminClaimSingle(
        address user,
        address collection,
        uint256 nftId
    ) external onlyRole(ADMIN_ROLE) {
        IERC721Upgradeable(collection).safeTransferFrom(
            address(this),
            user,
            nftId
        );
    }

    function _claimToken(address user, uint256 amount)
        internal
        returns (uint256[] memory)
    {
        uint256 newItemId;
        uint256[] memory claimedIds = new uint256[](amount);

        if (nftType == NFTType.ERC721) {
            for (uint256 i; i < amount; i++) {
                newItemId = nftIds[_tokenIdIndexes.current()];
                claimedIds[i] = newItemId;
                _tokenIdIndexes.increment();
                IERC721Upgradeable(nftCollection).safeTransferFrom(
                    address(this),
                    user,
                    newItemId
                );
            }
        } else if (nftType == NFTType.ERC1155) {
            uint256[] memory ids = new uint256[](amount);
            uint256[] memory amounts = new uint256[](amount);

            for (uint256 i; i < amount; i++) {
                newItemId = nftIds[_tokenIdIndexes.current()];
                claimedIds[i] = newItemId;
                _tokenIdIndexes.increment();
                ids[i] = newItemId;
                amounts[i] = 1;
            }

            IERC1155Upgradeable(nftCollection).safeBatchTransferFrom(
                address(this),
                user,
                ids,
                amounts,
                ""
            );
        }

        return claimedIds;
    }

    function _tokenPurchase(uint256 totalClaimFee)
        internal
        returns (uint256 extraPaid, uint256 launchpadFee)
    {
        if (totalClaimFee > msg.value)
            revert InvalidAmount({sent: msg.value, minRequired: totalClaimFee});

        extraPaid = msg.value > totalClaimFee ? msg.value - totalClaimFee : 0;

        launchpadFee = totalClaimFee.mulBP(launchpadFeePercentage);
        (bool success, ) = launchpadFeeWallet.call{value: launchpadFee}("");
        if (!success) revert TransferNotSuccessful();

        if (extraPaid != 0) {
            (success, ) = payable(_msgSender()).call{value: extraPaid}("");
            if (!success) revert TransferNotSuccessful();
        }

        (success, ) = creatorFeeWallet.call{
            value: totalClaimFee - launchpadFee
        }("");
        if (!success) revert TransferNotSuccessful();
    }

    function getTotalClaimPrice(
        uint256 guaranteedClaimCount,
        uint256 raceClaimCount
    ) public view returns (uint256 claimFee) {
        // ToDo: get discounts into account, not MVP
        return (guaranteedClaimCount + raceClaimCount) * mintPrice;
    }

    function setMintPrice(uint256 _mintPrice) external onlyRole(ADMIN_ROLE) {
        if (mode != Mode.Private) revert NotInPrivateMode();
        uint256 oldMintPrice = mintPrice;
        mintPrice = _mintPrice;
        emit ClaimPriceChanged(_mintPrice, oldMintPrice);
    }

    function setMintCap(uint256 _mintCap) external onlyRole(ADMIN_ROLE) {
        if (mode != Mode.Private) revert NotInPrivateMode();
        uint256 oldMintCap = mintCap;
        mintCap = _mintCap;
        emit ClaimCapChanged(_mintCap, oldMintCap);
    }

    /// @dev it may not provide any value when the uri has been set in the collection before
    function setBaseURI(string memory _BaseURI) external {
        if (whitelistMintStartDate + mintExpirationTime > block.timestamp)
            revert MintingNotEndedYet();

        bytes32 _baseURIHash = keccak256(bytes(_BaseURI));

        if (_baseURIHash != baseURIHash) revert WrongBaseURIProvided();
        else {
            baseURI = _BaseURI;
            emit baseURIIsSet(_BaseURI);
        }
    }

    function isWhitelisted(address user) public view returns (bool) {
        return whitelistedUsers[user].isWhitelisted;
    }

    function getPosition(address user) external view returns (uint256 rank) {
        rank = whitelistedUsers[user].position;
    }

    function getBestPrediction(address user)
        external
        view
        returns (uint256 bestPrediction)
    {
        bestPrediction = whitelistedUsers[user].bestPrediction;
    }

    function getTotalNumberOfFreeSpots(address user)
        public
        view
        returns (uint256)
    {
        return whitelistedUsers[user].freeSpots;
    }

    function getNumberOfRemainingFreeSpots(address user)
        public
        view
        returns (uint256)
    {
        return
            whitelistedUsers[user].freeSpots -
            whitelistedUsers[user].freeSpotsMinted;
    }

    function getTotalNumberOfGuaranteedSpots(address user)
        public
        view
        returns (uint256)
    {
        return whitelistedUsers[user].guaranteedSpots;
    }

    function getNumberOfRemainingGuaranteedSpots(address user)
        public
        view
        returns (uint256)
    {
        return
            whitelistedUsers[user].guaranteedSpots -
            whitelistedUsers[user].guaranteedSpotsMinted;
    }

    function getNumberOfRaceSpots(address user) public view returns (uint256) {
        return whitelistedUsers[user].raceSpots;
    }

    function getNumberOfRemainingRaceSpots(address user)
        public
        view
        returns (uint256)
    {
        return
            whitelistedUsers[user].raceSpots -
            whitelistedUsers[user].raceSpotsMinted;
    }

    function getNumberOfTotalRemainingNFTs() public view returns (uint256) {
        return maxMintCount - _tokenIdIndexes.current();
    }

    function getNumberOfTotalRemainingPublicNFTs()
        public
        view
        returns (uint256)
    {
        return publicModeMaxMintCount - _tokenIdIndexes.current();
    }

    function getNumberOfTotalRemainingRaceNFTs() public view returns (uint256) {
        return numberOfRaceNFTs - totalRaceMinted;
    }

    function getUserSpots(address user)
        external
        view
        returns (uint256[] memory)
    {
        return whitelistedUsers[user].spots;
    }

    function getTotalNFTsMinted(address user) public view returns (uint256) {
        return
            whitelistedUsers[user].freeSpotsMinted +
            whitelistedUsers[user].guaranteedSpotsMinted +
            whitelistedUsers[user].raceSpotsMinted +
            publicModeNFTsMintedCount[user];
    }

    function getUserMintedSpots(address user)
        external
        view
        returns (bool[] memory)
    {
        return whitelistedUsers[user].mintedSpots;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWinners() external view returns (address[] memory) {
        address[] memory addrs = new address[](winners.length);

        for (uint256 i = 0; i < winners.length; i++) {
            addrs[i] = winners[i];
        }

        return (addrs);
    }

    function withdrawBalance(address payable receiver)
        external
        onlyRole(ADMIN_ROLE)
    {
        uint256 amount = getBalance();
        (bool success, ) = receiver.call{value: amount}("");
        if (!success) revert TransferNotSuccessful();
        emit BalanceWithdrawn(_msgSender(), receiver, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../../libraries/BasisPoints.sol";

import "../../interfaces/INFTBank.sol";
import "../../interfaces/ISparkWorldToken.sol";

contract NFTBankStorageStructure is
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint256 public constant ERC721Token = 721;
    uint256 public constant ERC1155Token = 1155;
    uint256 public constant guaranteedWithNoDiscountSpot = 10001;
    uint256 public constant freeSpot = 10000;
    uint256 public constant raceSpot = 0; // Not MVP

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COLLECTION_CREATOR_ROLE =
        keccak256("COLLECTION_CREATOR_ROLE");

    uint256 public nftBankLaunchDate; // = block.timestamp
    uint256 public mintCap;
    uint256 public nftImportExpirationTime; // nftImportExpirationDate = nftBankLaunchDate + nftImportExpirationTime
    uint256 public launchpadFeePercentage; // in basis points
    uint256 public mintPrice;
    uint256 public mintExpirationTime; // claimExpirationTime
    uint256 public maxMintCount; // maxClaimCount
    uint256 public publicMintPrice;
    uint256 public publicMintExpirationTime;
    // the gap between the end of whitelist minting and the start of public minting
    uint256 public publicMintStartTimeGap;
    uint256 public publicMintCap;
    // the percentage of the remaining nfts from whitelist minting that is mintable in public mode minting
    uint256 public publicMintPercentage;

    uint256 public totalFreeAllocated;
    uint256 public totalGuaranteedAllocated;
    uint256 public totalRaceMinted;
    // mintExpirationTime is relative to this
    uint256 public whitelistMintStartDate;
    // will be set in setPublicMintMode function (block.timestamp + publicMintStartTime)
    uint256 public publicMintStartDate;
    // total number of NFTs available for public mint
    uint256 public publicMintTotalCount;
    // the maximum id we can reach in public mode (is less than or equal to maxMintCount)
    uint256 public publicModeMaxMintCount;

    // in setWhitelist
    uint256 public numberOfFreeNFTs; // 10 top stakes + 10 top predictions
    uint256 public numberOfGuaranteedNFTs; // king and queen spots
    uint256 public numberOfRaceNFTs; // fellow spots, not MVP

    // set in the factory constructor
    address public nftBankImpl;
    address payable public launchpadFeeWallet;

    address public nftCollection;
    address payable public creatorFeeWallet;

    bool public nftDataImported;

    bytes32 public baseURIHash;

    string public name; // to be filled with the project's name (and fetched later if ERC721)
    string public symbol; // fetched later (if ERC721)
    string public baseURI;

    INFTBank.NFTType public nftType;
    INFTBank.Mode public mode;
    CountersUpgradeable.Counter internal _tokenIdIndexes;

    mapping(address => INFTBank.Mintables) public whitelistedUsers;
    mapping(address => uint256) public publicModeNFTsMintedCount;
    address[] public winners;
    uint256[] public nftIds;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(INFTBank).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// added for the subgraph to extract external NFT data
    event ERC721Received(
        address indexed nftCollection,
        address previousOwner,
        uint256 tokenId
    );

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory
    ) public override returns (bytes4) {
        emit ERC721Received(_msgSender(), operator, tokenId);
        return this.onERC721Received.selector;
    }

    event ERC1155Received(
        address indexed nftCollection,
        address previousOwner,
        uint256 tokenId,
        uint256 amount
    );

    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256 amount,
        bytes memory
    ) public override returns (bytes4) {
        emit ERC1155Received(_msgSender(), operator, id, amount);
        return this.onERC1155Received.selector;
    }

    event ERC1155BatchReceived(
        address indexed nftCollection,
        address previousOwner,
        uint256[] tokenId,
        uint256[] amount
    );

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) public override returns (bytes4) {
        emit ERC1155BatchReceived(_msgSender(), operator, ids, amounts);
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

library BasisPoints {
    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return (amt * bp) / (BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return (amt * BASIS_POINTS) / (bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt + (mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt - (mulBP(amt, bp));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface INFTBank is IERC165Upgradeable {
    /**
     * @dev spots are the amount of discount a user can have on their WL NFTs.
     * examples:
     * spots = 10000 is for free NFTs (in Basis Points)
     * spots = 5000 is for 50% discounted NFTs
     * spots = 2500 is for 25% discounted NFTs
     * spots = 10001 is for guaranteed NFTs (no discount)
     * spots = 0 is for general NFTs (for all, no discount)
     * @note for the MVP, the only possible spots are 10000 and 10001 and 0
     */
    struct Mintables {
        uint256[] spots;
        bool[] mintedSpots;
        uint256 freeSpots;
        uint256 guaranteedSpots;
        uint256 raceSpots;
        uint256 freeSpotsMinted;
        uint256 raceSpotsMinted;
        uint256 guaranteedSpotsMinted;
        uint256 position;
        uint256 bestPrediction;
        bool isWhitelisted;
        bool isFreezed;
    }

    struct UserAllocation {
        address user;
        uint256 position;
        uint256 bestPrediction;
        uint256[] spots;
        uint256 freeSpots;
        uint256 guaranteedSpots;
        uint256 raceSpots;
    }

    enum Mode {
        Preparation, // is the default mode and nothing can be done in this mode (until FPL ends or
        // admins set the private mode)
        Private, // can set whitelist and mint price only in this mode, also admin
        // and creator can only mint in this mode
        Whitelist, // only whitelisted users can mint in this mode, can not be changed
        // before mintExpirationTime
        Public // anyone can mint in this mode, not MVP
    }

    enum NFTType {
        ERC721,
        ERC1155
    }

    error ShouldImportNFTDataFirst();
    error NotInPreparationMode();
    error NotInPrivateMode();
    error AlreadyInWhitelistMode();
    error CanNotImportDataBeforeNFTImportExpirationTime();
    error DoesNotSupportIERC721();
    error DoesNotSupportIERC1155();
    error NotAValidTokenType();
    error NotEnoughNFTsToBeClaimed();
    error SpotIsIncorrect(address user, uint256 spot);
    error TotalAllocationsExceedsMaxMintCount();
    error TotalFreeMintsExceedsFreeNFTs(uint256 requested, uint256 actual);
    error TotalGuaranteedMintsExceedsGuaranteedNFTs(
        uint256 requested,
        uint256 actual
    );
    error NumberOfFreeSpotsForUserIsWrong(uint256 requested, uint256 actual);
    error NumberOfGuaranteedSpotsForUserIsWrong(
        uint256 requested,
        uint256 actual
    );
    error NumberOfRaceSpotsForUserIsWrong(uint256 requested, uint256 actual);
    error MintingNotEndedYet();
    error MintingHasEnded();
    error WrongBaseURIProvided();
    error BalanceIsLessThanRequestedCount(uint256 requested, uint256 balance);
    error ClaimingNotStartedYet();
    error ClaimingHasEnded();
    error NotWhitelisted();
    error InvalidAmount(uint256 sent, uint256 minRequired);
    error RequestedPrivateModeClaimCountExceedsTotal();
    error RequestedFreeClaimCountExceedsTotal();
    error RequestedGuaranteedClaimCountExceedsTotal();
    error RequestedRaceClaimCountExceedsTotalForUser();
    error RequestedRaceClaimCountExceedsTotal();
    error NotEnoughNFTsLeft();
    error CanNotAllocateMoreThanClaimCap();
    error UserIsFreezed();
    error CanNotChangeModeBeforeWhitelistMintExpirationDate();
    error SpotIsAlreadyMinted(uint256 index);
    error RequestedPublicModeClaimCountExceedsTotal();
    error CanNotMintMoreThanMintCap();
    error PublicMintingIsEnded();
    error CanNotMintMoreThanPublicMintCap();
    error TransferNotSuccessful();
    error PublicMintingNotStartedYet();

    event PreparationModeIsOn();
    event PrivateModeIsOn();
    event WhitelistModeIsOn();
    event PublicModeIsOn();
    event ClaimPriceChanged(uint256 newClaimPrice, uint256 oldClaimPrice);
    event ClaimCapChanged(uint256 newClaimCap, uint256 oldClaimCap);
    event NFTDataImported(
        address[2] addresses,
        // nftType
        // price
        // publicMintPrice
        // maxMintCount
        // mintExpirationTime
        // publicMintExpirationTime
        // publicMintStartTimeGap
        // publicMintPercentage
        uint256[8] variables,
        uint256[] _nftIds,
        string symbol,
        bytes32 baseURIHash
    );
    event UsersUnfreezed(address[] users);
    event baseURIIsSet(string indexed baseURI);
    event WinnersAreSet(
        UserAllocation[] allocations,
        bool lastSlot,
        bool deletePreviousWinners,
        address[] deletedWinners
    );
    event UserClaimed(
        address indexed user,
        Mode claimMode,
        uint256 totalClaimFee,
        uint256 extraPaid,
        uint256 launchpadFee,
        bool[] spots,
        uint256 privateModeMintCount,
        uint256 publicModeMintCount,
        uint256[] claimedIds
    );
    event BalanceWithdrawn(address caller, address receiver, uint256 amount);
    event NewPublicMintExpirationTimeWasSet(
        uint256 oldDuration,
        uint256 newDuration
    );

    function getMode() external view returns (Mode);

    function getNFTType() external view returns (NFTType);

    function setPreparationMode() external;

    function setPrivateMode() external;

    function setPublicMode() external;

    function importNFTData(
        // addresses[0] = nftCollection
        // addresses[1] = creatorFeeWallet
        address[2] calldata addresses,
        // nftType
        // price
        // publicMintPrice
        // maxMintCount
        // mintExpirationTime
        // publicMintExpirationTime
        // publicMintStartTimeGap
        // publicMintPercentage
        uint256[8] calldata varibles,
        uint256[] calldata _nftIds,
        string memory _symbol,
        bytes32 _baseURIHash
    ) external;

    function setWhitelistedUsers(
        UserAllocation[] calldata allocations,
        uint256[3] calldata numberOfNFTs,
        address[] calldata deletedWinners,
        bool lastSlot,
        bool deletePreviousWinners
    ) external;

    function unfreezeUsers(address[] memory user) external;

    function claim(
        bool[] memory spots,
        uint256 privateModeMintCount,
        uint256 publicModeMintCount
    ) external payable;

    function getTotalClaimPrice(
        uint256 guaranteedClaimCount,
        uint256 raceClaimCount
    ) external view returns (uint256 claimFee);

    function setBaseURI(string memory _BaseURI) external;

    function setMintPrice(uint256 _mintPrice) external;

    function setMintCap(uint256 _mintCap) external;

    function isWhitelisted(address user) external view returns (bool);

    function getTotalNumberOfFreeSpots(address user)
        external
        view
        returns (uint256);

    function getNumberOfRemainingFreeSpots(address user)
        external
        view
        returns (uint256);

    function getTotalNumberOfGuaranteedSpots(address user)
        external
        view
        returns (uint256);

    function getNumberOfRemainingGuaranteedSpots(address user)
        external
        view
        returns (uint256);

    function getNumberOfRaceSpots(address user) external view returns (uint256);

    function getNumberOfRemainingRaceSpots(address user)
        external
        view
        returns (uint256);

    function getNumberOfTotalRemainingNFTs() external view returns (uint256);

    function getNumberOfTotalRemainingRaceNFTs()
        external
        view
        returns (uint256);

    function getUserSpots(address user)
        external
        view
        returns (uint256[] memory);

    function getUserMintedSpots(address user)
        external
        view
        returns (bool[] memory);

    function getTotalNFTsMinted(address user) external view returns (uint256);

    function getBalance() external view returns (uint256);

    function getWinners() external view returns (address[] memory);

    function getPosition(address user) external view returns (uint256 rank);

    function getBestPrediction(address user)
        external
        view
        returns (uint256 bestPrediction);

    function withdrawBalance(address payable receiver) external;

    function extendPublicMintDuration(uint256 newDuration) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "lossless/contracts/interfaces/ILosslessERC20.sol";

interface ISparkWorldToken is ILERC20 {
    function setAllocationAddresses(
        address _SeedAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingAddr,
        address _EchosystemTreasuryAddr,
        address _LiquidityAddr,
        address _AdvisorsAddr,
        address _AirdropAddr
    ) external;

    function distributeTokens() external;

    function getFeeWallet() external returns (address);

    function setFeeWallet(address _newFeeWallet) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function getAdmin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    
    function transferOutBlacklistedFunds(address[] calldata _from) external;
    function setLosslessAdmin(address _newAdmin) external;
    function transferRecoveryAdminOwnership(address _candidate, bytes32 _keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory _key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewAdmin(address indexed _newAdmin);
    event NewRecoveryAdminProposal(address indexed _candidate);
    event NewRecoveryAdmin(address indexed _newAdmin);
    event LosslessTurnOffProposal(uint256 _turnOffDate);
    event LosslessOff();
    event LosslessOn();
}