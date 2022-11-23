pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./dependencies/Controller.sol";
import "./helpers/PermitApprove.sol";
import "./helpers/EthReceiver.sol";
import "./interfaces/IUnizenDexAggr.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateReceiver.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";

contract UnizenDexAggr is
    IUnizenDexAggr,
    Controller,
    PermitApprove,
    EthReceiver,
    ReentrancyGuardUpgradeable,
    IStargateReceiver,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public stargateRouter;
    address public layerZeroEndpoint;
    address public stable;
    uint16 public stableDecimal;
    mapping(uint16 => uint16) public chainStableDecimal;
    mapping(uint16 => address) public destAddr;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => address) public poolToStableAddr;
    uint256 public dstGas;

    // mapping(address => bool) public callBackTradeMemory;

    function initialize() public initializer {
        __UnizenDexAggr_init();
    }

    function __UnizenDexAggr_init() internal onlyInitializing {
        __Controller_init_();
        __ReentrancyGuard_init();
        dstGas = 700000; // 700k gas for destination chain execution as default
    }

    // ADMIN function
    function setDstGas(uint256 _gas) external onlyOwner {
        dstGas = _gas;
    }

    function setDestAddr(uint16 chainId, address dexAggr) external onlyOwner {
        destAddr[chainId] = dexAggr;
    }

    function setLZEndPoint(address endpoint) external onlyOwner {
        require(endpoint != address(0), "Invalid-address");
        layerZeroEndpoint = endpoint;
    }

    function setTrustedRemote(uint16 chainId, bytes calldata remoteAddr)
        external
        onlyOwner
    {
        trustedRemoteLookup[chainId] = remoteAddr;
    }

    function setStargateRouter(address router) external onlyOwner {
        require(router != address(0), "Invalid-address");
        stargateRouter = router;
    }

    function setStableAddress(address stableAddr, uint16 decimal)
        external
        onlyOwner
    {
        require(stableAddr != address(0), "Invalid-address");
        require(stargateRouter != address(0), "Not-set-STG-Router");
        stable = stableAddr;
        stableDecimal = decimal;
        if (IERC20(stable).allowance(address(this), stargateRouter) == 0) {
            IERC20(stable).safeApprove(stargateRouter, type(uint256).max);
        }
    }

    function setPoolStable(uint16 poolId, address stableAddr)
        external
        onlyOwner
    {
        poolToStableAddr[poolId] = stableAddr;
        if (IERC20(stableAddr).allowance(address(this), stargateRouter) == 0) {
            IERC20(stableAddr).safeApprove(stargateRouter, type(uint256).max);
        }
    }

    function whiteListChainStable(uint16 chainId, uint16 decimal)
        external
        onlyOwner
    {
        chainStableDecimal[chainId] = decimal;
    }

    function fundStable(uint256 amount) external onlyOwner {
        IERC20(stable).safeTransferFrom(msg.sender, address(this), amount);
    }

    function recoverAsset(address token) external onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).sendValue(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(msg.sender, balance);
        }
    }

    function revokeApprove(address token, address spender) external onlyOwner {
        IERC20(token).safeApprove(spender, 0);
    }

    // SWAP LZ

    // CrossChainSwapSg memory swapInfo,

    function swapLZ(
        CrossChainSwapLz memory swapInfo,
        SwapCall[] memory calls,
        SwapCall[] memory dstCalls
    ) external payable nonReentrant {
        require(chainStableDecimal[swapInfo.dstChain] != 0, "Not-enable-yet");
        require(destAddr[swapInfo.dstChain] != address(0), "Invalid-address");
        uint256 balanceStableBefore = IERC20(stable).balanceOf(address(this));
        if (!swapInfo.isFromNative) {
            IERC20(swapInfo.srcToken).safeTransferFrom(
                msg.sender,
                address(this),
                swapInfo.amount
            );
        } else {
            require(
                msg.value >= swapInfo.amount + swapInfo.nativeFee,
                "Invalid-amount"
            );
        }

        for (uint8 i = 0; i < calls.length; i++) {
            require(calls[i].amount != 0, "Invalid-trade-amount");
            require(
                isWhiteListedDex(calls[i].targetExchange),
                "Not-verified-dex"
            );
            swapInfo.amount = swapInfo.amount - calls[i].amount;
            if (!swapInfo.isFromNative) {
                IERC20(swapInfo.srcToken).safeApprove(
                    calls[i].targetExchange,
                    0
                );
                IERC20(swapInfo.srcToken).safeApprove(
                    calls[i].targetExchange,
                    calls[i].amount
                );
            }
            {
                bool success;
                if (swapInfo.isFromNative) {
                    success = _executeTrade(
                        calls[i].targetExchange,
                        calls[i].amount,
                        calls[i].data
                    );
                } else {
                    success = _executeTrade(
                        calls[i].targetExchange,
                        0,
                        calls[i].data
                    );
                }
                require(success, "Call-Failed");
            }
        }

        if (swapInfo.srcToken != stable && swapInfo.amount > 0) {
            if (swapInfo.isFromNative) {
                swapInfo.nativeFee += swapInfo.amount;
            } else {
                // return diff amount
                IERC20(swapInfo.srcToken).safeTransfer(
                    msg.sender,
                    swapInfo.amount
                );
            }
        }

        uint256 bridgeAmount = IERC20(stable).balanceOf(address(this)) -
            balanceStableBefore;
        require(bridgeAmount > 0, "Something-went-wrong");
        bytes memory payload = abi.encode(
            (bridgeAmount * 10**chainStableDecimal[swapInfo.dstChain]) /
                10**stableDecimal,
            msg.sender,
            dstCalls
        );
        ILayerZeroEndpoint(layerZeroEndpoint).send{value: swapInfo.nativeFee}(
            swapInfo.dstChain,
            abi.encodePacked(destAddr[swapInfo.dstChain], address(this)),
            payload,
            payable(msg.sender),
            address(0),
            swapInfo.adapterParams
        );

        emit CrossChainSwapped(swapInfo.dstChain, msg.sender, bridgeAmount);
    }

    function swapSTG(
        CrossChainSwapSg memory swapInfo,
        SwapCall[] memory calls,
        SwapCall[] memory dstCalls
    ) external payable nonReentrant {
        require(
            poolToStableAddr[swapInfo.srcPool] != address(0),
            "Invalid-pool-Id"
        );
        require(destAddr[swapInfo.dstChain] != address(0), "Invalid-address");
        uint256 balanceStableBefore = IERC20(poolToStableAddr[swapInfo.srcPool])
            .balanceOf(address(this));
        if (!swapInfo.isFromNative) {
            IERC20(swapInfo.srcToken).safeTransferFrom(
                msg.sender,
                address(this),
                swapInfo.amount
            );
        } else {
            require(
                msg.value >= swapInfo.amount + swapInfo.nativeFee,
                "Invalid-amount"
            );
        }

        for (uint8 i = 0; i < calls.length; i++) {
            require(calls[i].amount != 0, "Invalid-trade-amount");
            require(
                isWhiteListedDex(calls[i].targetExchange),
                "Not-verified-dex"
            );
            swapInfo.amount = swapInfo.amount - calls[i].amount;
            if (!swapInfo.isFromNative) {
                IERC20(swapInfo.srcToken).safeApprove(
                    calls[i].targetExchange,
                    0
                );
                IERC20(swapInfo.srcToken).safeApprove(
                    calls[i].targetExchange,
                    calls[i].amount
                );
            }
            {
                bool success;
                if (swapInfo.isFromNative) {
                    success = _executeTrade(
                        calls[i].targetExchange,
                        calls[i].amount,
                        calls[i].data
                    );
                } else {
                    success = _executeTrade(
                        calls[i].targetExchange,
                        0,
                        calls[i].data
                    );
                }
                require(success, "Call-Failed");
            }
        }
        if (
            swapInfo.srcToken != poolToStableAddr[swapInfo.srcPool] &&
            calls.length > 0 &&
            swapInfo.amount > 0
        ) {
            if (swapInfo.isFromNative) {
                swapInfo.nativeFee += swapInfo.amount;
            } else {
                // return diff amount
                IERC20(swapInfo.srcToken).safeTransfer(
                    msg.sender,
                    swapInfo.amount
                );
            }
        }
        // Stargate's Router.swap() function sends the tokens to the destination chain.
        {
            uint256 balanceStableAfter = IERC20(
                poolToStableAddr[swapInfo.srcPool]
            ).balanceOf(address(this));
            uint256 amount = balanceStableAfter - balanceStableBefore;
            bytes memory payload = abi.encode(
                msg.sender,
                dstCalls,
                swapInfo.isAmountOut
            );
            _sendCrossChain(
                swapInfo.dstChain,
                swapInfo.srcPool,
                swapInfo.dstPool,
                msg.sender,
                swapInfo.nativeFee,
                amount,
                destAddr[swapInfo.dstChain],
                payload
            );
            emit CrossChainSwapped(swapInfo.dstChain, msg.sender, amount);
        }
    }

    function _sendCrossChain(
        uint16 dstChain,
        uint16 srcPool,
        uint16 dstPool,
        address feeReceiver,
        uint256 fee,
        uint256 amount,
        address to,
        bytes memory payload
    ) private {
        IStargateRouter(stargateRouter).swap{value: fee}(
            dstChain, // the destination chain id
            srcPool, // the source Stargate poolId
            dstPool, // the destination Stargate poolId
            payable(feeReceiver), // refund adddress. if msg.sender pays too much gas, return extra eth
            amount, // total amount of stable coin send to destination chain
            (amount * 995) / 1000, // minimum // 0.5% slipapge
            IStargateRouter.lzTxObj(dstGas, 0, bytes("")), // 500,000 for the sgReceive()
            abi.encodePacked(to), // destination address, the sgReceive() implementer
            payload // bytes payload
        );
    }

    // receive the bytes payload from the source chain via LayerZero
    // _srcChainId: the chainId that we are receiving the message from.
    // _fromAddress: the source PingPong address
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) external override {
        require(msg.sender == address(layerZeroEndpoint), "Only-lz-endpoint"); // boilerplate! lzReceive must be called by the endpoint for security
        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        require(
            _fromAddress.length == trustedRemote.length &&
                keccak256(_fromAddress) == keccak256(trustedRemote),
            "Only-trusted-remote"
        );
        //    bytes memory payload = abi.encode(
        //         (bridgeAmount * 10**chainStableDecimal[swapInfo.dstChain]) /
        //             10**stableDecimal,
        //         msg.sender,
        //         dstCalls
        //     );
        (uint256 amount, address user, SwapCall[] memory dstCalls) = abi.decode(
            _payload,
            (uint256, address, SwapCall[])
        );

        if (dstCalls.length == 0) {
            // user doesnt want to swap, want to take stable
            IERC20(stable).safeTransfer(user, amount);
            return;
        }
        uint256 balanceStableBefore = IERC20(stable).balanceOf(address(this));
        for (uint8 i = 0; i < dstCalls.length; i++) {
            require(dstCalls[i].amount != 0, "Invalid-trade-amount");
            require(
                isWhiteListedDex(dstCalls[i].targetExchange),
                "Not-verified-dex"
            );
            IERC20(stable).safeApprove(dstCalls[i].targetExchange, 0);
            IERC20(stable).safeApprove(
                dstCalls[i].targetExchange,
                dstCalls[i].amount
            );
            _executeTrade(dstCalls[i].targetExchange, 0, dstCalls[i].data);
        }

        unchecked {
            uint256 diff = IERC20(stable).balanceOf(address(this)) +
                amount -
                balanceStableBefore;
            require(diff >= 0, "Lost-token");
            if (diff > 0) {
                IERC20(stable).safeTransfer(user, diff);
            }
        }

        emit CrossChainSwapped(_srcChainId, user, amount);
    }

    //-----------------------------------------------------------------------------------------------------------------------
    // sgReceive() - the destination contract must implement this function to receive the tokens and payload
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        require(msg.sender == address(stargateRouter), "Only-Stargate-Router");
        (address user, SwapCall[] memory dstCalls, bool isAmountOut) = abi
            .decode(payload, (address, SwapCall[], bool));
        if (dstCalls.length == 0) {
            // user doesnt want to swap, want to take stable
            IERC20(_token).safeTransfer(user, amountLD);
            return;
        }
        uint256 balanceStableBefore = IERC20(_token).balanceOf(address(this));
        for (uint8 i = 0; i < dstCalls.length; i++) {
            require(dstCalls[i].amount != 0, "Invalid-trade-amount");
            require(
                isWhiteListedDex(dstCalls[i].targetExchange),
                "Not-verified-dex"
            );
            IERC20(_token).safeApprove(dstCalls[i].targetExchange, 0);
            if (isAmountOut) {
                IERC20(_token).safeApprove(
                    dstCalls[i].targetExchange,
                    amountLD
                );
            } else {
                IERC20(_token).safeApprove(
                    dstCalls[i].targetExchange,
                    dstCalls[i].amount
                );
            }
            _executeTrade(dstCalls[i].targetExchange, 0, dstCalls[i].data);
        }

        unchecked {
            uint256 diff = IERC20(_token).balanceOf(address(this)) +
                amountLD -
                balanceStableBefore;
            require(diff >= 0, "Lost-token");
            if (diff > 0) {
                IERC20(_token).safeTransfer(user, diff);
            }
        }

        emit CrossChainSwapped(_chainId, user, amountLD);
    }

    function setConfig(
        uint16, /*_version*/
        uint16 _dstChainId,
        uint256 _configType,
        bytes memory _config
    ) external override onlyOwner {
        ILayerZeroEndpoint(layerZeroEndpoint).setConfig(
            _dstChainId,
            ILayerZeroEndpoint(layerZeroEndpoint).getSendVersion(address(this)),
            _configType,
            _config
        );
    }

    function getConfig(
        uint16, /*_dstChainId*/
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return
            ILayerZeroEndpoint(layerZeroEndpoint).getConfig(
                ILayerZeroEndpoint(layerZeroEndpoint).getSendVersion(
                    address(this)
                ),
                _chainId,
                address(this),
                _configType
            );
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        ILayerZeroEndpoint(layerZeroEndpoint).setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        ILayerZeroEndpoint(layerZeroEndpoint).setReceiveVersion(version);
    }

    function getSendVersion() external view returns (uint16) {
        return
            ILayerZeroEndpoint(layerZeroEndpoint).getSendVersion(address(this));
    }

    function getReceiveVersion() external view returns (uint16) {
        return
            ILayerZeroEndpoint(layerZeroEndpoint).getReceiveVersion(
                address(this)
            );
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        ILayerZeroEndpoint(layerZeroEndpoint).forceResumeReceive(
            _srcChainId,
            _srcAddress
        );
    }

    // *** SWAP ***
    function swap(
        SwapCall[] memory calls,
        SwapGeneralInfo memory info,
        PermitERC20 memory permitERC20,
        PermitERC20DAI memory permitERC20DAI
    ) external payable whenNotPaused nonReentrant {
        require(calls.length != 0, "Invalid-call-data");
        uint256 amountTakenIn;
        uint256 amountSwappedOut;
        if (info.isAmountOut) {
            amountTakenIn = info.amountDelta;
            amountSwappedOut = info.amount;
        } else {
            amountTakenIn = info.amount;
            amountSwappedOut = info.amountDelta;
        }
        if (msg.value != 0) {
            require(amountTakenIn == msg.value, "Invalid-ETH-amount");
        } else {
            require(amountTakenIn != 0, "Invalid-token-amount");
        }
        require(info.receiver != address(0), "Invalid-receiver");
        require(info.sender == msg.sender, "Invalid-sender");
        if (permitERC20.holder != address(0)) {
            permit(info.srcToken, permitERC20);
        } else if (permitERC20DAI.holder != address(0)) {
            permitDAI(info.srcToken, permitERC20DAI);
        }

        address user = info.sender;
        ContractStatus memory contractStaus = ContractStatus(0, 0, 0, 0);

        if (msg.value == 0) {
            IERC20(info.srcToken).safeTransferFrom(
                user,
                address(this),
                amountTakenIn
            );
        }

        if (info.isAmountOut) {
            if (info.srcToken != address(0)) {
                // swap to token
                contractStaus.balanceSrcBefore = IERC20(info.srcToken)
                    .balanceOf(address(this));
            } else {
                // swap to ETH
                contractStaus.balanceSrcBefore = address(this).balance; // eth balance of contract
            }
        }

        if (info.dstToken != address(0)) {
            // swap to token
            contractStaus.balanceDstBefore = IERC20(info.dstToken).balanceOf(
                address(this)
            );
        } else {
            // swap to ETH
            contractStaus.balanceDstBefore = address(this).balance; // eth balance of contract
        }

        for (uint8 i = 0; i < calls.length; i++) {
            require(calls[i].amount != 0, "Invalid-trade-amount");
            require(
                isWhiteListedDex(calls[i].targetExchange),
                "Not-verified-dex"
            );
            bool success;
            if (msg.value != 0) {
                // trade ETH
                success = _executeTrade(
                    calls[i].targetExchange,
                    amountTakenIn,
                    calls[i].data
                );
            } else {
                // trade ERC20
                IERC20(info.srcToken).safeApprove(calls[i].targetExchange, 0);
                IERC20(info.srcToken).safeApprove(
                    calls[i].targetExchange,
                    amountTakenIn
                );

                success = _executeTrade(
                    calls[i].targetExchange,
                    0,
                    calls[i].data
                );
            }
            require(success, "Call-Failed");
        }

        if (info.isAmountOut) {
            if (info.dstToken != address(0)) {
                // swap to token
                contractStaus.balanceSrcAfter = IERC20(info.srcToken).balanceOf(
                    address(this)
                );
            } else {
                // swap to ETH
                contractStaus.balanceSrcAfter = address(this).balance; // eth balance of contract
            }
        }

        if (info.dstToken != address(0)) {
            // swap to token
            contractStaus.balanceDstAfter = IERC20(info.dstToken).balanceOf(
                address(this)
            );
        } else {
            // swap to ETH
            contractStaus.balanceDstAfter = address(this).balance; // eth balance of contract
        }
        uint256 totalDstAmount = contractStaus.balanceDstAfter -
            contractStaus.balanceDstBefore;
        require(
            totalDstAmount >= amountSwappedOut,
            "Return amount is not enough"
        );
        uint256 actualTakenIn;
        if (info.isAmountOut) {
            actualTakenIn =
                contractStaus.balanceSrcBefore -
                contractStaus.balanceSrcAfter;
            if (info.srcToken != address(0)) {
                IERC20(info.srcToken).safeTransfer(
                    msg.sender,
                    contractStaus.balanceSrcAfter
                );
            } else {
                payable(msg.sender).sendValue(contractStaus.balanceSrcAfter);
            }
        } else {
            actualTakenIn = info.amount;
        }

        if (info.dstToken != address(0)) {
            IERC20(info.dstToken).safeTransfer(info.receiver, totalDstAmount);
        } else {
            payable(info.receiver).sendValue(totalDstAmount);
        }
        emit Swapped(
            actualTakenIn,
            totalDstAmount,
            info.srcToken,
            info.dstToken,
            info.receiver,
            info.sender
        );
    }

    function _executeTrade(
        address _targetExchange,
        uint256 _nativeAmount,
        bytes memory _data
    ) internal returns (bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _targetExchange.call{value: _nativeAmount}(_data);
        return success;
    }
}

//SPDX-License-Identifier: UNLISENCED
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/IController.sol";

abstract contract Controller is
    OwnableUpgradeable,
    PausableUpgradeable,
    IController
{
    mapping(address => bool) private _isVerified;

    function __Controller_init_() internal onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    function whiteListDex(address _exchangeAddr, bool _verification)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(_exchangeAddr != address(0), "Zero-address");
        _isVerified[_exchangeAddr] = _verification;
        return (_verification);
    }

    function whiteListDexes(
        address[] memory _dexes,
        bool[] memory _verifications
    ) external onlyOwner {
        for (uint8 i = 0; i < _dexes.length; i++) {
            require(_dexes[i] != address(0), "Zero-address");
            _isVerified[_dexes[i]] = _verifications[i];
        }
    }

    function adminPause() external override onlyOwner {
        _pause();
    }

    function adminUnPause() external override onlyOwner {
        _unpause();
    }

    function isWhiteListedDex(address _exchangeAddr)
        public
        view
        override
        returns (bool)
    {
        return _isVerified[_exchangeAddr];
    }
}

abstract contract EthReceiver {
    receive() external payable {
        require(msg.sender != tx.origin, "Rejected");
    }
}

interface IUnizenDexAggr {
    struct SwapCall {
        address targetExchange;
        uint256 amount;
        bytes data; // Encoded data to execute the trade by contract call
    }

    struct SwapGeneralInfo {
        address sender; // Sender address
        address receiver; // Receiver address
        address srcToken; //Input token
        address dstToken; //Output token
        uint256 amount; // for exactIn this is inAmount for exactOut this is outAmount
        uint256 amountDelta; // for exactIn this is amountOutMin for exactOut this is amountInMax
        bool isAmountOut; // true if the swap is exactOut
    }

    struct CrossChainSwapLz {
        uint16 dstChain; // dstChainId in LZ - not network chain id
        bool isFromNative;
        uint256 amount; // trade amount of srcToken
        uint256 nativeFee; // fee to LZ
        address srcToken;
        bytes adapterParams;
    }

    struct CrossChainSwapSg {
        uint16 dstChain; // dstChainId in LZ - not network chain id
        uint16 srcPool; // src stable pool id
        uint16 dstPool; // dst stable pool id
        bool isFromNative;
        address srcToken;
        uint256 amount;
        uint256 nativeFee; // fee to LZ
        bool isAmountOut; // true if the swap is exactOut
    }

    struct SplitTrade {
        uint16 dstChain; // dstChainId in LZ - not network chain id
        uint16 srcPool; // src stable pool id
        uint16 dstPool; // dst stable pool id
        uint256[2] amount; // amount of srcToken
        uint256 bridgeAmount; // amount of stable token want to swap to destination chain
        uint256 amountOutMinSrc;
        uint256 amountOutMin; // amountOutMin on destination chain
        uint256 nativeFee; // fee to LZ
        address[] pathToken; // path to token out
        address[] pathStable; // path to stable
        address[] pathDstChain; // path trade on dst chain
    }

    struct CallBackTrade {
        uint16 dstChain; // dstChainId in LZ - not network chain id
        uint16 srcPool; // src stable pool id
        uint16 dstPool; // dst stable pool id
        uint256 amount; // amount of srcToken
        uint256 amountOutMinSrc;
        uint256 nativeFee; // fee to LZ
        address[] dstExchange;
        bytes[] dstExchangeData;
        address[] pathSrcChain; // path to stable
    }

    struct ContractStatus {
        uint256 balanceDstBefore;
        uint256 balanceDstAfter;
        uint256 balanceSrcBefore;
        uint256 balanceSrcAfter;
    }

    event Swapped(
        uint256 amountIn,
        uint256 amountOut,
        address srcToken,
        address dstToken,
        address receiver,
        address sender
    );

    event CrossChainSwapped(uint16 chainId, address user, uint256 valueInUSD);
}

import "./../interfaces/IPermit.sol";

contract PermitApprove {
    struct PermitERC20 {
        address holder;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitERC20DAI {
        address holder;
        address spender;
        uint256 nonce;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
        bool allowed;
        uint8 v;
    }

    /**
     *@dev permit like DAI
     */
    function permitDAI(address tokenAddress, PermitERC20DAI memory permitData)
        internal
    {
        IPermit(tokenAddress).permit(
            permitData.holder,
            permitData.spender,
            permitData.nonce,
            permitData.deadline,
            permitData.allowed,
            permitData.v,
            permitData.r,
            permitData.s
        );
    }

    /**
     *@dev permit from IERC20Permit - OZ
     */
    function permit(address tokenAddress, PermitERC20 memory permitData)
        internal
    {
        IPermit(tokenAddress).permit(
            permitData.holder,
            permitData.spender,
            permitData.value,
            permitData.deadline,
            permitData.v,
            permitData.r,
            permitData.s
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

interface IController {
    function whiteListDex(address, bool) external returns(bool);
    function adminPause() external; 
    function adminUnPause() external;
    function isWhiteListedDex(address) external returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

interface IPermit {
    /**
     *@dev permit like DAI
     */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     *@dev permit from IERC20Permit - OZ
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}