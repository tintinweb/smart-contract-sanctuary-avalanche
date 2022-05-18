/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-17
*/

// File: contracts/RebaseToken.sol


pragma solidity ^0.8.0;

contract RebaseTKN {
    
    address public owner;
    address public casino;

    uint internal constant maxNo = type(uint).max;   // IMMUTABLE
    uint internal constant maxTKN = type(uint).max;  // IMMUTABLE
    uint internal tot_frag;                          // IMMUTABLE
    uint internal _fragXTKN;
    uint public reward;
    uint public sup; // Initial Genesys Mint
    uint internal conv;
    uint internal decimals;

    string public name = "Miyamoto";
    string public sym = "MYA";

    mapping(address => uint) internal _fragBal;
    mapping(address => uint) internal _claims;

    event trans(address indexed from, address indexed to, uint256 value);

    modifier onlyOwn {
        require(msg.sender == owner, "You are not the Owner"); _;
    }

    constructor() {
        owner = msg.sender;
        casino = 0xcD14a0db9e3AD695b3226c3e7264cCBe1da5EBed;
        decimals = 18;
        conv = 100; // Each wei is this much TKN, would mean 0.01 ETH is equal 1TKN
        sup = 1 * 10**9 * 10**decimals; // Initial Genesys Mint 1 Billion with 18 decimals tot 27 zeros
        tot_frag = maxNo - (maxNo % sup);
        _fragBal[owner] = tot_frag;
        _fragXTKN = tot_frag / sup;
        reward = (sup * 821532) / 100000000; // 0.821532 (3 a day) rebase % to give a 777,777% Fixed APY for 1 Year Only!!!
    }

    /**
    Buy tokens with or ETH/BNB/AVAX
    Adds amount of claimable tokens to the buyer balance.
    The clamiable tokens, must be calimed before they 
    show as a user Token balance.
    Returns True is transaction succesfull.
    */
    function buy() public payable {
        uint claims = msg.value * conv;
        _claims[msg.sender] += claims;
        transFrom(owner,msg.sender,_claims[msg.sender]);
    }

    /**
    Checks the funds recived in the contract.
    Returns contract balance.
    */
    function checkContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
    Withdraw functions
    Reutrns true if succesfull.
    */
    function withdrow(address payable _to ) public payable onlyOwn() {
        _to.transfer(address(this).balance);
    }

    /**
    Returns user token balance.
    */
    function bal(address who) public view returns (uint) {
        return _fragBal[who] / _fragXTKN ;
    }

    /**
    Rebse function.
    Rebase by adding the APY reward, and 
    recreate a new reward based on the compouning
    process of the previous epoch.
    Returns Total Supply.
    */
    function rebase() public onlyOwn() returns (uint) {
        if (reward == 0) {return sup;}
        if (reward < 0) { sup = sup- uint(reward);}
        else { sup = sup + uint(reward);}
        if (sup > maxTKN) { sup = maxTKN;}
        _fragXTKN = tot_frag / sup;
        reward = (sup * 821532) / 100000000;
        return sup;
    }

    /**
    Buy tokens with or ETH/BNB/AVAX
    Adds amount of claimable tokens to the buyer balance.
    The clamiable tokens, must be calimed before they 
    show as a user Token balance.
    Returns True is transaction succesfull.
    */    
    function transf(address to, uint value) public returns (bool) {
        uint fragVal = value * _fragXTKN;
        _fragBal[msg.sender] = _fragBal[msg.sender] - fragVal;
        _fragBal[to] = _fragBal[to] + fragVal;
        emit trans(msg.sender, to, value);
        return true;
    }

    /**
    Transfer "Tokens" from address to address.
    Returns True is transaction succesfull.
    Returns true if transaction succesfull.
    */
    function transFrom(address from, address to, uint value) public returns (bool) {
        require(owner == msg.sender || _claims[msg.sender] >= value, "Not Owner or NO enough claimable"); 
        uint fragVal = value * _fragXTKN;
        _fragBal[from] = _fragBal[from] - fragVal;
        _fragBal[to] = _fragBal[to] + fragVal;
        _claims[msg.sender] -= value;
        emit trans(from, to, value);
        return true;
    }
}
    //event chk(string _info,address owner,address MSGsender,address indexed from, address indexed to, uint256 value);
    //emit chk("THIS IS TRANSFER FROM: OWNER-MSGSENDER-FROM-TO-AMT", owner, msg.sender,from, to, value);
// File: contracts/GameMaster.sol


pragma solidity ^0.8.0;


contract GMaster is RebaseTKN {

    uint private gCount; 
    //event gCreated(string _info, address _by,  uint _gIdx, string _gName, bool _gActive,uint _time);
    //event gRes(string _info, address _by, uint _gIdx, string _gName, bool _gActive, bool _resA, bool _resB, bool _resC);  
    
    mapping(uint => g) public _gByIdx;
    
    struct g {
        string gName;
        bool gActive;
        bool _resA;
        bool _resB;
        bool _resC;
        uint gTime;
        bool gCreated;
    }
    
    // Initialize game creation by assigning game name.
    function creatG(string memory _gName) public 
        onlyOwn() returns(uint, string memory, bool, uint){
        _gByIdx[gCount].gCreated = true;
        _gByIdx[gCount].gName = _gName;
        _gByIdx[gCount].gActive = true;
        _gByIdx[gCount].gTime = block.timestamp;
        gCount++;
        return((gCount-1), _gName, true, block.timestamp);
    }

    // Post game results.
    function postRes(uint _gIdx, uint _res) public 
        onlyOwn() returns(uint, string memory, bool, bool,bool,bool,uint) { 
        require(_res == 1 || _res == 2 || _res == 3,"Wrong input number!!! Only 1,2 or 3.");
        if (_res == 1) {_gByIdx[_gIdx]._resA = true;}
        else if (_res == 2) {_gByIdx[_gIdx]._resB = true;}
        else if (_res == 3) {_gByIdx[_gIdx]._resC = true;}
        else {revert("Wrong input number!!! Only 1,2 or 3.");}
        _gByIdx[_gIdx].gActive = false;
        return (_gIdx, _gByIdx[_gIdx].gName, _gByIdx[_gIdx].gActive, _gByIdx[_gIdx]._resA,
         _gByIdx[_gIdx]._resB, _gByIdx[_gIdx]._resC, block.timestamp);
    }

    function checkRes(uint _gIdx) public view
        returns(uint, string memory, bool, bool, bool, bool, uint) {
        require(_gByIdx[_gIdx].gCreated == true, "Game not created yet!!!"); 
        require(_gByIdx[_gIdx].gActive == false, "Game results not posted yet or game not active!!!");
        return (_gIdx, _gByIdx[_gIdx].gName, _gByIdx[_gIdx].gActive, _gByIdx[_gIdx]._resA,
        _gByIdx[_gIdx]._resB, _gByIdx[_gIdx]._resC, block.timestamp);
    }
}

/**
Must add only owner.
Must add pausable.
Must add Access control.
Additional I could place a contructor to emit something when game gets created
*/
// File: contracts/Utils.sol


pragma solidity ^0.8.0;

contract Utils {

    /**
    Returns the hased version of string.
    */
    function hash(string memory _string) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_string));
    }
    
    /**
    Compares 2 string to see if they are identical.
    This function is used to check the user input selection
    to be a valid selection (A,B,C).
    Returns the result selected.
    */    
    function compare(string memory _choice) internal pure returns(uint _result) {
        if (hash("A") == hash(_choice) ) {_result = 1;}
        else if (hash("B") == hash(_choice) ) {_result = 2;}
        else if (hash("C") == hash(_choice) ) {_result = 3;}
        else {revert("Wrong selection, only A,B,C!");}
        return _result;
    }

    //rounds to zero if x*y < WAD / 2
    uint constant WAD = 10 ** 18;
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}
// File: contracts/Play.sol


pragma solidity ^0.8.0;




contract Play is RebaseTKN, GMaster, Utils {
    mapping (address => mapping(uint => bet)) public bets;
    mapping (uint => totWaged) public waged;

    struct totWaged {
        uint _totWaged;
        uint _totA;
        uint _totB;
        uint _totC;
        bool _none;
        uint _toDistrib;
    }

    struct bet {
        uint _wage;
        uint _gIndex;
        bool _predictA;
        bool _predictB;
        bool _predictC;
        bool _none;
        uint _toCashOut;
    }

    /**
    User place bet on a game.
    The user can only select one winner letter.
    The user bets then get updated, as well
    as the total wage amount for later calculation
    porposes.
    Returns True if succesfull. 
    */
    function betOn(uint _wage, uint _gIndex, string memory _select) public returns (bool) {
        require(_fragBal[msg.sender] > 0,"You don't have any tokens");
        require(_gByIdx[_gIndex].gActive == true, "This game has ended!!!"); // Test it
        uint wageVal = _wage * _fragXTKN; 
        _fragBal[msg.sender] = _fragBal[msg.sender] - wageVal;
        _fragBal[casino] = _fragBal[casino] + wageVal;

        // Updating Player bets Struct
        bets[msg.sender][_gIndex]._wage += _wage;
        bets[msg.sender][_gIndex]._gIndex = _gIndex;
        if (compare(_select) == 1) {bets[msg.sender][_gIndex]._predictA = true;}
        else if (compare(_select) == 2) {bets[msg.sender][_gIndex]._predictB = true;}
        else if (compare(_select) == 3) {bets[msg.sender][_gIndex]._predictC = true;}
        else {bets[msg.sender][_gIndex]._none = true;} // Maybe fix this first
        
        // Updating Game Weges Assignment 
        waged[_gIndex]._totWaged += _wage;
        if (compare(_select) == 1) {waged[_gIndex]._totA += _wage;}
        else if (compare(_select) == 2) {waged[_gIndex]._totB += _wage;}
        else if (compare(_select) == 3) {waged[_gIndex]._totC += _wage;}
        else {waged[_gIndex]._none = true;}

        emit trans(msg.sender, casino, _wage);
        return true;
    }

    /**
    User checks the bet done by the user.
    It only works after having betted.
    Returns the bet inforamtions from the user database. 
    */
    function usrBet(uint _gIndex) public view returns(bet memory){
        require(_gByIdx[_gIndex].gCreated == true, "Game not exsisting / no bets placed!!!");
        return bets[msg.sender][_gIndex];
    }

    /**
    Generate stats for the game with
    claulcations for ditribution of wins/losses
    It only works after having betted.
    Returns the bet inforamtions from the user database. 
    */
    function gameStats(uint _gIndex) public onlyOwn() returns(uint, uint, uint){
        uint _losTotAmt;
        uint _winTotAmt;
        uint _distrLos;
        // Calculating wins and losses amounts
        if (_gByIdx[_gIndex]._resA == true) {_winTotAmt += waged[_gIndex]._totA;}           // Test it  
        else if (_gByIdx[_gIndex]._resB == true) {_winTotAmt += waged[_gIndex]._totB;}      // Test it
        else if (_gByIdx[_gIndex]._resC == true) {_winTotAmt += waged[_gIndex]._totC;}      // Test it
        else {revert("No valide results found!!!");}                                        // Test it
        _losTotAmt = waged[_gIndex]._totWaged - _winTotAmt;
        // Calculating the winning amount to distribute to winners
        if (_losTotAmt == 0 || _winTotAmt == 0) {_distrLos = 0;}
        else if (_losTotAmt > _winTotAmt) {_distrLos = wdiv(_losTotAmt,_winTotAmt);} 
        else {_distrLos = wdiv(_losTotAmt,_winTotAmt);} 
        waged[_gIndex]._toDistrib = _distrLos;
        return (_winTotAmt, _losTotAmt, _distrLos);
    }

    /**
    Checks if the user has won or not, if
    the user won, will generate info about the game
    such as money won, etc.
    Returns info about user bet.
    */
    function check(uint _gIndex) public  returns(uint,uint,uint,uint,uint) {
        require(checkIfWon(_gIndex) == true,"You did not win!!!");
        uint _betted = bets[msg.sender][_gIndex]._wage;
        uint _toDist = waged[_gIndex]._toDistrib;
        uint _amtWon = (bets[msg.sender][_gIndex]._wage * _toDist) / (10 ** 18);
        uint _toCashOut = _amtWon + _betted;
        if (_toCashOut > bal(casino)) {_toCashOut = bal(casino);} 
        else if (_toCashOut <= bal(casino)) {bets[msg.sender][_gIndex]._toCashOut = _toCashOut;}
        else{bets[msg.sender][_gIndex]._toCashOut = _toCashOut;}
        bets[msg.sender][_gIndex]._toCashOut = _toCashOut;
        return (_betted, _toDist, _amtWon, _toCashOut, bets[msg.sender][_gIndex]._toCashOut);
    }

    /**
    Simply check if you won or not.
    Returns true is won, false if lost.
    */
    function checkIfWon(uint _gIndex) public view returns(bool){
        require(_gByIdx[_gIndex].gCreated == true, "Game not exsisting!!!");
        require(_gByIdx[_gIndex].gActive == false, "Game not finished or results not posted yet!!!");
        if (bets[msg.sender][_gIndex]._predictA == _gByIdx[_gIndex]._resA &&
        bets[msg.sender][_gIndex]._predictB == _gByIdx[_gIndex]._resB &&
        bets[msg.sender][_gIndex]._predictC == _gByIdx[_gIndex]._resC) 
        {return true;}
        else {return false;}
    }
    
    /**
    Cashes out the winning for the user
    by transferring back his principal plus
    winning in the rebasing wallet.
    Returns true if succesfull.
    */
    function cashOut(uint _gIndex) public returns (bool) {
        require(owner == msg.sender || bets[msg.sender][_gIndex]._wage > 0, "You did not place any bet"); // Wrong the user should be able to chash out
        require(checkIfWon(_gIndex) == true, "You did not win anything, nothing to cash out!!!");
        uint fragVal = bets[msg.sender][0]._toCashOut * _fragXTKN; // need to change name to wageVal
        _fragBal[casino] = _fragBal[casino] - fragVal;
        _fragBal[msg.sender] = _fragBal[msg.sender] + fragVal;
        emit trans(casino, msg.sender, bets[msg.sender][_gIndex]._toCashOut);
        return true;
    }
}

/**
Personal notes:

*/