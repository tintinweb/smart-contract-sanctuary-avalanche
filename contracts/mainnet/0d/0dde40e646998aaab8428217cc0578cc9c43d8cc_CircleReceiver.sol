/**
 *Submitted for verification at snowtrace.io on 2022-12-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}
pragma solidity 0.8.14;

interface ICircle {
    function burn(uint amount) external;
}

interface ICircleDrip {
    function trigger() external;
}

interface IXCircle {
    function mint(uint256 amountCircle) external;
}

contract CircleReceiver is Ownable {

    // Circle Token Address
    address public constant circle = 0xaba658AB5FFA292e3DF464dE5cB141c7de83DB6D;
    address public constant xCircle = 0x6FC352270c3e15154F9AEBCE3e44c51524d1E0d8;

    // Circle prizePool
    address public ticketReceiver = 0xf14Bb7aB18F0c8653A7Df5158B4F3507DcC9b6D6;

    // Farm Token
    address public circleDrip = 0x3C0A8621a50C479A3beC59a8f7FA2f313c14eEbe;

    // Amount To Burn
    uint256 public toBurn = 25;
    uint256 public toPrizePool = 10;


    function setCircleDrip(address circleDrip_) external onlyOwner {
        require(
            circleDrip_ != address(0),
            'Zero Address'
        );
        circleDrip = circleDrip_;
    }

    function setTicketReceiver(address ticketReceiver_) external onlyOwner {
        require(
            ticketReceiver_ != address(0),
            'Zero Address'
        );
        ticketReceiver = ticketReceiver_;
    }

    function setBurnAllocation(uint toBurn_) external onlyOwner {
        require(
            toBurn_ <= 100,
            'ToBurn Too High'
        );
        toBurn = toBurn_;
    }

    function setPrizePoolAllocation(uint forPrizePool_) external onlyOwner {
        require(
            forPrizePool_ <= 100,
            'ToBurn Too High'
        );
        toPrizePool = forPrizePool_;
    }

    function trigger() external {

        // fetch balance
        uint balance = IERC20(circle).balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        // split up amount to burn and reward
        uint amountToBurn = ( balance * toBurn ) / 100;
        uint amountForPrizePool = ( balance * toPrizePool ) / 100;

        // add to prizePool
        if (amountForPrizePool > 0) {
            // send amount to ticket receiver
            IERC20(circle).transfer(ticketReceiver, amountForPrizePool);
        }

        // burn amount
        if (amountToBurn > 0) {
            ICircle(circle).burn(amountToBurn);
        }

        // amount to reward
        uint toReward = IERC20(circle).balanceOf(address(this));

        // reward amount
        if (toReward > 0) {
            IERC20(circle).transfer(circleDrip, toReward);
        }

        // trigger farm distributor
        ICircleDrip(circleDrip).trigger();
    }
}