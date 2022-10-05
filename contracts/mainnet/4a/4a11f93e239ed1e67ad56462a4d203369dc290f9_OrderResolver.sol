/**
 *Submitted for verification at snowtrace.io on 2022-10-05
*/

// File: lib/SafeMath.sol


pragma solidity >=0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}
// File: lib/BytesToTypes.sol

// From https://github.com/pouladzade/Seriality/blob/master/src/BytesToTypes.sol (Licensed under Apache2.0)

pragma solidity >=0.7.0;

library BytesToTypes {

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
}

// File: lib/BytesManipulation.sol


pragma solidity >=0.7.0;


library BytesManipulation {

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toBytes(address x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function mergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) {
        // From https://ethereum.stackexchange.com/a/40456
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address) {
        return BytesToTypes.bytesToAddress(_offst, _input);
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256) {
        return BytesToTypes.bytesToUint256(_offst, _input);
    } 

}

// File: order protocol/OrderResolver.sol


pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;



interface IRouter {
    function ADAPTERS(uint256) external view returns (address);

    function adaptersCount() external view returns (uint256);

    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) external view returns (ApexRouter.FormattedOffer memory);
}

interface ApexRouter {
    struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
    }

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }
}

interface IOrderPool {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function createOrder(
        string memory name,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 steps
    ) external;

    function editOrder(
        uint256 index,
        string memory name,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 steps,
        uint256 result,
        uint256 status
    ) external;

    function executeOrder(uint256 index, uint256 result) external;

    function getCurrentOrder() external view returns (OrderPool.Order memory);

    function ordernumber() external view returns (uint256);

    function orders(uint256)
        external
        view
        returns (
            string memory name,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOut,
            uint256 steps,
            uint256 result,
            uint256 status
        );

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setOrderNumber(uint256 _ordernumber) external;

    function transferOwnership(address newOwner) external;
}

interface OrderPool {
    struct Order {
        string name;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 steps;
        uint256 result;
        uint256 status;
    }
}

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}

contract OrderResolver is IResolver {
    using SafeMath for uint256;
    address public ORDERPOOL;
    address public ROUTER;

    event logs_uint256arr(uint256[] amounts);
    event log_uint256(uint256);
    event log_address(address);
    event log_string(string);
    event Response(bool success, bytes data);

    struct Opportunity {
        address token;
        uint256 amountin;
        uint256 amountout;
        uint256 profit;
        uint256 timestamp;
    }

    Opportunity public bestone;

    address constant USDTe = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    address constant USDCe = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address constant USDt = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;

    uint256 decimals = 6;
    event Logs(string memo, uint256 indexed number);

    constructor(address _ORDERPOOL, address _ROUTER) {
        ORDERPOOL = _ORDERPOOL;
        ROUTER = _ROUTER;
    }

    function setOrderPool(address _ORDERPOOL) public {
        ORDERPOOL = _ORDERPOOL;
    }

    function setRouter(address _ROUTER) public {
        ROUTER = _ROUTER;
    }

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        uint256 ordernumber = IOrderPool(ORDERPOOL).ordernumber();
        // emit log_uint256(ordernumber);

        OrderPool.Order memory offer = IOrderPool(ORDERPOOL).getCurrentOrder();
        // if (offer.status == 2) return (false, bytes("already executed"));

        uint256 router_amountout = getAmountOut(
            offer.amountIn,
            offer.tokenIn,
            offer.tokenOut,
            offer.steps
        );
        // emit log_uint256(router_amountout);

        if (router_amountout > offer.result && router_amountout > offer.amountOut) {
            execPayload = abi.encodeWithSelector(
                IOrderPool.executeOrder.selector,
                ordernumber,
                router_amountout
            );
            // emit log_string("true");
            return (true, execPayload);
        } else {
            bytes memory answer = BytesManipulation.toBytes(router_amountout);
            // emit log_string("false");
            return (false, answer);
        }
    }

    function getBestOne(
        address token,
        uint256 end,
        uint256 steps
    ) external view returns (uint256 bestprofit) {
        for (uint256 i = 1; i <= end; i++) {
            // address token = USDCe;
            uint256 amountin = i * 1e6;
            uint256 amountout = getAmountOut(amountin, token, token, steps);
            uint256 profit;
            if (amountout > amountin) profit = amountout - amountin;
            // if (profit > bestone.profit)
            //     bestone = Opportunity(token, amountin, amountout, profit, block.timestamp);
            if (profit > bestprofit) bestprofit = profit;
        }
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 steps
    ) public view returns (uint256) {
        // return amountIn.mul(105) / 100;

        ApexRouter.FormattedOffer memory offer = IRouter(ROUTER).findBestPath(
            amountIn,
            tokenIn,
            tokenOut,
            steps
        );

        uint256 length = offer.amounts.length;
        uint256 amountout;
        if (length > 0) amountout = offer.amounts[length - 1];

        return amountout;
    }
}