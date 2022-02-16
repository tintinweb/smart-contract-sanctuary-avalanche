/**
 *Submitted for verification at snowtrace.io on 2022-02-16
*/

// Sign Tester


pragma solidity ^0.8.0;

contract EIP712Tester {
    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Onepiece.ERC2612Verifier")),
                keccak256(bytes("1")),
                43114,
                address(this)
            )
        );
    }

    function TestSignature(
        address account,
        address operator,
        bytes32 approvalType,
        uint256 nonce,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (address) {
        bytes32 hashedMsg = keccak256(
            abi.encodePacked(
                hex"1901",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address account,address operator,bytes32 approvalType,uint256 nonce,uint256 deadline)"
                        ),
                        account,
                        operator,
                        approvalType,
                        nonce,
                        deadline
                    )
                )
            )
        );
        address signer = ecrecover(hashedMsg, v, r, s);
        return signer;
    }
}