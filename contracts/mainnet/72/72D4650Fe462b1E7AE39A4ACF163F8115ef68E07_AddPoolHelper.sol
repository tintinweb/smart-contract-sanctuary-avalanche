pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ILendingRateOracle {
    function setMarketBorrowRate(address _asset, uint256 _rate) external;
    function transferOwnership(address newOwner) external;
}

interface IChefIncentivesController {
    function batchUpdateAllocPoint(
        address[] calldata _tokens,
        uint256[] calldata _allocPoints
    ) external;
    function poolLength() external view returns (uint256);
    function registeredTokens(uint256) external view returns (address);
    function transferOwnership(address newOwner) external;
}

interface ILendingPoolConfigurator {
    struct InitReserveInput {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        address incentivesController;
        uint256 allocPoint;
        string underlyingAssetName;
        string aTokenName;
        string aTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        string stableDebtTokenName;
        string stableDebtTokenSymbol;
        bytes params;
    }

    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;
    function batchInitReserve(InitReserveInput[] calldata input) external;
    function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external;
    function setReserveFactor(address asset, uint256 reserveFactor) external;
    function transferOwnership(address newOwner) external;
}


contract AddPoolHelper {

    ILendingPoolConfigurator public immutable configurator;
    ILendingRateOracle public immutable oracle;
    IChefIncentivesController public immutable chef;

    address public immutable owner;
    address public immutable newOwner;

    constructor(
        ILendingPoolConfigurator _configurator,
        ILendingRateOracle _oracle,
        IChefIncentivesController _chef,
        address _newOwner
    ) {
        configurator = _configurator;
        oracle = _oracle;
        chef = _chef;
        owner = msg.sender;
        newOwner = _newOwner;
    }

    function addPool(
        ILendingPoolConfigurator.InitReserveInput[] calldata input,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 borrowRate,
        uint256 lendAlloc
    ) external {
        require(msg.sender == owner);
        require(input.length == 1);
        address underlyingAsset = input[0].underlyingAsset;
        configurator.batchInitReserve(input);
        configurator.configureReserveAsCollateral(
            underlyingAsset,
            ltv,
            liquidationThreshold,
            liquidationBonus
        );
        configurator.enableBorrowingOnReserve(underlyingAsset, false);
        configurator.setReserveFactor(underlyingAsset, 5000);
        oracle.setMarketBorrowRate(underlyingAsset, borrowRate);

        address[] memory tokens = new address[](2);
        uint256 length = chef.poolLength();
        tokens[0] = chef.registeredTokens(length - 2);
        tokens[1] = chef.registeredTokens(length - 1);

        uint256[] memory allocPoints = new uint256[](2);
        allocPoints[0] = lendAlloc;
        allocPoints[1] = lendAlloc * 3;

        chef.batchUpdateAllocPoint(tokens, allocPoints);
    }

    function transferOwnership() external {
        require(msg.sender == owner);
        configurator.transferOwnership(newOwner);
        oracle.transferOwnership(newOwner);
        chef.transferOwnership(newOwner);
    }
}