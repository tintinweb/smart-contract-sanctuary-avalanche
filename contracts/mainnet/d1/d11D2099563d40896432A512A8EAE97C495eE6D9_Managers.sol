// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAnnuToken is IERC20 {
    function pause() external;
    function unpause() external;
    function setSupplyPercent(uint256 num) external;
    function addExContract(address addr) external;
    function delExContract(address addr) external;
}

enum ActionCmd {
        AddManager,
        DelManager,
        Pause,
        UnPause,
        SupplyPrecent,
        Withdraw,
        WithdrawAvax,
        AddContract,
        DelContract
    }

contract Managers{
    mapping(address => uint8) public managers;
    uint256 public managerLen;
    uint256 public actionId;
    mapping(uint256 => Action) public actions;
    IAnnuToken private annuToken;
    struct Action {
        ActionCmd cmd; //add del set
        uint256 arg_num;
        address payable arg_addr;
        string arg_str;
        address arg_addr_erc20;
        uint256 signatureCount;
        mapping(address => bool) signatures;
        bool done;
    }
    event Receive(address sender, uint256 amount);
    event withdrawEvent(address receiver, uint256 amount);
    event withdrawAvaxEvent(address receiver, uint256 amount);

    constructor() {
        managers[msg.sender] = 1;
        managerLen = 1;
    }

    modifier isManager() {
        require(managers[msg.sender] == 1);
        _;
    }

    function setTargetContract(address _annuTokenAddr) public isManager {
        annuToken = IAnnuToken(_annuTokenAddr);
    }
    
    function newAction(
        uint8 _cmd,
        uint256 arg_num,
        address payable arg_addr,
        string memory arg_str,
        address arg_addr_erc20
    ) public isManager returns (bool){
        ActionCmd cmd = ActionCmd(_cmd);
        //防止重覆加入，導致managerLen出錯，出錯會有可能len比實際管理員少，就會達到不過2/3也能決策的局面
        if (cmd == ActionCmd.AddManager) {
            require(managers[arg_addr] == 0, "error addr already manager");
        } else if (cmd == ActionCmd.DelManager) {
            require(managers[arg_addr] == 1, "error addr not manager");
        }
        actionId = actionId + 1;
        actions[actionId].cmd = cmd;
        actions[actionId].arg_num = arg_num;
        actions[actionId].arg_addr = arg_addr;
        actions[actionId].arg_str = arg_str;
        actions[actionId].arg_addr_erc20 = arg_addr_erc20;
        actions[actionId].signatureCount = 0;
        return signAction(actionId);
        //emit event
    }

    function signAction(uint256 _actionId) public isManager returns (bool) {
        require(_actionId == actionId, "not currect action");
        require(actions[_actionId].done == false, "action already done");
        require(
            actions[_actionId].signatures[msg.sender] != true,
            "repeat sign"
        );
        actions[_actionId].signatures[msg.sender] = true;
        actions[_actionId].signatureCount++;
        if (actions[_actionId].signatureCount >= (((managerLen * 2) / 3) + 1)) {
            //(managerLen/2)+1
            actions[_actionId].done = true;
            if (actions[_actionId].cmd == ActionCmd.AddManager) {
                require(
                    actions[_actionId].arg_addr != address(0),
                    "error addr"
                );
                managers[actions[_actionId].arg_addr] = 1;
                managerLen++;
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.DelManager) {
                require(
                    actions[_actionId].arg_addr != address(0),
                    "error addr"
                );
                managers[actions[_actionId].arg_addr] = 0;
                managerLen--;
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.Pause) {
                annuToken.pause();
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.UnPause) {
                annuToken.unpause();
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.SupplyPrecent) {
                annuToken.setSupplyPercent(actions[_actionId].arg_num );
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.Withdraw) {
                require(
                    actions[_actionId].arg_addr != address(0),
                    "error addr"
                );
                require(
                    actions[_actionId].arg_addr_erc20 != address(0),
                    "error addr_erc20"
                );
                require(actions[_actionId].arg_num > 0, "error num");
                //IERCs
                IERC20 ercToken = IERC20(actions[_actionId].arg_addr_erc20);
                ercToken.transfer(
                    actions[_actionId].arg_addr,
                    actions[_actionId].arg_num
                );
                emit withdrawEvent(actions[_actionId].arg_addr, actions[_actionId].arg_num);
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.WithdrawAvax) {
                require(
                    actions[_actionId].arg_addr != address(0),
                    "error addr"
                );
                require(actions[_actionId].arg_num > 0, "error num");
                actions[_actionId].arg_addr.transfer(
                    actions[_actionId].arg_num
                );
                emit withdrawAvaxEvent(actions[_actionId].arg_addr, actions[_actionId].arg_num);
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.AddContract) {
                annuToken.addExContract(actions[_actionId].arg_addr_erc20);
                return true;
            } else if (actions[_actionId].cmd == ActionCmd.DelContract) {
                annuToken.delExContract(actions[_actionId].arg_addr_erc20);
                return true;
            } else {
                revert("error cmd");
            }
        } else {
            return false;
        }
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}