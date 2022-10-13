/**
 *Submitted for verification at snowtrace.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

contract FairFund is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public developerFee = 500; // 500 : 5 %. 10000 : 100 %
    uint256 public rewardPeriod = 30 days;
    uint256 public withdrawPeriod = 4 weeks;
    uint256 public apr = 2000; // 2000 : 20 %. 10000 : 100 %
    uint256 public percentRate = 10000;
    address payable private devWallet;
    uint256 public _currentDepositID = 0;
    address[] public investors;

    struct DepositStruct {
        address investor;
        uint256 depositAmount;
        uint256 depositAt; 
        uint256 claimedAmount; 
        bool state; 
    }

    mapping(uint256 => DepositStruct) public depositState;
    mapping(address => uint256[]) public ownedDeposits;

    constructor(address payable _devWallet) {
        devWallet = _devWallet;
    }


    function deposit() external payable {
        require(msg.value > 0, "you can deposit more than 0 matic");

        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (msg.value * developerFee).div(percentRate);
        // transfer 5% fee to dev wallet
        (bool success, ) = devWallet.call{value: depositFee}("");
        require(success, "Failed to send fee to the devWallet");

        depositState[_id].investor = msg.sender;
        depositState[_id].depositAmount = msg.value - depositFee;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].state = true;

        ownedDeposits[msg.sender].push(_id);
        if(!existInInvestors(msg.sender)) investors.push(msg.sender);
    }


     function getInvestors() public view returns (address[] memory) {
        return investors;
    }

    function claimReward(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can claim reward"
        );

        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getClaimableReward(id);
        require(claimableReward > 0, "your reward is zero");

        require(
            claimableReward <= address(this).balance,
            "no enough matic in pool"
        );

        // transfer reward to the user
        (bool success, ) = msg.sender.call{value: claimableReward}("");
        require(success, "Failed to claim reward");

        depositState[id].claimedAmount += claimableReward;
    }

    
    function claimAllReward() public nonReentrant {
        require(ownedDeposits[msg.sender].length > 0, "you can deposit once at least");

        uint256 allClaimableReward;
        for(uint256 i; i < ownedDeposits[msg.sender].length; i ++) {
            uint256 claimableReward = getClaimableReward(ownedDeposits[msg.sender][i]);
            allClaimableReward += claimableReward;
            depositState[ownedDeposits[msg.sender][i]].claimedAmount += claimableReward;
        }

        
        (bool success, ) = msg.sender.call{value: allClaimableReward}("");
        require(success, "Failed to claim reward");
    }

    
    function getAllClaimableReward(address investor) public view returns (uint256) {
        uint256 allClaimableReward;
        for(uint256 i = 0; i < ownedDeposits[investor].length; i ++) {
            allClaimableReward += getClaimableReward(ownedDeposits[investor][i]);
        }

        return allClaimableReward;
    }

    
    function getClaimableReward(uint256 id) public view returns (uint256) {
        if(depositState[id].state == false) return 0;
        uint256 lastedRoiTime = block.timestamp - depositState[id].depositAt;

        
        uint256 allClaimableAmount = (lastedRoiTime *
            depositState[id].depositAmount *
            apr).div(percentRate * rewardPeriod);

        
        require(
            allClaimableAmount >= depositState[id].claimedAmount,
            "something went wrong"
        );

        return allClaimableAmount - depositState[id].claimedAmount;
    }

    function getOwnedDeposits(address investor) public view returns (uint256[] memory) {
        return ownedDeposits[investor];
    }
    
    function existInInvestors(address investor) public view returns(bool) {
        for(uint256 j = 0; j < investors.length; j ++) {
            if (investors[j] == investor) {
                return true;
            }
        }
        return false;
    }

    function getTotalRewards() public view returns (uint256) {
        uint256 totalRewards;
        for(uint256 i = 0; i < _currentDepositID; i ++) {
            totalRewards += getClaimableReward(i + 1);
        }
        return totalRewards;
    }

    
    function getTotalInvests() public view returns (uint256) {
        uint256 totalInvests;
        for(uint256 i = 0; i < _currentDepositID; i ++) {
            if(depositState[i + 1].state) totalInvests += depositState[i + 1].depositAmount;
        }
        return totalInvests;
    }


    function _getNextDepositID() private view returns (uint256) {
        return _currentDepositID + 1;
    }

    function _incrementDepositID() private {
        _currentDepositID++;
    }

    // reset dev wallet address
    function resetContract(address payable _devWallet) public onlyOwner {
        devWallet = _devWallet;
    }

    

    function withdrawFunds(uint256 amount) external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw funds");
    }

   

    function withdrawCapital(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can claim reward"
        );
        require(
            block.timestamp - depositState[id].depositAt > withdrawPeriod,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getClaimableReward(id);

        require(
            depositState[id].depositAmount + claimableReward <= address(this).balance,
            "no enough avax in pool"
        );

        // transfer capital to the user
        (bool success, ) = msg.sender.call{
            value: depositState[id].depositAmount + claimableReward
        }("");
        require(success, "Failed to claim reward");

        depositState[id].state = false;
    }


    function removeInvestor(uint index) public{
        investors[index] = investors[investors.length - 1];
        investors.pop();
    }


    function addFunds() external payable onlyOwner returns(bool) {
        require(msg.value > 0, "you can deposit more than 0 avax");
        return true;
    }

}