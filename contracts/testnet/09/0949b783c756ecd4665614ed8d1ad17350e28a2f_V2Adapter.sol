import "./core.sol";
import "./aave.sol";
import "./atoken.sol";

contract V2Adapter {
    address public constant aave = 0x76cc67FF2CC77821A70ED14321111Ce381C2594D;
    function depositDelegate(address token, uint256 amount) public {
        Core(address(this)).Approve(token, address(aave), amount);
        IAaveLendingPool(aave).deposit(token, amount, address(this), 0);
    }

    function depositCall(address token, uint256 amount) public {
        Core(address(msg.sender)).Transfer(token, address(this), amount);
        IAToken(token).approve(address(aave), amount);
        IAaveLendingPool(aave).deposit(token, amount, msg.sender, 0);
    }
}

import "./atoken.sol";

contract Core {
    function CallFunction(address a,bytes calldata args) public {
        a.call(args);
    }
    function DelegateCall(address a,bytes calldata args) public {
        a.delegatecall(args);
    }
    function Approve(address a, address target,uint256 amount) public {
        IAToken(a).approve(target, amount);
    }

    function Transfer(address a, address target,uint256 amount) public {
        IAToken(a).transfer(target, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

interface IAToken {
    function balanceOf(address _user) external view returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function POOL() external view returns (address);

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint256);
}

interface IAaveLendingPool {
    function deposit(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        uint16 _referralCode
    ) external;

    function withdraw(
        address _asset,
        uint256 _amount,
        address _to
    ) external;
}