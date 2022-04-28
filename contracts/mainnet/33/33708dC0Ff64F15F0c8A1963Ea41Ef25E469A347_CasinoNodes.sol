/**
 *Submitted for verification at snowtrace.io on 2022-04-28
*/

//    ______           _                _   __          __         
//   / ____/___ ______(_)___  ____     / | / /___  ____/ /__  _____
//  / /   / __ `/ ___/ / __ \/ __ \   /  |/ / __ \/ __  / _ \/ ___/
// / /___/ /_/ (__  ) / / / / /_/ /  / /|  / /_/ / /_/ /  __(__  ) 
// \____/\__,_/____/_/_/ /_/\____/  /_/ |_/\____/\__,_/\___/____/  
//                                                                
//
// Developed by Anon from HRNS
// A Gentlemen's Club for Serious Investors on Avalanche Blockchain
// BasedProtocol.com
/**
 *Submitted for verification at snowtrace.io on 2022-04-25
*/
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract CasinoNodes is Context, Ownable {
    using SafeMath for uint256;

    uint256 private constant DEPOSIT_MAX_AMOUNT = 500 ether;
    uint256 private OPERATING_STEP = 1080000;
    uint256 private TAX_PERCENT = 3;
    uint256 private BOOST_PERCENT = 20;
    uint256 private BOOST_CHANCE = 35;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    mapping(address => uint256) private revenuePool;
    mapping(address => uint256) private operatingPower;
    mapping(address => uint256) private lastOperating;
    mapping(address => address) private referrals;
    address payable private taxAddress;
    uint256 private participants;
    uint256 private nodesLaunched;
    uint256 private marketRevenue;
    bool private launched = false;

    event RewardsBoosted(address indexed adr, uint256 boosted);

    constructor() {
        taxAddress = payable(msg.sender);
    }

    function handleLaunch(address ref, bool isReLaunch) private {
        uint256 userRevenue= getUserRevenue(msg.sender);
        uint256 newOperatingPower = SafeMath.div(userRevenue, OPERATING_STEP);
        if (isReLaunch && random(msg.sender) <= BOOST_CHANCE) {
            uint256 boosted = getBoost(newOperatingPower);
            newOperatingPower = SafeMath.add(newOperatingPower, boosted);
            emit RewardsBoosted(msg.sender, boosted);
        }

        operatingPower[msg.sender] = SafeMath.add(operatingPower[msg.sender], newOperatingPower);
        revenuePool[msg.sender] = 0;
        lastOperating[msg.sender] = block.timestamp;

        if (ref == msg.sender) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        revenuePool[referrals[msg.sender]] = SafeMath.add(revenuePool[referrals[msg.sender]], SafeMath.div(userRevenue, 8));

        nodesLaunched++;
        marketRevenue= SafeMath.add(marketRevenue, SafeMath.div(userRevenue, 5));
    }

    function launchNodes(address ref) public payable {
        require(launched, 'Casino node not launched yet');
        require(msg.value <= DEPOSIT_MAX_AMOUNT, 'Maximum deposit amount is 5000 AVAX');
        uint256 amount = calculateBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        amount = SafeMath.sub(amount, getTax(amount));
        uint256 tax = getTax(msg.value);
        taxAddress.transfer(tax);

        if (operatingPower[msg.sender] == 0) {
            participants++;
        }

        revenuePool[msg.sender] = SafeMath.add(revenuePool[msg.sender], amount);
        handleLaunch(ref, false);
    }

    function reLaunchNodes(address ref) public {
        require(launched, 'Casino node not launched yet');
        handleLaunch(ref, true);
    }

    function sellRevenue() public {
        require(launched, 'Casino node not launched yet');
        uint256 userRevenue= getUserRevenue(msg.sender);
        uint256 sellRewards = calculateSell(userRevenue);
        uint256 tax = getTax(sellRewards);
        revenuePool[msg.sender] = 0;
        lastOperating[msg.sender] = block.timestamp;
        marketRevenue= SafeMath.add(marketRevenue, userRevenue);
        taxAddress.transfer(tax);
        payable(msg.sender).transfer(SafeMath.sub(sellRewards, tax));
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateSell(uint256 revenue) public view returns (uint256) {
        return calculateTrade(revenue, marketRevenue, address(this).balance);
    }

    function calculateBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketRevenue);
    }

    function getProjectBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getProjectStats()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (address(this).balance, participants, nodesLaunched);
    }

    function getUserRevenue(address adr) public view returns (uint256) {
        return SafeMath.add(revenuePool[adr], getUserNewRevenue(adr));
    }

    function getUserNewRevenue(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(OPERATING_STEP, SafeMath.sub(block.timestamp, lastOperating[adr]));
        return SafeMath.mul(secondsPassed, operatingPower[adr]);
    }

    function getUserRewards(address adr) public view returns (uint256) {
        uint256 sellRewards = 0;
        uint256 userRevenue= getUserRevenue(adr);
        if (userRevenue> 0) {
            sellRewards = calculateSell(userRevenue);
        }
        return sellRewards;
    }

    function getUserOperatingPower(address adr) public view returns (uint256) {
        return operatingPower[adr];
    }

    function getUserStats(address adr) public view returns (uint256, uint256) {
        return (getUserRewards(adr), operatingPower[adr]);
    }

    function getTax(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, TAX_PERCENT), 100);
    }

    function getBoost(uint256 amount) private view returns (uint256) {
        return SafeMath.div(SafeMath.mul(amount, BOOST_PERCENT), 100);
    }

    function beginCasinoNodes() public payable onlyOwner {
        require(marketRevenue== 0);
        launched = true;
        marketRevenue= 108000000000;
    }

    function random(address adr) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, operatingPower[adr], nodesLaunched))) % 100;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}