/**
 *Submitted for verification at snowtrace.io on 2022-06-27
*/

pragma solidity 0.8.15;

// SPDX-License-Identifier: Unknown

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRewardContract {
    struct NodeInfo {
        uint256 createTime;
        uint256 lastTime;
        uint256 reward;
        uint8 version;
    }

    function getNodeList(address account) external view returns (NodeInfo[] memory result);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PhoenixClaim is IRewardContract, Ownable {

    IRewardContract public immutable rewardContract;
    mapping (address => bool) public blacklistedWallet;
    mapping (address => bool) public claimed;
    mapping (address => bool) public amountSetForWallet;

    uint256 public rewardPerNode;
    uint256 public totalEligibleNodes;
    IERC20 public immutable rewardToken;

    mapping (address => uint256) public amountToClaim;

    bool public paused = true;

    constructor(address _rewardContract, address _rewardToken) {
        rewardContract = IRewardContract(_rewardContract); // 0xD2BB9dD72029770eEE26ce7Ac106Fb4FA84FE07a
        rewardToken = IERC20(_rewardToken); // 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E for USDC, 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664 for USDC.e
    }

    function blacklistWallets(address[] calldata wallets, bool blacklist) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            blacklistedWallet[wallets[i]] = blacklist;
        }
    }

    function updateRewardPerNode() external onlyOwner {
        require(paused, "Must pause contract to update rewards.");
        rewardPerNode = rewardToken.balanceOf(address(this)) / totalEligibleNodes;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function claimReward() external {
        require(!paused, "Claiming is currently paused");
        require(!blacklistedWallet[msg.sender], "Address is ineligible for rewards"); 
        require(!claimed[msg.sender], "Wallet already claimed");
        require(amountSetForWallet[msg.sender], "Amount must be set to claim");
        claimed[msg.sender] = true;
        rewardToken.transfer(msg.sender, amountToClaim[msg.sender] * rewardPerNode);
        amountToClaim[msg.sender] = 0;
    }

    function setAmountToClaim(address account) internal { // make internal
        amountToClaim[account] = getEligibleAmountInternal(account);
        totalEligibleNodes += amountToClaim[account];
        amountSetForWallet[account] = true;
    }

    function setAmountsToClaim(address[] calldata accounts) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
            address account = accounts[i];
            if(!amountSetForWallet[account]){
                setAmountToClaim(account);
            }
        }
    }

    function setAmountsToClaimManual(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
            address account = accounts[i];
            uint256 amount = amounts[i];
            amountToClaim[account] = amount;
            amountSetForWallet[account] = true;
        }
    }

    function getEligibleAmountInternal(address account) internal view returns (uint256){ // make internal
        uint256 eligibleNodeCount = 0;
        if(blacklistedWallet[account]) return 0;
        if(claimed[account]) return 0;

        NodeInfo[] memory nodesOfUser = rewardContract.getNodeList(account);
        for(uint256 i = 0; i < nodesOfUser.length; i++){
            if(nodesOfUser[i].lastTime >= block.timestamp && nodesOfUser[i].version == 1){
                eligibleNodeCount += 1;
            }
        }
        return (eligibleNodeCount);
    }

    function getNodeList(address account) external view override returns (NodeInfo[] memory result){
        return rewardContract.getNodeList(account);
    }
}