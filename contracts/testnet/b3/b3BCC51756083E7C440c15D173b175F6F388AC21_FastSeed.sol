// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface Mintable {
    function faucet(uint256) external;
    function decimals() external returns(uint256);
    function transfer(address, uint256) external;
}

interface Booster {
    struct PoolInfo {
        address pool;
        address token;
        address lpToken;
        address rewardPool;
        bool shutdown;
    }
    function pools(uint256) external view returns(PoolInfo memory);
}

contract FastSeed {
    Booster booster = Booster(0xD77707514A2993f2b8b7dAD43cFEb3Bf6CDE3ebd);

    function multiSeed(address[] calldata accounts) external {
        for(uint256 i=0; i < accounts.length; ++i) {
            seed(accounts[i]);
        }
    }

    function seed(address account) public {
        for(uint256 i=0; i < 12; ++i) {
            Booster.PoolInfo memory info = booster.pools(i);
            Mintable token = Mintable(info.token);
            token.faucet(1000 * 10 ** token.decimals());
            token.transfer(account, 1000 * 10 ** token.decimals());
        }
    }
}