/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-31
*/

// File: contracts/interfaces/IVaultDistributor.sol

// File: contracts/interfaces/IVaultDistributor.sol


pragma solidity = 0.8.11;

interface IVaultDistributor {
  function setShare(address shareholder, uint256 amount) external;

  function deposit() external payable;

  function setMinDistribution(uint256 _minDistribution) external;
}

// File: contracts/interfaces/IBEP20.sol


// File: contracts/interfaces/IBEP20.sol


pragma solidity = 0.8.11;

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IETHSToken.sol




// File: contracts/interfaces/IETHSToken.sol

pragma solidity = 0.8.11;

interface IETHSToken is IBEP20 {
    function nodeMintTransfer(address sender, uint256 amount) external;

    function depositAll(address sender, uint256 amount) external;

    function nodeClaimTransfer(address recipient, uint256 amount) external;

    function vaultDepositNoFees(address sender, uint256 amount) external;

    function vaultCompoundFromNode(address sender, uint256 amount) external;

    function setInSwap(bool _inSwap) external;
}

// File: contracts/interfaces/IDEXRouter.sol

// File: contracts/interfaces/IDEXRouter.sol


pragma solidity = 0.8.11;

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/VaultDistributor.sol

// File: contracts/VaultDistributor.sol
// SPDX-License-Identifier: MIT

pragma solidity = 0.8.11;



contract VaultDistributor is IVaultDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded; // excluded dividend
        uint256 totalRealised;
        uint256 excludedAtUpdates; // Every time someone deposits or withdraws, this number is recalculated.
    }                              // It is used as a base for each new deposit to cancel out the current dividend 
                                   // per share since the dividendPerShare value is always increasing. Every withdraw
                                   // will reduce this number by the same amount it was previously incremented.
                                   // Deposits are impacted by the current dividends per share.
                                   // Withdraws are impacted by past dividends per share, stored in shareholderDeposits.

    IETHSToken eths;          
    IBEP20 WETH = IBEP20(0x32e5539Eb6122A5e32eE8F8D62b185BCc3c41483);
    address WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    IDEXRouter router;

    uint256 numShareholders;

    struct Deposit {
        uint256 amount;
        uint256 dividendPerShareSnapshot;
    }

    mapping(address => Deposit[]) shareholderDeposits; 
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed; // to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**18;

    uint256 public minDistribution = 5 * (10**18);

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address _eths) {
        _token = msg.sender;
        router = IDEXRouter(_router);
        eths = IETHSToken(_eths);
    }

    // amount and shareholder.amount are equal the only difference will create when there is deposit/ withdrawn...
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount >= minDistribution && shares[shareholder].amount < minDistribution) {
            numShareholders++;
        } else if (amount < minDistribution && shares[shareholder].amount >= minDistribution) {
            numShareholders--;
        }
        if(amount >= minDistribution || shares[shareholder].amount >= minDistribution) {
            totalShares = totalShares - shares[shareholder].amount + amount;
            // deposit
            if(amount > shares[shareholder].amount) { // amount = shareholderAmount + newdeposit
                uint256 amountDeposited = amount - shares[shareholder].amount;
                uint256 unpaid = getUnpaidEarnings(shareholder); // get unpaid data, calculate excludedAtUpdates, then calculate totalExcluded
                shares[shareholder].excludedAtUpdates += (dividendsPerShare * amountDeposited) / dividendsPerShareAccuracyFactor; // calc changes
                shares[shareholder].amount = amount;
                shares[shareholder].totalExcluded = getCumulativeDividends(shareholder) - unpaid; // carry unpaid over

                shareholderDeposits[shareholder].push(Deposit({
                    amount: amountDeposited,
                    dividendPerShareSnapshot: dividendsPerShare
                }));
            }
            // withdraw
            else if(amount < shares[shareholder].amount) { // shareholder.amount = withdrawnAmount + amount, means some amount has withdrawn
                uint256 unpaid = getUnpaidEarnings(shareholder); // get unpaid data, calculate excludedAtUpdates, then calculate totalExcluded
                uint256 sharesLost = shares[shareholder].amount - amount;
                uint256 len = shareholderDeposits[shareholder].length - 1;

                for(uint256 i = len; i >= 0; i--) { // calculate changes
                    uint256 depositShares = shareholderDeposits[shareholder][i].amount;
                    uint256 snapshot = shareholderDeposits[shareholder][i].dividendPerShareSnapshot;
                    if(depositShares <= sharesLost) {
                        shares[shareholder].excludedAtUpdates -= (depositShares * snapshot) / dividendsPerShareAccuracyFactor;
                        sharesLost -= depositShares;
                        shareholderDeposits[shareholder].pop();
                        if(sharesLost == 0) {
                            break;
                        }
                    } else {
                        shareholderDeposits[shareholder][i].amount = depositShares - sharesLost;
                        shares[shareholder].excludedAtUpdates -= (sharesLost * snapshot) / dividendsPerShareAccuracyFactor;
                        break;
                    }
                    if(i==0) {break;}
                }

                shares[shareholder].amount = amount;
                uint256 cumulative = getCumulativeDividends(shareholder);
                require(cumulative >= unpaid, "Claim pending rewards first"); // if withdrawing share while reward is pending for that share, Revert!
                shares[shareholder].totalExcluded = cumulative - unpaid; // carry unpaid over
            }
        } else {
            shares[shareholder].amount = amount;
        }
    }

    function deposit() external payable override { // debugging onlyToken
        uint256 balanceBefore = WETH.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(WETH);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = WETH.balanceOf(address(this)) - balanceBefore;

        totalDividends += amount;
        if(totalShares > 0) {
            dividendsPerShare += dividendsPerShareAccuracyFactor * amount / totalShares;
        }
    }
    
    // 0 is claim as WETH, 1 is compound to vault, 2 is claim as ETHS
    function claimDividend(uint256 action) external {
        require(action == 0 || action == 1 || action == 2, "Invalid action");
        uint256 amount = getUnpaidEarnings(msg.sender);
        require(amount > 0, "No rewards to claim");

        totalDistributed += amount;
        if(action == 0) {
            WETH.transfer(msg.sender, amount);
        } else {
            address[] memory path = new address[](3);
            path[0] = address(WETH);
            path[1] = WAVAX;
            path[2] = _token;

            uint256 amountBefore = eths.balanceOf(msg.sender);

            WETH.approve(address(router), amount);
            eths.setInSwap(true);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                msg.sender,
                block.timestamp
            );
            eths.setInSwap(false);

            if(action == 1) {
                uint256 amountCompound = eths.balanceOf(msg.sender) - amountBefore;
                eths.vaultDepositNoFees(msg.sender, amountCompound);
            }
        }
        shares[msg.sender].totalRealised += amount;
        shares[msg.sender].totalExcluded = getCumulativeDividends(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount < minDistribution) {
            return 0;
        }
        
        uint256 shareholderTotalDividends = getCumulativeDividends(shareholder);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded) { 
            return 0; 
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(address shareholder) internal view returns (uint256) {
        if(((shares[shareholder].amount * dividendsPerShare) / dividendsPerShareAccuracyFactor) <= shares[shareholder].excludedAtUpdates) {
            return 0;
            // exclude at update is reward for all new deposits, which is present in shareholder.amount. 
            // so, if user has reward then cummulative reward must be greater than new reward...
        }
        return ((shares[shareholder].amount * dividendsPerShare) / dividendsPerShareAccuracyFactor) - shares[shareholder].excludedAtUpdates;
    }

    function getNumberOfShareholders() external view returns (uint256) {
        return numShareholders;
    }

    function setMinDistribution(uint256 _minDistribution) external onlyToken {
        minDistribution = _minDistribution;
    }
}