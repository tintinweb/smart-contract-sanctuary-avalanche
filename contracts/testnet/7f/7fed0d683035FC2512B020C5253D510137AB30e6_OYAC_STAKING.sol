/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnbyContract(uint256 _amount) external;
    function withdrawStakingReward(address _address,uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface gen_1{
    function isStaked(address LockedUser) external view returns(bool);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed LockedTokenid);
    event Approval(address indexed owner, address indexed approved, uint256 indexed LockedTokenid);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 LockedTokenid) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 LockedTokenid) external;
    function transferFrom(address from,address to,uint256 LockedTokenid) external;
    function approve(address to, uint256 LockedTokenid) external;
    function getApproved(uint256 LockedTokenid) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 LockedTokenid,bytes calldata data) external;
}

contract Ownable {

    address public _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OYAC_STAKING is Ownable{

    ////////////    Variables   ////////////

    using SafeMath for uint256;
    IERC721 public NFT;
    IERC20 public Token;
    gen_1 public GEN_1;
    address public DutuchAuction;


    ////////////    Locked - Structure   ////////////

    struct LockeduserInfo 
    {
        uint256 totlaWithdrawn;
        uint256 withdrawable;
        uint256 totalStaked;
        uint256 lockedAvaialable;
    }

    ////////////    Locked - Mapping   ////////////

    mapping(address => LockeduserInfo ) public LockedUser;
    mapping(address => mapping(uint256 => uint256)) public LockedstakingTime;
    mapping(address => uint256[] ) public LockedTokenid;
    mapping(address => uint256) public LockedtotalStakedNft;
    mapping(uint256 => bool) public LockedalreadyAwarded;
    mapping(address => mapping(uint256=>uint256)) public lockeddepositTime;

    uint256 Time= 20 seconds;
    uint256 LockingTime= 60 seconds;
    uint256 maxNoOfDays = 3;

     constructor(IERC721 _NFTToken,IERC20 _token,gen_1 _gen_1)  
    {
        NFT =_NFTToken;
        Token=_token;
        GEN_1 = _gen_1;
    }

    modifier onlyDuctch() {
        require(msg.sender == DutuchAuction , "Caller is not from Ductch Auction");
        _;
    }

    function add_Dutch_address(address _dutuch) public {
        DutuchAuction = _dutuch;
    }

    ////////////    Locked Staking   ////////////

     function lockedStaking(uint256 _Tokenid, address _user) external 
     onlyDuctch 
     {

       LockedTokenid[_user].push(_Tokenid);
       LockedstakingTime[_user][_Tokenid]=block.timestamp;
       if(!LockedalreadyAwarded[_Tokenid]){
       lockeddepositTime[_user][_Tokenid]=block.timestamp;
        }       
       LockedUser[_user].totalStaked+=1;
       LockedtotalStakedNft[_user]+=1;
    }

    ////////////    Reward Check Function   ////////////

     function lockedCalcTime(uint256 Tid, address _user) public view returns(uint256) {
        uint256 noOfDays;
        // address addresss = msg.sender;
        if(LockedstakingTime[_user][Tid] > 0) {
        noOfDays = (block.timestamp.sub(LockedstakingTime[_user][Tid])).div(Time);
        if (noOfDays > maxNoOfDays) {
            noOfDays = maxNoOfDays;
            }
            else{
                noOfDays = 0;
            }
        }
        return noOfDays;
    }

    function lockedperNFTReward(address addrs) public view returns(uint256) {
        bool check = GEN_1.isStaked(addrs);
        uint256 rewardPerNFT;
        if(check == true) {
            rewardPerNFT = 15 ether;
            }
        else {
            rewardPerNFT = 10 ether;
            }
        return rewardPerNFT;
    }

    function lockedSingleReward(address Add, uint256 Tid) public view returns(uint256) {
        uint256 single_reward;
        uint256 noOfDays;
        uint256 rewardPerNFT = lockedperNFTReward(Add);
        
        for (uint256 i=0; i<LockedTokenid[Add].length; i++){
            uint256 _index=findlocked(Tid);
            if(LockedalreadyAwarded[LockedTokenid[Add][_index]] != true &&LockedTokenid[Add][i] == Tid && LockedTokenid[Add][i] > 0) {
                noOfDays = lockedCalcTime(Tid, Add);
                if (noOfDays == maxNoOfDays){
                    single_reward = (rewardPerNFT).mul(noOfDays);
                    }
                else if(noOfDays != maxNoOfDays) {
                    noOfDays = 0;
                    single_reward = (rewardPerNFT).mul(noOfDays);
                }
            }
        }
        return single_reward;
    }

    function lockedtotalReward(address Add) public view returns(uint256){
        uint256 ttlReward;
        for (uint256 i=0; i< LockedTokenid[Add].length; i++){
            ttlReward += lockedSingleReward(Add, LockedTokenid[Add][i]);
            }
        return ttlReward;
    }


    ////////////    Withdraw-Reward   ////////////

    function WithdrawLockedReward()  public {
        uint256 totalReward = lockedtotalReward(msg.sender) + 
        rewardOfUser(msg.sender) + 
        LockedUser[msg.sender].lockedAvaialable + User[msg.sender].availableToWithdraw ;
        require(totalReward > 0,"you don't have reward yet!");
        Token.withdrawStakingReward(msg.sender, totalReward);
        for(uint256 i=0; i < LockedTokenid[msg.sender].length;i++){
            uint256 _index=findlocked(LockedTokenid[msg.sender][i]);
            LockedalreadyAwarded[LockedTokenid[msg.sender][_index]]=true;
            // if(lockedCalcTime(LockedTokenid[msg.sender][i])==maxNoOfDays){
            //     LockedstakingTime[msg.sender][LockedTokenid[msg.sender][i]]=0;
            // }
        }
        for(uint8 i=0;i<Tokenid[msg.sender].length;i++){
            stakingTime[msg.sender][Tokenid[msg.sender][i]]=block.timestamp;
            alreadyAwarded[Tokenid[msg.sender][i]]=true;
            }
        LockedUser[msg.sender].lockedAvaialable = 0;
        User[msg.sender].availableToWithdraw =  0;
        LockedUser[msg.sender].totlaWithdrawn +=  totalReward;
    }

    ////////////    Get index by Value   ////////////

    function findlocked(uint value) public view returns(uint) {
        uint i = 0;
        while (LockedTokenid[msg.sender][i] != value) {
            i++;
        }
        return i;
    }


    ////////////    LockedUser have to pass tokenIdS to unstake   ////////////

    function unstakelocked(uint256[] memory TokenIds)  external
    {
   
        address nftContract = msg.sender;
        for(uint256 i=0; i<TokenIds.length; i++){
            uint256 _index=findlocked(TokenIds[i]);
            require(lockedCalcTime(LockedTokenid[msg.sender][_index], msg.sender)==maxNoOfDays," TIME NOT REACHED YET ");
            require(LockedTokenid[msg.sender][_index] == TokenIds[i] ," NFT WITH THIS LOCKED_TOKEN_ID NOT FOUND ");
            LockedUser[msg.sender].lockedAvaialable += lockedSingleReward(msg.sender,TokenIds[i]);
            NFT.transferFrom(address(this),address(nftContract),TokenIds[i]);
            delete LockedTokenid[msg.sender][_index];
            LockedTokenid[msg.sender][_index]=LockedTokenid[msg.sender][LockedTokenid[msg.sender].length-1];
            LockedstakingTime[msg.sender][TokenIds[i]]=0;
            LockedTokenid[msg.sender].pop();
            
        }

        LockedUser[msg.sender].totalStaked -= TokenIds.length;
        LockedtotalStakedNft[msg.sender]>0?LockedtotalStakedNft[msg.sender] -= TokenIds.length:LockedtotalStakedNft[msg.sender]=0;
    }  

    ////////////    Return All staked Nft's   ////////////
    
    function LockeduserNFT_s(address _staker)public view returns(uint256[] memory) {
       return LockedTokenid[_staker];
    }

    function isLockedStaked(address _stakeHolder)public view returns(bool){
        if(LockedtotalStakedNft[_stakeHolder]>0){
            return true;
            }else{
            return false;
        }
    }

    ////////////    Withdraw Token   ////////////    
    function WithdrawToken()public onlyOwner {
    require(Token.transfer(msg.sender,Token.balanceOf(address(this))),"Token transfer Error!");
    }




    ////////////////////////////////    SSTAKING     /////////////////////////////////
    struct userInfo 
    {
        uint256 totlaWithdrawn;
        uint256 withdrawable;
        uint256 totalStaked;
        uint256 availableToWithdraw;
    }

    mapping(address => mapping(uint256 => uint256)) public stakingTime;
    mapping(address => userInfo ) public User;
    mapping(address => uint256[] ) public Tokenid;
    mapping(address=>uint256) public totalStakedNft;
    mapping(uint256=>bool) public alreadyAwarded;
    mapping(address=>mapping(uint256=>uint256)) public depositTime;

    uint256 time= 10 seconds;
    uint256 lockingtime= 1 minutes;


    function Stake(uint256[] memory tokenId) external 
    {
       for(uint256 i=0;i<tokenId.length;i++){
    //    require(NFT.ownerOf(tokenId[i]) == msg.sender,"nft not found");
    //    NFT.transferFrom(msg.sender,address(this),tokenId[i]);
       Tokenid[msg.sender].push(tokenId[i]);
       stakingTime[msg.sender][tokenId[i]]=block.timestamp;
       if(!alreadyAwarded[tokenId[i]]){
       depositTime[msg.sender][tokenId[i]]=block.timestamp;
       
       }
       }
       
       User[msg.sender].totalStaked+=tokenId.length;
       totalStakedNft[msg.sender]+=tokenId.length;

    }

    function rewardOfUser(address Add) public view returns(uint256)
    {
        uint256 RewardToken;
        for(uint256 i = 0 ; i < Tokenid[Add].length ; i++){
            if(Tokenid[Add][i] > 0)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*10 ether;     
            }
     }
    return RewardToken;
    }

    // function WithdrawReward()  public 
    // {
    //    uint256 reward = rewardOfUser(msg.sender) + User[msg.sender].availableToWithdraw;
    //    require(reward > 0,"you don't have reward yet!");
    //    require(Token.balanceOf(address(Token))>=reward,"Contract Don't have enough tokens to give reward");
    //    Token.withdrawStakingReward(msg.sender,reward);
    //    for(uint8 i=0;i<Tokenid[msg.sender].length;i++){
    //    stakingTime[msg.sender][Tokenid[msg.sender][i]]=block.timestamp;
    //    }
    //    User[msg.sender].totlaWithdrawn +=  reward;
    //    User[msg.sender].availableToWithdraw =  0;
    //    for(uint256 i = 0 ; i < Tokenid[msg.sender].length ; i++){
    //     alreadyAwarded[Tokenid[msg.sender][i]]=true;
    //    }
    // }

    function find(uint value) internal  view returns(uint) {
        uint i = 0;
        while (Tokenid[msg.sender][i] != value) {
            i++;
        }
        return i;
     }

    function unstake(uint256[] memory _tokenId)  external 
    {
        User[msg.sender].availableToWithdraw+=rewardOfUser(msg.sender);
        for(uint256 i=0;i<_tokenId.length;i++){
        if(rewardOfUser(msg.sender)>0)alreadyAwarded[_tokenId[i]]=true;
        uint256 _index=find(_tokenId[i]);
        // require(Tokenid[msg.sender][_index] ==_tokenId[i] ,"NFT with this _tokenId not found");
        // NFT.transferFrom(address(this),msg.sender,_tokenId[i]);
        delete Tokenid[msg.sender][_index];
        Tokenid[msg.sender][_index]=Tokenid[msg.sender][Tokenid[msg.sender].length-1];
        stakingTime[msg.sender][_tokenId[i]]=0;
        Tokenid[msg.sender].pop();
        }
        User[msg.sender].totalStaked-=_tokenId.length;
        totalStakedNft[msg.sender]>0?totalStakedNft[msg.sender]-=_tokenId.length:totalStakedNft[msg.sender]=0;
       
    }

    function isStaked(address _stakeHolder)public view returns(bool){
            if(totalStakedNft[_stakeHolder]>0){
            return true;
            }else{
            return false;
          }
    }
    function userStakedNFT(address _staker)public view returns(uint256[] memory) {
       return Tokenid[_staker];
    }


}