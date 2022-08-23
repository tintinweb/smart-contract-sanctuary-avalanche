/**
 *Submitted for verification at snowtrace.io on 2022-08-23
*/

/**
 *Submitted for verification at snowtrace.io on 2022-07-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-09
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: UNLICENSED


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(  uint256 amount, address _target ) external returns (bool);
    function transfer( address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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



abstract contract Ownable is Context {
    address private _owner;

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
}



interface RandoEcosystem{
    function  isEngineContract( address _address ) external returns (bool);
    function returnAddress ( string memory _contract ) external returns ( address );
}


contract RandoData is Ownable {

    RandoEcosystem public ecosystem;

    uint256 public requests;
    uint256 public requestsProcessed;
    mapping ( uint256 => Request ) public Requests;
    mapping ( address => uint256 ) public lastRequest;

    struct Request {
        address _caller;
        uint8 _type;
        uint8 _numberofdie;
        uint8 _diesides;
        uint256 _result;
        bool _processed;

    }
    constructor( address _ecosystem ) payable {
        ecosystem = RandoEcosystem ( _ecosystem);
    }

    function process ( uint256 _request, uint256 _result ) public onlyEngine{
        require (  !Requests[_request]._processed , "Already Processed");
        require ( requestsProcessed < requests, "Not Allowed" );
        Requests[_request]._result = _result;
        Requests[_request]._processed = true;
        requestsProcessed++;
    }

    function getRandoAddress() public  returns(address _addy){
        _addy = ecosystem.returnAddress("RANDO");
    }


    function updateRandoEcosystem ( address _ecosystem ) public onlyOwner{
           ecosystem = RandoEcosystem ( _ecosystem);
    }

    function requestDice( address _caller, uint8 _type, uint8 _numberofdie, uint8 _diesides ) public onlyEngine returns ( uint256) {
        requests++;
        Requests[requests]._caller = _caller;
        Requests[requests]._type = _type;
        Requests[requests]._numberofdie = _numberofdie;
        Requests[requests]._diesides = _diesides;
        lastRequest[msg.sender] = requests;
        return requests;
    }

    function getResult( uint256 _request ) public view returns(uint256){
        require ( Requests[_request]._processed, "Not Processed Yet" );
        return Requests[_request]._result;
    }

    //EMERGENCY ONLY
    function setRequestsAndProcessed ( uint256 _requests, uint256 _processed ) public onlyOwner {
        requests = _requests;
        requestsProcessed = _processed;
    }

    modifier onlyEngine() {
        require ( ecosystem.isEngineContract(msg.sender), "Not an Engine Contract");
         _;
    }


}