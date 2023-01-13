/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/CyberGods_Buildings.sol


pragma solidity >=0.7.0 <0.9.0;



contract CyberGods_Buildings is Ownable, Pausable {
    constructor(address _excavatorPoolAddress, address _treasuryAddress) {
        teamAddress = msg.sender;
        excavatorPoolAddress = _excavatorPoolAddress;
        treasuryAddress = _treasuryAddress;
    }

    // Addresses
    address public excavatorPoolAddress;
    address public treasuryAddress;
    address public teamAddress;

    // Fees
    uint256 public excavatorPoolFee = 50;
    uint256 public treasuryFee = 40;
    uint256 public teamFee = 7;
    uint256 public burntFee = 3;
    uint256 public totalBurnt; // Total Burnt Tracker

    // Constants
    uint256 private constant EXCAVATOR_ID = 0;
    uint256 private constant NURSERY_ID = 1;
    uint256 private constant RADAR_ID = 2;
    uint256 private constant ROBBERY_SCHOOL_ID = 3;

    // Default values for Buildings
    uint256[4] private excavatorLevelValues = [0, 18, 12, 6]; // In hours, how often can a user claim
    uint256[6] private nurseryLevelValues = [0, 20, 15, 10, 5, 3]; // In hours, how long it takes to rest NFTs
    uint256[4] private radarLevelValues = [0, 50, 75, 90]; // In %, how accurately you can inspect enemy's Defense power
    uint256[4] private robberySchoolLevelValues = [0, 30, 40, 50]; // In %, amount you steal from an enemy for a won attack

    // Default upgrade prices for Buildings
    uint256[3] private excavatorLevelPrices = [1 * 1e18, 2 * 1e18, 3 * 1e18];
    uint256[5] private nurseryLevelPrices = [
        1 * 1e18,
        2 * 1e18,
        3 * 1e18,
        4 * 1e18,
        5 * 1e18
    ];
    uint256[3] private radarLevelPrices = [1 * 1e18, 2 * 1e18, 3 * 1e18];
    uint256[3] private robberySchoolLevelPrices = [
        1 * 1e18,
        2 * 1e18,
        3 * 1e18
    ];

    // address to building upgrades
    mapping(address => uint256[6]) private buildingUpgrades;

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Setters
    function setExcavatorPoolFee(uint256 _fee) external onlyOwner {
        excavatorPoolFee = _fee;
    }

    function setTreasuryFee(uint256 _fee) external onlyOwner {
        treasuryFee = _fee;
    }

    function setTeamFee(uint256 _fee) external onlyOwner {
        teamFee = _fee;
    }

    function setBurntFee(uint256 _fee) external onlyOwner {
        burntFee = _fee;
    }

    function setExcavatorPoolAddress(address _address) external onlyOwner {
        excavatorPoolAddress = payable(_address);
    }

    function setExcavatorValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        excavatorLevelValues[_index] = _value;
    }

    function setNurseryValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        nurseryLevelValues[_index] = _value;
    }

    function setRadarValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        radarLevelValues[_index] = _value;
    }

    function setRobberySchoolValueForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        robberySchoolLevelValues[_index] = _value;
    }

    function setExcavatorLevelPriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        excavatorLevelPrices[_index] = _value;
    }

    function setNurseryPriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        nurseryLevelPrices[_index] = _value;
    }

    function setRadarLevelPriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        radarLevelPrices[_index] = _value;
    }

    function setRobberySchoolLevelPriceForIndex(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        robberySchoolLevelPrices[_index] = _value;
    }

    // Getters
    function getExcavatorLevelValues()
        public
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3,
            uint256 level4
        )
    {
        level1 = excavatorLevelValues[0];
        level2 = excavatorLevelValues[1];
        level3 = excavatorLevelValues[2];
        level4 = excavatorLevelValues[3];
    }

    function getNurseryLevelValues()
        public
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3,
            uint256 level4,
            uint256 level5,
            uint256 level6
        )
    {
        level1 = nurseryLevelValues[0];
        level2 = nurseryLevelValues[1];
        level3 = nurseryLevelValues[2];
        level4 = nurseryLevelValues[3];
        level5 = nurseryLevelValues[4];
        level6 = nurseryLevelValues[5];
    }

    function getRadarLevelValues()
        public
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3,
            uint256 level4
        )
    {
        level1 = radarLevelValues[0];
        level2 = radarLevelValues[1];
        level3 = radarLevelValues[2];
        level4 = radarLevelValues[3];
    }

    function getRobberySchoolLevelValues()
        public
        view
        returns (
            uint256 level1,
            uint256 level2,
            uint256 level3,
            uint256 level4
        )
    {
        level1 = robberySchoolLevelValues[0];
        level2 = robberySchoolLevelValues[1];
        level3 = robberySchoolLevelValues[2];
        level4 = robberySchoolLevelValues[3];
    }

    // Return the buildings information
    function getBuildingsInformation()
        external
        view
        returns (
            uint256[4] memory excavatorLevels,
            uint256[3] memory excavatorPrices,
            uint256[6] memory nurseryLevels,
            uint256[5] memory nurseryPrices,
            uint256[4] memory radarLevels,
            uint256[3] memory radarPrices,
            uint256[4] memory robberySchoolLevels,
            uint256[3] memory robberySchoolPrices
        )
    {
        excavatorLevels = excavatorLevelValues;
        excavatorPrices = excavatorLevelPrices;

        nurseryLevels = nurseryLevelValues;
        nurseryPrices = nurseryLevelPrices;

        radarLevels = radarLevelValues;
        radarPrices = radarLevelPrices;

        robberySchoolLevels = robberySchoolLevelValues;
        robberySchoolPrices = robberySchoolLevelPrices;
    }

    // Returns a user's building tree
    function getUserBuildingLevels(address _owner)
        public
        view
        returns (
            uint256 excavator,
            uint256 nursery,
            uint256 radar,
            uint256 robberySchool
        )
    {
        uint256[6] memory userBuildings = buildingUpgrades[_owner];
        excavator = userBuildings[EXCAVATOR_ID];
        nursery = userBuildings[NURSERY_ID];
        radar = userBuildings[RADAR_ID];
        robberySchool = userBuildings[ROBBERY_SCHOOL_ID];
    }

    // Upgrades a building for the caller
    function upgradeBuilding(uint256 _buildingId)
        external
        payable
        whenNotPaused
    {
        address sender = msg.sender;
        require(
            _buildingId >= EXCAVATOR_ID && _buildingId <= ROBBERY_SCHOOL_ID,
            "Invalid Building"
        );

        uint256 currentBuildingLevel = buildingUpgrades[sender][_buildingId];

        if (_buildingId == EXCAVATOR_ID) {
            require(
                currentBuildingLevel + 1 <= excavatorLevelValues.length,
                "Excavator Already Max Level"
            );
            require(
                msg.value >= excavatorLevelPrices[currentBuildingLevel],
                "Value below price"
            );
        } else if (_buildingId == NURSERY_ID) {
            require(
                currentBuildingLevel + 1 <= nurseryLevelValues.length,
                "Nursery Already Max Level"
            );
            require(
                msg.value >= nurseryLevelPrices[currentBuildingLevel],
                "Value below price"
            );
        } else if (_buildingId == RADAR_ID) {
            require(
                currentBuildingLevel + 1 <= radarLevelValues.length,
                "Radar Already Max Level"
            );
            require(
                msg.value >= radarLevelPrices[currentBuildingLevel],
                "Value below price"
            );
        } else if (_buildingId == ROBBERY_SCHOOL_ID) {
            require(
                currentBuildingLevel + 1 <= robberySchoolLevelValues.length,
                "Robbery School Already Max Level"
            );
            require(
                msg.value >= robberySchoolLevelPrices[currentBuildingLevel],
                "Value below price"
            );
        }

        buildingUpgrades[sender][_buildingId] = currentBuildingLevel + 1;

        // payable(excavatorPoolAddress).transfer((msg.value * excavatorPoolFee) / 100); // Split for the mining pool
        // payable(treasuryAddress).transfer((msg.value * treasuryFee) / 100); // Split for the treasury
        // payable(teamAddress).transfer((msg.value * teamFee) / 100); // Split for the team
        // payable(address(0)).transfer((msg.value * burntFee) / 100); // Burn the rest

        totalBurnt += (msg.value * burntFee) / 100;
    }

    /**
     * @dev allows owner to withdraw AVAX
     */
    function withdrawAVAX(uint256 _amount) external payable onlyOwner {
        require(address(this).balance >= _amount, "not enough AVAX");
        address payable to = payable(_msgSender());
        (bool sent, ) = to.call{value: _amount}("");
        require(sent, "Failed to send AVAX");
    }
}