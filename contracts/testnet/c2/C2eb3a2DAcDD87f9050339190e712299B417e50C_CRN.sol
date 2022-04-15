// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract CRN is IERC20 {
    // Attributes. Change at your own will. THOUGH DON'T TOUCH THE "10**_decimals" PART!
    string public constant name = "Crypto Nodes";
    string public constant symbol = "CRN";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * 10**_decimals; //Total amount of tokens
    // bool public presale = false;

    uint8 public tax = 25;

    uint8 private buyTax = 5;

    uint256 constant rate = 100;

    uint8 constant NFTbonus = 125;
    // TODO : Change the Owner.
    address private Owner =
        0xF88635f443F0B8160aE7d0da7B649eb3282B15Ef;

    address private presalecontract;

    IERC721 private NFTContract;

    // Node attributes.
    bool nodespaused = true;
    uint8 constant nodePrice = 10;
    uint8 constant nodeTax = 10;
    uint256 nodeAmountlvl1 = 0;
    uint256 nodeAmountlvl2 = 0;
    mapping(address => uint256) nodesLvl1;
    mapping(address => uint256) nodesLvl2;
    mapping(address => uint256) nodeTimestamp;
    uint256 constant nodeYieldTime = 20; // TODO : Change to 86400 after debugging.
    uint256 nodeLvl1Yield = 15 * 10**(_decimals - 2);
    uint256 nodeLvl2Yield = 6 * 10**(_decimals);

    // 1 - Reward Pool, 2 - Liquid Pool, 3 - Presale Wallet, 4 - Team Wallet, 5 - Investor Wallet, 6 - Marketing Wallet, 7 - Treasure Wallet
    mapping(uint8 => uint256) private wallets;

    mapping(address => bool) whitelists;
    mapping(address => bool) blacklists;
    mapping(address => bool) noTaxAdresses;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    event Whitelist(
        address indexed owner,
        address indexed whitelister,
        bool indexed added
    );
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
    event PresaleTransaction(
        address indexed buyer,
        uint256 indexed amount,
        uint256 tax
    );

    // Total amount is hard-coded at the start just as an info button. Change these values to anything you want. ALSO DON'T TOUCH THE "10**_decimals" PART!
    constructor(IERC721 _NFTContract, address _owner) {
        NFTContract = _NFTContract;
        Owner = _owner;
        balances[msg.sender] = 100000 * 10**_decimals; //TODO: Used for debugging. Remove later
        wallets[1] = 560000 * 10**_decimals;
        wallets[2] = 250000 * 10**_decimals;
        wallets[3] = 100000 * 10**_decimals;
        wallets[4] = 50000 * 10**_decimals;
        wallets[5] = 25000 * 10**_decimals;
        wallets[6] = 15000 * 10**_decimals;
    }

    modifier OnlyOwners() {
        require(
            (msg.sender == Owner),
            "You are not the owner of the token"
        );
        _;
    }

    modifier BlacklistCheck() {
        require(blacklists[msg.sender] == false, "You are in the blacklist");
        _;
    }

    modifier NodesStopper() {
        require(nodespaused == false, "Nodes code is currently stopped.");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _who) public view override returns (uint256) {
        return balances[_who];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        BlacklistCheck
        returns (bool)
    {
        require(amount <= balances[msg.sender], "You do not have enough CRN");
        require(recipient != address(0), "The receiver address has to exist");
        if (msg.sender == presalecontract || noTaxAdresses[msg.sender] == true) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
        } else {
            uint256 taxAmount = (amount * tax) / 100;
            balances[msg.sender] -= amount;
            balances[recipient] += amount - taxAmount;
            TaxDistribution(taxAmount);
            emit Transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        BlacklistCheck
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        BlacklistCheck
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override BlacklistCheck returns (bool) {
        require(
            allowances[sender][msg.sender] >= amount && amount > 0,
            "You do not have enough CRN"
        );
        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        uint256 taxAmount = (amount * tax) / 100;
        balances[recipient] += amount - taxAmount;
        TaxDistribution(taxAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // tax variable is a percentage. Example, 25% = 25.
    function changeTax(uint8 _tax) public OnlyOwners {
        tax = _tax;
    }

    function walletWithdraw(
        uint8 _walletID,
        address _to,
        uint256 _amount
    ) public OnlyOwners {
        require(
            wallets[_walletID] >= _amount,
            "Wallet doesn't have enough tokens"
        );
        wallets[_walletID] -= _amount;
        balances[_to] += _amount;
    }

    function walletDeposit(uint8 _walletID, uint256 _amount) public OnlyOwners {
        require(
            balances[msg.sender] >= _amount,
            "You don't have enought tokens"
        );
        balances[msg.sender] -= _amount;
        wallets[_walletID] += _amount;
    }

    function walletRedistribution(
        uint8 _ID1,
        uint8 _ID2,
        uint256 _amount
    ) public OnlyOwners {
        require(wallets[_ID1] >= _amount, "Wallet doesn't have enough tokens");
        wallets[_ID1] -= _amount;
        wallets[_ID2] += _amount;
    }

    function walletCheck() public view OnlyOwners returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256){
        return(wallets[1], wallets[2], wallets[3], wallets[4], wallets[5], wallets[6], wallets[7]);
    }

    //TODO: Make the same way like whitelist (signature method)?
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
        noTaxAdresses[_who] = true;
        emit Blacklist(msg.sender, _who, true);
    }

    function removeNoTaxMember(address _who) public OnlyOwners {
        noTaxAdresses[_who] = false;
        emit Blacklist(msg.sender, _who, false);
    }

    function checkNoTaxMember(address _who) public view returns (bool) {
        return noTaxAdresses[_who];
    }

    function transferOwner(address _who) public OnlyOwners returns (bool) {
        Owner = _who;
        emit Ownership(msg.sender, _who, true);
        return true;
    }

    function addPresaleContract(address _contract) public OnlyOwners {
        presalecontract = _contract;
        balances[presalecontract] += wallets[3];
        wallets[3] = 0;
    }

    function changeNFTContract(IERC721 _contract) public OnlyOwners {
        NFTContract = _contract;
    }

    // Node code starts here

    event NodesCreated(address indexed who, uint256 indexed amount);
    event NodesUpgraded(
        address indexed who,
        uint256 indexed amount,
        uint8 indexed lvl
    );

    function TaxDistribution(uint256 _amount) public {
        uint256 amount = (_amount * 65) / 100;
        uint256 left = _amount - amount;
        wallets[1] += amount; // Reward Pool
        amount = (_amount * 15) / 100;
        left -= amount;
        wallets[7] += amount; // Treasure Wallet
        amount = (_amount * 10) / 100;
        left -= amount;
        wallets[2] += amount; // Liquidity Pool
        amount = (_amount * 5) / 100;
        left -= amount;
        wallets[6] += amount; // Marketing Wallet
        left -= amount;
        wallets[4] += left; // Team Wallet
    }

    function stopNodes(bool _status) public OnlyOwners {
        nodespaused = _status;
    }

    function createNodes(uint256 _amount) public NodesStopper BlacklistCheck {
        require(
            balances[msg.sender] >= _amount * nodePrice * 10**_decimals,
            "You don't have enough CRN."
        );
        balances[msg.sender] -= _amount * nodePrice * 10**_decimals;

        TaxDistribution(_amount * nodePrice * 10**_decimals);

        nodesLvl1[msg.sender] += _amount;
        nodeAmountlvl1 += _amount;
        if (nodeTimestamp[msg.sender] == 0) {
            nodeTimestamp[msg.sender] = block.timestamp;
        }
        emit NodesCreated(msg.sender, _amount);
    }

    function upgradeToLvl2(uint256 _amount) public NodesStopper BlacklistCheck {
        require(
            balances[msg.sender] >= (30 * 10**_decimals) * _amount,
            "You don't have enough CRN"
        );
        require(
            nodesLvl1[msg.sender] >= _amount * 25,
            "You don't have enough level 1 nodes"
        );

        balances[msg.sender] -= (30 * 10**_decimals) * _amount;
        TaxDistribution((30 * 10**_decimals) * _amount);

        nodesLvl1[msg.sender] -= _amount * 25;
        nodesLvl2[msg.sender] += _amount;
        nodeAmountlvl2 += _amount;
        emit NodesUpgraded(msg.sender, _amount, 2);
    }

    function totalNodesLvl1() public view returns (uint256) {
        return(nodeAmountlvl1);
    }

    function totalNodesLvl2() public view returns (uint256) {
        return(nodeAmountlvl2);
    }

    function checkNodesLvl1(address _who) public view returns (uint256) {
        return (nodesLvl1[_who]);
    }

    function checkNodesLvl2(address _who) public view returns (uint256) {
        return (nodesLvl2[_who]);
    }

    function checkNodesMoney(address _who) public view returns (uint256) {
        uint256 _amount = (((block.timestamp - nodeTimestamp[_who]) /
            nodeYieldTime) *
            (nodesLvl1[_who] * nodeLvl1Yield) +
            ((nodesLvl2[_who] * nodeLvl2Yield)));
        if (checkNFT(_who)) {
            _amount = (_amount * NFTbonus) / 100;
        }
        return _amount;
    }

    function claimNodesMoney(address _who) public NodesStopper BlacklistCheck {
        require(((block.timestamp - nodeTimestamp[_who]) / nodeYieldTime) > 0);
        uint256 _amount = checkNodesMoney(_who);
        nodeTimestamp[_who] +=
            ((block.timestamp - nodeTimestamp[_who]) / nodeYieldTime) *
            nodeYieldTime;
        wallets[1] -= _amount;
        uint256 _taxAmount = (_amount * nodeTax) / 100;
        _amount -= _taxAmount;
        wallets[2] += _taxAmount;
        balances[_who] += _amount;
    }

    // Returns true if the user has an NFT.
    function checkNFT(address _who) public view returns (bool) {
        return (NFTContract.balanceOf(_who) > 0);
    }

    // End of Nodes code.

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