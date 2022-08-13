// SPDX-License-Identifier: Proprietary
pragma solidity 0.7.5;

import "./LowGasSafeMath.sol";
import "./SafeERC20.sol";
import "./ITreasury.sol";
import "./Ownable.sol";
import "./IERC20Mintable.sol";
import "./IWorldOneERC20.sol";
import "./IWarrantDepository.sol";

contract WorldOneTreasury is Ownable {

    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;
    using SafeERC20 for IERC20;

    event Deposit( address indexed token, uint amount, uint value );
    event Withdrawal( address indexed token, uint amount, uint totalWithdrawal );
    event CreateDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event RepayDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event Payback( address indexed token, uint amount, uint totalReserves, uint paidExtra );
    event ReservesManaged( address indexed token, uint amount );
    event ReservesUpdated( uint indexed totalReserves );
    event ReservesAudited( uint indexed totalReserves );
    event ChangeQueued( MANAGING indexed managing, address queued );
    event ChangeActivated( MANAGING indexed managing, address activated, bool result );
    event ChangeLimitAmount( uint256 amount );

    enum MANAGING { 
        RESERVEDEPOSITOR, 
        RESERVESPENDER, 
        RESERVETOKEN, 
        RESERVEMANAGER, 
        DEBTOR, 
        REWARDMANAGER
    }

    IWorldOneERC20 public immutable WorldOne;
    uint32 public immutable secondsNeededForQueue;
    IWarrantDepository public warrantDepository;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isReserveToken;
    mapping( address => uint32 ) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => uint32 ) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveSpender;
    mapping( address => uint32 ) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveManager;
    mapping( address => uint32 ) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isDebtor;
    mapping( address => uint32 ) public debtorQueue; // Delays changes to mapping.
    mapping( address => uint ) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isRewardManager;
    mapping( address => uint32 ) public rewardManagerQueue; // Delays changes to mapping.

    mapping( address => uint256 ) public hourlyLimitAmounts; // tracks amounts
    mapping( address => uint32 ) public hourlyLimitQueue; // Delays changes to mapping.

    uint256 public limitAmount;
    
    uint public totalReserves; // Risk-free value of all assets
    uint public totalWithdraw;

    constructor (
        address _WorldOne,
        address _MIM,
        uint32 _secondsNeededForQueue,
        uint256 _limitAmount
    ) public {
        require( _WorldOne != address(0) );
        WorldOne = IWorldOneERC20(_WorldOne);

        isReserveToken[ _MIM ] = true;
        reserveTokens.push( _MIM );

        secondsNeededForQueue = _secondsNeededForQueue;
        limitAmount = _limitAmount;
    }

    function setLimitAmount(uint amount) external onlyOwner {
        limitAmount = amount;
        emit ChangeLimitAmount(limitAmount);
    }

    /**
        @notice allow approved address to deposit an asset for WorldOne
        @param _amount uint
        @param _token address
        @param _fee uint
        @return send_ uint
     */
    function deposit( uint _amount, address _token, uint _fee ) external returns ( uint send_ ) {
        require( isReserveToken[ _token ], "Not accepted" );
        uint value = convertToken(_token, _amount);
        send_ = valueOf(_token, _amount);
        send_ = send_.add( _fee );

        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        if ( isReserveToken[ _token ] ) {
            require( isReserveDepositor[ msg.sender ], "Not approved" );
        }
        WorldOne.mint( msg.sender, send_ );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );

        emit Deposit( _token, _amount, value );
    }

    /**
        @notice allow approved address to withdraw reserves
        @param _amount uint
        @param _token address
     */
    function withdraw( uint _amount, address _token ) external {
        require( isReserveToken[ _token ], "Not accepted" ); // Only reserves can be used for redemptions
        require( isReserveSpender[ msg.sender ], "Not approved" );
        require ( _amount <= totalReserves, "Cannot withdraw more than treasury currently holds");
        totalWithdraw = totalWithdraw.add( _amount );
        IERC20( _token ).safeTransfer( msg.sender, _amount );

        emit Withdrawal( _token, _amount, totalWithdraw );
    }

    /**
        @notice allow approved address to add funds back in treasury
        @param _amount uint
        @param _token address
     */

    function addBack(uint _amount, address _token) external {
        require( isReserveToken[ _token ], "Not accepted" ); // Only reserves can be used for redemptions
        require( isReserveSpender[ msg.sender ], "Not approved" );
        uint balance;
        if ( totalWithdraw >= _amount ) {
            totalWithdraw = totalWithdraw.sub( _amount );
        } else {
            balance = _amount.sub( totalWithdraw );
            totalReserves = totalReserves.add( balance );
            totalWithdraw = 0;
        }
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );
        emit Payback( _token, _amount, totalReserves, balance);

    }

    /**
        @notice Set warrant depository address for treasury
        @param _depo address
     */
    function setWarrantDepository(address _depo) external onlyOwner {
        warrantDepository = IWarrantDepository(_depo);
    }

    /**
        @notice get total reserves that treasury has
        @return totalReserves uint
     */
    function getTotalReserves() external view returns (uint) {
        return totalReserves;
    }
    
    
    /**
        @notice returns WorldOne valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOf( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match WorldOne decimals
            value_ = convertToken( _token, _amount );
            value_ = warrantDepository.valueOf(value_);
        }
    }

    /**
        @notice convert token decimals to match WorldOne decimals
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function convertToken( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match WorldOne decimals
            value_ = _amount.mul( 10 ** WorldOne.decimals() ).div( 10 ** IERC20( _token ).decimals() );
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue( MANAGING _managing, address _address ) external onlyOwner returns ( bool ) {
        require( _address != address(0), "IA" );
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            reserveDepositorQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            reserveSpenderQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            reserveTokenQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            ReserveManagerQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue.mul32( 2 ) );
        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            debtorQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            rewardManagerQueue[ _address ] = uint32(block.timestamp).add32( secondsNeededForQueue );
        } else return false;

        emit ChangeQueued( _managing, _address );
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function toggle(
        MANAGING _managing, 
        address _address
    ) external onlyOwner returns ( bool ) {
        require( _address != address(0), "IA" );
        bool result;
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            if ( requirements( reserveDepositorQueue, isReserveDepositor, _address ) ) {
                reserveDepositorQueue[ _address ] = 0;
                if( !listContains( reserveDepositors, _address ) ) {
                    reserveDepositors.push( _address );
                }
            }
            result = !isReserveDepositor[ _address ];
            isReserveDepositor[ _address ] = result;
            
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            if ( requirements( reserveSpenderQueue, isReserveSpender, _address ) ) {
                reserveSpenderQueue[ _address ] = 0;
                if( !listContains( reserveSpenders, _address ) ) {
                    reserveSpenders.push( _address );
                }
            }
            result = !isReserveSpender[ _address ];
            isReserveSpender[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            if ( requirements( reserveTokenQueue, isReserveToken, _address ) ) {
                reserveTokenQueue[ _address ] = 0;
                if( !listContains( reserveTokens, _address ) ) {
                    reserveTokens.push( _address );
                }
            }
            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            if ( requirements( ReserveManagerQueue, isReserveManager, _address ) ) {
                reserveManagers.push( _address );
                ReserveManagerQueue[ _address ] = 0;
                if( !listContains( reserveManagers, _address ) ) {
                    reserveManagers.push( _address );
                }
            }
            result = !isReserveManager[ _address ];
            isReserveManager[ _address ] = result;

        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            if ( requirements( debtorQueue, isDebtor, _address ) ) {
                debtorQueue[ _address ] = 0;
                if( !listContains( debtors, _address ) ) {
                    debtors.push( _address );
                }
            }
            result = !isDebtor[ _address ];
            isDebtor[ _address ] = result;

        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            if ( requirements( rewardManagerQueue, isRewardManager, _address ) ) {
                rewardManagerQueue[ _address ] = 0;
                if( !listContains( rewardManagers, _address ) ) {
                    rewardManagers.push( _address );
                }
            }
            result = !isRewardManager[ _address ];
            isRewardManager[ _address ] = result;

        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool 
     */
    function requirements( 
        mapping( address => uint32 ) storage queue_, 
        mapping( address => bool ) storage status_, 
        address _address 
    ) internal view returns ( bool ) {
        if ( !status_[ _address ] ) {
            require( queue_[ _address ] != 0, "Must queue" );
            require( queue_[ _address ] <= uint32(block.timestamp), "Queue not expired" );
            return true;
        } return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }
}