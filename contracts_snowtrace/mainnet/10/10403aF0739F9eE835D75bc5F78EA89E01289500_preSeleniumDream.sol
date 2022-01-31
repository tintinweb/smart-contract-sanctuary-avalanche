// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


import "./preSeleniumToken.sol";

contract preSeleniumDream is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    preSeleniumToken public immutable  preseleniumToken;

    IERC20 public immutable SELENIUMToken;

    address  seleniumAddress;

    bool  hasBurnedUnsoldPresale;

    uint256 public startBlock;

    event preSeleniumToSelenium(address sender, uint256 amount);
    event burnUnclaimedSELENIUM(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _preseleniumAddress, address _seleniumAddress) {
        require(_preseleniumAddress != _seleniumAddress, "preselenium cannot be equal to selenium");
        startBlock = _startBlock;
        preseleniumToken = preSeleniumToken(_preseleniumAddress);
        SELENIUMToken = IERC20(_seleniumAddress);
    }

    function swappreSeleniumForSELENIUM() external nonReentrant {
        require(block.number >= startBlock, "preselenium still awake.");

        uint256 swapAmount = preseleniumToken.balanceOf(msg.sender);
        require(SELENIUMToken.balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        require(preseleniumToken.transferFrom(msg.sender, BURN_ADDRESS, swapAmount), "failed sending preselenium" );
        SELENIUMToken.safeTransfer(msg.sender, swapAmount);

        emit preSeleniumToSelenium(msg.sender, swapAmount);
    }

    function sendUnclaimedSELENIUMToDeadAddress() external onlyOwner {
        require(block.number > preseleniumToken.endBlock(), "can only send excess preselenium to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(preseleniumToken.preseleniumRemaining() <= SELENIUMToken.balanceOf(address(this)),
            "burning too much selenium, check again please");

        if (preseleniumToken.preseleniumRemaining() > 0)
            SELENIUMToken.safeTransfer(BURN_ADDRESS, preseleniumToken.preseleniumRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedSELENIUM(preseleniumToken.preseleniumRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if presale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }

}