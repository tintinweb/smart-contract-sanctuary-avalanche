// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.7.0;

import "SafeMath.sol";

contract VaultConfig {
    using SafeMath for uint256;

    address public governance = 0x1F0F7336d624656b71367A1F330094496ccb03ed;
    address public pendingGovernance;
    address public management;
    address public guardian;
    address public partner;
    address public partnerFeeRecipient;
    address public approver;
    address public rewards;

    mapping (address => bool) isWhitelisted;

    mapping (address => uint256) partnerFees;
    mapping (address => uint256) managementFees;
    mapping (address => uint256) performanceFees;

    uint256 public constant MAX_BPS = 10000;

    event Configured (
        address indexed partner, address indexed management, address guardian, address rewards, address approver
        );
    event PerformanceFeeUpdated(address indexed vault, uint256 newFee);
    event ManagementUpdated(address indexed from, address indexed management);
    event ManagementFeeUpdated(address indexed vault, uint256 newFee);
    event PartnerFeeUpdated(address indexed vault, uint256 newFee);
    event PartnerUpdated(address indexed from, address indexed partner);
    event PartnerFeeRecipientUpdated (address indexed from, address indexed recipient);
    event ApproverUpdated (address indexed from, address indexed approver);
    event GuardianUpdated (address indexed from, address indexed guardian);
    event GovernanceUpdated (address indexed newGov, address indexed oldGov);
    event RewardRecipientUpdated (address indexed reward);

    modifier onlyGov () {
        require(msg.sender == governance, "feeConfig/unauthorised gov");
        _;
    }
    modifier onlyPartner () {
        require(msg.sender == partner, "feeConfig/unauthorised partner");
        _;
    }
    modifier onlyPendingGov () {
        require(msg.sender == pendingGovernance, "feeConfig/not a pendng gov");
        _;
    }

    constructor () public {
        governance = msg.sender;
    }

    function config (address _partner, address _management, address _guardian, address _rewards, address _approver) public onlyGov {
        partner = _partner;
        partnerFeeRecipient = _partner;
        management = _management;
        guardian = _guardian;
        rewards = _rewards;
        approver = _approver;
        emit Configured(_partner, _management, _guardian, _rewards, _approver);
    }

    function updatePartner (address _partner ) public onlyGov {
        partner = _partner;
        partnerFeeRecipient = _partner;
        emit PartnerUpdated(msg.sender ,_partner);
    }

    function updatePartnerFeeRecipient (address _recipient) public onlyPartner {
        partnerFeeRecipient = _recipient;
        emit PartnerFeeRecipientUpdated(msg.sender, _recipient);
    }

    function updatePartnerFee (address _vault, uint256 _partnerFee) public {
        require(
            msg.sender == governance ||
            msg.sender ==  partner,
            "feeConfig/unauthorised to update partner fee"
        );
        require(MAX_BPS > _partnerFee, "feeConfig/invalid partner fee");
        partnerFees[_vault] = _partnerFee;
        emit PartnerFeeUpdated(_vault, _partnerFee);
    }

    function updatePerformanceFee (address _vault,uint256 _performanceFee) public onlyGov {
        require(MAX_BPS.div(2) > _performanceFee, "feeConfig/invalid managementFee");
        performanceFees[_vault] = _performanceFee;
        emit PerformanceFeeUpdated(_vault,_performanceFee);
    }

    function updateManagement (address _newManagement) public onlyGov {
        require(_newManagement != address(0), "feeConfig/invalid management address");
        management = _newManagement;
        emit ManagementUpdated(msg.sender, _newManagement);
    }

    function updateManagementFee (address _vault, uint256 _managementFee) public onlyGov {
        require(MAX_BPS > _managementFee, "feeConfig/invalid managementFee");
        managementFees[_vault] = _managementFee;
        emit ManagementFeeUpdated(_vault,_managementFee);
    }

    function updateGuardian (address _newGuardian) public onlyGov {
        require(_newGuardian != address(0), "feeConfig/invalid guardian");
        guardian = _newGuardian;
        emit GuardianUpdated(msg.sender, _newGuardian);
    }

    function updateApprover (address _newApprover) public onlyGov {
        require(_newApprover != address(0), "feeConfig/invalid approver");
        approver = _newApprover;
        emit ApproverUpdated(msg.sender, _newApprover);
    }
    function updateRewards (address _newRewards) public onlyGov {
        require(_newRewards != address(0), "feeConfig/invalid reward recipient");
        rewards = _newRewards;
        emit RewardRecipientUpdated(_newRewards);
    }

    function proposeNewGoverner (address newGov) public onlyGov {
        pendingGovernance = newGov;
    }

    function acceptGovernance () public onlyPendingGov {
        emit GovernanceUpdated(pendingGovernance, governance);
        governance = pendingGovernance;
        pendingGovernance = address(0);
    }

    function getManagementFee (address _vault) public view returns (uint256 fee) {
        fee = managementFees[_vault];
        if(fee == 0)
            fee = 200;
    }

    function getPerformanceFee (address _vault) public view returns (uint256 fee) {
        fee = performanceFees[_vault];
        if (fee == 0)
            fee = 1000;
    }

    function getPartnerFee (address _vault) public view returns (uint256 fee) {
        fee = partnerFees[_vault];
    }

    function whitelist (address _toWhitelist) public {
        require(
            msg.sender == governance ||
            msg.sender ==  partner,
            "feeConfig/unauthorised to whitelist"
        );
        require(_toWhitelist != address(0), "feeConfig/invalid address to whitelist");
        require(!isWhitelisted[_toWhitelist], "feeConfig/already whitelisted");
        isWhitelisted[_toWhitelist] = true;
    }

    function cancelWhitelist (address _toCancel) public {
        require(
            msg.sender == governance ||
            msg.sender ==  partner,
            "feeConfig/unauthorised to whitelist"
        );
        require(_toCancel != address(0), "feeConfig/invalid address to cancel whitelisting");
        isWhitelisted[_toCancel] = false;
    }

    function bulkWhitelist (address [] calldata _toWhitelists) public {
        require(
            msg.sender == governance ||
            msg.sender ==  partner,
            "feeConfig/unauthorised to whitelist"
        );
        uint256 length = _toWhitelists.length;
        for (uint256 i = 0; i < length ;i++) {
            address tmp = _toWhitelists[i];
            if(tmp != address(0) && isWhitelisted[tmp]) {
                isWhitelisted[tmp] = true;
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}