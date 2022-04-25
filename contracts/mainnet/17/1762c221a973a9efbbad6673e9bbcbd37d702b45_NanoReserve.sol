/**
 *Submitted for verification at snowtrace.io on 2022-04-23
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-07
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: UNLICENSED


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
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



interface EngineEcosystemContract{
    function isEngineContract( address _address ) external returns (bool);
    function returnAddress ( string memory _contract ) external returns ( address );
}


contract NanoReserve is Ownable {

    EngineEcosystemContract public engineecosystem;

    constructor( address _ecosystem ){
        engineecosystem = EngineEcosystemContract ( _ecosystem);
    }

    function updateEcosystemContract ( address _ecosystem ) public onlyOwner{
         engineecosystem = EngineEcosystemContract ( _ecosystem);
    }

    function EmergencyWithdrawal ( address _address ) public onlyOwner{
        IERC20 _token = IERC20 ( _address );
        _token.transfer ( msg.sender, _token.balanceOf(address(this)));
    }

    function emergencyWithdrawAVAX() public onlyOwner {
       payable(msg.sender).transfer( address(this).balance );
    }


    function ApproveNMAC( address _address ) public onlyOwner {
        IERC20 _token = IERC20 ( engineecosystem.returnAddress("NMAC"));
        _token.approve ( _address , (2 **256)-1 );
    }

    function ApproveToken( address _address , address _tokenaddress ) public onlyOwner {
        IERC20 _token = IERC20 ( _tokenaddress );
        _token.approve ( _address , (2 **256)-1 );
    }

    function NMACBalance() public  returns(uint256){
        IERC20 _token = IERC20 ( engineecosystem.returnAddress("NMAC"));
        return ( _token.balanceOf(address(this)));
    }

    modifier onlyEngine() {
       
        require ( engineecosystem.isEngineContract(msg.sender), "Not an Engine Contract");
         _;
    }


}