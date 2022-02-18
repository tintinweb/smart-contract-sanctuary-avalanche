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
        uint256 startBlock;
        uint256 endBlock; 
        uint256 lastBlock; 
        bool active; 
    }  

    struct Record { 
        address userAddress; 
        uint256 maxPayout;  
        uint256 endBlock;  
    }  

    mapping (address => Info) private info; 
    address public token; 
    address public treasury; 
    address public staking; 
    uint256 public rebaseRate; 
    uint256 public epochLength; 
 
    
    constructor(address _treasury, address _staking, address _token, uint256 _rebaseRate,  uint256 _epochLength ) Ownable() {
        treasury = _treasury; 
        staking = _staking; 
        token = _token; 
        rebaseRate =  _rebaseRate; 
        epochLength = _epochLength; 
    }  
  

    function distribute (address _address) internal view  returns (uint256, bool){
        uint256 claimableReward = 0;
        bool rewardDistributed = false;
        if(block.number >= info[_address].endBlock){
            claimableReward = info[_address].maxPayout.sub(info[_address].claimedAmount); 
            rewardDistributed = true; 
        }else{
            uint256 maxClaimableRateReward = (info[_address].maxPayout.mul(rebaseRate)).div(10000);
            uint256 totalEpochs = (info[_address].endBlock.sub(info[_address].startBlock)).div(epochLength); 
            uint256 passedEpochs = (block.number.sub(info[_address].lastBlock)).div(epochLength);
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

        if(_stake){
            // claim and stake
            ITreasury( treasury ).mintRewards( address(this), claimableReward );
            IERC20(token).approve(address(staking), claimableReward); 
            uint _value = claimableReward.div(1e18).mul(1e9);
            IStakingHelper(staking).stake(_value, msg.sender);

        }else{
            ITreasury( treasury ).mintRewards( msg.sender, claimableReward );
        } 

        info[msg.sender].claimedAmount = info[msg.sender].claimedAmount.add(claimableReward);
        info[msg.sender].lastBlock = block.number; 
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
            startBlock: info[_address].startBlock,
            endBlock: info[_address].endBlock, 
            lastBlock: info[_address].lastBlock, 
            active: info[_address].active
        });
        return _info;
    }  
 

    function setAccounts(Record[] memory _records) external onlyOwner { 
        for(uint i=0; i< _records.length; i++){ 
           info[_records[i].userAddress] = Info( _records[i].userAddress, _records[i].maxPayout,  0, 0, block.number, _records[i].endBlock, block.number,  true ); 
        } 
    }

    function setAccount(address _address, uint256 _maxPayout, uint256 _endBlock) public onlyOwner {  
        Info memory newInfo = Info({
            userAddress: _address, 
            maxPayout: _maxPayout, 
            claimedAmount: 0,
            claimableAmount: 0,
            startBlock: block.number,
            endBlock: _endBlock,
            lastBlock: block.number, 
            active: true
        });
        info[_address] = newInfo;  
    }


     function update(address _address, uint256 _maxPayout,uint256 _startBlock, uint256 _endBlock, uint256 _lastBlock) external onlyOwner returns (bool){
        require(info[_address].active, "Address is not active!");
        info[_address].maxPayout = _maxPayout;
        info[_address].startBlock = _startBlock;
        info[_address].endBlock = _endBlock;
        info[_address].lastBlock = _lastBlock;
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
        rebaseRate = _rate;
        return true;
    }  

    function setEpoch(uint256 _epochLength) external  onlyOwner returns (bool){  
        epochLength = _epochLength;
        return true;
    } 
       
}