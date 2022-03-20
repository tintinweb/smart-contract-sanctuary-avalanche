// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./helpers/ReentrancyGuard.sol";

contract DAO is ReentrancyGuard {
    struct CompanyInfo {
        uint256 initializedAt;
        uint256 companyId;
        uint256 proposalCreatorTokenRate;
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
    address private admin ;
    uint256 index = 1;
    uint256 constant CONSTANT_TOKEN_AMOUNT = 10**18;
    mapping(uint256 => CompanyInfo) public companyDescription; // start from 1
    mapping(address => mapping(uint256 => bool)) public isEmployee; // checks for employee of a spesific company
    mapping(uint256 => mapping(address => uint256)) public eveTokenOfCompany; // checks for an employee evetoken for the company
    mapping(uint256 => uint256) public proposalsCreated; // proposals created for a company
    mapping(uint256 => uint256) public onGoingProposals; // proposals ongoing for a company
    mapping(address => ProposalInfo[]) public allProposals; // allproposals of an employee
    uint256 companyRegistered; // to keep track of all registered companies
    constructor() {
      admin = msg.sender;
    }

    function setProposalCreatorTokenRate(uint256 _proposalCreatorTokenRate, uint256 _companyIndex) external {
       require(msg.sender == companyDescription[_companyIndex].owner, "!owner");
       companyDescription[_companyIndex].proposalCreatorTokenRate = _proposalCreatorTokenRate; // 10000/10000 is 1
    }

    function signCompany(string memory _name) external {
        // modifier here
        require(companyDescription[index].companyId == 0); // not initialized before

        companyDescription[index] = CompanyInfo({
            initializedAt: block.timestamp,
            companyId: index,
            proposalCreatorTokenRate: 1500,
            owner: msg.sender,
            companyName: _name,
            active: true
        });
        index++;
        companyRegistered++;
    }

    function signEmployee(uint256 _companyIndex, address _employee) external {
        require(
            companyDescription[_companyIndex].owner == msg.sender,
            "only authorized"
        );
        require(
            isEmployee[_employee][_companyIndex] == false,
            "already employee"
        );
        require(_employee != address(0));
        isEmployee[_employee][_companyIndex] = true;
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

    function createProposalFromEmployee(
        uint256 _companyIndex,
        uint256 _deadLine,
        uint8 _inputTargets
    ) external {
        require(isEmployee[msg.sender][_companyIndex] == true, "!employee");
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
    ) external nonReentrant {
        require(isEmployee[msg.sender][_companyIndex] == true, "!employee");
        require(
            allProposals[_proposalCreator][_proposalIndex].active == true,
            "!deadLine"
        );
        require(block.timestamp <= allProposals[_proposalCreator][_proposalIndex].deadLine);
        allProposals[_proposalCreator][_proposalIndex].inputTargets[_input]++;
        allProposals[_proposalCreator][_proposalIndex].totalVoted += CONSTANT_TOKEN_AMOUNT;
        eveTokenOfCompany[_companyIndex][msg.sender] += CONSTANT_TOKEN_AMOUNT;
    }
    function finishEmployeeProposal(
        uint256 _companyIndex,
        address _proposalCreator,
        uint256 _proposalIndex
    ) external {
      require(
          allProposals[_proposalCreator][_proposalIndex].active == true,
          "!finishedAlready"
      );
        require(allProposals[_proposalCreator][_proposalIndex].creator == msg.sender || msg.sender == admin, "!onlyCreator");
        require(block.timestamp >= allProposals[_proposalCreator][_proposalIndex].deadLine);
        allProposals[_proposalCreator][_proposalIndex].active == false;
        onGoingProposals[_companyIndex] --;
        eveTokenOfCompany[_companyIndex][msg.sender] = (allProposals[_proposalCreator][_proposalIndex].totalVoted * (companyDescription[_companyIndex].proposalCreatorTokenRate)/10000) + CONSTANT_TOKEN_AMOUNT;
    }
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