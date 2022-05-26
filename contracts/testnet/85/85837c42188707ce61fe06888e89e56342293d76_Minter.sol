/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-25
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
        BaseToken,
        Treasury,
        Base_Waceo_LP, 
        Max_Ammount
    }
     
    event Mint_Basic( address indexed recipient, uint256 amount);
    event Mint_Single( uint256 amount);
    event Mint_Double( uint256 amount, address indexed token, address lp);
    event DistributeBasicMint( address indexed recipient, uint256 amount);
    event DistributeSingleMint( uint256 amount );
    event DistributeDoubleMint( uint256 amount, address indexed token, address lp);
    

    address public Waceo; 
    address public Treasury;
    address public BaseToken;
    address public Base_Waceo_LP; 
    uint256 public maxAmount = 1000000000000000;


    struct Distribution {
        address _address;
        uint256 _amount; 
    }  
  
    struct BasicRequest {
        address sender;
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
        address sender; 
        uint256 waceoAmount;
        uint256 createDate;
        uint256 updateDate;
        bool isApproved; 
        bool isDeclined; 
        bool active;
    } 

    bool distributionEnabled;
    Distribution public LP_Controller;
    Distribution public Founding_Team;
    Distribution public WACEO_LP_Rewards;
    Distribution public WACEO_Operational;
    Distribution public WACEO_Dev;
    Distribution public WACEO_Regulations;
    Distribution public WACEO_Unrekt;

    mapping(address => BasicRequest) public basic_mintRequests;
    mapping(address => SingleAutoAllocationRequest) public single_autoAllocation_mintRequests;
    mapping(address => DoubleAutoAllocationRequest) public double_autoAllocation_mintRequests;


    constructor( 
        address _waceo, 
        address _treasury,
        address _baseToken,
        address _base_waceo_lp 
    ) Ownable() {   
        Waceo = _waceo; 
        Treasury = _treasury;
        BaseToken = _baseToken;
        Base_Waceo_LP = _base_waceo_lp; 
    }  


    /**
     *  @dev validates Distribution struct parameters
     *  check for 0 address and percentage amount, must be more than 0 and less than 100  
     *  @return bool
     */
    function validateDistribution( Distribution memory _distribution ) internal pure returns(bool){
        if(  _distribution._amount < 100000000000 && 
            _distribution._address != address(0)
        ){
            return true;
        }else {
            return false;
        }
    }
  

     /**
     *  @dev Function for creating basic mint request
     *  Accepts WACEO token amount, which will be sent after request approval 
     *  @notice Anyone can create a request, but request could only be approved from Multisig wallet.
     *  @return bool
     */
    function mint_basic ( 
        address _address,
        uint256 _amount
    ) external returns (bool){ 
        require(_amount > 0 && _amount <= maxAmount, "Wrong amount");
        require(_address != address(0), "Wrong address");

        basic_mintRequests[msg.sender] = BasicRequest({
            sender: _address,
            amount: _amount,
            createDate: block.timestamp,
            updateDate: 0,
            isApproved: false,
            isDeclined: false,
            active: true
        });

        emit Mint_Basic(_address, _amount);
        return true;
    } 
 

     /**
     *  @dev Function for creating single mint request
     *  Accepts WACEO token amount, which will be sent after request approval along with distribution addresses and amounts
     *  @notice Anyone can create a request, but request could only be approved from Multisig wallet
     *  @return bool
     */
    function mint_auto_allocate_single ( 
        uint256 _amount 
    ) external returns (bool){ 
        require(_amount > 0 && _amount <= maxAmount, "Wrong amount"); 
        
        single_autoAllocation_mintRequests[msg.sender] = SingleAutoAllocationRequest({
            amount: _amount, 
            createDate: block.timestamp,
            updateDate: 0,
            isApproved: false,
            isDeclined: false,
            active: true
        }); 

        emit Mint_Single(_amount);
        return true;
    } 


    /**
     *  @dev Function for creating double mint request
     *  Accepts token and LP addresses to count the appropriate value of WACEO tokens
     *  @notice Anyone can create a request, but request could only be approved from Multisig wallet
     *  @return bool
     */
     function mint_auto_allocate_double ( 
        uint256 _amount,
        address _token,
        address _lp 
    ) external returns (bool){   
        require(_amount > 0, "Wrong token amount"); 
        require(_token != address(0), "Wrong token address"); 
        if(_token != BaseToken){
            require(_lp != address(0), "Wrong LP address");  
        } 
          
        uint256 _waceoAmount = waceoValueByToken(_token, _lp, _amount);
        require(_waceoAmount > 0 && _waceoAmount <= maxAmount, "Wrong WACEO amount");
        double_autoAllocation_mintRequests[msg.sender] = DoubleAutoAllocationRequest({
            amount: _amount,
            token: _token,
            lp: _lp,
            sender: msg.sender,
            waceoAmount: _waceoAmount,
            createDate: block.timestamp,
            updateDate: 0,
            isApproved: false,
            isDeclined: false,
            active: true
        }); 

        emit Mint_Double(_amount, _token, _lp);
        return true;
    } 



     /**
     *  @dev Approve or decline basic mint request,
     *  transfer WACEO tokens to request recipient address,
     *  update request updateDate and change isApproved/isDeclined status
     *  @return bool
     */
    function distribute_basic_mint(address _address, bool _approve) external onlyOwner returns(bool){
        require(basic_mintRequests[_address].active, "There are no requests from the _address");
        require(basic_mintRequests[_address].isApproved == false, "The request already approved"); 
        require(basic_mintRequests[_address].isDeclined == false, "The request already declined"); 
        
        BasicRequest storage request =  basic_mintRequests[_address];
        if(_approve){  
            IERC20(Waceo).mint(request.sender, request.amount);
            request.isApproved = true; 
        }else{
            request.isDeclined = true; 
        } 
        request.updateDate = block.timestamp;
        emit DistributeBasicMint(request.sender, request.amount);
        return true;
    }


    /**
     *  @dev Approve or decline single mint request,
     *  count WACEO amounts by request total amount and percentages from distributor addresses, 
     *  distribute WACEO tokens to recipient addresses
     *  update request updateDate and change isApproved/isDeclined status
     *  @return bool
     */
    function distribute_single_mint(address _address, bool _approve) external onlyOwner returns(bool){
        require(distributionEnabled, "Distribution not enabled");
        require(single_autoAllocation_mintRequests[_address].active, "There are no requests from the _address");
        require(single_autoAllocation_mintRequests[_address].isApproved == false, "The request already approved"); 
        require(single_autoAllocation_mintRequests[_address].isDeclined == false, "The request already declined"); 
         
        uint256 _amount = single_autoAllocation_mintRequests[_address].amount;
        if(_approve){ 
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
        emit DistributeSingleMint(_amount);
        return true;
    }



     /**
     *  @dev Approve or decline double mint request,
     *  count WACEO amounts by request total amount and percentages from distributor addresses,
     *  check for ERC20 allowance and transfer tokens from request sender to Treasury address,
     *  distribute WACEO tokens to recipient addresses
     *  update request updateDate and change isApproved/isDeclined status
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
            require(IERC20(request.token).allowance(request.sender, address(this)) >= _value, "Insufficient allowance");

            IERC20(request.token).transferFrom(request.sender, Treasury, _value); 
            IERC20(Waceo).mint( request.sender, _amount); 
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
        emit DistributeDoubleMint(request.amount, request.token, request.lp);
        return true;
    }



    /**
     *  @dev Update Waceo, Base and LP token addresses
     *  @return bool
     */
    function setContract (
        MANAGING _managing, 
        address _address,
        uint256 _amount
    ) external onlyOwner returns(bool) {    
        require(_address != address(0), "Wrong address");

        if ( _managing == MANAGING.Waceo ) { // 0
            Waceo = _address; 

        } else if ( _managing == MANAGING.BaseToken ) { // 1
            BaseToken = _address;   

        } else if ( _managing == MANAGING.Treasury ) { // 2
            Treasury = _address;   

        } else if ( _managing == MANAGING.Base_Waceo_LP ) { // 3
            Base_Waceo_LP =  _address;  

        } else if ( _managing == MANAGING.Max_Ammount ) { // 4
            require(_amount > 0, "Wrong amount");
            maxAmount = _amount;   
        } 
        return(true);
    } 


    /**
     *  @dev Updates distribution addresses and percentages
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
     *  @dev converts 'Token' amount in WACEO  
     *  @return value_ uint256
     */
    function waceoValueByToken(address _token, address _lp, uint256 _amount) public view returns ( uint256  value_) { 
        require(_token != address(0), "Wrong token address");
        require(_amount > 0, "Wrong amount"); 

        uint256 _baseAmount = _amount;
        uint256 _waceoValueInBaseToken = waceoValueInBaseToken(); 

        if(_token != BaseToken){
            uint256 _baseValue = IERC20(BaseToken).balanceOf(_lp).div(10**IERC20(BaseToken).decimals()).mul( 10**IERC20(Waceo).decimals());
            uint256 _tokenValue = IERC20(_token).balanceOf(_lp).div(10**IERC20(_token).decimals()).mul( 10**IERC20(Waceo).decimals());
            require(_baseValue > 0, "Base token - Insufficient pool supply");
            require(_tokenValue > 0, "Token - Insufficient pool supply");
            uint256 _tokenValueInBaseToken = _baseValue.mul( 10**IERC20(Waceo).decimals()).div(_tokenValue);   
            _baseAmount = _tokenValueInBaseToken.mul(_amount).div(10**IERC20(Waceo).decimals());
        }  
        value_ = _baseAmount.mul(10** IERC20(Waceo).decimals()).div(_waceoValueInBaseToken);
    }
 

    /**
     *  @dev converts WACEO amount in BASE token
     *  @return price_ uint256
     */
    function waceoValueInBaseToken() public view returns ( uint256 price_  ) {
        uint256 _baseValue = IERC20(BaseToken).balanceOf(Base_Waceo_LP).div(10**IERC20(BaseToken).decimals()).mul( 10**IERC20(Waceo).decimals());
        uint256 _waceoValue = IERC20(Waceo).balanceOf(Base_Waceo_LP);
        require(_baseValue > 0, "Base token - Insufficient pool supply");
        require(_waceoValue > 0, "WACEO - Insufficient pool supply");
        price_ = _baseValue.mul( 10**IERC20(Waceo).decimals()).div(_waceoValue);
    }

 
}