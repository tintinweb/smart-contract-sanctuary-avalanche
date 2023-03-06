/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20
{
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract GrumbExchange is Ownable, ReentrancyGuard
{
    IERC20 public _GOTH;
    uint256 public _exchangeFee; 
    address public _treasury;

    event GetGoth (address account, uint256 amount);
    event SetExchangeFee (uint256 oldFee, uint256 newFee);

    constructor (address goth, address treasury)
    {
        _GOTH = IERC20(goth);
        _treasury = treasury;
    }

    function setExchangeFee (uint256 fee) public onlyOwner
    {
        uint256 oldFee = _exchangeFee;
        _exchangeFee = fee;
        emit SetExchangeFee(oldFee, fee);
    }

    function getGoth (uint8 _v, bytes32 _r, bytes32 _s, uint256 gothOutput) public nonReentrant payable 
    {
        require(msg.value >= _exchangeFee, "getGoth: Exchange fee not supplied or is not enough.");

        bytes32 msgHash = keccak256(abi.encodePacked(gothOutput));
        require(owner() == ecrecover(msgHash, _v, _r, _s), "getGoth: the message is not signed by an authorised address.");

        _GOTH.transfer(msg.sender, gothOutput);

        emit GetGoth (msg.sender, gothOutput);
    }

    function giveGoth (uint8 _v, bytes32 _r, bytes32 _s, uint256 gothInput) public nonReentrant payable
    {
        require(msg.value >= _exchangeFee, "getGoth: Exchange fee not supplied or is not enough.");
        
        bytes32 msgHash = keccak256(abi.encodePacked(gothInput));
        require(owner() == ecrecover(msgHash, _v, _r, _s), "giveGoth: the message is not signed by an authorised address.");

        require (_GOTH.balanceOf(msg.sender) >= gothInput, "giveGoth: sender does not have enough GOTH to give.");
        require (_GOTH.allowance(msg.sender, address(this)) >= gothInput, "giveGoth: this contract does not have a high enough GOTH allowance.");

        _GOTH.transferFrom(msg.sender, address(this), gothInput);
    }

    function withdrawToTreasury (uint256 amount) public onlyOwner 
    {
        (bool sent, ) = _treasury.call{value: amount}("");
        require(sent, "withdrawToTreasury: failed to send Avax.");
    }
}