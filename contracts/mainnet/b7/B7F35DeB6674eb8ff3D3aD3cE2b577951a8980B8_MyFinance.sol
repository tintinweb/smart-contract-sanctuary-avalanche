// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import "./IPool.sol";
import "./IWETHGateway.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./Ownable.sol";
import "./IERC20.sol";


contract MyFinance is Ownable {
    using WadRayMath for uint256;

    IPool lendingPool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    IWETHGateway wethGateway = IWETHGateway(0xa938d8536aEed1Bd48f548380394Ab30Aa11B00E);

    address constant avaxToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //Wrapped AVAX
    address constant daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address constant usdtToken = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address constant usdcToken = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    address aAvaWAVAX = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

    mapping(address=>Supply) public avaxDeposits;
    mapping(address=>Supply) public daiDeposits;
    mapping(address=>Supply) public usdtDeposits;
    mapping(address=>Supply) public usdcDeposits;

    struct Supply {
        uint256 initialSupply;
        uint256 aaveInitialBalance;
    }

    mapping(address => bool) public charities;

    event Deposit(address indexed beneficiary, uint total, address asset);
    event DepositAVAX(address indexed beneficiary, uint total);
    event Withdrawal(address indexed beneficiary, uint totalRequested, address asset, address charity, uint percentage, uint totalRecovered, uint donation);
    event WithdrawalAVAX(address indexed beneficiary, uint totalRequested, address charity, uint percentage, uint totalRecovered, uint donation);

    constructor() {
        _approveWG(aAvaWAVAX, 1e25);
        _approveLP(daiToken, 1e24);
        _approveLP(usdtToken, 1e12);
        _approveLP(usdcToken, 1e12);
    }

    function depositAVAX() public payable {
        require(msg.value > 0, "Invalid value");

        wethGateway.depositETH{value:msg.value}(address(lendingPool), address(this), 0);

        avaxDeposits[msg.sender].initialSupply += msg.value;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(avaxToken);
        uint256 index = reserve.liquidityIndex;

        avaxDeposits[msg.sender].aaveInitialBalance += msg.value.rayDiv(index);

        emit DepositAVAX(msg.sender, msg.value);
    }
    
    function withdrawAVAX(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage >= 5 && _percentage <= 100, "Invalid percentage");
        require(avaxDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");

        uint256 totalToRecover = getUserAVAXBalance(msg.sender);
        uint256 initialSupply = avaxDeposits[msg.sender].initialSupply;

        avaxDeposits[msg.sender].initialSupply = 0;
        avaxDeposits[msg.sender].aaveInitialBalance = 0;

        uint256 originalBalance = address(this).balance;
        wethGateway.withdrawETH(address(lendingPool), totalToRecover, address(this));
        uint256 recovered = address(this).balance - originalBalance;

        uint256 interests = recovered - initialSupply;
        uint256 donation = interests * _percentage / 100;
        uint256 earnings = recovered - donation;

        if (donation > 0) {
            (bool sent, bytes memory data) = _charity.call{value: donation}("");
            require(sent, "Failed to send Ether");
        }

        if (earnings > 0) {
            require(payable(msg.sender).send(earnings), 'Could not transfer tokens');
        }

        emit WithdrawalAVAX(msg.sender, totalToRecover, _charity, _percentage, recovered, donation);
    }

    function depositDAI(uint256 _amount) public {
        _deposit(_amount, daiToken);

        daiDeposits[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(daiToken);
        uint256 index = reserve.liquidityIndex;

        daiDeposits[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }
    
    function withdrawDAI(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage >= 5 && _percentage <= 100, "Invalid percentage");
        require(daiDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");

        uint256 totalToRecover = getUserDAIBalance(msg.sender);
        uint256 initialSupply = daiDeposits[msg.sender].initialSupply;

        daiDeposits[msg.sender].initialSupply = 0;
        daiDeposits[msg.sender].aaveInitialBalance = 0;

        _withdraw(totalToRecover, initialSupply, daiToken, _charity, _percentage);
    }

    function depositUSDT(uint256 _amount) public {
        _deposit(_amount, usdtToken);

        usdtDeposits[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(usdtToken);
        uint256 index = reserve.liquidityIndex;

        usdtDeposits[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }

    function withdrawUSDT(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage >= 5 && _percentage <= 100, "Invalid percentage");
        require(usdtDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");

        uint256 totalToRecover = getUserUSDTBalance(msg.sender);
        uint256 initialSupply = usdtDeposits[msg.sender].initialSupply;
        
        usdtDeposits[msg.sender].initialSupply = 0;
        usdtDeposits[msg.sender].aaveInitialBalance = 0;

        _withdraw(totalToRecover, initialSupply, usdtToken, _charity, _percentage);
    }

    function depositUSDC(uint256 _amount) public {
        _deposit(_amount, usdcToken);

        usdcDeposits[msg.sender].initialSupply += _amount;

        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(usdcToken);
        uint256 index = reserve.liquidityIndex;

        usdcDeposits[msg.sender].aaveInitialBalance += _amount.rayDiv(index);
    }

    function withdrawUSDC(address _charity, uint256 _percentage) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage >= 5 && _percentage <= 100, "Invalid percentage");
        require(usdcDeposits[msg.sender].initialSupply > 0, "Nothing to withdraw");
        
        uint256 totalToRecover = getUserUSDCBalance(msg.sender);
        uint256 initialSupply = usdcDeposits[msg.sender].initialSupply;

        usdcDeposits[msg.sender].initialSupply = 0;
        usdcDeposits[msg.sender].aaveInitialBalance = 0;

        _withdraw(totalToRecover, initialSupply, usdcToken, _charity, _percentage);
    }

    function getUserAVAXBalance(address _user) public view returns(uint256) {
        uint256 initial = avaxDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, avaxToken);
    }

    function getUserDAIBalance(address _user) public view returns(uint256) {
        uint256 initial = daiDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, daiToken);
    }

    function getUserUSDTBalance(address _user) public view returns(uint256) {
        uint256 initial = usdtDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, usdtToken);
    }

    function getUserUSDCBalance(address _user) public view returns(uint256) {
        uint256 initial = usdcDeposits[_user].aaveInitialBalance;
        return getAAVEBalance(initial, usdcToken);
    }

    function getAAVEBalance(uint256 _initial, address _asset) public view returns (uint256) {
        return _initial.rayMul(getPoolReserve(_asset));
    }

    function getPoolReserve(address _asset) public view returns (uint256) {
        return lendingPool.getReserveNormalizedIncome(_asset);
    }

    function _deposit(uint256 _amount, address _token) internal {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        lendingPool.supply(_token, _amount, address(this), 0);

        emit Deposit(msg.sender, _amount, _token);
    }

    function _withdraw(uint256 _depositedPlusInterests, uint256 _initialSupply, address _token, address _charity, uint256 _percentage) internal {
        uint256 recovered = lendingPool.withdraw(_token, _depositedPlusInterests, address(this));
        uint256 interests = recovered - _initialSupply;
        uint256 donation = interests * _percentage / 100;
        uint256 earnings = recovered - donation;

        if (donation > 0) {
            require(IERC20(_token).transfer(_charity, donation), 'Could not transfer tokens');
        }

        if (earnings > 0) {
            require(IERC20(_token).transfer(msg.sender, earnings), 'Could not transfer tokens');
        }

        emit Withdrawal(msg.sender, _depositedPlusInterests, _token, _charity, _percentage, recovered, donation);
    }

    function _approveLP(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(lendingPool), _amount);
    }

    function _approveWG(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).approve(address(wethGateway), _amount);
    }

    function _enableCharity(address _charity, bool _enabled) public onlyOwner {
        charities[_charity] = _enabled;
    }

    receive() external payable {}
}