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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

interface Rental {
    function isForRent(address nftAddress, uint256 tokenId) external view returns(bool);
}

contract Withdrawable is Ownable {
    string private constant REVERT_TRANSFER_FAILED = "BuyNFT: AVAX_TRANSFER_FAILED";

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

    string internal constant REVERT_NULL_ADDRESS = "BuyNFT: Can not be address 0";
    string internal constant REVERT_LENGTH_MISMATCH = "BuyNFT: Length mismatch";

    function setFiatContract(address _fiatContract) public onlyOwner {
        require(_fiatContract != address(0), REVERT_NULL_ADDRESS);
        fiatContract = Fiat(_fiatContract);
    }

    function setFiat(string[] memory _symbols, address[] memory _addresses) public onlyOwner {
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

    function getFiat() public view returns (address[] memory) {
        return fiat;
    }

    function getTokenFiat(address _fiat) public view returns (string memory, bool) {
        return (tokensFiat[_fiat].symbol, tokensFiat[_fiat].existed);
    }
}

contract BuyNFT is GameFiat, Withdrawable {
    event SetPrice(uint256 orderId, address game, uint256[] tokenIds, uint256 price, address[] fiat);
    event ResetPrice(address game, uint256 orderId);

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

    address public buyNFTSub;
    address public ceoAddress;
    address public rentalContract;

    mapping(address => mapping(uint256 => bool)) public isForSale;
    mapping(address => Game) public games;
    address[] public arrGames;

    uint256 public constant PERCENT = 10000;
    string private constant REVERT_NOT_A_CEO = "BuyNFT: caller is not CEO";
    string private constant REVERT_NOT_HAVE_POSESSION = "BuyNFT: caller is not the owner of NFTs or NFTs are for rented";
    string private constant REVERT_NOT_A_OWNER = "BuyNFT: caller is not the owner of NFTs or NFTs are for rented";
    string private constant REVERT_NOT_A_MAKER = "BuyNFT: caller is not a maker";
    string private constant REVERT_NOT_A_SUB_MARKET = "BuyNFT: caller is not SubMarketplace";
    string private constant REVERT_INVALID_FIAT = "BuyNFT: Invalid fiat";
    string private constant REVERT_INVALID_FEE = "BuyNFT: Invalid fee";

    constructor() {
        ceoAddress = _msgSender();
        buyNFTSub = 0xC1325a01202f2BEaA345a7D9bcf719A6402D0387;
        fiatContract = Fiat(0x87596f78A0Fa11814B907C51e147aDA39905F099);
        tokensFiat[address(0)] = Token("AVAX", true);
        tokensFiat[0x2F7265b97F6655F78AbBf13168e1FB4749A03bd0] = Token("ET", true);
        fiat = [address(0), 0x1c73743870BEE9459c2AE95D97C5DF78ffBED29F];
    }

    modifier onlyCeoAddress() {
        require(_msgSender() == ceoAddress, REVERT_NOT_A_CEO);
        _;
    }

    modifier onlyMaker(address _game, uint256 _orderId) {
        require(_msgSender() == games[_game].tokenPrice[_orderId].maker, REVERT_NOT_A_MAKER);
        _;
    }

    modifier onlySub() {
        require(_msgSender() == buyNFTSub, REVERT_NOT_A_SUB_MARKET);
        _;
    }

    modifier isOwnerOf(address _game, uint256[] memory _tokenIds) {
        require(_isOwnerOf(_game, _tokenIds), REVERT_NOT_HAVE_POSESSION);
        _;
    }

    modifier isValidFiat(address[] memory _fiat) {
        require(_fiat.length > 0 && _isValidFiat(_fiat), REVERT_INVALID_FIAT);
        _;
    }

    function _setForSale(address _game, uint256[] memory _tokenIds, bool status) private {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            isForSale[_game][_tokenIds[i]] = status;
        } 
    }

    function _isOwnerOf(address _game, uint256[] memory _tokenIds) private returns (bool) {
        bool flag = true;
        address account = _msgSender();
        uint256 length = _tokenIds.length;
        IERC721 erc721Address = IERC721(_game);
        Rental rental = Rental(rentalContract);

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];
            if ((erc721Address.ownerOf(tokenId) != account) || (rental.isForRent(_game, tokenId))) {
                flag = false;
                break;
            } else {
                isForSale[_game][tokenId] = true;
            }
        }
        return flag;
    }

    function tokenId2wei(address _game, uint256 _orderId, address _fiatBuy) public view returns (uint256) {
        uint256 _price = games[_game].tokenPrice[_orderId].price;
        return price2wei(_price, _fiatBuy);
    }

    function getTokenPrice(address _game, uint256 _orderId) public view returns (
        address _maker,
        uint256[] memory _tokenIds,
        uint256 _price,
        address[] memory _fiat,
        address _buyByFiat,
        bool _isBuy
    ) {
        return (
            games[_game].tokenPrice[_orderId].maker,
            games[_game].tokenPrice[_orderId].tokenIds,
            games[_game].tokenPrice[_orderId].price,
            games[_game].tokenPrice[_orderId].fiat,
            games[_game].tokenPrice[_orderId].buyByFiat,
            games[_game].tokenPrice[_orderId].isBuy
        );
    }

    function getArrGames() public view returns (address[] memory) {
        return arrGames;
    }

    function calFee(address _game, string memory _fee, uint256 _price) public view returns (uint256) {
        return _price.mul(games[_game].fees[_fee].percent).div(PERCENT);
    }

    function calPrice(address _game, uint256 _orderId) public view returns (
        address,
        uint256,
        address[] memory,
        address,
        bool
    ) {
        return (
            games[_game].tokenPrice[_orderId].maker,
            games[_game].tokenPrice[_orderId].price,
            games[_game].tokenPrice[_orderId].fiat,
            games[_game].tokenPrice[_orderId].buyByFiat,
            games[_game].tokenPrice[_orderId].isBuy
        );
    }

    function _updateArrGames(address _game) private {
        bool flag = false;
        uint256 length = arrGames.length;
        for (uint256 i = 0; i < length; i++) {
            if (arrGames[i] == _game) {
                flag = true;
                break;
            }
        }
        if (!flag) arrGames.push(_game);
    }

    function _setPrice(
        uint256 _orderId,
        address _game,
        uint256[] memory _tokenIds,
        uint256 _price,
        address[] memory _fiat
    ) private {
        require(games[_game].tokenPrice[_orderId].maker == address(0) || games[_game].tokenPrice[_orderId].maker == msg.sender, REVERT_NOT_A_MAKER);
        games[_game].tokenPrice[_orderId] = Price(
            _tokenIds,
            _msgSender(),
            _price,
            _fiat,
            address(0),
            false
        );
        _updateArrGames(_game);
    }

    function setPriceFee(
        uint256 _orderId,
        address _game,
        uint256[] memory _tokenIds,
        uint256 _price,
        address[] memory _fiat
    ) public isValidFiat(_fiat) {
        require(_isOwnerOf(_game, _tokenIds), REVERT_NOT_HAVE_POSESSION);
        _setPrice(_orderId, _game, _tokenIds, _price, _fiat);
        emit SetPrice(_orderId, _game, _tokenIds, _price, _fiat);
    }

    function getGame(address _game) public view returns (uint256, uint256, uint256) {
        return (
            games[_game].fee,
            games[_game].limitFee,
            games[_game].creatorFee
        );
    }

    function getGameFees(address _game) public view returns (
        string[] memory,
        address[] memory,
        uint256[] memory,
        uint256
    ) {
        uint256 length = games[_game].arrFees.length;
        string[] memory fees = new string[](length);
        address[] memory takers = new address[](length);
        uint256[] memory percents = new uint256[](length);
        uint256 sumGamePercent = 0;
        for (uint256 i = 0; i < length; i++) {
            GameFee storage gameFee = games[_game].arrFees[i];
            fees[i] = gameFee.fee;
            takers[i] = gameFee.taker;
            percents[i] = gameFee.percent;
            sumGamePercent += gameFee.percent;
        }

        return (fees, takers, percents, sumGamePercent);
    }

    function getGameFeePercent(address _game, string memory _fee) public view returns (uint256) {
        return games[_game].fees[_fee].percent;
    }

    function setLimitFee(
        address _game,
        uint256 _fee,
        uint256 _limitFee,
        uint256 _creatorFee,
        string[] memory _gameFees,
        address[] memory _takers,
        uint256[] memory _percents
    ) public onlyOwner {
        require(_fee >= 0 && _limitFee >= 0, REVERT_INVALID_FEE);
        games[_game].fee = _fee;
        games[_game].limitFee = _limitFee;
        games[_game].creatorFee = _creatorFee;

        for (uint256 i = 0; i < _gameFees.length; i++) {
            if (!games[_game].fees[_gameFees[i]].existed) {
                GameFee memory newFee = GameFee({
                    fee: _gameFees[i],
                    taker: _takers[i],
                    percent: _percents[i],
                    existed: true
                });
                games[_game].fees[_gameFees[i]] = newFee;
                games[_game].arrFees.push(newFee);
            } else {
                games[_game].fees[_gameFees[i]].percent = _percents[i];
                games[_game].fees[_gameFees[i]].taker = _takers[i];
                games[_game].arrFees[i].percent = _percents[i];
                games[_game].arrFees[i].taker = _takers[i];
            }
        }
        _updateArrGames(_game);
    }

    function setLimitFeeAll(
        address[] memory _games,
        uint256[] memory _fees,
        uint256[] memory _limitFees,
        uint256[] memory _creatorFees,
        string[][] memory _gameFees,
        address[][] memory _takers,
        uint256[][] memory _percents
    ) public onlyOwner {
        require(_games.length == _fees.length, REVERT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _games.length; i++) {
            setLimitFee(
                _games[i],
                _fees[i],
                _limitFees[i],
                _creatorFees[i],
                _gameFees[i],
                _takers[i],
                _percents[i]
            );
        }
    }

    function sellNfts(
        uint256[] memory _orderIds,
        address[] memory _game,
        uint256[][] memory _tokenIds,
        uint256[] memory _price,
        address[][] memory _fiats
    ) public {
        require(_orderIds.length == _tokenIds.length, REVERT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _orderIds.length; i++) {
            require(_isOwnerOf(_game[i], _tokenIds[i]), REVERT_NOT_HAVE_POSESSION);
            require(_fiats[i].length > 0 && _isValidFiat(_fiats[i]), REVERT_INVALID_FIAT);
            setPriceFee(
                _orderIds[i],
                _game[i],
                _tokenIds[i],
                _price[i],
                _fiats[i]
            );
        }
    }

    function _resetPrice(address _game, uint256 _orderId) private {
        Price storage _price = games[_game].tokenPrice[_orderId];
        _price.maker = address(0);
        _price.price = 0;
        _price.buyByFiat = address(0);
        _price.isBuy = false;
        games[_game].tokenPrice[_orderId] = _price;
        _setForSale(_game, _price.tokenIds, false);
        emit ResetPrice(_game, _orderId);
    }

    function removePrice(address _game, uint256 _orderId) public onlyMaker(_game, _orderId) {
        _resetPrice(_game, _orderId);
    }

    function resetPrice4sub(address _game, uint256 _tokenId) public onlySub {
        _resetPrice(_game, _tokenId);
    }

    function changeCeo(address _address) public onlyCeoAddress {
        require(_address != address(0), REVERT_NULL_ADDRESS);
        ceoAddress = _address;
    }

    function setBuyNFTSub(address _buyNFTSub) public onlyOwner {
        require(_buyNFTSub != address(0), REVERT_NULL_ADDRESS);
        buyNFTSub = _buyNFTSub;
    }

    function setRental(address _rental) public onlyOwner {
        require(_rental != address(0), REVERT_NULL_ADDRESS);
        rentalContract = _rental;
    }
}