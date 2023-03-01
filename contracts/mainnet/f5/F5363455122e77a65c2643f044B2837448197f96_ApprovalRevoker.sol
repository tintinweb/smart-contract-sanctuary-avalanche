/**
 *Submitted for verification at snowtrace.io on 2023-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ApprovalRevoker {
    function revokeApprovals(address[] calldata tokens, address[][] calldata spenders) external {
        require(tokens.length == spenders.length, "Tokens and spenders arrays must have the same length");
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) {
                continue;
            }
            if (!supportsERC20Interface(token)) {
                continue;
            }
            for (uint j = 0; j < spenders[i].length; j++) {
                address spender = spenders[i][j];
                if (spender == address(0)) {
                    continue;
                }
                require(ERC20(token).approve(spender, 0), "Failed to revoke approval");
            }
        }
    }

    function supportsERC20Interface(address token) internal view returns (bool) {
        bytes4 interfaceId = 0x36372b07; // ERC20 interface ID
        bytes4 result = ERC165(token).supportsInterface(interfaceId);
        return result == interfaceId;
    }
}

interface ERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bytes4);
}