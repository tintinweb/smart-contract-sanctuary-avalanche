/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address _address) 
        external view 
        returns (uint256);
}

interface WBNB {
    function deposit() external payable;
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface RoboDogeCoin {
    function balanceOf(address _address) external view returns (uint256);
}

interface RoboDogeStaking {
    struct Stake {
        uint256 tAmount;
        uint256 rAmount;
        uint256 time;
        uint256 period;
        uint256 rate;
        bool isActive;
    }

    function getAllStakes(address _address)
        external
        view
        returns (Stake[] memory);
}

contract FantasyCrypto is Ownable {
    RoboDogeCoin private token;
    RoboDogeStaking private staking;

    struct pool {
        uint256 entryFee;
        address tokenAddress;
        uint256 startTime;
        uint256 endTime;
        address[] userAddress;
    }
    struct userDetails {
        address[10] aggregatorAddresses;
    }

    struct winner {
        address[] user;
        uint256[] amount;
    }

    address private constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 public minimumTokenBalance;
    uint256 public fee;
    address public AuthAddress;
    uint256 public poolCounter = 0;
    mapping(uint256 => pool) public pools;
    mapping(uint256 => mapping(address => userDetails)) internal userSelection;
    mapping(address => uint256) public feeAmount;
    mapping(uint256 => winner) internal winnerDetails;

    event poolCreated(
        uint256 poolID,
        uint256 entryFees,
        uint256 startTime,
        uint256 endTime,
        address tokenAddress
    );
    event enteredPool(
        address user,
        uint256 poolID,
        address[10] aggregatorAddress
    );
    event setWinners(
        uint256 poolID,
        address[] winners,
        uint256[] amounts
    );
    event RewardClaimed(uint256 poolID, address winner, uint256 amount);
    event FeeDeducted(uint256 poolID, address token, uint256 amount);
    event FeeWithdrawn(address token, uint256 amount);
    event AuthAddressUpdated(address prevAuth, address newAuth);
    event FeeUpdated(uint256 prevFee, uint256 newFee);
    event MinimumTokenBalanceUpdated(uint256 prevMinimumTokenBalance, uint256 newMinimumTokenBalance);
    event EmergencyWithdraw(address token, uint256 withdrawAmount);

    constructor(
        address _auth,
        uint256 _fee,
        uint256 _minimumTokenBalance,
        address _robodogeToken,
        address _roboDogeStaking
    ) {
        require(_auth != address(0), "Cannot be zero address");
        require(_robodogeToken != address(0), "Cannot be zero address");
        require(_roboDogeStaking != address(0), "Cannot be zero address");

        AuthAddress = _auth;
        fee = _fee;
        minimumTokenBalance = _minimumTokenBalance;
        token = RoboDogeCoin(_robodogeToken);
        staking = RoboDogeStaking(_roboDogeStaking);
    }

    modifier isAuth() {
        require(msg.sender == AuthAddress, "Address is not AuthAddress");
        _;
    }

    function createPool(
        uint256 entryFees,
        address _tokenAddress,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(
            _startTime < _endTime,
            "Start time cannot be greater than end time."
        );
        require(
            _startTime > block.timestamp,
            "Start time must be greator than current time"
        );
        require(
            _tokenAddress != address(0),
            "Token Address must not be zero address"
        );
        pools[poolCounter].entryFee = entryFees;
        pools[poolCounter].startTime = _startTime;
        pools[poolCounter].endTime = _endTime;
        pools[poolCounter].tokenAddress = _tokenAddress;
        emit poolCreated(
            poolCounter,
            entryFees,
            _startTime,
            _endTime,
            _tokenAddress
        );
        poolCounter++;
    }

    function enterPool(uint256 _poolID, address[10] memory _aggregatorAddress)
        external payable
    {
        require(_poolID < poolCounter, "Pool ID must exist");
        require(
            block.timestamp < pools[_poolID].startTime,
            "Pool has already started."
        );

        uint256 sum = 0;
        if (token.balanceOf(msg.sender) < minimumTokenBalance) {

            RoboDogeStaking.Stake[] memory userStakes = staking.getAllStakes(msg.sender);
            for (
                uint256 i = 0;
                i < userStakes.length;
                i++
            ) {
                if (userStakes[i].isActive) {
                    sum += userStakes[i].tAmount;
                }
            }
        }
        require(
            token.balanceOf(msg.sender) + sum >= minimumTokenBalance,
            "You dont have minimum RoboDoge Tokens."
        );

        require(
            userSelection[_poolID][msg.sender].aggregatorAddresses[0] == address(0), 
            "User already entered pool"
        );

        for(uint8 i = 0; i < 10; i++) {
            require(
                _aggregatorAddress[i] != address(0),
                "Aggregator cannot be zero address"
            );
        }

        userSelection[_poolID][msg.sender]
            .aggregatorAddresses = _aggregatorAddress;
        pools[_poolID].userAddress.push(msg.sender);

        if (pools[_poolID].tokenAddress == wbnbAddress && msg.value > 0) {
            require(msg.value >= pools[_poolID].entryFee, "Insufficient funds sent");
            WBNB(pools[_poolID].tokenAddress).deposit{value: pools[_poolID].entryFee}();
            payable(msg.sender).transfer(msg.value - pools[_poolID].entryFee);
        } else {
            IERC20(pools[_poolID].tokenAddress).transferFrom(
                msg.sender,
                address(this),
                pools[_poolID].entryFee
            );
        }

        emit enteredPool(msg.sender, _poolID, _aggregatorAddress);
    }

    function withdrawFees(address _tokenAddress) external onlyOwner {
        require(feeAmount[_tokenAddress] > 0, "No fees has been collected yet.");
        uint256 _fee = feeAmount[_tokenAddress];
        delete feeAmount[_tokenAddress];
        IERC20(_tokenAddress).transfer(msg.sender, _fee);

        emit FeeWithdrawn(_tokenAddress, _fee);
    }

    function emergencyWitdraw(address _tokenAddress) external onlyOwner {
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));

        require(amount > 0, "No funds to withdraw");

        IERC20(_tokenAddress).transfer(msg.sender, amount);

        emit EmergencyWithdraw(_tokenAddress, amount);
    }

    function setWinner(
        uint256 _poolID,
        address[] memory winners,
        uint256[] memory amount
    ) external isAuth {
        require(_poolID < poolCounter, "Pool does not exist");
        require(
            block.timestamp > pools[_poolID].endTime,
            "The pool has not been ended yet."
        );
        require(
            winnerDetails[_poolID].user.length == 0,
            "Winners are already set for this pool."
        );
        require(
            winners.length <= pools[_poolID].userAddress.length,
            "Winners must be less than total users."
        );
        require(
            winners.length == amount.length, 
            "Winners and amounts must be of same length"
        );

        winnerDetails[_poolID].user = winners;
        winnerDetails[_poolID].amount = amount;

        emit setWinners(_poolID, winners, amount);
    }

    function claimReward(uint256 _poolID, uint256 position) external {
        require(
            winnerDetails[_poolID].amount[position] > 0, 
            "You have already claimed prize"
        );
        require(
            msg.sender == winnerDetails[_poolID].user[position],
            "You are not the winner for this position."
        );
        require(
            block.timestamp > pools[_poolID].endTime,
            "The pool has not been ended yet"
        );

        uint256 prize = winnerDetails[_poolID].amount[position];
        winnerDetails[_poolID].amount[position] = 0;

        uint256 _fee = prize * fee / 10000;
        feeAmount[pools[_poolID].tokenAddress] += _fee;
        
        IERC20(pools[_poolID].tokenAddress).transfer(
            msg.sender,
            prize - _fee
        );

        emit RewardClaimed(_poolID, msg.sender, prize - _fee);
        emit FeeDeducted(_poolID, pools[_poolID].tokenAddress, _fee);
    }

    function setAuth(address _auth) external onlyOwner {
        require(_auth != AuthAddress, "Change auth address to update");
        require(_auth != address(0), "Auth cannot be zero address");

        address prevAuth = AuthAddress;
        AuthAddress = _auth;

        emit AuthAddressUpdated(prevAuth, _auth);
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee != fee, "Change fee to update");

        uint256 prevFee = fee;
        fee = _fee;

        emit FeeUpdated(prevFee, _fee);
    }

    function setminimumTokenBalance(uint256 _minimumTokenBalance)
        external
        onlyOwner
    {
        require(_minimumTokenBalance != minimumTokenBalance, "Change minimumTokenBalance to update");

        uint256 prevMinimumTokenBalance = minimumTokenBalance;
        minimumTokenBalance = _minimumTokenBalance;

        emit MinimumTokenBalanceUpdated(prevMinimumTokenBalance, _minimumTokenBalance);
    }

    function viewActivePools()
        external
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory activePools = new uint256[](poolCounter);
        uint256 count = 0;
        for (uint256 i = 0; i < poolCounter; i++) {
            if (pools[i].endTime > block.timestamp) {
                activePools[count] = i;
                count++;
            }
        }
        return (activePools, count);
    }

    function getPoolInfo(uint256 _poolID) external view returns (pool memory) {
        return pools[_poolID];
    }

    function getUserSelectionInfo(uint256 _poolID, address _address)
        external
        view
        returns (userDetails memory)
    {
        return userSelection[_poolID][_address];
    }

    function getPoolWinnerAmountAtPosition(uint256 _poolID, uint256 _position) external view returns (uint256) {
        require(_poolID < poolCounter, "Pool does not exist");
        require(winnerDetails[_poolID].amount.length > 0, "Pool winners not set");

        return winnerDetails[_poolID].amount[_position];
    }
}