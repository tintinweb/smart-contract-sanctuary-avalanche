/**
 *Submitted for verification at snowtrace.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT

// File: contracts/interfaces/IPair.sol
pragma solidity >=0.8.0;

interface ISoulSwapPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);
    function token1() external view returns (address);
    
    function getReserves() external view returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out, 
        uint256 amount1Out, 
        address to, 
        bytes calldata data
    ) external;

    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/interfaces/ISummoner.sol

interface ISummoner {
    function userInfo(uint pid, address owner) external view returns (uint, uint);
}

// File: contracts/interfaces/IBond.sol

interface IBond {
    function pendingSoul(uint pid, address owner) external view returns (uint);
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/governance/SoulAura.sol
pragma solidity >=0.8.0;

contract SoulAura is Ownable {

    ISummoner summoner = ISummoner(0x090D4911Db910efaA498f9b97b8999FbE7A41Dd7);
    IBond bond = IBond(0x4161A44D71F68852d6b013a9C6BF968d3b08D9b7);
    IERC20 soul = IERC20(0x11d6DD25c1695764e64F439E32cc7746f3945543);
    IERC20 seance = IERC20(0x97Ee3C9Cf4E5DE384f95e595a8F327e65265cC4E);
    IERC20 chant = IERC20(0xD191F9C5Bd60c9b2239E321C37a2397269170D61);

    // SOULSWAP PAIRS
    ISoulSwapPair soulNative = ISoulSwapPair(0x6Da1AD717C7577AAB46C19aB6d3d9C31aff32A00);
    ISoulSwapPair soulUsdc = ISoulSwapPair(0x922fcADa825Dc669798206A35D2D2B455f9A64E7);

    // SOULSWAP FARMS
    uint soulNativePid = 1;
    uint soulUsdcPid = 2;

    function name() public pure returns (string memory) { return "SoulAura"; }
    function symbol() public pure returns (string memory) { return "AURA"; }
    function decimals() public pure returns (uint8) { return 18; }

    // gets the total voting power = twice the reserves in the LPs + soul supply + seance supply.
    function totalSupply() public view returns (uint) {

        // SOUL | SOUL-AVAX + SOUL-USDC
        (uint totalSoulAvax, , ) = soulNative.getReserves(); // token0 = SOUL
        (uint totalSoulUsdc, , ) = soulUsdc.getReserves(); // token0 = SOUL

        uint totalSoul = (2 * (totalSoulAvax + totalSoulUsdc)) + soul.totalSupply();
        uint totalSeance = seance.totalSupply();

        return totalSoul + totalSeance;
    }

    function balanceOf(address member) public view returns (uint) {
        ( uint memberLiquidity, ) = pooledPower(member);
        ( uint memberStake, ) = stakedPower(member);
        ( uint memberSoul, ) = soulPower(member);
        ( uint memberSeance, ) = seancePower(member);
        ( uint memberBond, ) = bondPower(member);

        return memberLiquidity + memberStake + memberSoul + memberSeance + memberBond;
    }

    function soulBondPower(address member) public view returns (uint raw, uint formatted) {
        uint ZERO = bond.pendingSoul(0, member); // AVAX-SOUL
        uint ONE = bond.pendingSoul(1, member); // USDC-SOUL
        uint power = ZERO + ONE;

        return (power, fromWei(power));
    }

    // gets: member's bond power
    function bondPower(address member) public view returns (uint raw, uint formatted) {
        (uint SoulBondPower, ) = soulBondPower(member);

        uint TWO = bond.pendingSoul(2, member); // AVAX-USDC
        uint THREE = bond.pendingSoul(3, member); // AVAX-BTC
        uint FOUR = bond.pendingSoul(4, member); // AVAX-ETH
        
        uint avaxBondPower = TWO + THREE + FOUR;

        uint stableBondPower = bond.pendingSoul(5, member); // USDC-DAI

        uint nonSoulBondPower = avaxBondPower + stableBondPower;

        uint power = SoulBondPower + nonSoulBondPower;

        return (power, fromWei(power));
    }

    // gets: member's pooled power
    function pooledPower(address member) public view returns (uint raw, uint formatted) {
        ( uint soulPooled, ) = pooledSoul(member);
        uint power = soulPooled;

        return (power, fromWei(power));

    }

    // gets: member's pooled SOUL power
    function pooledSoul(address member) public view returns (uint raw, uint formatted) {
        // total | LP tokens
        uint lp_total =  
              soulNative.totalSupply() 
            + soulUsdc.totalSupply();

        // total | pooled SOUL
        uint lp_totalSoul =
              soul.balanceOf(address(soulNative)) 
            + soul.balanceOf(address(soulUsdc));

        // member | SOUL LP balance
        uint lp_walletBalance =
              soulNative.balanceOf(member)
            + soulUsdc.balanceOf(member);

        // member | staked LP balance
        (uint staked_soulNative, ) = summoner.userInfo(soulNativePid, member);
        (uint staked_soulUsdc, ) = summoner.userInfo(soulUsdcPid, member);

        uint lp_stakedBalance = staked_soulNative + staked_soulUsdc;

        // member | lp balance
        uint lp_balance = 
              lp_walletBalance 
            + lp_stakedBalance;

        // LP voting power is 2X the members' SOUL share in the LP pool.
        uint lp_power =
              lp_totalSoul 
            * lp_balance 
            / lp_total * 2;

        return (lp_power, fromWei(lp_power));

    }

    // gets: member's staked power
    function stakedPower(address member) public view returns (uint raw, uint formatted) {
        // stakedPower is the members' staked balance.
        uint chantStaked = chant.balanceOf(member);
        (uint manualStaked, ) = summoner.userInfo(0, member);
        uint staked_power = chantStaked + manualStaked;
        return (staked_power, fromWei(staked_power));
    }

    // gets: member's SOUL power
    function soulPower(address member) public view returns (uint raw, uint formatted) {
        // soul power is the members' SOUL balance.
        uint soul_power = soul.balanceOf(member);
        return (soul_power, fromWei(soul_power));
    }

    // gets: member's SEANCE power
    function seancePower(address member) public view returns (uint raw, uint formatted) {
        // soul power is the members' SOUL balance.
        uint seance_power = seance.balanceOf(member);
        return (seance_power, fromWei(seance_power));
    }

    // blocks ERC20 functionality.
    function allowance(address, address) public pure returns (uint) { return 0; }
    function transfer(address, uint) public pure returns (bool) { return false; }
    function approve(address, uint) public pure returns (bool) { return false; }
    function transferFrom(address, address, uint) public pure returns (bool) { return false; }

    // conversion helper functions
    function toWei(uint intNum) public pure returns (uint bigInt) { return intNum * 10**18; }
    function fromWei(uint bigInt) public pure returns (uint intNum) { return bigInt / 10**18; }
}