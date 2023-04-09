/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-08
*/

// SPDX-License-Identifier: MIT
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

    constructor() {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }


    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

}

interface IERC20 {
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function decimals() external view returns (uint8);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        );
}

error InvalidLevel();
error AlreadyOnHighLevel();
error ReferralNotRegistered();
error UsernameAlreadyRegistered();
error ContractPaused();

contract MatrixRewards is Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    AggregatorV3Interface internal BNBFeed;   

    uint public surgeFee = 50;  // split between ref and sponser
    uint public nCommision = 90;
    uint public nfee = 10;

    IERC20 public MAT;
    bool public paused;

    struct User {
        string username;
        address referrer;
        address[] referrals;
        uint activeLevels;
    }
    mapping(address => User) public users;
    mapping(address => bool) public blacklisted;

    mapping(string => bool) public RegisteredUsername;
    mapping(string => address) public UsernameToAddress;

    mapping(address => uint) public tokenRewardGiven;
    mapping(address => uint) public BNBCommisionGiven;

    uint256 public OwnerCommision;

    uint256 public totalCommision;
    uint256 public totalReward;
    
    uint256 public tokenRequirment = 100 * 10**9;
    uint256 public feeforUserName = 3;   //3-$

    uint[] public levels = [100,250,500,1000];
    uint[] public levelReward = [100*10**9,250*10**9,500*10**9,1000*10**9];

    constructor(address _token) {
        // BNBFeed = AggregatorV3Interface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941); //BUSD->BNB 18 (MAINNET)
        BNBFeed = AggregatorV3Interface(0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c); //DAI->BNB 18 (TESTNET)
        MAT = IERC20(_token);
        users[msg.sender].activeLevels = levels.length;
        users[msg.sender].username = "ADMIN";
        RegisteredUsername["ADMIN"] = true;
        UsernameToAddress["ADMIN"] = msg.sender;
    }

    function register(address _referrer,string memory _username,uint _level) external payable nonReentrant() {
        require(_referrer != address(0),"Invalid Referrer!");
        require(_referrer != msg.sender,"Invalid Referrer!");
        require(_level != 0,"Invalid Level");
        if(paused) revert ContractPaused();
        address account = msg.sender;
        require(users[account].referrer == address(0),"Already Registered!");
        require(MAT.balanceOf(account) >= tokenRequirment,"Insufficient Mat Tokens!");
        if(!RegisteredUsername[_username]) {
            RegisteredUsername[_username] = true;
            users[account].username = _username;
            UsernameToAddress[_username] = account;
        }
        else {
            revert UsernameAlreadyRegistered();
        }

        levelChecker(account,_level);
        uint fee = getLatestPrice() * levels[_level - 1];
        uint reward = levelReward[_level - 1];
        uint value = msg.value;
        require(value >= fee,"Invalid Fee!");
        refChecker(_referrer);

        if(_referrer == owner()) {
            users[account].referrer = _referrer;
            users[_referrer].referrals.push(account);
            users[account].activeLevels = _level;
            payable(_referrer).transfer(value);  //owner in this case
            OwnerCommision += value;
            totalCommision += value;
            if(!blacklisted[account]) {
                MAT.transfer(account, reward);
                tokenRewardGiven[account] += reward;
                totalReward += reward;
            }
        }
        else {

            bool rLevel = users[_referrer].activeLevels >= _level;

            uint referralCount = users[_referrer].referrals.length;

            if(referralCount % 2 == 0) {   //ODDs

                if(rLevel) {
                    users[account].referrer = _referrer;
                    users[_referrer].referrals.push(account);
                    users[account].activeLevels = _level;

                    uint oDue = value.mul(nfee).div(100);
                    uint rDue = value.sub(oDue);

                    if(!blacklisted[_referrer]) {
                        payable(_referrer).transfer(rDue);
                        BNBCommisionGiven[_referrer] += rDue;
                        totalCommision += rDue;
                    }

                    payable(owner()).transfer(oDue);
                    OwnerCommision += oDue;

                    if(!blacklisted[account]) {
                        MAT.transfer(account, reward);
                        tokenRewardGiven[account] += reward;
                        totalReward += reward;
                    }
                }
                else {
                    address uplineMatch = finduplinelevel(_referrer,_level);
                    users[_referrer].activeLevels = _level;  //free Upgrade
                    users[account].activeLevels = _level;
                    users[account].referrer = uplineMatch;
                    users[uplineMatch].referrals.push(account);

                    uint oDue = value.mul(nfee).div(100);
                    uint rDue = value.sub(oDue);

                    uint ONEsplit = rDue.mul(surgeFee).div(100);
                    uint Twosplit = rDue.sub(ONEsplit);

                    if(!blacklisted[_referrer]) {
                        address sRef = _referrer;
                        payable(_referrer).transfer(ONEsplit);
                        BNBCommisionGiven[sRef] += ONEsplit;
                        totalCommision += ONEsplit;
                    }
                    if(!blacklisted[uplineMatch]) {
                        payable(uplineMatch).transfer(Twosplit);
                        BNBCommisionGiven[uplineMatch] += Twosplit;
                        totalCommision += Twosplit;
                    }

                    payable(owner()).transfer(oDue);
                    OwnerCommision += oDue;

                    if(!blacklisted[account]) {
                        MAT.transfer(account, reward);
                        tokenRewardGiven[account] += reward;
                        totalReward += reward;
                        
                    }
                }

            }
            else {

                if(rLevel) {
                    //to the upline even 
                    address upline = finduplineforEven(_referrer); //users[_referrer].referrer;
                    
                    users[upline].referrals.push(account);
                    users[_referrer].referrals.push(address(0)); //push null in ref because of even logic
                    users[account].referrer = upline;
                    users[account].activeLevels = _level; 

                    uint oDue = value.mul(nfee).div(100);
                    uint rDue = value.sub(oDue);

                    uint ONEsplit = rDue.mul(surgeFee).div(100);
                    uint Twosplit = rDue.sub(ONEsplit);

                    if(!blacklisted[_referrer]) {
                        address sRef = _referrer;
                        payable(_referrer).transfer(ONEsplit);
                        BNBCommisionGiven[sRef] += ONEsplit;
                        totalCommision += ONEsplit;
                    }
                    if(!blacklisted[upline]) {
                        payable(upline).transfer(Twosplit);
                        BNBCommisionGiven[upline] += Twosplit;
                        totalCommision += Twosplit;
                    }

                    payable(owner()).transfer(oDue);
                    OwnerCommision += oDue;

                    if(!blacklisted[account]) {
                        MAT.transfer(account, reward);
                        tokenRewardGiven[account] += reward;
                        totalReward += reward;
                    }
                }
                
                else {

                    address uplineMatch = finduplinelevel(_referrer,_level);
                    users[_referrer].activeLevels = _level;  //free Upgrade
                    users[account].activeLevels = _level;
                    users[account].referrer = uplineMatch;
                    users[uplineMatch].referrals.push(account);

                    uint oDue = value.mul(nfee).div(100);
                    uint rDue = value.sub(oDue);

                    uint ONEsplit = rDue.mul(surgeFee).div(100);
                    uint Twosplit = rDue.sub(ONEsplit);

                    if(!blacklisted[_referrer]) {
                        address sRef = _referrer;
                        payable(_referrer).transfer(ONEsplit);
                        BNBCommisionGiven[sRef] += ONEsplit;
                        totalCommision += ONEsplit;
                    }
                    if(!blacklisted[uplineMatch]) {
                        payable(uplineMatch).transfer(Twosplit);
                        BNBCommisionGiven[uplineMatch] += Twosplit;
                        totalCommision += Twosplit;
                    }

                    payable(owner()).transfer(oDue);
                    OwnerCommision += oDue;

                    if(!blacklisted[account]) {
                        MAT.transfer(account, reward);
                        tokenRewardGiven[account] += reward;
                        totalReward += reward;
                    }
                }
            }
        }
    }

    function upgradeLevel(uint _level) public payable nonReentrant() {
        require(_level != 0,"Invalid Level");
        if(paused) revert ContractPaused();
        address account = msg.sender;
        require(!blacklisted[account],"User Blacklisted!");
        require(users[account].referrer != address(0),"Needs to Register First!");
        require(MAT.balanceOf(account) >= tokenRequirment,"Insufficient Mat Tokens!");
        levelChecker(account,_level);
        uint fee = getLatestPrice() * levels[_level - 1];
        uint reward = levelReward[_level - 1];
        uint value = msg.value;
        require(value >= fee,"Invalid Fee!");
        address ref = users[account].referrer;
        bool rLevel = users[ref].activeLevels >= _level;
        
        if(!rLevel) {
            address uplineMatch = finduplinelevel(ref,_level);

            users[ref].activeLevels = _level;  //free Upgrade
            users[account].activeLevels = _level;

            replaceRef(ref,account);

            users[account].referrer = uplineMatch;
            users[uplineMatch].referrals.push(account);

            uint oDue = value.mul(nfee).div(100);
            uint rDue = value.sub(oDue);

            uint ONEsplit = rDue.mul(surgeFee).div(100);
            uint Twosplit = rDue.sub(ONEsplit);

            
            if(!blacklisted[ref]) {
                payable(ref).transfer(ONEsplit);
                BNBCommisionGiven[ref] += ONEsplit;
                totalCommision += ONEsplit;
            }
            if(!blacklisted[uplineMatch]) {
                payable(uplineMatch).transfer(Twosplit);
                BNBCommisionGiven[uplineMatch] += Twosplit;
                totalCommision += Twosplit;
            }

            payable(owner()).transfer(oDue);
            OwnerCommision += oDue;

            if(!blacklisted[account]) {
                MAT.transfer(account, reward);
                tokenRewardGiven[account] += reward;
                totalReward += reward;
            }


        }
        else {

            users[account].activeLevels = _level;

            uint oDue = value.mul(nfee).div(100);
            uint rDue = value.sub(oDue);

            if(!blacklisted[ref]) {
                payable(ref).transfer(rDue);
                BNBCommisionGiven[ref] += rDue;
                totalCommision += rDue;
            }

            payable(owner()).transfer(oDue);

            if(!blacklisted[account]) {
                MAT.transfer(account, reward);
                tokenRewardGiven[account] += reward;
                totalReward += reward;
            }                                   

        }
    }

    function changeUsername(string memory _username) external payable {
        uint fee = feeforUserName * getLatestPrice();
        require(msg.value >= fee,"Sufficient Fee!");
        address account = msg.sender;
        string memory _userRegistered = users[account].username;
        if(!RegisteredUsername[_username]) {
            RegisteredUsername[_username] = true;
            users[account].username = _username;
            UsernameToAddress[_username] = account;
            UsernameToAddress[_userRegistered] = address(0);
            RegisteredUsername[_userRegistered] = false;
        }
        else {
            revert UsernameAlreadyRegistered();
        }
    }

    function replaceRef(address _ref,address _user) internal {
        uint length = users[_ref].referrals.length;
        for(uint i = 0; i < length;i++) {
            if(users[_ref].referrals[i] == _user){
                users[_ref].referrals[i] = address(0);
            }
        }
    }

    function refChecker(address _referrer) internal view {
        if(_referrer != owner()) {
            if(users[_referrer].referrer == address(0)) {
                revert ReferralNotRegistered();
            }
        }
    }

    function finduplinelevel(address _ref,uint _level) internal view returns (address) {
        address upline = _ref;
        while(users[upline].activeLevels < _level) {
            upline = users[upline].referrer;
        }
        return upline;
    }

    function finduplineforEven(address _ref) internal view returns (address) {
        return users[_ref].referrer;
    }

    function levelChecker(address account,uint _pid) private view {
        uint length = levels.length;
        uint userlevel = users[account].activeLevels;
        if(_pid > length) {
            revert InvalidLevel();
        }
        if(userlevel >= _pid) {
            revert AlreadyOnHighLevel();
        }
    }

    function setPauser(bool status) external onlyOwner {
        paused = status;
    }

    function activateOwnerLevel() external onlyOwner {
        users[owner()].activeLevels = levels.length;
    }

    function addWhitelist(address _referrer, address _user, uint _level) external onlyOwner {
        require(_referrer != address(0),"Invalid Referrer!");
        require(_referrer != _user,"Invalid Referrer!");
        require(_level != 0,"Invalid Level");
        require(users[_user].referrer == address(0),"Already Registered!");
        levelChecker(_user,_level);   

        users[_user].referrer = _referrer;
        users[_referrer].referrals.push(_user);
        users[_user].activeLevels = _level;
    }

    function addWhitelistBulk(address _referrer, address[] memory _user, uint[] memory _level) external onlyOwner {
        require(_user.length == _level.length,"Length Mismatch");
        for(uint i = 0; i < _user.length; i++) {
            users[_user[i]].referrer = _referrer;
            users[_referrer].referrals.push(_user[i]);
            users[_user[i]].activeLevels = _level[i];
        }
    }

    function setMat(address _newAddress) external onlyOwner {
        MAT = IERC20(_newAddress);
    }

    function setUsernameFee(uint _value) external onlyOwner {
        feeforUserName = _value;
    }

    function setTokenRequirement(uint _value) external onlyOwner {
        tokenRequirment = _value;
    }
    
    function addToBlacklist(address _user,bool _status) external onlyOwner {
        blacklisted[_user] = _status;
    }

    function setlevel(uint _index,uint _value) external onlyOwner {
        levels[_index] = _value;
    }

    function setReward(uint _index,uint _value) external onlyOwner {
        levelReward[_index] = _value;
    }

    function getUserReferrals(address _user) external view returns (address[] memory , uint length) {
        return (users[_user].referrals,users[_user].referrals.length);
    }

    function feeForLevel(uint _level) external view returns (uint) {
        uint fee = getLatestPrice() * levels[_level - 1];
        return fee;
    }

    function getLatestPrice() public view returns (uint) {
        (,int price,,,) = BNBFeed.latestRoundData();   
        return uint(price);
    }

    function setBnbFeed(address _feed) external onlyOwner {
        BNBFeed = AggregatorV3Interface(_feed);
    }

    function setSurgeFee(uint fee) external onlyOwner {
        surgeFee = fee;
    }

    function setCommissionFee(uint fee) external onlyOwner {
        nCommision = fee;
    }

    function setOwnerFee(uint fee) external onlyOwner {
        nfee = fee;
    }
    
    function withdrawFunds(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawTokens(address _token,uint amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender,amount);
    }

    receive() external payable {}

}