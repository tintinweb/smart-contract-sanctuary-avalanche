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

contract DGNRTSairdrop5 is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
  bytes32 keyHash = 0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696;
  uint32 callbackGasLimit = 2500000;
  uint16 requestConfirmations = 25;
  uint32 numWords =  1;
  address[] public airdrop;
  uint[] public shuffled;
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  //event Shuffled(uint[] indexed result);

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  airdrop.push(0x83771c019a51462a3407C54345A02Dc8c6A85108);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0xfB16BBbE36e4630b2d351d6083E6e2e766948C04);
  airdrop.push(0x4416aC5643cE3263fcF0bE32556F1370795e5D8E);
  airdrop.push(0x5C83Cd1Da8da92e9165Bb1B5ebBdec9a06e5b97b);
  airdrop.push(0x6B59918Cfa9a4A360482b98E32bd0EBC61AEe89e);
  airdrop.push(0x5BEdfC16c6ff7c522b8EE480cb6d295ed5eF82ff);
  airdrop.push(0xF7D5782719690994374aB25F9efa334391770bE5);
  airdrop.push(0xE91E73b5F5D0640082107FE61d6381Bf6883CD1d);
  airdrop.push(0x9dd9580bF833601eCFD2B6cb290139b83788726e);
  airdrop.push(0x0AcE6Cb556E520962DF2800003209F5423f245aB);
  airdrop.push(0x65297329D0f727e0b644393595A0DCc68E069292);
  airdrop.push(0x9dd9580bF833601eCFD2B6cb290139b83788726e);
  airdrop.push(0xb6d3928BBf35339416eB4220Bd3657b2Fd74Eb63);
  airdrop.push(0x71164d7e34b9e0290E9ef77177d27E32E8beB711);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0x3b3ad18ffb699eae4bF7997c104a9b206adA9098);
  airdrop.push(0xfFcbe5A6D807D47deea491cFc9A606fDEdfD8eA3);
  airdrop.push(0x9A34c612884311c747cAcb0297d5D63005b08c6A);
  airdrop.push(0x1ddbCcFFB075f9242720554391D6CaB8084Ad2Fc);
  airdrop.push(0x46774553BB668C8ac854aa4dB5706f5c06fA7486);
  airdrop.push(0xC1e1Ef2A8246e6fD9Bec9f32a9df58CE1AEBDBe4);
  airdrop.push(0x112513F784019b701f5556eA3C9d2C086ffcBE07);
  airdrop.push(0xDEf4a6f5734638670fe4c726329cafbD1640234d);
  airdrop.push(0xb3Dc104a1C92eAD8AaC732D137A3Ac3D4031872B);
  airdrop.push(0x692622208552234FA37210cC8DC0b87D4c551aca);
  airdrop.push(0x6Acd6A4CB407bf6E66D566246c3A7FF9d64bEb82);
  airdrop.push(0x122025a645663a2891956d1F5096e8815e5Ec8dd);
  airdrop.push(0x587cAf20EC6FfB3E6a93738D99BAF87943D088Cf);
  airdrop.push(0xb29fC57A24fB71BC9ef194Ef4dD7461F22366a43);
  airdrop.push(0xfbF23F877C2DD8ef7847bF4427a2f87d3fA651fc);
  airdrop.push(0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0x18a7Fb33BE337E8983A21ADC06479Ae083CA4Fab);
  airdrop.push(0x7990fb2109B07a42dd40C19F6E86058298B57B9e);
  airdrop.push(0xC3656D178c208E82b4807c51f187c09677Ff222A);
  airdrop.push(0x2Bb65fDc4fD33263C373809Ff9B31d81c4cCF3e1);
  airdrop.push(0x74aA8b45270Cb70719070D008ec26FE568625f73);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xa9Ef1e763FDeAD5Eadc840e9118a65A47125F939);
  airdrop.push(0xf1376072AE0e2E114ce40A3b43609A46Ea99D348);
  airdrop.push(0xFaF4FAF993aD3257C4c8a7D26230Fb25d4d948Ba);
  airdrop.push(0xa05BC9d3367AF241C9c441f8F81f623B691F2a9E);
  airdrop.push(0x257B600b084b0b82Fb1A0A3caAD51b87fe16b15f);
  airdrop.push(0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c);
  airdrop.push(0xeaB70F918A7d8c7bFa096653D9D97bd5A4d68BF7);
  airdrop.push(0x90b1c0E539413E332d7e5d8Cccb199b76941EC8B);
  airdrop.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
  airdrop.push(0xfbF23F877C2DD8ef7847bF4427a2f87d3fA651fc);
  airdrop.push(0xB4222c36084CF38156AD4a0ebd6610C2C40a0bF2);
  airdrop.push(0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5);
  airdrop.push(0x1793d9B7ff6C67650828e912bD384EA19600435B);
  airdrop.push(0x824E67982F7238293326df40A4B1bfd943F8103a);
  airdrop.push(0x4E499588Fe9Fd9B509e2D153F51193EB508b83E0);
  airdrop.push(0xF1858E7c9c1027F777CfB6E3b504C0DBa84DCC41);
  airdrop.push(0x906A8B72E609C0372cfE380b37A672AD387501C8);
  airdrop.push(0xadeF3cB1f6B73a2C123E9510393d88e5bDe91035);
  airdrop.push(0x603a59c8e44bba7635FB8BEA59EaB53106865d89);
  airdrop.push(0x95Cc8d7fB66f07E2a1B723709b92e0D464653CC4);
  airdrop.push(0x90b1c0E539413E332d7e5d8Cccb199b76941EC8B);
  airdrop.push(0x906A8B72E609C0372cfE380b37A672AD387501C8);
  airdrop.push(0xF09F593383Fa8481a1a5D14E4349f8c927583C14);
  airdrop.push(0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c);
  airdrop.push(0x6165Bc2c1868ab3911B6FaD01800415c1BD552dd);
  airdrop.push(0xD7E3019B1dd5eE6475C480381f62995ba0B0e5FA);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0x9F1bC89f26829F620E379E19581eFf5474Fd52d1);
  airdrop.push(0x34ff3BE1c150eF0Fd05500C2663BBFC56D0152a7);
  airdrop.push(0xeaDDAAd6500dEb6b7aea9af6B0A378CD67557e40);
  airdrop.push(0x6eA39ae73291027Ec053a7856e681d26680a8679);
  airdrop.push(0xca2ee0d41F0293ca46404CE3825e26589D3De431);
  airdrop.push(0x9A34c612884311c747cAcb0297d5D63005b08c6A);
  airdrop.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  airdrop.push(0xc3a5E7BeAb2F963CDA5cCADEc64A9eAA86d8C253);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x37CE4BE6ccdE73A47A9117364571E2a71Acf956C);
  airdrop.push(0xf8fD2434AEd4b564c8623A62519dc87FbB61D83D);
  airdrop.push(0xf5ffB26AFBdb4a16f0812908c7863677174DE5fe);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0xf1EF6FaD71CbB3947F4CCaE862817A5e110a17F0);
  airdrop.push(0x74aA8b45270Cb70719070D008ec26FE568625f73);
  airdrop.push(0xAe47114394a05D927BB54Ef2e468377b3Fc1458F);
  airdrop.push(0xdfF601647CCbC6317f6314bDF20129F74c37B1B2);
  airdrop.push(0x2Adf8c8B31809418f6ca45866cF1E4d2d73577BB);
  airdrop.push(0x618711478689a68aA547480c2D9ba72FBFC31774);
  airdrop.push(0xB70219C02CA65F257079370CE34CDCAfF837E7CD);
  airdrop.push(0x85E6cC88F3055b589eb1d4030863be2CFcc0763E);
  airdrop.push(0x1D38DD297F253837eF2b763BA9fE2EeCe45c48e4);
  airdrop.push(0x883ce32E186c69559E94C8BA276BfC4322Fc194a);
  airdrop.push(0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a);
  airdrop.push(0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a);
  airdrop.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
  airdrop.push(0x52Fc297ce072148A99bc0D6A2D8a8D34Ae0b145d);
  airdrop.push(0xDCB213eDE09Bdd3b3A0a4eBA7b5B21F81e000a97);
  airdrop.push(0x9e0F57C62c4C26Dc9122fc5981aC3D411220a899);
  airdrop.push(0x28655edB9Ee26AC115A12984B9Bdb5B4Bd69BB36);
  airdrop.push(0x3Ecb35b0012B71f04dfA994D6dea750a17CfF0b3);
  airdrop.push(0x217d1a1c13a128Eeda6A98C8bE08FcA9BC3E73c2);
  airdrop.push(0x883ce32E186c69559E94C8BA276BfC4322Fc194a);
  airdrop.push(0xe80113462D62b791B9EaEe68824c6531d0479881);
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
           result[i] = i + 1148;
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
    shuffled = shuffle(airdrop.length, s_randomWords[0]);
    //emit Shuffled(shuffled, s_randomWords[0]));
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }
}