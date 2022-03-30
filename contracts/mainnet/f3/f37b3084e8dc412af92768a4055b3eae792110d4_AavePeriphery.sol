// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.2;

import "./IERC20.sol";
import "./IPool.sol";

contract AavePeriphery {

    /// @notice V3 pool address
    address public constant POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    /**
     * @dev Supplies assets to the Aave V3 pool
     * @param token address of the token to supply
     */
    function aaveSupplyERC20(address token) external {

        // get token balance of sender
        uint256 tokenBalance = IERC20(token).balanceOf(msg.sender);

        // ensure that this contract has an allowance to spend the token balance
        require(IERC20(token).allowance(msg.sender, address(this)) >= tokenBalance);

        // transfer tokens to this contract
        IERC20(token).transferFrom(msg.sender, address(this), tokenBalance);

        // approve Aave pool to spend tokens
        IERC20(token).approve(POOL, tokenBalance);

        // supply tokens to Aave on behalf of msg.sender
        IPool(POOL).supply(token, tokenBalance, msg.sender, 0);
    }
}