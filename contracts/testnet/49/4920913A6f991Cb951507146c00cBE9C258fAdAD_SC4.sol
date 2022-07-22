// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IStargateRouter} from './IStargateRouter.sol';

pragma abicoder v2;



interface IBEP20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}



contract SC4{

    address stargateRouter = 0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1;
    constructor() {
    }

    function swap(
        uint qty,
        address bridgeToken,                    
        uint16 dstChainId,                      
        uint16 srcPoolId,                       
        uint16 dstPoolId,                       
        address to                        
    ) external payable {
        require(msg.value > 0, "stargate requires a msg.value to pay crosschain message");
        require(qty > 0, 'error: swap() requires qty > 0');

        // encode payload data to send to destination contract, which it will handle with sgReceive()
        bytes memory data = abi.encode(to);

        // this contract calls stargate swap()
        IBEP20(bridgeToken).transferFrom(msg.sender, address(this), qty);
        IBEP20(bridgeToken).approve(stargateRouter, qty);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouter).swap{value:msg.value}(
            dstChainId,                                     // the destination chain id
            srcPoolId,                                      // the source Stargate poolId
            dstPoolId,                                      // the destination Stargate poolId
            payable(msg.sender),                            // refund adddress. if msg.sender pays too much gas, return extra eth
            qty,                                            // total tokens to send to destination chain
            0,                                              // min amount allowed out
            IStargateRouter.lzTxObj(200000, 0, "0x"),       // default lzTxObj
            abi.encodePacked(to),         // destination address, the sgReceive() implementer
            data                                            // bytes payload
        );
    }

}