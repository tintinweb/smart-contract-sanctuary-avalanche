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

    // map each address to a submissionId(uint) and inside of each map a rank(uint) to a teamId(uint)
    mapping (address => mapping(uint => mapping(uint => uint) )) public submission;

    mapping(address => uint[]) public submissionCount;

    function getSubmissionLength(address _address) public view returns (uint){
        return submissionCount[_address].length;
    }

    mapping(uint => mapping(address => uint)) public nftOwners;

    function stakeBatch(uint8 _rank1, uint8 _rank2, uint8 _rank3, uint8 _rank4) public {

        uint subId = submissionCount[msg.sender].length;
        submission[msg.sender][subId][1] = _rank1;
        submission[msg.sender][subId][2] = _rank2;
        submission[msg.sender][subId][3] = _rank3;
        submission[msg.sender][subId][4] = _rank4;
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

        nftOwners[_rank1][msg.sender]++;
        nftOwners[_rank2][msg.sender]++;
        nftOwners[_rank3][msg.sender]++;
        nftOwners[_rank4][msg.sender]++;
    }

    function innerSwap(uint _submissionId, uint fromPosition, uint toPosition) public {
        // store the toPosition tokenId
        uint _to = submission[msg.sender][_submissionId][toPosition];

        // swap the "from" tokenId to "to" tokenId
        submission[msg.sender][_submissionId][toPosition] = submission[msg.sender][_submissionId][fromPosition];
        
        // swap the "to" tokenId to "from" tokenId
        submission[msg.sender][_submissionId][fromPosition] = _to;

        //increase swaps number
        swap[msg.sender][_submissionId]++ ;
    }

    function outerSwap(uint _submissionId, uint position, uint tokenId) public {
        uint previousTokenId = submission[msg.sender][_submissionId][position];
        // replace the value in the mapping
        submission[msg.sender][_submissionId][position] = tokenId;

        // unstake the swapped tokenId
        nft.safeTransferFrom(address(this), msg.sender, previousTokenId , 1, "");

        // stake the new tokenId
        nft.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");

        // add the msg.sender to the array of owners for the new tokenId
        nftOwners[tokenId][msg.sender]++;

        // remove the msg.sender from the array of owners for the previousTokenId
        nftOwners[previousTokenId][msg.sender]--;

        //increase swaps number
        swap[msg.sender][_submissionId]++ ;
    }

    function unstakeBatch(uint256 _submissionId) public {
        require(nftOwners[submission[msg.sender][_submissionId][1]][msg.sender]>0, "#1 Not your NFT");
        require(nftOwners[submission[msg.sender][_submissionId][2]][msg.sender]>0, "#2 Not your NFT");
        require(nftOwners[submission[msg.sender][_submissionId][3]][msg.sender]>0, "#3 Not your NFT");
        require(nftOwners[submission[msg.sender][_submissionId][4]][msg.sender]>0, "#4 Not your NFT");
        

        uint[] memory ids = new uint[](4);
        ids[0] = submission[msg.sender][_submissionId][1];
        ids[1] = submission[msg.sender][_submissionId][2];
        ids[2] = submission[msg.sender][_submissionId][3];
        ids[3] = submission[msg.sender][_submissionId][4];
        uint[] memory amounts = new uint[](4);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;

        nft.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");

        delete submission[msg.sender][_submissionId][1];
        delete submission[msg.sender][_submissionId][2];
        delete submission[msg.sender][_submissionId][3];
        delete submission[msg.sender][_submissionId][4];
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // R E W A R D

    uint[4] public finalRanking;
    bool public isFinalRankingSet;

    address[] public winnersCat1;
    address[] public winnersCat2;
    address[] public winnersCat3;

    // for each address map a submissionId(uint) to a number of swaps(uint)
    mapping (address => mapping(uint => uint )) public swap;

    function isWinner(uint _submissionId) public {
        require(isFinalRankingSet, "Final Ranking Not Set");
        require(submission[msg.sender][_submissionId][1] == finalRanking[0], "Not eligible");
        require(submission[msg.sender][_submissionId][2] == finalRanking[1], "Not eligible");
        require(submission[msg.sender][_submissionId][3] == finalRanking[2], "Not eligible");
        require(submission[msg.sender][_submissionId][4] == finalRanking[3], "Not eligible");
        
        if(swap[msg.sender][_submissionId] == 0){
            winnersCat1.push(msg.sender);
        } else if (swap[msg.sender][_submissionId] > 0 && swap[msg.sender][_submissionId] < 3){
            winnersCat2.push(msg.sender);
        } else {
            winnersCat3.push(msg.sender);
        }
    }

    function setFinalRanking(uint _1, uint _2, uint _3, uint _4) public onlyOwner {
        finalRanking[0] = _1;
        finalRanking[1] = _2;
        finalRanking[2] = _3;
        finalRanking[3] = _4;
        isFinalRankingSet = true;
    }

    function rewardWinners() public payable  onlyOwner {
        for(uint i; i < winnersCat1.length; i++){
            payable(address(winnersCat1[i])).transfer(address(this).balance*50/100*winnersCat1.length);
        }
        for(uint i; i < winnersCat2.length; i++){
            payable(address(winnersCat2[i])).transfer(address(this).balance*30/100*winnersCat2.length);
        }
        for(uint i; i < winnersCat3.length; i++){
            payable(address(winnersCat3[i])).transfer(address(this).balance*20/100*winnersCat3.length);
        }
    }

}