/**
 *Submitted for verification at snowtrace.io on 2022-08-04
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
 * @dev Vector Finance Interface
 * Houses methods for withdrawals, deposits and rewards
 *
 * NOTE: Interface will contain standalone address where it will be stored in a constants address
 */

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint8);
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

interface IVector {
    function deposit(uint256 _amount) external;

    function balanceOf(address _address) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function multiclaim(address[] calldata _lps, address user_address) external;
}

interface IVectorSingle {
    function balance(address _address) external view returns (uint256);

    function withdraw(uint256 _amount, uint256 _minAmount) external;
}

/**
 * @dev Vector Helper
 * Houses our custom withdrawal, deposit and rewards functionality w/
 * implemented safe guards and checks
 *
 * NOTE: Interface will contain standalone address where it will be stored in a constants address
 */
contract VectorHelper is Ownable {
    address private addressRouter;

    constructor(address _addressRouter) {
        addressRouter = _addressRouter;
    }

    /*
     * Deposit for Single-Sided Staking
     * _amount - actual token (USDC, BTCB) to deposit
     * _tokenAddress - contract of corresponding token ^
     * _spender - that will move tokens into deposit pool
     * _investmetnAddress - the corresponding staking contract
     * NOTE: Aimed at PTP
     */
    function depositSingle(
        uint256 _amount,
        address _tokenAddress,
        address _spender,
        address _investmentAddress
    ) public {
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
        IVector(_investmentAddress).deposit(_amount);
    }

    /*
     * Deposit for Avax LP
     * _amount - actual token (USDC, BTCB) to deposit
     * _tokenAddress - contract of corresponding token ^
     * _spender - that will move tokens into deposit pool
     * _investmetnAddress - the corresponding staking contract
     * NOTE: Aimed at PTP
     */
    function depositLPNative(
        uint256 _lpAmount,
        address _lpAddress,
        address _spender,
        address _investmentAddress
    ) public payable {
        require(_lpAmount > 0, "LP Amount is Equal to Zero.");
        checkAllowance(_lpAddress, _spender);
        IVector(_investmentAddress).deposit(_lpAmount);
    }

    /*
     *
     * NOTE: Error -> 'Amount Too Low' means higher slippage
     *
     */
    function withdrawSingle(
        uint256 _amount,
        uint256 _minAmount,
        address _investmentAddress
    ) public {
        IVectorSingle(_investmentAddress).withdraw(_amount, _minAmount);
    }

    function claimSingle(
        address[] memory _lps,
        address _beneficiary,
        address _investmentAddress
    ) public {
        IVector(_investmentAddress).multiclaim(_lps, _beneficiary);
    }

    function claimLpAvax(
        address[] memory _lps,
        address _beneficiary,
        address _investmentAddress
    ) public {
        IVector(_investmentAddress).multiclaim(_lps, _beneficiary);
    }

    function withdrawLp(uint256 _amount, address _investmentAddress) public {
        require(_amount > 0, "Amount to WithdrawLp is equal to zero.");
        IVector(_investmentAddress).withdraw(_amount);
    }

    function viewInvestmentBalance(
        address _investmentAddress,
        address _walletAddress
    ) public view returns (uint256) {
        uint256 bal = IVector(_investmentAddress).balanceOf(_walletAddress);
        return bal;
    }

    function queryInvestmentBalance(
        address _investmentAddress,
        address _walletAddress
    ) public view returns (uint256) {
        uint256 bal = IVectorSingle(_investmentAddress).balance(_walletAddress);
        return bal;
    }

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
}