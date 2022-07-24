/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: contracts/interfaces/IUGNFTs.sol


pragma solidity 0.8.13;

interface IUGNFTs {
 
    struct FighterYakuza {
        bool isFighter;
        uint8 Gen;
        uint8 level;
        uint8 rank;
        uint8 courage;
        uint8 cunning;
        uint8 brutality;
        uint8 knuckles;
        uint8 chains;
        uint8 butterfly;
        uint8 machete;
        uint8 katana;
        uint16 scars;
        uint16 imageId;
        uint32 lastLevelUpgradeTime;
        uint32 lastRankUpgradeTime;
        uint32 lastRaidTime;
    }  
    //weapons scores used to identify "metal"
    // steel = 10, bronze = 20, gold = 30, platinum = 50 , titanium = 80, diamond = 100
    struct RaidStats {
        uint8 knuckles;
        uint8 chains;
        uint8 butterfly;
        uint8 machete;
        uint8 katana;
        uint16 scars;
        uint32 fighterId;
    }

    struct ForgeFightClub {
        uint8 size;
        uint8 level;
        uint16 id;
        uint32 lastLevelUpgradeTime;
        uint32 lastUnstakeTime;
        address owner;
    }

    struct RingAmulet {
        uint8 level;
        uint32 lastLevelUpgradeTime;
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    function getPackedFighters(uint256[] calldata tokenIds) external view returns (uint256[] memory);
    function setBaseURI(string calldata uri) external;//onlyOwner
    function tokenURIs(uint256[] calldata tokenId) external view returns (string[] memory) ;
    function mintRingAmulet(address, uint256, bool ) external;//onlyAdmin  
    function mintFightClubForge(address _to, bytes memory _data, uint256 _size, uint256 _level, bool isFightClub) external;//onlyAdmin
    function batchMigrateFYakuza(address _to, uint256[] calldata v1TokenIds, FighterYakuza[] calldata oldFighters) external;//onlyAdmin 
    function checkUserBatchBalance(address user, uint256[] calldata tokenIds) external view returns (bool);
    function getNftIDsForUser(address , uint) external view returns (uint256[] memory);
    function getRingAmulet(uint256 ) external view returns (RingAmulet memory);
    function getFighter(uint256 tokenId) external view returns (FighterYakuza memory);
    function getFighters(uint256[] calldata) external view returns (FighterYakuza[] memory);
    function getForgeFightClub(uint256 tokenId) external view returns (ForgeFightClub memory);
    function getForgeFightClubs(uint256[] calldata tokenIds) external view returns (ForgeFightClub[] memory); 
    function levelUpFighters(uint256[] calldata, uint256[] calldata) external; // onlyAdmin
    function levelUpRingAmulets(uint256, uint256 ) external;
    function levelUpFightClubsForges(uint256[] calldata tokenIds, uint256[] calldata newSizes, uint256[] calldata newLevels) external returns (ForgeFightClub[] memory); // onlyAdmin
    function addAdmin(address) external; // onlyOwner 
    function removeAdmin(address) external; // onlyOwner
    function ttlFYakuzas() external view returns (uint256);
    function ttlFightClubs() external view returns (uint256);
    function ttlRings() external view returns (uint256);
    function ttlAmulets() external view returns (uint256);
    function ttlForges() external view returns (uint256);
    function setFightClubUnstakeTime (uint256 , bool) external;
    function setRaidTraitsFromPacked( uint256[] calldata raidStats) external;    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
// File: contracts/interfaces/IUGRaid.sol



pragma solidity 0.8.13;


interface IUGRaid {

  struct Raid {
    uint8 levelTier;
    uint8 sizeTier;
    uint16 fightClubId;
    uint16 maxScars;
    uint32 maxSweat;
    uint32 id;
    uint32 revenue;
    uint32 timestamp;
  }

  struct RaiderEntry{
      uint8 size;
      uint8 yakFamily;
      uint32 sweat;
  }

  struct RaidEntryTicket {
    uint8 sizeTier;
    uint8 fighterLevel;
    uint8 yakuzaFamily;
    uint8 courage;
    uint8 brutality;
    uint8 cunning;
    uint8 knuckles;
    uint8 chains;
    uint8 butterfly;
    uint8 machete;
    uint8 katana;
    uint16 scars;
    uint32 sweat;
    uint32 fighterId;
    uint32 entryFee;
    uint32 winnings;
  }
  
  function referee() external;
  function enterRaid(uint256[] calldata, RaiderEntry[] calldata) external  returns(uint256 ttlBloodEntryFee);
  function stakeFightclubs(uint256[] calldata) external;
  function unstakeFightclubs(uint256[] calldata) external;
  function claimRaiderBloodRewards() external;
  function claimFightClubBloodRewards() external ;
  function addFightClubToQueueAfterLevelSizeUp(uint256, uint8, uint8, IUGNFTs.ForgeFightClub calldata ) external;
  function getStakedFightClubIDsForUser(address) external view returns (uint256[] memory);
  //function getRaidCost(uint256, uint256) external view returns(uint256);
  function getRaiderQueueLength(uint8, uint8) external view returns(uint8);
  //function getFightClubIdInQueuePosition(uint8, uint8, uint) external view returns (uint256);
  //function getRaiderIdInQueuePosition(uint8, uint8, uint) external view returns (uint256);
  //function setUnstakeCoolDownPeriod(uint256) external;//onlyOwner
  function getValueInBin(uint256 , uint256 , uint256 )external pure returns (uint256);
  function viewIfRaiderIsInQueue( uint256 tokenId) external view returns(bool);
  function setWeaponsRound(bool) external;//onlyOwner
  function setYakuzaRound(bool) external;//onlyOwner
  function setSweatRound(bool) external;//onlyOwner
  function setBaseRaidFee(uint256 newBaseFee) external; //onlyOwner
  function setRefereeBasePct(uint256 pct) external; //onlyOwner
  function setDevWallet(address) external;//onlyOwner
  function setDevFightClubId(uint256) external;//onlyOwner
  function addAdmin(address) external;//onlyOwner
  function removeAdmin(address) external;//onlyOwner
//   function viewRaiderOwnerBloodRewards(address) external view returns (uint256);
//   function viewFightClubOwnerBloodRewards(address) external view returns (uint256);
}
// File: contracts/ERC1155/utils/Ownable.sol


pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner_;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () {
    _owner_ = msg.sender;
    emit OwnershipTransferred(address(0), _owner_);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner_, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    emit OwnershipTransferred(_owner_, _newOwner);
    _owner_ = _newOwner;
  }

  /**
   * @notice Returns the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner_;
  }
}
// File: contracts/utils/Address.sol


pragma solidity ^0.8.0;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}
// File: contracts/interfaces/IERC165.sol


pragma solidity ^0.8.0;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/utils/ERC165.sol


pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual override public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}
// File: contracts/interfaces/IERC1155.sol


pragma solidity ^0.8.0;



interface IERC1155 is IERC165 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// File: contracts/interfaces/IERC1155TokenReceiver.sol


pragma solidity ^0.8.0;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// File: contracts/ERC1155/tokens/UGPackedBalance/UGPackedBalance.sol


pragma solidity ^0.8.0;

//import "../../utils/SafeMath.sol";






/**
 * @dev Implementation of Multi-Token Standard contract. This implementation of the ERC-1155 standard
 *      utilizes the fact that balances of different token ids can be concatenated within individual
 *      uint256 storage slots. This allows the contract to batch transfer tokens more efficiently at
 *      the cost of limiting the maximum token balance each address can hold. This limit is
 *      2^IDS_BITS_SIZE, which can be adjusted below. In practice, using IDS_BITS_SIZE smaller than 16
 *      did not lead to major efficiency gains.
 */
contract UGPackedBalance is IERC1155, ERC165 {
  //using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Constants regarding bin sizes for balance packing
  // IDS_BITS_SIZE **MUST** be a power of 2 (e.g. 2, 4, 8, 16, 32, 64, 128)
  //using 1 bit for UG nfts
  uint256 internal constant IDS_BITS_SIZE   = 1;                  // Max balance amount in bits per token ID
  uint256 internal constant IDS_PER_UINT256 = 256 / IDS_BITS_SIZE; // Number of ids per uint256
  
  uint256 internal constant USER_TOTAL_BALANCES_BITS_SIZE   = 32;

  error InvalidOperator();
  error InvalidRecipient();
  error InvalidOnReceiveMsg();
  error MismatchArrays();
 
  

  // Operations for _updateIDBalance
  enum Operations { Add, Sub }

  // Token IDs balances ; balances[address][id] => balance (using array instead of mapping for efficiency)
  mapping (address => mapping(uint256 => uint256)) internal balances;
  //map user address to packed uint256
  mapping (address => uint256) internal userTotalBalances;
  //map users to bin => Token IDs balances ; 

  // Operators
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public virtual override
  {
    // Requirements
    if((msg.sender != _from) && !isApprovedForAll(_from, msg.sender)) revert InvalidOperator();
    if(_to == address(0)) revert InvalidRecipient();
    // require(_amount <= balances);  Not necessary since checked with _viewUpdateBinValue() checks

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public virtual
  {
    // Requirements
    if((msg.sender != _from) && !isApprovedForAll(_from, msg.sender)) revert InvalidOperator();
    if(_to == address(0)) revert InvalidRecipient();

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    //Update balances
    _updateIDBalance(_from, _id, _amount, Operations.Sub); // Subtract amount from sender
    _updateIDBalance(_to,   _id, _amount, Operations.Add); // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas:_gasLimit}(msg.sender, _from, _id, _amount, _data);
      if(retval != ERC1155_RECEIVED_VALUE) revert InvalidOnReceiveMsg();
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev Arrays should be sorted so that all ids in a same storage slot are adjacent (more efficient)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    uint256 nTransfer = _ids.length; // Number of transfer to execute
    if(nTransfer != _amounts.length) revert MismatchArrays();

    if (_from != _to && nTransfer > 0) {

      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balFrom = _viewUpdateBinValue(balances[_from][bin],IDS_BITS_SIZE, index, _amounts[0], Operations.Sub);
      uint256 balTo = _viewUpdateBinValue(balances[_to][bin], IDS_BITS_SIZE,index, _amounts[0], Operations.Add);

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          balances[_from][lastBin] = balFrom;
          balances[_to][lastBin] = balTo;

          balFrom = balances[_from][bin];
          balTo = balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balFrom = _viewUpdateBinValue(balFrom,IDS_BITS_SIZE, index, _amounts[i], Operations.Sub);
        balTo = _viewUpdateBinValue(balTo,IDS_BITS_SIZE, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      balances[_from][bin] = balFrom;
      balances[_to][bin] = balTo;

    // If transfer to self, just make sure all amounts are valid
    } else {
      for (uint256 i = 0; i < nTransfer; i++) {
        require(balanceOf(_from, _ids[i]) >= _amounts[i], " UNDERFLOW");
      }
    }
    //update type balances

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      if(retval != ERC1155_BATCH_RECEIVED_VALUE) revert InvalidOnReceiveMsg();
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |     Public Balance Functions      |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public virtual override view returns (uint256)
  {
    uint256 bin;
    uint256 index;

    //Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);
    return getValueInBin(balances[_owner][bin], IDS_BITS_SIZE, index);
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders (sorted owners will lead to less gas usage)
   * @param _ids    ID of the Tokens (sorted ids will lead to less gas usage
   * @return The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override virtual view returns (uint256[] memory)
  {
    uint256 n_owners = _owners.length;
    if(n_owners != _ids.length) revert MismatchArrays();

    // First values
    (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);
    uint256 balance_bin = balances[_owners[0]][bin];
    uint256 last_bin = bin;

    // Initialization
    uint256[] memory batchBalances = new uint256[](n_owners);
    batchBalances[0] = getValueInBin(balance_bin, IDS_BITS_SIZE, index);

    // Iterate over each owner and token ID
    for (uint256 i = 1; i < n_owners; i++) {
      (bin, index) = getIDBinIndex(_ids[i]);

      // SLOAD if bin changed for the same owner or if owner changed
      if (bin != last_bin || _owners[i-1] != _owners[i]) {
        balance_bin = balances[_owners[i]][bin];
        last_bin = bin;
      }

      batchBalances[i] = getValueInBin(balance_bin, IDS_BITS_SIZE, index);
    }

    return batchBalances;
  }


  /***********************************|
  |      Packed Balance Functions     |
  |__________________________________*/

  /**
   * @notice Update the balance of a id for a given address
   * @param _address    Address to update id balance
   * @param _id         Id to update balance of
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to id balance
   *   Operations.Sub: Substract _amount from id balance
   */
  function _updateIDBalance(address _address, uint256 _id, uint256 _amount, Operations _operation)
    internal
  {
    uint256 bin;
    uint256 index;

    // Get bin and index of _id
    (bin, index) = getIDBinIndex(_id);

    // Update balance
    balances[_address][bin] = _viewUpdateBinValue(balances[_address][bin], IDS_BITS_SIZE, index, _amount, _operation);
  }

  function _updateIDUserTotalBalance(address _address, uint256 _index, uint256 _amount, Operations _operation)
    internal
  {
    // Update balance
    userTotalBalances[_address] = _viewUpdateBinValue(userTotalBalances[_address], USER_TOTAL_BALANCES_BITS_SIZE, _index, _amount, _operation);
  }

  /**
   * @notice Update a value in _binValues
   * @param _binValues  Uint256 containing values of size IDS_BITS_SIZE (the token balances)
   * @param _index      Index of the value in the provided bin
   * @param _amount     Amount to update the id balance
   * @param _operation  Which operation to conduct :
   *   Operations.Add: Add _amount to value in _binValues at _index
   *   Operations.Sub: Substract _amount from value in _binValues at _index
   */
  function _viewUpdateBinValue(uint256 _binValues, uint256 bitsize, uint256 _index, uint256 _amount, Operations _operation)
    internal pure returns (uint256 newBinValues)
  {
    uint256 shift = bitsize * _index;
    uint256 mask = (uint256(1) << bitsize) - 1;

    if (_operation == Operations.Add) {
      newBinValues = _binValues + (_amount << shift);
      require(newBinValues >= _binValues, " OVERFLOW2");
      require(
        ((_binValues >> shift) & mask) + _amount < 2**bitsize, // Checks that no other id changed
        "OVERFLOW1"
      );

    } else if (_operation == Operations.Sub) {
      newBinValues = _binValues - (_amount << shift);
      require(newBinValues <= _binValues, " UNDERFLOW");
      require(
        ((_binValues >> shift) & mask) >= _amount, // Checks that no other id changed
        "viewUpdtBinVal: UNDERFLOW"
      );

    } else {
      revert("viewUpdtBV: INVALID_WRITE"); // Bad operation
    }

    return newBinValues;
  }

  /**
  * @notice Return the bin number and index within that bin where ID is
  * @param _id  Token id
  * @return bin index (Bin number, ID"s index within that bin)
  */
  function getIDBinIndex(uint256 _id)
    public pure returns (uint256 bin, uint256 index)
  {
    bin = _id / IDS_PER_UINT256;
    index = _id % IDS_PER_UINT256;
    return (bin, index);
  }

  /**
   * @notice Return amount in _binValues at position _index
   * @param _binValues  uint256 containing the balances of IDS_PER_UINT256 ids
   * @param _index      Index at which to retrieve amount
   * @return amount at given _index in _bin
   */
  function getValueInBin(uint256 _binValues, uint256 bitsize, uint256 _index)
    public pure returns (uint256)
  {
    // require(_index < IDS_PER_UINT256) is not required since getIDBinIndex ensures `_index < IDS_PER_UINT256`

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << bitsize) - 1;

    // Shift amount
    uint256 rightShift = bitsize * _index;
    return (_binValues >> rightShift) & mask;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// File: contracts/ERC1155/tokens/UGPackedBalance/UGMintBurnPackedBalance.sol


pragma solidity ^0.8.0;



/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions.
 */
contract UGMintBurnPackedBalance is UGPackedBalance {

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    //Add _amount
    _updateIDBalance(_to,   _id, _amount, Operations.Add); // Add amount to recipient

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each (_ids[i], _amounts[i]) pair
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    if(_ids.length != _amounts.length) revert MismatchArrays();

    if (_ids.length > 0) {
      // Load first bin and index where the token ID balance exists
      (uint256 bin, uint256 index) = getIDBinIndex(_ids[0]);

      // Balance for current bin in memory (initialized with first transfer)
      uint256 balTo = _viewUpdateBinValue(balances[_to][bin],IDS_BITS_SIZE, index, _amounts[0], Operations.Add);

      // Number of transfer to execute
      uint256 nTransfer = _ids.length;

      // Last bin updated
      uint256 lastBin = bin;

      for (uint256 i = 1; i < nTransfer; i++) {
        (bin, index) = getIDBinIndex(_ids[i]);

        // If new bin
        if (bin != lastBin) {
          // Update storage balance of previous bin
          balances[_to][lastBin] = balTo;
          balTo = balances[_to][bin];

          // Bin will be the most recent bin
          lastBin = bin;
        }

        // Update memory balance
        balTo = _viewUpdateBinValue(balTo, IDS_BITS_SIZE, index, _amounts[i], Operations.Add);
      }

      // Update storage of the last bin visited
      balances[_to][bin] = balTo;
    }

    // //Emit event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    // Substract _amount
    _updateIDBalance(_from, _id, _amount, Operations.Sub);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @dev This batchBurn method does not implement the most efficient way of updating
   *      balances to reduce the potential bug surface as this function is expected to
   *      be less common than transfers. EIP-2200 makes this method significantly
   *      more efficient already for packed balances.
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of burning to execute
    uint256 nBurn = _ids.length;
    if(nBurn != _amounts.length) revert MismatchArrays();

    // Executing all burning
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      _updateIDBalance(_from,   _ids[i], _amounts[i], Operations.Sub); // Add amount to recipient
    }

    // Emit batch burn event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// File: contracts/UGNFTs.sol


pragma solidity 0.8.13;






contract UGNFTs is UGMintBurnPackedBalance, IUGNFTs, Ownable {

  /*///////////////////////////////////////////////////////////////
                              TOKEN BASE  IDS
  //////////////////////////////////////////////////////////////*/

  uint16 constant RING = 5000;
  uint16 constant AMULET = 10000;
  uint16 constant FORGE = 15000;
  uint16 constant FIGHT_CLUB = 20000;
  uint32 constant FIGHTER = 100000;

  uint128 constant RING_MAX_SUPPLY = 4000;
  uint128 constant AMULET_MAX_SUPPLY = 4000;
  uint128 constant FORGE_MAX_SUPPLY = 2000;
  uint128 constant FIGHT_CLUB_MAX_SUPPLY = 2000;

  /*///////////////////////////////////////////////////////////////
                                 FIGHTERS
  //////////////////////////////////////////////////////////////*/  

   //user total balances bit indexes
  uint256 internal constant FIGHTER_INDEX  = 1;
  uint256 internal constant RING_INDEX  = 2;
  uint256 internal constant AMULET_INDEX  = 3;
  uint256 internal constant FORGE_INDEX  = 4;
  uint256 internal constant FIGHT_CLUB_INDEX  = 5;

  //maps id to packed fighter
  mapping(uint256 => uint256) public idToFYakuza;
  mapping(uint256 => ForgeFightClub) public idToForgeFightClub;
  mapping(uint256 => RingAmulet) public idToRingAmulet;

  uint256 public ttlRings;
  uint256 public ttlAmulets;
  uint256 public ttlFYakuzas;
  uint256 public ttlFightClubs;
  uint256 public ttlForges;

  /*///////////////////////////////////////////////////////////////
                              PRIVATE VARIABLES
  //////////////////////////////////////////////////////////////*/
  mapping(address => bool) private _admins;
  string public baseURI;

  /*///////////////////////////////////////////////////////////////
                                EVENTS
   //////////////////////////////////////////////////////////////*/
  event LevelUpFighter(uint256 indexed tokenId , uint256 indexed level, uint256 timestamp);
  event LevelUpRingAmulet(uint256 indexed tokenId , uint256 indexed level, uint256 timestamp);
  event LevelUpForgeFightClub(uint256 indexed tokenId , uint256 timestamp, uint256 indexed level, uint256 indexed size);
  event FighterYakuzaMigrated(uint256 indexed id, address indexed to, FighterYakuza fighter);
  event RingAmuletMinted(uint256 indexed id, address indexed to, RingAmulet ringAmulet);
  event ForgeFightClubMinted(uint256 indexed id, address indexed to, ForgeFightClub ffc);
  event RaidTraitsUpdated(uint256 indexed fighterId, FighterYakuza fighter);
  event FighterUpdated(uint256 indexed tokenId, FighterYakuza fighter);
  event FightClubUnstakeTimeUpdated(uint256 tokenId, uint256 timestamp);


  /*///////////////////////////////////////////////////////////////
                                ERRORS
  //////////////////////////////////////////////////////////////*/
  error Unauthorized();
  error InvalidTokenID(uint256 tokenId);
  error MaxSupplyReached();

  // set the base URI
  constructor(string memory uri, string memory __name, string memory __symbol)  {
    baseURI = uri;
    _name = __name;
    _symbol = __symbol;
  }

  /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
  //////////////////////////////////////////////////////////////*/


  modifier onlyAdmin() {
    if(!_admins[msg.sender]) revert Unauthorized();
    _;
  }

   function addAdmin(address addr) external onlyOwner {
    _admins[addr] = true;
  }

  function removeAdmin(address addr) external onlyOwner {
    delete _admins[addr];
  }

  function setBaseURI(string calldata uri) external onlyOwner {
    baseURI = uri;
  }

  /*///////////////////////////////////////////////////////////////
                    FIGHTER MIGRATION
  //////////////////////////////////////////////////////////////*/
  function batchMigrateFYakuza(
    address _to, 
    uint256[] calldata v1TokenIds,
    FighterYakuza[] calldata oldFighters
  ) external onlyAdmin {     
    if(v1TokenIds.length != oldFighters.length) revert MismatchArrays();

    uint256[] memory _ids = new uint256[](oldFighters.length);
    uint256[] memory _amounts = new uint256[](oldFighters.length);
    uint256 firstMintId = ttlFYakuzas + 1;
    // vars for packing
    uint256 newFighter;
    uint256 nextVal;
    for(uint i; i<oldFighters.length;i++){
      _ids[i] =  FIGHTER  + firstMintId++ ;
      _amounts[i] = 1;
        
      newFighter = oldFighters[i].isFighter ? 1 : 0;
      nextVal = 0;//setting all gen variables to 0
      newFighter |= nextVal<<1;
      nextVal = oldFighters[i].level;
      newFighter |= nextVal<<2;
      nextVal = oldFighters[i].isFighter ? 0 : oldFighters[i].rank;
      newFighter |= nextVal<<10;
      nextVal = oldFighters[i].courage;
      newFighter |= nextVal<<18;
      nextVal =  oldFighters[i].cunning;
      newFighter |= nextVal<<26;
      nextVal =  oldFighters[i].brutality;
      newFighter |= nextVal<<34;
      nextVal =  oldFighters[i].knuckles;
      newFighter |= nextVal<<42;
      nextVal =  oldFighters[i].chains;
      newFighter |= nextVal<<50;
      nextVal =  oldFighters[i].butterfly;
      newFighter |= nextVal<<58;
      nextVal =  oldFighters[i].machete;
      newFighter |= nextVal<<66;
      nextVal =  oldFighters[i].katana;
      newFighter |= nextVal<<74;
      nextVal =  oldFighters[i].Gen == 1 ? 0 : 100;
      newFighter |= nextVal<<90;
      //image id
      nextVal = v1TokenIds[i];
      newFighter |= nextVal<<106;
      //lastLevelUpgrade
      nextVal = block.timestamp;
      newFighter |= nextVal<<138;
      //lastRankUpgrade
      nextVal = block.timestamp;
      newFighter |= nextVal<<170;
      //lastRaidTime
      nextVal = block.timestamp;
      newFighter |= nextVal<<202;

      //add to array for first time (derived imageId from original v1 fighter)
      idToFYakuza[_ids[i]] = newFighter;

      emit FighterYakuzaMigrated(_ids[i], _to, unPackFighter(newFighter));
    }
    //update total fighter yakuzas
    ttlFYakuzas += oldFighters.length;
    //update fighter balance for user
    _updateIDUserTotalBalance(_to, FIGHTER_INDEX, v1TokenIds.length, Operations.Add); // Add amount to recipient
    _batchMint( _to,  _ids, _amounts, "");
  } 

  function mintRingAmulet(
    address _to, 
    uint256 _level, 
    bool isRing
  ) external onlyAdmin {
    
    uint256 _id;
    if(isRing){
      if(ttlRings >= RING_MAX_SUPPLY) revert MaxSupplyReached();
      _id = ++ttlRings + RING;

      //update ring balance for user
      _updateIDUserTotalBalance(_to, RING_INDEX, 1, Operations.Add);
    } else {
      if(ttlAmulets >= AMULET_MAX_SUPPLY) revert MaxSupplyReached();
      _id = ++ttlAmulets + AMULET;

      //update amulet balance for user
      _updateIDUserTotalBalance(_to, AMULET_INDEX, 1, Operations.Add);
    }

    RingAmulet memory traits;
    traits.level = uint8(_level);
    traits.lastLevelUpgradeTime = uint32(block.timestamp);
    idToRingAmulet[_id] = traits;

    _mint( _to,  _id, 1,  "");
    emit RingAmuletMinted(_id, _to, traits);
  }

  function mintFightClubForge(
    address _to, 
    bytes memory _data, 
    uint256 _size, 
    uint256 _level, 
    bool isFightClub
  ) external onlyAdmin {

    uint256 _id;
    if(isFightClub){
      if(ttlFightClubs >= FIGHT_CLUB_MAX_SUPPLY) revert MaxSupplyReached();
      _id = ++ttlFightClubs + FIGHT_CLUB;
      //update fight club balance for user
      _updateIDUserTotalBalance(_to, FIGHT_CLUB_INDEX, 1, Operations.Add);

    } else {
      if(ttlForges >= FORGE_MAX_SUPPLY) revert MaxSupplyReached();
      _id = ++ttlForges + FORGE;
      //update forge balance for user
      _updateIDUserTotalBalance(_to, FORGE_INDEX, 1, Operations.Add);
    }

    ForgeFightClub memory traits;
    traits.size = uint8(_size);
    traits.level = uint8(_level);
    traits.id = uint16(_id);
    traits.lastLevelUpgradeTime = uint32(block.timestamp);
    traits.owner = _to;
    idToForgeFightClub[_id] = traits;

    _mint( _to,  _id, 1,  _data);
    emit ForgeFightClubMinted(_id, _to, traits);
  }

  function levelUpFightClubsForges(
    uint256[] calldata tokenIds, 
    uint256[] calldata newSizes, 
    uint256[] calldata newLevels
  ) external onlyAdmin returns (ForgeFightClub[] memory) {
    if(tokenIds.length != newLevels.length) revert MismatchArrays();
    if(tokenIds.length != newSizes.length) revert MismatchArrays();
    ForgeFightClub[] memory traits = new ForgeFightClub[](tokenIds.length);

    for(uint i =0; i<tokenIds.length;i++){
      traits[i] = idToForgeFightClub[tokenIds[i]];
      //0 means no change to trait     
      traits[i].size = (newSizes[i] != 0) ? uint8(newSizes[i]) : traits[i].size;       
      traits[i].level = (newLevels[i] != 0) ? uint8(newLevels[i]) : traits[i].level;
      traits[i].lastLevelUpgradeTime = uint32(block.timestamp);      
      
      idToForgeFightClub[tokenIds[i]] = traits[i];  
    
      emit LevelUpForgeFightClub(tokenIds[i], block.timestamp, traits[i].level, traits[i].size);
    }
    return traits;
  }

  function levelUpRingAmulets(
    uint256 tokenId, 
    uint256 newLevel
  ) external onlyAdmin {
    
    RingAmulet memory traits ;
    traits.level = uint8(newLevel);
    traits.lastLevelUpgradeTime = uint32(block.timestamp);
    idToRingAmulet[tokenId] = traits;
    
    emit LevelUpRingAmulet(tokenId, traits.level, block.timestamp);
  }

  function levelUpFighters(uint256[] calldata tokenIds, uint256[] calldata levels) external onlyAdmin {
    if(tokenIds.length != levels.length) revert MismatchArrays();

    FighterYakuza memory fy;
    for(uint i =0; i<tokenIds.length;i++){
      fy = unPackFighter(idToFYakuza[tokenIds[i]]);
      if(fy.isFighter){
        fy.level = uint8(levels[i]);
        fy.lastLevelUpgradeTime = uint32(block.timestamp);
        idToFYakuza[tokenIds[i]] = packFighter(fy);
        emit LevelUpFighter(tokenIds[i], fy.level, block.timestamp);
      }
    }
  }

  function setRaidTraitsFromPacked(uint256[] memory packedTickets) external onlyAdmin {
    IUGRaid.RaidEntryTicket memory ticket;
    FighterYakuza memory FY;
    for(uint i =0; i<packedTickets.length;i++){
      ticket = unpackTicket(packedTickets[i]);
      
      if(ticket.fighterId > FIGHTER + ttlFYakuzas ||
        ticket.fighterId <= FIGHTER) revert InvalidTokenID({tokenId: ticket.fighterId});

      FY = unPackFighter(idToFYakuza[ticket.fighterId]);
      FY.brutality = ticket.brutality;
      FY.courage = ticket.courage;
      FY.cunning = ticket.cunning;
      FY.scars = ticket.scars;
      FY.knuckles = ticket.knuckles;
      FY.chains = ticket.chains;
      FY.butterfly = ticket.butterfly;
      FY.machete = ticket.machete;
      FY.katana = ticket.katana;
      FY.lastRaidTime = uint32(block.timestamp);
      //broken weapons scores will have modulo 10 (%10) = 1
      idToFYakuza[ticket.fighterId] = packFighter(FY);

      emit RaidTraitsUpdated(ticket.fighterId, FY);
    }
  }

  function getNftIDsForUser(address user, uint nftIndex) external view returns (uint256[] memory){
    //which nft?
    uint prefix;
    uint ttlNfts;
    if(nftIndex == FIGHTER_INDEX){
      prefix = FIGHTER;
      ttlNfts = ttlFYakuzas;
    }
    if(nftIndex == RING_INDEX){
      prefix = RING;
      ttlNfts = ttlRings;
    }
    if(nftIndex == AMULET_INDEX){
      prefix = AMULET;
      ttlNfts = ttlAmulets;
    }
    if(nftIndex == FIGHT_CLUB_INDEX){
      prefix = FIGHT_CLUB;
      ttlNfts = ttlFightClubs;
    }
    if(nftIndex == FORGE_INDEX){
      prefix = FORGE;
      ttlNfts = ttlForges;
    }
    //get balance of nfts
    uint256 num = getValueInBin(userTotalBalances[user], USER_TOTAL_BALANCES_BITS_SIZE, nftIndex);
    uint256[] memory _tokenIds = new uint256[](num);
    //loop through user balances until we find all the rings
    uint count;
    for(uint i=1; count<num && i <= ttlNfts; i++){
      if(balanceOf(user, prefix + i) ==1){
        _tokenIds[count] = prefix + i;
        count++;
      }
    }
    return _tokenIds;
  }

  function getForgeFightClubs(uint256[] calldata tokenIds) external view returns (ForgeFightClub[] memory){
    ForgeFightClub[] memory ffc = new ForgeFightClub[](tokenIds.length);
    for (uint i = 0; i < tokenIds.length; i++) {
      ffc[i] = idToForgeFightClub[tokenIds[i]];
    }
    return ffc;
  }

  function getForgeFightClub(uint256 tokenId) external view returns (ForgeFightClub memory){
    return idToForgeFightClub[tokenId];
  }

  function setFighter( uint256 tokenId, FighterYakuza memory FY) external onlyAdmin {
    idToFYakuza[tokenId] = packFighter(FY);
    emit FighterUpdated(tokenId, FY);
  }

  function setFightClubUnstakeTime (uint256 tokenId, bool isUnstaking) external onlyAdmin {
    idToForgeFightClub[tokenId].lastUnstakeTime = isUnstaking ? uint32(block.timestamp) : 0;
    emit FightClubUnstakeTimeUpdated(tokenId, block.timestamp);
  }

  function getFighters(uint256[] calldata tokenIds) external view returns (FighterYakuza[] memory){
    FighterYakuza[] memory FY = new FighterYakuza[](tokenIds.length);
    for (uint i = 0; i < tokenIds.length; i++) {
      FY[i] = unPackFighter(idToFYakuza[tokenIds[i]]);
    }
    return FY;
  }

  function getFighter(uint256 tokenId) external view returns (FighterYakuza memory){   
    return unPackFighter(idToFYakuza[tokenId]);    
  }

  function getPackedFighters(uint256[] calldata tokenIds) external view returns (uint256[] memory){
    uint256[] memory _packedFighters = new uint256[](tokenIds.length);
    for (uint i = 0; i < tokenIds.length; i++) {
      if(tokenIds[i] > FIGHTER + ttlFYakuzas || tokenIds[i] <= FIGHTER) revert InvalidTokenID({tokenId: tokenIds[i]});
      _packedFighters[i] = idToFYakuza[tokenIds[i]];
    }
    return _packedFighters;
  }

  function getRingAmulet(uint256 tokenId) external view returns (RingAmulet memory) {
    return idToRingAmulet[tokenId];
  }

  function safeTransferFrom(
    address _from, 
    address _to, 
    uint256 _id, 
    uint256 _amount, 
    bytes memory _data
  ) public override {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), " INVALID_OPERATOR");
    require(_to != address(0)," INVALID_RECIPIENT");
   
    if(_id > RING && _id <= RING + ttlRings) {
        _updateIDUserTotalBalance(_to, RING_INDEX, _amount, Operations.Add);
        _updateIDUserTotalBalance(_from, RING_INDEX, _amount, Operations.Sub);
      }
      if(_id > AMULET && _id <= AMULET + ttlAmulets){
        _updateIDUserTotalBalance(_to, AMULET_INDEX, _amount, Operations.Add);
        _updateIDUserTotalBalance(_from, AMULET_INDEX, _amount, Operations.Sub); 
      }
      if(_id > FIGHTER && _id <= FIGHTER + ttlFYakuzas) {
        _updateIDUserTotalBalance(_to, FIGHTER_INDEX, _amount, Operations.Add); // Add amount to recipient
        _updateIDUserTotalBalance(_from, FIGHTER_INDEX, _amount, Operations.Sub); // Add amount to recipient
      }
      if(_id > FIGHT_CLUB && _id <= FIGHT_CLUB + ttlFightClubs) {
        _updateIDUserTotalBalance(_to, FIGHT_CLUB_INDEX, _amount, Operations.Add); // Add amount to recipient
        _updateIDUserTotalBalance(_from, FIGHT_CLUB_INDEX, _amount, Operations.Sub); // Add amount to recipient
        idToForgeFightClub[_id].owner = _to;
      }
      if(_id > FORGE && _id <= FORGE + ttlForges) {
        _updateIDUserTotalBalance(_to, FORGE_INDEX, _amount, Operations.Add); // Add amount to recipient
        _updateIDUserTotalBalance(_from, FORGE_INDEX, _amount, Operations.Sub); // Add amount to recipient
        idToForgeFightClub[_id].owner = _to;
      }

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  function safeBatchTransferFrom(
    address _from, 
    address _to, 
    uint256[] calldata _ids, 
    uint256[] calldata _amounts,
    bytes memory _data
  ) public override (UGPackedBalance, IUGNFTs){
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), " INVALID_OPERATOR");
    require(_to != address(0)," INVALID_RECIPIENT");
    uint256 _index;

    for(uint i = 0; i < _ids.length; i++){
      if(_ids[i] > RING && _ids[i] <= RING + ttlRings){
        _index = RING_INDEX;
      } 
      if(_ids[i] > AMULET && _ids[i] <= AMULET + ttlAmulets) {
        _index = AMULET_INDEX;
      }
      if(_ids[i] > FIGHTER && _ids[i] <= FIGHTER + ttlFYakuzas) _index = FIGHTER_INDEX;
      if(_ids[i] > FIGHT_CLUB && _ids[i]<= FIGHT_CLUB + ttlFightClubs) {
        _index = FIGHT_CLUB_INDEX;
        idToForgeFightClub[_ids[i]].owner = _to;
      }
      if(_ids[i] > FORGE && _ids[i] <= FORGE + ttlForges) {
        _index = FORGE_INDEX;
        idToForgeFightClub[_ids[i]].owner = _to;
      }

      _updateIDUserTotalBalance(_to, _index, _amounts[i], Operations.Add);
      _updateIDUserTotalBalance(_from, _index, _amounts[i], Operations.Sub);  
    }

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }

  function checkUserBatchBalance(address user, uint256[] calldata tokenIds) external view returns (bool){
    for (uint i = 0; i < tokenIds.length;i++){
      uint256 bal = balanceOf(user, tokenIds[i]);
      if(bal == 0) revert InvalidTokenID({tokenId: tokenIds[i]});
    }
    return true;
  }

  string private _name;
  string private _symbol;

  function name() external view returns (string memory){
    return _name;
  }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory){
      return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
   // function tokenURI(uint256 tokenId) external view returns (string memory);

  function tokenURIs(uint256[] calldata tokenIds) external view returns (string[] memory) {
    string memory jsonString;
    string memory fyakuza;
    string memory imageId;
    string[] memory uris = new string[](tokenIds.length);

    for(uint256 i; i<tokenIds.length;i++){
      //if fighter
      if(tokenIds[i] > FIGHTER && tokenIds[i] <= FIGHTER + ttlFYakuzas) {
        FighterYakuza memory traits = unPackFighter(idToFYakuza[tokenIds[i]]);
        if (traits.imageId != 0) {
          imageId = Strings.toString(traits.imageId);
          jsonString = string(abi.encodePacked(
          jsonString,
          Strings.toString(tokenIds[i]),',',
          Strings.toString((traits.isFighter)? 1 : 0),',',
          Strings.toString(traits.Gen),',',
          Strings.toString(traits.cunning),',',
          Strings.toString(traits.brutality),','
          ));

          jsonString = string(abi.encodePacked(
          jsonString,
          Strings.toString(traits.courage),',',
          Strings.toString(traits.level),',',
          Strings.toString(traits.lastLevelUpgradeTime),',',
          Strings.toString(traits.rank),',',
          Strings.toString(traits.lastRaidTime),','
          ));

          jsonString = string(abi.encodePacked(
          jsonString,
          Strings.toString(traits.scars),',',
          Strings.toString(traits.knuckles),',',
          Strings.toString(traits.chains),',',
          Strings.toString(traits.butterfly),',',
          Strings.toString(traits.machete),',',
          Strings.toString(traits.katana)
          ));
        }

        fyakuza = traits.isFighter ? "fighteryakuza/fighter/" : "fighteryakuza/yakuza/";

        uris[i] = string(abi.encodePacked(
          baseURI,
          fyakuza,
          imageId,
          ".png",
          "?traits=",
          jsonString
        ));
      }

      //if ring
      if(tokenIds[i] > RING && tokenIds[i] <= RING + ttlRings) {
        RingAmulet memory traits = idToRingAmulet[tokenIds[i]];
        if (traits.lastLevelUpgradeTime != 0) {
          jsonString = string(abi.encodePacked(
          jsonString,
          Strings.toString(traits.level),',',
          Strings.toString(traits.lastLevelUpgradeTime)
          ));
        }

        uris[i] = string(abi.encodePacked(
          baseURI,
          "ring/ring.png",
          "?traits=",
          jsonString
        ));
      }

      //if amulet
      if(tokenIds[i] > AMULET && tokenIds[i] <= AMULET + ttlAmulets) {
        RingAmulet memory traits = idToRingAmulet[tokenIds[i]];
        if (traits.lastLevelUpgradeTime != 0) {
          jsonString = string(abi.encodePacked(
          jsonString,
          Strings.toString(traits.level),',',
          Strings.toString(traits.lastLevelUpgradeTime)
          ));
        }

        uris[i] = string(abi.encodePacked(
          baseURI,
          "amulet/amulet.png",
          "?traits=",
          jsonString
        ));
      }

    //if forge or fight club
      if( (tokenIds[i] > FORGE && tokenIds[i] <= FORGE + ttlForges) ||
          (tokenIds[i] > FIGHT_CLUB && tokenIds[i] <= FIGHT_CLUB + ttlFightClubs) ){
        //get forge / fight club
        ForgeFightClub memory traits = idToForgeFightClub[tokenIds[i]];
        //if Fight Club
        if(tokenIds[i] > FIGHT_CLUB && tokenIds[i] <= FIGHT_CLUB + ttlFightClubs){
          //using imageId as a holder variable for url segment
          imageId = string(abi.encodePacked('fightclub/',Strings.toString(tokenIds[i]))) ;//replace with fight club image id
        }
        //if forge
        if(tokenIds[i] > FORGE && tokenIds[i] <= FORGE + ttlForges){
          //using imageId as a holder variable for url segment
          imageId = string(abi.encodePacked('forge/',Strings.toString(traits.size))) ;//replace with fight club image id
        }

        if (traits.lastLevelUpgradeTime != 0) {
          jsonString = string(abi.encodePacked(
          jsonString,
          Strings.toString(traits.id),',',
          Strings.toString(traits.level),',',
          Strings.toString(traits.size),',',
          Strings.toString(traits.lastLevelUpgradeTime),',',
          Strings.toString(traits.lastUnstakeTime)
          ));
        }

        uris[i] = string(abi.encodePacked(
          baseURI,
          imageId,
          ".png",
          "?traits=",
          jsonString
        ));
      }
    }

    return uris;
  }

   function unPackFighter(uint256 packedFighter) private pure returns (FighterYakuza memory) {
    FighterYakuza memory fighter;   
    fighter.isFighter = uint8(packedFighter)%2 == 1 ? true : false;
    fighter.Gen = uint8(packedFighter>>1)%2 ;
    fighter.level = uint8(packedFighter>>2);
    fighter.rank = uint8(packedFighter>>10);
    fighter.courage = uint8(packedFighter>>18);
    fighter.cunning = uint8(packedFighter>>26);
    fighter.brutality = uint8(packedFighter>>34);
    fighter.knuckles = uint8(packedFighter>>42);
    fighter.chains = uint8(packedFighter>>50);
    fighter.butterfly = uint8(packedFighter>>58);
    fighter.machete = uint8(packedFighter>>66);
    fighter.katana = uint8(packedFighter>>74);
    fighter.scars = uint16(packedFighter>>90);
    fighter.imageId = uint16(packedFighter>>106);
    fighter.lastLevelUpgradeTime = uint32(packedFighter>>138);
    fighter.lastRankUpgradeTime = uint32(packedFighter>>170);
    fighter.lastRaidTime = uint32(packedFighter>>202);
    return fighter;
  }

  function packFighter(FighterYakuza memory unPackedFighter) private pure returns (uint256 ){
    uint256 packedFighter = unPackedFighter.isFighter ? 1 : 0;
      uint256 nextVal = unPackedFighter.Gen;
      packedFighter |= nextVal<<1;
      nextVal = unPackedFighter.level;
      packedFighter |= nextVal<<2;
      nextVal = unPackedFighter.isFighter ? 0 : unPackedFighter.rank;
      packedFighter |= nextVal<<10;
      nextVal = unPackedFighter.courage;
      packedFighter |= nextVal<<18;
      nextVal =  unPackedFighter.cunning;
      packedFighter |= nextVal<<26;
      nextVal =  unPackedFighter.brutality;
      packedFighter |= nextVal<<34;
      nextVal =  unPackedFighter.knuckles;
      packedFighter |= nextVal<<42;
      nextVal =  unPackedFighter.chains;
      packedFighter |= nextVal<<50;
      nextVal =  unPackedFighter.butterfly;
      packedFighter |= nextVal<<58;
      nextVal =  unPackedFighter.machete;
      packedFighter |= nextVal<<66;
      nextVal =  unPackedFighter.katana;
      packedFighter |= nextVal<<74;
      nextVal =  unPackedFighter.scars;
      packedFighter |= nextVal<<90;
      //image id
      nextVal = unPackedFighter.imageId;
      packedFighter |= nextVal<<106;
      //lastLevelUpgrade
      nextVal = unPackedFighter.lastLevelUpgradeTime;
      packedFighter |= nextVal<<138;
      //lastRankUpgrade
      nextVal = unPackedFighter.lastRankUpgradeTime;
      packedFighter |= nextVal<<170;
      //lastRaidTime
      nextVal = unPackedFighter.lastRaidTime;
      packedFighter |= nextVal<<202;
      return packedFighter;
  }

   function unpackTicket(uint256 packedTicket) 
    private pure returns (IUGRaid.RaidEntryTicket memory _ticket)
  {
      _ticket.sizeTier = uint8(packedTicket);
      _ticket.fighterLevel = uint8(packedTicket>>8);
      _ticket.yakuzaFamily = uint8(packedTicket>>16);
      _ticket.courage = uint8(packedTicket>>24);
      _ticket.brutality = uint8(packedTicket>>32);
      _ticket.cunning = uint8(packedTicket>>40);
      _ticket.knuckles = uint8(packedTicket>>48);
      _ticket.chains = uint8(packedTicket>>56);
      _ticket.butterfly = uint8(packedTicket>>64);
      _ticket.machete = uint8(packedTicket>>72);
      _ticket.katana = uint8(packedTicket>>80);
      _ticket.scars = uint16(packedTicket>>96);
      _ticket.sweat = uint32(packedTicket>>128);
      _ticket.fighterId = uint32(packedTicket>>160);
      _ticket.entryFee = uint32(packedTicket>>192);
      return _ticket;
  }

  /*///////////////////////////////////////////////////////////////
                       ERC165 FUNCTIONS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(UGPackedBalance) virtual pure returns (bool) {
    if (_interfaceID == 0xd9b67a26 ||
        _interfaceID == 0x0e89341c) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }

  //////////////////////////////////////
  //      Unsupported Functions       //
  /////////////////////////////////////

  fallback () external {
    revert("UGNFTs: INVALID_METHOD");
  }
}