// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

contract ClaimContract is Ownable {
    uint256 public tokensClaimed;
    uint256 public transactionCount;
    bool public active;

    struct Logs {
        uint256 txId;
        uint256 timeStamp;
        address user;
        uint256 avaxAmount;
        uint256 claimedTokens;
        address refAddress;
        uint256 refTokens;
    }

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public claimedTokens;
    mapping(address => uint256) public claimedAmount;
    mapping(uint256 => Logs) public logs;

    event LogUserAdded(address user);
    event LogUserRemoved(address user);
    event claimReset(uint256 reset);
    event LogClaim(
        uint256 txId,
        uint256 timeStamp,
        address indexed user,
        uint256 indexed avaxAmount,
        uint256 indexed claimedTokens,
        address refAddress,
        uint256 refTokens
    );

    constructor() {
        active = false;
    }

    modifier isActive() {
        require(active == true, "Claim Period has ended");
        _;
    }

    function addUser(address user) external onlyOwner {
        whitelisted[user] = true;
        emit LogUserAdded(user);
    }

    // Function to remove single user from Whitelist
    function removeUser(address user) external onlyOwner {
        whitelisted[user] = false;
        emit LogUserRemoved(user);
    }

    // Function to add multiple users to Whitelist
    function addManyUsers(address[] memory users) external onlyOwner {
        require(users.length < 1000);
        for (uint256 index = 0; index < users.length; index++) {
            whitelisted[users[index]] = true;
            emit LogUserAdded(users[index]);
        }
    }

    function activateContract() external onlyOwner {
        active = true;
    }

    function disableContract() external onlyOwner {
        active = false;
    }

    function isActivated() public view returns (bool) {
        return active;
    }

    function claimTokens(uint256 _avaxAmount) external isActive {
        uint256 amountToClaim = _avaxAmount / 1000;
        uint256 claimAmount;
        address from = msg.sender;
        require(
            whitelisted[from] == true,
            "You are not qualified for this claim"
        );
        require(claimedTokens[from] == false, "You have already withdrawn");
        if (amountToClaim >= 100) {
            claimAmount = 12500;
        } else if (amountToClaim < 100 && amountToClaim >= 10) {
            claimAmount = 5000;
        } else if (amountToClaim < 10 && amountToClaim >= 1) {
            claimAmount = 1000;
        } else if (amountToClaim < 1 && _avaxAmount > 0) {
            claimAmount = 250;
        } else {
            claimAmount = 0;
        }
        uint256 tokenAmount = (claimAmount * (10**18));
        require(tokenAmount > 0, "Token amount is 0, try a ref link");
        claimedAmount[from] = tokenAmount;
        tokensClaimed += tokenAmount;
        transactionCount++;
        claimedTokens[from] = true;
        logs[transactionCount] = Logs(
            transactionCount,
            block.timestamp,
            from,
            _avaxAmount,
            tokenAmount,
            address(this),
            0
        );
        emit LogClaim(
            transactionCount,
            block.timestamp,
            from,
            _avaxAmount,
            tokenAmount,
            address(this),
            0
        );
    }

    function claimRef(address _ref) external isActive {
        uint256 claimAmount = (50 * (10**18));
        address from = msg.sender;
        require(claimedTokens[from] == false, "You have already withdrawn");
        require(claimedTokens[_ref] == true, "Ref-Link invalid");
        uint256 refAmount = (10 * (10**18));
        uint256 totalTokensClaimed = claimAmount + refAmount;
        claimedAmount[from] = claimAmount;
        claimedAmount[_ref] = claimedAmount[_ref] + refAmount;
        tokensClaimed += totalTokensClaimed;
        transactionCount++;
        claimedTokens[from] = true;
        logs[transactionCount] = Logs(
            transactionCount,
            block.timestamp,
            from,
            0,
            claimAmount,
            _ref,
            refAmount
        );
        emit LogClaim(
            transactionCount,
            block.timestamp,
            from,
            0,
            claimAmount,
            _ref,
            refAmount
        );
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