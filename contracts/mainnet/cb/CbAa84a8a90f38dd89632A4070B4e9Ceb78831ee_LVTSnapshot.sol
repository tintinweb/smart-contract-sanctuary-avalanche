// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./library/Ownable.sol";

interface INodeReward {
    function _getNodeValueOf(address account) external view returns (uint256);
}

interface ILVT {
    function _isBlacklisted(address user) external view returns(bool);
}

contract LVTSnapshot is Ownable {
    address public constant NodeRewardManager = 0x3Cf1Dff7CCE2b7291456Bc2089b4bCB2AB5f311A;
    address public constant LVTContract = 0xff579d6259dEDcc80488c9b89d2820bCb5609160;

    mapping(address => bool) public blackList;

    constructor() {}

    function manageUser(address[] memory users, bool flag) external onlyOwner {
        require(users.length > 0);
        for(uint i = 0; i < users.length; i++) {
            blackList[users[i]] = flag;
        }
    }

    function getAmount(address user) external view returns(uint256 amount) {
        require(user != address(0));

        bool isBlacklisted = ILVT( LVTContract )._isBlacklisted(user);

        if(!isBlacklisted && !blackList[user]) {
            amount = INodeReward( NodeRewardManager )._getNodeValueOf(user);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../abstract/Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}