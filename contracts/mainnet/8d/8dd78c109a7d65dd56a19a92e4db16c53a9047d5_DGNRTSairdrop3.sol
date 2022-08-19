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

contract DGNRTSairdrop3 is VRFConsumerBaseV2 {
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
  airdrop.push(0xAe47114394a05D927BB54Ef2e468377b3Fc1458F);
  airdrop.push(0x692622208552234FA37210cC8DC0b87D4c551aca);
  airdrop.push(0xa19801bB2b3A8239466811913088745fb76799ae);
  airdrop.push(0x9467135a90023C731803289676302FA18E75F5fe);
  airdrop.push(0x34ff3BE1c150eF0Fd05500C2663BBFC56D0152a7);
  airdrop.push(0xB833DD536e9B1B82757e1d457714D048c7bBC0EB);
  airdrop.push(0x6B59918Cfa9a4A360482b98E32bd0EBC61AEe89e);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0xDEf4a6f5734638670fe4c726329cafbD1640234d);
  airdrop.push(0x824E67982F7238293326df40A4B1bfd943F8103a);
  airdrop.push(0xF9856EAE71B956C6eb2Bec6cE437375F84BC9178);
  airdrop.push(0xF5b882cae990AA9BDA8fAE39BDd9f72554A3F989);
  airdrop.push(0x9d89D5A4600c4C59df5d8a3939427Da9DcFFb938);
  airdrop.push(0x0cDA53a738DD457E2fb008DEE5674BbDfaec83F9);
  airdrop.push(0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5);
  airdrop.push(0xCe5F967FDCbaB1ff86B8A7B632Df33d6806C1A1b);
  airdrop.push(0xA7FaBf8A569335ad4eB5586DCe6f03FAcDf61d01);
  airdrop.push(0x9e7A83f3F29d1d38447545Baf4e80592631bb4d4);
  airdrop.push(0x3b3ad18ffb699eae4bF7997c104a9b206adA9098);
  airdrop.push(0x9809d5059f5DFBcf379B3bfaB5527132EEe165e4);
  airdrop.push(0x2BC4848d787512d79cE71739D93638067e2a5161);
  airdrop.push(0x4416aC5643cE3263fcF0bE32556F1370795e5D8E);
  airdrop.push(0xc428f9484b574EBB1B3f84Be45E425413AEC18a2);
  airdrop.push(0x9dd9580bF833601eCFD2B6cb290139b83788726e);
  airdrop.push(0x85a3d5b0405589E700b3153D294a1B92eb9e2e41);
  airdrop.push(0x3539580eeF6AeA74f540BBC081ad60CCF9E5Ee94);
  airdrop.push(0x0eb7E34F2c2Be8af190c6BD56FD67e68E1C2200f);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xF5b882cae990AA9BDA8fAE39BDd9f72554A3F989);
  airdrop.push(0xC104a029699beb0502d7283fb8d02c5666F9042b);
  airdrop.push(0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a);
  airdrop.push(0xE541F399af344CF8077Cc2852ABc03f92760AbB2);
  airdrop.push(0x5883Ef1414D389C1109F14f042486ec710852999);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x7e4e7Be312D007C6F9d3246f0816aCcF99BCd880);
  airdrop.push(0x7c9134bfEDad58Cb82c5d3b03B2c6EfD01182269);
  airdrop.push(0xca2ee0d41F0293ca46404CE3825e26589D3De431);
  airdrop.push(0x5BEdfC16c6ff7c522b8EE480cb6d295ed5eF82ff);
  airdrop.push(0x883ce32E186c69559E94C8BA276BfC4322Fc194a);
  airdrop.push(0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c);
  airdrop.push(0x1806375191422C16372165EB69b1D5Fe773c3101);
  airdrop.push(0xc8d6E8717b6F0f6648803e2537aCEb4b24039D2b);
  airdrop.push(0xF6E0d8081f59B7041AE6BaA6Af3374F0aCd241aD);
  airdrop.push(0x1a3c34b26E0F812Fe7496667902A6F18FF053833);
  airdrop.push(0xCe5F967FDCbaB1ff86B8A7B632Df33d6806C1A1b);
  airdrop.push(0x1892cd42F514DB1002F9A33d34AB9E625F3a6B61);
  airdrop.push(0xE56B6907cCB6F5CcA0FdF6B0CC7BF2e0C3aa57A1);
  airdrop.push(0x1ddbCcFFB075f9242720554391D6CaB8084Ad2Fc);
  airdrop.push(0xa3872bB17bEd808915C5594814D127864e310b1B);
  airdrop.push(0xc3a5E7BeAb2F963CDA5cCADEc64A9eAA86d8C253);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xBEAA4c5BE755060984e3F2AB72220d67297b7054);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0x85a3d5b0405589E700b3153D294a1B92eb9e2e41);
  airdrop.push(0x90b1c0E539413E332d7e5d8Cccb199b76941EC8B);
  airdrop.push(0x563Ac2A4f1ef0FD6Bc0F9eCD4A7939a731fc8683);
  airdrop.push(0x8F99125500E0E6943ec6C218bCFD8b387f15a976);
  airdrop.push(0x467bfc00c09237977b85E4eC82Ec02b38c524529);
  airdrop.push(0x26Cc7534ad3832b0f3C801e6926b218c44B8B902);
  airdrop.push(0x4f4D1c22B802fd650bcAC69263507023f9169f75);
  airdrop.push(0xe80113462D62b791B9EaEe68824c6531d0479881);
  airdrop.push(0xF523120d8310c004ab35654DC08bB9b4b2f83361);
  airdrop.push(0x74aA8b45270Cb70719070D008ec26FE568625f73);
  airdrop.push(0xBd3e9f69353041968CE51EcbCe9fd423B62107aE);
  airdrop.push(0x18a7Fb33BE337E8983A21ADC06479Ae083CA4Fab);
  airdrop.push(0x513390c09A07b1d659f4eF61c8011691c26909aF);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0x9dd9580bF833601eCFD2B6cb290139b83788726e);
  airdrop.push(0x6213fD5a700d1a059E2fb05077c5Bd1E626Ed9F3);
  airdrop.push(0x12cdfacFaD33C30F81B8f3B85EA50A7c357dcC1B);
  airdrop.push(0x52Fc297ce072148A99bc0D6A2D8a8D34Ae0b145d);
  airdrop.push(0x1ddbCcFFB075f9242720554391D6CaB8084Ad2Fc);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xfFcbe5A6D807D47deea491cFc9A606fDEdfD8eA3);
  airdrop.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
  airdrop.push(0xF4eE4717eCE12eD2Bd6E76D2b074C7D88599Be1F);
  airdrop.push(0xBE010cC1BAADAeaD144D39b3500076451f8FD3e0);
  airdrop.push(0x5BEdfC16c6ff7c522b8EE480cb6d295ed5eF82ff);
  airdrop.push(0x7CEFCe3a83932a14FCf947E439671BA03fecaBc6);
  airdrop.push(0x62f7c9e6cD838E5F48d4083f08B97d05B31418bb);
  airdrop.push(0x74aA8b45270Cb70719070D008ec26FE568625f73);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  airdrop.push(0x9467135a90023C731803289676302FA18E75F5fe);
  airdrop.push(0xed8A42E44b937da01B8E047dc7A426E6052Ef000);
  airdrop.push(0x95e4f2Ba1299e2A91654495A4b2C58d96B55E45A);
  airdrop.push(0x2FA85587De409eBC62B8f6D2b4e2f23D5B425390);
  airdrop.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
  airdrop.push(0xeaB70F918A7d8c7bFa096653D9D97bd5A4d68BF7);
  airdrop.push(0xBea4ab7d0a87260b24320D6B0BcAfc627F7a1737);
  airdrop.push(0x7c9134bfEDad58Cb82c5d3b03B2c6EfD01182269);
  airdrop.push(0x4416aC5643cE3263fcF0bE32556F1370795e5D8E);
  airdrop.push(0xB70219C02CA65F257079370CE34CDCAfF837E7CD);
  airdrop.push(0x2FA85587De409eBC62B8f6D2b4e2f23D5B425390);
  airdrop.push(0xE0dEA755A9853f8eD2d14e3e88393157E81beAF3);
  airdrop.push(0xE561fdBCeaa225Ccfa080bCD4D84382e27f6D9d9);
  airdrop.push(0x99a756C89F4208f65782B891E095098A782a2b5B);
  airdrop.push(0x9467135a90023C731803289676302FA18E75F5fe);
  airdrop.push(0x57C6812178d233246c3ae3A9e746B3443EF3DF16);
  airdrop.push(0x2125FA5D1881670f7786569d5CE5b0820D4AB86E);
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
           result[i] = i + 948;
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