// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract GameBoyz is Ownable, ERC721Holder {

    address public levelUp;
    uint[] levelUpBalance;

    constructor(address _levelUp) {
        levelUp = _levelUp;
    }

    /*
    * @notice Buy levelup NFT
    * @param uint256 amount : amount of level up to buy
    */
    function buyLevelUp(uint256 amount) public payable {
        require(levelUp != address(0), "LevelUp contract not set.");
        require(amount > 0, "Amount must be greater than 0.");
        require(amount <= 10, "Amount must be less than 10.");
        require(levelUpBalance.length >= amount, "Not enough LevelUp to sell.");
        require(msg.value >= getPrice(amount), "Insufficient funds.");

        for (uint i = 0; i < amount; i++) {
            uint tokenId = random(levelUpBalance.length);
            IERC721(levelUp).transferFrom(address(this), msg.sender, levelUpBalance[tokenId]);
            _removeTokenId(levelUpBalance[tokenId]);
        }
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        address contractAddress = bytesToAddress(data);
        require(contractAddress != address(0), "Invalid transfer.");

        if (contractAddress == levelUp) {
            levelUpBalance.push(tokenId);
        }

        return this.onERC721Received.selector;
    }

    /*
    * @notice Internal function to remove tokenID from levelUpBalance list
    * @param uint _tokenId : Token ID
    */
    function _removeTokenId(uint tokenId) internal {
        uint indexToRemove;
        bool indexFound = false;

        for (uint i = 0; i < levelUpBalance.length; i++) {
            if (levelUpBalance[i] == tokenId) {
                indexToRemove = i;
                indexFound = true;
                break;
            }
        }

        if (!indexFound) {
            revert("Token ID not found");
        }

        levelUpBalance[indexToRemove] = levelUpBalance[levelUpBalance.length - 1];
        levelUpBalance.pop();
    }

    /*
    * @notice Returns the price of the amount of levelUp to buy.
    * @return uint256 : amount
    */
    function getPrice(uint256 amount) public pure returns (uint256) {
        return 2 ether * amount - (0.1 ether * ((amount * amount - amount) / 2));
    }

    /*
    * @notice Returns the list of LevelUp IDs of this contract.
    * @return uint256[] : List of tokenIds.
    */
    function getLevelUpBalance() public view returns (uint256[] memory) {
        return levelUpBalance;
    }

    /*
    * @notice Get random number from 0 to num.
    * @param uint256 num : max number
    * @return uint256 : random number
    */
    function random(uint num) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % num;
    }

    /*
    * @notice Withdraw AVAX from contract.
    */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
    * @notice Admin function to recover ERC721 assets on this contract by address
    * @param address contractAddresses : contract addresses
    * @param address toAddress : addresses to send assets
    * @param uint256[][] calldata tokenIds : array of array of token IDs (use for ERC1155, set 0 for ERC20/ERC721)
    */
    function adminWithdrawERC721 (
        address contractAddress,
        address toAddress,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(contractAddress).transferFrom(address(this), toAddress, tokenIds[i]);
        }
    }

    /*
    * @notice convert bytes to address
    * @param bytes memory bytesAddress : bytes to convert
    * @return address : address
    */
    function bytesToAddress(bytes memory bytesAddress) private pure returns (address addr) {
        assembly {
            addr := mload(add(bytesAddress,20))
        }
        return addr;
    }
}

// @notice "ERC721" interface is used to interact with the token contract
interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}