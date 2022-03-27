/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if(value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while(temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while(value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MarketNFT is Ownable {
    using Address for address;
    using Strings for uint256;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string public _baseURI;
    mapping(uint256 => string) private _tokenURIs;
    uint256 private lastId;

    constructor() {
        _name = "WOW Marketplace";
        _symbol = "WOW";
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        require(_owners[tokenId] != address(0), "owner query for nonexistent token");
        return _owners[tokenId];
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if(bytes(_baseURI).length == 0) {
            return _tokenURI;
        } else {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _baseURI = uri;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) external {
        require(to != _owners[tokenId], "approval to current owner");
        require(msg.sender == _owners[tokenId] || _operatorApprovals[_owners[tokenId]][msg.sender], "approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "transfer caller is not owner nor approved");
        
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "transfer caller is not owner nor approved");

        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "transfer to non ERC721Receiver implementer");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "operator query for nonexistent token");
        address owner = _owners[tokenId];
        return (spender == owner || _tokenApprovals[tokenId] == spender || _operatorApprovals[owner][spender]);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");

        _approve(address(0), tokenId);

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenId] = to;
        }
        
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data), "transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "token already minted");

        unchecked {
            _balances[to] += 1;
            _owners[tokenId] = to;
        }

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];

        _approve(address(0), tokenId);

        unchecked {
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];
        if(bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if(to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch(bytes memory reason) {
                if(reason.length == 0) {
                    revert("transfer to non ERC721Receiver implementer");
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

    function mint(string memory uri) external {
        unchecked {
            lastId += 1;
        }
        _safeMint(msg.sender, lastId);
        _setTokenURI(lastId, uri);
    }

    function mintBatch(string[] memory uris) external {
        for(uint256 i = 0; i < uris.length; i++) {
            unchecked {
                lastId += 1;
            }
            _safeMint(msg.sender, lastId);
            _setTokenURI(lastId, uris[i]);
        }
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}