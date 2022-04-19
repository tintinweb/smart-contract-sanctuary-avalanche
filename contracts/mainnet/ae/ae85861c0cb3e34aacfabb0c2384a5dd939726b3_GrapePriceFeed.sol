/**
 *Submitted for verification at snowtrace.io on 2022-04-19
*/

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


interface IOracle {
    function update() external;
    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);
    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

interface IPriceFeed {
    function latestAnswer() external view returns (int256);
    function latestRoundData() external view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract GrapePriceFeed is Ownable {

    IOracle public Oracle = IOracle(0x9dc20044B2485DCc312f28952122d9A91d14079b);
    IPriceFeed public PriceFeed = IPriceFeed(0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
    address public GRAPE = 0x5541D83EFaD1f281571B343977648B75d95cdAC2;

    function update() external {
        Oracle.update();
    }

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        return Oracle.consult(_token, _amountIn);
    }

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut) {
        return Oracle.twap(_token, _amountIn);
    }

    function latestMimPrice() external view returns (int256) {
        return PriceFeed.latestAnswer();
    }

    function latestRoundMimPrice() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return PriceFeed.latestRoundData();
    }

    function latestPrice() external view returns (uint256) {
        uint256 mimPrice = uint256(PriceFeed.latestAnswer());
        uint256 price = Oracle.consult(GRAPE, 1e18);
        return price * mimPrice;
    }

    function setOracle(address oracle) external onlyOwner {
        Oracle = IOracle(oracle);
    }

    function setPriceFeed(address priceFeed) external onlyOwner {
        PriceFeed = IPriceFeed(priceFeed);
    }

    function setGRAPE(address _grape) external onlyOwner {
        GRAPE = _grape;
    }

}