// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './VeERC20Upgradeable.sol';
import './Whitelist.sol';
import './interfaces/IMasterPlatypus.sol';
import './libraries/Math.sol';
import './libraries/SafeOwnableUpgradeable.sol';
import './interfaces/IVePtpV3.sol';
import './interfaces/IPlatypusNFT.sol';

interface IVe {
    function vote(address _user, int256 _voteDelta) external;
}

/// @title VePtpV3
/// @notice Platypus Venom: the staking contract for PTP, as well as the token used for governance.
/// Note Venom does not seem to hurt the Platypus, it only makes it stronger.
/// Allows depositing/withdraw of ptp and staking/unstaking ERC721.
/// Here are the rules of the game:
/// If you stake ptp, you generate vePtp at the current `generationRate` until you reach `maxStakeCap`
/// If you unstake any amount of ptp, you loose all of your vePtp.
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Platypus is sufficiently
/// distributed and the community can show to govern itself.
/// VePtpV3 updates
/// - User can lock PTP and instantly mint vePTP.
/// - API change:
///   - maxCap => maxStakeCap
///   - isUser => isUserStaking
contract VePtpV3 is
    Initializable,
    SafeOwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    VeERC20Upgradeable,
    IVePtpV3,
    IVe
{
    // Staking user info
    struct UserInfo {
        uint256 amount; // ptp staked by user
        uint256 lastRelease; // time of last vePtp claim or first deposit if user has not claimed yet
        // the id of the currently staked nft
        // important note: the id is offset by +1 to handle tokenID = 0
        // stakedNftId = 0 (default value) means that no NFT is staked
        uint256 stakedNftId;
    }

    // Locking user info
    struct LockedPosition {
        uint128 initialLockTime;
        uint128 unlockTime;
        uint128 ptpLocked;
        uint128 vePtpAmount;
    }

    /// @notice the ptp token
    IERC20 public ptp;

    /// @notice the masterPlatypus contract
    IMasterPlatypus public masterPlatypus;

    /// @notice the NFT contract
    IPlatypusNFT public nft;

    /// @notice max vePtp to staked ptp ratio
    /// Note if user has 10 ptp staked, they can only have a max of 10 * maxStakeCap vePtp in balance
    uint256 public maxStakeCap;

    /// @notice the rate of vePtp generated per second, per ptp staked
    uint256 public generationRate;

    /// @notice invVvoteThreshold threshold.
    /// @notice voteThreshold is the tercentage of cap from which votes starts to count for governance proposals.
    /// @dev inverse of the threshold to apply.
    /// Example: th = 5% => (1/5) * 100 => invVoteThreshold = 20
    /// Example 2: th = 3.03% => (1/3.03) * 100 => invVoteThreshold = 33
    /// Formula is invVoteThreshold = (1 / th) * 100
    uint256 public invVoteThreshold;

    /// @notice whitelist wallet checker
    /// @dev contract addresses are by default unable to stake ptp, they must be previously whitelisted to stake ptp
    Whitelist public whitelist;

    /// @notice user info mapping
    // note Staking user info
    mapping(address => UserInfo) public users;

    uint256 public maxNftLevel;
    uint256 public xpEnableTime;

    // reserve more space for extensibility
    uint256[100] public xpRequiredForLevelUp;

    address public voter;

    /// @notice amount of vote used currently for each user
    mapping(address => uint256) public usedVote;
    /// @notice store the last block when a contract stake NFT
    mapping(address => uint256) internal lastBlockToStakeNftByContract;

    // Note used to prevent storage collision
    uint256[2] private __gap;

    /// @notice min and max lock days
    uint128 public minLockDays;
    uint128 public maxLockDays;

    /// @notice the max cap for locked positions
    uint256 public maxLockCap;

    /// @notice Locked PTP user info
    mapping(address => LockedPosition) public lockedPositions;

    /// @notice total amount of ptp locked
    uint256 public totalLockedPtp;

    /// @notice events describing staking, unstaking and claiming
    event Staked(address indexed user, uint256 indexed amount);
    event Unstaked(address indexed user, uint256 indexed amount);
    event Claimed(address indexed user, uint256 indexed amount);

    /// @notice events describing NFT staking and unstaking
    event StakedNft(address indexed user, uint256 indexed nftId);
    event UnstakedNft(address indexed user, uint256 indexed nftId);

    /// @notice events describing locking mechanics
    event Lock(address indexed user, uint256 unlockTime, uint256 amount, uint256 vePtpToMint);
    event ExtendLock(address indexed user, uint256 daysToExtend, uint256 unlockTime, uint256 vePtpToMint);
    event AddToLock(address indexed user, uint256 amountAdded, uint256 vePtpToMint);
    event Unlock(address indexed user, uint256 unlockTime, uint256 amount, uint256 vePtpToBurn);

    function initialize(
        IERC20 _ptp,
        IMasterPlatypus _masterPlatypus,
        IPlatypusNFT _nft
    ) public initializer {
        require(address(_masterPlatypus) != address(0), 'zero address');
        require(address(_ptp) != address(0), 'zero address');
        require(address(_nft) != address(0), 'zero address');

        // Initialize vePTP
        __ERC20_init('Platypus Venom', 'vePTP');
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        // set generationRate (vePtp per sec per ptp staked)
        generationRate = 3888888888888;

        // set maxStakeCap
        maxStakeCap = 100;

        // set inv vote threshold
        // invVoteThreshold = 20 => th = 5
        invVoteThreshold = 20;

        // set master platypus
        masterPlatypus = _masterPlatypus;

        // set ptp
        ptp = _ptp;

        // set nft, can be zero address at first
        nft = _nft;

        initializeNft();
        initializeLockDays();
    }

    function _verifyVoteIsEnough(address _user) internal view {
        require(balanceOf(_user) >= usedVote[_user], 'VePtp: not enough vote');
    }

    function _onlyVoter() internal view {
        require(msg.sender == voter, 'VePtp: caller is not voter');
    }

    function initializeNft() public onlyOwner {
        maxNftLevel = 1; // to enable leveling, call setMaxNftLevel
        xpRequiredForLevelUp = [uint256(0), 3000 ether, 30000 ether, 300000 ether, 3000000 ether];
    }

    function initializeLockDays() public onlyOwner {
        minLockDays = 7; // 1 week
        maxLockDays = 357; // 357/(365/12) ~ 11.7 months
        maxLockCap = 120; // < 12 month max lock

        // ~18 month max stake, can set separately
        // maxStakeCap = 180;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice set min and max lock days
    function setLockDaysAndCap(
        uint256 _minLockDays,
        uint256 _maxLockDays,
        uint256 _maxLockCap
    ) external onlyOwner {
        require(_minLockDays < _maxLockDays && _maxLockDays < type(uint128).max, 'lock days are invalid');
        minLockDays = uint128(_minLockDays);
        maxLockDays = uint128(_maxLockDays);
        maxLockCap = _maxLockCap;
    }

    /// @notice sets masterPlatpus address
    /// @param _masterPlatypus the new masterPlatypus address
    function setMasterPlatypus(IMasterPlatypus _masterPlatypus) external onlyOwner {
        require(address(_masterPlatypus) != address(0), 'zero address');
        masterPlatypus = _masterPlatypus;
    }

    /// @notice sets NFT contract address
    /// @param _nft the new NFT contract address
    function setNftAddress(IPlatypusNFT _nft) external onlyOwner {
        require(address(_nft) != address(0), 'zero address');
        nft = _nft;
    }

    /// @notice sets voter contract address
    /// @param _voter the new NFT contract address
    function setVoter(address _voter) external onlyOwner {
        require(address(_voter) != address(0), 'zero address');
        voter = _voter;
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(Whitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), 'zero address');
        whitelist = _whitelist;
    }

    /// @notice sets maxStakeCap
    /// @param _maxStakeCap the new max ratio
    function setMaxStakeCap(uint256 _maxStakeCap) external onlyOwner {
        require(_maxStakeCap != 0, 'max cap cannot be zero');
        maxStakeCap = _maxStakeCap;
    }

    /// @notice sets generation rate
    /// @param _generationRate the new max ratio
    function setGenerationRate(uint256 _generationRate) external onlyOwner {
        require(_generationRate != 0, 'generation rate cannot be zero');
        generationRate = _generationRate;
    }

    /// @notice sets invVoteThreshold
    /// @param _invVoteThreshold the new var
    /// Formula is invVoteThreshold = (1 / th) * 100
    function setInvVoteThreshold(uint256 _invVoteThreshold) external onlyOwner {
        require(_invVoteThreshold != 0, 'invVoteThreshold cannot be zero');
        invVoteThreshold = _invVoteThreshold;
    }

    /// @notice sets setMaxNftLevel, the first time this function is called, leveling will be enabled
    /// @param _maxNftLevel the new var
    function setMaxNftLevel(uint8 _maxNftLevel) external onlyOwner {
        maxNftLevel = _maxNftLevel;

        if (xpEnableTime == 0) {
            // enable users to accumulate timestamp the first time this function is invoked
            xpEnableTime = block.timestamp;
        }
    }

    /// @notice checks wether user _addr has ptp staked
    /// @param _addr the user address to check
    /// @return true if the user has ptp in stake, false otherwise
    function isUserStaking(address _addr) public view override returns (bool) {
        return users[_addr].amount > 0;
    }

    /// @notice [Deprecated] return the result of `isUserStaking()` for backward compatibility
    function isUser(address _addr) external view returns (bool) {
        return isUserStaking(_addr);
    }

    /// @notice [Deprecated] return the `maxStakeCap` for backward compatibility
    function maxCap() external view returns (uint256) {
        return maxStakeCap;
    }

    /// @notice returns staked amount of ptp for user
    /// @param _addr the user address to check
    /// @return staked amount of ptp
    function getStakedPtp(address _addr) external view override returns (uint256) {
        return users[_addr].amount;
    }

    /// @dev explicity override multiple inheritance
    function totalSupply() public view override(VeERC20Upgradeable, IVeERC20) returns (uint256) {
        return super.totalSupply();
    }

    /// @dev explicity override multiple inheritance
    function balanceOf(address account) public view override(VeERC20Upgradeable, IVeERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    /// @notice returns expected vePTP amount to be minted given amount and number of days to lock
    function _expectedVePtpAmount(uint256 _amount, uint256 _lockSeconds) private view returns (uint256) {
        return Math.wmul(_amount, _lockSeconds * generationRate);
    }

    function quoteExpectedVePtpAmount(uint256 _amount, uint256 _lockDays) external view returns (uint256) {
        return _expectedVePtpAmount(_amount, _lockDays * 1 days);
    }

    /// @notice locks PTP in the contract, immediately minting vePTP
    /// @param _amount amount of PTP to lock
    /// @param _lockDays number of days to lock the _amount of PTP for
    /// @return vePtpToMint the amount of vePTP minted by the lock
    function lockPtp(uint256 _amount, uint256 _lockDays)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 vePtpToMint)
    {
        require(_amount > 0, 'amount to lock cannot be zero');
        require(lockedPositions[msg.sender].ptpLocked == 0, 'user already has a lock, call addPtpToLock');

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        // validate lock days
        require(_lockDays >= uint256(minLockDays) && _lockDays <= uint256(maxLockDays), 'lock days is invalid');

        // calculate vePTP to mint and unlock time
        vePtpToMint = _expectedVePtpAmount(_amount, _lockDays * 1 days);
        uint256 unlockTime = block.timestamp + 1 days * _lockDays;

        // validate that cap is respected
        require(vePtpToMint <= _amount * maxLockCap, 'lock cap is not respected');

        // check type safety
        require(unlockTime < type(uint128).max, 'overflow');
        require(_amount < type(uint128).max, 'overflow');
        require(vePtpToMint < type(uint128).max, 'overflow');

        // Request Ptp from user
        ptp.transferFrom(msg.sender, address(this), _amount);

        lockedPositions[msg.sender] = LockedPosition(
            uint128(block.timestamp),
            uint128(unlockTime),
            uint128(_amount),
            uint128(vePtpToMint)
        );

        totalLockedPtp += _amount;

        _mint(msg.sender, vePtpToMint);

        emit Lock(msg.sender, unlockTime, _amount, vePtpToMint);

        return vePtpToMint;
    }

    /// @notice adds Ptp to current lock
    /// @param _amount the amount of ptp to add to lock
    /// @return vePtpToMint the amount of vePTP generated by adding to the lock
    function addPtpToLock(uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 vePtpToMint) {
        require(_amount > 0, 'amount to add to lock cannot be zero');
        LockedPosition memory position = lockedPositions[msg.sender];
        require(position.ptpLocked > 0, 'user doesnt have a lock, call lockPtp');

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        require(position.unlockTime > block.timestamp, 'cannot add to a finished lock, please extend lock');

        // timeLeftInLock > 0
        uint256 timeLeftInLock = position.unlockTime - block.timestamp;

        vePtpToMint = _expectedVePtpAmount(_amount, timeLeftInLock);

        // validate that cap is respected
        require(
            vePtpToMint + position.vePtpAmount <= (_amount + position.ptpLocked) * maxLockCap,
            'lock cap is not respected'
        );

        // check type safety
        require(_amount + position.ptpLocked < type(uint128).max, 'overflow');
        require(position.vePtpAmount + vePtpToMint < type(uint128).max, 'overflow');

        // Request Ptp from user
        ptp.transferFrom(msg.sender, address(this), _amount);

        lockedPositions[msg.sender].ptpLocked += uint128(_amount);
        lockedPositions[msg.sender].vePtpAmount += uint128(vePtpToMint);

        totalLockedPtp += _amount;

        _mint(msg.sender, vePtpToMint);
        emit AddToLock(msg.sender, _amount, vePtpToMint);

        return vePtpToMint;
    }

    /// @notice Extends curent lock by days. The total amount of vePTP generated is caculated based on the period
    /// between `initialLockTime` and the new `unlockPeriod`
    /// @dev the lock extends the duration taking into account `unlockTime` as reference. If current position is already unlockable, it will extend the position taking into consideration the registered unlock time, and not the block's timestamp.
    /// @param _daysToExtend amount of additional days to lock the position
    /// @return vePtpToMint amount of vePTP generated by extension
    function extendLock(uint256 _daysToExtend)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 vePtpToMint)
    {
        require(_daysToExtend >= uint256(minLockDays), 'extend: days are invalid');

        LockedPosition memory position = lockedPositions[msg.sender];

        require(position.ptpLocked > 0, 'extend: no ptp locked');

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        uint256 newUnlockTime = position.unlockTime + _daysToExtend * 1 days;
        require(newUnlockTime - position.initialLockTime <= uint256(maxLockDays * 1 days), 'extend: too much days');

        // calculate amount of vePTP to mint for the extended days
        // distributive property of `_expectedVePtpAmount` is assumed
        vePtpToMint = _expectedVePtpAmount(position.ptpLocked, _daysToExtend * 1 days);

        uint256 _maxCap = maxLockCap;
        // max user vePtp balance in case the extension was about to exceed lock
        if (vePtpToMint + position.vePtpAmount > position.ptpLocked * _maxCap) {
            // mint enough to max the position
            vePtpToMint = position.ptpLocked * _maxCap - position.vePtpAmount;
        }

        // validate type safety
        require(newUnlockTime < type(uint128).max, 'overflow');
        require(vePtpToMint + position.vePtpAmount < type(uint128).max, 'overflow');

        // assign new unlock time and vePTP amount
        lockedPositions[msg.sender].unlockTime = uint128(newUnlockTime);
        lockedPositions[msg.sender].vePtpAmount = position.vePtpAmount + uint128(vePtpToMint);

        _mint(msg.sender, vePtpToMint);

        emit ExtendLock(msg.sender, _daysToExtend, newUnlockTime, vePtpToMint);

        return vePtpToMint;
    }

    /// @notice unlocks all PTP for a user
    //// Lock needs to expire before unlock
    /// @return the amount of PTP recovered by the unlock
    function unlockPtp() external override nonReentrant whenNotPaused returns (uint256) {
        LockedPosition memory position = lockedPositions[msg.sender];
        require(position.ptpLocked > 0, 'no ptp locked');
        require(position.unlockTime <= block.timestamp, 'not yet');
        uint256 ptpToUnlock = position.ptpLocked;
        uint256 vePtpToBurn = position.vePtpAmount;

        // delete the lock position from mapping
        delete lockedPositions[msg.sender];

        totalLockedPtp -= ptpToUnlock;

        // burn corresponding vePTP
        _burn(msg.sender, vePtpToBurn);

        // transfer the ptp to the user
        ptp.transfer(msg.sender, ptpToUnlock);

        emit Unlock(msg.sender, position.unlockTime, ptpToUnlock, vePtpToBurn);

        return ptpToUnlock;
    }

    /// @notice deposits PTP into contract
    /// @param _amount the amount of ptp to deposit
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, 'amount to deposit cannot be zero');

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        if (isUserStaking(msg.sender)) {
            // if user exists, first, claim his vePTP
            _claim(msg.sender);
            // then, increment his holdings
            users[msg.sender].amount += _amount;
        } else {
            // add new user to mapping
            users[msg.sender].lastRelease = block.timestamp;
            users[msg.sender].amount = _amount;
        }

        // Request Ptp from user
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transferFrom(msg.sender, address(this), _amount);

        // emit event
        emit Staked(msg.sender, _amount);
    }

    /// @notice asserts addres in param is not a smart contract.
    /// @notice if it is a smart contract, check that it is whitelisted
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(
                address(whitelist) != address(0) && whitelist.check(_addr),
                'Smart contract depositors not allowed'
            );
        }
    }

    /// @notice claims accumulated vePTP
    function claim() external override nonReentrant whenNotPaused {
        require(isUserStaking(msg.sender), 'user has no stake');
        _claim(msg.sender);
    }

    /// @dev private claim function
    /// @param _addr the address of the user to claim from
    function _claim(address _addr) private {
        uint256 amount;
        uint256 xp;
        (amount, xp) = _claimable(_addr);

        UserInfo storage user = users[_addr];

        // update last release time
        user.lastRelease = block.timestamp;

        if (amount > 0) {
            emit Claimed(_addr, amount);
            _mint(_addr, amount);
        }

        if (xp > 0) {
            uint256 nftId = user.stakedNftId;

            // if nftId > 0, user has nft staked
            if (nftId > 0) {
                --nftId; // remove offset

                // level is already validated in _claimable()
                nft.growXp(nftId, xp);
            }
        }
    }

    /// @notice returns amount of vePTP that has been generated by staking (including those from NFT)
    /// @param _addr the address to check
    function vePtpGeneratedByStake(address _addr) public view returns (uint256) {
        return balanceOf(_addr) - lockedPositions[_addr].vePtpAmount;
    }

    /// @notice returns amount of vePTP that has been generated by staking
    /// @param _addr the address to check
    function vePtpGeneratedByLock(address _addr) public view returns (uint256) {
        return lockedPositions[_addr].vePtpAmount;
    }

    /// @notice Calculate the amount of vePTP that can be claimed by user
    /// @param _addr the address to check
    /// @return amount of vePTP that can be claimed by user
    function claimable(address _addr) external view returns (uint256 amount) {
        require(_addr != address(0), 'zero address');
        (amount, ) = _claimable(_addr);
    }

    /// @notice Calculate the amount of vePTP that can be claimed by user
    /// @param _addr the address to check
    /// @return amount of vePTP that can be claimed by user
    /// @return xp potential xp for NFT staked
    function claimableWithXp(address _addr) external view returns (uint256 amount, uint256 xp) {
        require(_addr != address(0), 'zero address');
        return _claimable(_addr);
    }

    /// @notice Calculate the amount of vePTP that can be claimed by user
    /// @dev private claimable function
    /// @param _addr the address to check
    /// @return amount of vePTP that can be claimed by user
    /// @return xp potential xp for NFT staked
    function _claimable(address _addr) private view returns (uint256 amount, uint256 xp) {
        UserInfo storage user = users[_addr];

        // get seconds elapsed since last claim
        uint256 secondsElapsed = block.timestamp - user.lastRelease;

        // calculate pending amount
        // Math.mwmul used to multiply wad numbers
        uint256 pending = Math.wmul(user.amount, secondsElapsed * generationRate);

        // get user's vePTP balance
        uint256 userVePtpBalance = vePtpGeneratedByStake(_addr);

        // user vePTP balance cannot go above user.amount * maxStakeCap
        uint256 maxVePtpCap = user.amount * maxStakeCap;

        // handle nft effects
        uint256 nftId = user.stakedNftId;
        // if nftId > 0, user has nft staked
        if (nftId > 0) {
            --nftId; // remove offset
            uint32 speedo;
            uint32 pudgy;
            uint32 diligent;
            uint32 gifted;
            (speedo, pudgy, diligent, gifted, ) = nft.getPlatypusDetails(nftId);

            if (speedo > 0) {
                // Speedo: x% faster vePTP generation
                pending = (pending * (100 + speedo)) / 100;
            }
            if (diligent > 0) {
                // Diligent: +D vePTP every hour (subject to cap)
                pending += ((uint256(diligent) * (10**decimals())) * secondsElapsed) / 1 hours;
            }
            if (pudgy > 0) {
                // Pudgy: x% higher vePTP cap
                maxVePtpCap = (maxVePtpCap * (100 + pudgy)) / 100;
            }
            if (gifted > 0) {
                // Gifted: +D vePTP regardless of PTP staked
                // The cap should also increase D
                maxVePtpCap += uint256(gifted) * (10**decimals());
            }

            uint256 level = nft.getPlatypusLevel(nftId);
            if (level < maxNftLevel) {
                // Accumulate XP only after leveling is enabled
                if (user.lastRelease >= xpEnableTime) {
                    xp = pending;
                } else {
                    xp = (pending * (block.timestamp - xpEnableTime)) / (block.timestamp - user.lastRelease);
                }
                uint256 currentXp = nft.getPlatypusXp(nftId);

                if (xp + currentXp > xpRequiredForLevelUp[level]) {
                    xp = xpRequiredForLevelUp[level] - currentXp;
                }
            }
        }

        // first, check that user hasn't reached the max limit yet
        if (userVePtpBalance < maxVePtpCap) {
            // amount of vePTP to reach max cap
            uint256 amountToCap = maxVePtpCap - userVePtpBalance;

            // then, check if pending amount will make user balance overpass maximum amount
            if (pending >= amountToCap) {
                amount = amountToCap;
            } else {
                amount = pending;
            }
        } else {
            amount = 0;
        }
        // Note: maxVePtpCap doesn't affect growing XP
    }

    /// @notice withdraws staked ptp
    /// @param _amount the amount of ptp to unstake
    /// Note Beware! you will loose all of your vePTP minted from staking if you unstake any amount of ptp!
    /// Besides, if you withdraw all PTP and you have staked NFT, it will be unstaked
    function withdraw(uint256 _amount) external override nonReentrant whenNotPaused {
        require(_amount > 0, 'amount to withdraw cannot be zero');
        require(users[msg.sender].amount >= _amount, 'not enough balance');

        uint256 nftId = users[msg.sender].stakedNftId;
        if (nftId > 0) {
            // claim to grow XP
            _claim(msg.sender);
        } else {
            users[msg.sender].lastRelease = block.timestamp;
        }

        // get user vePTP balance that must be burned before updating his balance
        uint256 valueToBurn = _vePtpBurnedOnWithdraw(msg.sender, _amount);

        // update his balance before burning or sending back ptp
        users[msg.sender].amount -= _amount;

        _burn(msg.sender, valueToBurn);

        // unstake NFT if all PTP is unstaked
        if (users[msg.sender].amount == 0 && users[msg.sender].stakedNftId != 0) {
            _unstakeNft(msg.sender);
        }

        // send back the staked ptp
        // SafeERC20 is not needed as PTP will revert if transfer fails
        ptp.transfer(msg.sender, _amount);

        // emit event
        emit Unstaked(msg.sender, _amount);
    }

    /// Calculate the amount of vePTP that will be burned when PTP is withdrawn
    /// @param _amount the amount of ptp to unstake
    /// @return the amount of vePTP that will be burned
    function vePtpBurnedOnWithdraw(address _addr, uint256 _amount) external view returns (uint256) {
        return _vePtpBurnedOnWithdraw(_addr, _amount);
    }

    /// Private function to calculate the amount of vePTP that will be burned when PTP is withdrawn
    /// Does NOT burn amount generated by locking upon withdrawal of staked PTP.
    /// @param _amount the amount of ptp to unstake
    /// @return the amount of vePTP that will be burned
    function _vePtpBurnedOnWithdraw(address _addr, uint256 _amount) private view returns (uint256) {
        require(_amount <= users[_addr].amount, 'not enough ptp');
        uint256 vePtpBalance = vePtpGeneratedByStake(_addr);
        uint256 nftId = users[_addr].stakedNftId;

        if (nftId == 0) {
            // user doesn't have nft staked
            return vePtpBalance;
        } else {
            --nftId; // remove offset
            (, , , uint32 gifted, uint32 hibernate) = nft.getPlatypusDetails(nftId);

            if (gifted > 0) {
                // Gifted: don't burn vePtp given by Gifted
                vePtpBalance -= uint256(gifted) * (10**decimals());
            }

            // retain some vePTP using nft
            // if it is a smart contract, check lastBlockToStakeNftByContract is not the current block
            // in case of flash loan attack
            if (
                hibernate > 0 && (msg.sender == tx.origin || lastBlockToStakeNftByContract[msg.sender] != block.number)
            ) {
                // Hibernate: Retain x% vePTP of cap upon unstaking
                return
                    vePtpBalance -
                    (vePtpBalance * hibernate * (users[_addr].amount - _amount)) /
                    users[_addr].amount /
                    100;
            } else {
                return vePtpBalance;
            }
        }
    }

    /// @notice hook called after token operation mint/burn
    /// @dev updates masterPlatypus
    /// @param _account the account being affected
    /// @param _newBalance the newVePtpBalance of the user
    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        _verifyVoteIsEnough(_account);
        masterPlatypus.updateFactor(_account, _newBalance);
    }

    /// @notice This function is called when users stake NFTs
    function stakeNft(uint256 _tokenId) external override nonReentrant whenNotPaused {
        require(isUserStaking(msg.sender), 'user has no stake');

        nft.transferFrom(msg.sender, address(this), _tokenId);

        // first, claim his vePTP
        _claim(msg.sender);

        // user has previously staked some NFT, try to unstake it
        if (users[msg.sender].stakedNftId != 0) {
            _unstakeNft(msg.sender);
        }

        users[msg.sender].stakedNftId = _tokenId + 1; // add offset

        if (msg.sender != tx.origin) {
            lastBlockToStakeNftByContract[msg.sender] = block.number;
        }

        _afterNftStake(msg.sender, _tokenId);
        emit StakedNft(msg.sender, _tokenId);
    }

    function _afterNftStake(address _addr, uint256 nftId) private {
        uint32 gifted;
        (, , , gifted, ) = nft.getPlatypusDetails(nftId);
        // mint vePTP using nft
        if (gifted > 0) {
            // Gifted: +D vePTP regardless of PTP staked
            _mint(_addr, uint256(gifted) * (10**decimals()));
        }
    }

    /// @notice unstakes current user nft
    function unstakeNft() external override nonReentrant whenNotPaused {
        // first, claim his vePTP
        // one should always has deposited if he has staked NFT
        _claim(msg.sender);

        _unstakeNft(msg.sender);
    }

    /// @notice private function used to unstake nft
    /// @param _addr the address of the nft owner
    function _unstakeNft(address _addr) private {
        uint256 nftId = users[_addr].stakedNftId;
        require(nftId > 0, 'No NFT is staked');
        --nftId; // remove offset

        nft.transferFrom(address(this), _addr, nftId);

        users[_addr].stakedNftId = 0;

        _afterNftUnstake(_addr, nftId);
        emit UnstakedNft(_addr, nftId);
    }

    function _afterNftUnstake(address _addr, uint256 nftId) private {
        uint32 gifted;
        (, , , gifted, ) = nft.getPlatypusDetails(nftId);
        // burn vePTP minted by nft
        if (gifted > 0) {
            // Gifted: +D vePTP regardless of PTP staked
            _burn(_addr, uint256(gifted) * (10**decimals()));
        }
    }

    /// @notice gets id of the staked nft
    /// @param _addr the addres of the nft staker
    /// @return id of the staked nft by _addr user
    /// if the user haven't stake any nft, tx reverts
    function getStakedNft(address _addr) external view returns (uint256) {
        uint256 nftId = users[_addr].stakedNftId;
        require(nftId > 0, 'not staking NFT');
        return nftId - 1; // remove offset
    }

    /// @notice level up the staked NFT
    /// @param platypusToBurn token IDs of platypuses to burn
    function levelUp(uint256[] calldata platypusToBurn) external override nonReentrant whenNotPaused {
        uint256 nftId = users[msg.sender].stakedNftId;
        require(nftId > 0, 'not staking NFT');
        --nftId; // remove offset

        uint16 level = nft.getPlatypusLevel(nftId);
        require(level < maxNftLevel, 'max level reached');

        uint256 sumOfLevels;

        for (uint256 i; i < platypusToBurn.length; ++i) {
            uint256 level_ = nft.getPlatypusLevel(platypusToBurn[i]); // 1 - 5
            uint256 exp = nft.getPlatypusXp(platypusToBurn[i]);

            // only count levels which maxXp is reached;
            sumOfLevels += level_ - 1;
            if (exp >= xpRequiredForLevelUp[level_]) {
                ++sumOfLevels;
            } else {
                require(level_ > 1, 'invalid platypusToBurn');
            }
        }
        require(sumOfLevels >= level, 'vePTP: wut are you burning?');

        // claim veptp before level up
        _claim(msg.sender);

        // Remove effect from Gifted
        _afterNftUnstake(msg.sender, nftId);

        // require XP
        require(nft.getPlatypusXp(nftId) >= xpRequiredForLevelUp[level], 'vePTP: XP not enough');

        // skill acquiring
        // acquire the primary skill of a burned platypus
        {
            uint256 contributor = 0;
            if (platypusToBurn.length > 1) {
                uint256 seed = _enoughRandom();
                contributor = (seed >> 8) % platypusToBurn.length;
            }

            uint256 newAbility;
            uint256 newPower;
            (newAbility, newPower) = nft.getPrimaryAbility(platypusToBurn[contributor]);
            nft.levelUp(nftId, newAbility, newPower);
            require(nft.getPlatypusXp(nftId) == 0, 'vePTP: XP should reset');
        }

        // Re apply effect for Gifted
        _afterNftStake(msg.sender, nftId);

        // burn platypuses
        for (uint16 i = 0; i < platypusToBurn.length; ++i) {
            require(nft.ownerOf(platypusToBurn[i]) == msg.sender, 'vePTP: not owner');
            nft.burn(platypusToBurn[i]);
        }
    }

    /// @dev your sure?
    function _enoughRandom() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
    }

    /// @notice level down the staked NFT
    function levelDown() external override nonReentrant whenNotPaused {
        uint256 nftId = users[msg.sender].stakedNftId;
        require(nftId > 0, 'not staking NFT');
        --nftId; // remove offset

        require(nft.getPlatypusLevel(nftId) > 1, 'wut?');

        _claim(msg.sender);

        // Remove effect from Gifted
        _afterNftUnstake(msg.sender, nftId);

        nft.levelDown(nftId);

        // grow to max XP after leveling down
        uint256 maxXp = xpRequiredForLevelUp[nft.getPlatypusLevel(nftId)];
        nft.growXp(nftId, maxXp);

        // Apply effect for Gifted
        _afterNftStake(msg.sender, nftId);

        // veptp should be capped
        uint32 pudgy;
        uint32 gifted;
        (, pudgy, , gifted, ) = nft.getPlatypusDetails(nftId);
        uint256 maxVePtpCap = users[msg.sender].amount * maxStakeCap;
        maxVePtpCap = (maxVePtpCap * (100 + pudgy)) / 100 + uint256(gifted) * (10**decimals());

        if (vePtpGeneratedByStake(msg.sender) > maxVePtpCap) {
            _burn(msg.sender, vePtpGeneratedByStake(msg.sender) - maxVePtpCap);
        }
    }

    /// @notice get votes for vePTP
    /// @dev votes should only count if account has > threshold% of current cap reached
    /// @dev invVoteThreshold = (1/threshold%)*100
    /// @param _addr the addres of the nft staker
    /// @return the valid votes
    function getVotes(address _addr) external view virtual override returns (uint256) {
        uint256 vePtpBalance = balanceOf(_addr);

        uint256 nftId = users[_addr].stakedNftId;
        // if nftId > 0, user has nft staked
        if (nftId > 0) {
            --nftId; //remove offset
            uint32 gifted;
            (, , , gifted, ) = nft.getPlatypusDetails(nftId);
            // burn vePTP minted by nft
            if (gifted > 0) {
                vePtpBalance -= uint256(gifted) * (10**decimals());
            }
        }

        // check that user has more than voting treshold of maxStakeCap and maxLockCap
        if (
            vePtpBalance * invVoteThreshold >
            users[_addr].amount * maxStakeCap + lockedPositions[_addr].ptpLocked * maxLockCap
        ) {
            return vePtpBalance;
        } else {
            return 0;
        }
    }

    function vote(address _user, int256 _voteDelta) external {
        _onlyVoter();

        if (_voteDelta >= 0) {
            usedVote[_user] += uint256(_voteDelta);
            _verifyVoteIsEnough(_user);
        } else {
            // reverts if usedVote[_user] < -_voteDelta
            usedVote[_user] -= uint256(-_voteDelta);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './interfaces/IVeERC20.sol';

/// @title VeERC20Upgradeable
/// @notice Modified version of ERC20Upgradeable where transfers and allowances are disabled.
/// @dev only minting and burning are allowed. The hook _afterTokenOperation is called after Minting and Burning.
contract VeERC20Upgradeable is Initializable, ContextUpgradeable, IVeERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    /**
     * @dev Emitted when `value` tokens are burned and minted
     */
    event Burn(address indexed account, uint256 value);
    event Mint(address indexed beneficiary, uint256 value);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Mint(account, amount);

        _afterTokenOperation(account, _balances[account]);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Burn(account, amount);

        _afterTokenOperation(account, _balances[account]);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any minting and burning.
     * @param account the account being affected
     * @param newBalance newBalance after operation
     */
    function _afterTokenOperation(address account, uint256 newBalance) internal virtual {}

    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

/// @title Whitelist
/// @notice contains a list of wallets allowed to perform a certain operation
contract Whitelist is Ownable {
    mapping(address => bool) internal wallets;

    /// @notice events of approval and revoking wallets
    event ApproveWallet(address);
    event RevokeWallet(address);

    /// @notice approves wallet
    /// @param _wallet the wallet to approve
    function approveWallet(address _wallet) external onlyOwner {
        if (!wallets[_wallet]) {
            wallets[_wallet] = true;
            emit ApproveWallet(_wallet);
        }
    }

    /// @notice revokes wallet
    /// @param _wallet the wallet to revoke
    function revokeWallet(address _wallet) external onlyOwner {
        if (wallets[_wallet]) {
            wallets[_wallet] = false;
            emit RevokeWallet(_wallet);
        }
    }

    /// @notice checks if _wallet is whitelisted
    /// @param _wallet the wallet to check
    /// @return true if wallet is whitelisted
    function check(address _wallet) external view returns (bool) {
        return wallets[_wallet];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Interface of the MasterPlatypus
 */
interface IMasterPlatypus {
    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// a library for performing various math operations

library Math {
    uint256 public constant WAD = 10**18;

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

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

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
 *
 * Note: This contract is backward compatible to OwnableUpgradeable of OZ except from that
 * transferOwnership is dropped.
 * __gap[0] is used as ownerCandidate, as changing storage is not supported yet
 * See https://forum.openzeppelin.com/t/storage-layout-upgrade-with-hardhat-upgrades/14567
 */
contract SafeOwnableUpgradeable is Initializable, ContextUpgradeable {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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

    function ownerCandidate() public view returns (address) {
        return address(uint160(__gap[0]));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function proposeOwner(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0x0)) revert('ZeroAddress');
        // __gap[0] is used as ownerCandidate
        __gap[0] = uint256(uint160(newOwner));
    }

    function acceptOwnership() external {
        if (ownerCandidate() != msg.sender) revert('Unauthorized');
        _setOwner(msg.sender);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './IVeERC20.sol';

/**
 * @dev Interface of the VePtp
 */
interface IVePtpV3 is IVeERC20 {
    function isUserStaking(address _addr) external view returns (bool);

    function deposit(uint256 _amount) external;

    function lockPtp(uint256 _amount, uint256 _lockDays) external returns (uint256);

    function extendLock(uint256 _daysToExtend) external returns (uint256);

    function addPtpToLock(uint256 _amount) external returns (uint256);

    function unlockPtp() external returns (uint256);

    function claim() external;

    function claimable(address _addr) external view returns (uint256);

    function claimableWithXp(address _addr) external view returns (uint256 amount, uint256 xp);

    function withdraw(uint256 _amount) external;

    function vePtpBurnedOnWithdraw(address _addr, uint256 _amount) external view returns (uint256);

    function stakeNft(uint256 _tokenId) external;

    function unstakeNft() external;

    function getStakedNft(address _addr) external view returns (uint256);

    function getStakedPtp(address _addr) external view returns (uint256);

    function levelUp(uint256[] memory platypusBurned) external;

    function levelDown() external;

    function getVotes(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@openzeppelin/contracts/interfaces/IERC721Enumerable.sol';
import './IERC2981Royalties.sol';

interface IPlatypusNFT is IERC721Enumerable, IERC2981Royalties {
    struct Platypus {
        uint16 level; // 1 - 5
        uint16 score;
        // Attributes ( 0 - 9 | D4 D3 D2 D1 C3 C2 C1 B1 B2 A)
        uint8 eyes;
        uint8 mouth;
        uint8 foot;
        uint8 body;
        uint8 tail;
        uint8 accessories;
        // Abilities
        // 0 - Speedo
        // 1 - Pudgy
        // 2 - Diligent
        // 3 - Gifted
        // 4 - Hibernate
        uint8[5] ability;
        uint32[5] power;
    }

    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    function mintCost() external view returns (uint256);

    function merkleRoot() external view returns (bytes32);

    function availableTotalSupply() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
        CONTRACT MANAGEMENT OPERATIONS / SALES
    //////////////////////////////////////////////////////////////*/
    function setOwner(address newOwner) external;

    function increaseAvailableTotalSupply(uint256 amount) external;

    function changeMintCost(uint256 cost) external;

    function setSaleDetails(bytes32 _root, uint256 _preSaleDeadline) external;

    function preSaleDeadline() external view returns (uint256);

    function usedPresaleTicket(address) external view returns (bool);

    function withdrawPTP() external;

    function setNewRoyaltyDetails(address _newAddress, uint256 _newFee) external;

    /*///////////////////////////////////////////////////////////////
                        PLATYPUS LEVEL MECHANICS
            Caretakers are other authorized contracts that
                according to their own logic can issue a platypus
                    to level up
    //////////////////////////////////////////////////////////////*/
    function caretakers(address) external view returns (uint256);

    function addCaretaker(address caretaker) external;

    function removeCaretaker(address caretaker) external;

    function growXp(uint256 tokenId, uint256 xp) external;

    function levelUp(
        uint256 tokenId,
        uint256 newAbility,
        uint256 newPower
    ) external;

    function levelDown(uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    /*///////////////////////////////////////////////////////////////
                            PLATYPUS
    //////////////////////////////////////////////////////////////*/

    function getPlatypusXp(uint256 tokenId) external view returns (uint256 xp);

    function getPlatypusLevel(uint256 tokenId) external view returns (uint16 level);

    function getPrimaryAbility(uint256 tokenId) external view returns (uint8 ability, uint32 power);

    function getPlatypusDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 speedo,
            uint32 pudgy,
            uint32 diligent,
            uint32 gifted,
            uint32 hibernate
        );

    function platypusesLength() external view returns (uint256);

    function setBaseURI(string memory _baseURI) external;

    /*///////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/
    function requestMint(uint256 numberOfMints) external;

    function requestMintTicket(uint256 numberOfMints, bytes32[] memory proof) external;

    // comment to disable a slither false allert: PlatypusNFT does not implement functions
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    // event MintRequest(uint256 from, uint256 length);
    // event OwnerUpdated(address indexed newOwner);
    // event PlatypusCreation(uint256 from, uint256 length);

    // ERC2981.sol
    // event ChangeRoyalty(address newAddress, uint256 newFee);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    // error FeeTooHigh();
    // error InvalidCaretaker();
    // error InvalidRequestID();
    // error InvalidTokenID();
    // error MintLimit();
    // error PreSaleEnded();
    // error TicketError();
    // error TooSoon();
    // error Unauthorized();
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
pragma solidity ^0.8.9;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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