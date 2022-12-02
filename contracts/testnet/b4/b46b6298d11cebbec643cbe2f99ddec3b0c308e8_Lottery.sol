//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "./interfaces/IWallet.sol";
import "./interfaces/IPrizePool.sol";
import "./interfaces/IGame.sol";
import "./interfaces/ILottery.sol";
import "./interfaces/IReferral.sol";
import "./interfaces/IPlatform.sol";
import "./interfaces/IPlatformAdmin.sol";
import "./interfaces/token/IERC20.sol";
import "./interfaces/token/IERC20Bonus.sol";
import "./interfaces/token/LinkTokenInterface.sol";
import "./interfaces/IRoundDeployer.sol";
import "./libs/utils/LUtil.sol";
import "./libs/utils/array/LArray.sol";
import "./libs/lottery/pool/LPrizePool.sol";
import "./libs/platform/LPlatform.sol";
import "./libs/lottery/LLottery.sol";
import "./utils/Context.sol";
import "./utils/structs/EnumerableSetUpgradeable.sol";
import "./Wallet.sol";
import "./PlatformAdminUpgradeable.sol";


contract PrizePoolUpgradeable is IPrizePool, PlatformAdminUpgradeable {
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    mapping (address => string) _walletsNames;
    EnumerableSetUpgradeable.AddressSet private _wallets;
    uint private _jackpotRequireMinimum;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using LPrizePool for EnumerableSetUpgradeable.AddressSet;
    
    modifier onlyWallet(address wallet) {
        require(_wallets.contains(wallet), "PRIZEPOOL: sender and recipient must be wallet");
        _;
    }

    function __PrizePool_init(address platformAddress) internal initializer {
        __PlatformAdmin_init(platformAddress);
    }

    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function addWallet(address walletAddress, string memory walletName) external onlyRole(LPlatform.adminRole) nonZeroAddress(walletAddress) {
        require(!_wallets.contains(walletAddress), "already exists");
        _wallets.add(walletAddress);
        _walletsNames[_wallets.at(_wallets.length() - 1)] = walletName;
    }

    function __PrizePool_init_unchained() internal initializer {
    }

    function resetJackpotMinimumAmount() internal {
        _jackpotRequireMinimum = LPrizePool.getJackpotMinimumAmount();
    }

    function walletBalances() public view returns(LUtil.PrizeWallet[] memory) {
        address tokenAddress = IPlatform(getPlatformAddress()).getTokenAddress(address(this));
        require(tokenAddress != address(0));
        IERC20 token = IERC20(tokenAddress);
        LUtil.PrizeWallet[] memory wallets = new LUtil.PrizeWallet[](LPrizePool.getPoolsCount());

        for (uint index = 0; index < LPrizePool.getPoolsCount(); index++) {
            address wallet = _wallets.at(index);
            uint amount = token.balanceOf(wallet);
            if (index == 0 && amount < _jackpotRequireMinimum) amount = _jackpotRequireMinimum;
            wallets[index] = LUtil.PrizeWallet(_walletsNames[wallet], wallet, amount);
        }
        return wallets;
    }

    function calculateAmount() internal view returns (uint) {
        address tokenAddress = IPlatform(getPlatformAddress()).getTokenAddress(address(this));
        require(tokenAddress != address(0));
        IERC20 token = IERC20(tokenAddress);
        uint amount;

        for (uint index = 0; index < LPrizePool.getPoolsCount(); index++) {
            amount += token.balanceOf(_wallets.at(index));
        }

        return amount;
    } 
    
    function getWalletAddress(LUtil.Wallets walletIndex) override external view returns (address) {
        return _wallets.at(uint(walletIndex));
    }

    /**
     * @dev distribute tokens to categories
     */
    function distribute(uint amount) internal {
        require(amount > 0, "PRIZEPOOL: Amount must be more than 0");
        _jackpotRequireMinimum = _wallets.distribute(getPlatformAddress(), address(this), _msgSender(), amount, _jackpotRequireMinimum);
    }
    
    /**
     * dev approve amount for round
     */
    function approve(LUtil.Wallets wallet, address roundAddress, uint amount) internal {
        _wallets.approve(wallet, roundAddress, amount);
    }

    function transaferOnClose() internal {
        _jackpotRequireMinimum = 0;
        IPlatform platform = IPlatform(getPlatformAddress());
        address platformOwner = platform.getPlatformOwnerAddress();
        // LinkTokenInterface link = LinkTokenInterface(platform.getLinkTokenAddress());
        // _safeTransfer(address(link), platformOwner, link.balanceOf(address(this)));

        address tokenAddress = platform.getTokenAddress(address(this));
        require(tokenAddress != address(0));
        IERC20 token = IERC20(tokenAddress);
        _safeTransfer(tokenAddress, platformOwner, token.balanceOf(address(this)));

        for (uint index = 0; index < LPrizePool.getPoolsCount(); index++) {
            IWallet wallet = IWallet(_wallets.at(index));
            wallet.transferTo(platform.getPlatformOwnerAddress(), wallet.balance());
        }
    }
}


contract GameUpgradeable is IGame, PrizePoolUpgradeable {
    LUtil.GameStatus private _status;
    EnumerableSetUpgradeable.AddressSet private _rounds;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using LArray for EnumerableSetUpgradeable.AddressSet;

    modifier onlyRound() {
        require(_rounds.contains(_msgSender()), "GAME: msg.sender is not linked round");
        _;
    }

    function __Game_init(address platformAddress) internal initializer {
        __PrizePool_init(platformAddress);
    }

    function __Game_init_unchained() internal initializer {
    }

    function getCurrentRoundNumber() override external view returns(uint) {
        require(_rounds.length() > 0, "ROUND: empty set");
        return _rounds.length();
    }

    function getCurrentRoundAddress() override external view returns(address) {
        require(_rounds.length() > 0, "ROUND: empty set");
        return _rounds.at(_rounds.length() - 1);
    }

    function getStatus() override external view returns(LUtil.GameStatus) {
        return _status;
    }

    function getRounds(uint page, uint16 resultsPerPage, bool isReversed) override external view returns(address[] memory) {
        if (!isReversed) return _rounds.getPaginatedArray(page, resultsPerPage);
        else return _rounds.getPaginatedArrayReversed(page, resultsPerPage);
    }

    function getRoundsFromIndex(uint index, uint16 resultsPerPage, bool isReversed) override external view returns(address[] memory) {
        if (!isReversed) return _rounds.getPaginatedArrayFromIndex(index, resultsPerPage);
        else return _rounds.getPaginatedArrayFromIndexReversed(index, resultsPerPage);
    }

    function isRoundExist(address roundAddress) override external view nonZeroAddress(roundAddress) returns (bool, uint) {
        if (_rounds.contains(roundAddress)) return (true, _rounds.getIndex(roundAddress) - 1);
        else return (false, 0);
    }
    
    /**
     * @dev on starting new round we deploy it and start processing for previous
     */
    function createNewRound(uint ticketPrice) internal whenNotPaused {
        IPlatform platform = IPlatform(getPlatformAddress());
        if (_rounds.length() > 0) {
            address roundAddress = _rounds.at(_rounds.length() - 1);
            IRound round = IRound(roundAddress);
            
            if (round.getStatus() == LUtil.RoundStatus.OPEN) {
                //LinkTokenInterface(platform.getLinkTokenAddress()).transfer(roundAddress, platform.getLinkFee());
                round.startProcessing{value: msg.value}(walletBalances(), ticketPrice);
                IReferral(platform.getReferralSystemAddress()).startProcessing(roundAddress);
            } else IReferral(IPlatform(getPlatformAddress()).getReferralSystemAddress()).setRefunded(roundAddress);
                
        } else resetJackpotMinimumAmount();
        _rounds.add(IRoundDeployer(platform.getRoundDeployerAddress()).deploy());
    }

    function createPreLastRoundNumbers() external whenNotPaused onlyRole(LPlatform.adminRole) {
        address roundAddress = _rounds.at(_rounds.length() - 2);
        IRound round = IRound(roundAddress);
        require(round.getStatus() == LUtil.RoundStatus.GENERATING, "Round: not generating");
        round.fulfillRandomness();
    }

    function approvePay(LUtil.Wallets wallet, uint amount) override external onlyRound {
        approve(wallet, _msgSender(), amount);
    }

    function resetJackpot() override external onlyRound {
        resetJackpotMinimumAmount();
    }
    
    function updateUserPoints(address user, uint points) internal {
        IReferral(IPlatform(getPlatformAddress()).getReferralSystemAddress()).updateUserPoints(_rounds.at(_rounds.length() - 1), user, points);
    }

    function suspend() external onlyRole(LPlatform.adminRole) {
        _pause();
        IRound(_rounds.at(_rounds.length() - 1)).suspend();
    }

    function resume() external onlyRole(LPlatform.adminRole) {
        require(_status != LUtil.GameStatus.CLOSED, "GAME: can\'t resume closed game");
        _unpause();
        IRound round = IRound(_rounds.at(_rounds.length() - 1));

        if (round.getStatus() == LUtil.RoundStatus.OPEN) round.resume();
        else createNewRound(0);
    }

    function close() external onlyRole(LPlatform.adminRole) whenPaused {
        require(_status != LUtil.GameStatus.CLOSED, "GAME: already closed");
        IRound round = IRound(_rounds.at(_rounds.length() - 1));

        require(round.getStatus() == LUtil.RoundStatus.REFUND, "GAME: round not refunded");
        _status = LUtil.GameStatus.CLOSED;
    }

    function transferToOwner() external onlyRole(LPlatform.adminRole) {
        require(_status == LUtil.GameStatus.CLOSED, "GAME: must be closed");
        transaferOnClose();
    }
}


contract Lottery is ILottery, GameUpgradeable {
    uint private _ticketPrice;

    function initialize(address platformAddress, uint ticketPrice) public initializer {
        __Lottery_init(platformAddress, ticketPrice);
    }

    function __Lottery_init(address platformAddress, uint ticketPrice) internal initializer {
        _ticketPrice = ticketPrice;
        __Game_init(platformAddress);
    }

    function __Lottery_init_unchained() internal initializer {
    }

    function getTicketPrice() override external view returns (uint) {
        return _ticketPrice;
    }

    /**
     * @dev batch buy many tickets
     * 
     * @param numbersArray array of numbers chosen by user for all his tickets
     * @param amount total amount of tokens
     * @param useBonus set tru if we want use bonuses for buy
     *                  if bonuses not enough we transfering tokens on remaining amount
     */
    function buyTickets(uint8[][] calldata numbersArray, uint amount, bool useBonus) external whenNotPaused {
        _distributeTickets(numbersArray, amount, useBonus);
    }
    
    /**
     * @dev batch buy many tickets with referrer
     * 
     * @param numbersArray array of numbers chosen by user for all his tickets
     * @param amount total amount of tokens
     * @param referrer user who invite to platform (set once)
     */
    function buyTicketsWithReferrer(uint8[][] calldata numbersArray, uint amount, address referrer) external whenNotPaused nonZeroAddress(referrer) {
        IReferral referralSystem = IReferral(IPlatform(getPlatformAddress()).getReferralSystemAddress());
        if (!referralSystem.isExist(_msgSender())) referralSystem.setReferrer(_msgSender(), referrer);
        _distributeTickets(numbersArray, amount, false);
    }
    
    function startNewRound() external payable onlyRole(LPlatform.adminRole) {
        createNewRound(_ticketPrice);
    }

    /** 
     * @param numbersArray array of numbers chosen by user for all his tickets
     * @param amount ticket price * count
     */
    function _distributeTickets(uint8[][] memory numbersArray, uint amount, bool useBonus) private {
        require(amount == _ticketPrice * numbersArray.length, "LOTTERY: Invalid amount of ticket");
        LLottery.validateTickets(numbersArray);

        IPlatform platform = IPlatform(getPlatformAddress());
        IERC20 token = IERC20(platform.getTokenAddress(address(this)));
        uint amount_;

        (bool isBonusAvailable, bool isBurnAvailable, bool isBuybackAvailable) = platform.getGameConfig(address(this));

        if (isBonusAvailable && useBonus) {
            IERC20Bonus bonusToken = IERC20Bonus(platform.getBonusTokenAddress());
            uint bonusBalance = bonusToken.balanceOf(_msgSender());
            
            if (bonusBalance < amount) {
                token.transferFrom(_msgSender(), address(this), amount - bonusBalance);
                amount_ = bonusBalance;
            } else amount_ = amount;
            bonusToken.transferToOwner(_msgSender(), amount_);
        } else {
            token.transferFrom(_msgSender(), address(this), amount);
        }
        
        IReferral referralSystem = IReferral(platform.getReferralSystemAddress());
        if (!referralSystem.isExist(_msgSender())) {
            referralSystem.setReferrer(_msgSender(), _msgSender());
        }
        
        updateUserPoints(_msgSender(), numbersArray.length);
        distribute(amount);
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../libs/utils/LUtil.sol";


interface IWallet {
    function balance() external view returns (uint);
    function approve(address approver, uint amount) external;
    function transferTo(address recipient, uint amount) external;
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../libs/utils/LUtil.sol";


interface IPrizePool {
    function getWalletAddress(LUtil.Wallets walletIndex) external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "./interfaces/access/IAccessControlUpgradeable.sol";
import "./interfaces/IPlatformAdmin.sol";
import "./security/PausableUpgradeable.sol";
import "./BaseUpgradeable.sol";


contract PlatformAdminUpgradeable is IPlatformAdmin, PausableUpgradeable, BaseUpgradeable {
    address private _platformAddress;

    function __PlatformAdmin_init(address platformAddress) internal initializer {
        _platformAddress = platformAddress;
        __Pausable_init();
        __Base_init();
    }

    function __PlatformAdmin_init_unchained() internal initializer {
    }

    modifier onlyRole(bytes32 role) {
        require(IAccessControlUpgradeable(_platformAddress).hasRole(role, _msgSender()), "PlatformAdmin: permission denied for msg.sender");
        _;
    }

    function getPlatformAddress() override public view returns (address) {
        return _platformAddress;
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../libs/utils/LUtil.sol";


interface IGame {
    function getStatus() external view returns(LUtil.GameStatus);
    function getCurrentRoundNumber() external view returns (uint);
    function getCurrentRoundAddress() external view returns (address);
    function getRounds(uint page, uint16 resultsPerPage, bool isReversed) external view returns(address[] memory);
    function getRoundsFromIndex(uint index, uint16 resultsPerPage, bool isReversed) external view returns(address[] memory);
    function isRoundExist(address roundAddress) external view returns(bool, uint);
    function approvePay(LUtil.Wallets wallet, uint amount) external;
    function resetJackpot() external;
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "./interfaces/IWallet.sol";
import "./interfaces/IPlatformAdmin.sol";
import "./interfaces/IPlatform.sol";
import "./interfaces/IPrizePool.sol";
import "./interfaces/token/IERC20.sol";
import "./libs/utils/LUtil.sol";
import "./access/Ownable.sol";


abstract contract Wallet is IWallet, Ownable {
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    modifier isRecipients(LUtil.WinnerPay calldata recipient) {
        require((recipient.recipient != address(0) && recipient.amount > 0), "recipients must be provided");
        _;
    }

    function balance() override public view returns(uint) {
        return IERC20(_getTokenAddress()).balanceOf(address(this));
    }

    function transferTo(address recipient, uint amount) override external onlyOwner() {
        _safeTransfer(_getTokenAddress(), recipient, amount);
    }

    function _getTokenAddress() internal view returns (address) {
        address tokenAddress = IPlatform(IPlatformAdmin(owner()).getPlatformAddress()).getTokenAddress(owner());
        require(tokenAddress != address(0));
        return tokenAddress;
    }

    function approve(address approver, uint amount) override external onlyOwner() {
        IERC20(_getTokenAddress()).approve(approver, amount);
    }
}

contract BoosterWallet is Wallet {
    function topUp() external payable {
        require(msg.value > 0);
    }

    function topUpJackpot(address jackpot, uint amount) external onlyOwner() {
        require(amount > 0, "Amount must be more than 0");
        _safeTransfer(_getTokenAddress(), jackpot, amount);
    }
}

contract GameWallet is Wallet {
}

contract JackpotWallet is Wallet {
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


interface ILottery {
    function getTicketPrice() external view returns (uint);
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


interface IPlatformAdmin {
    function getPlatformAddress() external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.8.0 <0.9.0;

import "../libs/utils/LUtil.sol";
import "./IWitnetRandomness.sol";

interface IPlatform {
    function getStatus() external view returns (LUtil.PlatformStatus);
    function getTokenAddress(address gameAddress) external view returns (address);
    function getGameConfig(address _gameAddress) external view returns (bool, bool, bool);
    function getRoundDeployerAddress() external view returns (address);
    function getReferralSystemAddress() external view returns (address);
    function getBonusTokenAddress() external view returns (address);
    function getPlatformOwnerAddress() external view returns (address);
    function getBuybackTreasuryAddress() external view returns (address);
    function getRouterAddress() external view returns (address);
    function getWitnetRandomness() external view returns (IWitnetRandomness);
    // function getLinkTokenAddress() external view returns (address);
    // function getVRFCoordinatorAddress() external view returns (address);
    // function getVRFKeyHash() external view returns (bytes32);
    // function getLinkFee() external view returns (uint256);
    function getGames(uint page, uint16 resultsPerPage, bool isReversed) external view returns (address[] memory);
    function isGameExist(address game) external view returns (bool);
    function isRoundExist(address roundAddress) external view returns (bool, uint, address);
    function setTokenAddress(address gameAddress, address tokenAddress) external;
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;



interface IReferral {
    function isExist(address referral) external view returns(bool);
    function getReferrer(address referral) external view returns(address);
    function updateUserPoints(address roundAddress, address user, uint ticketsCount) external;
    function setReferrer(address referral, address referrer) external;
    function startProcessing(address roundAddress) external;
    function setRefunded(address roundAddress) external;
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


interface IRoundDeployer {
    function deploy() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Bonus {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transferToOwner(address from, uint256 amount) external returns (bool);

    function transferFromOwner(address recipient, uint256 amount) external returns (bool);

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
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataBonus is IERC20Bonus {
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

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


library LUtil {
    enum PlatformStatus { OPENED, RUNNING, CLOSING, CLOSED }
    enum GameStatus { OPENED, RUNNING, CLOSING, CLOSED }
    enum RoundStatus { OPEN, PROCESSING, PAYING, CLOSED, GENERATING, REFUND }
    enum WinnerCategory { JACKPOT, CATEGORY2, CATEGORY3, CATEGORY4, CATEGORY5 }
    enum Wallets { JACKPOT_WALLET, CATEGORY2_WALLET, CATEGORY3_WALLET, CATEGORY4_WALLET, CATEGORY5_WALLET, BOOSTER_WALLET }

    struct PrizeWallet {
        string key;
        address wallet;
        uint amount;
    }

    struct WinnerPay {
        address recipient;
        uint amount;
        uint ticketsCount;
        bool isValid;
    }

    /// All the needed info around a ticket
    struct TicketObject {
        uint256 key;
        address owner;
        uint8[] numbers;
        bool isValid;
    }

    struct DistributionFlags {
        bool isBonusAvailable;
        bool isBurnAvailable;
        bool isBuybackAvailable;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../../libs/utils/LUtil.sol";
import "../../interfaces/IGame.sol";
import "../../libs/referral/LReferral.sol";
import "../../utils/structs/EnumerableSetUpgradeable.sol";



library LPlatform {
    bytes32 public constant ownerRole = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    bytes32 public constant adminRole = 0xf23ec0bb4210edd5cba85afd05127efcd2fc6a781bfed49188da1081670b22d8;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function isGamesClosed(EnumerableSetUpgradeable.AddressSet storage games) public view returns(bool) {
        bool isClosed = true;

        for (uint index = 0; index < games.length(); index++) {
            IGame game = IGame(games.at(index));
            if (game.getStatus() != LUtil.GameStatus.CLOSED) {
                isClosed = false; break;
            }
        }
        return isClosed;
    }

    function isRoundExist(EnumerableSetUpgradeable.AddressSet storage games, address roundAddress) public view returns (bool, uint, address) {
        require(roundAddress != address(0), "LPLATFORM: round address is zero");
        bool isRoundExist_;
        uint roundIndex;
        address gameAddress;
        for (uint index = 0; index < games.length(); index++) {
            IGame game = IGame(games.at(index));
            (isRoundExist_, roundIndex) = game.isRoundExist(roundAddress);

            if (roundIndex > 0) {
                gameAddress = games.at(index);
                break;
            }
        }

        return (isRoundExist_, roundIndex, gameAddress);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.8.0 <0.9.0;


import "../../interfaces/IRound.sol";
import "../../interfaces/IGame.sol";


library LLottery {
    
    function getTicketLength() public pure returns (uint8) {
        return 0x6;
    }
    
    function getMinNumber() public pure returns (uint8) {
        return 0x1;
    }
    
    function getMaxNumber() public pure returns (uint8) {
        return 0x2d;
    }

    function validateTickets(uint8[][] calldata numbersArray) external {
        IRound round = IRound(IGame(address(this)).getCurrentRoundAddress());
        for (uint index = 0; index < numbersArray.length; index++) {
            require(numbersArray[index].length == getTicketLength(), "LLottery: invalid ticket length");
            
            for (uint numIndex = 0; numIndex < getTicketLength(); numIndex++) {
                require(numbersArray[index][numIndex] > getMinNumber() - 1 && numbersArray[index][numIndex] < getMaxNumber() + 1, "LLottery: invalid numbers range");
                for (uint idx = index; idx < getTicketLength(); idx++) {
                    if (numIndex == idx) continue;
                    require(numbersArray[index][numIndex] != numbersArray[index][idx], "LLottery: dublicated number error");
                }
            }
            
            round.setTicket(numbersArray[index], msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    /**
     * @dev custom function to get element index
     */
    function _getIndex(Set storage set, bytes32 value) private view returns (uint) {
        return set._indexes[value];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    function getIndex(AddressSet storage set, address value) internal view returns (uint) {
        return _getIndex(set._inner, bytes32(uint256(uint160(value))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../../../interfaces/token/IERC20.sol";
import "../../../interfaces/token/IERC20Bonus.sol";
import "../../../interfaces/IWallet.sol";
import "../../../interfaces/IPlatform.sol";
import "../../../interfaces/IReferral.sol";
import "../../utils/LUtil.sol";
import "../../../utils/structs/EnumerableSetUpgradeable.sol";
import "../../../interfaces/swap-core/IUniswapV2Router02.sol";


library LPrizePool {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function getPoolsCount() public pure returns (uint8) {
        return 0x6;
    }

    function getCommonPrizePoolPercent() public pure returns (uint16) {
        return 0x1388; // 5000 - 50%
    }

    function getReferrerPurposePercent() public pure returns (uint16) {
        return 0x1F4; // 500 - 5%
    }

    function getReferrer2PurposePercent() public pure returns (uint16) {
        return 0x1F4; // 500 - 5%
    }

    // USDT
    function getPlatformPurposePercentUSDT() public pure returns (uint16) {
        return 0x9C4; // 2500 - 25%
    }

    function getULXBuybackPercent() public pure returns (uint16) {
        return 0x3E8; // 1000 - 10%
    }

    function getBonusPurposePercent() public pure returns (uint16) {
        return 0x1F4; // 500 - 5%
    }
    // USDT

    // ULX
    function getPlatformPurposePercentULX() public pure returns (uint16) {
        return 0x7D0; // 2000 - 20%
    }

    function getBurnPurposePercent() public pure returns (uint16) {
        return 0x7D0; // 2000 - 20%
    }
    // ULX

    function getJackpotPercent() public pure returns (uint16) {
        return 0x802; // 2050 - 20,50 %
    }

    function getCategoryTwoPercent() public pure returns (uint16) {
        return 0x60E; // 1550 - 15,50 %
    }

    function getCategoryThreePercent() public pure returns (uint16) {
        return 0x3B6; // 950 - 9,50%
    }

    function getCategoryFourPercent() public pure returns (uint16) {
        return 0x546; // 1350 - 13,50%
    }

    function getCategoryFivePercent() public pure returns (uint16) {
        return 0xC1C; // 3100 - 31%
    }

    function getBoosterPercent() public pure returns (uint16) {
        return 0x3E8; // 1000 - 10%
    }

    function getBoosterFundLimit() public pure returns (uint) {
        return 0x2ba7def3000; // 3 kk USDT 0x2ba7def3000 && 90 kk ULX 0x4A723DC6B40B8A9A000000
    }

    function getJackpotMinimumAmount() public pure returns (uint) {
        return 0xe8d4a51000; // 1 kk USDT 0xe8d4a51000 && 30 kk ULX 0x18D0BF423C03D8DE000000
    }

    //The function to distribute funds from prize pool to categories
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _swapWETH(address wethAddress, address treasuryAddress, address routerAddress, uint amount, address tokenAddress) private {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = wethAddress;
        uint[] memory amountsOut = IUniswapV2Router02(routerAddress).getAmountsOut(amount, path);
        if(amountsOut[amountsOut.length - 1] > 0) {
            uint amountOutMin = amountsOut[amountsOut.length - 1] - amountsOut[amountsOut.length - 1] * 0xa / 0x64;
            IERC20(tokenAddress).approve(routerAddress, amount);
            IUniswapV2Router02(routerAddress).swapExactTokensForETH(amount, amountOutMin, path, treasuryAddress, block.timestamp + 30);
        }
        else {
            _safeTransfer(tokenAddress, treasuryAddress, amount);
        }
    }

    function _distributePlartformPercent(
        bool isBonusAvailable, 
        IPlatform platform,
        uint amount,
        address buyer, 
        address tokenAddress) 
        private 
        returns(uint platformPercent, uint roundPrize)
    {
        if(isBonusAvailable) {
            platformPercent = getPlatformPurposePercentUSDT();
            {
                IERC20Bonus bonusToken = IERC20Bonus(platform.getBonusTokenAddress());
                bonusToken.transferFromOwner(buyer, amount * getBonusPurposePercent() / 0x2710);
            }
        }
        else {
            platformPercent = getPlatformPurposePercentULX();
        }

        roundPrize = amount * getCommonPrizePoolPercent() / 0x2710;
        {
            IReferral referralSystem = IReferral(platform.getReferralSystemAddress());
            address referrer = referralSystem.getReferrer(buyer);

            if (referrer == address(0)) {
                platformPercent += getReferrerPurposePercent();
            } else {
                _safeTransfer(tokenAddress, referrer, amount * getReferrerPurposePercent() / 0x2710);
            }
            _safeTransfer(tokenAddress, address(referralSystem), amount * getReferrer2PurposePercent() / 0x2710);
        }
    }

    function _distribute(
        EnumerableSetUpgradeable.AddressSet storage wallets,
        IPlatform platform,
        address tokenAddress,
        uint platformPercent, uint amount, uint roundPrize,
        bool isBurnAvailable, bool isBuybackAvailable) private 
    {
        IUniswapV2Router02 router = IUniswapV2Router02(platform.getRouterAddress());
        _safeTransfer(tokenAddress,  platform.getPlatformOwnerAddress(), amount * platformPercent / 0x2710);
        if(isBurnAvailable) {
            _safeTransfer(tokenAddress, platform.getBuybackTreasuryAddress(), amount * getBurnPurposePercent() / 0x2710);
        }
        if(isBuybackAvailable) {
            _safeTransfer(tokenAddress, platform.getBuybackTreasuryAddress(), amount * getULXBuybackPercent() / 0x2710);
            // _swapWETH(router.WETH(), platform.getBuybackTreasuryAddress(), address(router), amount * getULXBuybackPercent() / 0x2710, tokenAddress);
        }
        _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.CATEGORY2_WALLET)), roundPrize * getCategoryTwoPercent() / 0x2710);
        _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.CATEGORY3_WALLET)), roundPrize * getCategoryThreePercent() / 0x2710);
        _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.CATEGORY4_WALLET)), roundPrize * getCategoryFourPercent() / 0x2710);
        _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.CATEGORY5_WALLET)), roundPrize * getCategoryFivePercent() / 0x2710);
    }

    function _distributeJackpot(
        EnumerableSetUpgradeable.AddressSet storage wallets,
        address tokenAddress,
        uint roundPrize, uint jackpotRequireMin) private returns (uint)
    {
        IERC20 token = IERC20(tokenAddress);
        uint jackpotAmount = roundPrize * getJackpotPercent() / 0x2710;
        if (token.balanceOf(wallets.at(uint(LUtil.Wallets.BOOSTER_WALLET))) > getBoosterFundLimit()) {
            jackpotAmount += roundPrize * getBoosterPercent() / 0x2710;
        } else {
            if (token.balanceOf(wallets.at(uint(LUtil.Wallets.JACKPOT_WALLET))) < jackpotRequireMin) {
                uint amount_ = roundPrize * ((getBoosterPercent() / 0x64) * 0xa / 0x2) / 0x3e8;
                jackpotAmount += amount_;
                jackpotRequireMin += amount_;
                _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.BOOSTER_WALLET)), amount_);
            }
            else {
                _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.BOOSTER_WALLET)), roundPrize * getBoosterPercent() / 0x2710);
            } 
        } 
        _safeTransfer(tokenAddress, wallets.at(uint(LUtil.Wallets.JACKPOT_WALLET)), jackpotAmount);
        return jackpotRequireMin;
    }

    function distribute(
        EnumerableSetUpgradeable.AddressSet storage wallets, 
        address platformAddress, 
        address gameAddress,
        address buyer, uint amount, uint jackpotRequireMin) external returns (uint) {
        require(amount > 0, "PRIZEPOOL: Amount must be more than 0");
        IPlatform platform = IPlatform(platformAddress);

        address tokenAddress = platform.getTokenAddress(gameAddress);
        
        (bool isBonusAvailable, bool isBurnAvailable, bool isBuybackAvailable) = platform.getGameConfig(gameAddress);

        (uint platformPercent, uint roundPrize) = _distributePlartformPercent(isBonusAvailable, platform, amount, buyer, tokenAddress);

        _distribute(wallets, platform, tokenAddress, platformPercent, amount, roundPrize, isBurnAvailable, isBuybackAvailable);

        return _distributeJackpot(wallets, tokenAddress, roundPrize, jackpotRequireMin);
    }

    function approve(
        EnumerableSetUpgradeable.AddressSet storage wallets,
        LUtil.Wallets wallet,
        address roundAddress,
        uint amount) internal {
            IWallet(wallets.at(uint(wallet))).approve(roundAddress, amount);
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../../../utils/structs/EnumerableSetUpgradeable.sol";


library LArray {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    modifier nonZeroResultsPage(uint number) {
        require(number > 0, "LArray: results per page cant be 0");
        _;
    }

    function getPaginatedArray(address[] storage array, uint page, uint16 resultsPerPage) external view returns(address[] memory) {
        uint startIndex; uint stopIndex; uint elementsCount;
        (startIndex, stopIndex, elementsCount) = getPositions(array.length, page, resultsPerPage);
        address[] memory cuttedArray = new address[](elementsCount);

        uint iterator;
        for (uint index = startIndex; index < stopIndex + 1; index++) {
            cuttedArray[iterator] = array[index];
            iterator++; 
        }

        return cuttedArray;
    }

    function getPaginatedArrayReversed(address[] storage array, uint page, uint16 resultsPerPage) external view returns(address[] memory) {
        uint startIndex; uint stopIndex; uint elementsCount;
        (startIndex, stopIndex, elementsCount) = getPositionsReversed(array.length, page, resultsPerPage);
        address[] memory cuttedArray = new address[](elementsCount);

        uint iterator;
        uint index = startIndex;
        while (index >= stopIndex) {
            cuttedArray[iterator] = array[index];
            iterator++;

            if (index == stopIndex) {
                break;
            }
            index--;
        }

        return cuttedArray;
    }

    function getPaginatedArray(uint[] storage array, uint page, uint16 resultsPerPage) external view returns(uint[] memory) {
        uint startIndex; uint stopIndex; uint elementsCount;
        (startIndex, stopIndex, elementsCount) = getPositions(array.length, page, resultsPerPage);
        uint[] memory cuttedArray = new uint[](elementsCount);

        uint iterator;
        for (uint index = startIndex; index < stopIndex + 1; index++) {
            cuttedArray[iterator] = array[index];
            iterator++; 
        }

        return cuttedArray;
    }

    function getPaginatedArray(EnumerableSetUpgradeable.AddressSet storage set, uint page, uint16 resultsPerPage) external view returns(address[] memory) {
        uint startIndex; uint stopIndex; uint elementsCount;
        (startIndex, stopIndex, elementsCount) = getPositions(set.length(), page, resultsPerPage);
        address[] memory cuttedArray = new address[](elementsCount);

        uint iterator;
        for (uint256 index = startIndex; index < stopIndex + 1; index++) {
            cuttedArray[iterator] = set.at(index);
            iterator++; 
        }

        return cuttedArray;
    }

    function getPaginatedArrayReversed(EnumerableSetUpgradeable.AddressSet storage set, uint page, uint16 resultsPerPage) external view returns(address[] memory) {
        uint startIndex; uint stopIndex; uint elementsCount;
        (startIndex, stopIndex, elementsCount) = getPositionsReversed(set.length(), page, resultsPerPage);
        address[] memory cuttedArray = new address[](elementsCount);

        uint iterator;
        uint index = startIndex;
        while (index >= stopIndex && iterator < elementsCount) {
            cuttedArray[iterator] = set.at(index);
            iterator++;

            if (index == stopIndex) {
                break;
            }
            index--;
        }

        return cuttedArray;
    }

    function getPaginatedArrayFromIndex(EnumerableSetUpgradeable.AddressSet storage set, uint index, uint16 resultsPerPage) external view returns (address[] memory) {
        uint stopIndex; uint elementsCount;
        (stopIndex, elementsCount) = getPositionsFromIndex(set.length(), index, resultsPerPage);
        address[] memory cuttedArray = new address[](elementsCount);

        uint iterator;
        for (; index < stopIndex + 1; index++) {
            cuttedArray[iterator] = set.at(index);
            iterator++; 
        }

        return cuttedArray;
    }
    
    function getPaginatedArrayFromIndexReversed(EnumerableSetUpgradeable.AddressSet storage set, uint index, uint16 resultsPerPage) external view returns(address[] memory) {
        uint stopIndex; uint elementsCount;
        (stopIndex, elementsCount) = getPositionsFromIndexReversed(set.length(), index, resultsPerPage);
        address[] memory cuttedArray = new address[](elementsCount);

        uint iterator;
        while (index >= stopIndex && iterator < elementsCount) {
            cuttedArray[iterator] = set.at(index);
            iterator++;

            if (index == stopIndex) {
                break;
            }
            index--;
        }

        return cuttedArray;
    }

    function isExistOnPage(EnumerableSetUpgradeable.AddressSet storage set, address element, uint page, uint16 resultsPerPage) external view returns(bool) {
        uint startIndex; uint stopIndex;
        (startIndex, stopIndex,) = getPositions(set.length(), page, resultsPerPage);
        
        bool isExist;
        if (set.contains(element)) {
            uint256 index = set.getIndex(element);
            if (index > 0 && index - 1  >= startIndex && index - 1 < stopIndex) isExist = true;
        }

        return isExist;
    }

    function isExistOnPage(address[] storage array, address element, uint page, uint16 resultsPerPage) external view returns(bool) {
        uint startIndex; uint stopIndex; uint elementsCount;
        (startIndex, stopIndex, elementsCount) = getPositions(array.length, page, resultsPerPage);
        
        bool isExist;
        for (uint index = startIndex; index < stopIndex; index++) {
            if (array[index] == element) {
                isExist = true; break;
            }
        }

        return isExist;
    }

    function getPositions(uint size, uint page, uint16 resultPerPage) public pure nonZeroResultsPage(resultPerPage) returns (uint, uint, uint) {
        require(page > 0, "LArray: Invalid page");
        uint lastIndex = resultPerPage * page - 1;

        uint elementsCount;
        uint startIndex = resultPerPage * (page - 1);
        uint stopIndex;
        if (size > 0) stopIndex = lastIndex > size - 1 ? size - 1 : lastIndex;
        else stopIndex = size;
        if (size <= resultPerPage) elementsCount = size;
        else elementsCount = lastIndex > size - 1 ? lastIndex - (lastIndex - size) - (resultPerPage * (page - 1)) : resultPerPage;

        return (startIndex, stopIndex, elementsCount);
    }

    function getPositionsFromIndex(uint size, uint index, uint16 resultPerPage) public pure nonZeroResultsPage(resultPerPage) returns (uint, uint) {
        require(index >= 0 && index < size, "LArray: Invalid index");
        uint lastIndex = resultPerPage + index - 1;

        uint elementsCount;
        uint stopIndex = lastIndex > size - 1 ? size - 1 : lastIndex;
        if (size <= resultPerPage) elementsCount = size;
        else elementsCount = lastIndex > size - 1 ? lastIndex - (lastIndex - size) - index : resultPerPage;

        return (stopIndex, elementsCount);
    }

    function getPositionsReversed(uint size, uint page, uint16 resultPerPage) public pure nonZeroResultsPage(resultPerPage) returns (uint, uint, uint) {
        require(page > 0, "LArray: Invalid page");
        uint startIndex; uint stopIndex;
        startIndex = size > 0 ? size - ((page - 1) * resultPerPage) - 1 : 0;
        stopIndex = startIndex + 1 > resultPerPage ? (startIndex + 1) - resultPerPage : 0;
        
        uint elementsCount;
        elementsCount = startIndex >= resultPerPage ? resultPerPage : startIndex + 1;
        if (size < 1) elementsCount = 0;
        return (startIndex, stopIndex, elementsCount);
    }
    
    function getPositionsFromIndexReversed(uint size, uint index, uint16 resultPerPage) public pure nonZeroResultsPage(resultPerPage) returns (uint, uint) {
        require(index >= 0 && index < size, "LArray: Invalid index");
        uint startIndex; uint stopIndex;
        startIndex = index;
        stopIndex = startIndex + 1 > resultPerPage ? (startIndex + 1) - resultPerPage : 0;
        
        uint elementsCount;
        elementsCount = startIndex >= resultPerPage ? resultPerPage : startIndex + 1;
        if (size < 1) elementsCount = 0;
        return (stopIndex, elementsCount);
    }

    function getPagesByLimit(uint size, uint16 limit) public pure returns(uint) {
        if (size < limit) return 1;
        if (size % limit == 0) return size / limit;
        return size / limit + 1;
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "./access/OwnableUpgradeable.sol";
import "./utils/ContextUpgradeable.sol";
import "./proxy/utils/UUPSUpgradeable.sol";


contract BaseUpgradeable is UUPSUpgradeable, OwnableUpgradeable {
    function __Base_init() internal initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function __Base_init_unchained() internal initializer {
    }

    modifier nonZeroAddress(address addr) {
        require(addr != address(0), "BASE: zero-address provided");
        _;
    }

    function _authorizeUpgrade(address newImplementation) override internal onlyOwner() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "../proxy/utils/Initializable.sol";


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../libs/Witnet.sol";

/// @title The Witnet Randomness generator interface.
/// @author Witnet Foundation.
interface IWitnetRandomness {

    /// Thrown every time a new WitnetRandomnessRequest gets succesfully posted to the WitnetRequestBoard.
    /// @param from Address from which the randomize() function was called. 
    /// @param prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @param witnetQueryId Unique query id assigned to this request by the WRB.
    /// @param witnetRequestHash SHA-256 hash of the WitnetRandomnessRequest actual bytecode just posted to the WRB.
    event Randomized(
        address indexed from,
        uint256 indexed prevBlock,
        uint256 witnetQueryId,
        bytes32 witnetRequestHash
    );

    /// Returns amount of wei required to be paid as a fee when requesting randomization with a 
    /// transaction gas price as the one given.
    function estimateRandomizeFee(uint256 _gasPrice) external view returns (uint256);

    /// Retrieves data of a randomization request that got successfully posted to the WRB within a given block.
    /// @dev Returns zero values if no randomness request was actually posted within a given block.
    /// @param _block Block number whose randomness request is being queried for.
    /// @return _from Address from which the latest randomness request was posted.
    /// @return _id Unique request identifier as provided by the WRB.
    /// @return _prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @return _nextBlock Block number in which a randomness request got posted just after this one, 0 if none.
    function getRandomizeData(uint256 _block)
        external view returns (address _from, uint256 _id, uint256 _prevBlock, uint256 _nextBlock);

    /// Retrieves the randomness generated upon solving a request that was posted within a given block,
    /// if any, or to the _first_ request posted after that block, otherwise. Should the intended 
    /// request happen to be finalized with errors on the Witnet oracle network side, this function 
    /// will recursively try to return randomness from the next non-faulty randomization request found 
    /// in storage, if any. 
    /// @dev Fails if:
    /// @dev   i.   no `randomize()` was not called in either the given block, or afterwards.
    /// @dev   ii.  a request posted in/after given block does exist, but no result has been provided yet.
    /// @dev   iii. all requests in/after the given block were solved with errors.
    /// @param _block Block number from which the search will start.
    function getRandomnessAfter(uint256 _block) external view returns (bytes32); 

    /// Tells what is the number of the next block in which a randomization request was posted after the given one. 
    /// @param _block Block number from which the search will start.
    /// @return Number of the first block found after the given one, or `0` otherwise.
    function getRandomnessNextBlock(uint256 _block) external view returns (uint256); 

    /// Gets previous block in which a randomness request was posted before the given one.
    /// @param _block Block number from which the search will start.
    /// @return First block found before the given one, or `0` otherwise.
    function getRandomnessPrevBlock(uint256 _block) external view returns (uint256);

    /// Returns `true` only when the randomness request that got posted within given block was already
    /// reported back from the Witnet oracle, either successfully or with an error of any kind.
    function isRandomized(uint256 _block) external view returns (bool);

    /// Returns latest block in which a randomness request got sucessfully posted to the WRB.
    function latestRandomizeBlock() external view returns (uint256);

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the randomness returned by `getRandomnessAfter(_block)`. 
    /// @dev Fails under same conditions as `getRandomnessAfter(uint256)` may do.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _block Block number from which the search will start.
    function random(uint32 _range, uint256 _nonce, uint256 _block) external view returns (uint32);

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the given `_seed` as a source of entropy.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _seed Seed value used as entropy source.
    function random(uint32 _range, uint256 _nonce, bytes32 _seed) external pure returns (uint32);

    /// Requests the Witnet oracle to generate an EVM-agnostic and trustless source of randomness. 
    /// Only one randomness request per block will be actually posted to the WRB. Should there 
    /// already be a posted request within current block, it will try to upgrade Witnet fee of current's 
    /// block randomness request according to current gas price. In both cases, all unused funds shall 
    /// be transfered back to the tx sender.
    /// @return _usedFunds Amount of funds actually used from those provided by the tx sender.
    function randomize() external payable returns (uint256 _usedFunds);

    /// Increases Witnet fee related to a pending-to-be-solved randomness request, as much as it
    /// may be required in proportion to how much bigger the current tx gas price is with respect the 
    /// highest gas price that was paid in either previous fee upgrades, or when the given randomness 
    /// request was posted. All unused funds shall be transferred back to the tx sender.
    /// @return _usedFunds Amount of dunds actually used from those provided by the tx sender.
    function upgradeRandomizeFee(uint256 _block) external payable returns (uint256 _usedFunds);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IWitnetRequest.sol";

library Witnet {

    /// @notice Witnet function that computes the hash of a CBOR-encoded Data Request.
    /// @param _bytecode CBOR-encoded RADON.
    function hash(bytes memory _bytecode) internal pure returns (bytes32) {
        return sha256(_bytecode);
    }

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        IWitnetRequest addr;    // The contract containing the Data Request which execution has been requested.
        address requester;      // Address from which the request was posted.
        bytes32 hash;           // Hash of the Data Request whose execution has been requested.
        uint256 gasprice;       // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;         // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        CBOR value;             // Resulting value, in CBOR-serialized bytes.
    }

    /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// Witnet error codes table.
    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// Unallocated
        ScriptFormat0x04,
        ScriptFormat0x05,
        ScriptFormat0x06,
        ScriptFormat0x07,
        ScriptFormat0x08,
        ScriptFormat0x09,
        ScriptFormat0x0A,
        ScriptFormat0x0B,
        ScriptFormat0x0C,
        ScriptFormat0x0D,
        ScriptFormat0x0E,
        ScriptFormat0x0F,
        // Complexity errors
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12,
        Complexity0x13,
        Complexity0x14,
        Complexity0x15,
        Complexity0x16,
        Complexity0x17,
        Complexity0x18,
        Complexity0x19,
        Complexity0x1A,
        Complexity0x1B,
        Complexity0x1C,
        Complexity0x1D,
        Complexity0x1E,
        Complexity0x1F,
        // Operator errors
        /// 0x20: The operator does not exist.
        UnsupportedOperator,
        /// Unallocated
        Operator0x21,
        Operator0x22,
        Operator0x23,
        Operator0x24,
        Operator0x25,
        Operator0x26,
        Operator0x27,
        Operator0x28,
        Operator0x29,
        Operator0x2A,
        Operator0x2B,
        Operator0x2C,
        Operator0x2D,
        Operator0x2E,
        Operator0x2F,
        // Retrieval-specific errors
        /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
        HTTP,
        /// 0x31: Retrieval of at least one of the sources timed out.
        RetrievalTimeout,
        /// Unallocated
        Retrieval0x32,
        Retrieval0x33,
        Retrieval0x34,
        Retrieval0x35,
        Retrieval0x36,
        Retrieval0x37,
        Retrieval0x38,
        Retrieval0x39,
        Retrieval0x3A,
        Retrieval0x3B,
        Retrieval0x3C,
        Retrieval0x3D,
        Retrieval0x3E,
        Retrieval0x3F,
        // Math errors
        /// 0x40: Math operator caused an underflow.
        Underflow,
        /// 0x41: Math operator caused an overflow.
        Overflow,
        /// 0x42: Tried to divide by zero.
        DivisionByZero,
        /// Unallocated
        Math0x43,
        Math0x44,
        Math0x45,
        Math0x46,
        Math0x47,
        Math0x48,
        Math0x49,
        Math0x4A,
        Math0x4B,
        Math0x4C,
        Math0x4D,
        Math0x4E,
        Math0x4F,
        // Other errors
        /// 0x50: Received zero reveals
        NoReveals,
        /// 0x51: Insufficient consensus in tally precondition clause
        InsufficientConsensus,
        /// 0x52: Received zero commits
        InsufficientCommits,
        /// 0x53: Generic error during tally execution
        TallyExecution,
        /// Unallocated
        OtherError0x54,
        OtherError0x55,
        OtherError0x56,
        OtherError0x57,
        OtherError0x58,
        OtherError0x59,
        OtherError0x5A,
        OtherError0x5B,
        OtherError0x5C,
        OtherError0x5D,
        OtherError0x5E,
        OtherError0x5F,
        /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
        MalformedReveal,
        /// Unallocated
        OtherError0x61,
        OtherError0x62,
        OtherError0x63,
        OtherError0x64,
        OtherError0x65,
        OtherError0x66,
        OtherError0x67,
        OtherError0x68,
        OtherError0x69,
        OtherError0x6A,
        OtherError0x6B,
        OtherError0x6C,
        OtherError0x6D,
        OtherError0x6E,
        OtherError0x6F,
        // Access errors
        /// 0x70: Tried to access a value from an index using an index that is out of bounds
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist
        MapKeyNotFound,
        /// Unallocated
        OtherError0x72,
        OtherError0x73,
        OtherError0x74,
        OtherError0x75,
        OtherError0x76,
        OtherError0x77,
        OtherError0x78,
        OtherError0x79,
        OtherError0x7A,
        OtherError0x7B,
        OtherError0x7C,
        OtherError0x7D,
        OtherError0x7E,
        OtherError0x7F,
        OtherError0x80,
        OtherError0x81,
        OtherError0x82,
        OtherError0x83,
        OtherError0x84,
        OtherError0x85,
        OtherError0x86,
        OtherError0x87,
        OtherError0x88,
        OtherError0x89,
        OtherError0x8A,
        OtherError0x8B,
        OtherError0x8C,
        OtherError0x8D,
        OtherError0x8E,
        OtherError0x8F,
        OtherError0x90,
        OtherError0x91,
        OtherError0x92,
        OtherError0x93,
        OtherError0x94,
        OtherError0x95,
        OtherError0x96,
        OtherError0x97,
        OtherError0x98,
        OtherError0x99,
        OtherError0x9A,
        OtherError0x9B,
        OtherError0x9C,
        OtherError0x9D,
        OtherError0x9E,
        OtherError0x9F,
        OtherError0xA0,
        OtherError0xA1,
        OtherError0xA2,
        OtherError0xA3,
        OtherError0xA4,
        OtherError0xA5,
        OtherError0xA6,
        OtherError0xA7,
        OtherError0xA8,
        OtherError0xA9,
        OtherError0xAA,
        OtherError0xAB,
        OtherError0xAC,
        OtherError0xAD,
        OtherError0xAE,
        OtherError0xAF,
        OtherError0xB0,
        OtherError0xB1,
        OtherError0xB2,
        OtherError0xB3,
        OtherError0xB4,
        OtherError0xB5,
        OtherError0xB6,
        OtherError0xB7,
        OtherError0xB8,
        OtherError0xB9,
        OtherError0xBA,
        OtherError0xBB,
        OtherError0xBC,
        OtherError0xBD,
        OtherError0xBE,
        OtherError0xBF,
        OtherError0xC0,
        OtherError0xC1,
        OtherError0xC2,
        OtherError0xC3,
        OtherError0xC4,
        OtherError0xC5,
        OtherError0xC6,
        OtherError0xC7,
        OtherError0xC8,
        OtherError0xC9,
        OtherError0xCA,
        OtherError0xCB,
        OtherError0xCC,
        OtherError0xCD,
        OtherError0xCE,
        OtherError0xCF,
        OtherError0xD0,
        OtherError0xD1,
        OtherError0xD2,
        OtherError0xD3,
        OtherError0xD4,
        OtherError0xD5,
        OtherError0xD6,
        OtherError0xD7,
        OtherError0xD8,
        OtherError0xD9,
        OtherError0xDA,
        OtherError0xDB,
        OtherError0xDC,
        OtherError0xDD,
        OtherError0xDE,
        OtherError0xDF,
        // Bridge errors: errors that only belong in inter-client communication
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        /// However, this is not a valid result in a Tally transaction, because invalid requests
        /// are never included into blocks and therefore never get a Tally in response.
        BridgeMalformedRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedResult,
        /// Unallocated
        OtherError0xE3,
        OtherError0xE4,
        OtherError0xE5,
        OtherError0xE6,
        OtherError0xE7,
        OtherError0xE8,
        OtherError0xE9,
        OtherError0xEA,
        OtherError0xEB,
        OtherError0xEC,
        OtherError0xED,
        OtherError0xEE,
        OtherError0xEF,
        OtherError0xF0,
        OtherError0xF1,
        OtherError0xF2,
        OtherError0xF3,
        OtherError0xF4,
        OtherError0xF5,
        OtherError0xF6,
        OtherError0xF7,
        OtherError0xF8,
        OtherError0xF9,
        OtherError0xFA,
        OtherError0xFB,
        OtherError0xFC,
        OtherError0xFD,
        OtherError0xFE,
        // This should not exist:
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../../interfaces/IPlatform.sol";
import "../../interfaces/IGame.sol";


library LReferral {
    uint public constant category4Points = 25;
    uint public constant category5Points = 5;
    
    enum ReferralCategories { FIRST, SECOND, THIRD, FOURTH, FIFTH }
    enum ReferralRoundStatus { EMPTY, PROCESSING, PAYING, CLOSED, REFUNDED }
    
    
    function getProcessingRoundsCount() public pure returns (uint8) {
        return 0xe;
    }
    
    function getCategoriesCount() public pure returns (uint8) {
        return 0x5;
    }
    
    function getPayLimit() public pure returns (uint16) {
        return 0x384;
    }
    
    function getCalculateUserLimit() public pure returns (uint16) {
        return 0x384;
    }
    
    function getCategoryRequirePoints(ReferralCategories refCategory) public pure returns (uint16 count) {
        return getCategoryUintRequirePoints(uint8(refCategory));
    }

    function getCategoryUintRequirePoints(uint8 refCategory) public pure returns (uint16 count) {
        if (refCategory == uint8(ReferralCategories.FIRST)) return 0x3e8;
        if (refCategory == uint8(ReferralCategories.SECOND)) return 0x1f4;
        if (refCategory == uint8(ReferralCategories.THIRD)) return 0x64;
        if (refCategory == uint8(ReferralCategories.FOURTH)) return 0x19;
        if (refCategory == uint8(ReferralCategories.FIFTH)) return 0x5;
    }

    function isExistInCategories(address user, uint points, uint upAmount) public pure returns (bool) {
        if (user == address(0)) return false;
        if (points < getCategoryRequirePoints(ReferralCategories.FIFTH) && points + upAmount > getCategoryRequirePoints(ReferralCategories.FIFTH) - 1) return true;
        return false;
    }

    function isExistInCategories(address user, uint points) public pure returns (bool) {
        if (user == address(0)) return false;
        if (points > getCategoryRequirePoints(ReferralCategories.FIFTH) - 1) return true;
        return false;
    }

    function getCategoriesCountArray() public pure returns(uint[] memory) {
        uint[] memory catCounts = new uint[](getCategoriesCount());

        catCounts[0] = getCategoryRequirePoints(ReferralCategories.FIRST);
        catCounts[1] = getCategoryRequirePoints(ReferralCategories.SECOND);
        catCounts[2] = getCategoryRequirePoints(ReferralCategories.THIRD);
        catCounts[3] = getCategoryRequirePoints(ReferralCategories.FOURTH);
        catCounts[4] = getCategoryRequirePoints(ReferralCategories.FIFTH);

        return catCounts;
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../libs/utils/LUtil.sol";


interface IRound {
    function getStatus() external view returns (LUtil.RoundStatus);
    function getRoundPoolAmount() external view returns(uint);
    function setTicket(uint8[] calldata ticket, address owner) external;
    function startProcessing(LUtil.PrizeWallet[] calldata balances, uint roundPoolAmount) external payable;
    function fulfillRandomness() external;
    function payPage(LUtil.WinnerCategory category, uint page) external;
    function suspend() external;
    function resume() external;
    function refund() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address payable);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}