/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract MarketPlaceProxy {

    error ExternalCallError(string message);

    address public marketplace;

    address public owner;

    address private marketFeeTaker;

    // Byte Code Generator
    address private erc721Gen;

    struct SellOrder {
        address nftContract;
        address orderOwner;
        address token;
        address buyer;
        uint256 nftId;
        uint256 totalPrice;
        uint256 orderStartedAt;
        uint256 orderEndedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 totalSellOrderCount = 1;

    struct Bid {
        uint256 totalPrice;
        uint256 nftId;
        uint256 bidStartedAt;
        uint256 bidEndedAt;
        uint256 orderId;
        address nftContractAddr;
        address seller;
        address bidOwner;
        address token;
        bool isCanceled;
        bool isEnded;
    }
    uint256 totalBidCount = 1;

    event SellOrderCreated(address indexed creator,uint indexed orderId,address token);
    event BidCreated(address indexed creator,uint indexed bidId,address token);
    event ContractCreation(address indexed creator,string name,string symbol);

    // from orderId to order info (ERC721)
    mapping (uint256 => SellOrder) private order;
    // from order owner to all his sell orders (ERC721)
    mapping (address => uint[]) private userSellOrders;
    // from contract address to specific tokenids bids
    mapping (address => mapping (address => mapping (uint => uint[]))) private contractBids;
    // from user to is ERC721 contract created (ERC721)
    mapping (address => address) private userContract;
    // from bidId to bid info (ERC721)
    mapping (uint256 => Bid) private bid;
    // from bidder to bid id (ERC721)
    mapping (address => uint[]) private bidderBids;
    // from user to his added contract accounts
    mapping (address => address[]) private userAddedContracts;
    // from contract address to validation
    mapping (address => bool) private allMarketContracts;
    // from token too validation status
    mapping (address => bool) private allTokens;
    address[] private tokens;
    
    constructor(
        address[] memory _tokens,
        address _feeTaker,
        address _erc721Gen,
        address _implementation
    ) {
        tokens = _tokens;
        marketFeeTaker = _feeTaker;
        erc721Gen = _erc721Gen;
        owner = msg.sender;
        marketplace = _implementation;

        for (uint i; i < _tokens.length; ++i) {
            allTokens[_tokens[i]] = true;
        }
    }
    // Gaurd
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    //////////////////////////////////////// *Interact With Implemented Marketplace* ////////////////////////
    fallback() external {
        (bool res,) = marketplace.delegatecall(msg.data);
        require(res == true, "Delegate call failed.");
    }
    // Read state variables ///////////////////////////////////////////////////////////////////////////////
    function bidData(uint _bidId) external view returns(Bid memory) {
        return bid[_bidId];
    }

    function orderData(uint256 _orderId) external view returns(SellOrder memory) {
        require(_orderId != 0 && _orderId < totalSellOrderCount && _orderId >= 1, "Invalid Order Id.");
        return order[_orderId];
    }

    function totalOrdersCount() external view returns(uint256) {
        return totalSellOrderCount - 1;
    }

    function userAddress(address _addr) external view returns(address contractAddr) {
        contractAddr = userContract[_addr];
    }

    function userContracts(address _user) external view returns(address[] memory) {
        return userAddedContracts[_user];
    }

    function userOrders(address _user) external view returns(uint[] memory) {
        return userSellOrders[_user];
    }

    function userOwnedContract(address _user) external view returns(address) {
        return userContract[_user];
    }

    function userBids(address _user) external view returns(uint[] memory) {
        return bidderBids[_user];
    }

    function userContractBids(
        address _contract,
        address _owner,
        uint _tokenId
    ) external view returns(uint[] memory) {
        return contractBids[_contract][_owner][_tokenId];
    }

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }
    //////////////////////////////// Update Implementation Marketplace ////////////////////////////////////
    function upgrade(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }
    // Change
    function changeOwner(address _newOwner) external onlyOwner {
        require(owner != _newOwner, "You are owner right now!");

        owner = _newOwner;
    }
    
}