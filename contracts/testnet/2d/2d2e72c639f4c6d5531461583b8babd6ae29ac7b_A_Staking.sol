/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-26
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

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable   {
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

contract A_Staking is Ownable {

    using SafeMath for uint256;
    IERC20 public Token;
    IERC721 public NFT;

    uint256 public time = 1 seconds;
    // uint256 public lockingtime= 1 days;
    uint256 public lockingtime= 60 seconds;
    // uint256 public commonIds = 8000;
    uint256 public commonIds = 200;
    uint256 public genisisIds = 400;
    // uint256 public genisisIds = 10000;
    uint256 public maxNoOfDays = 60;
    uint256 public firstReward = 300000000000000000000;

    constructor(IERC721 _nft, IERC20 _token){
        NFT = _nft;
        Token = _token;
    }

    struct User
    {
        uint256 commonTotalWithdrawn;
        uint256 commonTotalStaked;
        uint256 genisisTotalWithdrawn;
        uint256 genisisTotalStaked;
        uint256 boosterTotalWithdrawn;
        uint256 boosterTotalStaked;
    }

    mapping(uint256 => mapping(address => uint256[])) public TokenIds;  // adrr > id[]
    mapping(address => User) public UserInfo;
    mapping(uint256 => mapping(address=>uint256)) public TotalStakedNft;
    mapping(uint256=>bool) public AlreadyAwarded;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public StakingTime;
    mapping(address => mapping(uint256 => uint256)) public SingleIdReward;
    // mapping(address => mapping(uint256 => bool)) public StakedId;


    function lockedStaking(address user, uint256 tokenId) external {
        require(tokenId >= 0 && tokenId < genisisIds,"Id not found");
        uint256 idType = getType(tokenId);
        // NFT.transferFrom(user, address(this), tokenId);
        TokenIds[idType][user].push(tokenId);
        StakingTime[idType][user][tokenId]=block.timestamp;
        UserInfo[user].commonTotalStaked+=1;
        TotalStakedNft[idType][user]+=1;
    }


   function calcTime(address user, uint256 tokenId) public view returns(uint256) {
        uint256 noOfDays;

        if(tokenId <= commonIds){
            noOfDays += (block.timestamp.sub(StakingTime[1][user][tokenId])).div(time);
            if (noOfDays > maxNoOfDays) {
            noOfDays = maxNoOfDays;
            }
        }

        else{
            noOfDays += (block.timestamp.sub(StakingTime[2][user][tokenId])).div(time);
            if (noOfDays > maxNoOfDays) {
            noOfDays = maxNoOfDays;
            }
        }
        return noOfDays;
    }

    function singleReward(address user, uint256 Id) public view returns (uint256){
        uint256 reward;
        uint256 noOfDays;
        if( Id <= commonIds){
        noOfDays = calcTime(user, Id);
        reward += ((noOfDays).mul(20).mul(1 ether)).div(1 minutes);
        }
        else{      
            noOfDays = calcTime(user, Id);
            reward += ((noOfDays).mul(100).mul(1 ether)).div(1 minutes);
        }
        return reward;
    }

    function userIds(address user, uint256 _type) public view returns(uint256[] memory){
        return TokenIds[_type][user];
    }

    function totalUserIds(address user) public view returns(uint256[] memory three){
        uint256[] memory _type1 = TokenIds[1][user];
        uint256[] memory _type2 = TokenIds[2][user];
        three = new uint256[] ( _type1.length + _type2.length);
        for (uint256 i=0; i < _type1.length ; i++){
            three[i] = _type1[i];
        }
        for (uint256 i=0; i < _type2.length ; i++){
            three[_type1.length + i] = _type2[i];
        } 
    }

    function totalUserReward(address _user) public view returns(uint256){
        uint256 totalRewards;
        for(uint256 i =1; i<= 2; i++){
           totalRewards += totalReward(_user, i);
        }
        return totalRewards;
    }

    function totalReward(address user, uint256 _type) public view returns(uint256){
        uint256 TotalReward;
        // uint256[] memory arr = userIds(user, _type);
        for(uint256 i; i<TokenIds[_type][user].length; i++){
            TotalReward += singleReward(user, TokenIds[_type][user][i]);
        }
         if(AlreadyAwarded[_type] != true){
            TotalReward = TotalReward + firstReward;
        }
        return TotalReward;
    }

    function getType(uint256 Id) public view returns(uint256 IdType){
        if(Id <= commonIds){
            IdType = 1;
        }
        else if(Id > commonIds && IdType <= genisisIds){
            IdType = 2;
        }
        else{
            IdType = 0;
        }
    }

    function _withdraw(address _user, uint256[] memory Ids) public {
        // require(block.timestamp > StakingTime[_type][_user][tokenId] + lockingtime,"Time not reached");
        uint256 _type;
        uint256   ttlReward;
        uint256 _index;
        for(uint256 i; i< Ids.length;i++){
            _type = getType(Ids[i]);
            _index =findId(Ids[i], _type);
            if(block.timestamp > StakingTime[_type][_user][Ids[i]] + lockingtime){
                // ttlReward = totalReward(_user, _type);
                ttlReward += singleReward(_user, TokenIds[_type][_user][_index]);
                if(AlreadyAwarded[_type] != true){
                    ttlReward = ttlReward + firstReward;
                }
                Token.transfer(_user, ttlReward);
                StakingTime[_type][_user][TokenIds[_type][_user][_index]] = 0;
                AlreadyAwarded[_type] = true;
            }
        }
    }

    function unstake( uint256[] memory Ids) public{
        address _user = msg.sender;
        uint256 _type;
        uint256 _index;
        for(uint256 i; i<Ids.length;i++){
            _type = getType(Ids[i]);
            _index =findId(Ids[i], _type);
            // require(TokenIds[_type][_user][_index] == Ids[i] ,"NFT with this tokenId not found");
            if((block.timestamp) >= (StakingTime[_type][_user][Ids[_index]] + lockingtime)){
                NFT.transferFrom(address(this),address(_user),Ids[_index]);
                StakingTime[_type][_user][Ids[_index]]=0;

                delete TokenIds[_type][_user][_index];
                TokenIds[_type][_user][_index] = TokenIds[_type][_user][TokenIds[_type][_user].length - 1];
                TokenIds[_type][_user].pop();
                if(_type == 1){
                    UserInfo[_user].commonTotalStaked -= 1;
                }
                else if(_type == 2){
                    UserInfo[_user].genisisTotalStaked -= 1;
                }
                TotalStakedNft[_type][_user]>0?TotalStakedNft[_type][_user] -= 1 : TotalStakedNft[_type][_user]=0;
            }
        }
    }

    function findId(uint256 _value, uint256 _type) public view returns (uint256){
        uint256 i = 0;
        while(TokenIds[_type][msg.sender][i] != _value){
            i++;
        }
        return i;
    }
}