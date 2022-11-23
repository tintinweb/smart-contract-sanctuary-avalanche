// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseVotingStrategy} from '../interfaces/IBaseVotingStrategy.sol';

abstract contract BaseVotingStrategy is IBaseVotingStrategy {
  uint128 public constant WEIGHT_PRECISION = 100;

  /**
  * @dev on the constructor we get all the voting assets and emit the different
         asset configurations
  */
  constructor() {
    address[] memory votingAssetList = getVotingAssetList();

    for (uint256 i; i < votingAssetList.length; i++) {
      VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(
        votingAssetList[i]
      );
      emit VotingAssetAdd(
        votingAssetList[i],
        votingAssetConfig.baseStorageSlot,
        votingAssetConfig.weight
      );
    }
  }

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetList() public view virtual returns (address[] memory);

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetConfig(address asset)
    public
    view
    virtual
    returns (VotingAssetConfig memory);

  /// @inheritdoc IBaseVotingStrategy
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power
  ) public view virtual returns (uint256) {
    VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(asset);
    if (votingAssetConfig.baseStorageSlot == baseStorageSlot) {
      return (power * votingAssetConfig.weight) / WEIGHT_PRECISION;
    }
    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseVotingStrategy} from '../BaseVotingStrategy.sol';

contract L2VotingStrategy is BaseVotingStrategy {
  // TODO: set correct ones
  address public constant AAVE = 0x57ce2286A84b3757B7D0286eC4B77CF1dCEd660d; // TODO: Goerli aave token
  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  //  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  //  address public constant A_AAVE = 0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;
  //  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  function getVotingAssetList()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory votingAssets = new address[](2);

    votingAssets[0] = AAVE;
    votingAssets[1] = STK_AAVE;
    //    votingAssets[1] = A_AAVE;

    return votingAssets;
  }

  function getVotingAssetConfig(address asset)
    public
    pure
    override
    returns (VotingAssetConfig memory)
  {
    VotingAssetConfig memory votingAssetConfig;

    if (
      asset == AAVE || asset == STK_AAVE
      //      || asset == A_AAVE
    ) {
      votingAssetConfig.weight = WEIGHT_PRECISION;
    }

    return votingAssetConfig;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseVotingStrategy {
  /**
   * @dev object storing the information of the asset used for the voting strategy
   * @param baseStorageSlot initial slot for the balance of the specified token.
            From that slot, by adding the address of the user, the correct balance can be taken.
   * @param weight determines the importance of the token on the vote.
   */
  struct VotingAssetConfig {
    uint128 baseStorageSlot;
    uint128 weight;
  }

  /**
   * @dev emitted when an asset is added for the voting strategy
   * @param asset address of the token to be added
   * @param storageSlot storage position of the start of the balance mapping
   * @param weight percentage of importance that the asset will have in the vote
   */
  event VotingAssetAdd(
    address indexed asset,
    uint128 storageSlot,
    uint128 weight
  );

  /**
   * @dev method to get the precision of the weights used.
   * @return the weight precision
   */
  function WEIGHT_PRECISION() external view returns (uint128);

  /**
   * @dev method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @dev method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the base storage slot, and the weight
   */
  function getVotingAssetConfig(address asset)
    external
    view
    returns (VotingAssetConfig memory);

  /**
   * @dev method to get the power of an asset, after applying the configured weight for said asset
   * @param asset address of the token to get the weighted power
   * @param baseStorageSlot storage position of the start of the balance mapping
   * @param power balance of a determined asset to be weighted for the vote
   */
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power
  ) external view returns (uint256);
}