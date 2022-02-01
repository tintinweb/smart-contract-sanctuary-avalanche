// SPDX-License-Identifier: MIT

/**
* Submitted for verification at snowtrace.io on 2021-12-06
*/

import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";


interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA, 
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}



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


// OpenZeppelin Contracts v4.3.2 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

pragma solidity ^0.8.0;

contract RewardManager {

    struct NodeEntity {
        string name;                    // node name
        uint256 nodeType;
        uint256 creationTime;           // creation time of node
        uint256 lastClaimTime;          // last claim time of rewards
    } // Node information

    struct NodeType {
        uint256 nodePrice;           // price of node
        uint256 rewardPerDay;       // reward per node
    }

    mapping(address => NodeEntity[]) private _nodesOfUser; // address -> Nodes which user have
    mapping(uint256 => NodeType) public nodeTypes;
    
    uint256 public claimTime;           // user can claim only if lastClaimTime + claimTime < now

    address public gateKeeper;          // creator of this reward manager
    address public token;               // this will be Marvel token address

    uint256 public totalNodesCreated = 0;       // total nodes number
    uint256 public totalRewardReleased = 0;       // total reward amount
    uint256[] public types;

    constructor(
        uint256 _claimTime
    ) {
        claimTime = _claimTime;
        gateKeeper = msg.sender;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    function setToken(address token_) external onlySentry {
        token = token_;
    }

    function addNewNodeType(uint256 typeNum, uint256 nodePrice, uint256 rewardPerDay) public onlySentry {
        require(nodeTypes[typeNum].nodePrice == 0, "Type name is already used");
        require(nodePrice != 0, "Node price should be above zero");
        require(rewardPerDay != 0, "Reward should be above zero");
        nodeTypes[typeNum] = NodeType({
                                        nodePrice: nodePrice,
                                        rewardPerDay: rewardPerDay
                                    });
    }

    function removeNodeType(uint256 typeNum) public onlySentry {
        require(nodeTypes[typeNum].nodePrice > 0, "Type name is not existing");
        delete nodeTypes[typeNum];
    }

    function changeNodeType(uint256 typeNum, uint256 nodePrice, uint256 rewardPerDay) public onlySentry {
        require(nodeTypes[typeNum].nodePrice != 0, "Type name is not existing.");
        require(nodePrice != 0, "Node price should be above zero");
        require(rewardPerDay != 0, "Reward should be above zero");
        require(nodeTypes[typeNum].nodePrice != nodePrice || nodeTypes[typeNum].rewardPerDay != rewardPerDay, "No change");

        nodeTypes[typeNum] = NodeType({
                                        nodePrice: nodePrice,
                                        rewardPerDay: rewardPerDay
                                    });
    }

    function changeNodePrice(uint256 typeNum, uint256 nodePrice) public onlySentry {
        require(nodeTypes[typeNum].nodePrice != 0, "Type name is not existing.");
        require(nodePrice != 0, "Node price should be above zero");
        require(nodeTypes[typeNum].nodePrice != nodePrice, "New price is same as old name");

        nodeTypes[typeNum] = NodeType({
                                        nodePrice: nodePrice,
                                        rewardPerDay: nodeTypes[typeNum].rewardPerDay
                                    });
    }

    function changeNodeReward(uint256 typeNum, uint256 rewardPerDay) public onlySentry {
        require(nodeTypes[typeNum].nodePrice != 0, "Type name is not existing.");
        require(rewardPerDay != 0, "Reward should be above zero");
        require(nodeTypes[typeNum].rewardPerDay != rewardPerDay, "Reward value is same as old one");

        nodeTypes[typeNum] = NodeType({
                                        nodePrice: nodeTypes[typeNum].nodePrice,
                                        rewardPerDay: rewardPerDay
                                    });

    }

    function getNodeType(uint256 typeNum) public view returns(uint256 nodePrice, uint256 rewardPerDay) {
        require(nodeTypes[typeNum].nodePrice != 0, "Type name is not existing.");
        return (nodeTypes[typeNum].nodePrice, nodeTypes[typeNum].rewardPerDay);
    }


    // Create New Node
    function createNode(address account, uint256 nodeType, string memory nodeName)
        external
        onlySentry
    {
        require(
            isNameAvailable(account, nodeName),
            "CREATE NODE: Name not available"
        );
        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                nodeType: nodeType,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp
            })
        );
        totalNodesCreated++;
    }

    // Node creator can't use already used name by him
    function isNameAvailable(address account, string memory nodeName)
        private
        view
        returns (bool)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    // Search Node created at specific time
    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length; // 0,1,2,3 = length = 4
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low)  / 2;
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    // Get amount of rewards of node
    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        onlySentry
        returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        (, uint256 rewardPerDay) = getNodeType(node.nodeType);
        uint256 rewardNode = (block.timestamp - node.lastClaimTime) * (rewardPerDay / 86400);
        node.lastClaimTime = block.timestamp;
        totalRewardReleased += rewardNode;
        return rewardNode;
    }

    // Get sum of all nodes' rewards 
    function _cashoutAllNodesReward(address account)
        external
        onlySentry
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            (, uint256 rewardPerDay) = getNodeType(nodes[i].nodeType);
            rewardsTotal += (block.timestamp - _node.lastClaimTime) * (rewardPerDay / 86400);
            _node.lastClaimTime = block.timestamp;
        }
        totalRewardReleased += rewardsTotal;
        return rewardsTotal;
    }

    // Check claim time is passed after lastClaimTime. In other words, Can claim claimTime after lastClaimTime
    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    // Get sum of all nodes' rewards owned by account
    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            (, uint256 rewardPerDay) = getNodeType(nodes[i].nodeType);
            rewardCount += (block.timestamp - nodes[i].lastClaimTime) * (rewardPerDay / 86400);
        }
        return rewardCount;
    }

    // Get Reward amount of Node
    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity memory node = _getNodeWithCreatime(nodes, _creationTime);
        (, uint256 rewardPerDay) = getNodeType(node.nodeType);
        uint256 rewardNode = (block.timestamp - node.lastClaimTime) * (rewardPerDay / 86400);
        return rewardNode;
    }

    // Get node names of account
    function _getNodesInfo(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory info = "";
        string memory separator = "#";
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            info = string(abi.encodePacked(info, separator, 
            _node.name, separator, 
            uint2str(_node.nodeType), separator, 
            uint2str(_node.creationTime), separator, 
            uint2str(_node.lastClaimTime)));
        }
        return info;
    }

    // // Get times of all nodes created by account
    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }


    // Get last claim times of all nodes created by account
    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "LAST CLAIME TIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    // Get number of nodes created by account
    function _getNodeNumberOf(address account) public view returns (uint256) {
        return _nodesOfUser[account].length;
    }

    // Check if account has node or not
    function isNodeOwner(address account) private view returns (bool) {
        return _nodesOfUser[account].length > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

}

pragma solidity ^0.8.0;

// Payees:
// ["0xC5BE903F276d4294E0f3555D33185D656436543c", "0x9626C9F9d3d6ed3932A13A3AD9EFa593Dc7523c8"]
// shares:
// [30,70]
// addresses:
// ["0x1E28E349De4aA27E94614C2ea89CEafae454B293","0xdFB4ee2A067a0D2a6719df23e54ec13B094B66c2","0xFc411B82C6c96E7d4D1938cfC438D0e0cFCFcdB5","0xe9D49E4cf3ffad40a62E4211c261815D3356E128","0xa8a6C61c0a0d9534d16d975F8e4d36Fb986b3D35"]
// balances:
// [5000000, 5000000, 5000000, 5000000, 5000000]
// fees: (future= 2, liquidity=10, rewards=60, cashout=10, rswp=2)
// [2,60,10,10,2]
// swapamount: 30000000000000000000
// univ2router: 0x60aE616a2155Ee3d9A68541Ba4544862310933d4

contract Marvel is ERC20, Ownable, PaymentSplitter {

    RewardManager public rewardManager;

    IJoeRouter02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public futurUsePool;            //futurfee is sent to this address
    address public distributionPool;        //rewards fee is sent to this address

    address public deadWallet = 0x000000000000000000000000000000000000dEaD; //Unused variable

    uint256 public rewardsFee;              
    uint256 public liquidityPoolFee;
    uint256 public futurFee;
    uint256 public totalFees;

    uint256 public cashoutFee;              // fee when claiming rewards

    uint256 private rwSwap;                 // rwSwap percentage of rewards fee will be swapped to avax
    bool private swapping = false;              
    bool private swapLiquify = true;
    uint256 public swapTokensAmount;        // Amount of token for swap

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory balances,
        uint256[] memory fees,
        uint256 swapAmount,
        address uniV2Router
    ) ERC20("Marvel", "MARV") PaymentSplitter(payees, shares) {
        futurUsePool = addresses[3];        
        distributionPool = addresses[4];

        require(
            futurUsePool != address(0) && distributionPool != address(0),
            "FUTUR & REWARD ADDRESS CANNOT BE ZERO"
        );

        require(uniV2Router != address(0), "ROUTER CANNOT BE ZERO");
        IJoeRouter02 _uniswapV2Router = IJoeRouter02(uniV2Router);

        address _uniswapV2Pair = IJoeFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WAVAX());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        require(
            fees[0] != 0 && fees[1] != 0 && fees[2] != 0 && fees[3] != 0,
            "CONSTR: Fees equal 0"
        );
        futurFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
        cashoutFee = fees[3];
        rwSwap = fees[4];

        totalFees = rewardsFee + liquidityPoolFee + futurFee;

        require(
            addresses.length > 0 && balances.length > 0,
            "CONSTR: addresses array length must be greater than zero"
        );
        require(
            addresses.length == balances.length,
            "CONSTR: addresses arrays length mismatch"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], balances[i] * (10**18));
        }
        require(
            totalSupply() == 25000000 * (10**18),
            "CONSTR: totalSupply must equal 20 million"
        );
        require(swapAmount > 0, "CONSTR: Swap amount incorrect");
        swapTokensAmount = swapAmount * (10**18);
    }

    function setNodeManagement(address nodeManagement) external onlyOwner {
        rewardManager = RewardManager(nodeManagement);        
    }

    // Change Swap Router Address
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "TKN: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IJoeRouter02(newAddress);
        address _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WAVAX());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        futurUsePool = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee + liquidityPoolFee+ futurFee;
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee + liquidityPoolFee + futurFee;
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee + liquidityPoolFee + futurFee;
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );

        super._transfer(from, to, amount);
    }

    // Swap tokens to avax and sent it to this contract address
    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance - initialETHBalance;
        payable(destination).transfer(newBalance);
    }

    // Swap half tokens to avax and add liqudity of other half tokens and swapped avax
    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance; // balance of avax of this contract address

        swapTokensForEth(half); // address of this contract will get new balance of avax after calling this function

        uint256 newBalance = address(this).balance - initialBalance; // amount of swapped avax using half amount of liquidity fee tokens

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    // Swap tokens to avax
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of Avax
            path,
            address(this),
            block.timestamp
        );
    }

    // Add liquidity of this token and avax
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityAVAX{value: ethAmount}( // this is native token function call format
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    // Create Node after paying Node price in tokens
    // When creating new node, compare token balance of this contract 
    // and swap tokens to avax if it is bigger than swapTokenAmount
    // After that, distribute rewards
    function createNodeWithTokens(uint256 typeNum, string memory name) public {
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        (uint256 nodePrice,) = rewardManager.getNodeType(typeNum);
        require(
            balanceOf(sender) >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );
        uint256 contractTokenBalance = balanceOf(address(this)); // balance of marvel token of this contract address
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner() &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;

            uint256 futurTokens = (contractTokenBalance * futurFee) / 100;

            swapAndSendToFee(futurUsePool, futurTokens);

            uint256 rewardsPoolTokens = (contractTokenBalance * rewardsFee) / 100;

            uint256 rewardsTokenstoSwap = (rewardsPoolTokens * rwSwap) / 100;

            swapAndSendToFee(distributionPool, rewardsTokenstoSwap);
            super._transfer(
                address(this),
                distributionPool,
                rewardsPoolTokens - rewardsTokenstoSwap
            );

            uint256 swapTokens = (contractTokenBalance * liquidityPoolFee) / 100;

            swapAndLiquify(swapTokens);

            swapTokensForEth(balanceOf(address(this)));

            swapping = false;
        }
        super._transfer(sender, address(this), nodePrice);
        rewardManager.createNode(sender, typeNum, name);
    }

    // Find node created at blocktime and claim rewards
    function cashoutReward(uint256 blocktime) public {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = rewardManager._getRewardAmountOf(
            sender,
            blocktime
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = (rewardAmount * cashoutFee) / 100;
                swapAndSendToFee(futurUsePool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, sender, rewardAmount);
        rewardManager._cashoutNodeReward(sender, blocktime);
    }

    // Claim rewards of all Nodes created by msgSender
    function cashoutAll() public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 rewardAmount = rewardManager._getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );
        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = (rewardAmount * cashoutFee) / 100;
                swapAndSendToFee(futurUsePool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, sender, rewardAmount);
        rewardManager._cashoutAllNodesReward(sender);
    }

    // Owner of contract get avax of token contract
    function boostReward(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    // Get number of node owned by account
    function getNodeNumberOf(address account) public view returns (uint256) {
        return rewardManager._getNodeNumberOf(account);
    }

    function getRewardAmountOf(address account)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return rewardManager._getRewardAmountOf(account);
    }

    // Get reward amount of msgSender
    function getRewardAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(rewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return rewardManager._getRewardAmountOf(_msgSender());
    }


    // Get Node price
    function getNodeType(uint256 typeNum) public view returns (uint256 nodePrice, uint256 rewardPerDay) {
        return rewardManager.getNodeType(typeNum);
    }

    function addNewNodeType(uint256 typeNum, uint256 nodePrice, uint256 rewardPerDay) public onlyOwner payable {
        rewardManager.addNewNodeType(typeNum, nodePrice, rewardPerDay);
    }

    function removeNodeType(uint256 typeNum) public onlyOwner {
        rewardManager.removeNodeType(typeNum);
    }

    function changeNodeType(uint256 typeNum, uint256 nodePrice, uint256 rewardPerDay) public onlyOwner {
        rewardManager.changeNodeType(typeNum, nodePrice, rewardPerDay);
    }

    function changeNodePrice(uint256 typeNum, uint256 nodePrice) public onlyOwner {
        rewardManager.changeNodePrice(typeNum, nodePrice);
    }

    function changeNodeReward(uint256 typeNum, uint256 rewardPerDay) public onlyOwner {
        rewardManager.changeNodeReward(typeNum, rewardPerDay);
    }


    // Change Claim time
    function changeClaimTime(uint256 newTime) public onlyOwner {
        rewardManager._changeClaimTime(newTime);
    }

    function getClaimTime() public view returns (uint256) {
        return rewardManager.claimTime();
    }

    
    function getNodesInfo() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(rewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return rewardManager._getNodesInfo(_msgSender());
    }

    function getNodesCreatime() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(rewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return rewardManager._getNodesCreationTime(_msgSender());
    }

    function getNodesLastClaims() public view returns (string memory) {
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(rewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return rewardManager._getNodesLastClaimTime(_msgSender());
    }

    function getTotalReleasedReward() public view returns (uint256) {
        return rewardManager.totalRewardReleased();
    }

    function getTotalCreatedNodes() public view returns (uint256) {
        return rewardManager.totalNodesCreated();
    }
}