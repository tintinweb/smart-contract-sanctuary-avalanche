// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibCFDiamond} from "./libraries/LibCFDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

/// @title A upgradable and pausable crowdfunding contract for every project
/// @author abhi3700, hosokawa-zen
/// @notice You can use this contract as a template for every crowdfunding project
contract CFDiamond is IDiamondCut {
    // Crowdfunding diamond constructor
    /// @dev initialize crowdfunding data
    /// @param _pName : the project name
    /// @param _coinAddr : the funding token(project coin) address
    /// @param _stAddr : the investing stable coin address
    /// @param _pOFeePt : the project owner fee percent (10000> fee >0)
    /// @param _bufferPeriod : the buffer period of crowdfunding in seconds
    /// @param _conversionPeriod : the conversion period of crowdfunding in seconds
    /// @param _minTh : the min.funding threshold of crowdfunding
    /// @param _treasuryAddr: the treasury address (the address withdrawing protocol fee)
    /// @param _analyticMathAddr: the deployed `AnalyticMath` contract`s address
    constructor(
        string memory _pName,
        address _coinAddr,
        address _stAddr,
        uint16 _pOFeePt,
        uint256 _bufferPeriod,
        uint256 _conversionPeriod,
        uint256 _minTh,
        address _treasuryAddr,
        address _analyticMathAddr
    ) {
        LibCFDiamond.setContractOwner(msg.sender);
        LibCFDiamond.setCrowdfunding(
            _pName,
            _coinAddr,
            _stAddr,
            _pOFeePt,
            _bufferPeriod,
            _conversionPeriod,
            _minTh,
            _treasuryAddr
        );
        LibCFDiamond.setAnalyticMath(_analyticMathAddr);
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
import "./Strings.sol";
import "./SafeMath.sol";
import {ProjectToken} from "../ProjectToken.sol";

library LibCFDiamond {
    using SafeMath for uint256;
    using Strings for string;

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

    // Funding Data Structure For Every Investor
    struct FundData {
        uint256 ptAmt;
        uint256 stableCoinAmt;
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
        /// Mapping of investor`s address => FundData
        mapping(address => FundData) contributionsMap;
        /// Total deposited stableCoins
        uint256 totalStableCoinAmt;
        /// coin`s address => Project Fee Amount
        uint256 projectFeeAmt;
        /// coin`s address => Protocol Fee Amount
        uint256 protocolFeeAmt;
        // Project Token
        address projectToken;
        // Address of the deployed Project Coin contract
        address projectCoinAddr;
        // Funding Project Coin`s Supply Amount
        uint256 allocatedPCAmt;
        // THEIA treasury address
        address treasuryAddress;
        // MIN. Funding Threshold
        uint256 minFundingThreshold;
        // GMT timestamp of when the crowdfund starts
        uint256 startTimestamp;
        // GMT timestamp of when reached to min.threshold
        uint256 tpTimestamp;
        // buffer time from min.threshold point to CP
        uint256 bufferPeriod;
        // Crowdfunding Conversion Period
        uint256 conversionPeriod;
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
        mapping(uint256 => uint256) dailyReleaseAmt;
        // Unclaimed PC Amount
        uint256 claimedPCAmt;
        // Created timestamp of CF
        uint256 createdTimestamp;
        // market fee percent
        uint256 marketFeePt;
        // market fee amount
        uint256 marketFeeAmt;
        // market address
        address market;

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
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: NOT_OWNER"
        );
    }

    // The contract must be paused.
    function whenPaused() internal view {
        require(diamondStorage()._paused, "Pausable: not paused");
    }

    // The contract must not be paused.
    function whenNotPaused() internal view {
        require(!diamondStorage()._paused, "Pausable: paused");
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
                revert("LibDiamond: INCORRECT_ACTION");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamond: NO_SELECTORS");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamond: ZERO_FACET_ADDRESS");
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
                oldFacetAddress == address(0),
                "LibDiamond: FUNCTION_EXIST"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamond: NO_SELECTORS");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamond: ZERO_FACET_ADDRESS");
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
        require(_functionSelectors.length > 0, "LibDiamond: NO_SELECTORS");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamond: ZERO_FACET_ADDRESS");
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
        enforceHasContractCode(_facetAddress, "LibDiamond: NO_CODE");
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
        require(_facetAddress != address(0), "LibDiamond: FUNCTION_NOT_EXIST");
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamond: IMMUTABLE_FUNCTION"
        );
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
            require(_calldata.length == 0, "LibDiamond: CALLDATA_NOT_EMPTY");
        } else {
            require(_calldata.length > 0, "LibDiamond: CALLDATA_EMPTY");
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamond: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamond: INIT_REVERTED");
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
        require(ds.startTimestamp > 0, "CF: NOT_STARTED");
        require(
            ds.tpTimestamp == 0 ||
                block.timestamp <
                ds.tpTimestamp.add(ds.bufferPeriod).add(ds.conversionPeriod),
            "CF: NOT_ONGOING"
        );
    }

    // Crowdfunding is active when project owner sends enough project coins to funding contracts
    function isActiveCF() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.allocatedPCAmt > 0, "CF: CF_NOT_ACTIVE");
    }

    // Ensure actions can only happen when funding threshold is reached
    function isReachedToTh() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(
            ds.totalStableCoinAmt >= ds.minFundingThreshold,
            "CF: NOT_REACHED_MIN_THRESHOLD"
        );
    }

    // Ensure actions can only happen while crowdfund is ongoing in CP
    function isConversionPeriod() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.tpTimestamp > 0, "CF: NOT_REACHED_MIN_TP");
        require(
            block.timestamp >= ds.tpTimestamp.add(ds.bufferPeriod) &&
                block.timestamp <
                ds.tpTimestamp.add(ds.bufferPeriod).add(ds.conversionPeriod),
            "CF: NOT_IN_CP"
        );
    }

    // Ensure actions can only happen while crowdfund is going after Buffer Time Period
    function isAfterBP() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.tpTimestamp > 0, "CF: NOT_REACHED_MIN_TP");
        require(
            block.timestamp >= ds.tpTimestamp.add(ds.bufferPeriod),
            "CF: NOT_ENDED_BP"
        );
    }

    // Ensure actions can only happen when funding is ended
    function isEndOfCF() internal view {
        DiamondStorage storage ds = diamondStorage();
        require(ds.tpTimestamp > 0, "CF: NOT_REACHED_MIN_TP");
        require(
            block.timestamp >=
                ds.tpTimestamp.add(ds.bufferPeriod).add(ds.conversionPeriod),
            "CF: NOT_ENDED"
        );
    }

    // Ensure actions can only happen when Bond Investment is activated
    function isActiveBondInv() internal view {
        require(
            diamondStorage().bondToken != address(0),
            "CF: BI_NOT_ACTIVATED"
        );
    }

    /// @param _pName                   Project Name
    /// @param _coinAddr                Funding Token Address
    /// @param _stAddr                  Stable Coin`s Address
    /// @param _pOFeePt                 Project Owner`s Fee
    /// @param _bfTime                  BUFFER PERIOD TIME
    /// @param _conversionPeriod        CONVERSION PERIOD TIME
    /// @param _minTh                   MIN.Threshold
    /// @param _treasuryAddr            TREASURY ADDRESS
    function setCrowdfunding(
        string memory _pName,
        address _coinAddr,
        address _stAddr,
        uint16 _pOFeePt,
        uint256 _bfTime,
        uint256 _conversionPeriod,
        uint256 _minTh,
        address _treasuryAddr
    ) internal {
        require(_pName.length() > 2, "CF: NAME_MIN_3");
        require(_pName.length() < 13, "CF: NAME_MAX_12");
        require(_pOFeePt < LibCFDiamond.PERCENT_DIVISOR, "CF: INVALID_PERCENT");
        // Min: One Week 3600 * 24 * 7
        require(_conversionPeriod >= 604800, "CF: CP_TIME>A_WEEK");
        require(_minTh > 0, "CF: MIN.THRESHOLD>0");
        require(_treasuryAddr != address(0), "CF: ZERO_TREASURY_ADDRESS");

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
        ds.bufferPeriod = _bfTime;
        ds.conversionPeriod = _conversionPeriod;

        // Set Min.Threshold
        ds.minFundingThreshold = _minTh;

        // Set created timestamp
        ds.createdTimestamp = block.timestamp;
    }

    // Set Bonding Curve
    function setAnalyticMath(address _analyticMath) internal {
        require(_analyticMath != address(0), "CF: ZERO_PO_ADDRESS");

        DiamondStorage storage ds = diamondStorage();
        ds.analyticMath = _analyticMath;
    }

    // Apply Project Owner Fee and Protocol Fee
    function _applyFee(uint256 _coinAmt) internal returns (uint256 totalFee) {
        DiamondStorage storage ds = diamondStorage();
        // Protocol Fee during investment
        uint256 _feeAmt = _coinAmt.mul(ds.protocolFeePercent1).div(
            PERCENT_DIVISOR
        );
        ds.protocolFeeAmt = ds.protocolFeeAmt.add(_feeAmt);
        totalFee = totalFee.add(_feeAmt);

        // Project Owner Fee during investment
        _feeAmt = _coinAmt.mul(ds.projectFeePercent1).div(PERCENT_DIVISOR);
        ds.projectFeeAmt = ds.projectFeeAmt.add(_feeAmt);
        totalFee = totalFee.add(_feeAmt);

        // Project Owner Fee during investment
        if (ds.marketFeePt > 0) {
            _feeAmt = _coinAmt.mul(ds.marketFeePt).div(PERCENT_DIVISOR);
            ds.marketFeeAmt = ds.marketFeeAmt.add(_feeAmt);
            totalFee = totalFee.add(_feeAmt);
        }
    }

    // Get Claimable Project Token Amount In CP and Ending of CF
    function getReleasedPCAmt(uint256 _curDay, uint256 _totalDays)
        internal
        view
        returns (uint256)
    {
        // First Week can not release
        if (_curDay == 0) {
            return 0;
        }

        DiamondStorage storage ds = diamondStorage();

        // Next Week Claimable PT Amount In Conversion Period
        if (_curDay < _totalDays) {
            // Get Release PT Amount of Current Week
            return ds.dailyReleaseAmt[_curDay - 1];
        }
        // Default
        return ds.allocatedPCAmt;
    }

    // Generate Random PC release per week
    function generatePCRelease(uint256[] memory rates, uint256 total) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 pastRelease = 0;
        for (uint256 i = 0; i < rates.length; i++) {
            // Set Weekly Releasable PC Percent
            ds.dailyReleaseAmt[i] =
                pastRelease +
                (rates[i] * ds.allocatedPCAmt) /
                total;
            pastRelease = ds.dailyReleaseAmt[i];
        }
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

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
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
        c = a + b;
        assert(c >= a);
        return c;
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
        assert(b <= a);
        return a - b;
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
        if (a == 0) return 0;
        c = a * b;
        assert(c / a == b);
        return c;
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
        assert(b > 0);
        return a / b;
    }
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
    mapping(address => mapping(address => uint256)) internal _allowances;

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

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _mint(address to, uint256 value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        onlyOwner
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override onlyOwner returns (bool) {
        if (_allowances[from][msg.sender] != type(uint256).max) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        require(amount > 0, "ERC20: mint amount zero");
        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external override onlyOwner {
        require(amount > 0, "ERC20: burn amount zero");
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * _allowances.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have _allowances for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount)
        external
        override
        onlyOwner
    {
        uint256 currentAllowance = _allowances[account][_msgSender()];
        require(currentAllowance >= amount, "PT: EXCEEDS_ALLOWANCE");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address to, uint256 value) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
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