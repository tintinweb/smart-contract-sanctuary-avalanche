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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { LPercentages } from "../libraries/LPercentages.sol";
import { IStratosphere } from "../interfaces/IStratosphere.sol";
import { LStratosphere } from "../libraries/LStratosphere.sol";

error UnlockFacet__InvalidAmount();
error UnlockFacet__AlreadyUnlocked();
error UnlockFacet__InvalidFeeReceivers();
error UnlockFacet__InvalidUnlock();

contract UnlockFacet {
    /// @notice Ordering of the events are according to their relevance in the facet
    event Unlocked(uint256 indexed seasonId, address indexed user, uint256 amount, uint256 unlockFee);

    AppStorage s;
    uint256 public constant COOLDOWN_PERIOD = 72 * 3600; // 72 Hours

    function unlock(uint256 _amount) external {
        uint256 _currentSeasonId = s.currentSeasonId;
        UserData storage _userData = s.usersData[_currentSeasonId][msg.sender];
        Season storage _currentSeason = s.seasons[_currentSeasonId];
        uint256 _seasonEndTimestamp = _currentSeason.endTimestamp; //used twice in transaction
        if (_userData.unlockTimestamp != 0) {
            revert UnlockFacet__AlreadyUnlocked();
        }
        if (_userData.depositAmount < _amount) {
            revert UnlockFacet__InvalidAmount();
        }
        _deductPoints(_amount, _seasonEndTimestamp, _userData, _currentSeason);

        uint256 _timeDiscount = 0;
        (bool isStratosphereMember, uint256 tier) = LStratosphere.getDetails(s, msg.sender);
        if (isStratosphereMember) {
            _timeDiscount = s.unlockTimestampDiscountForStratosphereMembers[tier];
        }
        uint256 _unlockFeeFromState = s.unlockFee;
        uint256 _fee = LPercentages.percentage(_amount, _unlockFeeFromState);
        _applyUnlockFee(_fee);
        uint256 _unlockTimestamp = block.timestamp + COOLDOWN_PERIOD - (_timeDiscount * COOLDOWN_PERIOD) / 10000;

        if (_unlockTimestamp >= _seasonEndTimestamp) {
            revert UnlockFacet__InvalidUnlock();
        }

        _userData.unlockAmount += (_amount - _fee);
        _userData.unlockTimestamp = _unlockTimestamp;

        emit Unlocked(_currentSeasonId, msg.sender, _amount, _fee);
    }

    /// @notice deduct points
    /// @param _amount Amount of token to deduct points
    function _deductPoints(
        uint256 _amount,
        uint256 _seasonEndTimestamp,
        UserData storage _userData,
        Season storage _season
    ) internal {
        uint256 _daysUntilSeasonEnd = (_seasonEndTimestamp - block.timestamp) / 1 days;
        _userData.depositAmount -= _amount;
        _userData.depositPoints -= _amount * _daysUntilSeasonEnd;
        _season.totalDepositAmount -= _amount;
        _season.totalPoints -= _amount * _daysUntilSeasonEnd;
    }

    /// @notice Apply deposit fee
    /// @param _fee Fee amount
    function _applyUnlockFee(uint256 _fee) internal {
        address[] memory _receivers = s.unlockFeeReceivers;
        uint256[] memory _shares = s.unlockFeeReceiversShares;
        uint256 _length = _receivers.length;

        if (_length != _shares.length) {
            revert UnlockFacet__InvalidFeeReceivers();
        }
        for (uint256 i; i < _length; ) {
            uint256 _share = LPercentages.percentage(_fee, _shares[i]);
            s.pendingWithdrawals[_receivers[i]][s.depositToken] += _share;
            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IStratosphere {
    function tokenIdOf(address account) external view returns (uint256);

    function tierOf(uint256 tokenId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @dev rewardTokenToDistribute is the amount of reward token to distribute to users
/// @dev rewardTokenBalance is the amount of reward token that is currently in the contract
struct Season {
    uint256 id;
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 rewardTokensToDistribute;
    uint256 rewardTokenBalance;
    uint256 totalDepositAmount;
    uint256 totalClaimAmount;
    uint256 totalPoints;
}

struct UserData {
    uint256 depositAmount;
    uint256 claimAmount;
    uint256 depositPoints;
    uint256 boostPoints;
    uint256 lastBoostClaimTimestamp;
    uint256 lastBoostClaimAmount;
    uint256 unlockAmount;
    uint256 unlockTimestamp;
    uint256 amountClaimed;
    uint256 miningPassTier;
    bool hasWithdrawnOrRestaked;
}

struct AppStorage {
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized;
    /////////////////
    /// PAUSATION ///
    /////////////////
    bool paused;
    //////////////
    /// SEASON ///
    //////////////
    uint256 currentSeasonId;
    uint256 seasonsCount;
    mapping(uint256 => Season) seasons;
    // nested mapping: seasonId => userAddress => UserData
    mapping(uint256 => mapping(address => UserData)) usersData;
    ///////////////
    /// UNLOCK ///
    ///////////////
    uint256 unlockFee;
    // mapping: tier => discount percentage
    mapping(uint256 => uint256) unlockTimestampDiscountForStratosphereMembers;
    // mapping: user => lastSeasonParticipated
    mapping(address => uint256) addressToLastSeasonId;
    address[] unlockFeeReceivers;
    uint256[] unlockFeeReceiversShares;
    ////////////////
    /// BOOST ///
    ////////////////
    uint256 boostForNonStratMembers;
    //mapping: level => USDC fee
    mapping(uint256 => uint256) boostLevelToFee;
    // nested mapping: tier => boostlevel => boost enhance points
    mapping(uint256 => mapping(uint256 => uint256)) boostPercentFromTierToLevel;
    address[] boostFeeReceivers;
    uint256[] boostFeeReceiversShares;
    ////////////////
    /// WITHDRAW ///
    ////////////////
    // nested mapping: userAddress => tokenAddress => amount
    mapping(address => mapping(address => uint256)) pendingWithdrawals;
    ///////////////////
    /// MINING PASS ///
    ///////////////////
    mapping(uint256 => uint256) miningPassTierToFee;
    mapping(uint256 => uint256) miningPassTierToDepositLimit;
    address[] miningPassFeeReceivers;
    uint256[] miningPassFeeReceiversShares;
    ///////////////
    /// GENERAL ///
    ///////////////
    address depositToken;
    address rewardToken;
    address feeToken;
    address stratosphereAddress;
    uint256 reentrancyGuardStatus;
    address emissionsManager;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LPercentages {
    /// @notice Calculates the percentage of a number using basis points
    /// @dev 1% = 100 basis points
    /// @param _number Number
    /// @param _percentage Percentage in bps
    /// @return Percentage of a number
    function percentage(uint256 _number, uint256 _percentage) internal pure returns (uint256) {
        return (_number * _percentage) / 10_000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AppStorage } from "./AppStorage.sol";
import { IStratosphere } from "../interfaces/IStratosphere.sol";

/// @title LStratosphere
/// @notice Library in charge of Stratosphere related logic
library LStratosphere {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get Stratosphere membership details
    /// @param s AppStorage
    /// @param _address Address
    /// @return isStratosphereMember Is Stratosphere member
    /// @return tier Tier
    function getDetails(
        AppStorage storage s,
        address _address
    ) internal view returns (bool isStratosphereMember, uint8 tier) {
        IStratosphere _stratosphere = IStratosphere(s.stratosphereAddress);
        uint256 _tokenId = _stratosphere.tokenIdOf(_address);
        if (_tokenId > 0) {
            isStratosphereMember = true;
            tier = _stratosphere.tierOf(_tokenId);
        }
    }
}