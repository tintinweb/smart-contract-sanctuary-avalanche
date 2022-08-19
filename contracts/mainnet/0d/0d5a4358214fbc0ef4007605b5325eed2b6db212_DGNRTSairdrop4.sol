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

contract DGNRTSairdrop4 is VRFConsumerBaseV2 {
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
  airdrop.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0x5009f90F584fb7d59c2Cca7Cfce88C1af3f662bd);
  airdrop.push(0xc428f9484b574EBB1B3f84Be45E425413AEC18a2);
  airdrop.push(0xbA109916A5f1381845d6FC4a2758C1abD196ff93);
  airdrop.push(0xE0dEA755A9853f8eD2d14e3e88393157E81beAF3);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
  airdrop.push(0x5A56fA89E6D61695c2681eceBa308B78Fef4Cb2b);
  airdrop.push(0xc6ea0144eC59edD0e7d6b67D5ba074C8677F6E80);
  airdrop.push(0x603a59c8e44bba7635FB8BEA59EaB53106865d89);
  airdrop.push(0xA24fCDfF33C0C4Ab0129Cc72B58A9BcAcf85B932);
  airdrop.push(0xA5f39A1Ad13834A1079572df5FEb0DfcE0f5d7E5);
  airdrop.push(0x618711478689a68aA547480c2D9ba72FBFC31774);
  airdrop.push(0xc6ea0144eC59edD0e7d6b67D5ba074C8677F6E80);
  airdrop.push(0xfFcbe5A6D807D47deea491cFc9A606fDEdfD8eA3);
  airdrop.push(0x6213fD5a700d1a059E2fb05077c5Bd1E626Ed9F3);
  airdrop.push(0xfFcbe5A6D807D47deea491cFc9A606fDEdfD8eA3);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  airdrop.push(0x9B6F20E0ea7a409A31E3595210c4CCBceFa95Fe5);
  airdrop.push(0x186f7C8e961Ea5fFfB36cDc4Cdaed94e40aBc62a);
  airdrop.push(0x5de3c13d424A08D8141668D4b7De15bB8cA23b0B);
  airdrop.push(0x6B59918Cfa9a4A360482b98E32bd0EBC61AEe89e);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x28655edB9Ee26AC115A12984B9Bdb5B4Bd69BB36);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xDCB213eDE09Bdd3b3A0a4eBA7b5B21F81e000a97);
  airdrop.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  airdrop.push(0x9494D5950802446F2AbDF81149CEA96227861b5c);
  airdrop.push(0x906A8B72E609C0372cfE380b37A672AD387501C8);
  airdrop.push(0x989923d33bE0612680064Dc7223a9f292C89A538);
  airdrop.push(0xe4E01E5F6a9c306Ad7EbCa53BEb943CF6B181045);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0x2bA4BfBF7b9Bc71223cBA2B8F19Ca49A696dA9e8);
  airdrop.push(0xA7FaBf8A569335ad4eB5586DCe6f03FAcDf61d01);
  airdrop.push(0xDCB213eDE09Bdd3b3A0a4eBA7b5B21F81e000a97);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xb29fC57A24fB71BC9ef194Ef4dD7461F22366a43);
  airdrop.push(0xfe941D632381460023Aef4455AA456e1b96e45Bb);
  airdrop.push(0x112513F784019b701f5556eA3C9d2C086ffcBE07);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xBea4ab7d0a87260b24320D6B0BcAfc627F7a1737);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a);
  airdrop.push(0xeaDDAAd6500dEb6b7aea9af6B0A378CD67557e40);
  airdrop.push(0x8fE4E9cD42c09d71c3CB590F7C2949ca94065001);
  airdrop.push(0x5e7cd592A306f7e6a030ed1b88cba5649e42AF72);
  airdrop.push(0x10b9382fF92105102D865a10Fed0C0C483805FC4);
  airdrop.push(0xf8fD2434AEd4b564c8623A62519dc87FbB61D83D);
  airdrop.push(0x60A0019F67ca72EfA41d8B6cA06a25ED5c7D1c44);
  airdrop.push(0x1a3c34b26E0F812Fe7496667902A6F18FF053833);
  airdrop.push(0x02482370dEaaE6443Af0f8bD19c4345D92364900);
  airdrop.push(0xd1A9053AB194c36E16637d0A73475274Aa764738);
  airdrop.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
  airdrop.push(0xca2ee0d41F0293ca46404CE3825e26589D3De431);
  airdrop.push(0x50a38311098E0Ce5874F9008e336c8cF3B5d7830);
  airdrop.push(0xF9856EAE71B956C6eb2Bec6cE437375F84BC9178);
  airdrop.push(0x02482370dEaaE6443Af0f8bD19c4345D92364900);
  airdrop.push(0x53b319B7c579DA994f01a31263d48cB9AeE07444);
  airdrop.push(0xBcE51807bcB31EcABc47A1aF05Fb47e0F9E92170);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0x1ec33f8D53BCaba1f1765132AA9ca402e4CB6da9);
  airdrop.push(0xbC8B718bFb350629eBBDbffC97e58cd156c6308d);
  airdrop.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x4e99CC69BBD2611ca4cCFA621C2370C1aE95359b);
  airdrop.push(0xEdbB35ED17524718002Ed414aFd71c533E74a5ba);
  airdrop.push(0xa19801bB2b3A8239466811913088745fb76799ae);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xf17668Ff22c63E63475D5f7DbDf7585D51E52c76);
  airdrop.push(0xA24fCDfF33C0C4Ab0129Cc72B58A9BcAcf85B932);
  airdrop.push(0xB833DD536e9B1B82757e1d457714D048c7bBC0EB);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xeaDDAAd6500dEb6b7aea9af6B0A378CD67557e40);
  airdrop.push(0xE561fdBCeaa225Ccfa080bCD4D84382e27f6D9d9);
  airdrop.push(0xCE6E4F1dc56eE1bcB0546A021D884eCb4B22eC42);
  airdrop.push(0xdfF601647CCbC6317f6314bDF20129F74c37B1B2);
  airdrop.push(0x587cAf20EC6FfB3E6a93738D99BAF87943D088Cf);
  airdrop.push(0x18a7Fb33BE337E8983A21ADC06479Ae083CA4Fab);
  airdrop.push(0xf5ffB26AFBdb4a16f0812908c7863677174DE5fe);
  airdrop.push(0xB833DD536e9B1B82757e1d457714D048c7bBC0EB);
  airdrop.push(0x1a3c34b26E0F812Fe7496667902A6F18FF053833);
  airdrop.push(0x15Cdc6Fe82B4Adc404F9041962eE3A8BE29f8fb3);
  airdrop.push(0x4f96C32B9EC8DfCB04Ada96Ff6BDc81f92C1F81C);
  airdrop.push(0x5de3c13d424A08D8141668D4b7De15bB8cA23b0B);
  airdrop.push(0x2BDEC7d5D1f137393880dA3D220A4a75436000f1);
  airdrop.push(0x828471C2CEE64A8B146d82C46f39c1889810ab1D);
  airdrop.push(0xfFcbe5A6D807D47deea491cFc9A606fDEdfD8eA3);
  airdrop.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  airdrop.push(0x2bA4BfBF7b9Bc71223cBA2B8F19Ca49A696dA9e8);
  airdrop.push(0x7AC3Fe761e1ee11F5FB79F042A4Fd45911dD640f);
  airdrop.push(0x90b1c0E539413E332d7e5d8Cccb199b76941EC8B);
  airdrop.push(0xB70219C02CA65F257079370CE34CDCAfF837E7CD);
  airdrop.push(0x52Fc297ce072148A99bc0D6A2D8a8D34Ae0b145d);
  airdrop.push(0xB833DD536e9B1B82757e1d457714D048c7bBC0EB);
  airdrop.push(0x02482370dEaaE6443Af0f8bD19c4345D92364900);
  airdrop.push(0x9C44888443bb570AB15033b0A71f5d8f273171Fb);
  airdrop.push(0x90b1c0E539413E332d7e5d8Cccb199b76941EC8B);
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
           result[i] = i + 1048;
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