pragma solidity ^0.8.11;

interface IERC1155{
    function safeTransferFrom(
        address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract ColorBubbleAirDrop{
    constructor(){}

    function bulkAirdrop(IERC1155 _contractAddress, address[] calldata _to, uint256[] calldata _amount, uint256[] calldata _id) public{
        require(_to.length == _id.length, "Mismatch");
        for(uint256 i=0;i<_to.length;i++){
            _contractAddress.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
        }
    }

}