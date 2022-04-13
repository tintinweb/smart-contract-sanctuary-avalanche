/**
 *Submitted for verification at snowtrace.io on 2022-04-13
*/

// AvacashFinance_AVAX.sol Flattened
// SPDX-License-Identifier: MIT
/*
Avacash.Finance: Privacy-focused Investments in Avalanche
Visit https://avacash.finance
Check Audits in https://docs.avacash.finance/

V.1.1


█████╗ ██╗   ██╗ █████╗  ██████╗ █████╗ ███████╗██╗  ██╗
██╔══██╗██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║
███████║██║   ██║███████║██║     ███████║███████╗███████║
██╔══██║╚██╗ ██╔╝██╔══██║██║     ██╔══██║╚════██║██╔══██║
██║  ██║ ╚████╔╝ ██║  ██║╚██████╗██║  ██║███████║██║  ██║
╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
█████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗
██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝
██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝

*/
// File: contracts/MerkleTreeWithHistory.sol

// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */


pragma solidity ^0.7.0;

interface IHasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) external pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  IHasher public immutable hasher;
  uint32 public immutable levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code

  // filledSubtrees, zeros, and roots could be bytes32[size], but using mappings makes it cheaper because
  // it removes index range check on every interaction
  mapping(uint256 => bytes32) public filledSubtrees;
  mapping(uint256 => bytes32) public zeros;
  mapping(uint256 => bytes32) public roots;
  uint32 public constant ROOT_HISTORY_SIZE = 30;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;

  constructor(uint32 _levels, IHasher _hasher) {
    require(_levels > 0, "_levels should be greater than zero");
    require(_levels < 32, "_levels should be less than 32");
    levels = _levels;
    hasher = _hasher;

    bytes32 currentZero = bytes32(ZERO_VALUE);
    for (uint32 i = 0; i < _levels; i++) {
      zeros[i] = currentZero;
      filledSubtrees[i] = currentZero;
      currentZero = hashLeftRight(_hasher, currentZero, currentZero);
    }

    roots[0] = currentZero;
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(
    IHasher _hasher,
    bytes32 _left,
    bytes32 _right
  ) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    (R, C) = _hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = _hasher.MiMCSponge(R, C);
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns (uint32 index) {
    uint32 _nextIndex = nextIndex;
    require(_nextIndex != uint32(2)**levels, "Merkle tree is full. No more leaves can be added");
    uint32 currentIndex = _nextIndex;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros[i];
        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }
      currentLevelHash = hashLeftRight(hasher, left, right);
      currentIndex /= 2;
    }

    uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    currentRootIndex = newRootIndex;
    roots[newRootIndex] = currentLevelHash;
    nextIndex = _nextIndex + 1;
    return _nextIndex;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns (bool) {
    if (_root == 0) {
      return false;
    }
    uint32 _currentRootIndex = currentRootIndex;
    uint32 i = _currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != _currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns (bytes32) {
    return roots[currentRootIndex];
  }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Tornado.sol



// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */


pragma solidity ^0.7.0;


interface IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns (bool);
}

abstract contract Tornado is MerkleTreeWithHistory, ReentrancyGuard {
  IVerifier public immutable verifier;
  uint256 public immutable denomination;

  mapping(bytes32 => bool) public nullifierHashes;
  // we store all commitments just to prevent accidental deposits with the same commitment
  mapping(bytes32 => bool) public commitments;

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _hasher the address of MiMC hash contract
    @param _denomination transfer amount for each deposit
    @param _merkleTreeHeight the height of deposits' Merkle Tree
  */
  constructor(
    IVerifier _verifier,
    IHasher _hasher,
    uint256 _denomination,
    uint32 _merkleTreeHeight
  ) MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
    require(_denomination > 0, "denomination should be greater than 0");
    verifier = _verifier;
    denomination = _denomination;
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    _processDeposit();

    emit Deposit(_commitment, insertedIndex, block.timestamp);
  }

  /** @dev this function is defined in a child contract */
  function _processDeposit() internal virtual;

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) external payable nonReentrant {
    require(_fee <= denomination, "Fee exceeds transfer value");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(
      verifier.verifyProof(
        _proof,
        [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _fee, _refund]
      ),
      "Invalid withdraw proof"
    );

    nullifierHashes[_nullifierHash] = true;
    _processWithdraw(_recipient, _relayer, _fee, _refund);
    emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
  }

  /** @dev this function is defined in a child contract */
  function _processWithdraw(
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) internal virtual;

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns (bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns (bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for (uint256 i = 0; i < _nullifierHashes.length; i++) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }
}

// File: contracts/libraries/SafeMathUni.sol

// Extracted from https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/libraries/SafeMath.sol
//https://ethereumdev.io/using-safe-math-library-to-prevent-from-overflows/
// Using GPL-3.0 License

pragma solidity ^0.7.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUni {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
        }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

// File: contracts/AvacashFlashLoanProvider.sol

// https://avacash.finance
/*
█████╗ ██╗   ██╗ █████╗  ██████╗ █████╗ ███████╗██╗  ██╗
██╔══██╗██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║
███████║██║   ██║███████║██║     ███████║███████╗███████║
██╔══██║╚██╗ ██╔╝██╔══██║██║     ██╔══██║╚════██║██╔══██║
██║  ██║ ╚████╔╝ ██║  ██║╚██████╗██║  ██║███████║██║  ██║
╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
█████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗
██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝
██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝

*/




pragma solidity ^0.7.0;

interface FlashLoanBorrower {
  function avacashFlashLoanCall(bytes calldata _data) external payable returns (bool);
  }


/**
  @title  A contact that holds AVAX and provides flash loans in a safe way
  @author avacash.finance
*/
contract AvacashFlashLoanProvider is ReentrancyGuard {
  using SafeMathUni for uint;

  address public flashLoanFeeReceiver;
  uint public flashLoanFee = 3;

  event FlashLoan(address _recipient, uint256 _amount, bytes _data);
  event FlashLoanFeeChanged(uint _newFlashLoanFee);
  event FlashLoanFeeReceiverChanged(address _newFlashLoanFeeReceiver);

  /**
    @dev The constructor
    @param _flashLoanFeeReceiver the initial address that will receive the fees for the usage of flash loans
  */
  constructor(address _flashLoanFeeReceiver)  public {
    require(_flashLoanFeeReceiver!=address(0), "feeReceiver should not be the Zero Address");
    flashLoanFeeReceiver = _flashLoanFeeReceiver;
  }

  /**
    @dev Function that changes the flashLoanFeeReceiver
    @notice Can only be called by the current flashLoanFeeReceiver
    @param _newFeeReceiver the new address that will receive the fees for the usage of flash loans
  */
  function changeFeeReceiver(address _newFeeReceiver) external nonReentrant returns (bool){
    require(msg.sender == flashLoanFeeReceiver, "Only current flashLoanFeeReceiver can change this value.");
    require(_newFeeReceiver!= address(0), "New fee receiver should not be address 0");
    flashLoanFeeReceiver = _newFeeReceiver;
    emit FlashLoanFeeReceiverChanged(flashLoanFeeReceiver);
    return true;
  }

  /**
    @dev Function that changes the flashLoanFeeReceiver
    @notice Can only be called by the current flashLoanFeeReceiver
    @param _newFlashLoanFee the new address that will receive the fees for the usage of flash loans
  */
  function changeFlashLoanFee(uint _newFlashLoanFee) external nonReentrant returns (bool){
    require(msg.sender == flashLoanFeeReceiver, "Only current flashLoanFeeReceiver can change this value.");
    flashLoanFee = _newFlashLoanFee;
    emit FlashLoanFeeChanged(flashLoanFee);
    return true;
  }

  /**
    @dev Function that verifies if the functions was called by a contract
    @param _addr address that needs to be verified
    @return bool : true if _addr is a contract, false if not
  */
  function isContract(address _addr) private view returns (bool){
  uint32 size;
  assembly {
    size := extcodesize(_addr)
  }
  return (size > 0);
}

  /**
    @dev Function to ask AVAX as a flashloan
    @param _recipient address of the flashloan recipient, that needs to implement FlashLoanBorrower interface
    @param _amount in AVAX of the flashloan
    @param _data any data that needs to be sent to the FlashLoanBorrower
    @return bool: true if successfull
  */

  function flashLoan( address _recipient,
                      uint256 _amount,
                      bytes calldata _data) external nonReentrant returns (bool){

    // 0. Check correct call.
    require(_amount > 0, "flashLoan(): Please select an positive flashloan _amount.");
    require(isContract(_recipient), "flashLoan(): _recipient should be a contract.");

    // 1. Check this contact's balance
    uint256  _initialBalance = address(this).balance;
    require(_initialBalance >= _amount, "flashLoan(): Not enough funds for the flashloan.");

    FlashLoanBorrower _borrower = FlashLoanBorrower(_recipient);

    // 2. Lend the money:
    (bool success1 ) = _borrower.avacashFlashLoanCall{value: _amount}(_data);
    require(success1, "flashLoan(): flashloan to _recipient did not go through.");

    // 3. Calculate _feeAdjusted
    // fees are in deci-bps, i.e. 1/10th bps https://www.investopedia.com/terms/b/basispoint.asp
    // if flashLoanFee = 3, means 0.003%

    uint256 _feeAdjusted = _amount.mul(flashLoanFee);

    require(address(this).balance.mul(100000) >= _initialBalance.mul(100000).add(_feeAdjusted) , "flashLoan(): Not enough fee paid");

    // 4. Send fee to feeReceiver.
    if (_feeAdjusted > 0 ) {
      (bool success2, ) = flashLoanFeeReceiver.call{value: address(this).balance.sub(_initialBalance)}("");
      require(success2, "flashLoan(): payment to feeReceiver  did not go through");
    }

    // 5. Check the final balance.
    require(address(this).balance == _initialBalance, "flashLoan(): Final balance should be equal to the initial balance.");

    emit FlashLoan(_recipient, _amount,_data);
    return true;
  }

  /**
    @dev Payable function to receive back the flashloan
    @notice Function that needs to be called by the FlashLoanBorrower in order to give back the flashloan + fees
    @return bool: true if successfull
  */
  function payBack() external payable returns (bool){
    return true;
  }

}

// File: contracts/AvacashFinance_AVAX.sol

// https://avacash.finance
/*
█████╗ ██╗   ██╗ █████╗  ██████╗ █████╗ ███████╗██╗  ██╗
██╔══██╗██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║
███████║██║   ██║███████║██║     ███████║███████╗███████║
██╔══██║╚██╗ ██╔╝██╔══██║██║     ██╔══██║╚════██║██╔══██║
██║  ██║ ╚████╔╝ ██║  ██║╚██████╗██║  ██║███████║██║  ██║
╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝

███████╗██╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
██╔════╝██║████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
█████╗  ██║██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗
██╔══╝  ██║██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝
██║     ██║██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝

*/




pragma solidity ^0.7.0;


contract AvacashFinance_AVAX is Tornado, AvacashFlashLoanProvider {

  constructor(
    IVerifier _verifier,
    IHasher _hasher,
    uint256 _denomination,
    uint32 _merkleTreeHeight,
    address _flashLoanFeeReceiver
  ) Tornado(_verifier, _hasher, _denomination, _merkleTreeHeight)
    AvacashFlashLoanProvider(_flashLoanFeeReceiver) public {}


    function _processDeposit() internal override {
      require(msg.value == denomination, "Please send `mixDenomination` ETH along with transaction");
    }

    function _processWithdraw(
      address payable _recipient,
      address payable _relayer,
      uint256 _fee,
      uint256 _refund
    ) internal override {
      // sanity checks
      require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
      require(_refund == 0, "Refund value is supposed to be zero for ETH instance");

      (bool success, ) = _recipient.call{ value: denomination - _fee }("");
      require(success, "payment to _recipient did not go thru");
      if (_fee > 0) {
        (success, ) = _relayer.call{ value: _fee }("");
        require(success, "payment to _relayer did not go thru");
      }
    }
  }