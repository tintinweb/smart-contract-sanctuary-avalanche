// SPDX-License-Identifier: MIT
/**
* ______              ______                  
* |  ___|             |  ___|                 
* | |_ _ __ ___   __ _| |_ _ __ ___ _ __  ___ 
* |  _| '__/ _ \ / _` |  _| '__/ _ \ '_ \/ __|
* | | | | | (_) | (_| | | | | |  __/ | | \__ \
* \_| |_|  \___/ \__, \_| |_|  \___|_| |_|___/
*                 __/ |                       
*                |___/          
*/

import "./ERC721.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./Address.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity 0.8.3;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

pragma solidity 0.8.3;

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

pragma solidity 0.8.3;

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties {
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");
        _royalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }
}

interface RoyaltiesInterface {
    function claimCommunity(uint256 tokenId) external;
}

pragma solidity 0.8.3;

contract FrogFrens is
    IERC721Receiver,
    ERC721Enumerable,
    Ownable,
    ERC2981PerTokenRoyalties
{
    using Strings for uint256;

    struct Winner {
        uint256 date;
        address winner;
        uint256 tokenId;
    }

    mapping(uint256 => address) private winner;

    string baseURI; 
    string public baseExtension = ".json";
    uint256 public giveawayIntervalDays = 7;
    uint256 private epochDay = 86400;
    uint256 public cost = 2 ether;
    uint256 public maxSupply = 4444;
    uint256 public maxMintForTx = 10;
    uint256 public maxMintsForAddress = 30;
    uint256 private noFreeAddresses = 0;
    uint256 public drawNumber = 0;
    uint256 private contractRoyalties = 300; 
    address public royaltiesAddress; 
    bool public paused = true;
    bool public giveawayActive = false;
    bool public airDropActive = false;
    bool public presaleListActive = false;
    uint256[] public giveawayDates;
    address[] private airDropAddresses;

    mapping(address => bool) public FreeListAddresses;
    mapping(address => uint256) private addressMints;
    mapping(uint256 => Winner[]) public winnerLog;
    mapping(address => uint256) private _winners;
    mapping(address => uint8) private _PresaleList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }
    
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*
    @function _baseURI()
    @description - Gets the current base URI for nft metadata
    @returns <string>
  */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
    @function setIsPresaleListActive(_isPresaleListActive)
    @description - Enable/Disable PresaleList.
    @param <bool> _isPresaleListActive - true/false.
   */
    function setIsPresaleListActive(bool _isPresaleListActive) external onlyOwner {
        presaleListActive = _isPresaleListActive;
    }

    function setPresaleList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _PresaleList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _PresaleList[addr];
    }

    function mintPresaleList(uint8 numberOfTokens) public payable {
        uint256 supply = totalSupply();
        require(presaleListActive, "Sorry Fren, the presale sale is not active.");
        require(numberOfTokens <= _PresaleList[msg.sender], "Sorry Fren, you have exceeded max available to purchase or not on the presale.");
        require(supply + numberOfTokens <= maxSupply, "Sorry Fren, all our Frog Frens are now minted!");
        require(cost * numberOfTokens <= msg.value, "Sorry Fren, you need more AVAX to mint Frog Frens.");

        _PresaleList[msg.sender] -= numberOfTokens;
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(msg.sender, tokenId);
            _setTokenRoyalty(tokenId, royaltiesAddress, contractRoyalties);
            supply = totalSupply();
        }
    }

    /*
    @function mint(_mintAmount)
    @description - Mints _mintAmount of NFTs for sender address.
    @param <uint256> _mintAmount - The number of NFTs to mint.
   */
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerCanMintCount = maxMintsForAddress - addressMints[msg.sender];

        require(ownerCanMintCount >= _mintAmount, "Sorry Fren, you have reached your Frog Frens limit.");
        require(!paused, "Contract is paused. Please check https://dsc.gg/frogfrens");
        require(_mintAmount <= maxMintForTx, "Sorry Fren, you have breached the max number of mints per transaction.");
        require(supply + _mintAmount <= maxSupply, "Sorry Fren, all our Frog Frens are now minted!");

        if (!FreeListAddresses[msg.sender]) {
            require(msg.value >= cost * _mintAmount, "Sorry Fren, you need more AVAX to mint Frog Frens.");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(msg.sender, tokenId);
            _setTokenRoyalty(tokenId, royaltiesAddress, contractRoyalties);

            addressMints[msg.sender]++;

            if (tokenId == maxSupply) {
                activateGiveaway();
            }

            supply = totalSupply();
        }
    }

    /*
    @function reserveNFT()
    @description - Reserve a number of NFT's 
   */
    function reserveNFT(uint16 _mintAmount, address _for) external onlyOwner {
        _mintReserveTokens(_mintAmount, _for);
    }

    function _mintReserveTokens(uint16 _mintAmount, address _for) internal {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "ERROR: Insufficient supply");
        
        for (uint i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(_for, tokenId);
            _setTokenRoyalty(tokenId, royaltiesAddress, contractRoyalties);
            supply = totalSupply();
        }
    }

    /*
    @function activateGiveaway(_owner)
    @description - Activates the giveaway
  */
    function activateGiveaway() private {
        giveawayActive = true;
        giveawayDates.push(block.timestamp + (epochDay * giveawayIntervalDays));
        drawNumber++;
    }

    /*
    @function walletOfOwner(_owner)
    @description - Gets the list of NFT tokenIds that owner has.
  */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /*
    @function tokenURL(tokenId)
    @description - Gets the metadata URI for a NFT tokenId
    @param <uint256> tokenId - The id ok the NFT token
    @returns <string> - The URI for the NFT metadata file
  */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /*
    @function setCost(_newCost)
    @description - Sets the cost of a single NFT
    @param <uint256> _newCost - The cost of a single nft
   */
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /*
    @dev internal set royalties address
    @param _royaltiesAddress address of the FrogFrensRoyaltiesContract
   */
    function _setRoyaltiesAddress(address _royaltiesAddress) internal {
        royaltiesAddress = _royaltiesAddress;
    }

    function setRoyaltiesAddress(address _newRoyaltiesAddress) public onlyOwner {
        royaltiesAddress = _newRoyaltiesAddress;
    }

    function getRoyaltiesAddress() public view returns (address) {
        return royaltiesAddress;
    }

    /*
    @function setMaxMintForTx
    @description - Sets the maximum mintable amount in 1 tx
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForTx(uint256 amount) public onlyOwner {
        maxMintForTx = amount;
    }

    /*
    @function setMaxMintForAddress
    @description - Sets the maximum mintable amount for an address
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForAddress(uint256 amount) public onlyOwner {
        maxMintsForAddress = amount;
    }

    /*
    @function setBaseURI(_newBaseURI)
    @description - Sets the base URI for the meta data files
    @param <string> _newBaseURI - The new base URI for the metadata files
  */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /*
    @function setBaseExtension(_newBaseExtension)
    @description - Sets the extension for the meta data file (default .json)
    @param <string> _newBaseExtension - The new file extension to use.
  */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /*
    @function pause(_state)
    @description - Pauses the contract.
    @param <bool> _state - true/false
  */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /*
    @function selectWinner()
    @description - Selects a winner if the current date allows. Uses NFT id to select winner.
    @param <uint> no - The number of winners
    @returns <address> - The winner
    */
    function selectWinners(uint256 noOfWinners) public onlyOwner {
        require(!paused, "ERROR: Contract is paused");
        require(giveawayActive, "ERROR: Giveaway not active yet");
        require(noOfWinners <= 15, "ERROR: Too many winners selected");

        uint256 epochNow = block.timestamp;
        uint256 nextGiveawayDate = giveawayDates[giveawayDates.length - 1];

        require(epochNow >= nextGiveawayDate, "ERROR: Cannot draw yet, too early");

        for (uint256 i = 0; i < noOfWinners; i++) {
            selectAWinner(
                0,
                epochNow,
                msg.sender,
                nextGiveawayDate,
                msg.sender,
                0
            );
        }

        giveawayDates.push(epochNow + (epochDay * giveawayIntervalDays));

        // increment draw
        drawNumber++;
    }

    /*
    @function selectAWinner()
    @description - Selects a winner and does not allow the same address to win more than once.
    @param <uint> no - The number of winners
    @returns <address> - The winner
    */
    function selectAWinner(
        uint256 it,
        uint256 epochNow,
        address sender,
        uint256 GiveawayDate,
        address randomAddr,
        uint256 randomNo
    ) internal {
        // Generate random id between 1 - 5000 (corresponds to NFT id)

        uint256 winningToken = rand(randomAddr, randomNo);
        address winnerAddress = ERC721.ownerOf(winningToken);
        uint256 lastWon = _winners[winnerAddress];

        bool alreadyWon = (lastWon == GiveawayDate);

        Winner memory win;

        if ((it < 5) && alreadyWon) {
            uint256 newIt = it + 1;
            return
                selectAWinner(
                    newIt,
                    epochNow,
                    sender,
                    GiveawayDate,
                    winnerAddress,
                    winningToken
                );
        } else if ((it >= 5) && alreadyWon) {
            return;
        } else {
            win.date = GiveawayDate;
            win.winner = winnerAddress;
            win.tokenId = winningToken;
            winnerLog[drawNumber].push(win);

            _winners[winnerAddress] = GiveawayDate;
        }

        return;
    }

    function rand(address randomAddress, uint256 randomNo)
        internal
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp - randomNo) +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(randomAddress)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / maxSupply) * maxSupply)) + 1;
    }

    /*
    @function getRandomAddress()
    @description - Gets a random address
    @param <address> random address
    */
    function getRandomAddress() public view onlyOwner returns (address) {
        uint256 tokenId = rand(msg.sender, 0);
        return ownerOf(tokenId);
    }

    /*
    @function setGiveawayState()
    @description - Sets the Giveaway state to active/not active (true/false)
    @param <address> state - The Giveaway state
    */
    function setGiveawayState(bool state) public onlyOwner {
        giveawayActive = state;
    }

    /*
    @function setMaxSupply()
    @description - Sets the max supply that can be minted.
    */
    function setMaxSupply(uint256 amount) public onlyOwner {
        require(amount > maxSupply, "ERROR: Max supply is currently smaller than new supply");
        giveawayActive = false;
        maxSupply = amount;
    }

    /*
    @function removeFeesForAddress(addr)
    @description - Add an address to the freebie list
    @param <address> addr - The address to whitelist
    */
    function addToFreeList(address addr) public onlyOwner {
        require(!paused, "ERROR: Contract paused!");
        require(noFreeAddresses < 10, "ERROR: MAX number of free addresses added");
        FreeListAddresses[addr] = true;
        noFreeAddresses++;
    }

    /*
    @function setGiveawayIntervalDays(noDays)
    @description - Set the number of days between each Giveaway draw.
    @param <uint256> noDays - The number of days.
    */
    function setGiveawayIntervalDays(uint256 noDays) public onlyOwner {
        giveawayIntervalDays = noDays;
    }

    /*
    @function airDrop(to, amount)
    @description - Air drop an nft to address
    @param <address> to - The address to airdrop nft
    */
    function airDrop(address to) public onlyOwner {
        require(airDropActive, "ERROR: Air drop is not active");
        airDropAddresses.push(to);

        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        _safeMint(to, tokenId);
        _setTokenRoyalty(tokenId, royaltiesAddress, contractRoyalties);
        addressMints[to]++;
    }

    /*
    @function setAirDropStatus(value)
    @description - Sets the status of airdrop to true/false
    @param <bool> value - true/false
    */
    function setAirDropStatus(bool value) public onlyOwner {
        airDropActive = value;
    }

    /*
    @function getWinnersForDraw(drawNo)
    @description - Gets all the winners for a given draw
    */
    function getWinnersForDraw(uint256 drawNo)
        public
        view
        returns (Winner[] memory)
    {
        return winnerLog[drawNo];
    }

    /*
    @function clearWinnersForDraw(drawNo)
    @description - clears out all the winner logs for that draw. This is for when the array gets large!
    */
    function clearWinnersForDraw(uint256 drawNo) public onlyOwner {
        for (uint256 i = 0; i < 50; i++) {
            delete winnerLog[drawNo][i];
        }
    }

    /*
    @function burnToken()
    @description - Burn a token
    */
    function burnToken(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /*
    @function _beforeTokenTransfer()
    @description - Allows for the royalty claim to occur automatically on every transfer of NFT
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // do stuff before every transfer
        if (royaltiesAddress != address(0) && from != address(0) && !Address.isContract(from)) {
            RoyaltiesInterface(royaltiesAddress).claimCommunity(tokenId);
        }
    }
}