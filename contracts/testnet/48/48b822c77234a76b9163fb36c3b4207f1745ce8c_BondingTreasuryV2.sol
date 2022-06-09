//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./BondingTreasuryStorageV2.sol";

contract BondingTreasuryV2 is OwnableUpgradeable, BondingTreasuryStorageV2 {
    function initialize() public initializer {
        __Ownable_init();
        EmeraldToken = IERC20(0xF126e2c45b87b5b0c0aA44bFE92f831b5F01de0C);
        WrappedAvax = IERC20(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);
        WrappedUsdt = IERC20(0xdf0cFA648f283945fd99EC435814B3e3fE0cAC30);

        bondCounter = 0;
        quaterBondCounter = 0;
        quaterCount = 0;

        bondTimeline = 600;
        bondPrice = (10**18);
        bondMaxAmount = 50 * (10**18);
        discountPercent = 10;

        AvaxUsdPriceFeed = AggregatorV3Interface(
            0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
        );
        UsdtUsdPriceFeed = AggregatorV3Interface(
            0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad
        );
        router = IPangolinRouter(0x2D99ABD9008Dc933ff5c0CD271B88309593aB921);

        pair1 = [
            0xd00ae08403B9bbb9124bB305C09058E32C39A48c,
            0xF126e2c45b87b5b0c0aA44bFE92f831b5F01de0C
        ];
        pair2 = [
            0xF126e2c45b87b5b0c0aA44bFE92f831b5F01de0C,
            0xd00ae08403B9bbb9124bB305C09058E32C39A48c
        ];

        bondSupply = feeCalculation(1, EmeraldToken.totalSupply());
        bondSupplyCounter = bondSupply;

        quaterTimestamp = [1653553623, 1653557222, 1653560822, 1653564422];

        treasuryAccount = owner();
    }

    function getAvaxToEmPrice(uint256 _amount) public view returns (int256) {
        uint256[] memory price = router.getAmountsOut(
            _amount * (10**18),
            pair1
        );
        return int256(price[1]);
    }

    function getEmToAvaxPrice(uint256 _amount) public view returns (int256) {
        uint256[] memory price = router.getAmountsOut(
            _amount * (10**18),
            pair2
        );
        return int256(price[1]);
    }

    function getEmToUSDPrice() public view returns (int256) {
        int256 EmPrice = getAvaxToEmPrice(1);
        (, int256 answer, , , ) = AvaxUsdPriceFeed.latestRoundData();
        int256 convertAnswer = answer * (10**18);
        int256 price = convertAnswer / EmPrice;
        return price;
    }

    function getAvaxToUsdPrice() public view returns (int256) {
        (, int256 price, , , ) = AvaxUsdPriceFeed.latestRoundData();
        return price;
    }

    function getUsdtToUsdPrice() public view returns (int256) {
        (, int256 price, , , ) = UsdtUsdPriceFeed.latestRoundData();
        return price;
    }

    function updateBondValue(uint256 _maxAmt, uint256 _timeline)
        external
        virtual
        onlyOwner
    {
        bondMaxAmount = _maxAmt;
        bondTimeline = _timeline;
    }

    function updateERC20(address _em_contract, address _usdt_contract)
        external
        virtual
        onlyOwner
    {
        EmeraldToken = IERC20(_em_contract);
        WrappedUsdt = IERC20(_usdt_contract);
    }

    function updateTreasuryAccount(address _account)
        external
        virtual
        onlyOwner
    {
        treasuryAccount = _account;
    }

    function updateQuaterDetails(uint256[] calldata _timestamp, uint256 _margin)
        external
        virtual
        onlyOwner
    {
        delete quaterTimestamp;
        for (uint256 i = 0; i < _timestamp.length; i++) {
            quaterTimestamp.push(_timestamp[i]);
        }
        discountPercent = _margin;
    }

    function updateBondSupply() external virtual onlyOwner {
        bondSupply = feeCalculation(1, EmeraldToken.totalSupply());
        bondSupplyCounter = bondSupply;
    }

    function bond(uint256 _amount) external payable virtual returns (bool) {
        // (
        //     uint256 TotalAmountReleased,
        //     uint256 TotalAmountLocked,
        //     ,

        // ) = viewUserDiscountedDetails(msg.sender);
        // uint256 tempAmt = TotalAmountReleased +
        //     TotalAmountLocked +
        //     _amount *
        //     (10**18);
        require(
            EmeraldToken.balanceOf(msg.sender) >= _amount * (10**18) &&
                _amount <= bondMaxAmount,
            "BondingTreasuryV1: Insufficient balance or cannot be above max bond amount"
        );

        bondCounter += 1;
        uint256 count;

        uint256 price = feeCalculation(
            (100 - discountPercent),
            uint256(getEmToAvaxPrice(_amount))
        );

        require(price == msg.value, "BondingTreasuryV1: Price is incorrect");

        payable(treasuryAccount).transfer(msg.value);

        BondDetails memory _bond = BondDetails(
            bondCounter,
            msg.sender,
            _amount * (10**18),
            block.timestamp,
            block.timestamp + bondTimeline,
            false
        );

        BondDetailsById[bondCounter] = _bond;

        BondDetails[] storage _data = UserBondDetails[msg.sender];
        _data.push(_bond);

        for (uint256 i = 0; i < quaterTimestamp.length; i++) {
            if (block.timestamp > quaterTimestamp[3]) {
                revert("BondingTreasuryV1: Quaterly details not updated");
            }
            if (
                block.timestamp >= quaterTimestamp[i] &&
                block.timestamp <= quaterTimestamp[i + 1]
            ) {
                count = i + 1;
                if (quaterCount != count) {
                    quaterCount = count;
                    quaterBondCounter = 0;
                    bondSupply = feeCalculation(1, EmeraldToken.totalSupply());
                    bondSupplyCounter = bondSupply;
                }

                require(
                    bondSupplyCounter >= _amount * (10**18),
                    "BondingTreasuryV1: Suppply is reached its limit"
                );

                quaterBondCounter += 1;
                bondSupplyCounter -= _amount * (10**18);

                break;
            }
        }

        emit CreateBond(
            bondCounter,
            msg.sender,
            _amount * (10**18),
            block.timestamp,
            block.timestamp + bondTimeline
        );

        return true;
    }

    function withdraw(uint256 _bondId) external virtual returns (bool) {
        require(
            BondDetailsById[_bondId].user == msg.sender,
            "BondingTreasuryV1: Invalid Owner"
        );
        require(
            BondDetailsById[_bondId].endedAt <= block.timestamp &&
                !BondDetailsById[_bondId].claimed,
            "BondingTreasuryV1: Bond is not matured yet or already claimed"
        );

        EmeraldToken.mintSupply(
            msg.sender,
            BondDetailsById[_bondId].amount / (10**18)
        );

        BondDetailsById[_bondId].claimed = true;
        for (uint256 i = 0; i < UserBondDetails[msg.sender].length; i++) {
            if (UserBondDetails[msg.sender][i].bondId == _bondId) {
                UserBondDetails[msg.sender][i].claimed = true;
            }
        }

        emit Withdraw(_bondId, msg.sender, BondDetailsById[_bondId].amount);

        return true;
    }

    function withdrawAll() external virtual returns (bool) {
        require(
            UserBondDetails[msg.sender].length > 0,
            "BondingTreasuryV1: You dont owned bond"
        );
        uint256 tempAmt;
        for (uint256 i = 0; i < UserBondDetails[msg.sender].length; i++) {
            BondDetails memory data = UserBondDetails[msg.sender][i];
            if (
                BondDetailsById[data.bondId].endedAt <= block.timestamp &&
                !BondDetailsById[data.bondId].claimed
            ) {
                tempAmt += BondDetailsById[data.bondId].amount;
                tempId.push(data.bondId);
                BondDetailsById[data.bondId].claimed = true;
                UserBondDetails[msg.sender][i].claimed = true;
            }
        }
        require(tempAmt > 0, "BondingTreasuryV1: No bond is matured");

        EmeraldToken.mintSupply(msg.sender, tempAmt / (10**18));

        emit WithdrawAll(tempId, msg.sender, tempAmt);

        return true;
    }

    function viewUserDiscountedDetails(address _user)
        public
        view
        virtual
        returns (
            uint256 TotalAmountReleased,
            uint256 TotalAmountLocked,
            uint256 ClaimedAmount,
            uint256 RemainingAmount
        )
    {
        for (uint256 i = 0; i < UserBondDetails[_user].length; i++) {
            BondDetails memory data = UserBondDetails[_user][i];
            if (BondDetailsById[data.bondId].endedAt <= block.timestamp) {
                TotalAmountReleased += data.amount;
                if (BondDetailsById[data.bondId].claimed) {
                    ClaimedAmount += data.amount;
                }
            }
            if (BondDetailsById[data.bondId].endedAt > block.timestamp) {
                TotalAmountLocked += data.amount;
            }
        }
        RemainingAmount = TotalAmountReleased - ClaimedAmount;
    }

    function checkTreasuryValueInUSD()
        external
        view
        returns (uint256 TreasuryPriceInUSD)
    {
        uint256 EmPrice = (uint256(getEmToUSDPrice()) *
            EmeraldToken.balanceOf(treasuryAccount)) / (10**18);
        uint256 AvaxPrice = (
            (uint256(getAvaxToUsdPrice()) * treasuryAccount.balance)
        ) / (10**18);
        uint256 WAvaxPrice = (
            (uint256(getAvaxToUsdPrice()) *
                WrappedAvax.balanceOf(treasuryAccount))
        ) / (10**18);
        uint256 WUsdtPrice = (
            (uint256(getUsdtToUsdPrice()) *
                WrappedUsdt.balanceOf(treasuryAccount))
        ) / (10**6);

        TreasuryPriceInUSD = EmPrice + AvaxPrice + WAvaxPrice + WUsdtPrice;
    }

    function viewUserAllBondDetails(address _user)
        public
        view
        virtual
        returns (BondDetails[] memory)
    {
        return UserBondDetails[_user];
    }

    function withdraw() external virtual onlyOwner {
        EmeraldToken.approve(msg.sender, EmeraldToken.balanceOf(address(this)));
        EmeraldToken.safeTransfer(
            address(this),
            msg.sender,
            EmeraldToken.balanceOf(address(this))
        );
    }

    function feeCalculation(uint256 _margin, uint256 _totalPrice)
        public
        pure
        returns (uint256)
    {
        uint256 fee = _margin * _totalPrice;
        uint256 fees = fee / 100;
        return fees;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IPangolinRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
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
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    function safeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /**
     * @dev mints the amount token.
     *
     * Emits a {Transfer} event.
     */

    function mintSupply(address _destAddress, uint256 _amount) external;

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IERC20.sol";
import "./IPangolinRouter.sol";

contract BondingTreasuryStorageV2 is OwnableUpgradeable {
    AggregatorV3Interface internal UsdtUsdPriceFeed;
    AggregatorV3Interface internal AvaxUsdPriceFeed;
    IPangolinRouter internal router;

    address[] pair1;
    address[] pair2;
    uint256[] tempId;

    IERC20 public EmeraldToken;
    IERC20 public WrappedAvax;
    IERC20 public WrappedUsdt;

    uint256 public bondCounter;
    uint256 public bondTimeline;
    uint256 public bondPrice;
    uint256 public bondMaxAmount;

    struct BondDetails {
        uint256 bondId;
        address user;
        uint256 amount;
        uint256 startedAt;
        uint256 endedAt;
        bool claimed;
    }

    mapping(uint256 => BondDetails) public BondDetailsById;

    mapping(address => BondDetails[]) public UserBondDetails;

    address public treasuryAccount;

    uint256[] public quaterTimestamp;

    uint256 public bondSupply;

    uint256 public quaterBondCounter;

    uint256 public quaterCount;

    uint256 public discountPercent;

    uint256 public bondSupplyCounter;

    // Events

    /**
     * @dev Emitted when bond is created by user.
     */
    event CreateBond(
        uint256 BondId,
        address User,
        uint256 Amount,
        uint256 StartedAt,
        uint256 EndAt
    );

    /**
     * @dev Emitted when bond is claimed by user.
     */
    event Withdraw(uint256 BondId, address User, uint256 Amount);

    /**
     * @dev Emitted when bond is claimed by user.
     */
    event WithdrawAll(uint256[] BondIds, address User, uint256 Amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}