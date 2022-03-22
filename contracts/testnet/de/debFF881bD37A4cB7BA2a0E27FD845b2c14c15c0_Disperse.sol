/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-21
*/

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity 0.8.3;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address provider) external view returns (uint256);
}

contract Disperse {
    mapping(address => uint256) public lastDistributed;
    uint256 interval = 7 days;
    address public owner;
    uint256 public usdcPerUser = 2000 ether;
    uint256 public ethPerUser = 1 ether;
    uint256 public btcPerUser = 1 ether;
    uint256 public nativePerUser = 0.2 ether;

    modifier onlyOwner() {
        require(msg.sender == owner, "caller has no access");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function disperseToken(IERC20[] calldata token, address[] calldata recipients) external {
        uint256 usdcTotal = 0;
        uint256 nativeTotal = 0;
        uint256 ethTotal = 0;
        uint256 btcTotal = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            usdcTotal += usdcPerUser;
            nativeTotal += nativePerUser;
            ethTotal += ethPerUser;
            btcTotal += btcPerUser;
        }
        require(token[0].balanceOf(address(this)) >= usdcTotal, "insufficient usdc in contract");
        require(address(this).balance >= nativeTotal, "insufficient native token in contract");
        require(token[1].balanceOf(address(this)) >= ethTotal, "insufficient oddz in contract");
        require(token[1].balanceOf(address(this)) >= btcTotal, "insufficient oddz in contract");
        for (uint256 i = 0; i < recipients.length; i++) {
            if (lastDistributed[recipients[i]] + interval <= block.timestamp) {
                require(token[0].transfer(recipients[i], usdcPerUser), "cannot transfer usdc"); // usdc
                payable(recipients[i]).transfer(nativePerUser); // avax
                require(token[1].transfer(recipients[i], ethPerUser), "cannot transfer ether"); // ether
                require(token[2].transfer(recipients[i], btcPerUser), "cannot transfer btc");
                lastDistributed[recipients[i]] = block.timestamp;
            }
        }
    }

    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), "invalid address");
        owner = _owner;
    }

    function setTotalUsdcPerUser(uint256 _amount) public onlyOwner {
        usdcPerUser = _amount;
    }

    function setTotalNativePerUser(uint256 _amount) public onlyOwner {
        nativePerUser = _amount;
    }

    function setTotalEtherPerUser(uint256 _amount) public onlyOwner {
        ethPerUser = _amount;
    }

    function setTotalBtcPerUser(uint256 _amount) public onlyOwner {
        btcPerUser = _amount;
    }

    receive() external payable {}
}