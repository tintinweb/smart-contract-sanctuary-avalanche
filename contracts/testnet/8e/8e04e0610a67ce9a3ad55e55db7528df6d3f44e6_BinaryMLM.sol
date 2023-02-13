/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-13
*/

pragma solidity ^0.8.0;

contract BinaryMLM {
    // Define the structure for a member
    struct Member {
        uint256 id;
        address payable sponsor;
        uint256 leftNode;
        uint256 rightNode;
    }

    // Mapping of members with their unique ID
    mapping (uint256 => Member) public members;

    // Mapping of addresses to member IDs
    mapping (address => uint256) public addressToId;

    // Counter for generating unique IDs for members
    uint256 public memberCount;

    // Join function to add a new member to the network
    function join(address payable sponsor) public {
        // Generate a unique ID for the new member
        memberCount++;
        uint256 id = memberCount;

        // Check if the sponsor has any open slots
        uint256 sponsorId = addressToId[sponsor];
        Member storage sponsorInfo = members[sponsorId];
        if (sponsorInfo.leftNode == 0) {
            sponsorInfo.leftNode = id;
        } else if (sponsorInfo.rightNode == 0) {
            sponsorInfo.rightNode = id;
        } else {
            // The sponsor has no open slots, return an error
            revert();
        }

        // Add the new member to the mappings
        members[id] = Member({
            id: id,
            sponsor: sponsor,
            leftNode: 0,
            rightNode: 0
        });
        addressToId[sponsor] = sponsorId;
    }
}