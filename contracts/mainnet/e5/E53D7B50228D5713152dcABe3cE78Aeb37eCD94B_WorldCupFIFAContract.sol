/**
 *Submitted for verification at snowtrace.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract WorldCupFIFAContract is ReentrancyGuard {
    bool public allowEditing = false;
    mapping(address => uint256[]) priorities;
    bool public allowWithdrawal = false;
    mapping(address => uint256) public winners;
    address public immutable _admin;
    uint256 public constant TOKEN_LENGTH = 4;

    constructor(address admin) {
        _admin = admin;
    }

    /// ==================== MODIFIERS =======================
    modifier onlyAdmin() {
        require(msg.sender != address(0), "address_  Zero:invalid address");
        require(msg.sender == _admin, "only admin can call this method");
        _;
    }

    modifier checkEditing() {
        require(allowEditing, "Priority Update is disabled!");
        _;
    }

    /// ==================== EVENTS =======================
    event Editing(bool allowed);
    event AllowWithdrawal(bool allowed);
    event PriorityModified(
        address ownerAddress,
        uint256 tokenIds
    );
    event UpdateAccountPermission(address account, bool permission);

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// ============= Allow Edit Function =======================
    function setAllowEditing(bool _allowEditing) external onlyAdmin {
        allowEditing = _allowEditing;
        emit Editing(allowEditing);
    }

    /// ============= Allow Withdrawal Function =======================
    function setAllowWithdrawal(bool _allowWithdrawal) external onlyAdmin {
        allowWithdrawal = _allowWithdrawal;
        emit AllowWithdrawal(allowWithdrawal);
    }

    /// ============= Set Priority Function =======================
    function setPriority(uint256[] calldata tokenIds) external checkEditing {
        require(msg.sender != address(0), "Address_Zero:invalid caller");
        require(
            tokenIds.length == TOKEN_LENGTH,
            "Invalid amount of Priorities!"
        );
        // reset priority
        delete priorities[msg.sender];
        // update priority
        for (uint256 j = 0; j < tokenIds.length; j++) {
            priorities[msg.sender].push(tokenIds[j]);
        }
        emit PriorityModified(msg.sender, tokenIds[0]);
    }

    /// ============= Get Priority Function =======================
    function getUserPriority() external view returns (uint256[] memory) {
        uint256[] memory priority = priorities[msg.sender];
        return priority;
    }

    /// ============= Get Priority by Address Function =======================
    function getAddressPriority(address userAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory priority = priorities[userAddress];
        return priority;
    }

    ///  =============  withdraw winnings  =====================
    function WithdrawWinnings() external nonReentrant {
        require(allowWithdrawal, "Withdrawal is disabled!");
        uint256 balance = winners[msg.sender];
        require(balance > 0, "No ether left to withdraw");
        winners[msg.sender] = 0;
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    /// ==================== ADMIN FUNCTIONS =======================

    ///  =============  Add Address as winner and amount won  =====================
    function setWinner(address winnerAddress, uint256 amountWon)
        external
        onlyAdmin
    {
        require(allowEditing, "Priority Update is disabled!");
        require(
            getBalance() >= amountWon,
            "Insufficeint"
        );
        winners[winnerAddress] += amountWon;
    }
}