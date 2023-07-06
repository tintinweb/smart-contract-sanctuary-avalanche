/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-05
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

    uint256 private constant referDepth = 9;
    uint256 baseDivider = 10000;
    uint256 perminute = 1 minutes;
    uint256 perDayMinutes = 5;  // 1440

    uint256 public  totalUser;

    address defaultRefer;
    address signer;
    address[] public depositors;
    // uint256 private constant directPercents = 800;
    // uint256[9] leveIncome = [600, 500, 400, 300, 300, 200, 200, 100, 100];

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

    mapping(bytes32 => bool) public depositHash;
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
    event Transferred(address indexed _user, uint256 indexed _amount);

    constructor(address _defaultRefer, address _token, address _signer){
        defaultRefer = _defaultRefer;
        Token = IERC20(_token);
        zs = Staking(address(this));
        signer = _signer;
    }

    /*
    *  user register himself before deposit
    *  user must have a referral for register
    *  user can also register himself with defualt address
    *  or from any other address address
    */

    function register(address _referral) internal {
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

    /*
    *  deposit function first check the amount to be deposited must be greater than zero
    *  first check the referral and then take teh deposit amount
    *  if referal not found it will then register first
    *  function will get the signature to verify if a user is a valid address or not
    */

    // function deposit(uint256 _tokenAmount, address _referral, uint256 _nonce, bytes memory _signature) external{
    //     require(_tokenAmount > 0, "amount must be greater than zero!!");


    //     bytes32 hash = keccak256(   
    //         abi.encodePacked(   
    //         toString(address(this)),   
    //         toString(msg.sender),
    //         toString(_referral),
    //         _nonce,
    //         _tokenAmount
    //         )
    //     );

    //     require(!depositHash[hash], "Invalid hash");
    //     require((recoverSigner(hash, _signature) == signer), "signature failed");
    //     depositHash[hash] = true;

    //     UserInfo storage user = userInfo[msg.sender];
    //     if(user.referrer == address(0)){
    //         register(_referral);
    //     }
    //     Token.transferFrom(msg.sender, address(this), _tokenAmount);
    //     _deposit(msg.sender,_tokenAmount);
    // }

    function deposit(uint256 _tokenAmount, address _referral) external{

        require(_tokenAmount > 0, "amount must be greater than zero!!");
        UserInfo storage user = userInfo[msg.sender];
         if(user.referrer == address(0)){
            register(_referral);
        }
        Token.transferFrom(msg.sender, address(this), _tokenAmount);
        _deposit(msg.sender,_tokenAmount);
    }


    /*
    *  function takes user address and amount through parameters
    *  checks if users is registered or not 
    *  if not registered, it reverts the error  
    */

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

        // _updateDirects(_user, _tokenAmount);

        _updateUserLevelInfo(_user, _tokenAmount);

        UpdateDirectsInfo(_user);

        updateReferral(_user);
        
        emit Deposit(_user, _tokenAmount);
    }

    /*
    *  update direct info 
    *  user refferal's direct will be updated
    */

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

    /*
    *  update the team number of user referral
    *  user will be added to his referral's team
    *  this will update the referrer's depth
    */

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

    /*
    *  update the directs reward
    *  every user's direct reward will be updated
    */
    // function _updateDirects(address _user, uint256 _amount) private{
    //     UserInfo storage user = userInfo[_user];
    //     address upline = user.referrer;
    //     if(upline != address(0))
    //     {
    //         uint256 newAmount = _amount;
    //         RewardInfo storage upRewards = rewardInfo[upline];
    //         uint256 reward;
    //         reward = newAmount.mul(directPercents).div(baseDivider);
    //         upRewards.directs = upRewards.directs.add(reward);
    //         // getDirectsamount[_user] += reward;
    //         getDirectsamount[upline] += reward;
    //     }
    //     // _updateLevelIncome(upline, _amount);
    // }

    /*
    *  update levels income 
    *  theese levels are updated in each deposit
    *  every time it checks the user referral level
    *  and update the reward
    */

    // function _updateLevelIncome(address _user, uint256 _amount) private{
    //     UserInfo storage user = userInfo[_user];
    //     address upline = user.referrer;
    //     for(uint256 i; i< referDepth; i++){
    //         if(upline != address(0))
    //         {
    //             // uint256 newAmount = _amount;
    //             RewardInfo storage upRewards = rewardInfo[upline];
    //             uint256 reward;
    //             reward = _amount.mul(leveIncome[i]).div(baseDivider);
    //             upRewards.AffiliateReward = upRewards.AffiliateReward.add(reward);
    //             // getDirectsamount[_user] += reward;
    //             getDirectsamount[upline] += reward;
    //             if(upline == defaultRefer) break;
    //             upline = userInfo[upline].referrer;
    //         }
    //         else {
    //             break;
    //         }
    //     }
    // }

    /*
    *  user referral count will be updated
    *  it means how many times user have deposited on this platform
    *  each referral will be updated 
    */

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

    /*
    *  user referral amount will be updated
    *  each referral will be updated till 9 levels above the user
    */

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

    /*
    *  this will update user referral amount that how much user have deposited 
    *  all referrals will be updated 
    */

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
    
    // this function will retruns the user deposit and its team deposit
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

    /*
    *  this function will transfer the amout to the caller
    *  caller must be a vsalid address
    *  other than tis will not be allowed to ttransfer the amount to the user
    */
    function withdraw(uint256 _reward, uint256 _nonce, bytes memory _signature) external {
        require(_msgSender() == tx.origin, "invalid caller");
        
        bytes32 hash = keccak256(   
            abi.encodePacked(   
            toString(address(this)),   
            toString(msg.sender),
            _nonce,
            _reward
            )
        );

        require(!usedHash[hash], "Invalid hash");
        require((recoverSigner(hash, _signature) == signer), "signature failed");
        usedHash[hash] = true;

        uint256 toalReward;
        
        RewardInfo storage userReward = rewardInfo[msg.sender];
        rewardClaimed[msg.sender] = rewardClaimed[msg.sender].add(_reward.add(userReward.directs).add(userReward.AffiliateReward));

        toalReward = _reward.add(userReward.directs.add(userReward.AffiliateReward));
        userReward.AffiliateReward = 0;
        userReward.directs = 0;
        Token.transfer(msg.sender, toalReward);
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
    {   return userInfo[_user]; }

    function getRewardInfo(address _user) 
    public 
    view 
    returns(RewardInfo memory)
    {   return rewardInfo[_user];   }

    function getDirectsAmounts(address _user) 
    public 
    view 
    returns(uint256)
    {   return getDirectsamount[_user]; }

    function getCountUser(address _user) 
    public 
    view 
    returns(uint256)
    {   return countUser[_user];    }

    function getCountUser1(address _user) 
    public 
    view 
    returns(uint256)
    {   return countUser1[_user];   }

    function getUserTotalAmount(address _user) 
    public 
    view 
    returns (uint256)
    {   return userTotalAmount[_user];  }

    function getUserCount(address _user, uint256 _index) 
    public 
    view 
    returns(uint256)
    {   return userCount[_user][_index];    }

    function getUserAddress(address _user, uint256 _index) 
    public 
    view 
    returns(address)
    {   return UserAdress[_user][_index];   }

    function getTotalUser(address _user, uint256 _index) 
    public 
    view 
    returns(uint256)
    {   return _totalUser[_user][_index];   }

    function getTeamUsers(address _user, uint _level) 
    public 
    view 
    returns(address[] memory)
    {   return teamUsers[_user][_level];    }

    function getTotalUserAmount(address _user, uint256 _level) 
    public 
    view 
    returns(uint256)
    {   return _totalUserAmount[_user][_level]; }

    function getUserReferral(address _user, uint256 _level, uint256 _count) 
    public 
    view 
    returns(address)
    {   return userReferral[_user][_level][_count]; }

    function getClaimedReward(address _user, uint256 _index, uint256 _amount, uint256 _time) 
    public 
    view 
    returns(uint256)
    {   return claimedReward[_index][_user][_amount][_time];    }

    function get_userAddressVerification(address _user1, address _user2, uint256 _index) 
    public 
    view 
    returns(bool)
    {   return _userAddressVerification[_user1][_user2][_index];    }

    function totalClaimedReward(address _user) 
    public 
    view 
    returns(uint256)
    {   return rewardClaimed[_user];    }

    function getDefaultAddress() 
    public 
    view 
    returns(address)
    {   return defaultRefer;    }

    /////////////////////     OWNER   //////////////////////

    function emergencyWithdraw(address _user) 
    external 
    onlyOwner
    {
        uint256 balance = Token.balanceOf(address(this));
        Token.transfer(_user,balance);
        emit Transferred(_user, balance);
    }

    function getReferralas(address _user) public view returns(address[] memory){
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        address[10] memory refs;
        uint256 count;
        for(uint256 i; i< 10; i++){
            if(upline != address(0)){
                refs[i] = upline;
                upline = userInfo[upline].referrer;
                count++;
                if(upline == defaultRefer){ break ; }
            }
            else{ break; }
        }

        address[] memory referrals = new address[](count);
        for(uint256 j; j< count; j++){
            if(refs[j] != address(0)){
                referrals[j] = refs[j];
            }
        }

        return referrals;
    }
    
    function setReferrals() public{
        userInfo[0x962B3b936CF677201A00Ae982CfC3ab4c4b13a48].referrer = 0x0c661FB2512B66B40668b057395869A48Cf2606c;
        userInfo[0x0f1eAb0CfC8401f8F350c71Bc2671b0Ba28e9f0A].referrer = 0x962B3b936CF677201A00Ae982CfC3ab4c4b13a48;
        userInfo[0xd4CA1609A58A8044393482B32F4A5f8CC7F579D1].referrer = 0x0f1eAb0CfC8401f8F350c71Bc2671b0Ba28e9f0A;
        userInfo[0x29086854B56D16a2548dAEc1d0c846E0b986c02B].referrer = 0xd4CA1609A58A8044393482B32F4A5f8CC7F579D1;
        userInfo[0x1716F8eed04673c99de0002DA15A3E5921cd0892].referrer = 0x29086854B56D16a2548dAEc1d0c846E0b986c02B;
        userInfo[0x8B7Cc1DA3eAC7c4F2d9387cceE611D6820e14622].referrer = 0x1716F8eed04673c99de0002DA15A3E5921cd0892;
        userInfo[0x0218319f823ADf8889A91730B724A228664677A3].referrer = 0x8B7Cc1DA3eAC7c4F2d9387cceE611D6820e14622;
        userInfo[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7].referrer = 0x0218319f823ADf8889A91730B724A228664677A3;
        userInfo[0x298119CB985cb9e8d80A8D6eb8f9d877c4744e8b].referrer = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;
        userInfo[0xb58E93cD6A780b33233cc3cd1AaC926cbdD26754].referrer = 0x298119CB985cb9e8d80A8D6eb8f9d877c4744e8b;
        userInfo[0xa05005B64385B0f2763E8Ce36dE44b56Ffb73b98].referrer = 0xb58E93cD6A780b33233cc3cd1AaC926cbdD26754;
        userInfo[0x5cCa637B3498609E5f0f5d4e212F45226c207c16].referrer = 0xa05005B64385B0f2763E8Ce36dE44b56Ffb73b98;
    }

    // function setReferrals() public{
    //     userInfo[0xdD870fA1b7C4700F2BD7f44238821C26f7392148].referrer = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    //     userInfo[0x583031D1113aD414F02576BD6afaBfb302140225].referrer = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    //     userInfo[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].referrer = 0x583031D1113aD414F02576BD6afaBfb302140225;
    //     userInfo[0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C].referrer = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    //     userInfo[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c].referrer = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    //     userInfo[0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC].referrer = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    //     userInfo[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C].referrer = 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC;
    //     userInfo[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7].referrer = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;
    //     userInfo[0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678].referrer = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;
    //     userInfo[0x617F2E2fD72FD9D5503197092aC168c91465E7f2].referrer = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
    //     userInfo[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2].referrer = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
    //     userInfo[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db].referrer = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    // }

}