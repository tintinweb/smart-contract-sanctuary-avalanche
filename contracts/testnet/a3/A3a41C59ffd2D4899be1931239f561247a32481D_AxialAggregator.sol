// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/Ownable.sol";
import "./interface/IRouter.sol";
import "./lib/SafeMath.sol";

/// @notice Aggregator contract to help swapping across known pools but favoring Axial pools when there is a path.
contract AxialAggregator is Ownable {
    using SafeMath for uint;

    /// @dev Router that swaps across Axial pools;
    address public InternalRouter;
    /// @dev Router that swaps across all non-Axial pools; 
    address public ExternalRouter;

    address public constant WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

    struct FindBestPathParams {
        uint256 amountIn;
        address tokenIn;
        address tokenOut;
        uint256 maxSteps;
        uint gasPrice;
    }

    event UpdatedInternalRouter(
        address _oldInternalRouter, 
        address _newInternalRouter
    );

    event UpdatedExternalRouter(
        address _oldExternalRouter, 
        address _newExternalRouter
    );

    constructor(address _internalRouter, address _externalRouter) {
        require(
            _internalRouter != address(0),
            "Aggregator: _internalRouter not set"
        );
        require(
            _externalRouter != address(0),
            "Aggregator: _externalRouter not set"
        );

        InternalRouter = _internalRouter;
        ExternalRouter = _externalRouter;
    }

    /// @notice Set router to be used for swapping across Axial pools.
    function setInternalRouter(address _internalRouter) public onlyOwner {
        emit UpdatedInternalRouter(InternalRouter, _internalRouter);
        InternalRouter = _internalRouter;
    }

    /// @notice Set router to be used for swapping across non-Axial pools.
    function setExternalRouter(address _externalRouter) public onlyOwner {
        emit UpdatedExternalRouter(ExternalRouter, _externalRouter);
        ExternalRouter = _externalRouter;
    }

    /// @notice Finds the best path between tokenIn & tokenOut, checking Axial owned pools first.
    /// @param _params This includes the input token, output token, max number of steps to use and amount in.
    function findBestPath(FindBestPathParams calldata _params) external view returns (IRouter.FormattedOfferWithGas memory bestPath, bool useInternalRouter) {
        IRouter.FormattedOfferWithGas memory offer;
        bool UseInternalRouter;

        IRouter.FormattedOffer memory gasQuery = IRouter(ExternalRouter).findBestPath(1e18, WAVAX, _params.tokenOut, 2);
        uint tknOutPriceNwei = gasQuery.amounts[gasQuery.amounts.length-1].mul(_params.gasPrice/1e9);

        // Query internal router for best path
        offer = IRouter(InternalRouter).findBestPathWithGas(
            _params.amountIn,
            _params.tokenIn,
            _params.tokenOut,
            _params.maxSteps,
            _params.gasPrice,
            tknOutPriceNwei
        );

        // Check if internal router returned an offer
        if (offer.adapters.length > 0) {
            UseInternalRouter = true;
        } else {
            offer = IRouter(ExternalRouter).findBestPathWithGas(
                _params.amountIn,
                _params.tokenIn,
                _params.tokenOut,
                _params.maxSteps,
                _params.gasPrice,
                tknOutPriceNwei
            );
        }

        return (offer, UseInternalRouter);
    }

    /// @notice Swaps input token to output token using the specified path and adapters.
    /// @param _trade This includes the input token, output token, the path to use, adapters and input amounts.
    /// @param _to The output amount will be sent to this address.
    /// @param _fee The fee to be paid by the sender.
    /// @param _useInternalRouter Specifies whether to use the internal router or external router.
    /// @dev The aggregator must be approved to spend users input token.
    function swap(
        IRouter.Trade calldata _trade,
        address _to,
        uint256 _fee,
        bool _useInternalRouter
    ) external {
        require(_to != address(0), "Aggregator: _to not set");

        if(_useInternalRouter) {
            (bool success,) = InternalRouter.delegatecall(
                abi.encodeWithSelector(IRouter(InternalRouter).swapNoSplit.selector, 
                _trade, _to, _fee)
            );

            require(success, "Aggregator: InternalRouter.swapNoSplit failed");
        }
        else{
            (bool success,) = ExternalRouter.delegatecall(
                abi.encodeWithSelector(IRouter(ExternalRouter).swapNoSplit.selector, 
                _trade, _to, _fee)
            );

            require(success, "Aggregator: ExternalRouter.swapNoSplit failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
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
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

/// @notice Router contract interface
interface IRouter {
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address[] adapters;
    }

    struct FormattedOffer {
        uint[] amounts;
        address[] adapters;
        address[] path;
    }

    struct FormattedOfferWithGas {
        uint[] amounts;
        address[] adapters;
        address[] path;
        uint gasEstimate;
    }

    function findBestPath(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps
    ) external view returns (FormattedOffer memory);

    function findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        uint _gasPrice,
        uint _tokenOutPrice
    ) external view returns (FormattedOfferWithGas memory);
  
    function swapNoSplit(
        Trade calldata _trade,
        address _to,
        uint _fee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}