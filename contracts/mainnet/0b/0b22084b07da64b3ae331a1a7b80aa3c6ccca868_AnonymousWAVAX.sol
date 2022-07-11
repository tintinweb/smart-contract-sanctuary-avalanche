/**
 *Submitted for verification at snowtrace.io on 2022-07-11
*/

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.7.0;

contract AnonymousWAVAX {
    string public name     = "ANONYMOUS WAVAX";
    string public symbol   = "ZAVAX";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
   // event  Transfer(address indexed src, address indexed dst, uint wad);
   // event  Deposit(address indexed dst, uint wad);
   // event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

   /*
    function() external payable {
        deposit();
    } -> unused syntax from solidity 0.6.0 */

    receive() external payable {
        deposit();
    } // fallback function according to solidity 0.6.0+ documentation

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
       // emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
      //  emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        //emit Transfer(src, dst, wad); //just exclude this event, now explorers cant track tranfers

        return true;
    }
}