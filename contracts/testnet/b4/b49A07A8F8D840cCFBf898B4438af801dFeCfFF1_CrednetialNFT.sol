//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./BaseRelayRecipient.sol";

contract CrednetialNFT is ERC721URIStorage, Ownable, BaseRelayRecipient {
    using Counters for Counters.Counter;

    bool private transferable = false;

    mapping(string => bool) userMetaDataURIMinted;

    event MINT(uint256 indexed tokenId);
    event BURN(uint256 indexed tokenId);

    Counters.Counter private tokenIdTracker;

    constructor() ERC721("Credential NFT", "GNFT") {}

    /**
     * @dev A method to mint NFT
     * 		Same NFT Mint is allowed only once for the same user.
     * @param to : Address to be minted
     * 		_tokenURI: metadataURI for NFT
     */
    function mint(address to, string memory _tokenURI) external virtual {
        require(
            userMetaDataURIMinted[_tokenURI] == false,
            "Not allowed to mint than ONCE."
        );
        tokenIdTracker.increment();
        _mint(to, tokenIdTracker.current());
        _setTokenURI(tokenIdTracker.current(), _tokenURI);
        userMetaDataURIMinted[_tokenURI] = true;
        emit MINT(tokenIdTracker.current());
    }

    /**
     * @dev A method to burn NFT by holder of NFT
     * @param _tokenId: NFT Id to be burned
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId), "Requested to burn for nonexistent token");
        _burn(_tokenId);
        tokenIdTracker.decrement();
        emit BURN(_tokenId);
    }

    /**
     * @dev Override to make non-transferable for NFT
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        require(
            from == address(0) || to == address(0),
            "NonTransferrableERC721Token: non transferrable"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev method for setting the address of trusted forwarder
     */
    function setTrustedForwarder(address _forwarder) public onlyOwner {
        _setTrustedForwarder(_forwarder);
    }

    /**
     * @dev Override _msgSender() of BaseRelayRecipient
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, BaseRelayRecipient)
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    /**
     * @dev Override _msgData() of BaseRelayRecipient
     */
    function _msgData()
        internal
        view
        virtual
        override(Context, BaseRelayRecipient)
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}