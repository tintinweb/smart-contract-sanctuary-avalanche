/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint256 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user 
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint256 expires) external ;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user 
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId 
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//1657561615 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
contract NFTRenting is Context{
    // Owner t???o cho th??ng tin cho thu?? v???i 1 token n??o ????
    struct RentalInfo{
        address nftAddress; // NFT of the token
        uint256 nftId; // tokenId
        address owner;
        address paymentToken;
        uint256 price;
        uint256 period;
    }

    struct RentalRequest{
        RentalInfo rentalInfo;
        address user;
        uint256 timeUp; // time for the request exists
    }

    // ??ang ???????c owner ????ng cho thu??
    mapping(string => RentalInfo) public tokensForRents;  // rentId => RentalInfo

    // Th??ng tin request mu???n thu?? NFT c???a user g???i ?????n owner
    mapping(string => mapping(address => RentalRequest)) public rentalRequests;
    // rentId => user
    // mapping(string => address[]) rentalRequestUsers;

   
    modifier onlyTokenOwner(address nft, uint256 tokenId){
        require(IERC721(nft).ownerOf(tokenId) == msg.sender,"ERC721: you are not the NFT's owner");
        _;
    }

    modifier checkIsRented(string memory rentId){
        uint256 expireTime = IERC4907(tokensForRents[rentId].nftAddress).userExpires(tokensForRents[rentId].nftId);
        // ch??a thu?? (expireTime = 0) ho???c h???t h???n (expireTime < timestamp) => expireTIme < block.timestamp
        require (expireTime < uint256(block.timestamp), "NFTRenting: the NFT is being rented");
        _;
    }

    constructor(){         
    }

    function userOf(address nftAddress, uint256 tokenId) public view returns(address){
        return IERC4907(nftAddress).userOf(tokenId);
    }


    function userExpires(address nftAddress, uint256 tokenId) public view returns(uint256){
        return IERC4907(nftAddress).userExpires(tokenId);
    }

    // Owner t???o ho???c c???p nh???t th??ng tin cho thu?? (ph???i ki???m tra nft t???n t???i)
    // checkIsRented
    function setForRent(string memory rentId, address nftAddress, uint256 nftId, address paymentToken, uint256 price, uint256 period) public onlyTokenOwner(nftAddress, nftId){
        tokensForRents[rentId] = RentalInfo(nftAddress, nftId, _msgSender(), paymentToken, price, period);
        // emit UpdateForRent(tokenId, msg.sender, price, period);   
    }

    // Owner hu??? th??ng tin cho thu??
    // function cancelForRent(string memory rentId) public checkIsRented(rentId){
    //     require(tokensForRents[rentId].owner == msg.sender,"NFTRenting: You are not the owner");
    //     delete tokensForRents[rentId];
    //     // emit    
    // }

    // User thu?? (v?? chuy???n ti???n)
    //  checkIsRented(rentId)
     struct UserInfo 
    {
        address user;   // address of user role
        uint64 expires; // unix timestamp, user expires
    }

    mapping (uint256  => UserInfo) internal _users;

    // ph???i set quy???n approval cho nft 
    // th??? set cho th???ng user lu??n
    function rent(string memory rentId) public{
        RentalInfo memory info = tokensForRents[rentId];
        // require(IERC20(info.paymentToken).transfer(info.owner, info.price), "ERC20: cannot pay money to the owner");
        IERC4907(info.nftAddress).setUser(info.nftId, msg.sender, block.timestamp + info.period);
        // emit UserRent(tokenId, user);
    }   

    // function setUser(uint256 tokenId, address user, uint64 expires) public virtual{
    //     require(_isApprovedOrOwner(msg.sender, tokenId),"ERC721: transfer caller is not owner nor approved");
    //     UserInfo storage info =  _users[tokenId];
    //     info.user = user;
    //     info.expires = expires;
    //     emit UpdateUser(tokenId,user,expires);
    // }

    // User g???i request mu???n thu?? m???t NFT v???i th???i gian request c?? h???n
    // function requestForRent(string memory rentId, address nftAddress, uint256 _tokenId, address paymentToken, uint256 price, uint256 period, uint256 timeUp) public {
    //     // require
        
    //     RentalInfo memory info   = RentalInfo(msg.sender, nftAddress, _tokenId, paymentToken, price, period);
    //     RentalRequest memory request = RentalRequest(info, msg.sender, timeUp);
    //     rentalRequests[rentId][msg.sender] = request;

    //     // Emit
    // }

    // function cancelRequestForRent(string memory rentId) public{
    //     // require
    //     require(rentalRequests[rentId][msg.sender].user == msg.sender, "NFTRenting: You are not the request owner");
    //     delete rentalRequests[rentId][msg.sender] ;

    //     // Emit
    // }

    // function acceptRequest(string memory rentId, address user) public checkIsRented(rentId){
    //     // require
        
    //     RentalRequest memory request = rentalRequests[rentId][user];
    //     require(request.timeUp < block.timestamp,"NFTRenting: the request is time up");
    //     RentalInfo memory info  = request.rentalInfo;
    //     IERC4907(info.nftAddress).setUser(info.nftId, user, uint256(block.timestamp) + info.period);

    //     // Emit
    // }
}