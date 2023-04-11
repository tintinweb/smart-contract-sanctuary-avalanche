// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *   ___      _              _         ___ _        _   _           
 *  |   \ ___| |_ _  ___ _ _| |_ ___  / __| |_ __ _| |_(_)_ _  __ _ 
 *  | |) / -_) | ' \/ _ \ '_|  _/ -_) \__ \  _/ _` | / / | ' \/ _` |
 *  |___/\___|_|_||_\___/_|  \__\___| |___/\__\__,_|_\_\_|_||_\__, |
 *                                                            |___/ 
 */

/**
 * @title DelnorteStaking contract
 * @author botpapa.xyz
 * @notice Smart contract for staking your fractionalized assets
 */


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./modules/Models.sol";
import "./modules/Events.sol";
import "./modules/Modifiers.sol";
import "./modules/Interfaces.sol";


contract DelnorteStaking is Ownable, Pausable, ReentrancyGuard, Modifiers {
    // base contract configuration
    Models.Configuration public config;

    // propertyId to staking data mapping
    mapping(uint => Models.Staking) public staking;

    // propertyId to staking data mapping
    mapping(address => Models.Staker) public stakers;

    /**
     * CONSTRUCTOR
     */
    constructor(
        address _propertiesContractAddress, 
        address _fractionalizationContractAddress, 
        address[] memory _admins
    ) {
        config.propertiesContractAddress = _propertiesContractAddress;
        config.fractionalizationContractAddress = _fractionalizationContractAddress;

        // Setting up admins
        for (uint i = 0; i < _admins.length; i++) {
            config.admins[_admins[i]] = true;
        }
    }


    /////////////////////
    //                 //
    //   Admin panel   //
    //                 //
    /////////////////////

    /**
     * @notice Flip admin status [admin]
     */
    function flipAdminStatus(address walletAddress) external onlyOwner returns(bool) {
        config.admins[walletAddress] = !config.admins[walletAddress];
        emit Events.AdminStatusFlipped(msg.sender, walletAddress, config.admins[walletAddress]);
        return config.admins[walletAddress];
    }

    /**
     * @notice Update parent smart contracts [admin]
     */
    function adminUpdateUserDepositsNumber(address _user, uint _newDepositsNumber) 
        public
        onlyAdmin(config) {
            stakers[_user].depositsNumber = _newDepositsNumber;
            emit Events.AdminUpdatedUserDepositsNumber(msg.sender, _user, _newDepositsNumber);
    }

    /**
     * @notice Force activate/deactivate a sale [admin]
     */
    function adminStakingForceDeactivate(uint _stakingId, bool _status) 
        public
        onlyAdmin(config) {
            staking[_stakingId].forceDeactivated = _status;
            emit Events.AdminStakingForceDeactivated(msg.sender, _stakingId, _status);
    }

    /**
     * @notice Update parent smart contracts [admin]
     */
    function adminUpdateParentContractsAddresses(address _propertiesContractAddress, address _fractionalizationContractAddress) 
        public
        onlyAdmin(config) {
            config.propertiesContractAddress = _propertiesContractAddress;
            config.fractionalizationContractAddress = _fractionalizationContractAddress;
            emit Events.AdminParentContractsUpdated(msg.sender, _propertiesContractAddress, _fractionalizationContractAddress);
    }

    /**
     * @notice Update user's deposit info [admin]
     */
    function adminUpdateUserDeposit(
        address _user,
        uint _depositId,

        bool _isOpen, 
        uint _amount, 
        uint _stakingId, 
        uint _creationTime, 
        uint _lastClaimTime
    ) public onlyAdmin(config) {
        stakers[_user].deposits[_depositId] = Models.Deposit(
            {
                isOpen: _isOpen,
                amount: _amount,
                stakingId: _stakingId,
                creationTime: _creationTime,
                lastClaimTime: _lastClaimTime
            }
        );
        emit Events.AdminUpdatedUserDeposit(
            msg.sender, _user, _depositId, _isOpen, _amount, _stakingId, _creationTime, _lastClaimTime
        );
    }

    /**
     * @notice Update staking info [admin]
     */
    function adminUpdateStaking(
        uint _stakingId,

        address _dividendsAddress,
        uint _dividendSize,
        uint _dividendPeriod,
        uint _minStakingTime,
        bool _active,
        bool _forceDeactivated,
        uint _startedAt,
        address _creator
    ) public onlyAdmin(config) {
        staking[_stakingId] = Models.Staking(
            {
                dividendsAddress: _dividendsAddress,
                dividendSize: _dividendSize,
                dividendPeriod: _dividendPeriod,
                minStakingTime: _minStakingTime,
                active: _active,
                forceDeactivated: _forceDeactivated,
                startedAt: _startedAt,
                creator: _creator
            }
        );
        emit Events.AdminUpdatedStaking(
            msg.sender, _stakingId, _dividendsAddress, _dividendSize, _dividendPeriod, _minStakingTime, _active, _forceDeactivated, _startedAt, _creator
        );
    }

    /**
     * @notice Pause smart contract [admin]
     */
    function pause() public onlyAdmin(config) {
        _pause();
        emit Events.AdminPaused(msg.sender);
    }

    /**
     * @notice Unpause smart contract [admin]
     */
    function unpause() public onlyAdmin(config) {
        _unpause();
        emit Events.AdminUnpaused(msg.sender);
    }


    ////////////////////////
    //                    //
    //   Read functions   //
    //                    //
    ////////////////////////

    function isAdmin(address _user) public view returns(bool) {
        return config.admins[_user];
    }

    function getUserDepositsCount(address _user) public view returns(uint) {
        return stakers[_user].depositsNumber;
    }

    function getUserDeposit(address _user, uint _depositId) public view returns(Models.Deposit memory) {
        return stakers[_user].deposits[_depositId];
    }

    function calculateDividends(address _user, uint _depositId) 
        public 
        view 
        returns(uint dividendsAvailableToClaim, address dividendsAddress, uint unclaimedBlocks, bool claimAvailable) {
            Models.Deposit memory _deposit = stakers[_user].deposits[_depositId];
            Models.Staking memory _staking = staking[_deposit.stakingId];

            uint _blocksPassed = block.number - _deposit.lastClaimTime;
            uint _periodsPassed = _blocksPassed / _staking.dividendPeriod;

            uint _dividendsAvailableToClaim = _periodsPassed * _staking.dividendSize;
            uint _unclaimedBlocks = _deposit.lastClaimTime - (_periodsPassed * _staking.dividendPeriod);

            address _dividendsAddress = _staking.dividendsAddress;
            bool _claimAvailable = _blocksPassed >= _staking.minStakingTime;
            if (!_staking.active || !_deposit.isOpen) {
                _claimAvailable = false;
            }

            return (_dividendsAvailableToClaim, _dividendsAddress, _unclaimedBlocks, _claimAvailable);
    }

    /**
     * @dev Getting address of the ERC-20 fractions belonging to the propery
     */
    function getStakingTokenAddress(uint _stakingId) internal view returns(address) {
        return IFractionalizerContract(config.fractionalizationContractAddress).getFractionsContractAddress(_stakingId);
    }


    /////////////////
    //             //
    //   Staking   //
    //             //
    /////////////////

    /**
     * @notice Stake your assets
     * @dev This function creates a new deposit for the given assets
     */
    function stake(uint _stakingId, uint _amount) 
        public 
        nonReentrant 
        whenNotPaused
        onlyActiveStaking(staking[_stakingId]) 
        returns(uint) {
            // Transferring fractions to this smart contract 
            address _fractionsContractAddress = getStakingTokenAddress(_stakingId);
            bool receiveSucess = getERC20(_fractionsContractAddress, msg.sender, _amount);
            require(receiveSucess, "Payment unsuccessful.");

            uint _newDepositId = stakers[msg.sender].depositsNumber;
            stakers[msg.sender].deposits[_newDepositId] = Models.Deposit(
                {
                    isOpen: true,
                    amount: _amount,
                    stakingId: _stakingId,
                    creationTime: block.number,
                    lastClaimTime: block.number
                }
            );
            stakers[msg.sender].depositsNumber += 1;

            emit Events.AssetsStaked(msg.sender, _stakingId, _newDepositId, _amount);
            return _newDepositId;
    }

    /**
     * @notice Unstake your assets
     * @dev This function returns assets back (if minStakingTime has passed) and closes the deposit
     */
    function unstake(uint _depositId) 
        public 
        nonReentrant 
        whenNotPaused 
        onlyActiveStaking(staking[stakers[msg.sender].deposits[_depositId].stakingId]) 
        returns(uint claimedDividends) {
            Models.Deposit memory _deposit = stakers[msg.sender].deposits[_depositId];
            Models.Staking memory _staking = staking[_deposit.stakingId];

            require(_deposit.isOpen, "The deposit you want to unstake is closed or does not exist.");
            require(_deposit.creationTime + _staking.minStakingTime <= block.number, "You cannot unstake this deposit due to the minimal staking time has not passed yet.");

            // Claiming dividends
            uint _claimedDividends = claimDividends(_depositId);

            // Resetting deposit
            Models.Deposit memory _resetDeposit;
            stakers[msg.sender].deposits[_depositId] = _resetDeposit;

            // Sending user's staked tokens back
            address _fractionsTokensAddress = getStakingTokenAddress(_deposit.stakingId);
            bool _transferSuccess = internalSendERC20(
                _fractionsTokensAddress,
                msg.sender,
                _deposit.amount
            );
            require(_transferSuccess, "Unstaking was unsuccessful.");

            emit Events.AssetsUnstaked(msg.sender, _deposit.stakingId, _depositId, _claimedDividends);
            return _claimedDividends;
    }

    /**
     * @notice Claim dividends
     * @dev Period for which dividents weren't paid is added back to the storage
     */
    function claimDividends(uint _depositId) 
        public 
        nonReentrant 
        whenNotPaused 
        onlyActiveStaking(staking[stakers[msg.sender].deposits[_depositId].stakingId]) 
        returns(uint claimedDividends) {
            (
                uint _dividendsAvailableToClaim, 
                address _dividendsAddress,
                uint _unclaimedBlocks, 
                bool _claimAvailable
            ) = calculateDividends(msg.sender, _depositId);
            require(_claimAvailable, "Minimal staking period hasn't passed yet.");

            // Sending dividends
            bool _transferSuccess = internalSendERC20(
                _dividendsAddress,
                msg.sender,
                _dividendsAvailableToClaim
            );
            require(_transferSuccess, "Transfer was unsuccessful.");

            // Saving unclaimed blocks to the storage
            stakers[msg.sender].deposits[_depositId].lastClaimTime = block.number - _unclaimedBlocks;

            emit Events.DividendsClaimed(msg.sender, _depositId, _dividendsAvailableToClaim);
            return _dividendsAvailableToClaim;
    }


    /////////////////////////////
    //                         //
    //   Staking admin panel   //
    //                         //
    /////////////////////////////

    /**
     * @notice Create a new staking
     * @dev Only the wallet that fractionalized property NFT is able to create a new staking for it
     * 
     * @param _propertyId -- id of the property whos fractions can be staked
     * @param _dividendsAddress -- address of the ERC-20 token that will be used to pay dividends
     * @param _dividendPeriod -- period in blocks that is used to pay dividends
     * @param _dividendSize -- amount of dividends paid every _dividendPeriod
     * @param _minStakingTime -- period in blocks after which the assets can be unstaked
     */
    function createStaking(uint _propertyId, address _dividendsAddress, uint _dividendPeriod, uint _dividendSize, uint _minStakingTime) 
        public 
        nonReentrant 
        onlyStakingPropertyOwner(config, _propertyId) 
        returns(uint256) {

        require(getStakingTokenAddress(_propertyId) != address(0), "Please, fractionalize your property first.");
        require(staking[_propertyId].creator == address(0), "Staking for this property was already created.");

        staking[_propertyId] = Models.Staking(
            {
                dividendsAddress: _dividendsAddress,
                dividendSize: _dividendSize,
                dividendPeriod: _dividendPeriod,
                minStakingTime: _minStakingTime,
                creator: msg.sender,
                active: false,
                forceDeactivated: false,
                startedAt: 0
            }
        );

        emit Events.StakingCreated(msg.sender, _propertyId);
        return _propertyId;
    }

    /**
     * @notice Change staking status
     * @dev Setting staking status to given bool; callable from staking creator or admin
     */
    function changeStakingStatus(uint _stakingId, bool _newStatus) 
        public 
        nonReentrant 
        onlyStakingPropertyOwner(config, _stakingId) 
        returns(bool) { 
            require(staking[_stakingId].creator == msg.sender, "You are not the creator of this staking.");

            if (_newStatus == true && staking[_stakingId].startedAt == 0) {
                staking[_stakingId].startedAt = block.number;
            }
            staking[_stakingId].active = _newStatus;

            emit Events.StakingStatusChanged(msg.sender, _newStatus);
            return staking[_stakingId].active;
    }


    /////////////////////////////////////////
    //                                     //
    //   Withdrawals and token transfers   //
    //                                     //
    /////////////////////////////////////////
    
    /**
     * @notice Withdraw all ether
     * @dev Function allows withdrawing ETH from the smart contract [for the owner only]
     */
    function withdrawAll() external onlyAdmin(config) {
        uint amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit Events.WithdrawExecuted(msg.sender, amount);
    }

    /**
     * @notice Withdraw ERC-20 token
     * @dev Function allows withdrawing ERC-20 from the smart contract [for the owner only]
     */
    function sendERC20(address token, address walletAddress, uint amount) public onlyAdmin(config) nonReentrant {
        bool sent = internalSendERC20(token, walletAddress, amount);
        require(sent, "Failed to send ERC20");
        emit Events.ERC20Sent(walletAddress, token, amount);
    }

    /**
     * @dev Function allows taking payments in custom ERC-20 tokens from this smart contract [internal]
     */
    function getERC20(address token, address walletAddress, uint amount) internal returns(bool) {
        bool sent = ERC20Contract(token).transferFrom(walletAddress, address(this), amount);
        emit Events.ERC20Received(walletAddress, token, amount, sent);
        return sent;
    }

    /**
     * @dev Function allows sending ERC-20 tokens to the diven address [internal]
     */
    function internalSendERC20(address token, address walletAddress, uint amount) internal returns(bool) {
        bool increased = ERC20Contract(token).increaseAllowance(address(this), amount);
        require(increased, "Failed to increase ERC20 allowance");

        bool sent = ERC20Contract(token).transferFrom(address(this), walletAddress, amount);
        emit Events.ERC20Sent(walletAddress, token, amount);
        return sent;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Models.sol";
import "./Interfaces.sol";


abstract contract Modifiers {

    modifier onlyStakingPropertyOwner(Models.Configuration storage _config, uint _stakingId) {
        address _tokenOwner = IPropertiesContract(_config.propertiesContractAddress).getTokenMinter(_stakingId);
        require(_tokenOwner == msg.sender, "You cannot create staking for this token as you haven't minted it.");
        _;
    }

    modifier onlyActiveStaking(Models.Staking storage _staking) {
        require(_staking.active && !_staking.forceDeactivated, "You cannot perform this action as given staking is not active or does not exist.");
        _;
    }

    modifier onlyAdmin(Models.Configuration storage _config) {
        require(_config.admins[msg.sender], "You're not an admin.");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Models {

    struct Staking {
        // ERC-20 tokens address, dividend size per token & dividend period
        address dividendsAddress;
        uint dividendSize;
        uint dividendPeriod;
        uint minStakingTime;

        // Staking switch
        bool active;

        // Staking admin switch
        bool forceDeactivated;

        // When staking was open
        uint startedAt;
        
        // Staking creator (same as the wallet that fractionalized the property)
        address creator;
    }

    struct Deposit {
        bool isOpen;

        uint amount;
        uint stakingId;
        uint creationTime;
        uint lastClaimTime;
    }

    struct Staker {
        // List of deposits owned by a wallet
        uint depositsNumber;

        // Mapping of depositId => Deposit
        mapping(uint => Deposit) deposits;
    }

    struct Configuration {
        // Parent smart contracts' addresses
        address propertiesContractAddress;
        address fractionalizationContractAddress;

        // Smart contract admins
        mapping(address => bool) admins;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC721Contract {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external returns (address);
    function ownerOf(uint256 tokenId) external returns (address);
}

interface ERC20Contract {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint addedValue) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

interface IPropertiesContract {
    function getTokenMinter(uint _tokenId) external view returns (address);
}

interface IFractionalizerContract {
    function getSaleStatus(uint propertyTokenId) external view returns (bool);
    function getFractionsContractAddress(uint propertyTokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library Events {
    event WithdrawExecuted(address walletAddress, uint amount);
    event ERC20Sent(address walletAddress, address token, uint amount);
    event ERC20Received(address walletAddress, address token, uint amount, bool success);

    event AssetsStaked(address _staker, uint _stakingId, uint _depositId, uint _amount);
    event AssetsUnstaked(address _staker, uint _stakingId, uint _depositId, uint _claimedDividends);
    event DividendsClaimed(address _staker, uint _depositId, uint _claimedDividends);
    event StakingCreated(address _creator, uint _propertyId);
    event StakingStatusChanged(address _by, bool _newStatus);

    event AdminPaused(address _admin);
    event AdminUnpaused(address _admin);
    event AdminStatusFlipped(address _admin, address _walletAddress, bool _newStatus);
    event AdminStakingForceDeactivated(address _admin, uint _stakingId, bool _status);
    event AdminUpdatedUserDepositsNumber(address _admin, address _walletAddress, uint _newDepositsNumber);
    event AdminParentContractsUpdated(
        address _admin, 
        address _propertiesContractAddress, 
        address _fractionalizationContractAddress
    );
    event AdminUpdatedUserDeposit(
        address _admin,
        address _user,
        uint _depositId,
        bool _isOpen, 
        uint _amount, 
        uint _stakingId, 
        uint _creationTime, 
        uint _lastClaimTime
    );
    event AdminUpdatedStaking(
        address _admin,
        uint _stakingId,
        address _dividendsAddress,
        uint _dividendSize,
        uint _dividendPeriod,
        uint _minStakingTime,
        bool _active,
        bool _forceDeactivated,
        uint _startedAt,
        address _creator
    );
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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