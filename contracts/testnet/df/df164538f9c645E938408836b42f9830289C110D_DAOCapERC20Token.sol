/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-30
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

interface ITWAPOracle {
    function uniV2CompPairAddressForLastEpochUpdateBlockTimstamp(address)
        external
        returns (uint32);

    function priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp(
        address tokenToPrice_,
        address tokenForPriceComparison_,
        uint256 epochPeriod_
    ) external returns (uint32);

    function pricedTokenForPricingTokenForEpochPeriodForPrice(
        address,
        address,
        uint256
    ) external returns (uint256);

    function pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice(
        address,
        address,
        uint256
    ) external returns (uint256);

    function updateTWAP(
        address uniV2CompatPairAddressToUpdate_,
        uint256 eopchPeriodToUpdate_
    ) external returns (bool);
}

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    function _getValues(Set storage set_)
        private
        view
        returns (bytes32[] storage)
    {
        return set_._values;
    }

    function _insert(
        Set storage set_,
        uint256 index_,
        bytes32 valueToInsert_
    ) private returns (bool) {
        require(set_._values.length > index_);
        require(
            !_contains(set_, valueToInsert_),
            "Remove value you wish to insert if you wish to reorder array."
        );
        bytes32 existingValue_ = _at(set_, index_);
        set_._values[index_] = valueToInsert_;
        return _add(set_, existingValue_);
    }

    struct Bytes4Set {
        Set _inner;
    }

    function add(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes4Set storage set, bytes4 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes4Set storage set, bytes4 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes4Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes4Set storage set, uint256 index)
        internal
        view
        returns (bytes4)
    {
        return bytes4(_at(set._inner, index));
    }

    function getValues(Bytes4Set storage set_)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes4[] memory bytes4Array_;
        for (
            uint256 iteration_ = 0;
            _length(set_._inner) > iteration_;
            iteration_++
        ) {
            bytes4Array_[iteration_] = bytes4(_at(set_._inner, iteration_));
        }
        return bytes4Array_;
    }

    function insert(
        Bytes4Set storage set_,
        uint256 index_,
        bytes4 valueToInsert_
    ) internal returns (bool) {
        return _insert(set_._inner, index_, valueToInsert_);
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function getValues(Bytes32Set storage set_)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes4[] memory bytes4Array_;

        for (
            uint256 iteration_ = 0;
            _length(set_._inner) >= iteration_;
            iteration_++
        ) {
            bytes4Array_[iteration_] = bytes4(at(set_, iteration_));
        }

        return bytes4Array_;
    }

    function insert(
        Bytes32Set storage set_,
        uint256 index_,
        bytes32 valueToInsert_
    ) internal returns (bool) {
        return _insert(set_._inner, index_, valueToInsert_);
    }

    // AddressSet
    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function getValues(AddressSet storage set_)
        internal
        view
        returns (address[] memory)
    {
        address[] memory addressArray;

        for (
            uint256 iteration_ = 0;
            _length(set_._inner) >= iteration_;
            iteration_++
        ) {
            addressArray[iteration_] = at(set_, iteration_);
        }

        return addressArray;
    }

    function insert(
        AddressSet storage set_,
        uint256 index_,
        address valueToInsert_
    ) internal returns (bool) {
        return
            _insert(
                set_._inner,
                index_,
                bytes32(uint256(uint160(valueToInsert_)))
            );
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    struct UInt256Set {
        Set _inner;
    }

    function add(UInt256Set storage set, uint256 value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(value));
    }

    function remove(UInt256Set storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UInt256Set storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UInt256Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UInt256Set storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_)
        internal
        pure
        returns (uint256 percentAmount_)
    {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_)
        internal
        pure
        returns (uint256 result_)
    {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_)
        internal
        pure
        returns (uint256 percent_)
    {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return mul(multiplier_, supply_);
    }
}

// All these standards present in ERC777
abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
        keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, amount_);
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(this), account_, amount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC2612Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 _hash = keccak256(
            abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(_hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ZeroSwapPermit: Invalid signature"
        );

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

interface IOwnable {
    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

contract VaultOwned is Ownable {
    address internal _vault;

    function setVault(address vault_) external onlyOwner returns (bool) {
        _vault = vault_;

        return true;
    }

    function vault() public view returns (address) {
        return _vault;
    }

    modifier onlyVault() {
        require(_vault == msg.sender, "VaultOwned: caller is not the Vault");
        _;
    }
}

contract TWAPOracleUpdater is ERC20Permit, VaultOwned {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TWAPOracleChanged(
        address indexed previousTWAPOracle,
        address indexed newTWAPOracle
    );
    event TWAPEpochChanged(
        uint256 previousTWAPEpochPeriod,
        uint256 newTWAPEpochPeriod
    );
    event TWAPSourceAdded(address indexed newTWAPSource);
    event TWAPSourceRemoved(address indexed removedTWAPSource);

    EnumerableSet.AddressSet private _dexPoolsTWAPSources;

    ITWAPOracle public twapOracle;

    uint256 public twapEpochPeriod;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {}

    function changeTWAPOracle(address newTWAPOracle_) external onlyOwner {
        emit TWAPOracleChanged(address(twapOracle), newTWAPOracle_);
        twapOracle = ITWAPOracle(newTWAPOracle_);
    }

    function changeTWAPEpochPeriod(uint256 newTWAPEpochPeriod_)
        external
        onlyOwner
    {
        require(
            newTWAPEpochPeriod_ > 0,
            "TWAPOracleUpdater: TWAP Epoch period must be greater than 0."
        );
        emit TWAPEpochChanged(twapEpochPeriod, newTWAPEpochPeriod_);
        twapEpochPeriod = newTWAPEpochPeriod_;
    }

    function addTWAPSource(address newTWAPSourceDexPool_) external onlyOwner {
        require(
            _dexPoolsTWAPSources.add(newTWAPSourceDexPool_),
            "DAOCapERC20TOken: TWAP Source already stored."
        );
        emit TWAPSourceAdded(newTWAPSourceDexPool_);
    }

    function removeTWAPSource(address twapSourceToRemove_) external onlyOwner {
        require(
            _dexPoolsTWAPSources.remove(twapSourceToRemove_),
            "DAOCapERC20TOken: TWAP source not present."
        );
        emit TWAPSourceRemoved(twapSourceToRemove_);
    }

    function _uodateTWAPOracle(
        address dexPoolToUpdateFrom_,
        uint256 twapEpochPeriodToUpdate_
    ) internal {
        if (_dexPoolsTWAPSources.contains(dexPoolToUpdateFrom_)) {
            twapOracle.updateTWAP(
                dexPoolToUpdateFrom_,
                twapEpochPeriodToUpdate_
            );
        }
    }

    function _beforeTokenTransfer(address from_, address to_) internal virtual {
        if (_dexPoolsTWAPSources.contains(from_)) {
            _uodateTWAPOracle(from_, twapEpochPeriod);
        } else {
            if (_dexPoolsTWAPSources.contains(to_)) {
                _uodateTWAPOracle(to_, twapEpochPeriod);
            }
        }
    }
}

contract Divine is TWAPOracleUpdater {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) TWAPOracleUpdater(name_, symbol_, decimals_) {}
}

contract DAOCapERC20Token is Divine {
    using SafeMath for uint256;

    constructor() Divine("DAOCap", "DCAP", 9) {}

    function mint(address account_, uint256 amount_) external onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}