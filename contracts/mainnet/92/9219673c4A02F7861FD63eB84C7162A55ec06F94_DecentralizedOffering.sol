//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./libraries/openzeppelin/token/ERC20/IERC20.sol";
import "./InstantSale.sol";

contract DecentralizedOffering is InstantSale {

    constructor(address lbcToken, address beneficiary)
    InstantSale(lbcToken, beneficiary) {
    }

    function init(uint256 avaxPrice)
    public
    onlyOwner
    {
        uint256 tokenAmount = 2515000 ether;
        uint256 tokenStartPrice = 26; // in cents of dollar
        uint256 thresholdValue = 20120 ether;
        uint256 increase = 1; // in cents of dollar

        _configureSale(tokenAmount, avaxPrice, tokenStartPrice, thresholdValue, increase);
    }

    function buyTokens()
    payable
    public {
        require(msg.value <= 1000 ether, "Humble Decentralized Offering: Investment must be lower or equal to 1000 AVAX");

        _buyTokens();
    }

    function withdrawFunds()
    public
    onlyOwner {
        _withdrawFunds();
    }

    modifier onlyOwner() override {
        require(msg.sender == Owner, "DecentralizedOffering: Only owner of contract can call this method");
        _;
    }
}