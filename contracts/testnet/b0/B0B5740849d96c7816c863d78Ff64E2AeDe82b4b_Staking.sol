/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract SignVerify {

    function splitSignature(bytes memory sig)
        internal
        pure
        returns(uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns(address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(hash, v, r, s);
    }

    function toString(address account)
        public
        pure 
        returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data)
        internal
        pure
        returns(string memory) 
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {   _status = _NOT_ENTERED;     }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused()
        public 
        view 
        virtual 
        returns (bool) 
    {   return _paused;     }

    modifier whenNotPaused(){
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause()
        internal 
        virtual 
        whenNotPaused 
    {
      _paused = true;
      emit Paused(_msgSender());
    }

    function _unpause() 
        internal 
        virtual 
        whenPaused 
    {
      _paused = false;
      emit Unpaused(_msgSender());
    }
}

contract Staking is Ownable, SignVerify, Pausable, ReentrancyGuard{

    using SafeMath for uint256;
    IERC20 public Token;
    Staking zs;

    uint256 private constant referDepth = 8;
    uint256 baseDivider = 10000;
    uint256 perminute = 1 minutes;
    uint256 perDayMinutes = 5;  // 1440

    uint256 public  totalUser;

    address defaultRefer;
    address signer;
    address[] public depositors;
    uint256 private constant directPercents = 800;
    uint256[8] leveIncome = [600, 500, 400, 300, 300, 200, 100, 100];

    uint256 level_1 = 100000*10**18;
    uint256 level_2 = 500000*10**18;
    uint256 level_3 = 1000000*10**18;
    uint256 level_4 = 2000000*10**18;

    uint256 ROI_1 = 150000000000000000;
    uint256 ROI_2 = 170000000000000000;
    uint256 ROI_3 = 190000000000000000;
    uint256 ROI_4 = 200000000000000000;
    uint256 ROI_5 = 230000000000000000;

    struct OrderInfo{
        uint256 amount;
        uint256 depsoitTime;
    }

    struct UserInfo{
        address referrer;
        uint256 start;
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 totalDepositAmount;
        uint256 teamNum;
        uint256 directsNum;
        uint256 teamTotalDeposit;
    }

    struct RewardInfo{
        uint256 directs;
        uint256 claimedDirectsandAffiliate;
        uint256 AffiliateReward;
        uint256 totalReward;
    }

    mapping(address => UserInfo) private userInfo;
    mapping(address => RewardInfo) private rewardInfo;
    mapping(address => OrderInfo[]) private orderInfos;

    mapping(bytes32 => bool) public usedHash;
    mapping(address => uint256) private countUser;
    mapping(address => uint256) private  countUser1;
    mapping(address => uint256) private rewardClaimed;
    mapping(address => uint256) private userTotalAmount;
    mapping(address => uint256) private getDirectsamount;

    mapping(address => mapping(uint256 => uint256)) private userCount;
    mapping(address => mapping(uint256 => address)) private UserAdress;
    mapping(address => mapping(uint256 => uint256)) private _totalUser; 
    mapping(address => mapping(uint256 => address[])) private teamUsers;
    mapping(address => mapping(uint256 => uint256)) private _totalUserAmount;
    mapping(address => mapping(address => bool)) private _userAddressVerforDirects;

    mapping(address => mapping(uint256 => mapping(uint256 => address))) private userReferral;
    mapping(address => mapping(address => mapping(uint256 => bool))) private userReferralVerification;
    mapping(address => mapping(address => mapping(uint256 => bool))) private _userAddressVerification;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(uint256 => uint256)))) private claimedReward; // order -> addr -> amount -> day -> reward

    event Deposit(address user, uint256 amount);
    event Register(address user, address referral);
    event Claimed(address indexed _user, uint256 indexed _amount);

    constructor(address _defaultRefer, address _token, address _signer){
        defaultRefer = _defaultRefer;
        Token = IERC20(_token);
        zs = Staking(address(this));
        signer = _signer;
    }

    function register(address _referral) public {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        userInfo[user.referrer].directsNum = userInfo[user.referrer].directsNum.add(1);
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _tokenAmount, address _referral) external{
        require(_tokenAmount > 0, "amount must be greater than zero!!");
        UserInfo storage user = userInfo[msg.sender];
        if(user.referrer == address(0)){
            register(_referral);
        }
        else {
            Token.transferFrom(msg.sender, address(this), _tokenAmount);
            _deposit(msg.sender,_tokenAmount);
        }
    }

    function _deposit(address _user, uint256 _tokenAmount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");

        if(user.maxDeposit == 0){
            user.maxDeposit = _tokenAmount;
        }else if(user.maxDeposit < _tokenAmount){
            user.maxDeposit = _tokenAmount;
        }

        depositors.push(_user);
        
        user.totalDeposit += _tokenAmount;
        user.totalDepositAmount += _tokenAmount;

        userTotalAmount[_user] += _tokenAmount;

        orderInfos[_user].push(OrderInfo(
            _tokenAmount,
            block.timestamp
        ));

        _updateReferInfo(_user, _tokenAmount);

        _updateDirects(_user, _tokenAmount);

        _updateUserLevelInfo(_user, _tokenAmount);

        UpdateDirectsInfo(_user);

        updateReferral(_user);
        
        emit Deposit(_user, _tokenAmount);
    }

    function UpdateDirectsInfo(address _user) private{
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if(upline != address(0))
        {
            if(!_userAddressVerforDirects[_user][upline])
            {
            countUser1[upline] += 1;
            countUser[_user] = countUser1[upline];
            _userAddressVerforDirects[_user][upline] = true;
            }
            UserAdress[upline][countUser[_user]] = _user;
        }
    }   

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }
    function _updateDirects(address _user, uint256 _amount) private{
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if(upline != address(0))
        {
            uint256 newAmount = _amount;
            RewardInfo storage upRewards = rewardInfo[upline];
            uint256 reward;
            reward = newAmount.mul(directPercents).div(baseDivider);
            upRewards.directs = upRewards.directs.add(reward);
            // getDirectsamount[_user] += reward;
            getDirectsamount[upline] += reward;
        }
        _updateLevelIncome(upline, _amount);
    }

    function _updateLevelIncome(address _user, uint256 _amount) private{
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i; i< referDepth; i++){
            if(upline != address(0))
            {
                // uint256 newAmount = _amount;
                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                reward = _amount.mul(leveIncome[i]).div(baseDivider);
                upRewards.AffiliateReward = upRewards.AffiliateReward.add(reward);
                // getDirectsamount[_user] += reward;
                getDirectsamount[upline] += reward;
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }
            else {
                break;
            }
        }
    }

    function updateReferral(address _user) public
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 1; i <= referDepth; i++){
            if(upline != address(0))
            {
                if(!userReferralVerification[upline][_user][i])
                { 
                userCount[upline][i] += 1;
                uint256 counts = userCount[upline][i];
                userReferral[upline][i][counts] = _user;
                userReferralVerification[upline][_user][i] = true;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) 
    private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateUserLevelInfo(address _user, uint256 _amount) 
    private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(!_userAddressVerification[_user][upline][i])
                {
                _totalUser[upline][i] += 1;
                _userAddressVerification[_user][upline][i] = true;
                }
                _totalUserAmount[upline][i] += _amount;
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam)
            {
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    function userROI(address _user, uint256 i) public view returns(uint256){
        uint256 totalDay;
        uint256 finalTime;
        uint256 reward;
        uint256 _amount;
        uint256 finalReward = 0;

        // for(uint256 i; i< orderInfos[_user].length; i++){
        OrderInfo storage order = orderInfos[_user][i];
        if((order.amount) <= level_1){
            _amount = ((order.amount).mul(ROI_1)).div(baseDivider);
            _amount = _amount.div(1e16);
            // reward += totalDay.mul(_amount);
            // reward = finalTime.mul(_amount);

            (,totalDay,,finalTime) = getTotalDays(order.depsoitTime);
            reward = (_amount.mul(finalTime)).div(perDayMinutes);
            finalReward = reward.sub(claimedReward[i][_user][order.amount][totalDay]);
        }
        else if((order.amount) > level_1 && (order.amount) <= level_2){
            _amount = ((order.amount).mul(ROI_1)).div(baseDivider);
            _amount = _amount.div(1e16);
            (,totalDay,,finalTime) = getTotalDays(order.depsoitTime);
            reward = (ROI_2.mul(finalTime)).div(perDayMinutes);
            finalReward = reward.sub(claimedReward[i][_user][order.amount][totalDay]);
        }
        else if((order.amount) > level_2 && (order.amount) <= level_3){
            _amount = ((order.amount).mul(ROI_1)).div(baseDivider);
            _amount = _amount.div(1e16);
            (,totalDay,,finalTime) = getTotalDays(order.depsoitTime);
            reward = (ROI_3.mul(finalTime)).div(perDayMinutes);
            finalReward = reward.sub(claimedReward[i][_user][order.amount][totalDay]);
        }
        else if((order.amount) > level_3 && (order.amount) <= level_4){
            _amount = ((order.amount).mul(ROI_1)).div(baseDivider);
            _amount = _amount.div(1e16);
            (,totalDay,,finalTime) = getTotalDays(order.depsoitTime);
            reward = (ROI_4.mul(finalTime)).div(perDayMinutes);
            finalReward = reward.sub(claimedReward[i][_user][order.amount][totalDay]);
        }
        else if((order.amount) > level_4){
            _amount = ((order.amount).mul(ROI_1)).div(baseDivider);
            _amount = _amount.div(1e16);
            (,totalDay,,finalTime) = getTotalDays(order.depsoitTime);
            reward = (ROI_5.mul(finalTime)).div(perDayMinutes);
            finalReward = reward.sub(claimedReward[i][_user][order.amount][totalDay]);
        }
        return finalReward;
    }

    function getROI(address _user) public view returns (uint256){
        uint256 reward;
        for(uint256 i; i< orderInfos[_user].length; i++){
            reward = reward.add(userROI(_user, i));
        }
        
        return reward;
    }   

    function getTotalDays(uint256 _time) 
    public
    view 
    returns(uint256, uint256, uint256, uint256)
    {
        uint256 perMinut = ((block.timestamp).sub(_time)).div(perminute);
        uint256 perDay = ((block.timestamp).sub(_time)).div(5 minutes);  // 1 days
        uint256 totalTime = perDayMinutes.mul(perDay);
        uint256 finalTime = perMinut.sub(totalTime);
        return (perMinut, perDay, totalTime, finalTime);
    }
    
    function updateROI(address _user) private returns(uint256){
        uint256 totalDay;
        // uint256 finalTime;
        uint256 reward;
        uint256 _userReward;
        for (uint256 i; i< orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            (,totalDay,,) = getTotalDays(order.depsoitTime);
            reward = userROI(_user, i);
            claimedReward[i][_user][order.amount][totalDay] += reward;
            _userReward += reward;
        }
        return _userReward;

    }

    function claimDirectsAndAffiliate() public {
        RewardInfo storage upRewards = rewardInfo[msg.sender];

        uint256 levelReward;
        uint256 userDirectsReward;
        uint256 totalReward;

        levelReward = upRewards.AffiliateReward;
        userDirectsReward = upRewards.directs;
        totalReward = levelReward.add(userDirectsReward);

        upRewards.AffiliateReward = 0;
        upRewards.directs = 0;
        upRewards.claimedDirectsandAffiliate = upRewards.claimedDirectsandAffiliate.add(totalReward);
        Token.transfer(msg.sender, totalReward);
    }

    function withdraw(uint256 _reward, uint256 nonce, bytes memory _signature) external {
        
        bytes32 hash = keccak256(abi.encodePacked(
            address(this),
            _msgSender(),
            _reward,
            nonce
        ));

        require(!usedHash[hash], "Invalid hash");
        require((recoverSigner(hash, _signature) == signer), "signature failed");
        RewardInfo storage userReward = rewardInfo[msg.sender];
        usedHash[hash] = true;

        rewardClaimed[msg.sender] = rewardClaimed[msg.sender].add(_reward.add(userReward.directs));
        userReward.directs = 0;
        Token.transfer(msg.sender, _reward);
        emit Claimed(msg.sender, _reward);

    }

    function getOrderInfo(address _user) 
    public 
    view 
    returns
    (uint256[] memory _amount, uint256[] memory _time)
    {
        uint256 size = orderInfos[_user].length;
        _amount = new uint256[](size);
        _time = new uint256[](size);
        for(uint256 i; i< size; i++){
            _amount[i] = orderInfos[_user][i].amount;
            _time[i] = orderInfos[_user][i].depsoitTime;
        }
        return(_amount, _time);
    }

    function getUserInfo(address _user) 
    public 
    view 
    returns(UserInfo memory)
    {
        return userInfo[_user];
    }

    function getRewardInfo(address _user) 
    public 
    view 
    returns(RewardInfo memory)
    {
        return rewardInfo[_user];
    }

    function getDirectsAmounts(address _user) 
    public 
    view 
    returns(uint256)
    {
        return getDirectsamount[_user];
    }

    function getCountUser(address _user) 
    public 
    view 
    returns(uint256)
    {
        return countUser[_user];
    }

    function getCountUser1(address _user) 
    public 
    view 
    returns(uint256)
    {
        return countUser1[_user];
    }

    function getUserTotalAmount(address _user) 
    public 
    view 
    returns (uint256)
    {
        return userTotalAmount[_user];
    }

    function getUserCount(address _user, uint256 _index) 
    public 
    view 
    returns(uint256)
    {
        return userCount[_user][_index];
    }

    function getUserAddress(address _user, uint256 _index) 
    public 
    view 
    returns(address)
    {
        return UserAdress[_user][_index];
    }

    function getTotalUser(address _user, uint256 _index) 
    public 
    view 
    returns(uint256)
    {
        return _totalUser[_user][_index];
    }

    function getTeamUsers(address _user, uint _level) 
    public 
    view 
    returns(address[] memory)
    {
        return teamUsers[_user][_level];
    }

    function getTotalUserAmount(address _user, uint256 _level) 
    public 
    view 
    returns(uint256)
    {
        return _totalUserAmount[_user][_level];
    }

    function getUserReferral(address _user, uint256 _level, uint256 _count) 
    public 
    view 
    returns(address)
    {
        return userReferral[_user][_level][_count];
    }

    function getClaimedReward(address _user, uint256 _index, uint256 _amount, uint256 _time) 
    public 
    view 
    returns(uint256)
    {
        return claimedReward[_index][_user][_amount][_time];
    }

    function get_userAddressVerification(address _user1, address _user2, uint256 _index) 
    public 
    view 
    returns(bool)
    {
        return _userAddressVerification[_user1][_user2][_index];
    }

    function totalClaimedReward(address _user) 
    public 
    view 
    returns(uint256)
    {
        return rewardClaimed[_user];
    }

    function getDefaultAddress() 
    public 
    view 
    returns(address)
    {
        return defaultRefer; 
    }

}