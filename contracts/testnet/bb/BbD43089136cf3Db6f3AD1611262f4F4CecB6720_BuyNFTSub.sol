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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

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

interface BuyNFT {
    function resetPrice4sub(address _game, uint256 _tokenId) external;

    function ceoAddress() external view returns (address);

    function getTokenFiat(address _fiat) external view returns (string memory, bool);

    function getTokenPrice(address _game, uint256 _orderId) external view returns (address, uint256[] memory, uint256 , address[] memory, address, bool);
    
    function tokenId2wei(address _game, uint256 _tokenId, address _fiatBuy) external view returns (uint256);

    function PERCENT() external view returns (uint256);

    function getGameFees(address _game) external view returns (string[] memory, address[] memory, uint256[] memory, uint256);

    function games(address _game) external view returns (uint256, uint256, uint256);

    function fiatContract() external view returns (address);

}

interface Fiat {
    function getToken2USD(string memory symbol) external view returns (string memory _symbolToken, uint256 _token2USD);
}

contract BuyNFTSub is Ownable {
    using SafeMath for uint256;

    BuyNFT public buynft;

    constructor() {
        buynft = BuyNFT(0xA9208C45Fd08DC1e4157669179bC2289A076DE88);
    }

    string public constant REVERT_APPROVE_NFTS = "BuyNFTSub: caller is not approve nfts";
    string public constant REVERT_INVALID_BUY_FIAT = "BuyNFTSub: Invalid buy fiat";
    string public constant REVERT_INSUFFICIENT_BALANCE = "BuyNFTSub: Insufficient balance";

    modifier isValidFiatBuy(address fiat) {
        (, bool existed) = buynft.getTokenFiat(fiat);
        require(existed, REVERT_INVALID_BUY_FIAT);
        _;
    }

    function _transferGameFees (address game, address fiatBuy, uint256 weiPrice) private {
        ( , address[] memory takers, uint256[] memory percents, ) = buynft.getGameFees(game);
        uint256 length = takers.length;
        uint256 percent = buynft.PERCENT();
        for (uint256 i = 0; i< length; i++) {
            uint256 gameProfit = (weiPrice.mul(percents[i])).div(percent);
            if (fiatBuy == address(0)) {
                payable(takers[i]).transfer(gameProfit);
            } else {
                IERC20(fiatBuy).transfer(takers[i], gameProfit);
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
        address ceo = buynft.ceoAddress();

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
        Fiat fiatContract = Fiat(buynft.fiatContract());
        (, uint256 tokenOnUSD) = fiatContract.getToken2USD(symbolFiatBuy);
        (uint256 fee, uint256 limitFee, uint256 creatorFee) = buynft.games(game);
        uint256 businessProfit = weiPrice.mul(fee).div(buynft.PERCENT());
        uint256 limitFee2Token = tokenOnUSD.mul(limitFee).div(1 ether);
        if (weiPrice > 0 && businessProfit < limitFee2Token) businessProfit = limitFee2Token;
        uint256 creatorProfit = weiPrice.mul(creatorFee).div(buynft.PERCENT());
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
        uint256 weiPrice = buynft.tokenId2wei(game, orderId, fiatBuy);
        (uint256 businessProfit, uint256 creatorProfit) = _businessFees(game, symbolFiatBuy, weiPrice);
        ( , , , uint256 sumGamePercent) = buynft.getGameFees(game);
        uint256 sumGameProfit = weiPrice.mul(sumGamePercent).div(buynft.PERCENT());
        uint256 ownerProfit = weiPrice.sub(businessProfit).sub(creatorProfit).sub(sumGameProfit);
        
        _transferFees(game, fiatBuy, weiPrice, maker, ownerProfit, businessProfit, creatorProfit, tokenId);
    }

    function buy(
        address game,
        uint256 orderId,
        address fiatBuy,
        string memory symbolFiatBuy
    ) external payable isValidFiatBuy(fiatBuy) {
        (address maker, uint256[] memory tokenIds, , , , ) = buynft.getTokenPrice(game, orderId);
        IERC721 erc721Address = IERC721(game);
        require(erc721Address.isApprovedForAll(maker, address(this)), REVERT_APPROVE_NFTS);
        _buy(game, orderId, fiatBuy, symbolFiatBuy, maker, tokenIds[0]);
        uint256 length = tokenIds.length;
        address account = _msgSender();
        for (uint256 i = 0; i < length; i++) erc721Address.transferFrom(maker, account, tokenIds[i]);
        buynft.resetPrice4sub(game, orderId);
    }

    function setBuyNFT(address _buyNFT) external onlyOwner {
        buynft = BuyNFT(_buyNFT);
    }
}