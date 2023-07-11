// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDiamondCut.sol";

error LDiamond__AddressMustBeZero();
error LDiamond__FunctionAlreadyExists();
error LDiamond__ImmutableFunction();
error LDiamond__IncorrectAction();
error LDiamond__InexistentFacetCode();
error LDiamond__InexistentFunction();
error LDiamond__InitializationFailed(address init, bytes data);
error LDiamond__InvalidAddressZero();
error LDiamond__InvalidReplacementWithSameFunction();
error LDiamond__NoSelectors();
error LDiamond__OnlyOwner();

/// @title LDiamond
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Diamond library
/// @dev EIP-2535 "Diamond" standard
library LDiamond {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(IDiamondCut.FacetCut[] _cut, address _init, bytes _data);

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    ///////////////
    /// STORAGE ///
    ///////////////

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        /// @notice Address of the facet
        address facetAddress;
        /// @notice Position of the facet in `facetFunctionSelectors.functionSelectors` array
        uint96 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        /// @notice Selectors of functions
        bytes4[] functionSelectors;
        /// @notice Position of `facetAddress` in `facetAddresses` array
        uint256 facetAddressPosition;
    }

    struct DiamondStorage {
        /// @notice Position of selector in `facetFunctionSelectors.selectors` array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        /// @notice Addresses of the facets to selectors of the functions
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        /// @notice Facet addresses
        address[] facetAddresses;
        /// @notice Query if contract implements an interface
        mapping(bytes4 => bool) supportedInterfaces;
        /// @notice Owner of the contract
        address owner;
    }

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Set the storage of the diamond
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;

        /// @solidity memory-safe-assembly
        assembly {
            ds.slot := position
        }
    }

    /// @notice Update the owner of the diamond
    /// @param _owner New owner
    function updateContractOwner(address _owner) internal {
        DiamondStorage storage ds = diamondStorage();

        address oldOwner = ds.owner;

        ds.owner = _owner;

        emit OwnershipTransferred(oldOwner, _owner);
    }

    /// @notice Get the owner of the diamond
    function contractOwner() internal view returns (address owner_) {
        owner_ = diamondStorage().owner;
    }

    /// @notice Enforce is the owner of the diamond
    function enforceIsOwner() internal view {
        if (diamondStorage().owner != msg.sender) revert LDiamond__OnlyOwner();
    }

    /// @notice Perform a diamond cut
    /// @param _cut Diamond cut
    /// @param _init Address of the initialization contract
    /// @param _data Data
    function diamondCut(
        IDiamondCut.FacetCut[] memory _cut,
        address _init,
        bytes memory _data
    ) internal {
        for (uint256 facetIndex; facetIndex < _cut.length; ) {
            IDiamondCut.FacetCutAction action = _cut[facetIndex].action;

            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _cut[facetIndex].facetAddress,
                    _cut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _cut[facetIndex].facetAddress,
                    _cut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _cut[facetIndex].facetAddress,
                    _cut[facetIndex].functionSelectors
                );
            } else {
                revert LDiamond__IncorrectAction();
            }
            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++facetIndex;
            }
        }

        emit DiamondCut(_cut, _init, _data);

        initializeDiamondCut(_init, _data);
    }

    /// @notice Add functions to the diamond
    /// @param _facet Address of the facet
    /// @param _selectors Selectors of the facet
    function addFunctions(address _facet, bytes4[] memory _selectors) internal {
        if (_selectors.length == 0) revert LDiamond__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facet == address(0)) revert LDiamond__InvalidAddressZero();

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facet].functionSelectors.length
        );

        /// @notice Add a new facet address if it does not exists already

        if (selectorPosition == 0) addFacet(ds, _facet);

        for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
            bytes4 selector = _selectors[selectorIndex];

            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress != address(0))
                revert LDiamond__FunctionAlreadyExists();

            addFunction(ds, selector, selectorPosition, _facet);

            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++selectorIndex;
                ++selectorPosition;
            }
        }
    }

    /// @notice Replace functions inside the diamond
    /// @param _facet Address of the facet
    /// @param _selectors Selectors of the facet
    function replaceFunctions(address _facet, bytes4[] memory _selectors)
        internal
    {
        if (_selectors.length == 0) revert LDiamond__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facet == address(0)) revert LDiamond__InvalidAddressZero();

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facet].functionSelectors.length
        );

        /// @notice Add a new facet address if it does not exists already

        if (selectorPosition == 0) addFacet(ds, _facet);

        for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
            bytes4 selector = _selectors[selectorIndex];

            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress == _facet)
                revert LDiamond__InvalidReplacementWithSameFunction();

            removeFunction(ds, oldFacetAddress, selector);
            
            addFunction(ds, selector, selectorPosition, _facet);

            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++selectorIndex;
                ++selectorPosition;
            }
        }
    }

    /// @notice Remove functions inside the diamond
    /// @param _facet Address of the facet
    /// @param _selectors Selectors of the facet
    function removeFunctions(address _facet, bytes4[] memory _selectors)
        internal
    {
        if (_selectors.length == 0) revert LDiamond__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facet != address(0)) revert LDiamond__AddressMustBeZero();

        for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
            bytes4 selector = _selectors[selectorIndex];

            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            removeFunction(ds, oldFacetAddress, selector);

            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++selectorIndex;
            }

        }
    }

    /// @notice Add facet to the diamond
    /// @param ds DiamondStorage
    /// @param _facet Address of the diamond
    function addFacet(DiamondStorage storage ds, address _facet) internal {
        enforceHasContractCode(_facet);

        ds.facetFunctionSelectors[_facet].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facet);
    }

    /// @notice Add a function to the diamond
    /// @param ds DiamondStorage
    /// @param _selector Selector of the function
    /// @param _positon Position of the selector
    /// @param _facet Address of the function
    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _positon,
        address _facet
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _positon;
        ds.facetFunctionSelectors[_facet].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facet;
    }

    /// @notice Remove a function from the diamond
    /// @param ds DiamondStorage
    /// @param _facet Address of the facet
    /// @param _selector Selector of the function
    function removeFunction(
        DiamondStorage storage ds,
        address _facet,
        bytes4 _selector
    ) internal {
        if (_facet == address(0)) revert LDiamond__InexistentFunction();

        /// @notice An immutable function is defined directly inside the diamond
        if (_facet == address(this)) revert LDiamond__ImmutableFunction();

        /// @notice Replaces selector with the last selector, then deletes the last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facet]
            .functionSelectors
            .length - 1;

        /// @notice Replaces `_selector` with `lastSelector`, if not, they are not the same
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facet]
                .functionSelectors[lastSelectorPosition];

            ds.facetFunctionSelectors[_facet].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }

        /// @notice Deletes the last selector

        ds.facetFunctionSelectors[_facet].functionSelectors.pop();

        delete ds.selectorToFacetAndPosition[_selector];

        /// @notice Deletes the facet address if there are no more selectors for the facet address
        if (lastSelectorPosition == 0) {
            /// @notice Replaces facet address with the last facet address, then deletes the last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facet]
                .facetAddressPosition;

            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];

                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }

            ds.facetAddresses.pop();

            delete ds.facetFunctionSelectors[_facet].facetAddressPosition;
        }
    }

    /// @notice Initialize diamond cut
    /// @param _init Address of the initialization contract
    /// @param _data Data
    function initializeDiamondCut(address _init, bytes memory _data) internal {
        if (_init == address(0)) return;

        enforceHasContractCode(_init);

        (bool success, bytes memory error) = _init.delegatecall(_data);

        if (!success) {
            if (error.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let dataSize := mload(error)

                    revert(add(32, error), dataSize)
                }
            } else {
                revert LDiamond__InitializationFailed(_init, _data);
            }
        }
    }

    /// @notice Enforce contract has code
    /// @param _contract Address of the contract
    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;

        /// @solidity memory-safe-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }

        if (contractSize == 0) revert LDiamond__InexistentFacetCode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDiamondCut
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @dev EIP-2535 "Diamond" standard
interface IDiamondCut {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(FacetCut[] cut, address init, bytes data);

    ///////////////
    /// STORAGE ///
    ///////////////

    /// ACTIONS

    /// Add     - 0
    /// Replace - 1
    /// Remove  - 2

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /////////////
    /// LOGIC ///
    /////////////

    function diamondCut(
        FacetCut[] calldata cut,
        address init,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { LDiamond } from "clouds/diamond/LDiamond.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppStorage, UserData, Season } from "../libraries/AppStorage.sol";
import { IEmissionsManager } from "../interfaces/IEmissionsManager.sol";

error DiamondManagerFacet__Not_Owner();
error DiamondManagerFacet__Invalid_Address();
error DiamondManagerFacet__Invalid_Input();
error DiamondManagerFacet__Season_Not_Finished();
error DiamondManagerFacet_InvalidArgs_ChangeBoostPoints();

contract DiamondManagerFacet {
    AppStorage s;
    uint256 public constant TOTAL_SHARES = 10_000;

    event BoostFeeWithdrawn(address indexed to, uint256 amount);
    event DepositTokenSet(address indexed token);
    event SeasonIdSet(uint256 indexed seasonId);
    event DepositFeeSet(uint256 fee);
    event StratosphereAddressSet(address indexed stratosphereAddress);
    event RewardsControllerAddressSet(address indexed rewardsControllerAddress);
    event SeasonEndTimestampSet(uint256 indexed season, uint256 endTimestamp);
    event DepositFeeReceiversSet(address[] receivers, uint256[] proportion);
    event BoostFeeReceiversSet(address[] receivers, uint256[] proportion);
    event ClaimFeeReceiversSet(address[] receivers, uint256[] proportion);
    event RestakeFeeReceiversSet(address[] receivers, uint256[] proportion);
    event VapeClaimedForSeason(uint256 indexed seasonId);
    event EmissionsManagerSet(address indexed emissionManager);
    event UnlockTimestampDiscountForStratosphereMemberSet(uint256 indexed tier, uint256 discountPoints);
    event UnlockFeeSet(uint256 fee);
    event UnlockFeeReceiversSet(address[] receivers, uint256[] proportion);
    event SeasonStarted(uint256 indexed seasonId, uint256 rewardTokenToDistribute);
    event SeasonEnded(uint256 indexed seasonId, uint256 rewardTokenDistributed);

    modifier onlyOwner() {
        if (msg.sender != LDiamond.contractOwner()) {
            revert DiamondManagerFacet__Not_Owner();
        }
        _;
    }

    modifier validAddress(address token) {
        if (token == address(0)) {
            revert DiamondManagerFacet__Invalid_Address();
        }
        _;
    }

    function setDepositToken(address token) external validAddress(token) onlyOwner {
        s.depositToken = token;
        emit DepositTokenSet(token);
    }

    function setCurrentSeasonId(uint256 seasonId) external onlyOwner {
        s.currentSeasonId = seasonId;
        emit SeasonIdSet(seasonId);
    }

    function setStratosphereAddress(address stratosphereAddress) external validAddress(stratosphereAddress) onlyOwner {
        s.stratosphereAddress = stratosphereAddress;
        emit StratosphereAddressSet(stratosphereAddress);
    }

    function setSeasonEndTimestamp(uint256 seasonId, uint256 timestamp) external onlyOwner {
        s.seasons[seasonId].endTimestamp = timestamp;
        emit SeasonEndTimestampSet(seasonId, timestamp);
    }

    function setBoostFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner {
        if (receivers.length != proportion.length) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        uint256 totalShares = 0;
        for (uint256 i; i < proportion.length; i++) {
            totalShares += proportion[i];
        }
        if (totalShares != TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.boostFeeReceivers = receivers;
        s.boostFeeReceiversShares = proportion;
        emit BoostFeeReceiversSet(receivers, proportion);
    }

    function setUnlockFeeReceivers(address[] memory receivers, uint256[] memory proportion) external onlyOwner {
        if (receivers.length != proportion.length) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        uint256 totalShares = 0;
        for (uint256 i; i < proportion.length; i++) {
            totalShares += proportion[i];
        }
        if (totalShares != TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.unlockFeeReceivers = receivers;
        s.unlockFeeReceiversShares = proportion;
        emit UnlockFeeReceiversSet(receivers, proportion);
    }

    function setRewardToken(address token) external validAddress(token) onlyOwner {
        s.rewardToken = token;
    }

    function startNewSeason(uint256 _rewardTokenToDistribute) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp >= block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        uint256 newSeasonId = _currentSeason + 1;
        s.currentSeasonId = newSeasonId;
        Season storage season = s.seasons[newSeasonId];

        season.id = newSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = block.timestamp + 25 days;
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;

        emit SeasonStarted(newSeasonId, _rewardTokenToDistribute);
    }

    function startNewSeasonWithDuration(uint256 _rewardTokenToDistribute, uint8 _durationDays) external onlyOwner {
        uint256 _currentSeason = s.currentSeasonId;
        if (_currentSeason != 0 && s.seasons[_currentSeason].endTimestamp >= block.timestamp) {
            revert DiamondManagerFacet__Season_Not_Finished();
        }
        s.currentSeasonId = _currentSeason + 1;
        Season storage season = s.seasons[s.currentSeasonId];
        season.id = s.currentSeasonId;
        season.startTimestamp = block.timestamp;
        season.endTimestamp = block.timestamp + (_durationDays * 1 days);
        season.rewardTokensToDistribute = _rewardTokenToDistribute;
        season.rewardTokenBalance = _rewardTokenToDistribute;

        emit SeasonStarted(s.currentSeasonId, _rewardTokenToDistribute);
    }

    //this function is added to fix the points, it's temporary
    function changeBoostPoints(address[] memory addresses, uint256[] memory newBoostPoints) external onlyOwner {
        if (addresses.length != newBoostPoints.length) revert DiamondManagerFacet_InvalidArgs_ChangeBoostPoints();

        uint256 difference = 0;
        uint256 currentSeasonId = s.currentSeasonId;

        for (uint256 i; i < addresses.length; i++) {
            UserData storage _userData = s.usersData[currentSeasonId][addresses[i]];
            uint256 newBoostPoint = newBoostPoints[i];
            if (_userData.depositAmount == 0) revert DiamondManagerFacet_InvalidArgs_ChangeBoostPoints();
            uint256 currentBoostPoints = _userData.boostPoints;

            //current boost point is greater than or equal to newBoostPoint, I'm assuming we'll remove function later, and this function cannot be used to increase boost point
            difference += currentBoostPoints - newBoostPoint;

            _userData.boostPoints = newBoostPoint;
        }
        s.seasons[currentSeasonId].totalPoints -= difference;
    }

    function getRewardTokenToDistribute(uint256 _seasonId) external view returns (uint256) {
        return s.seasons[_seasonId].rewardTokensToDistribute;
    }

    function claimTokensForSeason() external onlyOwner {
        IEmissionsManager(s.emissionsManager).mintLiquidMining();
        emit VapeClaimedForSeason(s.currentSeasonId);
    }

    function setEmissionsManager(address _emissionManager) external onlyOwner {
        if (_emissionManager == address(0)) {
            revert DiamondManagerFacet__Invalid_Address();
        }
        s.emissionsManager = _emissionManager;
        emit EmissionsManagerSet(_emissionManager);
    }

    function getUserDepositAmount(address user, uint256 seasonId) external view returns (uint256, uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return (_userData.depositAmount, _userData.depositPoints);
    }

    function getUserClaimedRewards(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.amountClaimed;
    }

    function getRewardTokenBalancePool(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].rewardTokenBalance;
    }

    function getSeasonTotalPoints(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalPoints;
    }

    function getSeasonTotalClaimedRewards(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalClaimAmount;
    }

    function getUserTotalPoints(uint256 seasonId, address user) external view returns (uint256) {
        return s.usersData[seasonId][user].depositPoints + s.usersData[seasonId][user].boostPoints;
    }

    function getPendingWithdrawals(address feeReceiver, address token) external view returns (uint256) {
        return s.pendingWithdrawals[feeReceiver][token];
    }

    function getDepositAmountOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.depositAmount;
    }

    function getDepositPointsOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.depositPoints;
    }

    function getTotalDepositAmountOfSeason(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalDepositAmount;
    }

    function getTotalPointsOfSeason(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].totalPoints;
    }

    function setUnlockTimestampDiscountForStratosphereMember(
        uint256 tier,
        uint256 discountBasisPoints
    ) external onlyOwner {
        s.unlockTimestampDiscountForStratosphereMembers[tier] = discountBasisPoints;
        emit UnlockTimestampDiscountForStratosphereMemberSet(tier, discountBasisPoints);
    }

    function setUnlockFee(uint256 fee) external onlyOwner {
        if (fee > TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.unlockFee = fee;
        emit UnlockFeeSet(fee);
    }

    function setBoostFee(uint256 boostLevel, uint256 boostFee) external onlyOwner {
        if (boostFee > TOTAL_SHARES) {
            revert DiamondManagerFacet__Invalid_Input();
        }
        s.boostLevelToFee[boostLevel] = boostFee;
    }

    function setBoostPercentTierLevel(uint256 tier, uint256 level, uint256 percent) external onlyOwner {
        s.boostPercentFromTierToLevel[tier][level] = percent;
    }

    function getUserPoints(address user, uint256 seasonId) external view returns (uint256, uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return (_userData.depositPoints, _userData.boostPoints);
    }

    function getUserLastBoostClaimedAmount(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.lastBoostClaimAmount;
    }

    function getUnlockAmountOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.unlockAmount;
    }

    function getUnlockTimestampOfUser(address user, uint256 seasonId) external view returns (uint256) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.unlockTimestamp;
    }

    function getCurrentSeasonId() external view returns (uint256) {
        return s.currentSeasonId;
    }

    function getSeasonEndTimestamp(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].endTimestamp;
    }

    function getWithdrawRestakeStatus(address user, uint256 seasonId) external view returns (bool) {
        UserData storage _userData = s.usersData[seasonId][user];
        return _userData.hasWithdrawnOrRestaked;
    }

    function getUserDataForSeason(address user, uint256 seasonId) external view returns (UserData memory) {
        return s.usersData[seasonId][user];
    }

    function getUserDataForCurrentSeason(address user) external view returns (UserData memory) {
        return s.usersData[s.currentSeasonId][user];
    }

    function getCurrentSeasonData() external view returns (Season memory) {
        return s.seasons[s.currentSeasonId];
    }

    function getSeasonData(uint256 seasonId) external view returns (Season memory) {
        return s.seasons[seasonId];
    }

    function getStratosphereAddress() external view returns (address) {
        return s.stratosphereAddress;
    }

    function getRewardTokensToDistribute(uint256 seasonId) external view returns (uint256) {
        return s.seasons[seasonId].rewardTokensToDistribute;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IEmissionsManager {
    function mintLiquidMining() external;
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