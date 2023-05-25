// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Utils/Admin.sol";
import "../Utils/IAdmin.sol";
import "../Utils/SignatureRecover.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interface/ISalesRegistry.sol";
import "./interface/INFT.sol";

contract Marketplace is ERC721Holder, ERC1155Holder, Admin, SignatureRecover{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private saleIdCounter; // saleIdCounter starts from 1
    Counters.Counter private auctionIdCounter; // auctionId starts from 1

    address private constant ETH = address(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa); //currency eth
    address private salesRegistry;

    struct SaleInfo {
        uint128 nftId;
        bool isERC721;
        address nftAddress;
        address owner;
        address currency; // use zero address or 0xaaa for ETH
        uint256 amount; // amount of NFTs being sold
        uint256 purchased; // amount of NFTs purchased thus far
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    struct AuctionInfo {
        uint256 id; // auctionId
        uint256 nftId;
        bool isERC721;
        address nftAddress;
        address owner; // NFT owner address
        address currency; // use zero address or 0xeee for ETH
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 reservePrice; // may need to be made private
    }

    struct Bid {
        uint256 amount;
        uint256 timestamp;
    }

    struct RoyaltyData {
        uint256 main_percentage;
        address creator;
        address[] royalty_recepient;
        uint256[] royalty_percentage;
        string message;
        bytes signature1;
        bytes signature2;
    }

    //##############################
    mapping(uint256 => SaleInfo) public sales; // saleId => saleInfo
    mapping(uint256 => bool) public cancelledSale; // saleId => status
    mapping(uint256 => mapping(address => uint256)) public purchased;
    
    mapping(uint256 => AuctionInfo) public auctions; // auctionId => AuctionInfo
    mapping(uint256 => bool) public cancelledAuction; // auctionId => status
    mapping(uint256 => bool) public claimed; // auctionId => status
    mapping(uint256 => address) public highestBidder; // auctionId => highest bidder address
    mapping(uint256 => mapping(address => Bid)) public bids;

    //##############################
    event SaleCreated(
        uint256 indexed id,
        address indexed nftAddress,
        uint256 indexed nftID,
        uint256 amount,
        address owner
    );
    event SaleCancelled(uint256 indexed saleId);
    event Purchase(
        uint256 indexed saleId,
        address indexed purchaser,
        address indexed recipient
    );

    event NewAuction(uint256 indexed auctionId, AuctionInfo newAuction);
    event AuctionCancelled(uint256 indexed auctionId);
    event BidPlaced(uint256 indexed auctionId, uint256 totalAmount);
    event ClaimAuctionNFT(
        uint256 indexed auctionId,
        address indexed claimer,
        address indexed recipient,
        uint256 amount
    );

    constructor(
        address _salesRegistry
    ){
        salesRegistry = _salesRegistry;
    }

    //##############################
    function createSale(
        bool isERC721,
        address nftAddress,
        uint128 nftId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 price,
        address currency
    ) external returns (uint256 saleId) {
        _beforeSaleOrAuction(nftAddress, startTime, endTime, currency);
        if (isERC721 == true && amount != 1) revert ("Can only sale 1 of amount");

        // transfer nft to the platform
        INFT nftContract = INFT(nftAddress);
        isERC721 //1
            ? nftContract.safeTransferFrom(msg.sender, address(this), nftId, "")
            : nftContract.safeTransferFrom(msg.sender, address(this), nftId, amount,"");

        /*
        //check ownership and approval only
        if(isERC721 == true){
            require(IERC721(nftAddress).ownerOf(nftId) == msg.sender, "must owner nft");
            require(IERC721(nftAddress).getApproved(nftId) == address(this) || 
                        IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == true, 
                            "marketplace must get approval");
        }
        else{
            require(IERC1155(nftAddress).balanceOf(msg.sender, nftId) >= amount, "must owner nft");
            require(IERC1155(nftAddress).isApprovedForAll(msg.sender, address(this)) == true, "marketplace must get approval");
        }
        */

        // save the sale info
        saleIdCounter.increment(); //1
        saleId = saleIdCounter.current();
        sales[saleId] = SaleInfo({ //2
            isERC721: isERC721,
            nftAddress: nftAddress,
            nftId: nftId,
            owner: msg.sender,
            amount: amount,
            purchased: 0,
            startTime: startTime,
            endTime: endTime,
            price: price,
            currency: currency
        });

        emit SaleCreated(saleId, nftAddress, nftId, amount, msg.sender);
    }

    function buy(
        uint256 saleId,
        address recipient,
        uint256 amountToBuy,
        uint256 amountFromBalance,
        RoyaltyData memory royaltyData
    ) external payable returns (bool) {
        require(getSaleStatus(saleId) == 200, "sale is not active");
        require(recipient != address(0),"recepient must not zero address");
        require(amountToBuy <= (sales[saleId].amount - sales[saleId].purchased), "not enough stock");
        require(amountFromBalance >= sales[saleId].price, "invalid buy price");

        SaleInfo memory saleinfo = sales[saleId];

        require(checkValue(amountFromBalance, saleinfo.currency, recipient, msg.value) == true, "invalid value");
        (address pool, uint256 fee)= calculateFee(amountFromBalance);
        (uint256[] memory splitRoyalty, uint256 total_royalty) = calculateRoyalty(amountFromBalance, saleinfo.nftAddress, saleinfo.nftId, royaltyData);
        payment(
            amountFromBalance, 
            pool,  
            fee, 
            splitRoyalty, 
            royaltyData.royalty_recepient,
            total_royalty,
            saleinfo.currency,
            saleinfo.owner
        );
        
        // update the sale info
        unchecked {
            sales[saleId].purchased += amountToBuy;
            purchased[saleId][msg.sender] += amountToBuy;
        }

        nftTransfer(saleinfo.isERC721, saleinfo.nftAddress, saleinfo.nftId, address(this), recipient, amountToBuy);

        emit Purchase(saleId, msg.sender, recipient);
        return true;
    }

    function cancelSale(uint256 saleId) external {
        require(msg.sender == sales[saleId].owner || isAdmin(msg.sender) == true, "only seller or admin contract");

        uint256 status = getSaleStatus(saleId);
        require(status == 102 || status == 200, "sale must be active or pending");

        cancelledSale[saleId] = true;

        nftTransfer(sales[saleId].isERC721, sales[saleId].nftAddress, sales[saleId].nftId, address(this), sales[saleId].owner, (sales[saleId].amount - sales[saleId].purchased));

        emit SaleCancelled(saleId);
    }

    //##############################
    function createAuction(
        bool isERC721,
        address nftAddress,
        uint128 nftId,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice,
        address currency
    ) external returns (uint256 auctionId) {
        _beforeSaleOrAuction(nftAddress, startTime, endTime, currency);
        if (isERC721 == true && amount != 1) revert ("Can only sale 1 of amount");

        // transfer nft to the platform
        INFT nftContract = INFT(nftAddress);
        isERC721 //1
            ? nftContract.safeTransferFrom(msg.sender, address(this), nftId, "")
            : nftContract.safeTransferFrom(msg.sender, address(this), nftId, amount,"");
        
        /*
        if(isERC721 == true){
            require(IERC721(nftAddress).ownerOf(nftId) == msg.sender, "must owner nft");
            require(IERC721(nftAddress).getApproved(nftId) == address(this) || 
                        IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) == true, 
                            "marketplace must get approval");
        }
        else{
            require(IERC1155(nftAddress).balanceOf(msg.sender, nftId) >= amount, "must owner nft");
            require(IERC1155(nftAddress).isApprovedForAll(msg.sender, address(this)) == true, "marketplace must get approval");
        }
        */

        auctionIdCounter.increment(); //2
        auctionId = auctionIdCounter.current();
        auctions[auctionId] = AuctionInfo({
            isERC721: isERC721,
            id: auctionId,
            owner: msg.sender,
            nftAddress: nftAddress,
            nftId: nftId,
            startTime: startTime,
            endTime: endTime,
            reservePrice: reservePrice,
            currency: currency,
            amount: amount
        });

        emit NewAuction(auctionId, auctions[auctionId]);
    }

    function bid(
        uint256 auctionId,
        uint256 amountFromBalance
    ) external payable returns (bool) {
        require(getAuctionStatus(auctionId) == 200, "sale is not active");

        //check bid
        uint256 totalAmount = amountFromBalance + bids[auctionId][msg.sender].amount;
        require(totalAmount > bids[auctionId][highestBidder[auctionId]].amount, "bid is not high enough");
        require(totalAmount > auctions[auctionId].reservePrice, "bid is lower than reserve price");
        AuctionInfo memory auctionInfo = auctions[auctionId];

        require(checkValue(amountFromBalance, auctionInfo.currency, msg.sender, msg.value) == true, "invalid value");

        address lastHighestBidder = highestBidder[auctionId];

        // last bidder can claim their fund now
        if (lastHighestBidder != msg.sender) {
            delete bids[auctionId][lastHighestBidder].amount;
        }
        if (amountFromBalance != 0) {
        }
        
        bids[auctionId][msg.sender].amount = totalAmount;
        bids[auctionId][msg.sender].timestamp = block.timestamp;
        highestBidder[auctionId] = msg.sender;

        emit BidPlaced(auctionId, totalAmount);
        return true;
    }

    function resolveAuction(uint256 auctionId, RoyaltyData memory royaltyData) external {
        require(getAuctionStatus(auctionId) != 101 || getAuctionStatus(auctionId) != 105,  "auction is not cancelled or ended");

        address highestBidder_ = highestBidder[auctionId];
        uint256 winningBid = bids[auctionId][highestBidder_].amount;
        uint256 totalFundsToPay = msg.sender == auctions[auctionId].owner ? 0 : winningBid;

        // accounting logic
        address recipient;
        AuctionInfo memory auctionInfo = auctions[auctionId];
        if (totalFundsToPay != 0) {
            recipient = highestBidder_;
            (address pool,  uint256 fee)= calculateFee(totalFundsToPay);
            (uint256[] memory splitRoyalty, uint256 total_royalty) = calculateRoyalty(
                totalFundsToPay, 
                auctionInfo.nftAddress, 
                auctionInfo.nftId, 
                royaltyData
            );

            payment(
                totalFundsToPay, 
                pool,  
                fee, 
                splitRoyalty, 
                royaltyData.royalty_recepient,
                total_royalty,
                auctionInfo.currency,
                auctionInfo.owner
            );
        } else {
            recipient = auctionInfo.owner;
        }

        nftTransfer(auctionInfo.isERC721, auctionInfo.nftAddress, auctionInfo.nftId, address(this), recipient, auctionInfo.amount);

        claimed[auctionId] = true;

        emit ClaimAuctionNFT(
            auctions[auctionId].id,
            msg.sender,
            recipient,
            bids[auctionId][highestBidder_].amount
        );
    }

    function cancelAuction(uint256 auctionId) external {
        require(msg.sender == auctions[auctionId].owner || isAdmin(msg.sender) == true, "only seller or admin contract");
        require(getAuctionStatus(auctionId) == 200 || getAuctionStatus(auctionId) == 104, "auction is active or pending");

        cancelledAuction[auctionId] = true;

        emit AuctionCancelled(auctionId);
    }

    //##############################
    function checkValue(uint256 amountFromBalance, address currency, address recipient, uint256 msgValue) private view returns(bool){
        if(currency != ETH){ //if currency is token erc20
            if (amountFromBalance > IERC20(currency).balanceOf(recipient) && amountFromBalance > IERC20(currency).allowance(recipient, address(this)))
                revert ("not enough token balance");
        }
        else if(currency == ETH){
            if (amountFromBalance > msgValue)
                revert ("not enough ether balance");
        }
        return true;
    }

    function calculateFee(uint256 amountFromBalance) private view returns(address, uint256){
        ISalesRegistry _REGISTRY =  ISalesRegistry(salesRegistry);
        uint256 divisor100 = uint256(100).mul(10 **_REGISTRY.decimals());

        (address systemWallet, uint256 fee) = _REGISTRY.feeInfo();
        return (systemWallet, ((amountFromBalance.mul(fee)).div(divisor100)));
    }

    function calculateRoyalty(
        uint256 amountFromBalance, 
        address nftAddress,
        uint256 nftId,
        RoyaltyData memory royaltyData
    ) internal view returns(
        uint256[] memory splitRoyalty,
        uint256 total_royalty
    ){
        uint256 divisor100 = uint256(100).mul(10 ** ISalesRegistry(salesRegistry).decimals());

        //calculate royalty
        (address artistAddress, bytes32 msgHash) = INFT(nftAddress).checkRoyaltiHash(nftId);

        //check signature
        require(keccak256(abi.encodePacked(royaltyData.signature1)) ==  msgHash, "signature hash invalid");
        require(IAdmin(salesRegistry).isAdmin(recoverSigner(prefixed(keccak256(abi.encodePacked(
            msgHash,
            artistAddress
        ))), royaltyData.signature2)) == true, "signature artist invalid");

        //calculate
        splitRoyalty = new uint256[](royaltyData.royalty_recepient.length);
        total_royalty = (amountFromBalance.mul(royaltyData.main_percentage)).div(divisor100);

        for(uint256 i=0; i<royaltyData.royalty_recepient.length; i++){
            splitRoyalty[i] = (total_royalty.mul(royaltyData.royalty_percentage[i])).div(divisor100);
        }

        return (splitRoyalty, total_royalty);
    }

    function payment(
        uint256 amountFromBalance, 
        address pool,  
        uint256 fee, 
        uint256[] memory splitRoyalty, 
        address[] memory royaltyRecipient,
        uint256 total_royalty,
        address currency,
        address seller
    ) internal {
        //send value
        if(currency != ETH){ //if currency is token erc20
            IERC20 token = IERC20(currency);

            //send fee
            token.safeTransfer(pool, fee);

            //send royalty
            for(uint256 i=0; i<splitRoyalty.length; i++){
                token.safeTransfer(royaltyRecipient[i], splitRoyalty[i]);
            }

            //send seller
            token.safeTransfer(seller, ((amountFromBalance.sub(fee)).sub(total_royalty)));

        }
        else if(currency == ETH){
            //send fee
            _sent(pool, fee);

            //send royalty
            for(uint256 i=0; i<splitRoyalty.length; i++){
                _sent(royaltyRecipient[i], splitRoyalty[i]);
            }

            //send seller
            _sent(seller, ((amountFromBalance.sub(fee)).sub(total_royalty)));
        }
    }

    function _sent(address _to, uint256 _value) internal returns (bool){
        (bool sent,) =payable(_to).call{value: _value}("");
        return sent;
    }

    function nftTransfer(bool isERC721, address nftAddress, uint256 nftId, address from, address recipient, uint256 amountToBuy) internal {
        // send the nft to the buyer
        isERC721
            ? INFT(nftAddress).safeTransferFrom(
                from,
                recipient,
                nftId,
                ""
            )
            : INFT(nftAddress).safeTransferFrom(
                from,
                recipient,
                nftId,
                amountToBuy,
                ""
            );
    }

    function getSaleStatus(uint256 saleId) public view returns (uint256) {
        if (saleId > saleIdCounter.current() || saleId == 0) revert("Sale id is not exist");

        if (cancelledSale[saleId]) return 101; //"CANCELLED"

        SaleInfo memory saleInfo = sales[saleId];
        if (block.timestamp < saleInfo.startTime) return 102; //"PENDING"

        if (block.timestamp < saleInfo.endTime && saleInfo.purchased < saleInfo.amount) return 200; //"ACTIVE"

        if (block.timestamp >= saleInfo.endTime ||saleInfo.purchased == saleInfo.amount) return 103; //"ENDED"

        revert("Unexpected Error is sale status");
    }

    function getAuctionStatus(uint256 auctionId) public view returns (uint256) {
        if (auctionId > auctionIdCounter.current() || auctionId == 0) revert("Auction id is not exist");

        if (cancelledAuction[auctionId]) return 101; //"CANCELLED";

        if (claimed[auctionId]) return 103; //"ENDED & CLAIMED";

        uint256 startTime = auctions[auctionId].startTime;
        uint256 endTime = auctions[auctionId].endTime;

        if (block.timestamp < startTime) return 104; //"PENDING";

        if (block.timestamp >= startTime && block.timestamp < endTime) return 200; //"ACTIVE";

        if (block.timestamp > endTime) return 105; //"ENDED";

        revert("Unexpected Error is auction status");
    }

    function _beforeSaleOrAuction(
        address nftAddress,
        uint256 startTime,
        uint256 endTime,
        address currency
    ) private view{
        ISalesRegistry _REGISTRY =  ISalesRegistry(salesRegistry);
        // if (!_REGISTRY.platformContracts(nftAddress))
        //     revert NFTContractIsNotApproved();
        // if (!_REGISTRY.platformContracts(address(this)))
        //     revert ContractIsDeprecated();
        if (!_REGISTRY.checkCurrency(currency))
            revert("Currency is not supported");
        if (nftAddress == address(0))
            revert("nft must zero address");
        // if (!INFT(nftAddress).supportsInterface(0x2a55205a))
        //     revert ContractMustSupportERC2981();
        if (endTime <= startTime) revert("End time must be greater than start time");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISalesRegistry {
    function feeInfo() external view returns (address, uint256);
    function checkCurrency(address _currency) external view returns(bool);
    function decimals() external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INFT{
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function checkRoyaltiHash(uint256 tokenId) external view returns(address creator, bytes32 msgHash);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function supportsInterface(bytes4 interfaceID) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

//signature recover module
abstract contract SignatureRecover{

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
        '\x19Ethereum Signed Message:\n32', 
        hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
    
        (v, r, s) = splitSignature(sig);
    
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "invalid signature length");
    
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    
        return (v, r, s);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IAdmin {
    function addAdmin(address _address) external;
    function removeAdmin(address _address) external;
    function isAdmin(address _address) external view returns(bool);
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Admin is Ownable{
    event AddAdminLog(address indexed newAdmin);
    event RemoveAdminLog(address indexed removedAdmin);
    address[] admin;
    mapping(address=>bool) records;
    
    /**
    * @dev Modifier to check if function called by registered admins.
    */
    modifier onlyAdmin(){
        require(records[msg.sender]==true, "msg.sender must be admin");
        _;
    }

    /**
    * @dev Constructor. Set the creator of the contract as one of admin.
    */
    constructor() {
        admin.push(msg.sender);
        records[msg.sender] = true;
    }
    
    /**
    * @dev function to add new admin.
    * @param _address Address of new admin.
    */
    function addAdmin(address _address) onlyOwner() external {
        if (!records[_address]) {
            admin.push(_address);
            records[_address] = true;
            emit AddAdminLog(_address);
        }
    }

    /**
    * @dev function to remove an admin
    * @param _address Address of the admin that is going to be removed.
    */
    function removeAdmin(address _address) onlyOwner() external{
        for (uint i = 0; i < admin.length; i++) {
            if (admin[i] == _address) {
                delete admin[i];
                records[_address] = false;
                emit RemoveAdminLog(_address);
            }
        }
    }

    /**
    * @dev function to check whether the address is registered admin or not
    * @param _address Address to be checked.
    */
    function isAdmin(address _address) public view returns(bool) {
        return records[_address];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}