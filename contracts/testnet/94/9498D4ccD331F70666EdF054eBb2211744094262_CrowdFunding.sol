/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    uint256 public requiredNFT;
    enum CampaignStatus { Ongoing, Failed, Successful }

    struct Campaign {
        address payable owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 balance;
        string image;
        mapping(address => uint256) donations;
        CampaignStatus status;
        uint256 numDonators;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(address => uint256[]) public ownedCampaigns;

    uint256 public numberOfCampaigns = 0;
    address public contractOwner;

    event CampaignCreated(uint256 campaignId, address owner, string title, uint256 target, uint256 deadline);
    event DonationReceived(uint256 campaignId, address donator, uint256 amount);
    event TokensTransferred(address recipient, uint256 tokenId, uint256 amount);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can perform this action.");
        _;
    }

    function createCampaign(string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public onlyOwner returns (uint256) {
        require(_deadline > block.timestamp, "The deadline should be a date in the future.");

        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = payable(msg.sender);
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;
        campaign.status = CampaignStatus.Ongoing;

        ownedCampaigns[msg.sender].push(numberOfCampaigns);

        emit CampaignCreated(numberOfCampaigns, msg.sender, _title, _target, _deadline);

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        Campaign storage campaign = campaigns[_id];

        require(campaign.status == CampaignStatus.Ongoing, "Cannot donate to a campaign that is not ongoing.");
        require(block.timestamp <= campaign.deadline, "Cannot donate to a campaign past its deadline.");

        campaign.donations[msg.sender] = campaign.donations[msg.sender] + msg.value;
        campaign.balance += msg.value;

        if(campaign.balance >= campaign.target) {
            campaign.status = CampaignStatus.Successful;
        }

        emit DonationReceived(_id, msg.sender, msg.value);

        campaign.numDonators++;
    }

    function withdrawFunds(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        require(campaign.owner == msg.sender, "Only the campaign owner can withdraw funds.");
        require(block.timestamp > campaign.deadline, "Cannot withdraw funds before the campaign deadline.");
        require(campaign.status == CampaignStatus.Successful, "Campaign must be successful to withdraw funds.");

        uint256 amountToTransfer = campaign.balance;
        campaign.balance = 0;

        campaign.owner.transfer(amountToTransfer);
    }

    function refundDonation(uint256 _id) public {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp > campaign.deadline, "Cannot refund donation before the campaign deadline.");
        require(campaign.status == CampaignStatus.Failed, "Can only refund donations from failed campaigns.");
        require(campaign.donations[msg.sender] > 0, "No donations to refund.");

        uint256 amountToRefund = campaign.donations[msg.sender];
        campaign.donations[msg.sender] = 0;

        payable(msg.sender).transfer(amountToRefund);
    }

    function getOwnedCampaigns(address _owner) public view returns (uint256[] memory) {
        return ownedCampaigns[_owner];
    }

    function checkCampaignStatus(uint256 _id) public view returns (CampaignStatus) {
        Campaign storage campaign = campaigns[_id];

        if(campaign.status == CampaignStatus.Ongoing && block.timestamp > campaign.deadline) {
            if(campaign.balance >= campaign.target) {
                return CampaignStatus.Successful;
            } else {
                return CampaignStatus.Failed;
            }
        }

        return campaign.status;
    }
}