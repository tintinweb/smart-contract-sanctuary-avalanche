/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-02
*/

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SmartSwapFee{

    uint256 public avaxFee;
    address public devWallet;
    mapping(address => bool)public excludedFromFee;
    mapping(address => uint256)public totalFeePerUser;
    uint256 public totalUsers;
    address[] public users;
    
    function updateSwapFee(uint256 _avaxFee)public{
        avaxFee = _avaxFee;
    }

    function updateDevWallet(address _devWallet)public{
        devWallet = _devWallet;
    }

    function setExcludedFromFee(address _excludedFromFee)public{
        excludedFromFee[_excludedFromFee] = true;
    }

    function takeFee()external payable{

        if(!excludedFromFee[msg.sender]){
        
            require(msg.value >= avaxFee, "Smart Swap: Insufficient Fee");
            payable(devWallet).transfer(avaxFee);
        }

        if(!(totalFeePerUser[msg.sender]>0)){
            users.push(msg.sender);
            totalUsers++;
        }
        totalFeePerUser[msg.sender] += avaxFee;

    }
}