// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./FarmCore.sol";

contract Farm is Ownable, FarmCore {

    /**
     * @dev Struct variable type
     */
    struct Deposit {
        uint256 amountFirst;
        uint256 amountSecond;
        uint256 startTime;
        uint256 farmPoolId;
    }

    struct Withdrawal {
        uint256 depositId;
        uint256 farmPoolId;
        uint256 amountFirst;
        uint256 amountSecond;
        uint256 date;
    }

    struct User {
        address referral;
        bool isBlocked;
        uint256 depositCount;
        uint256 withdrawCount;
        mapping(uint256 => Deposit) deposits;
        mapping(uint256 => Withdrawal) withdrawals;
    }

    /**
     * @dev Mapping data for quick access by index or address.
     */
    mapping(address => User) public users;

    /**
     * @dev Counters for mapped data. Used to store the length of the data.
     */
    uint256 public usersCount;

    /**
     * @dev All events. Used to track changes in the contract
     */
    event NewDeposit(address indexed user, uint256 amountFirst, uint256 amountSecond);
    event NewWithdraw(address indexed user, uint256 amountFirst, uint256 amountSecond, uint256 farmPoolId);
    event UserBlocked(address indexed user);
    event UserUnblocked(address indexed user);
    event NewUser(address indexed user, address indexed referral);
    event DepositStatusChanged(address indexed user, uint256 depositId);
    event WithdrawStatusChanged(address indexed user, uint256 withdrawId);

    bool private itialized;

    /**
     * @dev Initial setup.
     */
    function initialize() external virtual {
        require(itialized != true, 'FarmContract: already initialized');
        itialized = true;
        initOwner(_msgSender());
        addAdmin(_msgSender());
    }

    /**
     * @dev Block user by address.
     *
     * NOTE: Can only be called by the admin address.
     */
    function blockUser(address _address) public onlyWhenServiceEnabled onlyAdmin {
        users[_address].isBlocked = true;
        emit UserBlocked(_address);
    }

    /**
     * @dev Unblock user by address.
     *
     * NOTE: Can only be called by the admin address.
     */
    function unblockUser(address _address) public onlyWhenServiceEnabled onlyAdmin {
        users[_address].isBlocked = false;
        emit UserUnblocked(_address);
    }

    /**
     * @dev Create new (`User`) object by address.
     *
     * Emits a {NewUser} event.
     *
     * NOTE: Only internal call.
     */
    function createNewUser(address _referral) private {
        users[_msgSender()].referral = _referral;
        users[_msgSender()].isBlocked = false;
        users[_msgSender()].depositCount = 0;
        users[_msgSender()].withdrawCount = 0;
        usersCount++;

        emit NewUser(_msgSender(), _referral);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if (`_amount`) is greater than zero;
     * Checks if farm service exists and has active status;
     * Checks if contact has required amount of token for transfer from current caller;
     * Checks if farm pool is not moving;
     *
     * Transfers the amount of tokens to the current contract.
     * 
     * If its called by new address then new user will be created.
     * 
     * Creates new object of (`Deposit`) struct.
     *
     * Emits a {NewDeposit} event.
     */
    function deposit(
        uint256 _amountFirst,
        uint256 _amountSecond,
        address _referral,
        uint256 _farmServiceId,
        uint256 _farmPoolId
    ) public onlyWhenServiceEnabled {

        require(users[_msgSender()].isBlocked == false, "FarmContract: User blocked");
        require(_amountFirst > 0 || _amountSecond > 0, "FarmContract: Zero amount");
        require(farmServices[_farmServiceId].isActive, "FarmContract: No active farm service");
        require(farmPools[_farmPoolId].isActive, "FarmContract: No active farmPools");
        require(farmPools[_farmPoolId].isFarmMoving == false, "FarmContract: Farm pool is moving");

        if (_amountFirst > 0 ) {
            _transferTokens(
                farmPairs[farmPools[_farmPoolId].farmPairId].firstToken,
                farmPools[_farmPoolId].depositAddress,
                _amountFirst
            );
        }

        if (_amountSecond > 0 ) {
            _transferTokens(
                farmPairs[farmPools[_farmPoolId].farmPairId].secondToken,
                farmPools[_farmPoolId].depositAddress,
                _amountSecond
            );
        }

        uint256 depositCount = users[_msgSender()].depositCount;
        
        if (depositCount <= 0) {
            createNewUser(_referral);
            users[_msgSender()].deposits[users[_msgSender()].depositCount] = Deposit(_amountFirst, _amountSecond, block.timestamp, _farmPoolId);
            users[_msgSender()].depositCount += 1;
        } else {
            for (uint i = 0; i <= depositCount - 1; i++) {
                if (users[_msgSender()].deposits[i].farmPoolId == _farmPoolId) {
                    users[_msgSender()].deposits[i].amountFirst += _amountFirst > 0 ? _amountFirst : 0;
                    users[_msgSender()].deposits[i].amountSecond += _amountSecond > 0 ? _amountSecond : 0;
                }
            }
        }

        emit NewDeposit(_msgSender(), _amountFirst, _amountSecond);
    }

    /**
     * @dev Transfers tokens to deposit address.
     * Internal function without access restriction.
     */
    function _transferTokens(IERC20 _token, address _depositAddress, uint256 _amount) internal virtual {
        uint256 allowance = _token.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "FarmContract: Recheck the token allowance");
        (bool sent) = _token.transferFrom(_msgSender(), _depositAddress, _amount);
        require(sent, "FarmContract: Failed to send tokens");
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if requested amount is less or equal deposit balance;
     *
     * Creates new object of (`Withdrawal`) struct.
     *
     * Emits a {NewDeposit} event.
     */
    function withdraw(
        uint256 _depositId,
        uint256 _farmPoolId,
        uint256 _amountFirst,
        uint256 _amountSecond
    ) public onlyWhenServiceEnabled {

        require(users[_msgSender()].isBlocked == false, "FarmContract: User blocked");
        Deposit storage userDeposit = users[_msgSender()].deposits[_depositId];
        require(userDeposit.farmPoolId == _farmPoolId, "FarmContract: Wrong pool");
        require(_amountFirst > 0 || _amountSecond > 0, "FarmContract: Zero amount");

        if (_amountFirst > 0) {
            require(_amountFirst <= userDeposit.amountFirst, "FarmContract: Insufficient funds");
        }

        if (_amountSecond > 0) {
            require(_amountSecond <= userDeposit.amountSecond, "FarmContract: Insufficient funds");
        }
        
        uint256 newWithdrawalId = users[_msgSender()].withdrawCount;
        
        users[_msgSender()].deposits[_depositId].amountFirst -= _amountFirst > 0 ? _amountFirst : 0;
        users[_msgSender()].deposits[_depositId].amountSecond -= _amountSecond > 0 ? _amountSecond : 0;

        users[_msgSender()].withdrawals[newWithdrawalId] = Withdrawal(_depositId, _farmPoolId, _amountFirst, _amountSecond, block.timestamp);
        users[_msgSender()].withdrawCount += 1;

        emit NewWithdraw(_msgSender(), _amountFirst, _amountSecond, _farmPoolId);
    }

    /**
     * @dev Sync deposit from another chain.
     *
     * NOTE: Can only be called by the admin.
     */
    function syncCrossChainDeposit(
        address _userAddress,
        uint256 _amountFirst,
        uint256 _amountSecond,
        address _referral,
        uint256 _farmPoolId
    ) public onlyOwner {
        uint256 depositCount = users[_userAddress].depositCount;
        
        if (depositCount <= 0) {
            createNewUser(_referral);
            users[_userAddress].deposits[users[_userAddress].depositCount] = Deposit(_amountFirst, _amountSecond, block.timestamp, _farmPoolId);
            users[_userAddress].depositCount += 1;
        } else {
            for (uint i = 0; i <= depositCount - 1; i++) {
                if (users[_userAddress].deposits[i].farmPoolId == _farmPoolId) {
                    users[_userAddress].deposits[i].amountFirst += _amountFirst > 0 ? _amountFirst : 0;
                    users[_userAddress].deposits[i].amountSecond += _amountSecond > 0 ? _amountSecond : 0;
                }
            }
        }

        emit NewDeposit(_userAddress, _amountFirst, _amountSecond);
    }

    /**
     * @dev Sync withdrawal from another chain.
     *
     * NOTE: Can only be called by the admin.
     */
    function syncCrossChainWithdraw(
        address _userAddress,
        uint256 _depositId,
        uint256 _farmPoolId,
        uint256 _amountFirst,
        uint256 _amountSecond
    ) public onlyOwner {
        uint256 newWithdrawalId = users[_userAddress].withdrawCount;
        
        users[_userAddress].deposits[_depositId].amountFirst -= _amountFirst > 0 ? _amountFirst : 0;
        users[_userAddress].deposits[_depositId].amountSecond -= _amountSecond > 0 ? _amountSecond : 0;
        users[_userAddress].withdrawals[newWithdrawalId] = Withdrawal(_depositId, _farmPoolId, _amountFirst, _amountSecond, block.timestamp);
        users[_userAddress].withdrawCount += 1;

        emit NewWithdraw(_userAddress, _amountFirst, _amountSecond, _farmPoolId);
    }

    /**
     * @dev Returns the user (`Deposit`) object.
     */
    function getUserDeposit(
        address _userAddress,
        uint256 _depositId
    ) public view returns (Deposit memory) {
        return users[_userAddress].deposits[_depositId];
    }

    /**
     * @dev Returns the user (`Withdrawal`) object.
     */
    function getUserWithdraw(
        address _userAddress,
        uint256 _withdrawId
    ) public view returns (Withdrawal memory) {
        return users[_userAddress].withdrawals[_withdrawId];
    }
}