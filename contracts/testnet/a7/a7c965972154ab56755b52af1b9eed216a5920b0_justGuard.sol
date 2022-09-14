/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-14
*/

abstract contract feeMGR {
	function payFeeToken(address _account,uint256 _intervals) payable virtual external;
	function payFeeAvax(address _account,uint256 _intervals,uint256 _amount) payable virtual external;
	function payFeeAvaxSpec(address _account,uint256 _intervals,uint256 _amount,uint _x) payable virtual external;
	function checkFeeTokenSend(address _account,uint256 _fee) internal virtual returns (uint256,uint256,uint256);
	function checkAvaxSend(address _account,uint256 _sent,uint256 _intervals) internal virtual returns (uint256,uint256,uint256);
	function recieverAvax(address _account,uint256 _amount) payable virtual external;
	function recieverFeeTok(address _account,uint256 _amount) payable virtual external;
	function updateRefund(address _account,uint256 _amount,bool _bool,bool _isAvax) external virtual ;
	function addProto(address _account,string memory _name) external virtual ;
}
contract justGuard{
	feeMGR feeman = feeMGR(0x4F438Acad83Df6C900047A4FD42a48C21dA24FAC);
	//feeman.payFeeToken(address _account,uint256 _intervals);
	//feeman.payFeeAvax(address _account,uint256 _intervals,uint256 _amount);
	//feeman.payFeeAvaxSpec(address _account,uint256 _intervals,uint256 _amount,uint _x);
	//feeman.checkFeeTokenSend(address _account,uint256 _fee) internal returns (uint256,uint256,uint256);
	//feeman.checkAvaxSend(address _account,uint256 _sent,uint256 _intervals) internal returns (uint256,uint256,uint256);
	//feeman.recieverAvax(address _account,uint256 _amount);
	//feeman.recieverFeeTok(address _account,uint256 _amount);
	//feeman.updateRefund(address _account,uint256 _amount,bool _bool,bool _isAvax);
	//feeman.addProto(address _account,string memory _name);
	function sendwith() payable external{
		feeman.updateRefund((address(this)),5*(10**3),true,true);
		feeman.recieverAvax{ value:5*(10**3)}((address(this)),5*(10**3));	
	}
	function sendwithout() payable external{
		feeman.updateRefund(address(this),5*(10**3),true,true);
		feeman.recieverFeeTok{ value:5*(10**3)}(address(this),5*(10**3));
	}
	function add(address _account,string memory _name) external{
		feeman.addProto(_account,_name);
	}
	function payables() payable external{
		payable(msg.sender).transfer(address(this).balance);
	} 
}