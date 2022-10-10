/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-10
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IERC20
{
    function balanceOf(address _account) external view returns (uint256 _balance);

    function approve(address _spender, uint256 _amount) external returns (bool _success);
    function transfer(address _to, uint256 _amount) external returns (bool _success);
}

interface IAaveV3Pool
{
    function ADDRESSES_PROVIDER() external view returns (address _addressesProvider);

	function supply(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;

    // leverageAmount = baseAmount * (maxLTV / (1 - maxLTV))
	// function flashLoan(address _receiverAddress, address[] calldata _assets, uint256[] calldata _amounts, uint256[] calldata _interestRateModes, address _onBehalfOf, bytes calldata _params, uint16 _referralCode) external;
	// function repayWithATokens(address _asset, uint256 _amount, uint256 _interestRateMode) external returns (uint256 _repaidAmount);
}

interface IAaveV3FlashLoanReceiver
{
    function POOL() external view returns (address _pool);
    function ADDRESSES_PROVIDER() external view returns (address _addressesProvider);

    function executeOperation(address[] calldata _assets, uint256[] calldata _amounts, uint256[] calldata _premiums, address _initiator, bytes calldata _params) external returns (bool _success);
}

contract AaveV3FlashLoanReceiver is IAaveV3FlashLoanReceiver
{
    address public immutable POOL;
    address public immutable ADDRESSES_PROVIDER;

    mapping(address => bool) public whitelist;

    constructor(address _pool)
    {
        POOL = _pool;
        ADDRESSES_PROVIDER = IAaveV3Pool(POOL).ADDRESSES_PROVIDER();
        whitelist[msg.sender] = true;
    }

    function updateWhitelist(address[] calldata _accounts, bool _enabled) external
    {
        require(whitelist[msg.sender], "access denied");
        for (uint256 _i = 0; _i < _accounts.length; _i++) {
            whitelist[_accounts[_i]] = _enabled;
        }
    }

    function recoverFunds(address _asset) external
    {
        require(whitelist[msg.sender], "access denied");
        require(IERC20(_asset).transfer(msg.sender, IERC20(_asset).balanceOf(address(this))), "transfer failure");
    }

    function executeOperation(address[] calldata _assets, uint256[] calldata _amounts, uint256[] calldata, address _initiator, bytes calldata) external returns (bool _success)
    {
        require(whitelist[_initiator], "access denied");
        require(msg.sender == POOL, "invalid sender");
        for (uint256 _i = 0; _i < _amounts.length; _i++) {
            address _asset = _assets[_i];
            uint256 _amount = _amounts[_i];
            require(IERC20(_asset).approve(POOL, _amount), "approve failure");
            IAaveV3Pool(POOL).supply(_asset, _amount, _initiator, 0);
        }
        return true;
    }
}