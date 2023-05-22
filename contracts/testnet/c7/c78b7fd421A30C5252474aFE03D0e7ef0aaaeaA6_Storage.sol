// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error ETHER_TRANSFER_FAILED();
error ERC20_TRANSFER_FAILED();
error FUNCTION_LOCKED();
error ONLY_ONWER_CAN_CALL();
error ONLY_WHITELIST_CAN_CALL();
error ALREADY_WHITELISTED();
error NOT_WHITELISTED();

contract Storage {
    /// @notice address of the treasury contract
    address private treasury;

    /// @notice value of locked for reentrancy security
    uint256 private locked;

    /// @notice address of the owner
    address private owner;

    /// @notice Variable to store the total number of storage bundles
    uint256 private bundleStoreID;

    /**
     * @notice modifier to save from the reentrancy attack
     */
    modifier noReentrant() {
        if (locked != 0) {
            revert FUNCTION_LOCKED();
        }

        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @notice modifier to check that only the owner can call the function
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ONLY_ONWER_CAN_CALL();
        }
        _;
    }

    /**
     * @dev modifier to allow only whitelisted addresses and owner address to call the function
     */
    modifier onlyAllowList() {
        if (!(whiteListed[msg.sender]) && msg.sender != owner) {
            revert ONLY_WHITELIST_CAN_CALL();
        }
        _;
    }

    /**
     * @notice struct to store the details of the file
     */
    struct Content {
        address user;
        bytes cid;
        bytes config;
        bytes fileName;
        uint256 fileSize;
    }

    /**
     * @notice struct to store data of the user
     */
    struct UserStorage {
        uint256 totalStored;
        bytes[] cids;
    }

    /**
     * @notice Emitted when bundle storage passes
     */
    event BundleStorageRequest(
        uint256 indexed id,
        uint256 blocknumber,
        address indexed uploader,
        bool didAllSuceed,
        Content[] contents
    );

    /**
     * @notice Mapping to track the data stored by the user
     */
    mapping(address => UserStorage) public storageList;

    /**
     * @notice mapping to keep track of whitelisted addresses
     */
    mapping(address => bool) public whiteListed;

    /**
     * @notice constructor to set the initial value
     * @param _treasury address of the treasury contract
     * @param _owner address of the owner
     */
    constructor(address _treasury, address _owner) {
        treasury = _treasury;
        owner = _owner;
    }

    /**
     * @notice function to keep an on-chain record of Bundle Storage Requests
     * @dev inputs are in bytes form, not in string form
     * @param _contents details of the files that will be stored in Filecoin
     */
    function bundleStore(Content[] calldata _contents) external onlyAllowList {
        uint256 length = _contents.length;
        for (uint256 i = 0; i < length; ) {
            updateStorage(_contents[i].user, _contents[i].fileSize, _contents[i].cid);
            unchecked {
                ++i;
            }
        }
        // increase the number of BundleStore
        unchecked {
            ++bundleStoreID;
        }
        emit BundleStorageRequest(bundleStoreID, block.number, msg.sender, true, _contents);
    }

    /**
     *  @notice This function modifies a user's storage balance based on any file update and updates the list of CIDs associated with that user.
     *  @param _user user Address
     *  @param _filesize size of the file
     *  @param _cid CID of the file
     */
    function updateStorage(address _user, uint256 _filesize, bytes calldata _cid) private {
        storageList[_user].cids.push(_cid);
        storageList[_user].totalStored = storageList[_user].totalStored + (_filesize);
    }

    /**
     * @notice function to whitelist an address
     * @param _address address we want to whitelist
     */
    function addWhitelistAddress(address _address) external onlyOwner {
        if (whiteListed[_address]) {
            revert ALREADY_WHITELISTED();
        }
        whiteListed[_address] = true;
    }

    /**
     * @notice function to remove the address from whitelist
     * @param _address address we want to remove from whitelist
     */
    function removeWhitelistAddress(address _address) external onlyOwner {
        if (!whiteListed[_address]) {
            revert NOT_WHITELISTED();
        }
        whiteListed[_address] = false;
    }

    /**
     * @notice function to transfer Storage contract funds to endowment and Treasaury
     * @param _endow address of endowment contract
     * @param _token address of the token
     */
    function transferTo(address _endow, address _token) public noReentrant {
        IERC20 token = IERC20(_token);
        transferToTreasury(_token);
        if (!token.transfer(_endow, token.balanceOf(address(this)))) {
            revert ERC20_TRANSFER_FAILED();
        }
    }

    /**
     * @notice function to transfer tokens to Treasury
     * @param _token address of the token
     */
    function transferToTreasury(address _token) private {
        IERC20 token = IERC20(_token);
        uint treasuryAmount = (token.balanceOf(address(this)) * 25) / 100;
        if (!token.transfer(treasury, treasuryAmount)) {
            revert ERC20_TRANSFER_FAILED();
        }
    }

    /**
     * @notice function to update the address of Treasury contract
     * @param _treasury address of Treasury contract
     */
    function updateTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    // --------- Getter Functions ----------

    /**
     * @notice function to get the token balance of the contract
     * @param _token address of the token
     */
    function getErc20Balance(address _token) public view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice view total Bundle created
     */
    function getTotalBundle() external view returns (uint256) {
        return bundleStoreID;
    }

    /**
     * @notice get the CIDs store by the user
     * @dev output is in bytes form, not in string
     * @param _user address of the user
     */
    function getUserCids(address _user) external view returns (bytes[] memory) {
        return storageList[_user].cids;
    }

    /**
     * @notice get the total amount storage used by user
     * @param _user addres of the user
     */
    function getUserStorage(address _user) external view returns (uint256) {
        return storageList[_user].totalStored;
    }

    /**
     * @notice check whether this address is whitelisted
     * @param _user address of the user
     */
    function checkWhiteAddress(address _user) external view returns (bool) {
        return whiteListed[_user];
    }

    /**
     * @notice get the address of the treasury contract
     */
    function getTreasury() external view returns (address) {
        return treasury;
    }

    /**
     * @notice get the address of the owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @notice get the current lock value
     * ! @dev can be removed
     */
    function getLockedValue() external view returns (uint256) {
        return locked;
    }
}