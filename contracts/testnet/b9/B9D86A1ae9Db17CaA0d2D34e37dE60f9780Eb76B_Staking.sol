pragma solidity ^0.8.0;

import "./Utils.sol";
import "./SafeMath.sol";
import "./erc20/ERC20.sol";

contract Staking {
    using SafeMath for uint;

    mapping(address => bool) public managers;
    ERC20 public token;

    StakePlan[] public stakePlans;

    mapping(address => Investor) public investors;
    mapping(address => bool) public hasStaked;


    mapping(address => StakePackage[]) public investorStakes;


    uint public reservedForRewardsAmount;

    event CreatedStakePlan(StakePlan newPlan);
    event ChangedStakePlanStatus(bool newStatus);
    event InvestEvent(address investor, uint amount);
    event WithdrawEvent(address investor, uint amount);
    event CreatedManagerEvent(address newManagerAddress);
    event BailOutManagerTokensEvent(address toBailTokenAddress, uint tokensAmount);
    event BailOutManagerEthEvent(address toBailEthAddress, uint ethAmount);

    constructor(ERC20 _token, address _managerAddress, address _managerDeployerMaster) {
        managers[_managerAddress] = true;
        managers[_managerDeployerMaster] = true;
        token = _token;
        reservedForRewardsAmount = 0;
    }


    modifier onlyManager() {
        require(
            isManager(msg.sender),
            "Only Manager can call this function."
        );
        _;
    }

    modifier onlyInvestor() {
        require( investors[msg.sender].isValue, "Only Manager can call this.");_;
    }


    function stakeTokens(uint _amount, uint _stakePlanId) public payable {
        require(_amount > 0, "Amount can not be 0");

        StakePlan memory splan = stakePlans[_stakePlanId];
        uint reward = calculateRewardAmount(_amount, splan.planDays, splan.rewardPercent);
        uint amountWithReward = _amount + reward;
        require(splan.isActive, "Stake plan is not active for use");
        require(isEnoughTokenBalanceToStake(amountWithReward), "Not enough tokens on Plant Starter to ensure reward. Please try again in a while.");

        // Trasnfer tokens to this contract for staking
        token.transferFrom(msg.sender, address(this), _amount);
        //token.transfer(address(this), _amount);

        StakePackage memory sp = StakePackage({
            investorPackageUniqueId: investorStakes[msg.sender].length,
            planId: _stakePlanId,
            investor: msg.sender,
            amount: _amount,
            rewardAmount: reward,
            startDate: block.timestamp,
            daysStake: splan.planDays,
            status: 0
        });
        investorStakes[msg.sender].push(sp);

        //create investor if not yet
        stakeInvestor(amountWithReward);

        uint newAmount = reservedForRewardsAmount + amountWithReward;
        reservedForRewardsAmount = newAmount;

        hasStaked[msg.sender] = true;
    }

    function completeStake(uint packageId) public payable{
        StakePackage storage sp = investorStakes[msg.sender][packageId];
        require(sp.status == 0, "Stake has already been completed");
        require(sp.investor == msg.sender, "Not Your Stake");
        require(haveDaysPassed(sp.startDate, sp.daysStake), "Days have not expired yet");

        uint combine = sp.amount + sp.rewardAmount;
        token.transfer(msg.sender,combine);
        sp.status = 1;
        uint newAmount = reservedForRewardsAmount - combine;
        reservedForRewardsAmount = newAmount;
        withdrawInvestor(combine);
    }



    function addStakePlan(uint _days, uint _percentReward) public payable onlyManager{
        StakePlan memory newStakePlan = StakePlan(stakePlans.length, _days, _percentReward, true);
        //stakePlans[stakePlans.length] = newStakePlan;
        stakePlans.push(newStakePlan);
        emit CreatedStakePlan(newStakePlan);
    }


    function changeStakePlanStatus(uint _stakePlanId) public payable onlyManager {
        for (uint i=0; i<stakePlans.length; i++) {
            if (stakePlans[i].planId == _stakePlanId){
                stakePlans[i].isActive = !stakePlans[i].isActive;
            }
        }
    }

    function getStakePlans() public view returns(StakePlan[] memory){
        return stakePlans;
    }

    function getInvestorStakes(address investor) public view returns(StakePackage[] memory){
        return investorStakes[investor];
    }

    function getNextInvestorStakePackageId(address investor) public view returns(uint){
        return investorStakes[investor].length;
    }

    function stakeInvestor(uint _amount) private {
        uint investorAmount = _amount;
        if (investors[msg.sender].isValue) {
            investorAmount = investorAmount.add(investors[msg.sender].value);
        }

        investors[msg.sender] = Investor({
            investor: msg.sender,
            value: investorAmount,
            isValue: true
        });

        emit InvestEvent(msg.sender, _amount);

    }

    function calculateRewardAmount(uint _amountStaked, uint _daysStaked, uint _percentStaked) private pure returns(uint rewardAmountWei){
        uint percentAmountWei = (_amountStaked / 100) * _percentStaked;
        uint rewardWei = (percentAmountWei / 365) * _daysStaked;
        return rewardWei;
    }

    function isEnoughTokenBalanceToStake(uint _amount) private view returns(bool isEnough){
        uint balance = token.balanceOf(address(this));
        uint freeAmount = balance - reservedForRewardsAmount;
        return freeAmount > _amount;
    }

    function haveDaysPassed(uint256 start, uint daysCheck)public view returns(bool isPassed){
        return block.timestamp >= (start + daysCheck * 1 days);
    }


    function withdrawInvestor(uint _amount) private {
        require (investors[msg.sender].isValue, "Investor does not exist!");
        require (investors[msg.sender].value >= _amount, "Not enough balance");
        uint newValue = investors[msg.sender].value.sub(_amount);

        investors[msg.sender] = Investor({
            investor: msg.sender,
            value: newValue,
            isValue: true
        });
        emit WithdrawEvent(msg.sender, _amount);
    }

    function getTimetamp() public view returns(uint256 nowTime){
        return block.timestamp;
    }




    function setManager(address _managerAddress) public onlyManager{
        managers[_managerAddress] = true;
        emit CreatedManagerEvent(_managerAddress);
    }

    function unsetManager(address _managerAddress) public onlyManager{
        require(managers[_managerAddress]);
        managers[_managerAddress] = false;
    }
    function isManager(address _managerAddress) public view returns(bool){
        return managers[_managerAddress];
    }


    function bailFunds(address payable _toAddress) public payable onlyManager{
        uint tokenBalance = token.balanceOf(address(this));
        token.transfer(address(_toAddress), tokenBalance);
        emit BailOutManagerTokensEvent(address(_toAddress), tokenBalance);
        uint ethBalance = address(this).balance;
        bool sent = _toAddress.send(ethBalance);
        require(sent, "Failed to send ether");
        emit BailOutManagerEthEvent(address(_toAddress), ethBalance);
    }










}

pragma solidity ^0.8.0;

/**
 * The Utils library does this and that...
 */
struct Investor {
  address investor;
  uint value;
  bool isValue;
}

struct StakePlan {
  uint planId;
  uint planDays;
  uint rewardPercent;
  bool isActive;
}

struct StakePackage{
	uint investorPackageUniqueId;
	uint planId;
	address investor;
	uint amount;
	uint rewardAmount;
	uint256 startDate;
	uint daysStake;
	uint status; //0-opened, 1-finished, 2-closed/canceled	
}
/*
function f(uint start, uint daysAfter) public {
    if (block.timestamp >= start + daysAfter * 1 days) {
      // ...
    }
}


struct Sell {
  address seller;
  uint amount;
  uint price;
  bool isValue;
}

struct Transactions{
  address sender;
  address reciver;
  uint amount;
}

*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

pragma solidity ^0.8.0;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        _name = "WhiteH2Coin";
        _symbol = "WH2C";
        _mint(_msgSender(), 4460000000000000000000000);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 16;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.8.0;

library SafeMath {

    function mul(uint num1, uint num2) internal pure returns (uint) {
        uint result = num1 * num2;
        return result;
    }


    function div(uint num1, uint num2) internal pure returns (uint) {
        uint result = num1 / num2;
        return result;
    }


    function sub(uint num1, uint num2) internal pure returns (uint) {
        uint result = num1 - num2;
        return result;
    }


    function add(uint num1, uint num2) internal pure returns (uint) {
        uint result = num1 + num2;
        return result;
    }
}