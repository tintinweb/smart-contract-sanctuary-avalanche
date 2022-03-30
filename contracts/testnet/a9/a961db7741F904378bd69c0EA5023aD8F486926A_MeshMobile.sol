/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-29
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}


// File contracts/Enumerations.sol

pragma solidity ^0.8.11;

// Enumerations
enum DeviceTypes {
    AccessGateway,
    PacketGateway
}

enum ProviderTypes {
    Identity
}


// File contracts/Structs.sol

pragma solidity ^0.8.11;

// Structs
struct DeviceInfo {
    bytes32 identifier;
    DeviceTypes deviceType;

    uint8 deviceHealth;
    uint256 rewards;
    uint256 staked;
}

struct ProviderInfo {
    bytes32 identifier;
    bytes32 endpoint;
    bytes8 mcc_mnc;
    ProviderTypes providerType;

    uint256 deposit;
    uint256 staked;
}

struct ValidationRequest {
    address initiator;
    address idp;
    uint8 requiredVotes;
    uint256 reward;

    ValidationSubject[] subscribers;
    ValidationVote[] votes;
}

struct ValidationVote {
    address participant;
    bool vote;
}

struct ValidationSubject {
    bytes16 imsi;
    uint32 connected;
    uint32 ended;
}


// File contracts/MeshMobile.sol

/*
    Wireless Blockchain contract v1.2
        - Service payments based on active subscriber base fee + time connected
        - Staking required to register device/IDP
        - No coverage considerations/bonuses
        - Future consideration: Uber H3 Spatial Index coverage?
*/

pragma solidity ^0.8.11;



// Contract
contract MeshMobile is Ownable, ReentrancyGuard {
    event LogDeviceRegistered(address registrant, bytes32 identifier);
    event LogProviderRegistered(address registrant, bytes32 identifier);
    event LogValidationRequest(bytes32 identifier);
    event LogValidationSettled(bytes32 identifier, bool successful);
    event LogVoteSubmitted(bytes32 identifier, bool vote);
    event LogRewarded(address target, uint256 amount);

    mapping(address => DeviceInfo) public registeredDevices;
    mapping(address => ProviderInfo) public registeredProviders;
    mapping(bytes32 => ValidationRequest) public validationRequests;
    mapping(bytes8 => address) public mncToAddress;

    bytes32[] public pendingValidations;

    uint256 public baseSubscriberFee = 1000000000000000; // Base fee for serving subscriber
    uint256 public activeSubscriberThreshold = 1024; // 1kb
    uint256 public timeConnectedFee = 100000000000000; // Per time interval (min, sec, ms?)
    uint256 public timeConnectedInterval = 10;
    uint256 public coverageMultiplier = 1; // Fee multiplier for coverage bonuses
    uint256 public operatingFee = 1000000000; // Operating cost collected by Telnyx

    uint256 public deviceStake;
    uint256 public providerStake;

    bool public canValidate = true;
    bool public canRegister = true;
    bool public canWithdraw = true;

    //uint256 internal random;

    // Constructor
    constructor() {
        
    }

    receive() external payable {

    }

    // Modifiers
    modifier onlyDevices() {
       require(registeredDevices[msg.sender].identifier != 0x0, "Devices only");
       _;        
    }

    modifier onlyProvider() {
       require(registeredProviders[msg.sender].identifier != 0x0, "Providers only");
       _;        
    }

    modifier onlySubject(bytes32 signature) {
        require(validationRequests[signature].idp == msg.sender, "Subject only");
       _;
    }

    // Private functions
    function createValidationObj(
        address initiator, 
        address subject
    ) internal returns (
        ValidationRequest storage, 
        bytes32
    ) {
        bytes32 signature = keccak256(bytes.concat(bytes20(initiator), bytes20(subject), bytes32(block.number)));

        // This is probably bad for perf but we need ValidationSubject[] subscribers and ValidationVote[] votes to be unassigned
        ValidationRequest storage request = validationRequests[signature];
        request.initiator = initiator;
        request.idp = subject;
        request.requiredVotes = 1;

        pendingValidations.push(signature);

        return (request, signature);
    }

    // Public Functions
    function claimRewards() onlyDevices nonReentrant external {
        require(canWithdraw, "Withdraws disabled");

        DeviceInfo storage agwInfo = registeredDevices[msg.sender];
        uint256 payment = agwInfo.rewards;
        agwInfo.rewards = 0;

        Address.sendValue(payable(msg.sender), payment);
    }

    function requestValidation(
        address subject, 
        bytes8[] calldata subscribers, 
        uint32[] calldata startTimes,
        uint32[] calldata endTimes
    ) onlyDevices public {
        require(canValidate, "Validations disabled");

        uint256 calculatedReward = calculateAward(subscribers, startTimes, endTimes);

        ProviderInfo storage idpInfo = registeredProviders[subject];
        require(idpInfo.identifier != 0x0, "Invalid provider");
        require(idpInfo.deposit >= calculatedReward, "Not enough deposit");

        (ValidationRequest storage request, bytes32 signature) = createValidationObj(msg.sender, subject);
        request.reward = calculatedReward;
        ValidationSubject[] storage requestSubscribers = request.subscribers;

        for (uint32 i = 0; i < subscribers.length; i++) {
            // Subscriber IDP check
            requestSubscribers.push(ValidationSubject(subscribers[i], startTimes[i], endTimes[i]));
        }
        
        emit LogValidationRequest(signature);
    }

    function submitVote(
        bytes32 identifier, 
        bool vote
    ) onlySubject(identifier) public {
        ValidationRequest storage requestData = validationRequests[identifier];
        address initiator = requestData.initiator;
        address idp = requestData.idp;

        ValidationVote[] storage votes = requestData.votes;
        
        votes[votes.length] = ValidationVote(msg.sender, vote);

        if (votes.length == requestData.requiredVotes) {
            uint8 yesVotes;
            uint8 noVotes;

            for (uint i = 0; i < votes.length; i++) {
                votes[i].vote ? yesVotes += 1 : noVotes += 1;
            }

            bool successful = yesVotes > noVotes;
            emit LogValidationSettled(identifier, successful);

            if (successful) {
                uint256 award = requestData.reward;

                // Clamp these
                registeredDevices[initiator].rewards += award;
                registeredProviders[idp].deposit -= award;

                emit LogRewarded(initiator, award);
            }

            for (uint32 index = 0; index < pendingValidations.length; index++) {
                bytes32 pendingId = pendingValidations[index];

                if (identifier == pendingId) {
                    // super hacky
                    pendingValidations[index] = pendingValidations[pendingValidations.length - 1];
                    pendingValidations.pop();
                }
            }

            delete validationRequests[identifier];
        }

        emit LogVoteSubmitted(identifier, vote);
    }

    function calculateAward( 
        bytes8[] calldata subscribers, 
        uint32[] calldata startTimes,
        uint32[] calldata endTimes
    ) internal view returns (uint256) {
        uint256 totalReward = subscribers.length * baseSubscriberFee;
        for (uint32 index = 0; index < subscribers.length; index++) {
            uint32 timeConnected = endTimes[index] - startTimes[index];

            if (timeConnected > 0) {
                totalReward += (timeConnected / timeConnectedInterval) * timeConnectedFee;
            }
        }

        return totalReward;
    }

    // Registration
    function registerDevice(
        address owner,
        bytes32 identifier,
        DeviceTypes deviceType
    ) payable public {
        require(canRegister, "Registrations disabled");
        require(msg.value == deviceStake, "Not enough to stake");

        registeredDevices[owner] = DeviceInfo(identifier, deviceType, 255, 0, msg.value);
    }

    function registerProvider(
        address owner,
        bytes32 identifier,
        bytes32 endpoint,
        bytes8 mcc_mnc
    ) payable public {
        require(canRegister, "Registrations disabled");
        require(msg.value == providerStake, "Not enough to stake");

        registeredProviders[owner] = ProviderInfo(identifier, endpoint, mcc_mnc, ProviderTypes.Identity, 0, msg.value);
        mncToAddress[mcc_mnc] = owner;
    }

    function withdrawDevice() onlyDevices public {
        // Remove device and withdraw funds
    }

    function withdrawProvider() onlyProvider public {
        // Remove provider and withdraw funds
    }

    // Probably not a good idea for security reasons
    function deposit(address idp) onlyProvider public payable {
        require(msg.value > 0, "sent nothing");
        
        registeredProviders[idp].deposit += msg.value;
    }

    // Keeper-Only

    // VRF-Only
    /*function setRandomness(bytes32 requestId, uint256 randomValue) onlyOwner public {
        random = randomValue;
    }*/

    // Owner-Only
    function setOperatingFee(uint256 newFee) onlyOwner external {
        operatingFee = newFee;
    }

    function setBaseSubscriberFee(uint256 newFee) onlyOwner external {
        baseSubscriberFee = newFee;
    }

    function setActiveSubscriberThreshold(uint256 newThreshold) onlyOwner external {
        activeSubscriberThreshold = newThreshold;
    }

    function setTimeConnectedFee(uint256 newFee) onlyOwner external {
        timeConnectedFee = newFee;
    }

    function setCoverageMultiplier(uint256 newMultiplier) onlyOwner external {
        coverageMultiplier = newMultiplier;
    }
    
    function setDeviceStake(uint256 newStake) onlyOwner external {
        deviceStake = newStake;
    }

    function setProviderStake(uint256 newStake) onlyOwner external {
        providerStake = newStake;
    }

    function withdrawFees() onlyOwner external {

    }

    // Administration
    function removeDevice(address device) onlyOwner external {

    }

    function removeProvider(address provider) onlyOwner external {

    }

    // Toggle functions
    function toggleValidations() onlyOwner external {
        canValidate = !canValidate;
    }

    function toggleWithdraws() onlyOwner external {
        canWithdraw = !canWithdraw;
    }

    function toggleRegistrations() onlyOwner external {
        canRegister = !canRegister;
    }
    
    // Panic!
    function panic() onlyOwner external {
        // return everyone's funds

        canValidate = false;
        canRegister = false;
        canWithdraw = false;

        // Funds transfers
    }
}