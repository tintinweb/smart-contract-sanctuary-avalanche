/**
 *Submitted for verification at snowtrace.io on 2022-02-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
contract IERC20 {
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    function approve(address guy, uint wad) public returns (bool) {
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        return true;
    }
}

interface Router{
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
      ) external returns (uint[] memory amounts);
}

contract Arb {
    address payable private owner; 
    address public router;
    address public WAVAX;
    constructor(address _router, address _WAVAX) {
        router = _router;
        owner = payable(msg.sender);
        WAVAX = _WAVAX;
    }

    function arb(address[] calldata path, uint amountIn, uint amountMinOut,uint deadline) external{
        require(msg.sender == owner, "OWNER");
        uint prevWBalance = IERC20(WAVAX).balanceOf(address(this));
        Router(router).swapExactTokensForTokens(amountIn, amountMinOut, path, address(this), deadline);
        require(IERC20(WAVAX).balanceOf(address(this)) > prevWBalance, "Failed Arb");
    }

    function redeem(address[] calldata tokens) external {
        require(msg.sender == owner, "OWNER");
        for (uint i = 0; i < tokens.length; i++){
            if (tokens[i] != address(0)) {
                uint balance = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).transfer(owner, balance);
            }
            else{
                (bool sent, ) = owner.call{value: address(this).balance}("");
                require(sent, "NOT SENT");
            }
        }
    }

    function approve(address token,uint amt) external{
        require(msg.sender == owner, "OWNER");
        IERC20(token).approve(router, amt);
    }
}