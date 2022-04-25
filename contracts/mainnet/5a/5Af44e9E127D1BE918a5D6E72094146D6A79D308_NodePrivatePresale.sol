/**
 *Submitted for verification at snowtrace.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

interface IERC20Main {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC20 is IERC20Main {
    function burnFrom(address account, uint256 amount) external;
}

interface INODERewardManagement {
    function nodePrice() external view returns (uint256);

    function rewardPerNode() external view returns (uint256);

    function totalRewardStaked() external view returns (uint256);

    function totalNodesCreated() external view returns (uint256);

    function createNode(address account, string memory nodeName) external;
}

interface XConPresale {
    function whitelistedUser(address _account) external view returns (bool);
}

/// @title Node Presale
/// @author BlocTech Solutions
/// @dev This contract is used to mint nodes for usdc.
contract NodePrivatePresale is Ownable, ReentrancyGuard {
    IERC20 public xcon;
    INODERewardManagement public node;
    XConPresale public xconPresale;

    // ========================= State Variables ===========================
    uint256 public maxSupply;
    bool public isPremintActive;
    uint256 public nodeXConPrice;
    uint256 public totalSoldNodes;
    uint256 public perTransactionLimit;
    uint256 public perWalletLimit;
    uint256 public totalParticipants;

    string public perTransactionLimitMsg;
    string public perWalletLimitMsg;

    mapping(address => uint256) public userBoughtNodes;

    constructor(
        address _xconToken,
        uint256 _xConprice,
        uint256 _maxSupply,
        INODERewardManagement _node,
        XConPresale _xconPresale
    ) {
        xcon = IERC20(_xconToken);
        nodeXConPrice = _xConprice;
        maxSupply = _maxSupply;
        node = _node;
        xconPresale = _xconPresale;

        perTransactionLimit = 8;
        perWalletLimit = 25;
        perTransactionLimitMsg = "You can buy up to 8 nodes per transaction.";
        perWalletLimitMsg = "You can buy up to 25 nodes per wallet.";
    }

    function buyWithXCon(uint256 _amount) external nonReentrant {
        require(
            xconPresale.whitelistedUser(msg.sender),
            "Not a whitelisted user"
        );
        require(isPremintActive, "Presale is not active");
        require(maxSupply >= totalSoldNodes + _amount, "Not enough nodes left");
        require(_amount <= perTransactionLimit, perTransactionLimitMsg);
        require(
            perWalletLimit >= userBoughtNodes[msg.sender] + _amount,
            perWalletLimitMsg
        );

        xcon.burnFrom(msg.sender, _amount * nodeXConPrice);
        if (userBoughtNodes[msg.sender] == 0) {
            totalParticipants += 1;
        }
        for (uint256 i; i < _amount; i++) {
            node.createNode(msg.sender, "PRESALE");
        }

        totalSoldNodes += _amount;
        userBoughtNodes[msg.sender] += _amount;
    }

    function setMaxSupply(uint256 _max) external onlyOwner {
        maxSupply = _max;
    }

    function setXConPrice(uint256 _xConPrice) external onlyOwner {
        nodeXConPrice = _xConPrice;
    }

    function setPerWAllLimit(uint256 _limit) external onlyOwner {
        perWalletLimit = _limit;
    }

    function setPerTransLimit(uint256 _limit) external onlyOwner {
        perTransactionLimit = _limit;
    }

    function withdrawAVAX(address payable _account, uint256 _amount)
        external
        onlyOwner
    {
        _account.transfer(_amount);
    }

    function withdrawTokens(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }

    function updateXCon(address _token) external onlyOwner {
        xcon = IERC20(_token);
    }

    function setNodeManagement(INODERewardManagement nodeManagement)
        external
        onlyOwner
    {
        node = nodeManagement;
    }

    function setPremintSaleStatus(bool _status) external onlyOwner {
        isPremintActive = _status;
    }

    function setPerTansactionLimitMsg(string memory _msg) external onlyOwner {
        perTransactionLimitMsg = _msg;
    }

    function setPerWallLimtMsg(string memory _msg) external onlyOwner {
        perWalletLimitMsg = _msg;
    }
}