/**
 *Submitted for verification at snowtrace.io on 2022-03-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

interface IUniswapV2Pair {

    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
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

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 value, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target, 
        bytes memory data, 
        uint256 weiValue, 
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target, 
        bytes memory data, 
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success, 
        bytes memory returndata, 
        string memory errorMessage
    ) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}
interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using LowGasSafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender)
            .sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}


contract ANFTBondDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event InitTerms( Terms terms);
    event LogSetTerms(PARAMETER param, uint value);
    event LogRecoverLostToken( address indexed tokenToRecover, uint amount);



    /* ======== STATE VARIABLES ======== */

    IERC20 public immutable ANFT; // token given as payment for bond
    IERC20 public immutable principle; // token used to create bond
    address public warChest; // receive USDC , multisign wallet.
    address public feeReceiver; // receives profit share from bond
    address public autoBuyBack ;
    address public pair;
    uint256 public feeDenominator = 10000;

    Terms public terms; // stores terms for new bonds

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint minAmount; // min ANFT amount to be created
        uint maxAmount; // max ANFT amount to be created
        uint fee; // set 1 means 0.01%
        uint autoBuyBackFee; // set 1 means 0.01%
        uint32 vestingTerm; // in seconds
        uint discountValue; /// 157 means 15.7%
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // ANFT remaining to be paid
        uint32 lastTime; // Last interaction
        uint32 vesting; // Seconds left to vest
    }

    /* ======== INITIALIZATION ======== */

    constructor ( 
        address _ANFT,
        address _principle,
        address _pair,
        address _warChest, 
        address _feeReceiver,    // 10% fee to Dao Address
        address _autoBuyBack  // 20% to auto buyback
    ) {
        require( _ANFT != address(0) );
        ANFT = IERC20(_ANFT);
        require( _principle != address(0) );
        principle = IERC20(_principle);
        require( _warChest != address(0) );
        warChest = _warChest;
        require( _feeReceiver != address(0) );
        feeReceiver = _feeReceiver;
        require( _autoBuyBack != address(0) );
        autoBuyBack = _autoBuyBack;
        require( _pair != address(0) );
        pair = _pair;
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, MIN_AMOUNT,MAX_AMOUNT, FEE, AUTOBUYBACK_FEE, DISCOUNT_VALUE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.MIN_AMOUNT ) { // 1  
            terms.minAmount = _input;
        } else if ( _parameter == PARAMETER.MAX_AMOUNT ) {
            terms.maxAmount = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2   1000 means 10%
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            terms.fee = _input; 
        } else if ( _parameter == PARAMETER.AUTOBUYBACK_FEE ) { //3      1000 means 10%
            terms.autoBuyBackFee = _input;
        } else if ( _parameter == PARAMETER.DISCOUNT_VALUE ) {
            terms.discountValue = _input;
        }
        emit LogSetTerms(_parameter, _input);
    }

 

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( 
        uint _amount, 
        address _depositor
    ) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        require(msg.sender == _depositor, "LFNA");

        uint256 daoFee = _amount.mul( terms.fee ) / feeDenominator ;
        uint256 autoBuyBackFee = _amount.mul( terms.autoBuyBackFee ) / feeDenominator ;

        uint256 amountToBond = _amount.sub(daoFee.add(autoBuyBackFee));

        uint256 payout = payoutFor( amountToBond ); // payout to bonder is computed

        require( payout >= terms.minAmount, "Bond too small" ); // must be > 0.01 ANFT ( underflow protection )
        require( payout <= terms.maxAmount, "Bond too large"); // size protection because there is no slippage
        
        require(ANFT.balanceOf(address(this)) >= payout , "Not enough ANFT to create bond");

        principle.safeTransferFrom( msg.sender, feeReceiver, daoFee );
        principle.safeTransferFrom( msg.sender, autoBuyBack, autoBuyBackFee );
        principle.safeTransferFrom( msg.sender, warChest, amountToBond );
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp)
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ) );

        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @return uint
     */ 
    function redeem( address _recipient ) external returns ( bool ) {
   //     require(msg.sender == _recipient, "NA");     
        Bond memory info = bondInfo[ _recipient ];
        // (seconds since last interaction / vesting term remaining)
        uint percentVested = percentVestedFor( _recipient );

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return ANFT.transfer( _recipient, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ) / 10000 ;
            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub32( uint32( block.timestamp ).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp)
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return ANFT.transfer( _recipient, payout );
        }
    }


    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint256 _value ) public view returns ( uint256 ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18() / 1e9 ;
    }

    /**
     *  @notice calculate discounted bond price
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint256 price_ ) {        
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        (uint256 reserve0, uint256 reserve1, ) = pairContract.getReserves();
        price_ = FixedPoint.fraction( reserve1, reserve0 ).decode112with18() * (1000 - terms.discountValue ) / ( 1000 * 1e9);    
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ];
        uint secondsSinceLast = uint32(block.timestamp).sub32( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = secondsSinceLast.mul( 10000 ) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of ANFT available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ) / 10000;
        }
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or ANFT) to the DAO
     *  @return bool
     */
    function recoverLostToken(IERC20 _token ) external returns ( bool ) {
        require( _token != ANFT, "NAT" );
        require( _token != principle, "NAP" );
        uint balance = _token.balanceOf( address(this));
        _token.safeTransfer( warChest,  balance );
        emit LogRecoverLostToken(address(_token), balance);
        return true;
    }

    function setAutoBuyBack( address _autoBuyBack ) external onlyOwner() {
        autoBuyBack = _autoBuyBack;
    }

    function setPairAddress ( address _pair ) external onlyOwner() {
        require( _pair != address(0) );
        pair = _pair;
    }

    function setFeeReceiver ( address _feeReceiver) external onlyOwner() {
        require( _feeReceiver != address(0) );
        feeReceiver = _feeReceiver;
    }

    function setWarChest ( address _warChest) external onlyOwner() {
        require( _warChest != address(0) );
        warChest = _warChest;
    }
}