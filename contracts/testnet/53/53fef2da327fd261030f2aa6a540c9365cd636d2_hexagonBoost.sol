/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// File: @boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol


pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }
    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }
    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {require((c = a - b) <= a, "BoringMath: Underflow");}
}

// File: @boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: @boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol

pragma solidity 0.6.12;
library BoringERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// File: @boringcrypto/boring-solidity/contracts/BoringBatchable.sol

// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
// solhint-disable avoid-low-level-calls
// T1 - T4: OK
contract BaseBoringBatchable {
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }    
    
    // F3 - F9: OK
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C1 - C21: OK
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns(bool[] memory successes, bytes[] memory results) {
        // Interactions
        successes = new bool[](calls.length);
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = result;
        }
    }
}

// T1 - T4: OK
contract BoringBatchable is BaseBoringBatchable {
    // F1 - F9: OK
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    // C1 - C21: OK
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        // Interactions
        // X1 - X5
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// File: @boringcrypto/boring-solidity/contracts/BoringOwnable.sol

// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract BoringOwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract BoringOwnable is BoringOwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;
        
        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File: contracts/libraries/SafeMath.sol

pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

// File: contracts/libraries/SmallNumbers.sol

pragma solidity 0.6.12;
    /**
     * @dev Implementation of a Fraction number operation library.
     */
library SmallNumbers {
//    using Fraction for fractionNumber;
    int256 constant private sqrtNum = 1<<120;
    int256 constant private shl = 80;
    uint8 constant private PRECISION   = 32;  // fractional bits
    uint256 constant public FIXED_ONE = uint256(1) << PRECISION; // 0x100000000
    int256 constant public FIXED_64 = 1 << 64; // 0x100000000
    uint256 constant private FIXED_TWO = uint256(2) << PRECISION; // 0x200000000
    int256 constant private FIXED_SIX = int256(6) << PRECISION; // 0x200000000
    uint256 constant private MAX_VAL   = uint256(1) << (256 - PRECISION); // 0x0000000100000000000000000000000000000000000000000000000000000000

    /**
     * @dev Standard normal cumulative distribution function
     */
    function normsDist(int256 xNum) internal pure returns (int256) {
        bool _isNeg = xNum<0;
        if (_isNeg) {
            xNum = -xNum;
        }
        if (xNum > FIXED_SIX){
            return _isNeg ? 0 : int256(FIXED_ONE);
        } 
        // constant int256 b1 = 1371733226;
        // constant int256 b2 = -1531429783;
        // constant int256 b3 = 7651389478;
        // constant int256 b4 = -7822234863;
        // constant int256 b5 = 5713485167;
        //t = 1.0/(1.0 + p*x);
        int256 p = 994894385;
        int256 t = FIXED_64/(((p*xNum)>>PRECISION)+int256(FIXED_ONE));
        //double val = 1 - (1/(Math.sqrt(2*Math.PI))  * Math.exp(-1*Math.pow(a, 2)/2)) * (b1*t + b2 * Math.pow(t,2) + b3*Math.pow(t,3) + b4 * Math.pow(t,4) + b5 * Math.pow(t,5) );
        //1.0 - (-x * x / 2.0).exp()/ (2.0*pi()).sqrt() * t * (a1 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429)))) ;
        xNum=xNum*xNum/int256(FIXED_TWO);
        xNum = int256(7359186145390886912/fixedExp(uint256(xNum)));
        int256 tt = t;
        int256 All = 1371733226*tt;
        tt = (tt*t)>>PRECISION;
        All += -1531429783*tt;
        tt = (tt*t)>>PRECISION;
        All += 7651389478*tt;
        tt = (tt*t)>>PRECISION;
        All += -7822234863*tt;
        tt = (tt*t)>>PRECISION;
        All += 5713485167*tt;
        xNum = (xNum*All)>>64;
        if (!_isNeg) {
            xNum = uint64(FIXED_ONE) - xNum;
        }
        return xNum;
    }
    function pow(uint256 _x,uint256 _y) internal pure returns (uint256){
        _x = (ln(_x)*_y)>>PRECISION;
        return fixedExp(_x);
    }

    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        x = x << PRECISION;
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function ln(uint256 _x)  internal pure returns (uint256) {
        return fixedLoge(_x);
    }
        /**
        input range: 
            [0x100000000,uint256_max]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

    */
    function fixedLoge(uint256 _x) internal pure returns (uint256 logE) {
        /*
        Since `fixedLog2_min` output range is max `0xdfffffffff` 
        (40 bits, or 5 bytes), we can use a very large approximation
        for `ln(2)`. This one is used since it’s the max accuracy 
        of Python `ln(2)`

        0xb17217f7d1cf78 = ln(2) * (1 << 56)
        
        */
        //Cannot represent negative numbers (below 1)
        require(_x >= FIXED_ONE,"loge function input is too small");

        uint256 _log2 = fixedLog2(_x);
        logE = (_log2 * 0xb17217f7d1cf78) >> 56;
    }



    /**
        Returns log2(x >> 32) << 32 [1]
        So x is assumed to be already upshifted 32 bits, and 
        the result is also upshifted 32 bits. 
        
        [1] The function returns a number which is lower than the 
        actual value

        input-range : 
            [0x100000000,uint256_max]
        output-range: 
            [0,0xdfffffffff]

        This method asserts outside of bounds

    */
    function fixedLog2(uint256 _x) internal pure returns (uint256) {
        // Numbers below 1 are negative. 
        require( _x >= FIXED_ONE,"Log2 input is too small");

        uint256 hi = 0;
        while (_x >= FIXED_TWO) {
            _x >>= 1;
            hi += FIXED_ONE;
        }

        for (uint8 i = 0; i < PRECISION; ++i) {
            _x = (_x * _x) / FIXED_ONE;
            if (_x >= FIXED_TWO) {
                _x >>= 1;
                hi += uint256(1) << (PRECISION - 1 - i);
            }
        }

        return hi;
    }
    function exp(int256 _x)internal pure returns (uint256){
        bool _isNeg = _x<0;
        if (_isNeg) {
            _x = -_x;
        }
        uint256 value = fixedExp(uint256(_x));
        if (_isNeg){
            return uint256(FIXED_64) / value;
        }
        return value;
    }
    /**
        fixedExp is a ‘protected’ version of `fixedExpUnsafe`, which 
        asserts instead of overflows
    */
    function fixedExp(uint256 _x) internal pure returns (uint256) {
        require(_x <= 0x386bfdba29,"exp function input is overflow");
        return fixedExpUnsafe(_x);
    }
       /**
        fixedExp 
        Calculates e^x according to maclauren summation:

        e^x = 1+x+x^2/2!...+x^n/n!

        and returns e^(x>>32) << 32, that is, upshifted for accuracy

        Input range:
            - Function ok at    <= 242329958953 
            - Function fails at >= 242329958954

        This method is is visible for testcases, but not meant for direct use. 
 
        The values in this method been generated via the following python snippet: 

        def calculateFactorials():
            “”"Method to print out the factorials for fixedExp”“”

            ni = []
            ni.append( 295232799039604140847618609643520000000) # 34!
            ITERATIONS = 34
            for n in range( 1,  ITERATIONS,1 ) :
                ni.append(math.floor(ni[n - 1] / n))
            print( “\n        “.join([“xi = (xi * _x) >> PRECISION;\n        res += xi * %s;” % hex(int(x)) for x in ni]))

    */
    function fixedExpUnsafe(uint256 _x) internal pure returns (uint256) {
    
        uint256 xi = FIXED_ONE;
        uint256 res = 0xde1bc4d19efcac82445da75b00000000 * xi;

        xi = (xi * _x) >> PRECISION;
        res += xi * 0xde1bc4d19efcb0000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x6f0de268cf7e58000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x2504a0cd9a7f72000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9412833669fdc800000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1d9d4d714865f500000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x4ef8ce836bba8c0000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xb481d807d1aa68000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x16903b00fa354d000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x281cdaac677b3400000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x402e2aad725eb80000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x5d5a6c9f31fe24000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x7c7890d442a83000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9931ed540345280000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaf147cf24ce150000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d00000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xafc441338061b8000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9c3cabbc0056e000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x839168328705c80000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x694120286c04a0000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x50319e98b3d2c400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x3a52a1e36b82020;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x289286e0fce002;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x650139600;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x8c40;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x462;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }  
}

// File: contracts/boost/hexagonBoostStorage.sol

pragma solidity 0.6.12;

contract hexagonBoostStorage {
    address public safeMulsig;
    address public farmChef;
    uint256 constant public RATIO_DENOM = 1000;

    uint256 constant internal rayDecimals = 1e8;//100%
    //pid => totalSupply for boost token
    mapping(uint256=>uint256) internal totalsupplies;
    //pid => user => boost token balance
    mapping(uint256=>mapping(address => uint256)) internal balances;

    //pid => user => whitelist user
    mapping(uint256=>mapping(address => bool)) public whiteListLpUserInfo;

//    log(LOG_PARA0)(amount+LOG_PARA1)- LOG_PARA2
//    uint256 public LOG_PARA0 = 5;
//    uint256 public LOG_PARA1 = 500000e18;
//    uint256 public LOG_PARA2 = 329*SmallNumbers.FIXED_ONE/10;


    struct poolBoostPara{
        uint256 fixedTeamRatio;  //default 8%
        uint256 fixedWhitelistRatio;  //default 20%
        uint256 whiteListfloorLimit; //default 500 thousands
        bool enableTokenBoost;
        address boostToken;

        uint256 minBoostAmount;
        uint256 maxIncRatio;//5.5 multiple

        uint256 log_para0;//5;
        uint256 log_para1; //500000e18
        uint256 log_para2;// 329*SmallNumbers.FIXED_ONE/10;

    }

    mapping(uint256=>poolBoostPara) public boostPara;

    //uint256 public fixedTeamRatio = 80;  //default 8%
    //uint256 public fixedWhitelistRatio = 200;  //default 20%
    //uint256 public whiteListfloorLimit = 500000 ether; //default 500 thousands
    //uint256 constant internal rayDecimals = 1000e18;//100%
    //uint256 public BaseBoostTokenAmount = 1000e18;//1000 ether;
    //uint256 public BaseIncreaseRatio = 30e18; //3%
    //uint256 public RatioIncreaseStep = 10e18;// 1%
    //uint256 public BoostTokenStepAmount = 1000e18;//1000 ether;
    //uint256 public MaxFactor = 5500e18;//5.5 multiple

    event BoostDeposit(uint256 indexed _pid,address indexed user,  uint256 amount);
    event BoostApplyWithdraw(uint256 indexed _pid,address indexed user, uint256 amount);
    event CancelBoostApplyWithdraw(uint256 indexed _pid,address indexed user, uint256 amount);
    event BoostWithdraw(uint256 indexed _pid,address indexed user, uint256 amount);
}

// File: contracts/interfaces/IMiniChefV2.sol

pragma solidity 0.6.12;


interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accFlakePerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function poolLength() external view returns (uint256);
    function updatePool(uint256 pid) external returns (IMiniChefV2.PoolInfo memory);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
    function onTransfer(uint256 pid,address from,address to) external;
}

// File: contracts/boost/hexagonBoost.sol

pragma solidity 0.6.12;


contract hexagonBoost is hexagonBoostStorage {
    using SafeMath for uint256;
    using BoringERC20 for IERC20;


    modifier onlyMCV2() {
        require(msg.sender==farmChef, "not farmChef");
        _;
    }

    modifier onlyOrigin() {
        require(msg.sender==safeMulsig, "not mulsafe");
        _;
    }

    constructor ( address _multiSignature,
                  address _farmChef )
        public
    {
        safeMulsig = _multiSignature;
        farmChef = _farmChef;
    }

    function setMulsigAndFarmChef ( address _multiSignature,
                                    address _farmChef)
        external
        onlyOrigin
    {
        safeMulsig = _multiSignature;
        farmChef = _farmChef;
    }

    function setFixedTeamRatio(uint256 _pid,uint256 _ratio)
        external onlyMCV2
    {
        boostPara[_pid].fixedTeamRatio = _ratio;
    }

    function setFixedWhitelistPara(uint256 _pid,uint256 _incRatio,uint256 _whiteListfloorLimit)
        external onlyMCV2
    {
        //_incRatio,0 whiteList increase will stop
        boostPara[_pid].fixedWhitelistRatio = _incRatio;
        boostPara[_pid].whiteListfloorLimit = _whiteListfloorLimit;
    }

    function setWhiteListMemberStatus(uint256 _pid,address _user,bool _status)
        external onlyMCV2
    {
            whiteListLpUserInfo[_pid][_user] = _status;
    }

    function setBoostFarmFactorPara(uint256 _pid,
                                    bool    _enableTokenBoost,
                                    address _boostToken,
                                    uint256 _minBoostAmount,
                                    uint256 _maxIncRatio)
        external
        onlyMCV2
    {
        boostPara[_pid].enableTokenBoost = _enableTokenBoost;
        boostPara[_pid].boostToken = _boostToken;

        if(_minBoostAmount==0) {
            boostPara[_pid].minBoostAmount = _minBoostAmount;
        } else {
            boostPara[_pid].minBoostAmount = 500 ether;
        }

        if(_maxIncRatio==0) {
            boostPara[_pid].maxIncRatio = 50*SmallNumbers.FIXED_ONE;
        } else {
            boostPara[_pid].maxIncRatio = _maxIncRatio;
        }

        IERC20(boostPara[_pid].boostToken).approve(farmChef,uint256(-1));
    }

    function setBoostFunctionPara(uint256 _pid,
        uint256 _para0,
        uint256 _para1,
        uint256 _para2)
        external
        onlyMCV2
    {
        //log(5)(amount+LOG_PARA1)- LOG_PARA2
        if(_para0==0) {
            boostPara[_pid].log_para0 = 5;
        } else {
            boostPara[_pid].log_para0 = _para0;
        }

        if(_para1==0) {
            boostPara[_pid].log_para1 = 500000e18;
        } else {
            boostPara[_pid].log_para1 = _para1;
        }

        if(_para2==0) {
            boostPara[_pid].log_para2 = 329*rayDecimals/10;
        } else {
            boostPara[_pid].log_para2 = _para2;
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function getTotalBoostedAmount(uint256 _pid,address _user,uint256 _lpamount,uint256 _baseamount)
        public view returns(uint256,uint256)
    {
       uint256 whiteListBoostAmount = 0;
       if(isWhiteListBoost(_pid)) {
           whiteListBoostAmount = getWhiteListIncAmount(_pid,_user,_lpamount,_baseamount);
       }
        //set initial value
       uint256  tokenBoostAmount = _baseamount;
       if(isTokenBoost(_pid)) {
           //reset value, increased amount + _baseamount
           tokenBoostAmount = getUserBoostIncAmount(_pid,_user,_baseamount);

       }
       uint256 totalBoostAmount = tokenBoostAmount.add(whiteListBoostAmount);

       if(isTeamRoyalty(_pid)) {
           uint256 teamAmount = getTeamAmount(_pid,totalBoostAmount);
           return (totalBoostAmount.sub(teamAmount),teamAmount);
       } else {
           return (totalBoostAmount,0);
       }
    }

    function getTeamRatio(uint256 _pid)
        public view returns(uint256,uint256)
    {
          return (boostPara[_pid].fixedTeamRatio,RATIO_DENOM);
    }

    function getTeamAmount(uint256 _pid,uint256 _baseamount)
        public view returns(uint256)
    {
        return _baseamount.mul(boostPara[_pid].fixedTeamRatio).div(RATIO_DENOM);
    }

    function getWhiteListIncRatio(uint256 _pid,address _user,uint256 _lpamount)
        public view returns(uint256,uint256)
    {
        uint256 userIncRatio = 0;
        //current stake must be over minimum require lp amount
        if (whiteListLpUserInfo[_pid][_user]&&_lpamount >= boostPara[_pid].whiteListfloorLimit) {
            userIncRatio = boostPara[_pid].fixedWhitelistRatio;
        }

        return (userIncRatio,RATIO_DENOM);
    }

    function getWhiteListIncAmount(uint256 _pid,address _user,uint256 _lpamount,uint256 _baseamount)
        public view returns(uint256)
    {
        (uint256 ratio,uint256 denom) = getWhiteListIncRatio(_pid,_user,_lpamount);
        return _baseamount.mul(ratio).div(denom);
    }

    function getUserBoostRatio(uint256 _pid,address _account)
        external view returns(uint256,uint256)
    {
        return  boostRatio(_pid,balances[_pid][_account]);
    }

    function getUserBoostIncAmount(uint256 _pid,address _account,uint256 _baseamount)
        public view returns(uint256)
    {
        (uint256 ratio,uint256 denom) =  boostRatio(_pid,balances[_pid][_account]);
        //ratio is 1.0.....
        return _baseamount.mul(ratio).div(denom);
    }

    function getBoostToken(uint256 _pid)
        external view returns(address)
    {
        return boostPara[_pid].boostToken;
    }

    function boostRatio(uint256 _pid,uint256 _amount)
        public view returns(uint256,uint256)
    {

        if(_amount<boostPara[_pid].minBoostAmount
            ||!boostPara[_pid].enableTokenBoost
            ||boostPara[_pid].log_para0==0
            ||boostPara[_pid].log_para1==0
            ||boostPara[_pid].log_para2==0
        ) {
            return (rayDecimals,rayDecimals);
        } else {
            //log(LOG_PARA0)(amount+LOG_PARA1)- LOG_PARA2
            _amount = SmallNumbers.FIXED_ONE.mul(_amount.add(boostPara[_pid].log_para1));
            uint256 log2_x = SmallNumbers.fixedLog2(_amount);
            uint256 log2_5 = SmallNumbers.fixedLog2(boostPara[_pid].log_para0.mul(SmallNumbers.FIXED_ONE));
            uint256 ratio = log2_x.mul(rayDecimals).div(log2_5);
            //log_para2 already mul raydecimals
            ratio = ratio.sub(boostPara[_pid].log_para2);
            if(ratio>boostPara[_pid].maxIncRatio) {
                ratio = boostPara[_pid].maxIncRatio;
            }
            return (ratio,rayDecimals);
        }
    }

    function boostDeposit(uint256 _pid,address _account,uint256 _amount)
        external onlyMCV2
    {

        require(boostPara[_pid].enableTokenBoost,"pool is not allow boost");

        totalsupplies[_pid] = totalsupplies[_pid].add(_amount);
        balances[_pid][_account] = balances[_pid][_account].add(_amount);

        emit BoostDeposit(_pid,_account,_amount);
    }

    function boostWithdraw(uint256 _pid,address _account,uint256 _amount)
        external onlyMCV2
    {
        require(balances[_pid][_account]>=_amount);

        totalsupplies[_pid] = totalsupplies[_pid].sub(_amount);
        balances[_pid][_account] = balances[_pid][_account].sub(_amount);

        IERC20(boostPara[_pid].boostToken).safeTransfer(_account, _amount);


        emit BoostWithdraw(_pid,_account, _amount);
    }

    function boostStakedFor(uint256 _pid,address _account) public view returns (uint256) {
        return balances[_pid][_account];
    }

    function boostTotalStaked(uint256 _pid) public view returns (uint256){
        return totalsupplies[_pid];
    }

    function isTokenBoost(uint256 _pid) public view returns (bool){
        return boostPara[_pid].enableTokenBoost;
    }

    function isWhiteListBoost(uint256 _pid) public view returns (bool){
        return  boostPara[_pid].fixedWhitelistRatio>0;
    }

    function isTeamRoyalty(uint256 _pid) public view returns (bool){
        return  boostPara[_pid].fixedTeamRatio>0;
    }

}