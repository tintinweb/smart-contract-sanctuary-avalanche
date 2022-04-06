/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-05
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;



/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

contract YATMarket {

    struct Bid {
        uint bidId;
        uint tokenId;
        uint bidPrice;
        address bidder;
        bool active;
    }

    struct Listing {
        address owner;
        bool active;
        uint256 price;

    }
    
    address nftContract;
    address wETH = 0x0000111122223333444400001111222233334444; //mock
    //map tokenIds to array of Bids
    mapping(uint256 => Bid[]) public bids;
    //map to tokenID's that a user has bids on, to be used in conjunction with bids
    mapping(address => uint[]) public userToBids;

  
    uint256 public marketFeePercent = 0;
    bool public isMarketOpen = false;
    bool public emergencyDelisting = false;
    uint256 public marketCut = 0;

    mapping(uint256 => Listing) public listings;

    address public owner;

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event AddListingEv(uint256 indexed tokenId, uint256 price);
    event UpdateListingEv(uint256 indexed tokenId, uint256 price);
    event CancelListingEv(uint256 indexed tokenId);
    event FulfillListingEv(uint256 indexed tokenId, uint price);
    event CreateBidEv(uint256 tokenId, uint256 indexed bidId, uint256 bidPrice, address bidder, address owner);
    event AcceptBidEv(uint256 tokenId, uint256 indexed bidId);
    event CancelBidEv(uint256 tokenId, uint256 indexed bidId);


    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/

    error Percentage0to100();
    error ClosedMarket();
    error InactiveListing();
    error InsufficientValue();
    error InvalidOwner();
    error OnlyEmergency();
    error Unauthorized();


    constructor(
        address nft_address,
        uint256 market_fee
    ) {
        if (market_fee > 100 || market_fee < 0 ) revert Percentage0to100();
        owner = msg.sender;
        nftContract = nft_address;
        marketFeePercent = market_fee;
    
    }
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }


    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerUpdated(_newOwner);
    }

    function setWETH(address _WETH) external onlyOwner {
        wETH = _WETH;

    }

    function setNFTContract(address _newNFTcontract) external onlyOwner {
        nftContract = _newNFTcontract;
        
    }

    function withdrawableBalance() public view returns (uint256 value) { 
        return marketCut;
    }

    function withdraw() external onlyOwner {
        uint balance = marketCut;
        marketCut = 0;
        ERC20(wETH).transfer(msg.sender,balance);    
    }

    /*///////////////////////////////////////////////////////////////
                      MARKET MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function openMarket() external onlyOwner {
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        isMarketOpen = false;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function adjustFees(uint256 newMarketFee) external onlyOwner {
        if (newMarketFee > 100 || newMarketFee < 0 ) revert Percentage0to100();
        marketFeePercent = newMarketFee;
    }

    function emergencyDelist(uint256 _tokenId) external {
        require(emergencyDelisting && !isMarketOpen, "Only in emergency.");
        Listing memory listing = listings[_tokenId];
        delete  listings[_tokenId];
        ERC721(nftContract).transferFrom(address(this), listing.owner, _tokenId);
        emit CancelListingEv(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                      LISTING WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/


    function addListing(
        uint256 _tokenId,
        uint256 _price
    ) external {
        if (!isMarketOpen) revert ClosedMarket();

        //@dev no other checks since transferFrom will fail
        listings[_tokenId] = Listing( msg.sender, true,_price);
        ERC721(nftContract).transferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        emit AddListingEv( _tokenId, _price);
    
    }

    function updateListing(uint256 _tokenId, uint256 _price) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (!listings[_tokenId].active) revert InactiveListing();
        if (listings[_tokenId].owner != msg.sender) revert InvalidOwner();
        listings[_tokenId].price = _price;
        emit UpdateListingEv(_tokenId, _price);
    }

    function cancelListing(uint256 _tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();
        Listing memory listing = listings[_tokenId];
        if (!listing.active) revert InactiveListing();
        if (listing.owner != msg.sender) revert InvalidOwner();
        delete listings[_tokenId];
        ERC721(nftContract).transferFrom(
            address(this),
            listing.owner,
            _tokenId
        );
        emit CancelListingEv(_tokenId);
    }

    function fulfillListing(uint256 _tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();
        Listing memory listing = listings[_tokenId];
        if (!listing.active) revert InactiveListing();
        if (msg.sender == listing.owner) revert InvalidOwner(); // can not fulfill your own listing
        if (ERC20(wETH).balanceOf(msg.sender) < listing.price) revert InsufficientValue(); // TODO: Remove on production
        delete listings[_tokenId];
        marketCut += (listing.price * marketFeePercent) / 100; 
        ERC20(wETH).transferFrom(msg.sender, listing.owner, listing.price - (listing.price * marketFeePercent) / 100); 
        ERC20(wETH).transferFrom(msg.sender, address(this), (listing.price * marketFeePercent) / 100);   
      
        ERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        emit FulfillListingEv(_tokenId, listing.price);
    }

    function fullfillMultipleListings(uint256[] calldata _tokenIds) external {
        if (!isMarketOpen) revert ClosedMarket();
        for (uint256 index = 0; index < _tokenIds.length; ++index) {
            uint tokenId = _tokenIds[index];
            Listing memory listing = listings[tokenId];
            if (msg.sender == listing.owner) revert InvalidOwner();
            if (!listing.active) revert InactiveListing();
            delete listings[tokenId];
            marketCut += (listing.price * marketFeePercent) / 100; 
            ERC20(wETH).transferFrom(msg.sender, listing.owner, listing.price - (listing.price * marketFeePercent) / 100);
            ERC20(wETH).transferFrom(msg.sender, address(this), (listing.price * marketFeePercent) / 100);   
            ERC721(nftContract).transferFrom(address(this),msg.sender,tokenId);
            emit FulfillListingEv(tokenId,listing.price);
  
        }
    }



    /*///////////////////////////////////////////////////////////////
                      BIDDING WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/



    function placeBid(uint256 tokenId, uint amount) external {
        if (!isMarketOpen) revert ClosedMarket();
        address tokenOwner = getTokenOwner(tokenId); 
        require(msg.sender != tokenOwner, "Can't place bid for own blueprint");
        if (ERC20(wETH).balanceOf(msg.sender) < amount) revert InsufficientValue(); // TODO: remove in production

        //TODO multiple bids are allowed by the same user but it is discouraged
        ERC20(wETH).transferFrom(msg.sender, address(this), amount);     
        uint256 index = bids[tokenId].length;
        bids[tokenId].push(Bid(index, tokenId, amount, msg.sender, true));

        userToBids[msg.sender].push(tokenId); // TODO: remove in production

        emit CreateBidEv(
            bids[tokenId][index].bidId,
            bids[tokenId][index].tokenId,     
            bids[tokenId][index].bidPrice,
            bids[tokenId][index].bidder,
            tokenOwner
        );
    }



    function cancelBid (uint tokenId, uint256 bidId) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (bids[tokenId][bidId].bidder != msg.sender) revert InvalidOwner();
        if (bids[tokenId][bidId].active == false) revert InactiveListing();
        uint256 bidAmount = bids[tokenId][bidId].bidPrice;
        delete bids[tokenId][bidId];
        ERC20(wETH).transfer(msg.sender, bidAmount); 
        //userToBids[msg.sender]; TODO Remove in production. The list is not updated but the bidID is set to inactive. Duplicates may occour but this doesnt change anything
        emit  CancelBidEv(tokenId,bidId);

    }

    

    function acceptBid(uint tokenId, uint256 bidId) external { 
        if (!isMarketOpen) revert ClosedMarket();
        address tokenOwner = getTokenOwner(tokenId);
        if(msg.sender != tokenOwner) revert InvalidOwner();
        if( bids[tokenId][bidId].active == false) revert InactiveListing();
        uint256 bidAmount = bids[tokenId][bidId].bidPrice;
        address buyer = bids[tokenId][bidId].bidder;
        delete bids[tokenId][bidId];

        //check if this was an active listing
        if(listings[tokenId].active){
            delete listings[tokenId];
            ERC721(nftContract).transferFrom(address(this), buyer, tokenId);
            // userToBids[msg.sender]; TODO Remove in production. The list is not updated but the bidID is set to inactive. Duplicates may occour but this doesnt change anything
            emit CancelListingEv(tokenId);
        }
        else {
            ERC721(nftContract).transferFrom(tokenOwner, buyer, tokenId);
        }
        
        uint256 market_cut = (bidAmount * marketFeePercent) / 100;
        uint256 seller_cut = bidAmount - market_cut;
        marketCut += market_cut; 
        ERC20(wETH).transfer(tokenOwner, seller_cut); //remaining is left here

        emit AcceptBidEv(tokenId,bidId);
    }


    function cancelBidsOnBurnedTokenIds(uint256[] calldata _burnedTokenIds) external{
        for (uint256 index = 0; index < _burnedTokenIds.length; index++) {
            uint256 tokenId = _burnedTokenIds[index];
            if(ERC721(nftContract).ownerOf(tokenId) == address(0)){
                Bid[] memory bidArray = bids[tokenId];
                for (uint256 bidId = 0; bidId < bidArray.length; ++bidId) {
                    Bid memory currentBid = bidArray[bidId];
                    if(currentBid.active){
                        delete bids[tokenId][bidId];
                        ERC20(wETH).transfer(currentBid.bidder,currentBid.bidPrice);
                        emit CancelBidEv(tokenId, bidId);
                    }
                }    
            }
        }
        
    }
    // Fragmented variant of cancelBidsOnBurnedTokenIds. This is a back up for any gas limit issue
    // _start : 0, _max_len: type(uint).max gives the default behaviour of cancelBidsOnBurnedTokenIds
    function cancelBidsOnBurnedTokenIds(uint256[] calldata _burnedTokenIds, uint _start, uint _maxlen) external{
        for (uint256 index = 0; index < _burnedTokenIds.length; index++) {
            uint256 tokenId = _burnedTokenIds[index];
            if(ERC721(nftContract).ownerOf(tokenId) == address(0)){
                Bid[] memory bidArray = bids[tokenId];
                uint maxIterations = bidArray.length;
                if(_maxlen < bidArray.length){
                    maxIterations = _maxlen;
                }
                for (uint256 bidId = _start; bidId < maxIterations; ++bidId) {
                    Bid memory currentBid = bidArray[bidId];
                    if(currentBid.active){
                        delete bids[tokenId][bidId];
                        ERC20(wETH).transfer(currentBid.bidder,currentBid.bidPrice);
                        emit CancelBidEv(tokenId, bidId);
                        
                    }
                    
                }    
            }
        
        }
        
    }


    /*///////////////////////////////////////////////////////////////
                      READ OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function getListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            Listing[] memory _listings = new Listing[](length);
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < length; ++i) {
                _listings[i] = listings[from + i];
            }
            return _listings;
        }
    }
    function getTokenOwner(uint256 _tokenId) public view returns (address){
        if (listings[_tokenId].active){
            return listings[_tokenId].owner;
        } else {
            return ERC721(nftContract).ownerOf(_tokenId);
        }
    }
    
    function getBidsOnBlueprint(uint tokenID) public view returns (Bid[] memory bidsList) {
        return bids[tokenID];

    }



    /*///////////////////////////////////////////////////////////////
                      TO BE REMOVED IN PRODUCTION
    //////////////////////////////////////////////////////////////*/

    function getTokenIdsWithBids(address user) public view returns (uint[] memory tokenIds ){
        return userToBids[user];
    }

    // dont send duplicate ids maxLen should be  number of non duplicate ids + each duplicated id * how many times its duplicated
    function getUserBids(address user, uint[] calldata tokenIds, uint maxLen) public view returns (Bid[] memory bidsList ) {
        bidsList = new Bid[](maxLen);
        uint counter = 0;
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint tokenId = tokenIds[index];
            for (uint256 bidId = 0; bidId < bids[tokenId].length; ++bidId) {
                if( bids[tokenId][bidId].bidder == user){
                    bidsList[counter++] = bids[tokenId][bidId];
                }
            }
        }
        return bidsList;
    }
           

// @dev testing only view function due to lack of indexer, the len should be bigger than len of (tokenIdsWithBids) if it reverts (the exact len is duplicate ids squared + non duplicated ids TODO remove on production)
    function getBids(address user, uint start, uint len) public view returns (Bid[] memory bidsList ){
        uint[] memory tokenIdsWithBids = userToBids[user];
        uint limit = tokenIdsWithBids.length;
        if(len < limit) limit = len;
        Bid[] memory _userBids = new Bid[](limit); // causes problems due to pre size initialisation but dupplicates are accounted for since every duplicate is registerd again, the size wont be an issue
        for (uint256 y = start; y < limit; ++y) {
            for (uint256 index = 0; index < bids[tokenIdsWithBids[y]].length; index++) {
                if(bids[tokenIdsWithBids[y]][index].bidder == user && bids[tokenIdsWithBids[y]][index].active ) {
                    _userBids[y] = bids[tokenIdsWithBids[y]][index];
                }
            }
           
        }
        return _userBids;

    }


    function getListingId(uint id) public pure returns (uint tokenId){ //Todo remove in prod, required for testing
        return id;
    }

    /*///////////////////////////////////////////////////////////////
                    END OF TO BE REMOVED IN PRODUCTION
    //////////////////////////////////////////////////////////////*/

    receive() external payable {} // solhint-disable-line

    fallback() external payable {} // solhint-disable-line


}