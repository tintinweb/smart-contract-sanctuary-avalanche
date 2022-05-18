// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Owners.sol";
import "./EmergencyMode.sol";
import "./libraries/Percentage.sol";

/**
 * @dev An item available to pre-order.
 */
struct Item {
    string name;
    uint256 priceRegular;
    uint256 priceWhitelisted;
}

/**
 * @dev Used by burner contracts, this is the interface that will be used to
 * consume pre-ordered items.
 */
interface IPreSaleBurnable {
    function burnItemTypeFrom(address user, uint itemType)
        external
        returns (
            uint256 tokenAmount,
            uint256 itemAmount,
            string memory itemName
        );
}

/**
 * @notice Locks an ERC20 token in exchange of the future right to buy an item.
 * @dev The actual item can be anything and is therefore only identified by a
 * `string`. The `burner` contract will be responsible to bind the registered
 * item name to the type of asset issued.
 */
contract PreSale is Owners, EmergencyMode, IPreSaleBurnable {
    event PreOrder(
        address user,
        uint256 itemType,
        uint256 itemAmount,
        uint256 tokenAmount
    );

    event OrderBurned(
        address user,
        uint256 itemType,
        uint256 itemAmount,
        uint256 tokenAmount
    );

    using SafeERC20 for IERC20;
    using Percentages for UPercentage;

    IERC20 public immutable paymentToken;
    Item[] public items;
    uint256[] public amountByItemIdx;
    uint256[] public tvlByItemIdx;

    struct PlacedOrder {
        uint256 amount;
        uint256 totalPaid;
    }

    mapping(address => bool) internal whitelist;
    mapping(address => mapping(uint256 => PlacedOrder))
        internal userToItemIdxToAmount;

    address internal burner;
    bool internal openPreOrder = false;
    bool internal openToBurn = false;

    address internal immutable multisig;

    uint256 public maxTVLPerRegularUser;
    uint256 public maxTVLPerWhitelistedUser;

    /**
     * @param _paymentToken Address to the token on which the orders will be
     * accepted.
     * @param itemNames Names of the items to pre-order.
     * @param itemRegularPrices Prices of the items for regular users.
     * @param itemWLPrices Prices of the items for whitelisted users.
     * @param _multisig Address of the multisig wallet allowed to access funds
     * locked in the contract.
     * @param _maxTVLs Tuple of the max TVL by user, index 0 for regular users
     * and index 1 for whitelisted users.
     */
    constructor(
        IERC20 _paymentToken,
        string[] memory itemNames,
        uint256[] memory itemRegularPrices,
        uint256[] memory itemWLPrices,
        address _multisig,
        uint256[] memory _maxTVLs
    ) {
        require(
            itemNames.length == itemRegularPrices.length && itemRegularPrices.length == itemWLPrices.length,
            "Arrays must have the same length"
        );
        
        require(_maxTVLs.length == 2, "Invalid argument length");

        require(_multisig != address(0), "Multisig can't be the zero address");

        for (uint i = 0; i < itemNames.length; i++) {
            items.push(
                Item({
                    name: itemNames[i],
                    priceRegular: itemRegularPrices[i],
                    priceWhitelisted: itemWLPrices[i]
                })
            );
        }

        paymentToken = _paymentToken;
        amountByItemIdx = new uint[](itemNames.length);
        tvlByItemIdx = new uint256[](itemNames.length);
        multisig = _multisig;

        paymentToken.safeApprove(multisig, type(uint256).max);

        maxTVLPerRegularUser = _maxTVLs[0];
        maxTVLPerWhitelistedUser = _maxTVLs[1];
    }

    //========== User-facing interface

    /**
     * @notice Places a pre-order on a given item.
     *
     * @param itemIdx The index of the pre-ordered item.
     * @param amount How many items to pre-order.
     */
    function preOrder(uint itemIdx, uint256 amount) external onlySafeMode {
        require(openPreOrder, "PreSale: not open to pre-orders");
        require(itemIdx < items.length, "PreSale: index out of bounds");
        require(amount > 0, "PreSale: amount can't be zero");

        Item memory item = items[itemIdx];
        uint256 maxTVL;
        uint256 tokenAmountToTransfer = amount;

        if (_isWhitelisted(msg.sender)) {
            maxTVL = maxTVLPerWhitelistedUser;
            tokenAmountToTransfer *= item.priceWhitelisted;
        } else {
            maxTVL = maxTVLPerRegularUser;
            tokenAmountToTransfer *= item.priceRegular;
        }

        require(
            tokenAmountToTransfer + getTotalValueLockedByUser(msg.sender)
                <= maxTVL,
            "PreSale: Maximum TVL reached"
        );

        _createPreOrder(msg.sender, itemIdx, amount, tokenAmountToTransfer);

        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmountToTransfer
        );

        emit PreOrder(msg.sender, itemIdx, amount, tokenAmountToTransfer);
    }

    /**
     * @notice Used in case of emergency, will allow users to get back their
     * all of their locked funds.
     */
    function emergencyRedeem() external onlyEmergencyMode {
        uint256 deposited = _burnAllPreOrdersForUser(msg.sender);
        require(deposited > 0, "PreSale Emergency: no deposits");
        paymentToken.safeTransfer(msg.sender, deposited);
    }

    /**
     * @notice Used in case of emergency, will allow users to get back their
     * locked funds, by item type.
     * @dev To be used if the item list is too long to be iterated on a single
     * transaction by `emergencyRedeem`. Use `getItemsSize` to iterate over all
     * the items.
     *
     * @param itemIdx The item index to redeem.
     */
    function emergencyRedeemByItem(uint itemIdx) public onlyEmergencyMode {
        require(itemIdx < items.length, "PreSale Emergency: out of bounds");
        (,uint256 deposited) = _burnPreOrderForUser(msg.sender, itemIdx);
        require(deposited > 0, "PreSale Emergency: no deposits");

        paymentToken.safeTransfer(msg.sender, deposited);
    }

    //========== Burner-only interface =======================================//

    /**
     * @notice Burns orders of a given user for a given item type.
     * @dev Caller must iterate manually on the item types in order to avoid
     * gas fees explosion if there is too many item types.
     *
     * @param user The user whose orders must be burned.
     * @param itemIdx The item type index of the orders to be burned.
     *
     * @return tokenAmount Amount of token that is transferred to the burner.
     * @return itemAmount How many items were ordered by the user.
     */
    function burnItemTypeFrom(address user, uint itemIdx)
        external
        onlySafeMode
        returns (
            uint256 tokenAmount,
            uint256 itemAmount,
            string memory itemName
        )
    {
        require(openToBurn, "PreSale: not open to burn");
        require(msg.sender == burner, "PreSale: only by Burner");
        require(user != address(0), "PreSale: null address");
        require(itemIdx < items.length, "PreSale: itemIdx out of bounds");

        itemName = items[itemIdx].name;
        (itemAmount, tokenAmount) = _burnPreOrderForUser(user, itemIdx);

        emit OrderBurned(user, itemIdx, itemAmount, tokenAmount);
    }

    //========== Multisig-only interface =====================================//

    function resetAllowance() external {
        require(msg.sender == multisig, "PreSale: only multisig");
        _resetAllowance();
    }

    //========== Owners-only interface =======================================//

    function setWhitelist(address[] calldata users, bool isWhitelisted) external onlyOwners {
        for(uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = isWhitelisted;
        }
    }

    function setOpenPreOrder(bool isOpen) external onlyOwners {
        openPreOrder = isOpen;
    }

    function setOpenToBurn(bool isOpen) external onlyOwners {
        openToBurn = isOpen;
    }

    function setBurner(address _burner) external onlyOwners {
        burner = _burner;
    }

    function setMaxTVLByRegularUser(uint256 maxTVL) external onlyOwners {
        maxTVLPerRegularUser = maxTVL;
    }

    function setMaxTVLByWhitelistedUser(uint256 maxTVL) external onlyOwners {
        maxTVLPerWhitelistedUser = maxTVL;
    }

    //========= Getters =======================================================/

    function getItemsSize() public view returns (uint256) {
        return items.length;
    }

    struct ItemView {
        string name;
        uint256 priceRegular;
        uint256 priceWhitelisted;
        uint amountCreated;
        uint tvl;
    }

    function getItems() public view returns (ItemView[] memory) {
        ItemView[] memory viewItems = new ItemView[](items.length);
        for(uint i = 0; i < items.length; i++) {
            viewItems[i] = ItemView({
                name: items[i].name,
                priceRegular: items[i].priceRegular,
                priceWhitelisted: items[i].priceWhitelisted,
                amountCreated: amountByItemIdx[i],
                tvl: tvlByItemIdx[i]
            });
        }

        return viewItems;
    }

    function getPreOrderByUser(address user)
        public
        view
        returns (PlacedOrder[] memory)
    {
        PlacedOrder[] memory orders = new PlacedOrder[](items.length);
        for (uint i = 0; i < items.length; i++) {
            orders[i] = userToItemIdxToAmount[user][i];
        }

        return orders;
    }

    function getTotalValueLockedByUser(address user)
        public
        view
        returns (uint256 amount)
    {
        for (uint i = 0; i < items.length; i++) {
            amount += userToItemIdxToAmount[user][i].totalPaid;
        }
    }

    function getTotalValueLocked() public view returns (uint256) {
        uint total = 0;
        for(uint i = 0; i < tvlByItemIdx.length; i++) {
            total += tvlByItemIdx[i];
        }

        return total;
    }

    function getTotalPreOrderedItems() public view returns (uint) {
        uint total = 0;
        for(uint i = 0; i < amountByItemIdx.length; i++) {
            total += amountByItemIdx[i];
        }

        return total;
    }

    //========== Internal API =================================================//

    function _isWhitelisted(address user) internal view returns (bool) {
        return whitelist[user];
    }

    function _createPreOrder(address user, uint256 itemIdx, uint256 amount, uint256 totalPrice) internal returns (uint256 newAmount, uint256 totalPaid) {
        newAmount = userToItemIdxToAmount[user][itemIdx].amount += amount;
        totalPaid = userToItemIdxToAmount[user][itemIdx].totalPaid += totalPrice;

        amountByItemIdx[itemIdx] += amount;
        tvlByItemIdx[itemIdx] += totalPrice;
    }

    function _burnPreOrderForUser(address user, uint256 itemIdx) internal returns (uint256 amount, uint256 totalPaid) {
        amount = userToItemIdxToAmount[user][itemIdx].amount;
        totalPaid = userToItemIdxToAmount[user][itemIdx].totalPaid;

        amountByItemIdx[itemIdx] -= amount;
        tvlByItemIdx[itemIdx] -= totalPaid;

        userToItemIdxToAmount[user][itemIdx].amount = 0;
        userToItemIdxToAmount[user][itemIdx].totalPaid = 0;
    }

    function _burnAllPreOrdersForUser(address user) internal returns (uint256 deposited) {
        deposited = 0;
        for(uint i = 0; i < items.length; i++) {
            amountByItemIdx[i] -= userToItemIdxToAmount[user][i].amount;
            userToItemIdxToAmount[user][i].amount = 0;

            tvlByItemIdx[i] -= userToItemIdxToAmount[user][i].totalPaid;
            deposited += userToItemIdxToAmount[user][i].totalPaid;
            userToItemIdxToAmount[user][i].totalPaid = 0;
        }
    }

    function _resetAllowance() internal {
        paymentToken.safeIncreaseAllowance(
            multisig,
            type(uint256).max - paymentToken.allowance(address(this), msg.sender)
        );
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

contract Owners {
	
	address[] public owners;
	mapping(address => bool) public isOwner;

	constructor() {
		owners.push(msg.sender);
		isOwner[msg.sender] = true;
	}

	modifier onlySuperOwner() {
		require(owners[0] == msg.sender, "Owners: Only Super Owner");
		_;
	}
	
	modifier onlyOwners() {
		require(isOwner[msg.sender], "Owners: Only Owner");
		_;
	}

	function addOwner(address _new, bool _change) external onlySuperOwner {
		require(!isOwner[_new], "Owners: Already owner");
		isOwner[_new] = true;
		if (_change) {
			owners.push(owners[0]);
			owners[0] = _new;
		} else {
			owners.push(_new);
		}
	}

	function removeOwner(address _new) external onlySuperOwner {
		require(isOwner[_new], "Owners: Not owner");
		require(_new != owners[0], "Owners: Cannot remove super owner");
		for (uint i = 1; i < owners.length; i++) {
			if (owners[i] == _new) {
				owners[i] = owners[owners.length - 1];
				owners.pop();
				break;
			}
		}
		isOwner[_new] = false;
	}

	function getOwnersSize() external view returns(uint) {
		return owners.length;
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Owners.sol";

contract EmergencyMode is Owners {
    bool public isEmergencyMode = false;

    modifier onlySafeMode() {
        require(!isEmergencyMode, "Emergency mode is activated");
        _;
    }

    modifier onlyEmergencyMode() {
        require(isEmergencyMode, "Emergency mode is not activated");
        _;
    }

    function setEmergencyMode(bool _emergency) external onlyOwners {
        isEmergencyMode = _emergency;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.8;

type UPercentage is uint32;

library Percentages {
	function from(uint32 val) internal pure returns (UPercentage) {
		require(val <= 10000, "Percentages: out of bounds");
		return UPercentage.wrap(val);
	}

	function times(UPercentage p, uint256 val) internal pure returns (uint256) {
		return val * UPercentage.unwrap(p) / 10000;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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