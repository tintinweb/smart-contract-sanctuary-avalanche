// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        mapping(address => bool) approvals; // Track approvals from participants
        bool withdrawalRequestCreated;
        bool withdrawalRequestApproved;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];
        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        require(msg.value > 0, "Please insert correct value");
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);
        campaign.amountCollected += amount;
    }

    function createWithdrawalRequest(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];
        require(campaign.owner == msg.sender, "Only the campaign owner can create a withdrawal request.");
        require(campaign.amountCollected > 0, "No funds available for withdrawal.");

        campaign.withdrawalRequestCreated = true;
        campaign.withdrawalRequestApproved = false;

        // Reset participant approvals
        for (uint256 i = 0; i < campaign.donators.length; i++) {
            campaign.approvals[campaign.donators[i]] = false;
        }
    }

    function approveWithdrawalRequest(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];
        require(campaign.withdrawalRequestCreated, "No withdrawal request exists for this campaign.");
        require(!campaign.withdrawalRequestApproved, "Withdrawal request has already been approved.");
        require(campaign.approvals[msg.sender] == false, "You already approve for this request");
        uint256 totalParticipants = campaign.donators.length;
        uint256 halfTotalParticipant = totalParticipants/2;
        uint256 approvedTotalParticipant = 0;
        // Check if msg.sender is a participant in the campaign
        bool flag = false;
        for(uint256 i = 0; i<totalParticipants; i++){
            if(campaign.donators[i] == msg.sender){
                flag = true;
            }
        }

       require(flag, "Wallet Address Not Exist");

        campaign.approvals[msg.sender] = true;

        //////////////////////////////////////////
        for(uint256 i = 0; i < totalParticipants; i++){
            if (!campaign.approvals[campaign.donators[i]]) {
            }
            else{
                approvedTotalParticipant++;
            }
        }

       // require(approvedTotalParticipant >= halfTotalParticipant , "50% participant not complete yet");
       if(approvedTotalParticipant >= halfTotalParticipant){

       }
       else{
           return;
       }
        //////////////////////////////////////////
        campaign.withdrawalRequestApproved = true;

        // Perform the withdrawal
        (bool sent, ) = payable(campaign.owner).call{value: campaign.amountCollected}("");
        require(sent, "Failed to send funds to the campaign owner.");
        campaign.amountCollected = 0; // Reset the amountCollected for the campaign
    }

    function getCampaignOwner(uint256 _id) public view returns (address) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].owner;
    }
    function getCampaignTitle(uint256 _id) public view returns (string memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].title;
    }

    function getCampaignDescription(uint256 _id) public view returns (string memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].description;
    }

    function getCampaignTarget(uint256 _id) public view returns (uint256) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].target;
    }

    function getCampaignDeadline(uint256 _id) public view returns (uint256) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].deadline;
    }

    function getCampaignAmountCollected(uint256 _id) public view returns (uint256) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].amountCollected;
    }

    function getCampaignImage(uint256 _id) public view returns (string memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].image;
    }

    function getCampaignDonators(uint256 _id) public view returns (address[] memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].donators;
    }

    function getCampaignDonations(uint256 _id) public view returns (uint256[] memory) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].donations;
    }

    function isWithdrawalRequestCreated(uint256 _id) public view returns (bool) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].withdrawalRequestCreated;
    }

    function isWithdrawalRequestApproved(uint256 _id) public view returns (bool) {
        require(_id < numberOfCampaigns, "Invalid campaign ID.");
        return campaigns[_id].withdrawalRequestApproved;
    }
function getAllCampaigns() public view returns (uint256[] memory) {
    uint256[] memory allCampaigns = new uint256[](numberOfCampaigns);

    for (uint256 i = 0; i < numberOfCampaigns; i++) {
        allCampaigns[i] = i;
    }

    return allCampaigns;
}

 function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }
 

}