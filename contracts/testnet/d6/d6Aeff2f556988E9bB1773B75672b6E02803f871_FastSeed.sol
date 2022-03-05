// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface Mintable {
    function mint(address, uint256) external;
}

interface Faucet {
    function faucet(uint256) external;
    function transfer(address, uint256) external;
}

contract FastSeed {
    function seed(address account, uint256 amount) external {
        Mintable(0x48efa19fC7BA85061D687500ba223F5e8CE6F902).mint(account, amount * 10 ** 18);
        Mintable(0x03b3c37046fFB257ba8Da8fE5F20638D6648e890).mint(account, amount * 10 ** 18);

        Faucet(0x9A34ee6fc0ED6b9878f888427474c393Ba8BF3a1).faucet(amount * 10 ** 18);
        Faucet(0x9A34ee6fc0ED6b9878f888427474c393Ba8BF3a1).transfer(account, amount * 10 ** 18);

        Faucet(0xf07450C13F534cfa4F79a87D96D3B816118a8b33).faucet(amount * 10 ** 6);
         Faucet(0xf07450C13F534cfa4F79a87D96D3B816118a8b33).transfer(account, amount * 10 ** 6);

        Faucet(0x77f3aC515aCf934cA3F83964DE85d174B61c0ccE).faucet(amount * 10 ** 6);
        Faucet(0x77f3aC515aCf934cA3F83964DE85d174B61c0ccE).transfer(account, amount * 10 ** 6);

        Faucet(0x08CFd378d2A552A86Cd48EA0E271981E6554b4aE).faucet(amount * 10 ** 6);
        Faucet(0x08CFd378d2A552A86Cd48EA0E271981E6554b4aE).transfer(account, amount * 10 ** 6);
    }
}