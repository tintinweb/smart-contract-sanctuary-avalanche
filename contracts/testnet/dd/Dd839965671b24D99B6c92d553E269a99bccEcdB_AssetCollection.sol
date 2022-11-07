/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IAssetCollection {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function name() external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);

    function tokensOf(address tokenHolder)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mint(address tokenHolder, string memory tokenURI) external;

    function burn(address tokenHolder, uint256 tokenId) external;

    function transfer(uint256 tokenId) external;

    function transferFrom(
        address tokenHolder,
        address to,
        uint256 tokenId
    ) external;
}

interface IOwnable {
    event TransferOwnership(address indexed from, address indexed to);

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
}


contract AssetCollection is IAssetCollection, IOwnable {
    // Token ID counter
    uint256 private _tokenIds;

    // Owner of the smart-contract
    address private _owner;

    // Name of the asset collection
    string private _name;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to token URI
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory __name) {
        _name = __name;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _setTokenURI(uint tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        // Check that tokenId was not minted
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address tokenOwner = ownerOf(tokenId);
        _balances[tokenOwner] -= 1;

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    // Creates token
    function mint(address tokenHolder, string memory _tokenURI)
        public
        onlyOwner
    {
        uint256 tokenId = _tokenIds;
        _tokenIds += 1;
        _setTokenURI(tokenId, _tokenURI);
        _mint(tokenHolder, tokenId);
    }

    // Destroys token
    function burn(address tokenHolder, uint256 tokenId) public onlyOwner {
        _mint(tokenHolder, tokenId);
    }

    // Transfer the token back to the DAO
    function transfer(uint256 tokenId) public {
        _transfer(msg.sender, _owner, tokenId);
    }

    // Moves a token from one user to another
    function transferFrom(
        address tokenHolder,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        _transfer(tokenHolder, to, tokenId);
    }

    // Returns how many tokens a user owns
    function balanceOf(address tokenOwner) public view returns (uint256) {
        require(
            tokenOwner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[tokenOwner];
    }

    // Returns how many tokens a user owns
    function tokensOf(address tokenOwner)
        public
        view
        returns (uint256[] memory)
    {
        require(
            tokenOwner != address(0),
            "ERC721: address zero is not a valid owner"
        );

        uint256 balance = balanceOf(tokenOwner);
        uint256[] memory tokens = new uint[](balance);
        uint256 index = 0;

        for (uint id = 0; id < _tokenIds; id++) {
            if (_owners[id] == tokenOwner) {
                tokens[index] = id;
                index += 1;
            }
        }

        return tokens;
    }

    // Returns the token URI of the token
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721: token hasn't been minted");
        return _tokenURIs[_tokenIds];
    }

    // Returns the owner of the token
    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "ERC721: invalid token ID");
        return tokenOwner;
    }

    // Transfers the ownership of the smart-contract
    function transferOwnership(address _newOwner) public {
        require(msg.sender == _owner, "Ownable: Caller is not owner");
        require(
            _newOwner == address(0),
            "Ownable: New owner can not be the zero address"
        );

        address olOwner = _owner;
        _owner = _newOwner;
        emit TransferOwnership(olOwner, _newOwner);
    }

    // Returns name of the collection
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns owner of the smart-contract
    function owner() public view returns (address) {
        return _owner;
    }
}