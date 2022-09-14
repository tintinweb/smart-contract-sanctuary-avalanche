/**
 *Submitted for verification at snowtrace.io on 2022-09-13
*/

// File: @openzeppelin/contracts/utils/Context.sol
pragma solidity ^0.8.13;
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/utils/Address.sol


abstract contract NebulaProtoStarDrop is Context{

	struct DROPS{
	uint256 dropped;
	uint256 claimed;
	uint256 transfered;
	
	}
	mapping(address => DROPS) public airdrop;
	address[] public Managers;
	address[] public protoOwners;
	address[] public transfered; 
	address payable treasury;
	address oldDrop = 0x93363e831b56E6Ad959a85F61DfCaa01F82164bb;

	
}


contract dropget{

	address DROP = 0x1e042948c57F937546BAac445C4DBf4698AfD35B;
	NebulaProtoStarDrop drops = NebulaProtoStarDrop(DROP);
	
	function giveStructVar(address _account)public view returns(uint256,uint256,uint256){
		drops.airdrop;
	}
}