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

contract DGNRTSairdrop2 is VRFConsumerBaseV2 {
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
  airdrop.push(0x3c2cC1E798769C06A5CC75C146De966839B5Ee58);
  airdrop.push(0xc8d6E8717b6F0f6648803e2537aCEb4b24039D2b);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x4a9fDEd8E0E4b642A890e637C038E0733d666789);
  airdrop.push(0x257B600b084b0b82Fb1A0A3caAD51b87fe16b15f);
  airdrop.push(0xf06D7E4Fbd1d097fED2169AB39B397e289D34360);
  airdrop.push(0x5A56fA89E6D61695c2681eceBa308B78Fef4Cb2b);
  airdrop.push(0xf1376072AE0e2E114ce40A3b43609A46Ea99D348);
  airdrop.push(0x12cdfacFaD33C30F81B8f3B85EA50A7c357dcC1B);
  airdrop.push(0xbeB26afE641A88Da9dDf1b152d240CA5917839bC);
  airdrop.push(0x9494D5950802446F2AbDF81149CEA96227861b5c);
  airdrop.push(0x82bb8d9FB9Ec3a7DA2Dc3A7dcC48418dAc6BbD4a);
  airdrop.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
  airdrop.push(0x9B6F20E0ea7a409A31E3595210c4CCBceFa95Fe5);
  airdrop.push(0xd1A9053AB194c36E16637d0A73475274Aa764738);
  airdrop.push(0xAe47114394a05D927BB54Ef2e468377b3Fc1458F);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xB0643e8CB6506912a64A0b52d04CA16Df1872d81);
  airdrop.push(0x67e03993d20F8F8b5EAAc2801F14A461D75DF555);
  airdrop.push(0x568260F17772D41F0797690990eF9321CdD762f8);
  airdrop.push(0xbC8B718bFb350629eBBDbffC97e58cd156c6308d);
  airdrop.push(0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c);
  airdrop.push(0xF70E7013D4eDD78698447bfB58696e7f386BC67C);
  airdrop.push(0xB0643e8CB6506912a64A0b52d04CA16Df1872d81);
  airdrop.push(0x3106D6Dbc341fd9F27448B873a72e2e1e1C18497);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0xbF6413995E52A5EcfEDcEa4526A46F0c0AeCE96e);
  airdrop.push(0x7e4e7Be312D007C6F9d3246f0816aCcF99BCd880);
  airdrop.push(0x4416aC5643cE3263fcF0bE32556F1370795e5D8E);
  airdrop.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
  airdrop.push(0xA49E0Bb000E449ffea0BdF8965b92804466cF16D);
  airdrop.push(0xddd4B8572c1460accC62a49F4F417777260776DB);
  airdrop.push(0xc3a5E7BeAb2F963CDA5cCADEc64A9eAA86d8C253);
  airdrop.push(0x10b9382fF92105102D865a10Fed0C0C483805FC4);
  airdrop.push(0x95e4f2Ba1299e2A91654495A4b2C58d96B55E45A);
  airdrop.push(0xCe5F967FDCbaB1ff86B8A7B632Df33d6806C1A1b);
  airdrop.push(0xC3656D178c208E82b4807c51f187c09677Ff222A);
  airdrop.push(0xa19801bB2b3A8239466811913088745fb76799ae);
  airdrop.push(0x4f4D1c22B802fd650bcAC69263507023f9169f75);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x6213fD5a700d1a059E2fb05077c5Bd1E626Ed9F3);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0xF32738cDd702014AF7B41ce4C10B2650e3eCe740);
  airdrop.push(0x84b126C2e11689FD8A51c20e7d5beD6616F60558);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x2986E8Ce96a6Def7131a658F25dA11A661153B21);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x2125FA5D1881670f7786569d5CE5b0820D4AB86E);
  airdrop.push(0x3106D6Dbc341fd9F27448B873a72e2e1e1C18497);
  airdrop.push(0xf030230018828F40E610718c83E03BA6a8773850);
  airdrop.push(0x112513F784019b701f5556eA3C9d2C086ffcBE07);
  airdrop.push(0x883ce32E186c69559E94C8BA276BfC4322Fc194a);
  airdrop.push(0x9f0dD487e59aE7895615cC0D5DfEA1617739F2a5);
  airdrop.push(0xF5b882cae990AA9BDA8fAE39BDd9f72554A3F989);
  airdrop.push(0x0AcE6Cb556E520962DF2800003209F5423f245aB);
  airdrop.push(0x0252dFbad3169ea16665d668af107D5e217579fa);
  airdrop.push(0xc428f9484b574EBB1B3f84Be45E425413AEC18a2);
  airdrop.push(0x4cD35473b99125eC4A028081CEc28AA2eB5eef84);
  airdrop.push(0x16763494C398e72a58B9802b8204E07a62C1C7De);
  airdrop.push(0xF523120d8310c004ab35654DC08bB9b4b2f83361);
  airdrop.push(0xc3a5E7BeAb2F963CDA5cCADEc64A9eAA86d8C253);
  airdrop.push(0xCe37Ef768C937Cc597636947816C446D5C7EAec5);
  airdrop.push(0x2BDEC7d5D1f137393880dA3D220A4a75436000f1);
  airdrop.push(0xdfF601647CCbC6317f6314bDF20129F74c37B1B2);
  airdrop.push(0x206eEe77456933161403a4d04d39eFF994aBAa0b);
  airdrop.push(0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c);
  airdrop.push(0x9467135a90023C731803289676302FA18E75F5fe);
  airdrop.push(0x1892cd42F514DB1002F9A33d34AB9E625F3a6B61);
  airdrop.push(0x7AC3Fe761e1ee11F5FB79F042A4Fd45911dD640f);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0xE91E73b5F5D0640082107FE61d6381Bf6883CD1d);
  airdrop.push(0x5BD8Eff5967B1F1812FDA2d5e5802D28D1Cd793c);
  airdrop.push(0xbA109916A5f1381845d6FC4a2758C1abD196ff93);
  airdrop.push(0xF523120d8310c004ab35654DC08bB9b4b2f83361);
  airdrop.push(0x426261850e849013E7376A04AD0C2dCE4F6C52CB);
  airdrop.push(0x64c4607AD853999EE5042Ba8377BfC4099C273DE);
  airdrop.push(0x692622208552234FA37210cC8DC0b87D4c551aca);
  airdrop.push(0xAe47114394a05D927BB54Ef2e468377b3Fc1458F);
  airdrop.push(0xd1c984012Fcea173e99fa68c98d9549E985A4623);
  airdrop.push(0xDEf4a6f5734638670fe4c726329cafbD1640234d);
  airdrop.push(0x5750296b2ee46480bc4E4199067fF0C349Fdc95b);
  airdrop.push(0x9B6F20E0ea7a409A31E3595210c4CCBceFa95Fe5);
  airdrop.push(0x1EEd0A465dcA2C5f952fc59b3E8b30760Bd3593c);
  airdrop.push(0x36CcfEfeaef3D66C0E3A456aE9A0802Aec49249E);
  airdrop.push(0x7BA09A0449102F7F2e6398132fDe0cE35d1BC985);
  airdrop.push(0x6F50142e432B0f6cb851D93430Fd5afaAfa0734a);
  airdrop.push(0x95e4f2Ba1299e2A91654495A4b2C58d96B55E45A);
  airdrop.push(0xA8176b3F8f6Acc86494A3674Dd87DB5314cA2193);
  airdrop.push(0xE561fdBCeaa225Ccfa080bCD4D84382e27f6D9d9);
  airdrop.push(0xa19801bB2b3A8239466811913088745fb76799ae);
  airdrop.push(0x437a4f3C893c0e688ea4e75d189BE0460A75f184);
  airdrop.push(0xE561fdBCeaa225Ccfa080bCD4D84382e27f6D9d9);
  airdrop.push(0xF10ae6d2496DFdEAfb9FE4e7c9012eb625d765f2);
  airdrop.push(0x40c664FB77317EC83B2b188ff4f485A6C71Da4cA);
  airdrop.push(0x303f9B47e9925Fea54C16addd7A9F47C4775B521);
  airdrop.push(0xA7FaBf8A569335ad4eB5586DCe6f03FAcDf61d01);
  airdrop.push(0xCe5F967FDCbaB1ff86B8A7B632Df33d6806C1A1b);
  airdrop.push(0xa19801bB2b3A8239466811913088745fb76799ae);
  airdrop.push(0x46e7BC113E1f0748ddd15B49975c9dDD8E348DD2);
  airdrop.push(0xff3BceB0672287F8e807E5F034bd6Ba34bfA1673);
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
           result[i] = i + 848;
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