/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface Pool {
    function pendingRewardByToken(address _user, IERC20 _token) external view returns (uint256);
    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256[] memory, IERC20[] memory);
    function withdraw(uint256 _amount) external;
    // The reward token
    function rewardTokens() external view returns (IERC20[] memory);
}

contract ClaimAll {
    address[] public pools;
    address[] public farms;

    function setPools(address[] memory _pools) external {
        pools = _pools;
    }
    function setFarms(address[] memory _farms) external {
        farms = _farms;
    }

    function addPool(address pool) external {
        pools.push(pool);
    }

    function addFarm(address farm) external {
        farms.push(farm);
    }

    function claimAllPools() external {
        for(uint i=0; i < pools.length; i++){
            (uint256[] memory pendingReward, ) = Pool(pools[i]).pendingReward(msg.sender);

            if(pendingReward[0] > 0){
                Pool(pools[i]).withdraw(0); //Harvest
            }
        }
    }

    function claimAllFarms() external {
        for(uint i=0; i < farms.length; i++){
            (uint256[] memory pendingReward, ) = Pool(farms[i]).pendingReward(msg.sender);

            if(pendingReward[0] > 0){
                Pool(farms[i]).withdraw(0); //Harvest
            }
        }
    }
}