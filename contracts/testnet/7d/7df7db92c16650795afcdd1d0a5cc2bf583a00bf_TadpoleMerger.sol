// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./interface/ITadpole.sol";
import "./interface/IFly.sol";
import "../lib/solmate/src/auth/Owned.sol";
import "./TadpoleMinter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface LinkAvaxPriceFeed {
    function latestAnswer()
    external
    view
    returns (
        uint price
    );
}


contract TadpoleMerger is Owned, VRFConsumerBaseV2 {
    TadpoleMinterBurner public immutable TADPOLE_MINTER_BURNER;
    ITadpoleNFT immutable TADPOLE_NFT;
    IFly immutable FLY;
    uint256 constant COMMON_TADPOLE_VALUE = 10;
    uint256 constant RARE_TADPOLE_VALUE = 33;
    uint256 constant EXCEPTIONAL_TADPOLE_VALUE = 66;
    uint256 constant EPIC_TADPOLE_VALUE = 217;
    uint256 constant LEGENDARY_TADPOLE_VALUE = 1250;
    uint256 constant FLY_PREMIUM = 500 ether;

    //FUJI PRICE FEED
    LinkAvaxPriceFeed constant internal PRICE_FEED = LinkAvaxPriceFeed(0x79c91fd4F8b3DaBEe17d286EB11cEE4D83521775);
    //FUJI VRF SETUP
    address constant vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 constant s_subscriptionId = 223;
    bytes32 constant keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    uint32 constant callbackGasLimit = 200000;
    uint16 constant requestConfirmations = 1;
    uint32 constant numWords = 1;
    uint256 public s_requestId;

    mapping(uint256 => GamblerInfo) GamblerDict;


    struct GamblerInfo {
        uint64 points;
        uint64 category;
        address player;
    }

    error Mismatch();
    error NotEnoughPoints();
    error NoLegendaryMergingYet();
    error FeeNotCovered();
    error WrongCathegory();

    event GamblingInfo(uint points, uint rng, address gambler);

    constructor(address _minter, address _tadpoleNFT, address _fly) Owned(msg.sender) VRFConsumerBaseV2(vrfCoordinator)  {
        TADPOLE_MINTER_BURNER = TadpoleMinterBurner(_minter);
        TADPOLE_NFT = ITadpoleNFT(_tadpoleNFT);
        FLY = IFly(_fly);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function getCategoryPoints(uint256 category) public pure returns (uint256) {
        if (category == 0) {
            return COMMON_TADPOLE_VALUE;
        } else if (category == 1) {
            return RARE_TADPOLE_VALUE;
        } else if (category == 2) {
            return EXCEPTIONAL_TADPOLE_VALUE;
        } else if (category == 3) {
            return EPIC_TADPOLE_VALUE;
        } else {
            revert NoLegendaryMergingYet();
        }
    }

    function getGamblingTreshold(uint256 category) public pure returns (uint256) {
        if (category == 0) {
            return COMMON_TADPOLE_VALUE;
        } else if (category == 1) {
            return RARE_TADPOLE_VALUE;
        } else if (category == 2) {
            return EXCEPTIONAL_TADPOLE_VALUE;
        } else if (category == 3) {
            return EPIC_TADPOLE_VALUE;
        } else if (category == 4) {
            return LEGENDARY_TADPOLE_VALUE;
        }
        else {
            revert WrongCathegory();
        }
    }

    function getSeed(uint256 points, uint _traitSeed) internal pure returns (uint256) {
        if (points > LEGENDARY_TADPOLE_VALUE) {
            return (_traitSeed % 4);
        } else if (points > EPIC_TADPOLE_VALUE) {
            return (_traitSeed % 46) + 4;
        } else if (points > EXCEPTIONAL_TADPOLE_VALUE) {
            return (_traitSeed % 150) + 50;
        } else if (points > RARE_TADPOLE_VALUE) {
            return (_traitSeed % 300) + 200;
        } else {
            revert NotEnoughPoints();
        }
    }

    function getSeedForTraits() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    // solhint-disable-next-line
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );
    }


    function mergeTadpoles(uint256[] calldata _tokenIds) external {
        uint256 points;
        uint256 len = _tokenIds.length;
        for (uint256 index = 0; index < len; ++index) {
            uint256 tokenId = _tokenIds[index];
            (uint256 cat,,,) = TADPOLE_NFT.tadpoles(tokenId);
            TADPOLE_MINTER_BURNER.burnTadpole(msg.sender, tokenId);
            points += getCategoryPoints(cat);
        }
        uint traitSeed = getSeedForTraits();
        uint256 breedingSeed = getSeed(points,traitSeed);
        TADPOLE_MINTER_BURNER.mintTadpole(msg.sender, breedingSeed);
        FLY.burn(msg.sender, FLY_PREMIUM);
    }

    function gambleTadpoles(uint256[] calldata _tokenIds, uint256 _targetCategory) external payable {
        uint fee = calculateCurrentFee();
        if(msg.value < fee) { revert FeeNotCovered(); }
        uint256 points;
        uint256 len = _tokenIds.length;
        for (uint256 index = 0; index < len; ++index) {
            uint256 tokenId = _tokenIds[index];
            (uint256 cat,,,) = TADPOLE_NFT.tadpoles(tokenId);
            TADPOLE_MINTER_BURNER.burnTadpole(msg.sender, tokenId);
            points += getCategoryPoints(cat);
        }
        s_requestId =
            COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        GamblerDict[s_requestId] = GamblerInfo(uint64(points), uint64(_targetCategory), msg.sender);
        FLY.burn(msg.sender, FLY_PREMIUM);
    }

    function gambleTadpolesVrfCallback(uint256 _rng, uint256 _requestId) internal {
        uint256 _targetCategory = GamblerDict[_requestId].category;
        uint256 treshold = _rng % getGamblingTreshold(_targetCategory);
        if (GamblerDict[_requestId].points > treshold) {
            uint256 targetCategoryPoints = getCategoryPoints(_targetCategory) + 1;
            uint256 mintSeed = getSeed(targetCategoryPoints,_rng);
            TADPOLE_MINTER_BURNER.mintTadpole(GamblerDict[_requestId].player, mintSeed);
        }
        emit GamblingInfo(GamblerDict[_requestId].points, _rng, GamblerDict[_requestId].player);
        delete GamblerDict[_requestId];
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        gambleTadpolesVrfCallback(randomWords[0], requestId);
    }

    function calculateCurrentFee() public view returns (uint) {
        uint premimumInAvaxWei = PRICE_FEED.latestAnswer() / 200;
        return (tx.gasprice  +  premimumInAvaxWei);
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface ITadpoleNFT {
    error InvalidTokenID();
    error Unauthorized();

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnerUpdated(address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function _jsonString(uint256 tokenId) external view returns (string memory);

    function approve(address spender, uint256 id) external;

    function balanceOf(address) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function breedingSpot() external view returns (address);

    function burn(address _tadOwner, uint256 _tokenId) external;

    function exchanger() external view returns (address);

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function mint(address _receiver, uint256 _seed) external;

    function name() external view returns (string memory);

    function nextTokenID() external view returns (uint256);

    function owner() external view returns (address);

    function ownerOf(uint256) external view returns (address);

    function safeTransferFrom(address from, address to, uint256 id) external;

    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory _baseURI) external;

    function setBreedingSpot(address _breedingSpot) external;

    function setExchanger(address _exchanger) external;

    function setOwner(address _newOwner) external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function symbol() external view returns (string memory);

    function tadpoles(uint256) external view returns (uint128 category, uint64 skin, uint56 hat, uint8 background);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(address from, address to, uint256 id) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity ^0.8.12;

interface IFly {
    error Unauthorized();

    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event OwnerUpdated(address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function addZones(address[] memory _zones) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function burn(address from, uint256 amount) external;

    function decimals() external view returns (uint8);

    function mint(address receiver, uint256 amount) external;

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function removeZone(address zone) external;

    function setOwner(address newOwner) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function zones(address) external view returns (bool);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./interface/ITadpole.sol";
import "../lib/solmate/src/auth/Owned.sol";

contract TadpoleMinterBurner is Owned {
    mapping(address => bool) public MinterContract;
    ITadpoleNFT immutable TadpoleNFT;

    error Unauthorited();

    constructor(address _tadpoleAddress) Owned(msg.sender) {
        TadpoleNFT = ITadpoleNFT(_tadpoleAddress);
    }

    function setMinterContract(address _contract, bool _value) external onlyOwner {
        MinterContract[_contract] = _value;
    }

    function burnTadpole(address _tadOwner, uint256 _tokenId) external {
        if (!MinterContract[msg.sender]) {
            revert Unauthorited();
        }
        TadpoleNFT.burn(_tadOwner, _tokenId);
    }

    function mintTadpole(address _receiver, uint256 _seed) external {
        if (!MinterContract[msg.sender]) {
            revert Unauthorited();
        }
        TadpoleNFT.mint(_receiver, _seed);
    }
}

// SPDX-License-Identifier: MIT
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
}

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