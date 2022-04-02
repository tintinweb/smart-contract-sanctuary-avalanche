/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-01
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
contract Faucet is Ownable {
    address public addressClaim;
    mapping (address => uint256) public amountClaim;
    mapping (address => uint256) public claimLatest;
    uint256 public amountClaimDefault = 10000;
    uint256 public claimTime = 60 minutes;

    constructor(){
        addressClaim = msg.sender;
    }
    function setAddressClaim(address addressNew) public onlyOwner {
        addressClaim = addressNew;
    }
    function setAmountClaim(address tokenAddress, uint256 amount) public onlyOwner {
        amountClaim[tokenAddress] = amount;
    }

    function setAmountClaim(uint256 amount) public onlyOwner {
        amountClaimDefault = amount;
    }

    function setClaimTime(uint256 time) public onlyOwner {
        claimTime = time;
    }

    function claim(address tokenAddress) public {
        require(block.timestamp - claimLatest[msg.sender] > claimTime, "Please wait until next claim");
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = amountClaim[tokenAddress];
        if (amount == 0)
            amount = amountClaimDefault;
        token.transferFrom(addressClaim, msg.sender, amount * 10 ** token.decimals());
        claimLatest[msg.sender] = block.timestamp;
    }
}