/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: contracts/CyberGods_Game.sol


pragma solidity >=0.7.0 <0.9.0;



interface ICyberGods_Cyborgs {
     function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool);

     function ownerOf(uint256 tokenId) external view returns (address);
}

contract CyberGods_Game is Ownable, Pausable {
    // Mappings
    mapping(uint256 => address) public stakedCyborgs; // tokenId => owner
    mapping(address => uint256[2]) public numberOfStaked; // address => [number of Cyborgs, number of second tier]

    // Contracts
    ICyberGods_Cyborgs public cyborgsContract;

    // Constants
    uint256 public CYBORGS_INDEX = 0;

    constructor(ICyberGods_Cyborgs _cyborgsContract) {
        cyborgsContract = _cyborgsContract;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setCyborgContract(ICyberGods_Cyborgs _cyborgsContract) external onlyOwner {
        cyborgsContract = _cyborgsContract;
    }

    function unstakeNFTs(
        uint256[] calldata _cyborgsIds//,uint256[] calldata _tiers2Ids
    ) public {
        address owner = msg.sender;

        require(
            numberOfStaked[owner][CYBORGS_INDEX] >= _cyborgsIds.length,
            "[Cyborgs]: You don't own that many Cyborgs."
        );

        uint256 cyborgsLength = _cyborgsIds.length;

        for (uint256 i = 0; i < cyborgsLength; i++) {
            //unstake Cyborgs
            uint256 nftId = _cyborgsIds[i];

            require(stakedCyborgs[nftId] == owner, "You don't own this token");
            numberOfStaked[owner][CYBORGS_INDEX]--;
            delete stakedCyborgs[nftId];
            cyborgsContract.transferFrom(address(this), owner, nftId);
        }
        // _updateAttackPowerForUser(owner);
    }

    /**
     * This function updates stake NFTs
     */
    function stakeNFTs(
        uint256[] calldata _cyborgsIds//,
        //uint256[] calldata _tiers2Ids
    ) public whenNotPaused {
        address owner = msg.sender;

        uint256 cyborgsLength = _cyborgsIds.length;
        for (uint256 i = 0; i < cyborgsLength; i++) {
            //stakes Cyborgs
            uint256 nftId = _cyborgsIds[i];

            require(
                cyborgsContract.ownerOf(nftId) == owner,
                "You don't own this token"
            );

            numberOfStaked[owner][CYBORGS_INDEX]++;
            stakedCyborgs[nftId] = owner;
            cyborgsContract.transferFrom(owner, address(this), nftId);
        }
        // _updateAttackPowerForUser(owner);
    }
}