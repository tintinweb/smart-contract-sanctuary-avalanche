/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-31
*/

// 𓂀 𝔸𝕧𝕒𝕩 𝕊𝕟𝕠𝕨 ℍ𝕠𝕦𝕤𝕖 𓂀

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size; assembly {
            size := extcodesize(account)
        } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {   
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//libraries
struct User {
    uint256 startDate;
    uint256 divs;
    uint256 refBonus;
    uint256 totalInits;
    uint256 totalWiths;
    uint256 totalAccrued;
    uint256 lastWith;
    uint256 timesCmpd;
    uint256 keyCounter;
    Depo [] depoList;
}
struct Depo {
    uint256 key;
    uint256 depoTime;
    uint256 amt;
    address ref;
    bool initialWithdrawn;
}
struct Main {
    uint256 ovrTotalDeps;
    uint256 ovrTotalWiths;
    uint256 users;
    uint256 compounds;
}
struct DivPercs{
    uint256 daysInSeconds; // updated to be in seconds
    uint256 divsPercentage;
}
struct FeesPercs{
    uint256 daysInSeconds;
    uint256 feePercentage;
}


contract AvaxSnowHouse {
    using SafeMath for uint256;
    uint256 constant launch = 1671177022;  //2022-12-16 16:50:22
  	uint256 constant hardDays = 86400;
    uint256 constant percentdiv = 1000;
    uint256 refPercentage = 100;
    uint256 devPercentage = 100;
    uint256 public  MAX_DAY ;
    uint256 public  MAX_EARNINGS ;
    mapping (address => mapping(uint256 => Depo)) public DeposMap;
    mapping (address => User) public UsersKey;
    mapping (uint256 => DivPercs) public PercsKey;
    mapping (uint256 => FeesPercs) public FeesKey;
    mapping (uint256 => Main) public MainKey;
    using SafeERC20 for IERC20;
    IERC20 public USDC_AVAX_LP; 
    IERC20 public USDC;
    IERC20 public WAVAX;
    address public owner;
    IUniswapV2Router02 public uniswapV2Router;

    event Received(address, uint);
    event Fallback(address, uint);

    constructor() {
        owner = msg.sender;
        MAX_EARNINGS = 36500;
        
        PercsKey[10] = DivPercs(864000, 30);
        PercsKey[20] = DivPercs(1728000, 35);
        PercsKey[30] = DivPercs(2592000, 40);
        PercsKey[40] = DivPercs(3456000, 45);
        PercsKey[50] = DivPercs(4320000, 50);
        PercsKey[60] = DivPercs(5184000, 55);
        PercsKey[70] = DivPercs(6048000, 60);
        PercsKey[80] = DivPercs(6912000, 65);
        PercsKey[90] = DivPercs(7776000, 70);
        PercsKey[100] = DivPercs(8640000, 100);

        FeesKey[10] = FeesPercs(864000, 200);
        FeesKey[20] = FeesPercs(1728000, 190);
        FeesKey[30] = FeesPercs(2592000, 180);
        FeesKey[40] = FeesPercs(3456000, 170);
        FeesKey[50] = FeesPercs(4320000, 160);
        FeesKey[60] = FeesPercs(5184000, 150);
        FeesKey[70] = FeesPercs(6048000, 140);
        FeesKey[80] = FeesPercs(6912000, 130);
        FeesKey[90] = FeesPercs(7776000, 120);
        FeesKey[100] = FeesPercs(8640000, 100);
        MAX_DAY = 90;
         
        

        USDC_AVAX_LP = IERC20(0x4d308C46EA9f234ea515cC51F16fba776451cac8); // 0x4d308C46EA9f234ea515cC51F16fba776451cac8
        USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);  //0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
        WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); //0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
        uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable { 
        emit Fallback(msg.sender, msg.value);
    }

    function stakeStableCoins(uint256 amtx, address ref) public {

        USDC.transferFrom(msg.sender, address(this), amtx);
        
        uint256 half = amtx.div(2);
        uint256 otherHalf = amtx.sub(half);

        // capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap USDC for AVAX
        swapTokensForEth(half, address(this));

        // how much AVAX should we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // capture the contract's current LP balance
        uint256 initialLPBalance = USDC_AVAX_LP.balanceOf(address(this));

        // add liquidity to spookeyswap
        addLiquidity(otherHalf, newBalance);

        // how much LP should we stake
        uint256 newLPBalance = USDC_AVAX_LP.balanceOf(address(this)).sub(initialLPBalance);

        stake(newLPBalance, ref);
    }
    
    function stakeNativeCurrencies(address ref) public payable {
        uint256 half = msg.value.div(2);
        uint256 otherHalf = msg.value.sub(half);
        
        // capture the contract's current USDC balance.
        uint256 initialUSDCBalance = USDC.balanceOf(address(this));

        // swap AVAX for USDC
        swapEthForTokens(half, address(this));
      
        // how much USDC should we just swap into?
        uint256 increasedUSDCBalance = USDC.balanceOf(address(this)).sub(initialUSDCBalance);

        // capture the contract's current LP balance
        uint256 initialLPBalance = USDC_AVAX_LP.balanceOf(address(this));

        // add liquidity to spookeyswap
        addLiquidity(increasedUSDCBalance, otherHalf);

        // how much LP should we stake
        uint256 newLPBalance = USDC_AVAX_LP.balanceOf(address(this)).sub(initialLPBalance);

        stake(newLPBalance, ref);
    }

    function swapEthForTokens(uint256 ethAmount, address _to) internal {
        // generate the uniswap pair path of AVAX -> USDC
        address[] memory path = new address[](2);       
        path[0] = uniswapV2Router.WETH();
        path[1] = address(USDC);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(                
            0,               
            path,
            _to,
            block.timestamp
        );        
    }

    function swapTokensForEth(uint256 tokenAmount, address _to) internal {
        // generate the uniswap pair path of token -> wAVAX
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = uniswapV2Router.WETH();

        USDC.approve(address(uniswapV2Router), tokenAmount);    

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _to,
            block.timestamp
        );        

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios        
        USDC.approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(USDC), 
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function stake(uint256 amtx, address ref) internal {
        require(block.timestamp >= launch, "App did not launch yet.");
        require(ref != msg.sender, "You cannot refer yourself!");
                
        User storage user = UsersKey[msg.sender];
        User storage user2 = UsersKey[ref];
        Main storage main = MainKey[1];
        if (user.lastWith == 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }
        uint256 userStakePercentAdjustment = 1000 - devPercentage;
        uint256 adjustedAmt = amtx.mul(userStakePercentAdjustment).div(percentdiv); 
        uint256 stakeFee = amtx.mul(devPercentage).div(percentdiv); 
        
        user.totalInits += adjustedAmt; 
        uint256 refAmtx = adjustedAmt.mul(refPercentage).div(percentdiv);
        if (ref != address(0)) {
            user2.refBonus += refAmtx;
        }

        user.depoList.push(Depo({
            key: user.depoList.length,
            depoTime: block.timestamp,
            amt: adjustedAmt,
            ref: ref,
            initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.users += 1;
        
        USDC_AVAX_LP.safeTransfer(owner, stakeFee);
    }

    function userInfo() view external returns (Depo [] memory depoList) {
        User storage user = UsersKey[msg.sender];
        return(
            user.depoList
        );
    }

    function withdrawDivs() external returns (uint256 withdrawAmount) {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        uint256 x = calcdiv(msg.sender);
      
      	for (uint i = 0; i < user.depoList.length; i++){
          if (user.depoList[i].initialWithdrawn == false) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        uint256 userWithdrawPercentAdjustment = 1000 - devPercentage;
        uint256 adjustedAmt = x.mul(userWithdrawPercentAdjustment).div(percentdiv); 
        uint256 withdrawFee = x.mul(devPercentage).div(percentdiv);

        main.ovrTotalWiths += x;
        user.lastWith = block.timestamp;

        USDC_AVAX_LP.safeTransfer(msg.sender, adjustedAmt);
        USDC_AVAX_LP.safeTransfer(owner, withdrawFee);

        return x;
    }

    function withdrawInitial(uint256 key) external {
      	  
      	User storage user = UsersKey[msg.sender];
				
      	require(user.depoList[key].initialWithdrawn == false, "This has already been withdrawn.");
      
        uint256 initialAmt = user.depoList[key].amt; 
        uint256 currDays1 = user.depoList[key].depoTime;
        uint256 currTime = block.timestamp;
        uint256 currDays = currTime - currDays1;
        uint256 transferAmt;
      	
        if (currDays < FeesKey[10].daysInSeconds){ // LESS THAN 10 DAYS STAKED
            uint256 minusAmt = initialAmt.mul(FeesKey[10].feePercentage).div(percentdiv); //20% fee
           	
          	uint256 dailyReturn = initialAmt.mul(PercsKey[10].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
          	
          	transferAmt = initialAmt + currentReturn - minusAmt;
          
            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[10].daysInSeconds && currDays < FeesKey[20].daysInSeconds){ // BETWEEN 10 and 20 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[20].feePercentage).div(percentdiv); //19% fee
						
          	uint256 dailyReturn = initialAmt.mul(PercsKey[20].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[20].daysInSeconds && currDays < FeesKey[30].daysInSeconds){ // BETWEEN 20 and 30 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[30].feePercentage).div(percentdiv); //18% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[30].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[30].daysInSeconds && currDays < FeesKey[40].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //17% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[40].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);
          
        } else if (currDays >= FeesKey[40].daysInSeconds && currDays < FeesKey[50].daysInSeconds){ // BETWEEN 40 and 50 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[50].feePercentage).div(percentdiv); //16% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[50].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;

            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[50].daysInSeconds && currDays < FeesKey[60].daysInSeconds){ // BETWEEN 50 and 60 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[60].feePercentage).div(percentdiv); //15% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[60].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);

        } else if (currDays >= FeesKey[60].daysInSeconds && currDays < FeesKey[70].daysInSeconds){ // BETWEEN 60 and 70 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[70].feePercentage).div(percentdiv); //14% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[70].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);
        } else if (currDays >= FeesKey[70].daysInSeconds && currDays < FeesKey[80].daysInSeconds){ // BETWEEN 70 and 80 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[80].feePercentage).div(percentdiv); //13% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[80].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);
        } else if (currDays >= FeesKey[80].daysInSeconds && currDays < FeesKey[90].daysInSeconds){ // BETWEEN 80 and 90 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[90].feePercentage).div(percentdiv); //12% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[90].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);
        } else if (currDays >= FeesKey[90].daysInSeconds){ // 90+ DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[100].feePercentage).div(percentdiv); //10% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[100].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[key].amt = 0;
            user.depoList[key].initialWithdrawn = true;
            user.depoList[key].depoTime = block.timestamp;
            
            USDC_AVAX_LP.safeTransfer(msg.sender, transferAmt);
            USDC_AVAX_LP.safeTransfer(owner, minusAmt);
        } else {
            revert("Could not calculate the # of days you've been staked.");
        }        
    }
    function withdrawRefBonus() external {
        User storage user = UsersKey[msg.sender];
        uint256 amtz = user.refBonus;
        user.refBonus = 0;

        USDC_AVAX_LP.safeTransfer(msg.sender, amtz);
    }

    function stakeRefBonus() external { 
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        require(user.refBonus > 10);
      	uint256 referralAmount = user.refBonus;
        user.refBonus = 0;
        address ref = address(0);
				
        user.depoList.push(Depo({
            key: user.keyCounter,
            depoTime: block.timestamp,
            amt: referralAmount,
            ref: ref, 
            initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
    }

function getMaxPayOutLeft(address adr, uint256 keyy) public view returns(uint256 maxPayout) {
    User storage user = UsersKey[adr];
     user.depoList[keyy].amt ;
     user.depoList[keyy].initialWithdrawn ;
     user.depoList[keyy].depoTime ;
     maxPayout ;
    
    }

    function calcdiv(address dy) public view returns (uint256 totalWithdrawable) {
        User storage user = UsersKey[dy];	

        uint256 with;
        
        for (uint256 i = 0; i < user.depoList.length; i++){	
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);

            uint256 amount = user.depoList[i].amt;
            if (user.depoList[i].initialWithdrawn == false){
                if (elapsedTime <= PercsKey[10].daysInSeconds){ 
                    uint256 dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[50].daysInSeconds && elapsedTime <= PercsKey[60].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[60].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[60].daysInSeconds && elapsedTime <= PercsKey[70].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[70].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[70].daysInSeconds && elapsedTime <= PercsKey[80].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[80].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[80].daysInSeconds && elapsedTime <= PercsKey[90].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[90].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[90].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[100].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(hardDays);
                    with += currentReturn;
                }
                
            } 
        }
        return with;
    }

    function compound() external {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        uint256 y = calcdiv(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
          if (user.depoList[i].initialWithdrawn == false) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        user.depoList.push(Depo({
              key: user.keyCounter,
              depoTime: block.timestamp,
              amt: y,
              ref: address(0), 
              initialWithdrawn: false
          }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.compounds += 1;
        user.lastWith = block.timestamp;  
    }
}