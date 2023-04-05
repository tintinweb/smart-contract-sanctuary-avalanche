// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {ICrowdFunding} from "./Interface.sol";
import {CrowdFundingEvents} from "./Events.sol";
import {CrowdFundingStorage} from "./Storage.sol";

contract CrowdFunding is CrowdFundingStorage, CrowdFundingEvents {
    constructor(uint256 _goal, uint256 _deadline, uint256 _minContribution) {
        goal = _goal;
        owner = msg.sender;
        deadline = _deadline;
        minContribution = _minContribution;
    }

    receive() external payable {
        contribute();
    }

    function contribute() public payable {
        require(deadline >= block.timestamp, "!time");
        require(msg.value >= minContribution, "!amount");

        if (contributors[msg.sender] == 0) noOfContributors++;

        raised += msg.value;
        contributors[msg.sender] += msg.value;

        emit Contribute(msg.sender, msg.value, raised, noOfContributors);
    }

    function refund() public {
        require(contributors[msg.sender] > 0, "!contributor");
        require(block.timestamp > deadline && raised < goal, "!req");

        uint _amount = contributors[msg.sender];
        contributors[msg.sender] = 0;
        payable(msg.sender).transfer(_amount);
    }

    function createSpendingReq(
        uint _amount,
        address payable _recipient,
        string memory _description
    ) external Owner {
        Request storage req = requests[countRequests];
        countRequests++;

        req.amount = _amount;
        req.recipient = _recipient;
        req.description = _description;

        emit NewRequest(
            (countRequests - 1),
            req.amount,
            req.recipient,
            req.description
        );
    }

    function voteSpendingReq(uint _reqIndex) external {
        require(_reqIndex < countRequests, "!index");
        require(contributors[msg.sender] > 0, "!contributor");

        Request storage req = requests[_reqIndex];

        require(!req.voters[msg.sender], "hasVoted");

        req.voters[msg.sender] = true;
        req.noOfVoters++;

        emit Voted(
            _reqIndex,
            msg.sender,
            req.amount,
            req.recipient,
            req.description,
            req.noOfVoters
        );
    }

    function spendReq(uint _reqIndex) external Owner {
        require(raised >= goal, "!goal");

        Request storage req = requests[_reqIndex];

        require(!req.completed, "paid");
        require(req.noOfVoters > (noOfContributors / 2), "!votes");

        req.completed = true;
        req.recipient.transfer(req.amount);

        emit SpentRequest(
            _reqIndex,
            req.completed,
            req.amount,
            req.recipient,
            req.description
        );
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier Owner() {
        require(msg.sender == owner, "!owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract CrowdFundingEvents {
    event Contribute(
        address _sender,
        uint _amount,
        uint _raised,
        uint _noOfContributors
    );

    event NewRequest(
        uint _index,
        uint _amount,
        address _recipient,
        string _description
    );

    event SpentRequest(
        uint _index,
        bool _completed,
        uint _amount,
        address _recipient,
        string _description
    );

    event Voted(
        uint _index,
        address _voter,
        uint _amount,
        address _recipient,
        string _description,
        uint _noOfVoters
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ICrowdFunding {
    struct Request {
        uint amount;
        bool completed;
        uint noOfVoters;
        string description;
        address payable recipient;
        mapping(address => bool) voters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {ICrowdFunding} from "./Interface.sol";

contract CrowdFundingStorage is ICrowdFunding {
    address public owner;

    uint public goal;
    uint public raised;
    uint public deadline;
    uint public countRequests;
    uint public minContribution;
    uint public noOfContributors;

    mapping(uint => Request) public requests;
    mapping(address => uint) public contributors;
}