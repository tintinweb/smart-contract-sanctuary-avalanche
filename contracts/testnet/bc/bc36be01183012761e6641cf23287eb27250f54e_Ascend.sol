/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-24
*/

/**
 *Submitted for verification at snowtrace.io on 2022-03-09
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: Ascend.sol



pragma solidity >=0.6.0 <0.9.0;





  contract Ascend is IERC20, IERC20Metadata, Ownable {

    mapping (address => uint256) _tOwned;

    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExcluded;
    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;

    string constant private _name = "Ascend";
    string constant private _symbol = "ASND";
    uint8 private _decimals = 18;
    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private sameBlockActive = true;
    bool private sniperProtection = true;
    uint256 private _liqAddBlock = 0;

    address public currentRouter;
    mapping (address => bool) lpPairs;
    address public lpPair;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address private zero = 0x0000000000000000000000000000000000000000;

    uint256 public maxTxAmount;
    uint256 public maxWalletSize;
    uint256 public swapThreshold;
    bool inSwap;
    bool public tradingEnabled = false;
    bool public hasLiqBeenAdded = false;
    bool public isTransferFeeEnabled = false;

    //bool public transfersForNodeOwnersOnly = false;

    IERC721 public ascend_membership;
    IERC721 public platinum_membership;
    IERC721 public infinite_membership;
    IERC721 public meta_membership;


    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

   struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
        uint16 protocolFee;
    }

    Fees public _taxRates = Fees({
            buyFee: 0,
            sellFee: 10,
            transferFee: 40,
            protocolFee: 0
    });

    struct StaticValuesStruct {
        uint16 maxBuyTaxes;
        uint16 maxSellTaxes;
        uint16 maxTransferTaxes;
        uint16 masterTaxDivisor;
    }

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxBuyTaxes: 10,
        maxSellTaxes: 20,
        maxTransferTaxes: 50,
        masterTaxDivisor: 100
    });

    struct Ratios {
        uint16 rewards;
        uint16 liquidity;
        uint16 metaFund;
        uint16 treasury;
        uint16 total;
    }

    Ratios public _ratios = Ratios({
        rewards: 30,
        liquidity: 10,
        metaFund: 5,
        treasury: 55,
        total: 100
    });



    event ContractSwapEnabledUpdated(bool enabled);
    event TransferFees(uint256 amount);
    event SniperCaught(address sniperAddress);

    uint256  public startingSupply;
    uint256 private _tTotal;

    address payable public metaFundWallet;
    address payable private rewardsPool;
    address payable private treasuryWallet;
    address payable private liquidityWallet;



    constructor (address _currentRouter, uint256 _startingSupply) {
        startingSupply = _startingSupply;
        _tTotal = _startingSupply * (10 ** _decimals);
        address msgSender = msg.sender;
        _tOwned[msgSender] = _tTotal;
         //Trader Joe testnet  0x5db0735cf88F85E78ed742215090c465979B5006
         //Trader Joe mainet 0x60aE616a2155Ee3d9A68541Ba4544862310933d4


        maxTxAmount = (_tTotal * 11) / 10000;
        maxWalletSize = (_tTotal * 11) / 10000;
        swapThreshold = (_tTotal ) / 10000;

        currentRouter = _currentRouter;
        _approve(msg.sender, currentRouter, type(uint256).max);
        _approve(address(this), currentRouter, type(uint256).max);
        _isFeeExcluded[msg.sender] = true;
        _isFeeExcluded[address(this)] = true;
        emit Transfer(zero, msg.sender, _tTotal);
        emit OwnershipTransferred(address(0), msgSender);
    }


    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled = false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "Cannot set a new pair this week!");
            }
            lpPair = pair;
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            _liqAddBlock = block.number;
            //_liquidityHolders[from] = true;
            hasLiqBeenAdded = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }



    function setTaxes(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee, uint16 _protocolFee) external onlyOwner {
        require(_buyFee <= staticVals.maxBuyTaxes
                && _sellFee <= staticVals.maxSellTaxes
                && _transferFee <= staticVals.maxTransferTaxes);
        _taxRates = Fees({
                buyFee: _buyFee,
                sellFee: _sellFee,
                transferFee: _transferFee,
                protocolFee: _protocolFee
        });
    }

    function setTransferFeeEnabled(bool _isTransferFeeEnabled) external onlyOwner {
      isTransferFeeEnabled = _isTransferFeeEnabled;
    }

    function setRatios(uint16 _rewards, uint16 _liquidity, uint16 _metaFund, uint16 _treasury) external onlyOwner {
        _ratios = Ratios({
            rewards: _rewards,
            liquidity: _liquidity,
            metaFund: _metaFund,
            treasury: _treasury,
            total: _rewards + _liquidity + _metaFund + _treasury
        });
    }

    function setStaticValues(uint16 _maxBuyTaxes, uint16 _maxSellTaxes, uint16 _maxTransferTaxes, uint16 _masterTaxDivisor) public onlyOwner{
        // 20, 20, 40, 100
        staticVals = StaticValuesStruct({
            maxBuyTaxes: _maxBuyTaxes,
            maxSellTaxes: _maxSellTaxes,
            maxTransferTaxes: _maxTransferTaxes,
            masterTaxDivisor: _masterTaxDivisor
        });
    }

    function setNewMemberships(address _ascend, address _platinum, address _infinite, address _meta) external onlyOwner {
         ascend_membership = IERC721(_ascend);
         platinum_membership = IERC721(_platinum);
         infinite_membership = IERC721(_infinite);
         meta_membership = IERC721(_meta);
     }

    function hasNodes(address from) public view returns (bool) {
      if (ascend_membership.balanceOf(from) > 0 || platinum_membership.balanceOf(from) > 0
         || infinite_membership.balanceOf(from) > 0 || meta_membership.balanceOf(from) > 0 ){
          return true;
      }
      return false;
    }

    receive() external payable {}


    function decimals() external override view returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function nodeApprove(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(currentRouter), type(uint256).max);
        return true;
    }

    function setStartingProtections(uint8 _block) external onlyOwner{
        require (snipeBlockAmt == 0 && _block <= 5 && !hasLiqBeenAdded, "invalid parameter >5, or liquidity added, ");
        snipeBlockAmt = _block;
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        sameBlockActive = antiBlock;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transfer(sender, recipient, amount);
    }

    function changeRouterContingency(address router) external onlyOwner {
        require(!hasLiqBeenAdded);
        currentRouter = router;
    }

    function isFeeExcluded(address account) public view returns(bool) {
        return _isFeeExcluded[account];
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(hasLiqBeenAdded, "Liquidity must be added.");
        _liqAddBlock = block.number;
        tradingEnabled = true;
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isFeeExcluded[account] = enabled;
    }

    function setWallets(address payable metaFund, address payable treasury, address payable _rewardsPool, address _liquidityWallet) external onlyOwner {
        metaFundWallet = payable(metaFund);
        treasuryWallet = payable(treasury);
        rewardsPool = payable(_rewardsPool);
        liquidityWallet = payable(_liquidityWallet);
    }


    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        //require((_tTotal * percent) / divisor >= (_tTotal / 10000), "Max Transaction amt must be above 0.01% of total supply.");
        maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        //require((_tTotal * percent) / divisor >= (_tTotal / 10000), "Max Wallet amt must be above 0.01% of total supply.");
        maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() external view returns (uint256) {
        return maxTxAmount;
    }

    function getMaxWallet() external view returns (uint256) {
        return maxWalletSize;
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && tx.origin != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(_hasLimits(from, to) && hasLiqBeenAdded) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(lpPairs[from] || lpPairs[to]){
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
            if(to != currentRouter && !lpPairs[to]) {
                require(balanceOf(to) + amount <= maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        if(_isFeeExcluded[from] || _isFeeExcluded[to]){
            takeFee = false;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) internal returns (bool) {
        

        _tOwned[from] -= amount;

        if (inSwap || !hasLiqBeenAdded) {
            return _basicTransfer(from, to, amount);
        }

        uint256 amountReceived = amount;
        if (takeFee) {
            amountReceived = takeTaxes(from, to, amount);
        }
        _tOwned[to] += amountReceived;

        uint256 contractTokenBalance = _tOwned[address(this)];

        if (!inSwap
            && !lpPairs[from]
            && contractTokenBalance >= swapThreshold
        ) {
            contractTransfer(contractTokenBalance);
            _tOwned[address(this)] -= contractTokenBalance;
            emit TransferFees(contractTokenBalance);
        }

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _tOwned[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (from == lpPair) {
            currentFee = _taxRates.buyFee;
        } else if (to == lpPair) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
            if (!isTransferFeeEnabled ){
                return amount;
            }
        }
        if (currentFee == 0) {
            return amount;
        }

        uint256 feeAmount = amount * currentFee / staticVals.masterTaxDivisor;
        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function contractTransfer(uint256 numTokensToSwap) internal swapping {
        if (_ratios.total == 0) {
            return;
        }

        IERC20 ASCENDTOKEN = IERC20(address(this));

        uint256 amountToLiquify = ((numTokensToSwap * _ratios.liquidity) / (_ratios.total));
        if(amountToLiquify > 0){
            ASCENDTOKEN.transfer(liquidityWallet, amountToLiquify);
        }

        uint256 amountToRewards = ((numTokensToSwap * _ratios.rewards) / (_ratios.total));
        if(amountToRewards > 0) {
            ASCENDTOKEN.transfer(rewardsPool, amountToRewards);
        }

        uint256 amountToTreasury = ((numTokensToSwap * _ratios.treasury) / (_ratios.total));
        if(amountToTreasury > 0) {
            ASCENDTOKEN.transfer(treasuryWallet, amountToTreasury);
        }

        uint256 amountToMetaFund = ((numTokensToSwap * _ratios.metaFund) / (_ratios.total));
        if(amountToMetaFund > 0) {
            ASCENDTOKEN.transfer(metaFundWallet, amountToMetaFund);
        }
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[msg.sender] >= amounts[i], "Insuficient balance ");
            _transfer(msg.sender, accounts[i], amounts[i]*10**_decimals);
        }
    }

    function multiSendPercents(address[] memory accounts, uint256[] memory percents, uint256[] memory divisors) external {
        require(accounts.length == percents.length && percents.length == divisors.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[msg.sender] >= (_tTotal * percents[i]) / divisors[i], "Insuficient balance ");
            _transfer(msg.sender, accounts[i], (_tTotal * percents[i]) / divisors[i]);
        }
    }
}