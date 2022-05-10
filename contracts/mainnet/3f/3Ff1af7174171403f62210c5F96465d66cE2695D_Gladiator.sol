// SPDX-License-Identifier: MIT
import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import "./SpearERC20Permit.sol";
import "./GenericDex.sol";
import "./StandardToken.sol";
import "./WhitelistWallet.sol";
import "./DripRewarder.sol";

pragma solidity >=0.8.13;

library ConcatString {
    function concat(string memory a,string memory b) internal pure returns(string memory){
        return string(abi.encodePacked(a,b));
    }
}


interface ISpearLike {
    function setFeeExclusions(address account,bool normal,bool special) external;
    function startedOn() external returns(uint256);
}

interface IGetDexPair {
    function dexPair() external returns(address);
}

library GladiatorConstants {
    uint256 constant mintStableTreasuryPerc      =  74;
    uint256 constant mintSpearTreasuryPerc       =  25;
    uint256 constant mintStakerSpearRewardPerc   =   1;
    uint256 constant mintTotalPerc               = 100;

    uint256 constant postSpearTreasuryToStakerRewardPerc = 9;
    uint256 constant postSpearTreasuryToPerformancePerc  = 1;
    uint256 constant postSpearTreasuryTotalPerc          = 100;

    uint256 constant redeemStablePerc                     =  7425;
    uint256 constant redeemStableToStakerSpearRewardPerc  =    75;
    uint256 constant redeemSpearPerc                      =  2475;
    uint256 constant redeemSpearToStakerSpearRewardPerc   =    25;
    uint256 constant redeemTotalPerc                      = 10000;

    uint256 constant stakerSpearDripRatePerc       =   1;
    uint256 constant stakerSpearDripRatePercTotal  = 100;

    uint256 constant mCheckSum               = mintStableTreasuryPerc+mintSpearTreasuryPerc+mintStakerSpearRewardPerc;
    uint256 constant mCheckSumShouldBe			 = mintTotalPerc;

    uint256 constant rCheckSum               = redeemStablePerc+redeemSpearPerc+redeemSpearToStakerSpearRewardPerc+redeemStableToStakerSpearRewardPerc;
    uint256 constant rCheckSumShouldBe       = redeemTotalPerc;
}
    

contract Gladiator is ERC20Permit, Initializable, Ownable, MintableBurnableToken {
    using Strings for string;
    using ConcatString for string;
    
    uint256 public constant targetSupply = type(uint).max;
    IGenericToken public stableToken;
    IGenericToken public spearToken;
    IGenericAVAXRouter public dexRouter;
    IGenericPair public spearDexPair;
    bool private _spearIsToken0;
    
    WhitelistTokenWallet public stableTreasuryWallet;
    WhitelistTokenWallet public stablePurchaseWallet;
    WhitelistTokenWallet public spearTreasuryWallet;
    WhitelistTokenWallet public stakerSpearRewardWallet;
    address public spearPerformanceWallet;

    using DripRewarder for DripRewarderData;
    DripRewarderData internal rew;

    uint256 public totalStakerSpearRewardsAdded;

    address[] internal _holders;
    mapping (address => uint32) internal _holdersIndexPlusOne;

    uint8 internal _autoHousekeepingPerc;
    bool internal _needsSync;

    /**
     * @dev default constructor
     */
    constructor() {
        //REVIEW set owner and allow self-destruct on upgrade?

        _disableInitializers();
    }

    function hasFunc(address a, bytes4 sel) internal view returns(bool result) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr,sel)
            result := staticcall(gas(),a,ptr,4,0,0)
        }
    }
    
    function name() public view override returns (string memory) {
        require(!hasFunc(msg.sender,IGenericFactory.feeTo.selector),"disallowed");
        return _name;
    }

    
    function initialize(string memory name_, string memory symbol_,
                        address dexRouter_, address stableToken_, address spearToken_,
                        WhitelistTokenWallet stableTreasuryWallet_,
                        WhitelistTokenWallet stablePurchaseWallet_,
                        WhitelistTokenWallet spearTreasuryWallet_,
                        WhitelistTokenWallet stakerSpearRewardWallet_,
                        address spearPerformanceWallet_,
                        uint256 rewardStartDelay
                        ) public initializer {
        
        require(address(dexRouter_) != address(0) &&
                address(stableToken_) != address(0) &&
                address(spearToken_) != address(0) &&
                address(stableTreasuryWallet_) != address(0) &&
                address(stablePurchaseWallet_) != address(0) &&
                address(spearTreasuryWallet_) != address(0) &&
                address(stakerSpearRewardWallet_) != address(0) &&
                address(spearPerformanceWallet_) != address(0),
                "Invalid address supplied");
        
        assert(GladiatorConstants.mCheckSum == GladiatorConstants.mCheckSumShouldBe &&
               GladiatorConstants.rCheckSum == GladiatorConstants.rCheckSumShouldBe);
        
        _transferOwnership(_msgSender());
        
        super._initialize(name_,symbol_);
        //rewarder.initialize(decimals());

        dexRouter = IGenericAVAXRouter(dexRouter_);
        
        stableToken = IGenericToken(stableToken_);
        spearToken  = IGenericToken(spearToken_);
        spearDexPair = IGenericPair(IGetDexPair(address(spearToken)).dexPair());
        _spearIsToken0 = (spearDexPair.token0() == spearToken_);
        
        stableTreasuryWallet       = stableTreasuryWallet_;
        stablePurchaseWallet       = stablePurchaseWallet_;
        spearTreasuryWallet        = spearTreasuryWallet_;
        
        stakerSpearRewardWallet    = stakerSpearRewardWallet_;
        spearPerformanceWallet     = spearPerformanceWallet_;

        //IExcludeFromFee(spearToken).setFeeExclusions(address(this),true,true); //REVIEW must do this in launch script...
        
        //IExcludeFromFee(spearToken).setFeeExclusions(address(spearTreasuryWallet_),true,true);

        totalStakerSpearRewardsAdded = 0;

        if (rewardStartDelay < type(uint256).max)
            rewardStartDelay = ISpearLike(address(spearToken)).startedOn() + rewardStartDelay; //time + timediff
        rew.initialize(0,StartTime.wrap(rewardStartDelay),DripRate.wrap(0),DripAmount.wrap(totalStakerSpearRewardsAdded),24 hours);
        
        _enableMinting(true);
    }

    function decimals() public pure override(ERC20Metadata) returns (uint8) {
        return 6;
    }


    function housekeeping(uint256 qAmount) public onlyOwner {
        _housekeeping(qAmount);
    }
    
    function _housekeeping(uint256 qAmount) internal {
        if (_needsSync)
            _sync();
        
        uint256 qBal = stableToken.balanceOf(address(stablePurchaseWallet));
        if (qAmount == 0) {
            qAmount = qBal * uint256(_autoHousekeepingPerc) / 100;
        }
        
        require(qAmount<=qBal);

        if (qAmount == 0)
            return;

        uint256 spearAmount = swapStableTokenForSpearToken(stablePurchaseWallet, qAmount);
        
        uint256 stakerSpearRewardAmount = spearAmount * (GladiatorConstants.mintStakerSpearRewardPerc) / (GladiatorConstants.mintTotalPerc-GladiatorConstants.mintStableTreasuryPerc);
        
        uint256 temp = spearAmount * (GladiatorConstants.postSpearTreasuryToStakerRewardPerc) / (GladiatorConstants.postSpearTreasuryTotalPerc);
        
        stakerSpearRewardAmount = stakerSpearRewardAmount + (temp);
        spearToken.transfer(address(stakerSpearRewardWallet), stakerSpearRewardAmount);
        totalStakerSpearRewardsAdded = totalStakerSpearRewardsAdded + stakerSpearRewardAmount;

        _adjustRewards();

        temp = spearAmount * (GladiatorConstants.postSpearTreasuryToPerformancePerc) / (GladiatorConstants.postSpearTreasuryTotalPerc);
        spearToken.transfer(address(spearPerformanceWallet),temp);

        spearAmount = spearAmount - (stakerSpearRewardAmount) - (temp);
        
        spearToken.transfer(address(spearTreasuryWallet),spearAmount);
    }
    
    function swapStableTokenForSpearToken(WhitelistTokenWallet swapWallet, uint256 qAmount) private returns(uint256 ret){
        // generate the exchange pair path of token -> wavax
        address[] memory path = new address[](2);
        path[0] = address(stableToken);
        path[1] = address(spearToken);

        swapWallet.approveByWLSender(stableToken, qAmount);
        stableToken.transferFrom(address(swapWallet), address(this), qAmount);

        ret = spearToken.balanceOf(address(this));
        stableToken.approve(address(dexRouter), qAmount); //REVIEW .. if the swapWallet issued the swap, it's one less transfer
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            qAmount,
            0, // accept any amount of spearToken
            path,
            address(this),
            block.timestamp
        );
        ret = spearToken.balanceOf(address(this)) - (ret);
    }
    
    function mint(address to, uint256 amount) public returns (bool) {
        require(amount > 0 && _totalSupply + (amount) <= targetSupply);

        uint256 treasuryAmount = amount * (GladiatorConstants.mintStableTreasuryPerc) / (GladiatorConstants.mintTotalPerc);

        stableToken.transferFrom(to,address(this),amount);
        stableToken.transfer(address(stableTreasuryWallet),treasuryAmount);

        if (rew._dt()/rew.dripSeconds > 0) {
            rew.setBasis(_totalSupply+amount, _holders, balanceOf, true);
            _needsSync = false;
        } else {
            _needsSync = true;
        }
        
        //Mint
        require(_mint(to, amount));
        
        amount = amount - (treasuryAmount);
        
        stableToken.transfer(address(stablePurchaseWallet),amount);

        if (_totalSupply >= targetSupply) {
            enableMinting(false);
            emit MintFinished();
        }

        _checkNew(to);

        _housekeeping(0);

        return true;
    }

    function redeem(address to, uint256 amount) public {
        if (_needsSync)
            _sync();

        address sender = _msgSender();
        
        if (rewardBalance(sender)>0)
            claimReward(sender);
        
        uint256 temp = balanceOf(to);
        
        if (amount > temp)amount = temp;
        require(amount>0, "No balance to redeem");

        temp = amount * (GladiatorConstants.redeemStablePerc+GladiatorConstants.redeemStableToStakerSpearRewardPerc) / (GladiatorConstants.redeemTotalPerc);
        require(temp<=stableToken.balanceOf(address(stableTreasuryWallet)),ConcatString.concat("Insufficient stable treasury balances, contact administrator ",Strings.toString(temp)));
        
        temp = amount * (GladiatorConstants.redeemStablePerc) / (GladiatorConstants.redeemTotalPerc);
        stableTreasuryWallet.transferTokenTo(stableToken, to, temp);
        
        temp = amount * (GladiatorConstants.redeemStableToStakerSpearRewardPerc) / (GladiatorConstants.redeemTotalPerc);
        uint256 spearAmount = swapStableTokenForSpearToken(stableTreasuryWallet, temp);
        spearToken.transfer(address(stakerSpearRewardWallet), spearAmount);

        
        temp = amount * (GladiatorConstants.redeemSpearPerc+GladiatorConstants.redeemSpearToStakerSpearRewardPerc) / (GladiatorConstants.redeemTotalPerc);
        (uint256 resQ,uint256 resT,) = spearDexPair.getReserves();
        if (_spearIsToken0) (resT,resQ)=(resQ,resT);
        temp = GenericUtils.quote(temp,resQ,resT);
        uint256 temp2 = spearToken.balanceOf(address(spearTreasuryWallet));
        require(temp<=temp2,
                ConcatString.concat(ConcatString.concat(ConcatString.concat("Insufficient spear treasury balances, contact administrator ",Strings.toString(temp))," "),Strings.toString(temp2)));
        
        spearTreasuryWallet.transferTokenTo(spearToken, to,
                                            temp * (GladiatorConstants.redeemSpearPerc) / (GladiatorConstants.redeemSpearPerc+GladiatorConstants.redeemSpearToStakerSpearRewardPerc));

        temp = temp * (GladiatorConstants.redeemSpearToStakerSpearRewardPerc) / (GladiatorConstants.redeemSpearPerc+GladiatorConstants.redeemSpearToStakerSpearRewardPerc);
        spearTreasuryWallet.transferTokenTo(spearToken, address(stakerSpearRewardWallet),
                                            temp);

        totalStakerSpearRewardsAdded = totalStakerSpearRewardsAdded + temp + spearAmount;

        _adjustRewards(_totalSupply-amount);
               
        _burn(amount);
        _checkZero(_msgSender());
    }
    

    function rewardBalance(address a) public view returns(uint256) {
        return rew.balanceOf(a,balanceOf(a),Remainder.wrap(spearToken.balanceOf(address(stakerSpearRewardWallet))));
    }

    function claimReward(address to) public returns(uint256 ret) {
        ret = _claimReward(to);
        _checkZero(_msgSender());
    }
    
    function _claimReward(address to) internal returns(uint256) {
        if (_needsSync)
            _sync();
        
        address sender = _msgSender();
        if (to == address(0))
            to = sender;
        uint256 amount = rew.claim(sender,balanceOf(sender),Remainder.wrap(spearToken.balanceOf(address(stakerSpearRewardWallet))));
        if (amount > 0) {
            //This will always succeed because of Remainder param above
            stakerSpearRewardWallet.transferTokenTo(spearToken,to,amount);
        }
        _adjustRewards();
        emit DripRewarder.RewardClaimed(sender,to,amount);
        return amount;
    }

    function _adjustRewards() internal {
        _needsSync = false;
        rew.setMaxRewards(totalStakerSpearRewardsAdded);
        rew.setDripRate(DripRate.wrap(spearToken.balanceOf(address(stakerSpearRewardWallet)) * (GladiatorConstants.stakerSpearDripRatePerc) / (GladiatorConstants.stakerSpearDripRatePercTotal)),
                        _holders, balanceOf);
    }

    function _adjustRewards(uint256 basis) internal {
        _needsSync = false;
        rew.setMaxRewards(totalStakerSpearRewardsAdded);
        rew.setDripRateAndBasis(DripRate.wrap(spearToken.balanceOf(address(stakerSpearRewardWallet)) * (GladiatorConstants.stakerSpearDripRatePerc) / (GladiatorConstants.stakerSpearDripRatePercTotal)),
                                basis,
                                _holders, balanceOf);
    }
    
    function _checkNew(address a) internal {
        uint32 i=_holdersIndexPlusOne[a];
        if (i==0 || i==type(uint32).max) {
            _holders.push(a);
            require(_holders.length < type(uint32).max, "too many holders");
            _holdersIndexPlusOne[a] = uint32(_holders.length);
        }
    }

    function _checkZero(address a) internal {
        uint32 i = _holdersIndexPlusOne[a];
        if (i > 0 && i<type(uint32).max) {
            if (rewardBalance(a)>0 || balances[a]>0)
                return;
            _holdersIndexPlusOne[a] = type(uint32).max; // remember ok address
            address p = _holders[_holders.length-1];
            _holders.pop();
            if(p != a){
                _holders[i-1] = p;
                _holdersIndexPlusOne[p] = i;
            }
        }
    }
    
    function transferFrom(address from, address to, uint256 amount) public override(StandardToken) returns (bool ret) {
        if (_needsSync)
            _sync();
        if (rewardBalance(from)>0)
            claimReward(from);
        require(super.transferFrom(from, to, amount));
        _checkNew(to);
        _checkZero(from);
        return true;
    }

    function transfer(address to, uint256 amount) public override(StandardToken) returns (bool ret) {
        if (_needsSync)
            _sync();
        address from = _msgSender();
        if (rewardBalance(from)>0)
            _claimReward(from);
        require(super.transfer(to, amount));
        _checkNew(to);
        _checkZero(from);
        return true;
    }

    function remainingMintableSupply() public view returns (uint256) {
        return targetSupply - (_totalSupply);
    }

    function dripRate() public view returns(uint256) {
        return DripRate.unwrap(rew.dripRate);
    }
    
    function holders(uint i) public view onlyOwner returns(address){
        return _holders[i];
    }
    
    function holdersCount() public view onlyOwner returns(uint32){
        return uint32(_holders.length);
    }

    function setAutoHousekeepingPerc(uint8 p) public onlyOwner {
        if ( p > 100)
            p = 100;
        _autoHousekeepingPerc = p;
    }
    
    function autoHousekeepingPerc() public view onlyOwner returns(uint8){
        return _autoHousekeepingPerc;
    }

    function sync() public onlyOwner {
        _sync();
    }
    
    function _sync() internal {
        _needsSync = false;
        rew.setBasis(_totalSupply, _holders, balanceOf, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value -= 1;
    }
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    function initialize(string memory name) internal {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual;
        
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC2612Permit: expired deadline");

        bytes32 hashStruct =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ERC2612Permit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

library GenericUtils {
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "qutoe(): insufficient amountA");
        require(reserveA > 0 && reserveB > 0, "quote(): zero reserve");
        amountB = amountA * (reserveB) / (reserveA);
    }
}    

interface IGenericToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address from, address spender) external returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IGenericGraveyard {
    function getGraveyard() external returns (address);
}

interface IGenericTokenWithGraveyard is IGenericGraveyard, IGenericToken {
}

interface IGenericAVAXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function quote(uint256 amountA,uint256 reserveA,uint256 reserveB) external pure;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );
    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline) external payable returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
                             ) external returns (uint256 amountA, uint256 amountB);
    
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
                                                                 ) external payable;
}

interface IGenericFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external returns(address);
}

interface IGenericPair is IGenericToken {
    function kLast() external view returns(uint256);
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
                 ) ;
    function token0() external view returns(address);
    function token1() external view returns(address);
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SpearERC20Permit.sol";
import "./ERC20Metadata.sol";
import "./LockableOwnable.sol";

abstract contract StandardToken is ERC20Permit, ERC20Metadata {

    mapping(address => uint256) internal balances;

    uint256 internal _totalSupply;
    
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public virtual override returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - (_value);
        balances[_to] = balances[_to] + (_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public override  virtual returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from]            = balances[_from] - (_value);
        balances[_to]              = balances[_to] + (_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - (_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public override  returns (bool) {
        _approve(msg.sender,_spender,_value);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal override(ERC20Permit) {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public override  view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + (_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - (_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 */
abstract contract MintableBurnableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event MintFinished();

    bool private _mintingEnabled = true;

    modifier canMint() {
        require(_mintingEnabled);
        _;
    }

    function _mint(address _to, uint256 _amount) canMint internal returns (bool) {
        require(_to != address(0));
        _totalSupply = _totalSupply + (_amount);
        balances[_to] = balances[_to] + (_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function mintingEnabled() public view returns(bool) { return _mintingEnabled; }

    function enableMinting(bool t) public onlyOwner { _enableMinting(t); }
    
    function _enableMinting(bool t) internal { _mintingEnabled = t; }

    function _burn(uint256 _value) internal {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = _msgSender();
        balances[burner] = balances[burner] - (_value);
        _totalSupply = _totalSupply - (_value);
        emit Burn(burner, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./GenericDex.sol";
import "./Whitelist.sol";

contract WhitelistTokenWallet is Whitelist {
    function approveByWLSender(IGenericToken token, uint256 amount) public onlyWhitelistedOrOwner {
        token.approve(_msgSender(),amount);
    }
    function transferTokenTo(IGenericToken token, address to, uint256 amount) public onlyWhitelistedOrOwner {
        token.transfer(to,amount);
    }
    function claimToken(address token, uint amount) public onlyOwner {
        IGenericToken(token).transfer(owner(),amount);
    }
    function claim() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

//avoid parameter ordering errors in calls
type Remainder is uint256;
type DripAmount is uint256;
type DripRate is uint256;
type StartTime is uint256;

struct DripRewarderData {
    uint256 basis;
    DripRate dripRate;
    uint256 startTime;
    uint256 lastTime;
    uint256 maxRewards;
    uint32 dripSeconds;
    
    DripAmount _totalDrippedLast;

    mapping (address => int256) _bal; //signed!!
}

library DripRewarder {
    event RewardClaimed(address indexed from, address indexed to, uint256 amount);
    
    using DripRewarder for DripRewarderData;

    function initialize(DripRewarderData storage self, uint256 basis_, StartTime startTime_, DripRate dripRate_, DripAmount maxRewards_, uint32 dripSeconds_) internal {
        assert(self.lastTime == 0);
        //assert(DripAmount.unwrap(maxRewards_)>0);

        self.basis = basis_;
        self.startTime = StartTime.unwrap(startTime_);
        self.dripRate = dripRate_;
        self.dripSeconds = dripSeconds_;
        self.maxRewards = DripAmount.unwrap(maxRewards_);

        self.lastTime = type(uint256).max;
    }

    function setBasis(DripRewarderData storage self, uint256 basis_, address[] storage addrList, function(address) returns(uint256) bof, bool strict) internal {
        _checkpoint(self, addrList,bof, strict);
        self.basis = basis_;
    }

    function setDripRate(DripRewarderData storage self, DripRate dripRate_, address[] storage addrList, function(address) returns(uint256) bof) internal {
        _checkpoint(self, addrList,bof, true);
        self.dripRate = dripRate_;
    }

    function setDripRateAndBasis(DripRewarderData storage self, DripRate dripRate_, uint256 basis_, address[] storage addrList, function(address) returns(uint256) bof) internal {
        _checkpoint(self, addrList,bof, true);
        self.dripRate = dripRate_;
        self.basis = basis_;
    }

    function setMaxRewards(DripRewarderData storage self, uint256 maxRewards_) internal {
        self.maxRewards = maxRewards_;
    }

    function _checkpoint(DripRewarderData storage self, address[] storage addrList, function(address) returns(uint256) bof,bool strict) internal {
        require(addrList.length <= type(uint32).max, "DripRewarder: too many accounts");
        uint256 _now = block.timestamp;

        if (self.basis != 0) {
            if(self.lastTime != type(uint256).max && _now < self.lastTime) //DripRewarder: clocks going backward or too soon
                return;
            
            DripAmount curDrip = DripAmount.wrap(0);
            if (self.lastTime != type(uint256).max || _now >= self.startTime) {
                uint256 dt;
                (curDrip, dt) = self._curDrip();
                if (self.lastTime == type(uint256).max)
                    self.lastTime = self.startTime;
                self.lastTime = self.lastTime + (dt/self.dripSeconds)*self.dripSeconds; // quantize to the last time curDrip changed
            }
            
            uint256 sum = 0;
            for(uint32 x=0;x<addrList.length;++x){
                address a = addrList[x];
                uint256 b = bof(a);
                sum = sum + b;
                uint256 bal = self.balanceOf(a,b,curDrip); // it's ok we updated self.lastTime because we use curDrip
                require(bal<uint256(type(int256).max),"DripRewarder: overflow");
                self._bal[a] = int256(bal);
            }
            if (strict)
                require(sum==self.basis,"sum");
        } else {
            require(addrList.length==0,"addrlist");
            if (self.startTime == type(uint256).max){
                self.startTime = _now;
                self.lastTime = _now;
            }
        }
        self._totalDrippedLast = self.totalDripped();
    }

    function balanceOf(DripRewarderData storage self, address a, uint256 basisPart) internal view returns(uint256) {
        return self.balanceOf(a, basisPart, Remainder.wrap(type(uint256).max));
    }
            
    function totalDripped(DripRewarderData storage self) internal view returns(DripAmount) {
        (DripAmount da,) = self._curDrip();
        return DripAmount.wrap(DripAmount.unwrap(self._totalDrippedLast) + DripAmount.unwrap(da));
    }

    function _dt(DripRewarderData storage self) internal view returns(uint256 dt) {
        dt = block.timestamp;
        if (dt < self.startTime)
            return 0;

        dt = dt - (self.lastTime == type(uint256).max ? self.startTime:self.lastTime);
    }
        
    function _curDrip(DripRewarderData storage self) internal view returns(DripAmount, uint256 dt) {
        uint256 ret;
        dt = self._dt();
        ret = (dt/self.dripSeconds)*DripRate.unwrap(self.dripRate);
        
        if (self.maxRewards < DripAmount.unwrap(self._totalDrippedLast)+ret){
            if(self.maxRewards <= DripAmount.unwrap(self._totalDrippedLast)){
                return (DripAmount.wrap(0),dt);
            }
            ret = self.maxRewards-DripAmount.unwrap(self._totalDrippedLast);
        }
        return (DripAmount.wrap(ret),dt);
    }

    function balanceOf(DripRewarderData storage self, address a, uint256 basisPart, Remainder rem) internal view returns(uint256) {
        (DripAmount da,) = self._curDrip();
        return self.balanceOf(a, basisPart, da, rem);
    }

    function balanceOf(DripRewarderData storage self, address a, uint256 basisPart, DripAmount curDrip) internal view returns(uint256 ret) {
        return balanceOf(self,a,basisPart,curDrip,Remainder.wrap(type(uint256).max));
    }
        
    function balanceOf(DripRewarderData storage self, address a, uint256 basisPart, DripAmount curDrip, Remainder rem) internal view returns(uint256 ret) {
        if (self.basis==0){
            return 0;
        }
        
        uint256 contrib = (DripAmount.unwrap(curDrip)*basisPart)/self.basis;
        require(contrib <= uint256(type(int256).max) && contrib>=0,"contrib");

        ret = uint256(self._bal[a] + int256(contrib));
        require(ret >= 0,"ret");
        if (Remainder.unwrap(rem) < ret)
            ret = Remainder.unwrap(rem);
        return uint256(ret);
    }

    function claim(DripRewarderData storage self, address a, uint256 basisPart, Remainder remaining) internal returns(uint256) {
        require(block.timestamp >= self.startTime, "DripRewarder: too soon");
        if (self.lastTime == type(uint256).max)
            self.lastTime = self.startTime;

        (DripAmount da,) = self._curDrip();
        return self.claim(a, basisPart, remaining, da);
    }
        
    function claim(DripRewarderData storage self, address a, uint256 basisPart, Remainder remaining, DripAmount curDrip) internal returns(uint256 ret) {
        ret = self.balanceOf(a, basisPart, curDrip, remaining);
        require(ret > 0, "DripRewarder: no claim");
        self._bal[a] = self._bal[a] - int256(ret);
        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

pragma solidity ^0.8.13;

abstract contract ERC20Metadata is IERC20Metadata {
    string internal _name;
    string internal _symbol;

    function _initialize(string memory name_, string memory symbol_) internal virtual {
        require(bytes(name_).length > 0 && bytes(symbol_).length > 0, "Description information must be set");
        
        //Core Setup
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual returns (uint8);
}

// SPDX-License-Identifier: MIT

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

pragma solidity >=0.8.13;

abstract contract LockableOwnable is Ownable {
    address private _previousOwner;
    uint256 private _lockTime;

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner();
        _lockTime = block.timestamp + time;
        renounceOwnership();
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until getUnlockTime()");
        _previousOwner = address(0);
        _lockTime = 0;
        _transferOwnership(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelistedOrOwner() {
        require(whitelist[msg.sender] || msg.sender==owner(), 'not whitelisted');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return success true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] calldata  addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return success true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return success true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] calldata addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}