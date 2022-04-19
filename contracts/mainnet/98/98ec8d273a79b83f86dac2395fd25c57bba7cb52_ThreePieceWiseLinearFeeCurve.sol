// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IFeeCurve.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   ,[email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&&.,,      ,,**.&&&&&@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@,               ..,,,,,,,,,&@@@@@@@@@@
// @@@@@@,,,,,,&@@@@@@@@&                       ,,,,,&@@@@@@@@@
// @@@&,,,,,,,,@@@@@@@@@                        ,,,,,*@@@/@@@@@
// @@,*,*,*,*#,,*,&@@@@@   $$          $$       *,,,  ***&@@@@@
// @&***********(@@@@@@&   $$          $$       ,,,%&. & %@@@@@
// @(*****&**     &@@@@#                        *,,%  ,#%@*&@@@
// @... &             &                         **,,*&,(@*,*,&@
// @&,,.              &                         *,*       **,,@
// @@@,,,.            *                         **         ,*,,
// @@@@@,,,...   .,,,,&                        .,%          *,*
// @@@@@@@&/,,,,,,,,,,,,&,,,,,.         .,,,,,,,,.           *,
// @@@@@@@@@@@@&&@(,,,,,(@&&@@&&&&&%&&&&&%%%&,,,&            .(
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,,,,,&             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,,,,,&             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/            &             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&              &             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&      ,,,@@@&  &  &&  .&( &#%
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&%#**@@@&*&*******,,,,,**
//
//  $$\     $$\          $$\     $$\       $$$$$$$$\ $$\                                                   
//  \$$\   $$  |         $$ |    \__|      $$  _____|\__|                                                  
//   \$$\ $$  /$$$$$$\ $$$$$$\   $$\       $$ |      $$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\  
//    \$$$$  /$$  __$$\\_$$  _|  $$ |      $$$$$\    $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\ 
//     \$$  / $$$$$$$$ | $$ |    $$ |      $$  __|   $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
//      $$ |  $$   ____| $$ |$$\ $$ |      $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
//      $$ |  \$$$$$$$\  \$$$$  |$$ |      $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\ 
//      \__|   \_______|  \____/ \__|      \__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|

/** 
 * @notice This contract is used to calculate the variable fee for an input of tokens. 
 * Uses three linear piecewise functions to calculate the fee, and the average 
 * of the system collateralization by that asset before and after the tx. 
 */
contract ThreePieceWiseLinearFeeCurve is IFeeCurve, Ownable {
    using SafeMath for uint256;

    string public name;
    uint256 public m1;
    uint256 public b1;
    uint256 public cutoff1;
    uint256 public m2;
    uint256 public b2;
    bool public b2Negative;
    uint256 public cutoff2;
    uint256 public m3;
    uint256 public b3;
    bool public b3Negative;
    uint256 public decayTime;

    uint public lastFeeTime;
    uint public lastFeePercent;
    uint public dollarCap;
    address private controllerAddress;
    bool private addressesSet;
    bool private paramsInitialized;

    /** 
     * f1 = m1 * x + b1
     * f1 meets f2 at cutoff1, which is defined by that intersection point and slope m2
     * f2 meets f3 at cutoff2, which is defined by that intersection point and slope m3
     * Everything in terms of actual * 1e18, scaled by 1e18 because can't do percentages
     * Decimal precision = 1e18
     */

    /** 
     * Function for setting slopes and intercepts of linear functions used for fee calculations. 
     */
    function adjustParams(string memory _name, uint256 _m1, uint256 _b1, uint256 _m2, uint256 _cutoff1, uint256 _m3, uint256 _cutoff2, uint _dollarCap, uint _decayTime) external onlyOwner {
        require(_cutoff1 <= _cutoff2, "Cutoffs must be increasing");
        require(_m2 >= _m1, "slope cannot decrease");
        require(_m3 >= _m2, "slope cannot decrease");

        name = _name;
        m1 = _m1;
        b1 = _b1;
        m2 = _m2;
        uint256 m1Val = _m1.mul(_cutoff1).div(1e18).add(_b1);
        uint256 m2Val = _m2.mul(_cutoff1).div(1e18);
        if (m2Val > m1Val) {
            b2Negative = true;
            b2 = m2Val.sub(m1Val);
        } else {
            b2 = m1Val.sub(m2Val);
        }
        // b2 = _m1.mul(_cutoff1).div(1e18).add(_b1).sub(_m2.mul(_cutoff1).div(1e18));
        cutoff1 = _cutoff1;
        m3 = _m3;
        m2Val = _m2.mul(_cutoff2).div(1e18).add(b2);
        uint256 m3Val = _m3.mul(_cutoff2).div(1e18);
        if (m3Val > m2Val) {
            b3Negative = true;
            b3 = m3Val.sub(m2Val);
        } else {
            b3 = m2Val.sub(m3Val);
        }
        // b3 = _m2.mul(_cutoff2).div(1e18).add(b2).sub(_m3.mul(_cutoff2).div(1e18));
        cutoff2 = _cutoff2;
        dollarCap = _dollarCap; // Cap in VC terms of max of this asset. dollarCap = 0 means no cap.
        decayTime = _decayTime; // like 5 days = 432000 in unix time. 
        paramsInitialized = true;
    }

    // Set the controller address so that the fee can only be updated by controllerAddress
    function setAddresses(address _controllerAddress) external override onlyOwner {
        require(!addressesSet, "addresses already set");
        controllerAddress = _controllerAddress;
        addressesSet = true;
    }

    function initialized() external view override returns (bool) {
        return addressesSet && paramsInitialized;
    }

    // Set the decay time in seconds
    function setDecayTime(uint _decayTime) external override onlyOwner {
        decayTime = _decayTime;
    }

    // Set the dollar cap in VC terms
    function setDollarCap(uint _dollarCap) external override onlyOwner {
        dollarCap = _dollarCap;
    }

    // Gets the fee cap and time currently. Used for setting new values for next fee curve. 
    function getFeeCapAndTime() external override view returns (uint256, uint256) {
        return (lastFeePercent, lastFeeTime);
    }

    // Function for setting the old fee curve's last fee cap / value to the new fee cap / value. 
    // Called only by controller.
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external override {
        require(msg.sender == controllerAddress, "caller must be controller");
        lastFeePercent = _lastFeePercent;
        lastFeeTime = _lastFeeTime;
    }

    /** 
     * Function for getting the fee for a particular collateral type based on percent of YUSD backed
     * by this asset. 
     * @param _collateralVCInput is how much collateral is being input by the user into the system
     * @param _totalCollateralVCBalance is how much collateral is in the system
     * @param _totalVCBalancePost is how much VC the system for all collaterals after all adjustments (additions, subtractions)
     */
    function getFee(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) override external view returns (uint256 feeCalculated) {
        feeCalculated = _getFee(_collateralVCInput, _totalCollateralVCBalance, _totalVCBalancePre, _totalVCBalancePost);
    }

    // Called only by controller. Updates the last fee time and last fee percent
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) override external returns (uint256 feeCalculated) {
        require(msg.sender == controllerAddress, "Only controller can update fee");
        feeCalculated = _getFee(_collateralVCInput, _totalCollateralVCBalance, _totalVCBalancePre, _totalVCBalancePost);
        lastFeeTime = block.timestamp;
        lastFeePercent = feeCalculated;
    }

    function _getFee(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) internal view returns (uint256 feeCalculated) {
        // If dollarCap == 0, then it is not capped. Otherwise, then the total + the total input must be less than the cap.
        uint256 cachedDollarCap = dollarCap;
        if (cachedDollarCap != 0) {
            require(_totalCollateralVCBalance.add(_collateralVCInput) <= cachedDollarCap, "Collateral input exceeds cap");
        }

        uint feePre = _getFeePoint(_totalCollateralVCBalance, _totalVCBalancePre);
        uint feePost = _getFeePoint(_totalCollateralVCBalance.add(_collateralVCInput), _totalVCBalancePost);

        uint decayedLastFee = calculateDecayedFee();
        // Cap fee at 100%, but also at least decayedLastFee
        feeCalculated = _min(1e18, _max((feePre.add(feePost)).div(2), decayedLastFee));
    }

    /** 
     * Function for getting the fee for a particular collateral type based on percent of YUSD backed
     * by this asset. 
     */
    function _getFeePoint(uint256 _collateralVCBalance, uint256 _totalVCBalance) internal view returns (uint256) {
        if (_totalVCBalance == 0) {
            return 0;
        }
        // percent of all VC backed by this collateral * 1e18
        uint256 percentBacked = _collateralVCBalance.mul(1e18).div(_totalVCBalance);
        require(percentBacked <= 1e18, "percent backed out of bounds");

        if (percentBacked <= cutoff1) { // use function 1
            return _min(m1.mul(percentBacked).div(1e18).add(b1), 1e18);
        } else if (percentBacked <= cutoff2) { // use function 2
            if (b2Negative) {
                return _min(m2.mul(percentBacked).div(1e18).sub(b2), 1e18);
            } else {
                return _min(m2.mul(percentBacked).div(1e18).add(b2), 1e18);
            }
        } else { // use function 3
            if (b3Negative) {
                return _min(m3.mul(percentBacked).div(1e18).sub(b3), 1e18);
            } else {
                return _min(m3.mul(percentBacked).div(1e18).add(b3), 1e18);
            }
        }
    }

    function calculateDecayedFee() public override view returns (uint256 fee) {
        uint256 timeSinceLastFee = block.timestamp.sub(lastFeeTime);
        // Decay within bounds of decay time
        uint256 cachedDecayTime = decayTime;
        if (timeSinceLastFee <= cachedDecayTime) {
            // Linearly decay based on time since last fee. 
            fee = lastFeePercent.sub(lastFeePercent.mul(timeSinceLastFee).div(cachedDecayTime));
        } else {
            // If it has been longer than decay time, then reset fee to 0.
            fee = 0;
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? b : a;
    }
}