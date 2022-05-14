/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-13
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/CardGame.sol

pragma solidity ^0.8.0;

contract OxaGame is Ownable {
    struct CardSet {
        bool isDrawed;
        uint256 so1;
        uint256 chat1;
        uint256 so2;
        uint256 chat2;
        uint256 so3;
        uint256 chat3;
    }

    mapping (address => mapping( uint256 => CardSet)) public cardSets;
    string[13] public nos = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
    string[4] public attr = ["Co ", "Ro ", "Chuong ", "Bich "];
    uint256 public round;
    function draw() external {
        require(!cardSets[msg.sender][round].isDrawed, "You was drawed!");
        CardSet storage currentSet = cardSets[msg.sender][round];

        uint256 ranNum = _random();
        uint256 ranNo = randomInRange(ranNum, 13);
        uint256 ranAt = randomInRange(ranNo, 4);
        currentSet.so1 = ranNo;
        currentSet.chat1 = ranAt;
        // currentSet.card1 = append(nos[ranNo],"-",attr[ranAt]);
        currentSet.so2 = randomInRange(ranNo+ranAt, 13);
        currentSet.chat2 = randomInRange(ranNo+ranAt+currentSet.so2, 4);
        currentSet.so3 = randomInRange(ranNo+ranAt+currentSet.so2+currentSet.chat2, 13);
        currentSet.chat3 = randomInRange(ranNo+ranAt+currentSet.so2+currentSet.chat2+currentSet.so3, 4);
        currentSet.isDrawed = true;
    }

    function viewCard(address user) external view returns(string memory) {
        CardSet memory currentSet = cardSets[user][round];
        require(currentSet.isDrawed, "You was NOT drawed!");
        return append(append(nos[currentSet.so1], "-", attr[currentSet.chat1]), 
        append(nos[currentSet.so2], "-", attr[currentSet.chat2]), 
        append(nos[currentSet.so3], "-", attr[currentSet.chat3]));
    }

    function setNewRound() external onlyOwner {
        round += 1;
    }

    function randomInRange(uint256 seed, uint256 range) internal view returns (uint256 ) {
        uint256 rnd = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, gasleft(), msg.sender, seed, range)));
        return rnd%range;
    }

    function _random() internal view returns (uint256 ) {
        uint256 rnd = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, gasleft(), msg.sender)));
        return rnd;
    }

    //AUX
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
}