/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-13
*/

// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IMinter {

    function getUSD() external payable ;
    
    function getQLTOken(uint256 amount) external;
}

contract getAVAX {

    address private immutable addOfMinter;
    IERC20 private  immutable usdtql;
    IERC20 private immutable qlt;

    constructor(address _addOfMinter, address _usdtql, address _qlt) {
        addOfMinter = _addOfMinter;
        usdtql = IERC20(_usdtql);
        qlt = IERC20(_qlt);
    }

    function receiveToken() public payable {

        IMinter minter = IMinter(addOfMinter);
        uint256 amount = msg.value * 100 * 1e18;

        minter.getUSD{value:msg.value}();
        usdtql.approve(addOfMinter, amount);

        minter.getQLTOken(amount);
        qlt.transfer(msg.sender, amount);
    }
}