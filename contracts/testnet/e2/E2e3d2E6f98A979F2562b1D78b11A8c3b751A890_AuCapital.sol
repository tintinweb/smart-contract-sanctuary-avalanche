// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IAuthCenter.sol";
import "./IAuCapital.sol";

contract AuCapital is IAuCapital {
    address private owner;
    address private authCenter;

    // dynamic only growing array of capitals
    TCapital[] private capitals;

    // buyer Tx record
    struct TBuyerTx {
        address buyerAddress;  // buyer address
        uint256 purchasedAmount; // amount of purchased tokens
    }
    // mapping capitalIdx => buyer ordered num (0 key - number of buyers) => buyer Tx record
    mapping (uint256 => mapping(uint256 => TBuyerTx)) private buyers;

    // mapping tokenIdx => token metadata
    mapping (uint256 => TToken) private tokens;

    // owner address => token index => amount
    mapping(address => mapping(uint256 => uint256)) private balances;

    // owner address => token index => blocked amount
    mapping(address => mapping(uint256 => uint256)) private blocked;

    // owner => operator => full allowance trigger
    mapping(address => mapping(address => bool)) private allowances;

    //---------------------------------------------------------------
    
    // @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "AuCapital: You are not contract owner");
        _;
    }
    
    // @dev Throws if authCenter is zero address
    modifier onlyAuthCenter() {
        require(address(authCenter) != address(0),
                "AuCapital: AuthCenter is the zero address");
        _;
    }

    // @dev Access modifier for admin-only functionality
    modifier onlyAdmins() {
        require(IAuthCenter(authCenter).isAdmin(msg.sender), 
                "AuCapital: You are not admin");
        _;
    }

    // @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!IAuthCenter(authCenter).isContractPaused(address(this)),
                "AuCapital: contract paused");
        _;
    }

    // @dev Access modifier for client-only functionality
    modifier onlyClients() {
        require(IAuthCenter(authCenter).isClient(msg.sender), 
                "AuCapital: You are not our client");
        _;
    }

    // @dev Access modifier for approved persons and admins only functionality
    modifier onlyApproved(address _from) {
        require(_from == msg.sender || allowances[_from][msg.sender] ||
                IAuthCenter(authCenter).isAdmin(msg.sender),
                "AuCapital: You are not approved to action");
        _;
    }
    //---------------------------------------------------------------

    constructor () { owner = msg.sender; }

    function updateOwner(address _address) external onlyOwner override returns (bool) {
        owner = _address;
        emit UpdateOwner(_address);
        return true;
    }

    // @dev some gas ethers need for a normal work of this contract (calls to AuthCenter).
    // Only owner can put ethers to contract.
    receive() external onlyOwner payable {}

    // @dev Only owner can return to himself gas ethers before closing contract
    function withDrawAll() external onlyOwner override
    { payable(owner).transfer(address(this).balance); }

    // @dev Link AuthCenter to contract
    function setAuthCenter(address _address) external onlyOwner override returns (bool) {
        require(_address != address(0), "AuCapital: authCenter == zero address");
        authCenter = _address;
        return true;
    }

    // @dev check contract paused 
    function isPaused() external view onlyAuthCenter override returns (bool) {
        return IAuthCenter(authCenter).isContractPaused(address(this));
    }

    //---------------------------------------------------------------
    // Get all token's params
    function getTokenParams(uint256 _tokenIdx) external view override returns(TToken memory)
    { return tokens[_tokenIdx]; }

    // Get the valid(=true) or invalid(=false) state of the token.
    function isValid(uint256 _tokenIdx) external view override returns (bool)
    { return tokens[_tokenIdx].valid; }

    // @dev only admins can change the token state
    function setValid(uint256 _tokenIdx, bool _value) external onlyAuthCenter onlyAdmins override returns (bool) {
        tokens[_tokenIdx].valid = _value;
        return true;
    }

    // Enable or disable approval for a third party ("operator") to manage account
    // generate ApprovalForAll(msg.sender, _operator, _approved) event
    function setApprovalForAll(address _operator, bool _approved) external onlyAuthCenter whenNotPaused onlyClients override returns (bool) {
        allowances[msg.sender][_operator] = _approved; 
        emit ApprovalForAll(msg.sender, _operator, _approved);
        return true;
    }

    // Queries the approval status of an operator for a given owner.
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool)
    { return allowances[_owner][_operator]; }

    // Get the balance of an account's tokens.
    function balanceOf(address _owner, uint256 _tokenIdx) external view override returns (uint256)
    { return balances[_owner][_tokenIdx]; }

    // Get the blocked balance of an account's tokens.
    function blockedOf(address _owner, uint256 _tokenIdx) external view override returns (uint256)
    { return blocked[_owner][_tokenIdx]; }

    // Block or unlock some clients tokens.
    // only admins can block clients tokens,
    // emit BlockTokensEvent(msg.sender, _owner, _tokenIdx, _value, true) event
    function blockTokens(address _owner, uint256 _tokenIdx, uint256 _value, bool _action, bool _actionAll) external
        onlyAuthCenter onlyAdmins override returns (bool)
    {
        if (_actionAll)
            if (_action) _value = balances[_owner][_tokenIdx] - blocked[_owner][_tokenIdx];
            else _value = blocked[_owner][_tokenIdx];

        if (_action) {
            require(balances[_owner][_tokenIdx] - blocked[_owner][_tokenIdx] >= _value);
            blocked[_owner][_tokenIdx] += _value;
        } else {
            require(blocked[_owner][_tokenIdx] >= _value);
            blocked[_owner][_tokenIdx] -= _value;
        }

        emit BlockTokensEvent(msg.sender, _owner, _tokenIdx, _value, _action);
        return true;
    }

    // mint tokens to clients
    // NOTE: only admins can mint,
    //     emit Transfer(msg.sender, address(0), _to, _tokenIdx, _value) event
    function mint(address _to, uint256 _tokenIdx, uint256 _value) external onlyAuthCenter onlyAdmins override returns(bool) {
        balances[_to][_tokenIdx] += _value;
        emit Transfer(msg.sender, address(0), _to, _tokenIdx, _value);
        return true;
    }

    // burn client's tokens
    // NOTE: only token's owner==_address and admins can burn,
    // emit Transfer(msg.sender, _address, address(0), _tokenIdx, _value) event
    function burn(address _address, uint256 _tokenIdx, uint256 _value) external
        onlyAuthCenter whenNotPaused onlyApproved(_address)
        override returns(bool)
    {
        require(_value >= 0);
        uint256 balance = balances[_address][_tokenIdx] - blocked[_address][_tokenIdx];
        require(balance >= _value, "AuCapital: address have not so much free tokens");

        balances[_address][_tokenIdx] -= _value;

        emit Transfer(msg.sender, _address, address(0), _tokenIdx, _value);
        return true;
    }

    // only admins can create tokens
    // generate 'TokenCreate(args)' event
    function tokenCreate(
        uint256 _tokenIdx,          // key index of new token
        string memory _tokenName,   // long token name
        string memory _tokenSymbol, // short token name
        string memory _tokenUri     // token's URI
    ) external onlyAuthCenter onlyAdmins override returns (bool) {
        tokens[_tokenIdx].name    = _tokenName;
        tokens[_tokenIdx].symbol  = _tokenSymbol;
        tokens[_tokenIdx].uri     = _tokenUri;
        tokens[_tokenIdx].valid   = true;
        emit TokenCreate(_tokenIdx, msg.sender);//, _tokenName, _tokenSymbol, _tokenUri);
        return true;
    }

    //---------------------------------------------------------------
    
    // Get all auction's params
    function getCapitalParams(uint256 _capitalIdx) external view override returns (TCapital memory)
    { return capitals[_capitalIdx]; }

    // Get current state of auction
    function isActive(uint256 _capitalIdx) external view override returns (bool)
    { return capitals[_capitalIdx].active; }

    // Set current (active or closed) state of auction
    // NOTE: only admins can change auction state directly
    //      emit CapitalState(_capitalIdx, msg.sender, _value);
    function setActive(uint256 _capitalIdx, bool _value) external onlyAuthCenter onlyAdmins override returns (bool) {
        capitals[_capitalIdx].active = _value;
        emit CapitalState(_capitalIdx, msg.sender, _value);
        return true;
    }

    // Get the total value of the token being sold.
    function totalSold(uint256 _capitalIdx) external view override returns (uint256)
    { return capitals[_capitalIdx].totalSold; }

    // Get the total numbers of created auctions
    function getCapitalsNum() external view override returns (uint256)
    { return capitals.length; }

    // only approved operators and msg.sender==_from can make capitals
    //      emit 'MakeCapital(args)' event
    //      emit CapitalState(newCapitalIdx, msg.sender, true) event
    function makeCapital(
        address _from,        // address of the owner of the cool tokens being sold
        uint256 _token,       // key index of the cool token being sold
        uint256 _tokenQuote,  // key index of the payment token
        uint256 _totalAmount, // total amount of the '_tokens' for sale
        uint256 _price,       // price for the '_token' in '_tokenQuote' values
        uint256 _startAt,     // the datetime auction start (seconds from 01.01.1970 UTC+0)
        uint256 _expireAt,    // the datetime auction finish (seconds from 01.01.1970 UTC+0)
        uint256 _minCap,      // minimun amount of '_token' sold to success finish
        string memory _uri    // hyperlink to auction's URI
    ) external onlyAuthCenter whenNotPaused onlyClients onlyApproved(_from)
        override returns (uint256) // return new incremental key index for auction
    {
        require(IAuthCenter(authCenter).isClient(_from), "AuCapital: Auction creator not our client");
        require(tokens[_token].valid, "AuCapital: tokens for sale is invalid");
        require(tokens[_tokenQuote].valid, "AuCapital: payments tokens is invalid");
        require(balances[_from][_token] - blocked[_from][_token] >= _totalAmount,
                "AuCapital: Not enough free tokens to sold");

        // It's probably never going to happen, 4 billion capitals is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(capitals.length == uint256(uint32(capitals.length)), "AuCapital: 4 billions capitals overflow");

        TCapital memory _capital = TCapital({
            owner: _from,
            token: _token,
            tokenQuote: _tokenQuote,
            totalAmount: _totalAmount,
            totalSold: 0,
            price: _price,
            startAt: _startAt,
            expireAt: _expireAt,
            minCap: _minCap,
            active: true,
            uri: _uri
        });
        capitals.push(_capital);
        uint256 newCapitalIdx = capitals.length - 1;

        buyers[newCapitalIdx][0].purchasedAmount = 0; //set initial number of buyers

        emit MakeCapital(newCapitalIdx, msg.sender);
        emit CapitalState(newCapitalIdx, msg.sender, true);
        return newCapitalIdx;
    }

    // ----------------------------------------------------------------------

    // only approved operators and msg.sender==_from can buy capitals,
    // emit BlockTokensEvent(msg.sender, _from, _token, _amount, true)
    function buy(
        address _from,       // payment tokens owner address
        uint256 _capitalIdx, // key index for token's pair to purchased
        uint256 _amount      // quantity of cool tokens to purchased
    ) external onlyAuthCenter whenNotPaused onlyApproved(_from) override returns (bool) {
        require(capitals[_capitalIdx].active, "AuCapital: auction was closed");
        require(capitals[_capitalIdx].totalSold <= capitals[_capitalIdx].totalAmount,
                "AuCapital: all tokens was solded");

        require(tokens[capitals[_capitalIdx].token].valid, "AuCapital: token for sale is invalid");
        require(tokens[capitals[_capitalIdx].tokenQuote].valid, "AuCapital: payment token is invalid");
        require(block.timestamp >= capitals[_capitalIdx].startAt, "AuCapital: auction don't began");
        require(block.timestamp <= capitals[_capitalIdx].expireAt, "AuCapital: auction is done");

        uint256 _tokenQuote = capitals[_capitalIdx].tokenQuote;
        uint256 _cost = _amount * capitals[_capitalIdx].price;
        require(balances[_from][_tokenQuote] - blocked[_from][_tokenQuote] >= _cost,
                "AuCapital: buyer have not enough free payment tokens");

        address _merchant = capitals[_capitalIdx].owner;
        uint256 _token = capitals[_capitalIdx].token;
        require(balances[_merchant][_token] - blocked[_merchant][_token] >= _amount,
                "AuCapital: merchant have not enough free tokens for sale");

        capitals[_capitalIdx].totalSold += _amount;

        uint256 _buyersNum = buyers[_capitalIdx][0].purchasedAmount + 1;
        buyers[_capitalIdx][_buyersNum].buyerAddress = _from;
        buyers[_capitalIdx][_buyersNum].purchasedAmount = _amount;
        buyers[_capitalIdx][0].purchasedAmount = _buyersNum;

        // block buyers and merchans tokens
        blocked[_from][_tokenQuote] += _cost;
        emit BlockTokensEvent(msg.sender, _from, _tokenQuote, _cost, true);
        blocked[_merchant][_token] += _amount;
        emit BlockTokensEvent(msg.sender, _merchant, _token, _amount, true);

        return true;
    }

    // only admins and capital's creator can close auction
    // return 'true' if auction totalSold >= minCap, or 'false' otherwise.
    // emit CapitalState(_capitalIdx, msg.sender, false) event
    // emit BlockTokens(msg.sender, _buyer, _token, _value, false) events
    // emit Transfer(msg.sender, _from, _to, _token, _value) events
    function close(uint256 _capitalIdx) external
        onlyAuthCenter whenNotPaused onlyClients onlyApproved(capitals[_capitalIdx].owner)
        override returns (bool)
    {
        capitals[_capitalIdx].active = false;
        emit CapitalState(_capitalIdx, msg.sender, false);

        uint256 _token = capitals[_capitalIdx].token;
        uint256 _tokenQuote = capitals[_capitalIdx].tokenQuote;
        uint256 _price = capitals[_capitalIdx].price;
        uint256 _totalSold = capitals[_capitalIdx].totalSold;

        bool auctionResult = _totalSold >= capitals[_capitalIdx].minCap;

        // finish of the merchant transactions
        address _capitalOwner = capitals[_capitalIdx].owner;        
        blocked[_capitalOwner][_token] -= _totalSold;
        emit BlockTokensEvent(msg.sender, _capitalOwner, _token, _totalSold, false);
        if (auctionResult) {
            // successful completion of the merchant transaction
            balances[_capitalOwner][_tokenQuote] += _totalSold * _price;
            balances[_capitalOwner][_token] -= _totalSold;
        }

        // finish of the buyers transactions
        uint256 _buyersNum = buyers[_capitalIdx][0].purchasedAmount;
        address _buyerAddress;
        uint256 _purchasedTokens;
        uint256 _cost;
        for(uint256 buyerIdx=1; buyerIdx<=_buyersNum; buyerIdx++) {
            _buyerAddress = buyers[_capitalIdx][buyerIdx].buyerAddress;
            _purchasedTokens = buyers[_capitalIdx][buyerIdx].purchasedAmount;
            // unlock buyer's payment tokens
            _cost = _purchasedTokens * _price;
            blocked[_buyerAddress][_tokenQuote] -= _cost;
            emit BlockTokensEvent(msg.sender, _buyerAddress, _tokenQuote, _cost, false);
            if (auctionResult) {
                // successful completion of the buyer transaction
                balances[_buyerAddress][_tokenQuote] -= _cost;
                emit Transfer(msg.sender, _buyerAddress, _capitalOwner, _tokenQuote, _cost);
                balances[_buyerAddress][_token] += _purchasedTokens;
                emit Transfer(msg.sender, _capitalOwner, _buyerAddress, _token, _purchasedTokens);
            }
        }
        
        return auctionResult;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAuthCenter {
    event UpdateOwner(address indexed _address);
    event AddAdmin(address indexed _address);
    event DiscardAdmin(address indexed _address);
    event FreezeAddress(address indexed _address);
    event UnFreezeAddress(address indexed _address);
    event AddClient(address indexed _address);
    event RemoveClient(address indexed _address);
    event ContractPausedState(address indexed _address, bool _value);

    function addAdmin(address _address) external returns (bool);
    function discardAdmin(address _address) external returns (bool);
    function freezeAddress(address _address) external returns (bool);
    function unfreezeAddress(address _address) external returns (bool);
    function addClient(address _address) external returns (bool);
    function removeClient(address _address) external returns (bool);
    function isClient(address _address) external view returns (bool);
    function isAdmin(address _address) external view returns (bool);
    function isAddressFrozen(address _address) external view returns (bool);
    function setContractPaused(address _address) external returns (bool);
    function setContractUnpaused(address _address) external returns (bool);
    function isContractPaused(address _address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAuCapital {
    event UpdateOwner(address indexed _address);

    event TokenCreate(
        uint256 indexed _tokenIdx,    // key index of new token
        address indexed _creator     // token's creator address
    );
    //     string _tokenName,   // long token name
    //     string _tokenSymbol, // short token name
    //     string _tokenUri     // token's URI
    // );

    event MakeCapital(
        uint256 indexed _capitalIdx,  // key index of created auction
        address _operator             // approved operator address
                                      // who called function makeCapital
    );

    event Transfer(
        address indexed _operator, // address of spender
        address indexed _from,     // address of the owner of the payments tokens
        address indexed _to,       // address of the holder of the tokens being sold
        uint256 _tokenIdx,         // key index of payment tokens
        uint256 _value             // amount of payments tokens
    );

    event BlockTokensEvent(
        address indexed _operator, // address of operator, who blocked tockens
        address indexed _owner,    // address of owner blocked funds
        uint256 indexed _tokenIdx, // key index of blocked tokens
        uint256 _value,            // amount of blocked tokens
        bool _action               // action is block=true, unlock=false
    );

    event ApprovalForAll(
        address indexed _owner,    // address of the real holder
        address indexed _operator, // address of the spender
        bool _approved             // approved flag (accept=true, deny=false)
    );

    event CapitalState(
        uint256 indexed _capitalIdx, // key index of auction in capitals array
        address indexed _operator,   // address of operator, who change auction state
        bool _state                  // new state of auction (active=true, closed=false)
    );
    //---------------------------------------------------------------

        struct TToken {
        string name;    // long token name
        string symbol;  // short token name
        string uri;     // token's URI
        bool valid;     // valid (=true) or non-valid (=false) token state
    }

    struct TCapital {
        address owner;       // address of capital creator
        uint256 token;       // key index of the cool token being sold
        uint256 tokenQuote;  // key index of the payment token
        uint256 totalAmount; // initial amount of the '_tokens' for sale
        uint256 totalSold;   // total value of the token being sold.
        uint256 price;       // price for the '_token' in '_tokenQuote' values
        uint256 startAt;     // the datetime auction start
        uint256 expireAt;    // the datetime auction finish
        uint256 minCap;      // minimun amount of '_token' sold to success finish
        bool active;         // current state of auction
        string uri;          // hyperlink to auction's URI
    }
    //---------------------------------------------------------------

    function updateOwner(address _address) external returns (bool);

    // some gas ethers need for a normal work of this contract (calls to AuthCenter).
    // Only owner can put ethers to contract.
    // Only owner can return to himself gas ethers before closing contract
    function withDrawAll() external;

    // Link AuthCenter to contract
    function setAuthCenter(address _address) external returns (bool);

    // Get current (paused or active) state of contract
    function isPaused() external view returns (bool);

    //---------------------------------------------------------------
    // Get all token's params
    function getTokenParams(uint256 _tokenIdx) external view returns(TToken memory);

    // Get the valid(=true) or invalid(=false) state of the token.
    function isValid(uint256 _tokenIdx) external view returns (bool);

    // Set the token state
    function setValid(uint256 _tokenIdx, bool _value) external returns (bool);

    // Enable or disable approval for a third party ("operator") to manage account
    //      emit ApprovalForAll(msg.sender, _operator, _approved) event
    function setApprovalForAll(address _operator, bool _approved) external returns (bool);

    // Queries the approval status of an operator for a given owner.
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    // Get the balance of an account's tokens.
    function balanceOf(address _owner, uint256 _tokenIdx) external view returns (uint256);

    // Get the blocked balance of an account's tokens.
    function blockedOf(address _owner, uint256 _tokenIdx) external view returns (uint256);

    // Block some clients tokens.
    // to block tokens set _action to 'true'
    // to unlock tokens set _action to 'false'
    // to block or unlock all tokens[_tokenIdx], set _actionAll to 'true'
    // NOTE: only admins can block clients tokens,
    //       emit BlockTokens(msg.sender, _owner, _tokenIdx, _value) event
    function blockTokens(address _owner, uint256 _tokenIdx, uint256 _value, bool _action, bool _actionAll) external returns (bool);

    // mint tokens to clients
    // NOTE: only admins can mint,
    //   emitTransfer(msg.sender, address(0), _to, _tokenIdx, _value) event
    function mint(address _to, uint256 _tokenIdx, uint256 _value) external returns(bool);

    // burn client's tokens
    // NOTE: only token's owner==_address and admins can burn,
    // emit Transfer(msg.sender, _address, address(0), _tokenIdx, _value) event
    function burn(address _address, uint256 _tokenIdx, uint256 _value) external returns(bool);

    // only admins can create tokens
    //  emit 'TokenCreate(args)' event
    function tokenCreate(
        uint256 _tokenIdx,          // key index of new token
        string memory _tokenName,   // long token name
        string memory _tokenSymbol, // short token name
        string memory _tokenUri     // token's URI
    ) external returns (bool);

    //---------------------------------------------------------------

    // Get all auction's params
    function getCapitalParams(uint256 _capitalIdx) external view returns(TCapital memory);

    // Get current (active or closed) state of auction
    function isActive(uint256 _capitalIdx) external view returns (bool);

    // Set current (active or closed) state of auction
    // NOTE: only admins can change auction state directly,
    //      emit CapitalState(_capitalIdx, msg.sender, _value) event
    function setActive(uint256 _capitalIdx, bool _value) external returns (bool);

    // Get the total value of the token being sold.
    function totalSold(uint256 _capitalIdx) external view returns (uint256);

    // Get the total numbers of created auctions
    function getCapitalsNum() external view returns (uint256);

    // only approved operators and msg.sender==_from can make capitals
    // emit 'MakeCapital(args)' event
    // emit CapitalState(_capitalIdx, msg.sender, true) event
    function makeCapital(
        address _from,        // address of the owner of the cool tokens being sold
        uint256 _token,       // key index of the cool token being sold
        uint256 _tokenQuote,  // key index of the payment token
        uint256 _totalAmount, // initial amount of the '_tokens' for sale
        uint256 _price,       // price for the '_token' in '_tokenQuote' values
        uint256 _startAt,     // the datetime auction start
        uint256 _expireAt,    // the datetime auction finish
        uint256 _minCap,      // minimun amount of '_token' sold to success finish
        string memory _uri    // hyperlink to auction's URI
    ) external returns (uint256); // return new incremental key index for auction

    // only approved operators and msg.sender==_from can buy capitals,
    // emit BlockTokens(msg.sender, _from, _tokenQuote, _amount)
    function buy(
        address _from,       // payment tokens owner address
        uint256 _capitalIdx, // key index for token's pair to purchased
        uint256 _amount      // quantity of cool tokens to purchased
    ) external returns (bool);

    // only admins and capital's creator can close auction,
    // emit CapitalState(_capitalIdx, msg.sender, false) event
    function close(uint256 _capitalIdx) external returns (bool);
}