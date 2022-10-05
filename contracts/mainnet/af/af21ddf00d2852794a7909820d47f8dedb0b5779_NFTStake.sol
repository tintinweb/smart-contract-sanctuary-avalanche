/**
 *Submitted for verification at snowtrace.io on 2022-10-05
*/

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
	function placeInList(address[] memory _list, address _account) internal pure returns(uint){
		for(uint i=0;i<_list.length;i++){
			if(_account == _list[i]){
				return i;
			}
		}
	}
	function addressInList(address[] memory _list, address _account) internal pure returns(bool){
		for(uint i=0;i<_list.length;i++){
			if(_account == _list[i]){
				return true;
			}
		}
		return false;
	}
	function isInList(uint256[] memory _list, uint256 _id) internal pure returns(bool){
		for(uint i=0;i<_list.length;i++){
			if(_id == _list[i]){
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

pragma solidity ^0.8.0;
contract NFTStake is Ownable {
    IERC1155 public parentNFT;
    address public NFTcontract;
    uint256 public time = block.timestamp;
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
    address[] public staked;
    constructor(address _NFTcontract) {
    NFTcontract = _NFTcontract;
    }
    function isStaked(address _account) external view returns(bool){
    	return myLib.addressInList(staked,_account);
    }
    
    function isStakedSpec(address _account) external returns(uint256[3] memory){
    	return [INTidAmount(_account,1),INTidAmount(_account,2),INTidAmount(_account,3)];
    }
    function idAmount(address _account,uint256 _id) external returns(uint256){
    	INTidAmount(_account,_id);
    }
    function INTidAmount(address _account,uint256 _id) internal returns(uint256){
    	require(_id > 0 && _id < 4,"you have not entered a valid token ID, must be less than 4 but greater than zero");
      	if (_id == 1){
      		Stake_1[] storage _stakes = stakes_1[_account];
  		return _stakes.length;
  	}
  	if (_id == 2){
  		Stake_2[] storage _stakes = stakes_2[_account];
  		return _stakes.length;
  	}
  	if (_id == 3){
  		Stake_3[] storage _stakes = stakes_3[_account];
  		return _stakes.length;
  	}
    }
    function getTimes(address _account,uint256 _id,uint256 k) external returns(uint256){
    	require(_id > 0 && _id < 4,"you have not entered a valid token ID, must be less than 4 but greater than zero");
    	address _account = msg.sender;
    	uint256 amt = INTidAmount(_account,_id);
      	if (_id == 1){
      		Stake_1[] storage _stakes = stakes_1[_account];
      		require(k <= amt,"you have entered an amount greater than what you hold");
  		return _stakes[k].timestamp;
  	}
  	if (_id == 2){
  		Stake_2[] storage _stakes = stakes_2[_account];
  		require(k <= amt,"you have entered an amount greater than what you hold");
  		return _stakes[k].timestamp;
  	}
  	if (_id == 3){
  		Stake_3[] storage _stakes = stakes_3[_account];
  		require(k <= amt,"you have entered an amount greater than what you hold");
  		return _stakes[k].timestamp;
  	}
    }
    function stake(uint256 _tokenId, uint256 _amount) public {
    	require(_tokenId > 0 && _tokenId < 4,"you have not entered a valid token ID, must be less than 4 but greater than zero");
    	require(_amount >0,"you have not entered a valid token Amount, must be greater than Zero");
    	address _account = msg.sender;
    	if(myLib.addressInList(staked,_account)==false){
    		staked.push(_account);
    	}
    	if (_tokenId == 1) {
    		Stake_1[] storage _stakes = stakes_1[_account];
		for(uint j=0;j<_amount;j++) {
			_stakes.push(Stake_1({
				timestamp:block.timestamp
			}));
		}
        }
        if (_tokenId == 2) {
    		Stake_2[] storage _stakes = stakes_2[_account];
		for(uint j=0;j<_amount;j++) {
			_stakes.push(Stake_2({
				timestamp:block.timestamp
			}));
		}
        }
        if (_tokenId == 3) {
    		Stake_3[] storage _stakes = stakes_3[_account];
		for(uint j=0;j<_amount;j++) {
			_stakes.push(Stake_3({
				timestamp:block.timestamp
			}));
		}
        }
        parentNFT.safeTransferFrom(_account, address(this), _tokenId, _amount, "0x00");
    } 
    function unstake(uint256 _tokenId, uint8 _amount) public {
        require(_tokenId > 0 && _tokenId < 4,"you have not entered a valid token ID, must be less than 4 but greater than zero");
    	require(_amount >0,"you have not entered a valid token Amount, must be greater than Zero");
    	address _account = msg.sender;
	if (_tokenId == 1) {
		for(uint j=0;j<_amount;j++) {
		    Stake_1[] storage _stakes = stakes_1[_account];
		    uint len = _stakes.length - 1;
		    for(uint i = 0;i<len;i++){
			_stakes[i] = _stakes[i+1];
		    }
		    _stakes.pop();
		}
	}
	if (_tokenId == 2) {
		for(uint j=0;j<_amount;j++) {
		    Stake_2[] storage _stakes = stakes_2[_account];
		    uint len = _stakes.length;
		    for(uint i = 0;i<len;i++){
			_stakes[i] = _stakes[i+1];
		    }
		    _stakes.pop();
		}
	}
	if (_tokenId == 3) {
		for(uint j=0;j<_amount;j++) {
		    Stake_3[] storage _stakes = stakes_3[_account];
		    uint len = _stakes.length;
		    for(uint i = 0;i<len;i++){
			_stakes[i] = _stakes[i+1];
		    }
		    _stakes.pop();
		}
	}
	reconcileStaked(_account);
	parentNFT.safeTransferFrom(address(this),_account,_tokenId,_amount, "0x00");
    }
    function reconcileStaked(address _account) internal{
    	uint256 _amt;
    	for(uint i=1;i<4;i++){
    		_amt += INTidAmount(_account,i);
    	}
    	if(_amt == 0){
    		uint _x = myLib.placeInList(staked,_account);
    		uint len = staked.length-1;
    		for(uint i = _x;i<len;i++){
    			staked[i] = staked[i+1];
    		}
    		staked.pop();
    	}
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