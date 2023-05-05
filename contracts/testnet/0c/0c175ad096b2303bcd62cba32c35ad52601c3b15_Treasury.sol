/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-04
*/

// File: contracts/MMTH/InterfacesAggregated.sol


pragma solidity ^0.8.6;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ITreasury {
    function updateTaxesAccrued(uint taxType, uint amt) external;
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
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
}

interface IWAVAX {
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external returns (bool);
}
// File: contracts/MMTH/Treasury.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;



/// @notice The treasury is responsible for escrow of TaxToken fee's.
///         The treasury handles accounting, for what's owed to different groups.
///         The treasury handles distribution of TaxToken fees to different groups.
///         The admin can modify how TaxToken fees are distributed (the TaxDistribution struct).
contract Treasury {
 
    // ---------------
    // State Variables
    // ---------------

    /// @dev The token that fees are taken from, and what is held in escrow here.
    address public taxToken;

    /// @dev The stablecoin that is distributed via royalties.
    address public stable;

    /// @dev The administrator of accounting and distribution settings.
    address public admin;
    
    address public constant UNIV2_ROUTER = 0x3fd46eB17365e38754d696C660a77c30f826B54D;

    // Mappings

    /// @notice Handles the internal accounting for how much taxToken is owed to each taxType.
    /// @dev    e.g. 10,000 taxToken owed to taxType 0 => taxTokenAccruedForTaxType[0] = 10000 * 10**18.
    ///         taxType 0 => Xfer Tax
    ///         taxType 1 => Buy Tax
    ///         taxType 2 => Sell Tax
    mapping(uint => uint) public taxTokenAccruedForTaxType;

    /// @dev Mapping of taxType to TaxDistribution struct.
    mapping(uint => TaxDistribution) public taxSettings;

    /// @dev Tracks amount of taxToken distributed to recipients.
    mapping(address => uint) public distributionsTaxToken;

    /// @dev Tracks amount of WAVAX distributed to recipients.
    mapping(address => uint) public distributionsStable;      

    // Structs

    /// @notice Manages how TaxToken is distributed for a given taxType.
    ///         Variables:
    ///           walletCount           => The number of wallets to distribute fees to.
    ///           wallets               => The addresses to distribute fees (maps with convertToAsset and percentDistribution).
    ///           convertToAsset        => The asset to pre-convert taxToken to prior to distribution (if same as taxToken, no conversion executed).
    ///           percentDistribution   => The percentage of taxToken accrued for taxType to distribute.
    struct TaxDistribution {
        uint walletCount;
        address[] wallets;
        address[] convertToAsset;
        uint[] percentDistribution;
    }



    // -----------
    // Constructor
    // -----------

    /// @notice Initializes the Treasury.
    /// @param  _admin      The administrator of the contract.
    /// @param  _taxToken   The taxToken (ERC-20 asset) which accumulates in this Treasury.
    constructor(address _admin, address _taxToken, address _stable) {
        admin = _admin;
        taxToken = _taxToken;
        stable = _stable;
    }


    // ---------
    // Modifiers
    // ---------

    /// @dev Enforces msg.sender is admin.
    modifier isAdmin {
        require(msg.sender == admin);
        _;
    }

    /// @dev Enforces msg.sender is taxToken.
    modifier isTaxToken {
        require(msg.sender == taxToken);
        _;
    }



    // ------
    // Events
    // ------

    /// @dev Emitted when transferOwnership() is completed.
    event OwnershipTransferred(address indexed currentAdmin, address indexed newAdmin);

    /// @dev Emitted when royalties are distributed via distributeTaxes()
    event RoyaltiesDistributed(address indexed recipient, uint amount, address asset);

    /// @dev Emitted when the stable state variable is updated via updateStable()
    event StableUpdated(address currentStable, address newStable);

 

    // ---------
    // Functions
    // ---------

    /// @notice Increases _amt of taxToken allocated to _taxType.
    /// @dev    Only callable by taxToken.
    /// @param  _taxType The taxType to allocate more taxToken to for distribution.
    /// @param  _amt The amount of taxToken going to taxType.
    function updateTaxesAccrued(uint _taxType, uint _amt) isTaxToken external {
        taxTokenAccruedForTaxType[_taxType] += _amt;
    }

    /// @notice View function for taxes accrued (a.k.a. "claimable") for each tax type, and the sum.
    /// @return _taxType0 Taxes accrued (claimable) for taxType0.
    /// @return _taxType1 Taxes accrued (claimable) for taxType1.
    /// @return _taxType2 Taxes accrued (claimable) for taxType2.
    /// @return _sum Taxes accrued (claimable) for all tax types.
    function viewTaxesAccrued() external view returns(uint _taxType0, uint _taxType1, uint _taxType2, uint _sum) {
        return (
            taxTokenAccruedForTaxType[0],
            taxTokenAccruedForTaxType[1],
            taxTokenAccruedForTaxType[2],
            taxTokenAccruedForTaxType[0] + taxTokenAccruedForTaxType[1] + taxTokenAccruedForTaxType[2]
        );
    }

    /// @notice This function modifies the distribution settings for a given taxType.
    /// @dev    Only callable by Admin.
    /// @param  _taxType The taxType to update settings for.
    /// @param  _walletCount The number of wallets to distribute across.
    /// @param  _wallets The address of wallets to distribute fees across.
    /// @param  _convertToAsset The asset to convert taxToken to, prior to distribution.
    /// @param  _percentDistribution The percentage (corresponding with wallets) to distribute taxes to of overall amount owed for taxType.
    function setTaxDistribution(
        uint _taxType,
        uint _walletCount,
        address[] calldata _wallets,
        address[] calldata _convertToAsset,
        uint[] calldata _percentDistribution
    ) isAdmin external {

        // Pre-check that supplied values have equal lengths.
        require(_walletCount == _wallets.length, "Treasury.sol::setTaxDistribution(), walletCount length != wallets.length");
        require(_walletCount == _convertToAsset.length, "Treasury.sol::setTaxDistribution(), walletCount length != convertToAsset.length");
        require(_walletCount == _percentDistribution.length, "Treasury.sol::setTaxDistribution(), walletCount length != percentDistribution.length");

        // Enforce sum(percentDistribution) = 100;
        uint sumPercentDistribution;
        for(uint i = 0; i < _walletCount; i++) {
            sumPercentDistribution += _percentDistribution[i];
        }
        require(sumPercentDistribution == 100, "Treasury.sol::setTaxDistribution(), sumPercentDistribution != 100");

        // Update taxSettings for taxType.
        taxSettings[_taxType] = TaxDistribution(
            _walletCount,
            _wallets,
            _convertToAsset,
            _percentDistribution
        );
    }

    /// @notice Distributes taxes for given taxType.
    /// @param  _taxType Chosen taxType to distribute.
    /// @return _amountToDistribute TaxToken amount distributed.
    function distributeTaxes(uint _taxType) public returns(uint _amountToDistribute) {
        
        _amountToDistribute = taxTokenAccruedForTaxType[_taxType];

        if (_amountToDistribute > 0) {

            taxTokenAccruedForTaxType[_taxType] = 0;

            uint sumPercentToSell = 0;

            for (uint i = 0; i < taxSettings[_taxType].wallets.length; i++) {
                if (taxSettings[_taxType].convertToAsset[i] == taxToken) {
                    uint amt = _amountToDistribute * taxSettings[_taxType].percentDistribution[i] / 100;

                    assert(IERC20(taxToken).transfer(taxSettings[_taxType].wallets[i], amt));

                    distributionsTaxToken[taxSettings[_taxType].wallets[i]] += amt;
                    emit RoyaltiesDistributed(taxSettings[_taxType].wallets[i], amt, taxToken);
                }
                else {
                    sumPercentToSell += taxSettings[_taxType].percentDistribution[i];
                }
            }

            if (sumPercentToSell > 0) {

                uint amountToSell = _amountToDistribute * sumPercentToSell / 100;

                address WAVAX = IUniswapV2Router01(UNIV2_ROUTER).WAVAX();

                assert(IERC20(taxToken).approve(address(UNIV2_ROUTER), amountToSell));

                address[] memory path_uni_v2 = new address[](3);

                path_uni_v2[0] = taxToken;
                path_uni_v2[1] = WAVAX;
                path_uni_v2[2] = stable;

                IUniswapV2Router01(UNIV2_ROUTER).swapExactTokensForTokens(
                    amountToSell,           
                    0,
                    path_uni_v2,
                    address(this),
                    block.timestamp + 30000
                );

                uint balanceStable = IERC20(stable).balanceOf(address(this));

                for (uint i = 0; i < taxSettings[_taxType].wallets.length; i++) {
                    if (taxSettings[_taxType].convertToAsset[i] != taxToken) {
                        uint amt = balanceStable * taxSettings[_taxType].percentDistribution[i] / sumPercentToSell;

                        assert(IERC20(stable).transfer(taxSettings[_taxType].wallets[i], amt));

                        distributionsStable[taxSettings[_taxType].wallets[i]] += amt;
                        emit RoyaltiesDistributed(taxSettings[_taxType].wallets[i], amt, stable);
                    }
                }
            }
        }
    }

    /// @notice Distributes taxes for all taxTypes.
    function distributeAllTaxes() external {
        distributeTaxes(0);
        distributeTaxes(1);
        distributeTaxes(2);
    }


    /// @notice Helper view function for taxSettings.
    /// @param  _taxType     tax type of tax settings we want to return 0, 1, or 2.
    /// @return uint256    num of wallets in distribution.
    /// @return address[]  array of wallets in distribution.
    /// @return address[]  array of assets to be converted to during distribution to it's respective wallet.
    /// @return uint[]     array of distribution, all uints must add up to 100.
    function viewTaxSettings(uint _taxType) external view returns(uint256, address[] memory, address[] memory, uint[] memory) {
        return (
            taxSettings[_taxType].walletCount,
            taxSettings[_taxType].wallets,
            taxSettings[_taxType].convertToAsset,
            taxSettings[_taxType].percentDistribution
        );
    }

    /// @notice Withdraw a non-taxToken from the treasury.
    /// @dev    Reverts if token == taxtoken.
    /// @dev    Only callable by Admin.
    /// @param  _token The token to withdraw from the treasury.
    function safeWithdraw(address _token) external isAdmin {
        require(_token != taxToken, "Treasury.sol::safeWithdraw(), cannot withdraw native tokens from this contract");
        assert(IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this))));
    }

    /// @notice Change the admin for the treasury.
    /// @dev    Only callable by Admin.
    /// @param  _admin New admin address.
    function updateAdmin(address _admin) external isAdmin {
        require(_admin != address(0), "Treasury.sol::updateAdmin(), _admin == address(0)");
        emit OwnershipTransferred(admin, _admin);
        admin = _admin;
    }

    /// @notice Change the stable value of the treasury distriubution.
    /// @dev    Only callable by Admin.
    /// @param  _stable New stablecoin address.
    function updateStable(address _stable) external isAdmin {
        require(_stable != stable, "Treasury.sol::updateStable() value already set");
        emit StableUpdated(stable, _stable);
        stable = _stable;
    }
    
    /// @notice View function for exchanging fees collected for given taxType.
    /// @param  _path The path by which taxToken is converted into a given asset (i.e. taxToken => DAI => LINK).
    /// @param  _taxType The taxType to be exchanged.
    function exchangeRateForTaxType(address[] memory _path, uint _taxType) external view returns(uint256) {
        return IUniswapV2Router01(UNIV2_ROUTER).getAmountsOut(
            taxTokenAccruedForTaxType[_taxType], 
            _path
        )[_path.length - 1];
    }

}