/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface RaceableNFT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenTraits(uint256 tokenId) external view returns (bytes2);
}

interface TraitStorage {

    function traitValues(uint256 traitId, uint256 tokenId) external view returns (uint256 value);

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


interface SupportedCollections {

    function collectionExists(address collectionAddress) external view returns (
        bool exists
    );

    function collectionByAddress(address collectionAddress) external view returns (
        bool active,
        address feeReceiver,
        uint256 characterTypeCount,
        uint256 speedTraitId,
        uint256 enduranceTraitId,
        uint256 luckTraitId
    );

    function characterTraits(address collectionAddress, uint256 characterId) external view returns (
        uint256 speed,
        uint256 endurance,
        uint256 luck
    );

    function updateCharacterTraits(address collectionAddress, uint256 characterId) external returns (
        bool success
    );

}

interface RaceProcessor {

    function isRaceProcessorReady() external view returns (
        bool isReady
    );

    function startRace(uint256 raceId) external returns (
        bool success
    );

}


contract ethosRacing is Ownable {

    using SafeMath for uint256;
    
    address public supportedCollectionsAddress;
    address public raceProcessorAddress;

    bool public active = false;
    
    address payable public devWallet;

    uint256 public currentRequestId;

    uint256 public raceCounter;

    uint256 public cancelThreshold;

    uint256 public raceLimit;

    uint256 public activeRaces;
    
    // requestId => isFulfilled address
    mapping (uint256 => bool) public requestFulfilled;
    
    event Request(uint256 requestId);
    event RaceCreated(uint256 raceId);
    event RaceJoined(uint256 raceId, address collectionAddress, uint256 characterId);
    event RaceFinish(uint256 raceId);

    struct DogeTraits {
        uint256 speed;
        uint256 endurance;
        uint256 luck;
    }

    struct RaceParticipant {
        address collectionAddress;
        uint256 characterId;
    }

    struct Race {
        address initiator;
        uint256 creationTime;
        uint256 entryFee;
        bool isFinished;
        bool isCancelled;
        uint256 participantCount;
        mapping(uint256 => RaceParticipant) participants;
        mapping(uint256 => bool) isSlotTaken;
        mapping(uint256 => uint256) finishedPosition;
    }

    struct Location {
        bool active;
        string name;
        uint256 speedMultiplier;
        uint256 enduranceMultiplier;
        uint256 luckMultiplier;
    }

    mapping(uint256 => Race) public races;
    mapping(uint256 => Location) public supportedLocations;

    uint256 supportedLocationCount;

    mapping(address => mapping(uint256 => bool)) public isCharacterBusy; //collection address => character id => isBusy

    mapping(uint256 => uint256) public combinedTraitsArray;

    uint256[] public allowedEntryFees;
    mapping(uint256 => bool) public isAllowedEntryFee;
    
    constructor(address _supportedCollectionsAddress, address _raceProcessorAddress, address payable _devWallet, uint256[] memory entryFees) {
        supportedCollectionsAddress = _supportedCollectionsAddress;
        raceProcessorAddress = _raceProcessorAddress;
        devWallet = _devWallet;

        allowedEntryFees = entryFees;

        for(uint256 i=0; i<entryFees.length; i++) {
            isAllowedEntryFee[entryFees[i]] = true;
        }

        cancelThreshold = 1 hours;
        raceLimit = 10;

    }
    
    function getFinishedPosition(uint256 raceId, uint256 position) public view returns(uint256) {
        return races[raceId].finishedPosition[position];
    }
    
    function getRaceParticipant(uint256 raceId, uint256 index) public view returns(RaceParticipant memory) {
        return races[raceId].participants[index];
    }
    
    function getIsSlotTaken(uint256 raceId, uint256 index) public view returns(bool) {
        return races[raceId].isSlotTaken[index];
    }

    function createRace(address collectionAddress, uint256 characterId, uint256 locationId, uint256 entryFee) public payable returns(bool success) {
        require(active == true, "Racing disabled");
        require(isSupportedCollection(collectionAddress), "Incorrect collection address");
        require(isSupportedLocation(locationId), "Incorrect location id");
        require(isCharacterBusy[collectionAddress][characterId] == false, "Character is busy");
        require(RaceableNFT(collectionAddress).ownerOf(characterId) == msg.sender, "Not NFT owner");
        require(isAllowedEntryFee[entryFee] == true && msg.value == entryFee, "Incorrect entry fee");
        require(activeRaces < raceLimit, "Limit exceeded");
        
        raceCounter++;
        activeRaces++;

        races[raceCounter].initiator = msg.sender;
        races[raceCounter].creationTime = block.timestamp;
        races[raceCounter].participants[0] = RaceParticipant(collectionAddress,characterId);
        races[raceCounter].isSlotTaken[0] = true;
        races[raceCounter].participantCount = 1;
        races[raceCounter].entryFee = entryFee;

        SupportedCollections(supportedCollectionsAddress).updateCharacterTraits(collectionAddress, characterId);

        isCharacterBusy[collectionAddress][characterId] = true;

        emit RaceCreated(raceCounter);
        emit RaceJoined(raceCounter, collectionAddress, characterId);

        return true;
    }

    function isSupportedCollection(address collectionAddress) public view returns (bool) {
        require(collectionAddress != address(0), "Collection address cannot be 0");

        bool doesExist = SupportedCollections(supportedCollectionsAddress).collectionExists(collectionAddress);

        (bool isActive,,,,,) = SupportedCollections(supportedCollectionsAddress).collectionByAddress(collectionAddress);

        return (doesExist && isActive);
    }

    function isSupportedLocation(uint256 locationId) public view returns (bool) {

        return locationId < supportedLocationCount && supportedLocations[locationId].active;
        
    }

    function addLocation(string memory _name, uint256 _speedMultiplier, uint256 _enduranceMultiplier, uint256 _luckMultiplier) public onlyOwner {

        Location memory newLocation = Location(true, _name, _speedMultiplier, _enduranceMultiplier, _luckMultiplier);

        supportedLocations[supportedLocationCount] = newLocation;

        supportedLocationCount++;
    }

    function enableLocation(uint256 locationId) public onlyOwner {
        require(supportedLocations[locationId].active == false, "Location already enabled");
        supportedLocations[locationId].active = true;
    }

    function disableLocation(uint256 locationId) public onlyOwner {
        require(supportedLocations[locationId].active == true, "Location already disabled");
        supportedLocations[locationId].active = false;
    }
    

    function enterRace(uint256 raceId, address collectionAddress, uint256 characterId) public payable returns(bool success) {
        require(active == true, "Racing disabled");
        require(isSupportedCollection(collectionAddress), "Incorrect collection address");
        require(isCharacterBusy[collectionAddress][characterId] == false, "Character is busy");
        require(RaceableNFT(collectionAddress).ownerOf(characterId) == msg.sender, "Not NFT owner");
        require(races[raceId].creationTime > 0, "Race does not exist");
        require(races[raceId].isFinished == false, "Race finished");
        require(races[raceId].isCancelled == false, "Race cancelled");
        require(msg.value == races[raceId].entryFee, "Incorrect entry fee");
        
        for(uint256 i = 0; i < 9; i++) {
            if(races[raceId].isSlotTaken[i] == false) {
                races[raceId].participants[i] = RaceParticipant(collectionAddress,characterId);
                races[raceId].isSlotTaken[i] = true;
                races[raceId].participantCount++;

                SupportedCollections(supportedCollectionsAddress).updateCharacterTraits(collectionAddress, characterId);

                isCharacterBusy[collectionAddress][characterId] = true;
                
                emit RaceJoined(raceId, collectionAddress, characterId);
                
                // if this is the last character joining, initiate race
                if(races[raceId].participantCount == 9) {
                    require(RaceProcessor(raceProcessorAddress).isRaceProcessorReady(), "The race processor is currently unavailable. Try again later.");

                    RaceProcessor(raceProcessorAddress).startRace(raceId);
                    
                }

                return true;
            }
        }

        return false;
    }
    
    function leaveRace(uint256 raceId, address collectionAddress, uint256 characterId) public returns(bool success) {
        require(isSupportedCollection(collectionAddress), "Incorrect collection address");
        require(RaceableNFT(collectionAddress).ownerOf(characterId) == msg.sender, "Not NFT owner");
        require(races[raceId].creationTime > 0, "Race does not exist");
        require(races[raceId].isFinished == false, "Race finished");
        require(races[raceId].isCancelled == false, "Race cancelled");
        require(races[raceId].creationTime + cancelThreshold < block.timestamp, "Leaving the race will be enabled 1 hour from its creation.");

        // check if race initiator is trying to cancel a race 
        if(races[raceId].initiator == msg.sender) {
            cancelRace(raceId);
            return true;
        } else {
            for(uint256 i = 0; i < 9; i++) {
                if(races[raceId].participants[i].characterId == characterId && races[raceId].isSlotTaken[i] == true) {
                    isCharacterBusy[collectionAddress][characterId] = false;
                    races[raceId].isSlotTaken[i] = false;
                    races[raceId].participants[i] = RaceParticipant(address(0),0);
                    races[raceId].participantCount--;
                    
                    // refund avax
                    payable(msg.sender).transfer(races[raceId].entryFee);

                    return true;
                }
            }
        }
        return false;
    }

    function concludeRace(uint256 raceId, uint256[] memory randomNumbers) external {
        //require(msg.sender == raceProcessorAddress, "Caller is not race processor");

        // participant id => entry tickets
        uint256[9] memory entryTickets;
        bool[9] memory dogeFinished;
        uint256 totalTickets = 0;

        
        for(uint256 i = 0; i < 9; i++) {
            
            isCharacterBusy[races[raceId].participants[i].collectionAddress][races[raceId].participants[i].characterId] = false;

            uint256 combinedTraits = combinedTraitsArray[races[raceId].participants[i].characterId];

            entryTickets[i] = combinedTraits;
            totalTickets += combinedTraits;
        }

        // i = finished places, j = participants
        for(uint256 i = 0; i < 9; i++) {

            uint256 sumOfTickets = 0;

            for(uint256 j = 0; j < 9; j++) {
                if(dogeFinished[j] == false) {
                    sumOfTickets += entryTickets[j];
                    uint256 winner = randomNumbers[i] % (totalTickets) + 1;

                    if(winner <= sumOfTickets) {
                        totalTickets -= entryTickets[j];
                        races[raceId].finishedPosition[i] = j;
                        dogeFinished[j] = true;
                        break;
                    }
                }
            }
        }
        
        uint256 totalReward = races[raceId].entryFee.mul(9);
        
        address[3] memory winners;
        winners[0] = RaceableNFT(races[raceId].participants[races[raceId].finishedPosition[0]].collectionAddress).ownerOf(races[raceId].participants[races[raceId].finishedPosition[0]].characterId);
        winners[1] = RaceableNFT(races[raceId].participants[races[raceId].finishedPosition[1]].collectionAddress).ownerOf(races[raceId].participants[races[raceId].finishedPosition[1]].characterId);
        winners[2] = RaceableNFT(races[raceId].participants[races[raceId].finishedPosition[2]].collectionAddress).ownerOf(races[raceId].participants[races[raceId].finishedPosition[2]].characterId);
        
        distributeRewards(raceId, winners, totalReward);

    }

    function distributeRewards(uint256 raceId, address[3] memory winners, uint256 totalReward) private {
        uint256 reward1 = totalReward.mul(500).div(1000);
        uint256 reward2 = totalReward.mul(250).div(1000);
        uint256 reward3 = totalReward.mul(125).div(1000);
        uint256 devFee = totalReward.mul(625).div(10000);
        uint256 fractionalDevFee = totalReward.sub(reward1).sub(reward2).sub(reward3).sub(devFee).div(9);

        payable(winners[0]).transfer(reward1);
        payable(winners[1]).transfer(reward2);
        payable(winners[2]).transfer(reward3);
        payable(devWallet).transfer(devFee);
        
        distributeCollectionFees(raceId, fractionalDevFee);

    }

    // Distribute fees to collection owners
    function distributeCollectionFees(uint256 raceId, uint256 fractionalDevFee) private {

        address[9] memory feeReceivers;
        uint256[9] memory feeAmounts;
        uint256 paymentCount;

        for(uint256 i = 0; i < 9; i++) {
            bool receiverAlreadyAdded = false;
            (,address collectionFeeReceiver,,,,) = SupportedCollections(supportedCollectionsAddress).collectionByAddress(races[raceId].participants[i].collectionAddress);
            
            for(uint256 j=0; j<paymentCount; j++) {
                if(feeReceivers[j] == collectionFeeReceiver) {
                    feeAmounts[j] += fractionalDevFee;
                    receiverAlreadyAdded = true;
                }
            }

            if(!receiverAlreadyAdded) {
                feeReceivers[paymentCount] = collectionFeeReceiver;
                feeAmounts[paymentCount] = fractionalDevFee;
                paymentCount++;
            }
            
        }

        for(uint256 i = 0; i < paymentCount; i++) {
            payable(feeReceivers[i]).transfer(feeAmounts[i]);
        }

        emit RaceFinish(raceId);

        activeRaces--;
        
        races[raceId].isFinished = true; 
    }

    function setActive(bool isActive) public onlyOwner {
        active = isActive;
    }
    
    function updateRaceLimit(uint256 _raceLimit) public onlyOwner {
        raceLimit = _raceLimit;
    }
    
    function withdrawEther(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    function withdrawTokens(address token, address to, uint256 amount) public onlyOwner {
        IERC20 wToken = IERC20(token);
        wToken.transfer(to, amount);
    }
    

    function adminSetEntryFees(uint256[] memory entryFees) external onlyOwner {
        for(uint256 i=0; i<allowedEntryFees.length; i++) {
            isAllowedEntryFee[allowedEntryFees[i]] = false;
        }

        allowedEntryFees = entryFees;

        for(uint256 i=0; i<entryFees.length; i++) {
            isAllowedEntryFee[entryFees[i]] = true;
        }
    }

    function adminSetDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = newDevWallet;
    }

    function cancelRace(uint256 raceId) internal {
        for(uint256 i = 0; i < 9; i++) {
            if(races[raceId].isSlotTaken[i] == true) {
                isCharacterBusy[races[raceId].participants[i].collectionAddress][races[raceId].participants[i].characterId] = false;
                races[raceId].isSlotTaken[i] = false;
                races[raceId].participantCount = 0;
                races[raceId].isCancelled = true;

                // refund avax
                payable(RaceableNFT(races[raceId].participants[i].collectionAddress).ownerOf(races[raceId].participants[i].characterId)).transfer(races[raceId].entryFee);
            }
        }
        activeRaces--;
    }
    
    function adminCancelRace(uint256 raceId) external onlyOwner {
        require(races[raceId].creationTime > 0, "Race does not exist");
        require(races[raceId].isFinished == false, "Race finished");
        require(races[raceId].isCancelled == false, "Race cancelled");
        
        cancelRace(raceId);
    }

}