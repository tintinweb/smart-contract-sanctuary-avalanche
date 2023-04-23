//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./LandStatsOracleInterface.sol";
import "./LandInfoData.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandRegistryContract is Ownable, LandInfoData {
    // Define the interface to the Oracle contract
    LandStatsOracleInterface private landStatsContract;
    // Define the address of the Oracle contract
    //@dev: this is the address of the deployed contract.
    //@todo: Before deploying, make this private
    address public landStatsOracleContractAddress;
    address public paymentContractAddress;
    // Define the list of attributes that will be returned by the Oracle contract
    string [] public valueKeys;
    string [] public stringKeys;

    // Define the list of active registrations
    uint256 [] public activeRegistrations;

    // Define the minimum sampling frequency
    uint32 public minSamplingFrequency;

    uint32 public constant MODULUS = 1000000000;

    modifier ownerOf(uint256 _id) {
        require(idToRegInfo[_id].owner == msg.sender, "CallerContract: caller is not the owner of the land");
        _;
    }

    modifier oracleContractOnly() {
        require(msg.sender == landStatsOracleContractAddress, "CallerContract: caller is not the oracle contract");
        _;
    }

    modifier paymentContractOnly() {
        require(msg.sender == paymentContractAddress, "CallerContract: caller is not the payment contract");
        _;
    }
    
    modifier paymentContractOrOwnerOf(uint256 _id) {
        require(msg.sender == paymentContractAddress || idToRegInfo[_id].owner == msg.sender, "CallerContract: caller is not the payment contract or the owner of the land");
        _;
    }

    //mapping for all registration IDs to their registration information
    mapping (uint256 => LandRegistration) public idToRegInfo;

    //mapping for all request IDs to their registration IDs
    mapping (uint256 => uint256) myRequests;

    event LandStatsOracleAddressSetEvent(address indexed landStatsContractAddress);
    event NewRegistrationEvent(uint256 indexed id);
    event RecievedNewRequestIdEvent(uint256 indexed requestId);
    event LandStatsUpdatedEvent(uint256 indexed id);

    function setCalleeContractAddress(address _calleeContractAddress) public onlyOwner {
        landStatsOracleContractAddress = _calleeContractAddress;
        landStatsContract = LandStatsOracleInterface(landStatsOracleContractAddress);
        emit LandStatsOracleAddressSetEvent(landStatsOracleContractAddress);
    }

    function setPaymentContractAddress(address _paymentContractAddress) public onlyOwner {
        paymentContractAddress = _paymentContractAddress;
    }

    function setValueKeys(string [] memory _valueKeys) public onlyOwner {
        valueKeys = _valueKeys;
    }

    function getValueKeys() public view returns (string [] memory) {
        return valueKeys;
    }

    function setStringKeys(string [] memory _stringKeys) public onlyOwner {
        stringKeys = _stringKeys;
    }

    function getStringKeys() public view returns (string [] memory) {
        return stringKeys;
    }

    function getActiveRegistrations() public view returns (uint256 [] memory) {
        return activeRegistrations;
    }

    function setMinSamplingFrequency(uint32 _minSamplingFrequency) public onlyOwner {
        minSamplingFrequency = _minSamplingFrequency;
    }

    function setAllParameters(string [] memory _valueKeys, string [] memory _stringKeys, uint32 _minSamplingFrequency) public onlyOwner {
        setValueKeys(_valueKeys);
        setStringKeys(_stringKeys);
        setMinSamplingFrequency(_minSamplingFrequency);
    }

    function setOwner(uint256 _id, address _newOwner) public ownerOf(_id) {
        idToRegInfo[_id].owner = _newOwner;
    }

    function updateLandCoords(uint256 _id, int256 [][] memory _newLandCoords) public ownerOf(_id) {
        idToRegInfo[_id].landCoords = _newLandCoords;
        requestLandStats(_id, block.timestamp);
    }

    function updateCO2EStats(uint256 _id, int256 _newCO2EStats) public paymentContractOnly {
        idToRegInfo[_id].totalCO2EMintedLastYear = _newCO2EStats;
        idToRegInfo[_id].totalCO2EMinted += _newCO2EStats;
        idToRegInfo[_id].firstMintEvent = true;
    }

    function getLandCoords(uint256 _id) public view returns (int256 [][] memory) {
        return idToRegInfo[_id].landCoords;
    }

    function registerLand(int256 [][] memory _landCoords, string memory _landName) public returns (uint256) {
        LandRegistration memory newRegistration;
        newRegistration.nextSamplingTime = block.timestamp;
        newRegistration.registeringAuthority = msg.sender;
        newRegistration.owner = msg.sender;
        newRegistration.registrationTime = block.timestamp;
        newRegistration.landName = _landName;
        newRegistration.landCoords = _landCoords;
        uint256 id = uint256(keccak256((abi.encodePacked(block.timestamp, msg.sender, _landName, _landCoords[0])))) % MODULUS;
        idToRegInfo[id] = newRegistration;
        activeRegistrations.push(id);
        emit NewRegistrationEvent(id);
        return id;
    }

    function requestLandStats(uint256 _id, uint256 _time) public paymentContractOrOwnerOf(_id) {
        require(idToRegInfo[_id].registrationTime != 0, "LandRegistryContract: land not registered");
        require(idToRegInfo[_id].nextSamplingTime <= block.timestamp, "LandRegistryContract: land not ready for update");
        int256 [][] memory landCoords = idToRegInfo[_id].landCoords;
        uint256 requestId = landStatsContract.getLandStats(landCoords, _time);
        myRequests[requestId] = _id;
        emit RecievedNewRequestIdEvent(requestId);
    }

    function callBack(uint256 requestId, uint256 [] memory values, string [] memory strings) public oracleContractOnly {
        require(myRequests[requestId]!=0, "LandRegistryContract: requestId not found");

        uint256 id = myRequests[requestId];
        LandRegistration storage landRecord = idToRegInfo[id];
        landRecord.landStats = values;
        landRecord.landStatsAddlInfo = strings;
        landRecord.nextSamplingTime = uint64(block.timestamp + minSamplingFrequency);

        delete myRequests[requestId];
        emit LandStatsUpdatedEvent(id);
        
    }

    function returnLandStats(uint256 _id) public view returns (LandRegistration memory) {
        return (idToRegInfo[_id]);
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract LandStatsOracleInterface {
    function getLandStats (int256 [][] memory, uint256) public virtual returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract LandInfoData {
    // Define the struct that will hold the registration information
    struct LandRegistration {
        address registeringAuthority;
        address owner;
        uint256 registrationTime;
        uint256 nextSamplingTime;
        string landName;
        int256 [][] landCoords;
        uint256 [] landStats;
        string [] landStatsAddlInfo;
        int256 totalCO2EMinted;
        int256 totalCO2EMintedLastYear;
        bool firstMintEvent;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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