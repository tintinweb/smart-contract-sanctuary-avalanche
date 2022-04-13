/**
 *Submitted for verification at snowtrace.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
pragma solidity 0.7.5;

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
pragma solidity 0.7.5;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

pragma solidity 0.7.5;

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

pragma solidity 0.7.5;

contract AvaxFrogsSpawnPreSale {
    IERC20 public mim;
    IERC20 public spawn;

    address private owner_;
    address private preSaleWallet;
    address private timeFrogsNFTAddress_ =
        address(0xA1B46ff2a3394b9460B4004F2e7401DeC7f7A023);

    mapping(address => bool) private admins;
    mapping(address => bool) public whiteListAddresses;
    mapping(address => uint256) private amountSoldByAddress;

    uint256 public costMIM = 200000000000000000; // 0.2 MIM per SPAWN
    uint256 public maxBuy = 25000;

    bool whiteListOnly = true;
    bool public preSaleLive = false;

    constructor(address _spawnAddr, address _presaleWallet) {
        // MIM address
        mim = IERC20(address(0x130966628846BFd36ff31a822705796e8cb8C18D));
        spawn = IERC20(_spawnAddr);
        preSaleWallet = _presaleWallet;
        owner_ = msg.sender;
        admins[msg.sender] = true;
    }

    /*
    @function togglePresale(_value)
    @description - Set pre-sale live/not live
    @param <bool> _value - The value
  */
    function togglePresale(bool _value) external onlyAdmins {
        preSaleLive = _value;
    }

    /*
    @function setWhitelistOnly(_value)
    @description - Set white list only
    @param <bool> _value - The whitelist value
  */
    function setWhitelistOnly(bool _value) external onlyAdmins {
        whiteListOnly = _value;
    }

    /*
    @function setWhitelistOnly(_value)
    @description - Set white list only
    @param <bool> _value - The whitelist value
  */
    function isWhitelisted() public view returns (bool) {
        bool whiteListed = whiteListAddresses[msg.sender];
        return whiteListed;
    }

    /*
    @function addWhiteListAddresses()
    @description - Adds a batch of addresses to white list
    */
    function addWhiteListAddresses(address[] calldata _addresses)
        public
        onlyOwner
    {
        require(_addresses.length < 500, "ERROR: Too many in one tx");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteListAddresses[_addresses[i]] = true;
        }
    }

    /*
    @function setCostMIM(_cost)
    @description - Set the mim cost
    @param <address> _cost - The new cost
  */
    function setCostMIM(uint256 _cost) external onlyAdmins {
        costMIM = _cost;
    }

    /*
    @function addAdmin(newAdmin)
    @description - Add an admin who can process airdrops
    @param <address> newAdmin - The new admin to add
  */
    function addAdmin(address newAdmin) external onlyAdmins {
        require(newAdmin != msg.sender, "Admin: You are already an admin!");
        admins[newAdmin] = true;
    }

    /*
    @function addAdmin(newAdmin)
    @description - Removes an admin who can process airdrops
    @param <address> admin - The admin to remove
  */
    function removeAdmin(address admin) external onlyAdmins {
        require(
            admin != owner_,
            "ERROR: You cannot remove contract owner as admin."
        );
        admins[admin] = false;
    }

    /*
    @function dropMemo(recipients, amount)
    @description - Drops the amount of memo specified to each address in recipients
    @param <uint256> amount - The amount of MEMO to drop to each address
    @param <address[]> recipients - The recipients to receive the MEMO
  */
    function buy(uint256 amount) external {
        require(preSaleLive, "ERROR: Pre-sale not live yet");
        // total cost in MIM, including the 18 decimals
        uint256 totalMIM = (costMIM * amount);

        // Get the current balance of spawn in this ctx
        uint256 presaleBalance = spawn.balanceOf(address(this));

        // Calculate the amount of spawn to transfer, with 9 decimals
        uint256 amountSpawn = (amount * 1000000000);

        // see how much they have already bought
        uint256 alreadyBought = amountSoldByAddress[msg.sender];

        // Make sure the amount already bought plus the current purchase
        // is not over pre-sale amount
        require(
            (alreadyBought + amount) <= maxBuy,
            "ERROR: Max 5,000 $spawan per address in presale!"
        );

        // Make sure the buy is within limit
        require(amount <= maxBuy, "ERROR: Max buy is 5,000");

        if (whiteListOnly) {
            // Check for Whitelist
            require(
                whiteListAddresses[msg.sender] == true,
                "ERROR: You are not part of the white list."
            );
        }

        // Check that this contract can spend the required amount of MIM
        require(
            mim.allowance(msg.sender, address(this)) >= totalMIM,
            "ERROR: Not approved to spend enough MIM"
        );

        // Check that there is enough balance
        require(
            mim.balanceOf(address(msg.sender)) >= totalMIM,
            "ERROR: Not enough MIM balance"
        );

        // Check there are funds left to sell
        require(presaleBalance >= amountSpawn, "ERROR: Not enough tokens left");


        mim.transferFrom(msg.sender, preSaleWallet, totalMIM);
        spawn.transfer(msg.sender, amountSpawn);
        amountSoldByAddress[msg.sender] += amount;
    }


    /*
    @function withdraw()
    @description - Withdraws any excess that accidentally gets left in contract
  */
    function withdrawMIM() external onlyOwner {
        mim.transfer(owner_, mim.balanceOf(address(this)));
    }

    /*
    @function withdraw()
    @description - Withdraws any excess that accidentally gets left in contract
  */
    function withdrawSpawn() external onlyOwner {
        spawn.transfer(owner_, spawn.balanceOf(address(this)));
    }

    /*
    @modifier onlyAdmins()
    @description - Makes sure that only the admins can execute drops
  */
    modifier onlyAdmins() {
        bool valid = false;
        require(admins[msg.sender], "Admin: caller is not a admin!");
        _;
    }
    /*
    @modifier onlyOwner()
    @description - Makes sure that only the owner can execute
  */
    modifier onlyOwner() {
        require(msg.sender == owner_, "Owner: caller is not a owner!");
        _;
    }

    function spawnBalance() public view returns(uint256) {
        // Get the current balance of spawn in this ctx
        uint256 presaleBalance = spawn.balanceOf(address(this));
        return presaleBalance;
    }
}