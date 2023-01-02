/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-01
*/

// File: contracts/CrowdFunding.sol


pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 startAt;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        bool claimed;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public donateAmount;

    uint256 public numberOfCampaings = 0;

    function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _startAt, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaings];

        require(_startAt > block.timestamp, "The start time must be a date in the future");
        require(_deadline > _startAt,"End time is less than Start time");
        require(_deadline > block.timestamp, "The deadline must be a date in the future");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.startAt = _startAt;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.claimed = false;

        numberOfCampaings++;

        return numberOfCampaings -1 ;
    }

function cancel(uint _id) public {
    Campaign memory campaign = campaigns[_id];
    require(campaign.owner == msg.sender, "You did not create this Campaign");
    require(block.timestamp < campaign.startAt, "Campaign has already started");

    delete campaigns[_id];
    numberOfCampaings--;
}


    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];

        require(amount > 0, "You must pledge a positive amount");
        require(block.timestamp >= campaign.startAt, "Campaign has not Started yet");
        require(block.timestamp <= campaign.deadline, "Campaign has already ended");

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        donateAmount[_id][msg.sender] += amount;

        (bool sent,) = payable(address(this)).call{value: amount}("");

        if(sent) {
            campaign.amountCollected = campaign.amountCollected + amount;
        }
    }

    function claim(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner == msg.sender, "You did not create this Campaign");
        require(block.timestamp > campaign.deadline, "Campaign has not ended");
        require(campaign.amountCollected >= campaign.target, "Campaign did not succed");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;

       payable(msg.sender).transfer(campaign.amountCollected);
    }

    function refund(uint _id) public {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.deadline, "not ended");
        require(campaign.amountCollected < campaign.target, "You cannot Withdraw, Campaign has succeeded");

        uint bal = donateAmount[_id][msg.sender];
        payable(msg.sender).transfer(bal);
        donateAmount[_id][msg.sender] = 0;
    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaings);

        for(uint i = 0; i < numberOfCampaings; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item; 
        }

        return allCampaigns;
    }
}