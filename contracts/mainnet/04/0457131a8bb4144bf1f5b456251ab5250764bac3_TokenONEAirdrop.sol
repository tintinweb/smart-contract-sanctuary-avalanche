// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";


interface IERC20 {
   function approve(address spender, uint256 amount) external returns (bool);
} 

interface ITreasury {
    function mintRewards( address _recipient, uint _amount ) external;
}

interface IStakingHelper {
    function stake( uint _amount, address recipient ) external;
}

contract TokenONEAirdrop is Ownable { 

    using SafeMath for uint256;    
    struct Info { 
        address userAddress; 
        uint256 maxPayout; 
        uint256 claimedAmount; 
        uint256 claimableAmount;
        uint256 startEpoch;
        uint256 endEpoch; 
        uint256 lastEpoch; 
        bool active; 
    }  

    struct Record { 
        address userAddress; 
        uint256 maxPayout;  
        uint256 endEpoch;  
    }  

    mapping (address => Info) private info; 
    address public token; 
    address public treasury; 
    address public staking; 
    uint256 public rebaseRate; 
    uint256 public epochLength; 
 
    
    constructor(
        address _treasury, 
        address _stakingHelper, 
        address _token, 
        uint256 _rebaseRate,  
        uint256 _epochLength 
    ) Ownable() {
        treasury = _treasury; 
        staking = _stakingHelper; 
        token = _token; 
        rebaseRate =  _rebaseRate; 
        epochLength = _epochLength; 
    }  
  

    function distribute (address _address) internal view  returns (uint256, bool){
        uint256 claimableReward = 0;
        bool rewardDistributed = false;
        if(block.timestamp >= info[_address].endEpoch){
            claimableReward = info[_address].maxPayout.sub(info[_address].claimedAmount); 
            rewardDistributed = true; 
        }else{
            uint256 maxClaimableRateReward = (info[_address].maxPayout.mul(rebaseRate)).div(10000);
            uint256 totalEpochs = (info[_address].endEpoch.sub(info[_address].startEpoch)).div(epochLength); 
            uint256 passedEpochs = (block.timestamp.sub(info[_address].lastEpoch)).div(epochLength);
            if(passedEpochs >= 1){
                uint256 epochReward = maxClaimableRateReward.div(totalEpochs);
                claimableReward = passedEpochs.mul(epochReward);
            } 
            if( info[_address].claimedAmount.add(claimableReward) > maxClaimableRateReward){
                claimableReward = maxClaimableRateReward.sub(info[_address].claimedAmount);
            } 
        }   
        return (claimableReward, rewardDistributed);
    }


 
    function claim (bool _stake) public {  

        require(info[msg.sender].active, "Address is not active!");  

        uint256 claimableReward;
        bool rewardDistributed; 

        // get claimable amount
        (claimableReward, rewardDistributed) = distribute(msg.sender);

        require(claimableReward > 0, "Reward is not available!");

        if(rewardDistributed == true){
            info[msg.sender].active = false;
        }  
        uint _value = claimableReward.div(1e18).mul(1e9);
        if(_stake){
            // claim and stake 
            ITreasury( treasury ).mintRewards( address(this), _value );
            IERC20(token).approve(address(staking), claimableReward);  
            IStakingHelper(staking).stake(_value, msg.sender);
        }else{
            // claim
            ITreasury( treasury ).mintRewards( msg.sender, _value );
        } 

        info[msg.sender].claimedAmount = info[msg.sender].claimedAmount.add(claimableReward);
        info[msg.sender].lastEpoch = block.timestamp; 
    }  

 

    function status(address  _address) external view returns(Info  memory) {    
        uint256 claimableReward;
        bool rewardDistributed;
        (claimableReward, rewardDistributed) = distribute(_address);
        Info memory _info = Info({
            userAddress: info[_address].userAddress, 
            maxPayout: info[_address].maxPayout, 
            claimedAmount:  info[_address].claimedAmount,
            claimableAmount: claimableReward,
            startEpoch: info[_address].startEpoch,
            endEpoch: info[_address].endEpoch, 
            lastEpoch: info[_address].lastEpoch, 
            active: info[_address].active
        });
        return _info;
    }  
 

    function setAccounts(Record[] memory _records) external onlyOwner { 
        for(uint i=0; i< _records.length; i++){ 
           info[_records[i].userAddress] = Info( _records[i].userAddress, _records[i].maxPayout,  0, 0, block.timestamp, _records[i].endEpoch, block.timestamp,  true ); 
        } 
    }
  

     function update(address _address, uint256 _maxPayout,uint256 _startEpoch, uint256 _endEpoch, uint256 _lastEpoch) external onlyOwner returns (bool){
        require(info[_address].active, "Address is not active!");
        info[_address].maxPayout = _maxPayout;
        info[_address].startEpoch = _startEpoch;
        info[_address].endEpoch = _endEpoch;
        info[_address].lastEpoch = _lastEpoch;
        return true;
    } 

    function disable(address _address) external onlyOwner returns (bool){
        info[_address].active = false;
        return true;
    } 

    function enable(address _address) external onlyOwner returns (bool){
        info[_address].active = true;
        return true;
    }

    function setRate(uint256 _rate) external  onlyOwner returns (bool){  
        require(_rate > 0, "Rebase rate percentage must be more than 0!");
        rebaseRate = _rate;
        return true;
    }  

    function setEpoch(uint256 _epochLength) external  onlyOwner returns (bool){  
        epochLength = _epochLength;
        return true;
    } 
       
}