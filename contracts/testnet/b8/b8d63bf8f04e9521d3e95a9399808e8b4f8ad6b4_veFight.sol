/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// File: contracts/StreetBrawlerz/interfaces/IBallot.sol


pragma solidity 0.8.12;

interface IBallot {
    function forceUnvote(address _user) external;
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/StreetBrawlerz/veFight.sol


pragma solidity 0.8.12;



// solhint-disable-next-line
contract veFight {
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "veFIGHT";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "veFIGHT";

    address public immutable FIGHT;

    /*///////////////////////////////////////////////////////////////
                           FIGHT/VEFIGHT GENERATION
    //////////////////////////////////////////////////////////////*/

    struct GenerationDetails {
        uint128 maxRatio;
        uint64 generationRateNumerator;
        uint64 generationRateDenominator;
    }

    GenerationDetails public genDetails;

    mapping(address => uint256) public fightBalanceOf;
    mapping(address => uint256) private veFightBalance;
    mapping(address => uint256) private userSnapshot;

    /*///////////////////////////////////////////////////////////////
                              VOTING
    //////////////////////////////////////////////////////////////*/

    address[] public arrValidBallots;
    mapping(address => bool) public validBallots;
    mapping(address => mapping(address => bool)) public hasUserVoted;

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error InvalidAmount();
    error InvalidProposal();

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    event UpdatedOwner(address indexed owner);
    event AddedBallot(address indexed ballot);
    event RemovedBallot(address indexed ballot);

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _fightAddress,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator,
        uint256 _maxRatio
    ) {
        owner = msg.sender;

        FIGHT = _fightAddress;

        genDetails = GenerationDetails({
            maxRatio: uint128(_maxRatio),
            generationRateNumerator: uint64(_generationRateNumerator),
            generationRateDenominator: uint64(_generationRateDenominator)
        });
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setGenerationDetails(
        uint256 _maxRatio,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator
    ) external onlyOwner {
        GenerationDetails storage gen = genDetails;
        gen.maxRatio = uint128(_maxRatio);
        gen.generationRateNumerator = uint64(_generationRateNumerator);
        gen.generationRateDenominator = uint64(_generationRateDenominator);
    }

    /*///////////////////////////////////////////////////////////////
                               BALLOTS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBallot() {
        if (!validBallots[msg.sender]) revert Unauthorized();
        _;
    }

    function addBallot(address ballot) external onlyOwner {
        if (!validBallots[ballot]) {
            arrValidBallots.push(ballot);
            validBallots[ballot] = true;
            emit AddedBallot(ballot);
        }
    }

    function removeBallot(uint256 index) external onlyOwner {
        address removed = arrValidBallots[index];

        arrValidBallots[index] = arrValidBallots[arrValidBallots.length - 1];
        arrValidBallots.pop();

        delete validBallots[removed];

        emit RemovedBallot(removed);
    }

    function _forceUncastAllVotes() internal {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            address ballot = arrValidBallots[i];
            delete hasUserVoted[ballot][msg.sender];

            IBallot(ballot).forceUnvote(msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    function setHasVoted(address user) external onlyBallot {
        hasUserVoted[msg.sender][user] = true;
    }

    function unsetHasVoted(address user) external onlyBallot {
        delete hasUserVoted[msg.sender][user];
    }

    /*///////////////////////////////////////////////////////////////
                               STAKING
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount) external {
        //slither-disable-next-line incorrect-equality
        if (genDetails.maxRatio == 0) revert Unauthorized();

        // Reset veFight calculations
        veFightBalance[msg.sender] = balanceOf(msg.sender);
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            fightBalanceOf[msg.sender] += amount;
        }

        // slither-disable-next-line unchecked-transfer
        IERC20(FIGHT).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        if (fightBalanceOf[msg.sender] < amount) revert InvalidAmount();

        // Reset veFight calculations
        delete veFightBalance[msg.sender];
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            fightBalanceOf[msg.sender] -= amount;
        }

        _forceUncastAllVotes();

        // slither-disable-next-line unchecked-transfer
        IERC20(FIGHT).transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               veFight
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address account) public view returns (uint256) {
        GenerationDetails memory gen = genDetails;

        uint256 fightBalance = fightBalanceOf[account];

        uint256 veBalance = veFightBalance[account] +
            ((fightBalance * gen.generationRateNumerator) *
                (block.timestamp - userSnapshot[account])) /
            gen.generationRateDenominator;

        uint256 maxVe = gen.maxRatio * fightBalance;
        if (veBalance > maxVe) {
            return maxVe;
        } else {
            return veBalance;
        }
    }

    function hasUserVotedAny(address account) external view returns (bool) {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            if (hasUserVoted[arrValidBallots[i]][account]) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }
}