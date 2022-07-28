/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface MoonDoge {

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function tokenTraits(uint256 tokenId) external view returns (bytes2);

}

interface DogeRace {

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isDogeBusy(uint256 tokenId) external view returns (bool isBusy);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function tokenTraits(uint256 tokenId) external view returns (bytes2);

    function races(uint256 raceId) external view returns (address initiator, uint256 creationTime, uint256 entryFee, bool isFinished, bool isCancelled, uint256 participantCount);

    function raceCounter() external view returns (uint256 raceCount);

}



contract dogeRaceHelper {

    using SafeMath for uint256;
    
    address public dogeAddress;
    address public raceAddress;
    
    
    constructor(address _dogeAddress, address _raceAddress) {
        
        dogeAddress = _dogeAddress;
        raceAddress = _raceAddress;

    }

    function getUsersDoges(address owner) public view returns(uint256[] memory doges, bool[] memory isBusy) {

        uint256 ownerDogeBalance = MoonDoge(dogeAddress).balanceOf(owner);

        uint256[] memory usersDoges = new uint256[](ownerDogeBalance);
        bool[] memory busyDoges = new bool[](ownerDogeBalance);

        for(uint256 i=0; i<ownerDogeBalance; i++) {
            usersDoges[i] = MoonDoge(dogeAddress).tokenOfOwnerByIndex(owner, i);
            busyDoges[i] = DogeRace(raceAddress).isDogeBusy(usersDoges[i]);
        }

        return (usersDoges, busyDoges);
    }

    function getDogesBulk(uint256[] calldata tokenIds) public view returns(address[] memory owners, bool[] memory isBusy) {

        address[] memory dogeOwners = new address[](tokenIds.length);
        bool[] memory busyDoges = new bool[](tokenIds.length);

        for(uint256 i=0; i<tokenIds.length; i++) {
            dogeOwners[i] = MoonDoge(dogeAddress).ownerOf(tokenIds[i]);
            busyDoges[i] = DogeRace(raceAddress).isDogeBusy(tokenIds[i]);
        }

        return (dogeOwners, busyDoges);
    }
    
}