//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PlotCreation is Ownable {
    string public constant _PLOT_IDENTIFIER = "METAPLOT";

    // Enum representing the different plot sources
    enum PlotSource {
        Legal,
        Investor,
        Business
    }

    /**
     * @notice Plot structs.
     *  plotID - Unique ID of the plot. ie. It is an integer value. ex: 1,2,3 etc.
     *  canonicalIdentifier - String (Postal Address, Place Name). It is a string.
     *  name - Friendly name of the plot. Ex: "Plot-abc"
     *  boundaries - Polygon (Lat, Long). It is a serialized json. 
        Ex: "{{"lat":123658963,"long":256936995},{"lat":123658963,"long":256936995},{"lat":123658963,"long":256936995},{"lat":123658963,"long":256936995}}"
     *  elevationProfile - Array of Raster Tiles
     *  centrodId - Point (Lat, Long) of the plot. It is a serialized json. Ex: "{"lat":123658963,"long":256936995}"
     *  gisSource - Enum (Legal, Investor, Business)
     *  gisSourceAddress - Crypto Wallet Address of a GIS Source
     *  gisSourceName - Friendly name of the GIS Source
      * maxEditions - Maximum number of editions allowed for this plot.
     *  creationDate - DateTime of the plot creation
     */
    struct Plot {
        uint256 plotID;
        string canonicalIdentifier;
        string name;
        string boundaries;
        string elevationProfile;
        string centrodId;
        PlotSource gisSource;
        address gisSourceAddress;
        string gisSourceName;
        uint256 maxEditions;
        uint256 creationDate;
    }
    // Collection of Plot is Plots.
    mapping(uint256 => Plot) public Plots;
    // Last index of the Plots collection
    uint256 private _lastPlotIndex;
    event PlotCreate(string plotName, uint256 plotID);

    enum ReleaseType {
        None,
        Manual,
        Automatic_Price_Threshold,
        Automatic_Time_Interval
    }
    /**
     * @notice Released plot information
     *  releaseID - Unique ID of the relesed information of a plot.
     *  plotID - ID of a plot that is released.
     *  editionsReleased - Total number of editions released at this particular release. It should always be <= MaxEditions.
     *  totalReleased - Total number of all editions released so far in multiple releases which should always be <= MaxEditions.
     *  releaseType - Enum (None, Manual, Automatic_Price_Threshold, Automatic_Time_Interval)
     *  releaseScalar - For Automatic transaction this is the fraction that is released per threshold/interval
     *  releasedDate - DateTime of the plot edition released.
     */
    struct PlotRelease {
        uint256 releaseID;
        uint256 plotID;
        uint256 editionsReleased;
        uint256 totalReleased;
        ReleaseType releaseType;
        uint256 releaseScalar;
        uint256 releasedDate;
    }
    // Every plot Id will have multiple releases. So records are stored in a map. ex {plotID:{releaseID1:PlotRelease1,releaseID2:PlotRelease2}}
    mapping(uint256 => mapping(uint256 => PlotRelease)) public plotsReleased;
    // Last id of particular plot releases. ex if releaseIDs[plotID] = [1,2,3,4,5] then lastReleaseID[plotID] = 5
    mapping(uint256 => uint256) public plotLastReleaseID;

    function createPlot(
        string memory canonicalIdentifier,
        string memory name,
        string memory boundaries,
        string memory elevationProfile,
        string memory centrodId,
        PlotSource source,
        address sourceAddress,
        string memory sourceName,
        uint256 maxEditions
    ) public {
        require(maxEditions > 0, "Max editions should be greater than 0");
        uint256 id = ++_lastPlotIndex;

        Plots[id] = Plot(
            id,
            canonicalIdentifier,
            name,
            boundaries,
            elevationProfile,
            centrodId,
            source,
            sourceAddress,
            sourceName,
            maxEditions,
            block.timestamp
        );
        emit PlotCreate(name, id);
    }

    function createPlotRelease(
        uint256 plotID,
        uint256 editionToRelease,
        ReleaseType releaseType,
        uint256 releaseScalar
    ) public plotExists(plotID) onlyOwner {
        require(
            editionToRelease > 0,
            "Number of editions to release should be greater than 0"
        );
        uint256 totalReleased = getTotalPlotReleased(plotID, editionToRelease);

        uint256 releaseID = ++plotLastReleaseID[plotID];
        plotsReleased[plotID][releaseID] = PlotRelease(
            releaseID,
            plotID,
            editionToRelease,
            totalReleased + editionToRelease,
            releaseType,
            releaseScalar,
            block.timestamp
        );
    }

    modifier plotExists(uint256 plotID) {
        require(Plots[plotID].plotID != 0, "Plot doesnot exist.");

        _;
    }

    /**
     * @dev Get the latest released plot information.
     * @param plotID - ID of the plot
     * */
    function getPlot(uint256 plotID) public view returns (string memory pID) {
        Plot memory plot = Plots[plotID];
        return plot.name;
    }

    /**
     * @dev Get the latest released plot information.
     * @param plotID - ID of the plot
     * */
    function getLatestPlotRelease(uint256 plotID)
        public
        view
        returns (
            uint256 releaseID,
            uint256 editions,
            uint256 totalRelease,
            uint256 releaseScalar,
            uint256 releasedDate
        )
    {
        PlotRelease memory lastRelease = plotsReleased[plotID][
            plotLastReleaseID[plotID]
        ];
        return (
            lastRelease.releaseID,
            lastRelease.editionsReleased,
            lastRelease.totalReleased,
            lastRelease.releaseScalar,
            lastRelease.releasedDate
        );
    }

    /**
     * @dev Get the total number of editions released for a plot.
     * @notice This function is used to get the total number of editions released for a plot. It also checks if max editions is reached.
     * @param plotID - ID of the plot
     * @param editionsToRelease - Number of editions to release
     * */
    function getTotalPlotReleased(uint256 plotID, uint256 editionsToRelease)
        public
        view
        returns (uint256)
    {
        uint256 lastReleaseID = plotLastReleaseID[plotID];
        // If plotID has prior releases then check if the total number of releases is less than the maxEditions.
        uint256 totalReleased = plotsReleased[plotID][lastReleaseID]
            .totalReleased;
        require(
            (Plots[plotID].maxEditions - totalReleased) >= editionsToRelease,
            "Limit reached. Cannot release more than max editions."
        );

        return (totalReleased);
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