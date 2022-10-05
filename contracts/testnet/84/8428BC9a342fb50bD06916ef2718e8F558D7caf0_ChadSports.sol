// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

  ________              __   _____                  __      
  / ____/ /_  ____ _____/ /  / ___/____  ____  _____/ /______
 / /   / __ \/ __ `/ __  /   \__ \/ __ \/ __ \/ ___/ __/ ___/
/ /___/ / / / /_/ / /_/ /   ___/ / /_/ / /_/ / /  / /_(__  ) 
\____/_/ /_/\__,_/\__,_/   /____/ .___/\____/_/   \__/____/  
                               /_/                           


*/

// OpenZeppelin
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./IERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./Utils.sol";

contract ChadSports is ERC1155, ERC1155Supply, IERC2981, Ownable {

    mapping(address=> mapping(uint => bool)) public nftOwner;

    struct discountState {
        bool isAuthorized;
        bool hasMint;
    }
    mapping(address => discountState) discountlist;

    address[] public nftPartners;

    function setNFTOwner(address _nftContract, uint _tokenID) public {
        require(!nftOwner[_nftContract][_tokenID], "");
        require(msg.sender == IERC721(_nftContract).ownerOf(_tokenID), "Not your NFT");
        require(Utils.indexOfAddresses(nftPartners, _nftContract) > -1, "");
        // nftOwner[_nftContract][_tokenID].owner = msg.sender;
        nftOwner[_nftContract][_tokenID] = true;
        discountlist[msg.sender].isAuthorized = true;
    }

    function addNftPartner(address _addrCollection) external onlyOwner {
        nftPartners.push(_addrCollection);
    }

    constructor() ERC1155("")
        {
        name = "TestCSQ";
        symbol = "TESTCSQ";
        _uriBase = "ipfs://QmQyoRPzJpceXmv3uApjam8hLYXwRgThvg8vQ4wdWX9p4M/"; // IPFS base for ParkPics collection

        mintPrice = 2 ether;
        // 20000000000000000
        discountMintPrice = 1 ether;
        // 10000000000000000

        mintBatchPrice = 8 ether;
        // 80000000000000000
        discountMintBatchPrice = 6 ether;
        // 60000000000000000

        mintRandomPrice = 1 ether;
        // 10000000000000000
        discountMintRandomPrice = 0.5 ether;
        // 5000000000000000

        mintBatchRandomPrice = 4 ether;
        // 40000000000000000
        discountMintBatchRandomPrice = 2 ether;
        // 20000000000000000
    }

    string public name;
    string public symbol;
    string public _uriBase;

    function setUriBase(string memory _newUriBase) external onlyOwner {
        _uriBase = _newUriBase;
    }

    /** @dev URI override for OpenSea traits compatibility. */

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
    }

    // V R F
    /** @dev Minting funtions. */

    function mint(uint256 id)
        public
        payable
        payableMint
    {
        _mint(msg.sender, id, 1, "");
    }

    function mintBatch(uint team1, uint team2, uint team3, uint team4)
        public payable payableMintBatch
    {
        uint[] memory ids = new uint[](4);
        ids[0] = team1;
        ids[1] = team2;
        ids[2] = team3;
        ids[3] = team4;

        uint[] memory amount = new uint[](4);
        amount[0] = 1;
        amount[1] = 1;
        amount[2] = 1;
        amount[3] = 1;

        _mintBatch(msg.sender, ids, amount, "");
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function withdrawEth(address _receiver) public payable onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }


    // R O Y A L T I E S
    /** @dev Royalties implementation. */

    address private _recipient;

    /**
     * @dev EIP2981 royalties implementation: set the recepient of the royalties fee to 'newRecepient'
     * Maintain flexibility to modify royalties recipient (could also add basis points).
     *
     * Requirements:
     *
     * - `newRecepient` cannot be the zero address.
     */

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties new recipient is the 0x address");
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 6) / 100);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    // M O D I F I E R S

    uint internal mintPrice;
    uint internal discountMintPrice;

    uint internal mintBatchPrice;
    uint internal discountMintBatchPrice;

    uint internal mintRandomPrice;
    uint internal discountMintRandomPrice;

    uint internal mintBatchRandomPrice;
    uint internal discountMintBatchRandomPrice;

    address private _addr;

    modifier payableMint {
        _;
        require(block.timestamp <= 1668952800);
        if(discountlist[msg.sender].isAuthorized){
            require(msg.value >= discountMintPrice/100);
        } else{
            require(msg.value >= mintPrice/100);
        }
    }

    modifier payableRandomMint {
        _;
        require(block.timestamp <= 1668952800);
        if(discountlist[msg.sender].isAuthorized){
            require(msg.value >= discountMintRandomPrice/100);
        } else{
            require(msg.value >= mintRandomPrice/100);
        }
    }

    modifier payableMintBatch {
        _;
        require(block.timestamp <= 1668952800);
        if(discountlist[msg.sender].isAuthorized){
            require(msg.value >= discountMintBatchPrice/100);
        } else{
            require(msg.value >= mintBatchPrice/100);
        }
    }

    modifier payableRandomMintBatch {
        _;
        require(block.timestamp <= 1668952800);
        if(discountlist[msg.sender].isAuthorized){
            require(msg.value >= discountMintBatchRandomPrice/100);
            
        } else{
            require(msg.value >= mintBatchRandomPrice/100);
        }
    }
}