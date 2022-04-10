/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

abstract contract IERC20
{
    function transfer(address to, uint value) virtual external returns (bool);
}

struct PaymentEntry
{
    bool exists;
    uint256 endBlock;
}

contract SnowsightManager
{
    uint8 public constant version = 1;

    address public admin;
    uint256 public paymentPerBlock;
    uint256 public maximumPaymentBlocks;
    uint256 public minimumPaymentBlocks;
    bool public paymentsEnabled;

    mapping(address => PaymentEntry) public payments;

    event Marker_uint32(uint32 marker);

    constructor()
    {
        admin = msg.sender;
        paymentPerBlock = 1;
        maximumPaymentBlocks = 43200;
        minimumPaymentBlocks = 1800;
        paymentsEnabled = true;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function setAdmin(address payable newAdmin) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");
        admin = newAdmin;
    }

    function setPaymentsEnabled(bool enabled) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");
        paymentsEnabled = enabled;
    }

    function setPaymentPerBlock(uint256 newPaymentPerBlock) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");
        paymentPerBlock = newPaymentPerBlock;
    }

    function setMaximumPaymentBlocks(uint256 newMaximumPaymentBlocks) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");
        maximumPaymentBlocks = newMaximumPaymentBlocks;
    }

    function setMinimumPaymentBlocks(uint256 newMinimumPaymentBlocks) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");
        minimumPaymentBlocks = newMinimumPaymentBlocks;
    }

    function calculateMaxPayment() public view returns (uint256)
    {
        return calculate_max_payment(msg.sender);
    }

    function calculate_max_payment(address payer) internal view returns (uint256)
    {
        uint256 maxPayment = 0;

        if (payments[payer].exists && payments[payer].endBlock > block.number)
        {
            maxPayment = (maximumPaymentBlocks - (payments[payer].endBlock - block.number)) * paymentPerBlock;
        }
        else
        {
            maxPayment = maximumPaymentBlocks * paymentPerBlock;
        }

        return maxPayment;
    }

    function pay() external payable
    {
        emit Marker_uint32(1);
        require (paymentsEnabled == true, "ERROR_PAYMENTS_DISABLED");
        require (msg.value <= calculate_max_payment(msg.sender), "ERROR_PAYMENT_TOO_LARGE");
        require (msg.value >= minimumPaymentBlocks * paymentPerBlock, "ERROR_PAYMENT_TOO_SMALL");
        emit Marker_uint32(1);
        if (payments[msg.sender].exists)
        {
            if (payments[msg.sender].endBlock > block.number)
            {
                // account has a payment active
                payments[msg.sender].endBlock = payments[msg.sender].endBlock + (msg.value * paymentPerBlock);
            }
            else
            {
                // account exists, but payment expired
                payments[msg.sender].endBlock = block.number + (msg.value * paymentPerBlock);
            }
        }
        else
        {
            emit Marker_uint32(1);
            // account does not exist yet
            payments[msg.sender].exists = true;
            payments[msg.sender].endBlock = block.number + (msg.value * paymentPerBlock);
        }

        payable(admin).transfer(msg.value);
    }

    function transferEth(uint256 amount) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");
        payable(msg.sender).transfer(amount);
    }

    function transferToken(address tokenAddress, uint256 amount) external
    {
        require (msg.sender == admin, "ERR_ADMIN_PROTECT");

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }
}