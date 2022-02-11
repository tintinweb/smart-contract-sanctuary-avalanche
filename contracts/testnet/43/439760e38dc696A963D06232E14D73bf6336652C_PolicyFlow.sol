// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/Ownable.sol";

import "../tokens/interfaces/IBuyerToken.sol";
import "./interfaces/ISigManager.sol";
import "./interfaces/IFDPolicyToken.sol";
import "./interfaces/IFlightOracle.sol";
import "./interfaces/IInsurancePool.sol";

import "./interfaces/IPolicyStruct.sol";
import "./abstracts/PolicyParameters.sol";

contract PolicyFlow is IPolicyStruct, PolicyParameters, Ownable {
    // Other contracts
    IBuyerToken public buyerToken;
    ISigManager public sigManager;
    IFDPolicyToken public policyToken;
    IFlightOracle public flightOracle;
    IInsurancePool public insurancePool;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    string public FLIGHT_STATUS_URL =
        "https://18.163.254.50:3207/flight_status?";

    uint256 public totalPolicies;

    uint256 public fee;

    mapping(uint256 => PolicyInfo) public policyList;

    mapping(address => uint256[]) userPolicyList;

    mapping(bytes32 => uint256) requestList;

    mapping(uint256 => uint256) delayResultList;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event FeeChanged(uint256 newFee);
    event MaxPayoffChanged(uint256 newMaxPayoff);
    event MinTimeBeforeDepartureChanged(uint256 newMinTime);
    event FlightOracleChanged(address newOracle);
    event OracleUrlChanged(string newUrl);
    event DelayThresholdChanged(uint256 thresholdMin, uint256 thresholdMax);

    event NewPolicyApplication(uint256 _policyID, address indexed user);
    event PolicySold(uint256 policyID, address indexed user);
    event PolicyDeclined(uint256 policyID, address indexed user);
    event PolicyClaimed(uint256 policyID, address indexed user);
    event PolicyExpired(uint256 policyID, address indexed user);
    event FulfilledOracleRequest(uint256 policyId, bytes32 requestId);
    event PolicyOwnerTransfer(uint256 indexed tokenId, address newOwner);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(
        address _insurancePool,
        address _policyToken,
        address _sigManager,
        address _buyerToken
    ) {
        insurancePool = IInsurancePool(_insurancePool);
        policyToken = IFDPolicyToken(_policyToken);
        sigManager = ISigManager(_sigManager);
        buyerToken = IBuyerToken(_buyerToken);

        fee = 0.1 * 10**18;
    }

    // ----------------------------------------------------------------------------------- //
    // ************************************ Modifiers ************************************ //
    // ----------------------------------------------------------------------------------- //

    /**
     * @dev This modifier uses assert which means this error should never happens.
     */
    modifier validAddress() {
        assert(msg.sender != address(0));
        _;
    }

    // ----------------------------------------------------------------------------------- //
    // ********************************* View Functions ********************************** //
    // ----------------------------------------------------------------------------------- //

    /**
     * @notice Show a user's policies (all)
     * @param _user User's address
     * @return userPolicies User's all policy details
     */
    function viewUserPolicy(address _user)
        external
        view
        returns (PolicyInfo[] memory)
    {
        uint256 userPolicyAmount = userPolicyList[_user].length;
        require(userPolicyAmount > 0, "No policy for this user");

        PolicyInfo[] memory result = new PolicyInfo[](userPolicyAmount);

        for (uint256 i = 0; i < userPolicyAmount; i++) {
            uint256 policyId = userPolicyList[_user][i];

            result[i] = policyList[policyId];
        }
        return result;
    }

    /**
     * @notice Get the policyInfo from its count/order
     * @param _policyId Total count/order of the policy = NFT tokenId
     * @return policy A struct of information about this policy
     */
    // TODO: If still need this function
    function getPolicyInfoById(uint256 _policyId)
        public
        view
        returns (PolicyInfo memory policy)
    {
        policy = policyList[_policyId];
    }

    /**
     * @notice Get the policy buyer by policyId
     * @param _policyId Unique policy Id (uint256)
     * @return buyerAddress The buyer of this policy
     */
    // TODO: If still need this function
    function findPolicyBuyerById(uint256 _policyId)
        public
        view
        returns (address buyerAddress)
    {
        buyerAddress = policyList[_policyId].buyerAddress;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Change the oracle fee
     * @param _fee New oracle fee
     */
    function changeFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeChanged(_fee);
    }

    /**
     * @notice Change the max payoff
     * @param _newMaxPayoff New maxpayoff amount
     */
    function changeMaxPayoff(uint256 _newMaxPayoff) external onlyOwner {
        MAX_PAYOFF = _newMaxPayoff;
        emit MaxPayoffChanged(_newMaxPayoff);
    }

    /**
     * @notice How long before departure when users can not buy new policies
     * @param _newMinTime New time set
     */
    function changeMinTimeBeforeDeparture(uint256 _newMinTime)
        external
        onlyOwner
    {
        MIN_TIME_BEFORE_DEPARTURE = _newMinTime;
        emit MinTimeBeforeDepartureChanged(_newMinTime);
    }

    /**
     * @notice Change the oracle address
     * @param _oracleAddress New oracle address
     */
    function setFlightOracle(address _oracleAddress) external onlyOwner {
        flightOracle = IFlightOracle(_oracleAddress);
        emit FlightOracleChanged(_oracleAddress);
    }

    /**
     * @notice Set a new url
     */
    function setURL(string memory _url) external onlyOwner {
        FLIGHT_STATUS_URL = _url;
        emit OracleUrlChanged(_url);
    }

    /**
     * @notice Set the new delay threshold used for calculating payoff
     * @param _thresholdMin New minimum threshold
     * @param _thresholdMax New maximum threshold
     */
    function setDelayThreshold(uint256 _thresholdMin, uint256 _thresholdMax)
        external
        onlyOwner
    {
        DELAY_THRESHOLD_MIN = _thresholdMin;
        DELAY_THRESHOLD_MAX = _thresholdMax;
        emit DelayThresholdChanged(_thresholdMin, _thresholdMax);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Buy a new flight delay policy
     * @dev The transaction should have the signature from the backend server
     * @param _productId ID of the purchased product (0: flightdelay; 1,2,3...: others)
     * @param _flightNumber Flight number in string (e.g. "AQ1299")
     * @param _premium Premium of this policy (decimals: 18)
     * @param _departureTimestamp Departure date of this flight (unix timestamp in s, not ms!)
     * @param _landingDate Landing date of this flight (uinx timestamp in s, not ms!)
     * @param _deadline Deadline for this purchase request
     * @param signature Use web3.eth.sign(hash(data), account) to generate the signature
     */
    function newApplication(
        uint256 _productId,
        string memory _flightNumber,
        uint256 _premium,
        uint256 _departureTimestamp,
        uint256 _landingDate,
        uint256 _deadline,
        bytes calldata signature
    ) public returns (uint256 _policyId) {
        uint256 currentTimestamp = block.timestamp;
        require(
            currentTimestamp <= _deadline,
            "Expired deadline, please resubmit a transaction"
        );

        require(
            _productId == PRODUCT_ID,
            "You are calling the wrong product contract"
        );

        require(
            _departureTimestamp >= currentTimestamp + MIN_TIME_BEFORE_DEPARTURE,
            "It's too close to the departure time, you cannot buy this policy"
        );

        // Should be signed by operators
        _checkSignature(
            signature,
            _flightNumber,
            _msgSender(),
            _premium,
            _deadline
        );

        // Generate the policy
        uint256 currentPolicyId = totalPolicies;
        policyList[currentPolicyId] = PolicyInfo(
            PRODUCT_ID,
            _msgSender(),
            currentPolicyId,
            _flightNumber,
            _premium,
            MAX_PAYOFF,
            currentTimestamp,
            _departureTimestamp,
            _landingDate,
            PolicyStatus.INI,
            false,
            404
        );

        // Check the policy with the insurance pool status
        // May be accepted or rejected, if accepted then update the status of insurancePool
        _policyCheck(_premium, MAX_PAYOFF, msg.sender, currentPolicyId);

        // Give buyer tokens depending on the usd value they spent
        buyerToken.mintBuyerToken(msg.sender, _premium);

        // Store the policy's total order with userAddress
        userPolicyList[msg.sender].push(totalPolicies);

        // Update total policies
        totalPolicies += 1;

        emit NewPolicyApplication(currentPolicyId, msg.sender);

        return currentPolicyId;
    }

    /** @notice Make a claim request
     *  @param _policyId The total order/id of the policy
     *  @param _flightNumber The flight number
     *  @param _timestamp The flight departure timestamp
     *  @param _path Which data in json needs to get
     *  @param _forceUpdate Owner can force to update
     */
    function newClaimRequest(
        uint256 _policyId,
        string memory _flightNumber,
        string memory _timestamp,
        string memory _path,
        bool _forceUpdate
    ) public {
        // Can not get the result before landing date
        // Landing date may not be true, may be a fixed interval (4hours)
        require(
            block.timestamp >= policyList[_policyId].landingTimestamp,
            "Can only claim a policy after its expected landing timestamp"
        );

        // Check if the policy has been settled
        require(
            (!policyList[_policyId].alreadySettled) ||
                (_forceUpdate && (_msgSender() == owner())),
            "The policy status has already been settled, or you need to make a force update"
        );

        // Check if the flight number is correct
        require(
            keccak256(abi.encodePacked(_flightNumber)) ==
                keccak256(abi.encodePacked(policyList[_policyId].flightNumber)),
            "Wrong flight number provided"
        );

        // Check if the departure date is correct
        // require(
        //     keccak256(abi.encodePacked(_timestamp)) ==
        //         keccak256(
        //             abi.encodePacked(policyList[_policyId].departureTimestamp)
        //         ),
        //     "Wrong departure timestamp provided"
        // );

        // Construct the url for oracle
        string memory _url = string(
            abi.encodePacked(
                FLIGHT_STATUS_URL,
                "flight_no=",
                _flightNumber,
                "&timestamp=",
                _timestamp
            )
        );

        // Start a new oracle request
        bytes32 requestId = flightOracle.newOracleRequest(fee, _url, _path, 1);

        // Record this request
        requestList[requestId] = _policyId;
        policyList[_policyId].alreadySettled = true;
    }

    /**
     * @notice Update information when a policy token's ownership has been transferred
     * @dev This function is called by the ERC721 contract of PolicyToken
     * @param _tokenId Token Id of the policy token
     * @param _oldOwner The initial owner
     * @param _newOwner The new owner
     */
    function policyOwnerTransfer(
        uint256 _tokenId,
        address _oldOwner,
        address _newOwner
    ) external {
        // Check the call is from policy token contract
        require(
            _msgSender() == address(policyToken),
            "only called from the flight delay policy token contract"
        );

        // Check the previous owner record
        uint256 policyId = _tokenId;
        require(
            _oldOwner == policyList[policyId].buyerAddress,
            "The previous owner is wrong"
        );

        // Update the new buyer address
        policyList[policyId].buyerAddress = _newOwner;
        emit PolicyOwnerTransfer(_tokenId, _newOwner);
    }

    // ----------------------------------------------------------------------------------- //
    // ********************************* Oracle Functions ******************************** //
    // ----------------------------------------------------------------------------------- //

    /**
     * @notice Do the final settlement, called by FlightOracle contract
     * @param _requestId Chainlink request id
     * @param _result Delay result (minutes) given by oracle
     */
    function finalSettlement(bytes32 _requestId, uint256 _result) public {
        // Check if the call is from flight oracle
        require(
            msg.sender == address(flightOracle),
            "this function should be called by FlightOracle contract"
        );

        uint256 policyId = requestList[_requestId];

        PolicyInfo storage policy = policyList[policyId];
        policy.delayResult = _result;

        uint256 premium = policy.premium;
        address buyerAddress = policy.buyerAddress;

        require(
            _result <= DELAY_THRESHOLD_MAX || _result == 400,
            "Abnormal oracle result, result should be [0 - 240] or 400"
        );

        if (_result == 0) {
            // 0: on time
            policyExpired(premium, MAX_PAYOFF, buyerAddress, policyId);
        } else if (_result <= DELAY_THRESHOLD_MAX) {
            uint256 real_payoff = calcPayoff(_result);
            _policyClaimed(premium, real_payoff, buyerAddress, policyId);
        } else if (_result == 400) {
            // 400: cancelled
            _policyClaimed(premium, MAX_PAYOFF, buyerAddress, policyId);
        }

        emit FulfilledOracleRequest(policyId, _requestId);
    }

    // ----------------------------------------------------------------------------------- //
    // ******************************** Internal Functions ******************************* //
    // ----------------------------------------------------------------------------------- //

    /**
     * @notice check the policy and then determine whether we can afford it
     * @param _payoff the payoff of the policy sold
     * @param _user user's address
     * @param _policyId the unique policy ID
     */
    function _policyCheck(
        uint256 _premium,
        uint256 _payoff,
        address _user,
        uint256 _policyId
    ) internal {
        // Whether there are enough capacity in the pool
        bool _isAccepted = insurancePool.checkCapacity(_payoff);

        if (_isAccepted) {
            insurancePool.updateWhenBuy(_premium, _payoff, _user);
            policyList[_policyId].status = PolicyStatus.SOLD;
            emit PolicySold(_policyId, _user);

            policyToken.mintPolicyToken(_user);
        } else {
            policyList[_policyId].status = PolicyStatus.DECLINED;
            emit PolicyDeclined(_policyId, _user);
            revert("not sufficient capacity in the insurance pool");
        }
    }

    /**
     * @notice update the policy when it is expired
     * @param _premium the premium of the policy sold
     * @param _payoff the payoff of the policy sold
     * @param _user user's address
     * @param _policyId the unique policy ID
     */
    function policyExpired(
        uint256 _premium,
        uint256 _payoff,
        address _user,
        uint256 _policyId
    ) internal {
        insurancePool.updateWhenExpire(_premium, _payoff, _user);
        policyList[_policyId].status = PolicyStatus.EXPIRED;
        emit PolicyExpired(_policyId, _user);
    }

    /**
     * @notice Update the policy when it is claimed
     * @param _premium Premium of the policy sold
     * @param _payoff Payoff of the policy sold
     * @param _user User's address
     * @param _policyId The unique policy ID
     */
    function _policyClaimed(
        uint256 _premium,
        uint256 _payoff,
        address _user,
        uint256 _policyId
    ) internal {
        insurancePool.payClaim(_premium, MAX_PAYOFF, _payoff, _user);
        policyList[_policyId].status = PolicyStatus.CLAIMED;
        emit PolicyClaimed(_policyId, _user);
    }

    /**
     * @notice The payoff formula
     * @param _delay Delay in minutes
     * @return the final payoff volume
     */
    function calcPayoff(uint256 _delay) internal view returns (uint256) {
        uint256 payoff = 0;

        // payoff model 1 - linear
        if (_delay <= DELAY_THRESHOLD_MIN) {
            payoff = 0;
        } else if (
            _delay > DELAY_THRESHOLD_MIN && _delay <= DELAY_THRESHOLD_MAX
        ) {
            payoff = (_delay * _delay) / 480;
        } else if (_delay > DELAY_THRESHOLD_MAX) {
            payoff = MAX_PAYOFF;
        }

        payoff = payoff * 1e18;
        return payoff;
    }

    /**
     * @notice Check whether the signature is valid
     * @param signature 65 byte array: [[v (1)], [r (32)], [s (32)]]
     * @param _flightNumber Flight number
     * @param _address userAddress
     * @param _premium Premium of the policy
     * @param _deadline Deadline of the application
     */
    function _checkSignature(
        bytes calldata signature,
        string memory _flightNumber,
        address _address,
        uint256 _premium,
        uint256 _deadline
    ) internal view {
        sigManager.checkSignature(
            signature,
            _flightNumber,
            _address,
            _premium,
            _deadline
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * @dev    Renouncing ownership will leave the contract without an owner,
     *         thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     * @param  newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Internal function without access restriction.
     * @param  newOwner Address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBuyerToken is IERC20 {
    // ---------------------------------------------------------------------------------------- //
    // *************************************** Functions ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Mint buyer tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be minted
     */
    function mintBuyerToken(address _account, uint256 _amount) external;

    /**
     * @notice Burn buyer tokens
     * @param  _account Receiver's address
     * @param  _amount Amount to be burned
     */
    function burnBuyerToken(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISigManager {
    event SignerAdded(address indexed _newSigner);
    event SignerRemoved(address indexed _oldSigner);

    function addSigner(address) external;

    function removeSigner(address) external;

    function isValidSigner(address) external view returns (bool);

    function checkSignature(
        bytes calldata signature,
        string memory _flightNumber,
        address _address,
        uint256 _premium,
        uint256 _deadline
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IFDPolicyToken is IERC721Enumerable {
    function mintPolicyToken(address _receiver) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function getTokenURI(uint256 _tokenId)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFlightOracle {
    function newOracleRequest(
        uint256 _payment,
        string memory _url,
        string memory _path,
        int256 times
    ) external returns (bytes32);

    // Set a new url
    function setURL(string memory _url) external;

    // Set the oracle address
    function setOracleAddress(address _newOracle) external;

    // Set a new job id
    function setJobId(bytes32 _newJobId) external;

    // Set a new policy flow
    function setPolicyFlow(address _policyFlow) external;

    function getChainlinkTokenAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IInsurancePool {
    // view functions

    function getUserBalance(address) external view returns (uint256);

    function getPoolUnlocked() external view returns (uint256);

    function getUnlockedFor(address _user)
        external
        view
        returns (uint256);

    function getLockedFor(address _user) external view returns (uint256);

    function checkCapacity(uint256 _payoff) external view returns (bool);

    // set functions

    function setPurchaseIncentive(uint256 _newIncentive) external;

    function setFrozenTime(uint256 _newFrozenTime) external;

    function setPolicyFlow(address _policyFlowAddress) external;

    function setIncomeDistribution(uint256[3] memory _newDistribution) external;

    function setCollateralFactor(uint256 _factor) external;

    function transferOwnership(address _newOwner) external;

    // main functions

    function stake(address _user, uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function unstakeMax() external;

    function updateWhenBuy(
        uint256 _premium,
        uint256 _payoff,
        address _user
    ) external;

    function updateWhenExpire(
        uint256 _premium,
        uint256 _payoff,
        address _user
    ) external;

    function payClaim(
        uint256 _premium,
        uint256 _payoff,
        uint256 _realPayoff,
        address _user
    ) external;

    function revertUnstakeRequest(address _user) external;

    function revertAllUnstakeRequest(address _user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPolicyStruct {
    enum PolicyStatus {
        INI,
        SOLD,
        DECLINED,
        EXPIRED,
        CLAIMED
    }

    struct PolicyInfo {
        uint256 productId;
        address buyerAddress;
        uint256 policyId;
        string flightNumber;
        uint256 premium;
        uint256 payoff;
        uint256 purchaseTimestamp;
        uint256 departureTimestamp;
        uint256 landingTimestamp;
        PolicyStatus status;
        bool alreadySettled;
        uint256 delayResult;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract PolicyParameters {
    // Product parameter
    uint256 public constant PRODUCT_ID = 0;

    // Parameters about the claim curve
    uint256 public MAX_PAYOFF = 180 ether;
    uint256 public DELAY_THRESHOLD_MIN = 30;
    uint256 public DELAY_THRESHOLD_MAX = 240;

    // Minimum time before departure for applying
    // TODO: internal test
    uint256 public MIN_TIME_BEFORE_DEPARTURE = 0;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.10;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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