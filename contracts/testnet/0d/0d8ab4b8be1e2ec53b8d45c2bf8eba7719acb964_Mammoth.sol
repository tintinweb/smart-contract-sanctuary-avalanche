/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-03
*/

// File: contracts/MMTH/InterfacesAggregated.sol


pragma solidity ^0.8.6;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ITreasury {
    function updateTaxesAccrued(uint taxType, uint amt) external;
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IWAVAX {
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external returns (bool);
}
// File: contracts/MMTH/Mammoth.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


/// @dev    The TaxToken is responsible for supporting generic ERC20 functionality including ERC20Pausable functionality.
///         The TaxToken will generate taxes on transfer() and transferFrom() calls for non-whitelisted addresses.
///         The Admin can specify the tax fee in basis points for buys, sells, and transfers.
///         The TaxToken will forward all taxes generated to a Treasury
contract Mammoth {
 
    // ---------------
    // State Variables
    // ---------------

    // ERC20 Basic
    uint256 _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    // ERC20 Pausable state
    bool private _paused;

    // Extras
    address public owner;
    address public treasury;
    address public constant UNIV2_ROUTER = 0x3fd46eB17365e38754d696C660a77c30f826B54D;

    bool public taxesRemoved;   /// @dev Once true, taxes are permanently set to 0 and CAN NOT be increased in the future.

    uint256 public maxWalletSize;
    uint256 public maxTxAmount;

    // ERC20 Mappings
    mapping(address => uint256) balances;                       // Track balances.
    mapping(address => mapping(address => uint256)) allowed;    // Track allowances.

    // Extras Mappings
    mapping(address => bool) public blacklist;                  /// @dev If an address is blacklisted, they cannot perform transfer() or transferFrom().
    mapping(address => bool) public whitelist;                  /// @dev Any transfer that involves a whitelisted address, will not incur a tax.
    mapping(address => uint) public senderTaxType;              /// @dev Identifies tax type for msg.sender of transfer() call.
    mapping(address => uint) public receiverTaxType;            /// @dev Identifies tax type for _to of transfer() call.
    mapping(uint => uint) public basisPointsTax;                /// @dev Mapping between taxType and basisPoints (taxed).
    mapping(address => uint) public industryTokens;             /// @dev Mapping of how many locked tokens exist in a wallet (In 18 decimal format).
    mapping(address => uint) public lifeTimeIndustryTokens;     /// @dev Mapping of how many locked tokens have ever been minted (In 18 decimal format).  
    mapping(address => bool) public authorized;                 /// @dev Mapping of which wallets are authorized to call specific functions.


    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the TaxToken.
    /// @dev _paused - ERC20 Pausable global state variable, initial state is not paused ("unpaused").
    /// @dev The "owner" is the "admin" of this contract.
    /// @dev Initial liquidity, allocated entirely to "owner".
    /// @param  totalSupplyInput    The total supply of this token (this value is multipled by 10**decimals in constructor).
    /// @param  nameInput           The name of this token.
    /// @param  symbolInput         The symbol of this token.
    /// @param  decimalsInput       The decimal precision of this token.
    /// @param  maxWalletSizeInput  The maximum wallet size (this value is multipled by 10**decimals in constructor).
    /// @param  maxTxAmountInput    The maximum tx size (this value is multipled by 10**decimals in constructor).
    constructor(
        uint totalSupplyInput, 
        string memory nameInput, 
        string memory symbolInput, 
        uint8 decimalsInput,
        uint256 maxWalletSizeInput,
        uint256 maxTxAmountInput
    ) {
        _paused = false;
        _name = nameInput;
        _symbol = symbolInput;
        _decimals = decimalsInput;
        _totalSupply = totalSupplyInput * 10**_decimals;

        // Create a uniswap pair for this new token.
        address UNISWAP_V2_PAIR = IUniswapV2Factory(
            IUniswapV2Router01(UNIV2_ROUTER).factory()
        ).createPair(address(this), IUniswapV2Router01(UNIV2_ROUTER).WAVAX());
 
        senderTaxType[UNISWAP_V2_PAIR] = 1;
        receiverTaxType[UNISWAP_V2_PAIR] = 2;

        owner = msg.sender;                                         
        balances[msg.sender] = totalSupplyInput * 10**_decimals;
        maxWalletSize = maxWalletSizeInput * 10**_decimals;
        maxTxAmount = maxTxAmountInput * 10**_decimals;

        // TODO: Add before main-net deployment.
        // modifyWhitelist(owner, true);
        // modifyWhitelist(address(0), true);
    }

 

    // ---------
    // Modifiers
    // ---------

    /// @dev whenNotPausedUni() is used if the contract MUST be paused ("paused").
    modifier whenNotPausedUni(address a) {
        require(!paused() || whitelist[a], "TaxToken.sol::whenNotPausedUni(), Contract is currently paused.");
        _;
    }

    /// @dev whenNotPausedDual() is used if the contract MUST be paused ("paused").
    modifier whenNotPausedDual(address _from, address _to) {
        require(!paused() || whitelist[_from] || whitelist[_to], "TaxToken.sol::whenNotPausedDual(), Contract is currently paused.");
        _;
    }

    /// @dev whenNotPausedTri() is used if the contract MUST be paused ("paused").
    modifier whenNotPausedTri(address _from, address _to, address _sender) {
        require(!paused() || whitelist[_from] || whitelist[_to] || whitelist[_sender], "TaxToken.sol::whenNotPausedTri(), Contract is currently paused.");
        _;
    }

    /// @dev whenPaused() is used if the contract MUST NOT be paused ("unpaused").
    modifier whenPaused() {
        require(paused(), "TaxToken.sol::whenPaused(), Contract is not currently paused.");
        _;
    }
    
    /// @dev onlyOwner() is used if msg.sender MUST be owner.
    modifier onlyOwner {
       require(msg.sender == owner, "TaxToken.sol::onlyOwner(), msg.sender != owner."); 
       _;
    }

    /// @dev isAuthorized() is used if msg.sender MUST be either the owner, or an authorized user/contract.
    modifier onlyAuthorized {
       require(msg.sender == owner || authorized[msg.sender] == true, "TaxToken.sol::onlyAuthorized(), msg.sender is not authorized."); 
       _;
    }


    // ------
    // Events
    // ------

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address _account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address _account);

    /// @dev Emitted when approve() is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);   
 
    /// @dev Emitted during transfer().
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @dev Emitted during transferFrom().
    event TransferTax(address indexed _from, address indexed _to, uint256 _value, uint256 _taxType);

    /// @dev Emitted when transferOwnership() is completed.
    event OwnershipTransferred(address indexed _currentAdmin, address indexed _newAdmin);

    /// @dev Emitted when updating authorized addresses (users or contracts).
    event UpdatedAuthorizedWallets(address indexed _account, bool _state);


    // ---------
    // Functions
    // ---------


    // ~ ERC20 View ~
    
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }
 
    // ~ ERC20 transfer(), transferFrom(), approve() ~

    function approve(address _spender, uint256 _amount) external returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function transfer(address _to, uint256 _amount) external whenNotPausedDual(msg.sender, _to) returns (bool success) {  

        // taxType 0 => Xfer Tax
        // taxType 1 => Buy Tax
        // taxType 2 => Sell Tax
        uint _taxType;

        if (balances[msg.sender] >= _amount) {

            // Take a tax from them if neither party is whitelisted.
            if (!whitelist[_to] && !whitelist[msg.sender]) {

                if ((_amount > maxTxAmount) || (blacklist[msg.sender] || blacklist[_to])) {
                    return false;
                }

                // Determine, if not the default 0, tax type of transfer.
                if (senderTaxType[msg.sender] != 0) {
                    _taxType = senderTaxType[msg.sender];
                }

                if (receiverTaxType[_to] != 0) {
                    _taxType = receiverTaxType[_to];
                }

                uint _taxAmt = _amount * basisPointsTax[_taxType] / 10000;
                uint _sendAmt = _amount - _taxAmt;

                if (balances[_to] + _sendAmt <= maxWalletSize) {

                    balances[msg.sender] -= _amount;
                    balances[_to] += _sendAmt;
                    balances[treasury] += _taxAmt;

                    require(_taxAmt + _sendAmt == _amount, "TaxToken::transfer(), Critical error - math.");
                
                    // Update accounting in Treasury.
                    ITreasury(treasury).updateTaxesAccrued(
                        _taxType, _taxAmt
                    );
                    
                    emit Transfer(msg.sender, _to, _sendAmt);
                    emit TransferTax(msg.sender, treasury, _taxAmt, _taxType);

                    return true;
                }
                else {
                    return false;
                }
            }
            // Skip taxation if either party is whitelisted (_from or _to).
            else {
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;
                emit Transfer(msg.sender, _to, _amount);
                return true;
            }
        }
        else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _amount) external whenNotPausedTri(_from, _to, msg.sender) returns (bool success) {

        // taxType 0 => Xfer Tax
        // taxType 1 => Buy Tax
        // taxType 2 => Sell Tax
        uint _taxType;

        if (
            balances[_from] >= _amount && 
            allowed[_from][msg.sender] >= _amount && 
            _amount > 0 && balances[_to] + _amount > balances[_to]
        ) {
            
            // Reduce allowance.
            allowed[_from][msg.sender] -= _amount;

            // Take a tax from them if neither party is whitelisted.
            if (!whitelist[_to] && !whitelist[_from]) {

                if ((_amount > maxTxAmount) || (blacklist[msg.sender] || blacklist[_to])) {
                    return false;
                }

                // Determine, if not the default 0, tax type of transfer.
                if (senderTaxType[_from] != 0) {
                    _taxType = senderTaxType[_from];
                }

                if (receiverTaxType[_to] != 0) {
                    _taxType = receiverTaxType[_to];
                }

                uint _taxAmt = _amount * basisPointsTax[_taxType] / 10000;
                uint _sendAmt = _amount - _taxAmt;

                if (balances[_to] + _sendAmt <= maxWalletSize || _taxType == 2) {

                    balances[_from] -= _amount;
                    balances[_to] += _sendAmt;
                    balances[treasury] += _taxAmt;

                    require(_taxAmt + _sendAmt == _amount, "TaxToken::transferFrom(), Critical error - math.");
                
                    // Update accounting in Treasury.
                    ITreasury(treasury).updateTaxesAccrued(
                        _taxType, _taxAmt
                    );
                    
                    emit Transfer(_from, _to, _sendAmt);
                    emit TransferTax(_from, treasury, _taxAmt, _taxType);

                    return true;
                }
                else {
                    return false;
                }
            }
            // Skip taxation if either party is whitelisted (_from or _to).
            else {
                balances[_from] -= _amount;
                balances[_to] += _amount;
                emit Transfer(_from, _to, _amount);
                return true;
            }
        }
        else {
            return false;
        }
    }
    
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    // ~ ERC20 Pausable ~

    /// @notice Pause the contract, blocks transfer() and transferFrom().
    /// @dev    Contract MUST NOT be paused to call this, caller must be "owner".
    function pause() external onlyOwner whenNotPausedUni(msg.sender) {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpause the contract.
    /// @dev    Contract MUST be paused to call this, caller must be "owner".
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @return _paused Indicates whether the contract is paused (true) or not paused (false).
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    // ~ TaxType & Fee Management ~

    /// @notice     Used to store the LP Pair to differ type of transaction. Will be used to mark a BUY.
    /// @dev        _taxType must be lower than 3 because there can only be 3 tax types; buy, sell, & send.
    /// @param      _sender This value is the PAIR address.
    /// @param      _taxType This value must be be 0, 1, or 2. Best to correspond value with the BUY tax type.
    function updateSenderTaxType(address _sender, uint _taxType) external onlyOwner {
        require(_taxType < 3, "TaxToken::updateSenderTaxType(), _taxType must be less than 3.");
        senderTaxType[_sender] = _taxType;
    }

    /// @notice     Used to store the LP Pair to differ type of transaction. Will be used to mark a SELL.
    /// @dev        _taxType must be lower than 3 because there can only be 3 tax types; buy, sell, & send.
    /// @param      _receiver This value is the PAIR address.
    /// @param      _taxType This value must be be 0, 1, or 2. Best to correspond value with the SELL tax type.
    function updateReceiverTaxType(address _receiver, uint _taxType) external onlyOwner {
        require(_taxType < 3, "TaxToken::updateReceiverTaxType(), _taxType must be less than 3.");
        receiverTaxType[_receiver] = _taxType;
    }

    /// @notice     Used to map the tax type 0, 1 or 2 with it's corresponding tax percentage.
    /// @dev        Must be lower than 2000 which is equivalent to 20%.
    /// @param      _taxType This value is the tax type. Has to be 0, 1, or 2.
    /// @param      _bpt This is the corresponding percentage that is taken for royalties. 1200 = 12%.
    function adjustBasisPointsTax(uint _taxType, uint _bpt) external onlyOwner {
        require(_bpt <= 2000, "TaxToken.sol::adjustBasisPointsTax(), _bpt > 2000 (20%).");
        require(!taxesRemoved, "TaxToken.sol::adjustBasisPointsTax(), Taxation has been removed.");
        basisPointsTax[_taxType] = _bpt;
    }

    /// @notice Permanently remove taxes from this contract.
    /// @dev    An input is required here for sanity-check, given importance of this function call (and irreversible nature).
    /// @param  _key This value MUST equal 42 for function to execute.
    function permanentlyRemoveTaxes(uint _key) external onlyOwner {
        require(_key == 42, "TaxToken::permanentlyRemoveTaxes(), _key != 42.");
        basisPointsTax[0] = 0;
        basisPointsTax[1] = 0;
        basisPointsTax[2] = 0;
        taxesRemoved = true;
    }


    // ~ Admin ~

    /// @notice This is used to change the owner's wallet address. Used to give ownership to another wallet.
    /// @param  _owner is the new owner address.
    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "TaxToken.sol::transferOwnership(), _owner == 0.");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    /// @notice This is used to change the owner's wallet address. Used to give ownership to another wallet.
    /// @param  _account is the address that will change from authorized or not.
    /// @param  _state (True or False) If true, _account is authorized, if false, _account is not authorized.
    function updateAuthorizedList(address _account, bool _state) external onlyOwner {
        require(_account != address(0), "TaxToken.sol::updateAuthorizedList(), _owner == 0.");
        emit UpdatedAuthorizedWallets(_account, _state);
        authorized[_account] = _state;
    }

    /// @notice Set the treasury (contract) which receives taxes generated through transfer() and transferFrom().
    /// @param  _treasury is the contract address of the treasury.
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        modifyWhitelist(treasury, true);
    }

    /// @notice Adjust maxTxAmount value (maximum amount transferrable in a single transaction).
    /// @dev    Does not affect whitelisted wallets.
    /// @param  _maxTxAmount is the max amount of tokens that can be transacted at one time for a non-whitelisted wallet.
    function updateMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = (_maxTxAmount * 10**_decimals);
    }

    /// @notice This function is used to set the max amount of tokens a wallet can hold.
    /// @dev    Does not affect whitelisted wallets.
    /// @param  _maxWalletSize is the max amount of tokens that can be held on a non-whitelisted wallet.
    function updateMaxWalletSize(uint256 _maxWalletSize) external onlyOwner {
        maxWalletSize = (_maxWalletSize * 10**_decimals);
    }

    /// @notice This function is used to add wallets to the whitelist mapping.
    /// @dev    Whitelisted wallets are not affected by maxWalletSize, maxTxAmount, and taxes.
    /// @param  _wallet is the wallet address that will have their whitelist status modified.
    /// @param  _whitelist use True to whitelist a wallet, otherwise use False to remove wallet from whitelist.
    function modifyWhitelist(address _wallet, bool _whitelist) public onlyOwner {
        whitelist[_wallet] = _whitelist;
    }

    /// @notice This function is used to add or remove wallets from the blacklist.
    /// @dev    Blacklisted wallets cannot perform transfer() or transferFrom().
    ///         unless it's to or from a whitelisted wallet.
    /// @param  _wallet is the wallet address that will have their blacklist status modified.
    /// @param  _blacklist use True to blacklist a wallet, otherwise use False to remove wallet from blacklist.
    function modifyBlacklist(address _wallet, bool _blacklist) external onlyOwner {
        require(!whitelist[_wallet], "TaxToken.sol::modifyBlacklist(), Cannot blacklist a whitelisted wallet.");
        blacklist[_wallet] = _blacklist;
    }
    
    /// @notice This function will create new tokens and adding them to total supply.
    /// @dev    Does not truncate so amount needs to include the 18 decimal points.
    /// @param  _wallet the account we're minting tokens to.
    /// @param  _amount the amount of tokens we're minting.
    function mint(address _wallet, uint256 _amount) public onlyAuthorized() {
        require(_wallet != address(0), "TaxToken.sol::mint(), Cannot mint to zero address.");

        _totalSupply += _amount;
        balances[_wallet] += _amount;

        emit Transfer(address(0), _wallet, _amount);
    }

    /// @notice This function is used to mint tokens and log their creation to the industry wallet mappings.
    /// @dev    Any tokens minted through this process can only be used inside of the NFT marketplace to mint new NFTS (can only be burned).
    /// @dev    Users may still buy and sell new or prior existing non-minted tokens but these will be soulbound. 
    /// @dev    Does not truncate so amount needs to include the 18 decimal points.
    /// @param  _wallet is the wallet address that will recieve these minted tokens.
    /// @param  _amount is the amount of tokens to be minted into _wallet.
    function industryMint(address _wallet, uint256 _amount) external onlyAuthorized {
        mint(_wallet, _amount);

        industryTokens[_wallet] += _amount;
        lifeTimeIndustryTokens[_wallet] += _amount;
    }

    /// @notice This function will destroy existing tokens and deduct them from total supply.
    /// @dev    Does not truncate so amount needs to include the 18 decimal points.
    /// @param  _wallet the account we're burning tokens from.
    /// @param  _amount the amount of tokens we're burning.
    function burn(address _wallet, uint256 _amount) public onlyAuthorized() {
        require(_wallet != address(0), "TaxToken.sol::burn(), Cannot burn to zero address.");
        uint256 accountBalance = balances[_wallet];
        require(accountBalance >= _amount, "TaxToken.sol::burn(), Burn amount exceeds balance.");

        balances[_wallet] = accountBalance - _amount;
        _totalSupply -= _amount;
        
        emit Transfer(_wallet, address(0), _amount);
    }

    /// @notice This function will destroy existing tokens and deduct them from total supply.
    /// @dev    Does not truncate so amount needs to include the 18 decimal points.    
    /// @param  _wallet the account we're burning tokens from.
    /// @param  _amount the amount of tokens we're burning.
    function industryBurn(address _wallet, uint256 _amount) external onlyAuthorized {
        require(_wallet != address(0), "TaxToken.sol::industryBurn(), Cannot burn to zero address.");
        require(balances[_wallet] >= _amount, "TaxToken.sol::industryBurn(), Insufficient balance of $PROVE to burn.");

        if (industryTokens[_wallet] >= _amount) {
            burn(_wallet, _amount);
            industryTokens[_wallet] -= _amount;

        } else {
            burn(_wallet, _amount);
            industryTokens[_wallet] = 0;

        }
    }

    /// @notice This function is a VIEW function that returns the amount of industry tokens,
    ///         full balance, and normal tokens a wallet has.
    /// @dev    This function is for the front end to pull industry data for a specific wallet.
    /// @return numTokens the amount of taxTokens the _wallet holds.
    /// @return numIndustryTokens the amount of tokens they hold that is industry tokens.
    /// @return numDifference the amount of tokens they have that are NOT industry tokens.
    /// @return lifetime the amount of industry tokens that have been minted to _wallet in total.
    function getIndustryTokens(address _wallet) external view returns (uint numTokens, uint numIndustryTokens, uint numDifference, uint lifetime) {
        uint fullBalance = IERC20(address(this)).balanceOf(_wallet);
        uint industryBalance = industryTokens[_wallet];
        uint difference = fullBalance - industryBalance;

        return (fullBalance, industryBalance, difference, lifeTimeIndustryTokens[_wallet]);
    }
}