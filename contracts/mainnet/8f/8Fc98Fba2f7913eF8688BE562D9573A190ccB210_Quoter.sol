// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

import {IERC20 as _IERC20} from "@openzeppelin/contracts-solc8/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is _IERC20 {
    function nonces(address) external view returns (uint256); // Only tokens that support permit

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external; // Only tokens that support permit

    function mint(address to, uint256 amount) external; // only tokens that support minting
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

library Bytes {
    function toBytes(address x)
        internal
        pure
        returns (bytes memory b)
    {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toAddress(uint _offst, bytes memory _input)
        internal
        pure
        returns (address _output)
    {
        assembly { _output := mload(add(_input, _offst)) }
    }

    function toBytes(uint256 x)
        internal
        pure
        returns (bytes memory b)
    {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toUint256(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint256 _output)
    {
        assembly { _output := mload(add(_input, _offst)) }
    }

    function mergeBytes(bytes memory a, bytes memory b)
        internal
        pure
        returns (bytes memory c)
    {
        // From https://ethereum.stackexchange.com/a/40456
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBasicQuoter} from "./interfaces/IBasicQuoter.sol";
import {IBasicRouter} from "./interfaces/IBasicRouter.sol";

import {Ownable} from "@openzeppelin/contracts-4.4.2/access/Ownable.sol";
import {Bytes} from "@synapseprotocol/sol-lib/contracts/universal/lib/LibBytes.sol";

contract BasicQuoter is Ownable, IBasicQuoter {
    /// @notice A list of tokens that will be used as "intermediate" tokens, when
    /// finding the best path between initial and final token
    address[] internal trustedTokens;

    /// @notice A list of adapters that are abstracting away swaps via third party contracts
    address[] internal trustedAdapters;

    /// @notice Maximum amount of swaps that Quoter will be using
    /// for finding the best path between two tokens.
    /// This is done for two reasons:
    /// 1. Too many swaps in the path make very little sense
    /// 2. Every extra swap increases the amount of possible paths exponentially,
    ///    so we need some sensible limitation.
    // solhint-disable-next-line
    uint8 public MAX_SWAPS;

    address payable public immutable router;

    constructor(address payable _router, uint8 _maxSwaps) {
        setMaxSwaps(_maxSwaps);
        router = _router;
    }

    // -- MODIFIERS --

    modifier checkTokenIndex(uint8 index) {
        require(index < trustedTokens.length, "Token index out of range");
        _;
    }

    modifier checkAdapterIndex(uint8 index) {
        require(index < trustedAdapters.length, "Adapter index out of range");
        _;
    }

    //  -- VIEWS --

    function getTrustedAdapter(uint8 index)
        external
        view
        checkAdapterIndex(index)
        returns (address)
    {
        return trustedAdapters[index];
    }

    function getTrustedToken(uint8 index)
        external
        view
        checkTokenIndex(index)
        returns (address)
    {
        return trustedTokens[index];
    }

    function trustedAdaptersCount() external view returns (uint256) {
        return trustedAdapters.length;
    }

    function trustedTokensCount() external view returns (uint256) {
        return trustedTokens.length;
    }

    // -- RESTRICTED ADAPTER FUNCTIONS --

    function addTrustedAdapter(address adapter) external onlyOwner {
        for (uint8 i = 0; i < trustedAdapters.length; i++) {
            require(trustedAdapters[i] != adapter, "Adapter already added");
        }
        trustedAdapters.push(adapter);
        // Add Adapter to Router as well
        IBasicRouter(router).addTrustedAdapter(adapter);
        emit AddedTrustedAdapter(adapter);
    }

    function removeAdapter(address adapter) external onlyOwner {
        for (uint8 i = 0; i < trustedAdapters.length; i++) {
            if (trustedAdapters[i] == adapter) {
                _removeAdapterByIndex(i);
                return;
            }
        }
        revert("Adapter not found");
    }

    function removeAdapterByIndex(uint8 index) external onlyOwner {
        _removeAdapterByIndex(index);
    }

    // -- RESTRICTED TOKEN FUNCTIONS --

    function addTrustedToken(address token) external onlyOwner {
        for (uint8 i = 0; i < trustedTokens.length; i++) {
            require(trustedTokens[i] != token, "Token already added");
        }
        trustedTokens.push(token);
        emit AddedTrustedToken(token);
    }

    function removeToken(address token) external onlyOwner {
        for (uint8 i = 0; i < trustedTokens.length; i++) {
            if (trustedTokens[i] == token) {
                _removeTokenByIndex(i);
                return;
            }
        }
        revert("Token not found");
    }

    function removeTokenByIndex(uint8 index) external onlyOwner {
        _removeTokenByIndex(index);
    }

    // -- RESTRICTED SETTERS

    /// @dev This doesn't check if any of the adapters are duplicated,
    /// so make sure to check the data for duplicates
    function setAdapters(address[] calldata adapters) external onlyOwner {
        // First, remove old Adapters, if there are any
        if (trustedAdapters.length > 0) {
            IBasicRouter(router).setAdapters(trustedAdapters, false);
        }
        trustedAdapters = adapters;
        IBasicRouter(router).setAdapters(adapters, true);
        emit UpdatedTrustedAdapters(adapters);
    }

    function setMaxSwaps(uint8 _maxSwaps) public onlyOwner {
        MAX_SWAPS = _maxSwaps;
    }

    /// @dev This doesn't check if any of the tokens are duplicated,
    /// so make sure to check the data for duplicates
    function setTokens(address[] calldata tokens) public onlyOwner {
        trustedTokens = tokens;
        emit UpdatedTrustedTokens(tokens);
    }

    // -- PRIVATE FUNCTIONS --

    function _removeAdapterByIndex(uint8 index)
        private
        checkAdapterIndex(index)
    {
        address removedAdapter = trustedAdapters[index];

        // We don't care about adapters order, so we replace the
        // selected adapter with the last one
        trustedAdapters[index] = trustedAdapters[trustedAdapters.length - 1];
        trustedAdapters.pop();

        // Remove Adapter from Router as well
        IBasicRouter(router).removeAdapter(removedAdapter);

        emit RemovedAdapter(removedAdapter);
    }

    function _removeTokenByIndex(uint8 index) private checkTokenIndex(index) {
        address removedToken = trustedTokens[index];

        // We don't care about tokens order, so we replace the
        // selected token with the last one
        trustedTokens[index] = trustedTokens[trustedTokens.length - 1];
        trustedTokens.pop();

        emit RemovedToken(removedToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BasicQuoter} from "./BasicQuoter.sol";

import {IAdapter} from "./interfaces/IAdapter.sol";
import {IQuoter} from "./interfaces/IQuoter.sol";
import {IBasicRouter} from "./interfaces/IBasicRouter.sol";

import {Offers} from "./libraries/LibOffers.sol";

import {Bytes} from "@synapseprotocol/sol-lib/contracts/universal/lib/LibBytes.sol";

contract Quoter is BasicQuoter, IQuoter {
    /// @dev Setup flow:
    /// 1. Create Router contract
    /// 2. Create Quoter contract
    /// 3. Give Quoter ADAPTERS_STORAGE_ROLE in Router contract
    /// 4. Add tokens and adapters

    /// PS. If the migration from one Quoter to another is needed (w/0 changing Router):
    /// 1. call oldQuoter.setAdapters([]), this will clear the adapters in Router
    /// 2. revoke ADAPTERS_STORAGE_ROLE from oldQuoter
    /// 3. Do (2-4) from setup flow as usual
    constructor(address payable _router, uint8 _maxSwaps)
        BasicQuoter(_router, _maxSwaps)
    {
        this;
    }

    // -- FIND BEST PATH --

    /**
        @notice Find the best path between two tokens

        @param amountIn amount of initial tokens to swap
        @param tokenIn initial token to sell
        @param tokenOut final token to buy
        @param maxSwaps maximum amount of swaps in the route between initial and final tokens
    */
    function findBestPath(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint8 maxSwaps
    ) public view returns (Offers.FormattedOffer memory _bestOffer) {
        require(
            maxSwaps > 0 && maxSwaps <= MAX_SWAPS,
            "Quoter: Invalid max-swaps"
        );
        Offers.Offer memory queries;
        queries.amounts = Bytes.toBytes(amountIn);
        queries.path = Bytes.toBytes(tokenIn);

        queries = _findBestPath(amountIn, tokenIn, tokenOut, maxSwaps, queries);

        // If no paths are found, return empty struct
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return Offers.formatOfferWithGas(queries);
    }

    // -- INTERNAL HELPERS

    /**
        @notice Find the best path between two tokens
        @dev Part of the route is fixed, which is reflected in queries
             The return value is unformatted byte arrays, use Offers.formatOfferWithGas() to format

        @param amountIn amount of current tokens to swap
        @param tokenIn current token to sell
        @param tokenOut final token to buy
        @param maxSwaps maximum amount of swaps in the route between initial and final tokens
        @param queries Fixed prefix of the route between initial and final tokens
        @return bestOption bytes amounts, bytes adapters, bytes path
     */
    function _findBestPath(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 maxSwaps,
        Offers.Offer memory queries
    ) internal view returns (Offers.Offer memory) {
        Offers.Offer memory bestOption = Offers.cloneOfferWithGas(queries);
        /// @dev bestAmountOut is net returns of the swap,
        /// this is the parameter that should be maximized

        // bestAmountOut: amount of tokenOut in the local best found route

        // First check if there is a path directly from tokenIn to tokenOut
        uint256 bestAmountOut = _checkDirectSwap(
            amountIn,
            tokenIn,
            tokenOut,
            bestOption
        );

        // Check for swaps through intermediate tokens, only if there are enough swaps left
        // Need at least two extra swaps
        if (maxSwaps > 1 && queries.adapters.length / 32 <= maxSwaps - 2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i = 0; i < trustedTokens.length; i++) {
                address trustedToken = trustedTokens[i];
                // trustedToken == tokenIn  means swap isn't possible
                // trustedToken == tokenOut was checked above in _checkDirectSwap
                if (trustedToken == tokenIn || trustedToken == tokenOut) {
                    continue;
                }
                // Loop through all adapters to find the best one
                // for swapping tokenIn for one of the trusted tokens

                Query memory bestSwap = queryDirectSwap(
                    amountIn,
                    tokenIn,
                    trustedToken
                );
                if (bestSwap.amountOut == 0) {
                    continue;
                }
                Offers.Offer memory newOffer = Offers.cloneOfferWithGas(
                    queries
                );
                // add bestSwap to the current route
                Offers.addQuery(
                    newOffer,
                    bestSwap.amountOut,
                    bestSwap.adapter,
                    bestSwap.tokenOut
                );
                // Find best path, starting with current route + bestSwap
                // new current token is trustedToken
                // its amount is bestSwap.amountOut
                newOffer = _findBestPath(
                    bestSwap.amountOut,
                    trustedToken,
                    tokenOut,
                    maxSwaps,
                    newOffer
                );
                address lastToken = Bytes.toAddress(
                    newOffer.path.length,
                    newOffer.path
                );
                // Check that the last token in the path is tokenOut and update the new best option
                // only if amountOut is increased
                if (lastToken == tokenOut) {
                    uint256 newAmountOut = Bytes.toUint256(
                        newOffer.amounts.length,
                        newOffer.amounts
                    );

                    // bestAmountOut == 0 means we don't have the "best" option yet
                    if (bestAmountOut < newAmountOut || bestAmountOut == 0) {
                        bestAmountOut = newAmountOut;
                        bestOption = newOffer;
                    }
                }
            }
        }
        return bestOption;
    }

    /**
        @notice Get the best swap quote using any of the adapters
        @param amountIn amount of tokens to swap
        @param tokenIn token to sell
        @param tokenOut token to buy
        @return bestQuery Query with best quote available
     */
    function queryDirectSwap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (Query memory bestQuery) {
        for (uint8 i = 0; i < trustedAdapters.length; ++i) {
            address adapter = trustedAdapters[i];
            uint256 amountOut = IAdapter(adapter).query(
                amountIn,
                tokenIn,
                tokenOut
            );
            if (amountOut == 0) {
                continue;
            }

            // bestQuery.amountOut == 0 means there's no "best" yet
            if (amountOut > bestQuery.amountOut || bestQuery.amountOut == 0) {
                bestQuery = Query(adapter, tokenIn, tokenOut, amountOut);
            }
        }
    }

    /**
        @notice Find the best direct swap between tokens and append it to current Offer
        @dev Nothing will be appended, if no direct route between tokens is found
        @param amountIn amount of initial token to swap
        @param tokenIn current token to sell
        @param tokenOut final token to buy
        @param bestOption current Offer to append the found swap
     */
    function _checkDirectSwap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        Offers.Offer memory bestOption
    ) internal view returns (uint256 amountOut) {
        Query memory queryDirect = queryDirectSwap(amountIn, tokenIn, tokenOut);
        if (queryDirect.amountOut != 0) {
            Offers.addQuery(
                bestOption,
                queryDirect.amountOut,
                queryDirect.adapter,
                queryDirect.tokenOut
            );
            amountOut = queryDirect.amountOut;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6;

interface IAdapter {
    event UpdatedGasEstimate(address indexed adapter, uint256 newEstimate);

    event Recovered(address indexed asset, uint256 amount);

    function name() external view returns (string memory);

    function swapGasEstimate() external view returns (uint256);

    function depositAddress(address tokenIn, address tokenOut)
        external
        view
        returns (address);

    function swap(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        address to
    ) external returns (uint256);

    function query(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBasicQuoter {
    event UpdatedTrustedAdapters(address[] newTrustedAdapters);

    event AddedTrustedAdapter(address newTrustedAdapter);

    event RemovedAdapter(address removedAdapter);

    event RemovedAdapters(address[] removedAdapters);

    event UpdatedTrustedTokens(address[] newTrustedTokens);

    event AddedTrustedToken(address newTrustedToken);

    event RemovedToken(address removedToken);

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

    //  -- VIEWS --

    function getTrustedAdapter(uint8 index) external view returns (address);

    function getTrustedToken(uint8 index) external view returns (address);

    function trustedAdaptersCount() external view returns (uint256);

    function trustedTokensCount() external view returns (uint256);

    // -- ADAPTER FUNCTIONS --

    function addTrustedAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function removeAdapterByIndex(uint8 index) external;

    // -- TOKEN FUNCTIONS --

    function addTrustedToken(address token) external;

    function removeToken(address token) external;

    function removeTokenByIndex(uint8 index) external;

    // -- SETTERS --

    function setAdapters(address[] calldata adapters) external;

    function setMaxSwaps(uint8 maxSwaps) external;

    function setTokens(address[] memory tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/IERC20.sol";

interface IBasicRouter {
    event Recovered(address indexed asset, uint256 amount);

    event AddedTrustedAdapter(address newTrustedAdapter);

    event RemovedAdapter(address removedAdapter);

    event UpdatedAdapters(address[] adapters, bool isTrusted);

    // -- VIEWS --

    function isTrustedAdapter(address adapter) external view returns (bool);

    // solhint-disable-next-line
    function WGAS() external view returns (address payable);

    // -- ADAPTER FUNCTIONS --

    function addTrustedAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function setAdapters(address[] memory adapters, bool status) external;

    // -- RECOVER FUNCTIONS --

    function recoverERC20(IERC20 token) external;

    function recoverGAS() external;

    // -- RECEIVE GAS FUNCTION --

    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBasicQuoter} from "./IBasicQuoter.sol";
import {Offers} from "../libraries/LibOffers.sol";

interface IQuoter is IBasicQuoter {
    function findBestPath(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint8 maxSwaps
    ) external view returns (Offers.FormattedOffer memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Bytes} from "@synapseprotocol/sol-lib/contracts/universal/lib/LibBytes.sol";

library Offers {
    struct Offer {
        bytes amounts;
        bytes adapters;
        bytes path;
    }

    struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
    }

    /**
     * Appends Query elements to Offer struct
     */
    function addQuery(
        Offer memory _queries,
        uint256 _amount,
        address _adapter,
        address _tokenOut
    ) internal pure {
        _queries.path = Bytes.mergeBytes(
            _queries.path,
            Bytes.toBytes(_tokenOut)
        );
        _queries.amounts = Bytes.mergeBytes(
            _queries.amounts,
            Bytes.toBytes(_amount)
        );
        _queries.adapters = Bytes.mergeBytes(
            _queries.adapters,
            Bytes.toBytes(_adapter)
        );
    }

    /**
     * Makes a deep copy of Offer struct
     */
    function cloneOfferWithGas(Offer memory _queries)
        internal
        pure
        returns (Offer memory)
    {
        return Offer(_queries.amounts, _queries.adapters, _queries.path);
    }

    /**
     * Converts byte-arrays to an array of integers
     */
    function formatAmounts(bytes memory _amounts)
        internal
        pure
        returns (uint256[] memory)
    {
        // Format amounts
        uint256 chunks = _amounts.length / 32;
        uint256[] memory amountsFormatted = new uint256[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            amountsFormatted[i] = Bytes.toUint256(i * 32 + 32, _amounts);
        }
        return amountsFormatted;
    }

    /**
     * Converts byte-array to an array of addresses
     */
    function formatAddresses(bytes memory _addresses)
        internal
        pure
        returns (address[] memory)
    {
        uint256 chunks = _addresses.length / 32;
        address[] memory addressesFormatted = new address[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            addressesFormatted[i] = Bytes.toAddress(i * 32 + 32, _addresses);
        }
        return addressesFormatted;
    }

    /**
     * Formats elements in the Offer object from byte-arrays to integers and addresses
     */
    function formatOfferWithGas(Offer memory _queries)
        internal
        pure
        returns (FormattedOffer memory)
    {
        return
            FormattedOffer(
                formatAmounts(_queries.amounts),
                formatAddresses(_queries.adapters),
                formatAddresses(_queries.path)
            );
    }
}