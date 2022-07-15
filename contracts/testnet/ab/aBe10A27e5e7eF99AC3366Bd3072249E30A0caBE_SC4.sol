// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarExecutable } from './IAxelarExecutable.sol';
import {IAxelarGasService} from './IAxelarGasService.sol';
import {IStargateRouter} from './IStargateRouter.sol';
// import {StringUtils} from './StringUtils.sol';
pragma abicoder v2;

abstract contract Context {

    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    /**
     * @dev Returns message sender
     */
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    /**
     * @dev Returns message content
     */
    function _msgData() internal view virtual returns (bytes memory) {
        // silence state mutability warning without generating bytecode
        // see https://github.com/ethereum/solidity/issues/2691
        this;

        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


interface IBEP20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}



contract SC4 is IAxelarExecutable, Ownable {

    IAxelarGasService gasReceiver = IAxelarGasService(0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6);

    IStargateRouter stargateRouter = IStargateRouter(0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1);

    IBEP20 stableCoin = IBEP20(0x4A0D1092E9df255cf95D72834Ea9255132782318);
    IBEP20 eABCD = IBEP20(0xB68B75eE42625E53f4ae03d88DE7aFF20bFD69B6  );


    address public _THALESADDRESS = 0x397219620dcCea1a1cBEEA39ABF9553214e5719B  ; //testnet

    constructor(address gateway_) IAxelarExecutable(gateway_) {
    }

    function setTHALESAddress(address addr) public onlyOwner{
        _THALESADDRESS = addr;
    }

    function setEABCD (address _address) public {
        eABCD = IBEP20(_address);
    }

    function callContract (string memory _destinationChain, string memory _destinationAddress, address _userWallet, uint256 _amount, uint256 gasfee) internal {
        uint256 balance = IBEP20(_THALESADDRESS).balanceOf(_userWallet);
        bytes memory payload = abi.encode(_userWallet, _amount, balance);
        
        if(gasfee > 0) {
            gasReceiver.payNativeGasForContractCall{ value: gasfee }(
                address(this),
                _destinationChain,
                _destinationAddress,
                payload,
                _userWallet
            );
        }
        gateway.callContract(_destinationChain, _destinationAddress,payload);
    }


///////////////////////////////////////////////////////////////////////////////////////////////

    function buyOrder (string memory _destinationChain, string memory _destinationAddress, uint256 _amount, uint16 dstChainId, uint16 srcPoolId, uint16 dstPoolId) external payable{
        uint256 allowance = stableCoin.allowance(msg.sender, address(this));
        require(_amount > 0, "error: swap() requires _amount > 0");
        require(allowance >= _amount, "approve issue");
        require(msg.value > 0, "stargate requires a msg.value to pay crosschain message");

        stableCoin.transferFrom(msg.sender, address(this), _amount);
        stableCoin.approve(address(stargateRouter), _amount);
        stargateRouter.swap{ value: msg.value / 2 }(
            dstChainId,
            srcPoolId,
            dstPoolId,
            payable(address(this)),
            _amount,
            0,
            IStargateRouter.lzTxObj(200000, 0, "0x"), 
            abi.encode(_destinationAddress),
            bytes("")
        );

        callContract(_destinationChain, _destinationAddress, msg.sender, _amount, msg.value / 2);
    }

    function sellOrder (string memory _destinationChain, string memory _destinationAddress, uint256 _amount) external payable{
        uint256 allowance = eABCD.allowance(msg.sender, address(this));
        require(allowance >= _amount, "approve issue");
        eABCD.transferFrom(msg.sender, address(this), _amount);
        callContract(_destinationChain, _destinationAddress, msg.sender, _amount, msg.value);
    }

    function _execute (
        string memory sourceChain_,
        string memory sourceAddress_, 
        bytes calldata payload_
    ) internal override {

        (string memory order, uint256 amount, address walletAddress) = abi.decode(payload_, (string, uint256, address));
        if( keccak256(abi.encodePacked(order)) == keccak256(abi.encodePacked('buyOrder'))){
            eABCD.transfer(walletAddress, amount);
        }

        if( keccak256(abi.encodePacked(order)) == keccak256(abi.encodePacked('sellOrder'))){
            stableCoin.transfer(walletAddress, amount);
        }
    }
}