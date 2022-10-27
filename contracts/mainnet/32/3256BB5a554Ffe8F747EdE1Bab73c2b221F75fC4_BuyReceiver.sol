//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IFATE {
    function getOwner() external view returns (address);
}

interface IYieldFarm {
    function depositRewards(uint256 amount) external;
}

contract BuyReceiver {
    // Fate token
    address public token;

    // Recipients Of Fees
    // TODO: need to set the addresses for treasury and marketing
    address public treasury;
    address public marketing;

    /**
        Minimum Amount Of Fate In Contract To Trigger `trigger` Unless `approved`
            If Set To A Very High Number, Only Approved May Call Trigger Function
            If Set To A Very Low Number, Anybody May Call At Their Leasure
     */
    uint256 public minimumTokensRequiredToTrigger;

    // Address => Can Call Trigger
    mapping(address => bool) public approved;

    // Events
    event Approved(address caller, bool isApproved);

    // Trust Fund Allocation
    uint256 public marketingPercentage = 167;
    uint256 public treasuryPercentage = 833;

    modifier onlyOwner() {
        require(msg.sender == IFATE(token).getOwner(), "Only Fate Token Owner");
        _;
    }

    constructor(address tokenAddress, address treasuryAddress, address marketingAddress) {
        // set initial approved
        approved[msg.sender] = true;

        // only approved can trigger at the start
        minimumTokensRequiredToTrigger = 10**30;

        // set token address
        token = tokenAddress;

        // set treasury address
        treasury = treasuryAddress;

        // set marketing address
        marketing = marketingAddress;
    }

    function trigger() external {
        // Fate Balance In Contract
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance < minimumTokensRequiredToTrigger && !approved[msg.sender]) {
            return;
        }

        // fraction out tokens
        uint256 part1 = (balance * treasuryPercentage) / 1000;
        uint256 part2 = (balance * marketingPercentage) / 1000;

        // send to destinations
        _send(treasury, part1);
        _send(marketing, part2);
    }

    function setApproved(address caller, bool isApproved) external onlyOwner {
        approved[caller] = isApproved;
        emit Approved(caller, isApproved);
    }

    function setMinTriggerAmount(uint256 minTriggerAmount) external onlyOwner {
        minimumTokensRequiredToTrigger = minTriggerAmount;
    }

    function setTreasuryPercentage(uint256 newAllocatiton) external onlyOwner {
        treasuryPercentage = newAllocatiton;
    }

    function setMarketingPercentage(uint256 newAllocatiton) external onlyOwner {
        marketingPercentage = newAllocatiton;
    }

    function withdraw() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function setTreasuryWallet(address wallet) external onlyOwner {
        treasury = wallet;
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        marketing = wallet;
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    receive() external payable {}

    function _send(address recipient, uint256 amount) internal {
        bool s = IERC20(token).transfer(recipient, amount);
        require(s, "Failure On Token Transfer");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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