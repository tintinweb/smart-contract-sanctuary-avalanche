/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.6;

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * Available since v4.1.
 */


contract CrowdFunding is Ownable {
    event Launch(
        uint256 id,
        address indexed creator,
        uint256 goal,
        uint256 startAt,
        uint256 endAt
    );
    event Cancel(uint256 id);
    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Unpledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Claim(uint256 id);
    event Refund(uint256 indexed id, address indexed caller, uint256 amount);

     enum CampaignState { 
        OPEN,
        CANCELLED,
        ENDED
    }


    struct Campaign {
        address creator;
        uint256 goal;
        uint256 pledged;
        uint256 startAt;
        uint256 endAt;
        bool claimed;
        uint256 id;
        bool isCancelled;
    }

    uint256 public immutable MAX_WHITELIST = 500;

    IERC20 public immutable token;

    uint256 public campaignCount;
    uint256 public whitelistCount;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;
    mapping(address => bool) public whitelist;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        require(
            whitelistCount + _addresses.length <= MAX_WHITELIST,
            "Whitelist count should be less than 500"
        );
        
        whitelistCount += _addresses.length;

        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function launch(
        uint256 _goal,
        uint256 _startAt,
        uint256 _endAt
    ) external returns (uint256) {
        uint256 userBalance = 0;
        userBalance = IERC20(token).balanceOf(msg.sender);
        //uint256 userBalance = address(msg.sender).balance;
        require(userBalance > 0, "Creator balance should be greater than 0"); //checks if the user has a token for launch
        require(whitelist[msg.sender], "This address does not belong to whitelist");
        require(_startAt >= block.timestamp,"startAt should be greater then current time");
        require(_endAt >= _startAt, "endAt should be greater then startAt");
        require(_endAt > block.timestamp, "endAt > max duration");
        require(_goal > 0, "Goal should be grater than 0");
        
        campaignCount = 0;
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false,
            id: campaignCount,
            isCancelled: false
        });

        campaignCount +=1;

        emit Launch(campaignCount, msg.sender, _goal, _startAt, _endAt);
        return campaignCount;
    }

    function cancel(uint256 _id) external returns (bool) {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        require(getCampaignState(campaign.id) == CampaignState.OPEN, "Campaign is already closed.");
        require(_id == campaign.id, "The given ID is not in the campaigns");
        
        campaign.isCancelled = true;
        campaigns[_id] = campaign;
        emit Cancel(_id);
        return true;
    }

    function getCampaignState(uint256 _campaignId) public view returns(CampaignState) {
        Campaign memory _campaign = campaigns[_campaignId]; // get the auction

        if(_campaign.isCancelled) return CampaignState.CANCELLED; // If the campaign is cancelled return CANCELLED
        if(block.timestamp >= _campaign.endAt) return CampaignState.ENDED; // The campaign is over if the block timestamp is greater than the end timestamp, return ENDED
        return CampaignState.OPEN; // Otherwise return OPEN
    }

    function pledge(uint256 _id, uint256 _amount) external returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "the address does not belong to the creator");
        require(whitelist[msg.sender],"this address does not belong to any of the whitelistes addresses");
        require(getCampaignState(campaign.id) != CampaignState.CANCELLED, "Campaign is closed.");
        require(block.timestamp > campaign.startAt, "not started yet");
        require(block.timestamp < campaign.endAt, "already ended");
        require(_amount > 0, "The amount that pleged should be greater than 0");
        require(!(_amount > campaign.goal), "The amount that pleged cannot be greater than the goal");
        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
        return _amount;
    }

    function unpledge(uint256 _id, uint256 _amount) external returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        require( msg.sender == campaign.creator,"Only creators or whitelisted adrresses can unpledge");
        require(whitelist[msg.sender],"Only creators or whitelisted adrresses can unpledge");
        require(getCampaignState(campaign.id) != CampaignState.CANCELLED, "Campaign is closed.");
        require(block.timestamp >= campaign.startAt, "not started yet");
        require(block.timestamp <= campaign.endAt, "already ended");
        
        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Unpledge(_id, msg.sender, _amount);
        return _amount;
    }

    function claim(uint256 _id) external returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "not ended yet");
        require(getCampaignState(campaign.id) != CampaignState.CANCELLED, "Campaign is closed.");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);

        return _id;
    }

    function refund(uint256 _id) external returns (uint256) {
        Campaign storage campaign = campaigns[_id];
        require(
            msg.sender == campaign.creator,
            "Only campaign creator can refund"
        );
        require(block.timestamp > campaign.endAt, "not ended yet");
        require(campaign.pledged < campaign.goal, "pledge < goal");
        require(getCampaignState(campaign.id) != CampaignState.CANCELLED, "Campaign is closed.");

        uint256 ballance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        campaign.pledged -= ballance;
        //update pledge amount

        token.transfer(msg.sender, ballance);

        emit Refund(_id, msg.sender, ballance);
        return ballance;
    }
}