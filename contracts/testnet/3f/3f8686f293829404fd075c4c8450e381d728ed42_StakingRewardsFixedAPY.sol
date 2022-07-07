/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-07
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/StakingRewardsFixedAPY.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Math64x64 {
	/*
	 * Minimum value signed 64.64-bit fixed point number may have.
	 */
	int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

	/*
	 * Maximum value signed 64.64-bit fixed point number may have.
	 */
	int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

	/**
	 * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
	 * number.  Revert on overflow.
	 *
	 * @param x unsigned 256-bit integer number
	 * @return signed 64.64-bit fixed point number
	 */
	function fromUInt(uint256 x) internal pure returns (int128) {
		unchecked {
			require(x <= 0x7FFFFFFFFFFFFFFF);
			return int128(int256(x << 64));
		}
	}

	/**
	 * Convert signed 64.64 fixed point number into unsigned 64-bit integer
	 * number rounding down.  Revert on underflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @return unsigned 64-bit integer number
	 */
	function toUInt(int128 x) internal pure returns (uint64) {
		unchecked {
			require(x >= 0);
			return uint64(uint128(x >> 64));
		}
	}

	/**
	 * Calculate x * y rounding down, where x is signed 64.64 fixed point number
	 * and y is unsigned 256-bit integer number.  Revert on overflow.
	 *
	 * @param x signed 64.64 fixed point number
	 * @param y unsigned 256-bit integer number
	 * @return unsigned 256-bit integer number
	 */
	function mulu(int128 x, uint256 y) internal pure returns (uint256) {
		unchecked {
			if (y == 0) return 0;

			require(x >= 0);

			uint256 lo = (uint256(int256(x)) *
				(y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
			uint256 hi = uint256(int256(x)) * (y >> 128);

			require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
			hi <<= 64;

			require(
				hi <=
					0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
						lo
			);
			return hi + lo;
		}
	}

	/**
	 * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
	 * integer numbers.  Revert on overflow or when y is zero.
	 *
	 * @param x unsigned 256-bit integer number
	 * @param y unsigned 256-bit integer number
	 * @return signed 64.64-bit fixed point number
	 */
	function divu(uint256 x, uint256 y) internal pure returns (int128) {
		unchecked {
			require(y != 0);
			uint128 result = divuu(x, y);
			require(result <= uint128(MAX_64x64));
			return int128(result);
		}
	}

	/**
	 * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
	 * and y is unsigned 256-bit integer number.  Revert on overflow.
	 *
	 * @param x signed 64.64-bit fixed point number
	 * @param y uint256 value
	 * @return signed 64.64-bit fixed point number
	 */
	function pow(int128 x, uint256 y) internal pure returns (int128) {
		unchecked {
			bool negative = x < 0 && y & 1 == 1;

			uint256 absX = uint128(x < 0 ? -x : x);
			uint256 absResult;
			absResult = 0x100000000000000000000000000000000;

			if (absX <= 0x10000000000000000) {
				absX <<= 63;
				while (y != 0) {
					if (y & 0x1 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					if (y & 0x2 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					if (y & 0x4 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					if (y & 0x8 != 0) {
						absResult = (absResult * absX) >> 127;
					}
					absX = (absX * absX) >> 127;

					y >>= 4;
				}

				absResult >>= 64;
			} else {
				uint256 absXShift = 63;
				if (absX < 0x1000000000000000000000000) {
					absX <<= 32;
					absXShift -= 32;
				}
				if (absX < 0x10000000000000000000000000000) {
					absX <<= 16;
					absXShift -= 16;
				}
				if (absX < 0x1000000000000000000000000000000) {
					absX <<= 8;
					absXShift -= 8;
				}
				if (absX < 0x10000000000000000000000000000000) {
					absX <<= 4;
					absXShift -= 4;
				}
				if (absX < 0x40000000000000000000000000000000) {
					absX <<= 2;
					absXShift -= 2;
				}
				if (absX < 0x80000000000000000000000000000000) {
					absX <<= 1;
					absXShift -= 1;
				}

				uint256 resultShift = 0;
				while (y != 0) {
					require(absXShift < 64);

					if (y & 0x1 != 0) {
						absResult = (absResult * absX) >> 127;
						resultShift += absXShift;
						if (absResult > 0x100000000000000000000000000000000) {
							absResult >>= 1;
							resultShift += 1;
						}
					}
					absX = (absX * absX) >> 127;
					absXShift <<= 1;
					if (absX >= 0x100000000000000000000000000000000) {
						absX >>= 1;
						absXShift += 1;
					}

					y >>= 1;
				}

				require(resultShift < 64);
				absResult >>= 64 - resultShift;
			}
			int256 result = negative ? -int256(absResult) : int256(absResult);
			require(result >= MIN_64x64 && result <= MAX_64x64);
			return int128(result);
		}
	}

	/**
	 * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
	 * integer numbers.  Revert on overflow or when y is zero.
	 *
	 * @param x unsigned 256-bit integer number
	 * @param y unsigned 256-bit integer number
	 * @return unsigned 64.64-bit fixed point number
	 */
	function divuu(uint256 x, uint256 y) private pure returns (uint128) {
		unchecked {
			require(y != 0);

			uint256 result;

			if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
				result = (x << 64) / y;
			else {
				uint256 msb = 192;
				uint256 xc = x >> 192;
				if (xc >= 0x100000000) {
					xc >>= 32;
					msb += 32;
				}
				if (xc >= 0x10000) {
					xc >>= 16;
					msb += 16;
				}
				if (xc >= 0x100) {
					xc >>= 8;
					msb += 8;
				}
				if (xc >= 0x10) {
					xc >>= 4;
					msb += 4;
				}
				if (xc >= 0x4) {
					xc >>= 2;
					msb += 2;
				}
				if (xc >= 0x2) msb += 1; // No need to shift xc anymore

				result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
				require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

				uint256 hi = result * (y >> 128);
				uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

				uint256 xh = x >> 192;
				uint256 xl = x << 64;

				if (xl < lo) xh -= 1;
				xl -= lo; // We rely on overflow behavior here
				lo = hi << 128;
				if (xl < lo) xh -= 1;
				xl -= lo; // We rely on overflow behavior here

				assert(xh == hi >> 128);

				result += xl / y;
			}

			require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
			return uint128(result);
		}
	}
}

contract StakingRewardsFixedAPY {
	using Math64x64 for int128;

	// precision constant for math
	uint128 public constant PRECISION = 1e18;
	uint128 public constant SHARE_PRECISION = 1e8;
	uint128 public constant SHARE_DECIMALS = 1e2;

	// the users stake information
	struct StakerInfo {
		uint128 deposit; // the amount of user active stake
		uint128 shares;
		uint128 rewardsPaid; // rewards that accounted already so should be substracted
		uint128 rewardsDonated; //total rewards user has donated so far
		uint128 avgDonationRatio; //donation ratio per share
	}

	struct Stats {
		// last block this staking contract was updated and rewards were calculated
		uint128 lastUpdateBlock;
		// total supply of active stakes
		uint128 totalStaked;
		uint128 totalShares;
		uint128 totalRewardsPaid;
		uint128 totalRewardsDonated;
		uint128 avgDonationRatio;
		uint256 principle; //total earning compounding interest;
	}

	Stats public stats;

	// the user info sheet
	mapping(address => StakerInfo) public stakersInfo;

	// interest rate per one block in 1e18 precision.
	//for example APY=5% then per block = nroot(1+0.05,numberOfBlocksPerYear)
	//nroot(1.05,6000000) = 1.000000008131694
	//in 1e18 = 1000000008131694000
	int128 public interestRatePerBlockX64;

	function _setAPY(uint128 _interestRatePerBlock) internal updateReward {
		interestRatePerBlockX64 = Math64x64.divu(_interestRatePerBlock, 1e18); //convert to signed int x64
	}

	modifier updateReward() {
		_updateReward();
		_;
	}

	function _compound() internal view returns (uint256 compoundedPrinciple) {
		if (stats.principle == 0 || block.number == stats.lastUpdateBlock) {
			return stats.principle;
		}
		int128 compound = interestRatePerBlockX64.pow(
			block.number - stats.lastUpdateBlock
		);
		compoundedPrinciple = compound.mulu(stats.principle);
	}

	function sharePrice() public view returns (uint256 price) {
		uint256 compoundedPrinciple = _compound();

		return
			(compoundedPrinciple * SHARE_PRECISION) / (stats.totalShares * PRECISION);
	}

	/**
	 * @dev calculate how much user can withdraw after reducing donations
	 */
	function getPrinciple(address _account)
		public
		view
		returns (uint256 balance)
	{
		(uint256 earnedRewards, uint256 earnedRewardsAfterDonation) = earned(
			_account
		);

		// console.log(
		// 	"getPrinciple: earned rewards: %s, afterDonation: %s, sharePrice: %s",
		// 	earnedRewards,
		// 	earnedRewardsAfterDonation,
		// 	sharePrice()
		// );
		// console.log("getPrinciple: shares: %s", stakersInfo[_account].shares);

		return
			(sharePrice() * stakersInfo[_account].shares) /
			SHARE_PRECISION -
			earnedRewards +
			earnedRewardsAfterDonation;
	}

	/**
	 * @dev The function allows anyone to calculate the exact amount of reward
	 * earned.
	 * @param _account A staker address
	 */
	function earned(address _account)
		public
		view
		returns (uint256 earnedRewards, uint256 earnedRewardsAfterDonation)
	{
		earnedRewards =
			(sharePrice() * stakersInfo[_account].shares) /
			SHARE_PRECISION -
			stakersInfo[_account].deposit;
		earnedRewardsAfterDonation =
			(earnedRewards *
				(100 * PRECISION - stakersInfo[_account].avgDonationRatio)) /
			(100 * PRECISION);
	}

	function getRewardsDebt() external view returns (uint256 rewardsDebt) {
		uint256 rewardsToPay = _compound() - stats.totalStaked;
		rewardsDebt =
			(rewardsToPay * (100 * PRECISION - stats.avgDonationRatio)) /
			(100 * PRECISION);
	}

	/**
	 * @dev Updates the rewards for all stakers
	 */
	function _updateReward() internal virtual {
		stats.principle = _compound();
		stats.lastUpdateBlock = uint128(block.number);
	}

	function _withdraw(address _from, uint256 _amount)
		internal
		virtual
		updateReward
		returns (uint256 depositComponent, uint256 rewardComponent)
	{
		require(_amount > 0, "Cannot withdraw 0");
		require(_amount <= getPrinciple(_from), "not enough balance");

		(uint256 earnedRewards, uint256 earnedRewardsAfterDonation) = earned(_from);
		rewardComponent = earnedRewardsAfterDonation >= _amount
			? _amount
			: earnedRewardsAfterDonation;

		depositComponent = _amount > earnedRewardsAfterDonation
			? _amount - earnedRewardsAfterDonation
			: 0;

		// console.log(
		// 	"rewards %s, deposit: %s, earnedRewardsAfter %s",
		// 	rewardComponent,
		// 	depositComponent,
		// 	earnedRewardsAfterDonation
		// );

		//we also need to account for the diff between earnedRewards and donated rewards
		uint256 donatedRewards = earnedRewards - earnedRewardsAfterDonation;

		// console.log(
		// 	"withdraw: rewardCompoent %s, depositComponent %s, donatedRewards %s",
		// 	rewardComponent,
		// 	depositComponent,
		// 	donatedRewards
		// );

		_amount += donatedRewards; //we also "withdraw" the donation part from user shares

		uint128 shares = uint128((_amount * SHARE_PRECISION) / sharePrice()); //_amount now includes also donated rewards

		// console.log("withdraw: redeemed shares %s", shares);

		require(shares > 0, "min withdraw 1 share");

		stats.avgDonationRatio =
			(stats.avgDonationRatio *
				stats.totalShares -
				stakersInfo[_from].avgDonationRatio *
				shares) /
			(stats.totalShares - shares);

		// console.log("withdraw: reducing principle by %s", _amount);

		stats.principle -= _amount * PRECISION;
		stats.totalShares -= shares;
		stats.totalStaked -= uint128(depositComponent);
		stats.totalRewardsPaid += uint128(rewardComponent);
		stats.totalRewardsDonated += uint128(donatedRewards);
		stakersInfo[_from].shares -= shares;
		stakersInfo[_from].deposit -= uint128(depositComponent);
		stakersInfo[_from].rewardsPaid += uint128(rewardComponent);
		stakersInfo[_from].rewardsDonated += uint128(donatedRewards);
	}

	function _stake(
		address _from,
		uint256 _amount,
		uint32 _donationRatio
	) internal virtual updateReward {
		require(_amount > 0, "Cannot stake 0");
		uint128 newShares = uint128(
			stats.totalShares > 0
				? ((_amount * SHARE_PRECISION) / sharePrice()) //amount/sharePrice = new shares = amount/(principle/totalShares)
				: (_amount * SHARE_DECIMALS) //principal/number of shares is shares price, so initially each share price will represent G%cent/SHARE_DECIMALS
		);
		require(newShares > 0, "min stake 1 share price");

		stakersInfo[_from].deposit += uint128(_amount);
		uint128 accountShares = stakersInfo[_from].shares;
		stakersInfo[_from].avgDonationRatio =
			(stakersInfo[_from].avgDonationRatio *
				accountShares +
				_donationRatio *
				PRECISION *
				newShares) /
			(accountShares + newShares);
		stakersInfo[_from].shares += newShares;

		stats.avgDonationRatio =
			(stats.avgDonationRatio *
				stats.totalShares +
				_donationRatio *
				PRECISION *
				newShares) /
			(stats.totalShares + newShares);

		stats.totalShares += newShares;
		stats.totalStaked += uint128(_amount);
		stats.principle += _amount * PRECISION;
	}

	// function _getReward(address _to)
	// 	internal
	// 	virtual
	// 	updateReward
	// 	returns (uint256 reward)
	// {
	// 	// return and reset the reward if there is any
	// 	reward = stakersInfo[_to].reward;
	// 	stakersInfo[_to].reward = 0;
	// 	stakersInfo[_to].rewardsMinted += uint128(reward);
	// 	principle -= reward * PRECISION; //rewards are part of the compounding interest
	// }

	/**
	 * @dev keep track of debt to user in case reward minting failed
	 */
	function _undoReward(address _to, uint256 _rewardsPaidAfterDonation)
		internal
		virtual
	{
		//the actual amount we undo needs to take into account the user donation ratio.
		uint256 rewardsBeforeDonation = (100 *
			PRECISION *
			_rewardsPaidAfterDonation) / stakersInfo[_to].avgDonationRatio;

		//calculate this before udpating global principle
		uint128 newShares = uint128(
			(rewardsBeforeDonation * SHARE_PRECISION) / sharePrice()
		);
		// console.log(
		// 	"undoReward: increasing principle by %s",
		// 	rewardsBeforeDonation
		// );

		stats.avgDonationRatio =
			(stats.avgDonationRatio *
				stats.totalShares +
				stakersInfo[_to].avgDonationRatio *
				newShares) /
			(stats.totalShares + newShares);

		uint128 rewardsDonated = uint128(
			rewardsBeforeDonation - _rewardsPaidAfterDonation
		);
		stats.totalRewardsPaid -= uint128(_rewardsPaidAfterDonation);
		stats.totalRewardsDonated -= rewardsDonated;
		stats.principle += rewardsBeforeDonation * PRECISION; //rewards are part of the compounding interest
		stats.totalShares += newShares;

		stakersInfo[_to].rewardsPaid -= uint128(_rewardsPaidAfterDonation);
		stakersInfo[_to].rewardsDonated -= rewardsDonated;
		stakersInfo[_to].shares += newShares;
	}

}