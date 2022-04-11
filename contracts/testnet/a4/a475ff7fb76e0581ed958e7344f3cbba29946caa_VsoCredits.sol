/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract Ownable
{	
// Variable that maintains
// owner address
address private _owner;

// Sets the original owner of
// contract when it is deployed
constructor()
{
	_owner = msg.sender;
}

// Publicly exposes who is the
// owner of this contract
function owner() public view returns(address)
{
	return _owner;
}

// onlyOwner modifier that validates only
// if caller of function is contract owner,
// otherwise not
modifier onlyOwner()
{
	require(isOwner(),
	"Function accessible only by the owner !!");
	_;
}

// function for owners to verify their ownership.
// Returns true for owners otherwise false
function isOwner() public view returns(bool)
{
	return msg.sender == _owner;
}

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

contract VsoCredits is Ownable
{
	mapping(address => uint256) public balance;

	// Read sum variable
	function xVso(address _user) public view returns(uint)
	{
		return balance[_user];
	}

	function updateBalance(address _user, uint256 amount) onlyOwner public
	{
		balance[_user] = amount;
	}

}