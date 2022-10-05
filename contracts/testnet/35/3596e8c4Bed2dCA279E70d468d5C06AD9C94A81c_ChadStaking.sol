// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";

import "./Utils.sol";

contract ChadStaking is Ownable {
    IERC1155 public nft;

    constructor(address _nft) {
        nft = IERC1155(_nft);
    }

    struct Ranking {
        uint rank1;
        uint rank2;
        uint rank3;
        uint rank4;
    }

    mapping (address => mapping(uint => Ranking)) public submission;

    mapping(address => uint[]) public submissionCount;

    function getSubmissionLenght() public view returns (uint){
        return submissionCount[msg.sender].length;
    }

    function setSubmission(uint _1, uint _2, uint _3, uint _4) public {
        uint incr = submissionCount[msg.sender].length;
        submission[msg.sender][incr].rank1 = _1;
        submission[msg.sender][incr].rank2 = _2;
        submission[msg.sender][incr].rank3 = _3;
        submission[msg.sender][incr].rank4 = _4;
        submissionCount[msg.sender].push(1);
        
    }

    mapping(uint => address[]) public nftOwners;

    function stake(uint8 _rank1, uint8 _rank2, uint8 _rank3, uint8 _rank4) public {

        uint incr = submissionCount[msg.sender].length;
        submission[msg.sender][incr].rank1 = _rank1;
        submission[msg.sender][incr].rank2 = _rank2;
        submission[msg.sender][incr].rank3 = _rank3;
        submission[msg.sender][incr].rank4 = _rank4;
        submissionCount[msg.sender].push(1);

        uint[] memory ids = new uint[](4);
        ids[0] = _rank1;
        ids[1] = _rank2;
        ids[2] = _rank3;
        ids[3] = _rank4;
        uint[] memory amounts = new uint[](4);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;

        nft.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        for(uint i; i < ids.length; i++){
            nftOwners[ids[i]].push(msg.sender);
        }
    }

    function unstake(uint256 _submissionId) public {
        require(Utils.indexOfAddresses(nftOwners[submission[msg.sender][_submissionId].rank1], msg.sender) > -1, "#1 Not your NFT");
        require(Utils.indexOfAddresses(nftOwners[submission[msg.sender][_submissionId].rank2], msg.sender) > -1, "#2 Not your NFT");
        require(Utils.indexOfAddresses(nftOwners[submission[msg.sender][_submissionId].rank3], msg.sender) > -1, "#3 Not your NFT");
        require(Utils.indexOfAddresses(nftOwners[submission[msg.sender][_submissionId].rank4], msg.sender) > -1, "#4 Not your NFT");

        uint[] memory ids = new uint[](4);
        ids[0] = submission[msg.sender][_submissionId].rank1;
        ids[1] = submission[msg.sender][_submissionId].rank2;
        ids[2] = submission[msg.sender][_submissionId].rank3;
        ids[3] = submission[msg.sender][_submissionId].rank4;
        uint[] memory amounts = new uint[](4);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;

        nft.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        delete submission[msg.sender][_submissionId].rank1;
        delete submission[msg.sender][_submissionId].rank2;
        delete submission[msg.sender][_submissionId].rank3;
        delete submission[msg.sender][_submissionId].rank4;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // R E W A R D

    address[] public winners;
    function isWinner(uint _submissionId, uint rank1, uint rank2, uint rank3, uint rank4) public {
        require(submission[msg.sender][_submissionId].rank1 == rank1, "Not eligible");
        require(submission[msg.sender][_submissionId].rank2 == rank2, "Not eligible");
        require(submission[msg.sender][_submissionId].rank3 == rank3, "Not eligible");
        require(submission[msg.sender][_submissionId].rank4 == rank4, "Not eligible");
        winners.push(msg.sender);
    }

    function rewardWinners() public payable  onlyOwner {
        for(uint i; i < winners.length; i++){
            payable(address(winners[i])).transfer(address(this).balance/winners.length);
        }
    }

}