/**
 *Submitted for verification at snowtrace.io on 2022-08-18
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;

/**
 * @dev Joe Router Interface
 * Conduct swaps and obtaining LP tokens
 *
 * NOTE: Interface will contain standalone address where it will be stored in a constants address
 */
interface IJoeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external;
}

/**
 * @dev IERC20 Interface
 * Helper functions to call common metadata on ERC20 token
 */
interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

/**
 * @dev Address Router
 * Instantly query address saved
 */
interface IAddressRouter {
    function viewAddressDirectory(string memory _name)
        external
        view
        returns (address);
}

contract JoeHelper is Ownable {
    address private addressRouter;

    constructor(address _addressRouter) {
        addressRouter = _addressRouter;
    }

    /**
     * @dev Exhange Exact Tokens for Tokens
     * Will be used to swap rewards tokens for reinvestment ones
     * @param _amountIn - amount of reward token to sell
     * @param _amountOutMin -
     */
    function exchangeExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _buyTokenContract,
        address _sellTokenContract
    ) external {
        // Establish Addresses
        address avaxContract = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        address joeRouter = IAddressRouter(addressRouter).viewAddressDirectory(
            "JoeRouter"
        );
        address joeRouterSpender = IAddressRouter(addressRouter)
            .viewAddressDirectory("JoeRouterSpender");
        // Swap Non-Avax Token
        if (_sellTokenContract != avaxContract) {
            address[] memory path = new address[](3);
            path[0] = _sellTokenContract;
            path[1] = avaxContract;
            path[2] = _buyTokenContract;
            IJoeRouter(joeRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                address(this),
                block.timestamp + 3600
            );
            // Swap Avax Token
        } else {
            address[] memory path = new address[](2);
            path[0] = _sellTokenContract;
            path[1] = _buyTokenContract;
            IJoeRouter(joeRouter).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                address(this),
                block.timestamp + 3600
            );
        }
    }

    /**
     * @dev Swap Token for Avax
     * Will be used to swap rewards tokens for reinvestment ones
     * @param _amountIn - amount of reward token to sell
     * @param _amountOutMin - amount of buy token willing to accept
     * @param _sellTokenContract - self-explanatory
     */
    function exchangeExactTokensForAvax(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _sellTokenContract
    ) public payable {
        address[] memory path = new address[](2);
        address avaxContract = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        address joeRouter = IAddressRouter(addressRouter).viewAddressDirectory(
            "JoeRouter"
        );
        address joeRouterSpender = IAddressRouter(addressRouter)
            .viewAddressDirectory("JoeRouterSpender");
        checkAllowance(_sellTokenContract, joeRouterSpender);
        path[0] = _sellTokenContract;
        path[1] = avaxContract;

        IJoeRouter(joeRouter).swapExactTokensForAVAX(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            block.timestamp + 3600
        );
    }

    /**
     * @dev Swap Exact AVAX for Tokens
     * _amountOutMin - buy token minimum willing to accept
     * _avaxAmount - amount of avax to send in value field of transaction
     * _buyTokenContract - address of desired token to purchase
     */
    function exchangeExactAvaxForTokens(
        uint256 _amountOutMin,
        uint256 _avaxAmount,
        address _buyTokenContract
    ) public payable {
        address[] memory path = new address[](2);
        address avaxContract = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        address joeRouter = IAddressRouter(addressRouter).viewAddressDirectory(
            "JoeRouter"
        );

        path[0] = avaxContract;
        path[1] = _buyTokenContract;

        IJoeRouter(joeRouter).swapExactAVAXForTokens{value: _avaxAmount}(
            _amountOutMin,
            path,
            address(this),
            block.timestamp + 3600
        );
    }

    /**
     * @dev Get Exchange RATE
     * _amountIn - amount of token to sell
     * _tokenPath - path to sell and buy token
     * returns exchangeRate - 0 first token, 1 second token etc
     */
    function calculateExchangeRate(
        uint256 _amountIn,
        address[] memory _tokenPath
    ) public payable returns (uint256[] memory) {
        uint256[] memory exchangeRate;
        address joeRouter = IAddressRouter(addressRouter).viewAddressDirectory(
            "JoeRouter"
        );
        exchangeRate = IJoeRouter(joeRouter).getAmountsOut(
            _amountIn,
            _tokenPath
        );

        return exchangeRate;
    }

    /**
     * @dev Deposit Token Pair into TJ Liquidity
     * pair1 - address (0), requested amount (1), minimum willing to accept (2)
     * _avaxAmount - Avax amount for transactions value field
     * _avaxMin - Min Avax demanding for adding liquidity
     * @notice _axaxMin - resolved thru slippage on Investor contract
     */
    function addLiquidityAvax(
        address _pair1Token,
        uint256 _pair1Desired,
        uint256 _pair1Min,
        uint256 _avaxAmount,
        uint256 _avaxMin
    )
        public
        payable
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        //Get Addresses
        address joeRouter = IAddressRouter(addressRouter).viewAddressDirectory(
            "JoeRouter"
        );
        address avaxContract = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        checkAllowance(_pair1Token, joeRouter);
        checkAllowance(avaxContract, joeRouter);
        // Add Both Tokens to Liquidity
        (
            uint256 pair1Amount,
            uint256 amountAvax,
            uint256 liquidity
        ) = IJoeRouter(joeRouter).addLiquidityAVAX{value: _avaxAmount}(
                _pair1Token,
                _pair1Desired,
                _pair1Min,
                _avaxMin,
                address(this),
                block.timestamp + 3600
            );
        return (pair1Amount, amountAvax, liquidity);
    }

    /**
     * @dev Remove Token Pair from TJ Liquidity
     * _token - Address of Pair 1 Token
     * _lpPair - Contract Address for LP Token
     * _liquidityAmount - Requested amount of LP Token to Remove
     * _amountTokenMin - Min of Pair 1 Token Requesting
     * _amountAvaxMin - Min of Pair 2 Token Requesting
     */
    function removeAvaxLiquidity(
        address _token,
        address _lpPair,
        uint256 _liquidityAmount,
        uint256 _amountTokenMin,
        uint256 _amountAvaxMin
    ) public payable {
        //Get Address & Check Approve For LP Pair Removal
        address joeRouter = IAddressRouter(addressRouter).viewAddressDirectory(
            "JoeRouter"
        );
        checkAllowance(_lpPair, joeRouter);
        // Remove Liquidity
        IJoeRouter(joeRouter).removeLiquidityAVAX(
            _token,
            _liquidityAmount,
            _amountTokenMin,
            _amountAvaxMin,
            tx.origin,
            block.timestamp + 3600
        );
    }

    /**
     * @dev Check Allowance
     * Checks to make sure contract has extended permissions to other contracts
     */
    function checkAllowance(address _tokenAddress, address _spender) public {
        uint256 permittedFunds = IERC20(_tokenAddress).allowance(
            address(this),
            _spender
        );
        if (
            permittedFunds !=
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        ) {
            IERC20(_tokenAddress).approve(
                _spender,
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            );
        }
    }

    fallback() external payable {}

    receive() external payable {}
}