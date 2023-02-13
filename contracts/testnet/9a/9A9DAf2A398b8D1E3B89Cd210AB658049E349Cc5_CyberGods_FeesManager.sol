/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-11
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/CyberGods_FeesManager.sol


pragma solidity ^0.8.4;


contract CyberGods_FeesManager is Ownable {
    // addresses
    address public gamePoolAddress;
    address public treasuryAddress;
    address public teamAddress;

    // Fees
    uint256 public treasuryFee = 30;
    uint256 public teamFee = 8;
    uint256 public burntFee = 2; // TBH to put this to treasury / team instead

    // Trackers
    uint256 public totalSentTreasury;
    uint256 public totalSentTeam;
    uint256 public totalBurnt;

    receive() external payable {}

    // Setters
    function setTreasuryFee(uint256 _fee) external onlyOwner {
        treasuryFee = _fee;
    }

    function setTeamFee(uint256 _fee) external onlyOwner {
        teamFee = _fee;
    }

    function setBurntFee(uint256 _fee) external onlyOwner {
        burntFee = _fee;
    }

    function setTreasuryAddress(address _address) external onlyOwner {
        treasuryAddress = payable(_address);
    }

    function setTeamAddress(address _address) external onlyOwner {
        teamAddress = payable(_address);
    }

    function adminEmergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function splitAvax() external onlyOwner {
        uint256 treasuryAmount = 0;
        if (treasuryFee > 0) {
            treasuryAmount = (address(this).balance * treasuryFee) / 100;
        }
        uint256 teamAmount = 0;
        if (teamFee > 0) {
            teamAmount = (address(this).balance * teamFee) / 100;
        }
        uint256 burntAmount = 0;
        if (burntFee > 0) {
            burntAmount = (address(this).balance * burntFee) / 100;
        }

        payable(treasuryAddress).transfer(treasuryAmount); // Split for the treasury
        payable(teamAddress).transfer(teamAmount); // Split for the team
        payable(address(0)).transfer(burntAmount); // Burn the rest

        totalSentTreasury += treasuryAmount;
        totalSentTeam += teamAmount;
        totalBurnt += burntAmount;
    }
}