/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-01
*/

// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.14;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/interfaces/IAssetPricer.sol


pragma solidity ^0.8.14;

interface IAssetPricer {
    function valuation(
        address _asset,
        address _quote,
        uint256 _amount
    ) external view returns (uint256);
}

// File: contracts/pricers/TrivialPricer.sol



pragma solidity 0.8.14;



/**
 * Pricer returning
 */
contract TrivialPricer is IAssetPricer {
    constructor() {}

    /**
     * note normalizes asset value to 18 decimals
     * @param _asset asset to normalize
     */
    function getTotalValue(address _asset) public view returns (uint256 _value) {
        _value = IERC20(_asset).totalSupply() * 10**(18 - IERC20(_asset).decimals());
    }

    /**
     * - calculates the value in reqt of the input LP amount provided
     * @param _asset assumed to be the quote
     * @param _amount the amount
     * @return _value normalzed value
     */
    function valuation(
        address _asset,
        address,
        uint256 _amount
    ) external view override returns (uint256 _value) {
        _value = _amount * 10**(18 - IERC20(_asset).decimals());
    }

    // markdown function for bond valuation
    function markdown(address _asset) external view returns (uint256) {
        return getTotalValue(_asset);
    }
}