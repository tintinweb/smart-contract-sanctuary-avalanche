// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IJoeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter02 {
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract CloneCCC is Context, Ownable, IERC20, IERC20Metadata {

  // initialize name and symbol
  string private constant _name   = "ClonedCCCv1";
  string private constant _symbol = "CLC";

  // storing balances, allowances and the addresses that are excluded from fees
  mapping(address => uint256) private _factoredBalances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromFees;

  // calculate supplies
  uint256 private constant _maxValue    = ~uint256(0); 
  uint256 private constant _totalSupply = 1500000000000; 

  // biggest possible uint256 number that is perfectly divisible by the totalSupply
  uint256 private _factoredSupply       = _maxValue - (_maxValue % _totalSupply);

  // keep track of all reflected tokens
  uint256 private _totalFees;

  // Wallets
  address payable _treasuryWallet;
  address payable _cccWallet;

  // dex specific
  // trader Jeo
  IJoeRouter02 private joeV2Router;
  address private joeV2Pair;

  // tax variables
  uint256 private _taxFee          = 10;
  uint256 private _teamFee         = 10;
  uint256 private _previousTaxFee  = _taxFee;
  uint256 private _previousteamFee = _teamFee;

  // blocking of the swap
  bool private _inSwap = false;

  modifier lockTheSwap() {
      _inSwap = true; 
      _;
      _inSwap = false;
  }

  constructor(address payable treasuryWallet, address payable cccWallet, address router) Ownable() {

      //assigne team and treasury wallets
      _treasuryWallet = treasuryWallet;
      _cccWallet = cccWallet;
      
      // exclued main wallets from fees
      _isExcludedFromFees[owner()] = true; 
      _isExcludedFromFees[_treasuryWallet] = true; 
      _isExcludedFromFees[_cccWallet] = true; 
      _isExcludedFromFees[address(this)] = true; 
    
      // give initial supply to owner and emit Transfer event for the transaction
      _factoredBalances[_msgSender()]   = _factoredSupply;
      emit Transfer(address(0), _msgSender(), _totalSupply);

      // assign and approve router
      joeV2Router = IJoeRouter02(router);
      _approve(address(this), address(joeV2Router), _totalSupply);

      // create and approve pair
      joeV2Pair = IJoeFactory(joeV2Router.factory()).createPair(address(this), joeV2Router.WAVAX());
      IERC20(joeV2Pair).approve(address(joeV2Router), type(uint).max);
  }

  function name() public pure override returns (string memory) {return _name;}
  function symbol() public pure override returns (string memory) {return _symbol;}
  function decimals() public pure override returns (uint8) {return 9;}
  function totalSupply() public pure override returns (uint256) {return _totalSupply;}
  function balanceOf(address account) public view override returns (uint256) {return realBalance(_factoredBalances[account]);}

  function transfer(address recipient, uint256 amount) public override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
      return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
  }

  function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
       _transfer(sender, recipient, amount);
       require(_allowances[sender][_msgSender()] >= amount, "ERC20: not enough allowance");
       _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
       return true;
  }

  function _approve(address owner,address spender, uint256 amount) internal {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");

      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }

  function _transfer(address sender,address recipient,uint256 amount) internal {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");
      require(amount > 0, "ERC20: trasaction amount is 0");
       
      swapForAvaxAndSendToWallets(sender);

      bool takeFee = true;
      if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]){
          takeFee = false;
      }

      if(sender != joeV2Pair && recipient != joeV2Pair) {
          takeFee = false;
      }

      if (takeFee && recipient == joeV2Pair) {
       _previousteamFee = _teamFee;
       _teamFee = 0;
      }
      if(takeFee && sender == joeV2Pair) {
       _previousTaxFee = _taxFee;
       _taxFee = 0;
      } 
      _tokenTransfer(sender, recipient, amount, takeFee);
      if (takeFee && sender == joeV2Pair) _teamFee = _previousteamFee;
      if (takeFee && recipient == joeV2Pair) _taxFee = _previousTaxFee;
  }

  function swapForAvaxAndSendToWallets(address sender) private {

      uint256 contractTokenBalance = balanceOf(address(this));

      if(!_inSwap && sender != joeV2Pair) {
          if(contractTokenBalance > 0) {
              if(contractTokenBalance > balanceOf(joeV2Pair) * 5 / 100) {
                  contractTokenBalance = balanceOf(joeV2Pair) * 5 / 100;
              }
              swapTokensForEth(contractTokenBalance);
          }
          uint256 contractETHBalance = address(this).balance;
          if(contractETHBalance > 0) {
              sendETHToFee(address(this).balance);
          }
      }
  }

  function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = joeV2Router.WAVAX();
      _approve(address(this), address(joeV2Router), tokenAmount);
      joeV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
          tokenAmount,
          0,
          path,
          address(this),
          block.timestamp
     );
  }

  function sendETHToFee(uint256 amount) private {
      _treasuryWallet.transfer(amount / 2);
      _cccWallet.transfer(amount / 2); 
  }


  function realBalance(uint256 factoredAmount) private view returns (uint256) {
      return factoredAmount / _getFactor();
  }


  function _getFactor() private view returns (uint256) {
      return _factoredSupply / _totalSupply;
  }

  function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
     if(!takeFee)
         removeAllFee();
     _transferStandard(sender, recipient, amount);
     if(!takeFee)
         restoreAllFee();
  }

  function _transferStandard(address sender, address recipient, uint256 totalAmount) private {
     (uint256 factoredAmount, uint256 factoredTransferAmount, uint256 factoredFee, uint256 totalTransferAmount, uint256 totalFee, uint256 totalTeam) = _getValues(totalAmount);
     _factoredBalances[sender] -= factoredAmount;
     _factoredBalances[recipient] += factoredTransferAmount; 

     _takeTeam(totalTeam);
     _reflectFee(factoredFee, totalFee);
     emit Transfer(sender, recipient, totalTransferAmount);
  }

  function _getValues(uint256 totalAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
      (uint256 totalTransferAmount, uint256 totalFee, uint256 totalTeam) = _getTotalValues(totalAmount, _taxFee, _teamFee);
      uint256 currentFactor =  _getFactor();
      (uint256 factoredAmount, uint256 factoredTransferAmount, uint256 factoredFee) = _getFactoredFalues(totalAmount, totalFee, totalTeam, currentFactor);
      return (factoredAmount, factoredTransferAmount, factoredFee, totalTransferAmount, totalFee, totalTeam);
  }

  function _getTotalValues(uint256 totalAmount, uint256 taxFee, uint256 teamFee) private pure returns (uint256, uint256, uint256) {
      uint256 totalFee = totalAmount * taxFee / 100;
      uint256 totalTeam = totalAmount * teamFee / 100;
      uint256 totalTransferAmount = totalAmount - totalFee - totalTeam;
      return (totalTransferAmount, totalFee, totalTeam);
  }

  function _getFactoredFalues(uint256 totalAmount, uint256 totalFee, uint256 totalTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
      uint256 factoredAmount = totalAmount * currentRate;
      uint256 factoredFee = totalFee * currentRate;
      uint256 factoredTeam = totalTeam * currentRate;
      uint256 factoredTransferAmount = factoredAmount - factoredFee - factoredTeam;
      return (factoredAmount, factoredTransferAmount, factoredFee);
  }

  function _takeTeam(uint256 totalTeam) private {
      uint256 currentRate =  _getFactor();
      uint256 factoredTeam = totalTeam * currentRate;

      _factoredBalances[address(this)] += factoredTeam;
  }

  function _reflectFee(uint256 factoredFee, uint256 totalFee) private {
      _factoredSupply -= factoredFee;
      _totalFees += totalFee;
  }

  function removeAllFee() private {
     if(_taxFee == 0 && _teamFee == 0) return;
     _previousTaxFee = _taxFee;
     _previousteamFee = _teamFee;
     _taxFee = 0;
     _teamFee = 0;
  }
    
  function restoreAllFee() private {
      _taxFee = _previousTaxFee;
      _teamFee = _previousteamFee;
  }

  function setTreasuryWallet(address payable treasuryWallet) external {
        require(_msgSender() == _treasuryWallet);
        _treasuryWallet = treasuryWallet;
        _isExcludedFromFees[_treasuryWallet] = true;
    }

    function setCCCWallet(address payable cccWallet) external {
        require(_msgSender() == _cccWallet);
        _cccWallet = cccWallet;
        _isExcludedFromFees[_cccWallet] = true;
    }

    function excludeFromFee(address payable ad) external {
        require(_msgSender() == _treasuryWallet);
        _isExcludedFromFees[ad] = true;
    }
    
    function includeToFee(address payable ad) external {
        require(_msgSender() == _treasuryWallet);
        _isExcludedFromFees[ad] = false;
    }
    
    function setTeamFee(uint256 team) external {
        require(_msgSender() == _treasuryWallet);
        require(team <= 25);
        _teamFee = team;
    }
        
    function setTaxFee(uint256 tax) external {
        require(_msgSender() == _treasuryWallet);
        require(tax <= 25);
        _taxFee = tax;
    }
 
    function manualswap() external {
        require(_msgSender() == _treasuryWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _treasuryWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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