// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title This smart contract is for the 2023 Nigerian Presidential Election which is acting as a tool for decentralized Staking
 * @author Contract for AvraQ.com Developed by Arasomwan Aisosa Goodluck,
 *
 */

/**
 * @title IERC20 Interface, as this contract would utilize a ERC-20 token
 * @dev Implementing a ERC-20 Interface
 */

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable {
    address public owner;

    /**
     * @dev The Ownable Constructor set the oroginal 'owner' of the contract to the sender
     */

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

error IDdoesNotExist(uint16 id);
error NotaWinner();
error StakingStillOpen();
error StakingClose();

contract NigeriaStaking is Ownable {
    /*Contract State*/
    enum StakingState {
        OPEN,
        FINISHED
    }

    StakingState public state; //Variable state whether the election is still running or it is closed

    uint8 public winner; // Variable to hold the winner of the election
    //Initializing the number of Presidential Aspirant contesting for 2023 Nugeria General Election
    uint8 constant NUM_OF_CANDIDATE = 6;

    uint256 private lost_staking_pool;
    uint256 private totalAmount;

    /**
     * @dev Using mapping to store the aspirant ID to check if candidate exist


    /**
     * @dev The voteChoiceAmount variable store the address of staking corresponding inputing their choice and the amount stake
     */
    mapping(address => mapping(uint8 => uint256)) private voteChoiceAmount;

    /**
     * @dev The VoteAmount stores the amount of stake per aspirant,this would be used in the sharing of Successful Stake
     */
    mapping(uint8 => uint256) private voteAmount;

    IERC20 tokenAddress; // This would be the gateway in interacting with the ERC-20 Contract

    constructor(address _tokenAddress) Ownable() {
        state = StakingState.OPEN; //We declare the staking open
        tokenAddress = IERC20(_tokenAddress);
    }

    event StakeSuccessful(
        address indexed from,
        uint8 indexed candidate,
        uint256 amount
    ); // An Event to indicate Successful Staking

    /**
     * @dev stake is called to place a bet on the preferred presidential aspirant
     * @param candidateId The Id of the presidential aspirant
     * @param amount_to_stake The amount that is willing to be stake
     */

    function stake(uint8 candidateId, uint256 amount_to_stake) public {
        //We first check to see if the stake is currently open
        if (state == StakingState.FINISHED) {
            revert StakingClose();
        }
        // We then check to see if the required candidateId does exist
        if (candidateId > NUM_OF_CANDIDATE) {
            revert IDdoesNotExist({id: candidateId});
        }

        //We then transfer the token from the caller's address to the contract Address
        bool transferSuccessful = tokenAddress.transferFrom(
            msg.sender,
            address(this),
            amount_to_stake
        );
        require(transferSuccessful, "money not received"); //We make sure the transfer is succcessful

        voteChoiceAmount[msg.sender][candidateId] += amount_to_stake; // we increase their staking amount

        voteAmount[candidateId] += amount_to_stake; // We then increase the amount staked for the particular Aspirant
        totalAmount += amount_to_stake; // We then increase the total amount staked to the new Amount

        emit StakeSuccessful(msg.sender, candidateId, amount_to_stake);
    }

    /**
     * @dev claimReward to transfer token after the end of the staking period to the callers if the stake was guess correctly
     * @return boolean Stating if the claimReward call is Successful
     * @notice This claimReward will only execute if the Staking Process is over
     */

    event ClaimSuccessful(address indexed from, uint256 amount); // An Event to indicate Successful Claiming

    function claimReward() public returns (bool) {
        //Check to see if the staking has ended
        if (state == StakingState.OPEN) {
            revert StakingStillOpen();
        }
        //We then check to see the user has corrected staked for the winner
        uint256 correct_entry = voteChoiceAmount[msg.sender][winner]; // We store a local copy of the total amout the users got
        if (correct_entry == 0) {
            revert NotaWinner(); //We revert the caller didnt stake correctly on the winner
        }

        voteChoiceAmount[msg.sender][winner] = 0; // Since we have stored a local amount, We can then clear the Storage data to prevent re-entrary Attack

        //We then calculate ratio of the amount the user would gain from the lost stake pool
        uint256 amount_won = (correct_entry * lost_staking_pool) /
            voteAmount[winner];

        uint256 total_money_won = correct_entry + amount_won; // Add the total amount

        //Then do a ERC20 Transfer of the total amount gain to the sender
        bool transferState = tokenAddress.transfer(msg.sender, total_money_won);
        require(transferState, "money not received"); //We make sure the transfer is succcessful
        emit ClaimSuccessful(msg.sender, total_money_won);
        return true;
    }

    function SetStakingOver(uint8 winnerID) public onlyOwner returns (bool) {
        // We then check to see if the required candidateId does exist
        if (winnerID > NUM_OF_CANDIDATE) {
            revert IDdoesNotExist({id: winnerID});
        }
        winner = winnerID; //We then set the winner ID

        // Set the Staking state to finished
        state = StakingState.FINISHED;

        uint256 totalLoststake = totalAmount - voteAmount[winner]; //We get total lost stake

        uint256 commission = (30 * totalLoststake) / 100; //30 % commission goes to the Avraq Team

        lost_staking_pool = totalLoststake - commission;

        bool transferSuccessful = tokenAddress.transfer(msg.sender, commission);

        return transferSuccessful;
    }

    /**
     * @dev A view function to return the Address Staked for the various Accounts
     */

    function amountStaked(
        address participant,
        uint8 id
    ) public view returns (uint256) {
        return voteChoiceAmount[participant][id];
    }

    /**
     * @dev A view function to return the potential Stake for the various Accounts
     */

    function candidateVotes(uint8 id) public view returns (uint256) {
        return voteAmount[id];
    }

    function totalValueStake() public view returns (uint256) {
        return totalAmount;
    }
}