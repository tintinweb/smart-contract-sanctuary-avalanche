// File: interfaces/IPangolinRouter.sol

pragma solidity >=0.6.2;

interface IPangolinRouter {
        function factory() external pure returns (address);
        function WAVAX() external pure returns (address);

        function addLiquidity(
            address tokenA,
            address tokenB,
            uint amountADesired,
            uint amountBDesired,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity);
        function addLiquidityAVAX(
            address token,
            uint amountTokenDesired,
            uint amountTokenMin,
            uint amountAVAXMin,
            address to,
            uint deadline
        ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
        function removeLiquidity(
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
        ) external returns (uint amountA, uint amountB);
        function removeLiquidityAVAX(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountAVAXMin,
            address to,
            uint deadline
        ) external returns (uint amountToken, uint amountAVAX);
        function removeLiquidityWithPermit(
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountA, uint amountB);
        function removeLiquidityAVAXWithPermit(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountAVAXMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountToken, uint amountAVAX);
        function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
        function swapTokensForExactTokens(
            uint amountOut,
            uint amountInMax,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
        function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
            external
            payable
            returns (uint[] memory amounts);
        function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
            external
            returns (uint[] memory amounts);
        function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
            external
            returns (uint[] memory amounts);
        function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
            external
            payable
            returns (uint[] memory amounts);

        function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
        function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
        function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
        function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

        function removeLiquidityAVAXSupportingFeeOnTransferTokens(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountAVAXMin,
            address to,
            uint deadline
        ) external returns (uint amountAVAX);
        function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountAVAXMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountAVAX);

        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
        function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable;
        function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
}

pragma solidity ^0.8.0;

interface INodeManager {
    function isNodeOwner(address account) external view returns (bool);
    function getTotalNodes() external view returns (uint256);
    function getAllNodesRewards(address account) external view returns (uint256);
    function createNode(address account, string memory nodeName, uint256 amount) external;
    function cashoutAllNodesRewards(address account) external;

}

// File: interfaces/reflections.sol
pragma solidity ^0.8.0;

interface reflections{
    function addNodeForReflections(address _user)external;
}

interface smartNodes{
    function balanceOf(address _user) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    // mapping(address => bool) public isBlacklisted;
}
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SMRTCompound is Ownable{

    using SafeMath for uint256;
    // using SafeERC20 for IERC20Metadata;
    IPangolinRouter public joeRouter = IPangolinRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    INodeManager public nodeManager;
    reflections public refPool;

    smartNodes public token;

    uint256 public nodeValue;
    uint256 public compoundTax;

    address public teamPool;
    address public rewardsPool;

    string public nodeName = "SMRT_CMPD";
    uint256 public i = 0;

    uint256 public devPercent;
    bool public swapLiquifyEnabled = true;
    uint256 public cashoutFee;
    uint256 public teamPoolPercent;
    uint256 public rewardsPoolPercent;
    uint256 public totalClaimed;


    mapping(address => uint256) public cmpdUserDebt;


    modifier onlyNodeOwner(address account) {
        require(nodeManager.isNodeOwner(account), "NOT_NODE_OWNER");
        _;
    }

    constructor(address _nodeManager, address _token, address _refpool){
        nodeManager = INodeManager(_nodeManager);
        token = smartNodes(_token);
        refPool = reflections(_refpool);
    }

    fallback() external payable { }
    receive() external payable { }
    function updateToken(address _token)public onlyOwner{
        token = smartNodes(_token);
    }

    function updateNodeHandler(address _nodeManager)public onlyOwner{
        nodeManager = INodeManager(_nodeManager);
    }

    function updateReflectionsPool(address _refPool)public onlyOwner{
        refPool = reflections(_refPool);
    }

    function updateNodeValue(uint256 _nodeValue)public onlyOwner{
        nodeValue = _nodeValue;
    }

    function updateCompoundTax(uint256 _compoundTax)public onlyOwner{
        compoundTax = _compoundTax;
    }

    function updateTeamPool(address _teamPool)public onlyOwner{
        teamPool = _teamPool;
    }

    function updateRewardsPool(address _rewardsPool)public onlyOwner{
        rewardsPool = _rewardsPool;
    }

    function updateJoeRouter(address _joeRouter)external onlyOwner{
        joeRouter = IPangolinRouter(_joeRouter);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialAVAXBalance = address(this).balance;

        swapTokensForAVAX(tokens);

        uint256 newBalance = (address(this).balance).sub(initialAVAXBalance);
        payable(destination).transfer(newBalance);
    }

    function updateDevPercent(uint256 _value)public onlyOwner{
        devPercent = _value;
    }

    function updateCashoutDistribution(uint256 _value1, uint256 value2)public onlyOwner{
        teamPoolPercent = _value1;
        rewardsPoolPercent = value2;
    }

    function swapTokensForAVAX(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = joeRouter.WAVAX();

        token.approve(address(joeRouter), tokenAmount);

        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            address(this),
            block.timestamp
        );
    }

    function compoundRewardsForNode()external onlyNodeOwner(msg.sender){

        address sender = _msgSender();

        uint256 rewardAmount = (nodeManager.getAllNodesRewards(sender)).sub(cmpdUserDebt[sender]);
        uint256 cmpdTax = nodeValue.mul(compoundTax).div(100);
        
        require((nodeValue + cmpdTax) <= rewardAmount, "SmartNodes: Not enough rewards to compound");
        // token.transferFrom(sender, rewardsPool, nodeValue);

        uint256 devTeamShare = nodeValue.mul(devPercent).div(100);
        token.transferFrom(rewardsPool, address(this), (cmpdTax+devTeamShare));

        swapAndSendToFee(teamPool, (cmpdTax+devTeamShare));

        nodeManager.createNode(sender, string(abi.encodePacked(nodeName, i)), nodeValue);
        i = i.add(1);

        refPool.addNodeForReflections(sender);
        
        cmpdUserDebt[sender] = cmpdUserDebt[sender].add(nodeValue.add(cmpdTax));

    }

    function cashoutAll()external{
         address sender = _msgSender();
            require(
                sender != address(0),
                "SmartNodes: Wrong address"
            );
            require(
                sender != teamPool && sender != rewardsPool,
                "SmartNodes: Wrong address"
            );
            uint256 rewardAmount = (nodeManager.getAllNodesRewards(sender)).sub(cmpdUserDebt[sender]);
            require(
                rewardAmount > 0,
                "SmartNodes: No reward to cash out"
            );
            
            if (swapLiquifyEnabled) {
                uint256 feeAmount;
                if (cashoutFee > 0) {
                    feeAmount = rewardAmount.mul(cashoutFee).div(100);
                    token.transferFrom(rewardsPool, address(this), feeAmount);
                    
                    uint256 rewardsPoolCut = feeAmount.mul(rewardsPoolPercent).div(100);
                    swapAndSendToFee(rewardsPool, rewardsPoolCut);

                    uint256 teamPoolCut = feeAmount.mul(teamPoolPercent).div(100);
                    swapAndSendToFee(teamPool, teamPoolCut);
                }
                rewardAmount -= feeAmount;
            }
            token.transferFrom(rewardsPool, sender, rewardAmount);
            nodeManager.cashoutAllNodesRewards(sender);
            totalClaimed += rewardAmount;

    }

    function getAllNodesRewards(address _user)external view returns(uint256){
        uint256 rewards = nodeManager.getAllNodesRewards(_user);
        return (rewards.sub(cmpdUserDebt[_user]));
    }

    function updateCashoutFee(uint256 _value)external onlyOwner{
        cashoutFee = _value;
    }

    function enableSwapLiquify(bool _value)external onlyOwner{
        swapLiquifyEnabled = _value;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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