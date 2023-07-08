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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
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

pragma solidity 0.8.17;

interface esLBRMinter {
    function refreshReward(address user) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
contract Governable {
    address public gov;

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity 0.8.17;

interface Ireth {

    function balanceOf(address _account) external view returns (uint256);

    function transfer(address _recipient, uint256 _amount)
        external
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);
}

pragma solidity 0.8.17;

interface ISwap {
    function burnSwap(uint _amount) external;
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity 0.8.17;

interface LbrStakingPool {
    function notifyRewardAmount(uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./PVUSD.sol";
import "./Governable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./AggregatorV3Interface.sol";
import "./Ireth.sol";
import "./LbrStakingPool.sol";
import "./esLBRMinter.sol";
import "./ISwap.sol";

contract LybraPvUSD is PVUSD, Governable {
    uint256 public totalDepositedEther;
    uint256 public lastReportTime;
    uint256 public totalPVUSDCirculation;
    uint256 year = 86400 * 365;

    uint256 public mintFeeApy = 150;
    uint256 public safeCollateralRate = 160 * 1e18;
    uint256 public immutable badCollateralRate = 150 * 1e18;
    uint256 public redemptionFee = 50;
    uint8 public keeperRate = 1;

    mapping(address => uint256) public depositedEther;
    mapping(address => uint256) borrowed;
    uint256 public feeStored;

    bool public initializer;

    Ireth reth;
    AggregatorV3Interface internal priceFeed;
    esLBRMinter public eslbrMinter;
    LbrStakingPool public serviceFeePool;
    address vUSD;

    event DepositEther(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawEther(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event Mint(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event Burn(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event LiquidationRecord(
        address provider,
        address keeper,
        address indexed onBehalfOf,
        uint256 pvusdamount,
        uint256 LiquidateEtherAmount,
        uint256 keeperReward,
        bool superLiquidation,
        uint256 timestamp
    );
    event LSDistribution(
        uint256 rETHAdded,
        uint256 payoutPVUSD,
        uint256 timestamp
    );
    
    event RigidRedemption(
        address indexed caller,
        address indexed provider,
        uint256 pvusdAmount,
        uint256 etherAmount,
        uint256 timestamp
    );
    event FeeDistribution(
        address indexed feeAddress,
        uint256 feeAmount,
        uint256 timestamp
    );

    constructor(address _reth, address _priceFeed) {
        gov = msg.sender;
        reth = Ireth(_reth);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function initialize(address _vUSD) public {
        require(!initializer);
        vUSD = _vUSD;
        initializer = true;
    } 
    function setBorrowApy(uint256 newApy) external onlyGov {
        require(newApy <= 150, "Borrow APY > 1.5%");
        _saveReport();
        mintFeeApy = newApy;
    }

    /**
     * @notice  safeCollateralRate can be decided by DAO,starts at 160%
     */
    function setSafeCollateralRate(uint256 newRatio) external onlyGov {
        require(
            newRatio >= 160 * 1e18,
            "Safe CollateralRate > 160%"
        );
        safeCollateralRate = newRatio;
    }

    /**
     * @notice KeeperRate can be decided by DAO,1 means 1% of revenue
     */
    function setKeeperRate(uint8 newRate) external onlyGov {
        require(newRate <= 5, "Max Keeper reward is 5%");
        keeperRate = newRate;
    }

    /**
     * @notice DAO sets RedemptionFee, 100 means 1%
     */
    function setRedemptionFee(uint8 newFee) external onlyGov {
        require(newFee <= 500, "Max Redemption Fee is 5%");
        redemptionFee = newFee;
    }

    function setLbrStakingPool(address addr) external onlyGov {
        serviceFeePool = LbrStakingPool(addr);
    }

    function setESLBRMinter(address addr) external onlyGov {
        eslbrMinter = esLBRMinter(addr);
    }

    /**
     * @notice Deposit rETH on behalf of an address, update the interest distribution and deposit record the this address, can mint PVUSD directly
     * Emits a `DepositEther` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `rETHamount` Must be higher than 0.
     * - `mintAmount` Send 0 if doesn't mint PVUSD
     * @dev Record the deposited rETH in the ratio of 1:1.
     */
    function depositrETHToMint(
        address onBehalfOf,
        uint256 rETHamount,
        uint256 mintAmount
    ) external {
        require(onBehalfOf != address(0) && rETHamount >= 1 ether, "INPUT_WRONG");
        reth.transferFrom(msg.sender, address(this), rETHamount);

        totalDepositedEther += rETHamount;
        depositedEther[onBehalfOf] += rETHamount;
        if (mintAmount > 0) {
            _mintPVUSD(onBehalfOf, onBehalfOf, mintAmount);
        }
        emit DepositEther(msg.sender, onBehalfOf, rETHamount, block.timestamp);
    }

    /**
     * @notice Withdraw collateral assets to an address
     * Emits a `WithdrawEther` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0.
     *
     * @dev Withdraw rETH. Check user’s collateral rate after withdrawal, should be higher than `safeCollateralRate`
     */
    function withdraw(address onBehalfOf, uint256 amount) external {
        require(onBehalfOf != address(0) && amount > 0 && depositedEther[msg.sender] >= amount, "INPUT_WRONG");
        totalDepositedEther -= amount;
        depositedEther[msg.sender] -= amount;

        reth.transfer(onBehalfOf, amount);
        if (borrowed[msg.sender] > 0) {
            _checkHealth(msg.sender);
        }
        emit WithdrawEther(msg.sender, onBehalfOf, amount, block.timestamp);
    }

    /**
     * @notice The mint amount number of PVUSD is minted to the address
     * Emits a `Mint` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0. Individual mint amount shouldn't surpass 10% when the circulation reaches 10_000_000
     */
    function mint(address onBehalfOf, uint256 amount) public {
        require(onBehalfOf != address(0) && amount > 0 , "INPUT_WRONG");
        _mintPVUSD(msg.sender, onBehalfOf, amount);
        if (
            (borrowed[msg.sender] * 100) / totalSupply() > 10 &&
            totalSupply() > 10_000_000 * 1e18
        ) revert("Mint Amount > 10% of total circulation");
    }

    /**
     * @notice Burn the amount of PVUSD and payback the amount of minted PVUSD
     * Emits a `Burn` event.
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0.
     * @dev Calling the internal`_repay`function.
     */
    function burn(address onBehalfOf, uint256 amount) external {
        require(onBehalfOf != address(0), "BURN_ZERO_ADDRESS");
        _repay(msg.sender, onBehalfOf, amount);
    }

    /**
     * @notice When overallCollateralRate is above 150%, Keeper liquidates borrowers whose collateral rate is below badCollateralRate, using PVUSD provided by Liquidation Provider.
     *
     * Requirements:
     * - onBehalfOf Collateral Rate should be below badCollateralRate
     * - etherAmount should be less than 50% of collateral
     * - provider should authorize Lybra to utilize PVUSD
     * @dev After liquidation, borrower's debt is reduced by etherAmount * etherPrice, collateral is reduced by the etherAmount corresponding to 110% of the value. Keeper gets keeperRate / 110 of Liquidation Reward and Liquidator gets the remaining rETH.
     */
    function liquidation(
        address provider,
        address onBehalfOf,
        uint256 etherAmount
    ) external {
        uint256 etherPrice = _etherPrice();
        uint256 onBehalfOfCollateralRate = (depositedEther[onBehalfOf] *
            etherPrice *
            100) / borrowed[onBehalfOf];
        require(
            onBehalfOfCollateralRate < badCollateralRate,
            "Borrowers collateral rate should below badCollateralRate"
        );

        require(
            etherAmount * 2 <= depositedEther[onBehalfOf],
            "a max of 50% collateral can be liquidated"
        );
        uint256 pvusdAmount = (etherAmount * etherPrice) / 1e18;

        _repay(provider, onBehalfOf, pvusdAmount);
        uint256 reducedEther = (etherAmount * 11) / 10;
        totalDepositedEther -= reducedEther;
        depositedEther[onBehalfOf] -= reducedEther;
        uint256 reward2keeper;
        if (provider == msg.sender) {
            reth.transfer(msg.sender, reducedEther);
        } else {
            reward2keeper = (reducedEther * keeperRate) / 110;
            reth.transfer(provider, reducedEther - reward2keeper);
            reth.transfer(msg.sender, reward2keeper);
        }
        emit LiquidationRecord(
            provider,
            msg.sender,
            onBehalfOf,
            pvusdAmount,
            reducedEther,
            reward2keeper,
            false,
            block.timestamp
        );
    }

    /**
     * @notice When overallCollateralRate is below badCollateralRate, borrowers with collateralRate below 125% could be fully liquidated.
     * Emits a `LiquidationRecord` event.
     *
     * Requirements:
     * - Current overallCollateralRate should be below badCollateralRate
     * - `onBehalfOf`collateralRate should be below 125%
     * @dev After Liquidation, borrower's debt is reduced by etherAmount * etherPrice, deposit is reduced by etherAmount * borrower's collateralRate. Keeper gets a liquidation reward of `keeperRate / borrower's collateralRate
     */
    function superLiquidation(
        address provider,
        address onBehalfOf,
        uint256 etherAmount
    ) external {
        uint256 etherPrice = _etherPrice();
        require(
            (totalDepositedEther * etherPrice * 100) / totalSupply() <
                badCollateralRate,
            "overallCollateralRate > 150%"
        );
        uint256 onBehalfOfCollateralRate = (depositedEther[onBehalfOf] *
            etherPrice *
            100) / borrowed[onBehalfOf];
        require(
            onBehalfOfCollateralRate < 125 * 1e18,
            "borrowers collateralRate > 125%"
        );
        require(
            etherAmount <= depositedEther[onBehalfOf],
            "total of collateral can be liquidated at most"
        );
        uint256 pvusdAmount = (etherAmount * etherPrice) / 1e18;
        if (onBehalfOfCollateralRate >= 1e20) {
            pvusdAmount = (pvusdAmount * 1e20) / onBehalfOfCollateralRate;
        }
        require(
            allowance(provider, address(this)) >= pvusdAmount,
            "provider should authorize to provide liquidation PVUSD"
        );

        _repay(provider, onBehalfOf, pvusdAmount);

        totalDepositedEther -= etherAmount;
        depositedEther[onBehalfOf] -= etherAmount;
        uint256 reward2keeper;
        if (
            msg.sender != provider &&
            onBehalfOfCollateralRate >= 1e20 + keeperRate * 1e18
        ) {
            reward2keeper =
                ((etherAmount * keeperRate) * 1e18) /
                onBehalfOfCollateralRate;
            reth.transfer(msg.sender, reward2keeper);
        }
        reth.transfer(provider, etherAmount - reward2keeper);

        emit LiquidationRecord(
            provider,
            msg.sender,
            onBehalfOf,
            pvusdAmount,
            etherAmount,
            reward2keeper,
            true,
            block.timestamp
        );
    }

    /**
     * @notice When rETH balance increases through LSD or other reasons, the excess income is sold for PVUSD, allocated to PVUSD holders through rebase mechanism.
     * Emits a `LSDistribution` event.
     *
     * *Requirements:
     * - rETH balance in the contract cannot be less than totalDepositedEther after exchange.
     * @dev Income is used to cover accumulated Service Fee first.
     */
    function excessIncomeDistribution(uint256 payAmount) external {
        uint256 payoutEther = (payAmount * 1e18) / _etherPrice();
        require(
            payoutEther <=
                reth.balanceOf(address(this)) - totalDepositedEther &&
                payoutEther > 0,
            "Only LSD excess income can be exchanged"
        );

        uint256 income = feeStored + _newFee();

        if (payAmount > income) {
            _transfer(msg.sender, address(serviceFeePool), income);
            serviceFeePool.notifyRewardAmount(income);

            uint256 sharesAmount = getSharesByMintedVUSD(payAmount - income);
            if (sharesAmount == 0) {
                //PVUSD totalSupply is 0: assume that shares correspond to PVUSD 1-to-1
                sharesAmount = payAmount - income;
            }
            //Income is distributed to LBR staker.
            _burnShares(msg.sender, sharesAmount);
            feeStored = 0;
            emit FeeDistribution(
                address(serviceFeePool),
                income,
                block.timestamp
            );
        } else {
            _transfer(msg.sender, address(serviceFeePool), payAmount);
            serviceFeePool.notifyRewardAmount(payAmount);
            feeStored = income - payAmount;
            emit FeeDistribution(
                address(serviceFeePool),
                payAmount,
                block.timestamp
            );
        }

        lastReportTime = block.timestamp;
        reth.transfer(msg.sender, payoutEther);

        emit LSDistribution(payoutEther, payAmount, block.timestamp);
    }

    /**
     * @notice Choose a Redemption Provider, Rigid Redeem `pvusdAmount` of PVUSD and get 1:1 value of rETH
     * Emits a `RigidRedemption` event.
     *
     * *Requirements:
     * - `provider` must be a Redemption Provider
     * - `provider`debt must equal to or above`pvusdAmount`
     * @dev Service Fee for rigidRedemption `redemptionFee` is set to 0.5% by default, can be revised by DAO.
     */
    function rigidRedemption(address provider, uint256 pvusdAmount) external {
        require(
            borrowed[provider] >= pvusdAmount,
            "pvusdAmount cannot surpass providers debt"
        );
        uint256 etherPrice = _etherPrice();
        uint256 providerCollateralRate = (depositedEther[provider] *
            etherPrice *
            100) / borrowed[provider];
        require(
            providerCollateralRate >= 100 * 1e18,
            "provider's collateral rate should more than 100%"
        );
        _repay(msg.sender, provider, pvusdAmount);
        uint256 etherAmount = (((pvusdAmount * 1e18) / etherPrice) *
            (10000 - redemptionFee)) / 10000;
        depositedEther[provider] -= etherAmount;
        totalDepositedEther -= etherAmount;
        reth.transfer(msg.sender, etherAmount);
        emit RigidRedemption(
            msg.sender,
            provider,
            pvusdAmount,
            etherAmount,
            block.timestamp
        );
    }

    /**
     * @dev Refresh LBR reward before adding providers debt. Refresh Lybra generated service fee before adding totalPVUSDCirculation. Check providers collateralRate cannot below `safeCollateralRate`after minting.
     */
    function _mintPVUSD(
        address _provider,
        address _onBehalfOf,
        uint256 _amount
    ) internal {
        uint256 sharesAmount = getSharesByMintedVUSD(_amount);
        if (sharesAmount == 0) {
            //PVUSD totalSupply is 0: assume that shares correspond to PVUSD 1-to-1
            sharesAmount = _amount;
        }
        eslbrMinter.refreshReward(_provider);
        borrowed[_provider] += _amount;

        _mintShares(_onBehalfOf, sharesAmount);

        _saveReport();
        totalPVUSDCirculation += _amount;
        _checkHealth(_provider);
        emit Mint(msg.sender, _onBehalfOf, _amount, block.timestamp);
    }

    /**
     * @notice Burn _provideramount PVUSD to payback minted PVUSD for _onBehalfOf.
     *
     * @dev Refresh LBR reward before reducing providers debt. Refresh Lybra generated service fee before reducing totalPVUSDCirculation.
     */
    function _repay(
        address _provider,
        address _onBehalfOf,
        uint256 _amount
    ) internal {
        require(
            borrowed[_onBehalfOf] >= _amount,
            "Repaying Amount Surpasses Borrowing Amount"
        );

        uint256 sharesAmount = getSharesByMintedVUSD(_amount);
        _burnShares(_provider, sharesAmount);

        eslbrMinter.refreshReward(_onBehalfOf);

        borrowed[_onBehalfOf] -= _amount;
        _saveReport();
        totalPVUSDCirculation -= _amount;

        emit Burn(_provider, _onBehalfOf, _amount, block.timestamp);
    }

    function _saveReport() internal {
        feeStored += _newFee();
        lastReportTime = block.timestamp;
    }

    function burnSwap(address _account, uint _amount) external {
        require(msg.sender == vUSD);
        uint256 sharesAmount = getSharesByMintedVUSD(_amount);
        _burnShares(_account, sharesAmount);
        eslbrMinter.refreshReward(_account);
        _saveReport();
        totalPVUSDCirculation -= _amount;
        emit Burn(_account, _account, _amount, block.timestamp);
    }

    function swap(uint _amount) external {
        ISwap(vUSD).burnSwap(_amount);
      
        eslbrMinter.refreshReward(msg.sender);

        _mintShares(msg.sender, _amount);

        _saveReport();
        totalPVUSDCirculation += _amount;
    }

    /**
     * @dev Get USD value of current collateral asset and minted PVUSD through price oracle / Collateral asset USD value must higher than safe Collateral Rate.
     */
    function _checkHealth(address user) internal {
        if (
            ((depositedEther[user] * _etherPrice() * 100) / borrowed[user]) <
            safeCollateralRate
        ) revert("collateralRate is Below safeCollateralRate");
    }

    /**
     * @dev Return USD value of current ETH through Liquity PriceFeed Contract.
     * https://etherscan.io/address/0x4c517D4e2C851CA76d7eC94B805269Df0f2201De#code
     */
    function _etherPrice() internal returns (uint256) {
         // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function _newFee() internal view returns (uint256) {
        return
            (totalPVUSDCirculation *
                mintFeeApy *
                (block.timestamp - lastReportTime)) /
            year /
            10000;
    }

    /**
     * @dev total circulation of PVUSD
     */
    function _getTotalMintedVUSD() internal view override returns (uint256) {
        return totalPVUSDCirculation;
    }

    function getBorrowedOf(address user) external view returns (uint256) {
        return borrowed[user];
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./SafeMath.sol";
import "./IERC20.sol";
/**
 * @title Interest-bearing ERC20-like token for Lybra protocol.
 *
 * This contract is abstract. To make the contract deployable override the
 * `_getTotalMintedVUSD` function. `Lybra.sol` contract inherits VUSD and defines
 * the `_getTotalMintedVUSD` function.
 *
 * VUSD balances are dynamic and represent the holder's share in the total amount
 * of Ether controlled by the protocol. Account shares aren't normalized, so the
 * contract also stores the sum of all shares to calculate each account's token balance
 * which equals to:
 *
 *   shares[account] * _getTotalMintedVUSD() / _getTotalShares()
 *
 * For example, assume that we have:
 *
 *   _getTotalMintedVUSD() -> 1000 VUSD
 *   sharesOf(user1) -> 100
 *   sharesOf(user2) -> 400
 *
 * Therefore:
 *
 *   balanceOf(user1) -> 2 tokens which corresponds 200 VUSD
 *   balanceOf(user2) -> 8 tokens which corresponds 800 VUSD
 *
 * Since balances of all token holders change when the amount of total supplied VUSD
 * changes, this token cannot fully implement ERC20 standard: it only emits `Transfer`
 * events upon explicit transfer between holders. In contrast, when total amount of
 * pooled Ether increases, no `Transfer` events are generated: doing so would require
 * emitting an event for each token holder and thus running an unbounded loop.
 */
abstract contract PVUSD is IERC20 {
    using SafeMath for uint256;
    uint256 private totalShares;

    /**
     * @dev VUSD balances are dynamic and are calculated based on the accounts' shares
     * and the total supply by the protocol. Account shares aren't
     * normalized, so the contract also stores the sum of all shares to calculate
     * each account's token balance which equals to:
     *
     *   shares[account] * _getTotalMintedVUSD() / _getTotalShares()
     */
    mapping(address => uint256) private shares;

    /**
     * @dev Allowances are nominated in tokens, not token shares.
     */
    mapping(address => mapping(address => uint256)) private allowances;

    /**
     * @notice An executed shares transfer from `sender` to `recipient`.
     *
     * @dev emitted in pair with an ERC20-defined `Transfer` event.
     */
    event TransferShares(
        address indexed from,
        address indexed to,
        uint256 sharesValue
    );

    /**
     * @notice An executed `burnShares` request
     *
     * @dev Reports simultaneously burnt shares amount
     * and corresponding VUSD amount.
     * The VUSD amount is calculated twice: before and after the burning incurred rebase.
     *
     * @param account holder of the burnt shares
     * @param preRebaseTokenAmount amount of VUSD the burnt shares corresponded to before the burn
     * @param postRebaseTokenAmount amount of VUSD the burnt shares corresponded to after the burn
     * @param sharesAmount amount of burnt shares
     */
    event SharesBurnt(
        address indexed account,
        uint256 preRebaseTokenAmount,
        uint256 postRebaseTokenAmount,
        uint256 sharesAmount
    );

    /**
     * @return the name of the token.
     */
    function name() public pure returns (string memory) {
        return "pvUSD";
    }

    /**
     * @return the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return "pvUSD";
    }

    /**
     * @return the number of decimals for getting user representation of a token amount.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @return the amount of VUSD in existence.
     *
     * @dev Always equals to `_getTotalMintedVUSD()` since token amount
     * is pegged to the total amount of VUSD controlled by the protocol.
     */
    function totalSupply() public view returns (uint256) {
        return _getTotalMintedVUSD();
    }

    /**
     * @return the amount of tokens owned by the `_account`.
     *
     * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
     * total Ether controlled by the protocol. See `sharesOf`.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return getMintedVUSDByShares(_sharesOf(_account));
    }

    /**
     * @notice Moves `_amount` tokens from the caller's account to the `_recipient` account.
     *
     * @return a boolean value indicating whether the operation succeeded.
     * Emits a `Transfer` event.
     * Emits a `TransferShares` event.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the caller must have a balance of at least `_amount`.
     * - the contract must not be paused.
     *
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    /**
     * @return the remaining number of tokens that `_spender` is allowed to spend
     * on behalf of `_owner` through `transferFrom`. This is zero by default.
     *
     * @dev This value changes when `approve` or `transferFrom` is called.
     */
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
     *
     * @return a boolean value indicating whether the operation succeeded.
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - the contract must not be paused.
     *
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient` using the
     * allowance mechanism. `_amount` is then deducted from the caller's
     * allowance.
     *
     * @return a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     * Emits a `TransferShares` event.
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_sender` and `_recipient` cannot be the zero addresses.
     * - `_sender` must have a balance of at least `_amount`.
     * - the caller must have allowance for `_sender`'s tokens of at least `_amount`.
     * - the contract must not be paused.
     *
     * @dev The `_amount` argument is the amount of tokens, not shares.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public returns (bool) {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(
            currentAllowance >= _amount,
            "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE"
        );

        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance.sub(_amount));
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `_spender` by the caller by `_addedValue`.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the the zero address.
     * - the contract must not be paused.
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            _spender,
            allowances[msg.sender][_spender].add(_addedValue)
        );
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `_spender` by the caller by `_subtractedValue`.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in:
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `_spender` cannot be the zero address.
     * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
     * - the contract must not be paused.
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(
            currentAllowance >= _subtractedValue,
            "DECREASED_ALLOWANCE_BELOW_ZERO"
        );
        _approve(msg.sender, _spender, currentAllowance.sub(_subtractedValue));
        return true;
    }

    /**
     * @return the total amount of shares in existence.
     *
     * @dev The sum of all accounts' shares can be an arbitrary number, therefore
     * it is necessary to store it in order to calculate each account's relative share.
     */
    function getTotalShares() public view returns (uint256) {
        return _getTotalShares();
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function sharesOf(address _account) public view returns (uint256) {
        return _sharesOf(_account);
    }

    /**
     * @return the amount of shares that corresponds to `_VUSDAmount` protocol-supplied VUSD.
     */
    function getSharesByMintedVUSD(
        uint256 _VUSDAmount
    ) public view returns (uint256) {
        uint256 totalMintedVUSD = _getTotalMintedVUSD();
        if (totalMintedVUSD == 0) {
            return 0;
        } else {
            return _VUSDAmount.mul(_getTotalShares()).div(totalMintedVUSD);
        }
    }

    /**
     * @return the amount of VUSD that corresponds to `_sharesAmount` token shares.
     */
    function getMintedVUSDByShares(
        uint256 _sharesAmount
    ) public view returns (uint256) {
        uint256 totalSharesAmount = _getTotalShares();
        if (totalShares == 0) {
            return 0;
        } else {
            return
                _sharesAmount.mul(_getTotalMintedVUSD()).div(totalSharesAmount);
        }
    }

    /**
     * @notice Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.
     *
     * @return amount of transferred tokens.
     * Emits a `TransferShares` event.
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the caller must have at least `_sharesAmount` shares.
     * - the contract must not be paused.
     *
     * @dev The `_sharesAmount` argument is the amount of shares, not tokens.
     */
    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) public returns (uint256) {
        _transferShares(msg.sender, _recipient, _sharesAmount);
        emit TransferShares(msg.sender, _recipient, _sharesAmount);
        uint256 tokensAmount = getMintedVUSDByShares(_sharesAmount);
        emit Transfer(msg.sender, _recipient, tokensAmount);
        return tokensAmount;
    }

    /**
     * @return the total amount of VUSD.
     * @dev This is used for calculating tokens from shares and vice versa.
     * @dev This function is required to be implemented in a derived contract.
     */
    function _getTotalMintedVUSD() internal view virtual returns (uint256);

    /**
     * @notice Moves `_amount` tokens from `_sender` to `_recipient`.
     * Emits a `Transfer` event.
     * Emits a `TransferShares` event.
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        uint256 _sharesToTransfer = getSharesByMintedVUSD(_amount);
        _transferShares(_sender, _recipient, _sharesToTransfer);
        emit Transfer(_sender, _recipient, _amount);
        emit TransferShares(_sender, _recipient, _sharesToTransfer);
    }

    /**
     * @notice Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `_spender` cannot be the zero address.
     * - the contract must not be paused.
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @return the total amount of shares in existence.
     */
    function _getTotalShares() internal view returns (uint256) {
        return totalShares;
    }

    /**
     * @return the amount of shares owned by `_account`.
     */
    function _sharesOf(address _account) internal view returns (uint256) {
        return shares[_account];
    }

    /**
     * @notice Moves `_sharesAmount` shares from `_sender` to `_recipient`.
     *
     * Requirements:
     *
     * - `_sender` cannot be the zero address.
     * - `_recipient` cannot be the zero address.
     * - `_sender` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function _transferShares(
        address _sender,
        address _recipient,
        uint256 _sharesAmount
    ) internal {
        require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

        uint256 currentSenderShares = shares[_sender];
        require(
            _sharesAmount <= currentSenderShares,
            "TRANSFER_AMOUNT_EXCEEDS_BALANCE"
        );

        shares[_sender] = currentSenderShares.sub(_sharesAmount);
        shares[_recipient] = shares[_recipient].add(_sharesAmount);
    }

    /**
     * @notice Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
     * @dev This doesn't increase the token total supply.
     *
     * Requirements:
     *
     * - `_recipient` cannot be the zero address.
     * - the contract must not be paused.
     */
    function _mintShares(
        address _recipient,
        uint256 _sharesAmount
    ) internal returns (uint256 newTotalShares) {
        require(_recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");

        newTotalShares = _getTotalShares().add(_sharesAmount);
        totalShares = newTotalShares;

        shares[_recipient] = shares[_recipient].add(_sharesAmount);

        // Notice: we're not emitting a Transfer event from the zero address here since shares mint
        // works by taking the amount of tokens corresponding to the minted shares from all other
        // token holders, proportionally to their share. The total supply of the token doesn't change
        // as the result. This is equivalent to performing a send from each other token holder's
        // address to `address`, but we cannot reflect this as it would require sending an unbounded
        // number of events.
    }

    /**
     * @notice Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
     * @dev This doesn't decrease the token total supply.
     *
     * Requirements:
     *
     * - `_account` cannot be the zero address.
     * - `_account` must hold at least `_sharesAmount` shares.
     * - the contract must not be paused.
     */
    function _burnShares(
        address _account,
        uint256 _sharesAmount
    ) internal returns (uint256 newTotalShares) {
        require(_account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");

        uint256 accountShares = shares[_account];
        require(_sharesAmount <= accountShares, "BURN_AMOUNT_EXCEEDS_BALANCE");

        uint256 preRebaseTokenAmount = getMintedVUSDByShares(_sharesAmount);

        newTotalShares = _getTotalShares().sub(_sharesAmount);
        totalShares = newTotalShares;

        shares[_account] = accountShares.sub(_sharesAmount);

        uint256 postRebaseTokenAmount = getMintedVUSDByShares(_sharesAmount);

        emit SharesBurnt(
            _account,
            preRebaseTokenAmount,
            postRebaseTokenAmount,
            _sharesAmount
        );

        // Notice: we're not emitting a Transfer event to the zero address here since shares burn
        // works by redistributing the amount of tokens corresponding to the burned shares between
        // all other token holders. The total supply of the token doesn't change as the result.
        // This is equivalent to performing a send from `address` to each other token holder address,
        // but we cannot reflect this as it would require sending an unbounded number of events.

        // We're emitting `SharesBurnt` event to provide an explicit rebase log record nonetheless.
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}