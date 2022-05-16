/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-16
*/

pragma solidity ^0.4.22;
pragma experimental ABIEncoderV2;

contract trace{
  mapping (address=> uint256[])  item_id;  
  mapping (uint256 => address) final_recipient;
  uint256 public id=1;
  struct item_info {
      string ipfs;
      address creator;
      address owner;
      address nextowner;
      address recipient;
   }
   mapping(uint256 => item_info) items;
   mapping(uint256=> string[]) history_ipfs;
   mapping(uint256=> address[]) history_owner;
   mapping(uint256=> bool) id_lock;

  

  function sell(string ipfs,address recept,address next) public returns (uint256){
    item_id[msg.sender].push(id);
    
    items[id]=item_info(ipfs,msg.sender,msg.sender,next,recept);
    
    history_ipfs[id].push(ipfs);
    history_owner[id].push(msg.sender);
    ++id;
    return(id-1);
  }

  function agree(uint256 nowid) public returns (bool){
     if(id_lock[nowid]==true)return false;
     if( msg.sender == items[nowid].nextowner){
        if(msg.sender==items[nowid].recipient){
            items[nowid].owner=msg.sender;
            history_owner[nowid].push(msg.sender);
            id_lock[nowid]=true;
        }else{
           items[nowid].owner=msg.sender;
           history_owner[nowid].push(msg.sender);
        }
       return true;
     }else{
       return false;
     }
  } 
  function transfer(uint256 nowid,address next, string ipfs) public returns(bool){
     if(id_lock[nowid]==true)return false;
     if(items[nowid].owner==msg.sender){
        items[nowid].nextowner=next;
        items[nowid].ipfs=ipfs;
        history_ipfs[nowid].push(ipfs);
        return true;
     }else{
        return false;
     }
  }


  function person_item(address person) public view returns(uint256[]){
          return item_id[person];
  }
  function item_ipfs_history(uint256 nowid) public view returns(string[]){
          return history_ipfs[nowid];
  }
  function item_owner_history(uint256 nowid) public view returns(address[]){
          return history_owner[nowid];
  }
  function item_info_now(uint256 nowid) public view returns(item_info ){
          return items[nowid];
  }
  function item_lock_check(uint256 nowid) public view returns(bool){
       return id_lock[nowid];
  }
}