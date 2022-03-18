/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface  IMasterChef{
    function poolInfo(uint256) external view returns(IERC20,uint256,uint256,bool,uint256,uint256,uint256,uint256);
    function userInfo(uint256,address) external view returns(uint256,uint256,uint256,uint256,bool);
    function pendingSushi(uint256,address) external view returns(uint256);
}


contract Helper {
        struct PoolData {
        uint256 pid;
        IERC20 lpToken; 
        uint256 allocPoint; 
        uint256 amount; 
        bool isNFT; 
        uint256 withdrawFee; 
        uint256 minAmount; 
        uint256 lastRewardTime;
        uint256 accSushiPerShare; 

        bool _is721;
        uint256 allowance;
        uint256 balance;
        uint8 decimals;
        uint256 pending;
 
        uint256 amount1; 
        uint256 boostAmount; 
        uint256 untilLock; 
        uint256 rewardDebt; 
        bool markUserStatus;
    }
        event err(uint256 a);
        
       
    
    function getUserInfo(address masterchef_,uint256[] memory pids_,address account_,address[] memory token_,address[] memory farms_) 
    public view returns(PoolData[] memory) {
        PoolData[] memory list = new PoolData[](pids_.length);
          for (uint256 i = 0; i < pids_.length; i++) {
            
            PoolData memory p = poolInfoOne(masterchef_, pids_[i]);
            p.pending = IMasterChef(masterchef_).pendingSushi(pids_[i],account_);
            (p.amount1,p.boostAmount,p.untilLock,p.rewardDebt,p.markUserStatus) =  IMasterChef(masterchef_).userInfo(pids_[i],account_);
            //address add = address(p.lpToken);
            bool _is721 = _isErc721(token_[i]);
            if (_is721){
                bool isApproveAll = IERC721(token_[i]).isApprovedForAll(account_,masterchef_);
                p.allowance = isApproveAll? type(uint256).max:0;
                p.decimals = 0;
            }else{
            p.allowance = IERC20(token_[i]).allowance(account_,farms_[i]);            
            p.decimals= IERC20(token_[i]).decimals();
            }
            
            p.balance= IERC20(token_[i]).balanceOf(account_);
            p.pid = i;
            list[i] = p;
        }
        
            return list; 
}

    bytes4 public constant SupportsInterfaceSel = bytes4(keccak256(bytes('supportsInterface(bytes4)')));
    function _isErc721(address _token) public view returns (bool) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSelector(SupportsInterfaceSel, bytes4(0x80ac58cd)));
    if (success) {
      return abi.decode(data, (bool));
    }
    return success;
  }



    function userInfoOne(address masterchef_,uint256 pid_,address account_) public view returns(PoolData memory p) {
        (p.amount1,p.boostAmount,p.untilLock,p.rewardDebt,p.markUserStatus) =  IMasterChef(masterchef_).userInfo(pid_,account_);
        p.pending = IMasterChef(masterchef_).pendingSushi(pid_,account_);
        // p.allowance = IERC20(p.lpToken).allowance(account_, masterchef_);
        return p;
    }

    function userInfoTwo(address[] memory _token, address account_) public view returns (uint256[] memory) {
        uint256[] memory account = new uint256[](7);
        for (uint256 i = 0; i < _token.length; i++) {
            account[i] = IERC20(_token[i]).balanceOf(account_);
        }
        return account;
    }

    function userInfoThree(address[] memory token_,address[] memory farms_,address account_) public view returns(uint256[] memory) {
         
            uint256[] memory master = new uint256[](farms_.length);
            for (uint256 i = 0; i < farms_.length; i++) {
                master[i] = IERC20(token_[i]).allowance(account_,farms_[i]);
            }
            return (master);
    }

    function getPoolInfo(address masterchef_,  uint256[] memory pids_) public view returns (PoolData[] memory){

        PoolData[] memory p = new PoolData[](pids_.length);
        for (uint256 i = 0; i < pids_.length; i++) {
            p[i] = poolInfoOne(masterchef_, pids_[i]);
        }
        return p;
    }

    function poolInfoOne(address masterchef_, uint256 pid_) public view returns(PoolData memory p) {
        
        (p.lpToken,p.allocPoint,p.amount,p.isNFT,p.withdrawFee,p.minAmount,p.lastRewardTime,p.accSushiPerShare) =  IMasterChef(masterchef_).poolInfo(pid_);

        return p;
        
    }



}