/**
 *Submitted for verification at snowtrace.io on 2022-04-06
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
    uint public payoutPeriod = 24 hours;
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

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    function upgrade(address _newImplementation) 
        external onlyDeployer 
    {
        require(implementation != _newImplementation);
        _setnew(_newImplementation);
    }
    function _setnew(address _newImp) internal {
        implementation = _newImp;
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
                    payout = (users[_addr].deposit_amount * ((users[_addr].last_withdraw + roiBlock - users[_addr].last_withdraw) / payoutPeriod) / 250);
                }
                else {
                    payout = (users[_addr].deposit_amount * ((users[_addr].last_withdraw + roiBlock - users[_addr].last_withdraw) / payoutPeriod) / 214);
                }
            }
            else {
                if(users[_addr].package == 1){
                    payout = (users[_addr].deposit_amount * ((now - users[_addr].last_withdraw) / payoutPeriod) / 250);
                }
                
                if(users[_addr].package == 2){
                    payout = (users[_addr].deposit_amount * ((now - users[_addr].last_withdraw) / payoutPeriod) / 214);
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
}