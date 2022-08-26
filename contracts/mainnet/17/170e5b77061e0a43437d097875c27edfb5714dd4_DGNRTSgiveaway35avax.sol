/**
 *Submitted for verification at snowtrace.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

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


    
    contract DGNRTSgiveaway35avax is VRFConsumerBaseV2 {
        address [] public addresses = [
            0x0252dFbad3169ea16665d668af107D5e217579fa,
            0xF70E7013D4eDD78698447bfB58696e7f386BC67C,
            0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42,
            0x16763494C398e72a58B9802b8204E07a62C1C7De,
            0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA,
            0x4cD35473b99125eC4A028081CEc28AA2eB5eef84,
            0x6B59918Cfa9a4A360482b98E32bd0EBC61AEe89e,
            0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a,
            0x90b1c0E539413E332d7e5d8Cccb199b76941EC8B,
            0x9467135a90023C731803289676302FA18E75F5fe,
            0xfFcbe5A6D807D47deea491cFc9A606fDEdfD8eA3,
            0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c,
            0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5,
            0xA24fCDfF33C0C4Ab0129Cc72B58A9BcAcf85B932,
            0xB70219C02CA65F257079370CE34CDCAfF837E7CD,
            0xB833DD536e9B1B82757e1d457714D048c7bBC0EB,
            0xDEf4a6f5734638670fe4c726329cafbD1640234d,
            0x02482370dEaaE6443Af0f8bD19c4345D92364900,
            0x112513F784019b701f5556eA3C9d2C086ffcBE07,
            0x11d2E8c447b1262b6b6676d1020D1Beb1B4bF611,
            0x1892cd42F514DB1002F9A33d34AB9E625F3a6B61,
            0x18a7Fb33BE337E8983A21ADC06479Ae083CA4Fab,
            0x1a3c34b26E0F812Fe7496667902A6F18FF053833,
            0x1ddbCcFFB075f9242720554391D6CaB8084Ad2Fc,
            0x257B600b084b0b82Fb1A0A3caAD51b87fe16b15f,
            0x28655edB9Ee26AC115A12984B9Bdb5B4Bd69BB36,
            0x2bA4BfBF7b9Bc71223cBA2B8F19Ca49A696dA9e8,
            0x2BDEC7d5D1f137393880dA3D220A4a75436000f1,
            0x4416aC5643cE3263fcF0bE32556F1370795e5D8E,
            0x513390c09A07b1d659f4eF61c8011691c26909aF,
            0x52Fc297ce072148A99bc0D6A2D8a8D34Ae0b145d,
            0x587cAf20EC6FfB3E6a93738D99BAF87943D088Cf,
            0x5BEdfC16c6ff7c522b8EE480cb6d295ed5eF82ff,
            0x5C83Cd1Da8da92e9165Bb1B5ebBdec9a06e5b97b,
            0x6213fD5a700d1a059E2fb05077c5Bd1E626Ed9F3,
            0x74aA8b45270Cb70719070D008ec26FE568625f73,
            0x824E67982F7238293326df40A4B1bfd943F8103a,
            0x85a3d5b0405589E700b3153D294a1B92eb9e2e41,
            0x883ce32E186c69559E94C8BA276BfC4322Fc194a,
            0x906A8B72E609C0372cfE380b37A672AD387501C8,
            0x95e4f2Ba1299e2A91654495A4b2C58d96B55E45A,
            0x9dd9580bF833601eCFD2B6cb290139b83788726e,
            0x9e0F57C62c4C26Dc9122fc5981aC3D411220a899,
            0xa19801bB2b3A8239466811913088745fb76799ae,
            0xA7FaBf8A569335ad4eB5586DCe6f03FAcDf61d01,
            0xAe47114394a05D927BB54Ef2e468377b3Fc1458F,
            0xb29fC57A24fB71BC9ef194Ef4dD7461F22366a43,
            0xbC8B718bFb350629eBBDbffC97e58cd156c6308d,
            0xc3a5E7BeAb2F963CDA5cCADEc64A9eAA86d8C253,
            0xc428f9484b574EBB1B3f84Be45E425413AEC18a2,
            0xCe5F967FDCbaB1ff86B8A7B632Df33d6806C1A1b,
            0xDCB213eDE09Bdd3b3A0a4eBA7b5B21F81e000a97,
            0xdfF601647CCbC6317f6314bDF20129F74c37B1B2,
            0xE561fdBCeaa225Ccfa080bCD4D84382e27f6D9d9,
            0xeaDDAAd6500dEb6b7aea9af6B0A378CD67557e40,
            0xF09F593383Fa8481a1a5D14E4349f8c927583C14,
            0xf1496644aaD7Ade10c229E1813a0ea4f2B56221e,
            0xf1EF6FaD71CbB3947F4CCaE862817A5e110a17F0,
            0xF523120d8310c004ab35654DC08bB9b4b2f83361,
            0xF5b882cae990AA9BDA8fAE39BDd9f72554A3F989,
            0xF9856EAE71B956C6eb2Bec6cE437375F84BC9178,
            0xfbF23F877C2DD8ef7847bF4427a2f87d3fA651fc
        ];
        mapping (uint256 => address) public games;
        address public winner;
        event Winner(
            address indexed winner,
            uint256 gameId
        );
    
        VRFCoordinatorV2Interface COORDINATOR;
    
        // Your subscription ID.
        uint64 s_subscriptionId;
    
        // Rinkeby coordinator. For other networks,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        address vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash = 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d;
    
        // Depends on the number of requested values that you want sent to the
        // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
        // so 100,000 is a safe default for this example contract. Test and adjust
        // this limit based on the network that you select, the size of the request,
        // and the processing of the callback request in the fulfillRandomWords()
        // function.
        uint32 callbackGasLimit = 2500000;
    
        // The default is 3, but you can set this higher.
        uint16 requestConfirmations = 20;
    
        // For this example, retrieve 2 random values in one request.
        // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
        uint32 numRandoms =  1;
    
        uint256 public s_requestId;
        address s_owner;
    
        constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
            COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
            s_owner = msg.sender;
            s_subscriptionId = subscriptionId;
        }
    
        // Assumes the subscription is funded sufficiently.
        function giveaway() external onlyOwner {
            // Will revert if subscription is not set and funded.
            s_requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numRandoms
            );
        }
        
        function fulfillRandomWords(
            uint256, /* requestId */
            uint256[] memory randomWords
        ) internal override {
            // a random number that will represent the index
            // of the winning address in the list of addresses.
            // the number is between 0 and the length of the array of addresses - 1
            uint256 randomNumber = (randomWords[0] % (addresses.length - 1));
            winner = addresses[randomNumber];
            games[s_requestId] = addresses[randomNumber];
            emit Winner(winner, s_requestId);
        }
    
        modifier onlyOwner() {
            require(msg.sender == s_owner);
            _;
        }
    }