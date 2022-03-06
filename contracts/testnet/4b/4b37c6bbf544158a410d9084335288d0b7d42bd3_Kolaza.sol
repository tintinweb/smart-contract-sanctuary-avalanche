/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-05
*/

// SPDX-License-Identifier: UNLICENSED

// File: https://github.com/vetherasset/vaderprotocol-contracts/blob/5607d6d597ae8cd681ae9f7659c55dd5d826b669/contracts/interfaces/iROUTER.sol


pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit,
        uint256 newInterval
    ) external;
    function setAnchorParams(
        uint256 newLimit,
        uint256 newInside,
        uint256 newOutside
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 units, uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function curatePool(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function listAnchor(address token) external;

    function replaceAnchor(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getKOLAAmount(uint256 USDKAmount) external view returns (uint256 kolaAmount);

    function getUSDKAmount(uint256 kolaAmount) external view returns (uint256 USDKAmount);

    function isCurated(address token) external view returns (bool curated);

    function isBase(address token) external view returns (bool base);

    function reserveUSDK() external view returns (uint256);

    function reserveKOLA() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// File: https://github.com/vetherasset/vaderprotocol-contracts/blob/5607d6d597ae8cd681ae9f7659c55dd5d826b669/contracts/interfaces/iUSDV.sol


pragma solidity 0.8.3;

interface iUSDK {
    function isMature() external view returns (bool);

    function setParams(uint256 newDelay) external;

    function convertToUSDK(uint256 amount) external returns (uint256);

    function convertToUSDKForMember(address member, uint256 amount) external returns (uint256);

    function convertToUSDKDirectly() external returns (uint256 convertAmount);

    function convertToUSDKForMemberDirectly(address member) external returns (uint256 convertAmount);
}

// File: https://github.com/vetherasset/vaderprotocol-contracts/blob/5607d6d597ae8cd681ae9f7659c55dd5d826b669/contracts/interfaces/iUTILS.sol


pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function isBase(address token) external view returns (bool base);

    function calcValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcValueInToken(address token, uint256 amount) external view returns (uint256);

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) external view returns (uint256);

    function calcSwapValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcSwapValueInToken(address token, uint256 amount) external view returns (uint256);

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view;

    function getMemberShare(uint256 basisPoints, address token, address member) external view returns(uint256 units, uint256 outputBase, uint256 outputToken);

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare);

    function getReducedShare(uint256 amount) external view returns (uint256);

    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection);

    function getCoverage(address member, address token) external view returns (uint256);

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external returns (uint256 debt, uint256 baseValue);

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256);

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external returns (uint256 interestOwed);

    function getInterestPayment(address collateralAsset, address debtAsset) external view returns (uint256);

    function getDebtLoading(address collateralAsset, address debtAsset) external view returns (uint256);

    function calcPart(uint256 bp, uint256 total) external pure returns (uint256);

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) external pure returns (uint256);

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256);

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external view returns (uint256);

    function getSlipAdustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) external view returns (uint256);

    function calcSynthUnits(
        uint256 b,
        uint256 B,
        uint256 P
    ) external view returns (uint256);

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) external pure returns (uint256);

    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) external pure returns (uint256);

    function sortArray(uint256[] memory array) external pure returns (uint256[] memory);
}

// File: https://github.com/vetherasset/vaderprotocol-contracts/blob/5607d6d597ae8cd681ae9f7659c55dd5d826b669/contracts/interfaces/iGovernorAlpha.sol


pragma solidity 0.8.3;

interface iGovernorAlpha {
    function VETHER() external view returns(address);
    function KOLA() external view returns(address);
    function USDK() external view returns(address);
    function RESERVE() external view returns(address);
    function VAULT() external view returns(address);
    function ROUTER() external view returns(address);
    function LENDER() external view returns(address);
    function POOLS() external view returns(address);
    function FACTORY() external view returns(address);
    function UTILS() external view returns(address);
    function TIMELOCK() external view returns(address);
}

// File: https://github.com/vetherasset/vaderprotocol-contracts/blob/5607d6d597ae8cd681ae9f7659c55dd5d826b669/contracts/interfaces/iERC677.sol


pragma solidity 0.8.3;

interface iERC677 {
 function onTokenApproval(address token, uint amount, address member, bytes calldata data) external;
 function onTokenTransfer(address token, uint amount, address member, bytes calldata data) external;
}

// File: https://github.com/vetherasset/vaderprotocol-contracts/blob/5607d6d597ae8cd681ae9f7659c55dd5d826b669/contracts/interfaces/iERC20.sol


pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Pola.sol


pragma solidity 0.8.3;

// Interfaces








contract Kolaza is iERC20 {

 // ERC-20 Parameters
    string public constant override name = "Kolaza protocol token";
    string public constant override symbol = "KOLA";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    uint256 public constant maxSupply = 2 * 10**9 * 10**decimals; //2bn

  constructor()  {
    totalSupply = 50000000000000000000000000;
    _balances[msg.sender] = totalSupply;

    emit Transfer(address(0), msg.sender, totalSupply);
  }

    // ERC-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    
    // Parameters
     
    bool public emitting;
    bool public minting;
    uint256 public constant conversionFactor = 1000;

    uint256 public emissionCurve;
    uint256 public secondsPerEra;
    uint256 public era;
    uint256 public eraTailEmissions;
    uint256 public dailyEmission;

    uint256 public nextEraTime;
    uint256 public feeOnTransfer;

    address private governorAlpha;
    address private admin;

    address public constant burnAddress = 0x0111011001100001011011000111010101100101;

    event NewEra(uint256 era, uint256 nextEraTime, uint256 emission);

    // Only TIMELOCK can execute
    modifier onlyTIMELOCK() {
        require(msg.sender == TIMELOCK(), "!TIMELOCK");
        _;
    }
    // Only ADMIN can execute
    modifier onlyADMIN() {
        require(msg.sender == admin, "!ADMIN");
        _;
    }
    // Only GovernorAlpha or TIMELOCK can execute
    modifier onlyGovernorAlphaOrTIMELOCK() {
        require(msg.sender == governorAlpha || msg.sender == TIMELOCK(), "!GovernorAlpha && !TIMELOCK");
        _;
    }
    // Only Admin or TIMELOCK can execute
    modifier onlyAdminOrTIMELOCK() {
        require(msg.sender == admin || msg.sender == TIMELOCK(), "!Admin && !TIMELOCK");
        _;
    }
    // Only VAULT can execute
    modifier onlyVAULT() {
        require(msg.sender == VAULT(), "!VAULT");
        _;
    }

    //=====================================CREATION=========================================//


    //========================================iERC20=========================================//
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // iERC20 Transfer function
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // iERC20 Approve, change allowance functions
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]+(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "allowance err");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        if (_allowances[owner][spender] < type(uint256).max) { // No need to re-approve if already max
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }

    // iERC20 TransferFrom function
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        // Unlimited approval (saves an SSTORE)
        if (_allowances[sender][msg.sender] < type(uint256).max) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "allowance err");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    //iERC677 approveAndCall
    function approveAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
        _approve(msg.sender, recipient, amount);
        iERC677(recipient).onTokenApproval(address(this), amount, msg.sender, data); // Amount is passed thru to recipient
        return true;
    }

    //iERC677 transferAndCall
    function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        iERC677(recipient).onTokenTransfer(address(this), amount, msg.sender, data); // Amount is passed thru to recipient 
        return true;
    }

    // Internal transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "sender");
        require(recipient != address(this), "recipient");
        require(_balances[sender] >= amount, "balance err");
        uint _fee = iUTILS(UTILS()).calcPart(feeOnTransfer, amount); // Critical functionality
        if (_fee <= amount) {
            // Stops reverts if UTILS corrupted
            amount -= _fee;
            _burn(sender, _fee);
        }
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _checkEmission();
    }

    // Internal mint (upgrading and daily emissions)
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "recipient");
        if ((totalSupply + amount) > maxSupply) {
            amount = maxSupply - totalSupply; // Safety, can't mint above maxSupply
        }
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Burn supply
    function burn(uint256 amount) external virtual override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external virtual override {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "address err");
        require(_balances[account] >= amount, "balance err");
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    //===================================== TIMELOCK ====================================//
    // Can start
    function flipEmissions() external onlyTIMELOCK {
        emitting = !emitting;
    }

    // Can stop
    function flipMinting() external onlyADMIN {
        minting = !minting;
    }

    // Can set params
    function setParams(uint256 newSeconds, uint256 newCurve, uint256 newTailEmissionEra) external onlyTIMELOCK {
        secondsPerEra = newSeconds;
        emissionCurve = newCurve;
        eraTailEmissions = newTailEmissionEra;
    }

    // Can change GovernorAlpha
    function changeGovernorAlpha(address newGovernorAlpha) external onlyGovernorAlphaOrTIMELOCK {
        require(newGovernorAlpha != address(0), "address err");
        governorAlpha = newGovernorAlpha;
    }

    // Can change Admin
    function changeAdmin(address newAdmin) external onlyAdminOrTIMELOCK {
        require(newAdmin != address(0), "address err");
        admin = newAdmin;
    }

    // Can purge GovernorAlpha
    function purgeGovernorAlpha() external onlyTIMELOCK {
        governorAlpha = address(0);
    }

    // Can purge Admin
    function purgeAdmin() external onlyTIMELOCK {
        admin = address(0);
    }

    //======================================EMISSION========================================//
    // Internal - Update emission function
    function _checkEmission() private {
        if ((block.timestamp >= nextEraTime) && emitting) {
            // If new Era and allowed to emit
            nextEraTime = block.timestamp + secondsPerEra; // Set next Era time
            uint256 _emission = getDailyEmission(); // Get Daily Dmission
            dailyEmission = _emission;
            _mint(RESERVE(), _emission); // Mint to the RESERVE Address
            feeOnTransfer = iUTILS(UTILS()).getFeeOnTransfer(totalSupply, maxSupply); // UpdateFeeOnTransfer
            if (feeOnTransfer > 1000) {
                feeOnTransfer = 1000;
            } // Max 10% if UTILS corrupted
            era += 1;
            emit NewEra(era, nextEraTime, _emission); // Emit Event
        }
    }

    // Calculate Daily Emission
    function getDailyEmission() public view returns (uint256) {
        if(era < eraTailEmissions && emitting){
            return totalSupply / emissionCurve / 365; // Target inflation prior
        } else {
            return dailyEmission;
        }
    }

    //======================================ASSET MINTING========================================//
    // VETHER Owners to Upgrade
    function upgrade(uint256 amount) external {
        require(iERC20(VETHER()).transferFrom(msg.sender, burnAddress, amount), "!Transfer"); // safeERC20 not needed; vether trusted
        _mint(msg.sender, amount * conversionFactor);
    }

    //============================== HELPERS ================================//

    function GovernorAlpha() external view returns (address) {
        return governorAlpha;
    }

    function Admin() external view returns (address) {
        return admin;
    }

    function VETHER() internal view returns (address) {
        return iGovernorAlpha(governorAlpha).VETHER();
    }


    function VAULT() internal view returns (address) {
        return iGovernorAlpha(governorAlpha).VAULT();
    }

    function RESERVE() internal view returns (address) {
        return iGovernorAlpha(governorAlpha).RESERVE();
    }

    function ROUTER() internal view returns (address) {
        return iGovernorAlpha(governorAlpha).ROUTER();
    }

    function UTILS() internal view returns (address) {
        return iGovernorAlpha(governorAlpha).UTILS();
    }

    function TIMELOCK() internal view returns (address) {
        return iGovernorAlpha(governorAlpha).TIMELOCK();
    }
}