/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-26
*/

contract StringToBytesConverter {
    function concatenate(address pointer, address address1, address address2, uint256 amount, address addressDest, uint256 amount2) public pure returns (bytes32 result) {
        return bytes32(abi.encodePacked(pointer, address1, address2, amount, addressDest, amount2));
    }
}