// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


import "./preArsenicToken.sol";

contract preArsenicDream is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    preArsenicToken public immutable  prearsenicToken;

    IERC20 public immutable ARSENICToken;

    address  arsenicAddress;

    bool  hasBurnedUnsoldPresale;

    uint256 public startBlock;

    event preArsenicToArsenic(address sender, uint256 amount);
    event burnUnclaimedARSENIC(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _prearsenicAddress, address _arsenicAddress) {
        require(_prearsenicAddress != _arsenicAddress, "prearsenic cannot be equal to arsenic");
        startBlock = _startBlock;
        prearsenicToken = preArsenicToken(_prearsenicAddress);
        ARSENICToken = IERC20(_arsenicAddress);
    }

    function swappreArsenicForARSENIC() external nonReentrant {
        require(block.number >= startBlock, "prearsenic still awake.");

        uint256 swapAmount = prearsenicToken.balanceOf(msg.sender);
        require(ARSENICToken.balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        require(prearsenicToken.transferFrom(msg.sender, BURN_ADDRESS, swapAmount), "failed sending prearsenic" );
        ARSENICToken.safeTransfer(msg.sender, swapAmount);

        emit preArsenicToArsenic(msg.sender, swapAmount);
    }

    function sendUnclaimedARSENICToDeadAddress() external onlyOwner {
        require(block.number > prearsenicToken.endBlock(), "can only send excess prearsenic to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(prearsenicToken.prearsenicRemaining() <= ARSENICToken.balanceOf(address(this)),
            "burning too much arsenic, check again please");

        if (prearsenicToken.prearsenicRemaining() > 0)
            ARSENICToken.safeTransfer(BURN_ADDRESS, prearsenicToken.prearsenicRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedARSENIC(prearsenicToken.prearsenicRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if presale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }

}