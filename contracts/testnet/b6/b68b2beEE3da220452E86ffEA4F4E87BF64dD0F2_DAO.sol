// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract DAO is Ownable, ReentrancyGuard {

    struct EmployeeForm {
        string id;
        uint nonce;
    }
    struct CompanyInfo {
        uint256 initializedAt;
        uint256 companyId;
        address owner;
        string companyName;
        bool active;
    }
    struct ProposalInfo {
        uint256 initializedAt;
        uint256 deadLine;
        uint256 totalVoted;
        uint8[] inputTargets;
        address creator;
        bool active;
    }
    uint256 index = 1;
    mapping(uint256 => CompanyInfo) public companyDescription; // start from 1
    mapping(address => mapping(uint256 => bool)) public isEmployee; // checks for employee of a spesific company
    mapping(address => mapping(uint256 => bool)) public formerEmployee;
    mapping(uint256 => mapping(address => uint256)) public votedProposals; // checks for an employee votes for the companys polls
    mapping(uint256 => uint256) public proposalsCreated; // proposals created for a company
    mapping(uint256 => uint256) public onGoingProposals; // proposals ongoing for a company
    mapping(address => ProposalInfo[]) public allProposals; // allproposals of a company
    uint256 companyRegistered; // to keep track of all registered companies

    mapping(uint256 => mapping(bytes32 => address)) private approvedHashes;

    function setHashes(string memory _name, uint256 _secretNumber, uint256 _companyIndex) external {
      require(companyDescription[_companyIndex].owner == msg.sender, "only authorized");
        bytes32 hashedForm = _getMessageHash(_name, _secretNumber);
        approvedHashes[_companyIndex][hashedForm] = address(this);
    }

    function signCompany(string memory _name, address _companyRepresenter) external onlyOwner {
        require(companyDescription[index].companyId == 0); // not initialized before
        require(_companyRepresenter != address(0));

        companyDescription[index] = CompanyInfo({
            initializedAt: block.timestamp,
            companyId: index,
            owner: _companyRepresenter,
            companyName: _name,
            active: true
        });
        index++;
        companyRegistered++;
    }

    function signEmployee(uint256 _companyIndex, string memory _id, uint _nonce) external {
       bytes32 _hash = _getMessageHash(_id, _nonce);
       require(approvedHashes[_companyIndex][_hash] == address(this));
        require(
            isEmployee[msg.sender][_companyIndex] == false,
            "already employee"
        );
        require(msg.sender != address(0));
        isEmployee[msg.sender][_companyIndex] = true;
        approvedHashes[_companyIndex][_hash] == address(0);
    }

    function kickEmployee(uint256 _companyIndex, string memory _id, uint _nonce) external {
      require(companyDescription[_companyIndex].owner == msg.sender, "only authorized");
      bytes32 _hash = _getMessageHash(_id, _nonce);
      require(approvedHashes[_companyIndex][_hash] == address(0), "not an employee");

      address employee = approvedHashes[_companyIndex][_hash];
      approvedHashes[_companyIndex][_hash] = address(this);
      isEmployee[employee][_companyIndex] = false; // fire
      formerEmployee[employee][_companyIndex] = true;
    }

    function createProposalFromCompany(
        uint256 _companyIndex,
        uint256 _deadLine,
        uint8 _inputTargets
    ) external {
        require(companyDescription[_companyIndex].owner == msg.sender, "only authorized");
        require(block.timestamp < _deadLine, "!time");

        uint8[] memory array = new uint8[](_inputTargets);
        for (uint256 i; i < _inputTargets; i++) {
            array[i] = 0;
        }
        allProposals[msg.sender].push(
            ProposalInfo(block.timestamp, _deadLine, 0, array, msg.sender, true)
        );
        proposalsCreated[_companyIndex]++;
        onGoingProposals[_companyIndex]++;
    }

    function submitEmployeeVote(
        uint256 _companyIndex,
        address _proposalCreator,
        uint256 _proposalIndex,
        uint256 _input
    ) external  {
        require(isEmployee[msg.sender][_companyIndex] == true, "!employee");
        require(
            allProposals[_proposalCreator][_proposalIndex].active == true,
            "!deadLine"
        );
        require(block.timestamp <= allProposals[_proposalCreator][_proposalIndex].deadLine);
        allProposals[_proposalCreator][_proposalIndex].inputTargets[_input]++;
        allProposals[_proposalCreator][_proposalIndex].totalVoted++;
        votedProposals[_companyIndex][msg.sender]++;
    }


    function _getMessageHash(
        string memory _id,    // id number of the company of the employee
        uint _nonce           // random number that company will assign to employee
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_id, _nonce, address(this)));
    }

    // [{("A",1), ("B",2)}]

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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