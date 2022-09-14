/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-13
*/

pragma solidity ^0.8.13;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract sendback is Context {
    function createProtoAvax() payable virtual external;
    }


contract sling{
	sendback public mssnn;
	function slng() payable external{
		sendback mssnn = sendback(msg.sender);
		mssnn.createProtoAvax();
		payable(msg.sender).transfer(msg.value);
	}
		
}