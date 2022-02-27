/**
 *Submitted for verification at snowtrace.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT
   

                                                                                                         
                                                                                                         
//      WWWWWWWW                           WWWWWWWWWWWWWWWW                           WWWWWWWW 333333333333333   
//      W::::::W                           W::::::WW::::::W                           W::::::W3:::::::::::::::33 
//      W::::::W                           W::::::WW::::::W                           W::::::W3::::::33333::::::3
//      W::::::W                           W::::::WW::::::W                           W::::::W3333333     3:::::3
//       W:::::W           WWWWW           W:::::W  W:::::W           WWWWW           W:::::W             3:::::3
//        W:::::W         W:::::W         W:::::W    W:::::W         W:::::W         W:::::W              3:::::3
//         W:::::W       W:::::::W       W:::::W      W:::::W       W:::::::W       W:::::W       33333333:::::3 
//          W:::::W     W:::::::::W     W:::::W        W:::::W     W:::::::::W     W:::::W        3:::::::::::3  
//           W:::::W   W:::::W:::::W   W:::::W          W:::::W   W:::::W:::::W   W:::::W         33333333:::::3 
//            W:::::W W:::::W W:::::W W:::::W            W:::::W W:::::W W:::::W W:::::W                  3:::::3
//             W:::::W:::::W   W:::::W:::::W              W:::::W:::::W   W:::::W:::::W                   3:::::3
//              W:::::::::W     W:::::::::W                W:::::::::W     W:::::::::W                    3:::::3
//               W:::::::W       W:::::::W                  W:::::::W       W:::::::W         3333333     3:::::3
//                W:::::W         W:::::W                    W:::::W         W:::::W          3::::::33333::::::3
//                 W:::W           W:::W                      W:::W           W:::W           3:::::::::::::::33 
//                  WWW             WWW                        WWW             WWW             333333333333333   
                                                                                                         
                                                                                                         
                                                                                                         
//Twitter: https://twitter.com/WW3_Token

//Website: https://WW3Token.info

//Telegram: https://t.me/WW3Portal

//Discord:  https://discord.com/invite/ZyVSNqZyqX                                                                                                        
                                                                                                         
                                                                                                         
                                                                                                         


pragma solidity ^0.8.9;

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

interface IERC20Metadata is IERC20 {
 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender() || owner() == tx.origin, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
   
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IJoeRouter01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Token is ERC20, Ownable, Pausable {

    // CONFIG START
    uint256 public initialSupply;
   
    uint256 public denominator = 100;

    uint256 public swapThreshold = 1 ether; 
    
    uint256 public devTaxBuy;
    uint256 public marketingTaxBuy;
    uint256 public liquidityTaxBuy;
    uint256 public charityTaxBuy;
    uint256 public multiple = 1e18;

    bool public isBuyBack = true;


    uint256 public maxWalletAmount;
    bool public maxWalletAmountLimited = true;
    mapping (address => bool) public excludedMaxWalletAmount;

    uint256 public maxTxAmount;
    bool public maxTxAmountLimited = true;
    mapping (address => bool) public excludedMaxTxAmount;

    mapping (address => bool) public isPair;

    uint256 public devTaxSell;
    uint256 public marketingTaxSell;
    uint256 public liquidityTaxSell;
    uint256 public charityTaxSell;
    
    mapping (address => bool) public blacklist;
    mapping (address => bool) public excludeList;
    
    mapping (string => uint256) public buyTaxes;
    mapping (string => uint256) public sellTaxes;
    mapping (string => address) public taxWallets;
    
    bool public taxStatus = true;
    
    IJoeRouter02 public uniswapV2Router02;
    IJoeFactory public uniswapV2Factory;
    IJoePair public uniswapV2Pair;
    
    constructor() ERC20("WorldWar3","WW3", 18) payable
    {

        address owner = 0xdd184B7986029ab957aA1C55B4574a3F994ff986;
        _setOwner(msg.sender);
        initialSupply = 1000000000 * 10 ** decimals();
        maxWalletAmount = initialSupply / 100;
        maxTxAmount = initialSupply / 100;
        
        uniswapV2Router02 = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        uniswapV2Factory = IJoeFactory(uniswapV2Router02.factory());
        uniswapV2Pair = IJoePair(uniswapV2Factory.createPair(address(this), uniswapV2Router02.WAVAX()));
        setBuyTax(10, 0, 5, 0);
        setSellTax(10, 0, 5, 0);
        setTaxWallets(owner, owner, owner, owner);
        exclude(owner);
        exclude(address(this));
        excludedMaxWalletAmount[address(this)] = true;
        excludedMaxTxAmount[address(this)] = true;

        // liquidity wallet exclusion
        excludedMaxWalletAmount[owner] = true;
        excludedMaxTxAmount[owner] = true;

        // pair exclusion
        excludedMaxWalletAmount[address(uniswapV2Pair)] = true;
        excludedMaxTxAmount[address(uniswapV2Pair)] = true;
        isPair[address(uniswapV2Pair)] = true;

        _mint(owner, initialSupply);
        _setOwner(owner);
    }
    
    uint256 private marketingTokens;
    uint256 private devTokens;
    uint256 private liquidityTokens;
    uint256 private charityTokens;
    
    /**
     * @dev Calculates the tax, transfer it to the contract. If the user is selling, and the swap threshold is met, it executes the tax.
     */
    function handleTax(address from, address to, uint256 amount) private returns (uint256) {
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = uniswapV2Router02.WAVAX();
        
        if(!isExcluded(from) && !isExcluded(to)) {
            uint256 tax;
            uint256 baseUnit = amount / denominator;
            if(isPair[from]) {
                tax += baseUnit * buyTaxes["marketing"];
                tax += baseUnit * buyTaxes["dev"];
                tax += baseUnit * buyTaxes["liquidity"];
                tax += baseUnit * buyTaxes["charity"];
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                marketingTokens += baseUnit * buyTaxes["marketing"];
                devTokens += baseUnit * buyTaxes["dev"];
                liquidityTokens += baseUnit * buyTaxes["liquidity"];
                charityTokens += baseUnit * buyTaxes["charity"];
            } else if(isPair[to]) {

                tax += baseUnit * sellTaxes["marketing"];
                tax += baseUnit * sellTaxes["dev"];
                tax += baseUnit * sellTaxes["liquidity"];
                tax += baseUnit * sellTaxes["charity"];
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                marketingTokens += baseUnit * sellTaxes["marketing"];
                devTokens += baseUnit * sellTaxes["dev"];
                liquidityTokens += baseUnit * sellTaxes["liquidity"];
                charityTokens += baseUnit * sellTaxes["charity"];
                
                uint256 taxSum = marketingTokens + devTokens + liquidityTokens + charityTokens;
                
                if(taxSum == 0) return amount;
                
                uint256 ethValue = uniswapV2Router02.getAmountsOut(marketingTokens + devTokens + liquidityTokens + charityTokens, sellPath)[1];
                
                if(ethValue >= swapThreshold && isBuyBack) {
                    uint256 startBalance = address(this).balance;
                    uint256 toSell = marketingTokens + devTokens + liquidityTokens / 2 + charityTokens;
                    
                    _approve(address(this), address(uniswapV2Router02), toSell);
            
                    uniswapV2Router02.swapExactTokensForAVAX(
                        toSell,
                        0,
                        sellPath,
                        address(this),
                        block.timestamp
                    );
                    
                    uint256 ethGained = address(this).balance - startBalance;
                    
                    uint256 liquidityToken = liquidityTokens / 2;
                    uint256 liquidityETH = (ethGained * ((liquidityTokens / 2 * multiple) / taxSum)) / multiple;
                    
                    uint256 marketingETH = (ethGained * ((marketingTokens * multiple) / taxSum)) / multiple;
                    uint256 devETH = (ethGained * ((devTokens * multiple) / taxSum)) / multiple;
                    uint256 charityETH = (ethGained * ((charityTokens * multiple) / taxSum)) / multiple;
                    
                    _approve(address(this), address(uniswapV2Router02), liquidityToken);
                    
                    (uint amountToken,,) = uniswapV2Router02.addLiquidityAVAX{value: liquidityETH}(
                        address(this),
                        liquidityToken,
                        0,
                        0,
                        taxWallets["liquidity"],
                        block.timestamp
                    );
                    
                    uint256 remainingTokens = (marketingTokens + devTokens + liquidityTokens + charityTokens) - (toSell + amountToken);
                    
                    if(remainingTokens > 0) {
                        _transfer(address(this), taxWallets["dev"], remainingTokens);
                    }
                    
                    (bool successMarketing,) = taxWallets["marketing"].call{value: marketingETH}("");
                    (bool successDev,) = taxWallets["dev"].call{value: devETH}("");
                    (bool successCharity,) = taxWallets["charity"].call{value: charityETH}("");
                    require(successMarketing && successDev && successCharity, "handleTax: transfer 1 error.");
                    
                    if(ethGained - (marketingETH + devETH + liquidityETH + charityETH) > 0) {
                        (bool successMarketing2,) = taxWallets["marketing"].call{value: ethGained - (marketingETH + devETH + liquidityETH + charityETH)}("");
                        require(successMarketing2, "handleTax: transfer 2 error.");
                    }
                    
                    marketingTokens = 0;
                    devTokens = 0;
                    liquidityTokens = 0;
                    charityTokens = 0;
                }
                
            }
            
            amount -= tax;
        }
        
        return amount;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        require(!paused(), "CoinToken: token transfer while paused");
        require(!isBlacklisted(msg.sender), "CoinToken: sender blacklisted");
        require(!isBlacklisted(recipient), "CoinToken: recipient blacklisted");
        require(!isBlacklisted(tx.origin), "CoinToken: sender blacklisted");
        require(!maxWalletAmountLimited || (excludedMaxWalletAmount[recipient] || amount + balanceOf(recipient) <= maxWalletAmount), "CoinToken: amount and balance will be higher than max wallet for recipient.");
        require(!maxTxAmountLimited || (excludedMaxTxAmount[sender] || amount  <= maxTxAmount), "CoinToken: amount higher than max tx allowed for sender.");

        if(taxStatus) {
            amount = handleTax(sender, recipient, amount);   
        }
        
        super._transfer(sender, recipient, amount);
    }
    
    /**
     * @dev Triggers the tax handling functionality
     */
    function triggerTax() external onlyOwner {
        handleTax(address(0), address(uniswapV2Pair), 0);
    }
    
    /**
     * @dev Pauses transfers on the token.
     */
    function pause() external onlyOwner {
        require(!paused(), "CoinToken: Contract is already paused");
        _pause();
    }

    /**
     * @dev Unpauses transfers on the token.
     */
    function unpause() external onlyOwner {
        require(paused(), "CoinToken: Contract is not paused");
        _unpause();
    }
    
    /**
     * @dev Burns tokens from caller address.
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(_msgSender(), amount);
    }
    
    /**
     * @dev Blacklists the specified account (Disables transfers to and from the account).
     */
    function enableBlacklist(address account) public onlyOwner {
        require(!blacklist[account], "CoinToken: Account is already blacklisted");
        blacklist[account] = true;
    }
    
    /**
     * @dev Remove the specified account from the blacklist.
     */
    function disableBlacklist(address account) public onlyOwner {
        require(blacklist[account], "CoinToken: Account is not blacklisted");
        blacklist[account] = false;
    }
    
    /**
     * @dev Excludes the specified account from tax.
     */
    function exclude(address account) public onlyOwner {
        require(!isExcluded(account), "CoinToken: Account is already excluded");
        excludeList[account] = true;
    }
    
    /**
     * @dev Re-enables tax on the specified account.
     */
    function removeExclude(address account) public onlyOwner {
        require(isExcluded(account), "CoinToken: Account is not excluded");
        excludeList[account] = false;
    }
    
    /**
     * @dev Sets tax for buys.
     */
    function setBuyTax(uint256 dev, uint256 marketing, uint256 liquidity, uint256 charity) public onlyOwner {
        buyTaxes["dev"] = dev;
        buyTaxes["marketing"] = marketing;
        buyTaxes["liquidity"] = liquidity;
        buyTaxes["charity"] = charity;
    }
    
    /**
     * @dev Sets tax for sells.
     */
    function setSellTax(uint256 dev, uint256 marketing, uint256 liquidity, uint256 charity) public onlyOwner {

        sellTaxes["dev"] = dev;
        sellTaxes["marketing"] = marketing;
        sellTaxes["liquidity"] = liquidity;
        sellTaxes["charity"] = charity;
    }
    
    /**
     * @dev Sets wallets for taxes.
     */
    function setTaxWallets(address dev, address marketing, address liquidity, address charity) public onlyOwner {
        taxWallets["dev"] = dev;
        taxWallets["marketing"] = marketing;
        taxWallets["liquidity"] = liquidity;
        taxWallets["charity"] = charity;
    }
    
    /**
     * @dev Enables tax globally.
     */
    function enableTax() external onlyOwner {
        require(!taxStatus, "CoinToken: Tax is already enabled");
        taxStatus = true;
    }
    
    /**
     * @dev Disables tax globally.
     */
    function disableTax() external onlyOwner {
        require(taxStatus, "CoinToken: Tax is already disabled");
        taxStatus = false;
    }
    
    /**
     * @dev Returns true if the account is blacklisted, and false otherwise.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
    
    /**
     * @dev Returns true if the account is excluded, and false otherwise.
     */
    function isExcluded(address account) public view returns (bool) {
        return excludeList[account];
    }

    function setSwapThreshold( uint256 _swapThreshold) external onlyOwner {
        swapThreshold = _swapThreshold;
    }

    function setDenominator( uint256 _denominator) external onlyOwner {
        denominator = _denominator;
    }

    function setMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
        maxWalletAmount = _maxWalletAmount;
    }

    function setMaxWalletAmountLimited(bool _maxWalletAmountLimited) external onlyOwner {
        maxWalletAmountLimited = _maxWalletAmountLimited;
    }

    function excludeMaxWalletAmount(address _address, bool _shouldExclude) external onlyOwner {
        excludedMaxWalletAmount[_address] = _shouldExclude;
    }

     function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }
     
    function setMaxTxAmountLimited(bool _maxTxAmountLimited) external onlyOwner {
        maxTxAmountLimited = _maxTxAmountLimited;
    }

    function excludeMaxTxAmount(address _address, bool _shouldExclude) external onlyOwner {
        excludedMaxTxAmount[_address] = _shouldExclude;
    }

    function setPair(address _address, bool _isPair) external onlyOwner {
        isPair[_address] = _isPair;
    }

    function setMultiple(uint256 _multiple) external onlyOwner {
        multiple = _multiple;
    }

    function setIsBuyBack(bool _isBuyBack) external onlyOwner {
        isBuyBack = _isBuyBack;
    }



    

    function withdraw(uint256 _ethAmount, bool _withdrawAll) external onlyOwner returns(bool){
        uint256 ethBalance = address(this).balance;
        uint256 ethAmount;
        if(_withdrawAll){
            ethAmount = ethBalance;
        } else {
            ethAmount = _ethAmount;
        }
        require(ethAmount <= ethBalance, "withdraw: eth balance must be larger than amount.");
        (bool success,) = payable(_msgSender()).call{value: ethAmount}(new bytes(0));
        require(success, "withdraw: transfer error.");
        return true;
    }

    function ERC20Withdraw(address _tokenAddress, uint256 _tokenAmount, bool _withdrawAll) external onlyOwner returns(bool){
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 tokenAmount;
        if(_withdrawAll){
            tokenAmount = tokenBalance;
        } else {
            tokenAmount = _tokenAmount;
        }
        require(_tokenAmount <= tokenBalance, "ERC20withdraw: token balance must be larger than amount.");
        token.transfer(_msgSender(), tokenAmount);
        return true;
    }

    receive() external payable {}

}