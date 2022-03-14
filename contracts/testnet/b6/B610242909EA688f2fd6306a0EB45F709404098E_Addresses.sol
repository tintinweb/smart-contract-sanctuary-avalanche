/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-13
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Addresses.sol



pragma solidity ^0.8.0;


contract Addresses is Ownable {
    address[] contracts;
    mapping(address => bool) verified;

    modifier exists(address contractAddr) {
        require(existingContract(contractAddr), "The contract does not exist");
        _;
    }

    modifier doesNotExist(address contractAddr) {
        require(!existingContract(contractAddr), "The contract already exists");
        _;
    }

    function existingContract(address contractAddr) public view returns (bool) {
        uint256 i;
        uint256 length = contracts.length;
        for (i = 0; i < length; ++i) {
            if (contracts[i] == contractAddr) {
                return true;
            }
        }
        return false;
    }

    function addContract(address contractAddr)
        external
        doesNotExist(contractAddr)
        onlyOwner
    {
        contracts.push(contractAddr);
    }

    function removeContract(address contractAddr)
        external
        exists(contractAddr)
        onlyOwner
    {
        uint256 i;
        uint256 length = contracts.length;
        for (i = 0; i < length; ++i) {
            if (contracts[i] == contractAddr) {
                break;
            }
        }
        require(i < length, "Not Found the Contract");
        contracts[i] = contracts[length - 1];
        contracts.pop();
        verified[contractAddr] = false;
    }

    function verify(address contractAddr)
        external
        exists(contractAddr)
        onlyOwner
    {
        require(
            verified[contractAddr] == false,
            "The contract is already verified"
        );
        verified[contractAddr] = true;
    }

    function getContracts() external view returns (address[] memory) {
        return contracts;
    }

    function getVerifiedContracts() external view returns (address[] memory) {
        address[] memory verifiedContracts;
        uint256 i;
        uint256 length = contracts.length;
        uint256 vlength = 0;
        for (i = 0; i < length; ++i) {
            if (verified[contracts[i]]) {
                verifiedContracts[vlength++] = contracts[i];
            }
        }
        return verifiedContracts;
    }

    function isVerified(address contractAddr) external view returns (bool) {
        return verified[contractAddr];
    }
}