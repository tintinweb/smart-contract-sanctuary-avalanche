// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IDegisNFT} from "./interfaces/IDegisNFT.sol";
import {IVeDEG} from "./interfaces/IVeDEG.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    IDegisNFT public degisNFT;
    IVeDEG public veDEG;

    mapping(address => uint256) public userStaked;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event championReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    event Stake(address user, uint256 tokenId, uint256 boostType);
    event Unstake(address user, uint256 tokenId);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(address _degisNFT, address _veDEG) {
        degisNFT = IDegisNFT(_degisNFT);
        veDEG = IVeDEG(_veDEG);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set degis nft contract
     *
     * @param _degisNFT Degis nft address
     */
    function setDegisNFTContract(address _degisNFT) external onlyOwner {
        degisNFT = IDegisNFT(_degisNFT);
    }

    /**
     * @notice Set veDEG contract
     *
     * @param _veDEG VeDEG address
     */
    function setVeDEG(address _veDEG) external onlyOwner {
        veDEG = IVeDEG(_veDEG);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake NFT
     *
     * @param _tokenId Token id to stake
     */
    function stake(uint256 _tokenId) external {
        require(degisNFT.ownerOf(_tokenId) == msg.sender, "not owner of token");
        require(_tokenId != 0, "tokenId cannot be 0");

        require(userStaked[msg.sender] == 0, "already staked");

        degisNFT.approve(address(this), _tokenId);

        degisNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        userStaked[msg.sender] = _tokenId;

        // If token id > 99 normal boost
        // If token id <= 99 rare boost
        uint256 boostType = _tokenId > 99 ? 1 : 2;
        veDEG.boostVeDEG(msg.sender, boostType);

        emit Stake(msg.sender, _tokenId, boostType);
    }

    /**
     * @notice Withdraw NFT
     *
     * @param _tokenId Token id to withdraw
     */
    function withdraw(uint256 _tokenId) external {
        require(userStaked[msg.sender] == _tokenId, "not owner of token");

        degisNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        // Delete the record
        userStaked[msg.sender] = 0;

        // Unboost veDEG
        veDEG.unBoostVeDEG(msg.sender);

        emit Unstake(msg.sender, _tokenId);
    }

    /**
     * @notice Selector for receiving ERC721 tokens
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit championReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
pragma solidity ^0.8.13;

interface IDegisNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address _target, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVeDEG {
    function boostVeDEG(address _address, uint256 _multiplier) external;

    function unBoostVeDEG(address _address) external;
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