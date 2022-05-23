//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20PoolEscrow.sol";

import "./IParticipantsVault.sol";

import "./ParticipantVaultStorage.sol";

/// @title Participants' vault for PoE
/// @notice Vault used during PoE to keep a ledger of users' balance and automatic participation to cycles
contract ParticipantsVault is ParticipantVaultStorage, IParticipantsVault, Ownable {

    using LinkedLists for LinkedLists.CDLLBalance;

    constructor(IERC20PoolEscrow poolEscrow) {
        SharedStorage storage ds = sharedStorage();
        ds._poolEscrow = poolEscrow;
    }

    function getPoolEscrowAddress()
    override
    view
    public
    returns (IERC20PoolEscrow) {
        SharedStorage storage ds = sharedStorage();
        
        return ds._poolEscrow;
    }

    function initForDelegator(address poolEscrowAddress)
    override
    onlyOwner
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow = IERC20PoolEscrow(poolEscrowAddress);
    }

    /// @notice Inflates number of LBC based on calculation from Proof of Entry
    /// @param lbcAmount Amount of LBC to base the inflation on
    function inflateFromPoe(uint256 lbcAmount)
    override
    onlyOwner
    public {
        SharedStorage storage ds = sharedStorage();
        
        ds._poolEscrow.inflatePool(lbcAmount);
    }

    /// @notice Burns an amount of tokens from user wallet
    function burnAmountFromWallet(uint256 amount)
    override
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow.burnAmountFromWallet(_msgSender(), amount);
    }

    /// @notice Burns an amount of tokens from user wallet
    function burnAmountFromBalance(address sender, uint256 amount)
    override
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow.burnAmountFromBalance(sender, amount);
    }

    /// @notice Transfers an amount of tokens to the pool
    function sendAmountToPool(uint256 amount)
    override
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow.allocatePool(_msgSender(), amount);
    }

    function addToUserBalanceFromPool(address wallet, uint256 amount)
    override
    onlyOwner
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow.allocateUser(wallet, amount);
    }

    function addToUserListBalanceFromPool(address[] memory wallets, uint256 numberElected, uint256 blockReward)
    override
    onlyOwner
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow.allocateListUsers(wallets, numberElected, blockReward);
    }

    /// @notice Participates to a cycle withdrawing and adding to the pool directly from user's balance inside the escrow
    function setParticipationAmountFromBalance(address spender, uint256 amount)
    override
    onlyOwner
    public {
        SharedStorage storage ds = sharedStorage();

        ds._poolEscrow.transferFromBalanceToPool(spender, amount);
    }

    /// @notice Retrieves amount of automatic participation for an address
    /// @param addr Address for which balance is retrieved
    function getAutomaticParticipationAmount(address addr)
    override
    public
    view
    returns(uint256) {
        SharedStorage storage ds = sharedStorage();

        return ds._automaticParticipations.getBalanceOf(addr);
    }

    /// @notice Sets an amount to be automatically sent for each cycle
    /// @param participationAmount The amount of LBC to set as automatic participation
    /// @dev Might limit to 1 LBC for 1 <-> 1 Cardinality and flat mapping of linked list nodes
    function setAutomaticParticipationAmount(uint256 participationAmount) 
    override
    public {
        SharedStorage storage ds = sharedStorage();
        
        require(participationAmount <= ds._poolEscrow.getBalance(_msgSender()), "ParticipantsVault: participationAmount is greater than user's balance");

        ds._automaticParticipations.setBalanceOf(_msgSender(), participationAmount);
    }

    /// @notice Deposits an amount of ERC-20 into the participants vault and sets the automatic participation
    /// @param amount Amount of ERC-20 to deposit in wei
    /// @param participationAmount The amount of LBC to set as automatic participation
    function depositAutomaticParticipationAmount(uint256 amount, uint256 participationAmount) 
    override
    public {
        SharedStorage storage ds = sharedStorage();

        require(participationAmount <= ds._poolEscrow.getBalance(_msgSender()) + amount, "ParticipantsVault: participationAmount would be greater than updated user's balance");

        //ds._poolEscrow.deposit(amount);
        setAutomaticParticipationAmount(participationAmount);
    }

    /// @notice Returns the total amount of ERC-20 token available in the pool
    function getPool()
    override
    public
    view
    returns(uint256) {
        SharedStorage storage ds = sharedStorage();

        return ds._poolEscrow.getPool();
    }
}