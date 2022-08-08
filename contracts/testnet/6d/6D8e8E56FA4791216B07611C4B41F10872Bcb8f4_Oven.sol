/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-07
*/

// This contract turns Dough into PZA, can be upgraded

//SPDX-License-Identifier: MIT




pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





// TODO Timestamp + Don't hardcode + 
interface IDough is IERC20 {
    function mint(address receiver, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
}

contract Oven is Ownable {
    IDough dough;
    IDough pza;
    address projectwallet;

    uint256 waitTime = 6 hours;

    uint256[] public burnRates = [40, 25, 15, 10];
    uint256[] public burnPrices = [1 ether, 5 ether, 10 ether, 50 ether];
    uint256[] public conversionRates = [1000, 900, 800, 500];
    uint256[] public conversionPrices = [2 ether, 8 ether, 16 ether, 32 ether];
    
    mapping(address => uint256) public depositTime;
    mapping(address => uint256) public doughDeposit;
    mapping(address => uint256) public burnUpgrade;
    mapping(address => uint256) public conversionUpgrade;
    

    constructor(address _dough, address _pza, address _projectwallet) {
        dough = IDough(_dough);
        pza = IDough(_pza);
        projectwallet = _projectwallet;
    }
    // --------------------------------------------------------VIEW-------------------------------------------------------- 
    function getBurnUpPrice(address user) external view returns (uint256) {
        return burnPrices[burnUpgrade[user]];
    }

    function getConversionUpPrice(address user) external view returns (uint256) {
        return conversionPrices[conversionUpgrade[user]];
    }

    function getBurnUpgradeLevel(address user) external view returns (uint256) {
        return burnUpgrade[user];
    }

    function getConversionUpgradeLevel(address user) external view returns (uint256) {
        return conversionUpgrade[user];
    }
    function getDoughDeposit(address user) external view returns (uint256) {
        return doughDeposit[user];
    }

    function getPizzaReady(address user) external view returns (uint256) {
        return depositTime[user] + waitTime;
    }
    function getPizzaAmount(address user) external view returns (uint256) {
        uint256 totalPZA = doughDeposit[user] / conversionRates[conversionUpgrade[user]];
        uint256 halfBurn = totalPZA * burnRates[burnUpgrade[user]] / 200;
        uint256 pizzaout = totalPZA - 2*halfBurn;
        return pizzaout;
    }    
    // --------------------------------------------------------PUBLIC - Upgrades--------------------------------------------------------
    function buyBurnUpgrade() external {
        require(burnUpgrade[msg.sender] < burnRates.length - 1, "Oven: Max burn upgrade reached");
        
        uint256 price = burnPrices[burnUpgrade[msg.sender]];
        // uint256 approv = pza.allowance(msg.sender, address(this));
        // require( approv >= price, "Oven: Insufficient Allowance");
        // Where does it go? 
        pza.transferFrom(msg.sender, address(this), price);

        burnUpgrade[msg.sender] += 1;
    }

    function buyConversionUpgrade() external {
        require(conversionUpgrade[msg.sender] < conversionRates.length - 1, "Oven: Max Conversion upgrade reached");

        uint256 price = conversionPrices[conversionUpgrade[msg.sender]];
        // uint256 approv = pza.allowance(msg.sender, address(this));
        // require( approv >= price, "Oven: Insufficient Allowance");
        pza.transferFrom(msg.sender, address(this), price);

        conversionUpgrade[msg.sender] += 1;
    }
    // --------------------------------------------------------PUBLIC - Normal--------------------------------------------------------



    /// @dev Put dough into oven to receive pizza, amount depends on upgrade status
    /// @param amount Amount of Tokens to add to pizza oven
    function bake(uint256 amount) external {
        require(doughDeposit[msg.sender] == 0, "Oven still in use");
        // uint256 spendable = dough.allowance(msg.sender, address(this));
        // require(spendable >= amount, "Allowance insufficient");
        dough.burnFrom(msg.sender, amount);
        // dough.transferFrom(msg.sender, address(this), amount);
        // dough.burn(amount);
        doughDeposit[msg.sender] = amount;
        depositTime[msg.sender] = block.timestamp;
    }




    function withdraw() external {
        require(doughDeposit[msg.sender] > 0, "Oven: Empty oven, cannot withdraw");
        require(block.timestamp - depositTime[msg.sender] >= waitTime, "Oven: Pizza is not ready");

        uint256 totalPZA = doughDeposit[msg.sender] / conversionRates[conversionUpgrade[msg.sender]];
        uint256 halfBurn = totalPZA * burnRates[burnUpgrade[msg.sender]] / 200;
        uint256 pizzaout = totalPZA - 2*halfBurn;
        doughDeposit[msg.sender] = 0;
        //implicit burn half
        pza.mint(projectwallet, halfBurn);
        pza.mint(msg.sender, pizzaout);
    }

    // --------------------------------------------------------PUBLIC - Owner--------------------------------------------------------
    function updateWaitTime(uint256 time) external onlyOwner {
        if(time > 0) {
        waitTime = time;
        }
    }
    function updateBurn(uint256[] calldata rates, uint256[] calldata prices) external onlyOwner {
        require(rates.length == 4 && prices.length == 4, "!input");
        for(uint i; i < 4; i++) {
            if(rates[i] > 0) {
                burnRates[i] = rates[i];
            }
            if(prices[i] > 0) {
                burnPrices[i] = prices[i];
            }            
        }
    }
    function updateConversion(uint256[] calldata rates, uint256[] calldata prices) external onlyOwner {
        require(rates.length == 4 && prices.length == 4, "!input");
        for(uint i; i < 4; i++) {
            if(rates[i] > 0) {
                conversionRates[i] = rates[i];
            }
            if(prices[i] > 0) {
                conversionPrices[i] = prices[i];
            }            
        }
    }    
}