/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-03
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;
  

interface IERC20 { 

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256); 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);  

    function decimals() external view returns (uint8);

    function mint(address account_, uint256 amount_) external; 

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

    enum MANAGING {   
        Waceo,
        Base,
        Base_Waceo_LP,
        Base_Stable_LP  
    }
     
    
    address public Waceo;
    address public Stable;
    address public LP_Helper;
    address public Base;
    address public Base_Waceo_LP;
    address public Base_Stable_LP;

    struct Distribution {
        address _address;
        uint256 _amount; 
    }  
  
    struct BasicRequest {
        address recipient;
        uint256 amount; 
        uint256 createDate;
        uint256 updateDate;
        bool isApproved; 
        bool isDeclined; 
        bool active;
    } 

    struct SingleAutoAllocationRequest {
        uint256 amount; 
        uint256 createDate;
        uint256 updateDate;
        bool isApproved; 
        bool isDeclined; 
        bool active;
    } 
 
    struct DoubleAutoAllocationRequest {
        uint256 amount;
        address token;
        address lp;
        address recipient; 
        uint256 waceoAmount;
        uint256 createDate;
        uint256 updateDate;
        bool isApproved; 
        bool isDeclined; 
        bool active;
    } 

    bool distributionEnabled;
    Distribution private LP_Controller;
    Distribution private Founding_Team;
    Distribution private WACEO_LP_Rewards;
    Distribution private WACEO_Operational;
    Distribution private WACEO_Dev;
    Distribution private WACEO_Regulations;
    Distribution private WACEO_Unrekt;

    mapping(address => BasicRequest) public basic_mintRequests;
    mapping(address => SingleAutoAllocationRequest) public single_autoAllocation_mintRequests;
    mapping(address => DoubleAutoAllocationRequest) public double_autoAllocation_mintRequests;


    constructor( 
        address _waceo,
        address _stable,
        address _lp_helper,
        address _base,
        address _base_waceo_lp,
        address _base_stable_lp 
    ) Ownable() {   
        Waceo = _waceo;
        Stable = _stable;
        LP_Helper = _lp_helper;
        Base = _base;
        Base_Waceo_LP = _base_waceo_lp;
        Base_Stable_LP = _base_stable_lp; 
    }  


    /**
     *  @notice validates Distribution struct parameters
     *  @return bool
     */
    function validateDistribution( Distribution memory _distribution ) internal pure returns(bool){
        if(_distribution._amount > 0 && 
            _distribution._amount < 100000000000 && 
            _distribution._address != address(0)
        ){
            return true;
        }else {
            return false;
        }
    }
  

    /**
     *  @notice basic request of minting WACEO tokens
     *  @return bool
     */
    function mint_basic ( 
        address _address,
        uint256 _amount
    ) external returns (bool){ 
        require(_amount > 0, "BASIC_MINT_REQUEST: Wrong amount");
        require(_address != address(0), "BASIC_MINT_REQUEST: Wrong address");

        basic_mintRequests[msg.sender] = BasicRequest({
            recipient: _address,
            amount: _amount,
            createDate: block.timestamp,
            updateDate: 0,
            isApproved: false,
            isDeclined: false,
            active: true
        });
        return true;
    } 
 

    /**
     *  @notice single - auto allocation mint request
     *  @return bool
     */
    function mint_auto_allocate_single ( 
        uint256 _amount 
    ) external returns (bool){ 
        require(_amount > 0, "Wrong amount"); 
        
        single_autoAllocation_mintRequests[msg.sender] = SingleAutoAllocationRequest({
            amount: _amount, 
            createDate: block.timestamp,
            updateDate: 0,
            isApproved: false,
            isDeclined: false,
            active: true
        }); 
        return true;
    } 


    /**
     *  @notice double - auto allocation mint request, converts amount to WACEO value
     *  @return bool
     */
     function mint_auto_allocate_double ( 
        uint256 _amount,
        address _token,
        address _lp 
    ) external returns (bool){   
        require(_amount > 0, "Wrong amount"); 
        require(_token != address(0), "Wrong token address"); 
        require(_lp != address(0), "Wrong LP address");  
          
        uint256 _waceoAmount = waceoValueByToken(_token, _lp, _amount);
        double_autoAllocation_mintRequests[msg.sender] = DoubleAutoAllocationRequest({
            amount: _amount,
            token: _token,
            lp: _lp,
            recipient: msg.sender,
            waceoAmount: _waceoAmount,
            createDate: block.timestamp,
            updateDate: 0,
            isApproved: false,
            isDeclined: false,
            active: true
        }); 
        return true;
    } 



     /**
     *  @notice approve/decline basic mint request, send WACEO tokens to recipient address
     *  @return bool
     */
    function distribute_basic_mint(address _address, bool _approve) external onlyOwner returns(bool){
        require(basic_mintRequests[_address].active, "There are no requests from the _address");
        require(basic_mintRequests[_address].isApproved == false, "The request already approved"); 
        require(basic_mintRequests[_address].isDeclined == false, "The request already declined"); 
        
        BasicRequest storage request =  basic_mintRequests[_address];
        if(_approve){  
            IERC20(Waceo).mint(request.recipient, request.amount);
            request.isApproved = true; 
        }else{
            request.isDeclined = true; 
        } 
        request.updateDate = block.timestamp;
        return true;
    }


     /**
     *  @notice approve/decline single mint request, auto distribute WACEO tokens
     *  @return bool
     */
    function distribute_single_mint(address _address, bool _approve) external onlyOwner returns(bool){
        require(distributionEnabled, "Distribution not enabled");
        require(single_autoAllocation_mintRequests[_address].active, "There are no requests from the _address");
        require(single_autoAllocation_mintRequests[_address].isApproved == false, "The request already approved"); 
        require(single_autoAllocation_mintRequests[_address].isDeclined == false, "The request already declined"); 
         
        if(_approve){
            uint256 _amount = single_autoAllocation_mintRequests[_address].amount;
            uint256 _LP_Controller_Value = _amount.mul(LP_Controller._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _Founding_Team_Value = _amount.mul(Founding_Team._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_LP_Rewards_Value = _amount.mul(WACEO_LP_Rewards._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Operational_Value = _amount.mul(WACEO_Operational._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Dev_Value = _amount.mul(WACEO_Dev._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Regulations_Value = _amount.mul(WACEO_Regulations._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Unrekt_Value = _amount.mul(WACEO_Unrekt._amount).div(10**IERC20(Waceo).decimals()).div(100);   
            
            IERC20(Waceo).mint(LP_Controller._address, _LP_Controller_Value);
            IERC20(Waceo).mint( Founding_Team._address, _Founding_Team_Value);
            IERC20(Waceo).mint( WACEO_LP_Rewards._address, _WACEO_LP_Rewards_Value);
            IERC20(Waceo).mint( WACEO_Operational._address, _WACEO_Operational_Value);
            IERC20(Waceo).mint( WACEO_Dev._address, _WACEO_Dev_Value);
            IERC20(Waceo).mint( WACEO_Regulations._address, _WACEO_Regulations_Value);
            IERC20(Waceo).mint( WACEO_Unrekt._address, _WACEO_Unrekt_Value);
            single_autoAllocation_mintRequests[_address].isApproved = true;  
        }else{
            single_autoAllocation_mintRequests[_address].isDeclined = true;  
        }
        single_autoAllocation_mintRequests[_address].updateDate = block.timestamp;
        return true;
    }


     /**
     *  @notice approve/decline single mint request, distribute IDO amount to recipient and auto distribute WACEO tokens  
     *  @return bool
     */
    function distribute_double_mint(address _address, bool _approve) external onlyOwner returns(bool){
        require(distributionEnabled, "Distribution not enabled");
        require(double_autoAllocation_mintRequests[_address].active, "There are no requests from the _address");
        require(double_autoAllocation_mintRequests[_address].isApproved == false, "The request already approved");
        require(double_autoAllocation_mintRequests[_address].isDeclined == false, "The request already approved");
        
        DoubleAutoAllocationRequest storage request = double_autoAllocation_mintRequests[_address];
        if(_approve){ 
            uint256 _amount = request.waceoAmount;
            uint256 _LP_Controller_Value = _amount.mul(LP_Controller._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _Founding_Team_Value = _amount.mul(Founding_Team._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_LP_Rewards_Value = _amount.mul(WACEO_LP_Rewards._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Operational_Value = _amount.mul(WACEO_Operational._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Dev_Value = _amount.mul(WACEO_Dev._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Regulations_Value = _amount.mul(WACEO_Regulations._amount).div(10**IERC20(Waceo).decimals()).div(100);  
            uint256 _WACEO_Unrekt_Value = _amount.mul(WACEO_Unrekt._amount).div(10**IERC20(Waceo).decimals()).div(100);  
              
            uint256 _value = request.amount.mul(10** IERC20(request.token).decimals()).div(10** IERC20(Waceo).decimals());
            require(IERC20(request.token).allowance(request.recipient, address(this)) >= _value, "Insufficient allowance");

            IERC20(request.token).transferFrom(request.recipient, LP_Helper, _value); 
            IERC20(Waceo).mint( request.recipient, _amount); 
            IERC20(Waceo).mint( LP_Controller._address, _LP_Controller_Value);
            IERC20(Waceo).mint( Founding_Team._address, _Founding_Team_Value);
            IERC20(Waceo).mint( WACEO_LP_Rewards._address, _WACEO_LP_Rewards_Value);
            IERC20(Waceo).mint( WACEO_Operational._address, _WACEO_Operational_Value);
            IERC20(Waceo).mint( WACEO_Dev._address, _WACEO_Dev_Value);
            IERC20(Waceo).mint( WACEO_Regulations._address, _WACEO_Regulations_Value);
            IERC20(Waceo).mint( WACEO_Unrekt._address, _WACEO_Unrekt_Value);
            request.isApproved = true;  
        }else{
            request.isDeclined = true;  
        }
        request.updateDate = block.timestamp;
        return true;
    }



    /**
     *  @notice Update Waceo, Base and LP token address
     *  @return bool
     */
    function setContract (
        MANAGING _managing, 
        address _address   
    ) external onlyOwner returns(bool) {    
        require(_address != address(0), "Wrong address");
        if ( _managing == MANAGING.Waceo ) { // 7
            Waceo = _address; 

        } else if ( _managing == MANAGING.Base ) { // 8
            Base = _address;   

        } else if ( _managing == MANAGING.Base_Waceo_LP ) { // 9
            Base_Waceo_LP =  _address;  

        } else if ( _managing == MANAGING.Base_Stable_LP ) { // 10 
            Base_Stable_LP = _address;   
        } 
        return(true);
    } 


    /**
     *  @notice Updates distribution addresses and amounts
     *  @return bool
     */
    function setDistribution(
        Distribution memory _lp_controller,
        Distribution memory _founding_team,
        Distribution memory _waceo_lp_rewards,
        Distribution memory _waceo_operational,
        Distribution memory _waceo_dev,
        Distribution memory _waceo_regulations,
        Distribution memory _waceo_unrekt
    ) external onlyOwner returns (bool){
        require(validateDistribution(_lp_controller), "LP_Controller: Wrong values");
        require(validateDistribution(_founding_team), "Founding_Team: Wrong values");
        require(validateDistribution(_waceo_lp_rewards), "WACEO_LP_Rewards: Wrong values");
        require(validateDistribution(_waceo_operational), "WACEO_Operational: Wrong values");
        require(validateDistribution(_waceo_dev), "WACEO_Dev: Wrong values");
        require(validateDistribution(_waceo_regulations), "WACEO_Regulations: Wrong values");
        require(validateDistribution(_waceo_unrekt), "WACEO_Unrekt: Wrong values");  
 
        LP_Controller = _lp_controller;
        Founding_Team = _founding_team;
        WACEO_LP_Rewards = _waceo_lp_rewards;
        WACEO_Operational = _waceo_operational;
        WACEO_Dev = _waceo_dev;
        WACEO_Regulations = _waceo_regulations;
        WACEO_Unrekt = _waceo_unrekt;
        distributionEnabled = true;

        return(true);
    }
 


    /**
     *  @notice converts 'Token' amount to WACEO value 
     *  @return value_ uint256
     */
    function waceoValueByToken(address _token, address _lp, uint256 _amount) public view returns ( uint256  value_) { 
        uint256 _baseValue = IERC20(Base).balanceOf(_lp).div(10** IERC20(Base).decimals()).mul( 10** IERC20(Waceo).decimals());
        uint256 _tokenValue = IERC20(_token).balanceOf(_lp).div(10** IERC20(_token).decimals()).mul( 10** IERC20(Waceo).decimals()); 
 
        uint256 _waceoValueInBaseToken = waceoValueInBaseToken();
        uint256 _tokenValueInBaseToken = _baseValue.mul( 10** IERC20(Waceo).decimals()).div(_tokenValue);   
        uint256 _baseAmount = _tokenValueInBaseToken.mul(_amount).div(10** IERC20(Waceo).decimals());
        value_ = _baseAmount.mul(10** IERC20(Waceo).decimals()).div(_waceoValueInBaseToken);
    }
 

    /**
     *  @notice converts WACEO amount to BASE value
     *  @return price_ uint256
     */
    function waceoValueInBaseToken() public view returns ( uint256 price_  ) {
        uint256 _baseValue = IERC20(Base).balanceOf(Base_Waceo_LP).div(10** IERC20(Base).decimals()).mul( 10** IERC20(Waceo).decimals());
        uint256 _waceoValue = IERC20(Waceo).balanceOf(Base_Waceo_LP);
        price_ = _baseValue.mul( 10** IERC20(Waceo).decimals()).div(_waceoValue);
    }

 
}