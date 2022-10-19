// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IDepositExecute.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IOneSplitWrap.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20Upgradeable.sol";
import "./HandlerHelpersUpgradeable.sol";
import "../interfaces/IUsdcDepositAndBurn.sol";

/// @title Handles ERC20 deposits and deposit executions.
/// @author Router Protocol.
/// @notice This contract is intended to be used with the Bridge contract.
contract ERC20HandlerUpgradeable is
    Initializable,
    ContextUpgradeable,
    IDepositExecute,
    HandlerHelpersUpgradeable,
    ILiquidityPool
{
    using SafeMathUpgradeable for uint256;

    struct DepositRecord {
        uint8 _destinationChainID;
        address _srcTokenAddress;
        address _stableTokenAddress;
        uint256 _stableTokenAmount;
        address _destStableTokenAddress;
        uint256 _destStableTokenAmount;
        address _destinationTokenAdress;
        uint256 _destinationTokenAmount;
        bytes32 _resourceID;
        address _destinationRecipientAddress;
        address _depositer;
        uint256 _srcTokenAmount;
        address _feeTokenAddress;
        uint256 _feeAmount;
        uint256 _isDestNative;
    }

    // destId => depositNonce => Deposit Record
    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    // token contract address => chainId => decimals
    mapping(address => mapping(uint8 => uint8)) public tokenDecimals;

    mapping(uint256 => mapping(uint64 => uint256)) public executeRecord;

    address public _sequencerAddress;

    bytes32 public constant SEQUENCER_ROLE = keccak256("SEQUENCER_ROLE");

    IUsdcDepositAndBurn public _usdcBurnerContract;

    // destId => if USDC is burnable and mintable
    mapping(uint8 => bool) public _isUsdcBurnableMintable;

    // destId => depositNonce => usdcNonce if usdc was burnt else 0
    mapping(uint8 => mapping(uint64 => uint64)) private _usdcBurnData;
    address private _usdc;

    modifier onlyBridgeOrSequencer() {
        require(
            hasRole(BRIDGE_ROLE, msg.sender) || hasRole(SEQUENCER_ROLE, msg.sender),
            "ERC20Handler: Unauthorized transaction"
        );
        _;
    }

    function __ERC20HandlerUpgradeable_init(
        address bridgeAddress,
        address ETH,
        address WETH,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        address[] memory burnableContractAddresses
    ) internal initializer {
        __Context_init_unchained();
        __HandlerHelpersUpgradeable_init();

        require(
            initialResourceIDs.length == initialContractAddresses.length,
            "initialResourceIDs & initialContractAddresses len mismatch"
        );

        _bridgeAddress = bridgeAddress;
        _ETH = ETH;
        _WETH = WETH;

        uint256 initialResourceCount = initialResourceIDs.length;
        for (uint256 i = 0; i < initialResourceCount; i++) {
            _setResource(initialResourceIDs[i], initialContractAddresses[i]);
        }

        uint256 burnableCount = burnableContractAddresses.length;
        for (uint256 i = 0; i < burnableCount; i++) {
            _setBurnable(burnableContractAddresses[i], true);
        }
    }

    function __ERC20HandlerUpgradeable_init_unchained() internal initializer {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
        // Resource IDs are used to identify a specific contract address.
        // These are the Resource IDs this contract will initially support.
        // These are the addresses the {initialResourceIDs} will point to,
        // and are the contracts that will be called to perform various deposit calls.
        @param burnableContractAddresses These addresses will be set as burnable and when {deposit} is called,
        the deposited token will be burned.
        When {executeProposal} is called, new tokens will be minted.

        @dev {initialResourceIDs} and {initialContractAddresses} must have the same length
        (one resourceID for every address).
        Also, these arrays must be ordered in the way that {initialResourceIDs}[0] is the
        intended resourceID for {initialContractAddresses}[0].
     */
    function initialize(
        address bridgeAddress,
        address ETH,
        address WETH,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        address[] memory burnableContractAddresses
    ) external initializer {
        __ERC20HandlerUpgradeable_init(
            bridgeAddress,
            ETH,
            WETH,
            initialResourceIDs,
            initialContractAddresses,
            burnableContractAddresses
        );
    }

    receive() external payable {}

    /// @notice Function to set the bridge address
    /// @dev Can only be called by default admin
    /// @param _bridge address of the bridge
    function setBridge(address _bridge) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _bridgeAddress = _bridge;
    }

    /// @notice Function to set the sequencer address
    /// @dev Can only be called by default admin
    /// @param _sequencer address of the sequencer
    function setSequencer(address _sequencer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _sequencerAddress = _sequencer;
        grantRole(SEQUENCER_ROLE, _sequencer);
    }

    /// @notice Function to set token decimals on target chain.
    /// @param  tokenAddress address of the token
    /// @param  destinationChainID chainId for destination chain
    /// @param  decimals decimals for the token
    function setTokenDecimals(
        address[] calldata tokenAddress,
        uint8[] calldata destinationChainID,
        uint8[] calldata decimals
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            tokenAddress.length == destinationChainID.length && tokenAddress.length == decimals.length,
            "ERC20HandlerUpgradeable setTokenDecimals: Array length mismatch"
        );
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            require(_contractWhitelist[tokenAddress[i]], "provided contract is not whitelisted");
            tokenDecimals[tokenAddress[i]][destinationChainID[i]] = decimals[i];
        }
    }

    /// @notice Function to change precision of a token
    /// @param  token address of the token
    /// @param  chainId chainId for destination chain
    /// @param  tokenAmount amount of token
    function changePrecision(
        address token,
        uint8 chainId,
        uint256 tokenAmount
    ) public view returns (uint256) {
        IERC20Upgradeable srcToken = IERC20Upgradeable(token);
        require(tokenDecimals[token][chainId] > 0, "Decimals not set for token and chain id");
        uint8 srcDecimal = srcToken.decimals();
        uint8 destDecimal = tokenDecimals[token][chainId];
        if (srcDecimal == destDecimal) return tokenAmount;
        if (srcDecimal > destDecimal) {
            uint256 factor = (10**(srcDecimal - destDecimal));
            return tokenAmount / factor;
        } else {
            uint256 factor = (10**(destDecimal - srcDecimal));
            return tokenAmount * factor;
        }
    }

    /// @notice Function to set execute record
    /// @param  chainId chainId for destination chain
    /// @param  nonce nonce for the transaction
    function setExecuteRecord(uint256 chainId, uint64 nonce) internal {
        executeRecord[chainId][nonce] = block.number;
    }

    /// @notice Function used to fetch deposit record
    /// @param depositNonce This ID will have been generated by the Bridge contract
    /// @param destId ID of chain deposit will be bridged to
    /// @return DepositRecord
    function getDepositRecord(uint64 depositNonce, uint8 destId) public view virtual returns (DepositRecord memory) {
        return _depositRecords[destId][depositNonce];
    }

    /// @notice Function used to fetch usdc burn data
    /// @param depositNonce This ID will have been generated by the Bridge contract
    /// @param destId ID of chain deposit will be bridged to
    /// @return USDC Burn data()
    /// (abi.encode(uint8 destChainId,uint32 usdcDomainId,address destReserveHandlerAddress,address usdc,address destCallerAddress,uint256 usdcNonce))
    function getUsdcBurnData(uint64 depositNonce, uint8 destId) public view virtual returns (uint64) {
        return _usdcBurnData[destId][depositNonce];
    }

    /// @notice Function used to fetch usdc address
    function getUsdcAddress() public view returns (address) {
        return _usdc;
    }

    /// @notice Function used to set reserve handler
    /// @param reserve address of the reserve handler
    function setReserve(IHandlerReserve reserve) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _reserve = reserve;
    }

    /// @notice Function used to set usdc address
    /// @param  usdc address
    function setUsdcAddress(address usdc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _usdc = usdc;
    }

    function setUsdcBurnerContract(address _usdcBurner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _usdcBurnerContract = IUsdcDepositAndBurn(_usdcBurner);
    }

    function setUsdcBurnableAndMintable(uint8[] memory _destChainID) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint8 i = 0; i < _destChainID.length; i++) {
            require(_destChainID[i] != 0, "ERC20 Handler: Chain Id cannot be 0");

            _isUsdcBurnableMintable[i] = true;
        }
    }

    /// @notice A deposit is initiatied by making a deposit in the Bridge contract
    /// @dev Depending if the corresponding {tokenAddress} for the parsed {resourceID} is
    /// marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
    /// @param resourceID Resource ID for the token
    /// @param destinationChainID Chain ID of chain tokens are expected to be bridged to
    /// @param depositNonce This value is generated as an ID by the Bridge contract
    /// @param swapDetails Swap details struct required for the deposit
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo memory swapDetails
    ) public virtual override onlyBridgeOrSequencer {
        uint256 feeAmount;
        swapDetails.srcStableTokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[swapDetails.srcStableTokenAddress], "provided tokenAddress is not whitelisted");

        if (address(swapDetails.srcTokenAddress) == swapDetails.srcStableTokenAddress) {
            require(swapDetails.srcStableTokenAmount == swapDetails.srcTokenAmount, "Invalid token amount");
            if (swapDetails.feeTokenAddress == address(0)) {
                swapDetails.feeTokenAddress = swapDetails.srcStableTokenAddress;
            }
            (uint256 transferFee, ) = getBridgeFee(destinationChainID, swapDetails.feeTokenAddress);
            feeAmount = transferFee;
            // Fees of stable token address
            _reserve.deductFee(
                swapDetails.feeTokenAddress,
                swapDetails.depositer,
                // swapDetails.providedFee,
                transferFee,
                // _ETH,
                _isFeeEnabled,
                address(feeManager)
            );

            if (_usdc == swapDetails.srcStableTokenAddress && _isUsdcBurnableMintable[destinationChainID]) {
                // Burn USDC
                handleUsdcBurn(swapDetails.depositer, swapDetails.srcTokenAmount, destinationChainID, depositNonce);
            } else {
                // just deposit
                handleDepositForReserveToken(swapDetails);
            }
        } else if (_reserve._contractToLP(swapDetails.srcStableTokenAddress) == address(swapDetails.srcTokenAddress)) {
            require(swapDetails.srcStableTokenAmount == swapDetails.srcTokenAmount, "Invalid token amount");
            feeAmount = deductFeeAndHandleDepositForLPToken(swapDetails, destinationChainID);
        } else {
            if (swapDetails.feeTokenAddress != address(0)) {
                (, uint256 exchangeFee) = getBridgeFee(destinationChainID, swapDetails.feeTokenAddress);
                feeAmount = exchangeFee;
                // Fees of stable token address

                _reserve.deductFee(
                    swapDetails.feeTokenAddress,
                    swapDetails.depositer,
                    // swapDetails.providedFee,
                    exchangeFee,
                    // _ETH,
                    _isFeeEnabled,
                    address(feeManager)
                );
            }

            _reserve.lockERC20(
                address(swapDetails.srcTokenAddress),
                swapDetails.depositer,
                _oneSplitAddress,
                swapDetails.srcTokenAmount
            );
            handleDepositForNonReserveToken(swapDetails);

            if (swapDetails.feeTokenAddress == address(0)) {
                (, uint256 exchangeFee) = getBridgeFee(destinationChainID, swapDetails.srcStableTokenAddress);
                feeAmount = exchangeFee;
                swapDetails.feeTokenAddress = swapDetails.srcStableTokenAddress;
                require(
                    swapDetails.srcStableTokenAmount >= exchangeFee,
                    "ERC20handler : provided fee is less than the amount"
                );
                swapDetails.srcStableTokenAmount = swapDetails.srcStableTokenAmount - exchangeFee;
                _reserve.releaseERC20(swapDetails.feeTokenAddress, address(feeManager), exchangeFee);
            }

            if (_burnList[address(swapDetails.srcStableTokenAddress)]) {
                _reserve.burnERC20(
                    address(swapDetails.srcStableTokenAddress),
                    address(_reserve),
                    swapDetails.srcStableTokenAmount
                );
            } else if (swapDetails.srcStableTokenAddress == _usdc && _isUsdcBurnableMintable[destinationChainID]) {
                // Burn USDC
                _reserve.giveAllowance(_usdc, address(_usdcBurnerContract), swapDetails.srcStableTokenAmount);
                handleUsdcBurn(address(_reserve), swapDetails.srcStableTokenAmount, destinationChainID, depositNonce);
            }
        }

        uint256 destStableTokenAmount = changePrecision(
            address(swapDetails.srcStableTokenAddress),
            destinationChainID,
            swapDetails.srcStableTokenAmount
        );

        require(destStableTokenAmount > 0, "Transfer amount too low");
        _depositRecords[destinationChainID][depositNonce] = DepositRecord(
            destinationChainID,
            address(swapDetails.srcTokenAddress),
            swapDetails.srcStableTokenAddress,
            swapDetails.srcStableTokenAmount,
            address(swapDetails.destStableTokenAddress),
            destStableTokenAmount,
            address(swapDetails.destTokenAddress),
            swapDetails.destTokenAmount,
            resourceID,
            swapDetails.recipient,
            swapDetails.depositer,
            swapDetails.srcTokenAmount,
            swapDetails.feeTokenAddress,
            feeAmount,
            swapDetails.isDestNative ? 1 : 0
        );
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    /// by a relayer on the deposit's destination chain
    /// @notice Data passed into the function should be constructed as follows:
    ///    amount                                 uint256     bytes  0 - 32
    ///    destinationRecipientAddress length     uint256     bytes  32 - 64
    ///    destinationRecipientAddress            bytes       bytes  64 - END
    /// @param  swapDetails swapInfo struct required for the transaction
    /// @param  resourceID resourceId for the token
    /// @return settlementToken and settlementAmount
    function executeProposal(SwapInfo memory swapDetails, bytes32 resourceID)
        public
        virtual
        override
        onlyBridgeOrSequencer
        returns (address settlementToken, uint256 settlementAmount)
    {
        swapDetails.destStableTokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[swapDetails.destStableTokenAddress], "provided tokenAddress is not whitelisted");

        if (address(swapDetails.destTokenAddress) == swapDetails.destStableTokenAddress) {
            // just release destStable tokens
            (settlementToken, settlementAmount) = handleExecuteForReserveToken(swapDetails);
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        } else if (
            _reserve._contractToLP(swapDetails.destStableTokenAddress) == address(swapDetails.destTokenAddress)
        ) {
            // release LP is destToken is LP of destStableToken
            handleExecuteForLPToken(swapDetails);
            settlementToken = address(swapDetails.destTokenAddress);
            settlementAmount = swapDetails.destStableTokenAmount;
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        } else {
            // exchange destStable to destToken and release tokens
            (settlementToken, settlementAmount) = handleExecuteForNonReserveToken(swapDetails);
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        }
    }

    /// @notice Used to manually release ERC20 tokens from ERC20Safe
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount The amount of ERC20 tokens to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.releaseERC20(tokenAddress, recipient, amount);
    }

    /// @notice Used to manually release ERC20 tokens from FeeManager
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount The amount of ERC20 tokens to release.
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        feeManager.withdrawFee(tokenAddress, recipient, amount);
    }

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.stake(depositor, tokenAddress, amount);
    }

    /// @notice Staking should be done by using bridge contract
    /// @param depositor address of the depositor
    /// @param tokenAddress address of the token for which lp needs to be added
    /// @param amount amount of the token
    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        require(IWETH(_WETH).transfer(address(_reserve), amount));
        _reserve.stakeETH(depositor, tokenAddress, amount);
    }

    /// @notice Unstake token from LP
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.unstake(unstaker, tokenAddress, amount);
    }

    /// @notice Unstake ETH from LP
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.unstakeETH(unstaker, tokenAddress, amount, _WETH);
    }

    /// @notice Function to fetch the staked record
    /// @param  account Address of the account who has staked
    /// @param  tokenAddress staking token address
    function getStakedRecord(address account, address tokenAddress) public view virtual returns (uint256) {
        return _reserve.getStakedRecord(account, tokenAddress);
    }

    /// @notice Function to handle USDC burn and sets the details in the _usdcBurnData
    /// @param  depositor address of the depositor
    /// @param  amount amount to be burnt
    /// @param  destChainId Router destination chainId
    function handleUsdcBurn(
        address depositor,
        uint256 amount,
        uint8 destChainId,
        uint64 depositNonce
    ) internal {
        IUsdcDepositAndBurn usdcBurnerContract = _usdcBurnerContract;
        require(address(usdcBurnerContract) != address(0), "USDC Burner Contract is not set");
        uint64 usdcNonce = usdcBurnerContract.depositAndBurnUsdc(depositor, amount, destChainId);
        _usdcBurnData[destChainId][depositNonce] = usdcNonce;
    }

    /// @notice Function to handle deposit for reserve tokens
    /// @param  swapDetails swapInfo struct for the swap details
    function handleDepositForReserveToken(SwapInfo memory swapDetails) internal {
        if (_burnList[address(swapDetails.srcTokenAddress)]) {
            _reserve.burnERC20(address(swapDetails.srcTokenAddress), swapDetails.depositer, swapDetails.srcTokenAmount);
        } else {
            _reserve.lockERC20(
                address(swapDetails.srcTokenAddress),
                swapDetails.depositer,
                address(_reserve),
                swapDetails.srcTokenAmount
            );
        }
    }

    /// @notice Deducts fee and handles deposit for LP tokens
    /// @param swapDetails swapInfo struct for the swap details
    /// @param destinationChainID chainId for destination chain
    /// @return transferFee
    function deductFeeAndHandleDepositForLPToken(SwapInfo memory swapDetails, uint8 destinationChainID)
        internal
        returns (uint256 transferFee)
    {
        if (swapDetails.feeTokenAddress == address(0)) {
            swapDetails.feeTokenAddress = address(swapDetails.srcTokenAddress);
            (transferFee, ) = getBridgeFee(destinationChainID, swapDetails.srcStableTokenAddress);
        } else {
            (transferFee, ) = getBridgeFee(destinationChainID, swapDetails.feeTokenAddress);
        }
        // Fees of stable token address
        _reserve.deductFee(
            swapDetails.feeTokenAddress,
            swapDetails.depositer,
            // swapDetails.providedFee,
            transferFee,
            // _ETH,
            _isFeeEnabled,
            address(feeManager)
        );
        _reserve.burnERC20(address(swapDetails.srcTokenAddress), swapDetails.depositer, swapDetails.srcTokenAmount);
    }

    /// @notice Handles deposit for non-reserve tokens
    /// @param swapDetails swapInfo struct for the swap details
    function handleDepositForNonReserveToken(SwapInfo memory swapDetails) internal {
        uint256 pathLength = swapDetails.path.length;
        if (pathLength > 2) {
            //swapMulti
            require(swapDetails.path[pathLength - 1] == swapDetails.srcStableTokenAddress);
            swapDetails.srcStableTokenAmount = _reserve.swapMulti(
                _oneSplitAddress,
                swapDetails.path,
                swapDetails.srcTokenAmount,
                swapDetails.srcStableTokenAmount,
                swapDetails.flags,
                swapDetails.dataTx
            );
        } else {
            swapDetails.srcStableTokenAmount = _reserve.swap(
                _oneSplitAddress,
                address(swapDetails.srcTokenAddress),
                swapDetails.srcStableTokenAddress,
                swapDetails.srcTokenAmount,
                swapDetails.srcStableTokenAmount,
                swapDetails.flags[0],
                swapDetails.dataTx[0]
            );
        }
    }

    /// @notice Handles execution of transfer for reserve tokens
    /// @param swapDetails swapInfo struct for the swap details
    /// @return destinationStableTokenAddress and destinationStableTokenAmount
    function handleExecuteForReserveToken(SwapInfo memory swapDetails) internal returns (address, uint256) {
        if (_burnList[address(swapDetails.destTokenAddress)]) {
            _reserve.mintERC20(
                address(swapDetails.destTokenAddress),
                swapDetails.recipient,
                swapDetails.destStableTokenAmount
            );
        } else {
            uint256 reserveBalance = IERC20(address(swapDetails.destStableTokenAddress)).balanceOf(address(_reserve));
            if (reserveBalance < swapDetails.destStableTokenAmount) {
                _reserve.mintWrappedERC20(
                    address(swapDetails.destStableTokenAddress),
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (
                    _reserve._contractToLP(address(swapDetails.destStableTokenAddress)),
                    swapDetails.destStableTokenAmount
                );
            } else {
                if (address(swapDetails.destStableTokenAddress) == _WETH && swapDetails.isDestNative) {
                    _reserve.withdrawWETH(_WETH, swapDetails.destStableTokenAmount);
                    _reserve.safeTransferETH(swapDetails.recipient, swapDetails.destStableTokenAmount);
                } else {
                    _reserve.releaseERC20(
                        address(swapDetails.destStableTokenAddress),
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    );
                }
            }
        }
        return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
    }

    /// @notice Handles execution of transfer for LP tokens
    /// @param swapDetails swapInfo struct for the swap details
    function handleExecuteForLPToken(SwapInfo memory swapDetails) internal {
        _reserve.mintWrappedERC20(
            address(swapDetails.destStableTokenAddress),
            swapDetails.recipient,
            swapDetails.destStableTokenAmount
        );
    }

    /// @notice Handles execution of transfer for non-reserve tokens
    /// @param swapDetails swapInfo struct for the swap details
    /// @return destinationStableTokenAddress and destinationStableTokenAmount
    function handleExecuteForNonReserveToken(SwapInfo memory swapDetails) internal returns (address, uint256) {
        if (_burnList[swapDetails.destStableTokenAddress]) {
            if (
                (swapDetails.path.length > 2) &&
                (swapDetails.path[swapDetails.path.length - 1] != address(swapDetails.destTokenAddress))
            ) {
                _reserve.mintERC20(
                    swapDetails.destStableTokenAddress,
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (swapDetails.destStableTokenAddress, swapDetails.destStableTokenAmount);
            }
            _reserve.mintERC20(swapDetails.destStableTokenAddress, _oneSplitAddress, swapDetails.destStableTokenAmount);
        } else {
            uint256 reserveBalance = IERC20(address(swapDetails.destStableTokenAddress)).balanceOf(address(_reserve));
            if (reserveBalance < swapDetails.destStableTokenAmount) {
                _reserve.mintWrappedERC20(
                    address(swapDetails.destStableTokenAddress),
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (
                    _reserve._contractToLP(address(swapDetails.destStableTokenAddress)),
                    swapDetails.destStableTokenAmount
                );
            } else {
                if (
                    (swapDetails.path.length > 2) &&
                    (swapDetails.path[swapDetails.path.length - 1] != address(swapDetails.destTokenAddress))
                ) {
                    _reserve.releaseERC20(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    );
                    return (swapDetails.destStableTokenAddress, swapDetails.destStableTokenAmount);
                }
                _reserve.releaseERC20(
                    swapDetails.destStableTokenAddress,
                    _oneSplitAddress,
                    swapDetails.destStableTokenAmount
                );
            }
        }
        if (swapDetails.path.length > 2) {
            //solhint-disable avoid-low-level-calls
            (bool success, bytes memory returnData) = address(_reserve).call(
                abi.encodeWithSelector(
                    0x2214e13b, // swapMulti(address,address[],uint256,uint256,uint256[],bytes[])
                    _oneSplitAddress,
                    swapDetails.path,
                    swapDetails.destStableTokenAmount,
                    swapDetails.destTokenAmount,
                    swapDetails.flags,
                    swapDetails.dataTx
                )
            );
            if (success) {
                swapDetails.returnAmount = abi.decode(returnData, (uint256));
            } else {
                require(
                    IOneSplitWrap(_oneSplitAddress).withdraw(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    )
                );
                return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
            }
        } else {
            (bool success, bytes memory returnData) = address(_reserve).call(
                abi.encodeWithSelector(
                    0xda041a85, //swap(address,address,address,uint256,uint256,uint256,bytes)
                    _oneSplitAddress,
                    swapDetails.destStableTokenAddress,
                    address(swapDetails.destTokenAddress),
                    swapDetails.destStableTokenAmount,
                    swapDetails.destTokenAmount,
                    swapDetails.flags[0],
                    swapDetails.dataTx[0]
                )
            );
            if (success) {
                swapDetails.returnAmount = abi.decode(returnData, (uint256));
            } else {
                require(
                    IOneSplitWrap(_oneSplitAddress).withdraw(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    )
                );
                return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
            }
        }
        if (address(swapDetails.destTokenAddress) == _WETH && swapDetails.isDestNative) {
            _reserve.withdrawWETH(_WETH, swapDetails.returnAmount);
            _reserve.safeTransferETH(swapDetails.recipient, swapDetails.returnAmount);
        } else {
            _reserve.releaseERC20(
                address(swapDetails.destTokenAddress),
                swapDetails.recipient,
                swapDetails.returnAmount
            );
        }
        return (address(swapDetails.destTokenAddress), swapDetails.returnAmount);
    }

    function withdrawNative(
        address recipient,
        uint256 amount,
        bool withdrawAll
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 bal = address(this).balance;
        bool success;
        if (withdrawAll) {
            (success, ) = recipient.call{ value: bal }("");
        } else {
            require(bal >= amount, "Insufficient balance");
            (success, ) = recipient.call{ value: amount }("");
        }
        require(success, "Transaction failed");
    }

    uint256[50] public gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface IDepositExecute {
    struct SwapInfo {
        address feeTokenAddress;
        uint64 depositNonce;
        uint256 index;
        uint256 returnAmount;
        address recipient;
        address stableTokenAddress;
        address handler;
        uint256 srcTokenAmount;
        uint256 srcStableTokenAmount;
        uint256 destStableTokenAmount;
        uint256 destTokenAmount;
        uint256 lenRecipientAddress;
        uint256 lenSrcTokenAddress;
        uint256 lenDestTokenAddress;
        bytes20 srcTokenAddress;
        address srcStableTokenAddress;
        bytes20 destTokenAddress;
        address destStableTokenAddress;
        bytes[] dataTx;
        uint256[] flags;
        address[] path;
        address depositer;
        bool isDestNative;
        uint256 widgetID;
    }

    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param destinationChainID Chain ID deposit is expected to be bridged to.
    /// @param depositNonce This value is generated as an ID by the Bridge contract.
    /// @param swapDetails Swap details
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo calldata swapDetails
    ) external;

    /// @notice It is intended that proposals are executed by the Bridge contract.
    function executeProposal(SwapInfo calldata swapDetails, bytes32 resourceID) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface ILiquidityPool {
    /// @notice Staking should be done by using bridge contract.
    /// @param depositor stakes liquidity in the pool .
    /// @param tokenAddress staking token for which liquidity needs to be added.
    /// @param amount Amount that needs to be staked.
    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    /// @notice Staking should be done by using bridge contract.
    /// @param depositor stakes liquidity in the pool .
    /// @param tokenAddress staking token for which liquidity needs to be added.
    /// @param amount Amount that needs to be staked.
    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    /// @notice Staking should be done by using bridge contract.
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;

    /// @notice Staking should be done by using bridge contract.
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IOneSplitWrap {
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) external view returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGasMulti(
        address[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        external
        view
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper
    ) external payable returns (uint256 returnAmount);

    function swapMulti(
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERC20Upgradeable {
    function transfer(address, uint256) external;

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../interfaces/IERCHandler.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/IHandlerReserve.sol";

/// @title Function used across handler contracts.
/// @author Router Protocol.
/// @notice This contract is intended to be used with the Bridge contract.
contract HandlerHelpersUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable, IERCHandler {
    address public _bridgeAddress;
    address public _oneSplitAddress;
    address public override _ETH;
    address public override _WETH;
    bool public _isFeeEnabled;
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    IFeeManagerUpgradeable public feeManager;
    IHandlerReserve public _reserve;

    // resourceID => token contract address
    mapping(bytes32 => address) internal _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping(address => bytes32) public _tokenContractAddressToResourceID;

    // token contract address => is whitelisted
    mapping(address => bool) public _contractWhitelist;

    // token contract address => is burnable
    mapping(address => bool) public _burnList;

    // bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    function __HandlerHelpersUpgradeable_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _msgSender());
        _isFeeEnabled = false;
    }

    function __HandlerHelpersUpgradeable_init_unchained() internal initializer {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // function grantFeeRole(address account) public virtual override onlyRole(BRIDGE_ROLE) {
    //     grantRole(FEE_SETTER_ROLE, account);
    //     totalFeeSetters = totalFeeSetters + 1;
    // }

    // function revokeFeeRole(address account) public virtual override onlyRole(BRIDGE_ROLE) {
    //     revokeRole(FEE_SETTER_ROLE, account);
    //     totalFeeSetters = totalFeeSetters - 1;
    // }

    /// @notice Function to set the fee manager address
    /// @dev Can only be called by default admin
    /// @param _feeManager address of the fee manager
    function setFeeManager(IFeeManagerUpgradeable _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = _feeManager;
    }

    /// @notice Function to get the bridge fee
    /// @param destinationChainID chainId for destination chain
    /// @param feeTokenAddress address of the fee token
    /// @return fees struct
    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress)
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return feeManager.getFee(destinationChainID, feeTokenAddress);
    }

    /// @notice Function to set the bridge fee
    /// @dev Can only be called by bridge
    /// @param destinationChainID chainId for destination chain
    /// @param feeTokenAddress address of the fee token
    /// @param transferFee fee for cross-chain transfer
    /// @param exchangeFee fee for cross-chain swaps
    /// @param accepted true if the fee token is an accepted fee token
    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, transferFee, exchangeFee, accepted);
    }

    /// @notice Function to set fee status
    /// @dev Can only be called by bridge
    /// @param status true to enable the fees
    function toggleFeeStatus(bool status) public virtual override onlyRole(BRIDGE_ROLE) {
        _isFeeEnabled = status;
    }

    /// @notice Function to get the fee status
    /// @return feeStatus
    function getFeeStatus() public view virtual override returns (bool) {
        return _isFeeEnabled;
    }

    /// @notice Function to get the token contract address from resource Id
    /// @param resourceID resourceID for the token
    /// @return tokenAddress
    function resourceIDToTokenContractAddress(bytes32 resourceID) public view virtual override returns (address) {
        return _resourceIDToTokenContractAddress[resourceID];
    }

    /// @notice First verifies {_resourceIDToContractAddress}[{resourceID}] and
    /// {_contractAddressToResourceID}[{contractAddress}] are not already set,
    /// then sets {_resourceIDToContractAddress} with {contractAddress},
    /// {_contractAddressToResourceID} with {resourceID},
    /// and {_contractWhitelist} to true for {contractAddress}.
    /// @dev Can only be called by the bridge
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) public virtual override onlyRole(BRIDGE_ROLE) {
        _setResource(resourceID, contractAddress);
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @dev Can only be called by the bridge
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag to change burnable status.

    function setBurnable(address contractAddress, bool status) public virtual override onlyRole(BRIDGE_ROLE) {
        _setBurnable(contractAddress, status);
    }

    /// @notice Used to manually release funds from ERC safes.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount the amount of ERC20 tokens to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override {}

    /// @notice Used to withdraw fees from fee manager.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount the amount of tokens to release.
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override {}

    /// @notice Sets oneSplitAddress for the handler
    /// @dev Can only be set by the bridge
    /// @param contractAddress Address of oneSplit contract
    function setOneSplitAddress(address contractAddress) public virtual override onlyRole(BRIDGE_ROLE) {
        _setOneSplitAddress(contractAddress);
    }

    /// @notice Sets liquidity pool for given ERC20 address. These pools will be used to
    /// stake and unstake liqudity.
    /// @dev Can only be set by the bridge
    /// @param contractAddress Address of contract for which LP contract should be set.
    /// @param lpAddress Address of lp contract.
    function setLiquidityPool(
        // string memory name,
        // string memory symbol,
        // uint8 decimals,
        address contractAddress,
        address lpAddress
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        // address newLPAddress = _reserve._setLiquidityPool(name, symbol, decimals, contractAddress, lpAddress);
        address newLPAddress = _reserve._setLiquidityPool(contractAddress, lpAddress);
        _contractWhitelist[newLPAddress] = true;
        _burnList[newLPAddress] = true;
    }

    /// @notice Sets liquidity pool owner for an existing LP.
    /// @dev Can only be set by the bridge
    /// @param oldOwner Address of the old owner of LP
    /// @param newOwner Address of the new owner for LP
    /// @param tokenAddress Address of ERC20 token
    /// @param lpAddress Address of LP.
    function setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve._setLiquidityPoolOwner(oldOwner, newOwner, tokenAddress, lpAddress);
    }

    /// @notice Sets resource for the bridge.
    /// @param resourceID resourceID of ERC20 tokens
    /// @param contractAddress Address of ERC20 tokens
    function _setResource(bytes32 resourceID, address contractAddress) internal virtual {
        require(contractAddress != address(0), "contract address can't be zero");

        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
        _tokenContractAddressToResourceID[contractAddress] = resourceID;
        _contractWhitelist[contractAddress] = true;
    }

    /// @notice Sets a resource burnable.
    /// @param contractAddress Address of ERC20 token
    /// @param status true for burnable, false for not burnable
    function _setBurnable(address contractAddress, bool status) internal virtual {
        require(_contractWhitelist[contractAddress], "provided contract is not whitelisted");
        _burnList[contractAddress] = status;
    }

    /// @notice Sets onesplit address.
    /// @param contractAddress Address of OneSplit contract
    function _setOneSplitAddress(address contractAddress) internal virtual {
        require(contractAddress != address(0), "ERC20Handler: contractAddress cannot be null");
        _oneSplitAddress = address(contractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IUsdcDepositAndBurn {
    struct DestDetails {
        uint8 chainId;
        uint32 usdcDomainId;
        address reserveHandlerAddress;
        address destCallerAddress;
    }

    function setDestDetails(DestDetails[] memory destDetails) external;

    function depositAndBurnUsdc(
        address sender,
        uint256 amount,
        uint8 destChainId
    ) external returns (uint64);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERCHandler {
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);

    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) external;

    function toggleFeeStatus(bool status) external;

    function getFeeStatus() external view returns (bool);

    function _ETH() external view returns (address);

    function _WETH() external view returns (address);

    function resourceIDToTokenContractAddress(bytes32 resourceID) external view returns (address);

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    // function setTokenDecimals(
    //     address[] calldata tokenAddress,
    //     uint8[] calldata destinationChainID,
    //     uint8[] calldata decimals
    // ) external;

    /// @notice Sets oneSplitAddress for the handler
    /// @param contractAddress Address of oneSplit contract
    function setOneSplitAddress(address contractAddress) external;

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param contractAddress Address of contract for qhich liquidity pool needs to be created.
    function setLiquidityPool(address contractAddress, address lpAddress) external;

    // function setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external;

    /// @notice Sets liquidity pool owner for an existing LP.
    /// @dev Can only be set by the bridge
    /// @param oldOwner Address of the old owner of LP
    /// @param newOwner Address of the new owner for LP
    /// @param tokenAddress Address of ERC20 token
    /// @param lpAddress Address of LP
    function setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag for burnanble status.
    function setBurnable(address contractAddress, bool status) external;

    /// @notice Used to manually release funds from ERC safes.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IFeeManagerUpgradeable {
    function setFees(
        uint8 destinationChainID,
        address[] calldata feeTokenAddrs,
        uint256[] calldata transferFees,
        uint256[] calldata exchangeFees,
        bool[] calldata accepted
    ) external;

    function withdrawFee(address tokenAddress, address recipient, uint256 amount) external;

    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) external;

    function getFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IHandlerReserve {
    function fundERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) external;

    function lockERC20(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 amount
    ) external;

    function releaseERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function mintERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function burnERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) external;

    function safeTransferETH(address to, uint256 value) external;

    function deductFee(
        address feeTokenAddress,
        address depositor,
        // uint256 providedFee,
        uint256 requiredFee,
        // address _ETH,
        bool _isFeeEnabled,
        address _feeManager
    ) external;

    function mintWrappedERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount,
        address WETH
    ) external;

    function giveAllowance(
        address token,
        address spender,
        uint256 amount
    ) external;

    function getStakedRecord(address account, address tokenAddress) external view returns (uint256);

    function withdrawWETH(address WETH, uint256 amount) external;

    function _setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    function _setLiquidityPool(address contractAddress, address lpAddress) external returns (address);

    // function _setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external returns (address);

    function swapMulti(
        address oneSplitAddress,
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx
    ) external returns (uint256 returnAmount);

    function swap(
        address oneSplitAddress,
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx
    ) external returns (uint256 returnAmount);

    function feeManager() external returns (address);

    function _lpToContract(address token) external returns (address);

    function _contractToLP(address token) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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