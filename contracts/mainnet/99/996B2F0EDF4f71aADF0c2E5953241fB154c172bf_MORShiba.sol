// SPDX-License-Identifier: MIT

/*
We are going to the moon, we have a good team and a good project looking for long term sustainability.
Site: https://moonrocketshiba.com
Telegram: https://t.me/moonrocketshiba
Discord: https://discord.gg/EhCVyj8KtW
Twitter: https://twitter.com/MoonRocketShiba
Github: https://github.com/moonrocketshiba/MoonRocketShiba
*/
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";




contract MORShiba is Context, IERC20, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
	mapping (address => mapping (address => uint256)) private _allowances;

	mapping (address => bool) private _isExcludedFromFee;
	mapping (address => bool) private _isExcludedFromReward;
	mapping(address => bool) private _excludedFromAntiWhale;
	address[] private _excludedFromReward;

	address BURN_ADDRESS = 0x0000000000000000000000000000000000000001;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tHolderRewardsTotal;

	string private _name = "Moon Rocket Shiba";
	string private _symbol = "MORShiba";
	uint8 private _decimals = 9;

	uint256 public _rewardFee = 6;
	uint256 private _previousRewardFee = _rewardFee;

	uint256 public _burnFee = 2;
	uint256 private _previousBurnFee = _burnFee;

	// address public immutable traderJoePair;

	uint16 public maxTransferAmountRateAntiWhale = 10;

	bool public antiWhaleEnabled = false;
	bool public feeEnabled = false;


	modifier antiWhale(address sender, address recipient, uint256 amount) {
		if (maxTransferAmount() > 0) {
			if (
				_excludedFromAntiWhale[sender] == false
				&& _excludedFromAntiWhale[recipient] == false
				&& antiWhaleEnabled
			) {
				require(amount <= maxTransferAmount(), "antiWhale: Transfer amount exceeds the maxTransferAmount");
			}
		}
		_;
	}

	event TransferBurn(address indexed from, address indexed burnAddress, uint256 value);
	event MaxTransferAmountRateAntiWhaleUpdated(address indexed operator, uint256 previousRate, uint256 newRate);


	constructor () {
		_rOwned[_msgSender()] = _rTotal;
		//IJoeRouter02 _joeRouter = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
		// address _traderJoePair = IJoeFactory(_joeRouter.factory()).createPair(address(this), _joeRouter.WAVAX());
		// traderJoePair = _traderJoePair;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromReward[address(this)] = true;


		_isExcludedFromFee[BURN_ADDRESS] = true;
		_isExcludedFromReward[BURN_ADDRESS] = true;


		_isExcludedFromFee[_msgSender()] = true;

		// _isExcludedFromFee[_traderJoePair] = true;// false;
		// _isExcludedFromReward[_traderJoePair] = true;

		_excludedFromAntiWhale[_msgSender()] = true;
		_excludedFromAntiWhale[BURN_ADDRESS] = true;
		_excludedFromAntiWhale[address(this)] = true;
		emit Transfer(address(0), _msgSender(), _tTotal);
	}

	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function decimals() public view returns (uint8) {return _decimals;}
	function totalSupply() public view override returns (uint256) {return _tTotal;}

	function balanceOf(address account) public view override returns (uint256) {
		if (_isExcludedFromReward[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

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

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function totalHolderRewards() public view returns (uint256) {
		return _tHolderRewardsTotal;
	}

	function totalBurned() public view returns (uint256) {
		return balanceOf(BURN_ADDRESS);
	}
	function setAntiWhaleEnabled(bool _enabled) public onlyOwner {
		antiWhaleEnabled = _enabled;
	}
	function setFeeEnabled(bool _enabled) public onlyOwner {
		feeEnabled = _enabled;
	}
	function isExcludedFromAntiWhale(address _account) public view returns (bool) {
		return _excludedFromAntiWhale[_account];
	}
	function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOwner {
		_excludedFromAntiWhale[_account] = _excluded;
	}
	function maxTransferAmount() public view returns (uint256) {
		return totalSupply().mul(maxTransferAmountRateAntiWhale).div(10000);
	}
	function updateMaxTransferAmountRateAntiWhale(uint16 _maxTransferAmountRateAntiWhale) public onlyOwner {
		require(_maxTransferAmountRateAntiWhale <= 500, "updateMaxTransferAmountRateAntiWhale: Max transfer amount rate must not exceed the maximum rate.");
		emit MaxTransferAmountRateAntiWhaleUpdated(_msgSender(), _maxTransferAmountRateAntiWhale, maxTransferAmountRateAntiWhale);
		maxTransferAmountRateAntiWhale = _maxTransferAmountRateAntiWhale;
	}

	function deliver(uint256 tAmount) public {
		address sender = _msgSender();
		require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
		(uint256 rAmount,,,,,) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rTotal = _rTotal.sub(rAmount);
		_tHolderRewardsTotal = _tHolderRewardsTotal.add(tAmount);
	}

	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
		require(tAmount <= _tTotal, "Amount must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate =  _getRate();
		return rAmount.div(currentRate);
	}

	function isExcludedFromReward(address account) public view returns (bool) {
		return _isExcludedFromReward[account];
	}

	function excludeFromReward(address account) public onlyOwner {
		require(!_isExcludedFromReward[account], "Account is already excluded");
		if(_rOwned[account] > 0) {
			_tOwned[account] = tokenFromReflection(_rOwned[account]);
		}
		_isExcludedFromReward[account] = true;
		_excludedFromReward.push(account);
	}

	function includeInReward(address account) external onlyOwner {
		require(_isExcludedFromReward[account], "Account is already excluded");
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_excludedFromReward[i] == account) {
				_excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
				_tOwned[account] = 0;
				_isExcludedFromReward[account] = false;
				_excludedFromReward.pop();
				break;
			}
		}
	}

	function excludeFromFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) public onlyOwner {
		_isExcludedFromFee[account] = false;
	}

	function setRewardFeePercent(uint256 rewardFee) external onlyOwner {
		_rewardFee = rewardFee;
	}

	function setBurnFeePercent(uint256 burnFee) external onlyOwner {
		_burnFee = burnFee;
	}

	receive() external payable {}

	function _HolderFee(uint256 rHolderFee, uint256 tHolderFee) private {
		_rTotal = _rTotal.sub(rHolderFee);
		_tHolderRewardsTotal = _tHolderRewardsTotal.add(tHolderFee);
	}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
		(uint256 tTransferAmount, uint256 tHolderFee, uint256 tBurn) = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderFee) = _getRValues(tAmount, tHolderFee, tBurn, _getRate());
		return (rAmount, rTransferAmount, rHolderFee, tTransferAmount, tHolderFee, tBurn);
	}

	function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
		uint256 tHolderFee = calculateRewardFee(tAmount);
		uint256 tBurn = calculateBurnFee(tAmount);
		uint256 tTransferAmount = tAmount.sub(tHolderFee).sub(tBurn);
		return (tTransferAmount, tHolderFee, tBurn);
	}

	function _getRValues(uint256 tAmount, uint256 tHolderFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rHolderFee = tHolderFee.mul(currentRate);
		uint256 rBurn = tBurn.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rHolderFee).sub(rBurn);
		return (rAmount, rTransferAmount, rHolderFee);
	}

	function _getRate() private view returns(uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

	function _getCurrentSupply() private view returns(uint256, uint256) {
		uint256 rSupply = _rTotal;
		uint256 tSupply = _tTotal;
		for (uint256 i = 0; i < _excludedFromReward.length; i++) {
			if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
			rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
			tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
		}
		if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
		return (rSupply, tSupply);
	}



	function calculateRewardFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_rewardFee).div(
			10**2
		);
	}

	function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_burnFee).div(
			10**2
		);
	}

	function removeAllFee() private {
		if(_rewardFee == 0 && _burnFee == 0) return;
		_previousRewardFee = _rewardFee;
		_previousBurnFee = _burnFee;
		_rewardFee = 0;
		_burnFee = 0;
	}

	function restoreAllFee() private {
		_rewardFee = _previousRewardFee;
		_burnFee = _previousBurnFee;
	}

	function isExcludedFromFee(address account) public view returns(bool) {
		return _isExcludedFromFee[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	)  private antiWhale(from, to, amount) {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, "Transfer amount must be greater than zero");
		bool takeFee = true;
		if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feeEnabled){
			takeFee = false;
		}
		_tokenTransfer(from,to,amount,takeFee);
	}
	function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
		if(!takeFee)
			removeAllFee();
		if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
			_transferFromExcluded(sender, recipient, amount);
		} else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
			_transferToExcluded(sender, recipient, amount);
		} else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
			_transferStandard(sender, recipient, amount);
		} else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
			_transferBothExcluded(sender, recipient, amount);
		} else {
			_transferStandard(sender, recipient, amount);
		}
		if(!takeFee)
			restoreAllFee();
	}

	function _transferBurn(uint256 tBurn) private {
		_tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(tBurn);
	}

	function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(
		uint256 rAmount,
		uint256 rTransferAmount,
		uint256 rHolderFee,
		uint256 tTransferAmount,
		uint256 tHolderFee,
		uint256 tBurn
		) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HolderFee(rHolderFee, tHolderFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderFee, uint256 tTransferAmount, uint256 tHolderFee, uint256 tBurn) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HolderFee(rHolderFee, tHolderFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderFee, uint256 tTransferAmount, uint256 tHolderFee, uint256 tBurn) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HolderFee(rHolderFee, tHolderFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rHolderFee, uint256 tTransferAmount, uint256 tHolderFee, uint256 tBurn) = _getValues(tAmount);
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_transferBurn(tBurn);
		_HolderFee(rHolderFee, tHolderFee);
		emit TransferBurn(sender, BURN_ADDRESS, tBurn);
		emit Transfer(sender, recipient, tTransferAmount);
	}

}