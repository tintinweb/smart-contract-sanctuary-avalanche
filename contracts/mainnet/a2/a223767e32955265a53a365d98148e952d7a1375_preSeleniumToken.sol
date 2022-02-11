// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/* preSeleniumToken Presale
 After Presale you'll be able to swap this token for Selenium. Ratio 1:1
*/
contract preSeleniumToken is ERC20('preSeleniumToken', 'PRESELENIUM'), ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address  constant presaleAddress = 0xD904EF4Ca577D376D00F58314a2a7A0da0EcdE38;

    IERC20 public USDC = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    IERC20 preseleniumToken = IERC20(address(this));

    uint256 public salePrice = 2;

    uint256 public constant preseleniumMaximumSupply = 2000 * (10 ** 18); //2k

    uint256 public preseleniumRemaining = preseleniumMaximumSupply;

    uint256 public maxHardCap = 4000 * (10 ** 18); // 4k usdc

    uint256 public constant maxpreSeleniumPurchase = 200 * (10 ** 18); // 200 preselenium

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public constant presaleDuration = 279800; // 5 days aprox

    mapping(address => uint256) public userpreSeleniumTotally;

    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event preseleniumPurchased(address sender, uint256 usdcSpent, uint256 preseleniumReceived);

    constructor(uint256 _startBlock) {
        startBlock  = _startBlock;
        endBlock    = _startBlock + presaleDuration;
        _mint(address(this), preseleniumMaximumSupply);
    }

    function buypreSelenium(uint256 _usdcSpent) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(preseleniumRemaining > 0, "No more preSelenium remains!");
        require(preseleniumToken.balanceOf(address(this)) > 0, "No more preSelenium left!");
        require(_usdcSpent > 0, "not enough usdc provided");
        require(_usdcSpent <= maxHardCap, "preSelenium Presale hardcap reached");
        require(userpreSeleniumTotally[msg.sender] < maxpreSeleniumPurchase, "user has already purchased too much preselenium");

        uint256 preseleniumPurchaseAmount = (_usdcSpent * 1000000000000) / salePrice;

        // if we dont have enough left, give them the rest.
        if (preseleniumRemaining < preseleniumPurchaseAmount)
            preseleniumPurchaseAmount = preseleniumRemaining;

        require(preseleniumPurchaseAmount > 0, "user cannot purchase 0 preselenium");

        // shouldn't be possible to fail these asserts.
        assert(preseleniumPurchaseAmount <= preseleniumRemaining);
        assert(preseleniumPurchaseAmount <= preseleniumToken.balanceOf(address(this)));

        //send preselenium to user
        preseleniumToken.safeTransfer(msg.sender, preseleniumPurchaseAmount);
        // send usdc to presale address
    	USDC.safeTransferFrom(msg.sender, address(presaleAddress), _usdcSpent);

        preseleniumRemaining = preseleniumRemaining - preseleniumPurchaseAmount;
        userpreSeleniumTotally[msg.sender] = userpreSeleniumTotally[msg.sender] + preseleniumPurchaseAmount;

        emit preseleniumPurchased(msg.sender, _usdcSpent, preseleniumPurchaseAmount);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }

}