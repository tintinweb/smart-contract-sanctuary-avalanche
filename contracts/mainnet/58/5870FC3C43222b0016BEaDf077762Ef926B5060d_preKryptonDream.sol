// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;


import "./preKryptonToken.sol";

contract preKryptonDream is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    preKryptonToken public immutable  prekryptonToken;

    IERC20 public immutable KRYPTONToken;

    address  kryptonAddress;

    bool  hasBurnedUnsoldPresale;

    uint256 public startBlock;

    event preKryptonToKrypton(address sender, uint256 amount);
    event burnUnclaimedKRYPTON(uint256 amount);
    event startBlockChanged(uint256 newStartBlock);

    constructor(uint256 _startBlock, address _prekryptonAddress, address _kryptonAddress) {
        require(_prekryptonAddress != _kryptonAddress, "prekrypton cannot be equal to krypton");
        startBlock = _startBlock;
        prekryptonToken = preKryptonToken(_prekryptonAddress);
        KRYPTONToken = IERC20(_kryptonAddress);
    }

    function swappreKryptonForKRYPTON() external nonReentrant {
        require(block.number >= startBlock, "prekrypton still awake.");

        uint256 swapAmount = prekryptonToken.balanceOf(msg.sender);
        require(KRYPTONToken.balanceOf(address(this)) >= swapAmount, "Not Enough tokens in contract for swap");
        require(prekryptonToken.transferFrom(msg.sender, BURN_ADDRESS, swapAmount), "failed sending prekrypton" );
        KRYPTONToken.safeTransfer(msg.sender, swapAmount);

        emit preKryptonToKrypton(msg.sender, swapAmount);
    }

    function sendUnclaimedKRYPTONToDeadAddress() external onlyOwner {
        require(block.number > prekryptonToken.endBlock(), "can only send excess prekrypton to dead address after presale has ended");
        require(!hasBurnedUnsoldPresale, "can only burn unsold presale once!");

        require(prekryptonToken.prekryptonRemaining() <= KRYPTONToken.balanceOf(address(this)),
            "burning too much krypton, check again please");

        if (prekryptonToken.prekryptonRemaining() > 0)
            KRYPTONToken.safeTransfer(BURN_ADDRESS, prekryptonToken.prekryptonRemaining());
        hasBurnedUnsoldPresale = true;

        emit burnUnclaimedKRYPTON(prekryptonToken.prekryptonRemaining());
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if presale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit startBlockChanged(_newStartBlock);
    }

}