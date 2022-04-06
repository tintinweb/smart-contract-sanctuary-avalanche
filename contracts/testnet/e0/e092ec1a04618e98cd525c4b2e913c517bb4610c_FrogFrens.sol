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

    string baseURI; 
    string public baseExtension = ".json";
    uint256 public whitelistCost = 1 ether;
    uint256 public publicCost = 1.5 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxMintPerTx = 5;
    uint256 public maxMintsPerAddress = 10;
    uint256 private noFreeAddresses = 0;
    uint256 private contractRoyalties = 300; // Decided by community vote on Discord
    address public royaltiesAddress; 
    bool public contractPaused = true;
    bool public airdropActive = false;
    bool public publicSaleActive = false;
    bool public metadataLocked; // Metadata lock
    address[] private airdropAddresses;

    mapping(address => bool) public whitelistAddresses;
    mapping(address => uint256) public addressMints;

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
    @function pauseContract(_state)
    @description - Allows the contract to be paused.
    @param <bool> _state - true/false
  */
    function pauseContract(bool _state) public onlyOwner {
        contractPaused = _state;
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
    @function lockMetadata()
    @description - Lock metadata for the eternity!
    */
	function lockMetadata() external onlyOwner {
		metadataLocked = true;
	}

    /*
    @function setAirdropStatus(value)
    @description - Sets the status of airdrop to true/false
    @param <bool> value - true/false
    */
    function setAirdropStatus(bool value) public onlyOwner {
        airdropActive = value;
    }

    /*
    @function setPublicSaleActive(value)
    @description - Sets the status of public sale
    @param <bool> value - true/false
    */
    function setPublicSaleActive(bool value) public onlyOwner {
        publicSaleActive = value;
    }

    /*
    @function addWhitelistAddress()
    @description - Add an address to the whitelist.
   */
    function addWhitelistAddress(address addr) external onlyOwner {
        whitelistAddresses[addr] = true;
    }

    /*
    @function addWhitelistBatch(address[])
    @description - Add whitelist addresses in batch.
   */
    function addWhitelistBatch(address[] memory addr) public onlyOwner { 
  
        for(uint i=0; i< addr.length; i++){  
            whitelistAddresses[addr[i]] = true;  
        }
    }

    /*
    @function setMaxSupply()
    @description - Sets the max supply that can be minted.
    */
    function setMaxSupply(uint256 amount) public onlyOwner {
        require(amount > maxSupply, "ERROR: You cannot decrease the max supply");
        maxSupply = amount;
    }

    /*
    @function setWhitelistCost(_newCost)
    @description - Sets the whitelist cost of a single NFT
    @param <uint256> _newCost - The new cost of a single NFT
   */
    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    /*
    @function setPublicCost(_newCost)
    @description - Sets the public cost of a single NFT
    @param <uint256> _newCost - The new cost of a single NFT
   */
    function setPublicCost(uint256 _newCost) public onlyOwner {
        publicCost = _newCost;
    }

    /*
    @function setRoyaltiesAddress(address) 
    @description - Sets royalties address for the NFTs
    @param <addr> _newRoyaltiesAddress - Address of the FrogFrensRoyalties Contract
   */
    function setRoyaltiesAddress(address _newRoyaltiesAddress) public onlyOwner {
        royaltiesAddress = _newRoyaltiesAddress;
    }

    /*
    @function setMaxMintPerTx
    @description - Set the max mintable per TX
    @param <uint256> amount - The mintible limit per TX
  */
    function setMaxMintPerTx(uint256 amount) public onlyOwner {
        maxMintPerTx = amount;
    }

    /*
    @function setMaxMintPerAddress
    @description - Set the max mintable per address
    @param <uint256> amount - The mintible limit per adddress
  */
    function setMaxMintPerAddress(uint256 amount) public onlyOwner {
        maxMintsPerAddress = amount;
    }

    /*
    @function setBaseURI(_newBaseURI)
    @description - Sets the base URI for the metadata files
    @param <string> _newBaseURI - The new base URI for the metadata files
  */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(!metadataLocked, "Metadata locked forever!");
        baseURI = _newBaseURI;
    }

    /*
    @function setBaseExtension(_newBaseExtension)
    @description - Sets the extension for the metadata file (default .json)
    @param <string> _newBaseExtension - The new file extension to use.
  */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /*
    @function mint(_mintAmount)
    @description - Mints a token.
    @param <uint256> _mintAmount - The number of NFTs to mint.
   */
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerCanMintCount = maxMintsPerAddress - addressMints[msg.sender];
        require(ownerCanMintCount >= _mintAmount, "Sorry fren, you have reached your Frog Frens limit.");
        require(!contractPaused, "Sorry fren, contract is paused. Please check https://dsc.gg/frogfrens");
        require(_mintAmount <= maxMintPerTx, "Sorry fren, you have breached the max number of mints per transaction.");       
        require(supply + _mintAmount <= maxSupply, "Sorry fren, all our Frog Frens are now minted!");

        if (!publicSaleActive) {
            if (whitelistAddresses[msg.sender]) {
                require(msg.value >= whitelistCost * _mintAmount, "Sorry fren, you need more AVAX to mint WL!");
            } else {
                require(whitelistAddresses[msg.sender], "Sorry fren, only whitelist addresses can mint!");        
            }   
        }
        
        if (publicSaleActive) {
            if (whitelistAddresses[msg.sender]) {
                require(msg.value >= whitelistCost * _mintAmount, "Sorry fren, you need more AVAX to mint WL!");
            } else {
                require(msg.value >= publicCost * _mintAmount, "Sorry fren, you need more AVAX to mint public!");         
            }   
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(msg.sender, tokenId);
            _setTokenRoyalty(tokenId, royaltiesAddress, contractRoyalties);

            addressMints[msg.sender]++;

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

    /*
    @function _mintReserveTokens() internal
    @description - Internal function used by reserveNFT() to mint reserve tokens
   */
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
    @function getTokensForAddress(_owner)
    @description - Gets the list of NFT tokenIds that owner has.
  */
    function getTokensForAddress(address _owner)
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
    @function tokenURI(tokenId)
    @description - Gets the metadata URI for tokenId
    @param <uint256> tokenId - The id of the NFT token
    @returns <string> - The URI of the NFT metadata file
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
    @function getRoyaltiesAddress() 
    @description - Gets the royalties address for the NFTs
   */
    function getRoyaltiesAddress() public view returns (address) {
        return royaltiesAddress;
    }

    /*
    @function rand()
    @description - Generates a random tokenID from within the maxSupply
    */
    function rand(address randomAddress, uint256 randomNo) internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked((block.timestamp - randomNo) + block.difficulty +((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(randomAddress)))) / (block.timestamp)) + block.number)));
        return (seed - ((seed / maxSupply) * maxSupply)) + 1;
    }

    /*
    @function getRandomAddress()
    @description - Gets a random address using rand function
    @param <address> random address holding tokenID
    */
    function getRandomAddress() public view onlyOwner returns (address) {
        uint256 tokenId = rand(msg.sender, 0);
        return ownerOf(tokenId);
    }

    /*
    @function airdrop(to, amount)
    @description - Airdrop an nft to address
    @param <address> to - The address to airdrop the NFT to
    */
    function airdrop(address to) public onlyOwner {
        require(airdropActive, "ERROR: Air drop is not active");
        airdropAddresses.push(to);

        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        _safeMint(to, tokenId);
        _setTokenRoyalty(tokenId, royaltiesAddress, contractRoyalties);
        addressMints[to]++;
    }

    /*
    @function withdrawBalance()
    @description - Withdraw AVAX balance from contract to owner
    */
    function withdrawBalance() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    /*
    @function burnToken(tokenId)
    @description - Burn a tokenId 
    @param <uint256> tokenId - tokenId to burn
    */
    function burnToken(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        ERC721.transferFrom(msg.sender, address(0xdead), tokenId);
    }

    /*
    @function bulkBurn(tokenId)
    @description - Bulk burn a tokenIds
    @param <uint256> tokenId - tokenIds to burn
    */
    function bulkBurn(uint256[] memory tokenId) external onlyOwner {
        for (uint256 i = 0; i < tokenId.length; i++) {  
            ERC721.transferFrom(owner(), address(0xdead), tokenId[i]);
        }
    }

    // reclaim stuck ERC20 tokens in contract
	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

    // reclaim stuck ERC721 tokens in contract
	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
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