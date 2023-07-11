// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


interface IMintBurn721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address account, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract Administrable {
    address public admin;
    address public pendingAdmin;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

abstract contract ERC721Gateway is Administrable {
    address public token;
    uint256 public swapoutSeq;
    mapping(uint256 => address) internal peer;

    constructor (address token_) {
        setAdmin(msg.sender);
        token = token_;
    }

    event SetPeers(uint256[] chainIDs, address[] peers);

    function setPeers(uint256[] memory chainIDs, address[] memory  peers) public onlyAdmin {
        for (uint i = 0; i < chainIDs.length; i++) {
            peer[chainIDs[i]] = peers[i];
            emit SetPeers(chainIDs, peers);
        }
    }

    function getPeer(uint256 foreignChainID) external view returns (address) {
        return peer[foreignChainID];
    }
}


contract ERC721GatewayDestination is ERC721Gateway {
    constructor(address token_) ERC721Gateway(token_){}

    function Swapin(uint256 tokenId, address receiver ) onlyAdmin public returns (bool) {
        try IMintBurn721(token).mint(receiver, tokenId) {
            return true;
        } catch {
            return false;
        }
    }
}