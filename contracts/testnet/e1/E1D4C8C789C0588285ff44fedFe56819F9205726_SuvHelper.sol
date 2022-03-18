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


contract SuvHelper {
        struct PoolData {
        uint256 pid;
        IERC20 lpToken; // 池子是哪种lp.
        uint256 allocPoint; //分配点
        uint256 amount; // 用户存的数量
        bool isNFT; // NFT flags.
        uint256 withdrawFee; // User withdraw fee
        uint256 minAmount; // 设置最小数量
        uint256 lastRewardTime; //lastRewardBlock是上一次分配奖励的区块数。/或者是池子分配奖励开始的时间，池子更新时会变化
        uint256 accSushiPerShare; //池子更新updatePool时这个值会更新（存币取币都会调用updatePool）
        // accSushiPerShare是质押一个LPToken的全局收益，用户依赖这个计算实际收益，
        //原理很简单，用户在质押LPToken的时候，会把当前accSushiPerShare记下来作为起始点位，
        //当解除质押的时候，可以通过最新的accSushiPerShare减去起始点位，就可以得到用户实际的收益。
        bool _is721;
        uint256 allowance;//lpToken合约还可以调用用户多少个token
        uint256 balance;//用户的余额
        uint8 decimals;
        uint256 pending;//当前时间用户在某一个池子里可取出的代币(lpToken)最大数量
 
        uint256 amount1; // 用户提供了多少lp TOKEN.
        uint256 boostAmount; // How many LP tokens with multilex the user has provided.
        uint256 untilLock; // 用户锁定时间的时间戳
        uint256 rewardDebt; // Reward debt. See explanation below.
        bool markUserStatus; // 黑名单.
    }
        event err(uint256 a);
        
       
    //传入14个token_真实代币地址token_，传入14个挖矿合约地址farms_（masterchef_，masterchef_，itoken,...,masterchef_...）
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

//     function isErc721(address _token) public view returns (bool) {
//     bool success = _isErc721(_token);
//       return success;
//   }
//     function isErc721_(address[] memory _token)  public view returns(bool[] memory ) {
//             bool[] memory account= new bool[](_token.length);
//             for (uint256 i = 0; i < _token.length; i++) {
//                 account[i] = _isErc721(_token[i]);
//             }
//             return account;
//     }

    // function Erc721(address _token) public view returns (bool) {
    //    _is721 =IERC721(_token).supportsInterface(0x80ac58cd);
    //    return _is721;
    // }
    bytes4 public constant SupportsInterfaceSel = bytes4(keccak256(bytes('supportsInterface(bytes4)')));
    function _isErc721(address _token) public view returns (bool) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSelector(SupportsInterfaceSel, bytes4(0x80ac58cd)));
    if (success) {
      return abi.decode(data, (bool));
    }
    return success;
  }


        //单独查某一个挖矿合约的用户信息
    function userInfoOne(address masterchef_,uint256 pid_,address account_) public view returns(PoolData memory p) {
        (p.amount1,p.boostAmount,p.untilLock,p.rewardDebt,p.markUserStatus) =  IMasterChef(masterchef_).userInfo(pid_,account_);
        p.pending = IMasterChef(masterchef_).pendingSushi(pid_,account_);
        // p.allowance = IERC20(p.lpToken).allowance(account_, masterchef_);
        return p;
    }
        //单独查询用户还有多少代币，_token代表14个真实的代币合约地址
    function userInfoTwo(address[] memory _token, address account_) public view returns (uint256[] memory) {
        uint256[] memory account = new uint256[](7);
        for (uint256 i = 0; i < _token.length; i++) {
            account[i] = IERC20(_token[i]).balanceOf(account_);
        }
        return account;
    }
        //单独查询14个allowance
    function userInfoThree(address[] memory token_,address[] memory farms_,address account_) public view returns(uint256[] memory) {
            //传入14个token_真实代币地址token_，传入14个挖矿合约地址farms_（masterchef_，masterchef_，itoken,...,masterchef_...）
            uint256[] memory master = new uint256[](farms_.length);
            for (uint256 i = 0; i < farms_.length; i++) {
                master[i] = IERC20(token_[i]).allowance(account_,farms_[i]);
            }
            return (master);
    }
    //单独查询所有挖矿池子的信息
    function getPoolInfo(address masterchef_,  uint256[] memory pids_) public view returns (PoolData[] memory){

        PoolData[] memory p = new PoolData[](pids_.length);
        for (uint256 i = 0; i < pids_.length; i++) {
            p[i] = poolInfoOne(masterchef_, pids_[i]);
        }
        return p;
    }
        //单独查询某个挖矿池子的信息
    function poolInfoOne(address masterchef_, uint256 pid_) public view returns(PoolData memory p) {
        
        (p.lpToken,p.allocPoint,p.amount,p.isNFT,p.withdrawFee,p.minAmount,p.lastRewardTime,p.accSushiPerShare) =  IMasterChef(masterchef_).poolInfo(pid_);

        return p;
        
    }



}