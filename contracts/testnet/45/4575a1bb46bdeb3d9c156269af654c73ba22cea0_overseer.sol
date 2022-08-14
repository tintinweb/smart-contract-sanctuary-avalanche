/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-13
*/

// SPDX-License-Identifier: (Unlicense)
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-22
*/
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
// File contracts/TestReserves_1.sol
pragma solidity ^0.8.0;
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function decimals() external view returns (uint8);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
pragma solidity ^0.8.4;
abstract contract Authorizable {
  mapping(address => bool) private _authorizedAddresses;
  constructor() {
    _authorizedAddresses[msg.sender] = true;
  }
  modifier onlyAuthorized() {
    require(_authorizedAddresses[msg.sender], "Not authorized");
    _;
  }
  function setAuthorizedAddress(address _address, bool _value)
    public
    virtual
    onlyAuthorized
  {
    _authorizedAddresses[_address] = _value;
  }
  function isAuthorized(address _address) public view returns (bool) {
    return _authorizedAddresses[_address];
  }
}
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

abstract contract nft_stake is Context {
    uint256 public time = block.timestamp;
    struct Stake_1 {
        uint256 tokenId;
        uint256 amount;
        uint256[] timestamp;
    }
    struct Stake_2 {
        uint256 tokenId;
        uint256 amount;
        uint256[] timestamp;
    }
    struct Stake_3 {
        uint256 tokenId;
        uint256 amount;
        uint256[] timestamp;
    }

    mapping(address => Stake_1) public stakes_1;
    mapping(address => Stake_2) public stakes_2;
    mapping(address => Stake_3) public stakes_3;

    // map staker to total staking time
    mapping(address => uint256[]) public stakingTime_1;
    mapping(address => uint256[]) public stakingTime_2;
    mapping(address => uint256[]) public stakingTime_3;
    function get_stake(address _account) external virtual returns(uint256[3] memory);
    function get_times(address _account,uint256 i,uint256 k) external virtual returns(uint256);
}


pragma solidity ^0.8.4;
contract overseer is
  Ownable,
  Authorizable
{
  using SafeMath for uint;
   struct GREENSamt {
        uint256 amount;
    }
    struct GREENStime {
        uint256 elapsed;
    }
    struct GREENSboost {
        uint256 boost;
    }
    
  
  mapping(address => GREENSamt) public greensamount;
  mapping(address => GREENStime[]) public greenstime;
  mapping(address => GREENSboost[]) public greensboost;
  uint doll_pr = 1;
  uint low_perc = 30;
  uint high_perc = 30;
  uint val = 30;
  //address swap_add = 0x20d0BD6fd12ECf99Fdd2EDD932e9598482F82482;
  //address stable_swap_add = 0x4E47Cd2a94dB858f599A55A534543ddAc30AFeC2;
  //address token_add =  0x6A7B82C844394e575fBE35645A7909DD28405F9a;
  //address main_add = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
  //address stable_add = 0x863ad4F88428151c0Ffa796456E445a978fb2c47;
  address swap_add;
  address stable_swap_add;
  address token_add;
  address main_add;
  address stable_add;
  address public _stake;
  nft_stake NFT_CONT;
  bool stableOn = true;
  uint256[] public boostMultiplier;
  constructor(address[] memory swaps,address[] memory addresses,uint256[] memory _boosts){
	  swap_add = swaps[0];
	  stable_swap_add = swaps[1];
	  token_add = swaps[2];
	  main_add = swaps[3];
	  stable_add = swaps[4];
	  _stake = addresses[0];
	  nft_stake NFT_CONT  = nft_stake(_stake);
	  boostMultiplier = [_boosts[0],_boosts[1],_boosts[2]];
  }
  
  function getStablePrice() public view returns (uint)
   {
    uint[4] memory vals = find_dir(stable_swap_add);
    uint _stable = vals[0].div(10**vals[2]);
    uint _main = vals[1].div(10**vals[3]);
    uint stable_now_val = _stable.div(_main);
    return stable_now_val;
   }

  function getGreensAmount(address _account) internal returns(uint256[3] memory,uint256){
  	uint256[3] memory Data = NFT_CONT.get_stake(_account);
  	uint256 _amount;
  	for(uint i=0;i<Data.length;i++){
  		_amount += Data[i];
  	}
  	return (Data,_amount);
  }
  function getCurrGreens(address _account, uint i, uint k) external returns (uint256,uint256) {
  	uint256 _time = NFT_CONT.get_times(_account,i,k);
  	uint256 _boost = boostMultiplier[i];
  	return (_time,_boost);
  }
  // calculate price based on pair reserves
  function adds(address pair_add, bool tok) public view returns(address) {
      IUniswapV2Pair pair = IUniswapV2Pair(swap_add);
      if (tok) {
         IERC20 swap_token = IERC20(pair.token0());
         return address(swap_token);
      }
      IERC20 swap_token = IERC20(pair.token1());
      return address(swap_token);
      }
  function decs(address pair_add) public view returns(uint8) {
         IERC20 swap_token = IERC20(pair_add);
         uint8 _dec =  swap_token.decimals();
         return _dec;
     }
  function find_dir(address ad) public view returns(uint[4] memory) {
    IUniswapV2Pair pair = IUniswapV2Pair(ad);
    address ad0 = adds(swap_add, true);
    address ad1 = adds(swap_add, false);
    uint dec0 = decs(ad0);
    uint dec1 = decs(ad1);
    (uint res0, uint res1,) = pair.getReserves();
    uint t0 = res0;
    uint t0_dec = dec0;
    uint t1 = res1;
    uint t1_dec = dec1;
    if (main_add == ad0) {
    	t1 = res0;
    	t1_dec = dec0;
    	t0 = res1;
    	t0_dec = dec1;
    }
    return [t0,t1,t0_dec,t1_dec];
   }
  function getTokenPrice() public view returns(uint) {
    uint[4] memory vals = find_dir(swap_add);
    uint _token = vals[0].div(10**vals[2]);
    uint _main = vals[1].div(10**vals[3]);
    uint now_val = _token.div(_main);
    if (stableOn) {
    	uint doll_pr = getStablePrice();
    	_main = _main.mul(doll_pr);
    	now_val = _main.div(_token);
    	}
    uint high_perc_val = val.mul(high_perc).div(100);
    uint low_perc_val = val.mul(low_perc).div(100);
    uint low_val = val.sub(low_perc_val);
    uint high_val = val.add(high_perc_val);
    if (now_val < low_val) {
      return 1;
    }
    if (now_val > high_val) {
      return 2;
    }
    return 0;
    // return amount of token0 needed to buy token1
   }
function getEm() public view returns (uint) {
    	uint res = getTokenPrice();
    	return res;
    }
function updateStableOn(bool newVal) external onlyOwner {
        stableOn = newVal; //turn stable pair on
    }
 function updateStakeAddress(address newVal) external onlyOwner {
          _stake = newVal;
	  nft_stake NFT_CONT  = nft_stake(_stake);
    }
  function updateStableAddress(address newVal) external onlyOwner {
        stable_add = newVal; //true: token0 = stable && token1 = main
    }
  function updateTokenAddress(address newVal) external onlyOwner {
        token_add = newVal; //true: token0 = token && token1 = main
    }
  function updateMainAddress(address newVal) external onlyOwner {
        main_add = newVal; //true: token0 = token && token1 = main
    }
  function updateSwapAddress(address newVal) external onlyOwner {
        swap_add = newVal; //token swap address
    }
  function updateStableSwapAddress(address newVal) external onlyOwner {
        stable_swap_add = newVal; //stable swap address
    }
  function updateVal(uint newVal) external onlyOwner {
        val = newVal; //min amount to swap
    }
  function updateHighPerc(uint newVal) external onlyOwner {
        high_perc = newVal; //high_percentage high_perc.div(100)
    }

  function updateLowPerc(uint newVal) external onlyOwner {
        low_perc = newVal; //low_percentage low_perc.div(100)
    }    
}