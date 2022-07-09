// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    function metadata(uint256 tokenId) external view returns (address creator);
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Fiat {
    function getToken2USD(string memory _symbol) external view returns (string memory _symbolToken, uint256 _token2USD);
}

contract Withdrawable is Ownable {
    string internal constant REVERT_TRANSFER_FAILED = "Withdrawable: AVAX_TRANSFER_FAILED";

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        address account = _msgSender();
        if (_token == address(0)) {
            (bool success, ) = account.call{value: _amount}(new bytes(0));
            require(success, REVERT_TRANSFER_FAILED);
        } else {
            IERC20(_token).transfer(account, _amount);
        }
    }
}

contract GameFiat is Ownable {
    event SetFiat(string[] symbols, address[] addresses);
    
    using SafeMath for uint256;

    struct Token {
        string symbol;
        bool existed;
    }

    Fiat public fiatContract;
    
    address[] public fiat;
    mapping(address => Token) public tokensFiat;

    string internal constant REVERT_NULL_ADDRESS = "Can not be address 0";
    string internal constant REVERT_LENGTH_MISMATCH = "Length mismatch";

    function setFiatContract(address _fiatContract) external onlyOwner {
        require(_fiatContract != address(0), REVERT_NULL_ADDRESS);
        fiatContract = Fiat(_fiatContract);
    }

    function setFiat(string[] memory _symbols, address[] memory _addresses) external onlyOwner {
        require(_symbols.length == _addresses.length, REVERT_LENGTH_MISMATCH);
        uint256 length = _symbols.length;
        for (uint256 i = 0; i < length; i++) {
            tokensFiat[_addresses[i]].symbol = _symbols[i];
            if (!tokensFiat[_addresses[i]].existed) {
                tokensFiat[_addresses[i]].existed = true;
                fiat.push(_addresses[i]);
            }
        }
        emit SetFiat(_symbols, _addresses);
    }

    function _isValidFiat(address[] memory _fiat) internal view returns (bool) {
        uint256 length = _fiat.length;
        bool isValid = true;
        for (uint256 i = 0; i < length; i++) {
            bool isExist = tokensFiat[_fiat[i]].existed;
            if (!isExist) {
                isValid = false;
                break;
            }
        }
        return isValid;
    }

    function price2wei(uint256 _price, address _fiatBuy) public view returns (uint256) {
        (, uint256 weitoken) = fiatContract.getToken2USD( tokensFiat[_fiatBuy].symbol);
        return _price.mul(weitoken).div(1 ether);
    }

    function getFiat() external view returns (address[] memory) {
        return fiat;
    }

    function getTokenFiat(address _fiat) external view returns (string memory, bool) {
        return (tokensFiat[_fiat].symbol, tokensFiat[_fiat].existed);
    }
}

contract Marketplace is GameFiat, Withdrawable {
    event SetPrice(address game, uint256[] tokenIds, uint256 price, uint256 orderType);
    event ResetPrice(address game, uint256 orderId);
    event Buy(address account, address game, uint256 orderId, address fiatBuy);
    
    using SafeMath for uint256;

    struct GameFee {
        string fee;
        address taker;
        uint256 percent;
        bool existed;
    }

    struct Price {
        uint256[] tokenIds;
        address maker;
        uint256 price;
        address[] fiat;
        address buyByFiat;
        bool isBuy;
    }

    struct Game {
        uint256 fee;
        uint256 limitFee;
        uint256 creatorFee;
        mapping(uint256 => Price) tokenPrice;
        GameFee[] arrFees;
        mapping(string => GameFee) fees;
    }

    address public ceoAddress;

    mapping(address => Game) public games;
    address[] public arrGames;

    uint256 public constant PERCENT = 1000;
    string private constant REVERT_NOT_A_CEO = "Marketplace: caller is not CEO";
    string private constant REVERT_NOT_A_OWNER_NFTS = "Marketplace: caller is not the owner of NFTs";
    string private constant REVERT_NOT_A_MAKER = "Marketplace: caller is not a maker";
    string private constant REVERT_INVALID_FIAT = "Marketplace: Invalid fiat";
    string private constant REVERT_INVALID_FEE = "Marketplace: Invalid fee";
    string private constant REVERT_APPROVE_NFTS = "Marketplace: maker is not approve nfts";
    string private constant REVERT_INVALID_BUY_FIAT = "Marketplace: Invalid buy fiat";
    string private constant REVERT_INSUFFICIENT_BALANCE = "Marketplace: Insufficient balance";

    constructor() {
        ceoAddress = _msgSender();
        fiatContract = Fiat(0x87596f78A0Fa11814B907C51e147aDA39905F099);
        tokensFiat[address(0)] = Token("AVAX", true);
        tokensFiat[0x2F7265b97F6655F78AbBf13168e1FB4749A03bd0] = Token("ET", true);
        fiat = [address(0), 0x2F7265b97F6655F78AbBf13168e1FB4749A03bd0];
    }

    modifier onlyCeoAddress() {
        require(_msgSender() == ceoAddress, REVERT_NOT_A_CEO);
        _;
    }

    modifier onlyMaker(address game, uint256 orderId) {
        require(_msgSender() == games[game].tokenPrice[orderId].maker, REVERT_NOT_A_MAKER);
        _;
    }

    modifier isOwnerOf(address game, uint256[] memory tokenIds) {
        require(_isOwnerOf(game, tokenIds), REVERT_NOT_A_OWNER_NFTS);
        _;
    }

    modifier isValidFiat(address[] memory fiat) {
        require(fiat.length > 0 && _isValidFiat(fiat), REVERT_INVALID_FIAT);
        _;
    }

    modifier isValidFiatBuy(address fiat) {
        require(tokensFiat[fiat].existed, REVERT_INVALID_BUY_FIAT);
        _;
    }

    function _isOwnerOf(address game, uint256[] memory tokenIds) private view returns (bool) {
        bool flag = true;
        uint256 length = tokenIds.length;
        IERC721 erc721Address = IERC721(game);
        for (uint256 i = 0; i < length; i++) {
            if (erc721Address.ownerOf(tokenIds[i]) != msg.sender) {
                flag = false;
                break;
            }
        }
        return flag;
    }

    function tokenId2wei(address game, uint256 orderId, address fiatBuy) public view returns (uint256) {
        uint256 price = games[game].tokenPrice[orderId].price;
        return price2wei(price, fiatBuy);
    }

    function getTokenPrice(address game, uint256 orderId) public view returns (
        address _maker,
        uint256[] memory _tokenIds,
        uint256 _price,
        address[] memory _fiat,
        address _buyByFiat,
        bool _isBuy
    ) {
        return (
            games[game].tokenPrice[orderId].maker,
            games[game].tokenPrice[orderId].tokenIds,
            games[game].tokenPrice[orderId].price,
            games[game].tokenPrice[orderId].fiat,
            games[game].tokenPrice[orderId].buyByFiat,
            games[game].tokenPrice[orderId].isBuy
        );
    }

    function getArrGames() external view returns (address[] memory) {
        return arrGames;
    }

    function calFee(address game, string memory fee, uint256 price) external view returns (uint256) {
        return price.mul(games[game].fees[fee].percent).div(PERCENT);
    }

    function calPrice(address game, uint256 orderId) external view returns (address, uint256, address[] memory, address, bool) {
        return (
            games[game].tokenPrice[orderId].maker,
            games[game].tokenPrice[orderId].price,
            games[game].tokenPrice[orderId].fiat,
            games[game].tokenPrice[orderId].buyByFiat,
            games[game].tokenPrice[orderId].isBuy
        );
    }

    function _updateArrGames(address game) private {
        bool flag = false;
        uint256 length = arrGames.length;
        for (uint256 i = 0; i < length; i++) {
            if (arrGames[i] == game) {
                flag = true;
                break;
            }
        }
        if (!flag) arrGames.push(game);
    }

    function _setPrice(
        uint256 orderId,
        address game,
        uint256[] memory tokenIds,
        uint256 price,
        address[] memory fiat
    ) private {
        require(games[game].tokenPrice[orderId].maker == address(0) || games[game].tokenPrice[orderId].maker == msg.sender, REVERT_NOT_A_OWNER_NFTS);
        games[game].tokenPrice[orderId] = Price(tokenIds, _msgSender(), price, fiat, address(0), false);
        _updateArrGames(game);
    }

    function setPriceFee(
        uint256 orderId,
        address game,
        uint256[] memory tokenIds,
        uint256 price,
        address[] memory fiat
    ) public isOwnerOf(game, tokenIds) isValidFiat(fiat) {
        _setPrice(orderId, game, tokenIds, price, fiat);
        emit SetPrice(game, tokenIds, price, 1);
    }

    function getGame(address game) public view returns (uint256, uint256, uint256) {
        return (
            games[game].fee,
            games[game].limitFee,
            games[game].creatorFee
        );
    }

    function getGameFees(address game) public view returns (
        string[] memory,
        address[] memory,
        uint256[] memory,
        uint256
    ) {
        uint256 length = games[game].arrFees.length;
        string[] memory fees = new string[](length);
        address[] memory takers = new address[](length);
        uint256[] memory percents = new uint256[](length);
        uint256 sumGamePercent = 0;
        for (uint256 i = 0; i < length; i++) {
            GameFee storage gameFee = games[game].arrFees[i];
            fees[i] = gameFee.fee;
            takers[i] = gameFee.taker;
            percents[i] = gameFee.percent;
            sumGamePercent += gameFee.percent;
        }

        return (fees, takers, percents, sumGamePercent);
    }

    function getGameFeePercent(address game, string memory fee) public view returns (uint256) {
        return games[game].fees[fee].percent;
    }

    function setLimitFee(
        address game,
        uint256 fee,
        uint256 limitFee,
        uint256 creatorFee,
        string[] memory gameFees,
        address[] memory takers,
        uint256[] memory percents
    ) public onlyOwner {
        require(fee >= 0 && limitFee >= 0, REVERT_INVALID_FEE);
        games[game].fee = fee;
        games[game].limitFee = limitFee;
        games[game].creatorFee = creatorFee;

        for (uint256 i = 0; i < gameFees.length; i++) {
            if (!games[game].fees[gameFees[i]].existed) {
                GameFee memory newFee = GameFee({
                    fee: gameFees[i],
                    taker: takers[i],
                    percent: percents[i],
                    existed: true
                });
                games[game].fees[gameFees[i]] = newFee;
                games[game].arrFees.push(newFee);
            } else {
                games[game].fees[gameFees[i]].percent = percents[i];
                games[game].fees[gameFees[i]].taker = takers[i];
                games[game].arrFees[i].percent = percents[i];
                games[game].arrFees[i].taker = takers[i];
            }
        }
        _updateArrGames(game);
    }

    function setLimitFeeAll(
        address[] memory gameAddresses,
        uint256[] memory fees,
        uint256[] memory limitFees,
        uint256[] memory creatorFees,
        string[][] memory gameFees,
        address[][] memory takers,
        uint256[][] memory percents
    ) external onlyOwner {
        require(gameAddresses.length == fees.length, REVERT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < gameAddresses.length; i++) {
            setLimitFee(gameAddresses[i], fees[i], limitFees[i], creatorFees[i], gameFees[i], takers[i], percents[i]);
        }
    }

    function sellNfts(
        uint256[] memory orderIds,
        address[] memory gameAddresses,
        uint256[][] memory tokenIds,
        uint256[] memory price,
        address[][] memory fiats
    ) external {
        require(orderIds.length == tokenIds.length, REVERT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < orderIds.length; i++) {
            require(_isOwnerOf(gameAddresses[i], tokenIds[i]), REVERT_NOT_A_OWNER_NFTS);
            require(_isValidFiat(fiats[i]), REVERT_INVALID_FIAT);
            setPriceFee(orderIds[i], gameAddresses[i], tokenIds[i], price[i], fiats[i]);
        }
    }

    function _resetPrice(address game, uint256 orderId) private {
        Price storage price = games[game].tokenPrice[orderId];
        price.maker = address(0);
        price.price = 0;
        price.buyByFiat = address(0);
        price.isBuy = false;
        games[game].tokenPrice[orderId] = price;
        emit ResetPrice(game, orderId);
    }

    function removePrice(address game, uint256 orderId) external onlyMaker(game, orderId) {
        _resetPrice(game, orderId);
    }

    function _transferGameFees (address game, address fiatBuy, uint256 weiPrice) private {
        ( , address[] memory takers, uint256[] memory percents, ) = getGameFees(game);
        uint256 length = takers.length;
        for (uint256 i = 0; i< length; i++) {
            uint256 gameProfit = (weiPrice.mul(percents[i])).div(PERCENT);
            if (gameProfit > 0) {
                if (fiatBuy == address(0)) {
                    payable(takers[i]).transfer(gameProfit);
                } else {
                    IERC20(fiatBuy).transfer(takers[i], gameProfit);
                }
            }
        }
    }

    function _transferFees(
        address game,
        address fiatBuy,
        uint256 weiPrice,
        address maker,
        uint256 ownerProfit,
        uint256 businessProfit,
        uint256 creatorProfit,
        uint256 tokenId
    ) private {
        IERC721 erc721Address = IERC721(game);
        address ceo = ceoAddress;

        if (fiatBuy == address(0)) {
            require(weiPrice <= msg.value, REVERT_INSUFFICIENT_BALANCE);
            if (ownerProfit > 0) payable(maker).transfer(ownerProfit);
            if (businessProfit > 0) payable(ceo).transfer(businessProfit);
            if (creatorProfit > 0) {
                (address creator) = erc721Address.metadata(tokenId);
                payable(creator).transfer(creatorProfit);
            }
        } else {
            IERC20 erc20 = IERC20(fiatBuy);
            require(erc20.transferFrom(msg.sender, address(this), weiPrice), REVERT_INSUFFICIENT_BALANCE);
            if (ownerProfit > 0) erc20.transfer(maker, ownerProfit);
            if (businessProfit > 0) erc20.transfer(ceo, businessProfit);
            if (creatorProfit > 0) {
                (address creator) = erc721Address.metadata(tokenId);
                erc20.transfer(creator, creatorProfit);
            }
        }

        _transferGameFees(game, fiatBuy, weiPrice);
    }

    function _businessFees(
        address game,
        string memory symbolFiatBuy,
        uint256 weiPrice
    ) private view returns (uint256, uint256) {
        (, uint256 tokenOnUSD) = fiatContract.getToken2USD(symbolFiatBuy);
        (uint256 fee, uint256 limitFee, uint256 creatorFee) = (games[game].fee, games[game].limitFee, games[game].creatorFee);
        uint256 businessProfit = weiPrice.mul(fee).div(PERCENT);
        uint256 limitFee2Token = tokenOnUSD.mul(limitFee).div(1 ether);
        if (weiPrice > 0 && businessProfit < limitFee2Token) businessProfit = limitFee2Token;
        uint256 creatorProfit = weiPrice.mul(creatorFee).div(PERCENT);
        return (businessProfit, creatorProfit);
    }

    function _buy(
        address game,
        uint256 orderId,
        address fiatBuy,
        string memory symbolFiatBuy,
        address maker,
        uint256 tokenId
    ) private {
        uint256 weiPrice = tokenId2wei(game, orderId, fiatBuy);
        (uint256 businessProfit, uint256 creatorProfit) = _businessFees(game, symbolFiatBuy, weiPrice);
        ( , , , uint256 sumGamePercent) = getGameFees(game);
        uint256 sumGameProfit = weiPrice.mul(sumGamePercent).div(PERCENT);
        uint256 ownerProfit = weiPrice.sub(businessProfit).sub(creatorProfit).sub(sumGameProfit);
        
        _transferFees(game, fiatBuy, weiPrice, maker, ownerProfit, businessProfit, creatorProfit, tokenId);
    }

    function buy(
        address game,
        uint256 orderId,
        address fiatBuy,
        string memory symbolFiatBuy
    ) external payable isValidFiatBuy(fiatBuy) {
        // gas saving
        (address maker, uint256[] memory tokenIds) = (games[game].tokenPrice[orderId].maker, games[game].tokenPrice[orderId].tokenIds);
        IERC721 erc721Address = IERC721(game);
        require(erc721Address.isApprovedForAll(maker, address(this)), REVERT_APPROVE_NFTS);
        _buy(game, orderId, fiatBuy, symbolFiatBuy, maker, tokenIds[0]);
        uint256 length = tokenIds.length;
        address account = _msgSender();
        for (uint256 i = 0; i < length; i++) erc721Address.transferFrom(maker, account, tokenIds[i]);
        _resetPrice(game, orderId);
        emit Buy(account, game, orderId, fiatBuy);
    }


    function changeCeo(address _address) external onlyCeoAddress {
        require(_address != address(0), REVERT_NULL_ADDRESS);
        ceoAddress = _address;
    }
}