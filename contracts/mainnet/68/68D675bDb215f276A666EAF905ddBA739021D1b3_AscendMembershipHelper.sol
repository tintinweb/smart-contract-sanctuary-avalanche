// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract Pool is Ownable {
    IERC20 public ASCEND;
    constructor(address _ASCEND) {
        ASCEND = IERC20(_ASCEND);
    }
    function pay(address _to, uint _amount) external onlyOwner returns (bool) {
        return ASCEND.transfer(_to, _amount);
    }
}

interface AscendMembershipManager {
    function totalPrice(uint256 amount, address from) external view returns(uint256);
    function createNode(address account) external;
    function claim(address account, uint256 _id) external returns (uint);
    function getTaxFeeAscend(address from) external view returns (uint256);
    function getTaxFeePlatinum() external view returns (uint256);
    function getTaxFeeInfinite() external view returns (uint256);
    function getTaxFeeMeta(address from) external view returns (uint256);
    function getTaxFeeBase() external view returns (uint256);
    function getTaxFeeTreasury() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function migrateNodes( uint64[] memory _claims, address _to) external;
    function getMembershipsOf(address _account) external view returns (uint256[] memory);
}

interface AscendMembershipManagerV1 {
   function ownerOf(uint256 tokenId) external view returns (address);
   function getClaimOf(uint256 _id) external view returns (uint64);
   function transferFrom(address from, address to, uint256 tokenId) external;
   function balanceOf(address owner) external view returns (uint256 balance);
   function getMembershipsOf(address _account) external view returns (uint256[] memory);
}
interface PlatinumManager is IERC20 {
  function getPlatinumsOf(address _account) external view returns (uint256[] memory);
  function claim(address account, uint256 _id) external returns (uint);
  function nodeAscendMembershipPrice() external returns (uint256);
}
interface InfiniteManager is IERC20 {
  function getInfinitesOf(address _account) external view returns (uint256[] memory);
  function claim(address account, uint256 _id) external returns (uint);
  function nodeAscendMembershipPrice() external returns (uint256);
  function nodePlatinumPrice() external returns (uint256);
}
interface MetaManager is IERC20 {
  function getMetasOf(address _account) external view returns (uint256[] memory);
  function claim(address account, uint256 _id) external returns (uint);
  function nodeAscendMembershipPrice() external returns (uint256);
  function nodeInfinitePrice() external returns (uint256);
}

interface RewardsCalculator {
  function calculateAllRewards(address from) external view returns (uint);
}

contract AscendMembershipHelper is Ownable {

    IERC20 public ASCEND;

    AscendMembershipManager public amsManager;
    PlatinumManager public platinumManager;
    InfiniteManager public infiniteManager;
    MetaManager public metaManager;

    AscendMembershipManagerV1 public amsManagerV1;

    RewardsCalculator public calculator;

    address  public metaFundWallet;
    address  public treasuryWallet;
    address  public liquidityWallet;

    Pool public pool;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint claimFeePrecision = 1000;

    uint public swapThreshold = 10; //upgradeable
    uint public maxWalletL1 = 30;  //upgradeable
    uint public maxWalletL2 = 40;  //upgradeable
    uint public maxWalletL3 = 50;  //upgradeable
    uint public maxWalletL4 = 80;  //upgradeable
    uint public maxTX = 20; //upgradeable
    uint256 maxtTokens = 20000000;

    using SafeMath for uint;
    using SafeMath for uint256;

    struct NodeRatios {
        uint16 poolFee;
        uint16 liquidityFee;
        uint16 treasuryFee;
        uint16 total;
    }

    NodeRatios public _nodeRatios = NodeRatios({
        poolFee: 75, //rewards
        liquidityFee: 20,  //liquidity
        treasuryFee: 5, //treasury
        total: 100
    });

    struct ClaimRatios {
        uint16 poolClaimFee;
        uint16 treasuryFee;
        uint16 metaFundFee;
        uint16 total;
    }

    ClaimRatios public _claimRatios = ClaimRatios({
        poolClaimFee: 80,
        treasuryFee: 15,
        metaFundFee: 5,
        total: 100
    });

    struct ClaimRatiosWhale {
        uint16 poolClaimFee;
        uint16 treasuryFee;
        uint16 metaFundFee;
        uint16 liquidity;
        uint16 total;
    }

    ClaimRatiosWhale public _claimRatiosWhale = ClaimRatiosWhale({
        poolClaimFee: 30,
        treasuryFee: 50,
        metaFundFee: 10,
        liquidity: 10,
        total: 100
    });

    event ClaimAms(address from, uint256 amount);
    event ClaimPlatinum(address from, uint256 amount);
    event ClaimInfinite(address from, uint256 amount);
    event ClaimMeta(address from, uint256 amount);
    event CreateMultipleAms(address from, uint amount);
    event CreateMultipleAmsRewards(address from, uint amount);
    event ClaimAll(address from, uint256 amount);

    constructor( address _amsManager,
        address _ASCEND, address _treasuryWallet, address _metaFundWallet, address _liquidityWallet)  {
        amsManager = AscendMembershipManager(_amsManager);
        metaFundWallet = _metaFundWallet;
        treasuryWallet = _treasuryWallet;
        liquidityWallet = _liquidityWallet;
        ASCEND = IERC20(_ASCEND);
        pool = new Pool(_ASCEND);
    }

    function setAmsManagerV1(address _amsManagerV1 ) external onlyOwner {
        amsManagerV1 = AscendMembershipManagerV1(_amsManagerV1);
    }

    function setCalculator(address _calculator ) external onlyOwner {
        calculator = RewardsCalculator(_calculator);
    }

    function setManagers(address _amsManager, address _platinumMembershipManager, address _InfiniteManager, address _MetaManager) external onlyOwner {
        amsManager = AscendMembershipManager(_amsManager);
        platinumManager = PlatinumManager(_platinumMembershipManager);
        infiniteManager = InfiniteManager(_InfiniteManager);
        metaManager = MetaManager(_MetaManager);
    }

    function updatePoolAddress(address _pool) external onlyOwner {
        pool.pay(address(owner()), ASCEND.balanceOf(address(pool)));
        pool = new Pool(_pool);
    }

    function updateMaxWalletLevels(uint256 _maxWalletL1, uint256 _maxWalletL2,
      uint256 _maxWalletL3, uint256 _maxWalletL4) external onlyOwner {
        maxWalletL1 = _maxWalletL1;
        maxWalletL2 = _maxWalletL2;
        maxWalletL3 = _maxWalletL3;
        maxWalletL4 = _maxWalletL4;
    }

    function updateSwapThreshold(uint256 _swapThreshold) external onlyOwner {
        swapThreshold = _swapThreshold;
    }

    function updateMaxTX(uint256 _maxTX) external onlyOwner {
        maxTX = _maxTX;
    }

    function updateMetaFundWallet(address payable _metaFundWallet) external onlyOwner {
        metaFundWallet = _metaFundWallet;
    }

    function updateTreasuryWallet(address payable _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function updateLiquidityWallet(address payable _liquidityWallet) external onlyOwner {
        liquidityWallet = _liquidityWallet;
    }

    function setNodeRatios(uint16 _poolFee, uint16 _liquidityFee,uint16 _treasuryFee) external onlyOwner {
        _nodeRatios.poolFee = _poolFee;
        _nodeRatios.liquidityFee = _liquidityFee;
        _nodeRatios.treasuryFee = _treasuryFee;
        _nodeRatios.total = _poolFee + _liquidityFee + _treasuryFee;
    }

    function setClaimRatios(uint16 _poolClaimFee, uint16 _treasuryFee, uint16 _metaFundFee) external onlyOwner {
        _claimRatios.poolClaimFee = _poolClaimFee;
        _claimRatios.treasuryFee = _treasuryFee;
        _claimRatios.metaFundFee = _metaFundFee;
        _claimRatios.total = _poolClaimFee + _metaFundFee + _treasuryFee;
    }

    function setClaimRatiosWhales(uint16 _poolClaimFee, uint16 _treasuryFee, uint16 _metaFundFee, uint16 _liquidity) external onlyOwner {
        _claimRatiosWhale.poolClaimFee = _poolClaimFee;
        _claimRatiosWhale.treasuryFee = _treasuryFee;
        _claimRatiosWhale.metaFundFee = _metaFundFee;
        _claimRatiosWhale.liquidity = _liquidity;
    }

    function getMaxMembershipsOf(address _address) public view returns (uint256) {
        if (metaManager.balanceOf(_address) > 0) {
            return maxWalletL4;
        } else if (infiniteManager.balanceOf(_address) > 0) {
            return maxWalletL3;
        } if (platinumManager.balanceOf(_address) > 0) {
            return maxWalletL2;
        } else {
            return maxWalletL1;
        }
    }

    function contractSwap(uint256 numTokensToSwap) internal {
        if (_nodeRatios.total == 0) {
            return;
        }
        uint256 amountToRewardsPool = (numTokensToSwap * _nodeRatios.poolFee) / (_nodeRatios.total);
        if(amountToRewardsPool > 0) {
            ASCEND.transfer(address(pool), amountToRewardsPool);
        }
        uint256 amountToTreasury = (numTokensToSwap * _nodeRatios.treasuryFee) / (_nodeRatios.total);
        if(amountToTreasury > 0) {
            ASCEND.transfer(treasuryWallet, amountToTreasury);
        }
        uint256 amountToLiquidity = (numTokensToSwap * _nodeRatios.liquidityFee) / (_nodeRatios.total);
        if(amountToLiquidity > 0) {
            ASCEND.transfer(liquidityWallet, amountToTreasury);
        }
    }


    function migrateNodes(uint64[] memory userNodes) public {
        address sender = _msgSender();
        uint64[] memory _claims = new uint64[](userNodes.length);
        require(amsManager.balanceOf(sender) + userNodes.length <= maxWalletL4, "HELPER: Exceeds max memberships per wallet");
        for (uint256 i = 0; i < userNodes.length; i++) {
             require(sender ==  amsManagerV1.ownerOf(userNodes[i]), "You are not the owner of the Node" );
             _claims[i] = amsManagerV1.getClaimOf(userNodes[i]);
             amsManagerV1.transferFrom(_msgSender(), address(deadAddress), userNodes[i] );
        }
        amsManager.migrateNodes(_claims, sender);
    }

    function claimRewardsForCompoundAms(address sender, uint256 nodePrice ) public returns (uint256) {
        return claimRewardsForCompound(sender, nodePrice, 0, 0, 0);
    }

    function claimRewardsForCompoundPlatinum(address sender, uint256 nodePrice ) public returns (uint256) {
        uint256 ams = platinumManager.nodeAscendMembershipPrice();
        return claimRewardsForCompound(sender, nodePrice, ams, 0, 0);
    }

    function claimRewardsForCompoundInfinite(address sender, uint256 nodePrice ) public returns (uint256) {
        uint256 ams = infiniteManager.nodeAscendMembershipPrice();
        uint256 platinum = infiniteManager.nodePlatinumPrice();
        return claimRewardsForCompound(sender, nodePrice, ams, platinum, 0);
    }

    function claimRewardsForCompoundMeta(address sender, uint256 nodePrice ) public returns (uint256) {
        uint256 ams = metaManager.nodeAscendMembershipPrice();
        uint256 infinite = metaManager.nodeInfinitePrice();
        return claimRewardsForCompound(sender, nodePrice, ams, 0, infinite);
    }

    function claimRewardsForCompound(address sender, uint256 nodePrice, uint256 amsPrice, uint256 platinumPrice, uint256 infinitePrice) internal returns (uint256) {


            uint256 rewardAmount = 0;
            uint8 taxLayer = 1;

            uint256[] memory ams = amsManager.getMembershipsOf(sender);
            for (uint256 i = 0; i < ams.length; i++) {
              if (rewardAmount < nodePrice || i < amsPrice){
                rewardAmount = rewardAmount + amsManager.claim(sender, ams[i]);
              }
            }
            if (rewardAmount < nodePrice || platinumPrice > 0){
              uint256[] memory platinums = platinumManager.getPlatinumsOf(sender);
              for (uint256 i = 0; i < platinums.length; i++) {
                 if (rewardAmount < nodePrice || i < platinumPrice ){
                   rewardAmount = rewardAmount + platinumManager.claim(sender, platinums[i]);
                 }
              }
              taxLayer = 2;
            }
            if (rewardAmount < nodePrice || infinitePrice > 0){
              uint256[] memory infinites = infiniteManager.getInfinitesOf(sender);
              for (uint256 i = 0; i < infinites.length; i++) {
                if (rewardAmount < nodePrice || i < infinitePrice ){
                    rewardAmount = rewardAmount + infiniteManager.claim(sender, infinites[i]);
                }
              }
              taxLayer = 3;
            }
            if (rewardAmount < nodePrice ){
              uint256[] memory metas = metaManager.getMetasOf(sender);
              for (uint256 i = 0; i < metas.length; i++) {
                  if (rewardAmount < nodePrice ){
                    rewardAmount = rewardAmount + metaManager.claim(sender, metas[i]);
                  }
              }
              taxLayer = 4;
            }

            emit ClaimAll(sender, rewardAmount);
            if (rewardAmount > nodePrice){
                uint256 whaleTax = 0;
                if (taxLayer == 1){
                  whaleTax = amsManager.getTaxFeeAscend(sender);
                } else if (taxLayer == 2){
                  whaleTax = amsManager.getTaxFeePlatinum();
                } else if (taxLayer == 3){
                  whaleTax = amsManager.getTaxFeeInfinite();
                } else {
                  whaleTax = amsManager.getTaxFeeMeta(sender);
                }
                uint256 differenceA = rewardAmount - nodePrice;
                splitRewards(sender, differenceA, whaleTax);
            }
            return rewardAmount;
    }

    function createMultipleNodeWithRewards(uint amount) public {
        require(amount <= maxTX, "HELPER: Exceeds max memberships per transaction");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        require(amsManager.totalPrice( amount, _msgSender()) > 0, "HELPER: amsManager is not working");
        uint256 nodePrice = amsManager.totalPrice( amount, _msgSender()) * 10 ** 18;
        require(amsManager.balanceOf(sender) + amount <= getMaxMembershipsOf(sender), "HELPER: Exceeds max wallet amount");

        uint256 allRewards = calculator.calculateAllRewards(sender) * 10 ** 18;
        require(allRewards.add(ASCEND.balanceOf(sender))  >= nodePrice, "HELPER: Balance too low for creation.");
        require(ASCEND.allowance(sender, address(this)) + allRewards >= nodePrice,"HELPER: Not authorized to spend ASND");

        // Claim nodes AMS
        uint256 rewardsAmount = claimRewardsForCompoundAms( sender, nodePrice );

        if (nodePrice > rewardsAmount ){
            uint256 difference = nodePrice - rewardsAmount;
            ASCEND.transferFrom(sender, address(this), difference);
        }
        //  mint the AMS
        for (uint256 i = 0; i < amount; i++) {
            amsManager.createNode(sender);
        }
        emit CreateMultipleAmsRewards(sender, amount);
    }

    function createMultipleNodeWithTokens(uint amount) public {
        require(amount <= maxTX, "HELPER: Exceeds max memberships per transaction");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        require(amsManager.totalPrice( amount, _msgSender()) > 0, "HELPER: amsManager is not working");
        uint256 nodePrice = amsManager.totalPrice( amount, _msgSender()) * 10 ** 18;
        require(getMaxMembershipsOf(sender) > 0, "HELPER: Incorrect getMaxMembershipsOf, check the configuration");
        require(ASCEND.balanceOf(sender) >= nodePrice, "HELPER: Balance too low for creation.");
        require(amsManager.balanceOf(sender) + amount <= getMaxMembershipsOf(sender), "HELPER: Exceeds max wallet amount");
        require(ASCEND.allowance(sender, address(this)) >= nodePrice,"HELPER: Insuficiente allowance");
        ASCEND.transferFrom(_msgSender(), address(this),  nodePrice);
        for (uint256 i = 0; i < amount; i++) {
            amsManager.createNode(sender);
        }
        if ((ASCEND.balanceOf(address(this)) > swapThreshold)) {
            uint256 contractTokenBalance = ASCEND.balanceOf(address(this));
            contractSwap(contractTokenBalance);
        }
        emit CreateMultipleAms(sender, amount);
    }


    function calculateRewardsAmsAfterTaxes(address sender, uint256 rewardAmount ) public view returns (uint256) {
      uint256 whaleTax = amsManager.getTaxFeeAscend(sender);
      uint256 feeAmount = rewardAmount.mul(whaleTax).div(claimFeePrecision);
      uint256 feeAmountBase = rewardAmount.mul(amsManager.getTaxFeeBase()).div(claimFeePrecision);
      uint256 feeAmountTreasury = rewardAmount.mul(amsManager.getTaxFeeTreasury()).div(claimFeePrecision);
      return rewardAmount -feeAmount -feeAmountBase -feeAmountTreasury;
    }

    function calculateRewardsPlatinumAfterTaxes(uint256 rewardAmount ) public view returns (uint256) {
      uint256 whaleTax = amsManager.getTaxFeePlatinum();
      uint256 feeAmount = rewardAmount.mul(whaleTax).div(claimFeePrecision);
      uint256 feeAmountBase = rewardAmount.mul(amsManager.getTaxFeeBase()).div(claimFeePrecision);
      uint256 feeAmountTreasury = rewardAmount.mul(amsManager.getTaxFeeTreasury()).div(claimFeePrecision);
      return rewardAmount -feeAmount -feeAmountBase -feeAmountTreasury;
    }

    function calculateRewardaInfiniteAfterTaxes( uint256 rewardAmount ) public view returns (uint256) {
      uint256 whaleTax = amsManager.getTaxFeeInfinite();
      uint256 feeAmount = rewardAmount.mul(whaleTax).div(claimFeePrecision);
      uint256 feeAmountBase = rewardAmount.mul(amsManager.getTaxFeeBase()).div(claimFeePrecision);
      uint256 feeAmountTreasury = rewardAmount.mul(amsManager.getTaxFeeTreasury()).div(claimFeePrecision);
      return rewardAmount -feeAmount -feeAmountBase -feeAmountTreasury;
    }

    function calculateRewardaMetaAfterTaxes(address sender, uint256 rewardAmount ) public view returns (uint256) {
      uint256 whaleTax = amsManager.getTaxFeeMeta(sender);
      uint256 feeAmount = rewardAmount.mul(whaleTax).div(claimFeePrecision);
      uint256 feeAmountBase = rewardAmount.mul(amsManager.getTaxFeeBase()).div(claimFeePrecision);
      uint256 feeAmountTreasury = rewardAmount.mul(amsManager.getTaxFeeTreasury()).div(claimFeePrecision);
      return rewardAmount -feeAmount -feeAmountBase -feeAmountTreasury;
    }

    function splitRewards(address sender, uint256 rewardAmount, uint256 whaleTax ) internal {

      uint256 feeAmount = rewardAmount.mul(whaleTax).div(claimFeePrecision);
      uint256 feeAmountBase = rewardAmount.mul(amsManager.getTaxFeeBase()).div(claimFeePrecision);
      uint256 feeAmountTreasury = rewardAmount.mul(amsManager.getTaxFeeTreasury()).div(claimFeePrecision);
      uint256 realReward = rewardAmount -feeAmount -feeAmountBase -feeAmountTreasury;

      pool.pay(sender, realReward);

      uint256 amountToMetaFundWallet = (feeAmountBase * _claimRatios.metaFundFee) / (_claimRatios.total)
       + (feeAmount * _claimRatiosWhale.metaFundFee) / (_claimRatiosWhale.total);
      pool.pay(metaFundWallet, amountToMetaFundWallet);

      uint256 amountToCollectTreasury = (feeAmountBase * _claimRatios.treasuryFee) / (_claimRatios.total)
      + (feeAmount * _claimRatiosWhale.treasuryFee) / (_claimRatiosWhale.total)
      + feeAmountTreasury;
      pool.pay(treasuryWallet, amountToCollectTreasury);

      uint256 amountToLiquidityWallet = (feeAmount * _claimRatiosWhale.liquidity) / (_claimRatiosWhale.total);
      pool.pay(liquidityWallet, amountToLiquidityWallet);
    }

    function claimAms(uint64[] calldata _nodes) public {
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodes.length; i++) {
            rewardAmount = rewardAmount + amsManager.claim(_msgSender(), _nodes[i]);
        }
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        uint256 whaleTax = amsManager.getTaxFeeAscend(sender);
        require(whaleTax > 0, "Helper: Error, invalid Claim Fee Tax");
        splitRewards(sender, rewardAmount, whaleTax);
        emit ClaimAms(sender, rewardAmount);
    }


    function claimPlatinum(uint64[] calldata _nodes) public {
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodes.length; i++) {
            rewardAmount = rewardAmount + platinumManager.claim(_msgSender(), _nodes[i]);
        }
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");

        uint256 whaleTax = amsManager.getTaxFeePlatinum();
        require(whaleTax > 0, "Helper: Error, invalid Claim Fee Tax");
        splitRewards(sender, rewardAmount, whaleTax);
        emit ClaimPlatinum(sender, rewardAmount);
    }

    function claimInfinite(uint64[] calldata _nodes) public {
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodes.length; i++) {
            rewardAmount = rewardAmount + infiniteManager.claim(_msgSender(), _nodes[i]);
        }
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        uint256 whaleTax = amsManager.getTaxFeeInfinite();
        require(whaleTax > 0, "Helper: Error, invalid Claim Fee Tax");
        splitRewards(sender, rewardAmount, whaleTax);

        emit ClaimInfinite(sender, rewardAmount);
    }

    function claimMeta(uint64[] calldata _nodes) public {
        address sender = _msgSender();
        require(sender != address(0), "HELPER: creation from the zero address");
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < _nodes.length; i++) {
            rewardAmount = rewardAmount + metaManager.claim(_msgSender(), _nodes[i]);
        }
        require(rewardAmount > 0,"HELPER: You don't have enough reward to cash out");
        uint256 whaleTax = amsManager.getTaxFeeMeta(sender);
        require(whaleTax > 0, "Helper: Error, invalid Claim Fee Tax");
        splitRewards(sender, rewardAmount, whaleTax);
        emit ClaimMeta(sender, rewardAmount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}