// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/* preKryptonToken Presale
 After Presale you'll be able to swap this token for Krypton. Ratio 1:1
*/
contract preKryptonToken is ERC20('preKryptonToken', 'PREKRYPTON'), ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address  constant presaleAddress = 0xD904EF4Ca577D376D00F58314a2a7A0da0EcdE38;

    IERC20 public USDC = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    IERC20 prekryptonToken = IERC20(address(this));

    uint256 public salePrice = 5;

    uint256 public constant prekryptonMaximumSupply = 10000 * (10 ** 18); //10k

    uint256 public prekryptonRemaining = prekryptonMaximumSupply;

    uint256 public maxHardCap = 50000 * (10 ** 18); // 50k usdc

    uint256 public constant maxpreKryptonPurchase = 500 * (10 ** 18); // 500 prekrypton

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public constant presaleDuration = 386765; // 5 days aprox

    mapping(address => uint256) public userpreKryptonTotally;

    event StartBlockChanged(uint256 newStartBlock, uint256 newEndBlock);
    event prekryptonPurchased(address sender, uint256 usdcSpent, uint256 prekryptonReceived);

    constructor(uint256 _startBlock) {
        startBlock  = _startBlock;
        endBlock    = _startBlock + presaleDuration;
        _mint(address(this), prekryptonMaximumSupply);
    }

    function buypreKrypton(uint256 _usdcSpent) external nonReentrant {
        require(block.number >= startBlock, "presale hasn't started yet, good things come to those that wait");
        require(block.number < endBlock, "presale has ended, come back next time!");
        require(prekryptonRemaining > 0, "No more preKrypton remains!");
        require(prekryptonToken.balanceOf(address(this)) > 0, "No more preKrypton left!");
        require(_usdcSpent > 0, "not enough usdc provided");
        require(_usdcSpent <= maxHardCap, "preKrypton Presale hardcap reached");
        require(userpreKryptonTotally[msg.sender] < maxpreKryptonPurchase, "user has already purchased too much prekrypton");

        uint256 prekryptonPurchaseAmount = (_usdcSpent * 1000000000000) / salePrice;

        // if we dont have enough left, give them the rest.
        if (prekryptonRemaining < prekryptonPurchaseAmount)
            prekryptonPurchaseAmount = prekryptonRemaining;

        require(prekryptonPurchaseAmount > 0, "user cannot purchase 0 prekrypton");

        // shouldn't be possible to fail these asserts.
        assert(prekryptonPurchaseAmount <= prekryptonRemaining);
        assert(prekryptonPurchaseAmount <= prekryptonToken.balanceOf(address(this)));

        //send prekrypton to user
        prekryptonToken.safeTransfer(msg.sender, prekryptonPurchaseAmount);
        // send usdc to presale address
    	USDC.safeTransferFrom(msg.sender, address(presaleAddress), _usdcSpent);

        prekryptonRemaining = prekryptonRemaining - prekryptonPurchaseAmount;
        userpreKryptonTotally[msg.sender] = userpreKryptonTotally[msg.sender] + prekryptonPurchaseAmount;

        emit prekryptonPurchased(msg.sender, _usdcSpent, prekryptonPurchaseAmount);

    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if sale has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;
        endBlock   = _newStartBlock + presaleDuration;

        emit StartBlockChanged(_newStartBlock, endBlock);
    }

}