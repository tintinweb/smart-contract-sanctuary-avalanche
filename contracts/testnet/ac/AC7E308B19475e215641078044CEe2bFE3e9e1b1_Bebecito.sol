//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Utils.sol";

contract Bebecito is Ownable {
    enum Sex {
        UNDEFINED,
        MALE,
        FEMALE
    }

    struct NameBet {
        uint256 bet;
        string name;
    }

    struct SexBet {
        uint256 bet;
        Sex sex;
    }

    mapping(address => NameBet) private nameBets;
    address[] private addressesNameBet;

    mapping(address => SexBet) private sexBets;
    address[] private addressesSexBet;

    modifier maxNameLength(string memory name) {
        require(Utils.utfStringLength(name) <= 30, "Name is too length");
        _;
    }

    modifier nonEmptyString(string memory str) {
        require(
            keccak256(bytes(str)) != keccak256(bytes("")),
            "String is empty"
        );
        _;
    }

    modifier validSex(Sex sex) {
        require(sex != Sex.UNDEFINED, "Invalid Sex");
        _;
    }

    function hasAlreadyBetName() public view returns (bool) {
        return bytes(nameBets[msg.sender].name).length > 0;
    }

    function hasAlreadyBetSex() public view returns (bool) {
        return sexBets[msg.sender].sex != Sex.UNDEFINED;
    }

    function nameBet(string calldata name)
        external
        payable
        maxNameLength(name)
        nonEmptyString(name)
    {
        require(!hasAlreadyBetName(), "Already made a bet");

        NameBet memory bet = nameBets[msg.sender];
        bet.bet = msg.value;
        bet.name = name;

        addressesNameBet.push(msg.sender);
    }

    function sexBet(Sex sex) external payable validSex(sex) {
        require(!hasAlreadyBetSex(), "Already made a bet");

        SexBet memory bet = sexBets[msg.sender];
        bet.bet = msg.value;
        bet.sex = sex;

        addressesSexBet.push(msg.sender);
    }

    function getNameBet() public view returns (NameBet memory) {
        require(hasAlreadyBetName(), "No bet has been found");

        return nameBets[msg.sender];
    }

    function getSexBet() public view returns (SexBet memory) {
        require(hasAlreadyBetSex(), "No bet has been found");

        return sexBets[msg.sender];
    }

    function bets()
        external
        view
        onlyOwner
        returns (address[] memory, address[] memory)
    {
        return (addressesNameBet, addressesSexBet);
    }

    function betByAddress(address addr)
        external
        view
        onlyOwner
        returns (NameBet memory, SexBet memory)
    {
        return (nameBets[addr], sexBets[addr]);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
    function utfStringLength(string memory str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory stringRep = bytes(str);

        while (i < stringRep.length) {
            if (stringRep[i] >> 7 == 0) i += 1;
            else if (stringRep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (stringRep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (stringRep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
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