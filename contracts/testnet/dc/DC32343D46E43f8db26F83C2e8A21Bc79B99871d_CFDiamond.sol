// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibCFDiamond} from "./libraries/LibCFDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {ProjectToken} from "./ProjectToken.sol";
import "./libraries/Strings.sol";
import "./AnalyticMath.sol";

/// @title A upgradable and pausable crowdfunding contract for every project
/// @author abhi3700, hosokawa-zen
/// @notice You can use this contract as a template for every crowdfunding project
contract CFDiamond is IDiamondCut {
    using Strings for string;

    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     CFDE0: th CF name should be least 3 letters
     CFDE1: the CF name should be not over 12 letters
     CFDE2: the fee percentage should be between 0 and 10000
     CFDE3: the conversion period should be least one week(604800)
     CFDE4: the min.threshold can not be zero
     CFDE5: the treasury address can not be zero_address
     CFDE6: the AnalyticMath contract is invalid
     CFDE7: the frequency duration is invalid
     CFDE8: the frequency duration must be less than or equal to conversion period
    */

    // Crowdfunding diamond constructor
    /// @dev initialize crowdfunding data
    /// @param _pName : the project name
    /// @param _coinAddr : the funding token(project coin) address
    /// @param _stAddr : the investing stable coin address
    /// @param _pOFeePt : the project owner fee percent (10000> fee >0)
    /// @param _bufferPeriod : the buffer period of crowdfunding in seconds
    /// @param _conversionPeriod : the conversion period of crowdfunding in seconds
    /// @param _frequencyDuration : the frequency duration in seconds for releasing PC (A day / Couple days / A week)
    /// @param _minTh : the MinThreshold structure (minTh : value, minThType: type)
    /// @param _treasuryAddr: the treasury address (the address withdrawing protocol fee)
    /// @param _analyticMathAddr: the deployed `AnalyticMath` contract`s address
    /// @param _diamondCut: "FacetCut" array for setting facets
    constructor(
        string memory _pName,
        address _coinAddr,
        address _stAddr,
        uint16 _pOFeePt,
        uint256 _bufferPeriod,
        uint256 _conversionPeriod,
        uint256 _frequencyDuration,
        LibCFDiamond.MinThreshold memory _minTh,
        address _treasuryAddr,
        address _analyticMathAddr,
        FacetCut[] memory _diamondCut
    ) {
        LibCFDiamond.setContractOwner(msg.sender);

        require(_pName.length() > 2, "CFDE0");
        require(_pName.length() < 13, "CFDE1");
        require(_pOFeePt < LibCFDiamond.PERCENT_DIVISOR, "CFDE2");
        // Min: One Week 3600 * 24 * 7
        // require(_conversionPeriod >= 604800, "CFDE3");   // Enable this for production code
        require(_conversionPeriod >= 0, "CFDE3"); // TODO: remove this later. It's only for testing purpose.
        require(_frequencyDuration > 0, "CFDE7");
        require(_frequencyDuration <= _conversionPeriod, "CFDE8");
        require(_minTh.minThAmt > 0, "CFDE4");
        require(_treasuryAddr != address(0), "CFDE5");
        require(_analyticMathAddr != address(0), "CFDE6");

        LibCFDiamond.DiamondStorage storage ds = LibCFDiamond.diamondStorage();

        ds.projectCoinAddr = _coinAddr;
        ds.stableCoinAddr = _stAddr;
        ds.projectFeePercent1 = _pOFeePt;

        // Sell Curve Coefficient 90%
        ds.sellCoefficient = 9000;
        // Crowdfunding Protocol Fee 1%
        ds.protocolFeePercent1 = 100;
        // Reserve Ratio 4
        ds.reserveRatio = 4;
        // Curve Supply 20000 PT * Decimals
        ds.curveSupply = 20000 * 1e18;

        ds.treasuryAddress = _treasuryAddr;

        /// Unique Project Token
        /// Name: Project Name
        /// Symbol: Protocol Prefix (T) + Project Name (Max 6 letters)
        ds._projectName = _pName.upper();
        string memory tokenSymbol = string("T").append(
            ds._projectName.slice(0, 6)
        );
        ds.projectToken = address(
            new ProjectToken(ds._projectName, tokenSymbol)
        );

        // Set Crowdfunding Duration
        ds.bufferPeriod = _bufferPeriod;
        ds.conversionPeriod = _conversionPeriod;
        ds.frequencyDuration = _frequencyDuration;

        // Set Min.Threshold
        ds.minThreshold = _minTh.minThAmt;
        ds.minThresholdType = _minTh.minThType;

        // Set market limit
        ds.marketLimit = 1;

        // Set created timestamp
        ds.createdTimestamp = block.timestamp;

        // Set AnalyticMath
        ds.analyticMath = _analyticMathAddr;

        // Set facets
        LibCFDiamond.diamondCut(_diamondCut, address(0), "");
    }

    // DiamondCut Actions (Add/Replace/Remove)
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibCFDiamond.enforceIsContractOwner();
        LibCFDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    // Set AnalyticMath
    function setAMathAddr(address _analyticMath) external override {
        LibCFDiamond.enforceIsContractOwner();
        LibCFDiamond.setAnalyticMath(_analyticMath);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibCFDiamond.DiamondStorage storage ds;
        bytes32 position = LibCFDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import "./SafeMath.sol";

library LibCFDiamond {
    using SafeMath for uint256;

    /**
     * ****************************************
     *
     * Errors
     * ****************************************
     LIBE0: the caller is not a owner
     LIBE1: CF was not paused
     LIBE2: CF was paused
     LIBE3: the diamond cut action is not correct
     LIBE4: the function selectors are empty
     LIBE5: the facet address can not be zero_address.
     LIBE6: the function already exists
     LIBE7: the facet has no code
     LIBE8: the function does not exist
     LIBE9: the function is immutable.
     LIBE10: CALL_DATA is not empty
     LIBE11: CALL_DATA is empty
     LIBE12: the init address has no code
     LIBE13: while executing init code, the transaction was reverted
     LIBE14: the CF was not started
     LIBE15: the CF is outside of ongoing period
     LIBE16: the CF is deactivated
     LIBE17: the CF still was not reached to min.threshold
     LIBE18: the CF is outside of conversion period
     LIBE19: the CF is in buffer period
     LIBE20: the CF is ongoing
     LIBE21: the Bond Investment was not activated
     */

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("theia.crowdfunding.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    // Offer Data for Bond Investment
    struct OfferData {
        address seller;
        uint256 bondTokenAmt;
        uint256 reserveBTAmt;
        address askCoinAddr;
        uint256 askCoinAmt;
        uint8 status;
    }

    // Market Data
    struct Market {
        uint256 marketId;
        // market stable coin
        address marketStCoin;
        // market fee percent
        uint16 marketFeePt;
        // market fee amount
        uint256 marketFeeAmt;
    }

    // PC release detail
    struct PCRDetails {
        uint256 convertiblePT;
        uint256 tobeConvertiblePT;
        uint256 pcrCount;
    }

    enum MinThresholdType {
        Funding,
        ProjectFee
    }

    struct MinThreshold {
        uint256 minThAmt;
        MinThresholdType minThType;
    }

    enum MarketStatus {
        None,
        Joining,
        Joined
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the contract & project owner
        address contractOwner;
        // paused of the contract
        bool _paused;
        /// Project name
        string _projectName;
        /// Total deposited stableCoins
        uint256 totalStableCoinAmt;
        /// coin`s address => Project Fee Amount
        uint256 projectFeeAmt;
        /// coin`s address => Protocol Fee Amount
        uint256 protocolFeeAmt;
        // Project Token
        address projectToken;
        // The amount of locked Project Token in CF
        uint256 lockPTAmt;
        // Address of the deployed Project Coin contract
        address projectCoinAddr;
        // Funding Project Coin`s Supply Amount
        uint256 allocatedPCAmt;
        // THEIA treasury address
        address treasuryAddress;
        // MIN.Threshold amount
        uint256 minThreshold;
        // MIN.Threshold Type
        MinThresholdType minThresholdType;
        // GMT timestamp of when the crowdfund starts
        uint256 startTimestamp;
        // GMT timestamp of when reached to min.threshold
        uint256 tpTimestamp;
        // buffer time from min.threshold point to CP
        uint256 bufferPeriod;
        // Crowdfunding Conversion Period
        uint256 conversionPeriod;
        // Frequency Duration
        uint256 frequencyDuration;
        // USDT, USDC
        address stableCoinAddr;
        // Protocol Fee Percent In Funding (1%)
        uint16 protocolFeePercent1;
        // Project Owner Fee Percent
        uint16 projectFeePercent1;
        // Sell price coefficient (0.9)
        uint16 sellCoefficient;
        // Reserve Ratio (0 < - < 10, default: 4)
        uint16 reserveRatio;
        // Curve Supply (20000 TEA)
        uint256 curveSupply;
        // Analytic Math Contract
        address analyticMath;
        // Mapping of offer_id => OfferData
        mapping(uint256 => OfferData) bondOffersMap;
        // Bond Offer Iterator
        uint256 offersCounter;
        // Bond Token
        address bondToken;
        // Protocol Fee Percent In Bond Investment (1%)
        uint16 protocolFeePercent2;
        // Bond Investment Project Owner Fee Percent
        uint16 projectFeePercent2;
        // Total Crowdfunding Investors
        uint256 totPInvestors;
        // Total Bond funding Investors
        uint256 totBInvestors;
        // Daily Release Rates in increasing order (day_index => PC Release Amount)
        mapping(uint256 => uint256) pcrAmtList;
        // User`s PC release detail
        mapping(address => PCRDetails) pcrMap;
        // PCR event counter
        uint256 pcrCount;
        // Unclaimed PC Amount
        uint256 claimedPCAmt;
        // Created timestamp of CF
        uint256 createdTimestamp;
        // market requests
        mapping(address => MarketStatus) marketRequests;
        // markets
        mapping(address => Market) markets;
        // market indexes
        mapping(uint256 => address) marketIndex;
        // market counter
        uint256 marketCounter;
        // market limit
        uint256 marketLimit;

        // TODO Please add new members from end of struct
    }

    // Percent Division
    uint16 internal constant PERCENT_DIVISOR = 10**4;

    // Offer Status Open
    uint8 internal constant OFFER_STATUS_OPEN = 1;
    uint8 internal constant OFFER_STATUS_CLOSE = 0;

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LIBE0");
    }

    // The contract must be paused.
    function whenPaused() internal view {
        require(diamondStorage()._paused, "LIBE1");
    }

    // The contract must not be paused.
    function whenNotPaused() internal view {
        require(!diamondStorage()._paused, "LIBE2");
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LIBE3");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LIBE4");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LIBE5");
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(oldFacetAddress == address(0), "LIBE6");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LIBE4");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LIBE5");
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamond: SAME_FUNCTION"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LIBE4");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LIBE5");
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(_facetAddress, "LIBE7");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LIBE8");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LIBE9");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LIBE10");
        } else {
            require(_calldata.length > 0, "LIBE11");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LIBE12");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LIBE13");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    /**
     * ****************************************
     *
     * Modifiers
     * ****************************************
     */
    // Ensure actions can only happen while crowdfund is ongoing
    function isOngoingCF() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.startTimestamp > 0, "LIBE14");
        require(
            ds.tpTimestamp == 0 ||
                block.timestamp <
                ds.tpTimestamp.add(ds.bufferPeriod).add(ds.conversionPeriod),
            "LIBE15"
        );
    }

    // Crowdfunding is active when project owner sends enough project coins to funding contracts
    function isActiveCF() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.allocatedPCAmt > 0, "LIBE16");
    }

    // Ensure actions can only happen when funding threshold is reached
    function isReachedToTh() internal view {
        DiamondStorage storage ds = diamondStorage();
        uint256 minThresholdAmt;
        if (ds.minThresholdType == LibCFDiamond.MinThresholdType.Funding) {
            minThresholdAmt = ds.totalStableCoinAmt;
        } else {
            minThresholdAmt = ds.projectFeeAmt;
        }
        require(minThresholdAmt >= ds.minThreshold, "LIBE17");
    }

    // Ensure actions can only happen while crowdfund is ongoing in CP
    function isConversionPeriod() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.tpTimestamp > 0, "LIBE17");
        require(
            block.timestamp >= ds.tpTimestamp.add(ds.bufferPeriod) &&
                block.timestamp <
                ds.tpTimestamp.add(ds.bufferPeriod).add(ds.conversionPeriod),
            "LIBE18"
        );
    }

    // Ensure actions can only happen while crowdfund is going after Buffer Time Period
    function isAfterBP() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.tpTimestamp > 0, "LIBE17");
        require(
            block.timestamp >= ds.tpTimestamp.add(ds.bufferPeriod),
            "LIBE19"
        );
    }

    // Ensure actions can only happen when funding is ended
    function isEndOfCF() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.tpTimestamp > 0, "LIBE17");
        require(
            block.timestamp >=
                ds.tpTimestamp.add(ds.bufferPeriod).add(ds.conversionPeriod),
            "LIBE20"
        );
    }

    // Ensure actions can only happen when Bond Investment is activated
    function isActiveBondInv() internal view {
        require(diamondStorage().bondToken != address(0), "LIBE21");
    }

    event SetAMathAddr(address _analyticMath);

    // Set AnalyticMath
    function setAnalyticMath(address _analyticMath) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.analyticMath = _analyticMath;

        emit SetAMathAddr(_analyticMath);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    /// @notice Set the "AnalyticMath" library contract for upgrading
    /// @param _analyticMath The address of the "AnalyticMath" library contract
    function setAMathAddr(address _analyticMath) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IProjectToken.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

// the ERC20 token for crowdfunding
/// @notice work as the LP token of crowdfunding pool
/// @author abhi3700, hosokawa-zen
/// @dev only owner can mint, transfer and burn (the owner will be the crowdfunding contract)
contract ProjectToken is IProjectToken, Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 internal constant _DECIMALS = 18;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    constructor(string memory _tName, string memory _tSymbol) {
        _name = _tName;
        _symbol = _tSymbol;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        require(amount > 0, "ERC20: mint amount zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(address account, uint256 amount) external override onlyOwner {
        require(amount > 0, "ERC20: burn amount zero");
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title String library contract
/// @author abhi3700, hosokawa-zen
library Strings {
    /// @notice Get string`s length
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /// @notice Concat string
    function append(string memory _base, string memory second)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_base, second));
    }

    /// @notice Get string`s substring
    /// @param _offset Substring`s start offset
    /// @param _length Substring`s length
    function slice(
        string memory _base,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint256(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint256(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint256 j = 0;
        for (
            uint256 i = uint256(_offset);
            i < uint256(_offset + _length);
            i++
        ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    /// @notice Get string`s uppercase
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] >= 0x61 && _baseBytes[i] <= 0x7A) {
                _baseBytes[i] = bytes1(uint8(_baseBytes[i]) - 32);
            }
        }
        return string(_baseBytes);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/math/IntegralMath.sol";
import "./interfaces/IAnalyticMath.sol";

/// @title A helper contract for calculating the complex mathematical formulas
/// @author abhi3700, hosokawa-zen
/// @notice calculate power, log, exponent with uint256
contract AnalyticMath is IAnalyticMath {
    uint8 internal constant MIN_PRECISION = 32;
    uint8 internal constant MAX_PRECISION = 127;

    uint256 internal constant FIXED_1 = 1 << MAX_PRECISION;
    uint256 internal constant FIXED_2 = 2 << MAX_PRECISION;

    // Auto-generated via 'PrintLn2ScalingFactors.py'
    uint256 internal constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 internal constant LN2_DENOMINATOR =
        0x5b9de1d10bf4103d647b0955897ba80;

    // Auto-generated via 'PrintOptimalThresholds.py'
    uint256 internal constant OPT_LOG_MAX_VAL =
        0x15bf0a8b1457695355fb8ac404e7a79e4;
    uint256 internal constant OPT_EXP_MAX_VAL =
        0x800000000000000000000000000000000;

    uint256[MAX_PRECISION + 1] private maxExpArray;

    constructor() {
        initMaxExpArray();
    }

    /**
     * @dev Compute (a / b) ^ (c / d)
     */
    function powF(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) external view override returns (uint256, uint256) {
        unchecked {
            if (a >= b) return mulDivExp(mulDivLog(FIXED_1, a, b), c, d);
            (uint256 q, uint256 p) = mulDivExp(mulDivLog(FIXED_1, b, a), c, d);
            return (p, q);
        }
    }

    /**
     * @dev Compute (a * b / c)
     */
    function mulDivF(
        uint256 a,
        uint256 b,
        uint256 c
    ) external pure override returns (uint256) {
        return IntegralMath.mulDivF(a, b, c);
    }

    /**
     * @dev Compute log(x / FIXED_1) * FIXED_1
     */
    function fixedLog(uint256 x) internal pure returns (uint256) {
        unchecked {
            if (x < OPT_LOG_MAX_VAL) {
                return optimalLog(x);
            } else {
                return generalLog(x);
            }
        }
    }

    /**
     * @dev Compute e ^ (x / FIXED_1) * FIXED_1
     */
    function fixedExp(uint256 x) internal view returns (uint256, uint256) {
        unchecked {
            if (x < OPT_EXP_MAX_VAL) {
                return (optimalExp(x), 1 << MAX_PRECISION);
            } else {
                uint8 precision = findPosition(x);
                return (
                    generalExp(x >> (MAX_PRECISION - precision), precision),
                    1 << precision
                );
            }
        }
    }

    /**
     * @dev Compute log(x / FIXED_1) * FIXED_1
     * This functions assumes that x >= FIXED_1, because the output would be negative otherwise
     */
    function generalLog(uint256 x) internal pure returns (uint256) {
        unchecked {
            uint256 res = 0;

            // if x >= 2, then we compute the integer part of log2(x), which is larger than 0
            if (x >= FIXED_2) {
                uint8 count = IntegralMath.floorLog2(x / FIXED_1);
                x >>= count; // now x < 2
                res = count * FIXED_1;
            }

            // if x > 1, then we compute the fraction part of log2(x), which is larger than 0
            if (x > FIXED_1) {
                for (uint8 i = MAX_PRECISION; i > 0; --i) {
                    x = (x * x) / FIXED_1; // now 1 < x < 4
                    if (x >= FIXED_2) {
                        x >>= 1; // now 1 < x < 2
                        res += 1 << (i - 1);
                    }
                }
            }

            return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
        }
    }

    /**
     * @dev Approximate e ^ x as (x ^ 0) / 0! + (x ^ 1) / 1! + ... + (x ^ n) / n!
     * Auto-generated via 'PrintFunctionGeneralExp.py'
     * Detailed description:
     * - This function returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy
     * - The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1"
     * - The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)"
     */
    function generalExp(uint256 x, uint8 precision)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 xi = x;
            uint256 res = 0;

            xi = (xi * x) >> precision;
            res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
            xi = (xi * x) >> precision;
            res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
            xi = (xi * x) >> precision;
            res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
            xi = (xi * x) >> precision;
            res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
            xi = (xi * x) >> precision;
            res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
            xi = (xi * x) >> precision;
            res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
            xi = (xi * x) >> precision;
            res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
            xi = (xi * x) >> precision;
            res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
            xi = (xi * x) >> precision;
            res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
            xi = (xi * x) >> precision;
            res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
            xi = (xi * x) >> precision;
            res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
            xi = (xi * x) >> precision;
            res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
            xi = (xi * x) >> precision;
            res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
            xi = (xi * x) >> precision;
            res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
            xi = (xi * x) >> precision;
            res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

            return
                res / 0x688589cc0e9505e2f2fee5580000000 + x + (1 << precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
        }
    }

    /**
     * @dev Compute log(x / FIXED_1) * FIXED_1
     * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalLog.py'
     * Detailed description:
     * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
     * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
     * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
     * - The natural logarithm of the input is calculated by summing up the intermediate results above
     * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
     */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        unchecked {
            uint256 res = 0;

            uint256 y;
            uint256 z;
            uint256 w;

            if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd9) {
                res += 0x40000000000000000000000000000000;
                x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd9;
            } // add 1 / 2^1
            if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a8) {
                res += 0x20000000000000000000000000000000;
                x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a8;
            } // add 1 / 2^2
            if (x >= 0x910b022db7ae67ce76b441c27035c6a2) {
                res += 0x10000000000000000000000000000000;
                x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a2;
            } // add 1 / 2^3
            if (x >= 0x88415abbe9a76bead8d00cf112e4d4a9) {
                res += 0x08000000000000000000000000000000;
                x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a9;
            } // add 1 / 2^4
            if (x >= 0x84102b00893f64c705e841d5d4064bd4) {
                res += 0x04000000000000000000000000000000;
                x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd4;
            } // add 1 / 2^5
            if (x >= 0x8204055aaef1c8bd5c3259f4822735a3) {
                res += 0x02000000000000000000000000000000;
                x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a3;
            } // add 1 / 2^6
            if (x >= 0x810100ab00222d861931c15e39b44e9a) {
                res += 0x01000000000000000000000000000000;
                x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e9a;
            } // add 1 / 2^7
            if (x >= 0x808040155aabbbe9451521693554f734) {
                res += 0x00800000000000000000000000000000;
                x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f734;
            } // add 1 / 2^8

            z = y = x - FIXED_1;
            w = (y * y) / FIXED_1;
            res +=
                (z * (0x100000000000000000000000000000000 - y)) /
                0x100000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
            res +=
                (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) /
                0x200000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
            res +=
                (z * (0x099999999999999999999999999999999 - y)) /
                0x300000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
            res +=
                (z * (0x092492492492492492492492492492492 - y)) /
                0x400000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
            res +=
                (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) /
                0x500000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
            res +=
                (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) /
                0x600000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
            res +=
                (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) /
                0x700000000000000000000000000000000;
            z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
            res +=
                (z * (0x088888888888888888888888888888888 - y)) /
                0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

            return res;
        }
    }

    /**
     * @dev Compute e ^ (x / FIXED_1) * FIXED_1
     * Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
     * Auto-generated via 'PrintFunctionOptimalExp.py'
     * Detailed description:
     * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
     * - The exponentiation of each binary exponent is given (pre-calculated)
     * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
     * - The exponentiation of the input is calculated by multiplying the intermediate results above
     * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
     */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        unchecked {
            uint256 res = 0;

            uint256 y;
            uint256 z;

            z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
            z = (z * y) / FIXED_1;
            res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
            z = (z * y) / FIXED_1;
            res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
            z = (z * y) / FIXED_1;
            res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
            z = (z * y) / FIXED_1;
            res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
            z = (z * y) / FIXED_1;
            res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
            z = (z * y) / FIXED_1;
            res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
            z = (z * y) / FIXED_1;
            res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
            z = (z * y) / FIXED_1;
            res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
            z = (z * y) / FIXED_1;
            res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
            z = (z * y) / FIXED_1;
            res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
            z = (z * y) / FIXED_1;
            res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
            z = (z * y) / FIXED_1;
            res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
            z = (z * y) / FIXED_1;
            res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
            res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

            if ((x & 0x010000000000000000000000000000000) != 0)
                res =
                    (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) /
                    0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
            if ((x & 0x020000000000000000000000000000000) != 0)
                res =
                    (res * 0x18ebef9eac820ae8682b9793ac6d1e778) /
                    0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
            if ((x & 0x040000000000000000000000000000000) != 0)
                res =
                    (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) /
                    0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
            if ((x & 0x080000000000000000000000000000000) != 0)
                res =
                    (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) /
                    0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
            if ((x & 0x100000000000000000000000000000000) != 0)
                res =
                    (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) /
                    0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
            if ((x & 0x200000000000000000000000000000000) != 0)
                res =
                    (res * 0x00960aadc109e7a3bf4578099615711d7) /
                    0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
            if ((x & 0x400000000000000000000000000000000) != 0)
                res =
                    (res * 0x0002bf84208204f5977f9a8cf01fdc307) /
                    0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

            return res;
        }
    }

    /**
     * @dev The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
     * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
     * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
     * This function supports the rational approximation of "(a / b) ^ (c / d)" via "e ^ (log(a / b) * c / d)".
     * The value of "log(a / b)" is represented with an integer slightly smaller than "log(a / b) * 2 ^ precision".
     * The larger "precision" is, the more accurately this value represents the real value.
     * However, the larger "precision" is, the more bits are required in order to store this value.
     * And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (a maximum value of "x").
     * This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
     * Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
     * This allows us to compute the result with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
     */
    function findPosition(uint256 x) internal view returns (uint8) {
        unchecked {
            uint8 lo = MIN_PRECISION;
            uint8 hi = MAX_PRECISION;

            while (lo + 1 < hi) {
                uint8 mid = (lo + hi) / 2;
                if (maxExpArray[mid] >= x) lo = mid;
                else hi = mid;
            }

            if (maxExpArray[hi] >= x) return hi;
            if (maxExpArray[lo] >= x) return lo;

            revert("findPosition: x > max");
        }
    }

    /**
     * @dev Initialize internal data structure
     * Auto-generated via 'PrintMaxExpArray.py'
     */
    function initMaxExpArray() internal {
        //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
        //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
        //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
        //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
        //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
        //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
        //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
        //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
        //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
        //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
        //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
        //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
        //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
        //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
        //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
        //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
        //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
        //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
        //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
        //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
        //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
        //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
        //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
        //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
        //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
        //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
        //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
        //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
        //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
        //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
        //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
        //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    // auxiliary function
    function mulDivLog(
        uint256 x,
        uint256 y,
        uint256 z
    ) private pure returns (uint256) {
        return fixedLog(IntegralMath.mulDivF(x, y, z));
    }

    // auxiliary function
    function mulDivExp(
        uint256 x,
        uint256 y,
        uint256 z
    ) private view returns (uint256, uint256) {
        return fixedExp(IntegralMath.mulDivF(x, y, z));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title the math library contract for crowdfunding
/// @author abhi3700, hosokawa-zen
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked {
            c = a + b;
            assert(c >= a);
            return c;
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            assert(b <= a);
            return a - b;
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked {
            if (a == 0) return 0;
            c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            assert(b > 0);
            return a / b;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProjectToken {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Uint.sol";

library IntegralMath {
    /**
     * @dev Compute the largest integer smaller than or equal to the binary logarithm of `n`
     */
    function floorLog2(uint256 n) internal pure returns (uint8) {
        unchecked {
            uint8 res = 0;

            if (n < 256) {
                // at most 8 iterations
                while (n > 1) {
                    n >>= 1;
                    res += 1;
                }
            } else {
                // exactly 8 iterations
                for (uint8 s = 128; s > 0; s >>= 1) {
                    if (n >= 1 << s) {
                        n >>= s;
                        res |= s;
                    }
                }
            }

            return res;
        }
    }

    /**
     * @dev Compute the largest integer smaller than or equal to `x * y / z`
     */
    function mulDivF(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        unchecked {
            (uint256 xyh, uint256 xyl) = mul512(x, y);
            if (xyh == 0) {
                // `x * y < 2 ^ 256`
                return xyl / z;
            }
            if (xyh < z) {
                // `x * y / z < 2 ^ 256`
                uint256 m = mulMod(x, y, z); // `m = x * y % z`
                (uint256 nh, uint256 nl) = sub512(xyh, xyl, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`
                if (nh == 0) {
                    // `n < 2 ^ 256`
                    return nl / z;
                }
                uint256 p = unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
                uint256 q = div512(nh, nl, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
                uint256 r = inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
                return unsafeMul(q, r); // `q * r = (n / p) * inverse(z / p) = n / z`
            }
            revert("MATH: Overflow"); // `x * y / z >= 2 ^ 256`
        }
    }

    /**
     * @dev Compute the value of `x * y`
     */
    function mul512(uint256 x, uint256 y)
        private
        pure
        returns (uint256, uint256)
    {
        unchecked {
            uint256 p = mulModMax(x, y);
            uint256 q = unsafeMul(x, y);
            if (p >= q) return (p - q, q);
            return (unsafeSub(p, q) - 1, q);
        }
    }

    /**
     * @dev Compute the value of `2 ^ 256 * xh + xl - y`, where `2 ^ 256 * xh + xl >= y`
     */
    function sub512(
        uint256 xh,
        uint256 xl,
        uint256 y
    ) private pure returns (uint256, uint256) {
        unchecked {
            if (xl >= y) return (xh, xl - y);
            return (xh - 1, unsafeSub(xl, y));
        }
    }

    /**
     * @dev Compute the value of `(2 ^ 256 * xh + xl) / pow2n`, where `xl` is divisible by `pow2n`
     */
    function div512(
        uint256 xh,
        uint256 xl,
        uint256 pow2n
    ) private pure returns (uint256) {
        unchecked {
            uint256 pow2nInv = unsafeAdd(unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
            return unsafeMul(xh, pow2nInv) | (xl / pow2n); // `(xh << (256 - n)) | (xl >> n)`
        }
    }

    /**
     * @dev Compute the inverse of `d` modulo `2 ^ 256`, where `d` is congruent to `1` modulo `2`
     */
    function inv256(uint256 d) private pure returns (uint256) {
        unchecked {
            // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
            uint256 x = 1;
            for (uint256 i = 0; i < 8; ++i)
                x = unsafeMul(x, unsafeSub(2, unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
            return x;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAnalyticMath {
    /// @dev Compute (a / b) ^ (c / d)
    function powF(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d
    ) external view returns (uint256, uint256);

    // @dev calculate a * b / c
    function mulDivF(
        uint256 a,
        uint256 b,
        uint256 c
    ) external pure returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

uint256 constant MAX_VAL = type(uint256).max;

// does not revert on overflow
function unsafeAdd(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return x + y;
    }
}

// does not revert on overflow
function unsafeSub(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return x - y;
    }
}

// does not revert on overflow
function unsafeMul(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return x * y;
    }
}

// does not overflow
function mulModMax(uint256 x, uint256 y) pure returns (uint256) {
    unchecked {
        return mulmod(x, y, MAX_VAL);
    }
}

// does not overflow
function mulMod(
    uint256 x,
    uint256 y,
    uint256 z
) pure returns (uint256) {
    unchecked {
        return mulmod(x, y, z);
    }
}