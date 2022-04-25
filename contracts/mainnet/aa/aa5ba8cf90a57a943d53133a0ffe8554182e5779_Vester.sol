/**
 *Submitted for verification at snowtrace.io on 2022-04-25
*/

/**
  
   ChoccyCoin

   Chocconomics:
   100M supply, no tax
   
**/

pragma solidity ^0.8.0;
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

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

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract Choccy is ERC20 {
    address public devV;
    address public invV;
    address public vester;
    address public treasury;

    constructor() ERC20("ChoccyCoin", "CCY") {
        devV = address(new devVesting(15*(30 days), this, msg.sender, 10*1e6*1e18));
        invV = address(new invVest(this, 12*(30 days)));
        vester = address(new Vester(this, 6*(30 days))); 
        treasury = address(new Treasury(this, msg.sender, 1 days));
        _mint(vester, 100 * (1e6) * (1e18) + 8855240700000000000000000); //100M supply + investor
        _transfer(vester, invV, 8855240700000000000000000); //investor vesting
        _transfer(vester, devV, 10*1e6*1e18); //10% dev fund
        _transfer(vester, treasury, 30*1e6*1e18); //30% treasury.
        _transfer(vester, msg.sender, 27*1e6*1e18); //27% liq. this leaves the rest for vesting (10%+30%+27% = 67%, 33 presold)
    }
}

contract devVesting {
    ERC20 public immutable token;
    uint public immutable amountStart;
    uint public immutable duration;
    uint public immutable start;
    address public immutable dev; //could let you transfer ownership of the token, but I don't see that happen often and it would increase the surface area

    constructor(uint _duration, ERC20 _token, address _dev, uint _amountStart){
        duration = _duration;
        start = block.timestamp + 3 * (30 days);
        token = _token;
        dev = _dev;
        amountStart = _amountStart;
    }

    function takeFunds(uint amount) external{
        require(msg.sender == dev);
        token.transfer(dev, amount);
        require(block.timestamp > start, "Too soon!");
        uint age = block.timestamp - start;
        require(( amountStart - token.balanceOf(address(this)) ) <= ( amountStart*(age*age) )/(duration*duration) , "You've taken too much");
    }

    function calcUnvestable() external view returns (uint){
        uint age = block.timestamp - start;
        return ( amountStart*(age*age) )/(duration*duration);
    }
}

struct Withdrawal {
    string reason;
    uint timestamp;
    uint amount;
}

contract Treasury {
    ERC20 public immutable token;
    uint public immutable delay;
    mapping (uint8 => Withdrawal) public withdrawals;
    address public immutable dev; //could let you transfer ownership of the token, but I don't see that happen soon and it would increase the surface area
    event WithdrawalRequest(uint indexed timestamp, uint indexed amount, uint8 index);

    constructor(ERC20 _token, address _dev, uint _delay){
        delay = _delay;
        token = _token;
        dev = _dev;
    }

    function requestWithdrawal(uint8 index, uint amount, string memory reason) external{
        require(msg.sender == dev);
        withdrawals[index] = Withdrawal(reason, block.timestamp, amount);
        emit WithdrawalRequest(block.timestamp, amount, index);
    }

    function withdraw(uint8 index) external{
        require(msg.sender == dev);
        require(block.timestamp >= withdrawals[index].timestamp+delay, "Too soon!");
        uint amount = withdrawals[index].amount;
        withdrawals[index] = Withdrawal("", 0, 0);
        token.transfer(dev, amount);
    }
}

contract Vester {
    ERC20 public immutable token;
    address public immutable dev;
    uint public immutable vestDuration;
    mapping (address => uint) bought;
    mapping (address => uint) sent;
    uint start;

    constructor(ERC20 _token, uint _vest){
        token = _token;
        vestDuration = _vest;
        dev = tx.origin;
        address[43] memory l = [  0x06d750Bf47589a7A6859A35F1398dD5C90Fac181,
            0x0b99363648eFEa66689d58a553bb015957083C57,
            0x11F4E3a68beb04A2B75d2f9fB3eB9F1f7a2139f2,
            0x1B59237D0cFF7b879f3A7C5045d30Ba3E9518D3F,
            0x1C86E98A4CC451db8A502f31c14327D2B7CEC123,
            0x1Cc2fc26183775D18b179F7238Fafab6aF96c16e,
            0x235eA8C4537303D1255f86E930ba3019cf4D2a1b,
            0x25F122472d6BF36c314797A575a35cEff924832B,
            0x2dc6860AfA78Bf650e31aDd119A716539cdD3F9b,
            0x3B69BE4932bb76255672C7b07f33B5B4Aa35a3Be,
            0x431b5DDB0AcE97eBC3d936403ea25831BaD832B6,
            0x4F0F20c412Db383F3F89A1d0Bc52Ae43A6CB1E98,
            0x56958F16098FeB35c1f489138861548b23258d73,
            0x5bb35d290ecc0f00A8C84b03E66D974b01D64AfB,
            0x616865017Fbc6CBc49610ea9CA614feF572232df,
            0x6767Bab6284F033a946Fe0ef46B0CFBADab6f40D,
            0x682c72e317Cf93A36Ace26d52f9eB9c41712e56C,
            0x6ACe206b3d969C8D17070f835518333f8A454Fb4,
            0x6Bd3CA523dB86c780eC279b52D26b8F5aFa327f8,
            0x6bf6dE62Ef0921a68712e3d1034E4c30f53dfAff,
            0x6c99a242b813dac80E770B1F6de88863A8118192,
            0x6cA2eE9507e3F59c25DB2c114d80E3f74002E7D2,
            0x6d8572A5eD95B437CD47bAD878Fd3654BC370615,
            0x6e190f1729dE7B965eccB4c4fF6a1Ce81AcBd3e4,
            0x732E10cd2aC0D2FB895f9a897fE5c3c23AE652fA,
            0x808DB09A91D11466Ea95DFBd458bB009fd62Db3c,
            0x8A62b587a26eD6752Eb5CBC82920d0A77A148332,
            0x8B38F093408605c82B99129cd440eFE8fDde361F,
            0x9368Fd936438ca20C6813a6B4e3D4C7a087A1eEe,
            0x98aecD4DFb836A2a460453A2AaAd4C660Cd03739,
            0x9A98c687a3623b280fDCD2a0dAc40ab45f07fE6d,
            0x9cc8d1A121b9C82212Bbc3f9782FDbcDfBA0C0Ef,
            0xa9aB31E27D22420e5B0916Af7898d36ED773ff8E,
            0xb87aaaaaa6BE7c809f2fde0e7f4b83d14743E030,
            0xd11DAf5E5288C556771E2bed59d50d51C4Dc8954,
            0xd48A5a5045cd6D7F1a6f079B80bDdc4CD25eFEAd,
            0xD5a66baDA4a62E59aeAf95c33268a5f77666F46C,
            0xDB97A4cBAAD62729Ee829892B9F9D0045aaeecF6,
            0xDCa3A92A58E2c19bcE477384a29622247ef5114D,
            0xe17E85E91B3c04025bAF4dd23AdCEdC7a7e7cE12,
            0xe1c9C17801089Abc6dE41106bFb5753D1AA26d2a,
            0xe32A4c7a2a5EfC52a79ccE5128189A5763589225,
            0xfd6c6F1B16672760a55F23a10101d9c8b7A710FB];
        uint88[43] memory am = [196929000000000000000000,
            408955890000000000000000,
            357754350000000000000000,
            164107500000000000000000,
            131286000000000000000000,
            131286000000000000000000,
            2215188678000000000000,
            65643000000000000000000,
            196929000000000000000000,
            1312860000000000000000000,
            65643000000000000000000,
            164107500000000000000000,
            131286000000000000000000,
            421470525748079000000000,
            787716000000000000000000,
            32821500000000000000000,
            196929000000000000000000,
            393858000000000000000000,
            3282150000000000000000000,
            525144000000000000000000,
            131286000000000000000000,
            328215000000000000000000,
            6557735700000000000000000,
            39385800000000000000000,
            190364700000000000000000,
            196929000000000000000000,
            539585460000000000000000,
            2192305904723760000000,
            6564300000000000000000000,
            127347420000000000000000,
            584222700000000000000000,
            669558600000000000000000,
            2012821504566660000000000,
            4145383020060000000000000,
            256007700000000000000000,
            24944340000000000000000,
            131286000000000000000000,
            334779300000000000000000,
            262572000000000000000000,
            131286000000000000000000,
            656430000000000000000000,
            45950100000000000000000,
            98464500000000000000000];
        for (uint i = 0; i < 42; i++){
            bought[l[i]] = uint(am[i]);
        }
        start = block.timestamp;
    }

    receive() external payable {
        revert("Presale has already ended!");
    }

    function _calcRetrievable(address who) internal view returns (uint am){
        uint timePercent = 50 + 50*(block.timestamp - start) / vestDuration;
        timePercent = timePercent > 100? 100 : timePercent;
        uint amount = (bought[who] * timePercent) / 100;
        uint toSend = amount - sent[who];
        return toSend;
    }

    function status(address who) public view returns (uint b, uint r) {
        return (bought[who], _calcRetrievable(who));
    }

    function retrieveToken() external{
        uint toSend = _calcRetrievable(msg.sender);
        sent[msg.sender] += toSend;
        token.transfer(msg.sender, toSend);
    }
}

contract invVest {
    ERC20 public immutable token;
    uint public immutable vestDuration;
    uint constant totAmount = 8855240700000000000000000;
    address constant investor = 0x8b187EA19C93091a4D6B426b71871648182b5Fac;
    uint public sent;
    uint start;

    constructor(ERC20 _token, uint _vest){
        token = _token;
        vestDuration = _vest;
        start = block.timestamp;
    }

    function calcRetrievable() public view returns (uint am){
        uint timePercent = 50 + 50*(block.timestamp - start) / vestDuration;
        timePercent = timePercent > 100? 100 : timePercent;
        uint amount = (totAmount * timePercent) / 100;
        uint toSend = amount - sent;
        return toSend;
    }

    function retrieveToken() external{
        uint toSend = calcRetrievable();
        sent += toSend;
        token.transfer(investor, toSend);
    }
}