// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./Ownable.sol";

import "./SafeERC20.sol";
import "./SafeMath.sol";

contract RewardPool is Ownable {
    using SafeMath for uint256;

    address public UNODE;
    address public treasury;

	mapping(address => bool) public _managers;

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    constructor (
        address _UNODE,
        address _treasury
    ) {
		_managers[msg.sender] = true;

        require(_UNODE != address(0), "Zero Address");
        UNODE = _UNODE;

        require(_treasury != address(0), "Zero Address");
        treasury = _treasury;
    }

	function addManager(address manager) external onlyManager {
		_managers[manager] = true;
	}

	function removeManager(address manager) external onlyManager {
		_managers[manager] = false;
	}

    function setUNODEAddress(address _UNODE) external onlyOwner {
        require(_UNODE != address(0), "Zero Address");
        UNODE = _UNODE;
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero Address");
        treasury = _treasury;
    }

    function rewardTo(address _account, uint256 _rewardAmount) external onlyManager {
        require(IERC20(UNODE).balanceOf(address(this)) > _rewardAmount, "Insufficient Balance");

        SafeERC20.safeTransfer(IERC20(UNODE), _account, _rewardAmount);
    }

    function withdrawToken() external onlyManager {
        uint256 balance = IERC20(UNODE).balanceOf(address(this));

        require (balance > 0, "Insufficient Balance");
        SafeERC20.safeTransfer(IERC20(UNODE), treasury, balance);
    }
}