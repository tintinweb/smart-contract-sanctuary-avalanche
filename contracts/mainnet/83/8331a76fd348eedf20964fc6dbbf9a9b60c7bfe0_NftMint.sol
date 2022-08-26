/**
 *Submitted for verification at snowtrace.io on 2022-08-26
*/

// SPDX-License-Identifier: (Unlicense)
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library nebuLib {
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
		for(uint i=0;i<_list.length;i++){
			if(_account == _list[i]){
				return true;
			}
		}
		return false;
	}
}
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;
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

abstract contract prevNftMint is Context {
	function NFTAccountsLength() external virtual returns(uint256);
	function NFTAccountAddress(uint256 _x) external virtual returns(address);
	function NFTaccountExists(address _account) external virtual returns (bool);
	function NFTaccountData(address _account) external virtual returns(uint256,uint256,uint256,uint256,uint256,uint256,bool);
}
abstract contract overseer is Context {
   function getAvaxDollar() external virtual returns(uint256);
   function getAvaxPrice() external virtual returns (uint256);
   function getNftInfo(address _account,uint256 _id,uint256 _k) external virtual returns(uint256);
   function getStakedAmount(address _account,uint256 _id) external virtual returns(uint256);
   
} 
abstract contract NebulaNFT is Context {
	function Pmint(address _account, uint256 _id, uint256 _amount, bytes memory data) external virtual;
	function mint(address _account, uint256 _id, uint256 _amount, bytes memory data) external virtual;
	function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory data) external virtual;
}

contract NftMint is Ownable {
    using SafeMath for uint256;
    struct TOTALS {
    	    uint256 tier_1;
    	    uint256 tier_2;
    	    uint256 tier_3;
    	    uint256 total;
    	    uint256 totalUSD;
    	    uint256 totalAVAX;
    	    bool full;
    	   }
    mapping(address => TOTALS) public totals;
    address[] public NFTaccounts;
    address[] public NFTtransfered;
    address[] public Managers;
    address public nftAddress;
    address public _overseer;
    address payable treasury;
    address Guard;
    uint256 public limit;
    uint256[] public maxSupplies;
    uint256 public Zero = 0;
    uint256[] public nft_cost;
    overseer public over;
    NebulaNFT public nft;
    modifier managerOnly() {require(nebuLib.addressInList(Managers,msg.sender)== true); _;}
    constructor(address[] memory addresses,address payable _treasury, uint256[] memory supplies,uint256[] memory _costs,uint256 _limit) {
    	for(uint i = 0;i<addresses.length;i++){
    		require(addresses[i] != address(0) && addresses[i] != address(this),"your constructor addresses contain either burn or this");
    	}
    	nftAddress = addresses[0];
    	nft = NebulaNFT(nftAddress);
    	_overseer = addresses[1];
    	over = overseer(_overseer);
    	treasury = _treasury;
    	for(uint256 i=0;i<_costs.length;i++){
    		nft_cost.push(_costs[i]);
    	}
    	for(uint256 i=0;i<_costs.length;i++){
    		maxSupplies.push(supplies[i]);
    	}
    	limit = _limit;
    	Managers.push(owner());
    }
    function getMax(uint256 _num) internal view returns(bool){
        TOTALS storage house = totals[address(this)];
        if(_num == 0){
    		if(house.tier_1 < maxSupplies[_num]){
    			return false;
    		}
    	}
    	if(_num == 1){
    		if(house.tier_2 < maxSupplies[_num]){
    			return false;
    		}
    	}
    	if(_num == 2){
    		if(house.tier_3 < maxSupplies[_num]){
    			return false;
    		}
    	}
    	return true;
    }
    function getAvaxPrice(uint256 _val) internal returns(uint256) {
    	uint256 _dollar = over.getAvaxDollar();
    	return _dollar.mul(_val);
    }
    function mint(uint256 _id) payable external {
    	uint256 num = _id - 1;
    	require(getMax(num) == false,"the totala supply for this tier has already been minted");
    	address _account = msg.sender;
    	uint256 _price = getAvaxPrice(nft_cost[num]);
    	uint256 _value = msg.value;
    	require(_value >= _price,"you did not send enough to purchase this NFT");
    	uint256 balance = address(_account).balance;
    	require(balance >= _value,"you do not hold enough to purchase this NFT");
    	TOTALS storage tot = totals[_account];
        if (nebuLib.addressInList(NFTaccounts,_account) == false){
    		NFTaccounts.push(_account);
    	}

    	require(tot.full != true,"sorry, you already have too many NFT's");
    	if (_id == 1){
	    nft.Pmint(_account,1,1,"0x0");
    	}else if (_id == 2){
	    nft.Pmint(_account,2,1,"0x0");
    	}else if (_id == 3){
	    nft.Pmint(_account,3,1,"0x0");
    	}
    	treasury.transfer(_price);
    	uint256 returnBalance = _value.sub(_price);
    	if(returnBalance > 0){
		payable(_account).transfer(returnBalance);
	}
	updateTotals(_account,_id,1);
    }
    function MGRmint(uint256[] memory _ids,address[] memory _accounts,bool _send,bool _record,bool _fullOverrride) external managerOnly {
    	for(uint i=0;i<_ids.length;i++){
    		uint256 _id = _ids[i];
    		address _account = _accounts[i];
	    	uint256 num = _id - 1;
	    	TOTALS storage tot = totals[_account];
	    	bool full = tot.full;
	    	if(_fullOverrride == true){
	    		full = false;
	    	}
		if (nebuLib.addressInList(NFTaccounts,_account) == false){
	    		NFTaccounts.push(_account);
	    	}
	    	if (full == false && _send == true) {
		    	getMax(num);
		    	if (_id == 1){
			    nft.Pmint(_account,1,1,"0x0");
		    	}else if (_id == 2){
			    nft.Pmint(_account,2,1,"0x0");
		    	}else if (_id == 3){
			    nft.Pmint(_account,3,1,"0x0");
		    	}
		}
		if (_record == true){
		    	updateTotals(_account,_id,1);
		}
		
	    }
    }
    function transferAllNFTdata(address prev) external managerOnly {
    		prevNftMint _prev = prevNftMint(prev);
    	    	uint256 accts = _prev.NFTAccountsLength();
    	    	for(uint i=0;i<accts;i++){
    	    		address _account = _prev.NFTAccountAddress(i);
    	    		if(nebuLib.addressInList(NFTtransfered,_account) == false){
	    	    		TOTALS storage tots = totals[_account];
	    	    		(uint256 a,uint256 b,uint256 c,uint256 d,uint256 e,uint256 f,bool g)= _prev.NFTaccountData(_account);
	    	    		tots.tier_1 = a;
	    	    		tots.tier_2 = b;
	    	    		tots.tier_3 = c;
	    	    		tots.total =d;
	    	    		tots.totalUSD = e;
	    	    		tots.totalAVAX = f;
	    	    		tots.full = g;
	    			NFTtransfered.push(_account);
	    		}
	    	}
    }
    function updateTotals(address _account, uint256 _id,uint256 _amount) internal {
    	uint256[3] memory vals = [Zero,Zero,Zero];
    	if(_id != 0){
    		vals[_id-1] = _id;
    	}
    	TOTALS storage tot = totals[_account];
    	tot.tier_1 += vals[0];
    	tot.tier_2 += vals[1];
    	tot.tier_3 += vals[2];
    	if(_id != 0){
        	tot.total += 1;
        }
    	tot.totalUSD += _amount;
    	tot.totalAVAX += msg.value;
	tot.full = false;
    	if ((tot.tier_1).add(tot.tier_2).add(tot.tier_3) >= 10){
    		tot.full = true;
    	}
    }
    function changeCostNfts(uint256[3] memory _costs) external onlyOwner{
    	for(uint256 i = 0;i<_costs.length;i++){
    		nft_cost[i] = _costs[i]*(10**18);
    	}
    }
    function NFTaccountExists(address _account) external returns (bool) {
    	return nebuLib.addressInList(NFTaccounts,_account);
    }
    function nftAccountData(address _account) external managerOnly returns(uint256,uint256,uint256,uint256,uint256,uint256,bool){
    		TOTALS storage tot = totals[_account];
    		return (tot.tier_1,tot.tier_2,tot.tier_3,tot.total,tot.totalUSD,tot.totalAVAX,tot.full);
    	}
    function changeNFTAddress(address _address) external managerOnly {
    	nftAddress = _address;
    	nft = NebulaNFT(nftAddress);
    }
    function updateManagers(address newVal) external onlyOwner {
    	if(nebuLib.addressInList(Managers,newVal) ==false){
        	Managers.push(newVal); //token swap address
        }
    }
    function updateGuard(address _address) external onlyOwner {
        Guard = _address; //token swap address
    }
    function nftAccountsLength() external view returns(uint256){
    	return NFTaccounts.length;
    }
    function changeNftAddress(uint256 _x) external view returns(address){
    	return NFTaccounts[_x];
    }
    function nftAccountExists(address _account) external returns (bool) {
    	return nebuLib.addressInList(NFTaccounts,_account);
    }
}