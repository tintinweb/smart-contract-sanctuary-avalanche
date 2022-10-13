// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./lib/Claimable.sol";
import "./lib/IDEX.sol";
import "./lib/Math.sol";
import "./lib/RewardsHelperLibs.sol";

contract RewardsExtension is
    Math,
    Claimable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private rewardsPool;
    IYieldBox private YieldBox;
    IMaintFee private MaintFee;
    IRewards public Rewards;

    address private tokenAddress;
    address private router;

    IStakedYieldKey private StakedYieldKeyLeg;
    IStakedYieldKey private StakedYieldKeyReg;
    IYieldKey private YieldKey;

    // Pause rewards
    bool private pauseRewards;

    event RewardsCompounded(address indexed owner, uint8 limit);

    event AmountDonated(address indexed owner, uint256 amount);

    function initialize(
        address _tokenAddress,
        address _rewardsPool,
        address _yieldBox,
        address _yieldKey,
        address _stakedYieldKeyLeg,
        address _stakedYieldKeyReg,
        address _mainFee,
        address _rewards
    ) public initializer {
        __ReentrancyGuard_init();
        tokenAddress = _tokenAddress;
        rewardsPool = _rewardsPool;
        YieldBox = IYieldBox(_yieldBox);
        YieldKey = IYieldKey(_yieldKey);
        StakedYieldKeyLeg = IStakedYieldKey(_stakedYieldKeyLeg);
        StakedYieldKeyReg = IStakedYieldKey(_stakedYieldKeyReg);
        MaintFee = IMaintFee(_mainFee);
        Rewards = IRewards(_rewards);
    }

    function rewardsPerYKWithDonation(
        uint256[] memory _yieldKey,
        uint8[] memory _type,
        uint256 percentage
    ) external nonReentrant {
        require(_yieldKey.length == _type.length, "invalid input");

        //Calculating rewards for the yieldKeys
        for (uint256 i = 0; i < _yieldKey.length; i++) {
            (
                uint256[] memory amount,
                uint256[] memory rewarded,
                uint256[] memory YieldBoxRewarded,
                uint256 time
            ) = preRewardPerYK(_yieldKey[i], _type[i], _msgSender());

            //Refernce for storing totalAmounts to be claimed
            uint256 total;

            //Calculating totalRewards
            for (uint256 j = 0; j < amount.length; j++) {
                total += amount[j];
            }

            uint256 donations = total.mul(percentage).div(100);

            IERC20Upgradeable _token = IERC20Upgradeable(tokenAddress);

            require(
                _token.balanceOf(rewardsPool) >= total,
                "Not enough ValiFi tokens in pool"
            );

            //Transfering the user ClaimedRewards to this Address
            bool success_treasury = _token.transferFrom(
                rewardsPool,
                _msgSender(),
                total - donations
            );

            emit AmountDonated(_msgSender(), donations);

            require(success_treasury, "Rewards claim failed");

            //Store the YieldBox rewards-related data
            require(
                Rewards.setYieldBoxBatchRewards(
                    amount,
                    rewarded,
                    YieldBoxRewarded,
                    _msgSender(),
                    percentage
                ),
                "Setting rewards data failed!"
            );
        }
    }

    function compound(
        address _currency,
        uint8 _limit,
        bool _isWalletIncluded,
        bool _isWalletOnly
    ) external nonReentrant {
        require(_limit <= 25, "Can't compound more than 25 YieldBoxes at once");
        require(YieldBox.isValidToken(_currency), "Currency not supported");
        uint256 VALIforYB = 5 ether;
        uint256 swapConst = 5.6 ether;
        uint256 amountRequiredInVali = 10.6 ether;
        uint256 totalRequiredVALI = amountRequiredInVali.mul(_limit);
        uint256 totalRewardsAmount;
        uint256 totalAmountFromUser;
        uint256 totalAmount;

        if (!_isWalletOnly) {
            (
                uint256[] memory amount,
                uint256[] memory rewarded,
                uint256[] memory YieldBoxRewarded,
                uint256[] memory _YieldKey,
                uint256 time
            ) = Rewards.getTotalRewards(_msgSender());

            //calculating rewards
            for (uint256 i = 0; i < _YieldKey.length; i++) {
                totalRewardsAmount += amount[i];

                Rewards.setYieldBoxWithYieldKeyRewards(
                    amount[i],
                    rewarded[i],
                    YieldBoxRewarded[i],
                    _YieldKey[i],
                    _msgSender()
                );
            }

            //transferring rewards from rewardspool to this address
            require(
                Rewards.getFunds(
                    rewardsPool,
                    address(this),
                    totalRewardsAmount
                ),
                "Transferring funds from rewards pool failed"
            );

            if (totalRewardsAmount < totalRequiredVALI) {
                uint256 neededVALI = totalRequiredVALI.sub(totalRewardsAmount);

                if (_isWalletIncluded) {
                    require(
                        IERC20Upgradeable(tokenAddress).balanceOf(
                            _msgSender()
                        ) >= neededVALI,
                        "Low wallet balance to compound"
                    );
                    //if wallet included just transfer the required VALI from the callers wallet
                    require(
                        Rewards.getFunds(
                            _msgSender(),
                            address(this),
                            neededVALI
                        ),
                        "Transfer VALI from wallet failed!"
                    );
                    totalAmountFromUser += neededVALI;
                }
            }

            totalAmount = totalAmountFromUser + totalRewardsAmount;

            require(
                totalAmount >= totalRequiredVALI,
                "Not enough rewards and balance to create specified YieldBoxes"
            );
        }

        if (_isWalletOnly) {
            uint256 userBalance = IERC20Upgradeable(tokenAddress).balanceOf(
                _msgSender()
            );
            require(
                userBalance >= totalRequiredVALI,
                "Unable to compound. Low wallet balance"
            );

            require(
                Rewards.getFunds(
                    _msgSender(),
                    address(this),
                    totalRequiredVALI
                ),
                "Transfer VALI from wallet failed!"
            );

            totalAmount = totalRequiredVALI;
        }

        //approving for router to swap
        IERC20Upgradeable(tokenAddress).approve(router, swapConst.mul(_limit));

        //swap
        swapTokensForTokens(swapConst.mul(_limit), _currency);

        //approving for YB
        IERC20Upgradeable(tokenAddress).approve(
            address(YieldBox),
            VALIforYB.mul(_limit)
        );
        IERC20Upgradeable(_currency).approve(
            address(YieldBox),
            IERC20Upgradeable(_currency).balanceOf(address(this))
        );

        //buying YieldBoxes
        for (uint256 z = 0; z < _limit; z++) {
            YieldBox.createFor(_msgSender(), _currency);
        }

        uint256 remainingStable = IERC20Upgradeable(_currency).balanceOf(
            address(this)
        );

        if (remainingStable > 0) {
            IERC20Upgradeable(_currency).approve(router, remainingStable);
            //swapping remaining back to the rewardsPool
            swapBack(remainingStable, _currency, rewardsPool);
        }

        uint256 remainingVALI = IERC20Upgradeable(tokenAddress).balanceOf(
            address(this)
        );

        if (remainingVALI > 0) {
            uint256 remainingUserVali = totalAmount.sub(totalRequiredVALI);
            if (remainingUserVali > 0) {
                IERC20Upgradeable(tokenAddress).transfer(
                    _msgSender(),
                    remainingUserVali
                );
            }

            uint256 remainingVALICheck = IERC20Upgradeable(tokenAddress)
                .balanceOf(address(this));

            if (remainingVALICheck > 0) {
                IERC20Upgradeable(tokenAddress).transfer(
                    rewardsPool,
                    remainingVALICheck
                );
            }
        }

        emit RewardsCompounded(_msgSender(), _limit);
    }

    ///Helper functions///

    function swapTokensForTokens(uint256 amountIn, address currency) internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(currency);

        // make the swap
        IDEXRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                1,
                path,
                address(this),
                block.timestamp + 10
            );
    }

    function swapBack(
        uint256 amountIn,
        address currency,
        address receiver
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(currency);
        path[1] = address(tokenAddress);

        // make the swap
        IDEXRouter02(router).swapExactTokensForTokens(
            amountIn,
            1,
            path,
            receiver,
            block.timestamp + 10
        );
    }

    /**
     * @dev Calculate Pre-reward per YieldKey
     * @param _yieldKey YieldKey of YieldBox
     * @param _type Type of YieldKey
     */
    function preRewardPerYK(
        uint256 _yieldKey,
        uint8 _type,
        address _user
    )
        public
        view
        whenNotPaused
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        )
    {
        require(!pauseRewards, "The rewards are paused");
        uint256[] memory YieldBoxIds = YieldBox.activeYieldBoxes(_user);
        // if (YieldBoxIds.length != 0) {
        //     YieldBoxIds = sort(YieldBoxIds);
        // }
        require(YieldBoxIds.length > 0, "No YieldBox currently with rewards");
        require(
            (OwnerIsStaked(_yieldKey, _type, _user) &&
                (MaintFee.yieldBoxYieldKeyLeg(_yieldKey).length > 0 ||
                    MaintFee.yieldBoxYieldKeyReg(_yieldKey).length > 0)),
            "YieldKey is not associated to YieldBoxes"
        );
        time = block.timestamp;
        uint64[] memory startstake;
        uint64[] memory endstake;
        if (_type == 12) {
            YieldBoxRewarded = new uint256[](
                MaintFee.yieldBoxYieldKeyLeg(_yieldKey).length
            );
            YieldBoxRewarded = MaintFee.yieldBoxYieldKeyLeg(_yieldKey);
            (startstake, endstake) = StakedYieldKeyLeg.getStakedYieldKeyHistory(
                _user,
                _yieldKey
            );
        } else if (_type == 8 || _type == 6 || _type == 4) {
            YieldBoxRewarded = new uint256[](
                MaintFee.yieldBoxYieldKeyReg(_yieldKey).length
            );
            YieldBoxRewarded = MaintFee.yieldBoxYieldKeyReg(_yieldKey);
            (startstake, endstake) = StakedYieldKeyReg.getStakedYieldKeyHistory(
                _user,
                _yieldKey
            );
        }
        rewarded = new uint256[](YieldBoxRewarded.length);
        amount = new uint256[](YieldBoxRewarded.length);
        for (uint256 i = 0; i < YieldBoxRewarded.length; i++) {
            rewarded[i] += Rewards.getRewardsDays(
                startstake,
                endstake,
                YieldBoxRewarded[i],
                uint64(time)
            );
            amount[i] += rewarded[i] * Rewards.REWARDS_PER_DAYS();
        }
    }

    /**
     * @dev checks if the YieldKey is staked by its owner
     * @param _yieldKey YieldKey Token Id
     * @return Status true if the owner has YieldKey in staking, or false if the YieldKey is not in staking
     */
    function OwnerIsStaked(
        uint256 _yieldKey,
        uint8 _type,
        address _user
    ) public view returns (bool) {
        if (_type == 12) {
            require(
                StakedYieldKeyLeg.ownerOf(_yieldKey) == _user,
                "Caller is not the owner of the Legendary YieldKey"
            );
            require(
                StakedYieldKeyLeg.isStaked(_user, _yieldKey),
                "YieldKey is not staked"
            );
        } else if (_type == 8 || _type == 6 || _type == 4) {
            require(
                StakedYieldKeyReg.ownerOf(_yieldKey) == _user,
                "Caller is not the owner of the Regular YieldKey"
            );
            require(
                YieldKey.capacityAmount(_yieldKey) == _type,
                "YieldKey type does not match"
            );
            require(
                StakedYieldKeyReg.isStaked(_user, _yieldKey),
                "YieldKey is not being staked"
            );
        } else {
            revert("YieldKey type is not valid");
        }
        if (_type == 12) {
            uint256[] memory stakedYKL = StakedYieldKeyLeg.tokenStaking(_user);
            for (uint256 i = 0; i < stakedYKL.length; i++) {
                if (stakedYKL[i] == _yieldKey) {
                    return true;
                }
            }
        } else if (_type == 8 || _type == 6 || _type == 4) {
            uint256[] memory stakedYKR = StakedYieldKeyReg.tokenStaking(_user);
            for (uint256 i = 0; i < stakedYKR.length; i++) {
                if (stakedYKR[i] == _yieldKey) {
                    return true;
                }
            }
        }
        return false;
    }

    ///Rewards accessible functions

    /**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pauseReward(bool status) external onlyRewards {
        if (status) {
            pauseRewards = true;
        } else {
            pauseRewards = false;
        }
    }

    function setRouterAddress(address _address) external onlyRewards {
        router = _address;
    }

    /**
     * @dev Allows to get the total days the YieldKey has been staked
     * @dev based on the amount of YieldKeys (Regular or Legendary) staked by the caller
     * @param startStaked Start timestamp of YieldKey staking
     * @param endStaked End timestamp of YieldKey staking
     * @return amountDays Total days staked
     */
    function getStakedDays(
        uint64[] memory startStaked,
        uint64[] memory endStaked,
        uint256 YieldBoxIds
    ) external view returns (uint256 amountDays) {
        uint64 value = YieldBox.yieldBox(YieldBoxIds).rewardClaimed >
            MaintFee.maintFee(YieldBoxIds).firstDay
            ? YieldBox.yieldBox(YieldBoxIds).rewardClaimed
            : MaintFee.maintFee(YieldBoxIds).firstDay;
        for (uint256 i = 0; i < startStaked.length; i++) {
            if ((value < startStaked[i]) && (value < endStaked[i])) {
                amountDays += (endStaked[i] - startStaked[i]).div(1 minutes);
            } else if ((value >= startStaked[i]) && (value < endStaked[i])) {
                amountDays += (endStaked[i] - value).div(1 minutes);
            }
        }
    }

    modifier onlyRewards() {
        require(
            _msgSender() == address(Rewards),
            "Caller is not the rewards contract"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./Blacklistable.sol";

/**
 * @title Claimable Methods
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Claimable is OwnableUpgradeable, Blacklistable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // Event when the Smart Contract receive Amount of Native or ERC20 tokens
    /**
     * @dev Event when the Smart Contract receive Amount of Native or ERC20 tokens
     * @param sender The address of the sender
     * @param value The amount of tokens
     */
    event ValueReceived(address indexed sender, uint256 indexed value);
    /**
     * @dev Event when the Smart Contract Send Amount of Native or ERC20 tokens
     * @param receiver The address of the receiver
     * @param value The amount of tokens
     */
    event ValueSent(address indexed receiver, uint256 indexed value);

    /// @notice Handle receive ether
    receive() external payable {
        emit ValueReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to)
        public
        validAddress(_to)
        notBlacklisted(_to)
        onlyOwner
    {
        if (_token == address(0)) {
            _claimNativeCoins(_to);
        } else {
            _claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function _claimNativeCoins(address _to) private {
        uint256 amount = address(this).balance;

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = _to.call{value: amount}("");
        require(
            success,
            "ERC20: Address: unable to send value, recipient may have reverted"
        );
        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit ValueSent(_to, amount);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function _claimErc20Tokens(address _token, address _to) private {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc721Tokens(address _token, address _to)
        public
        validAddress(_to)
        notBlacklisted(_to)
        onlyOwner
    {
        IERC721Upgradeable token = IERC721Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(address(this), _to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc1155Tokens(
        address _token,
        address _to,
        uint256 _id
    ) public validAddress(_to) notBlacklisted(_to) onlyOwner {
        IERC1155Upgradeable token = IERC1155Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this), _id);
        bytes memory data = "0x00";
        token.safeTransferFrom(address(this), _to, _id, balance, data);
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

interface IDEXFactory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function migrator() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setMigrator(address) external;
}

interface IDEXPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

interface IDEXRouter01 {
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
}

// pragma solidity >=0.6.2;

interface IDEXRouter02 is IDEXRouter01 {
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

/**
 * @title Math Library
 * @dev Allows handle 512-bit multiply, RoundingUp
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Math {
    using SafeMathUpgradeable for uint256;

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator.add(uint256(1))) &
            denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
    }

    function sort_item(uint256 pos, uint256[] memory _array)
        internal
        pure
        returns (uint256 w_min)
    {
        w_min = pos;
        for (uint256 i = pos; i < _array.length; i++) {
            if (_array[i] < _array[w_min]) {
                w_min = i;
            }
        }
    }

    /**
     * @dev Sort the array
     */
    function sort(uint256[] memory _array)
        internal
        pure
        returns (uint256[] memory)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            uint256 w_min = sort_item(i, _array);
            if (w_min == i) continue;
            uint256 tmp = _array[i];
            _array[i] = _array[w_min];
            _array[w_min] = tmp;
        }
        return _array;
    }
}

import "./Claimable.sol";

contract RewardsHelperLibs {
    struct RewardStruct {
        /** @dev First day maintenance fee */
        uint64 firstDay; // must be change Last Claim
        /** @dev Days of rewards claimed */
        uint256 claimedDays;
        /** @dev Days of minimal rewards (free) claimed */
        uint256 freeDaysClaimed;
    }
}

interface IRewards {
    function REWARDS_PER_DAYS() external view returns (uint256);

    function setYieldBoxBatchRewards(
        uint256[] memory amount,
        uint256[] memory rewarded,
        uint256[] memory YieldBoxRewarded,
        address user,
        uint256 percentage
    ) external returns (bool);

    function setYieldBoxWithYieldKeyRewards(
        uint256 amount,
        uint256 rewarded,
        uint256 YieldBoxRewarded,
        uint256 _YieldKey,
        address user
    ) external returns (bool);

    function getFunds(
        address user,
        address to,
        uint256 _amount
    ) external returns (bool);

    function getRewardsDays(
        uint64[] memory startStaked,
        uint64[] memory endStaked,
        uint256 YieldBoxIds,
        uint64 time
    ) external view returns (uint256 rewardDays);

    function getTotalRewards(address wallet)
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256[] memory _YieldKey,
            uint256 time
        );
}

interface IRewardsExtension {
    function pauseReward(bool status) external;

    function setRouterAddress(address _address) external;

    function getStakedDays(
        uint64[] memory startStaked,
        uint64[] memory endStaked,
        uint256 YieldBoxIds
    ) external view returns (uint256 amountDays);

    function OwnerIsStaked(
        uint256 _yieldKey,
        uint8 _type,
        address _user
    ) external view returns (bool);

    function preRewardPerYK(
        uint256 _yieldKey,
        uint8 _type,
        address _user
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );
}

/** @dev Interface of Maintenance Fee */
interface IMaintFee {
    struct MainFeeStruct {
        /** @dev Maintenance fee status */
        bool status;
        /** @dev Maintenance fee owner */
        address lastOwner;
        /** @dev First day maintenance fee */
        uint64 firstDay;
        /** @dev Fee due Date */
        uint64 feeDue;
        /** @dev Unclaimed Days */
        uint256 unClaimedDays;
        /** @dev YieldKey Token Id */
        uint256 yieldKey;
        /** @dev Type of YieldKey */
        uint8 yieldKeyType; // Types: 4,6,8 and 12
    }

    /**@dev Maintenance fee details by Token Id */
    function maintFee(uint256 _tokenId)
        external
        view
        returns (MainFeeStruct memory);

    /** @dev get array of YieldBoxes per Legendary YieldKey */
    function yieldBoxYieldKeyLeg(uint256 _yieldKey)
        external
        view
        returns (uint256[] memory);

    /** @dev get array of YieldBoxes per Regular YieldKey */
    function yieldBoxYieldKeyReg(uint256 _yieldKey)
        external
        view
        returns (uint256[] memory);

    /** @dev get array of YieldBoxes without associated YieldKeys */
    function getYieldBoxWithoutYieldKey(address _walletAddress)
        external
        view
        returns (uint256[] memory);
}

/** @dev Interface of Legendary YieldKey */
interface I_ValiFiNFT is IERC721Upgradeable {
    function tokenHoldings(address _owner)
        external
        view
        returns (uint256[] memory);
}

interface IStakedYieldKey is I_ValiFiNFT {
    /**
     * @dev Struct of Staked YieldKeys
     */
    struct StakeYieldKey {
        bool isStaked;
        uint64[] startstake;
        uint64[] endstake;
    }

    function isStaked(address wallet, uint256 _tokenId)
        external
        view
        returns (bool);

    function getStakedYieldKeyHistory(address wallet, uint256 _tokenId)
        external
        view
        returns (uint64[] memory startstake, uint64[] memory endstake);

    function tokenStaking(address _owner)
        external
        view
        returns (uint256[] memory stakeTokenIds);
}

/** @dev Interface of YieldBox */
interface IYieldBox is I_ValiFiNFT {
    /**
     * @dev Struct of the YieldBox
     */
    struct YieldBoxStruct {
        /** @dev YieldBox status */
        bool status;
        /** @dev Dead YieldBox token */
        bool dead;
        /** @dev Time of last claim */
        uint64 rewardClaimed;
        /** @dev YieldBox owner */
        address owner;
        /** @dev YieldBox Token ID */
        uint256 id;
        /** @dev Time of creation */
        uint256 createdAt;
    }

    function yieldBox(uint256 _tokenIDs)
        external
        view
        returns (YieldBoxStruct memory);

    function activeYieldBoxes(address _wallet)
        external
        view
        returns (uint256[] memory);

    function setRewardClaimed(
        bool status,
        bool dead,
        uint256 tokenId
    ) external;

    function isValidToken(address _token) external view returns (bool);

    function createFor(address _user, address _currency) external;

    function _getVaLiFiPriceinStable() external view returns (uint256 price);
}

/** @dev Interface of Regular YieldKey */
interface IYieldKey is I_ValiFiNFT {
    function capacityAmount(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Blacklistable Methods
 * @dev Allows accounts to be blacklisted by Owner
 */
contract Blacklistable is OwnableUpgradeable {
    // Index Address
    address[] private wallets;
    // Mapping of blacklisted Addresses
    mapping(address => bool) private blacklisted;
    // Events when wallets are added or dropped from the blacklisted mapping
    event InBlacklisted(address indexed _account);
    event OutBlacklisted(address indexed _account);

    /**
     * @dev Reverts if account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "ERC721 ValiFi: sender account is blacklisted"
        );
        _;
    }

    /**
     * @dev Reverts if a given address is equal to address(0)
     * @param _to The address to check
     */
    modifier validAddress(address _to) {
        require(_to != address(0), "ERC721 ValiFi: Zero Address not allowed");
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addBlacklist(address _account)
        public
        validAddress(_account)
        notBlacklisted(_account)
        onlyOwner
    {
        blacklisted[_account] = true;
        wallets.push(_account);
        emit InBlacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function dropBlacklist(address _account)
        public
        validAddress(_account)
        onlyOwner
    {
        require(
            isBlacklisted(_account),
            "ERC721 ValiFi: Wallet not present in blacklist"
        );
        blacklisted[_account] = false;
        emit OutBlacklisted(_account);
    }

    /**
     * @dev Retrieve the list of Blacklisted Addresses
     */
    function getBlacklist() public view returns (address[] memory) {
        return wallets;
    }
}

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
interface IERC165Upgradeable {
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