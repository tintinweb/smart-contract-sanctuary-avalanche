/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-14
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract PaidPromoServicesConfirmationVault
{ 
    struct OrderData 
    {
        string orderId;
        string status;
        uint256 value;
        bool isPaidToPromoter;
        address promoter;
        address payer;
    }

    mapping (string => OrderData) private orderPools;

    address nf3launchpad;


    function addOrderPool( string memory _orderId, uint256 _value, address _promoter, address _payer ) external payable
    {
        require(msg.value == _value);
        require(msg.sender == nf3launchpad);

        
        orderPools[_orderId] = OrderData( 
            _orderId,
            "in-progress",
            _value,
            false,
            _promoter,
            _payer
        );

        payable(address(this)).transfer(msg.value);

    }

    function completeOrderPool(string memory _orderId) external payable{
        
        require(orderPools[_orderId].value<=0, "Order Not Found" );
        require(msg.sender == nf3launchpad);

        payable(orderPools[_orderId].promoter).transfer(orderPools[_orderId].value);

        orderPools[_orderId].status = "completed"; 
        orderPools[_orderId].isPaidToPromoter = true; 
    }

    function cancelOrderPool(string memory _orderId) external payable{
        
        require(orderPools[_orderId].value<=0, "Order Not Found" );
        require(msg.sender == nf3launchpad);

        payable(orderPools[_orderId].payer).transfer(orderPools[_orderId].value);

        orderPools[_orderId].status = "cancelled"; 
    }

}