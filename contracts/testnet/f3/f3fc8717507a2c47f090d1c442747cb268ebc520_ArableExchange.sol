// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IArableOracle.sol";
import "./interfaces/IArableSynth.sol";
import "./interfaces/IArableManager.sol";
import "./interfaces/IArableAddressRegistry.sol";
import "./interfaces/IArableFeeCollector.sol";
import "./interfaces/IArableCollateral.sol";
import "./libs/ArableFees.sol";

// Implement swap between two synths based on exchange rate on oracle
contract ArableExchange is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    string private constant _arUSD = "arUSD";
    address public addressRegistry;
    uint256 public assetProtectionTime;
    mapping(address => uint256) public tokenPurchasePrice;
    mapping(address => uint256) public tokenPurchaseTimestamp;
    uint256 public offchainAssetProtectionTime; // to set to 20 mins on upgrade
    uint256 public offchainValidTimestampOffset; // to set to 30s on upgrade
    bool public onChainTradingAllowedForEveryone; // to set to false on upgrade
    mapping(address => bool) public onChainTradingAllowedAddress;

    uint256 public usdLimitPerTrading; // $1 = 1ether

    event Swap(address inToken, uint256 inAmount, address outToken, uint256 outAmount, uint256 inFeeAmount);
    event Pause();
    event Unpause();

    function initialize(address addressRegistry_) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init();
        __Pausable_init_unchained();

        require(addressRegistry_ != address(0), "Invalid addressRegistry_");

        addressRegistry = addressRegistry_;
    }

    function setMEVProtectionTime(uint256 interval) external onlyOwner {
        assetProtectionTime = interval;
    }

    function setOffchainAssetProtectionTime(uint256 interval) external onlyOwner {
        offchainAssetProtectionTime = interval;
    }

    function setoffchainValidTimestampOffset(uint256 offset) external onlyOwner {
        offchainValidTimestampOffset = offset;
    }

    function setOnChainTradingAllowedForEveryone(bool allowed) external onlyOwner {
        onChainTradingAllowedForEveryone = allowed;
    }

    function setBulkOnChainTradingAllowedAddress(address[] calldata addresses, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            onChainTradingAllowedAddress[addresses[i]] = allowed;
        }
    }

    function setUsdLimitPerTrading(uint256 _usdLimitPerTrading) external onlyOwner {
        usdLimitPerTrading = _usdLimitPerTrading;
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    /**
     * @notice convert fees to arUSD
     */
    function convertFeesToUsd(address inToken, uint256 inAmount) external whenNotPaused {
        address feeCollectorAddress = IArableAddressRegistry(addressRegistry).getArableFeeCollector();
        require(msg.sender == feeCollectorAddress, "caller is not the fee collector");

        require(inToken != address(0x0), "inToken should be set");
        require(inAmount != 0, "In amount should not be ZERO");
        address manager = IArableAddressRegistry(addressRegistry).getArableManager();
        IArableManager managerContract = IArableManager(manager);
        address arUSD = managerContract.getSynthAddress(_arUSD);

        if (inToken == arUSD) {
            return;
        }

        address oracle = IArableAddressRegistry(addressRegistry).getArableOracle();
        IArableOracle oracleContract = IArableOracle(oracle);
        uint256 inTokenPrice = oracleContract.getPrice(inToken);
        require(inTokenPrice != 0, "inToken price should be set");

        // send tokens to the contract
        IERC20(inToken).transferFrom(msg.sender, address(this), inAmount);

        uint256 outAmount = (inTokenPrice * (inAmount)) / 1 ether;
        IArableSynth(inToken).burn(inAmount);
        IArableSynth(arUSD).mint(msg.sender, outAmount);
    }

    function getPriceMessage(
        address token,
        uint256 price,
        uint256 timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, price, timestamp));
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function getSigner(bytes32 message, bytes memory signature) public pure returns (address _signer) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    /**
     * @notice swap inAmount of inToken to outToken
     */
    function swapSynthsOnChainPrice(
        address inToken,
        uint256 inAmount,
        address outToken
    ) external nonReentrant whenNotPaused {
        require(inToken != address(0x0), "inToken should be set");
        require(outToken != address(0x0), "outToken should be set");
        require(inAmount != 0, "In amount should not be ZERO");
        bool tradingAllowed = onChainTradingAllowedForEveryone || onChainTradingAllowedAddress[msg.sender];
        require(tradingAllowed, "not allowed for on-chain price trading");

        IArableManager managerContract = IArableManager(IArableAddressRegistry(addressRegistry).getArableManager());
        require(managerContract.isEnabledSynth(inToken), "inToken should be enabled synth");
        require(managerContract.isEnabledSynth(outToken), "outToken should be enabled synth");

        IArableOracle oracleContract = IArableOracle(IArableAddressRegistry(addressRegistry).getArableOracle());
        uint256 inTokenPrice = oracleContract.getPrice(inToken);
        uint256 outTokenPrice = oracleContract.getPrice(outToken);

        require(inTokenPrice != 0, "inToken price should be set");
        require(outTokenPrice != 0, "outToken price should be set");

        require((inAmount * inTokenPrice) / 1 ether <= usdLimitPerTrading, "Too much amount");

        // send tokens to the contract
        IERC20(inToken).transferFrom(msg.sender, address(this), inAmount);

        // pay swap fees
        uint256 fees = payFeesFor(inToken, inAmount, msg.sender, ArableFees.Model.SYNTHS_X);

        // if token purchase record in protection time is lower than the current sell price,
        // it set sell price of inToken to purchase price for MEV protection
        uint256 effectiveInTokenPrice = inTokenPrice;
        if (
            tokenPurchaseTimestamp[inToken] > 0 &&
            tokenPurchaseTimestamp[inToken] + assetProtectionTime >= block.timestamp &&
            tokenPurchasePrice[inToken] < inTokenPrice
        ) {
            effectiveInTokenPrice = tokenPurchasePrice[inToken];
            address collateral = IArableAddressRegistry(addressRegistry).getArableCollateral();
            IArableCollateral collateralContract = IArableCollateral(collateral);
            // debt is reduced when MEV protection mechanism is executed
            collateralContract.removeFromDebt(((inTokenPrice - effectiveInTokenPrice) * (inAmount - fees)) / 1 ether);
        }

        uint256 outAmount = (effectiveInTokenPrice * (inAmount - fees)) / outTokenPrice;

        IArableSynth(inToken).burn(inAmount - fees);
        IArableSynth(outToken).mint(msg.sender, outAmount);

        // if protection time passed or token price is lower than previous purchase price, update it.
        if (
            tokenPurchaseTimestamp[outToken] + assetProtectionTime <= block.timestamp ||
            tokenPurchasePrice[outToken] > outTokenPrice
        ) {
            tokenPurchasePrice[outToken] = outTokenPrice;
            tokenPurchaseTimestamp[outToken] = block.timestamp;
        }
        emit Swap(inToken, inAmount, outToken, outAmount, fees);
    }

    function _verifySignature(
        address token,
        uint256 price,
        uint256 timestamp,
        bytes memory signature
    ) internal view {
        IArableManager managerContract = IArableManager(IArableAddressRegistry(addressRegistry).getArableManager());

        require(managerContract.isEnabledSynth(token), "Invalid synth token");

        address arUSD = managerContract.getSynthAddress(_arUSD);

        IArableOracle oracleContract = IArableOracle(IArableAddressRegistry(addressRegistry).getArableOracle());

        if (token != arUSD) {
            address _signer = getSigner(getPriceMessage(token, price, timestamp), signature);
            require(oracleContract.isAllowedProvider(_signer), "Invalid getSigner");
        }
    }

    function isArUsd(address token) internal view returns (bool) {
        IArableManager managerContract = IArableManager(IArableAddressRegistry(addressRegistry).getArableManager());

        address arUSD = managerContract.getSynthAddress(_arUSD);
        return token == arUSD;
    }

    function _executeOffchainPriceSwap(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 inTokenPrice,
        uint256 outTokenPrice,
        uint256 timestamp
    ) internal {
        require(
            IArableManager(IArableAddressRegistry(addressRegistry).getArableManager()).isEnabledSynth(inToken),
            "inToken should be enabled synth"
        );
        require(
            IArableManager(IArableAddressRegistry(addressRegistry).getArableManager()).isEnabledSynth(outToken),
            "outToken should be enabled synth"
        );

        uint256 oracleInTokenPrice = IArableOracle(IArableAddressRegistry(addressRegistry).getArableOracle()).getPrice(
            inToken
        );
        uint256 oracleOutTokenPrice = IArableOracle(IArableAddressRegistry(addressRegistry).getArableOracle()).getPrice(
            outToken
        );

        require(oracleInTokenPrice != 0, "inToken price should be set");
        require(oracleOutTokenPrice != 0, "outToken price should be set");

        // check EIP712 signature for in token price
        if (isArUsd(inToken)) {
            inTokenPrice = 1 ether;
        }

        if (isArUsd(outToken)) {
            outTokenPrice = 1 ether;
        }

        require((inAmount * inTokenPrice) / 1 ether <= usdLimitPerTrading, "Exchange amount is too much");
        // verify timestamp is within validTimestampOffset
        require(timestamp + offchainValidTimestampOffset >= block.timestamp, "Old timestamp");

        // send tokens to the contract
        IERC20(inToken).transferFrom(msg.sender, address(this), inAmount);

        // pay swap fees
        uint256 fees = payFeesFor(inToken, inAmount, msg.sender, ArableFees.Model.SYNTHS_X);

        // if token purchase record in protection time is lower than the current sell price,
        // it set sell price of inToken to purchase price for MEV protection
        uint256 effectiveInTokenPrice = inTokenPrice;
        if (
            tokenPurchaseTimestamp[inToken] > 0 &&
            tokenPurchaseTimestamp[inToken] + offchainAssetProtectionTime >= block.timestamp &&
            tokenPurchasePrice[inToken] < inTokenPrice
        ) {
            effectiveInTokenPrice = tokenPurchasePrice[inToken];
        }

        uint256 outAmount = (effectiveInTokenPrice * (inAmount - fees)) / outTokenPrice;

        IArableCollateral collateralContract = IArableCollateral(
            IArableAddressRegistry(addressRegistry).getArableCollateral()
        );
        collateralContract.addToDebt((oracleOutTokenPrice * outAmount) / 1 ether);
        collateralContract.removeFromDebt((oracleInTokenPrice * (inAmount - fees)) / 1 ether);

        IArableSynth(inToken).burn(inAmount - fees);
        IArableSynth(outToken).mint(msg.sender, outAmount);

        // if protection time passed or token price is lower than previous purchase price, update it.
        if (
            tokenPurchaseTimestamp[outToken] + offchainAssetProtectionTime <= block.timestamp ||
            tokenPurchasePrice[outToken] > outTokenPrice
        ) {
            tokenPurchasePrice[outToken] = outTokenPrice;
            tokenPurchaseTimestamp[outToken] = block.timestamp;
        }
        emit Swap(inToken, inAmount, outToken, outAmount, fees);
    }

    /**
     * @notice swap inAmount of inToken to outToken
     */
    function swapSynthsOffchainPrice(
        address inToken,
        uint256 inAmount,
        address outToken,
        uint256 inTokenPrice,
        uint256 outTokenPrice,
        uint256 timestamp,
        bytes calldata inTokenSignature,
        bytes calldata outTokenSignature
    ) external nonReentrant whenNotPaused {
        require(inToken != address(0x0), "inToken should be set");
        require(outToken != address(0x0), "outToken should be set");
        require(inTokenPrice != 0, "inToken price should be set");
        require(outTokenPrice != 0, "outToken price should be set");
        require(inAmount != 0, "In amount should not be ZERO");

        _verifySignature(inToken, inTokenPrice, timestamp, inTokenSignature);
        _verifySignature(outToken, outTokenPrice, timestamp, outTokenSignature);

        _executeOffchainPriceSwap(inToken, inAmount, outToken, inTokenPrice, outTokenPrice, timestamp);
    }

    function payFeesFor(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) internal returns (uint256) {
        // collect fees for farm enter fee
        address feeCollectorAddress = IArableAddressRegistry(addressRegistry).getArableFeeCollector();
        IArableFeeCollector arableCollector = IArableFeeCollector(feeCollectorAddress);

        uint256 fees = arableCollector.calculateFees(asset_, amount_, account_, model_);
        IERC20(asset_).approve(feeCollectorAddress, fees);
        arableCollector.payFeesFor(asset_, amount_, account_, model_);

        return fees;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableOracle {
    function getPrice(address token) external view returns (uint256);
    function getDailyRewardRate(uint256 farmId, address rewardToken) external view returns (uint256);
    function registerPrice(address token_, uint256 price_) external;
    function registerRewardRate(
        uint256 farmId_,
        address token_,
        uint256 dailyRewardRate_
    ) external;
    function isAllowedProvider(address provider) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArableSynth is IERC20 {
    function mint(address toAddress, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function safeMint(address toAddress, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableManager {
    function isSynth(address _token) external view returns (bool);
    function isSynthDisabled(address _token) external view returns (bool);
    function isEnabledSynth(address _token) external view returns (bool);
    function getSynthAddress(string memory tokenSymbol) external view returns (address);
    function onAssetPriceChange(address asset, uint256 oldPrice, uint256 newPrice) external;
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

/**
 * @title Provider interface for Arable
 * @dev
 */
interface IArableAddressRegistry {
    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address address_) external;

    function getArableOracle() external view returns (address);

    function setArableOracle(address arableOracle_) external;

    function getArableExchange() external view returns (address);

    function setArableExchange(address arableExchange_) external;

    function getArableManager() external view returns (address);

    function setArableManager(address arableManager_) external;

    function getArableFarming() external view returns (address);

    function setArableFarming(address arableFarming_) external;

    function getArableCollateral() external view returns (address);

    function setArableCollateral(address arableCollateral_) external;

    function getArableLiquidation() external view returns (address);

    function setArableLiquidation(address arableLiquidation_) external;

    function getArableFeeCollector() external view returns (address);

    function setArableFeeCollector(address arableFeeCollector_) external;
}

// interfaces/IArableFeeCollector.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libs/ArableFees.sol"; 

interface IArableFeeCollector {
    function calculateFees(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external view returns (uint256 fees);

    function setAssetFeeModel(
        address asset_,
        uint256 fees_,
        ArableFees.Model model_
    ) external;

    function payFeesFor(
        address asset_,
        uint256 amount_,
        address account_,
        ArableFees.Model model_
    ) external returns (uint256[] memory collectorReceipt);

    function setRewardTokens(address[] memory _rewardTokens) external;

    function deleteRewardTokens() external;

    function startNewEpoch() external;

    function increaseMinterRewards(address minter, address rewardToken, uint256 amount) external;

    function bulkIncreaseMinterRewards(
        address rewardToken,
        address[] calldata minters,
        uint256[] calldata amounts
    ) external;

    function claimReward(address rewardToken) external;

    function estimatedReward(address minter, address rewardToken) external view returns (uint256);

    function getTotalDistributableRewards(address rewardToken) external view  returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IArableCollateral {
    function addToDebt(uint amount) external returns (bool);
    function removeFromDebt(uint256 amount) external returns (bool);
    function getTotalDebt() external returns (uint);
    function addSupportedCollateral(address token, uint allowedRate) external returns (bool);
    function removeSupportedCollateral(address token) external returns (bool);
    function changeAllowedRate(address token, uint newAllowedRate) external returns (bool);
    function userRiskRate(address user) external view returns (uint256);
    function maxIssuableArUSD(address user) external view returns (uint);
    function currentDebt(address user) external view returns (uint);
    function calculateCollateralValue(address user) external view returns (uint);
    function _liquidateCollateral(address user, address beneficiary, uint liquidationAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ArableFees {
    enum Model {
        DEFAULT,           // default fees if asset is unknow (0)
        SETUP_FARM,        // new farm fees
        EXIT_FARM,         // exit farm fees
        REWARD,            // reward fees
        SYNTHS_X,          // synthetic asset exchange fees
        SYNTHS_MINT,       // synthetic asset mint fees
        SYNTHS_BURN,       // synthetic asset burn fees
        LIQUIDATE,         // liquidation fees
        MAX                // maximumn value (8)
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}