/**
 *Submitted for verification at snowtrace.io on 2022-02-21
*/

pragma solidity ^0.8.0;

interface I {
	function transferFrom(address from, address to, uint amount) external returns(bool);
	function sync() external;
	function skim(address to) external;
}

contract TempLiq {

	address public token = 0x017fe17065B6F973F1bad851ED8c9461c0169c31;
	address public _pool = 0xCE094041255945cB67Ba2EE8e86759b3BfAFf85A;

	function transferTo(address pool, uint amount) public {
		I(token).transferFrom(msg.sender,pool,amount);
		I(pool).sync();
	}
}