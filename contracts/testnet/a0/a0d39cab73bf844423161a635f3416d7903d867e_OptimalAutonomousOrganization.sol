/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */


 interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract OptimalAutonomousOrganization {



  

     // Mapping from seat ID to owner address
    mapping(uint256 => address) public _owners;

    // Mapping owner address to seat count
    mapping(address => uint256) public _balances;

    mapping(address => uint256) public allowance; //CEO's weekly withdrawl limits for various treasury tokens

    mapping(address => uint256) public lastWithdrawal; //last time particular asset was withdrawn

    enum ACTION {hire, fire, empty, fill, weekly}

    address ceo;
    uint threshold; //how many votes before action execution

    uint nonEmptySeats; //number of filled seats
    

    uint voteIndex; //number of votes board has held
    
    struct Vote {
        ACTION action; //action board is voting on
        uint256 ID;    //seat ID or allowance amount
        address owner; //address of ceo/boardmember or token
        uint256[12] tally; //record of votes. 1 = yes 0 = no. default one every vote is no
        bool open;         //if true members can still vote or change vote

    }

    mapping(uint256 => Vote) public votes;
    
    
    
    constructor(address owner0, address owner1, address owner2, address owner3, address owner4) {
       _owners[0] = owner0;
       _owners[1] = owner1;
       _owners[2] = owner2;
       _owners[3] = owner3;
       _owners[4] = owner4;
        voteIndex = 0;
        ceo = address(0);
        threshold = 4;

        _balances[owner0] = 1;
        _balances[owner1] = 1;
        _balances[owner2] = 1;
        _balances[owner3] = 1;
        _balances[owner4] = 1;
    }

    //public board member functions

    
    function transferSeat(address newOwner, uint256 ID) public {
        require(newOwner != address(0));
        require(msg.sender == _owners[ID]);
        require(_balances[newOwner] == 0);
        _owners[ID] = newOwner;
        _balances[msg.sender] -= 1;
        _balances[newOwner] += 1;
    }

    function openVote(ACTION _action, uint256 _ID, address _owner) public {
        require(_balances[msg.sender] == 1);
        votes[voteIndex] = Vote({
            action : _action,
            ID : _ID, // weekly allowance or seat ID
            owner : _owner, // token address (zero for avax) or person being hired/fired
            tally : [uint256(0),0,0,0,0,0,0,0,0,0,0,0],
            open : true

        });
        voteIndex ++;
        
    }

    function castVote(uint _voteIndex, uint _vote, uint256 _voterID) public{
        require(votes[_voteIndex].open==true);
        require(_owners[_voterID] == msg.sender);
        votes[_voteIndex].tally[_voterID]=_vote;
        
    }

    function countVotes(uint _voteIndex) public {
        uint256 count =0;
        for(uint256 i = 0; i < 12; i ++){
            count += votes[_voteIndex].tally[i];
        }
        if(count >= threshold){
            execute(_voteIndex);
            votes[_voteIndex].open = false;
        }

    }

    //Internal Functions. Executed after vote.

    function emptySeat(address owner, uint256 ID) internal {
        _owners[ID] = address(0);
        _balances[owner] -= 1;
        nonEmptySeats = getNonEmpty();
        threshold = getThreshold();
    }

    function fillSeat(address owner, uint256 ID) internal {
        require(_owners[ID] == address(0));
        require(_balances[owner] == 0);
        require(owner != ceo);
        _owners[ID] = owner;
        _balances[owner] += 1;
        nonEmptySeats = getNonEmpty();
        threshold = getThreshold();
    }

    function hireCEO(address newCEO) internal {
        require(_balances[newCEO] == 0);
        require( newCEO != address(0));
        ceo = newCEO;
    }

    function fireCEO() internal {
        ceo = address(0);
    }

   function setWeekly(address token, uint256 _allowance) internal {
       allowance[token] = _allowance;
   }


    


    function execute(uint _voteIndex) internal {
        ACTION action_ = votes[_voteIndex].action;

        if(action_ == ACTION.hire){
            hireCEO(votes[_voteIndex].owner);

        }else if(action_ == ACTION.fire){
            fireCEO();

        }else if(action_ == ACTION.empty){
            emptySeat(votes[_voteIndex].owner,votes[_voteIndex].ID);

        }else if(action_ == ACTION.fill){
            fillSeat(votes[_voteIndex].owner,votes[_voteIndex].ID);

        }else if(action_ == ACTION.weekly){
            setWeekly(votes[_voteIndex].owner, votes[_voteIndex].ID);
        }
    }


    //public view functions

    function getThreshold() public view returns (uint threshold_) {
        threshold_ = nonEmptySeats * 10 / 8;

    }

    function getNonEmpty() public view returns (uint nonEmpty_){
        for(uint i=0; i< 12; i++){
            if( _owners[i]==address(0)){
                nonEmpty_ ++;
            }
        }
    }

    //CEO functions

    function withdrawERC20(address _token, uint256 _amount) public {
        require(msg.sender == ceo);
        require(!isContract(msg.sender));
        require(_amount <= allowance[_token]); //weekly withdrawal limit
        require(uint256(block.timestamp)-lastWithdrawal[address(_token)] >= 60*60*24*7); //one withdrawal per week per asset
        IERC20(_token).transfer(ceo, _amount);
        lastWithdrawal[_token] = uint256(block.timestamp);
    }

    function withdrawAVAX(uint256 _amount) public {
        require(msg.sender == ceo);
        require(!isContract(msg.sender));
        require(_amount <= allowance[address(0)]);
        require(uint256(block.timestamp)-lastWithdrawal[address(0)] >= 60*60*24*7);
        payable(ceo).transfer(_amount);
        lastWithdrawal[address(0)] = uint256(block.timestamp);

    }

    function depositAVAX() public payable{}

    //The internet told me this function was scary but I'm using it anyway! 
    //I didn't want the board to have the power to elect a multisig in their control as ceo

    function isContract(address addr) internal view returns (bool) {
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    bytes32 codehash;
    assembly {
        codehash := extcodehash(addr)
    }
    return (codehash != 0x0 && codehash != accountHash);
}





}