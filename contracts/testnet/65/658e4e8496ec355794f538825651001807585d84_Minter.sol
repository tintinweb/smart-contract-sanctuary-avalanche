/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-29
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;
 


interface IERC20 {
   /**
   * @dev Returns the amount of tokens owned by `account`.
   */
   function balanceOf(address account) external view returns (uint256);

    /**
    * Function for WACEO mint instance.
    * Mints WACEO tokens to the recipient address.
    */
   function mint(address account_, uint256 amount_) external;

   /**
    * Returns token decimals.
    */
   function decimals() external view returns (uint8);
}
 

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}




 
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract Minter is Ownable {
    using SafeMath for uint256; 
 
    address public Waceo;
    address public Stable;
    address public Wavax;
    address public WAVAX_WACEO_LP;
    address public WAVAX_STABLE_LP;

    struct Distribution {
        address _address;
        uint256 _amount; 
    }  

    struct BasicRequest {
        address Recipient;
        uint256 Amount; 
        uint256 Timestamp;
        bool Approved; 
        bool Active;
    } 

    struct AutoAllocationRequest {
        uint256 Amount;
        Distribution LP_Controller;
        Distribution Founding_Team;
        Distribution WACEO_LP_Rewards;
        Distribution WACEO_Operational;
        Distribution WACEO_Dev;
        Distribution WACEO_Regulations;
        Distribution WACEO_Unrekt;  
        uint256 Timestamp;
        bool Approved; 
        bool Active;
    } 

    mapping(address => BasicRequest) public basic_mintRequests;
    mapping(address => AutoAllocationRequest) public single_autoAllocation_mintRequests;
    mapping(address => AutoAllocationRequest) public double_autoAllocation_mintRequests;


    constructor(
        address _waceo,  
        address _stable, 
        address _wavax,
        address _wavax_waceo_lp,
        address _wavax_stable_lp 
    ) Ownable() {  
        Waceo = _waceo;
        Stable = _stable;
        Wavax = _wavax;
        WAVAX_WACEO_LP = _wavax_waceo_lp;
        WAVAX_STABLE_LP = _wavax_stable_lp;
    }  



    function validate( Distribution memory _distribution ) internal pure returns(bool){
        if(_distribution._amount > 0 && _distribution._address != address(0)){
            return true;
        }else {
            return false;
        }
    }



    function _mint_basic ( 
        address _address,
        uint256 _amount
    ) external returns (bool){ 
        require(_amount > 0, "BASIC_MINT_REQUEST: Wrong amount");
        require(_address != address(0), "BASIC_MINT_REQUEST: Wrong address");

        basic_mintRequests[msg.sender] = BasicRequest({
            Recipient: _address,
            Amount: _amount,
            Timestamp: block.timestamp,
            Approved: false,
            Active: true
        });
        return true;
    } 

  


    function _mint_auto_allocate_single ( 
        uint256 _amount,
        Distribution memory _lp_controller,
        Distribution memory _founding_team,
        Distribution memory _waceo_lp_rewards,
        Distribution memory _waceo_operational,
        Distribution memory _waceo_dev,
        Distribution memory _waceo_regulations,
        Distribution memory _waceo_unrekt
    ) external returns (bool){ 
        require(_amount > 0, "Wrong amount");
        require(validate(_lp_controller), "LP_Controller: Wrong values");
        require(validate(_founding_team), "Founding_Team: Wrong values");
        require(validate(_waceo_lp_rewards), "Waceo_LP_Rewards: Wrong values");
        require(validate(_waceo_operational), "Waceo_Operational: Wrong values");
        require(validate(_waceo_dev), "Waceo_Dev: Wrong values");
        require(validate(_waceo_regulations), "Waceo_Regulations: Wrong values");
        require(validate(_waceo_unrekt), "Waceo_Unrekt: Wrong values"); 
        
        single_autoAllocation_mintRequests[msg.sender] = AutoAllocationRequest({
            Amount: _amount,
            LP_Controller: _lp_controller,
            Founding_Team: _founding_team,
            WACEO_LP_Rewards: _waceo_lp_rewards,
            WACEO_Operational: _waceo_operational,
            WACEO_Dev: _waceo_dev,
            WACEO_Regulations: _waceo_regulations,
            WACEO_Unrekt: _waceo_unrekt,
            Timestamp: block.timestamp,
            Approved: false,
            Active: true
        }); 
        return true;
    } 




    function approve_basic_mint(address _address) external onlyOwner returns(bool){
        require(basic_mintRequests[_address].Active, "There are no requests from the _address");
        require(basic_mintRequests[_address].Approved == false, "The request already approved");

        BasicRequest storage request =  basic_mintRequests[_address];
        IERC20(Waceo).mint(request.Recipient, request.Amount);
        request.Approved = true;
        return true;
    }



    function approve_auto_allocate_single(address _address) external onlyOwner returns(bool){
        require(single_autoAllocation_mintRequests[_address].Active, "There are no requests from the _address");
        require(single_autoAllocation_mintRequests[_address].Approved == false, "The request already approved");
        
        AutoAllocationRequest storage request =  single_autoAllocation_mintRequests[_address];
        uint256 _LP_Controller_Value = request.Amount.mul(request.LP_Controller._amount.div(10**IERC20(Waceo).decimals())).div(100);
        uint256 _Founding_Team_Value = request.Amount.mul(request.Founding_Team._amount.div(10**IERC20(Waceo).decimals())).div(100);
        uint256 _WACEO_LP_Rewards_Value = request.Amount.mul(request.WACEO_LP_Rewards._amount.div(10**IERC20(Waceo).decimals())).div(100);
        uint256 _WACEO_Operational_Value = request.Amount.mul(request.WACEO_Operational._amount.div(10**IERC20(Waceo).decimals())).div(100);
        uint256 _WACEO_Dev_Value = request.Amount.mul(request.WACEO_Dev._amount.div(10**IERC20(Waceo).decimals())).div(100);
        uint256 _WACEO_Regulations_Value = request.Amount.mul(request.WACEO_Regulations._amount.div(10**IERC20(Waceo).decimals())).div(100);
        uint256 _WACEO_Unrekt_Value = request.Amount.mul(request.WACEO_Unrekt._amount.div(10**IERC20(Waceo).decimals())).div(100); 
        
        IERC20(Waceo).mint(request.LP_Controller._address, _LP_Controller_Value);
        IERC20(Waceo).mint( request.Founding_Team._address, _Founding_Team_Value);
        IERC20(Waceo).mint( request.WACEO_LP_Rewards._address, _WACEO_LP_Rewards_Value);
        IERC20(Waceo).mint( request.WACEO_Operational._address, _WACEO_Operational_Value);
        IERC20(Waceo).mint( request.WACEO_Dev._address, _WACEO_Dev_Value);
        IERC20(Waceo).mint( request.WACEO_Regulations._address, _WACEO_Regulations_Value);
        IERC20(Waceo).mint( request.WACEO_Unrekt._address, _WACEO_Unrekt_Value);
        request.Approved = true; 
        return true;
    }

  


    /**
     *  @notice converts WACEO price to USDC value
     *  @return price_ uint
     */
    function waceoPriceInUSD() public view returns ( uint256 price_ ) {
        uint256 _waceoInWAVAX = waceoPriceInWAVAX();
        uint256 _wavaxInUSD =  wavaxPriceInUSD();
        price_ = _waceoInWAVAX.mul(_wavaxInUSD);
    }


    /**
     *  @notice converts WACEO price to WAVAX value
     *  @return price_ uint
     */
    function waceoPriceInWAVAX() public view returns ( uint256 price_ ) {
        uint256 _wavaxValue = IERC20(Wavax).balanceOf(WAVAX_WACEO_LP);
        uint256 _waceoValue = IERC20(Waceo).balanceOf(WAVAX_WACEO_LP);
        price_ = _wavaxValue.div(_waceoValue);
    }


    /**
     *  @notice converts WAVAX price to USD value
     *  @return price_ uint
     */
    function wavaxPriceInUSD() public view returns ( uint256 price_ ) {
        uint256 _wavaxValue = IERC20(Wavax).balanceOf(WAVAX_STABLE_LP);
        uint256 _stableValue = IERC20(Stable).balanceOf(WAVAX_STABLE_LP);
        price_ = _stableValue.div(_wavaxValue);
    }
}