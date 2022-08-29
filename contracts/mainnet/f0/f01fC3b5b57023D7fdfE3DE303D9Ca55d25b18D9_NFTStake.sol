// SPDX-License-Identifier: (Unlicense)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
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

pragma solidity ^0.8.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    
    event URI(string value, uint256 indexed id);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);
    
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    
    function setApprovalForAll(address operator, bool approved) external;
    
    function isApprovedForAll(address account, address operator) external view returns (bool);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
library myLib {
	function addressInList(address[] memory  _list, address _account) internal pure returns(bool){
		for(uint i=0;i<_list.length;i++){
			if(_account == _list[i]){
				return true;
			}
		}
		return false;
	}

}
pragma solidity ^0.8.0;

interface IERC1155Receiver is IERC165 {
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
pragma solidity ^0.8.0;
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
pragma solidity ^0.8.7;
contract NFTStake is Ownable {
    IERC1155 public parentNFT;
    address _NFTcontract = 0x3C1000Bb0b0b2d6678e0c3F58957f33C48C6C89C;
    address public NFTcontract;
    
    struct Stake_1 {
        uint256 timestamp;
    }
    struct Stake_2 {
        uint256 timestamp;
    }
    struct Stake_3 {
        uint256 timestamp;
    }
    mapping(address => Stake_1[]) public stakes_1;
    mapping(address => Stake_2[]) public stakes_2;
    mapping(address => Stake_3[]) public stakes_3;
    address[] public accounts;
    constructor() {
    	NFTcontract = _NFTcontract;
    }
    function isStaked(address _account) external view returns(bool){
    	return myLib.addressInList(accounts,_account);
    }
    function idAmount(address _account,uint256 i) external view returns(uint256){
      	if (i == 0){
      		Stake_1[] storage stakes = stakes_1[_account];
      		return stakes.length;
  	}if (i == 1){
  		Stake_2[] storage stakes = stakes_2[_account];
  		return stakes.length;
  	}if (i == 2){
  		Stake_3[] storage stakes = stakes_3[_account];
  		return stakes.length;
  	}
  	
    }
    function getTimes(address _account,uint256 i,uint256 k) external view returns(uint256){
      	if (i == 0){
  		Stake_1[] storage stakes = stakes_1[_account];
  		Stake_1 storage stake = stakes[k];
  		return stake.timestamp;
  	}if (i == 1){
  		Stake_2[] storage stakes = stakes_2[_account];
  		Stake_2 storage stake = stakes[k];
  		return stake.timestamp;
  	}if (i == 2){
  		Stake_3[] storage stakes = stakes_3[_account];
  		Stake_3 storage stake = stakes[k];
  		return stake.timestamp;
  	}
  	
    }
    function stake(uint256 _tokenId, uint256 _amount) external {
    	require(_tokenId >0 && _tokenId <4,"cannot stake NFT Ids other than 1,2, or 3");
    	uint256 time = block.timestamp;
    	if (_tokenId == 1) {
    		Stake_1[] storage stakes = stakes_1[msg.sender];
		for(uint i=0;i<_amount;i++){
    			stakes.push(Stake_1({
        			timestamp:time
        		}));
		}
        }
    	if (_tokenId == 2) {
    		Stake_2[] storage stakes = stakes_2[msg.sender];
		for(uint i=0;i<_amount;i++){
    			stakes.push(Stake_2({
        			timestamp:time
        		}));
		}
        }
    	if (_tokenId == 3) {
    		Stake_3[] storage stakes = stakes_3[msg.sender];
		for(uint i=0;i<_amount;i++){
    			stakes.push(Stake_3({
        			timestamp:time
        		}));
		}
        }
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "0x00");
    } 
    
    function unstake(uint256 _tokenId, uint8 _amount) external{
	    if (_tokenId == 1) {
		for(uint i=0;i<_amount;i++){
			Stake_1[] storage stakes = stakes_1[msg.sender];
			for(uint j=0;j<stakes.length;j++){
				if(j<stakes.length-1){
				    Stake_1 storage stake = stakes[j];
				    Stake_1 storage stake_ = stakes[j+1];
				    stake.timestamp = stake_.timestamp;
				}
			}
			stakes.pop();
		}
	   }
	   if (_tokenId == 2) {
		for(uint i=0;i<_amount;i++){
			Stake_2[] storage stakes = stakes_2[msg.sender];
			for(uint j=0;j<stakes.length;j++){
				if(j<stakes.length-1){
				    Stake_2 storage stake = stakes[j];
				    Stake_2 storage stake_ = stakes[j+1];
				    stake.timestamp = stake_.timestamp;
				}
			}
			stakes.pop();
		}
	   }
	   if (_tokenId == 3) {
		for(uint i=0;i<_amount;i++){
			Stake_3[] storage stakes = stakes_3[msg.sender];
			for(uint j=0;j<stakes.length;j++){
				if(j<stakes.length-1){
				    Stake_3 storage stake = stakes[j];
				    Stake_3 storage stake_ = stakes[j+1];
				    stake.timestamp = stake_.timestamp;
				}
			}
			stakes.pop();
		}
	}	
        parentNFT.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "0x00");
    }  
    
     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    function changeNFTcontract(address contract_address) external onlyOwner {
    	NFTcontract = contract_address;
    	parentNFT = IERC1155(NFTcontract);
    }
    
}