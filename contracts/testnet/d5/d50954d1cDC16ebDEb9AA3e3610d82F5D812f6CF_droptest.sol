/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

pragma solidity ^0.8.7;

contract droptest is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
  bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
  uint32 callbackGasLimit = 2500000;
  uint16 requestConfirmations = 15;
  uint32 numWords =  1;
  address[] public contestants;
  uint[] public shuffled;
  uint256 public s_randomRange;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  //event Shuffled(uint[] indexed result);

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
    contestants.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
    contestants.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
    contestants.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  }
  
  function shuffle(
        uint size, 
        uint entropy
    ) 
    private  
    pure
    returns (
        uint[] memory
    ) {
        uint[] memory result = new uint[](size); 
        
        // Initialize array.
        for (uint i = 0; i < size; i++) {
           result[i] = i + 1;
        }
        
        // Set the initial randomness based on the provided entropy.
        bytes32 random = keccak256(abi.encodePacked(entropy));
        
        // Set the last item of the array which will be swapped.
        uint last_item = size - 1;
        
        // We need to do `size - 1` iterations to completely shuffle the array.
        for (uint i = 1; i < size - 1; i++) {
            // Select a number based on the randomness.
            uint selected_item = uint(random) % last_item;
            
            // Swap items `selected_item <> last_item`.
            uint aux = result[last_item];
            result[last_item] = result[selected_item];
            result[selected_item] = aux;
        
            // Decrease the size of the possible shuffle
            // to preserve the already shuffled items.
            // The already shuffled items are at the end of the array.
            last_item--;
            
            // Generate new randomness.
            random = keccak256(abi.encodePacked(random));
        }
        
        return result;
    }

  function requestRandomWords() external onlyOwner {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomRange = (randomWords[748] % 847) + 1;
    // Save it to 'shuffled'
    shuffled = shuffle(contestants.length, s_randomWords[0]);
    //emit Shuffled(shuffled, s_randomWords[0]));
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}