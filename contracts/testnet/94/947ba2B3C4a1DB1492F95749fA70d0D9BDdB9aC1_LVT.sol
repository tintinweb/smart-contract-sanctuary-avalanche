/*
 *        __                                        __                                  ______    _                                      
 *       / /   ____   __  __ _   __  ___    _____  / /_  __  __   _____  ___           / ____/   (_)   ____   ____ _   ____   _____  ___ 
 *      / /   / __ \ / / / /| | / / / _ \  / ___/ / __/ / / / /  / ___/ / _ \         / /_      / /   / __ \ / __ `/  / __ \ / ___/ / _ \
 *     / /___/ /_/ // /_/ / | |/ / /  __/ / /    / /_  / /_/ /  / /    /  __/        / __/     / /   / / / // /_/ /  / / / // /__  /  __/
 *    /_____/\____/ \__,_/  |___/  \___/ /_/     \__/  \__,_/  /_/     \___/        /_/       /_/   /_/ /_/ \__,_/  /_/ /_/ \___/  \___/ 
 *                              
 
 *
 *    Web:      https://www.louverture.finance/
 *    Telegram: https://t.me/louverture_fi
 *    Discord:  https://discord.gg/HKjuqjdN
 *    Twitter:  https://twitter.com/louverture_fi
 *
 *    Created with Love by the DevTheAbe.eth Team 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/INodeReward.sol";
import "./interface/IOrbNode.sol";
import "./interface/IOrbNodeHelper.sol";
import "./types/ERC20.sol";
import "./library/Ownable.sol";
import "./library/Strings.sol";
import "./library/SafeMath.sol";
import "./library/SafeERC20.sol";

interface ITaxPool {
    function distribute(uint256 amount, bool isCreate) external;

    function getAddress()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );
}

contract LVT is ERC20, Ownable {
    using Strings for string;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IOrbNode private orbNode;
    IOrbNodeHelper private orbNodeHelper;
    INodeReward private nodeRewardManager;

    bool private AllowTransfer;
    bool private TradingOpen = false;

    address private MigrateAdmin;

    address public TaxPool;
    address public LVTTreasury;

    address public LVTV1Token;
    address public MistelToken;

    uint256 public MinAmount;
    uint256 public MistelRatio;

    uint256 public MaxBalance;
    uint256 public MigrateTimestamp;

    mapping(address => bool) public Blacklisted;
    
    mapping(address => bool) public MistelMigrated;
    mapping(address => bool) public UserNodeMigrated;
    mapping(address => bool) public UserTokenMigrated;

    constructor(address[] memory users) ERC20("Louverture", "LVT") {
        AllowTransfer = true;

        for (uint8 ii = 0; ii < users.length; ii++) {
            _mint(users[ii], 1e8 * 1e18);
        }
    }

    event StartTrading(uint256 startTime);
    event Compound(address indexed user, uint256 tokenId);
    event CompoundAll(address indexed user);
    event CompoundType(address indexed user, IOrbNode.TokenType tokenType);
    event Claim(address indexed user, uint256 tokenId);
    event ClaimAll(address indexed user);
    event ClaimType(address indexed user, IOrbNode.TokenType tokenType);
    event MeltOrb(address indexed user, uint256 tokenId);

    event MigrateUserNode(address indexed user);
    event MigrateMistel(address indexed user, uint256 balance, uint256 amount);
    event MigrateLVTV1(address indexed user, uint256 balance, uint256 amount);

    modifier whitelisted() {
        require(!Blacklisted[msg.sender], "Blacklisted");
        _;
    }

    modifier onlyMigrator() {
        require(msg.sender == MigrateAdmin, "Not allowed");
        _;
    }

    function setBlacklist(address[] calldata users, bool flag)
        external
        onlyOwner
    {
        for (uint256 ii = 0; ii < users.length; ii++) {
            Blacklisted[users[ii]] = flag;
        }
    }

    function setAllow(bool flag) external onlyOwner {
        AllowTransfer = flag;
    }

    function setAddress(
        address _taxPool,
        address _orbNode,
        address _orbNodeHelper,
        address _treasury
    ) external onlyOwner {
        TaxPool = _taxPool;
        orbNode = IOrbNode(_orbNode);
        orbNodeHelper = IOrbNodeHelper(_orbNodeHelper);

        LVTTreasury = _treasury;
    }

    function setBalance(uint256 _min, uint256 _max) external onlyOwner {
        MinAmount = _min.mul(10**decimals());
        MaxBalance = _max;
    }

    function setMistel(address _mistel, uint256 _ratio) external onlyOwner {
        MistelToken = _mistel;
        MistelRatio = _ratio;
    }

    function openTrading() external onlyOwner {
        require(!TradingOpen, "trading is already open");
        TradingOpen = true;

        emit StartTrading(block.timestamp);
    }

    function setMigrate(
        address _migrator,
        address _lvt,
        address _nodeRewardManager,
        uint256 _timestamp
    ) external onlyOwner {
        MigrateAdmin = _migrator;

        LVTV1Token = _lvt;
        nodeRewardManager = INodeReward(_nodeRewardManager);

        MigrateTimestamp = _timestamp;
    }

    function getPendingReward(uint256 tokenId)
        external
        view
        whitelisted
        returns (uint256 reward)
    {
        (, , reward) = orbNode.getCompound(tokenId);
    }

    // this is for only testing
    function mintToken(address user) external onlyOwner {
        _mint(user, 1e8 * 1e18);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!Blacklisted[from] && !Blacklisted[to], "Blacklisted address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        require(AllowTransfer, "Transfer now allowed");

        (
            address uniswapV2Pair,
            address uniswapV2Router,
            address devWallet,
            address treasuryWallet,
            address marketingWalllet
        ) = ITaxPool(TaxPool).getAddress();
        if (
            from != owner() &&
            to != uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            to != address(this) &&
            from != address(this)
        ) {
            require(TradingOpen, "Trading not yet enabled.");

            // anti whale
            if (
                to != devWallet &&
                to != treasuryWallet &&
                to != marketingWalllet &&
                from != devWallet &&
                from != treasuryWallet &&
                from != marketingWalllet
            ) {
                uint256 totalSupply = totalSupply();
                uint256 walletBalance = balanceOf(address(to));
                require(
                    amount.add(walletBalance) <=
                        totalSupply.mul(MaxBalance).div(1e4),
                    "STOP TRYING TO BECOME A WHALE. WE KNOW WHO YOU ARE."
                );
            }
        }
        super._transfer(from, to, amount);
    }

    function migrateFromV1()
        external
        whitelisted
        returns (uint256 numElements, uint256 numBlackholes)
    {
        require(!UserNodeMigrated[msg.sender], "USER ALREADY MIGRATED!");

        string[] memory nodeNames = nodeRewardManager
            ._getNodesNames(msg.sender)
            .split("#");

        require(nodeNames.length > 0, "No Node");

        string[] memory lastClaimTimes = nodeRewardManager
            ._getNodesLastClaimTime(msg.sender)
            .split("#");
        string[] memory nodeCreationTimes = nodeRewardManager
            ._getNodesCreationTime(msg.sender)
            .split("#");
        string[] memory nodeRewardsAvailable = nodeRewardManager
            ._getNodesRewardAvailable(msg.sender)
            .split("#");

        for (uint256 i = 0; i < nodeNames.length; i++) {
            uint256 creationTime = nodeCreationTimes[i].parseInt();
            uint256 nodeValue = nodeRewardManager._getNodeValueOf(
                msg.sender,
                creationTime
            );

            if (
                nodeRewardManager._getRewardMultOf(msg.sender, creationTime) >=
                135000
            ) {
                orbNode.createToken(
                    IOrbNode.TokenMeta({
                        name: nodeNames[i], // name
                        tokenId: 0,
                        amount: nodeValue, // amount
                        tier: orbNode.getTier(), // tier
                        rarity: IOrbNode.RarityType.Common, // rarity ; unnecessary
                        compound: 0, // compound
                        tokenType: IOrbNode.TokenType(
                            orbNodeHelper.getRandomElement()
                        ), // tokenType
                        lastClaimTime: block.timestamp, // lastClaimTime
                        lastClaimAmount: nodeValue -
                            nodeRewardsAvailable[i].parseInt() // lastClaimAmount
                    }),
                    msg.sender
                );

                numElements++;
            } else {
                orbNode.createToken(
                    IOrbNode.TokenMeta({
                        name: nodeNames[i], // name
                        tokenId: 0,
                        amount: nodeValue, // amount
                        tier: 0, // tier
                        rarity: IOrbNode.RarityType.Common, // rarity ; unnecessary
                        compound: nodeRewardManager._getAddValueCountOf(
                            msg.sender,
                            creationTime
                        ), // compound
                        tokenType: IOrbNode.TokenType.Blackhole, // tokenType
                        lastClaimTime: lastClaimTimes[i].parseInt(), // lastClaimTime
                        lastClaimAmount: nodeValue -
                            nodeRewardsAvailable[i].parseInt() // lastClaimAmount
                    }),
                    msg.sender // accountFrom
                );

                numBlackholes++;
            }
        }

        UserNodeMigrated[msg.sender] = true;
        emit MigrateUserNode(msg.sender);
    }

    function createToken(
        string memory name,
        uint256 amount,
        IOrbNode.TokenType tokenType
    ) public whitelisted returns (uint256) {
        require(amount > 0, "Invalid amount");
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        require(
            tokenType == IOrbNode.TokenType.Blackhole || amount >= MinAmount,
            "Under min amount"
        );
        require(tokenType != IOrbNode.TokenType.Orb, "Invalid type");

        super._transfer(msg.sender, TaxPool, amount);
        ITaxPool(TaxPool).distribute(amount, true);

        return
            orbNode.createToken(
                name,
                0,
                0,
                amount,
                block.timestamp,
                amount,
                tokenType,
                msg.sender
            );
    }

    function addLVT2Blackhole(uint256 tokenId, uint256 amount)
        external
        whitelisted
    {
        require(amount > 0, "Invalid amount");

        super._transfer(msg.sender, TaxPool, amount);
        ITaxPool(TaxPool).distribute(amount, true);

        orbNode.addLVT2Blackhole(tokenId, amount, msg.sender);
    }

    function _compound(uint256 reward, uint256 tax) private {
        super._transfer(LVTTreasury, address(this), reward);
        super._transfer(address(this), TaxPool, tax);
        ITaxPool(TaxPool).distribute(tax, false);
    }

    function _claim(uint256 reward, uint256 tax) private {
        super._transfer(address(this), TaxPool, tax);
        super._transfer(address(this), msg.sender, reward.sub(tax));
        ITaxPool(TaxPool).distribute(tax, false);
    }

    function compound(uint256[] calldata tokenIds) external whitelisted {
        require(tokenIds.length > 0);
        for (uint256 ii = 0; ii < tokenIds.length; ii++) {
            uint256 tokenId = tokenIds[ii];
            require(
                orbNode.checkAction(
                    tokenId,
                    msg.sender,
                    IOrbNode.UserAction.Compound
                ),
                "Wait!"
            );

            (uint256 reward, uint256 tax, ) = orbNode.getCompound(tokenId);
            if (reward > 0) {
                _compound(reward, tax);

                orbNode.compound(tokenId, msg.sender);

                emit Compound(msg.sender, tokenId);
            }
        }
    }

    function compoundType(IOrbNode.TokenType tokenType) external whitelisted {
        (uint256 totalReward, uint256 totalTax) = orbNode.getTotalReward(
            msg.sender,
            tokenType,
            true
        );
        if (totalReward > 0) {
            _compound(totalReward, totalTax);

            orbNode.compoundAll(msg.sender, tokenType, true);

            emit CompoundType(msg.sender, tokenType);
        }
    }

    function compoundAll() external whitelisted {
        (uint256 totalReward, uint256 totalTax) = orbNode.getTotalReward(
            msg.sender,
            IOrbNode.TokenType.Blackhole,
            false
        );
        if (totalReward > 0) {
            _compound(totalReward, totalTax);

            orbNode.compoundAll(
                msg.sender,
                IOrbNode.TokenType.Blackhole,
                false
            );

            emit CompoundAll(msg.sender);
        }
    }

    function claim(uint256[] calldata tokenIds) external whitelisted {
        require(tokenIds.length > 0);
        for (uint256 ii = 0; ii < tokenIds.length; ii++) {
            uint256 tokenId = tokenIds[ii];
            require(
                orbNode.checkAction(
                    tokenId,
                    msg.sender,
                    IOrbNode.UserAction.Claim
                ),
                "Wait!"
            );

            (uint256 claim_, uint256 tax) = orbNode.getClaim(tokenId);
            if (claim_ > 0) {
                _claim(claim_, tax);

                orbNode.claim(tokenId, msg.sender);

                emit Claim(msg.sender, tokenId);
            }
        }
    }

    function claimType(IOrbNode.TokenType tokenType) external whitelisted {
        (uint256 totalClaim, uint256 totalTax) = orbNode.getTotalClaim(
            msg.sender,
            tokenType,
            true
        );
        if (totalClaim > 0) {
            _claim(totalClaim, totalTax);

            orbNode.claimAll(msg.sender, tokenType, true);

            emit ClaimType(msg.sender, tokenType);
        }
    }

    function claimAll() external whitelisted {
        (uint256 totalClaim, uint256 totalTax) = orbNode.getTotalClaim(
            msg.sender,
            IOrbNode.TokenType.Blackhole,
            false
        );
        if (totalClaim > 0) {
            _claim(totalClaim, totalTax);

            orbNode.claimAll(msg.sender, IOrbNode.TokenType.Blackhole, false);

            emit ClaimAll(msg.sender);
        }
    }

    function fuseOrb(string calldata name, uint256[] calldata tokenIds)
        external
        whitelisted
    {
        orbNode.fuseOrb(msg.sender, name, tokenIds);
    }

    function mergeBlackholes(string calldata name, uint256[] calldata tokenIds)
        external
        whitelisted
    {
        orbNode.mergeBlackholes(msg.sender, name, tokenIds);
    }

    function meltOrb(uint256 tokenId) external {
        (uint256 userAmount, uint256 taxAmount) = orbNode.getOrb(
            tokenId,
            msg.sender
        );
        if (userAmount > 0) {
            super._transfer(LVTTreasury, TaxPool, taxAmount);
            super._transfer(LVTTreasury, msg.sender, userAmount);
            ITaxPool(TaxPool).distribute(taxAmount, false);

            orbNode.meltOrb(tokenId, msg.sender);

            emit MeltOrb(msg.sender, tokenId);
        }
    }

    function migrateMistel(
        address account,
        uint256 snapshot
    ) external onlyMigrator {
        require(snapshot > 0);
        require(!Blacklisted[account], "Blacklisted");
        require(!MistelMigrated[account], "Already migrated");

        uint256 balance = IERC20(MistelToken).balanceOf(account);
        balance = balance > snapshot ? snapshot : balance;
        if (balance > 0) {
            uint256 amount = balance
                .mul(10**decimals())
                .div(10**IERC20(MistelToken).decimals())
                .div(MistelRatio);

            IERC20(MistelToken).safeTransferFrom(account, LVTTreasury, balance);

            super._transfer(LVTTreasury, account, amount);

            MistelMigrated[account] = true;
            emit MigrateMistel(account, balance, amount);
        }
    }

    function migrateLVTV1(
        address account,
        uint256 snapshot
    ) external onlyMigrator {
        require(snapshot > 0);
        require(!Blacklisted[account], "Blacklisted");
        require(!UserTokenMigrated[account], "Already migrated");

        uint256 balance = IERC20(LVTV1Token).balanceOf(account);
        balance = balance > snapshot ? snapshot : balance;
        if (balance > 0) {
            uint256 amount = balance.mul(10**decimals()).div(
                10**IERC20(LVTV1Token).decimals()
            );

            IERC20(LVTV1Token).safeTransferFrom(account, LVTTreasury, balance);

            super._transfer(LVTTreasury, account, amount);

            UserTokenMigrated[account] = true;
            emit MigrateLVTV1(account, balance, amount);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeReward {
    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory);

    function _getRewardMultOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeValueOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getAddValueCountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOrbNode {
    enum TokenType {
        Meteorite,
        Titanium,
        DarkMatter,
        Platinum,
        Blackhole,
        Orb
    }

    enum RarityType {
        Common,
        Uncommon,
        Rare,
        Epic,
        Legendary,
        Mythic
    }

    enum UserAction {
        Claim,
        Compound
    }

    struct TokenMeta {
        string name;
        uint256 tokenId;
        uint256 amount;
        uint256 lastClaimTime;
        uint256 lastClaimAmount;
        uint256 tier;
        uint256 compound;
        RarityType rarity;
        TokenType tokenType;
    }

    event CreateToken(
        address indexed minter,
        uint256 compound,
        uint256 amount,
        uint256 lastClaimTime,
        uint256 lastClaimAmount,
        RarityType rarity,
        TokenType tokenType
    );

    function createToken(
        string memory name,
        uint256 compnd,
        uint256 tier,
        uint256 amount,
        uint256 lastClaimTime,
        uint256 lastClaimAmount,
        TokenType tokenType,
        address accountFrom
    ) external returns (uint256 tokenId);

    function createToken(TokenMeta memory meta, address accountFrom)
        external
        returns (uint256 tokenId);

    function addLVT2Blackhole(
        uint256 tokenId,
        uint256 amount,
        address account
    ) external;

    function checkAction(
        uint256 tokenId,
        address account,
        UserAction action
    ) external view returns (bool);

    function compound(uint256 tokenId, address account) external;

    function claim(uint256 tokenId, address account) external;

    function getCompound(uint256 tokenId)
        external
        view
        returns (
            uint256 _reward,
            uint256 _tax,
            uint256 _rtReward
        );

    function getClaim(uint256 tokenId)
        external
        view
        returns (uint256 claim_, uint256 tax_);

    function getTotalReward(
        address account, 
        TokenType tokenType,
        bool flag
    ) external view returns (uint256 _reward, uint256 _tax);

    function getTotalClaim(
        address account, 
        TokenType tokenType,
        bool flag
    ) external
        view
        returns (uint256 claim_, uint256 tax_);

    function claimAll(
        address account, 
        TokenType tokenType,
        bool flag
    ) external;

    function compoundAll(
        address account,
        TokenType tokenType,
        bool flag
    ) external;

    function getOrb(uint256 tokenId, address account)
        external
        view
        returns (uint256 _user, uint256 _tax);

    function fuseOrb(
        address account,
        string calldata name,
        uint256[] calldata tokenIds
    ) external;

    function mergeBlackholes(
        address account,
        string calldata name,
        uint256[] calldata tokenIds
    ) external;

    function meltOrb(uint256 tokenId, address account) external;

    function getTier() external view returns (uint256);

    function getCurrentTokenId() external view returns (uint256 tokenId);

    function getMeta(uint256 tokenId)
        external
        view
        returns (TokenMeta memory info);

    function getOrbClaim() external view returns (uint256);

    function getOrbCompound() external view returns (uint256);

    function getBlackholeClaim() external view returns (uint256);

    function getBlackholeCompound() external view returns (uint256);

    function getElementClaim() external view returns (uint256);

    function getElementCompound() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOrbNodeHelper {
    function _getRarity() external view returns (uint256 rarity);

    function getRandomElement() external view returns (uint256 element);

    function getOrbTier(uint256 _compnd) external pure returns (uint256);

    function elementSizeModifier(uint256 amount)
        external
        pure
        returns (uint256);

    function orbRoi(uint256 tokenId, uint8[4] memory rarityLevel)
        external
        view
        returns (uint256 dailyRoi);

    function getPercent(uint256 tokenId, uint256 _action)
        external
        view
        returns (uint256 _percent);

    function tokenURI(
        uint256 roi,
        uint256 reward,
        uint256 tokenId,
        string memory imageURI
    ) external view returns (string memory output);

    function getTVL() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/SafeMath.sol";
import "../abstract/Context.sol";
import "../interface/IERC20.sol";

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

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
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint8) {
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
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
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
     * will be to transferred to `to`.
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../abstract/Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * param _value The needle to search for, at present this is currently
     *               limited to one character
     * param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * param _value The delimiter to split the string on which must be a single
     *               character
     * return string[] An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }

        return splitArr;
    }

    function parseInt(string memory _value) public pure returns (uint256 _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint256 j = 1;
        for (
            uint256 i = _bytesValue.length - 1;
            i >= 0 && i < _bytesValue.length;
            i--
        ) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48) * j;
            j *= 10;
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "../interface/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        //unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
        //}
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
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
    * @dev Returns the decimals of tokens in existence.
    */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}