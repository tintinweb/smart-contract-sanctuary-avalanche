/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-21
*/

// File: ERC1155.sol


pragma solidity >=0.8.0;

// import 'hardhat/console.sol';

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    event PauseFlipped(bool paused);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NoArrayParity();

    error Paused();

    error SignatureExpired();

    error NullAddress();

    error InvalidNonce();

    error NotDetermined();

    error InvalidSignature();

    error Uint32max();

    error Uint96max();

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
        );

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    uint256 internal INITIAL_CHAIN_ID = 43114;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                            DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    bool public paused;

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 deadline)');

    mapping(address => address) internal _delegates;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => uint256) public numCheckpoints;

    struct Checkpoint {
        uint32 fromTimestamp;
        uint96 votes;
    }

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    //function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            'UNSAFE_RECIPIENT'
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, 'LENGTH_MISMATCH');

        require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            'UNSAFE_RECIPIENT'
        );
    }

    // REMOVED - Reduced gas 0.6kb
    // function balanceOfBatch(address[] memory owners, uint256[] memory ids)
    //     public
    //     view
    //     virtual
    //     returns (uint256[] memory balances)
    // {
    //     uint256 ownersLength = owners.length; // Saves MLOADs.

    //     require(ownersLength == ids.length, 'LENGTH_MISMATCH');

    //     balances = new uint256[](owners.length);

    //     // Unchecked because the only math done is incrementing
    //     // the array index counter which cannot possibly overflow.
    //     unchecked {
    //         for (uint256 i = 0; i < ownersLength; i++) {
    //             balances[i] = balanceOf[owners[i]][ids[i]];
    //         }
    //     }
    // }

    //////////// check this
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes(name)),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    ////////////////////
    /*///////////////////////////////////////////////////////////////
                            DAO LOGIC
    //////////////////////////////////////////////////////////////*/

    // modifier notPaused() {
    //     if (paused) revert Paused();

    //     _;
    // }

    function delegates(address delegator) public view virtual returns (address) {
        address current = _delegates[delegator];

        return current == address(0) ? delegator : current;
    }

    function getCurrentVotes(address account) public view virtual returns (uint256) {
        // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];

            return nCheckpoints != 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    // function delegateBySig(
    //     address delegatee,
    //     uint256 nonce,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) public virtual {
    //     if (block.timestamp > deadline) revert SignatureExpired();

    //     bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, deadline));

    //     bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

    //     address signatory = ecrecover(digest, v, r, s);

    //     if (signatory == address(0)) revert NullAddress();

    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         if (nonce != nonces[signatory]++) revert InvalidNonce();
    //     }

    //     _delegate(signatory, delegatee);
    // }

    // function getPriorVotes(address account, uint256 timestamp) public view virtual returns (uint96) {
    //     if (block.timestamp <= timestamp) revert NotDetermined();

    //     uint256 nCheckpoints = numCheckpoints[account];

    //     if (nCheckpoints == 0) return 0;

    //     // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
    //     unchecked {
    //         if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp)
    //             return checkpoints[account][nCheckpoints - 1].votes;

    //         if (checkpoints[account][0].fromTimestamp > timestamp) return 0;

    //         uint256 lower;

    //         // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
    //         uint256 upper = nCheckpoints - 1;

    //         while (upper > lower) {
    //             // this is safe from underflow because `upper` ceiling is provided
    //             uint256 center = upper - (upper - lower) / 2;

    //             Checkpoint memory cp = checkpoints[account][center];

    //             if (cp.fromTimestamp == timestamp) {
    //                 return cp.votes;
    //             } else if (cp.fromTimestamp < timestamp) {
    //                 lower = center;
    //             } else {
    //                 upper = center - 1;
    //             }
    //         }

    //     return checkpoints[account][lower].votes;

    //     }
    // }

    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator][1]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal virtual {
        if (srcRep != dstRep && amount != 0)
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];

                uint256 srcRepOld = srcRepNum != 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

        if (dstRep != address(0)) {
            uint256 dstRepNum = numCheckpoints[dstRep];

            uint256 dstRepOld = dstRepNum != 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

            uint256 dstRepNew = dstRepOld + amount;

            _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal virtual {
        unchecked {
            // this is safe from underflow because decrement only occurs if `nCheckpoints` is positive
            if (
                nCheckpoints != 0 &&
                checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp
            ) {
                checkpoints[delegatee][nCheckpoints - 1].votes = _safeCastTo96(newVotes);
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(
                    _safeCastTo32(block.timestamp),
                    _safeCastTo96(newVotes)
                );

                // cannot realistically overflow on human timescales
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        // TODO WHY DOES THIS REVERT WITH THE TEABLE CONTRACT?? SHOULD BE 1155!
        // require(
        //     to.code.length == 0
        //         ? to != address(0)
        //         : ERC1155TokenReceiver(to).onERC1155Received(
        //             msg.sender,
        //             address(0),
        //             id,
        //             amount,
        //             data
        //         ) == ERC1155TokenReceiver.onERC1155Received.selector,
        //     'UNSAFE_RECIPIENT'
        // );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, 'LENGTH_MISMATCH');

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            'UNSAFE_RECIPIENT'
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, 'LENGTH_MISMATCH');

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /*///////////////////////////////////////////////////////////////
                            PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _flipPause() internal virtual {
        paused = !paused;

        emit PauseFlipped(paused);
    }

    /*///////////////////////////////////////////////////////////////
                            SAFECAST LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
        if (x > type(uint32).max) revert Uint32max();

        return uint32(x);
    }

    function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
        if (x > type(uint96).max) revert Uint96max();

        return uint96(x);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// File: ReentrancyGuard.sol



pragma solidity >=0.8.4;

/// @notice Gas-optimized reentrancy protection.
/// @author Modified from OpenZeppelin 
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/// License-Identifier: MIT
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant NOT_ENTERED = 1;

    uint256 private constant ENTERED = 2;

    uint256 private status = NOT_ENTERED;

    modifier nonReentrant() {
        if (status == ENTERED) revert Reentrancy();

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }
}

// File: Multicall.sol



pragma solidity >=0.8.4;

// TODO remove if not needed

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
    function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);

        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);

                if (!success) {
                    if (result.length < 68) revert();

                    assembly {
                        result := add(result, 0x04)
                    }

                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }
}

// File: TableMultisig.sol



pragma solidity >=0.8.4;

// import 'hardhat/console.sol';

// import './KaliDAOtoken.sol';

// import './utils/NFThelper.sol';



// import './utils/Base64.sol';

library Base64 {
  string internal constant TABLE_ENCODE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  bytes internal constant TABLE_DECODE =
    hex"0000000000000000000000000000000000000000000000000000000000000000"
    hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
    hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
    hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE_ENCODE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        // read 3 bytes
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)

        // write 4 characters
        mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }

  function decode(string memory _data) internal pure returns (bytes memory) {
    bytes memory data = bytes(_data);

    if (data.length == 0) return new bytes(0);
    require(data.length % 4 == 0, "invalid base64 decoder input");

    // load the table into memory
    bytes memory table = TABLE_DECODE;

    // every 4 characters represent 3 bytes
    uint256 decodedLen = (data.length / 4) * 3;

    // add some extra buffer at the end required for the writing
    bytes memory result = new bytes(decodedLen + 32);

    assembly {
      // padding with '='
      let lastBytes := mload(add(data, mload(data)))
      if eq(and(lastBytes, 0xFF), 0x3d) {
        decodedLen := sub(decodedLen, 1)
        if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
          decodedLen := sub(decodedLen, 1)
        }
      }

      // set the actual output length
      mstore(result, decodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 4 characters at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        // read 4 characters
        dataPtr := add(dataPtr, 4)
        let input := mload(dataPtr)

        // write 3 bytes
        let output := add(
          add(
            shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
            shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
          ),
          add(
            shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
            and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
          )
        )
        mstore(resultPtr, shl(232, output))
        resultPtr := add(resultPtr, 3)
      }
    }

    return result;
  }
}

// TODO
// - create extensions
// - consider implementing EIP-2612 for approval of tokens externally

/// @notice Simple gas-optimized Roundtable group module.
/// @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)

// contract TableMultisig is KaliDAOtoken, Multicall, NFThelper, ReentrancyGuard {
contract TableMultisig is ERC1155, ReentrancyGuard, Multicall {
  /*///////////////////////////////////////////////////////////////
														EVENTS
		//////////////////////////////////////////////////////////////*/

  event NewProposal(address indexed proposer, uint256 indexed proposal);

  event ProposalCancelled(address indexed proposer, uint256 indexed proposal);

  event ProposalSponsored(address indexed sponsor, uint256 indexed proposal);

  event VoteCast(
    address indexed voter,
    uint256 indexed proposal,
    bool indexed approve
  );

  event ProposalProcessed(
    uint256 indexed proposal,
    bool indexed didProposalPass
  );

  /*///////////////////////////////////////////////////////////////
														ERRORS
		//////////////////////////////////////////////////////////////*/

  error Initialized();

  error MemberLimitExceeded();

  error VotingPeriodBounds();

  error QuorumMax();

  error SupermajorityBounds();

  error InitCallFail();

  error TypeBounds();

  error NotProposer();

  error Sponsored();

  error NotMember();

  error NotCurrentProposal();

  error AlreadyVoted();

  error NotVoteable();

  error VotingNotEnded();

  error PrevNotProcessed();

  error NotExtension();

  /*///////////////////////////////////////////////////////////////
														DAO STORAGE
		//////////////////////////////////////////////////////////////*/
  uint256 public constant SHIELDPASS = 0;

  uint256 public constant SHIELD = 1;

  uint256 public constant TOKEN = 2;

  uint256 private memberCount;

  uint256 private currentSponsoredProposal;

  uint256 public proposalCount;

  string public docs;

  uint32 public votingPeriod;

  uint8 public quorum; // 1-100

  uint8 public supermajority; // 1-100

  bytes32 public constant VOTE_HASH =
    keccak256("SignVote(address signer,uint256 proposal,bool approve)");

  mapping(uint256 => address) public members;

  mapping(address => bool) public extensions;

  mapping(uint256 => Proposal) public proposals;

  mapping(uint256 => ProposalState) public proposalStates;

  mapping(ProposalType => VoteType) public proposalVoteTypes;

  mapping(uint256 => mapping(address => bool)) public voted;

  mapping(address => uint256) public lastYesVote;

  enum ProposalType {
    MINT, // add membership
    BURN, // revoke membership
    CALL, // call contracts
    PERIOD, // set `votingPeriod`
    QUORUM, // set `quorum`
    SUPERMAJORITY, // set `supermajority`
    TYPE, // set `VoteType` to `ProposalType`
    PAUSE, // flip membership transferability
    EXTENSION, // flip `extensions` whitelisting
    ESCAPE, // delete pending proposal in case of revert
    DOCS // amend org docs
  }

  enum VoteType {
    SIMPLE_MAJORITY,
    SIMPLE_MAJORITY_QUORUM_REQUIRED,
    SUPERMAJORITY,
    SUPERMAJORITY_QUORUM_REQUIRED
  }

  struct Proposal {
    ProposalType proposalType;
    string description;
    address[] accounts; // member(s) being added/kicked; account(s) receiving payload
    uint256[] amounts; // value(s) to be minted/burned/spent; gov setting [0]
    bytes[] payloads; // data for CALL proposals
    uint256 prevProposal;
    uint96 yesVotes;
    uint96 noVotes;
    uint32 creationTime;
    address proposer;
  }

  struct ProposalState {
    bool passed;
    bool processed;
  }

  /*///////////////////////////////////////////////////////////////
														CONSTRUCTOR
		//////////////////////////////////////////////////////////////*/

  function init(
    string memory name_,
    string memory symbol_,
    string memory docs_,
    bool paused_,
    address[] memory extensions_,
    bytes[] memory extensionsData_,
    address[] memory voters_,
    uint256[] memory shares_,
    uint32 votingPeriod_,
    uint8[13] memory govSettings_
  ) public payable virtual nonReentrant {
    if (voters_.length > 12) revert MemberLimitExceeded();

    if (extensions_.length != extensionsData_.length) revert NoArrayParity();

    if (votingPeriod != 0) revert Initialized();

    if (votingPeriod_ == 0 || votingPeriod_ > 365 days)
      revert VotingPeriodBounds();

    if (govSettings_[0] > 100) revert QuorumMax();

    if (govSettings_[1] <= 51 || govSettings_[1] > 100)
      revert SupermajorityBounds();

    // KaliDAOtoken._init(name_, symbol_, paused_, voters_, shares_);

    // if (extensions_.length != 0) {
    //     // cannot realistically overflow on human timescales
    //     unchecked {
    //         for (uint256 i; i < extensions_.length; i++) {
    //             extensions[extensions_[i]] = true;

    //             if (extensionsData_[i].length != 0) {
    //                 (bool success, ) = extensions_[i].call(extensionsData_[i]);

    //                 if (!success) revert InitCallFail();
    //             }
    //         }
    //     }
    // }

    // mint pass to create shield
    address t = address(this);
    // console.log(t);
    _mint(t, SHIELDPASS, 1, "");
    // console.log('after mint');

    // // voters can never be more than 12
    unchecked {
      for (uint256 i; i < voters_.length; i++) {
        _mint(address(this), 2, shares_[i], "");
        members[i] = voters_[i];
      }
    }

    name = name_;

    symbol = symbol_;

    paused = paused_;

    docs = docs_;

    votingPeriod = votingPeriod_;

    memberCount = voters_.length;

    quorum = govSettings_[0];

    supermajority = govSettings_[1];

    // set initial vote types
    proposalVoteTypes[ProposalType.MINT] = VoteType(govSettings_[2]);

    proposalVoteTypes[ProposalType.BURN] = VoteType(govSettings_[3]);

    proposalVoteTypes[ProposalType.CALL] = VoteType(govSettings_[4]);

    proposalVoteTypes[ProposalType.PERIOD] = VoteType(govSettings_[5]);

    proposalVoteTypes[ProposalType.QUORUM] = VoteType(govSettings_[6]);

    proposalVoteTypes[ProposalType.SUPERMAJORITY] = VoteType(govSettings_[7]);

    proposalVoteTypes[ProposalType.TYPE] = VoteType(govSettings_[8]);

    proposalVoteTypes[ProposalType.PAUSE] = VoteType(govSettings_[9]);

    proposalVoteTypes[ProposalType.EXTENSION] = VoteType(govSettings_[10]);

    proposalVoteTypes[ProposalType.ESCAPE] = VoteType(govSettings_[11]);

    proposalVoteTypes[ProposalType.DOCS] = VoteType(govSettings_[12]);
  }

  /*///////////////////////////////////////////////////////////////
													PROPOSAL LOGIC
	//////////////////////////////////////////////////////////////*/

  function getProposalArrays(uint256 proposal)
    public
    view
    virtual
    returns (
      address[] memory accounts,
      uint256[] memory amounts,
      bytes[] memory payloads
    )
  {
    Proposal storage prop = proposals[proposal];

    (accounts, amounts, payloads) = (
      prop.accounts,
      prop.amounts,
      prop.payloads
    );
  }

  function propose(
    ProposalType proposalType,
    string calldata description,
    address[] calldata accounts,
    uint256[] calldata amounts,
    bytes[] calldata payloads
  ) public virtual nonReentrant returns (uint256 proposal) {
    if (accounts.length != amounts.length || amounts.length != payloads.length)
      revert NoArrayParity();

    if (proposalType == ProposalType.PERIOD)
      if (amounts[0] == 0 || amounts[0] > 365 days) revert VotingPeriodBounds();

    if (proposalType == ProposalType.QUORUM)
      if (amounts[0] > 100) revert QuorumMax();

    if (proposalType == ProposalType.SUPERMAJORITY)
      if (amounts[0] <= 51 || amounts[0] > 100) revert SupermajorityBounds();

    if (proposalType == ProposalType.TYPE)
      if (amounts[0] > 10 || amounts[1] > 3 || amounts.length != 2)
        revert TypeBounds();

    if (proposalType == ProposalType.MINT)
      if ((memberCount + accounts.length) > 12) revert MemberLimitExceeded();

    bool selfSponsor;

    // if member or extension is making proposal, include sponsorship
    if (balanceOf[msg.sender][SHIELD] != 0 || extensions[msg.sender])
      selfSponsor = true;

    // cannot realistically overflow on human timescales
    unchecked {
      proposalCount++;
    }

    proposal = proposalCount;

    proposals[proposal] = Proposal({
      proposalType: proposalType,
      description: description,
      accounts: accounts,
      amounts: amounts,
      payloads: payloads,
      prevProposal: selfSponsor ? currentSponsoredProposal : 0,
      yesVotes: 0,
      noVotes: 0,
      creationTime: selfSponsor ? _safeCastTo32(block.timestamp) : 0,
      proposer: msg.sender
    });

    if (selfSponsor) currentSponsoredProposal = proposal;

    emit NewProposal(msg.sender, proposal);
  }

  function cancelProposal(uint256 proposal) public virtual nonReentrant {
    Proposal storage prop = proposals[proposal];

    if (msg.sender != prop.proposer) revert NotProposer();

    if (prop.creationTime != 0) revert Sponsored();

    delete proposals[proposal];

    emit ProposalCancelled(msg.sender, proposal);
  }

  function sponsorProposal(uint256 proposal) public virtual nonReentrant {
    Proposal storage prop = proposals[proposal];

    if (balanceOf[msg.sender][TOKEN] == 0) revert NotMember();

    if (prop.proposer == address(0)) revert NotCurrentProposal();

    if (prop.creationTime != 0) revert Sponsored();

    prop.prevProposal = currentSponsoredProposal;

    currentSponsoredProposal = proposal;

    prop.creationTime = _safeCastTo32(block.timestamp);

    emit ProposalSponsored(msg.sender, proposal);
  }

  function vote(uint256 proposal, bool approve) public virtual nonReentrant {
    _vote(msg.sender, proposal, approve);
  }

  function voteBySig(
    address signer,
    uint256 proposal,
    bool approve,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual nonReentrant {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR(),
        keccak256(abi.encode(VOTE_HASH, signer, proposal, approve))
      )
    );

    address recoveredAddress = ecrecover(digest, v, r, s);

    if (recoveredAddress == address(0) || recoveredAddress != signer)
      revert InvalidSignature();

    _vote(signer, proposal, approve);
  }

  function _vote(
    address signer,
    uint256 proposal,
    bool approve
  ) internal virtual {
    Proposal storage prop = proposals[proposal];

    if (balanceOf[signer][TOKEN] == 0) revert NotMember();

    if (voted[proposal][signer]) revert AlreadyVoted();

    // this is safe from overflow because `votingPeriod` is capped so it will not combine
    // with unix time to exceed the max uint256 value
    unchecked {
      if (block.timestamp > prop.creationTime + votingPeriod)
        revert NotVoteable();
    }

    // TODO implement weighted voting
    /////uint96 weight = getPriorVotes(signer, prop.creationTime);
    uint96 weight = 1;

    // this is safe from overflow because `yesVotes` and `noVotes` are capped by `totalSupply`
    // which is checked for overflow in `KaliDAOtoken` contract
    unchecked {
      if (approve) {
        prop.yesVotes += weight;

        lastYesVote[signer] = proposal;
      } else {
        prop.noVotes += weight;
      }
    }

    voted[proposal][signer] = true;

    emit VoteCast(signer, proposal, approve);
  }

  function processProposal(uint256 proposal)
    public
    virtual
    nonReentrant
    returns (bool didProposalPass, bytes[] memory results)
  {
    Proposal storage prop = proposals[proposal];

    VoteType voteType = proposalVoteTypes[prop.proposalType];

    if (prop.creationTime == 0) revert NotCurrentProposal();

    // this is safe from overflow because `votingPeriod` is capped so it will not combine
    // with unix time to exceed the max uint256 value
    unchecked {
      if (block.timestamp <= prop.creationTime + votingPeriod)
        revert VotingNotEnded();
    }

    // skip previous proposal processing requirement in case of escape hatch
    if (prop.proposalType != ProposalType.ESCAPE)
      if (proposals[prop.prevProposal].creationTime != 0)
        revert PrevNotProcessed();

    didProposalPass = _countVotes(voteType, prop.yesVotes, prop.noVotes);

    if (didProposalPass) {
      // cannot realistically overflow on human timescales
      unchecked {
        if (prop.proposalType == ProposalType.MINT)
          for (uint256 i; i < prop.accounts.length; i++) {
            _mint(prop.accounts[i], 0, prop.amounts[i], "");
          }
        //
        // TODO Add burn of token supply / redemption
        //
        if (prop.proposalType == ProposalType.BURN)
          for (uint256 i; i < prop.accounts.length; i++) {
            _burn(prop.accounts[i], 0, prop.amounts[i]);
          }

        if (prop.proposalType == ProposalType.CALL)
          for (uint256 i; i < prop.accounts.length; i++) {
            results = new bytes[](prop.accounts.length);

            (, bytes memory result) = prop.accounts[i].call{
              value: prop.amounts[i]
            }(prop.payloads[i]);

            results[i] = result;
          }

        // governance settings
        if (prop.proposalType == ProposalType.PERIOD)
          if (prop.amounts[0] != 0) votingPeriod = uint32(prop.amounts[0]);

        if (prop.proposalType == ProposalType.QUORUM)
          if (prop.amounts[0] != 0) quorum = uint8(prop.amounts[0]);

        if (prop.proposalType == ProposalType.SUPERMAJORITY)
          if (prop.amounts[0] != 0) supermajority = uint8(prop.amounts[0]);

        if (prop.proposalType == ProposalType.TYPE)
          proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(
            prop.amounts[1]
          );

        if (prop.proposalType == ProposalType.PAUSE) _flipPause();

        // if (prop.proposalType == ProposalType.EXTENSION)
        //     for (uint256 i; i < prop.accounts.length; i++) {
        //         if (prop.amounts[i] != 0)
        //             extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

        //         if (prop.payloads[i].length != 0)
        //             IKaliDAOextension(prop.accounts[i]).setExtension(prop.payloads[i]);
        //     }

        if (prop.proposalType == ProposalType.ESCAPE)
          delete proposals[prop.amounts[0]];

        if (prop.proposalType == ProposalType.DOCS) docs = prop.description;

        proposalStates[proposal].passed = true;
      }
    }

    delete proposals[proposal];

    proposalStates[proposal].processed = true;

    emit ProposalProcessed(proposal, didProposalPass);
  }

  function _countVotes(
    VoteType voteType,
    uint256 yesVotes,
    uint256 noVotes
  ) internal view virtual returns (bool didProposalPass) {
    // fail proposal if no participation
    if (yesVotes == 0 && noVotes == 0) return false;

    // rule out any failed quorums
    if (
      voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED ||
      voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED
    ) {
      uint256 minVotes = (12 * quorum) / 100;
      // uint256 minVotes = (totalSupply * quorum) / 100;

      // this is safe from overflow because `yesVotes` and `noVotes`
      // supply are checked in `KaliDAOtoken` contract
      unchecked {
        uint256 votes = yesVotes + noVotes;

        if (votes < minVotes) return false;
      }
    }

    // simple majority check
    if (
      voteType == VoteType.SIMPLE_MAJORITY ||
      voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED
    ) {
      if (yesVotes > noVotes) return true;
      // supermajority check
    } else {
      // example: 7 yes, 2 no, supermajority = 66
      // ((7+2) * 66) / 100 = 5.94; 7 yes will pass
      uint256 minYes = ((yesVotes + noVotes) * supermajority) / 100;

      if (yesVotes >= minYes) return true;
    }
  }

  /*///////////////////////////////////////////////////////////////
														UTILITIES 
		//////////////////////////////////////////////////////////////*/

  receive() external payable virtual {}

  function createShields(
    string calldata groupName,
    string calldata svgPartOne,
    string calldata svgPartTwo
  ) public virtual nonReentrant {
    // mint 12 shields
    if (balanceOf[msg.sender][TOKEN] == 0) revert NotMember();
    if (balanceOf[address(this)][SHIELDPASS] == 0) revert Initialized();

    // TODO implement pricing
    // uint256 _price = this.price(name);
    // require(msg.value >= _price, "Not enough Matic paid");

    unchecked {
      for (uint256 i = 0; i < memberCount; i++) {
        string memory finalSvg = string(
          abi.encodePacked(svgPartOne, i, svgPartTwo)
        );
        //	uint256 newRecordId = i;

        // console.log('Registering %s as number %s', members[i], i);

        string memory json = Base64.encode(
          bytes(
            string(
              abi.encodePacked(
                '{"name": "',
                groupName,
                '", "description": "Group Description", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '"}'
              )
            )
          )
        );

        string memory finalTokenUri = string(
          abi.encodePacked("data:application/json;base64,", json)
        );

        // console.log('\n--------------------------------------------------------');
        // console.log('Final tokenURI', finalTokenUri);
        // console.log('--------------------------------------------------------\n');

        _mint(members[i], 1, 1, bytes(finalTokenUri));
        // _setTokenURI(newRecordId, finalTokenUri);
        // domains[name] = msg.sender;
      }
    }

    // transfer to existing group members

    // revoke pass
    // disabled for testing
  }

  // function callExtension(
  //     address extension,
  //     uint256 amount,
  //     bytes calldata extensionData
  // ) public payable virtual nonReentrant returns (bool mint, uint256 amountOut) {
  //     if (!extensions[extension] && !extensions[msg.sender]) revert NotExtension();

  //     address account;

  //     if (extensions[msg.sender]) {
  //         account = extension;
  //         amountOut = amount;
  //         mint = abi.decode(extensionData, (bool));
  //     } else {
  //         account = msg.sender;
  //         (mint, amountOut) = IKaliDAOextension(extension).callExtension{value: msg.value}(
  //             msg.sender,
  //             amount,
  //             extensionData
  //         );
  //     }

  //     if (mint) {
  //         if (amountOut != 0) _mint(account, amountOut);
  //     } else {
  //         if (amountOut != 0) _burn(account, amount);
  //     }
  // }
}