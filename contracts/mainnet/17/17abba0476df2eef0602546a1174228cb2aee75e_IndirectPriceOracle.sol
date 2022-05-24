//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {BasePriceOracle} from "./BasePriceOracle.sol";

contract IndirectPriceOracle is BasePriceOracle {
    uint8 public constant override decimals = 18;
    string public override description;

    IPriceOracle public priceOracle0;
    IPriceOracle public priceOracle1;
    string public intermediateSymbol;
    address public intermediateAddr;

    bool public AC;
    bool public AD;
    bool public BC;
    bool public BD;

    uint8 public decimals0;
    uint8 public decimals1;

    function initialize(address _priceOracle0, address _priceOracle1) external initializer {
        require(_priceOracle0 != address(0), "IPriceOracle 0 address is 0");
        require(_priceOracle1 != address(0), "IPriceOracle 1 address is 0");

        priceOracle0 = IPriceOracle(_priceOracle0);
        priceOracle1 = IPriceOracle(_priceOracle1);
        decimals0 = priceOracle0.decimals();
        decimals1 = priceOracle1.decimals();
        address A = priceOracle0.baseAddr();
        address B = priceOracle0.quoteAddr();
        address C = priceOracle1.baseAddr();
        address D = priceOracle1.quoteAddr();

        AC = A == C;
        AD = A == D;
        BC = B == C;
        BD = B == D;

        require(AC || AD || BC || BD, "Common address not found!");

        address _baseAddr;
        address _quoteAddr;
        string memory _baseSymbol;
        string memory _quoteSymbol;

        // setup symbols and addrs
        if (AC) {
            _baseAddr = B;
            _baseSymbol = priceOracle0.quoteSymbol();
            _quoteAddr = D;
            _quoteSymbol = priceOracle1.quoteSymbol();
            intermediateAddr = A;
            intermediateSymbol = priceOracle0.baseSymbol();
        } else if (AD) {
            _baseAddr = B;
            _baseSymbol = priceOracle0.quoteSymbol();
            _quoteAddr = C;
            _quoteSymbol = priceOracle1.baseSymbol();
            intermediateAddr = A;
            intermediateSymbol = priceOracle0.baseSymbol();
        } else if (BC) {
            _baseAddr = A;
            _baseSymbol = priceOracle0.baseSymbol();
            _quoteAddr = D;
            _quoteSymbol = priceOracle1.quoteSymbol();
            intermediateAddr = B;
            intermediateSymbol = priceOracle0.quoteSymbol();
        } else {
            _baseAddr = A;
            _baseSymbol = priceOracle0.baseSymbol();
            _quoteAddr = C;
            _quoteSymbol = priceOracle1.baseSymbol();
            intermediateAddr = B;
            intermediateSymbol = priceOracle0.quoteSymbol();
        }
        super.setSymbols(_baseSymbol, _quoteSymbol, _baseAddr, _quoteAddr);
        description = string(abi.encodePacked(baseSymbol, " / ", quoteSymbol));
    }

    function lastUpdate() external view override returns (uint256 updateAt) {
        uint256 oracle0LastUpdate = priceOracle0.lastUpdate();
        uint256 oracle1LastUpdate = priceOracle1.lastUpdate();
        // use more recent timestamp
        updateAt = oracle0LastUpdate > oracle1LastUpdate ? oracle0LastUpdate : oracle1LastUpdate;
    }

    function priceInternal() internal view returns (uint256) {
        uint256 price0 = priceOracle0.price(baseAddr);
        uint256 price1 = priceOracle1.price(intermediateAddr);

        if (price0 == type(uint256).max) return price0;
        if (price1 == type(uint256).max) return price1;

        // All 4 cases reduce to the same formula
        // if (AC) {
        //     // A==C
        //     // B / D = B / A * C / D
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // } else if (AD) {
        //     // A==D
        //     // B / C = B / A * D / C
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // } else if (BC) {
        //     // B==C
        //     // A / D = A / B * C / D
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // } else {
        //     // B==D
        //     // A / C = A / B * D / C
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // }

        return (price0 * price1 * 10**decimals) / 10**decimals0 / 10**decimals1;
    }

    function price(address _baseAddr) external view override isValidSymbol(_baseAddr) returns (uint256) {
        uint256 priceFeed = priceInternal();
        if (priceFeed == type(uint256).max) return priceFeed;
        if (baseAddr == _baseAddr) return priceFeed;
        return 1e36 / priceFeed;
    }

    function priceByQuoteSymbol(address _quoteAddr) external view override isValidSymbol(_quoteAddr) returns (uint256) {
        uint256 priceFeed = priceInternal();
        if (priceFeed == type(uint256).max) return priceFeed;
        if (quoteAddr == _quoteAddr) return priceFeed;
        return 1e36 / priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceOracle {
    /**
     * @return decimals of the "baseSymbol / quoteSymbol" rate
     */
    function decimals() external view returns (uint8);

    /**
     * @return name of the token pair, in the form of "baseSymbol / quoteSymbol"
     */
    function description() external view returns (string memory);

    /**
     * @return name of the base symbol
     */
    function baseSymbol() external view returns (string memory);

    /**
     * @return name of the quote symbol
     */
    function quoteSymbol() external view returns (string memory);

    /**
     * @return address of the base symbol, zero address if `baseSymbol` is USD
     */
    function baseAddr() external view returns (address);

    /**
     * @return address of the quote symbol, zero address if `baseSymbol` is USD
     */
    function quoteAddr() external view returns (address);

    /**
     * @return updateAt timestamp of the last update as seconds since unix epoch
     */
    function lastUpdate() external view returns (uint256 updateAt);

    /**
     * @param _baseAddr address of the base currency in the currency pair
     * @return "baseSymbol / quoteSymbol" rate, i.e. quantity of quote currency in exchange for 1 unit of base currency,
     * where the baseSymbol is specified in the input parameter, return type(uint256).max for invalid rate
     */
    function price(address _baseAddr) external view returns (uint256);

    /**
     * @param _quoteAddr address of the quote currency in the currency pair
     * @return "baseSymbol / quoteSymbol" rate, i.e. quantity of quote currency in exchange for 1 unit of base currency,
     * where the quoteSymbol is specified in the input parameter, return type(uint256).max for invalid rate
     */
    function priceByQuoteSymbol(address _quoteAddr) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title BasePriceOracle Abstract Contract
 * @notice Abstract Contract to implement variables and modifiers in common
 */
abstract contract BasePriceOracle is IPriceOracle, Initializable {
    string public override baseSymbol;
    string public override quoteSymbol;
    address public override baseAddr;
    address public override quoteAddr;

    function setSymbols(
        string memory _baseSymbol,
        string memory _quoteSymbol,
        address _baseAddr,
        address _quoteAddr
    ) internal {
        baseSymbol = _baseSymbol;
        quoteSymbol = _quoteSymbol;
        baseAddr = _baseAddr;
        quoteAddr = _quoteAddr;
    }

    modifier isValidSymbol(address addr) {
        require(addr == baseAddr || addr == quoteAddr, "Symbol not in this price oracle");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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