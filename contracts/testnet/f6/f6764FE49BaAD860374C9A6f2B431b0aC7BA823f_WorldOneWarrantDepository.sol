// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity  0.7.5;
pragma abicoder v2;

import "./LowGasSafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./FullMath.sol";
import "./FixedPoint.sol";
import "./ITreasury.sol";
import "./IPangolinFactory.sol";
import "./IPangolinPair.sol";
import "./Ownable.sol";

contract WorldOneWarrantDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;

    /* ======== EVENTS ======== */
    event WarrantCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event WarrantRedeemed( address indexed recipient, uint payout, uint remaining );
    event WarrantPriceChanged( uint indexed priceInUSD, uint indexed internalPrice );
    event InitWarrantLot( WarrantLot terms);
    event LogSetFactory(address _factory);
    event LogRecoverLostToken( address indexed tokenToRecover, uint amount);



    /* ======== STATE VARIABLES ======== */

    IERC20 public immutable WorldOne; // token given as payment for warrant
    IERC20 public immutable principle; // token used to create warrant
    ITreasury public immutable treasury; // mints WorldOne when receives principle
    address public immutable DAO; // receives profit share from warrant
    IPangolinFactory public immutable dexFactory; // Factory address to get market price

    mapping( address => Warrant ) public warrantInfo; // stores warrant information for depositors

    uint public warrantLotIndex = 0;

    uint32 constant MAX_PAYOUT_IN_PERCENTAGE = 100000; // in thousandths of a %. i.e. 500 = 0.5%
    uint32 constant MIN_VESTING_TERM = 129600; // in seconds. i.e. 1 day = 86400 seconds
    uint32 constant MAX_ALLOWED_DISCOUNT = 50000; // in thousandths of a %. i.e. 50000 = 50.00%


    /* ======== STRUCTS ======== */

    // Info for warrant holder
    struct Warrant {
        uint payout; // WorldOne remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
        uint32 purchasedAt; // When the warrant was purchased in block number/timestamp
        uint32 warrantLotID; // ID of warrant lot
    }

    struct WarrantLot {
        uint discount; // discount variable
        uint32 vestingTerm; // in seconds
        uint totalCapacity; // Maximum amount of tokens that can be issued
        uint consumed; // Amount of tokens that have been issued
        uint fee; // as % of warrant payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint price; // price of a bond in given bond lot
    }

    mapping(uint256 => WarrantLot) public warrantLots;


    /* ======== INITIALIZATION ======== */

    constructor ( 
        address _WorldOne,
        address _principle,
        address _treasury, 
        address _DAO,
        address _factory
    ) public {
        require( _WorldOne != address(0) );
        WorldOne = IERC20(_WorldOne);
        require( _principle != address(0) );
        principle = IERC20(_principle);
        require( _treasury != address(0) );
        treasury = ITreasury(_treasury);
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _factory != address(0) );
        dexFactory = IPangolinFactory( _factory );
    }

    /**
     *  @notice initializes warrant lot parameters
     *  @param _discount uint
     *  @param _vestingTerm uint32
     *  @param _totalCapacity uint
     *  @param _fee uint
     *  @param _maxPayout uint
     *  @param _minimumPrice uint
     */
    function initializeWarrantLot( 
        uint _discount, 
        uint32 _vestingTerm,
        uint _totalCapacity,
        uint _fee,
        uint _maxPayout,
        uint _minimumPrice
    ) external onlyOwner() {
        require( _discount > 0, "Discount must be greater than 0");
        require( _discount <= MAX_ALLOWED_DISCOUNT, "Discount must be greater than 0");
        require( _vestingTerm >= MIN_VESTING_TERM, "Vesting must be longer than 36 hours" );
        require( _totalCapacity > 0, "Total capacity must be greater than 0" );
        require( _fee <= 10000, "DAO fee cannot exceed payout" );
        require( _maxPayout <= MAX_PAYOUT_IN_PERCENTAGE, "Payout cannot be above 100 percent" );
        require( _minimumPrice > 0, "Minimum price must be greater than 0" );
        if( warrantLotIndex > 0 ){
            require( currentWarrantLot().consumed == currentWarrantLot().totalCapacity, "Warrant lot already in progress" );
        }
        uint _price = getLatestPrice();
        if( _price < _minimumPrice ){
            _price = _minimumPrice;
        }
        WarrantLot memory warrantLot = WarrantLot ({
            discount: _discount,
            vestingTerm: _vestingTerm,
            totalCapacity: _totalCapacity.mul( 10**WorldOne.decimals() ),
            consumed: 0,
            fee: _fee,
            maxPayout: _maxPayout,
            price: _price
        });
        warrantLots[warrantLotIndex] = warrantLot;
        warrantLotIndex += 1;
        emit InitWarrantLot(warrantLot);
        emit WarrantPriceChanged( warrantPriceInUSD(), warrantPrice() );
    }

    
    /* ======== POLICY FUNCTIONS ======== */



    

    /* ======== USER FUNCTIONS ======== */


    /**
     *  @notice deposit warrant
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        require(msg.sender == _depositor);
        require(warrantLotIndex > 0, "Warrant lot has not been initialized");
        require( isPurchasable(), "Market price must be greater than warrant lot price" );
        uint priceInUSD = warrantPriceInUSD(); // Stored in warrant info
        uint nativePrice = warrantPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = treasury.convertToken( address(principle), _amount );
        
        uint payout = payoutFor( value ); // payout to warranter is computed

        require( payout >= 10_000_000, "Warrant too small" ); // must be > 0.01 WorldOne ( underflow protection )
        require( payout <= maxPayout(), "Warrant too large"); // size protection because there is no slippage
        require(currentWarrantLot().consumed.add(payout) <= currentWarrantLot().totalCapacity, "Exceeding maximum allowed purchase in current warrant lot");

        uint fee = payout.mul( currentWarrantLot().fee ) / 100_00 ;

        principle.safeTransferFrom( msg.sender, address(this), _amount );
        principle.approve( address( treasury ), _amount );

        treasury.deposit( _amount, address(principle), fee );
        if ( fee != 0 ) { // fee is transferred to dao 
            WorldOne.safeTransfer( DAO, fee ); 
        }

        // depositor info is stored
        warrantInfo[ _depositor ] = Warrant({ 
            payout: warrantInfo[ _depositor ].payout.add( payout ),
            warrantLotID: uint32(warrantLotIndex - 1),
            purchasedAt: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        warrantLots[ warrantLotIndex - 1 ] = WarrantLot({
            discount: currentWarrantLot().discount,
            vestingTerm: currentWarrantLot().vestingTerm,
            totalCapacity: currentWarrantLot().totalCapacity,
            consumed: currentWarrantLot().consumed.add(payout),
            fee: currentWarrantLot().fee,
            maxPayout: currentWarrantLot().maxPayout,
            price: currentWarrantLot().price
        });

        emit WarrantCreated( _amount, payout, block.timestamp.add( currentWarrantLot().vestingTerm ), priceInUSD );

        return payout; 
    }


    /** 
     *  @notice redeem warrant for user
     *  @param _recipient address
     *  @return uint
     */ 
    function redeem( address _recipient ) external returns ( uint ) {
        require(msg.sender == _recipient, "NA");     
        Warrant memory info = warrantInfo[ _recipient ];
        require( uint32(block.timestamp) >= info.purchasedAt.add32( warrantLots[info.warrantLotID].vestingTerm )  , "Cannot redeem before vesting period is over");
        delete warrantInfo[ _recipient ]; // delete user info
        emit WarrantRedeemed( _recipient, info.payout, 0 ); // emit warrant data
        return send( _recipient, info.payout ); // pay user everything due
    }


    /**
     *  @notice get remaining WorldOne available in current warrant lot. THIS IS FOR TESTING PURPOSES ONLY
     *  @return uint
     */
    function remainingAvailable() public view returns ( uint ) {
        return currentWarrantLot().totalCapacity.sub( currentWarrantLot().consumed );
    }

    /**
     *  @notice Get cost of all remaining WorldOne tokens.  THIS IS FOR TESTING PURPOSES ONLY
     *  @return uint
     */
    function allCost() public view returns (uint) {
        return remainingAvailable().mul( 10**principle.decimals() ).mul( warrantPrice() ).div( 10**WorldOne.decimals() ) / 100;
    }


    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */


    /**
     *  @notice check if warrant is purchaseable
     *  @return bool
     */
    function isPurchasable() internal view returns(bool) {
        uint price = warrantPrice(); // 1100 x 
        price = price.mul(10**principle.decimals())/100;
        if ( price < getMarketPrice() ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     *  @notice get current market price
     *  @return uint
     */
    function getMarketPrice() internal view returns(uint) {
        IPangolinPair pair = IPangolinPair(dexFactory.getPair(address(principle), address(WorldOne)));
        IERC20 token1 = IERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        uint res0 = Res0*(10**token1.decimals());
        return(res0/Res1); // return _amount of token0 needed to buy token1 :: token0 = DAI, token1 = WorldOne
    }

    /**
     *  @notice allow user to send payout
     *  @param _amount uint
     *  @return uint
     */
    function send( address _recipient, uint _amount ) internal returns ( uint ) {
        WorldOne.transfer( _recipient, _amount ); // send payout       
        return _amount;
    }

    /**
     *  @notice get current warrant lot terms
     *  @return WarrantLot
     */
    function currentWarrantLot() internal view returns ( WarrantLot memory ) {
        require( warrantLotIndex > 0, "No bond lot has been initialised");
        return warrantLots[ warrantLotIndex - 1 ];
    } 

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum warrant size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return currentWarrantLot().totalCapacity.mul( currentWarrantLot().maxPayout ) / 100000;
    }

    /**
     *  @notice calculate interest due for new warrant
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, warrantPrice() ).decode112with18() / 1e16 ;
    }

    /**
     *  @notice calculate value of token via token amount
     *  @param _amount uint
     *  @return uint
     */
    function valueOf( uint _amount ) external view returns ( uint ) {
        return FixedPoint.fraction( _amount, warrantPrice() ).decode112with18() / 1e16 ;
    }

    /**
     *  @notice calculate current warrant premium
     *  @return price_ uint
     */
    function warrantPrice() public view returns ( uint price_ ) {
        price_ = currentWarrantLot().price;
    }

    function getLatestPrice() public view returns ( uint price_ ) {
        uint circulatingSupply = WorldOne.totalSupply();
        uint treasuryBalance = treasury.getTotalReserves().mul(1e9); //IERC20(principle).balanceOf(address(treasury));
        if (circulatingSupply == 0) { // On first warrant sale, there will be no circulating supply
            price_ = 0;
        } else {
            price_ = treasuryBalance.div(circulatingSupply).mul(getYieldFactor()).div(1e11);
        }
    }


    function getYieldFactor() public view returns ( uint ) {
        return currentWarrantLot().discount.add( 1e4 ); // add extra 100_00 to add 100% to original discount value
    }


    /**
     *  @notice converts warrant price to DAI value
     *  @return price_ uint
     */
    function warrantPriceInUSD() public view returns ( uint price_ ) {
        price_ = warrantPrice().mul( 10 ** principle.decimals() ) / 100;
    }


    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or WorldOne) to the DAO
     *  @return bool
     */
    function recoverLostToken(IERC20 _token ) external returns ( bool ) {
        require( _token != WorldOne, "NAT" );
        require( _token != principle, "NAP" );
        uint balance = _token.balanceOf( address(this));
        _token.safeTransfer( DAO,  balance );
        emit LogRecoverLostToken(address(_token), balance);
        return true;
    }
}