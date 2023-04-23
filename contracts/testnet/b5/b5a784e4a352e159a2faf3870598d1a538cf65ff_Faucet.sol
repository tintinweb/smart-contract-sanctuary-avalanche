/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Faucet {
    mapping(address => uint256) private _lastRequest;
    IERC20 private _token1;
    IERC20 private _token2;
    IERC20 private _token3;
    uint256 private constant _requestInterval = 24 hours;
    uint256 private constant _tokensToRelease = 1000*1e18;

    constructor(address token1, address token2, address token3) {
        _token1 = IERC20(token1);
        _token2 = IERC20(token2);
        _token3 = IERC20(token3);
    }

    function requestTokens() external {
        require(_lastRequest[msg.sender] + _requestInterval <= block.timestamp, "You can only request tokens once every 24 hours");
        _lastRequest[msg.sender] = block.timestamp;

        uint256 balance1 = _token1.balanceOf(address(this));
        uint256 balance2 = _token2.balanceOf(address(this));
        uint256 balance3 = _token3.balanceOf(address(this));

        require(balance1 >= _tokensToRelease && balance2 >= _tokensToRelease && balance3 >= _tokensToRelease, "Faucet is empty");

        _token1.transfer(msg.sender, _tokensToRelease);
        _token2.transfer(msg.sender, _tokensToRelease);
        _token3.transfer(msg.sender, _tokensToRelease);
    }
}