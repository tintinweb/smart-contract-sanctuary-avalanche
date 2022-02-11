/**
 *Submitted for verification at snowtrace.io on 2022-01-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract instaDAO {

    /// @dev Security tweaks

    bool locked;

    address owner;

    modifier onlyOwner () {
        require(msg.sender==owner, "Stop right there criminal scum!");
        _;
    }

    modifier safe () {
        require(!locked, "Reentrancy!");
        locked = true;
        _;
        locked = false;
    }

    mapping(address => bool) is_free;

    /// @dev Events
    event paid(address from, uint256 value);
    event NewDao(string name, uint256 id, address founder);
    event closedVote(uint256 id, uint256 vote_id, bool side);
    event newVote(uint256 id, uint256 vote_id, uint256 startingblock, uint256 endingblock);

    /// @dev General assumptions

    uint256 public _native_decimals = 10**18;
    uint256 public _price_to_create = 50 * _native_decimals; // 50 FTM for example

    /// @dev Structures
    
    struct VOTE {
        string name;
        address creator;
        uint256 id;
        uint256 yes;
        uint256 no;
        uint256 startingblock;
        uint256 endingblock;
        bool exists;
        bool closed;
        bool approved;
        mapping(address => bool) has_voted;
    }

    struct DAO {
        IERC20 token;
        string name;
        bool exists;
        address founder;
        mapping (address => bool) owner;
        mapping (address => bool) authorized;
        mapping (uint256 => VOTE) votes;
        uint256 last_vote_id;
        uint256 total_shares;
        uint256 proposal_treshold;
    }

    mapping(uint256 => DAO) public daos;
    mapping(address => uint256[]) user_daos;
    uint256 public last_id = 0;

    mapping(uint256 => bool) public is_federated;

    constructor() {
        owner = msg.sender;
        is_free[owner] = true;
    }

    /// @dev Public views

    function get_dao(uint256 id) public view returns (
        address,
        string memory,
        bool,
        address,
        uint256,
        uint256,
        uint256
    ) {
        return (
            address(
                daos[id].token),
                daos[id].name,
                daos[id].exists,
                daos[id].founder,
                daos[id].last_vote_id,
                daos[id].total_shares,
                daos[id].proposal_treshold
        );
    }

    function get_dao_founder(uint256 id) public view returns (address ) {
        require(daos[id].exists, "Not existant");
        return daos[id].founder;
    }

    function get_my_daos(address addy) public view returns (uint256[] memory) {
        return user_daos[addy];
    }

    function get_vote(uint256 id, uint256 vote_id) public view returns (
        string memory,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        bool,
        bool
    ) {
        VOTE storage this_vote  = daos[id].votes[vote_id];
        return (
            this_vote.name,
            this_vote.creator,
            this_vote.yes,
            this_vote.no,
            this_vote.startingblock,
            this_vote.endingblock,
            this_vote.closed,
            this_vote.approved
        );
    }

    /// @dev Public interactions

    function create_dao(string memory name, address token, address[] memory owners, address[] memory authorizeds, uint256 treshold) public payable safe {
        if(!is_free[msg.sender]) {
            require(msg.value == _price_to_create, "Wrong price, you tried!");
            _new_dao(name, token, owners, authorizeds, msg.sender, treshold);
        }
    }
    
    function delete_dao(uint256 id) public safe {
        require(daos[id].exists, "The DAO does not exist");
        require(msg.sender==daos[id].founder);
        delete daos[id];        
    }

    function dao_get_shares(uint256 id, address addy)  public view returns (uint256) {
        require(daos[id].exists, "The DAO does not exist");
        uint256 updated_shares = (daos[id].token.balanceOf(addy) * 1000) / daos[id].token.totalSupply(); // Shares are from 1 to 1000
        return updated_shares;
    }

    function dao_create_vote(string memory name, uint256 id, uint256 block_to_start, uint256 block_to_end) safe public {
        require(daos[id].exists, "The DAO does not exist");
        require(dao_get_shares(id, msg.sender) >= daos[id].proposal_treshold, "Unauthorized");
        daos[id].votes[daos[id].last_vote_id].name = name;
        daos[id].votes[daos[id].last_vote_id].startingblock = block_to_start;
        daos[id].votes[daos[id].last_vote_id].endingblock = block_to_end;
        daos[id].votes[daos[id].last_vote_id].id = daos[id].last_vote_id;
        daos[id].votes[daos[id].last_vote_id].creator = msg.sender;
        daos[id].last_vote_id++;
    }

    function dao_vote(uint256 id, uint256 vote_id, bool side) safe public returns (bool) {
        require(daos[id].exists, "The DAO does not exist");
        require(daos[id].votes[vote_id].exists, "The DAO voting does not exist");
        require(!daos[id].votes[vote_id].closed, "The DAO voting is closed");
        require(daos[id].votes[vote_id].startingblock <= block.number, "The DAO voting isn't started");
        require(daos[id].votes[vote_id].endingblock > block.number, "The DAO voting is finished");
        require(!daos[id].votes[vote_id].has_voted[msg.sender], "You already voted");
        if(side) {
            daos[id].votes[vote_id].yes += dao_get_shares(id, msg.sender);
            if(daos[id].votes[vote_id].no >= (daos[id].total_shares/2)) {
                _vote_end(id, vote_id, true);
            }   
        } else {
            daos[id].votes[vote_id].no += dao_get_shares(id, msg.sender);
            if(daos[id].votes[vote_id].no >= (daos[id].total_shares/2)) {
                _vote_end(id, vote_id, false);
            }   
        }
        daos[id].votes[vote_id].has_voted[msg.sender] = true;
        return daos[id].votes[vote_id].closed;
    }


    /// @dev DAO controls

    function dao_set_treshold(uint256 id, uint256 treshold) public {
        require(daos[id].exists, "DAO does not exist");
        require(daos[id].founder==msg.sender || daos[id].owner[msg.sender] || daos[id].authorized[msg.sender], "Unauthorized");
        daos[id].proposal_treshold = treshold;
    }
    
    function dao_set_owner(uint256 id, address addy, bool booly) public {
        require(daos[id].exists, "DAO does not exist");
        require(daos[id].founder==msg.sender || daos[id].owner[msg.sender], "Unauthorized");
        daos[id].owner[addy] = booly;
    }

    function dao_set_authorized(uint256 id, address addy, bool booly) public {
        require(daos[id].exists, "DAO does not exist");
        require(daos[id].founder==msg.sender || daos[id].owner[msg.sender] || daos[id].authorized[msg.sender], "Unauthorized");
        daos[id].authorized[addy] = booly;
    }



    /// @dev Private interactions

    function _new_dao(
        string memory name, 
        address token, 
        address[] memory owners, 
        address[] memory authorizeds, 
        address founder, 
        uint256 treshold
        ) private returns (uint256){

            daos[last_id].exists = true;
            daos[last_id].name = name;
            daos[last_id].founder = founder;
            daos[last_id].token = IERC20(token);
            for(uint256 i=0; i<owners.length; i++) {
                daos[last_id].owner[owners[i]] = true;
            }
            for(uint256 o=0; o<owners.length; o++) {
                daos[last_id].authorized[authorizeds[o]] = true;
            }
            daos[last_id].proposal_treshold = treshold;
            user_daos[msg.sender].push(last_id);
            last_id++;
            return (last_id-1);
    }

    function _vote_end(uint256 id, uint256 voting_id, bool side) private {
        daos[id].votes[voting_id].closed = true;
        daos[id].votes[voting_id].approved = side;
    }

    /// @dev Contract Administration

    function set_price(uint256 price) public onlyOwner {
        _price_to_create = price*_native_decimals;
    }

    function set_free(address addy, bool booly) public onlyOwner {
        is_free[addy] = booly;
    }

    function retrieve_payments() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function harakiri() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

     receive() external payable {
            emit paid(msg.sender, msg.value);
        }

}