/**
 *Submitted for verification at snowtrace.io on 2022-04-22
*/

//SPDX-License-Identifier: UNLICENSED
//Omniverse
//Author: https://twitter.com/KamaDeFi, CTO of https://prismashield.com

pragma solidity 0.8.13;


library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: AVAX_TRANSFER_FAILED");
    }
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value)
        external
        returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}


interface TokenManager {
    //Creates trading pairs between OMNI and other tokens as dictated
    //by the implementation of createPairs(). This function returns the
    //addresses of all the created pairs.
    //This gives the flexibility of having an external contract handle
    //all the necessary routers and pairs. For example, if we start off
    //with just using TraderJoe and an OMNI/AVAX pair, then we later
    //decide to also use Pangolin and create an OMNI/DAI pair, we can
    //easily do that through creating a new TokenManager contract.
    function createPairs()
        external
        returns (address[] memory pairs);
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage self, address account) internal {
        require(!has(self, account), "Roles: account already has role");
        self.bearer[account] = true;
    }

    function remove(Role storage self, address account) internal {
        require(has(self, account), "Roles: account does not have role");
        self.bearer[account] = false;
    }

    function has(Role storage self, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return self.bearer[account];
    }
}


contract MinterRole {	
    using Roles for Roles.Role;	

    Roles.Role private minters;

    event MinterAdded(address indexed account);	
    event MinterRemoved(address indexed account);	

    modifier onlyMinter() {	
        require(
            isMinter(msg.sender),
            "MinterRole: caller does not have the Minter role"
        );	
        _;	
    }

    function renounceMinter() public {	
        removeMinterInternal(msg.sender);	
    }

    function isMinter(address addr) public view returns (bool) {	
        return minters.has(addr);	
    }

    function addMinterInternal(address addr) internal {	
        minters.add(addr);	
        emit MinterAdded(addr);	
    }

    function removeMinterInternal(address addr) internal {	
        minters.remove(addr);	
        emit MinterRemoved(addr);	
    }
}


abstract contract ERC20Detailed is IERC20 {
    string private tokenName;
    string private tokenSymbol;
    uint8 private tokenDecimals;

    constructor(string memory name_, string memory token_, uint8 decimals_) {
        tokenName = name_;
        tokenSymbol = token_;
        tokenDecimals = decimals_;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }
}


contract Ownable {
    address private owner_;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner_ = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner_);
        owner_ = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        transferOwnershipInternal(newOwner);
    }

    function owner() public view returns (address) {
        return owner_;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner_;
    }

    function transferOwnershipInternal(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner_, newOwner);
        owner_ = newOwner;
    }
}


contract OmniverseTest1 is ERC20Detailed, Ownable, MinterRole {
    uint256 private constant INITIAL_TOKEN_SUPPLY = 4 * 10**9 * 10**DECIMALS;
    uint256 private constant MAX_SUPPLY = type(uint128).max;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_FEE = 100;

    bool public transferEnabled = false;

    uint256 public buyFee = 40;
    uint256 public sellFee = 40;

    bool public feesOnNormalTransfers = true;
    bool public isBlacklistingEnabled = true;
    bool public isMaxTaxReceiversEnabled = true;

    uint256 public maxTaxReceiverSellTransactionAmount = 15000 * 10**18;

    mapping(address => bool) public blacklist;
    mapping(address => bool) public maxTaxReceivers;
    mapping(address => bool) public allowTransfer;
    mapping(address => bool) public isFeeExempt;    

    uint256 private totalTokenSupply = INITIAL_TOKEN_SUPPLY;
    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowedFragments;

    TokenManager public tokenManager;

    address[] private pairs;
    mapping(address => bool) private pairsCheck;

    modifier transferLock() {
        require(transferEnabled || isOwner() || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor(
        address ownerAddr,
        address[] memory otherFeeExemptAddrs
    )
        ERC20Detailed("OmniverseTest1", "OMNITEST1", uint8(DECIMALS))
    {
        balances[ownerAddr] = INITIAL_TOKEN_SUPPLY;
        isFeeExempt[ownerAddr] = true;
        for (uint i = 0; i < otherFeeExemptAddrs.length; i++) {
            isFeeExempt[otherFeeExemptAddrs[i]] = true;
        }

        addMinterInternal(ownerAddr);
        transferOwnershipInternal(ownerAddr);

        emit Transfer(address(0x0), ownerAddr, INITIAL_TOKEN_SUPPLY);
    }

    receive() external payable {}

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        transferLock
        returns (bool)
    {
        transferFromInternal(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        external
        override
        validRecipient(to)
        transferLock
        returns (bool)
    {
        if (allowedFragments[from][msg.sender] != type(uint256).max) {
            allowedFragments[from][msg.sender] -= value;
        }
        transferFromInternal(from, to, value);
        return true;
    }

    function setTransferEnabled(bool enabled) external onlyOwner {
        transferEnabled = enabled;
    }

    function setFees(
        uint256 buyPercent,
        uint256 sellPercent
    ) external onlyOwner {
        require(buyPercent <= MAX_FEE, "exceeded max buy fees");
        require(sellPercent <= MAX_FEE, "exceeded max sell fees");

        buyFee = buyPercent;
        sellFee = sellPercent;
    }

    function setFeesOnNormalTransfers(bool enabled) external onlyOwner {
        feesOnNormalTransfers = enabled;
    }

    function setBlacklistingEnabled(bool enabled) external onlyOwner {
        isBlacklistingEnabled = enabled;
    }

    function setMaxTaxReceiversEnabled(bool enabled) external onlyOwner {
        isMaxTaxReceiversEnabled = enabled;
    }

    function setMaxTaxReceiversSellTransactionAmount(uint256 amount)
        external
        onlyOwner
    {
        maxTaxReceiverSellTransactionAmount = amount;
    }

    function updateBlacklist(address user, bool flag) external onlyOwner{
        blacklist[user] = flag;
    }

    function updateMaxTaxReceivers(address addr, bool flag)
        external
        onlyOwner
    {
        maxTaxReceivers[addr] = flag;
    }

    function setAllowTransfer(address addr, bool allowed) external onlyOwner {
        allowTransfer[addr] = allowed;
    }

    function setFeeExempt(address addr, bool enabled) external onlyOwner {
        isFeeExempt[addr] = enabled;
    }

    function addMinter(address addr) external onlyOwner {	
        addMinterInternal(addr);	
    }
	
    function removeMinter(address addr) external onlyOwner {	
        removeMinterInternal(addr);	
    }

    //Minting is only to be used in two scenarios:
    //a- As OMNI rewards in the OmniVault
    //b- To counteract low supply issues due to OMNI's deflationary nature
    function mint(address recipient, uint256 amount) external onlyMinter {
        totalTokenSupply += amount;

        if (totalTokenSupply > MAX_SUPPLY) {
            totalTokenSupply = MAX_SUPPLY;
        }

        balances[recipient] += amount;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            allowedFragments[msg.sender][spender] = 0;
        } else {
            allowedFragments[msg.sender][spender] = (
                oldValue - subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        allowedFragments[msg.sender][spender] += addedValue;
        emit Approval(
            msg.sender,
            spender,
            allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function setTokenManager(address tokenManagerAddr) external onlyOwner {
        address oldTokenManager = address(tokenManager);

        tokenManager = TokenManager(tokenManagerAddr);

        address[] memory newPairs = tokenManager.createPairs();

        isFeeExempt[oldTokenManager] = false;

        for (uint i = 0; i < pairs.length; i++) {
            pairsCheck[pairs[i]] = false;
        }

        isFeeExempt[tokenManagerAddr] = true;

        pairs = newPairs;

        for (uint i = 0; i < pairs.length; i++) {
            pairsCheck[pairs[i]] = true;
        }
    }

    function rescueAVAX(uint256 amount, address receiver)
        external
        onlyOwner
    {
        require(
            amount <= address(this).balance,
            "Amount larger than what's in the contract"
        );
        TransferHelper.safeTransferAVAX(receiver, amount);
    }

    function rescueERC20Token(
        address tokenAddr,
        uint256 tokens,
        address receiver
    )
        external
        onlyOwner
    {
        require(
            tokens <= IERC20(tokenAddr).balanceOf(address(this)),
            "Amount larger than what's in the contract"
        );
        TransferHelper.safeTransfer(tokenAddr, receiver, tokens);
    }

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return balances[addr];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowedFragments[owner][spender];
    }

    function getTaxPercentages(address addr)
        external
        view
        returns (uint256 buyPercentage, uint256 sellPercentage)
    {
        buyPercentage = buyFee;
        sellPercentage = getSellFee(addr);
    }

    function getAllowTransfer(address addr) external view returns (bool) {
        return allowTransfer[addr];
    }

    function checkFeeExempt(address addr) external view returns (bool) {
        return isFeeExempt[addr];
    }

    function getBlackist(address addr) public view returns (bool) {
        return blacklist[addr] && isBlacklistingEnabled;
    }

    function getMaxTaxReceiver(address addr) public view returns (bool) {
        return maxTaxReceivers[addr] && isMaxTaxReceiversEnabled;
    }

    function getSellFee(address addr) private view returns (uint256) {
        uint256 sellPercentage = sellFee;
        if (getMaxTaxReceiver(addr)) {
            sellPercentage = MAX_FEE;
        }
        return sellPercentage;
    }

    function shouldTakeFee(address from, address to)
        private
        view
        returns (bool)
    {
        if (isFeeExempt[from] || isFeeExempt[to]) {
            return false;
        } else if (feesOnNormalTransfers) {
            return true;
        } else {
            return pairsCheck[from] || pairsCheck[to];
        }
    }

    function takeFee(address sender, address recipient, uint256 amount)
        private
        returns (uint256)
    {
        uint256 totalFee = buyFee;
        if (pairsCheck[recipient]) totalFee = getSellFee(sender);

        uint256 feeAmount = amount * totalFee / 100;

        balances[address(tokenManager)] += feeAmount;

        emit Transfer(sender, address(tokenManager), feeAmount);

        return amount - feeAmount;
    }

    function transferFromInternal(
        address sender,
        address recipient,
        uint256 amount
    )
        private
    {
        require(
            !getBlackist(sender) && !getBlackist(recipient),
            "Blacklisted"
        );

        if (pairsCheck[recipient] && !isFeeExempt[sender]) {
            require(
                amount <= maxTaxReceiverSellTransactionAmount ||
                !getMaxTaxReceiver(sender),
                "Amount greater than allowed limit"
            );
        }

        balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        balances[recipient] += amountReceived;

        emit Transfer(
            sender,
            recipient,
            amountReceived
        );
    }
}