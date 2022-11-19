/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Match {
    
    event MatchBet(
        address addy, 
        uint amount, 
        string team1,
        uint score1,
        bool winner1,
        string team2,
        uint score2,
        bool winner2
    );

     struct Bet{
        address addy; 
        uint amount;
        string team1;
        uint score1;
        bool winner1;
        string team2;
        uint score2;
        bool winner2;
     }

    struct Result {
        string team1_r;
        uint score1_r;
        bool winner1_r;
        string team2_r;
        uint score2_r;
        bool winner2_r;
    }

    // Important addresses
    address payable private owner;
    address payable private admin;
    
    // Public vars
    address payable[] public bettors;        // holds all adresses
    mapping (address => Bet) public bets;    // maps adress to value and choice
    uint private bets_sum;
    string public match_id;
    string public team1;
    string public team2;
    uint public match_time;
    uint public closing_time;
    Result public result;
    bool public canceled;
    bool public finished;
    string public description;
    uint private winner_cut = 60;
    uint private perfect_score_cut = 10;
    uint private next_day_pot_cut = 10;
    uint private final_pot_cut = 5;
    uint private treasury_cut = 10;
    uint private founders_club_cut = 5;
    uint private winner_pot;
    uint private perfect_score_pot;
    uint private next_day_pot;
    uint private final_pot;
    uint private treasury_pot;
    uint private founders_club_pot;
    uint public min_bet;
    uint public pot;
    
    // Consts
    uint32 constant hour = 60*60;

    // Match constructor - this contract contains all bets which belongs to certain match
     constructor(string memory _match_id, address payable _admin, string memory _team1, string memory _team2, uint _match_time, uint _closing_time,
                string memory _description, uint _min_bet, uint32 _pot) {
        owner = payable(msg.sender);         // owning contract
        admin = _admin;             // set admin to prevent owning contract failure
        match_id = _match_id;
        team1 = _team1;
        team2 = _team2;
        match_time = _match_time;   // match start time
        closing_time = _closing_time;
        canceled = false;
        finished = false;
        //result = ("Qatar",1,false,"Ecuador",1,false);                // -1 unknown ... the rest corresponds to option
        /*winner_cut = _winner_cut;
        perfect_score_cut = _perfect_score_cut;
        next_day_pot_cut = _next_day_pot_cut;
        final_pot_cut = _final_pot_cut;
        treasury_cut = _treasury_cut;
        founders_club_cut = _founders_club_cut;*/
        //bet_option = _bet_option;
        //options_num = _options_num; // possible match results
        pot = _pot;
        description = _description;
        //dev_fee = _dev_fee;
        min_bet = _min_bet;
    }
    
    // ------------ USER FUNCTIONS -------------
    
    function bet(string memory _team1, uint32 _score1, bool _winner1, string memory _team2, uint32 _score2, bool _winner2) external payable {
        require(block.timestamp < closing_time && !canceled, "bet cannot be made now");
        require(_score1 >= 0 && _score2 >= 0, "impossible option");
        require(_winner1  && _winner2, "impossible option");
        require(msg.value >= min_bet, "too low bet");
        require(bets[msg.sender].amount == 0, "bet already made");
        
        uint256 funds = msg.value;          // dev fee
        if (bets[msg.sender].amount == 0){
            bets[msg.sender].amount = funds;
            bets[msg.sender].team1 = _team1;
            bets[msg.sender].score1 = _score1;
            bets[msg.sender].winner1 = _winner1;
            bets[msg.sender].team2 = _team2;
            bets[msg.sender].score2 = _score2;
            bets[msg.sender].winner1 = _winner1;

            bets_sum += funds;
            /* pot += (funds * (1-next_day_pot_cut-final_pot_cut-treasury_cut-founders_club_cut));
            winner_pot += (funds * winner_cut);
            perfect_score_pot += (funds * perfect_score_cut);
        
            next_day_pot += (funds * next_day_pot_cut);
            final_pot += (funds * final_pot_cut);
            treasury_pot += (funds * treasury_cut);
            founders_club_pot += (funds * founders_club_cut);

            bettors.push(msg.sender); */
            emit MatchBet(msg.sender, msg.value, _team1, _score1, _winner1, _team2, _score2, _winner2);
        } /*else {
            bets_sum[bets[msg.sender].option] -= bets[msg.sender].value;
            bets[msg.sender].value += funds;
            bets[msg.sender].option = option;
            bets_sum[option] += bets[msg.sender].value;
        }*/
    }
    
    //Review if is necessary
    function withdraw_funds() external {
        // you can withraw funds from match which did not start yet or has been canceled
        require(block.timestamp < closing_time || canceled, "funds cannot be withdrawn");
        
        uint return_value;
        if (canceled){
            return_value = bets[msg.sender].amount;  // return dev fee
        } else {
            return_value = bets[msg.sender].amount;
        }
        bets_sum -= bets[msg.sender].amount;
        pot -= bets[msg.sender].amount;
        bets[msg.sender].amount = 0;
       // msg.sender.transfer(return_value);
    }
    
    function claim_win() external {
        require(!finished && !canceled, "match is not finished");
        require(result.winner1_r == bets[msg.sender].winner1 && result.winner2_r == bets[msg.sender].winner2, "you are not a winner");
        //require(bets[msg.sender].value > 0, "your funds has been already withdrawn");
        
        uint winned_sum = 0;
        //uint winner_bet = bets[msg.sender].value; 
        /* for (uint8 i = 0; i < options_num; i++){
            if (i != uint8(result)) {
                uint option_win = bets_sum[i]*winner_bet/bets_sum[uint(result)];
                winned_sum += option_win;
                bets_sum[i] -= option_win;
            }
        } */
 //       winned_sum += bets[msg.sender].value;
        //bets_sum[uint(result)] -= winner_bet;
   //     bets[msg.sender].value = 0;
       // msg.sender.transfer(winned_sum*(dev_fee+10)/dev_fee);   // return 1% of fee
    }
    
    // ------------ ADMIN FUNCTIONS ------------
    
    // GETTERS
    
    function get_options_value() public view returns(uint) {
        return bets_sum;
    }
    
    function bets_sums() public view returns(uint) {
        uint sum = bets_sum;
        /* for (uint8 i = 0; i < options_num; i++) {
            sum += bets_sum[i];
        } */
        return sum;
    }
    
    function get_address_option(address addr) external view returns(int16) {
       /*  if (bets[addr].value > 0) {
            return bets[addr].option;
        } else {
            return -1;
        } */
    }
    
    function get_unpaid_winners_in_nth_100(uint32 n) public view returns(address payable[] memory) {
       /*  require(result >= 0, "no result - no unpaid winner");
        
        address payable[] memory ret = new address payable[](100);
        uint max_size = (n+1)*100;
        if (bettors.length < max_size){
            max_size = bettors.length;
        }
        for (uint32 i = n*100; i < max_size; i++){
            if (bets[bettors[i]].value > 0 && bets[bettors[i]].option == uint8(result)){
                ret[i] = bettors[i];
            }
        }
        return ret; */
    }
    
    function get_bettors_num() public view returns(uint32) {
        return uint32(bettors.length);
    }
    
    // SETTERS
    
    function set_result(uint8 _result) external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        //require(_result >= 0 && _result < options_num, "impossible result");
        require(match_time < block.timestamp, "match is not finished yet");
        require(!canceled, "match was canceled");
        //require(bets_sum[_result] > 0 && bets_sum[_result] < bets_sums());
        
        //result = int8(_result);
    }
    
    function cancel_match() external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");
        require(canceled == false, "the match is already canceled");
        //require(result < 0, "match has already result");
        
        canceled = true;
    }
    
    // CROWD CONTROL

    function return_funds(address payable recipient) external {
        // in case of canceling the match, this method return funds of certain address
        require(canceled, "match is not canceled, funds cannot be returned");
        
        //uint return_value = bets[recipient].value*1000/dev_fee;   // return dev_fee
       /*  bets_sum[bets[recipient].option] -= bets[recipient].value;
        bets[recipient].value = 0; */
        //recipient.transfer(return_value);
    }
    
    function payout(address payable winner) external {
       /*  require(result >= 0 && !canceled, "match is not finished");
        require(uint8(result) == bets[winner].option, "you are not a winner");
        require(bets[winner].value > 0, "your funds has been already withdrawn");
        require(now > match_time + 24*3*hour, "too soon to autopayout");
        
        uint winned_sum = 0;
        uint winner_bet = bets[msg.sender].value; 
        /* for (uint8 i = 0; i < options_num; i++){
            if (i != uint8(result)) {
                uint option_win = bets_sum[i]*winner_bet/bets_sum[uint(result)];
                winned_sum += option_win;
                bets_sum[i] -= option_win;
            }
        } 
        winned_sum += bets[winner].value;
        bets_sum[uint8(result)] -= bets[winner].value;
        bets[winner].value = 0;
        winner.transfer(winned_sum);      */   // this payout is triggered by admin, so there is no fee return
    }

    function close_contract() external {
        require(msg.sender == owner || msg.sender == admin, "only owner can call this");    
       // require(block.timestamp > match_time + hour*24*3 || bets_sum[uint8(result)] == 0, "match cannot be closed yet");
       // require(result >= 0 || canceled, "match was not resolved");
        
        selfdestruct(admin);
    }
}

contract GambitBet {
    address payable private admin;
    mapping (string => Match) public matches;
    uint32 public dev_fee;
    uint public min_bet;
    
    // Parent contract constructor
    constructor() {
        admin = payable(msg.sender);
        dev_fee = 975;
        min_bet = 1 ether;
    }
    
    // method for initialisation of match, match_time is in UTC unix time in sec
    function init_match(uint match_time, uint closing_time, uint8 options_num, string calldata description, string memory _id) external {
        require(msg.sender == admin, "only owner can call this");
        require(options_num > 1, "every match must have at least two stacks");
        require(closing_time <= match_time - 3600, "wrong match times");
        //require(matches[_id] == Match(0), "match with this id already exists");
        
        matches[_id] = new Match(_id, admin, "Qatar", "Ecuador", match_time, closing_time, 
                                 description, min_bet, 1);
    }

    // SETTERS
    function set_dev_fee(uint32 _dev_fee) external {
        require(msg.sender == admin, "only owner can call this");
        require(_dev_fee > 500 && dev_fee < 1000, "should be in mille");

        dev_fee = _dev_fee;
    }

    function set_min_bet(uint _min_bet) external {
        require(msg.sender == admin, "only owner can call this");
        require(_min_bet > 1 ether, "this would be very small bet");
        
        min_bet = _min_bet;
    }
    
    // GETTERS
   /*  function get_my_options(uint32[] calldata _id) external view returns(int16[] memory) {
        uint size = _id.length;
        int16[] memory ret = new int16[](size);
        for (uint32 i = 0; i < size; i++) {
            if (matches[_id[i]].match_time() != 0) {     
                ret[i] = matches[_id[i]].get_address_option(msg.sender);
            } else {
                ret[i] = -2;     // return -2 because match with this is is already destructed
            }
        }
        return ret;
    } */
    
    // DESTROY CONTRACTS
    function close_match(string memory _id) external{
        require(msg.sender == admin, "only owner can call this");
        
        matches[_id].close_contract();
        delete matches[_id];
    }
    
    function close_contract() external {
        require(msg.sender == admin, "only owner can call this");
        
        selfdestruct(admin);
    }
}