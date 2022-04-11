/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library BoringERC20 {

    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

    function sqrt(uint256 n) internal pure returns (uint256) { unchecked {
        if (n > 0) {
            uint256 x = n / 2 + 1;
            uint256 y = (x + n / x) / 2;
            while (x > y) {
                x = y;
                y = (x + n / x) / 2;
            }
            return x;
        }
        return 0;
    } }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract ArcaneSigils is ERC20("Arcane Sigils", "SIGIL"), Ownable {
    using SafeMath for uint256;

    /// @notice Total number of tokens
    uint256 public maxSupply = 100_000_000e18; // 100 Million SIGIL's

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(totalSupply().add(_amount) <= maxSupply, "SIGIL::mint: cannot exceed max supply");
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from Trader Joe code:
    // https://github.com/traderjoe-xyz/joe-core/blob/main/contracts/JoeToken.sol
    // Which is copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );

        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SIGIL::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SIGIL::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "SIGIL::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        require(blockNumber < block.number, "SIGIL::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying JOEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "SIGIL::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

interface IArcaneDispenser
{
    function onSigilReward(address user, uint256 newLpAmount) external;

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20);
}
// Forked, merged and modified (slightly) from Trader Joe's joe-core repository found here
// https://github.com/traderjoe-xyz/joe-core/tree/main/contracts
// This is a merge of MasterChefV2 and MasterChefV3 contracts, it gives out a constant
// number of SIGIL per block. It holds the minting rights for Arcane Sigil's, the GOTH
// Token Networks governance token.
contract ArcaneWeaver is BoringOwnable, ReentrancyGuard
{
    // USINGS //
    using SafeMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for ArcaneSigils;
    using EnumerableSet for EnumerableSet.AddressSet;

    // STRUCTS //
    struct Weaver {
        uint256 amount;
        uint256 accrued;
    }

    struct ArcaneFarm {
        IERC20 lpToken;
        uint256 accSigilPerShare;
        uint256 lastRewardTime;
        uint256 allocationPoints;
        IArcaneDispenser dispenser;
    }

    // STATE VARIABLES //
    ArcaneSigils public sigil;
    ArcaneFarm[] public arcaneFarms;
    EnumerableSet.AddressSet private lpTokens;
    mapping(uint256 => mapping(address => Weaver)) public weavers;
    uint256 public totalAllocationPoints;
    uint256 private constant ACC_TOKEN_PRECISION = 1e18;

    address public devAddr;
    address public treasuryAddr;
    address public investorAddr;
    uint256 public sigilPerSec;
    uint256 public devPercent;
    uint256 public treasuryPercent;
    uint256 public investorPercent; 

    uint256 public startTimestamp;

    // EVENTS //
    event FarmAdd(uint256 indexed farmId, uint256 allocation, IERC20 indexed lpToken, IArcaneDispenser indexed dispenser);
    event SetFarm(uint256 indexed farmId, uint256 allocation, IArcaneDispenser indexed dispenser, bool overwrite);
    event UpdateFarm(uint256 indexed farmId, uint256 lastRewardTime, uint256 lpSupply, uint256 accSigilPerShare);
    event Collection(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event Deposit(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event Withdraw(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event EmergencyWithdraw(address indexed weaver, uint256 indexed farmId, uint256 amount);
    event UpdateEmissionRate(address indexed account, uint256 sigilPerSec);
    event SetDevAddress(address indexed account, address newAddress);

    constructor
    (ArcaneSigils _sigil, address _devAddr, address _treasuryAddr, address _investorAddr, uint256 _sigilPerSec, 
    uint256 _startTime, uint256 _devPercent, uint256 _treasuryPercent, uint256 _investorPercent)
    {
        require(0 <= _devPercent && _devPercent <= 1000, "constructor: invalid dev percent value");
        require(0 <= _treasuryPercent && _treasuryPercent <= 1000, "constructor: invalid treasury percent value");
        require(0 <= _investorPercent && _investorPercent <= 1000, "constructor: invalid investor percent value");
        require(_devPercent + _treasuryPercent + _investorPercent <= 1000, "constructor: total percent over max");

        sigil = _sigil;
        devAddr = _devAddr;
        treasuryAddr = _treasuryAddr;
        investorAddr = _investorAddr;
        sigilPerSec = _sigilPerSec;
        startTimestamp = _startTime;
        devPercent = _devPercent;
        treasuryPercent = _treasuryPercent;
        investorPercent = _investorPercent;
        totalAllocationPoints = 0;
    }

    function farmLength () external view returns (uint256 farms)
    {
        farms = arcaneFarms.length;
    }

    function addFarm (uint256 allocation, IERC20 lpToken, IArcaneDispenser dispenser) external onlyOwner
    {
        require(!lpTokens.contains(address(lpToken)), "addFarm: farm has already been added.");
        lpToken.balanceOf(address(this));

        if (address(dispenser) != address(0)) 
        {
            dispenser.onSigilReward(address(0), 0);
        }

        uint256 lastRewardTime = block.timestamp;
        totalAllocationPoints = totalAllocationPoints.add(allocation);

        arcaneFarms.push(
            ArcaneFarm(
                {
                    lpToken: lpToken,
                    allocationPoints: allocation,
                    lastRewardTime: lastRewardTime,
                    accSigilPerShare: 0,
                    dispenser: dispenser
                }
            )
        );

        lpTokens.add(address(lpToken));
        emit FarmAdd(arcaneFarms.length.sub(1), allocation, lpToken, dispenser);
    }

    function setFarm (uint256 farmId, uint256 allocation, IArcaneDispenser dispenser, bool overwrite) external onlyOwner
    {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        totalAllocationPoints = totalAllocationPoints.sub(arcaneFarms[farmId].allocationPoints).add(allocation);
        farm.allocationPoints = allocation;

        if (overwrite)
        {
            dispenser.onSigilReward(address(0), 0);
            farm.dispenser = dispenser;
        }

        arcaneFarms[farmId] = farm;
        emit SetFarm(farmId, allocation, overwrite ? dispenser : farm.dispenser, overwrite);
    }

    function pendingTokens (uint256 farmId, address weaverAddress) external view 
    returns (uint256 pendingSigil, address bonusTokenAddress, string memory bonusTokenSymbol, uint256 pendingBonusToken)
    {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][weaverAddress];
        uint256 accSigilPerShare = farm.accSigilPerShare;
        uint256 lpSupply = farm.lpToken.balanceOf(address(this));

        if (block.timestamp > farm.lastRewardTime && lpSupply != 0)
        {
            uint256 secondsElapsed = block.timestamp.sub(farm.lastRewardTime);
            uint256 sigilReward = secondsElapsed.mul(sigilPerSec).mul(farm.allocationPoints).div(totalAllocationPoints);
            accSigilPerShare = accSigilPerShare.add(sigilReward.mul(ACC_TOKEN_PRECISION).div(lpSupply));
        }

        pendingSigil = weaver.amount.mul(accSigilPerShare).div(ACC_TOKEN_PRECISION).sub(weaver.accrued);

        if (address(farm.dispenser) != address(0))
        {
            bonusTokenAddress = address(farm.dispenser.rewardToken());
            bonusTokenSymbol = IERC20(farm.dispenser.rewardToken()).safeSymbol();
            pendingBonusToken = farm.dispenser.pendingTokens(weaverAddress);
        }
    }

    function massUpdateFarms (uint256[] memory farmIds) public
    {
        uint256 length = farmIds.length;
        for (uint256 i = 0; i < length; ++i)
        {
            updateFarm(farmIds[i]);
        }
    }

    function updateFarm (uint256 farmId) public 
    {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        if (block.timestamp > farm.lastRewardTime)
        {
            uint256 lpSupply = farm.lpToken.balanceOf(address(this));
            if (lpSupply > 0)
            {
                uint256 secondsElapsed = block.timestamp.sub(farm.lastRewardTime);
                uint256 sigilReward = secondsElapsed.mul(sigilPerSec).mul(farm.allocationPoints).div(totalAllocationPoints);
                uint256 lpPercent = 1000 - devPercent - treasuryPercent - investorPercent;

                sigil.mint(devAddr, sigilReward.mul(devPercent).div(1000));
                sigil.mint(treasuryAddr, sigilReward.mul(treasuryPercent).div(1000));
                sigil.mint(investorAddr, sigilReward.mul(investorPercent).div(1000));
                sigil.mint(address(this), sigilReward.mul(lpPercent).div(1000));

                farm.accSigilPerShare = farm.accSigilPerShare.add((sigilReward.mul(lpPercent).div(1000).mul(ACC_TOKEN_PRECISION).div(lpSupply)));               
            }
            farm.lastRewardTime = block.timestamp;
            arcaneFarms[farmId] = farm;
            emit UpdateFarm(farmId, farm.lastRewardTime, lpSupply, farm.accSigilPerShare);
        }
    }

    function deposit (uint256 farmId, uint256 amount) external nonReentrant
    {
        updateFarm(farmId);

        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][msg.sender];

        if (weaver.amount > 0)
        {
            uint256 pending = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION).sub(weaver.accrued);
            sigil.safeTransfer(msg.sender, pending);
            emit Collection(msg.sender, farmId, pending);
        }

        uint256 balanceBefore = farm.lpToken.balanceOf(address(this));
        farm.lpToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountReceived = farm.lpToken.balanceOf(address(this)).sub(balanceBefore);

        weaver.amount = weaver.amount.add(amountReceived);
        weaver.accrued = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION);

        IArcaneDispenser dispenser = farm.dispenser;
        if (address(dispenser) != address(0))
        {
            dispenser.onSigilReward(msg.sender, weaver.amount);
        }

        emit Deposit(msg.sender, farmId, amountReceived);
    }

    function withdraw (uint256 farmId, uint256 amount) external nonReentrant
    {
        updateFarm(farmId);
        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][msg.sender];

        if (weaver.amount > 0)
        {
            uint256 pending = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION).sub(weaver.accrued);
            sigil.safeTransfer(msg.sender, pending);
            emit Collection(msg.sender, farmId, pending);
        }

        weaver.amount = weaver.amount.sub(amount);
        weaver.accrued = weaver.amount.mul(farm.accSigilPerShare).div(ACC_TOKEN_PRECISION);

        IArcaneDispenser dispenser = farm.dispenser;
        if (address(dispenser) != address(0))
        {
            dispenser.onSigilReward(msg.sender, weaver.amount);
        }

        farm.lpToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, farmId, amount);
    }

    function emergencyWithdraw(uint256 farmId) external nonReentrant {
        ArcaneFarm memory farm = arcaneFarms[farmId];
        Weaver storage weaver = weavers[farmId][msg.sender];
        uint256 amount = weaver.amount;
        weaver.amount = 0;
        weaver.accrued = 0;

        IArcaneDispenser dispenser = farm.dispenser;
        if (address(dispenser) != address(0)) {
            dispenser.onSigilReward(msg.sender, 0);
        }

        farm.lpToken.safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, farmId, amount);
    }

    function updateEmissionRate(uint256 _sigilPerSec) public onlyOwner 
    {
        uint256 count = arcaneFarms.length;
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++)
        {
            ids[i] = i;
        }

        massUpdateFarms(ids);
        sigilPerSec = _sigilPerSec;
        emit UpdateEmissionRate(msg.sender, _sigilPerSec);
    }

    function dev(address _devAddr) public 
    {
        require(msg.sender == devAddr, "dev: BE GONE!");
        devAddr = _devAddr;
        emit SetDevAddress(msg.sender, _devAddr);
    }

    function setDevPercent(uint256 _newDevPercent) public onlyOwner 
    {
        require(0 <= _newDevPercent && _newDevPercent <= 1000, "setDevPercent: invalid percent value");
        require(treasuryPercent + _newDevPercent + investorPercent <= 1000, "setDevPercent: total percent over max");
        devPercent = _newDevPercent;
    }

    function setTreasuryAddr(address _treasuryAddr) public 
    {
        require(msg.sender == treasuryAddr, "setTreasuryAddr: BE GONE!");
        treasuryAddr = _treasuryAddr;
    }

    function setTreasuryPercent(uint256 _newTreasuryPercent) public onlyOwner 
    {
        require(0 <= _newTreasuryPercent && _newTreasuryPercent <= 1000, "setTreasuryPercent: invalid percent value");
        require(
            devPercent + _newTreasuryPercent + investorPercent <= 1000,
            "setTreasuryPercent: total percent over max"
        );
        treasuryPercent = _newTreasuryPercent;
    }

    function setInvestorAddr(address _investorAddr) public 
    {
        require(msg.sender == investorAddr, "setInvestorAddr: BE GONE!");
        investorAddr = _investorAddr;
    }

    function setInvestorPercent(uint256 _newInvestorPercent) public onlyOwner 
    {
        require(0 <= _newInvestorPercent && _newInvestorPercent <= 1000, "setInvestorPercent: invalid percent value");
        require(
            devPercent + _newInvestorPercent + treasuryPercent <= 1000,
            "setInvestorPercent: total percent over max"
        );
        investorPercent = _newInvestorPercent;
    }
}