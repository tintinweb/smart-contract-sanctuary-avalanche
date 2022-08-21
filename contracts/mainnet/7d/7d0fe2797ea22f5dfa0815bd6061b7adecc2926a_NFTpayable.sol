/**
 *Submitted for verification at snowtrace.io on 2022-08-21
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-20
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-19
*/
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
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
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

abstract contract NebulaNFT is Context {
    function PsetURI(uint256 k) external view virtual;
    function Pmint(address account, uint256 id, uint256 amount, bytes memory data) external virtual;
    function checkTots() external virtual view  returns(uint256[3] memory);


}
contract NFTpayable is Ownable {

    string public constant name = "Nebula";
    string public constant symbol = "NEFI";
    using SafeMath for uint256;
    struct Recieved {
	    uint256 amountrecieved;
	    uint256 amountverified;
	    bool full;
    
    }
    struct Sent{
	    uint256 tok1;
	    uint256 tok2;
	    uint256 tok3;
    }
    mapping(address => Recieved) public recieved;
    mapping(address => Sent) public sent;
    address[] public accounts;
    uint256 public Zero = 0;
    uint256 public one = 1;
    uint256 public limit1 = 10;
    uint256 public limit2 = 10;
    uint256 public limit3 = 10;
    uint256 public cost1 = 300*(10**6);
    uint256 public cost2 = 750*(10**6);
    uint256 public cost3 = 1500*(10**6);
    uint256 public gas = 1*(10**17);
    uint256[3] public maxSupplies = [3000,2000,1000];
    uint256[3] public nft_cost = [cost1,cost2,cost3];
    NebulaNFT public nft;
    IERC20 public _feeToken;
    address public nftAddress;
    address public treasury;
    address public feeToken;

 
    // Payable constructor can receive Ether
    constructor() payable {
        
        nftAddress = 0x3C1000Bb0b0b2d6678e0c3F58957f33C48C6C89C;
        nft = NebulaNFT(nftAddress);
        treasury = 0x6EF53D5FD1B15B0f6c38E1Ea72F72eb33134E75D;
        feeToken = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
        _feeToken = IERC20(feeToken);
    }
   function queryERC20Balance(address _account) internal view returns (uint) {
        return IERC20(_feeToken).balanceOf(_account);
    }
    function Tots() internal view returns(uint256[3] memory){
    	uint256[3] memory tots = nft.checkTots();
    	return tots;
    } 
    function checkFull(uint256 num) internal {
    	uint256[3] memory ls = Tots();
    	require(ls[num] <= maxSupplies[num],"the totala supply for this tier has already been minted") ;
    	}
    
    function isInList(address _account, address[] memory list) internal returns(bool){
    	for(uint i=0;i<list.length;i++){
    		if(_account == list[i]){
    			return true;
    		}
    	}
    	return false;
    }
    function mint(uint256 _id) external {
    	
    	address _account = msg.sender;
    	uint256 num = _id - 1;
        if (isInList(_account,accounts) == false){
    		accounts.push(_account);
    	}
    	Recieved storage _rec = recieved[_account];
    	require(_rec.full != true,"sorry, you already have too many NFT's");
    	Sent storage _sent = sent[_account];
    	uint256 tokens = 1;
    	require(queryERC20Balance(_account) >= tokens,"you dont have enough to purchase this NFT");
    	checkFull(num);
    	SendFeeToken(msg.sender,treasury,tokens);
    	_rec.amountrecieved += nft_cost[num];

    	_rec.amountverified += nft_cost[num];
    	if ((_sent.tok1).add(_sent.tok2).add(_sent.tok3) >= 10){
    		_rec.full = true;
    	}
    }
   function SendFeeToken(address _account, address _destination, uint256 tokens) private {
    	_feeToken.approve(treasury,tokens);
    	_feeToken.transferFrom(_account,_destination,tokens);
   }
    function _transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
    function updateNFTaddress(address newAdd) external{
        nftAddress = newAdd;
        nft = NebulaNFT(nftAddress);
    }
    function changeFeeToken(address FeeTok) external onlyOwner {
    	feeToken = FeeTok;
    	_feeToken = IERC20(feeToken);
    }
    function changeNFTAddress(address NFTAdd) external onlyOwner {
    	nftAddress = NFTAdd;
    	nft = NebulaNFT(nftAddress);
    }
}