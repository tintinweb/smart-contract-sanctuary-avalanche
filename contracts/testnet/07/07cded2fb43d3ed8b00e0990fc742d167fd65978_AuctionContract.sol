/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IERC20 {
    //Fuction that use in ERC20 token
    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address Owner) external view returns (uint256);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 token) external returns (bool);

    function approve(address spender, uint256 token) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 token
    ) external returns (bool);

    //Events use in ERC20
    event approval(address indexed Owner, address indexed to, uint256 token);
    event Transfer(address from, address to, uint256 token);
}
abstract contract Ownable  {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
    constructor() {
        _transferOwnership(msg.sender);
    }

   
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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


contract AuctionContract is Ownable {
    IERC20 token;

    struct Auction {
        address addressNftToken;
        string identityString;
        uint256 lastBidPrice;
        uint256 bidInc;
        address highestBidder;
        address winner;
        uint256 endTime;
        mapping(uint256 => uint256) biddingAmounts;
        mapping(uint256 => address) bidderAddress;
        mapping(address => uint256) bidPosition;
        mapping(address => bool) exist;
        uint256 bidCount;
        bool active;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionNonce;

    constructor() {
        token = IERC20(0x3d60a6A3DBcAC4d5C2B9a262E24A2F6991B9817f);

    }

    function changeToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    function withdrawTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function createAuction(
        address _addressNftToken,
        string memory _identityString,
        uint256 _initialValue,
        uint256 _bidInc,
        uint256 _endTime
    ) external onlyOwner {
        require(_initialValue > 0, "Invalid initial bid price");

        auctions[auctionNonce].addressNftToken = _addressNftToken;
        auctions[auctionNonce].identityString = _identityString;
        auctions[auctionNonce].lastBidPrice = _initialValue;
        auctions[auctionNonce].bidInc = _bidInc;
        auctions[auctionNonce].endTime = block.timestamp + _endTime;
        auctions[auctionNonce].active = true;
        auctionNonce++;
    }

    function _cancelAuction(uint256 _auctionId) public onlyOwner {
        require(_auctionId < auctionNonce, "Invalid auction index");
        require(auctions[_auctionId].active, "Already cancelled or finalized");
        auctions[_auctionId].active = false;
    }

 
    function bid(uint256 _auctionId, uint256 _newBid) external  {
        require(_auctionId < auctionNonce, "Invalid auction index");
        require(
            !auctions[_auctionId].exist[msg.sender],
            "You already placed a bid. Now try to update your bid"
        );
        require(
            auctions[_auctionId].endTime > block.timestamp,
            "Auction is time out to particiate"
        );
        require(
            _newBid >= getNextBidAmount(_auctionId),
            "You cannot place a bid less than the last bid and incremental sum amount"
        );
        token.transferFrom(msg.sender,address(this),_newBid);


        auctions[_auctionId].lastBidPrice = _newBid;
        auctions[_auctionId].exist[msg.sender] = true;
        auctions[_auctionId].highestBidder = msg.sender;
        auctions[_auctionId].biddingAmounts[
            auctions[_auctionId].bidCount
        ] = _newBid;
        auctions[_auctionId].bidderAddress[auctions[_auctionId].bidCount] = msg
            .sender;
        auctions[_auctionId].bidPosition[msg.sender] = auctions[_auctionId]
            .bidCount;
        auctions[_auctionId].bidCount++;
    }

    function updateBid(uint256 _auctionId, uint256 _updateValue)
        external
    {
        require(_auctionId < auctionNonce, "Invalid auction index");
        require(
            auctions[_auctionId].exist[msg.sender],
            "You already placed a bid. Now try to update your bid"
        );
        require(
            auctions[_auctionId].endTime > block.timestamp,
            "Auction is time out to particiate"
        );
        require(
            _updateValue >= getNextBidAmountForUpdate(msg.sender, _auctionId),
            "You cannot place a bid less than the last bid and incremental sum amount"
        );

        token.transferFrom(msg.sender,address(this),_updateValue);

        auctions[_auctionId].lastBidPrice +=
           ( _updateValue -
            getNextBidAmountForUpdate(msg.sender, _auctionId));
        auctions[_auctionId].highestBidder = msg.sender;
        auctions[_auctionId].biddingAmounts[
            auctions[_auctionId].bidPosition[msg.sender]
        ] += _updateValue;


    }

       function getAllBidAmounts(uint256 _auctionId)
        public
        view
        returns (uint256[] memory)
    {
        require(_auctionId < auctionNonce, "Invalid auction index");
        uint256[] memory amounts = new uint256[](auctions[_auctionId].bidCount);

        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = auctions[_auctionId].biddingAmounts[i];
        }

        return amounts;
    }

    function getAllBidders(uint256 _auctionId)
        public
        view
        returns (address[] memory)
    {
        require(_auctionId < auctionNonce, "Invalid auction index");
        address[] memory users = new address[](auctions[_auctionId].bidCount);

        for (uint256 i = 0; i < users.length; i++) {
            users[i] = auctions[_auctionId].bidderAddress[i];
        }
        return users;
    }

    function getNextBidAmount(uint256 _auctionId)
        public
        view
        returns (uint256)
    {
        return
            (auctions[_auctionId].bidCount > 0)
                ? auctions[_auctionId].lastBidPrice + auctions[_auctionId].bidInc
                : auctions[_auctionId].lastBidPrice;
    }

    function getNextBidAmountForUpdate(address _user, uint256 _auctionId)
        public
        view
        returns (uint256)
    {
        require(
            auctions[_auctionId].exist[_user],
            "User does not exists in this auction"
        );
        require(
            auctions[_auctionId].highestBidder != _user,
            "User is already highest bidder in this auction"
        );
        return ((auctions[_auctionId].lastBidPrice + auctions[_auctionId].bidInc) -
            auctions[_auctionId].biddingAmounts[
                auctions[_auctionId].bidPosition[_user]
            ]);
    }


    function finalizeAuction(uint256 _auctionId) external {
        require(_auctionId < auctionNonce, "Invalid auction index");
        require(
            auctions[_auctionId].active,
            "auction is already cancelled or finalized"
        );
        require(
            auctions[_auctionId].endTime < block.timestamp,
            "auction is live , time is not finished yet"
        );
        auctions[_auctionId].winner = auctions[_auctionId].highestBidder;
        auctions[_auctionId].biddingAmounts[
            auctions[_auctionId].bidPosition[auctions[_auctionId].winner]
        ] = 0;
        auctions[_auctionId].active = false;
        auctions[_auctionId].exist[msg.sender] = false;
    }

    function claimFunds(uint256 _auctionId) external {
        if (auctions[_auctionId].endTime < block.timestamp) {
            require(
                auctions[_auctionId].highestBidder != msg.sender,
                "You cannot withdraw funds , because you are highest bidder. Please contact admin to refund your funds"
            );
        }
        require(
            auctions[_auctionId].exist[msg.sender],
            "You are not member of this auction"
        );
        require(
            auctions[_auctionId].endTime < block.timestamp,
            "Auction is not ended yet"
        );
        token.transfer(
            msg.sender,
            auctions[_auctionId].biddingAmounts[
                auctions[_auctionId].bidPosition[msg.sender]
            ]
        );
        auctions[_auctionId].exist[msg.sender] = false;
    }

    function RefundHighestBidderFunds(address _user, uint256 _auctionId)
        external
        onlyOwner
    {
        require(
            auctions[_auctionId].highestBidder == _user,
            "Provided user is not a highest bidder, it can risk your funds"
        );
        require(
            auctions[_auctionId].exist[_user],
            "Provided user is not exist anymore"
        );
        token.transfer(
            _user,
            auctions[_auctionId].biddingAmounts[
                auctions[_auctionId].bidPosition[_user]
            ]
        );
        auctions[_auctionId].biddingAmounts[
            auctions[_auctionId].bidPosition[msg.sender]
        ] = 0;
        auctions[_auctionId].exist[_user] = false;
    }
}