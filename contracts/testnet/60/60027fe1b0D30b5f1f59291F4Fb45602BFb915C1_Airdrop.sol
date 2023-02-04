// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IARC {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 rawAmount) external returns (bool);
}

/**
 *  Contract for administering the Airdrop of xARC to ARC holders.
 *  Arbitrary amount ARC will be made available in the airdrop. After the
 *  Airdrop period is over, all unclaimed ARC will be transferred to the
 *  community treasury.
 */
contract Airdrop {
    address public immutable arc;
    address public owner;
    address public whitelister;
    address public remainderDestination;

    // amount of ARC to transfer
    mapping(address => uint256) public withdrawAmount;

    uint256 public totalAllocated;
    uint256 public airdropSupply;

    bool public claimingAllowed;

    /**
     * Initializes the contract. Sets token addresses, owner, and leftover token
     * destination. Claiming period is not enabled.
     *
     * @param arc_ the ARC token contract address
     * @param owner_ the privileged contract owner
     * @param remainderDestination_ address to transfer remaining ARC to when
     *     claiming ends. Should be community treasury.
     */
    constructor(
        uint256 supply_,
        address arc_,
        address owner_,
        address remainderDestination_
    ) {
        require(owner_ != address(0), "Airdrop::Construct: invalid new owner");
        require(arc_ != address(0), "Airdrop::Construct: invalid arc address");

        airdropSupply = supply_;
        arc = arc_;
        owner = owner_;
        remainderDestination = remainderDestination_;
    }

    /**
     * Changes the address that receives the remaining ARC at the end of the
     * claiming period. Can only be set by the contract owner.
     *
     * @param remainderDestination_ address to transfer remaining ARC to when
     *     claiming ends.
     */
    function setRemainderDestination(address remainderDestination_) external {
        require(
            msg.sender == owner,
            "Airdrop::setRemainderDestination: unauthorized"
        );
        remainderDestination = remainderDestination_;
    }

    /**
     * Changes the contract owner. Can only be set by the contract owner.
     *
     * @param owner_ new contract owner address
     */
    function setOwner(address owner_) external {
        require(owner_ != address(0), "Airdrop::setOwner: invalid new owner");
        require(msg.sender == owner, "Airdrop::setOwner: unauthorized");
        owner = owner_;
    }

    /**
     *  Optionally set a secondary address to manage whitelisting (e.g. a bot)
     */
    function setWhitelister(address addr) external {
        require(msg.sender == owner, "Airdrop::setWhitelister: unauthorized");
        whitelister = addr;
    }

    function setAirdropSupply(uint256 supply) external {
        require(msg.sender == owner, "Airdrop::setAirdropSupply: unauthorized");
        require(
            !claimingAllowed,
            "Airdrop::setAirdropSupply: claiming in session"
        );
        require(
            supply >= totalAllocated,
            "Airdrop::setAirdropSupply: supply less than total allocated"
        );
        airdropSupply = supply;
    }

    /**
     * Enable the claiming period and allow user to claim ARC. Before
     * activation, this contract must have a ARC balance equal to airdropSupply
     * All claimable ARC tokens must be whitelisted before claiming is enabled.
     * Only callable by the owner.
     */
    function allowClaiming() external {
        require(
            IARC(arc).balanceOf(address(this)) >= airdropSupply,
            "Airdrop::allowClaiming: incorrect ARC supply"
        );
        require(msg.sender == owner, "Airdrop::allowClaiming: unauthorized");
        claimingAllowed = true;
        emit ClaimingAllowed();
    }

    /**
     * End the claiming period. All unclaimed ARC will be transferred to the address
     * specified by remainderDestination. Can only be called by the owner.
     */
    function endClaiming() external {
        require(msg.sender == owner, "Airdrop::endClaiming: unauthorized");
        require(claimingAllowed, "Airdrop::endClaiming: Claiming not started");

        claimingAllowed = false;

        // Transfer remainder
        uint256 amount = IARC(arc).balanceOf(address(this));
        require(
            IARC(arc).transfer(remainderDestination, amount),
            "Airdrop::endClaiming: Transfer failed"
        );

        emit ClaimingOver();
    }

    /**
     * Withdraw your ARC. In order to qualify for a withdrawal, the
     * caller's address must be whitelisted. All ARC must be claimed at
     * once. Only the full amount can be claimed and only one claim is
     * allowed per user.
     */
    function claim() external {
        require(claimingAllowed, "Airdrop::claim: Claiming is not allowed");
        require(
            withdrawAmount[msg.sender] > 0,
            "Airdrop::claim: No ARC to claim"
        );

        uint256 amountToClaim = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;

        require(
            IARC(arc).transfer(msg.sender, amountToClaim),
            "Airdrop::claim: Transfer failed"
        );

        emit ArcClaimed(msg.sender, amountToClaim);
    }

    /**
     * Whitelist multiple addresses in one call.
     * All parameters are arrays. Each array must be the same length. Each index
     * corresponds to one (address, arc) tuple. Callable by the owner or whitelister.
     */
    function whitelistAddresses(
        address[] memory addrs,
        uint256[] memory arcOuts
    ) external {
        require(
            !claimingAllowed,
            "Airdrop::whitelistAddresses: claiming in session"
        );
        require(
            msg.sender == owner || msg.sender == whitelister,
            "Airdrop::whitelistAddresses: unauthorized"
        );
        require(
            addrs.length == arcOuts.length,
            "Airdrop::whitelistAddresses: incorrect array length"
        );
        for (uint256 i; i < addrs.length; ++i) {
            address addr = addrs[i];
            uint256 arcOut = arcOuts[i];
            totalAllocated = totalAllocated + arcOut - withdrawAmount[addr];
            withdrawAmount[addr] = arcOut;
        }
        require(
            totalAllocated <= airdropSupply,
            "Airdrop::whitelistAddresses: Exceeds ARC allocation"
        );
    }

    // Events
    event ClaimingAllowed();
    event ClaimingOver();
    event ArcClaimed(address claimer, uint256 amount);
}