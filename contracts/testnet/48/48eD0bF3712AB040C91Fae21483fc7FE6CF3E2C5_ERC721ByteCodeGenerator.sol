/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

}

interface ProxyGenerator {
    function generate(
        address _owner
    ) external returns(bytes memory byteCode);
}

contract ERC721Token {

    string public tokenName;
    string public tokenSymbol;
    string public tokenDesc;

    address private immutable proxy;

    address public immutable ownerAddress;
    uint internal tokenTotalCount = 1;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Mint(address indexed minter, uint tokenId, uint time);

    struct Data {
        string URI; // IPFS Hash
        string tokenImage; // IPFS Hash
    }

    // from tokenId to token full info
    mapping (uint256 => Data) private tokenData;
    // from tokenId to owner address
    mapping (uint256 => address) private balance;
    // from address to owned tokens count
    mapping (address => uint256) private ownedCount;
    // from owner to approvalAll addresss
    mapping (address => mapping (address => bool)) private operatorApproval;
    // from owner to singleApprove addresses
    mapping (uint256 => address) private approval;
    // from owner address to ownedd tokens
    mapping (address => uint256[]) private ownedTokens; // [2] ---> tokenId == 2
    // from owner address to token index in UP mapping
    mapping (address => mapping (uint256 => uint256)) private tokenIndex;
 
    constructor(string memory _name, string memory _symbol, string memory _desc, address _owner, address _proxyGen) {
        require(
            bytes(_name).length > 0 &&
            bytes(_symbol).length > 0 &&
            bytes(_desc).length > 0,
            "invalid strings."
        );

        tokenName = _name;
        tokenSymbol = _symbol;
        ownerAddress = _owner;
        tokenDesc = _desc;

        bytes memory byteCode = ProxyGenerator(_proxyGen).generate(_owner);
        address addr;
        assembly {
            addr := create(callvalue(), add(byteCode, 0x20), mload(byteCode))
        }
        require(addr != address(0), "invalid deployed address");
        proxy = addr;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "only owner");
        _;
    }

    function updateMetadata(
        string calldata _name,
        string calldata _symbol,
        string calldata _desc
    ) external onlyOwner {
        require(
            bytes(_name).length > 0 &&
            bytes(_symbol).length > 0 &&
            bytes(_desc).length > 0,
            "invalid strings."
        );

        (bool result, ) = proxy.delegatecall(
            abi.encodeWithSignature("updateData(string,string,string,address)", _name, _symbol, _desc, address(this))
        );
        require(result == true, "cannot update metadata");
    }

    function balanceOf(address _addr) public view returns(uint) {
        require(_addr != address(0), "Address Zero Error.");

        return ownedCount[_addr];
    }

    function proxyContractAddr() external view returns(address) {
        return proxy;
    }

    function ownerOf(uint256 _tokenId) public view returns(address) {
        require(_tokenId != 0 && _tokenId < tokenTotalCount && _tokenId >= 1, "Invalid Token Id.");

        return balance[_tokenId];
    }

    function name() public view returns(string memory) {
        return tokenName;
    }

    function symbol() public view returns(string memory) {
        return tokenSymbol;
    }

    function tokenURI(uint256 _tokenId) public view returns(string memory) {
        require(_tokenId != 0 && _tokenId < tokenTotalCount && _tokenId >= 1, "Invalid Token Id.");

        return tokenData[_tokenId].URI;
    }

    function approve(address _to, uint256 _tokenId) public payable {
        require(ownerOf(_tokenId) == msg.sender || operatorApproval[ownerOf(_tokenId)][msg.sender], "You Are Not Owner Nor Valid Operator Of This NFT.");
        require(_to != address(0) && _to != msg.sender, "Invalid To Address.");
        require(_tokenId != 0 && _tokenId < tokenTotalCount && _tokenId >= 1, "Invalid Token Id.");

        approval[_tokenId] = _to;

        emit Approval(msg.sender, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns(address) {
        require(_tokenId != 0 && _tokenId < tokenTotalCount && _tokenId >= 1, "Invalid Token Id.");

        return approval[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != address(0) && _operator != msg.sender, "Invalid Operator Address.");
        
        operatorApproval[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(_from != address(0) && _to != address(0) && _from != _to, "Invalid Address Entered!");
        require(_tokenId != 0 && _tokenId < tokenTotalCount && _tokenId >= 1, "Invalid Token Id.");
        require(ownerOf(_tokenId) == msg.sender || getApproved(_tokenId) == msg.sender || isApprovedForAll(ownerOf(_tokenId), msg.sender), unicode"Invalid Access Denied! 🚫");

        ownedCount[_from] -= 1;
        ownedCount[_to] += 1;

        delete ownedTokens[_from][tokenIndex[_from][_tokenId]];
        ownedTokens[_to].push(_tokenId);
        tokenIndex[_to][ownedTokens[_to].length - 1];

        balance[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable {
        transferFrom(_from, _to, _tokenId);

        require(_checkOnERC721Received(_from, _to, _tokenId, data), "Receiver Contract Doesn't Properly Impelement The ERC721Receiver.");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function mint(string calldata _uri, string calldata _img) external {
        require(msg.sender == ownerAddress, "Only Owner Can Access To This Function.");
        require(bytes(_uri).length > 0 && bytes(_img).length > 0, "Invalid String Entered.");

        Data memory newToken = Data({
            URI: _uri,
            tokenImage: _img
        });

        tokenData[tokenTotalCount] = newToken;

        tokenTotalCount += 1;

        ownedCount[msg.sender] += 1;
        balance[tokenTotalCount - 1] = msg.sender;
        ownedTokens[msg.sender].push(tokenTotalCount - 1);
        tokenIndex[msg.sender][tokenTotalCount - 1] = ownedTokens[msg.sender].length - 1;

        emit Mint(msg.sender, tokenTotalCount - 1, block.timestamp);
    }

    function total() external view returns(uint) {
        return tokenTotalCount - 1;
    } 

    function supportInterface(bytes4 _interfaceId) public pure returns(bool) { // ERC165
        return 
        _interfaceId == 0x80ac58cd || // IERC721 InterfaceId (bytes4)
        _interfaceId == 0x5b5e139f    // IERC721Metadata InterfaceId (bytes4)
        ;
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
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

}
///////////////////////////////////
contract ERC721ByteCodeGenerator {

    event ERC721ContractCreation(address indexed creator, string name, string symbol, string desc);

    function generate(
        string memory _name,
        string memory _symbol,
        string memory _desc,
        address owner,
        address _proxyGen
    ) external returns(bytes memory byteCode) {
        byteCode = abi.encodePacked(type(ERC721Token).creationCode, abi.encode(_name, _symbol, _desc, owner, _proxyGen));

        emit ERC721ContractCreation({
            creator: owner,
            name: _name,
            symbol: _symbol,
            desc: _desc
        });
    }

}