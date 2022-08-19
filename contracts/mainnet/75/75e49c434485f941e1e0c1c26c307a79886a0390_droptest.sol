/**
 *Submitted for verification at snowtrace.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: contracts/droptest.sol


pragma solidity ^0.8.7;



contract droptest is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
  bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
  uint32 callbackGasLimit = 2500000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;
  address[] public contestants;
  uint[] public shuffled;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  //event Shuffled(uint[] indexed result);

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    // Simulate whitelisting 5 contestant addresses
  contestants.push(0x6C882e9Fe244344F635D5C49bE1276138e6f40E2);
  contestants.push(0x0CB2A2dcD489f3FDf4e1a9156DCe2573CdcD32a5);
  contestants.push(0xdfF601647CCbC6317f6314bDF20129F74c37B1B2);
  contestants.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
  contestants.push(0x467bfc00c09237977b85E4eC82Ec02b38c524529);
  contestants.push(0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5);
  contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  contestants.push(0xf1EF6FaD71CbB3947F4CCaE862817A5e110a17F0);
  contestants.push(0x906A8B72E609C0372cfE380b37A672AD387501C8);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0x845C36aCb8133Bc0a50b4FB432356647367d5081);
  contestants.push(0xb816d4785B0a9a3939aeF97198a9C26Cb3d5e143);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0x62B9D72D55C63F443a8206c6fB88B7D3DD2ad159);
  contestants.push(0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5);
  contestants.push(0x95e4f2Ba1299e2A91654495A4b2C58d96B55E45A);
  contestants.push(0xf1EF6FaD71CbB3947F4CCaE862817A5e110a17F0);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0x4e99CC69BBD2611ca4cCFA621C2370C1aE95359b);
  contestants.push(0x2BC4848d787512d79cE71739D93638067e2a5161);
  contestants.push(0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a);
  contestants.push(0x11d2E8c447b1262b6b6676d1020D1Beb1B4bF611);
  contestants.push(0x6EC6875f2E9958F64Df8f05D123DCfa3ABDF3BB8);
  contestants.push(0x84A642d8F5aF837256eAC4c46264a0d53D66Fd65);
  contestants.push(0x563Ac2A4f1ef0FD6Bc0F9eCD4A7939a731fc8683);
  contestants.push(0xA24fCDfF33C0C4Ab0129Cc72B58A9BcAcf85B932);
  contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
  contestants.push(0x824E67982F7238293326df40A4B1bfd943F8103a);
  contestants.push(0xd45DA880CCba56527f943862835176C84a6c2A3D);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0xf85301143cABbD7AEDA500b480a8dAc24C051634);
  contestants.push(0xF09F593383Fa8481a1a5D14E4349f8c927583C14);
  contestants.push(0x4f96C32B9EC8DfCB04Ada96Ff6BDc81f92C1F81C);
  contestants.push(0x257B600b084b0b82Fb1A0A3caAD51b87fe16b15f);
  contestants.push(0xAe47114394a05D927BB54Ef2e468377b3Fc1458F);
  contestants.push(0xb29fC57A24fB71BC9ef194Ef4dD7461F22366a43);
  contestants.push(0xfB16BBbE36e4630b2d351d6083E6e2e766948C04);
  contestants.push(0x4E499588Fe9Fd9B509e2D153F51193EB508b83E0);
  contestants.push(0x6B59918Cfa9a4A360482b98E32bd0EBC61AEe89e);
  contestants.push(0xfc4755e96E7a935d72f7181AdB0aE8B683d5D467);
  contestants.push(0x587cAf20EC6FfB3E6a93738D99BAF87943D088Cf);
  contestants.push(0x9467135a90023C731803289676302FA18E75F5fe);
  contestants.push(0xb7Aa0094Dc0e47107301300cFBA780690660F7Be);
  contestants.push(0x93E05D9B8A40cF5e63B748782450b29b49db93da);
  contestants.push(0xbB2BE69428bc1b318f0f8d261221290cd7c9FE9b);
  contestants.push(0x1892cd42F514DB1002F9A33d34AB9E625F3a6B61);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0xc3a5E7BeAb2F963CDA5cCADEc64A9eAA86d8C253);
  contestants.push(0xCFC76EBe6B57fd8EDFA33C5794386da4e3be9F76);
  contestants.push(0xDEf4a6f5734638670fe4c726329cafbD1640234d);
  contestants.push(0x35268017d6fb589C91B88515B4fdF3BF65f1EfE3);
  contestants.push(0xAaab39aFE5bf887c12F20117E63334f257dFA211);
  contestants.push(0x1806375191422C16372165EB69b1D5Fe773c3101);
  contestants.push(0xAa7c3D6dBa1997B0087930D8E60bCbAd24119E66);
  contestants.push(0xB747D0713E54a3322806e0F828A76a970D90A7a5);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0xeBE8CBE0597BF8464e7e992b425b439F7b82e258);
  contestants.push(0xafa3CB4Aed86B03C850144455bd89bedeAE17eCf);
  contestants.push(0x5883Ef1414D389C1109F14f042486ec710852999);
  contestants.push(0x3539580eeF6AeA74f540BBC081ad60CCF9E5Ee94);
  contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  contestants.push(0x7663F1E0879f1C20Dd6caD7452100699Fda0bdAc);
  contestants.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
  contestants.push(0x5C83Cd1Da8da92e9165Bb1B5ebBdec9a06e5b97b);
  contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  contestants.push(0x9A34c612884311c747cAcb0297d5D63005b08c6A);
  contestants.push(0x9e0F57C62c4C26Dc9122fc5981aC3D411220a899);
  contestants.push(0x1a3c34b26E0F812Fe7496667902A6F18FF053833);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0xe8EA5feef30b2d839562c7FAc184AF5898fCEb65);
  contestants.push(0x257B600b084b0b82Fb1A0A3caAD51b87fe16b15f);
  contestants.push(0xfc4755e96E7a935d72f7181AdB0aE8B683d5D467);
  contestants.push(0xA8C1C346fDcDa249fEF8aDE52c8912de7E817970);
  contestants.push(0xf1EF6FaD71CbB3947F4CCaE862817A5e110a17F0);
  contestants.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  contestants.push(0x6EC6875f2E9958F64Df8f05D123DCfa3ABDF3BB8);
  contestants.push(0xCe5F967FDCbaB1ff86B8A7B632Df33d6806C1A1b);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0xa3872bB17bEd808915C5594814D127864e310b1B);
  contestants.push(0x119460eCc4C538a02307e5D4f687BB83eDdC5cf9);
  contestants.push(0xA7FaBf8A569335ad4eB5586DCe6f03FAcDf61d01);
  contestants.push(0xf8fD2434AEd4b564c8623A62519dc87FbB61D83D);
  contestants.push(0x4fb9F8B671C3D23921d749cA9066fEB9Dcbd34c8);
  contestants.push(0x824E67982F7238293326df40A4B1bfd943F8103a);
  contestants.push(0xF9856EAE71B956C6eb2Bec6cE437375F84BC9178);
  contestants.push(0x12cdfacFaD33C30F81B8f3B85EA50A7c357dcC1B);
  contestants.push(0xf1496644aaD7Ade10c229E1813a0ea4f2B56221e);
  contestants.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  contestants.push(0x95Cc8d7fB66f07E2a1B723709b92e0D464653CC4);
  contestants.push(0x6213fD5a700d1a059E2fb05077c5Bd1E626Ed9F3);
  contestants.push(0x1ddbCcFFB075f9242720554391D6CaB8084Ad2Fc);
  contestants.push(0xDEf4a6f5734638670fe4c726329cafbD1640234d);
  contestants.push(0xca2ee0d41F0293ca46404CE3825e26589D3De431);
  contestants.push(0x3Ecb35b0012B71f04dfA994D6dea750a17CfF0b3);
  contestants.push(0xB833DD536e9B1B82757e1d457714D048c7bBC0EB);
  contestants.push(0x60A0019F67ca72EfA41d8B6cA06a25ED5c7D1c44);
  contestants.push(0xb29fC57A24fB71BC9ef194Ef4dD7461F22366a43);
  contestants.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
  contestants.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  contestants.push(0x11d2E8c447b1262b6b6676d1020D1Beb1B4bF611);
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
           result[i] = i + 748;
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
    s_randomWords = randomWords;
    // Save it to 'shuffled'
    shuffled = shuffle(contestants.length, s_randomWords[0]);
    //emit Shuffled(shuffled, s_randomWords[0]));
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}