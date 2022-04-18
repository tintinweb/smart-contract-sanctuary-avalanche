//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

contract MultiSigFactory {
    address public owner;
    uint256 public walletIdCounter;
    uint256 public price;

    constructor(uint256 _price) {
        owner = msg.sender;
        price = _price;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner method");
        _;
    }

    mapping(uint256 => address) public walletIdToWalletAddress;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256[]) public memberToWalletIds;

    function getWalletAddresses_msgSender()
        public
        view
        returns (address[] memory)
    {
        return getWalletAddresses(msg.sender);
    }

    function getWalletAddresses(address member)
        public
        view
        returns (address[] memory)
    {
        uint256[] memory walletIds = memberToWalletIds[member];
        uint256 l = walletIds.length;
        address[] memory addresses = new address[](l);
        for (uint256 i; i < l; i++) {
            addresses[i] = walletIdToWalletAddress[walletIds[i]];
        }
        return addresses;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function createWallet(string memory description)
        public
        payable
        returns (uint256 walletId, address newWalletAddress)
    {
        require(msg.value == price, "Insufficient payment amount");
        walletIdCounter++;
        MultiSigWallet newMultiSigWallet = new MultiSigWallet(
            msg.sender,
            address(this),
            walletIdCounter,
            description
        );
        newWalletAddress = address(newMultiSigWallet);
        walletIdToWalletAddress[walletIdCounter] = newWalletAddress;
        ownerOf[walletIdCounter] = msg.sender;
        walletId = walletIdCounter;
    }

    function addMember(uint256 walletId, address member) public {
        require(
            walletIdToWalletAddress[walletId] == msg.sender,
            "Only wallet method"
        );
        memberToWalletIds[member].push(walletId);
    }
}

//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Interfaces/IMultiSigFactory.sol";

contract MultiSigWallet is ReentrancyGuard {
    address public owner;
    uint256 public orderCounter;
    uint256 public walletId;
    string public description;
    IMultiSigFactory multiSigFactory;

    struct Member {
        uint256 timeAdded;
        address walletAddress;
    }

    struct Order {
        uint256 creationTime;
        address tokenAddress;
        address toAddress;
        uint256 amount;
        uint256 numberOfAcceptance;
        uint256 numberOfRejections;
        uint256 minRequiredDecision;
        uint256 finalDecision;
    }

    uint256 public memberCount;
    mapping(address => Member) public addressToMember;
    mapping(address => bool) public isMember;

    mapping(uint256 => Order) public orderIdToOrder;
    mapping(uint256 => mapping(address => uint256)) orderIdToAddressToDecision;

    constructor(
        address _owner,
        address _factoryAddress,
        uint256 _walletId,
        string memory _description
    ) {
        owner = _owner;
        multiSigFactory = IMultiSigFactory(_factoryAddress);
        walletId = _walletId;
        description = _description;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner method");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only member method");
        _;
    }

    function balanceOf(address tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        balance = IERC20(tokenAddress).balanceOf(address(this));
    }

    function addMember(address member) internal {
        require(!isMember[member], "Already a member");
        addressToMember[member] = Member(block.timestamp, member);
        isMember[member] = true;
        multiSigFactory.addMember(walletId, member);
        memberCount++;
    }

    function addMembers(address[] memory members) public onlyOwner {
        for (uint256 i; i < members.length; i++) addMember(members[i]);
    }

    // set token address to address(0) to send ether
    function createOrder(
        address _tokenAddress,
        address _toAddress,
        uint256 _amount
    ) public onlyMember returns (uint256 orderId) {
        orderId = orderCounter;
        orderIdToOrder[orderId] = Order({
            creationTime: block.timestamp,
            tokenAddress: _tokenAddress,
            toAddress: _toAddress,
            amount: _amount,
            numberOfAcceptance: 0,
            numberOfRejections: 0,
            minRequiredDecision: memberCount - memberCount / 2,
            finalDecision: 0
        });
        orderCounter++;
    }

    // 1 is for acceptance
    // 2 is for rejectance
    function makeDecision(uint256 orderId, uint256 decision)
        public
        nonReentrant
    {
        require(orderId >= orderCounter, "No such order");
        require((decision == 1) || (decision == 2), "Not a valid decision");
        Order storage o = orderIdToOrder[orderId];
        require(o.finalDecision == 0, "Already executed");
        require(
            addressToMember[msg.sender].timeAdded <= o.creationTime,
            "User wasn't a member at the time of ordering"
        );
        require(
            orderIdToAddressToDecision[orderId][msg.sender] == 0,
            "Already made a decision"
        );
        orderIdToAddressToDecision[orderId][msg.sender] = decision;
        if (decision == 1) o.numberOfAcceptance++;
        else o.numberOfRejections++;
        if (
            (o.numberOfAcceptance >= o.minRequiredDecision) ||
            (o.numberOfRejections >= o.minRequiredDecision)
        ) finalizeOrder(o);
    }

    function finalizeOrder(Order storage o) internal {
        if (o.numberOfAcceptance >= o.minRequiredDecision) {
            transfer(o.tokenAddress, o.toAddress, o.amount);
            o.finalDecision = 1;
        } else if (o.numberOfRejections >= o.minRequiredDecision)
            o.finalDecision = 2;
    }

    function transfer(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        if (tokenAddress == address(0)) payable(to).transfer(amount);
        else
            require(
                IERC20(tokenAddress).transfer(to, amount),
                "Transfer failed"
            );
    }

    receive() external payable {}
}

//SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IMultiSigFactory {
    function addMember(uint256 walletId, address member) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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