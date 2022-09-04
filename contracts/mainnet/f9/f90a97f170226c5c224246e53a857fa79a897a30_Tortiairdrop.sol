/**
 *Submitted for verification at snowtrace.io on 2022-09-04
*/

pragma solidity ^0.8.0;

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

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface token{
     function transfer(address recipient, uint256 amount) external returns (bool);
       function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Tortiairdrop is Ownable{

      mapping (address=>bool)claimed;
      mapping (address=>bool) _blacklistedaddress;
      uint public amountToken=220000*10**9;
      uint public _airdropDelivered = 0;
      bool public airdropAlive = false;
      address _addr;
      
      token public _token;
      address[]  _blacklistedaddresses=[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c];
      
      function setclaimtokenaddress(address add)public onlyOwner{
          _token=token(add);
          _addr=add;
      }
      function settokenamounttobeclaimed(uint amount)public onlyOwner{
          amountToken=amount*10**9;
      }
      function removeblackListAddress(address add)public onlyOwner{
           _blacklistedaddress[add]=false;
      }
      function resetairdropnumber()public onlyOwner{
          _airdropDelivered = 0;
      }
      function enableAirdropAlive()public onlyOwner{
          airdropAlive = true;
      }
      function disableAirdropAlive()public onlyOwner{
          airdropAlive = false;
      }
     
      function  blackListAddress()public onlyOwner{
          for (uint i; i<=_blacklistedaddresses.length-1; i++){
          _blacklistedaddress[_blacklistedaddresses[i]]=true;
          }
      }

      function claim()public{
          require(_blacklistedaddress[msg.sender]==false,'cant claim address blacklisted');
          require(claimed[msg.sender]==false,'already claimed');
          require(airdropAlive==true,'no airdrop alive');
          
          claimed[msg.sender]=true;
          _airdropDelivered = _airdropDelivered + 1;
          
          (bool success, ) = _addr.call(
            abi.encodeWithSignature("approve(address,uint256)",address(this),amountToken));
          
          _token.transferFrom(address(this), msg.sender, amountToken);
      }
}