//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface InvestmentsNFT is IERC721 {
    function totalToken() external view returns (uint256);
}

contract SmartTestCoin is ERC20 {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowances;

    address private _coinOwner;
    address private _teamAddress = 0x02DCe9c40968F6CB627Bd295e13a5c994e8a4a48;
    address private _devAddress = 0xb386aBd1795A2D70F186989ef4C39d0d4E9BD658;
    address private _investorAddress = 0x18BD461214fEE61F00B05330cc36E4E162181a07;
    address private _marketingAddress = 0x69e07DbffFDDF108da0B24b0351a11f383a11E9b;
    address private _treasureAddress = 0xEC48Fbc5C76d37D2d54dC63D07eDE46700753AF6;
    address private _transitAddress = 0x6DE33E94038d629A05F36E62BB889110E7A29734;

    mapping(address => bool) public excludedFromOutcomeFee;
    mapping(address => bool) public excludedFromIncomeFee;

    address private _poolAddress;
    address private _gameAddress;

    uint256 private _total = 2000000;
    uint256 private _teamTotal = 150000;
    uint256 private _investorTotal = 50000;

    uint256 private _outcomePoolFee = 5;
    uint256 private _incomePoolFee = 25;
    uint256 private _commonFee = 15;
    uint256 private _poolAddressFee = 10;
    uint256 private _treasureAddressFee = 10;
    uint256 private _marketingAddressFee = 8;
    uint256 private _gameAddressFee = 60;
    uint256 private _teamAddressFee = 5;
    uint256 private _devAddressFee = 10;
    uint256 private _epicNFTFee = 2;
    uint256 private _legendaryNFTFee = 5;

    InvestmentsNFT private _epicNFTContract;
    InvestmentsNFT private _legendaryNFTContract;

    uint256 private _legendaryTotalIncome = 0;
    uint256 private _epicTotalIncome = 0;

    uint256 private _legendaryTrigger = 20 * (10 ** 8);
    uint256 private _epicTrigger = 40 * (10 ** 8);

    mapping(address => uint256) private _legendaryTotalIncomePerAddress;
    mapping(address => uint256) private _epicTotalIncomePerAddress;

    mapping(address => uint256) private _epicForClaim;
    mapping(address => uint256) private _legendaryForClaim;

    bool private _allowActions = false;

    modifier onlyOwner() {
        require(msg.sender == _coinOwner, "Access denied");
        _;
    }

    constructor(
        InvestmentsNFT legendaryNFTContract,
        InvestmentsNFT epicNFTContract
    ) ERC20("TEST COIN V12", "$TCV V12") {
        _coinOwner = msg.sender;

        _legendaryNFTContract = legendaryNFTContract;
        _epicNFTContract = epicNFTContract;

        uint256 initialSupply = _totalSupply().sub(_teamSupply().add(_investorSupply()));
        _mint(_coinOwner, initialSupply);
        _mint(_investorAddress, _investorSupply());
        _mint(_teamAddress, _teamSupply().sub(_devSupply()));
        _mint(_devAddress, _devSupply());

        addToExcludedFromIncomeFee(_coinOwner);
        addToExcludedFromIncomeFee(_teamAddress);
        addToExcludedFromIncomeFee(_devAddress);
        addToExcludedFromIncomeFee(_investorAddress);

        addToExcludedFromOutcomeFee(_coinOwner);
        addToExcludedFromOutcomeFee(_teamAddress);
        addToExcludedFromOutcomeFee(_devAddress);
        addToExcludedFromOutcomeFee(_investorAddress);
    }

    function addToExcludedFromOutcomeFee(address address_) public onlyOwner {
        excludedFromOutcomeFee[address_] = true;
    }

    function addToExcludedFromIncomeFee(address address_) public onlyOwner {
        excludedFromIncomeFee[address_] = true;
    }

    function epicForClaim(address address_) public view returns (uint256) {
        return _epicForClaim[address_];
    }

    function legendaryForClaim(address address_) public view returns (uint256) {
        return _legendaryForClaim[address_];
    }

    function epicTotalIncomePerAddress(address address_) public view returns (uint256) {
        return _epicTotalIncomePerAddress[address_];
    }

    function legendaryTotalIncome(address address_) public view returns (uint256) {
        return _legendaryTotalIncomePerAddress[address_];
    }

    function allowActions(bool status_) public onlyOwner {
        _allowActions = status_;
    }

    function poolAddressFee() public view returns (uint256) {
        return _poolAddressFee;
    }

    function setPoolAddressFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _poolAddressFee = fee_;
    }

    function treasureAddressFee() public view returns (uint256) {
        return _treasureAddressFee;
    }

    function setTreasureAddressFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _treasureAddressFee = fee_;
    }

    function marketingAddressFee() public view returns (uint256) {
        return _marketingAddressFee;
    }

    function setMarketingAddressFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _marketingAddressFee = fee_;
    }

    function gameAddressFee() public view returns (uint256) {
        return _gameAddressFee;
    }

    function setGameAddressFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _gameAddressFee = fee_;
    }

    function teamAddressFee() public view returns (uint256) {
        return _teamAddressFee;
    }

    function setTeamAddressFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _teamAddressFee = fee_;
    }

    function devAddressFee() public view returns (uint256) {
        return _devAddressFee;
    }

    function setDevAddressFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _devAddressFee = fee_;
    }

    function epicNFTFee() public view returns (uint256) {
        return _epicNFTFee;
    }

    function setEpicNFTFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _epicNFTFee = fee_;
    }

    function legendaryNFTFee() public view returns (uint256) {
        return _legendaryNFTFee;
    }

    function setLegendaryNFTFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _legendaryNFTFee = fee_;
    }

    function outcomePoolFee() public view returns (uint256) {
        return _outcomePoolFee;
    }

    function setOutcomePoolFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _outcomePoolFee = fee_;
    }

    function incomePoolFee() public view returns (uint256) {
        return _incomePoolFee;
    }

    function setIncomePoolFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _incomePoolFee = fee_;
    }

    function commonFee() public view returns (uint256) {
        return _commonFee;
    }

    function setCommonFee(uint256 fee_) public onlyOwner {
        require(fee_ <= 100 && fee_ >= 0, "Not valid fee value.");
        _commonFee = fee_;
    }

    function epicTrigger() public view returns (uint256) {
        return _epicTrigger;
    }

    function setEpicTrigger(uint256 value_) public onlyOwner {
        require(value_ > 1, "Not valid value.");
        _epicTrigger = value_ * (10 ** 8);
    }

    function legendaryTrigger() public view returns (uint256) {
        return _legendaryTrigger;
    }

    function setLegendaryTrigger(uint256 value_) public onlyOwner {
        require(value_ > 1, "Not valid value.");
        _epicTrigger = value_ * (10 ** 8);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function _totalSupply() private view returns (uint256) {
        return _total.mul(10 ** decimals());
    }

    function _investorSupply() private view returns (uint256) {
        return _investorTotal.mul(10 ** decimals());
    }

    function _teamSupply() private view returns (uint256) {
        return _teamTotal.mul(10 ** decimals());
    }

    function _devSupply() private view returns (uint256) {
        return _teamSupply().div(100).mul(10);
    }

    function devAddress() public view returns (address){
        return _devAddress;
    }

    function setDevAddress(address address_) public onlyOwner {
        _devAddress = address_;
    }

    function teamAddress() public view returns (address){
        return _teamAddress;
    }

    function setTeamAddress(address address_) public onlyOwner {
        _teamAddress = address_;
    }

    function poolAddress() public view returns (address){
        return _poolAddress;
    }

    function setPoolAddress(address address_) public onlyOwner {
        _poolAddress = address_;
    }

    function transitAddress() public view returns (address){
        return _transitAddress;
    }

    function setTransitAddress(address address_) public onlyOwner {
        _transitAddress = address_;
    }

    function gameAddress() public view returns (address) {
        return _gameAddress;
    }

    function setGameAddress(address address_) public onlyOwner {
        addToExcludedFromOutcomeFee(address_);
        addToExcludedFromIncomeFee(address_);
        _gameAddress = address_;
    }

    function resetClaimableFor(address address_) public {
        require(msg.sender == _gameAddress, "Don't have permission for this action");

        _epicForClaim[address_] = 0;
        _legendaryForClaim[address_] = 0;
    }

    function _distributeForInvestmentsNFTs(uint256 legendary, uint256 epic) private {
        uint256 epicTotalToken = _epicNFTContract.totalToken();
        uint256 legendaryTotalToken = _legendaryNFTContract.totalToken();

        _epicTotalIncome += epic;
        _legendaryTotalIncome += legendary;

        if (epicTotalToken > 0 && _epicTotalIncome >= _epicTrigger) {
            uint256 part = _epicTotalIncome.div(epicTotalToken);

            for (uint256 i = 1; i < epicTotalToken + 1; i++) {
                address nftOwner = _epicNFTContract.ownerOf(i);
                _epicTotalIncomePerAddress[nftOwner] += part;
                _epicForClaim[nftOwner] += part;
            }

            _epicTotalIncome = 0;
        }

        if (legendaryTotalToken > 0 && _legendaryTotalIncome >= _legendaryTrigger) {
            uint256 part = _legendaryTotalIncome.div(legendaryTotalToken);

            for (uint256 i = 1; i < legendaryTotalToken + 1; i++) {
                address nftOwner = _legendaryNFTContract.ownerOf(i);
                _legendaryTotalIncomePerAddress[nftOwner] += part;
                _legendaryForClaim[nftOwner] += part;
            }

            _legendaryTotalIncome = 0;
        }
    }

    function _distributeFee(address sender, uint256 amount) private {
        uint256 percent = amount.div(100);

        _transfer(sender, _transitAddress, percent.mul(_poolAddressFee));

        uint256 legendaryFee = percent.mul(_legendaryNFTFee);
        uint256 epicFee = percent.mul(_epicNFTFee);

        _transfer(sender, _treasureAddress, percent.mul(_treasureAddressFee));
        _transfer(sender, _marketingAddress, percent.mul(_marketingAddressFee));
        _transfer(sender, _gameAddress, percent.mul(_gameAddressFee.add(legendaryFee).add(epicFee)));

        _distributeForInvestmentsNFTs(legendaryFee, epicFee);

        uint256 teamFee_ = percent.mul(_teamAddressFee);
        uint256 devFee_ = teamFee_.div(100).mul(_devAddressFee);

        _transfer(sender, _teamAddress, teamFee_.sub(devFee_));
        _transfer(sender, _devAddress, devFee_);
    }

    function _customTransfer(address sender, address recipient, uint256 amount) private {
        uint256 actualAmount;

        if (excludedFromOutcomeFee[sender]) {
            _transfer(sender, recipient, amount);
        } else if (excludedFromIncomeFee[recipient]) {
            _transfer(sender, recipient, amount);
        } else if (sender == _poolAddress && recipient != _poolAddress) {
            uint256 fee = amount.div(100).mul(_outcomePoolFee);
            actualAmount = amount.sub(fee);

            _transfer(sender, recipient, actualAmount);
            _distributeFee(sender, fee);
        } else if (sender != _poolAddress && recipient == _poolAddress && sender != _coinOwner) {
            uint256 fee = amount.div(100).mul(_incomePoolFee);
            actualAmount = amount.sub(fee);

            _transfer(sender, recipient, actualAmount);
            _distributeFee(sender, fee);
        } else {
            require(_allowActions == true, "Transfer locked");
            uint256 fee = amount.div(100).mul(_commonFee);
            actualAmount = amount.sub(fee);

            _transfer(sender, recipient, actualAmount);
            _distributeFee(sender, fee);
        }
    }

    function transfer(address recipient, uint256 amount) public virtual override(ERC20) returns (bool) {
        _customTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20) returns (bool) {
        _customTransfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override(ERC20) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override(ERC20) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view virtual override(ERC20) returns (uint256) {
        return _allowances[owner][spender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}