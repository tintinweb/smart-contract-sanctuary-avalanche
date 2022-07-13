pragma solidity 0.8.7;

import "Ownable.sol";

interface IDiamondStorage {
    function getUserInfo(address user)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}

contract DiamondAccounting is Ownable {
    mapping(address => bool) isBond;

    struct UserInformations {
        bool isRegistered;
        uint256 userJLPTotal;
        uint256 userJLPRemaining;
        uint256 userDiamondTier;
    }
    mapping(address => UserInformations) usersInformations;
    address public truthSource;
    address public jlp;

    constructor(address _truthSource, address _jlp) {
        truthSource = _truthSource;
        jlp = _jlp;
    }

    function registerBond(address _bond) public {
        isBond[_bond] = true;
    }

    modifier onlyBond() {
        require(isBond[msg.sender], "requires a bond");
        _;
    }

    function setDiamondTier(address _user, uint256 diamondTier) public onlyBond {
        UserInformations storage info = usersInformations[_user];
        require(info.isRegistered, "User is not registered");
        info.userDiamondTier = diamondTier;
    }

    function resetUser(address _user) public onlyBond {
        delete usersInformations[_user];
    }

    function lowerRemainingJLP(address _user, uint256 _amount) public onlyBond {
        UserInformations storage info = usersInformations[_user];
        if (info.isRegistered == false) {
            (
                bool isRegistered,
                uint256 userJLPTotal,
                uint256 userJLPRemaining,
                uint256 userDiamondTier
            ) = getUserInfo(_user);
            info.isRegistered = isRegistered;
            info.userDiamondTier = userDiamondTier;
            info.userJLPRemaining = userJLPRemaining;
            info.userJLPTotal = userJLPTotal;
        }

        require(info.isRegistered, "user not registered yet");
        require(info.userJLPRemaining >= _amount, "remaining JLP too low");
        info.userJLPRemaining -= _amount;
    }

    function setRemainingJLP(address _user, uint256 _amount) public onlyBond {
        UserInformations storage info = usersInformations[_user];
        if (info.isRegistered == false) {
            (
                bool isRegistered,
                uint256 userJLPTotal,
                uint256 userJLPRemaining,
                uint256 userDiamondTier
            ) = getUserInfo(_user);
            info.isRegistered = isRegistered;
            info.userDiamondTier = userDiamondTier;
            info.userJLPRemaining = userJLPRemaining;
            info.userJLPTotal = userJLPTotal;
        }

        require(info.isRegistered, "user not registered yet");
        info.userJLPRemaining = _amount;
    }

    function getUserInfo(address _address)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        UserInformations memory info = usersInformations[_address];
        if (info.isRegistered == false) {
            (bool isRegistered, uint256 userJLPTotal, uint256 userDiamondTier) = IDiamondStorage(
                truthSource
            ).getUserInfo(_address);
            return (isRegistered, userJLPTotal, userJLPTotal, userDiamondTier);
        } else {
            return (
                info.isRegistered,
                info.userJLPTotal,
                info.userJLPRemaining,
                info.userDiamondTier
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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