/**
 *Submitted for verification at snowtrace.io on 2022-05-15
*/

pragma solidity ^0.4.24;

/**
 * @title Token
 * @dev Simpler version of ERC20 interface
 */
contract Token {
    function balanceOf(address owner) public returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract AirDrop is Ownable {
    // This declares a state variable that would store the contract address
    Token public tokenInstance;
    mapping(address => bool) _hasBeenDeliveredTokens;

    /*
      constructor function to set token address
     */
    constructor(address _tokenAddress) public {
        tokenInstance = Token(_tokenAddress);
    }

    /*
      Airdrop function which take up a array of address, and array of amount
     */
    function sendBatch(address[] _recipients, uint[] _amounts) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < _recipients.length; i++) {
            //prevent accidentally sending twice
            if (_hasBeenDeliveredTokens[_recipients[i]]) continue;
            uint256 balance = _amounts[i];
            _hasBeenDeliveredTokens[_recipients[i]] = true;
            tokenInstance.transferFrom(
                msg.sender,
                _recipients[i],
                balance
            );
        }
        return true;
    }

    function withdraw() public onlyOwner returns (bool) {
        uint256 balance_ = tokenInstance.balanceOf(address(this));
        tokenInstance.transfer(msg.sender, balance_);
        return true;
    }
}