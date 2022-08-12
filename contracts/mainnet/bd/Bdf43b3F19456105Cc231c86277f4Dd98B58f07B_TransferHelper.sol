// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../interfaces/IERC20.sol";
import "./interfaces/IJoeVoterProxy.sol";

/**
 * @notice TransferHelper moves stuck AVAX from JoeVoter to `RECEIVER`.
 * The contract re-uses `devAddr` from JoeVoterProxy, which can disable
 * transfers and change `RECEIVER`. While the contract is not disabled,
 * anyone can call `transfer()`.
 * 
 * This TransferHelper should be disabled and upgraded in case more than
 * one Strategy awards AVAX to JoeVoter or JoeVoterProxy is upgraded.
 */
contract TransferHelper {
    uint256 public constant PID = 0;
    address public constant STAKING_CONTRACT = address(0);
    IJoeVoterProxy public constant PROXY = IJoeVoterProxy(0xc31e24f8A25a1dCeCcfd791CA25b62dcFec5c8F7);
    address public RECEIVER;
    bool public DISABLED;

    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    constructor() {
        RECEIVER = msg.sender;
    }

    /**
     * @notice Claims AVAX/WAVAX from `PROXY` and transfers balance to `RECEIVER`
     * @dev Restricted to EOA
     */
    function transfer() external {
        require(!DISABLED, "TransferHelper::disabled");
        require(msg.sender == tx.origin, "TransferHelper::onlyEOA");
        PROXY.distributeReward(PID, STAKING_CONTRACT, WAVAX);
        uint256 amount = IERC20(WAVAX).balanceOf(address(this));
        if (amount > 0) {
            IERC20(WAVAX).transfer(RECEIVER, amount);
        }
    }

    /**
     * @notice Reads `devAddr` from `PROXY`
     * @dev Admin rights are inherited from `PROXY`
     * @return address devAddr
     */
    function devAddr() view public returns (address) {
        return PROXY.devAddr();
    }

    /**
     * @notice Disable the contract functionality
     * @dev Restricted to `devAddr`
     * @dev One-way change; contract cannot be subsequently enabled
     */
    function disable() external {
        require(msg.sender == devAddr(), "TransferHelper::onlyDev");
        DISABLED = true;
    }

    function updateReceiver(address receiver) external {
        require(msg.sender == devAddr(), "TransferHelper::onlyDev");
        RECEIVER = receiver;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IJoeVoterProxy {
    function withdraw(
        uint256 _pid,
        address _stakingContract,
        address _token,
        uint256 _amount
    ) external;

    function emergencyWithdraw(
        uint256 _pid,
        address _stakingContract,
        address _token
    ) external;

    function deposit(
        uint256 _pid,
        address _stakingContract,
        address _token,
        uint256 _amount
    ) external;

    function pendingRewards(address _stakingContract, uint256 _pid)
        external
        view
        returns (
            uint256,
            address,
            uint256
        );

    function poolBalance(address _stakingContract, uint256 _pid) external view returns (uint256);

    function claimReward(
        uint256 _pid,
        address _stakingContract,
        address _extraToken
    ) external;

    function distributeReward(
        uint256 _pid,
        address _stakingContract,
        address _extraToken
    ) external;

    function approveStrategy(address _stakingContract, address _strategy) external;

    function reinvestFeeBips() external view returns (uint256);

    function devAddr() external view returns (address);
}