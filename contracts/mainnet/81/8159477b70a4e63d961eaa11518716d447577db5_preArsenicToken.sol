// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/* preArsenicToken Presale
 After Presale you'll be able to swap this token for Arsenic. Ratio 1:1
*/
contract preArsenicToken is ERC20('preArsenicToken', 'PREARSENIC'), ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address  constant presaleAddress = 0xD904EF4Ca577D376D00F58314a2a7A0da0EcdE38;

    IERC20 public USDC = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    IERC20 prearsenicToken = IERC20(address(this));

    uint256 public salePrice = 3;

    uint256 public constant prearsenicMaximumSupply = 5000 * (10 ** 18); //2k

    uint256 public prearsenicRemaining = prearsenicMaximumSupply;

    uint256 public maxHardCap = 15000 * (10 ** 18); // 15k usdc

    uint256 public constant maxpreArsenicPurchase = 200 * (10 ** 18); // 200 prearsenic

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public constant presaleDuration = 203160; // 5 days aprox

    mapping(address => uint256) public userpreArsenicTotally;

    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event prearsenicPurchased(address sender, uint256 usdcSpent, uint256 prearsenicReceived);

    constructor(uint256 _startBlock) {
        startBlock  = _startBlock;
        endBlock    = _startBlock + presaleDuration;
        _mint(address(this), prearsenicMaximumSupply);
    }

    function buypreArsenic(uint256 _usdcSpent) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(prearsenicRemaining > 0, "No more preArsenic remains!");
        require(prearsenicToken.balanceOf(address(this)) > 0, "No more preArsenic left!");
        require(_usdcSpent > 0, "not enough usdc provided");
        require(_usdcSpent <= maxHardCap, "preArsenic Presale hardcap reached");
        require(userpreArsenicTotally[msg.sender] < maxpreArsenicPurchase, "user has already purchased too much prearsenic");

        uint256 prearsenicPurchaseAmount = (_usdcSpent * 1000000000000) / salePrice;

        // if we dont have enough left, give them the rest.
        if (prearsenicRemaining < prearsenicPurchaseAmount)
            prearsenicPurchaseAmount = prearsenicRemaining;

        require(prearsenicPurchaseAmount > 0, "user cannot purchase 0 prearsenic");

        // shouldn't be possible to fail these asserts.
        assert(prearsenicPurchaseAmount <= prearsenicRemaining);
        assert(prearsenicPurchaseAmount <= prearsenicToken.balanceOf(address(this)));

        //send prearsenic to user
        prearsenicToken.safeTransfer(msg.sender, prearsenicPurchaseAmount);
        // send usdc to presale address
    	USDC.safeTransferFrom(msg.sender, address(presaleAddress), _usdcSpent);

        prearsenicRemaining = prearsenicRemaining - prearsenicPurchaseAmount;
        userpreArsenicTotally[msg.sender] = userpreArsenicTotally[msg.sender] + prearsenicPurchaseAmount;

        emit prearsenicPurchased(msg.sender, _usdcSpent, prearsenicPurchaseAmount);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }

}