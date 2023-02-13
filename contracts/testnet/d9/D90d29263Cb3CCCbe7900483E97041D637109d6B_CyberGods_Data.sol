/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-11
*/

// File: contracts/SharedStructs.sol


pragma solidity >=0.7.0 <0.9.0;

library SharedStructs {
    // Holds data for players
    struct Player {
        // ----------------- Troops
        // [0] cyborgs [1] mechas [2] beasts [3] demigods || Placeholders for more
        uint256[10] warriorsByTier;
        // [0] fences [1] militians [2] protectors [3] zeus lightnings || Placeholders for more
        uint256[10] defensesByTier;
        // [0] hydras [1] Blood of Ares  || Placeholders for more
        uint256[10] upgradesByTier;
        // represents the attack power given by warriors
        uint256 attackPower;
        // represents the defense power given by defenses
        uint256 defensePower;
        // Current shares (attackPower + defensePower). Shares go back to 0 once ROI is reached
        uint256 shares;
        // current tier based on the shares, on ranks[]
        uint256 tier;
        // ----------------- Buildings
        // [0] excavator [1] garage [2] radar [3] robbery school || placeholders for more
        uint256[10] buildings;
        // ----------------- Statistics
        // [0] count of defenses [1] won defenses [2] lost defenses [3] total avax lose || placeholders for more
        uint256[10] defensesStats;
        // [0] count of attacks [1] won attacks [2] lost attacks [3] total avax won || placeholders for more
        uint256[10] attacksStats;
        // ----------------- Shares & Rewards
        // amount of avax lost to fights since last claim
        uint256 totalLostSinceLastClaim;
        // amount of avax won from fights since last claim
        uint256 totalWonSinceLastClaim;
        // total avax claimed ever
        uint256 totalClaimed;
        // Time of last claim
        uint256 lastClaimTime;
        // epoch when last claim
        uint256 lastClaimEpoch;
        // Time when claim unlocks
        uint256 nextClaimTime;
        // Time for your next attack
        uint256 attackUnlocksTime;
        // Indicates if player has ROId
        bool isROI;
    }

    // Holds data for snapshots
    struct EpochSnapshot {
        // timestamp of the snapshot
        uint256 timestamp;
        // total shares at snapshot
        uint256 totalShares;
        // rewards to distribute this epoch
        uint256 totalRewards;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/CyberGods_Data.sol


pragma solidity >=0.7.0 <0.9.0;



contract CyberGods_Data is Ownable {
    // This contract holds all the data for the CyberGods Game
    // Logic implemented in another Contract

    // Map address to Player
    mapping(address => SharedStructs.Player) private players;
    // Map Snapshot index to Snapshot
    mapping(uint256 => SharedStructs.EpochSnapshot) public epochSnapshots;
    // Map tier to count of players
    mapping(uint256 => uint256) public playersInTiers;
    // Map address to player username
    mapping(address => string) public playersToUsername;

    // Array of address, used for quickly looping over accounts when retrieving players in a tier
    address[] private playersAddress;
    // Game Contract address
    address gameContract;
    // Fees Manager Contract Address
    address public feesManagerAddress;

    // Total Unclaimed rewards
    uint256 public totalRewardsPending = 0;
    // Total Claimed rewards
    uint256 public totalRewardsClaimed = 0;
    // Total rewards distributed since Epoch 1
    uint256 public totalRewards = 0;
    // Total cumulative amount of Avax ever that was in the pool
    uint256 public totalCumulativeAvax = 0;

    // Total Players in Game
    uint256 public totalPlayers = 0;
    // Total Shares of all Players
    uint256 public totalShares = 0;
    // Current Epoch
    uint256 public currentEpoch = 0;
    // Next Epoch Time
    uint256 public nextEpochTime = 0;

    // Verifies if the sender is the Game contract
    modifier onlyAuthorized() {
        require(
            msg.sender == gameContract || msg.sender == owner(),
            "Caller is not the Game"
        );
        _;
    }

    constructor(address _feesManagerAddress) {
        feesManagerAddress = _feesManagerAddress;
    }

    // Allows Fee Manager to send funds
    receive() external payable {
        totalCumulativeAvax += msg.value;
    }

    // Emergency withdraw
    function adminEmergencyWithdraw() external onlyOwner {
        totalRewardsPending = 0;
        payable(owner()).transfer(getTotalPoolBalance());
    }

    // Player functions -----
    // ----------------------
    // ----------------------

    // Get a player's information - admin only
    // _player: the player address
    // returns a Player
    function adminGetPlayerInformation(address _player)
        external
        view
        onlyOwner
        returns (SharedStructs.Player memory)
    {
        return players[_player];
    }

    // Called from Game Contract
    function setBuildings(
        address _player,
        uint256 _buildingId,
        uint256 _toLevel
    ) public onlyAuthorized {
        players[_player].buildings[_buildingId] = _toLevel;
    }

    // Get a player
    // _player: the player's address
    // returns a Player
    function getPlayer(address _player)
        public
        view
        onlyAuthorized
        returns (SharedStructs.Player memory)
    {
        return players[_player];
    }

    // Updates a player's attacks stats
    // _player: the players address
    // _stats: the stats array to set
    function setAttacksStats(address _player, uint256[10] memory _stats)
        public
        onlyAuthorized
    {
        players[_player].attacksStats = _stats;
    }

    // Updates a player's defenses stats
    // _player: the players address
    // _stats: the stats array to set
    function setDefensesStats(address _player, uint256[10] memory _stats)
        public
        onlyAuthorized
    {
        players[_player].defensesStats = _stats;
    }

    // set the total avax won since last claim
    // _player: the player's address
    // _value: the value to set
    function setTotalWonSinceLastClaim(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].totalWonSinceLastClaim = _value;
    }

    // set the total avax lost since last claim
    // _player: the player's address
    // _value: the value to set
    function setTotalLostSinceLastClaim(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].totalLostSinceLastClaim = _value;
    }

    function claimForPlayer(
        address _player,
        uint256 rewards,
        uint256 _nextClaimTime
    ) public onlyAuthorized {
        totalRewardsPending -= rewards;
        totalRewardsClaimed += rewards;

        players[_player].totalClaimed += rewards;
        players[_player].totalWonSinceLastClaim = 0;
        players[_player].totalLostSinceLastClaim = 0;
        players[_player].lastClaimTime = block.timestamp;
        players[_player].nextClaimTime = _nextClaimTime;
        players[_player].lastClaimEpoch = currentEpoch;
        payable(_player).transfer(rewards);
    }

    function setTotalClaimed(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].totalClaimed = _value;
    }

    function setLastClaimTime(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].lastClaimTime = _value;
    }

    function setLastClaimEpoch(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].lastClaimEpoch = _value;
    }

    function setTier(
        address _toPlayer,
        bool _isNewPlayer,
        uint256 _tier
    ) public onlyAuthorized {
        if (!_isNewPlayer) {
            playersInTiers[players[_toPlayer].tier]--;
        }

        players[_toPlayer].tier = _tier;
        playersInTiers[_tier]++;
    }

    function setWarriorsByTier(
        address _player,
        uint256 _tier,
        uint256 _qty
    ) public onlyAuthorized {
        players[_player].warriorsByTier[_tier] = _qty;
    }

    function setAttackPower(address _player, uint256 _attackPower)
        public
        onlyAuthorized
    {
        players[_player].attackPower = _attackPower;
    }

    function setDefensesByTier(
        address _player,
        uint256 _tier,
        uint256 _qty
    ) public onlyAuthorized {
        players[_player].defensesByTier[_tier] = _qty;
    }

    function setDefensePower(address _player, uint256 _defensePower)
        public
        onlyAuthorized
    {
        players[_player].defensePower = _defensePower;
    }

    function setUpgradesByTier(
        address _player,
        uint256 _tier,
        uint256 _qty
    ) public onlyAuthorized {
        players[_player].upgradesByTier[_tier] = _qty;
    }

    function setShares(address _player, uint256 _shares) public onlyAuthorized {
        players[_player].shares = _shares;
    }

    function setNextClaimTime(address _player, uint256 _value)
        public
        onlyAuthorized
    {
        players[_player].nextClaimTime = _value;
    }

    function setIsROI(address _player, bool _isROI) public onlyAuthorized {
        players[_player].isROI = _isROI;
    }

    function updatePlayerLastClaimEpoch(address _player) public onlyAuthorized {
        players[_player].lastClaimEpoch = currentEpoch;
    }

    function setAttackUnlocksTime(address _player, uint256 _unlockTime)
        public
        onlyAuthorized
    {
        players[_player].attackUnlocksTime = _unlockTime;
    }

    // End Player functions -
    // ----------------------
    // ----------------------

    // Epochs functions -----
    // ----------------------
    // ----------------------
    function setNextEpochTime(uint256 _value) public onlyAuthorized {
        nextEpochTime = _value;
    }

    function createEpochSnapshot(
        uint256 _timestamp,
        uint256 _totalShares,
        uint256 _totalRewardsThisEpoch
    ) public onlyAuthorized {
        SharedStructs.EpochSnapshot memory snapshot = SharedStructs
            .EpochSnapshot(_timestamp, _totalShares, _totalRewardsThisEpoch);
        epochSnapshots[currentEpoch] = snapshot;
        currentEpoch++;
    }

    function getEpochSnapshot(uint256 _epochIndex)
        public
        view
        returns (SharedStructs.EpochSnapshot memory)
    {
        return epochSnapshots[_epochIndex];
    }

    // End Epochs functions -
    // ----------------------
    // ----------------------

    // Username functions -----
    // ----------------------
    // ----------------------

    // set a player's username
    // _player: the player's address
    // _username: the username
    function setUsernameForPlayer(address _player, string memory _username)
        public
        onlyAuthorized
    {
        playersToUsername[_player] = _username;
    }

    // remove a player's username
    // _player: the player's address
    function deleteUsernameForPlayer(address _player) public onlyAuthorized {
        delete playersToUsername[_player];
    }

    // Force changes username of a player
    // _address: the player's address
    // _username: the username
    function adminSetUsername(address _address, string memory _username)
        external
        onlyOwner
    {
        playersToUsername[_address] = _username;
    }

    // End Username functions -
    // ----------------------
    // ----------------------

    // Get the list of addresses playing the game
    function getPlayersAddresses() external view returns (address[] memory) {
        return playersAddress;
    }

    // Get player count in tier
    function getPlayerAddress(uint256 _index)
        external
        view
        onlyAuthorized
        returns (address)
    {
        return playersAddress[_index];
    }

    function addNewAddress(address _newPlayer) public onlyAuthorized {
        playersAddress.push(_newPlayer);
        totalPlayers++;
    }

    // ADMIN FUNCTIONS ---------------------

    // Set the Game Contract address
    // _gameContract: the contract address
    function adminSetGameContract(address _gameContract) external onlyOwner {
        gameContract = _gameContract;
    }

    // Set the Fees Manager Contract address
    // _feesManagerAddress: the contract address
    function adminSetFeesManagerAddress(address _feesManagerAddress)
        external
        onlyOwner
    {
        feesManagerAddress = _feesManagerAddress;
    }

    // onlyAuthorized ------------
    function setTotalRewardsPending(uint256 _value) public onlyAuthorized {
        totalRewardsPending = _value;
    }

    function setTotalRewards(uint256 _value) public onlyAuthorized {
        totalRewards = _value;
    }

    function setTotalRewardsClaimed(uint256 _value) public onlyAuthorized {
        totalRewardsClaimed = _value;
    }

    // Get the game pool's balance, minus the pending rewards
    function getPoolBalanceMinusRewards() public view returns (uint256) {
        return address(this).balance - totalRewardsPending;
    }

    // Get the game pool balance
    function getTotalPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setTotalShares(uint256 _totalShares) public onlyAuthorized {
        totalShares = _totalShares;
    }

    function setTotalPlayers(uint256 _value) public onlyAuthorized {
        totalPlayers = _value;
    }

    function setCurrentEpoch(uint256 _value) public onlyAuthorized {
        currentEpoch = _value;
    }
}