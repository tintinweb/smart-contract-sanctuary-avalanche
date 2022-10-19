//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ERC721Contract {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

/**
 * Load the contract (address) up with the currencies listed.
 */
contract ChiknFaucetV1 {

    /**
     * Map of token name to the contract implementation.
     */
    mapping(string => ERC721Contract) public tokens;

    function withdraw(string calldata _token, uint256 _amount) external {
        require(_amount < 1000 ether, 'AMOUNT MUST BE LESS THAN OR EQUAL TO 1000');
        tokens[_token].transfer(msg.sender, _amount);
    }

    function balanceOf(string calldata _token) external returns (uint256 balance) {
        return tokens[_token].balanceOf(address(this));
    }

    function setContractByName(string calldata _token, address _contract) external {
        tokens[_token] = ERC721Contract(_contract);
    }
}