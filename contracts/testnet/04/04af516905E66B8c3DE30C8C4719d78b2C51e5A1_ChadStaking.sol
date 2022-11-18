// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// Utils functions
import "./Utils.sol";

/// @title Chad Sports Staking.
/// @author Memepanze
/// @notice ERC1155 Staking contract for Chad Sports to rank the teams and get rewarded.
contract ChadStaking is Ownable, ReentrancyGuard {

    constructor(address _nft) {
        nft = IERC1155(_nft);
    }

    /// @notice ERC1155 interface variable
    IERC1155 public nft;

    /// @notice map each address to a submissionId {uint} and inside of each: map a rank {uint} to a teamId {uint}
    mapping (address => mapping(uint => mapping(uint => uint) )) public submission;

    /// @notice The number of submissions for each user address
    mapping(address => uint) public submissionCount;

    /// @notice Track the number of NFTs (tokenID) per user address
    mapping(uint => mapping(address => uint)) public nftOwners;

    /// @notice Track all the submissions for each user address
    mapping (address => uint[][]) public allSubmissions;

    /// @notice an array of the final ranking of the 4 teams in the World Cup
    uint[4] public finalRanking;

    /// @notice Check if the Final Ranking is set by contract owners after the World Cup if finished
    bool public isFinalRankingSet;

    /// @notice List of winners
    address[] public winners4teams;

    /// @notice List of winners
    address[] public winners3teams;

    /// @notice List of winners
    address[] public winners2teams;

    /// @notice List of winners
    address[] public winners1team;

    /// @notice The end date for the minting
    /// @dev for the 2022 world cup 1670594400
    uint public endDate;

    // M O D I F I E R

    /// @notice NFTs hodlers can change their rankings until 1 hour before the Top 16
    modifier changeRankings {
        require(block.timestamp <= endDate);
        _;
    }

    // E V E N T S

    /// @notice Emitted on the receive()
    /// @param amount The amount of received Eth
    event ReceivedEth(uint amount);

    /// @notice Emitted on withdrawBalance() 
    event BalanceWithdraw(address to, uint amount);

    // E R R O R

    error Chad__FinalRankingNotSet();

    error Chad__BalanceIsEmpty();

    error Chad__TransferFailed();

    error Chad__NotAWinner();

    /// @notice Get the 4 teams ranked in a submission
    /// @return An array of tokenIds
    function getSubmission(address _userAddr, uint256 _submissionId) external view returns(uint[] memory) {
        uint[] memory teams = new uint[](4);
        teams[0] = submission[_userAddr][_submissionId][1];
        teams[1] = submission[_userAddr][_submissionId][2];
        teams[2] = submission[_userAddr][_submissionId][3];
        teams[3] = submission[_userAddr][_submissionId][4];

        return teams;
    }

    /// @notice Get all the submissions for a wallet address
    /// @return An array of arrays of tokenIds
    function getAllSubmissions(address _userAddr) external view returns(uint[][] memory) {
        uint[][] memory _allSub = new uint[][](submissionCount[_userAddr]);
        for(uint i; i < submissionCount[_userAddr]; i++){
            uint[] memory teams = new uint[](4);
            teams[0] = submission[_userAddr][i][1];
            teams[1] = submission[_userAddr][i][2];
            teams[2] = submission[_userAddr][i][3];
            teams[3] = submission[_userAddr][i][4];

            _allSub[i] = teams;
        }

        return _allSub;
    }

    /// @notice User stake batch 4 teams (ERC1155) by ranking the NFTs from 1 to 4.
    /// @dev This function can be called before the start of the Top 16 of the world cup.
    function stakeBatch(uint8 _rank1, uint8 _rank2, uint8 _rank3, uint8 _rank4) external nonReentrant changeRankings {

        // track of the number of submissions by address
        uint subId = submissionCount[msg.sender];
        submission[msg.sender][subId][1] = _rank1;
        submission[msg.sender][subId][2] = _rank2;
        submission[msg.sender][subId][3] = _rank3;
        submission[msg.sender][subId][4] = _rank4;
        submissionCount[msg.sender]++;

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

        // The ERC1155 are transfer to the contract address to avoid user to have multiple ranking with the same NFTs
        nft.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");

        // Track of the ownership of the NFTs which will be used to allow the user to unstake its staked ERC1155.
        nftOwners[_rank1][msg.sender]++;
        nftOwners[_rank2][msg.sender]++;
        nftOwners[_rank3][msg.sender]++;
        nftOwners[_rank4][msg.sender]++;

        allSubmissions[msg.sender].push(ids);
    }

    /// @notice User unstakes batch its 4 teams (ERC1155).
    function unstakeBatch(uint256 _submissionId) external nonReentrant {
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

        // Track of the ownership of the NFTs which will be used to allow the user to unstake its staked ERC1155.
        nftOwners[submission[msg.sender][_submissionId][1]][msg.sender]--;
        nftOwners[submission[msg.sender][_submissionId][2]][msg.sender]--;
        nftOwners[submission[msg.sender][_submissionId][3]][msg.sender]--;
        nftOwners[submission[msg.sender][_submissionId][4]][msg.sender]--;

        delete submission[msg.sender][_submissionId][1];
        delete submission[msg.sender][_submissionId][2];
        delete submission[msg.sender][_submissionId][3];
        delete submission[msg.sender][_submissionId][4];

        nft.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    /// @notice Set the end date (timestamp) for the minting.
    function setEndDate(uint _date) external onlyOwner {
        endDate = _date;
    }

    // R E W A R D

    /// @notice Check if a ranking submission is winning.
    function isWinner(uint _submissionId) external {
        if(!isFinalRankingSet){
            revert Chad__FinalRankingNotSet();
        }
        if(submission[msg.sender][_submissionId][1] == finalRanking[0]){
            winners1team.push(msg.sender);
            if(submission[msg.sender][_submissionId][2] == finalRanking[1]){
                winners2teams.push(msg.sender);
            }
            if(submission[msg.sender][_submissionId][3] == finalRanking[2]){
                winners3teams.push(msg.sender);
            }
            if(submission[msg.sender][_submissionId][4] == finalRanking[3]){
                winners4teams.push(msg.sender);
            }
        } else {
            revert Chad__NotAWinner();
        }
        
        winners4teams.push(msg.sender);
    }

    /// @notice Admin function to set the final ranking of the Top 4 for the World Cup.
    function setFinalRanking(uint _1, uint _2, uint _3, uint _4) public onlyOwner {
        finalRanking[0] = _1;
        finalRanking[1] = _2;
        finalRanking[2] = _3;
        finalRanking[3] = _4;
        isFinalRankingSet = true;
    }

    
    /// @notice Admin function to reward the list of Winners
    function rewardWinners() external onlyOwner {
        uint stakingPot = address(this).balance;
        if(stakingPot == 0){
            revert Chad__BalanceIsEmpty();
        }
        if(winners4teams.length > 0){
            for(uint i; i < winners4teams.length; i++){
                
                bool sent;
                (sent, ) = address(winners4teams[i]).call{value:stakingPot/winners4teams.length}("");
                if (!sent) {
                    revert Chad__TransferFailed();
                }
            }
        } else if(winners3teams.length > 0){
            for(uint i; i < winners3teams.length; i++){
                
                bool sent;
                (sent, ) = address(winners3teams[i]).call{value:stakingPot/winners3teams.length}("");
                if (!sent) {
                    revert Chad__TransferFailed();
                }
            }
        } else if(winners2teams.length > 0){
            for(uint i; i < winners2teams.length; i++){
                
                bool sent;
                (sent, ) = address(winners2teams[i]).call{value:stakingPot/winners2teams.length}("");
                if (!sent) {
                    revert Chad__TransferFailed();
                }
            }
        } else if(winners1team.length > 0){
            for(uint i; i < winners1team.length; i++){
                
                bool sent;
                (sent, ) = address(winners1team[i]).call{value:stakingPot/winners1team.length}("");
                if (!sent) {
                    revert Chad__TransferFailed();
                }
            }
        }
    }

    /// @notice The Staking contract will receive the rewards from the Minting Contract.
    receive() external payable {
        emit ReceivedEth(msg.value);
    }

    /// @notice Withdraw the contract balance to the contract owner
    /// @param _to Recipient of the withdrawal
    function withdrawBalance(address _to) external onlyOwner nonReentrant {
        uint amount = address(this).balance;
        bool sent;

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert Chad__TransferFailed();
        }

        emit BalanceWithdraw(_to, amount);
    }


    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}