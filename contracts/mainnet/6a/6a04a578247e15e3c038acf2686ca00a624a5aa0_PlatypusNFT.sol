// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@base64/base64.sol";
import "./ERC2981.sol";
import "./interfaces/IPlatypusNFT.sol";

contract PlatypusNFT is ERC721, ERC2981, IPlatypusNFT {
    using Strings for uint256;

    address public owner;
    address public ownerCandidate;

    uint256 public availableTotalSupply;
    uint256 public preSaleOpenTime;
    uint256 public mintCost;
    uint256 public wlMintCost;
    uint256 public veMintCost;
    uint256 public auctionStep;
    uint256 public auctionFloor;


    string public baseURI = "nft.platypus.finance/api/platypus/";

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable PTP_TOKEN;
    uint256 public immutable MAX_PER_ADDRESS;

    /*///////////////////////////////////////////////////////////////
                            WHITELISTING
    //////////////////////////////////////////////////////////////*/

    bytes32 public veMerkleRoot;
    bytes32 public wlMerkleRoot;
    bytes32 public freeMerkleRoot;
    mapping(address => uint256) public veRedeemed;
    mapping(address => uint256) public wlRedeemed;
    mapping(address => uint256) public freeRedeemed;

    // for airdrops/partnerships
    uint256 public reserved;
    uint256 public wlSpotsLeft;
    uint256 public veSpotsLeft;

    /*///////////////////////////////////////////////////////////////
                            PLATYPUS DATA
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => Platypus) public platypuses;
    uint256 public platypusesLength;
    uint256 public totalSupply;

    // whitelist for leveling up
    mapping(address => uint256) public caretakers;
    mapping(uint256 => string) public platypusesNames;
    mapping(bytes32 => bool) public takenNames;
    uint256 public nameFee;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event LevelUpEv(
        uint256 tokenId,
        uint256 indexed newAbility,
        uint256 newPower
    );
    event LevelDownEv(uint256 tokenId);
    event GrowXp(uint256 tokenId, uint256 amount);
    event NameChange(uint256 tokenId);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error FeeTooHigh();
    error InvalidCaretaker();
    error InvalidTokenID();
    error MintLimit();
    error PreSaleEnded();
    error TicketError();
    error TooSoon();
    error Unauthorized();
    error OnlyEOAAllowed();
    error InvalidOperation();
    error ZeroAddress();
    error MaxLength25();
    error ReservedAmountInvalid();
    error OnlyAlphanumeric();
    error NameTaken();

    constructor(
        string memory _NFT_NAME,
        string memory _NFT_SYMBOL,
        address _PTP_ADDRESS,
        uint256 _TOTAL_SUPPLY,
        uint256 _MAX_PER_ADDRESS,
        address _ROYALTY_ADDRESS,
        uint256 _ROYALTY_FEE
    ) ERC721(_NFT_NAME, _NFT_SYMBOL) ERC2981(_ROYALTY_ADDRESS, _ROYALTY_FEE) {
        if (_ROYALTY_FEE > 100) revert FeeTooHigh();
        if (_PTP_ADDRESS == address(0x0)) revert ZeroAddress();
        if (_ROYALTY_ADDRESS == address(0x0)) revert ZeroAddress();

        owner = msg.sender;
        availableTotalSupply = _TOTAL_SUPPLY;

        mintCost = 500 ether;
        wlMintCost = 250 ether;
        veMintCost = 250 ether;

        auctionStep = 20 ether;
        auctionFloor = 200 ether;

        wlSpotsLeft = 1000;
        veSpotsLeft = 2800;

        nameFee = 100 ether;

        //slither-disable-next-line missing-zero-check
        PTP_TOKEN = _PTP_ADDRESS;

        //slither-disable-next-line missing-zero-check
        MAX_PER_ADDRESS = _MAX_PER_ADDRESS;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function proposeOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0x0)) revert ZeroAddress();

        ownerCandidate = newOwner;
    }

    function acceptOwnership() external {
        if (ownerCandidate != msg.sender) revert Unauthorized();

        owner = msg.sender;
        emit OwnerUpdated(msg.sender);
    }

    function cancelOwnerProposal() external {
        if (ownerCandidate != msg.sender && owner != msg.sender)
            revert Unauthorized();

        ownerCandidate = address(0x0);
    }

    function increaseAvailableTotalSupply(uint256 amount)
        external
        override
        onlyOwner
    {
        // overflow is unrealistic
        unchecked {
            availableTotalSupply += amount;
        }
    }

    function changeMintCost(
        uint256 publicCost,
        uint256 wlCost,
        uint256 veCost
    ) external override onlyOwner {
        mintCost = publicCost;
        wlMintCost = wlCost;
        veMintCost = veCost;
    }

    function setNewRoyaltyDetails(address _newAddress, uint256 _newFee)
        external
        override
        onlyOwner
    {
        if (_newFee > 100) revert FeeTooHigh();
        if (_newAddress == address(0x0)) revert ZeroAddress();

        ROYALTY_ADDRESS = _newAddress;

        ROYALTY_FEE = _newFee;

        emit ChangeRoyalty(_newAddress, _newFee);
    }

    function setBaseURI(string memory _baseURI) external override onlyOwner {
        baseURI = _baseURI;
    }

    function setNameFee(uint256 _nameFee) external override onlyOwner {
        nameFee = _nameFee;
    }

    function setAuctionParameters(uint256 _auctionStep, uint256 _auctionFloor) external onlyOwner {
        auctionStep = _auctionStep;
        auctionFloor = _auctionFloor;
    }

    function setPrioritySteps(uint256 _wlSpotsLeft, uint256 _veSpotsLeft) external onlyOwner {
        wlSpotsLeft = _wlSpotsLeft;
        veSpotsLeft = _veSpotsLeft;
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    function withdrawPTP() external override onlyOwner {
        ERC20 token = ERC20(PTP_TOKEN);
        SafeTransferLib.safeTransfer(
            token,
            msg.sender,
            token.balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                        PLATYPUS LEVEL MECHANICS
            Caretakers are other authorized contracts that
                according to their own logic can issue a platypus
                    to level up
    //////////////////////////////////////////////////////////////*/

    function addCaretaker(address caretaker) external override onlyOwner {
        if (caretaker == address(0x0)) revert ZeroAddress();
        caretakers[caretaker] = 1;
    }

    function removeCaretaker(address caretaker) external override onlyOwner {
        if (caretaker == address(0x0)) revert ZeroAddress();
        delete caretakers[caretaker];
    }

    function growXp(uint256 tokenId, uint256 xp) external {
        if (!_exists(tokenId)) revert InvalidTokenID();
        if (caretakers[msg.sender] == 0) revert InvalidCaretaker();

        // overflow is unrealistic
        unchecked {
            platypuses[tokenId].xp += xp;
        }
        emit GrowXp(tokenId, xp);
    }

    function levelUp(
        uint256 tokenId,
        uint256 newAbility,
        uint256 newPower
    ) external override {
        if (!_exists(tokenId)) revert InvalidTokenID();
        if (caretakers[msg.sender] == 0) revert InvalidCaretaker();

        // overflow is unrealistic
        unchecked {
            Platypus storage platypus = platypuses[tokenId];

            uint256 abilitySlot = platypus.level;

            platypus.level += 1;
            platypus.ability[abilitySlot] = uint8(newAbility);
            platypus.power[abilitySlot] = uint32(newPower);

            // reset XP;
            platypus.xp = 0;
        }
        emit LevelUpEv(tokenId, newAbility, newPower);
    }

    function levelDown(uint256 tokenId) external override {
        if (!_exists(tokenId)) revert InvalidTokenID();
        if (caretakers[msg.sender] == 0) revert InvalidCaretaker();

        Platypus storage platypus = platypuses[tokenId];

        //slither-disable-next-line incorrect-equality
        if (platypus.level == 1) revert InvalidOperation();

        unchecked {
            platypus.level -= 1;
        }

        // reset XP;
        platypus.xp = 0;

        emit LevelDownEv(tokenId);
    }

    function burn(uint256 tokenId) external override {
        if (!_exists(tokenId)) revert InvalidTokenID();

        //solhint-disable-next-line
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        if (caretakers[msg.sender] == 0) revert InvalidCaretaker();

        delete platypuses[tokenId];

        unchecked {
            --totalSupply;
        }

        _burn(tokenId);
    }

    function changePlatypusName(uint256 tokenId, string calldata _newName)
        external
        override
    {
        if (!_exists(tokenId)) revert InvalidTokenID();
        if (ownerOf(tokenId) != msg.sender) revert Unauthorized();

        bytes memory newName = bytes(_newName);
        uint256 newLength = newName.length;

        if (newLength > 25) revert MaxLength25();

        // Checks it's only alphanumeric characters
        for (uint256 i = 0; i < newLength; ) {
            bytes1 char = newName[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            ) {
                revert OnlyAlphanumeric();
            }
            unchecked {
                ++i;
            }
        }

        // Checks new name uniqueness
        bytes32 nameHash = keccak256(newName);
        if (takenNames[nameHash]) revert NameTaken();

        // Free previous name
        takenNames[keccak256(bytes(platypusesNames[tokenId]))] = false;

        // Reserve name
        takenNames[nameHash] = true;
        platypusesNames[tokenId] = _newName;

        SafeTransferLib.safeTransferFrom(
            ERC20(PTP_TOKEN),
            msg.sender,
            address(this),
            nameFee
        );

        emit NameChange(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                        PLATYPUS TRAIT GENERATION
    //////////////////////////////////////////////////////////////*/

    //slither-disable-next-line incorrect-equality
    function calculateTraitScore(uint256 traitID)
        internal
        pure
        returns (uint256)
    {
        if (traitID <= 7) {
            // D8 - D1
            return 1;
        } else if (traitID <= 13) {
            // C6 - C1
            return 2;
        } else if (traitID <= 17) {
            // B4 - B1
            return 3;
        } else {
            // A2 - A1
            return 4;
        }
    }

    function calculateOverallScore(Platypus memory platypus)
        internal
        pure
        returns (uint256)
    {
        // overflow should not happen since each attribute is at most 6.
        unchecked {
            return
                calculateTraitScore(platypus.eyes) +
                calculateTraitScore(platypus.mouth) +
                calculateTraitScore(platypus.skin) +
                calculateTraitScore(platypus.clothes) +
                calculateTraitScore(platypus.tail) +
                calculateTraitScore(platypus.accessories);
        }
    }

    //slither-disable-next-line weak-prng,incorrect-equality
    function calculatePower(uint256 ability, uint256 score)
        internal
        pure
        returns (uint256)
    {
        // overflow should not happen, since each score is at most 30
        unchecked {
            if (ability == 0) {
                // Speedo
                return score;
            } else if (ability == 1) {
                // Pudgy
                return score;
            } else if (ability == 2) {
                // Diligent

                // round off
                return (score**4 + 500) / 1000;
            } else if (ability == 3) {
                // Gifted
                return (score**3) * 10;
            } else if (ability == 4) {
                // Hibernate
                return score * 4;
            }
        }
    }

    function enoughRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
    }

    //slither-disable-next-line weak-prng
    function generate(uint256 seed) internal pure returns (Platypus memory) {
        unchecked {
            Platypus memory plat = Platypus({
                eyes: uint8((seed >> (8 * 1)) % 20),
                mouth: uint8((seed >> (8 * 2)) % 20),
                skin: uint8((seed >> (8 * 3)) % 20),
                clothes: uint8((seed >> (8 * 4)) % 20),
                tail: uint8((seed >> (8 * 5)) % 20),
                accessories: uint8((seed >> (8 * 6)) % 20),
                bg: uint8((seed >> (8 * 7)) % 5),
                ability: [uint8(generateRandomAbilityId(seed)), 0, 0, 0, 0],
                score: 0,
                power: [uint32(0), 0, 0, 0, 0],
                level: 1,
                xp: 0
            });
            plat.score = uint16(calculateOverallScore(plat));
            plat.power[0] = uint32(calculatePower(plat.ability[0], plat.score));
            return plat;
        }
    }

    //slither-disable-next-line weak-prng
    function generateRandomAbilityId(uint256 seed)
        internal
        pure
        returns (uint256)
    {
        /*///////////////////////////////////////////////////////////////
        ###  WEIGHT ABILITIES ####
         0x3d << 8*0 |  // Speedo 24% | 61
         0x3d << 8*1 |  // Pudgy 24% | 61
         0x3d << 8*2 | // Diligent 24% | 61
         0x3d << 8*3 | // Gifted 24% | 61
         0x0a << 8*4 | // Hibernate 4% | 10
        ###  ALIASES ABILITIES ####
         0x01 << 8*5 | // Speedo
         0x02 << 8*6 | // Pudgy
         0x03 << 8*7 | // Diligent
         0x00 << 8*8 | // Gifted
         0x00 << 8*9;  // Hibernate
    //////////////////////////////////////////////////////////////*/

        //slither-disable-next-line too-many-digits
        uint256 cpw = 0x00_00_03_02_01_0a_3d_3d_3d_3d;
        uint256 trait = uint8(seed) % 5;

        unchecked {
            if (uint8(seed >> 8) < uint8(cpw >> (8 * trait))) return trait;
            else return uint8(cpw >> (8 * (5 + trait)));
        }
    }

    /*///////////////////////////////////////////////////////////////
                            MINT REQUESTS
    //////////////////////////////////////////////////////////////*/

    function _requestMint(
        uint256 numberOfMints,
        uint256 _preSaleOpenTime,
        uint256 payment
    ) internal {
        // solhint-disable-next-line
        if (msg.sender != tx.origin) revert OnlyEOAAllowed();

        if (_preSaleOpenTime == 0 || block.timestamp < _preSaleOpenTime)
            revert TooSoon();

        uint256 pId = platypusesLength;

        if (
            numberOfMints > MAX_PER_ADDRESS ||
            pId + numberOfMints > availableTotalSupply
        ) revert MintLimit();

        // overflow is unrealistic
        unchecked {
            platypusesLength += numberOfMints;
            totalSupply += numberOfMints;

            uint256 seed = enoughRandom();

            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < numberOfMints; ++i) {
                _mint(msg.sender, pId + i);
                platypuses[pId + i] = generate(seed >> i);
            }
        }

        if (payment > 0) {
            // Payment
            SafeTransferLib.safeTransferFrom(
                ERC20(PTP_TOKEN),
                msg.sender,
                address(this),
                payment
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            PTP MINTING
    //////////////////////////////////////////////////////////////*/

    function freeMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external {
        if (freeRedeemed[msg.sender] + numberOfMints > totalGiven)
            revert Unauthorized();

        if (reserved < numberOfMints) revert ReservedAmountInvalid();

        if (
            !MerkleProof.verify(
                proof,
                freeMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, totalGiven))
            )
        ) revert Unauthorized();

        unchecked {
            freeRedeemed[msg.sender] += numberOfMints;
            reserved -= numberOfMints;
        }

        _requestMint(numberOfMints, preSaleOpenTime, 0);
    }

    function wlMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external {
        uint256 _preSaleOpenTime = preSaleOpenTime;

        unchecked {
            if (block.timestamp > _preSaleOpenTime + 24 hours)
                revert PreSaleEnded();
        }

        if (wlRedeemed[msg.sender] + numberOfMints > totalGiven)
            revert Unauthorized();

        if (numberOfMints > wlSpotsLeft) revert Unauthorized();

        if (
            !MerkleProof.verify(
                proof,
                wlMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, totalGiven))
            )
        ) revert Unauthorized();

        unchecked {
            wlRedeemed[msg.sender] += numberOfMints;
            wlSpotsLeft -= numberOfMints;
        }

        _requestMint(
            numberOfMints,
            _preSaleOpenTime,
            numberOfMints * wlMintCost
        );
    }

    function veMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external {
        uint256 _preSaleOpenTime = preSaleOpenTime;
        unchecked {
            if (block.timestamp > _preSaleOpenTime + 24 hours)
                revert PreSaleEnded();
        }

        if (veRedeemed[msg.sender] + numberOfMints > totalGiven)
            revert Unauthorized();

        if (numberOfMints > veSpotsLeft) revert Unauthorized();

        if (
            !MerkleProof.verify(
                proof,
                veMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, totalGiven))
            )
        ) revert Unauthorized();

        unchecked {
            veRedeemed[msg.sender] += numberOfMints;
            veSpotsLeft -= numberOfMints;
        }

        _requestMint(
            numberOfMints,
            _preSaleOpenTime,
            numberOfMints * veMintCost
        );
    }

    function normalMint(uint256 numberOfMints) external {
        uint256 _preSaleOpenTime = preSaleOpenTime;
        unchecked {
            if (block.timestamp < _preSaleOpenTime + 24 hours) revert TooSoon();
        }

        _requestMint(
            numberOfMints,
            _preSaleOpenTime,
            _getPrice() * numberOfMints
        );
    }

    /*///////////////////////////////////////////////////////////////
                            OPEN SALE
    //////////////////////////////////////////////////////////////*/

    function setSaleDetails(
        uint256 _preSaleOpenTime,
        bytes32 _wlRoot,
        bytes32 _veRoot,
        bytes32 _freeRoot,
        uint256 _reserved
    ) external override onlyOwner {
        wlMerkleRoot = _wlRoot;
        veMerkleRoot = _veRoot;
        freeMerkleRoot = _freeRoot;
        reserved = _reserved;

        // setting a deadline opens up the minting right away
        preSaleOpenTime = _preSaleOpenTime;
    }

    function _getPrice() internal view returns (uint256) {
        uint256 saleTime = preSaleOpenTime + 24 hours;
        if (block.timestamp < saleTime) revert TooSoon();
        uint256 _mintCost = mintCost;

        //slither-disable-next-line divide-before-multiply
        uint256 decrease = auctionStep *
            ((block.timestamp - saleTime) / uint256(30 minutes));

        if (decrease > _mintCost) {
            return auctionFloor;
        } else {
            uint256 price = _mintCost - decrease;
            uint256 _auctionFloor = auctionFloor;
            return price > _auctionFloor ? price : _auctionFloor;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function getPrice() external view returns (uint256) {
        return _getPrice();
    }

    function getPlatypusXp(uint256 tokenId)
        external
        view
        override
        returns (uint256 xp)
    {
        if (!_exists(tokenId)) revert InvalidTokenID();
        return platypuses[tokenId].xp;
    }

    function getPlatypusLevel(uint256 tokenId)
        external
        view
        override
        returns (uint16 level)
    {
        if (!_exists(tokenId)) revert InvalidTokenID();
        return platypuses[tokenId].level;
    }

    function getPrimaryAbility(uint256 tokenId)
        external
        view
        override
        returns (uint8 ability, uint32 power)
    {
        if (!_exists(tokenId)) revert InvalidTokenID();
        Platypus memory platypus = platypuses[tokenId];
        return (platypus.ability[0], platypus.power[0]);
    }

    //slither-disable-next-line incorrect-equality
    function getPlatypusDetails(uint256 tokenId)
        external
        view
        override
        returns (
            uint32 speedo,
            uint32 pudgy,
            uint32 diligent,
            uint32 gifted,
            uint32 hibernate
        )
    {
        if (!_exists(tokenId)) revert InvalidTokenID();
        Platypus memory platypus = platypuses[tokenId];

        unchecked {
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < platypus.level; ++i) {
                if (platypus.ability[i] == 0) {
                    speedo += platypus.power[i];
                } else if (platypus.ability[i] == 1) {
                    pudgy += platypus.power[i];
                } else if (platypus.ability[i] == 2) {
                    diligent += platypus.power[i];
                } else if (platypus.ability[i] == 3) {
                    gifted += platypus.power[i];
                } else if (platypus.ability[i] == 4) {
                    hibernate += platypus.power[i];
                }
            }
        }
        hibernate = hibernate <= 100 ? hibernate : 100;
    }

    //slither-disable-next-line incorrect-equality
    function getAttributeClassification(uint256 traitID)
        internal
        pure
        returns (string memory)
    {
        if (traitID <= 7) {
            // D8 - D1
            if (traitID <= 3) {
                if (traitID == 0) {
                    return "D8";
                } else if (traitID == 1) {
                    return "D7";
                } else if (traitID == 2) {
                    return "D6";
                } else {
                    return "D5";
                }
            } else {
                if (traitID == 4) {
                    return "D4";
                } else if (traitID == 5) {
                    return "D3";
                } else if (traitID == 6) {
                    return "D2";
                } else {
                    return "D1";
                }
            }
        } else if (traitID <= 13) {
            // C6 - C1
            if (traitID == 8) {
                return "C6";
            } else if (traitID == 9) {
                return "C5";
            } else if (traitID == 10) {
                return "C4";
            } else if (traitID == 11) {
                return "C3";
            } else if (traitID == 12) {
                return "C2";
            } else {
                return "C1";
            }
        } else if (traitID <= 17) {
            // B4 - B1
            if (traitID == 14) {
                return "B4";
            } else if (traitID == 15) {
                return "B3";
            } else if (traitID == 16) {
                return "B2";
            } else {
                return "B1";
            }
        } else {
            // A2 - A1
            if (traitID == 18) {
                return "A2";
            } else if (traitID == 19) {
                return "A1";
            } else {
                revert("invalid class");
            }
        }
    }

    //slither-disable-next-line incorrect-equality
    function getAbilityClassification(uint256 rank)
        internal
        pure
        returns (string memory)
    {
        if (rank == 0) {
            return "Speedo";
        } else if (rank == 1) {
            return "Pudgy";
        } else if (rank == 2) {
            return "Diligent";
        } else if (rank == 3) {
            return "Gifted";
        } else if (rank == 4) {
            return "Hibernate";
        }
    }

    function getPlatypusClassification(uint256 score)
        internal
        pure
        returns (string memory)
    {
        if (score >= 20 && score <= 24) {
            return "Legendary";
        } else if (score >= 17 && score <= 19) {
            return "Mystic";
        } else if (score >= 15 && score <= 16) {
            return "Exceptional";
        } else if (score >= 13 && score <= 14) {
            return "Rare";
        } else if (score >= 6 && score <= 12) {
            return "Common";
        } else {
            return "undefined";
        }
    }

    function getPlatypusName(uint256 tokenId)
        public
        view
        override
        returns (string memory name)
    {
        name = platypusesNames[tokenId];

        if (bytes(name).length == 0) {
            name = "Unnamed";
        }
    }

    function buildAttributesJSON(Platypus memory platypus)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                bytes.concat(
                    '{"trait_type": "eyes", "value": "',
                    bytes(getAttributeClassification(platypus.eyes)),
                    '"},',
                    '{"trait_type": "mouth", "value": "',
                    bytes(getAttributeClassification(platypus.mouth)),
                    '"},',
                    '{"trait_type": "skin", "value": "',
                    bytes(getAttributeClassification(platypus.skin)),
                    '"},',
                    '{"trait_type": "clothes", "value": "',
                    bytes(getAttributeClassification(platypus.clothes)),
                    '"},',
                    '{"trait_type": "tail", "value": "',
                    bytes(getAttributeClassification(platypus.tail)),
                    '"},',
                    '{"trait_type": "accessories", "value": "',
                    bytes(getAttributeClassification(platypus.accessories)),
                    '"},',
                    '{"trait_type": "xp", "value": "',
                    bytes(uint256(platypus.xp).toString()),
                    '"},',
                    '{"trait_type": "bg", "value": "',
                    bytes(uint256(platypus.bg).toString()),
                    '"}'
                )
            );
    }

    function buildPowersJSON(Platypus memory platypus)
        internal
        pure
        returns (string memory powersAbilities)
    {
        unchecked {
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < platypus.level; ++i) {
                powersAbilities = string(
                    bytes.concat(
                        bytes(powersAbilities),
                        '{"trait_type": "power',
                        bytes(uint256(i).toString()),
                        '", "value": ',
                        bytes(uint256(platypus.power[i]).toString()),
                        "},"
                    )
                );

                powersAbilities = string(
                    bytes.concat(
                        bytes(powersAbilities),
                        '{"trait_type": "ability',
                        bytes(uint256(i).toString()),
                        '", "value": "',
                        bytes(getAbilityClassification(platypus.ability[i])),
                        '"}'
                    )
                );

                if (i != platypus.level - 1) {
                    powersAbilities = string(
                        bytes.concat(bytes(powersAbilities), bytes(","))
                    );
                }
            }
        }
    }

    function _jsonString(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenID();

        Platypus memory platypus = platypuses[tokenId];
        string memory powersAbilities = buildPowersJSON(platypus);

        return
            string(
                bytes.concat(
                    '{"name":"',
                    bytes(getPlatypusName(tokenId)),
                    '", "description":"PlatypusNFT!", "attributes":[',
                    '{"trait_type": "level", "value": ',
                    bytes(uint256(platypus.level).toString()),
                    "},",
                    '{"trait_type": "score", "value": ',
                    bytes(uint256(platypus.score).toString()),
                    "},",
                    '{"trait_type": "category", "value": "',
                    bytes(getPlatypusClassification(platypus.score)),
                    '"},',
                    bytes(powersAbilities),
                    ",",
                    bytes(buildAttributesJSON(platypus)),
                    "],",
                    '"token_id":',
                    bytes(uint256(tokenId).toString()),
                    ', "image":"https://',
                    bytes(baseURI),
                    bytes(tokenId.toString()),
                    '"}'
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, IPlatypusNFT)
        returns (string memory)
    {
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    bytes(Base64.encode(bytes(_jsonString(tokenId))))
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./interfaces/IERC2981Royalties.sol";

abstract contract ERC2981 is IERC2981Royalties {
    address public ROYALTY_ADDRESS;
    uint256 public ROYALTY_FEE; // 0 - 100 %

    event ChangeRoyalty(address newAddress, uint256 newFee);

    constructor(address _ROYALTY_ADDRESS, uint256 _ROYALTY_FEE) {
        ROYALTY_ADDRESS = _ROYALTY_ADDRESS;
        ROYALTY_FEE = _ROYALTY_FEE;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == 0x01ffc9a7; //erc165
    }

    function royaltyInfo(
        uint256 _tokenId, // solhint-disable-line
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        return (ROYALTY_ADDRESS, (_value * ROYALTY_FEE) / 100);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IERC2981Royalties.sol";

interface IPlatypusNFT is IERC721, IERC2981Royalties {
    struct Platypus {
        uint16 level;
        uint16 score;
        // Attributes ( 0 - 9 | D4 D3 D2 D1 C3 C2 C1 B1 B2 A)
        uint8 eyes;
        uint8 mouth;
        uint8 skin;
        uint8 clothes;
        uint8 tail;
        uint8 accessories;
        uint8 bg;
        // Abilities
        // 0 - Speedo
        // 1 - Pudgy
        // 2 - Diligent
        // 3 - Gifted
        // 4 - Hibernate
        uint8[5] ability;
        uint32[5] power;
        uint256 xp;
    }

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    function getPrice() external view returns (uint256);

    function availableTotalSupply() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
        CONTRACT MANAGEMENT OPERATIONS / SALES
    //////////////////////////////////////////////////////////////*/
    function owner() external view returns (address);

    function ownerCandidate() external view returns (address);

    function proposeOwner(address newOwner) external;

    function acceptOwnership() external;

    function cancelOwnerProposal() external;

    function increaseAvailableTotalSupply(uint256 amount) external;

    function changeMintCost(
        uint256 publicCost,
        uint256 wlCost,
        uint256 veCost
    ) external;

    function setSaleDetails(
        uint256 _preSaleOpenTime,
        bytes32 _wlRoot,
        bytes32 _veRoot,
        bytes32 _freeRoot,
        uint256 _reserved
    ) external;

    function preSaleOpenTime() external view returns (uint256);

    function withdrawPTP() external;

    function setNewRoyaltyDetails(address _newAddress, uint256 _newFee)
        external;

    /*///////////////////////////////////////////////////////////////
                        PLATYPUS LEVEL MECHANICS
            Caretakers are other authorized contracts that
                according to their own logic can issue a platypus
                    to level up
    //////////////////////////////////////////////////////////////*/
    function caretakers(address) external view returns (uint256);

    function addCaretaker(address caretaker) external;

    function removeCaretaker(address caretaker) external;

    function growXp(uint256 tokenId, uint256 xp) external;

    function levelUp(
        uint256 tokenId,
        uint256 newAbility,
        uint256 newPower
    ) external;

    function levelDown(uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function changePlatypusName(uint256 tokenId, string calldata name) external;

    /*///////////////////////////////////////////////////////////////
                            PLATYPUS
    //////////////////////////////////////////////////////////////*/

    function getPlatypusXp(uint256 tokenId) external view returns (uint256 xp);

    function getPlatypusLevel(uint256 tokenId)
        external
        view
        returns (uint16 level);

    function getPrimaryAbility(uint256 tokenId)
        external
        view
        returns (uint8 ability, uint32 power);

    function getPlatypusDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 speedo,
            uint32 pudgy,
            uint32 diligent,
            uint32 gifted,
            uint32 hibernate
        );

    function platypusesLength() external view returns (uint256);

    function setBaseURI(string memory _baseURI) external;

    function setNameFee(uint256 _nameFee) external;

    function getPlatypusName(uint256 tokenId)
        external
        view
        returns (string memory name);

    /*///////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/
    function normalMint(uint256 numberOfMints) external;

    function veMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external;

    function wlMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external;

    function freeMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external;

    // comment to disable a slither false allert: PlatypusNFT does not implement functions
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function _jsonString(uint256 tokenId) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    // event OwnerUpdated(address indexed newOwner);

    // ERC2981.sol
    // event ChangeRoyalty(address newAddress, uint256 newFee);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    // error FeeTooHigh();
    // error InvalidCaretaker();
    // error InvalidTokenID();
    // error MintLimit();
    // error PreSaleEnded();
    // error TicketError();
    // error TooSoon();
    // error Unauthorized();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
interface IERC165 {
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";