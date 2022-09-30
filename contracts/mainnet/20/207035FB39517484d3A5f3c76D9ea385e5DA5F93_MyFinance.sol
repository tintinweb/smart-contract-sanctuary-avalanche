// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


import "./IPool.sol";
import "./IWETHGateway.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./Ownable.sol";
import "./IERC20.sol";

library Assets {
    function removeAsset(address[] storage _array, address _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
    function findAsset(address[] memory _array, address _element) internal pure returns (bool){
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                return true;
            }
        }
        return false;
    }
}

contract MyFinance is Ownable {
    using WadRayMath for uint256;
    using Assets for address [];
    IPool lendingPool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    IWETHGateway wethGateway = IWETHGateway(0xa938d8536aEed1Bd48f548380394Ab30Aa11B00E);

    address [] private assets ;

    address constant avaxToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //Wrapped AVAX
    address aAvaWAVAX = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

    mapping(address=>mapping(address=>Supply)) public deposits;

    struct Supply {
        uint256 Supply;
        uint256 aaveBalance;
    }

    mapping(address => bool) public charities;

    event Deposit(address indexed beneficiary, uint total, address asset);
    event DepositAVAX(address indexed beneficiary, uint total);
    event Withdrawal(address indexed beneficiary, address asset, address charity, uint percentage, uint totalRecovered, uint donation);
    event WithdrawalAVAX(address indexed beneficiary, address charity, uint percentage, uint totalRecovered, uint donation);

    constructor() {
        address daiToken = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
        address usdtToken = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
        address usdcToken = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

        _approveWG(aAvaWAVAX, 1e25);

        _approveLP(daiToken, 1e24);
        _approveLP(usdtToken, 1e12);
        _approveLP(usdcToken, 1e12);

        assets.push(daiToken);
        assets.push(usdtToken);
        assets.push(usdcToken);
    }

    function depositAVAX() public payable {
        require(msg.value > 0, "Invalid value");

        wethGateway.depositETH{value:msg.value}(address(lendingPool), address(this), 0);
        deposits[avaxToken][msg.sender].Supply += msg.value;
        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(avaxToken);
        uint256 index = reserve.liquidityIndex;
        deposits[avaxToken][msg.sender].aaveBalance += msg.value.rayDiv(index);

        emit DepositAVAX(msg.sender, msg.value);
    }

    function withdrawAmountAvax(address _charity, uint256 _percentage, uint256 amount) public {
        require(charities[_charity], "Invalid charity");
        require(_percentage >= 5 && _percentage <= 100, "Invalid percentage");
        require(deposits[avaxToken][msg.sender].Supply>= amount && amount > 0, "Invalid amount");
        
        uint256 supply = deposits[avaxToken][msg.sender].Supply;
        uint256 balance = getUserBalance(msg.sender, avaxToken);
        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(avaxToken);
        uint256 index = reserve.liquidityIndex;            
        uint256 _amount = amount.rayDiv(index);

        deposits[avaxToken][msg.sender].Supply -= amount;
        deposits[avaxToken][msg.sender].aaveBalance -= _amount;

        uint256 interests = (balance - supply) * amount / supply;
        uint256 donation = interests * _percentage / 100;
        uint256 earnings = amount + (interests - donation);
        wethGateway.withdrawETH(address(lendingPool), (amount + interests), address(this));

        if (donation > 0) {
            (bool sent, bytes memory data) = _charity.call{value: donation}("");
            require(sent, "Failed to send Ether");
        }

        if (earnings > 0) {
            require(payable(msg.sender).send(earnings), 'Could not transfer tokens');
        }

        emit WithdrawalAVAX(msg.sender, _charity, _percentage, (amount + interests), donation);
    }
    
    function depositAsset(uint256 _amount, address _asset) public {
        require(assets.findAsset(_asset), "Asset is not implemented");
        require(IERC20(_asset).transferFrom(msg.sender, address(this), _amount), 'Could not transfer tokens');
        
        lendingPool.supply(_asset, _amount, address(this), 0);
        deposits[_asset][msg.sender].Supply += _amount;
        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(_asset);
        uint256 index = reserve.liquidityIndex;
        deposits[_asset][msg.sender].aaveBalance += _amount.rayDiv(index);
        
        emit Deposit(msg.sender, _amount, _asset);
    }

    function withdrawAsset(address _charity, uint256 _percentage, uint256 amount, address _asset) public {
        require(assets.findAsset(_asset), "Asset is not implemented");

        require(charities[_charity], "Invalid charity");
        require(_percentage >= 5 && _percentage <= 100, "Invalid percentage");
        require(deposits[_asset][msg.sender].Supply>= amount && amount > 0, "Invalid amount");
        
        uint256 supply = deposits[_asset][msg.sender].Supply;
        uint256 balance = getUserBalance(msg.sender, _asset);
        DataTypes.ReserveData memory reserve = lendingPool.getReserveData(_asset);
        uint256 index = reserve.liquidityIndex;            
        uint256 _amount = amount.rayDiv(index);
        deposits[_asset][msg.sender].Supply -= amount;
        deposits[_asset][msg.sender].aaveBalance -= _amount; 
        uint256 interests = (balance - supply) * amount / supply;
        uint256 donation = interests * _percentage / 100;
        uint256 earnings = (interests - donation) + amount;
        uint256 total = amount + interests;
        lendingPool.withdraw(_asset, total, address(this));

        if (donation > 0) {
            require(IERC20(_asset).transfer(_charity, donation), 'Could not transfer tokens');
        }
        if (earnings > 0) {
            require(IERC20(_asset).transfer(msg.sender, earnings), 'Could not transfer tokens');
        }

        emit Withdrawal(msg.sender, _asset, _charity, _percentage, total, donation);
    }

    function getUserBalance(address _user, address _asset) public view returns(uint256) {
        require(assets.findAsset(_asset), "Asset is not implemented");

        uint256 initial = deposits[_asset][_user].aaveBalance;
        return initial.rayMul(getPoolReserve(_asset));
    }

    function getPoolReserve(address _asset) public view returns (uint256) {
        return lendingPool.getReserveNormalizedIncome(_asset);
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

    function addAsset(address _asset, uint256 _amount) public onlyOwner {
        require(!assets.findAsset(_asset), "Asset already existing");
        assets.push(_asset);
        _approveLP(_asset,_amount);
    }

    function removeAsset(address _asset) public onlyOwner {
        assets.removeAsset(_asset);
    }
    
    function getAssets() public view returns ( address[] memory) {
        return assets;
    }
    
    receive() external payable {}
}