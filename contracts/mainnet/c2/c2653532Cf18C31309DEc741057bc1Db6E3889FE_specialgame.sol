/**
 *Submitted for verification at snowtrace.io on 2022-03-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract specialgame is Ownable{
   
    constructor() payable {
        
    }
    uint256 flipCount;
    uint256 winnerCount;
    uint256 loserCount;
    uint256 maxWinStrake;
    uint256 winnertotall;
    uint256 losertotall;
    uint256 totallfee;
    uint256 public cost1 = 50000000000000000;
    uint256 public cost2 = 100000000000000000;
    uint256 public cost3 = 500000000000000000;
    uint256 public cost4 = 1000000000000000000;
    uint256 public cost5 = 2000000000000000000;
    address public addr = 0xAfC5D4f80564E723C5c3EC41c0CfA49EA6a39C63;
    
     struct winnerListWalletStruct{
        address sender;
    }
     struct loserListWalletStruct{
        address sender;
    }
    winnerListWalletStruct[]  winnerlistwallet;
    loserListWalletStruct[]  loserlistwallet;
   
    event userListener(uint256 indexed date,address indexed from,string gfscore);
    
    function startGamecost1(uint _inuserselect)  payable public{
        require(msg.value >= 50000000000000000, 'Need to send 0.05 AVAX');
        
        payable(addr).transfer(1750000000000000);
       
         flipCount += 1;
         totallfee += 1750000000000000;
       
        if(61 != _inuserselect){
            loserCount += 1;
            loserlistwallet.push(loserListWalletStruct(msg.sender));
             losertotall += 50000000000000000;
            
              emit userListener(block.timestamp,msg.sender,"lose");
        }else{
            winnerCount += 1;
             winnerlistwallet.push(winnerListWalletStruct(msg.sender));
             payable(msg.sender).transfer(98250000000000000);
            winnertotall += 98250000000000000;
            
           emit userListener(block.timestamp,msg.sender,"win");
        }
        
        
    }
    function startGamecost2(uint _inuserselect)  payable public{
        require(msg.value >= 100000000000000000, 'Need to send 0.1 AVAX');
        payable(addr).transfer(3500000000000000);
       
         flipCount += 1;
         totallfee += 3500000000000000;
        if(61 != _inuserselect){
            loserCount += 1;
            loserlistwallet.push(loserListWalletStruct(msg.sender));
             losertotall += 100000000000000000;
            
              emit userListener(block.timestamp,msg.sender,"lose");
        }else{
            winnerCount += 1;
             winnerlistwallet.push(winnerListWalletStruct(msg.sender));
             payable(msg.sender).transfer(196500000000000000);
            winnertotall += 196500000000000000;
            
           emit userListener(block.timestamp,msg.sender,"win");
        }
        
        
    }
    function startGamecost3(uint _inuserselect)  payable public{
        require(msg.value >= 500000000000000000, 'Need to send 0.5 AVAX');
        payable(addr).transfer(17500000000000000);
       
         flipCount += 1;
         totallfee += 52500000000000000;
        if(61 != _inuserselect){
            loserCount += 1;
            loserlistwallet.push(loserListWalletStruct(msg.sender));
             losertotall += 500000000000000000;
            
              emit userListener(block.timestamp,msg.sender,"lose");
        }else{
            winnerCount += 1;
             winnerlistwallet.push(winnerListWalletStruct(msg.sender));
             payable(msg.sender).transfer(982500000000000000);
            winnertotall += 982500000000000000;
            
           emit userListener(block.timestamp,msg.sender,"win");
        }
        
        
    }
    function startGamecost4(uint _inuserselect)  payable public{
        require(msg.value >= 1000000000000000000, 'Need to send 1 AVAX');
        
         flipCount += 1;
          payable(addr).transfer(35000000000000000);
         totallfee += 35000000000000000;
        if(61 != _inuserselect){
            loserCount += 1;
            loserlistwallet.push(loserListWalletStruct(msg.sender));
             losertotall += 1000000000000000000;
            
              emit userListener(block.timestamp,msg.sender,"lose");
        }else{
            winnerCount += 1;
             winnerlistwallet.push(winnerListWalletStruct(msg.sender));
             payable(msg.sender).transfer(1965000000000000000);
            winnertotall += 1965000000000000000;
            
           emit userListener(block.timestamp,msg.sender,"win");
        }
        
        
    }
    function startGamecost5(uint _inuserselect)  payable public{
          require(msg.value >= 2000000000000000000, 'Need to send 1 AVAX');
        
         flipCount += 1;
          payable(addr).transfer(70000000000000000);
         totallfee += 70000000000000000;
        if(61 != _inuserselect){
            loserCount += 1;
            loserlistwallet.push(loserListWalletStruct(msg.sender));
             losertotall += 2000000000000000000;
            
              emit userListener(block.timestamp,msg.sender,"lose");
        }else{
            winnerCount += 1;
             winnerlistwallet.push(winnerListWalletStruct(msg.sender));
             payable(msg.sender).transfer(3930000000000000000);
            winnertotall += 3930000000000000000;
            
           emit userListener(block.timestamp,msg.sender,"win");
        }
        
        
    }
   
    function getTotalFee() public view returns (uint256){
        return totallfee;
    }
    
    

    function getFlipCount() public view returns (uint256){
        return flipCount;
    }
    function getWinnerCount() public view returns (uint256){
        return winnerCount;
    }
    function getLoserCount() public view returns (uint256){
        return loserCount;
    }
   
    function random() public view returns (uint) {
       uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
    )));

    return seed;
    }
    
    function balanceOf() external view returns(uint){
        return address(this).balance;
    }
     function getcashMe() public payable {}
     function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}