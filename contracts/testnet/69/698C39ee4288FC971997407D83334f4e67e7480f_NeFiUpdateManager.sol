/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable_FeeMGR: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract overseer is Context {
	 function getFee() external virtual view returns(uint256);
}
abstract contract protoManager is Context{
	function updateFeeManager(address _account) external virtual;
	function updateDropManager(address _account) external virtual;
	function updateBoostManager(address _account) external virtual;
	function updateTreasury(address payable _account) external virtual;
	function updateNeFiToken(address _account) external virtual;
        function updateFeeToken(address _account) external virtual;
        function updateOverseer(address _account) external virtual;
}
abstract contract feeManager is Context{
	function updateDropManager(address _account) external virtual;
	function updateBoostManager(address _account) external virtual;
	function updateProtoManager(address _account) external virtual;
	function updateTreasury(address payable _account) external virtual;
	function updateTeamPool(address _account) external virtual;
	function updateRewardsPool(address _account) external virtual;
	function updateNeFiToken(address _account) external virtual;
        function updateFeeToken(address _account) external virtual;
        function updateOverseer(address _account) external virtual;
}
abstract contract dropManager is Context{
	function updateFeeManager(address _account) external virtual;
	function updateBoostManager(address _account) external virtual;
	function updateProtoManager(address _account) external virtual;
	function updateTreasury(address payable _account) external virtual;
	function updateNeFiToken(address _account) external virtual;
        function updateFeeToken(address _account) external virtual;
        function updateOverseer(address _account) external virtual;
}
abstract contract boostManager is Context{
	function updateFeeManager(address _account) external virtual;
	function updateDropManager(address _account) external virtual;
	function updateProtoManager(address _account) external virtual;
	function updateTreasury(address payable _account) external virtual;
	function updateNeFiToken(address _account) external virtual;
        function updateFeeToken(address _account) external virtual;
        function updateOverseer(address _account) external virtual;
}
contract NeFiUpdateManager is Ownable {
	address public _feeManager;
	address public _protoManager;
	address public _dropManager;
	address public _boostManager;
	address public _overseer;
	address public teamPool;
	address public rewardsPool;
	address payable public treasury;
	feeManager public feeMGR;
	boostManager public boostMGR;
	protoManager public protoMGR;
	dropManager public dropMGR;
	overseer public over;
//internalUpdate-----------------------------------------------------------------------------------------------------------
	function INTupdateFeeManager() internal{
		protoMGR.updateFeeManager(_feeManager);
		dropMGR.updateFeeManager(_feeManager);
		boostMGR.updateFeeManager(_feeManager);
	}
	function INTupdateProtoManager() internal{
		dropMGR.updateProtoManager(_protoManager);
		feeMGR.updateProtoManager(_protoManager);
		boostMGR.updateProtoManager(_protoManager);
	}
	function INTupdateDropManager() internal{
		protoMGR.updateDropManager(_dropManager);
		feeMGR.updateDropManager(_dropManager);
		boostMGR.updateDropManager(_dropManager);
	}
	function INTupdateBoostManager() internal{
		protoMGR.updateBoostManager(_boostManager);
		dropMGR.updateBoostManager(_boostManager);
		feeMGR.updateBoostManager(_boostManager);
	}
	function INTupdateTreasury() internal{
		protoMGR.updateTreasury(treasury);
		feeMGR.updateTreasury(treasury);
		boostMGR.updateTreasury(treasury);
		dropMGR.updateTreasury(treasury);
	}
	function INTupdateOverseer() internal{
		protoMGR.updateOverseer(_overseer);
		feeMGR.updateOverseer(_overseer);
		dropMGR.updateOverseer(_overseer);
		boostMGR.updateOverseer(_overseer);
	}
	function INTupdateRewardsPool() internal{
		feeMGR.updateRewardsPool(rewardsPool);
	}
	function INTupdateTeamPool() internal{
		feeMGR.updateTeamPool(teamPool);
	}
//externalUpdate-----------------------------------------------------------------------------------------------------------
	function updateTreasury() external onlyOwner{
		INTupdateTreasury();
	}
	function updateBoostManager() external onlyOwner{
		INTupdateBoostManager();
	}
	function updateDropManager() external onlyOwner{
		INTupdateDropManager();
	}
	function updateProtoManager() external onlyOwner{
		INTupdateProtoManager();
	}
	function updateFeeManager() external onlyOwner{
		INTupdateFeeManager();
	}
	function updateOverseer() external onlyOwner{
		INTupdateOverseer();
	}
//externalChangeALLS-----------------------------------------------------------------------------------------------------------
	function changeTreasury(address payable _account) external onlyOwner{
    		treasury = _account;
    		INTupdateTreasury();
        }
        function changeFeeManager(address _account) external  onlyOwner(){
        	_feeManager = _account;
    		feeMGR = feeManager(_feeManager);
    		INTupdateFeeManager();
        }
        function changeProtoManager(address _account) external  onlyOwner(){
        	_protoManager = _account;
    		protoMGR = protoManager(_protoManager);
    		INTupdateProtoManager();
        }
        function changeOverseer(address _account) external  onlyOwner(){
    		_overseer = _account;
    		over = overseer(_overseer);
    		INTupdateOverseer();
        }
        function changeDropManager(address _account) external  onlyOwner(){
        	_dropManager = _account;
        	dropMGR = dropManager(_dropManager);
        	INTupdateDropManager();
        }
        function changeBoostManager(address _account) external  onlyOwner(){
        	_boostManager = _account;
    		boostMGR = boostManager(_boostManager);
    		INTupdateBoostManager();
        }
        function changeTeamPool(address _account) external onlyOwner(){
        	teamPool = _account;
        	INTupdateTeamPool();
        }
        function changeRewardsPool(address _account) external onlyOwner(){
        	rewardsPool = _account;
        	INTupdateRewardsPool();
        }
//externalChange-----------------------------------------------------------------------------------------------------------
	function INDchangeTreasury(address payable _account) external onlyOwner{
    		treasury = _account;
        }
        function INDchangeFeeManager(address _account) external  onlyOwner(){
        	_feeManager = _account;
    		feeMGR = feeManager(_feeManager);
        }
        function INDchangeProtoManager(address _account) external  onlyOwner(){
        	_protoManager = _account;
    		protoMGR = protoManager(_protoManager);
        }
        function INDchangeOverseer(address _account) external  onlyOwner(){
    		_overseer = _account;
    		over = overseer(_overseer);
        }
        function INDchangeDropManager(address _account) external  onlyOwner(){
        	_dropManager = _account;
        	dropMGR = dropManager(_dropManager);
        }
        function INDchangeBoostManager(address _account) external  onlyOwner(){
        	_boostManager = _account;
    		boostMGR = boostManager(_boostManager);
        }
        function INDchangeTeamPool(address _account) external onlyOwner(){
        	teamPool = _account;
        }
        function INDchangeRewardsPool(address _account) external onlyOwner(){
        	rewardsPool = _account;
        }
//externalGets-----------------------------------------------------------------------------------------------------------
	function getTreasury() external returns(address){
		return treasury;
	}
	function getBoostManager() external returns(address){
		return _boostManager;
	}
	function getDropManager() external returns(address){
		return _dropManager;
	}
	function getProtoManager() external returns(address){
		return _protoManager;
	}
	function getFeeManager() external returns(address){
		return _feeManager;
	}
	function getOverseer() external returns(address){
		return _overseer;
	}
	function getRewardsPool() external returns(address){
		return rewardsPool;
	}
	function getTeamPool() external returns(address){
		return teamPool;
	}
}