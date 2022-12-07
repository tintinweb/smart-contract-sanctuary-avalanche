/**
 *Submitted for verification at snowtrace.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract XANAOWB {
    constructor(address _xetaAddress) {
        owner = msg.sender;
        xeta = _xetaAddress;
    }

    address public xeta;
    address public owner;
    uint256 private depositId;
    uint256 public minDeposit = 100 * 1E18;
    uint256 public maxDeposit = 100000 * 1E18;
    mapping(address => uint256) public amountDeposited;
    event Deposit(address user, uint256 amount, uint256 depositedAt, uint256 depositId);

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not owner");
        _;
    }

    /**
     * @dev PUBLIC FACING: Users can deposit their XETA on this contract
     * and recieve on XANAChain
     */
    function deposit(uint256 _amount) external {
        require(_amount >= minDeposit && _amount <= maxDeposit, "amount off limits");
        require(IERC20(xeta).transferFrom(msg.sender, address(this), _amount), "deposit transfer failed");
        amountDeposited[msg.sender] += _amount;
        depositId++;
        emit Deposit(msg.sender, _amount, block.timestamp, depositId);
    }

    function emergencyWithdraw(address _receiver) external onlyOwner {
        uint256 balance = IERC20(xeta).balanceOf(address(this));
        require(IERC20(xeta).transfer(_receiver, balance));
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setDepositLimits(uint256 _min, uint256 _max) external onlyOwner {
        minDeposit = _min;
        maxDeposit = _max;
    }
}