/**
 *Submitted for verification at snowtrace.io on 2022-12-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
}

interface IPriceFeed {
    function latestPrice() external view returns (uint256);
    function latestMimPrice() external view returns (int256);
}

interface IXGrape is IERC20 {
    function calculatePrice() external view returns (uint256);
}

interface IMagicToken is IERC20 {
    function getPricePerFullShare() external view returns (uint256);
}

contract xGrapeOracle is Ownable {

    IPriceFeed public constant priceFeed = IPriceFeed(0x8F6979C039a45B7738E8BDC999658E49d4Efd4a7);
    IXGrape public constant xGrape = IXGrape(0x95CED7c63eA990588F3fd01cdDe25247D04b8D98);
    IMagicToken public constant magicToken = IMagicToken(0x0dA1DC567D81925cFf22Df74C6b9e294E9E1c3A5);
    IERC20 public constant LP = IERC20(0x9076C15D7b2297723ecEAC17419D506AE320CbF1);
    IERC20 public constant MIM = IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
    IERC20 public constant Grape = IERC20(0x5541D83EFaD1f281571B343977648B75d95cdAC2);

    uint256 public breakPrice;

    function xGrapePrice() public view returns (uint256) {
        return valueOfXGrape(10**18);
    }

    function latestAnswer() public view returns (uint256) {
        uint256 rawPrice = valueOfXGrape(10**8);

        if(rawPrice >= breakPrice){
            rawPrice = breakPrice;
        }

        return rawPrice;
    }

    function tvlInXGrape() public view returns (uint256) {
        return ( magicToken.balanceOf(address(xGrape)) * tvlInMagicToken() ) / magicToken.totalSupply();
    }

    function tvlInMagicToken() public view returns (uint256) {
        return valueOfLP(( magicToken.getPricePerFullShare() * magicToken.totalSupply() ) / 10**18);
    }

    function valueOfXGrape(uint nTokens) public view returns (uint256) {
        return ( valueOfMagicToken(nTokens) * calculatePrice() ) / 10**18;
    }

    function valueOfMagicToken(uint nTokens) public view returns (uint256) {
        return ( valueOfLP(nTokens) * getPricePerFullShare() ) / 10**18;
    }

    function valueOfLP(uint nTokens) public view returns (uint256) {

        // tvl in LP
        uint tvl = TVLInLP();

        // find out what the TVL is per token, multiply by `nTokens`
        return ( tvl * nTokens ) / LP.totalSupply();
    }

    function TVLInLP() public view returns (uint256) {
        return TVL(address(LP));
    }

    function TVL(address wallet) public view returns (uint256) {

        // balance in LPs
        uint256 balanceGrape = Grape.balanceOf(wallet);
        uint256 balanceMim = MIM.balanceOf(wallet);

        // tvl in LPs
        uint tvlGrape = ( balanceGrape * latestGrapePriceFormatted() ) / 10**18;
        uint tvlMim   = ( balanceMim   * latestMimPriceFormatted() )   / 10**18;
        return tvlGrape + tvlMim;

    }

    function calculatePrice() public view returns (uint256) {
        return xGrape.calculatePrice();
    }

    function getPricePerFullShare() public view returns (uint256) {
        return magicToken.getPricePerFullShare();
    }

    function latestGrapePriceFormatted() public view returns (uint256) {
        return latestPrice() / 10**8;
    }

    function latestMimPriceFormatted() public view returns (uint256) {
        return latestMimPrice() * 10**10;
    }

    function latestPrice() public view returns (uint256) {
        return priceFeed.latestPrice();
    }

    function latestMimPrice() public view returns (uint256) {
        int256 val = priceFeed.latestMimPrice();
        require(val > 0, 'MIM Price Error');
        return uint256(val);
    } 

    function balanceOf(address user) external view returns (uint256) {
        return ( xGrape.balanceOf(user) * xGrapePrice() ) / 10**18;
    }

    function totalSupply() public view returns (uint256) {
        return tvlInXGrape();
    }

    function name() external pure returns (string memory) {
        return 'XGrape Price';
    }

    function symbol() external pure returns (string memory) {
        return 'USD';
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function setBreak(uint256 _break) external onlyOwner {
        breakPrice = _break;
    }
}