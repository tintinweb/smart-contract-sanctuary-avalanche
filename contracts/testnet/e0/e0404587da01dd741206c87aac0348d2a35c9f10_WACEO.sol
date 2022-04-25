/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-22
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;

 

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract ERC20 is IERC20 {

  using SafeMath for uint256;

  // TODO comment actual hash value.
  bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256( "ERC20Token" );
    
  // Present in ERC777
  mapping (address => uint256) internal _balances;

  // Present in ERC777
  mapping (address => mapping (address => uint256)) internal _allowances;

  // Present in ERC777
  uint256 internal _maxSupply = 100000000 * (10 ** 9);  // 100 Million Tokens;

  // Present in ERC777
  uint256 internal _totalSupply;  

  // Present in ERC777
  string internal _name;
    
  // Present in ERC777
  string internal _symbol;
    
  // Present in ERC777
  uint8 internal _decimals;

  constructor (string memory name_, string memory symbol_, uint8 decimals_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]
          .sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]
          .sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");

      _beforeTokenTransfer(sender, recipient, amount);

      _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        require(_totalSupply.add(amount_) <= _maxSupply, "ERC20: mint more than max supply");
        _beforeTokenTransfer(address( this ), account_, amount_);
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address( this ), account_, amount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
} 


interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

contract VaultOwned is Ownable {
    
  address internal _vault;

  function setVault( address vault_ ) external onlyOwner() returns ( bool ) {
    _vault = vault_;

    return true;
  }

  function vault() public view returns (address) {
    return _vault;
  }

  modifier onlyVault() {
    require( _vault == msg.sender, "VaultOwned: caller is not the Vault" );
    _;
  }

}


abstract contract Distributed is ERC20, VaultOwned {
    using SafeMath for uint256;

     enum MANAGING { 
        IDO_Distribution,
        AUTO_Distribution,
        LP_Controller, 
        Founding_Team, 
        WACEO_LP_Rewards, 
        WACEO_Operational, 
        WACEO_Dev, 
        WACEO_Regulations, 
        WACEO_Unrekt   
    } 

    struct Distribution {
        address _address;
        uint256 _amount;
        bool enabled;
    }

    struct AutoDistribution{
      uint256 totalAmount;
      Distribution LP_Controller;
      Distribution Founding_Team;
      Distribution WACEO_LP_Rewards;
      Distribution WACEO_Operational;
      Distribution WACEO_Dev;
      Distribution WACEO_Regulations;
      Distribution WACEO_Unrekt;  

    }
 
    AutoDistribution public autoDistribution;
    Distribution public idoDistribution;
     


    function setContract (
        MANAGING _managing, 
        address _address, 
        uint256 _amount 
    ) external onlyVault { 
        if(_managing != MANAGING.AUTO_Distribution){
          require( _address != address(0), "AUTO_Distribution: Wrong address" );
          require( _amount > 0, "Distribution: Wrong value");
        }

        if ( _managing == MANAGING.IDO_Distribution ) { // 0
           idoDistribution = Distribution(_address, _amount, true); 

        } else if ( _managing == MANAGING.AUTO_Distribution ) { // 1
           autoDistribution.totalAmount = _amount;  

        } else if ( _managing == MANAGING.LP_Controller ) { // 2
            autoDistribution.LP_Controller = Distribution(_address, _amount, true);  

        } else if ( _managing == MANAGING.Founding_Team ) { // 3
            autoDistribution.Founding_Team = Distribution(_address, _amount, true);  

        } else if ( _managing == MANAGING.WACEO_LP_Rewards ) { // 4
            autoDistribution.WACEO_LP_Rewards = Distribution(_address, _amount, true);  

        } else if ( _managing == MANAGING.WACEO_Operational ) { // 5
            autoDistribution.WACEO_Operational = Distribution(_address, _amount, true);  

        } else if ( _managing == MANAGING.WACEO_Dev ) { // 6
            autoDistribution.WACEO_Dev = Distribution(_address, _amount, true);  

        } else if ( _managing == MANAGING.WACEO_Regulations ) { // 7
            autoDistribution.WACEO_Regulations = Distribution(_address, _amount, true);  

        } else if ( _managing == MANAGING.WACEO_Unrekt ) { // 8
            autoDistribution.WACEO_Unrekt = Distribution(_address, _amount, true);   
        } 
    } 


    function mintIDODistribution () external onlyVault returns(bool){
      require(idoDistribution.enabled, "IDO_Distribution is not enabled");
      _mint(idoDistribution._address, idoDistribution._amount); 
      return true;
    }


    function mintAutoDistribution () external onlyVault returns(bool) {

      require(autoDistribution.totalAmount > 0, "AUTO_Distribution: Distribution total amount not set");
      require(autoDistribution.LP_Controller.enabled, "AUTO_Distribution: LP_Controller not set");
      require(autoDistribution.Founding_Team.enabled, "AUTO_Distribution: Founding_Team not set");
      require(autoDistribution.WACEO_LP_Rewards.enabled, "AUTO_Distribution: WACEO_LP_Rewards not set");
      require(autoDistribution.WACEO_Operational.enabled, "AUTO_Distribution: WACEO_Operational not set");
      require(autoDistribution.WACEO_Dev.enabled, "AUTO_Distribution: WACEO_Dev not set");
      require(autoDistribution.WACEO_Regulations.enabled, "AUTO_Distribution: WACEO_Regulations not set");
      require(autoDistribution.WACEO_Unrekt.enabled, "AUTO_Distribution: WACEO_Unrekt not set");

      uint256  _LP_Controller_Value = autoDistribution.totalAmount.mul(autoDistribution.LP_Controller._amount).div(1000);
      uint256  _Founding_Team_Value = autoDistribution.totalAmount.mul(autoDistribution.Founding_Team._amount).div(1000);
      uint256  _WACEO_LP_Rewards_Value = autoDistribution.totalAmount.mul(autoDistribution.WACEO_LP_Rewards._amount).div(1000);
      uint256  _WACEO_Operational_Value = autoDistribution.totalAmount.mul(autoDistribution.WACEO_Operational._amount).div(1000);
      uint256  _WACEO_Dev_Value = autoDistribution.totalAmount.mul(autoDistribution.WACEO_Dev._amount).div(1000);
      uint256  _WACEO_Regulations_Value = autoDistribution.totalAmount.mul(autoDistribution.WACEO_Regulations._amount).div(1000);
      uint256  _WACEO_Unrekt_Value = autoDistribution.totalAmount.mul(autoDistribution.WACEO_Unrekt._amount).div(1000); 

      _mint(autoDistribution.LP_Controller._address, _LP_Controller_Value);
      _mint(autoDistribution.Founding_Team._address, _Founding_Team_Value);
      _mint(autoDistribution.WACEO_LP_Rewards._address, _WACEO_LP_Rewards_Value);
      _mint(autoDistribution.WACEO_Operational._address, _WACEO_Operational_Value);
      _mint(autoDistribution.WACEO_Dev._address, _WACEO_Dev_Value);
      _mint(autoDistribution.WACEO_Regulations._address, _WACEO_Regulations_Value);
      _mint(autoDistribution.WACEO_Unrekt._address, _WACEO_Unrekt_Value);
      return true;
    }


}

contract WACEO is Distributed {

    using SafeMath for uint256;

    constructor() ERC20("WACEO", "WACEO", 9) {
    }

    function mint(address account_, uint256 amount_) external onlyVault() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
     
    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}