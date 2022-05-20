/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-19
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


}

contract GrainITO is Context, Ownable {
    using Address for address;

    mapping (address => StakedAmount) private stakedAmounts;

    address public constant grainAddress = 0xf030faCCE5Dc952ad89ED362a0bfBDD517a436C5;
    IERC20 grain = IERC20(grainAddress);

    uint256 constant decimals = 18;
    uint256 public mincap = 100 * 10 ** decimals;
    uint256 public maxcap = 100000 * 10 ** decimals;
    uint256 public rate = 100;
    uint256 public maxTxAmount = 10000000 * 10 ** decimals;
    bool public purchaseEnabled = true;
    
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    struct StakedAmount {
        uint256 previousVestedPercent;
        uint256 total;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[7] public stages;

    /**
     * Starting timestamp of the first stage of vesting (Tuesday, 19 June 2018, 09:00:00 GMT).
     * Will be used as a starting point for all dates calculations.
     */
    uint256 public vestingStartTimestamp = 1652967925;

    event GrainPurchased( address user, uint256 amount);
    event PurchaseEnabled (bool purchaseEnabled);
    event WithdrawAllEther (uint256 amount, address to);

    constructor () payable {
        _owner = 0xC25D17869728509f9FE2a4969566f26aB0e7042C;
        initVestingStages();
    }

    function setMincap(uint256 _mincap) external onlyOwner() {
        mincap = _mincap;
    }

    function setMaxcap(uint256 _maxcap) external onlyOwner() {
        maxcap = _maxcap;
    }

    function setRate(uint256 _rate) external onlyOwner() {
        rate = _rate;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner() {
        maxTxAmount = _amount;
    }

    function setPurchaseEnabled(bool _enabled) external onlyOwner() {
        purchaseEnabled = _enabled;
        emit PurchaseEnabled(purchaseEnabled);
    }

    function initVestingStages() internal {
        uint256 month = 3 minutes;
        stages[0].date = vestingStartTimestamp;
        stages[1].date = vestingStartTimestamp + month;
        stages[2].date = vestingStartTimestamp + (month*2);
        stages[3].date = vestingStartTimestamp + (month*3);
        stages[4].date = vestingStartTimestamp + (month*4);
        stages[5].date = vestingStartTimestamp + (month*5);
        stages[6].date = vestingStartTimestamp + (month*6);

        stages[0].tokensUnlockedPercentage = 10;
        stages[1].tokensUnlockedPercentage = 20;
        stages[2].tokensUnlockedPercentage = 35;
        stages[3].tokensUnlockedPercentage = 50;
        stages[4].tokensUnlockedPercentage = 65;
        stages[5].tokensUnlockedPercentage = 80;
        stages[6].tokensUnlockedPercentage = 100;
    }

    //to recieve AVAX from uniswapV2Router when swapping
    receive() external payable {
        purchaseGrain(msg.sender, msg.value * rate);
    }

    //User Functions
    function purchaseGrain(address to, uint256 amount) internal{
        require(amount >= mincap, "Purchase amount too low");
        require(amount <= maxcap, "Purchase amount too high");
        require(purchaseEnabled, "Purchases are disabled");
        StakedAmount storage ledger = stakedAmounts[to];
        uint256 vestedPercent = getVestedPercent();

        //payable(address(this)).transfer(val);
        uint256 payout = ((ledger.total * (vestedPercent - ledger.previousVestedPercent)) + (amount * vestedPercent))/100;
        ledger.total = ledger.total + amount;
        ledger.previousVestedPercent =  vestedPercent;
        grain.transfer(to, payout);        
        emit GrainPurchased(to, payout);
    }

    function getRemainingVestedAmount() public view returns(uint256){
        StakedAmount storage ledger = stakedAmounts[msg.sender];
        return ledger.total * (100 - ledger.previousVestedPercent);
    }

    function withdrawVestedTokens(address to) public{
        StakedAmount storage ledger = stakedAmounts[to];
        require(ledger.previousVestedPercent < 100, "All tokens have been withdrawn");
        require(ledger.total > 0, "You have no tokens to withdraw");
        uint256 vestedPercent = getVestedPercent();
        uint256 pendingBalance = ledger.total * ( vestedPercent - ledger.previousVestedPercent)/100;
        while(pendingBalance > maxTxAmount){
            grain.transfer(to, maxTxAmount);
            pendingBalance = pendingBalance - maxTxAmount;
        }
        ledger.previousVestedPercent = vestedPercent;
        grain.transfer(to, pendingBalance);
    }

    function getVestedPercent() public onlyOwner view returns (uint256){
        uint256 vestedPercent = 0;
        uint256 stage = 0;
        for (stage = 0; stage < stages.length; stage++) {
            if (block.timestamp >= stages[stage].date) {
                vestedPercent = stages[stage].tokensUnlockedPercentage;
            }
        }
        return vestedPercent;
    }

    function withdrawAllAVAX() public onlyOwner returns (uint256 amount){
        uint256 funds = address(this).balance;
        payable(_owner).transfer(funds);
        emit WithdrawAllEther(funds, _owner);
        return funds;
    }

    function withdrawAllGRAIN() public onlyOwner returns (uint256){
        uint256 funds = grain.balanceOf(address(this));
        grain.transfer(_owner, funds);
        return funds;
    }

}