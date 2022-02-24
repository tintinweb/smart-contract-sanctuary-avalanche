// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./UIntArrays.sol";

contract Avaxies is ERC721Enumerable, Ownable {
  // Generation Related Variables
  struct Avaxy {
    uint256 color;
    uint256 head;
    uint256 mouth;
    uint256 eyes;
    uint256 ears;
    uint256 back;
    uint256 tail;
    uint256 body;
    uint256 setModifier;
    uint256 combinedCount;
    uint256 powerClass;
    uint256 power;
  }

  mapping(bytes32 => uint256) private hashToTokenId;
  mapping(uint256 => uint256) private avaxies;
  mapping(uint256 => uint256[]) public combinations;

  uint256 public constant NUM_TRAITS = 8;
  uint256 public combinedId = 20000;

  uint256 public constant TRAIT_INDEX_COLOR = 0;
  uint256 public constant TRAIT_INDEX_HEAD = 1;
  uint256 public constant TRAIT_INDEX_MOUTH = 2;
  uint256 public constant TRAIT_INDEX_EYES = 3;
  uint256 public constant TRAIT_INDEX_EARS = 4;
  uint256 public constant TRAIT_INDEX_BACK = 5;
  uint256 public constant TRAIT_INDEX_TAIL = 6;
  uint256 public constant TRAIT_INDEX_BODY = 7;

  uint256[NUM_TRAITS] private traitSizes;
  uint256[NUM_TRAITS] private traitCounts;
  uint256[NUM_TRAITS] private traitRemaining;

  uint256 private fallbackModelProbabilities;

  bytes32[NUM_TRAITS] public traitCategories;
  bytes32[][NUM_TRAITS] public traitNames;

  event AvaxyMinted(
    address indexed owner,
    uint256 tokenId,
    uint256[] traits,
    uint256 setModifier,
    uint256 combinedCount,
    uint256 powerClass,
    uint256 power
  );

  // ERC721 Sales Related Variables
  uint256 public constant TOKEN_LIMIT = 20000;
  uint256 private constant RESERVE_LIMIT = 500;
  uint256 private constant MAX_CHUBBIES = 10000;
  uint256 internal constant PRICE = 100 ether;

  bool public isSaleActive = false;

  uint256 public numSold = 82; // Mainnet results

  string private _baseTokenURI;

  // Withdraw Addresses
  address payable[] public senders;
  mapping(address => bool) public isSender;

  constructor() ERC721("Avaxies", "AVAXY") {
    traitSizes = [9, 15, 15, 15, 16, 15, 15, 7];

    uint256[] memory colorDistribution = new uint256[](
      traitSizes[TRAIT_INDEX_COLOR]
    );
    uint256[] memory modelDistribution = new uint256[](
      traitSizes[TRAIT_INDEX_HEAD]
    );
    uint256[] memory earsDistribution = new uint256[](
      traitSizes[TRAIT_INDEX_EARS]
    );
    uint256[] memory bodyDistribution = new uint256[](
      traitSizes[TRAIT_INDEX_BODY]
    );

    uint256[] memory probabilitiesDistribution = new uint256[](NUM_TRAITS);

    traitCounts[TRAIT_INDEX_COLOR] = UIntArrays.packedUintFromArray(
      colorDistribution
    );
    traitCounts[TRAIT_INDEX_HEAD] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitCounts[TRAIT_INDEX_MOUTH] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitCounts[TRAIT_INDEX_EYES] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitCounts[TRAIT_INDEX_EARS] = UIntArrays.packedUintFromArray(
      earsDistribution
    );
    traitCounts[TRAIT_INDEX_BACK] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitCounts[TRAIT_INDEX_TAIL] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitCounts[TRAIT_INDEX_BODY] = UIntArrays.packedUintFromArray(
      bodyDistribution
    );

    for (uint256 i = 0; i < 9; i++) {
      colorDistribution[i] = 100;
    }
    for (uint256 i = 0; i < 15; i++) {
      modelDistribution[i] = 100 * (i + 1);
      earsDistribution[i] = 100 * (i + 1);
    }
    earsDistribution[15] = 1600;
    for (uint256 i = 0; i < 7; i++) {
      bodyDistribution[i] = 100 * (i + 1);
    }

    for (uint256 i = 0; i < NUM_TRAITS; i++) {
      probabilitiesDistribution[i] = 1600;
    }

    traitRemaining[TRAIT_INDEX_COLOR] = UIntArrays.packedUintFromArray(
      colorDistribution
    );
    traitRemaining[TRAIT_INDEX_HEAD] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitRemaining[TRAIT_INDEX_MOUTH] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitRemaining[TRAIT_INDEX_EYES] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitRemaining[TRAIT_INDEX_EARS] = UIntArrays.packedUintFromArray(
      earsDistribution
    );
    traitRemaining[TRAIT_INDEX_BACK] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitRemaining[TRAIT_INDEX_TAIL] = UIntArrays.packedUintFromArray(
      modelDistribution
    );
    traitRemaining[TRAIT_INDEX_BODY] = UIntArrays.packedUintFromArray(
      bodyDistribution
    );

    fallbackModelProbabilities = UIntArrays.packedUintFromArray(
      probabilitiesDistribution
    );

    traitCategories = [
      bytes32("Color"),
      bytes32("Head"),
      bytes32("Mouth"),
      bytes32("Eyes"),
      bytes32("Ears"),
      bytes32("Back"),
      bytes32("Tail"),
      bytes32("Body")
    ];
  }

  // Avaxy helpers
  function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }

  function setTraitNames(string[][] memory _names) public onlyOwner {
    require(_names.length == NUM_TRAITS, "Traits count incorrect");

    for (uint256 i = 0; i < NUM_TRAITS; i++) {
      require(_names[i].length == traitSizes[i], "Trait names length not matched");

      bytes32[] memory names_ = new bytes32[](_names[i].length);
      for (uint256 j = 0; j < _names[i].length; j++) {
        names_[j] = stringToBytes32(_names[i][j]);
      }
      traitNames[i] = names_;
    }
  }

  // Packing optimization to save gas
  function setAvaxy(
    uint256 _tokenId,
    uint256[] memory _traits,
    uint256 _setModifier,
    uint256 _combinedCount,
    uint256 _powerClass,
    uint256 _power
  ) internal {
    uint256 avaxy = _traits[0];
    avaxy |= _traits[1] << 8;
    avaxy |= _traits[2] << 16;
    avaxy |= _traits[3] << 24;
    avaxy |= _traits[4] << 32;
    avaxy |= _traits[5] << 40;
    avaxy |= _traits[6] << 48;
    avaxy |= _traits[7] << 56;
    avaxy |= _setModifier << 64;
    avaxy |= _combinedCount << 72;
    avaxy |= _powerClass << 80;
    avaxy |= _power << 88;

    avaxies[_tokenId] = avaxy;
  }

  function getAvaxy(uint256 _tokenId)
    internal
    view
    returns (Avaxy memory _bot)
  {
    uint256 avaxy = avaxies[_tokenId];
    _bot.color = uint256(uint8(avaxy));
    _bot.head = uint256(uint8(avaxy >> 8));
    _bot.mouth = uint256(uint8(avaxy >> 16));
    _bot.eyes = uint256(uint8(avaxy >> 24));
    _bot.ears = uint256(uint8(avaxy >> 32));
    _bot.back = uint256(uint8(avaxy >> 40));
    _bot.tail = uint256(uint8(avaxy >> 48));
    _bot.body = uint256(uint8(avaxy >> 56));
    _bot.setModifier = uint256(uint8(avaxy >> 64));
    _bot.combinedCount = uint256(uint8(avaxy >> 72));
    _bot.powerClass = uint256(uint8(avaxy >> 80));
    _bot.power = uint256(uint16(avaxy >> 88));
  }

  function getTraitRemaining() public view returns (uint256[][] memory) {
    uint256[][] memory results = new uint256[][](NUM_TRAITS);

    for (uint256 i; i < NUM_TRAITS; i++) {
      results[i] = UIntArrays.arrayFromPackedUint(
        traitRemaining[i],
        traitSizes[i]
      );
    }

    return results;
  }

  function getTraitCounts() public view returns (uint256[][] memory) {
    uint256[][] memory results = new uint256[][](NUM_TRAITS);

    for (uint256 i; i < NUM_TRAITS; i++) {
      results[i] = UIntArrays.arrayFromPackedUint(
        traitCounts[i],
        traitSizes[i]
      );
    }

    return results;
  }

  // Hash is only determined by core traits and type
  function avaxyHash(uint256[] memory _traits) public pure returns (bytes32) {
    return UIntArrays.hash(_traits, NUM_TRAITS);
  }

  function isBotAvailable(uint256 _claimId) public view returns (bool) {
    return avaxies[_claimId] == 0;
  }

  function existTraits(uint256[] memory _traits) public view returns (bool) {
    return tokenIdFromTraits(_traits) != 0;
  }

  function tokenIdFromTraits(uint256[] memory _traits)
    public
    view
    returns (uint256)
  {
    return hashToTokenId[avaxyHash(_traits)];
  }

  function traitsForTokenId(uint256 _tokenId)
    public
    view
    returns (
      uint256[] memory _traits,
      uint256 _setModifier,
      uint256 _combinedCount,
      uint256 _powerClass,
      uint256 _power
    )
  {
    (
      _traits,
      _setModifier,
      _combinedCount,
      _powerClass,
      _power
    ) = traitsFromBot(getAvaxy(_tokenId));
  }

  function traitsFromBot(Avaxy memory _bot)
    internal
    pure
    returns (
      uint256[] memory _traits,
      uint256 _setModifier,
      uint256 _combinedCount,
      uint256 _powerClass,
      uint256 _power
    )
  {
    _traits = new uint256[](NUM_TRAITS);
    _traits[TRAIT_INDEX_COLOR] = _bot.color;
    _traits[TRAIT_INDEX_HEAD] = _bot.head;
    _traits[TRAIT_INDEX_MOUTH] = _bot.mouth;
    _traits[TRAIT_INDEX_EYES] = _bot.eyes;
    _traits[TRAIT_INDEX_EARS] = _bot.ears;
    _traits[TRAIT_INDEX_BACK] = _bot.back;
    _traits[TRAIT_INDEX_TAIL] = _bot.tail;
    _traits[TRAIT_INDEX_BODY] = _bot.body;

    _setModifier = _bot.setModifier;
    _combinedCount = _bot.combinedCount;
    _powerClass = _bot.powerClass;
    _power = _bot.power;
  }

  function strConcat(string memory _a, string memory _b)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(bytes(_a), bytes(_b)));
  }

  function bytes32ToString(bytes32 _bytes32)
    internal
    pure
    returns (string memory)
  {
    uint256 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function _mintBot(address _sendTo, uint256 _tokenId) internal {
    // 1. Try to get random traits from remaining
    uint256 dna = uint256(
      keccak256(
        abi.encodePacked(
          msg.sender,
          _tokenId,
          block.difficulty,
          block.timestamp
        )
      )
    );
    uint256[] memory traits = randomTraits(dna);

    // 2. Try reroll with fixed probabillity model if we hit a duplicate (0.0002% of happening)
    if (existTraits(traits)) {
      uint256 offset = 0;
      do {
        traits = randomFallbackTraits(dna, offset);
        offset += 1;
        require(offset < 5, "Rerolled traits but failed");
      } while (existTraits(traits));
    }

    hashToTokenId[avaxyHash(traits)] = _tokenId;
    uint256 setModifier = setModifierForParts(traits);
    uint256 power = estimatePowerForBot(traits, new uint256[](0), setModifier);
    uint256 powerClass = powerClassForPower(power);
    setAvaxy(_tokenId, traits, setModifier, 0, powerClass, power);

    for (uint256 i = 0; i < traits.length; i++) {
      traitRemaining[i] = UIntArrays.decrementPackedUint(
        traitRemaining[i],
        traits[i],
        1
      );
      traitCounts[i] = UIntArrays.incrementPackedUint(
        traitCounts[i],
        traits[i],
        1
      );
    }
    combinations[_tokenId].push(_tokenId);

    _safeMint(_sendTo, _tokenId);
    emit AvaxyMinted(
      _sendTo,
      _tokenId,
      traits,
      setModifier,
      0,
      powerClass,
      power
    );
  }

  function randomTraits(uint256 _dna) internal view returns (uint256[] memory) {
    uint256[] memory traits = new uint256[](NUM_TRAITS);
    for (uint256 i = 0; i < traitRemaining.length; i++) {
      traits[i] = UIntArrays.randomIndexFromWeightedArray(
        UIntArrays.arrayFromPackedUint(traitRemaining[i], traitSizes[i]),
        uint256(keccak256(abi.encodePacked(_dna, i + 1)))
      );
    }

    return traits;
  }

  function randomFallbackTraits(uint256 _dna, uint256 _offset)
    internal
    view
    returns (uint256[] memory)
  {
    uint256[] memory traits = new uint256[](NUM_TRAITS);

    for (uint256 i = 0; i < 8; i++) {
      traits[i] = UIntArrays.randomIndexFromWeightedArray(
        UIntArrays.arrayFromPackedUint(
          fallbackModelProbabilities,
          traitSizes[i]
        ),
        uint256(keccak256(abi.encodePacked(_dna, _offset * i)))
      );
    }

    return traits;
  }

  function metadata(uint256 _tokenId)
    public
    view
    returns (string memory resultString)
  {
    if (_exists(_tokenId) == false) {
      return "{}";
    }
    resultString = "{";
    (
      uint256[] memory traits,
      uint256 setModifier,
      uint256 combinedCount,
      uint256 powerClass,
      uint256 power
    ) = traitsForTokenId(_tokenId);

    for (uint256 i = 0; i < traits.length; i++) {
      if (i > 0) {
        resultString = strConcat(resultString, ", ");
      }
      resultString = strConcat(resultString, '"');
      resultString = strConcat(
        resultString,
        bytes32ToString(traitCategories[i])
      );
      resultString = strConcat(resultString, '": "');
      resultString = strConcat(
        resultString,
        bytes32ToString(traitNames[i][traits[i]])
      );
      resultString = strConcat(resultString, '"');
    }

    resultString = strConcat(resultString, ", ");

    string[] memory valueCategories = new string[](4);
    valueCategories[0] = "Full Set";
    valueCategories[1] = "Combined";
    valueCategories[2] = "Power Class";
    valueCategories[3] = "Power";
    uint256[] memory values = new uint256[](4);
    values[0] = setModifier;
    values[1] = combinedCount;
    values[2] = powerClass;
    values[3] = power;

    for (uint256 i = 0; i < valueCategories.length; i++) {
      if (i > 0) {
        resultString = strConcat(resultString, ", ");
      }
      resultString = strConcat(resultString, '"');
      resultString = strConcat(resultString, valueCategories[i]);
      resultString = strConcat(resultString, '": ');
      resultString = strConcat(resultString, Strings.toString(values[i]));
    }

    resultString = strConcat(resultString, "}");

    return resultString;
  }

  // COMBINE
  function isSelectedTraitsEligible(
    uint256[] memory _selectedTraits,
    uint256[] memory _selectedBots
  ) public view returns (bool) {
    uint256[] memory traits;

    for (
      uint256 traitIndex = 0;
      traitIndex < _selectedTraits.length;
      traitIndex++
    ) {
      bool traitCheck = false;
      for (uint256 botIndex = 0; botIndex < _selectedBots.length; botIndex++) {
        (traits, , , , ) = traitsForTokenId(_selectedBots[botIndex]);

        if (traits[traitIndex] == _selectedTraits[traitIndex]) {
          traitCheck = true;
          break;
        }
      }
      if (traitCheck == false) {
        return false;
      }
    }

    return true;
  }

  function combine(
    uint256[] memory _selectedTraits,
    uint256[] memory _selectedBots
  ) external payable {
    // 1. check if bot already exists and not in selected bot
    require(_selectedTraits.length == NUM_TRAITS, "Malformed traits");
    require(_selectedBots.length < 6, "Cannot combine more than 5 bots");

    // 2. check traits is in selected bots
    require(
      isSelectedTraitsEligible(_selectedTraits, _selectedBots),
      "Traits not in bots"
    );

    // 3. burn selected bots
    uint256[] memory selectedBotTraits;
    uint256[] memory traitsToDeduct = new uint256[](NUM_TRAITS);
    uint256 maxCombinedCount = 0;
    uint256 combinedCount;
    uint256 selectedPowerClass;

    combinations[combinedId].push(combinedId);
    for (uint256 i = 0; i < _selectedBots.length; i++) {
      require(_exists(_selectedBots[i]), "Selected bot doesn't exist");
      (
        selectedBotTraits,
        ,
        combinedCount,
        selectedPowerClass,

      ) = traitsForTokenId(_selectedBots[i]);

      if (combinedCount > maxCombinedCount) {
        maxCombinedCount = combinedCount;
      }

      for (uint256 j = 0; j < combinations[_selectedBots[i]].length; j++) {
        combinations[combinedId].push(combinations[_selectedBots[i]][j]);
      }

      for (uint256 j = 0; j < NUM_TRAITS; j++) {
        traitsToDeduct[j] = UIntArrays.incrementPackedUint(
          traitsToDeduct[j],
          selectedBotTraits[j],
          1
        );
      }

      // remove hash so that the traits are freed
      delete hashToTokenId[avaxyHash(selectedBotTraits)];

      _burn(_selectedBots[i]);
    }
    uint256 newCombinedCount = maxCombinedCount + 1;
    require(existTraits(_selectedTraits) == false, "Traits already exist");
    require(newCombinedCount < 4, "Cannot combine more than 3 times");

    // Combine Fee
    uint256 combineFee = 0;
    if (newCombinedCount > 1) {
      if (newCombinedCount == 2) {
        combineFee = PRICE;
      } else if (newCombinedCount == 3) {
        combineFee = 2 * PRICE;
      }
      require(
        msg.value >= combineFee,
        "Ether value sent is below the combine fee"
      );
    }

    // 4. mint new bot with selected traits
    _safeMint(msg.sender, combinedId);

    hashToTokenId[avaxyHash(_selectedTraits)] = combinedId;
    uint256 setModifier = setModifierForParts(_selectedTraits);
    uint256 power = estimatePowerForBot(
      _selectedTraits,
      _selectedBots,
      setModifier
    );
    uint256 powerClass = powerClassForPower(power);
    setAvaxy(
      combinedId,
      _selectedTraits,
      setModifier,
      newCombinedCount,
      powerClass,
      power
    );

    // Update Trait Count in one sitting to avoid expensive storage hit
    for (uint256 i = 0; i < NUM_TRAITS; i++) {
      traitsToDeduct[i] = UIntArrays.decrementPackedUint(
        traitsToDeduct[i],
        _selectedTraits[i],
        1
      );
      traitCounts[i] -= traitsToDeduct[i];
    }

    emit AvaxyMinted(
      msg.sender,
      combinedId,
      _selectedTraits,
      setModifier,
      newCombinedCount,
      powerClass,
      power
    );
    combinedId++;
  }

  function powerForPart(uint256 _traitCategory, uint256 _traitIndex)
    public
    pure
    returns (uint256)
  {
    if (_traitCategory == 0 && _traitIndex >= 0) {
      return 100;
    }
    return 200;
  }

  function setModifierForParts(uint256[] memory _traits)
    public
    pure
    returns (uint256 count)
  {
    for (uint256 i = 0; i < 4; i++) {
      uint256 currentCount = 0;
      for (uint256 j = 0; j < 4; j++) {
        if (_traits[i] == _traits[j]) {
          currentCount++;
        }
      }
      if (currentCount > count) {
        count = currentCount;
      }
    }
    return count;
  }

  function powerClassForPower(uint256 _power) public pure returns (uint256) {
    if (_power < 300) {
      return 1;
    } else if (_power < 500) {
      return 2;
    } else if (_power < 800) {
      return 3;
    } else if (_power < 1000) {
      return 4;
    } else if (_power < 1200) {
      return 5;
    } else if (_power < 1400) {
      return 6;
    } else if (_power < 1600) {
      return 7;
    } else if (_power < 1800) {
      return 8;
    } else if (_power < 2000) {
      return 9;
    } else {
      return 10;
    }
  }

  function estimatePowerForBot(
    uint256[] memory _selectedTraits,
    uint256[] memory _selectedBots,
    uint256 _setModifier
  ) public view returns (uint256 power) {
    if (_selectedTraits[TRAIT_INDEX_COLOR] == 1) {
      return 1400;
    } else if (_selectedTraits[TRAIT_INDEX_COLOR] == 2) {
      return 1600;
    } else if (_selectedTraits[TRAIT_INDEX_COLOR] == 3) {
      return 1800;
    }

    // get power of bots
    Avaxy memory bot;
    for (uint256 i = 0; i < _selectedBots.length; i++) {
      bot = getAvaxy(_selectedBots[i]);
      power += bot.power / 4;
    }

    // get power for parts
    for (uint256 i = 0; i < _selectedTraits.length; i++) {
      power += powerForPart(i, _selectedTraits[i]);
    }

    return
      (_setModifier > 1)
        ? (power * ((1 << (_setModifier - 2)) + 10)) / 10
        : power;
  }

  // Sales related functions
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokensOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory result = new uint256[](tokenCount);
    for (uint256 index = 0; index < tokenCount; index++) {
      result[index] = tokenOfOwnerByIndex(_owner, index);
    }
    return result;
  }

  function buy(uint256 _numBuy) external payable {
    uint256 startIndex = MAX_CHUBBIES + RESERVE_LIMIT + numSold;
    require(isSaleActive, "Sale is not active");
    require(startIndex + _numBuy < TOKEN_LIMIT, "Exceeded 20000 limit");
    require(_numBuy < 11, "You can buy maximum 10 bots");
    require(
      msg.value >= PRICE * _numBuy,
      "Ether value sent is below the price"
    );

    for (uint256 i = 0; i < _numBuy; i++) {
      _mintBot(msg.sender, startIndex + i);
    }
    numSold += _numBuy;
  }

  function airdrop(address _sendTo, uint256 _numAirdrop) public onlyOwner {
    uint256 startIndex = MAX_CHUBBIES + RESERVE_LIMIT + numSold;
    for (uint256 i = 0; i < _numAirdrop; i++) {
      _mintBot(_sendTo, startIndex + i);
    }
    numSold += _numAirdrop;
  }

  // Note: This should only be used for minting existing bots on Ethereum Mainnet
  function mintSpecificBot(
    address _sendTo,
    uint256 _tokenId,
    uint256[] memory _traits
  ) public onlyOwner {
    hashToTokenId[avaxyHash(_traits)] = _tokenId;
    uint256 setModifier = setModifierForParts(_traits);
    uint256 power = estimatePowerForBot(_traits, new uint256[](0), setModifier);
    uint256 powerClass = powerClassForPower(power);
    setAvaxy(_tokenId, _traits, setModifier, 0, powerClass, power);

    for (uint256 i = 0; i < _traits.length; i++) {
      traitRemaining[i] = UIntArrays.decrementPackedUint(
        traitRemaining[i],
        _traits[i],
        1
      );
      traitCounts[i] = UIntArrays.incrementPackedUint(
        traitCounts[i],
        _traits[i],
        1
      );
    }
    combinations[_tokenId].push(_tokenId);

    _safeMint(_sendTo, _tokenId);
    emit AvaxyMinted(
      _sendTo,
      _tokenId,
      _traits,
      setModifier,
      0,
      powerClass,
      power
    );
  }

  function addWithdrawAddress(address payable _sender) public onlyOwner {
    senders.push(_sender);
    isSender[_sender] = true;
  }

  function removeWithdrawAddress(address payable _sender) public onlyOwner {
    uint256 index;
    for (uint256 i = 0; i < senders.length; i++) {
      if (senders[i] == _sender) {
        index = i;
        break;
      }
    }

    for (uint256 i = index; i < senders.length - 1; i++) {
      senders[i] = senders[i + 1];
    }
    senders.pop();

    isSender[_sender] = false;
  }

  function startSale() public onlyOwner {
    isSaleActive = true;
  }

  function stopSale() public onlyOwner {
    isSaleActive = false;
  }

  function withdraw() public {
    require(
      isSender[msg.sender] == true || msg.sender == owner(),
      "Invalid sender"
    );
    require(senders.length > 0, "No senders");

    uint256 balance = address(this).balance / senders.length;
    for (uint256 i = 1; i < senders.length; i++) {
      senders[i].transfer(balance);
    }
    senders[0].transfer(address(this).balance);
  }

  function withdrawTokens(IERC20 token) public {
    require(address(token) != address(0));
    require(
      isSender[msg.sender] == true || msg.sender == owner(),
      "Invalid sender"
    );
    require(senders.length > 0, "No senders");

    uint256 balance = token.balanceOf(address(this)) / senders.length;
    for (uint256 i = 1; i < senders.length; i++) {
      token.transfer(senders[i], balance);
    }
    token.transfer(senders[0], token.balanceOf(address(this)));
  }

  function reserveMint(address _sendTo, uint256 _tokenId) public {
    require(
      isSender[msg.sender] == true || msg.sender == owner(),
      "Invalid sender"
    );
    require(isBotAvailable(_tokenId), "Invalid token id");
    _mintBot(_sendTo, _tokenId);
  }

  function reserveBulkMint(address _sendTo, uint256 _numReserve) public {
    require(
      isSender[msg.sender] == true || msg.sender == owner(),
      "Invalid sender"
    );
    uint256 numReserved = 0;
    for (uint256 i = MAX_CHUBBIES; i < MAX_CHUBBIES + RESERVE_LIMIT; i++) {
      if (isBotAvailable(i)) {
        _mintBot(_sendTo, i);
        numReserved++;
      }
      if (numReserved == _numReserve) {
        return;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity 0.8.7;

library UIntArrays {
  function sum(uint256[] memory _array) public pure returns (uint256 result) {
    result = 0;
    for (uint256 i = 0; i < _array.length; i++) {
      result += _array[i];
    }
  }

  function randomIndexFromWeightedArray(
    uint256[] memory _weightedArray,
    uint256 _randomNumber
  ) public pure returns (uint256) {
    uint256 totalSumWeight = sum(_weightedArray);
    require(totalSumWeight > 0, "Array has no weight");
    uint256 randomSumWeight = _randomNumber % totalSumWeight;
    uint256 currentSumWeight = 0;

    for (uint256 i = 0; i < _weightedArray.length; i++) {
      currentSumWeight += _weightedArray[i];
      if (randomSumWeight < currentSumWeight) {
        return i;
      }
    }

    return _weightedArray.length - 1;
  }

  function hash(uint256[] memory _array, uint256 _endIndex)
    public
    pure
    returns (bytes32)
  {
    bytes memory encoded;
    for (uint256 i = 0; i < _endIndex; i++) {
      encoded = abi.encode(encoded, _array[i]);
    }

    return keccak256(encoded);
  }

  function arrayFromPackedUint(uint256 _packed, uint256 _size)
    public
    pure
    returns (uint256[] memory)
  {
    uint256[] memory array = new uint256[](_size);

    for (uint256 i = 0; i < _size; i++) {
      array[i] = uint256(uint16(_packed >> (i * 16)));
    }

    return array;
  }

  function packedUintFromArray(uint256[] memory _array)
    public
    pure
    returns (uint256 _packed)
  {
    require(_array.length < 17, "pack array > 16");
    for (uint256 i = 0; i < _array.length; i++) {
      _packed |= _array[i] << (i * 16);
    }
  }

  function elementFromPackedUint(uint256 _packed, uint256 _index)
    public
    pure
    returns (uint256)
  {
    return uint256(uint16(_packed >> (_index * 16)));
  }

  function decrementPackedUint(
    uint256 _packed,
    uint256 _index,
    uint256 _number
  ) public pure returns (uint256 result) {
    result = _packed & ~(((1 << 16) - 1) << (_index * 16));
    result |=
      (elementFromPackedUint(_packed, _index) - _number) <<
      (_index * 16);
  }

  function incrementPackedUint(
    uint256 _packed,
    uint256 _index,
    uint256 _number
  ) public pure returns (uint256 result) {
    result = _packed & ~(((1 << 16) - 1) << (_index * 16));
    result |=
      (elementFromPackedUint(_packed, _index) + _number) <<
      (_index * 16);
  }

  function mergeArrays(
    uint256[] memory _array1,
    uint256[] memory _array2,
    bool _isPositive
  ) public pure returns (uint256[] memory) {
    for (uint256 i = 0; i < _array1.length; i++) {
      if (_isPositive) {
        _array1[i] += _array2[i];
      } else {
        _array1[i] -= _array2[i];
      }
    }
    return _array1;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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