/**
 *Submitted for verification at snowtrace.io on 2023-05-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface IERC20 {

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StakingWarmup {

    address public immutable staking;
    address public immutable sHentai;

    constructor ( address _staking, address _sHentai ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _sHentai != address(0) );
        sHentai = _sHentai;
    }

    function retrieve( address _staker, uint _amount ) external {
        require( msg.sender == staking );
        IERC20( sHentai ).transfer( _staker, _amount );
    }
}