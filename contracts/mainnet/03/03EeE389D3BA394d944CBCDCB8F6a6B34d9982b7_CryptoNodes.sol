// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./coin.sol";

contract CryptoNodes {
    address private Owner;
    AI private tokenContract1;
    IERC20 private tokenContract2;
    IERC721 private NFTContract;

    uint8 tokendecimals;

    // Node attributes.
    bool nodespaused = true;
    uint8 constant NFTbonus = 125;
    uint8 constant nodePrice = 10;
    uint8 constant nodeTax = 10;
    uint256 nodeAmountlvl1 = 0;
    uint256 nodeAmountlvl2 = 0;
    mapping(address => uint256) nodesLvl1;
    mapping(address => uint256) nodesLvl2;
    mapping(address => uint256) nodeTimestamp;
    uint256 constant nodeYieldTime = 9;
    uint256 nodeLvl1Yield;
    uint256 nodeLvl2Yield;
    mapping(address => bool) blacklists;

    event Ownership(
        address indexed owner,
        address indexed newOwner,
        bool indexed added
    );

    constructor(AI _tokenContract1, IERC20 _tokenContract2, IERC721 _nftContract, address _owner) {
        Owner = _owner;
        tokenContract1 = _tokenContract1;
        tokenContract2 = _tokenContract2;
        NFTContract = _nftContract;
        tokendecimals = tokenContract1.decimals();
        nodeLvl1Yield = 156250 * 10**(tokendecimals - 10);
        nodeLvl2Yield = 625 * 10**(tokendecimals - 6);
    }

    modifier OnlyOwners() {
        require((msg.sender == Owner), "You are not the owner of the token.");
        _;
    }

    modifier BlacklistCheck() {
        require(blacklists[msg.sender] == false, "You are in the blacklist.");
        _;
    }

    modifier NodesStopper() {
        require(nodespaused == false, "Nodes code is currently stopped.");
        _;
    }

    function transferOwner(address _who) public OnlyOwners returns (bool) {
        Owner = _who;
        emit Ownership(msg.sender, _who, true);
        return true;
    }

    event NodesCreated(
        address indexed who, 
        uint256 indexed amount
    );
    event NodesUpgraded(
        address indexed who,
        uint256 indexed amount,
        uint8 indexed lvl
    );
    event Blacklist(
        address indexed owner,
        address indexed blacklisted,
        bool indexed added
    );

    function addBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = true;
        emit Blacklist(msg.sender, _who, true);
    }

    function removeBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = false;
        emit Blacklist(msg.sender, _who, false);
    }

    function checkBlacklistMember(address _who) public view returns (bool) {
        return blacklists[_who];
    }

    function stopNodes(bool _status) public OnlyOwners {
        nodespaused = _status;
    }

    function createNodes(uint256 _amount) public NodesStopper BlacklistCheck {
        uint256 userBalance = tokenContract2.balanceOf(msg.sender);
        uint256 amount = _amount * nodePrice * 10**tokendecimals;
        require(
            userBalance >= amount,
            "You don't have enough tokens."
        );

        tokenContract2.transferFrom(msg.sender, address(this), amount);
        tokenContract1.TaxDistribution(_amount * nodePrice * 10**tokendecimals);

        nodesLvl1[msg.sender] += _amount;
        nodeAmountlvl1 += _amount;
        if (nodeTimestamp[msg.sender] == 0) {
            nodeTimestamp[msg.sender] = block.timestamp;
        }
        emit NodesCreated(msg.sender, _amount);
    }

    function upgradeToLvl2(uint256 _amount) public NodesStopper BlacklistCheck {
        require(
           tokenContract2.balanceOf(msg.sender) >= (30 * 10**tokendecimals) * _amount,
            "You don't have enough tokens."
        );
        require(
            nodesLvl1[msg.sender] >= _amount * 25,
            "You don't have enough level 1 nodes."
        );

        uint256 amount = (30 * 10**tokendecimals) * _amount;
        tokenContract2.transferFrom(msg.sender, address(this), amount);
        tokenContract1.TaxDistribution(amount);

        nodesLvl1[msg.sender] -= _amount * 25;
        nodesLvl2[msg.sender] += _amount;
        nodeAmountlvl2 += _amount;
        emit NodesUpgraded(msg.sender, _amount, 2);
    }

    function totalNodesLvl1() public view returns (uint256) {
        return (nodeAmountlvl1);
    }

    function totalNodesLvl2() public view returns (uint256) {
        return (nodeAmountlvl2);
    }

    function checkNodesLvl1(address _who) public view returns (uint256) {
        return (nodesLvl1[_who]);
    }

    function checkNodesLvl2(address _who) public view returns (uint256) {
        return (nodesLvl2[_who]);
    }

    function checkNodesMoney(address _who) public view returns (uint256) {
        uint256 _cycles = ((block.timestamp - nodeTimestamp[_who]) /
            nodeYieldTime);
        uint256 _amount = ((nodesLvl1[_who] * nodeLvl1Yield) + (nodesLvl2[_who] * nodeLvl2Yield)) * _cycles;
        if (checkNFT(_who)) {
            _amount = (_amount * NFTbonus) / 100;
        }
        return (_amount);
    }

    function claimNodesMoney(address _who) public NodesStopper BlacklistCheck {
        require(((block.timestamp - nodeTimestamp[_who]) / nodeYieldTime) > 0);
        uint256 _amount = checkNodesMoney(_who);
        nodeTimestamp[_who] +=
            ((block.timestamp - nodeTimestamp[_who]) / nodeYieldTime) *
            nodeYieldTime;
        uint256 _taxAmount = (_amount * nodeTax) / 100;
        tokenContract2.transfer(msg.sender, _amount - _taxAmount);
        tokenContract1.TaxDistribution(_taxAmount);
    }

    // Returns true if the user has an NFT.
    function checkNFT(address _who) public view returns (bool) {
        return (NFTContract.balanceOf(_who) > 0);
    }

    function changeNFTContract(IERC721 _contract) public OnlyOwners {
        NFTContract = _contract;
    }

    function withdrawToken() public OnlyOwners {
        require(tokenContract2.balanceOf(address(this)) > 0);
        tokenContract2.transfer(Owner, tokenContract2.balanceOf(address(this)));
    }

    function withdraw() public OnlyOwners {
        require(address(this).balance > 0);
        payable(Owner).transfer(address(this).balance);
    }
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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface AI {
    function decimals() external view returns (uint8);
    function TaxDistribution(uint256 amount) external;
}

contract CryptoNodesCoin is ERC20, AI {
    uint8 public constant _decimals = 18;
    uint8 public tax = 25;
    uint8 private buyTax = 5;

    address private Owner;
    address private presaleContract;
    address private gameContract;
    address private traderJoe;

    address public RewardPool = 0x7df09b9E4c3097dDC17Ca559546d17D346EABF38;
    address public TransitWallet = 0x56597Ff7c7Bd24C701bD65A7A44c5887EF8B3978;
    address public PresaleWallet = 0xc2E6764fD877196193b5aaB735755061d824116b;
    address public TeamWallet = 0x6983D547cFF7bcDe49DD4517F5A0C3B05009b170;
    address public InvestorWallet = 0xa4f45078751B303Efaac8E61F398f7c6aD997579;
    address public MarketingWallet = 0xca29C0573D5ADb74935a5cd6a52c5a0ee75949B3;
    address public TreasuryWallet = 0xCfC7B9C2159395cC44E28101c092A3C92A236282;

    mapping(address => bool) blacklists;
    mapping(address => bool) noTaxAddresses;

    event Blacklist(
        address indexed owner,
        address indexed blacklisted,
        bool indexed added
    );
    event Ownership(
        address indexed owner,
        address indexed newOwner,
        bool indexed added
    );

    constructor(address _owner) ERC20("CryptoNodes Coin", "CRND") {
        Owner = _owner;
        _mint(RewardPool, 560000 * 10**_decimals);
        _mint(TransitWallet, 250000 * 10**_decimals);
        _mint(PresaleWallet, 100000 * 10**_decimals);
        _mint(TeamWallet, 50000 * 10**_decimals);
        _mint(InvestorWallet, 25000 * 10**_decimals);
        _mint(MarketingWallet, 15000 * 10**_decimals);
        noTaxAddresses[RewardPool] = true;
        noTaxAddresses[TransitWallet] = true;
        noTaxAddresses[PresaleWallet] = true;
        noTaxAddresses[TeamWallet] = true;
        noTaxAddresses[InvestorWallet] = true;
        noTaxAddresses[MarketingWallet] = true;
        noTaxAddresses[TreasuryWallet] = true;

    }

    modifier OnlyOwners() {
        require(
            (msg.sender == Owner),
            "You are not the owner of the token."
        );
        _;
    }

    modifier BlacklistCheck() {
        require(blacklists[msg.sender] == false, "You are in the blacklist.");
        _;
    }

    function decimals() public pure override(AI, ERC20) returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        BlacklistCheck
        returns (bool)
    {
        require(balanceOf(msg.sender) >= amount, "You do not have enough tokens.");
        require(recipient != address(0), "The receiver address has to exist.");
        if (msg.sender == presaleContract || noTaxAddresses[msg.sender] == true || msg.sender == gameContract) {
            _transfer(msg.sender, recipient, amount);
        } else if (msg.sender == traderJoe) {
            uint256 taxAmount = (amount * buyTax) / 100;
            _transfer(msg.sender, recipient, amount - taxAmount);
            _transfer(msg.sender, TransitWallet, taxAmount);
        } else {
            uint256 taxAmount = (amount * tax) / 100;
            _transfer(msg.sender, recipient, amount - taxAmount);
            TaxDistributionFrom(msg.sender, taxAmount);
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override BlacklistCheck returns (bool) {
        
        if (msg.sender == gameContract) {
            _transfer(sender, recipient, amount);
        } else {
        if (noTaxAddresses[sender] == true || sender == presaleContract || sender == gameContract) {
            _spendAllowance(sender, msg.sender, amount);
            _transfer(sender, recipient, amount);
        }  else if (msg.sender == traderJoe) {
            uint256 taxAmount = (amount * buyTax) / 100;
            _spendAllowance(sender, traderJoe, amount);
            _transfer(sender, recipient, amount - taxAmount);
            _transfer(sender, TransitWallet, taxAmount);
        }
        else {
            uint256 taxAmount = (amount * tax) / 100;
            _spendAllowance(sender, msg.sender, amount);
            _transfer(sender, recipient, amount - taxAmount);
            TaxDistributionFrom(sender, taxAmount);
        }
        }
        
        return true;
    }

    function changeTax(uint8 _tax) public OnlyOwners {
        tax = _tax;
    }

    function addBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = true;
        emit Blacklist(msg.sender, _who, true);
    }

    function removeBlacklistMember(address _who) public OnlyOwners {
        blacklists[_who] = false;
        emit Blacklist(msg.sender, _who, false);
    }

    function checkBlacklistMember(address _who) public view returns (bool) {
        return blacklists[_who];
    }

    function addNoTaxMember(address _who) public OnlyOwners {
        noTaxAddresses[_who] = true;
        emit Blacklist(msg.sender, _who, true);
    }

    function removeNoTaxMember(address _who) public OnlyOwners {
        noTaxAddresses[_who] = false;
        emit Blacklist(msg.sender, _who, false);
    }

    function checkNoTaxMember(address _who) public view returns (bool) {
        return noTaxAddresses[_who];
    }

    function transferOwner(address _who) public OnlyOwners returns (bool) {
        Owner = _who;
        emit Ownership(msg.sender, _who, true);
        return true;
    }

    function changeLiquidityPool(address _to) public OnlyOwners {
        _transfer(TransitWallet, _to, balanceOf(TransitWallet));
        TransitWallet = _to;
    }

    function addPresaleContract(address _contract) public OnlyOwners {
        presaleContract = _contract;
        _transfer(PresaleWallet, presaleContract, balanceOf(PresaleWallet));
        PresaleWallet = _contract;
    }

    function addGameContract(address _contract) public OnlyOwners {
        gameContract = _contract;
        _transfer(RewardPool, gameContract, balanceOf(RewardPool));
        RewardPool = _contract;
    }

    function addTraderJoe(address _address) public OnlyOwners {
        traderJoe = _address;
    }

    function TaxDistributionFrom(address _sender, uint256 _amount) internal {
        uint256 amount = (_amount * 65) / 100;
        uint256 left = _amount - amount;
        _transfer(_sender, RewardPool, amount);
        amount = (_amount * 15) / 100;
        left -= amount;
        _transfer(_sender, TreasuryWallet, amount);
        amount = (_amount * 10) / 100;
        left -= amount;
        _transfer(_sender, TransitWallet, amount);
        amount = (_amount * 5) / 100;
        _transfer(_sender, MarketingWallet, amount);
        left -= amount;
        _transfer(_sender, TeamWallet, left);
    }

    function TaxDistribution(uint256 _amount) public override {
        uint256 amount = (_amount * 65) / 100;
        uint256 left = _amount - amount;
        _transfer(msg.sender, RewardPool, amount);
        amount = (_amount * 15) / 100;
        left -= amount;
        _transfer(msg.sender, TreasuryWallet, amount);
        amount = (_amount * 10) / 100;
        left -= amount;
        _transfer(msg.sender, TransitWallet, amount);
        amount = (_amount * 5) / 100;
        _transfer(msg.sender, MarketingWallet, amount);
        left -= amount;
        _transfer(msg.sender, TeamWallet, left);
    }

    function withdraw() public OnlyOwners {
        require(address(this).balance > 0);
        payable(Owner).transfer(address(this).balance);
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