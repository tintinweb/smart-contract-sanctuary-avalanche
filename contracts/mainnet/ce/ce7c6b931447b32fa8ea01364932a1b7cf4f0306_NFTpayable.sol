/**
 *Submitted for verification at snowtrace.io on 2022-08-22
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
// Sources flattened with hardhat v2.3.0 https://hardhat.org
// File @uniswap/v2-core/contracts/interfaces/[email protected]
pragma solidity >=0.5.0;
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
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
abstract contract prevNFTpayable is Context {
    function viewAccountsLength() external virtual returns(uint256);
    function NFTAccountsLength() external virtual returns(uint256);
    function PROTOAccountsLength() external virtual returns(uint256);
    function PROTOStarsLength(address _account) external virtual returns(uint256);
    function PROTOAccountAddress(uint256 _x) external virtual returns(address);
    function NFTAccountAddress(uint256 _x) external virtual returns(address);
    function PROTOLength(uint256 _x) external virtual returns(address);
    function PROTOaccountExists(address _account) external virtual returns (bool);
    function NFTaccountExists(address _account) external virtual returns (bool);
    function NFTaccountData(address _account) external virtual returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool);
    function PROTOaccountData(address _account, uint256 _x) external virtual returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool);
}
interface ITestPayable {
    function payableFunction() payable external;
}



abstract contract overseer is Context {
    function getEm() external virtual returns (uint256);
}
contract NFTpayable is Ownable {
    string public constant name = "NebulaNFTpay";
    string public constant symbol = "NePay";
    using SafeMath for uint256;
    using SafeMath for uint;
    struct TOTALS {
    	    uint256 tier_1;
    	    uint256 tier_2;
    	    uint256 tier_3;
    	    uint256 total;
    	    uint256 totalUSD;
    	    uint256 totalAVAX;
    	    uint256 totalfees;
    	    bool full;
    	   }
    struct PROTOstars {
    	    string name;
    	    uint256 nextDue;
    	    uint256 feeFroze;
    	    uint256 futureFees;
    	    uint256 creationTime;
    	    uint256 protoElapsed;
    	    uint256 collapseDate;
    	    bool insolvent;
    	    bool owed;
    	    
    }
    struct FEES{
	uint256 feesOwed;
	uint256 feesPaid; 
	uint256 futureFees;
	uint256 total;
	uint256 FeesAdded;  
    }
    struct DEADStars {
    	    string name;
	    uint256 nextDue;
    	    uint256 feeFroze;
    	    uint256 futureFees;
    	    uint256 creationTime;
    	    uint256 protoElapsed;
    	    uint256 collapseDate;
    	    bool insolvent;
    	    bool collapsed;
    	}
    mapping(address => TOTALS) public totals;
    mapping(address => PROTOstars[]) public protostars;
    mapping(address => DEADStars[]) public deadstars;
    mapping(address => FEES) public accountFees;

    address[] public NFTaccounts;
    address[] public PROTOaccounts;
    address[] public NFTtransfered;
    address[] public PROTOtransfered;
    address[] public Managers;
    uint256 public Zero = 0;
    uint256 public one = 1;
    uint256 public limit1 = 10;
    uint256 public limit2 = 10;
    uint256 public limit3 = 10;
    uint public cost1;
    uint public cost2;
    uint public cost3;
    uint256 public gas = 1*(10**17);
    uint[3] public maxSupplies = [3000,2000,1000];
    uint[3] public nft_cost;
    uint256 public feePeriod = 31 days;
    uint256 public gracePeriod = 5 days;
    uint256 public protoLife = 500 days;
    uint256 public maxFeePayment = 365 days;
    uint256 public feeOn;
    uint256 public feeOff;
    address Guard;
    bool public fees = false;
    NebulaNFT public nft;
    overseer public _overseer;
    address public overseer_;
    address public nftAddress;
    address payable public treasury;
    address public swap_add;
    address public main_add;
    address public stable_add;
    modifier onlyManager(address sender) {require(isInList(sender, Managers)== true); _;}
    modifier onlyGuard() {require(owner() == _msgSender() || Guard == _msgSender(), "NOT_GUARD");_;}
    

    constructor(address[] memory swaps,address payable _treasury) payable {
    	overseer_ = swaps[0];
    	_overseer = overseer(overseer_);
	nftAddress = swaps[1];
	treasury = _treasury;
	nft = NebulaNFT(nftAddress);
	Managers.push(owner());
	cost1 = 30;
	cost2 = 7;
	cost3 = 15;
	nft_cost = [cost1,cost2,cost3];
    }
    
    function createProto(address _account, string memory _name) external {
    	PROTOstars[] storage protos = protostars[_account];
    	uint256 froze = Zero;
    	if (fees == true) {
    	    	froze = block.timestamp;
    	    }
    	protos.push(PROTOstars({
    	    name:_name,
    	    nextDue:block.timestamp,
    	    feeFroze:Zero,
    	    futureFees:12,
    	    creationTime:block.timestamp,
    	    protoElapsed:Zero,
    	    collapseDate:block.timestamp.add(protoLife),
    	    insolvent:true,
    	    owed:true
    	    }));
    	  }
    function collapseProto(address _account, uint256 _x) internal {
    	PROTOstars[] storage protos = protostars[_account];
    	PROTOstars storage proto = protos[_x];
    	DEADStars[] storage stars = deadstars[_account];
    	stars.push(DEADStars({
    	    name:proto.name,
	    nextDue:proto.nextDue,
    	    feeFroze:proto.feeFroze,
    	    futureFees:proto.futureFees,
    	    creationTime:proto.creationTime,
    	    protoElapsed:proto.protoElapsed,
    	    collapseDate:block.timestamp,
    	    insolvent:proto.insolvent,
    	    collapsed:true

    	    }));
    	}
    function queryFees(address _account) internal returns (uint256) {
    	FEES storage owed = accountFees[_account];
    	owed.feesOwed = 0;
    	owed.futureFees = 0;
    	PROTOstars[] storage protos = protostars[_account];
    	for(uint i = 0;i<protos.length;i++) {
    		PROTOstars storage proto = protos[i];
    		uint256 remainingLife = proto.collapseDate - block.timestamp;
    		uint256 currMax = maxFeePayment - (proto.nextDue - block.timestamp);
    		uint256 futMax = currMax.div(feePeriod);
    		uint256 futLifeMax = remainingLife.div(feePeriod);
    		if (proto.nextDue - block.timestamp < feePeriod){
    			owed.feesOwed += 1;
    			proto.owed = true;
    			
    		}else{
    			proto.owed = false;
    		}if(futMax > futLifeMax){
	    		owed.futureFees += futLifeMax;
	    		proto.futureFees = futLifeMax;
	    	}else{
	    		owed.futureFees += futMax;
	    		proto.futureFees = futMax;
	    	}
	    }
	owed.total = owed.futureFees + owed.feesOwed+owed.FeesAdded;
    }
        function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
   	uint256 xx = x.div((10000)/(y*100));
    	return xx;
    }
    function payFee(uint256 _intervals) payable external returns (bool) {
        address _account = msg.sender;
        require(_intervals > 0,"if you want to pay nothing just make a query for the fees");
        queryFees(_account);
        FEES storage owed = accountFees[_account];
        require(owed.total > 0, "you dont owe any fees");
        uint256 avaxPrice = _overseer.getEm();
    	uint256 fee = uint256(15*(10**18)).div((10000)/(avaxPrice*(10**18))*100);
    	uint256 balance = getBalanceOf(_account);
    	require(balance >= fee,"you do not have enough AVAX to pay the fee");
    	require(balance.div(fee) >= _intervals,"youre trying to pay more than your ballance allows");
        require(msg.value >= fee,"Amount should be equal the fee");
        _transfer(treasury, fee);
        recPayFees(_account);
        return true;
    }
    function recPayFees(address _account) internal {
        uint256 _intervals = 1;
        FEES storage owed = accountFees[_account];
	PROTOstars[] storage protos = protostars[_account];
	for(uint i=0;i<protos.length;i++){
		PROTOstars storage proto = protos[i];
		if(owed.feesOwed > 0 && _intervals >0){
			if (owed.feesOwed > 0){
				proto.owed = false;
				owed.feesOwed -=1;
				_intervals -= 1;
			}
		}
	}
	for(uint i=0;i<protos.length;i++){
	PROTOstars storage proto = protos[i];
		if(proto.futureFees > 0 && _intervals >0){
			if (proto.futureFees > 0){
				proto.futureFees -=1;
				_intervals -= 1;
				owed.futureFees -=1;
			}
		}
	}
	owed.total = owed.futureFees + owed.feesOwed;
    }   		
    	
    function updateTotals(address _account, uint256 _id,uint256 _amount) internal{
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
	if (fees !=false){
		queryFees(_account);
	}
    	if ((tot.tier_1).add(tot.tier_2).add(tot.tier_3) >= 10){
    		tot.full = true;
    	}
    }
    // Payable constructor can receive Ether

   function queryERC20Balance(address _account,address _token) internal view returns (uint) {
        return IERC20(_token).balanceOf(_account);
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

    function mint(uint256 _id,address _account) payable external {
    	uint256 avaxPrice = _overseer.getEm();
    	uint256 num = _id - 1;
    	uint256 _amount = nft_cost[num].div(avaxPrice);
    	require(msg.value >= _amount,"you do not have enough to purchase this NFT");
        if (isInList(_account,NFTaccounts) == false){
    		NFTaccounts.push(_account);
    	}
    	TOTALS storage tot = totals[_account];
    	require(tot.full != true,"sorry, you already have too many NFT's");
    	checkFull(num);
    	if (_id == 1){
	    nft.Pmint(_account,1,1,"0x0");
    	}else if (_id == 2){
	    nft.Pmint(_account,2,1,"0x0");
    	}else if (_id == 3){
	    nft.Pmint(_account,3,1,"0x0");
    	}

    	updateTotals(_account,_id,_amount);
    	_transfer(treasury,msg.value);
    }
    function MGRmint(uint256[] memory _id_,address[] memory _account_) external onlyManager(msg.sender) {
    	for(uint i=0;i<_id_.length;i++){
    		uint256 _id = _id_[i];
    		address _account = _account_[i];
	    	uint256 num = _id - 1;
		if (isInList(_account,NFTaccounts) == false){
	    		NFTaccounts.push(_account);
	    	}
	    	TOTALS storage tot = totals[_account];
	    	if (tot.full != true) {
		    	checkFull(num);
		    	if (_id == 1){
			    nft.Pmint(_account,1,1,"0x0");
		    	}else if (_id == 2){
			    nft.Pmint(_account,2,1,"0x0");
		    	}else if (_id == 3){
			    nft.Pmint(_account,3,1,"0x0");
		    	}
		    	updateTotals(_account,_id,1);
		}
	    }
    }
    function transferAllNFTdata(address prev) external onlyManager(msg.sender) {
    		prevNFTpayable _prev = prevNFTpayable(prev);
    	    	uint256 accts = _prev.NFTAccountsLength();
    	    	for(uint i=0;i<accts;i++){
    	    		address _account = _prev.NFTAccountAddress(i);
    	    		if(isInList(_account,PROTOtransfered) == false){
	    	    		TOTALS storage tots = totals[_account];
	    	    		(uint256 a,uint256 b,uint256 c,uint256 d,uint256 e,uint256 f,uint256 g,bool h)= _prev.NFTaccountData(_account);
	    	    		tots.tier_1 = a;
	    	    		tots.tier_2 = b;
	    	    		tots.tier_3 = c;
	    	    		tots.total =d;
	    	    		tots.totalUSD = e;
	    	    		tots.totalAVAX = f;
	    	    		tots.totalfees = g;
	    	    		tots.full = h;
	    			NFTtransfered.push(_account);
	    		}
	    	}
    }
    function transferAllProtoData(address prev) external onlyManager(msg.sender) {
    		prevNFTpayable _prev = prevNFTpayable(prev);
    		uint256 accts = _prev.PROTOAccountsLength();
    	    	for(uint i=0;i<accts;i++){
    	    		address _account = _prev.PROTOAccountAddress(i);
    	    		if(isInList(_account,PROTOtransfered) == false){
	    	    		PROTOstars[] storage stars = protostars[_account];
	    	    		uint256 P_stars = _prev.PROTOStarsLength(_account);
	    	    		for(uint j=0;j<P_stars;j++){
		    	    		(string memory a,uint256 b,uint256 c,uint256 d,uint256 e,uint256 f, uint256 g,bool h,bool i) = _prev.PROTOaccountData(_account,j);
			    	    		stars.push(PROTOstars({
			    	    		    name:a,
			    	    		    nextDue:b,
					    	    feeFroze:c,
					    	    futureFees:d,
					    	    creationTime:e,
					    	    protoElapsed:f,
					    	    collapseDate:g,
					    	    insolvent:h,
					    	    owed:i
					    	    }));
			    			PROTOtransfered.push(_account);
		    		}
	    		}
	    	}
    }
    function mgrTest(address payable _to, uint256 _amount) payable external onlyManager(msg.sender) {
    	_transfer(_to, _amount);
    }
    function _transfer(address payable _to, uint _amount) internal {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
    function _transfer_(address payable _to, uint _amount) payable external onlyManager(msg.sender) {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function changeNFTAddress(address NFTAdd) external onlyManager(msg.sender) {
    	nftAddress = NFTAdd;
    	nft = NebulaNFT(nftAddress);
    }
    function NFTaccountData(address _account) external onlyGuard onlyManager(msg.sender) returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool){
    		TOTALS storage tot = totals[_account];
    		return (tot.tier_1,tot.tier_2,tot.tier_3,tot.total,tot.totalUSD,tot.totalAVAX,tot.totalfees,tot.full);
    	}
    function PROTOaccountData(address _account, uint256 _x) external onlyGuard onlyManager(msg.sender) returns(string memory,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool){
    		PROTOstars[] storage stars = protostars[_account];
    		PROTOstars storage star = stars[_x];
    		return (star.name,star.nextDue,star.feeFroze,star.futureFees,star.creationTime,star.protoElapsed,star.collapseDate,star.insolvent,star.owed);
    	}
   function PROTOaccountExists(address _account) external returns (bool) {
    	return isInList(_account,PROTOaccounts);
    }
   function NFTaccountExists(address _account) external returns (bool) {
    	return isInList(_account,NFTaccounts);
    }
    function PROTOAccountsLength() external view returns(uint256){
    	return PROTOaccounts.length;
    }
    function NFTAccountsLength() external view returns(uint256){
    	return NFTaccounts.length;
    }
    function NFTAddress(uint256 _x) external view returns(address){
    	return NFTaccounts[_x];
    }
    function viewFees(address _account) public view returns(uint256,uint256,uint256){
    	FEES storage owed = accountFees[_account];
    	uint256 owe = owed.feesOwed;
    	uint256 pay = owed.feesPaid;
    	uint256 future = owed.futureFees;
    	return (owe,pay,future);
    }
    function addFees(address _account,uint256 _amount) external onlyOwner{
    	FEES storage owed = accountFees[_account];
    	uint256 FeesAdded = _amount;
    }
    function PROTOAddress(uint256 _x) external view returns(address){
    	return PROTOaccounts[_x];
    }
    function PROTOStarsLength(address _account) external view returns(uint256){
    	PROTOstars[] storage stars = protostars[_account];
    	return stars.length;
    }
    function getBalanceOf(address _account) public view returns (uint256) {
        return _account.balance;
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function updateStableAddress(address newVal) external onlyOwner {
        stable_add = newVal; //true: token0 = stable && token1 = main
    }
    function updateMainAddress(address newVal) external onlyOwner {
        main_add = newVal; //true: token0 = token && token1 = main
    }
    function updateSwapAddress(address newVal) external onlyOwner {
        swap_add = newVal; //token swap address
    }
    function updateGuard(address newVal) external onlyOwner {
        Guard = newVal; //token swap address
    }
    function updateManagers(address newVal) external onlyOwner {
    	if(isInList(newVal,Managers) ==false){
        	Managers.push(newVal); //token swap address
        }
    }
    function changeCostNfts(uint256[3] memory _costs) external onlyOwner{
    	cost1 = _costs[0];
    	cost2 = _costs[1];
    	cost3 = _costs[2];
    	nft_cost = [cost1,cost2,cost3];
    }
    function pauseFees(bool _x) external onlyOwner {
    	fees = _x;
    	if (fees == true){
    		feeOn = block.timestamp;
    		for(uint j = 0;j<PROTOaccounts.length;j++){
    			PROTOstars[] storage protos = protostars[PROTOaccounts[j]];
    			for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    				proto.nextDue = proto.feeFroze + block.timestamp;
    			}
    		}
    	}
    	else{
    		feeOff = block.timestamp;
    		for(uint j = 0;j<PROTOaccounts.length;j++){
    			PROTOstars[] storage protos = protostars[PROTOaccounts[j]];
    			for(uint i = 0;i<protos.length;i++) {
    			PROTOstars storage proto = protos[i];
    				proto.feeFroze = proto.nextDue -block.timestamp;
    			}
    		}
    	} 
    }
    function changeGracePeriod(uint256 _days) external onlyOwner {
    	gracePeriod = _days * 1 days;
    }
    function changeProtoLife(uint256 _days) external onlyOwner {
    	protoLife = _days * 1 days;
    }
}