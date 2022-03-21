//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20PoolEscrow.sol";

/// @title ERC-20 Pool Escrow Contract
/// @notice Escrow contract that can deal with ERC-20 tokens withdrawals and deposits and keeps a global number of the deposited amount
/// @dev This escrow contract deals with one token implicitely using the interface IERC20. This means that token filtering must happen upstream to prevent mapping to an incorrect concrete ERC-20 token.
contract Erc20PoolEscrow is IERC20PoolEscrow, Ownable {
    address         _authorized;

    IERC20 internal _token;
    mapping(address => uint256) public _escrowBalance;
    uint256 private _totalPool;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event AllocatedPool(uint256 amount);
    event ChangedAuthorized(address indexed newAuthorizedAddr);

    /// @notice This contract needs to be explicitely initialized with a unique ERC-20 token
    /// @param token ERC-20 token the escrow contract will deal with
    constructor(IERC20 token) {
        _authorized = _msgSender();
        _token = token;
    }

    /// @notice Returns a wallet's balance from the escrow
    function getBalance(address wallet)
    override
    public
    view
    returns(uint256) {
        return _escrowBalance[wallet];
    }

    /// @notice Returns the total amount of ERC-20 token available in the pool
    function getPool()
    override
    public 
    view 
    returns(uint256) {
        return _totalPool;
    }

    /// @notice Inflates token and adds them to the pool
    /// @param tokenAmount Number of tokens to mint and add to the pool
    function inflatePool(uint256 tokenAmount)
    override
    onlyAuthorized
    public {
        bytes memory payload = abi.encodeWithSignature("mint(address,uint256)", address(this), tokenAmount);
        (bool success, bytes memory returnData) = address(_token).call(payload);

        console.log(string(returnData));

        require(success == true, "Erc20PoolEscrow: Could not generate inflation");

        _totalPool += tokenAmount;
    }

    /// @notice Allocates to the pool for participants election
    /// @param amount Amount of tokens to be added to the pool
    function allocatePool(address spender, uint256 amount)
    override 
    public {
        require(address(_token) != address(0), "Erc20PoolEscrow : token isn't initialized");
        require(_token.transferFrom(spender, address(this), amount));

        _totalPool += amount;

        emit AllocatedPool(amount);
    }

    /// @notice Allocates to an elected user
    /// @param amount Amount of tokens to be added to the user's balance
    function allocateUser(address user, uint256 amount)
    override
    onlyAuthorized
    public {
        require(amount <= _totalPool, "Erc20PoolEscrow : amount is greater than pool's balance");

        _totalPool -= amount;
        _escrowBalance[user] += amount;
    }

    /// @notice Allocates a number of individualAmounts to a list of users
    /// @param numberElected TThe number of users that got elected
    /// @param individualAmount Amount of tokens to be added to the user's balance
    function allocateListUsers(address[] memory users, uint256 numberElected, uint256 individualAmount)
    override
    onlyAuthorized
    public {
        require(numberElected * individualAmount <= _totalPool, "Erc20PoolEscrow : amount is greater than pool's balance");

        _totalPool -= numberElected * individualAmount;

        for (uint i=0; i < numberElected; i++) {
            _escrowBalance[users[i]] += individualAmount;
        }
    }

    /// @notice Transfers from an escrow balance to the Pool
    /// @param amount Amount of tokens to transfer to the pool
    function transferFromBalanceToPool(address spender, uint256 amount)
    override
    onlyAuthorized
    public {
        require(amount <= _escrowBalance[spender], "Erc20PoolEscrow : amount is greater than balance");

        _escrowBalance[spender] -= amount;
        _totalPool += amount;
    }

    /// @notice Deposits a fixed amount of ERC-20 token nominatively into the escrow contract
    /// @param amount The amount of this token to deposit in wei
    function deposit(uint256 amount) 
    override
    public {
        require(address(_token) != address(0), "Erc20PoolEscrow : token isn't initialized");
        require(_token.allowance(_msgSender(), address(this)) >= amount, "Erc20PoolEscrow: allowance is insufficient to approve transfer");

        require(_token.transferFrom(_msgSender(), address(this), amount));

        _escrowBalance[_msgSender()] += amount;

        emit Deposit(_msgSender(), amount);
    }

    /// @notice Withdraws from calling user balance a fixed amount of ERC-20 token
    /// @param amount Amount to withdraw in wei
    function withdraw(uint256 amount)
    override
    public {
        require(address(_token) != address(0), "Erc20PoolEscrow : token isn't initialized");
        require(amount <= _escrowBalance[_msgSender()], "Erc20PoolEscrow : amount is greater than balance");

        _escrowBalance[_msgSender()] -= amount;

        require(_token.transfer(_msgSender(), amount));
    }

    /// @notice Withdraws the whole balance of the calling user
    function withdrawAll()
    override
    public {
        require(address(_token) != address(0), "Erc20PoolEscrow : token isn't initialized");

        uint256 amount = _escrowBalance[_msgSender()];
        _escrowBalance[_msgSender()] = 0;

        require(_token.transfer(_msgSender(), amount));
    }

    function changeAuthorized(address newAuthorizedAddr)
    override
    onlyOwner
    public
    {
        _authorized = newAuthorizedAddr;
        emit ChangedAuthorized(newAuthorizedAddr);
    }

    modifier onlyAuthorized() {
        require(_msgSender() == _authorized);
        _;
    }
}