// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./CloneFactory.sol";

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

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
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
}

interface IMarketFactory {
    function _tokenIds() external view returns (uint256);

    function uri(uint256 tokenId) external view returns (string memory);

    function setSize(uint256 _size) external;

    function setCollectionInfo(string memory _uri) external;

    function setMarketplace(address _marketplace) external;

    function transferOwnership(address newOwner) external;

    function initialize(address newOnwer) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function getUserInfo(uint tokenId) external view returns(uint8 royaltyFee, uint8 royaltyShare, uint8 nftType, uint tier0Cnt, address admin);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

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

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IOwnerable {
    function owner() external view returns(address);
}

interface IRedeemAndFee {
    function accumulateTransactionFee(address user, uint royaltyFee, uint amount) external returns(uint transactionFee, uint, uint income);
    function unCliamedReward(address user) external view returns(uint amount);
    function claim(address user) external;
    function getBlackList (address user) external view returns(bool);
    function unclassifiedList(address user) external view returns (bool);
    function flatFee() external view returns (uint);
    function ableToViewALLPrivateMetadata(address user) external view returns(bool);
}

interface IFactory {
    // function decreaseTier0(uint tokenId, address user) external returns(uint8, uint256);
    // function initialTier0(uint tokenId) external;
    function tier0TokenId() external view returns(uint256);
    function getUserInfo(uint tokenId) external view returns(uint8 royaltyFee, uint8 royaltyShare, uint8 nftType, address tier0, address admin);
}

interface ITier0 {
    function setType(uint8 _type) external;
    function getState() external view returns(uint256 total, uint256 current);
    function mint(address user, uint256 amount) external;
    function disput(address user, uint256 amount) external;
    function cancelList() external;
    function isSaleOver() external view returns(bool);
    function requireValidAmount(uint256 amount) external view;
}

contract FNFT_Market is Ownable, CloneFactory {
    using SafeERC20 for IERC20;

    address public marketFactory;
    address public redeemAndFee;
    address immutable WAVAX; // 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;     // for test
    address public treasury;
    address[] buyerNum;
    uint buyerNumLen = 0;

    enum FNFT_TYPE {Fixed, StepBy, Increament}

    struct PutOnSaleInfo {
        address maker;
        address collectionId;
        uint256 tokenId;
        uint8 royaltyFee;
        uint8 royaltyShare;
        address admin;
        address coin;
        uint256 price;
        uint256 endPrice;
        FNFT_TYPE _type;
        AuctionInfo[] auctionInfo;
        bool isAlive;
        uint256 expirate;
        bool isEscrowFNFT;
    }

    struct AuctionInfo {
        address taker;
        uint256 price;
        uint256 amount;
    }

    struct FNFTBuyerInfo {
        address buyer;
        uint price;
        uint amount;
    }

    struct TradingInfo {
        uint index;
        bytes32 key;
        uint price;
        uint amount;
        bool isCancel;
    }

    struct WithdrawInfo {
        uint lockedAmount;
        uint withdrawAmount;
    }

    mapping(address => address[]) public userCollectionInfo;

    mapping(bytes32 => PutOnSaleInfo) listInfo;
    mapping(bytes32 => FNFTBuyerInfo[]) buyerInfo;
    mapping(bytes32 => WithdrawInfo) withdrawInfo;
    mapping(address => uint8) royaltyFeeForExternal;
    mapping(address => uint256[]) userTokenInfo;
    mapping(uint256 => mapping(address => TradingInfo)) tradingInfo;
    // bytes32[] public hashList;

    event CreateCollection(address indexed collectionId);
    event PutOnSaleEvent(
        bytes32 _key,
        uint8 royaltyFee,
        uint8 royaltyShare,
        address admin
    );
    // event TradingNFT(uint256 amount, uint256 price, uint256 income, address maker, address taker, uint256 remain);
    event TradingNFT(uint256 price, uint256 income, address maker, address taker);
    event RoyaltyHistory(uint256 royaltyFee, address admin);

    modifier isBlackList() {
        require(false == IRedeemAndFee(redeemAndFee).getBlackList(msg.sender), "FNFT:blackLiser");
        _;
    }

    constructor(address _WAVAX) {
        WAVAX = _WAVAX;
    }

    function find(address value) private returns(uint) {
        uint i = 0;
        while (buyerNum[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(address value) private {
        uint i = find(value);
        removeByIndex(i);
    }

    function removeByIndex(uint i) private {
        while (i<buyerNumLen-1) {
            buyerNum[i] = buyerNum[i+1];
            i++;
        }
        buyerNumLen--;
    }

    function _makeHash(
        address user,
        address collectionId,
        uint256 tokenId,
        uint currentTime
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, collectionId, tokenId, currentTime));
    }

    function setTreasury(address wallet) external onlyOwner {
        treasury = wallet;
    }

    function setMarketFactory(address factory) external onlyOwner {
        marketFactory = factory;
    }

    function setRedeemFeeContract(address _contract) external onlyOwner {
        redeemAndFee = _contract;
    }

    function putOnSale(
        address collectionId,
        uint256 tokenId,
        address coin,
        uint256 price,
        uint256 endPrice,
        uint8 royaltyFee,
        FNFT_TYPE _type,
        bool setRoyaltyFee,
        address user,
        uint256 exp,     // expirate time (unit days)
        bool isEscrow       // FNFT escrow mode
    ) external payable isBlackList {
        if(user != msg.sender)
            require(IRedeemAndFee(redeemAndFee).ableToViewALLPrivateMetadata(msg.sender), "FNFT:no angel");
        if(user != detectOwner(collectionId))
            require(msg.value == IRedeemAndFee(redeemAndFee).flatFee(), "FNFT:wrong flatfee");
        if(_type == FNFT_TYPE.StepBy)
            require(endPrice >= price, "FNFT:IV endPrie");
        // if(_type == FNFT_TYPE.Increament)
        //     require(endPrice < 21 && endPrice > 9, "FNFT:IV rate");
        bytes32 _key = _makeHash(user, collectionId, tokenId, block.timestamp);
        require(!listInfo[_key].isAlive || (listInfo[_key].isAlive && listInfo[_key].expirate < block.timestamp && listInfo[_key].expirate != 0), "FNFT: alreay listed");
        if (listInfo[_key].maker == address(0) && listInfo[_key].collectionId == address(0)) {
            // hashList.push(_key);
            listInfo[_key].maker = user;
            listInfo[_key].collectionId = collectionId;
            listInfo[_key].tokenId = tokenId;
        }
        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(tokenId);
        ITier0(tier0).setType(uint8(_type));
        listInfo[_key]._type = _type;
        listInfo[_key].coin = coin;
        listInfo[_key].price = price;
        listInfo[_key].endPrice = endPrice;
        listInfo[_key].isAlive = true;
        listInfo[_key].expirate = exp > 0 ? block.timestamp + exp * 1 days : 0;
        listInfo[_key].isEscrowFNFT = isEscrow;
        userTokenInfo[user].push(tokenId);
        address collectionOwner = detectOwner(collectionId);

        if(setRoyaltyFee) {
            require(collectionOwner == user, "FNFT:721-no owner");
            royaltyFeeForExternal[user] = royaltyFee;
        }

        if(collectionOwner != address(0) && royaltyFeeForExternal[user] != 0) {         // But when the original contract owner will come and verify and set the roatlity fee...
             listInfo[_key].admin = collectionOwner;
             listInfo[_key].royaltyFee = royaltyFeeForExternal[user];
        }
        _putonSaleFor1155(_key, collectionId, tokenId); // lock this FNFT when put on sale
        if(msg.sender != user) {        // lazy mode
            listInfo[_key].royaltyShare = 50;       // 50% will be left in this contract and the other %50 fee will go to the nft angel
            listInfo[_key].admin = msg.sender;      // NFT angel
        }   
        if(msg.value > 0)
            payable (treasury).transfer(msg.value);
        emit PutOnSaleEvent(
            _key,
            listInfo[_key].royaltyFee,
            listInfo[_key].royaltyShare,
            listInfo[_key].admin
        );
    }

    function _putonSaleFor1155(bytes32 _key, address collectionId, uint tokenId) private {
        try IERC1155(collectionId).getUserInfo(tokenId) returns(uint8 _royaltyFee, uint8 _royaltyShare, uint8 nftType, uint, address admin) {
            require(nftType == 1, "FNFT:no trade");
            listInfo[_key].royaltyFee = _royaltyFee;
            listInfo[_key].royaltyShare = _royaltyShare;
            listInfo[_key].admin = admin;
            IERC1155(collectionId).safeTransferFrom(msg.sender, address(this), tokenId, 1, ""); // lock this FNFT when put on sale
        } catch {
            require(false, "FNFT:no FNFT");
        }
    }

    function cancelList (bytes32 _key) external isBlackList {
        require(listInfo[_key].maker == msg.sender && listInfo[_key].isAlive, "FNFT:not owner");
        require(withdrawInfo[_key].withdrawAmount == 0, "FNFT: no permission");
        listInfo[_key].isAlive = false;
        listInfo[_key].expirate = 0;
        uint tokenId = listInfo[_key].tokenId;
        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);

        for(uint i; i < buyerNumLen; i++)
        {
            ITier0(tier0).disput(buyerNum[i], tradingInfo[tokenId][(buyerNum[i])].amount);
            tradingInfo[tokenId][(buyerNum[i])].isCancel = true;
        }

        // require(buyerInfo[_key][9].buyer == address(0), "FNFT:saled");
        IERC1155(listInfo[_key].collectionId).safeTransferFrom(address(this), msg.sender, listInfo[_key].tokenId, 1, "");
        ITier0(tier0).cancelList();
    }

    /* 
    * after canceling FNFT, user can refund
    */
    function sellTier0(bytes32 _key) external isBlackList {
        // require(listInfo[_key].isAlive == false, "FNFT:cant refund");
        // uint price;
        // uint amount;
        // for(uint i = 0; i < 10; i++) {
        //     if(buyerInfo[_key][i].buyer == msg.sender) {
        //         price += buyerInfo[_key][i].price;
        //         amount += buyerInfo[_key][i].amount;
        //         delete  buyerInfo[_key][i];
        //     }
        // }
        // require(price > 0, "FNFT:IV user");
        // address coin = listInfo[_key].coin;
        // IERC20(coin).safeTransfer(msg.sender, price);
        // IERC1155(listInfo[_key].collectionId).safeTransferFrom(msg.sender, marketFactory, IFactory(marketFactory).tier0TokenId(), amount, "");
    }

    /* 
    * withdraw funds from sold tier0
    */
    function withDrawFromFNFT(bytes32 _key, uint amount) external isBlackList {
        require(listInfo[_key].maker == msg.sender, "FNFT:no owner");
        require(!listInfo[_key].isEscrowFNFT, "FNFT:escrow enabled");
        require(withdrawInfo[_key].lockedAmount >= withdrawInfo[_key].withdrawAmount + amount, "FNF: insuffience balance");
        // require(buyerInfo[_key][9].buyer != address(0), "FNFT:not saled");
        withdrawInfo[_key].withdrawAmount += amount;
        (,, uint income) = IRedeemAndFee(redeemAndFee).accumulateTransactionFee(msg.sender, 0, amount);
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransfer(msg.sender, income);
    }

    /* 
    * withdraw funds from sold tier0
    */
    function refundToFNFT(bytes32 _key, uint amount) external isBlackList {
        require(listInfo[_key].maker == msg.sender, "FNFT:no owner");
        require(!listInfo[_key].isEscrowFNFT, "FNFT:escrow enabled");
        require(withdrawInfo[_key].withdrawAmount >= amount, "FNF: overflow refund");
        // require(buyerInfo[_key][9].buyer != address(0), "FNFT:not saled");
        withdrawInfo[_key].withdrawAmount -= amount;
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransferFrom(msg.sender, address(this), amount);
    }

    function detectOwner(address _contract) public view returns (address) {
        try IOwnerable(_contract).owner() returns (address owner) {
            return owner;
        } catch {
            return address(0);
        }
    }

    function auction(
        bytes32 _key,
        uint256 price,
        uint256 amount
    ) external isBlackList {
        require(listInfo[_key].maker != msg.sender, "FNFT:IV user");
        require(amount>0 && price > 0, "FNFT:IV amount");
        require(listInfo[_key].isAlive && listInfo[_key].expirate >= block.timestamp, "FNFT:IV hash id");
        // require(listInfo[_key].amount >= amount, "FNFT:overflow");
        (,,,address tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);
        ITier0(tier0).requireValidAmount(amount);
        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        bool isExist;
        uint oldValue;
        for(uint i = 0; i < auctionInfoList.length; i++) {
            if(auctionInfoList[i].taker == msg.sender) {
                oldValue = auctionInfoList[i].price;
                auctionInfoList[i].price = price;
                auctionInfoList[i].amount = amount;
                isExist = true;
                break;
            }
        }
        if(!isExist) {
            AuctionInfo memory auctionInfo = AuctionInfo({ taker: msg.sender, price: price, amount: amount });
            listInfo[_key].auctionInfo.push(auctionInfo);
        }

        address coin = listInfo[_key].coin;
        if(price > oldValue) {
            IERC20(coin).safeTransferFrom(msg.sender, address(this), price - oldValue);
        } else if (price < oldValue) {
            IERC20(coin).safeTransfer(msg.sender, oldValue - price);
        }
        // _trading(_key, msg.sender, amount, price);
    }

    function cancelAuction (bytes32 _key) external isBlackList {
        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        uint amount = 0;
        uint price = 0;
        for (uint i = 0; i < auctionInfoList.length; i++) {
            if( auctionInfoList[i].taker == msg.sender ) {
                amount = auctionInfoList[i].amount;
                price = auctionInfoList[i].price;
                auctionInfoList[i] = auctionInfoList[auctionInfoList.length - 1];
                auctionInfoList.pop();
                break;
            }
        }
        require(amount > 0 && price > 0, "FNFT:invalid user");
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransfer(msg.sender, price);
    }

    function buyNow(bytes32 _key, uint256 amount) external isBlackList {                
        require(listInfo[_key].maker != address(this), "FNFT:unlisted");
        require(listInfo[_key].maker != msg.sender && listInfo[_key].isAlive && listInfo[_key].expirate >= block.timestamp, "FNFT:IV maker");
        _trading(_key, msg.sender, amount, 0);
    }
    
    function getTier0Price_0(bytes32 _key, uint256 amount, uint256 total, uint256 current) private view returns(uint256 price, uint256 step) {

        price = (listInfo[_key].price) * amount / total;
        step = (current + amount) * 10 / total;
    }

    function getTier0Price_1(bytes32 _key, uint256 amount, uint256 total, uint256 current) private view returns(uint256 price, uint256 step) {
        uint256 unit = 0;
        uint256 rest = 0;
        uint i = 0;
        uint j = 0;

        unit = total / 10;
        i = current / unit;
        rest = unit - current % unit;
        uint delta = (listInfo[_key].endPrice - listInfo[_key].price) / 10;
        j = (current + amount) / unit;

        if(rest < amount)
        {
            price = (delta * i + listInfo[_key].price) * rest / unit;
            i++;

            if(j == i)
              price = (delta * i + listInfo[_key].price) * (amount - rest) / unit;
            else
              {
                price += (i + j) * (j - i + 1) / 2 * delta + (j - i + 1) * listInfo[_key].price;
                i = j;

                if((current + amount) % unit != 0)
                   price = (delta * i + listInfo[_key].price) * ((current + amount) % unit) / unit;
              }
        }
        else
        {
            price = (delta * i + listInfo[_key].price) * amount / unit;
            if(rest == amount)
                i++;
        }
        step = i;
    }

    function getTier0Price_2(bytes32 _key, uint256 amount, uint256 total, uint256 current) private view returns(uint256 price, uint256 step) {
        uint256 unit = 0;
        uint256 rest = 0;
        uint i = 0;

        unit = total / 10;
        i = current / unit;
        rest = unit - current % unit;
        uint delta = listInfo[_key].price / 10;

        if(rest < amount)
        {
            (price, step) = getTier0Price_3(_key, amount, total, current);
        }
        else
        {
            price = (delta ** i + listInfo[_key].price) * amount / unit;
            if(rest == amount)
                i++;
        }
        step = i;
    }

    function getTier0Price_3(bytes32 _key, uint256 amount, uint256 total, uint256 current) private view returns(uint256 price, uint256 step) {
        uint256 unit = 0;
        uint256 rest = 0;
        uint i = 0;
        uint j = 0;
        uint k = 0;

        unit = total / 10;
        i = current / unit;
        rest = unit - current % unit;
        uint delta = listInfo[_key].price / 10;
        j = (current + amount) / unit;


        price = (delta ** i + listInfo[_key].price) * rest / unit;
        i++;

        if(j == i)
            price = (delta ** i + listInfo[_key].price) * (amount - rest) / unit;
        else
            {
            for(k = i; k <= j; k++)
                price += delta ** k  + listInfo[_key].price;
            i = j;

            if((current + amount) % unit != 0)
                price += (delta ** i + listInfo[_key].price) * ((current + amount) % unit) / unit;
            }

        step = i;
    }

    function getTier0Price(bytes32 _key, uint256 amount) public view returns(uint256 price, uint256 step) {
        uint256 _total = 0;
        uint256 _current = 0;
        address tier0;

        (,,, tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);
        (_total, _current) = ITier0(tier0).getState();

        if (listInfo[_key]._type == FNFT_TYPE.Fixed)
            (price, step) = getTier0Price_0(_key, amount, _total, _current);
        else if (listInfo[_key]._type == FNFT_TYPE.StepBy) {
            (price, step) = getTier0Price_1(_key, amount, _total, _current);
        } else if (listInfo[_key]._type == FNFT_TYPE.Increament) {
            (price, step) = getTier0Price_2(_key, amount, _total, _current);
        }
    }

    function _trading (bytes32 _key, address user, uint256 amount, uint price) private {
        require(listInfo[_key].isAlive && listInfo[_key].expirate >= block.timestamp, "FNFT: invalid nft");
        
        // (uint8 step, uint amount) = ITier0(tier0).decreaseTier0(listInfo[_key].tokenId, user);
        uint256 step;
        address tier0;
        uint256 _total = 0;
        uint256 _current = 0;
        (,,, tier0,) = IFactory(marketFactory).getUserInfo(listInfo[_key].tokenId);
        (_total, _current) = ITier0(tier0).getState();

        if(price == 0){
            (price, step) = getTier0Price(_key, amount);
        } else {  
            step = (amount + _current) * 10 / _total;
        }
        FNFTBuyerInfo[] storage info = buyerInfo[_key];
        info.push(FNFTBuyerInfo(user, price, amount));
        withdrawInfo[_key].lockedAmount += price;

        // buyerInfo[_key][step-1].buyer = user;
        // buyerInfo[_key][step-1].price = price;
        // buyerInfo[_key][step-1].amount = amount;
        address coin = listInfo[_key].coin;
        IERC20(coin).safeTransferFrom(user, address(this), price);
        ITier0(tier0).mint(user, amount);
        uint tokenId = (listInfo[_key].tokenId);

        if(tradingInfo[(tokenId)][user].amount > 0 && !tradingInfo[tokenId][user].isCancel)
        {
            tradingInfo[tokenId][user].amount += amount;
            tradingInfo[tokenId][user].price += price;
        }
        else{
            tradingInfo[tokenId][user].amount = amount;
            tradingInfo[tokenId][user].price = price;
            tradingInfo[tokenId][user].key = _key;
            tradingInfo[tokenId][user].isCancel = false;
            buyerNum.push(user);
            buyerNumLen++;
        }

        if(step == 10) listInfo[_key].isAlive = false;
    }

    function makeOffer(bytes32 _key, address taker) external isBlackList {
        require(listInfo[_key].isAlive && msg.sender == listInfo[_key].maker, "FNFT:not maker");
        bool isExist = false;
        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        for(uint i = 0; i < auctionInfoList.length; i++) {
            if(auctionInfoList[i].taker == taker) {
                uint _amount = auctionInfoList[i].amount;
                uint _price = auctionInfoList[i].price;
                _trading(_key, taker, _amount, _price);
                auctionInfoList[i] = auctionInfoList[auctionInfoList.length - 1];
                auctionInfoList.pop();
                isExist = true;
                break;
            }
        }
        require(isExist, "Main:no user");
    }
    
    function UnClassifiedList(address user) private view returns(bool) {
        return IRedeemAndFee(redeemAndFee).unclassifiedList(user);
    }

    function ListInfo(bytes32 _key) external view returns(PutOnSaleInfo memory info, bool isValid) {
        if(UnClassifiedList(listInfo[_key].maker)) {
            return (info, false);
        }
        return (listInfo[_key], true);
    }

    function BuyerInfo(bytes32 _key) external view returns (FNFTBuyerInfo[] memory info) {
        return buyerInfo[_key];
    }

    function getWithdrawInfo(bytes32 _key) external view returns (WithdrawInfo memory info) {
        return withdrawInfo[_key];
    }

    function getUserTokenInfo(address user) external view returns(uint256[] memory ids) {
        return userTokenInfo[user];
    }

    function getTradingInfo(uint256 tokenId, address buyer) external view returns(TradingInfo memory info) {
        return tradingInfo[tokenId][buyer];
    }

    function cancelBuy(uint256 tokenID, address taker) external isBlackList {
        bytes32 key = tradingInfo[tokenID][taker].key;
        require(listInfo[key].isAlive && !tradingInfo[tokenID][taker].isCancel &&  ((withdrawInfo[key].lockedAmount - withdrawInfo[key].withdrawAmount) >= tradingInfo[tokenID][taker].price), "FNFT:not Tier0 Price");

        address coin = listInfo[key].coin;
        address tier0;
        (,,, tier0,) = IFactory(marketFactory).getUserInfo(listInfo[key].tokenId);
        IERC20(coin).safeTransferFrom(address(this), taker, tradingInfo[tokenID][taker].price);
        ITier0(tier0).disput(taker, tradingInfo[tokenID][taker].amount);
        withdrawInfo[key].lockedAmount -= tradingInfo[tokenID][taker].price;
        tradingInfo[tokenID][taker].isCancel = true;
        removeByValue(taker);
        delete tradingInfo[tokenID][taker];
    }

    function claim(uint256 tokenID, address taker) external isBlackList {
        bytes32 key = tradingInfo[tokenID][taker].key;
        require(!listInfo[key].isAlive && tradingInfo[tokenID][taker].isCancel &&  ((withdrawInfo[key].lockedAmount - withdrawInfo[key].withdrawAmount) >= tradingInfo[tokenID][taker].price), "FNFT:not Tier0 Price");

        address coin = listInfo[key].coin;
        IERC20(coin).safeTransferFrom(address(this), taker, tradingInfo[tokenID][taker].price);
        withdrawInfo[key].lockedAmount -= tradingInfo[tokenID][taker].price;
        removeByValue(taker);
        delete tradingInfo[tokenID][taker]; 
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}