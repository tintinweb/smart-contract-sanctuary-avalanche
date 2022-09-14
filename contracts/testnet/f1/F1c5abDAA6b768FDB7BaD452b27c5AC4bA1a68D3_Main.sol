// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
// import "./Factory.sol";
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

contract Detective {
    function isERC721(address _contract) public view returns (bool) {
        if (IERC165(_contract).supportsInterface(type(IERC721).interfaceId)) {
            return true;
        } else if (IERC165(_contract).supportsInterface(type(IERC1155).interfaceId)) {
            return false;
        } else {
            return false;
        }
    }
}

interface IOwnerable {
    function owner() external view returns(address);
}

interface IRedeemAndFee {
    function accumulateTransactionFee(address user, uint royaltyFee, uint amount) external returns(uint transactionFee, uint, uint income);
}

interface IFactory {
    function decreaseTier0(uint tokenId, address user) external returns(uint8);
}

contract Main is Ownable, CloneFactory {
    using SafeERC20 for IERC20;

    address public key;
    address public marketFactory;
    address public redeemAndFee;
    Detective detect;
    address WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;     // for test
    address public treasury;

    enum FNFT_TYPE {None, Fixed, StepBy, Increament}

    struct PutOnSaleInfo {
        address maker;
        address collectionId;
        uint256 tokenId;
        uint256 amount;
        uint8 royaltyFee;
        uint8 royaltyShare;
        address admin;
        uint256 price;
        uint256 endPrice;
        FNFT_TYPE _type;
        AuctionInfo[] auctionInfo;
    }

    struct AuctionInfo {
        address taker;
        uint256 price;
        uint256 amount;
    }

    uint256 public flatFee = 15 * 10**16; // default fee 0.15 avax
    mapping(address => address[]) public userCollectionInfo;
    mapping(address => bool) _ableToCreatePrivateNFTforSale;
    mapping(address => bool) _ableToViewALLPrivateMetadata;
    mapping(bytes32 => PutOnSaleInfo) public listInfo;
    bytes32[] public hashList;

    enum ContractType {
        ERC721,
        ERC1155,
        Unknown
    }

    constructor() {
        detect = new Detective();
    }

    function _makeHash(
        address user,
        address collectionId,
        uint256 tokenId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, collectionId, tokenId));
    }

    function setFlatFee(uint256 _fee) public onlyOwner {
        flatFee = _fee;
    }

    function AbleToCreatePrivateNFTforSale(address user) external view returns (bool) {
        return _ableToCreatePrivateNFTforSale[user];
    }

    function setAbleToCreatePrivateNFTforSale(address user, bool flag) external onlyOwner {
        _ableToCreatePrivateNFTforSale[user] = flag;
    }

    function AbleToViewALLPrivateMetadata(address user) external view returns (bool) {
        return _ableToViewALLPrivateMetadata[user];
    }

    function setAbleToViewALLPrivateMetadata(address user, bool flag) external onlyOwner {
        _ableToViewALLPrivateMetadata[user] = flag;
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

    function setKey(address _key) public onlyOwner {
        key = _key;
    }

    function creatCollection(string memory collectionMetadata, uint256 size) external payable {
        if (msg.sender != owner()) require(msg.value == flatFee, "Main: insufficient flat fee");
        address subFactory = createClone(marketFactory);
        // MarketFactory subFactory = new MarketFactory();
        userCollectionInfo[msg.sender].push(subFactory);
        IMarketFactory(subFactory).initialize(address(this));
        IMarketFactory(subFactory).setSize(size);
        IMarketFactory(subFactory).setCollectionInfo(collectionMetadata);
        IMarketFactory(subFactory).setMarketplace(address(this));
        IMarketFactory(subFactory).transferOwnership(msg.sender);
    }

    function putOnSale(
        address collectionId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 endPrice,
        uint8 royaltyFee,
        uint8 royaltyShare,
        FNFT_TYPE _type,
        bool setRoyaltyFee
    ) external {
        require(_detect(collectionId) != ContractType.Unknown, "Main: not NFT contract");
        require(endPrice >= price, "Main:invalid endPrie");
        bytes32 _key = _makeHash(msg.sender, collectionId, tokenId);
        if (listInfo[_key].maker == address(0) && listInfo[_key].collectionId == address(0)) {
            hashList.push(_key);
            listInfo[_key].maker = msg.sender;
            listInfo[_key].collectionId = collectionId;
        }
        listInfo[_key].amount = amount;
        listInfo[_key]._type = _type;
        listInfo[_key].price = price;
        listInfo[_key].endPrice = endPrice;

        if (_detect(collectionId) == ContractType.ERC721) {
            require(IERC721(collectionId).ownerOf(tokenId) == msg.sender, "Main:721-not owner");
            if(setRoyaltyFee) {
                require(_detectOwner(collectionId) == msg.sender, "Main:ERC721-no permission for royaltyFee");
                listInfo[_key].royaltyFee = royaltyFee;
                listInfo[_key].royaltyShare = royaltyShare;
                listInfo[_key].admin = msg.sender;
            } else {
                listInfo[_key].royaltyFee = 5;
                listInfo[_key].royaltyShare = 100;
            }

            // IERC721(collectionId).safeTransferFrom(msg.sender, address(this), tokenId);
            // IERC721(collectionId).setApprovalForAll(address(this), true);
        } else if(_detect(collectionId) == ContractType.ERC1155) {
            require(IERC1155(collectionId).balanceOf(msg.sender, tokenId) >= amount, "Main:1155-not owner");
            if(setRoyaltyFee) {
                require(_detectOwner(collectionId) == msg.sender, "Main:ERC1155-no permission for royaltyFee");
                listInfo[_key].royaltyFee = royaltyFee;
                listInfo[_key].royaltyShare = royaltyShare;
                listInfo[_key].admin = msg.sender;
            } else {
                try IERC1155(collectionId).getUserInfo(tokenId) returns(uint8 _royaltyFee, uint8 _royaltyShare, uint8 nftType, uint, address admin) {
                    require(nftType != 2, "Main:can't trade with sNFT");
                    listInfo[_key].royaltyFee = _royaltyFee;
                    listInfo[_key].royaltyShare = _royaltyShare;
                    listInfo[_key].admin = admin;
                } catch {
                    listInfo[_key].royaltyFee = 5;
                    listInfo[_key].royaltyShare = 100;
                }
            }

            // IERC1155(collectionId).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
            // IERC1155(collectionId).setApprovalForAll(address(this), true);
        }
    }

    function cancelList (bytes32 _key) external {
        require(listInfo[_key].maker == msg.sender, "Main: not owner");
        
        if (_detect(listInfo[_key].collectionId) == ContractType.ERC721) {
            // IERC721(collectionId).safeTransferFrom(msg.sender, address(this), tokenId);
            IERC721(listInfo[_key].collectionId).setApprovalForAll(address(this), true);
        } else if(_detect(listInfo[_key].collectionId) == ContractType.ERC1155) {
            // IERC1155(collectionId).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
            IERC1155(listInfo[_key].collectionId).setApprovalForAll(address(this), true);
        }
        _cancelList(_key);
    }

    function _cancelList (bytes32 _key) private {
        for(uint i = 0; i < hashList.length; i++) {
            if(hashList[i] == _key) {
                hashList[i] = hashList[hashList.length - 1];
                hashList.pop();
                break;
            }
        }
        listInfo[_key].maker = address(0);
        listInfo[_key].collectionId = address(0);
        listInfo[_key].amount = 0;

        // if (_detect(listInfo[_key].collectionId) == ContractType.ERC721) {
        //     IERC721(listInfo[_key].collectionId).safeTransferFrom(msg.sender, address(this), listInfo[_key].tokenId);
        // } else {
        //     IERC1155(listInfo[_key].collectionId).safeTransferFrom(msg.sender, address(this), listInfo[_key].tokenId, listInfo[_key].amount, "");
        // }
    }

    function _detect(address _contract) public view returns (ContractType) {
        try (detect).isERC721(_contract) returns (bool result) {
            if (result) return ContractType.ERC721;
            else return ContractType.ERC1155;
        } catch {
            return ContractType.Unknown;
        }
    }

    function _detectOwner(address _contract) private view returns (address) {
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
    ) external {
        require(listInfo[_key].maker != msg.sender, "Main: invalid user");
        require(amount * price > 0, "Main:invalid amount");
        require(
            listInfo[_key].maker != address(0) && listInfo[_key].collectionId != address(0),
            "Main: invalid hash id"
        );
        require(listInfo[_key].amount >= amount, "Main: overflow of amount");

        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        bool isExist;
        for(uint i = 0; i < auctionInfoList.length; i++) {
            if(auctionInfoList[i].taker == msg.sender) {
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

        IERC20(WAVAX).safeTransferFrom(msg.sender, address(this), amount * price);
    }

    function cancelAuction (bytes32 _key) external {
        AuctionInfo[] storage auctionInfoList = listInfo[_key].auctionInfo;
        uint amount;
        uint price;
        for (uint i = 0; i < auctionInfoList.length; i++) {
            if( auctionInfoList[i].taker == msg.sender ) {
                amount = auctionInfoList[i].amount;
                price = auctionInfoList[i].price;
                auctionInfoList[i] = auctionInfoList[auctionInfoList.length - 1];
                auctionInfoList.pop();
                break;
            }
        }
        require(amount > 0, "Main:invalid user");
        IERC20(WAVAX).safeTransfer(msg.sender, amount * price);
    }
    
    function getListInfo (address _collectionId, uint256 _tokenId) external view returns(address maker, uint256 amount, AuctionInfo[] memory acutionInfo) {
        bytes32 _key = _makeHash(msg.sender, _collectionId, _tokenId);
        acutionInfo = new AuctionInfo[](listInfo[_key].auctionInfo.length);
        for(uint i = 0; i < acutionInfo.length; i++) {
            acutionInfo[i] = listInfo[_key].auctionInfo[i];
        }
        return (listInfo[_key].maker, listInfo[_key].amount, acutionInfo);
    }

    function buyNow(bytes32 _key) external {
        address maker = listInfo[_key].maker;
        require(maker != address(this), "Main:unlisted");
        require(maker != msg.sender, "Main:maker not buy");
        if(_detect(listInfo[_key].collectionId) == ContractType.ERC721) {
            require(IERC721(listInfo[_key].collectionId).ownerOf(listInfo[_key].tokenId) == maker, "Main:not 721 owner");
            uint amount = listInfo[_key].amount;
            _exchangeDefaultNFT(_key, amount, listInfo[_key].price, false);
        } else if (_detect(listInfo[_key].collectionId) == ContractType.ERC1155) {
            uint amount;
            try IERC1155(listInfo[_key].collectionId).getUserInfo(listInfo[_key].tokenId) returns(uint8, uint8, uint8 nftType, uint, address) {
                require(nftType != 3, "Main: cannot trade");
                if(nftType == 0 || nftType == 2 || nftType == 4) {      // default NFT or Tier0 NFT or PRIVATE NFT
                    amount = listInfo[_key].amount;
                    if(IERC1155(listInfo[_key].collectionId).balanceOf(maker, listInfo[_key].tokenId) < amount) {
                        amount = IERC1155(listInfo[_key].collectionId).balanceOf(maker, listInfo[_key].tokenId);
                    }
                    _exchangeDefaultNFT(_key, amount, listInfo[_key].price, false);
                } else if (nftType == 1) { // FNFT
                    uint8 step = IFactory(marketFactory).decreaseTier0(listInfo[_key].tokenId, msg.sender);
                    uint price;
                    if (listInfo[_key]._type == FNFT_TYPE.Fixed) price = listInfo[_key].price;
                    else if (listInfo[_key]._type == FNFT_TYPE.StepBy) {
                        uint delta = listInfo[_key].endPrice - listInfo[_key].price;
                        price = listInfo[_key].price + delta * (step - 1) / 9;
                    } else if (listInfo[_key]._type == FNFT_TYPE.Increament) {
                        price = listInfo[_key].price * 11 ** (step - 1) / 10 ** (step - 1);
                    }
                    _exchangeDefaultNFT(_key, 1, listInfo[_key].price, true);
                }
            } catch {
                amount = listInfo[_key].amount;
                if(IERC1155(listInfo[_key].collectionId).balanceOf(maker, listInfo[_key].tokenId) < amount) {
                    amount = IERC1155(listInfo[_key].collectionId).balanceOf(maker, listInfo[_key].tokenId);
                }
                _exchangeDefaultNFT(_key, amount, listInfo[_key].price, false);
            }

        }
    }

    function _exchangeDefaultNFT(bytes32 _key, uint amount, uint price, bool isFNFT) private {
        require(amount * price > 0, "Main: insufficient 1155");
        (,uint royaltyAmount, uint income) = IRedeemAndFee(redeemAndFee).accumulateTransactionFee(msg.sender, listInfo[_key].royaltyFee, amount * price);
        IERC20(WAVAX).safeTransfer(listInfo[_key].maker, income);
        if(listInfo[_key].admin != address(0) && 100 - listInfo[_key].royaltyShare > 0) {
            IERC20(WAVAX).safeTransfer(listInfo[_key].admin, royaltyAmount * (100 - listInfo[_key].royaltyShare) / 100);
        }
        IERC20(WAVAX).safeTransfer(treasury, royaltyAmount * listInfo[_key].royaltyShare / 100);
        if(!isFNFT)
            IERC721(listInfo[_key].collectionId).safeTransferFrom(listInfo[_key].maker, msg.sender, listInfo[_key].tokenId);
    }

    function makeOffer(bytes32 _key, address taker) external {
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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