// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./IERC20.sol";
import "./SafeMath.sol";


/**
 * Lock tokens to vest over a period of time as well as includes
 * a token cliff unlock at vestStart
 */ 
contract LinearVest {
    using SafeMath for uint256;

    address public controller;
    address public beneficiary; // token recipient
    
    IERC20 public immutable token; // token that will vest

    uint public immutable vestStart; // time when vest starts
    uint public immutable vestLength; // time period over which tokens linearly vest

    uint public immutable totalVestAmount; // amount of tokens that vest across vestLength
    uint public immutable cliffUnlockAmount; // amount of tokens that unlocks immediately at vestStart

    uint public vestAmountClaimed; // amount of vested tokens claimed so far
    bool public cliffIsClaimed = false;

    event TokensClaimed(uint _amount, uint _time);


    modifier onlyController {
        require(
            msg.sender == controller,
            "Only the controller can call this function."
        );
        _;
    }

    constructor(
        IERC20 _token,
        address _controller,
        address _beneficiary,
        uint _vestStart,
        uint _vestLength,
        uint _vestAmount,
        uint _cliffUnlockAmount) public {

        token = _token;
        controller = _controller;
        beneficiary = _beneficiary;

        vestStart = _vestStart;
        vestLength = _vestLength;
        totalVestAmount = _vestAmount;
        cliffUnlockAmount = _cliffUnlockAmount;
    }


    // ========= EXTERNAL MUTABLE FUNCTIONS =========


    // update address that can claim tokens
    function updateController(address _newController) external onlyController {
        controller = _newController;
    }

    // update address that will receive claimed tokens
    function updateBeneficary(address _newBeneficiary) external onlyController {
        beneficiary = _newBeneficiary;
    }


    // claim vested tokens
    function claimVestedTokens(uint _amount) external onlyController {
        require(block.timestamp > vestStart, "Vesting has not started yet");

        uint availableToClaim = amountVested().sub(vestAmountClaimed);

        require(_amount <= availableToClaim, "Input amount not available to claim");

        vestAmountClaimed = vestAmountClaimed.add(_amount);

        require(token.transfer(beneficiary, _amount));

        emit TokensClaimed(_amount, block.timestamp);
    }


    // claim full cliff token amount
    function claimCliffTokens() public onlyController {
        require(block.timestamp >= vestStart, "Cliff tokens not unlocked yet");
        require(!cliffIsClaimed, "Cliff tokens already claimed");

        cliffIsClaimed = true;

        require(token.transfer(beneficiary, cliffUnlockAmount));

        emit TokensClaimed(cliffUnlockAmount, block.timestamp);
    }


    // ========= PUBLIC VIEW FUNCTIONS =========


    // returns amount of tokens that have vested
    function amountVested() public view returns (uint claimable) {
        if (block.timestamp < vestStart) {
            // time is prior to vestStart
            return 0;
        }
        uint end = getLastRelevantTime();
        uint vestTime = end.sub(vestStart);

        return totalVestAmount.mul(vestTime).div(vestLength);
    }


    // returns vestEnd if the current time is past the vest end
    // otherwise returns the current time
    function getLastRelevantTime() public view returns (uint) {
        uint vestEnd = vestStart.add(vestLength);

        if (block.timestamp > vestEnd) {
            return vestEnd;
        }

        return block.timestamp;
    }


}