/**
 *Submitted for verification at snowtrace.io on 2022-01-31
*/

// File: contracts/BM/interfaces/IContestStorage.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IContestStorage {
    function saveOrganizer(address organizer, address contest) external;
    function saveMemer(address memer, address contest) external;
    function saveScientist(address scientist, address contest) external;
    function checkIfContestExists(address contest) external returns (bool);
}
// File: contracts/BM/interfaces/IContestDeployer.sol

pragma solidity 0.8.4;

interface IContestDeployer {
    function createContest(address creator, uint256 voteCost, uint32 submissionStart, uint32 votingStart, uint32 votingEnd, 
                            string memory title, string memory encodedImage, bool hideImage, string memory publicKey) external returns (address);
}
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

// File: contracts/BM/ContestsFactory.sol

pragma solidity 0.8.4;




contract ContestsFactory is Ownable {
    address public contestStorage;
    address public contestDeployer;

    uint256 public contestCost;

    event onContestCreated(
        address indexed organizer,
        address contestContract
    );

    constructor(uint256 _contestCost) {
        contestCost = _contestCost;
    }

    function createContest(uint256 voteCost, uint32 submissionStart, 
                uint32 votingStart, uint32 votingEnd, string memory title, string memory encodedImage, bool hideImage, string memory publicKey) public payable{
        
        require(contestCost == msg.value, "Wrong amount of funds sent to create contest");
        
        address contestAddress = IContestDeployer(contestDeployer).createContest(msg.sender, voteCost, submissionStart, votingStart,
                 votingEnd, title, encodedImage, hideImage, publicKey);
                
        IContestStorage(contestStorage).saveOrganizer(msg.sender, contestAddress);

        if (msg.value > 0) {
            payable(contestAddress).transfer(msg.value);
        }
        
        emit onContestCreated(msg.sender, contestAddress);
    }
    
    function setStorageDeployer(address _contestStorage, address _contestDeployer) public onlyOwner {
        contestStorage = _contestStorage;
        contestDeployer = _contestDeployer;
    }

    function setStorage(address _contestStorage) public onlyOwner () {
        contestStorage = _contestStorage;
    }
    
    function setContestDeployer(address _contestDeployer) public onlyOwner () {
        contestDeployer = _contestDeployer;
    }

    function setContestCost(uint256 _contestCost) public onlyOwner () {
        contestCost = _contestCost;
    }
}