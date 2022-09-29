// SPDX-License-Identifier: MIT
// SpartanLabs Contracts (SBT)
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";

/**
 * @dev Implementation of Soul Bound Token (SBT)
 * Following Vitalik's co-authored whitepaper at: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4105763
 *
 * Contract provides a basic Soul Bound Token mechanism, where address can mint SBT with their private data.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 */
contract BasicSBT is Ownable {
    // Name for the SBT
    string public _name;

    // Symbol for the SBT
    string public _symbol;

    // Total count of SBT
    uint256 public _totalSBT; 

    // Mapping between address and the soul
    mapping(address => Soul) private souls;

    /**
     * @dev Struct `Soul` contains the soulbound token information for a given address.
     * The fields within the struct can be be edited for the usecase of the SBT.
     *
     * The fields of `identity` and `uri` can be hashed for privacy.
     */
    struct Soul {
        string identity;
        string uri;
    }

    // Events
    event Mint(address _soul);
    event Burn(address _soul);
    event Update(address _soul);

    /**
     * @dev This modifier checks that the address passed in is not the zero address.
     */
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the SBT. 
     * The `totalSBT` is set to zero.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _totalSBT = 0;
    }

    /**
     * @dev Mints `SBT` and transfers it to `_soul`.
     *
     * Emits a {Mint} event.
     */
    function mint(address _soul, Soul memory _soulData)
        external
        virtual
        onlyOwner
        validAddress(_soul)
    {
        require(!hasSoul(_soul), "Soul already exists");
        souls[_soul] = _soulData;
        _totalSBT++;
        emit Mint(_soul);
    }

    /**
     * @dev Destroys SBT for a given address.
     *
     * Requirements:
     * Only the owner of the SBT can destroy it.
     * Emits a {Burn} event.
     *
     * However, projects can have it such that users can propose changes for the contract owner to update.
     */
    function burn(address _soul) external virtual onlyOwner validAddress(_soul) {
        require(hasSoul(_soul), "Soul does not exists");
        delete souls[_soul];
        _totalSBT--;
        emit Burn(_soul);
    }

    /**
     * @dev Updates the mapping of address to attribute.
     * Only the owner address is able to update the information.
     *
     * However, projects can have it such that users can propose changes for the contract owner to update.
     */
    function updateSBT(address _soul, Soul memory _soulData)
        public
        onlyOwner
        validAddress(_soul)
        returns (bool)
    {
        require(hasSoul(_soul), "Soul does not exist");
        souls[_soul] = _soulData;
        emit Update(_soul);
        return true;
    }

    /**
     * @dev Returns the soul data of `identity, uri` for the given address
     */
    function getSBTData(address _soul)
        public
        view
        virtual
        validAddress(_soul)
        returns (string memory, string memory)
    {
        return (souls[_soul].identity, souls[_soul].uri);
    }

    /**
     * @dev Validates if the _soul is associated with the valid data in the corresponding address.
     * By checking if the `_soulData` given in parameter is the same as the data in the struct of mapping.
     * 
     * Projects can consider implementing their own offchain verification mechanism as well.
     */
    function validateAttribute(address _soul, Soul memory _soulData)
        public
        view
        virtual
        returns (bool)
    {
        require(hasSoul(_soul), "Soul does not exist");
        (string memory _identity, string memory _uri) = getSBTData(_soul);

        return
            compareString(_soulData.identity, _identity) &&
            compareString(_soulData.uri, _uri);
    }

    /**
     * @dev Gets the total count of SBT.
     */
    function totalSBT() public view virtual returns (uint256) {
        return _totalSBT;
    }

    /**
     * @dev Returns if two strings are equalx 
     */
    function compareString(string memory a, string memory b)
        internal
        pure
        virtual
        returns (bool)
    {
        return compareMemory(bytes(a), bytes(b));
    }

    /**
     * @dev Returns if two memory arrays are equal
     */
    function compareMemory(bytes memory a, bytes memory b)
        internal
        pure
        virtual
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /**
     * @dev Returns whether SBT exists for a given address.
     *
     * SBT start existing when they are minted (`mint`),
     * and stop existing when they are burned (`burn`).
     */
    function hasSoul(address _soul)
        public
        view
        virtual
        validAddress(_soul)
        returns (bool)
    {
        (string memory _identity, string memory _uri) = getSBTData(_soul);
        return bytes(_identity).length > 0 && bytes(_uri).length > 0;
    }

    /**
     * @dev Returns the name of SBT.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol ticker of SBT.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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