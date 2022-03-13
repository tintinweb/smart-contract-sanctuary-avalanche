/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-12
*/

pragma solidity ^0.4.15;

contract Owned {
    address public owner;

    function Owned() { owner = msg.sender; }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Bounty0xPresale is Owned {

    // contract closed
    bool private saleHasEnded = false;

    // set whitelisting filter on/off
    bool private isWhitelistingActive = true;

    // Keep track of the total funding amount
    uint256 public totalFunding;

    // Minimum and maximum amounts per transaction for public participants
    uint256 public constant MINIMUM_PARTICIPATION_AMOUNT =   3 ether;
    uint256 public MAXIMUM_PARTICIPATION_AMOUNT = 10 ether;

    // Minimum and maximum goals of the presale
    uint256 public constant PRESALE_MINIMUM_FUNDING =  100 ether;
    uint256 public constant PRESALE_MAXIMUM_FUNDING = 1000 ether;

    // Total preallocation in wei
    uint256 public constant TOTAL_PREALLOCATION = 500 ether;


    uint256 public constant PRESALE_START_DATE = 1511186400;
    uint256 public constant PRESALE_END_DATE = PRESALE_START_DATE + 2 weeks;

    uint256 public constant OWNER_CLAWBACK_DATE = 1512306000;


    mapping (address => uint256) public balanceOf;

    /// List of whitelisted participants
    mapping (address => bool) public earlyParticipantWhitelist;


    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);
    
    function Bounty0xPresale () payable {
    }

    /// @notice A participant sends a contribution to the contract's address
    ///         between the PRESALE_STATE_DATE and the PRESALE_END_DATE
    /// @notice Only contributions between the MINIMUM_PARTICIPATION_AMOUNT and
    ///         MAXIMUM_PARTICIPATION_AMOUNT are accepted. Otherwise the transaction
    ///         is rejected and contributed amount is returned to the participant's
    ///         account
    /// @notice A participant's contribution will be rejected if the presale
    ///         has been funded to the maximum amount
    function () payable {
        require(!saleHasEnded);
        // A participant cannot send funds before the presale start date
        require(now > PRESALE_START_DATE);
        // A participant cannot send funds after the presale end date
        require(now < PRESALE_END_DATE);
        // A participant cannot send less than the minimum amount
        require(msg.value >= MINIMUM_PARTICIPATION_AMOUNT);
        // A participant cannot send more than the maximum amount
        require(msg.value <= MAXIMUM_PARTICIPATION_AMOUNT);
        // If whitelist filtering is active, if so then check the contributor is in list of addresses
        if (isWhitelistingActive) {
            require(earlyParticipantWhitelist[msg.sender]);
            require(safeAdd(balanceOf[msg.sender], msg.value) <= MAXIMUM_PARTICIPATION_AMOUNT);
        }
        // A participant cannot send funds if the presale has been reached the maximum funding amount
        require(safeAdd(totalFunding, msg.value) <= PRESALE_MAXIMUM_FUNDING);
        // Register the participant's contribution
        addBalance(msg.sender, msg.value);    
    }
    
    /// @notice The owner can withdraw ethers after the presale has completed,
    ///         only if the minimum funding level has been reached
    function ownerWithdraw(uint256 value) external onlyOwner {
        if (totalFunding >= PRESALE_MAXIMUM_FUNDING) {
            owner.transfer(value);
            saleHasEnded = true;
        } else {
        // The owner cannot withdraw before the presale ends
        require(now >= PRESALE_END_DATE);
        // The owner cannot withdraw if the presale did not reach the minimum funding amount
        require(totalFunding >= PRESALE_MINIMUM_FUNDING);
        // Withdraw the amount requested
        owner.transfer(value);
        }
    }


    function participantWithdrawIfMinimumFundingNotReached(uint256 value) external {

        require(now >= PRESALE_END_DATE);

        require(totalFunding <= PRESALE_MINIMUM_FUNDING);

        assert(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        msg.sender.transfer(value);
    }


    function ownerClawback() external onlyOwner {

        require(now >= OWNER_CLAWBACK_DATE);

        owner.transfer(this.balance);
    }

    // Set addresses in whitelist
    function setEarlyParicipantWhitelist(address addr, bool status) external onlyOwner {
        earlyParticipantWhitelist[addr] = status;
    }

    /// Ability to turn of whitelist filtering after 24 hours
    function whitelistFilteringSwitch() external onlyOwner {
        if (isWhitelistingActive) {
            isWhitelistingActive = false;
            MAXIMUM_PARTICIPATION_AMOUNT = 30000 ether;
        } else {
            revert();
        }
    }

    /// @dev Keep track of participants contributions and the total funding amount
    function addBalance(address participant, uint256 value) private {
        // Participant's balance is increased by the sent amount
        balanceOf[participant] = safeAdd(balanceOf[participant], value);
        // Keep track of the total funding amount
        totalFunding = safeAdd(totalFunding, value);
        // Log an event of the participant's contribution
        LogParticipation(participant, value, now);
    }

    /// @dev Throw an exception if the amounts are not equal
    function assertEquals(uint256 expectedValue, uint256 actualValue) private constant {
        assert(expectedValue == actualValue);
    }

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}