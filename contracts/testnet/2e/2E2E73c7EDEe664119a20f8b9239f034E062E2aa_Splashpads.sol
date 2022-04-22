/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.8.13;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferAVAX: AVAX transfer failed');
    }
}

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

interface IPangolinRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISwapper {
    function sendTaxToWell(uint256 _amount) external;
    function senderAddress() external view returns (address sender);
}

contract Splashpads is OwnableUpgradeable {

    enum TaxState {withTax, withoutTax}
    
    TaxState public taxState;
    
    struct Deposit {
        uint256 id;
        uint256 amount;
        address owner;
        uint256 payout;
        uint256 depositTime;
        uint256 claimTime;
        uint256 rollTime;
    }
    struct User {
        uint256 payouts;
        uint256 deposits;
        uint256 lastDepositTime;
        uint256 lastClaimTime;
        uint256 lastRollTime;
        uint256[] depositsIds;
        uint256 depositsCount;
    }
    mapping(address => User) public users;
    mapping(uint256 => Deposit) public deposits;
    
    uint256 public depositsCount;
    uint256 public totalDeposits;
    uint256 public totalPayouts;

    ISwapper private Swapper;
    IERC20 public USDT;
    IERC20 public splashToken;
    IERC20 public LPToken;

    /*****TAXES****/
    uint256 public depositTax;
    uint256 public claimTax;
    uint256 public compoundTax;

    /*****ADMIN PARAMETERS*****/
    bool public isPaused = true;
    mapping(address=>bool) public blackList;

    /*****ADMIN FUNCTIONS*****/
    function initialize(address _USDTAddress, address _splashAddress, address _LPAddress, address _Swapper ) external initializer {
        __Ownable_init();
        totalDeposits = 0;
        totalPayouts = 0;
        depositsCount = 0;
        depositTax = 10;
        claimTax = 10;
        compoundTax = 5;
        LPToken = IERC20(_LPAddress);
        USDT = IERC20(_USDTAddress);
        splashToken = IERC20(_splashAddress);
        Swapper = ISwapper(_Swapper);
    }
    function unpause() public onlyOwner {
        isPaused = false;
    }
    function pause() public onlyOwner {
        isPaused = true;
    }
    modifier isNotPaused() {
        require(!isPaused, "Swaps currently paused");
        _;
    }
    function removeFromBlackList(address[] memory blackListAddress) external onlyOwner {
        for(uint256 i;i<blackListAddress.length;i++){
            blackList[blackListAddress[i]]=false;
        }
    }
    function addToBlackList(address[] memory blackListAddress) external onlyOwner {
        for(uint256 i;i<blackListAddress.length;i++){
            blackList[blackListAddress[i]]=true;
        }
    }
    modifier noBlackList(){
        require(!blackList[msg.sender]==true,"No Blacklist calls");
        _;
    }
    modifier taxStates(TaxState _amountWithoutTax, TaxState _taxAmount) {
        if (_amountWithoutTax != taxState && _taxAmount != taxState) {
            revert();
        }
        _;
    }
    function setDepositTax(uint256 _percentage) external onlyOwner {
        depositTax = _percentage;
    }
    function setClaimTax(uint256 _percentage) external onlyOwner {
        claimTax = _percentage;
    }
    function setCompoundTax(uint256 _percentage) external onlyOwner {
        compoundTax = _percentage;
    }

    /****MAIN FUNCTIONS****/
    function deposit(uint256 _amount) taxStates(TaxState.withTax,TaxState.withoutTax) external isNotPaused noBlackList {
        require(_amount > 0, "Amount needs to be > 0");
        address _addr = msg.sender;
        (uint256 _amountWithoutTax, uint256 _taxAmount) = calculateTax(_amount, depositTax);
        require(LPToken.transferFrom(_addr, address(this), _amount));
        reinvestTaxes(_taxAmount);

        //Add to user
        users[_addr].deposits += _amountWithoutTax;
        users[_addr].lastDepositTime = block.timestamp;
        users[_addr].lastClaimTime = block.timestamp;
        users[_addr].lastRollTime = block.timestamp;
        users[_addr].depositsIds.push(depositsCount);
        users[_addr].depositsCount++;

        //Add new deposit
        deposits[depositsCount].id = depositsCount;
        deposits[depositsCount].amount = _amountWithoutTax;
        deposits[depositsCount].owner = _addr;
        deposits[depositsCount].payout = 0;
        deposits[depositsCount].depositTime = block.timestamp;
        deposits[depositsCount].claimTime = block.timestamp;
        deposits[depositsCount].rollTime = block.timestamp;

        //Global stat
        totalDeposits += _amount;
        depositsCount++;
    }

    function claim(uint256 _depositId) taxStates(TaxState.withTax,TaxState.withoutTax) external isNotPaused noBlackList {
        address _addr = msg.sender;
        //Get rewards
        uint256 rewards = getRewards(_depositId);
        require(rewards > 0, "No rewards");
        (uint256 _amountWithoutTax, uint256 _taxAmount) = calculateTax(rewards, claimTax);
        require(deposits[_depositId].owner == _addr, "Not the owner");

        

        //Update Deposit
        deposits[_depositId].payout += rewards;
        deposits[_depositId].claimTime = block.timestamp;
        deposits[_depositId].rollTime = block.timestamp;

        //Update User
        users[_addr].payouts += rewards;
        users[_addr].lastClaimTime = block.timestamp;

        //Update global
        totalPayouts += rewards;
    }

    function roll(uint256 _depositId) taxStates(TaxState.withTax,TaxState.withoutTax) external isNotPaused noBlackList {
        address _addr = msg.sender;
        uint256 rewards = getRewards(_depositId);
        require(rewards > 0, "No rewards");
        (uint256 _amountWithoutTax, uint256 _taxAmount) = calculateTax(rewards, compoundTax);
        require(deposits[_depositId].owner == _addr, "Not the owner");

        //Roll
        
        deposits[_depositId].payout += rewards;
        deposits[_depositId].rollTime = block.timestamp;
        users[_addr].payouts += rewards;
        users[_addr].lastRollTime = block.timestamp;

        //Add to existing deposit
        deposits[_depositId].amount += rewards;
        users[_addr].deposits += rewards;

        //Global stat
        totalDeposits += rewards;
        totalPayouts += rewards;
    }

    function claimAll() taxStates(TaxState.withTax,TaxState.withoutTax) external isNotPaused noBlackList {
        address _addr = msg.sender;
        
        require(users[_addr].depositsCount > 0, "No deposits");

        uint256 _totalrewards = 0;

        //Loop through deposits of user
        for (uint256 i = 0; i < users[_addr].depositsCount; i++) {
            uint256 _depositId = users[_addr].depositsIds[i];
            uint256 _rewards = getRewards(_depositId);
            (uint256 _amountWithoutTax, uint256 _taxAmount) = calculateTax(_rewards, claimTax);
            _totalrewards += _rewards;
            deposits[_depositId].payout += _rewards;
            deposits[_depositId].claimTime = block.timestamp;
            deposits[_depositId].rollTime = block.timestamp;
        }

        //Update stats
        users[_addr].lastClaimTime = block.timestamp;
        users[_addr].payouts += _totalrewards;
        totalPayouts += _totalrewards;
    }

    function rollAll() taxStates(TaxState.withTax,TaxState.withoutTax) external isNotPaused noBlackList {
        address _addr = msg.sender;
        
        require(users[_addr].depositsCount > 0, "No deposits");

        uint256 _totalrewards = 0;

        //Loop through deposits of user
        for (uint256 i = 0; i < users[_addr].depositsCount; i++) {
            uint256 _depositId = users[_addr].depositsIds[i];
            uint256 _rewards = getRewards(_depositId);
            (uint256 _amountWithoutTax, uint256 _taxAmount) = calculateTax(_rewards, compoundTax);
            _totalrewards += _rewards-_amountWithoutTax ;
            deposits[_depositId].payout += _rewards;
            deposits[_depositId].rollTime = block.timestamp;
            deposits[_depositId].amount += _rewards;
        }

        //Update Stats
        users[_addr].deposits += _totalrewards;
        users[_addr].lastRollTime = block.timestamp;
        users[_addr].payouts += _totalrewards;
        totalPayouts += _totalrewards;
        totalDeposits += _totalrewards;
    }

    /*******GETTERS********/
    function getDepositsIds(address _addr)
        public
        view
        returns (uint256[] memory _depositsIds)
    {
        _depositsIds = users[_addr].depositsIds;
    }
    function getRewards(uint256 _depositId)
        public
        view
        returns (uint256 _rewards)
    {
        _rewards =
            calculateRewards(
                deposits[_depositId].amount,
                block.timestamp,
                deposits[_depositId].claimTime
            ) -
            calculateRewards(
                deposits[_depositId].amount,
                deposits[_depositId].rollTime,
                deposits[_depositId].claimTime
            );
    }
    function getDeposit(uint256 _depositId)
        public
        view
        returns (
            uint256 id,
            uint256 amount,
            address owner,
            uint256 payout,
            uint256 depositTime,
            uint256 claimTime,
            uint256 rollTime,
            uint256 percentage,
            uint256 rewardsAvailable
        )
    {
        id = deposits[_depositId].id;
        amount = deposits[_depositId].amount;
        owner = deposits[_depositId].owner;
        payout = deposits[_depositId].payout;
        depositTime = deposits[_depositId].depositTime;
        claimTime = deposits[_depositId].claimTime;
        rollTime = deposits[_depositId].rollTime;
        percentage = getPercentage(_depositId);
        rewardsAvailable = getRewards(_depositId);
    }
    function getPercentage(uint256 _depositId)
        public
        view
        returns (uint256 percentage)
    {
        uint256 _timeSinceLastWithdraw = block.timestamp -
            deposits[_depositId].claimTime;
        uint256 _bracket = 10 seconds;
        if (_timeSinceLastWithdraw < 1 * _bracket) {
            percentage = 1;
        } else if (_timeSinceLastWithdraw < 2 * _bracket) {
            percentage = 2;
        } else {
            percentage = 3;
        }
    }

    /*****PRIVATE****/
    function calculateRewards(
        uint256 _deposits,
        uint256 _atTime,
        uint256 _claimTime
    ) private pure returns (uint256 _rewards) {
        uint256 _timeElasped = _atTime - _claimTime;
        uint256 _bracket = 10 seconds;
        if (_timeElasped > 0) {
            _rewards = (((_deposits * _timeElasped) / 1 days) * 1) / 100;
        }
        if (_timeElasped >= 1 * _bracket) {
            _rewards +=
                (((_deposits * (_timeElasped - _bracket)) / 1 days) * 2) /
                100 -
                (((_deposits * (_timeElasped - _bracket)) / 1 days) * 1) /
                100;
        }
        if (_timeElasped >= 2 * _bracket) {
            _rewards +=
                (((_deposits * (_timeElasped - 2 * _bracket)) / 1 days) * 3) /
                100 -
                (((_deposits * (_timeElasped - 2 * _bracket)) / 1 days) * 2) /
                100;
        }
    }
    function calculateTax(uint256 _amount, uint256 _taxPercentage) private pure returns (uint256 taxAmount, uint256 withoutTax){
        taxAmount = _amount * _taxPercentage / 100;
        withoutTax = _amount * (100-_taxPercentage) / 100;
    }
    function reinvestTaxes(uint256 _amount) private {
        uint256 _half = _amount / 2;
        Swapper.sendTaxToWell(_half);
    }

    /****TEST FUNCTIONS***/
    function getLPBalance() external view returns(uint256 balance){
       balance = LPToken.balanceOf(address(this));
    }
    function getSenderAddress() external view returns(address sender){
       sender = Swapper.senderAddress();
    }
}

//USDT : 0x5e666D284815C9C2f00fA7Ac8786abfB806954FC
//Splash Token : 0xde83309d30524eA6F9526AaE4E3c2D93cA87f1e9
//LP Token : 0x919D6510Fbf0E792Ccc6fAc26e864D45D1E197Da
//Swapper : 0xaB726b5e542aB973a0Dc561E85E68A85d1F4fC17