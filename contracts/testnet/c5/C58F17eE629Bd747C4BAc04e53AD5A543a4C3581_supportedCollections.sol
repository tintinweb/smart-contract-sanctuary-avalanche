/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-12
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

contract supportedCollections is Ownable {
    using SafeMath for uint256;

    address public raceContract;


    struct TraitSettings {
        bool exists;
        uint256 speedMin;
        uint256 speedMax;
        uint256 enduranceMin;
        uint256 enduranceMax;
        uint256 luckMin;
        uint256 luckMax;
    }

    struct CharacterTraits {
        uint256 speed;
        uint256 endurance;
        uint256 luck;
    }

    struct CollectionDetails {
        bool active;
        address traitAddress;
        address feeReceiver;
        string name;
        uint256 characterTypeCount;
        uint256 speedTraitId;
        uint256 enduranceTraitId;
        uint256 luckTraitId;
        mapping(uint256 => CharacterTraits) traitArray;
    }

    uint256 public addedCollections = 0;

    // collectionAddress => CollectionDetails
    mapping(address => CollectionDetails) public collectionDetails;
    mapping(address => bool) public collectionExists;
    mapping(address => uint256) public collectionIdByContractAddress;
    mapping(uint256 => address) public collectionAddressById;
    

    // collectionAddress => characterTypeId => TraitSettings
    mapping(address => mapping(uint256 => TraitSettings)) public traitSettingsPerCharacterType;


    constructor() {

    }

    function setup(address _raceContract) public onlyOwner {
        raceContract = _raceContract;
    }

    function setupCollection(
        address contractAddress,
        address traitAddress,
        address feeReceiver,
        string calldata name,
        uint256 speedTraitId,
        uint256 enduranceTraitId,
        uint256 luckTraitId
    ) public onlyOwner {
        require(contractAddress != address(0), "Invalid contract address");

        uint256 collectionId = addedCollections;
        collectionDetails[contractAddress].active = false;
        collectionDetails[contractAddress].traitAddress = traitAddress;
        collectionDetails[contractAddress].feeReceiver = feeReceiver;
        collectionDetails[contractAddress].name = name;
        collectionDetails[contractAddress].characterTypeCount = 0;
        collectionDetails[contractAddress].speedTraitId = speedTraitId;
        collectionDetails[contractAddress].enduranceTraitId = enduranceTraitId;
        collectionDetails[contractAddress].luckTraitId = luckTraitId;
        
        collectionIdByContractAddress[contractAddress] = collectionId;
        collectionAddressById[collectionId] = contractAddress;
        collectionExists[contractAddress] = true;

        addedCollections++;
    }

    function enableCollection(address collectionAddress) public onlyOwner {
        require(collectionExists[collectionAddress], "This collection doesn't exist");

        collectionDetails[collectionAddress].active = true;
    }

    function disableCollection(address collectionAddress) public onlyOwner {
        require(collectionExists[collectionAddress], "This collection doesn't exist");

        collectionDetails[collectionAddress].active = false;
    }



    function addCharacter(
        address collectionAddress,
        uint256 speedMin,
        uint256 speedMax,
        uint256 enduranceMin,
        uint256 enduranceMax,
        uint256 luckMin,
        uint256 luckMax
    ) public onlyOwner {
        require(collectionExists[collectionAddress], "This collection doesn't exist");

        uint256 characterTypeId = collectionDetails[collectionAddress].characterTypeCount;
        traitSettingsPerCharacterType[collectionAddress][characterTypeId] = TraitSettings(true, speedMin, speedMax, enduranceMin, enduranceMax, luckMin, luckMax);
        collectionDetails[collectionAddress].characterTypeCount++;
    }


    function getTraits(address collectionAddress, uint256 characterId) external returns (CharacterTraits memory) {
        updateLocalTraits(collectionAddress, characterId);

        uint256 speedSeed = collectionDetails[collectionAddress].traitArray[characterId].speed;
        uint256 enduranceSeed = collectionDetails[collectionAddress].traitArray[characterId].endurance;
        uint256 luckSeed = collectionDetails[collectionAddress].traitArray[characterId].luck;

        return getCharacterTraits(collectionAddress, characterId, speedSeed, enduranceSeed, luckSeed);
    }
    
    
    function updateLocalTraits(address collectionAddress, uint256 characterId) internal returns (bool) {
        require(collectionExists[collectionAddress] == true, "The specified collection doesn't exist");

        address traitAddress = collectionDetails[collectionAddress].traitAddress;

        if(collectionDetails[collectionAddress].traitArray[characterId].speed == 0) {

            bytes2 traits = RaceableNFT(collectionAddress).tokenTraits(characterId);
            bytes1 breed = traits[0];

            uint256 speedSeed = TraitStorage(traitAddress).traitValues(collectionDetails[collectionAddress].speedTraitId, characterId);
            uint256 enduranceSeed = TraitStorage(traitAddress).traitValues(collectionDetails[collectionAddress].enduranceTraitId, characterId);
            uint256 luckSeed = TraitStorage(traitAddress).traitValues(collectionDetails[collectionAddress].luckTraitId, characterId);

            CharacterTraits memory updatedCharacterTraits = getCharacterTraits(collectionAddress, uint8(breed), speedSeed, enduranceSeed, luckSeed);

            collectionDetails[collectionAddress].traitArray[characterId] = updatedCharacterTraits;
        }

        return true;
    }
    
    function updateCharacterTraits(address collectionAddress, uint256 characterId) external returns (bool) {
        require(msg.sender == raceContract, "Caller is not the race contract");

        updateLocalTraits(collectionAddress, characterId);

        return true;
    }


    function getCharacterTraits(address collectionAddress, uint256 characterTypeId, uint256 speedSeed, uint256 enduranceSeed, uint256 luckSeed) public view returns(CharacterTraits memory) {
        uint256 generatedSpeed = speedSeed % (traitSettingsPerCharacterType[collectionAddress][characterTypeId].speedMax - traitSettingsPerCharacterType[collectionAddress][characterTypeId].speedMin) + traitSettingsPerCharacterType[collectionAddress][characterTypeId].speedMin;
        uint256 generatedEndurance = enduranceSeed % (traitSettingsPerCharacterType[collectionAddress][characterTypeId].enduranceMax - traitSettingsPerCharacterType[collectionAddress][characterTypeId].enduranceMin) + traitSettingsPerCharacterType[collectionAddress][characterTypeId].enduranceMin;
        uint256 generatedLuck = luckSeed % (traitSettingsPerCharacterType[collectionAddress][characterTypeId].luckMax - traitSettingsPerCharacterType[collectionAddress][characterTypeId].luckMin) + traitSettingsPerCharacterType[collectionAddress][characterTypeId].luckMin;

        return CharacterTraits(generatedSpeed,generatedEndurance,generatedLuck);
    }

    function collectionByAddress(address collectionAddress) external view returns (
        bool active,
        address feeReceiver,
        uint256 characterTypeCount,
        uint256 speedTraitId,
        uint256 enduranceTraitId,
        uint256 luckTraitId
    ) {
        require(collectionExists[collectionAddress] == true, "The specified collection doesn't exist");

        return(
            collectionDetails[collectionAddress].active,
            collectionDetails[collectionAddress].feeReceiver,
            collectionDetails[collectionAddress].characterTypeCount,
            collectionDetails[collectionAddress].speedTraitId,
            collectionDetails[collectionAddress].enduranceTraitId,
            collectionDetails[collectionAddress].luckTraitId
        );
    }

    function characterTraits(address collectionAddress, uint256 characterId) external view returns (
        uint256 speed,
        uint256 endurance,
        uint256 luck
    ) {
        require(collectionExists[collectionAddress] == true, "The specified collection doesn't exist");

        return(
            collectionDetails[collectionAddress].traitArray[characterId].speed,
            collectionDetails[collectionAddress].traitArray[characterId].endurance,
            collectionDetails[collectionAddress].traitArray[characterId].luck
        );
    }

    
}