/**
 *Submitted for verification at snowtrace.io on 2022-09-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface TokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (Executor executor);

    function srcDefaultFees(uint256 _targetChainId) external view returns (uint256 baseFees, uint256 feesPerByte);
}

interface Executor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

contract DataTest is ReentrancyGuard {
    struct Action {
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
    }

    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    struct TargetMessage {
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }

    struct KeyValuePair {
        uint256 key;
        uint256 value;
    }

    struct OptionalValue {
        bool isSet;
        uint256 value;
    }

    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant CHAIN_ID_WILDCARD = 0;

    address public owner;

    CallProxy public immutable callProxy;
    Executor public immutable executor;

    uint256[] public vaultTypes;
    mapping(uint256 => address) public vaults;
    mapping(uint256 => address) public vaultAssets;
    mapping(uint256 => mapping(uint256 => OptionalValue)) vaultDecimalsTable; // keys: vault type, chain id

    uint256[] public peerChainIds;
    mapping(uint256 => address) public peers;

    mapping(uint256 => address) public routers;
    mapping(address => bool) public managers;
    mapping(address => bool) public whitelist;

    uint256 public systemFee;

    uint256 private constant systemFeeFactor = 1e5;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "owner"
        );

        _;
    }

    modifier onlyManager {
        require(
            managers[msg.sender],
            "manager"
        );

        _;
    }

    constructor(address _callProxy) {
        require(
            _callProxy != address(0),
            "call-proxy"
        );

        owner = msg.sender;
        callProxy = CallProxy(_callProxy);
        executor = callProxy.executor();
    }

    receive() external payable {
    }

    fallback() external {
    }

    function setVault(uint256 _vaultType, address _vaultAddress, address _vaultAssetAddress) external onlyManager {
        require(
            _vaultAddress != address(0),
            "vault-address"
        );

        require(
            _vaultAssetAddress != address(0),
            "vault-asset-address"
        );
        
        if (vaults[_vaultType] == address(0)) {
            vaultTypes.push(_vaultType);
        }

        vaults[_vaultType] = _vaultAddress;
        vaultAssets[_vaultType] = _vaultAssetAddress;
    }

    function setVaultCustomDecimals(uint256 _vaultType, KeyValuePair[] calldata _customDecimals) external onlyManager {
        require(
            vaults[_vaultType] != address(0),
            "vault"
        );

        for (uint256 index; index < _customDecimals.length; index++) {
            KeyValuePair calldata customDecimalsItem = _customDecimals[index];
            vaultDecimalsTable[_vaultType][customDecimalsItem.key] = OptionalValue(true, customDecimalsItem.value);
        }
    }

    function unsetVaultCustomDecimals(uint256 _vaultType, uint256[] calldata _chainIds) external onlyManager {
        require(
            vaults[_vaultType] != address(0),
            "vault"
        );

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }
    }

    function removeVault(uint256 _vaultType) external onlyManager {
        delete vaults[_vaultType];
        delete vaultAssets[_vaultType];
        removeArrayValue(vaultTypes, _vaultType);

        delete vaultDecimalsTable[_vaultType][CHAIN_ID_WILDCARD];

        uint256 peerChainIdsLength = peerChainIds.length;

        for (uint256 index; index < peerChainIdsLength; index++) {
            uint256 peerChainId = peerChainIds[index];

            delete vaultDecimalsTable[_vaultType][peerChainId];
        }
    }

    function setPeer(uint256 _chainId, address _peerAddress) external onlyManager {
        require(
            _peerAddress != address(0),
            "peer-address"
        );

        if (peers[_chainId] == address(0)) {
            peerChainIds.push(_chainId);
        }

        peers[_chainId] = _peerAddress;
    }

    function removePeer(uint256 _chainId) external onlyManager {
        delete peers[_chainId];
        removeArrayValue(peerChainIds, _chainId);

        uint256 vaultTypesLength = vaultTypes.length;

        for (uint256 index; index < vaultTypesLength; index++) {
            uint256 vaultType = vaultTypes[index];

            delete vaultDecimalsTable[vaultType][_chainId];
        }
    }

    function setRouter(uint256 _routerType, address _routerAddress) external onlyManager {
        require(
            _routerAddress != address(0),
            "router-address"
        );

        routers[_routerType] = _routerAddress;
    }

    function removeRouter(uint256 _routerType) external onlyManager {
        delete routers[_routerType];
    }

    function setManager(address _managerAddress, bool _value) external onlyOwner {
        managers[_managerAddress] = _value;
    }

    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        whitelist[_whitelistAddress] = _value;
    }

    function setSystemFee(uint256 _systemFee) external onlyManager {
        require(
            _systemFee <= systemFeeFactor,
            "system-fee-value"
        );

        systemFee = _systemFee;
    }

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function execute(Action calldata _action) external payable nonReentrant {
        address vaultAddress = vaults[_action.vaultType];
        address vaultAssetAddress = vaultAssets[_action.vaultType];

        require(
            vaultAddress != address(0) && vaultAssetAddress != address(0),
            "vault-address"
        );

        uint256 initialBalance = address(this).balance - msg.value; 

        uint256 processedAmount = _processSource(_action.sourceTokenAddress, vaultAssetAddress, _action.sourceSwapInfo);
        uint256 targetVaultAmountMax = targetVaultAmount(_action.vaultType, _action.targetChainId, processedAmount);

        SwapInfo memory targetSwapInfo;

        uint256 targetOptionsLength = _action.targetSwapInfoOptions.length;

        if (targetOptionsLength != 0) {
            for (uint256 index; index < targetOptionsLength; index++) {
                SwapInfo memory targetSwapInfoOption = _action.targetSwapInfoOptions[index];

                if (targetSwapInfoOption.fromAmount <= targetVaultAmountMax) {
                    targetSwapInfo = targetSwapInfoOption;
                    break;
                }
            }

            require(
                targetSwapInfo.fromAmount != 0,
                "target-swap-info"
            );
        } else {
            targetSwapInfo = SwapInfo({
                fromAmount: targetVaultAmountMax,
                routerType: uint256(0),
                routerData: new bytes(0)
            });
        }

        if (_action.targetChainId == block.chainid) {
            _processTarget(
                vaultAssetAddress,
                _action.targetTokenAddress,
                targetSwapInfo,
                _action.targetRecipient
            );
        } else {
            uint256 sourceVaultAmount = _convertVaultDecimals(_action.vaultType, targetSwapInfo.fromAmount, _action.targetChainId, block.chainid);

            safeTransfer(vaultAssetAddress, vaultAddress, sourceVaultAmount);

            TargetMessage memory targetMessage = TargetMessage({
                vaultType: _action.vaultType,
                targetTokenAddress: _action.targetTokenAddress,
                targetSwapInfo: targetSwapInfo,
                targetRecipient: _action.targetRecipient
            });

            _notifyTarget(_action.targetChainId, abi.encode(targetMessage));
        }

        uint256 extraBalance = address(this).balance - initialBalance;

        if (extraBalance > 0) {
            safeTransferNative(msg.sender, extraBalance);
        }
    }

    function anyExecute(bytes memory _data) external nonReentrant returns (bool success, bytes memory result) {
        require(
            msg.sender == address(executor),
             "msg-sender"
        );

        (address from, uint256 fromChainId,) = executor.context();

        require(
            fromChainId != 0 && from == peers[fromChainId],
             "caller"
        );

        TargetMessage memory targetMessage = abi.decode(_data, (TargetMessage));

        address vaultAddress = vaults[targetMessage.vaultType];
        address vaultAssetAddress = vaultAssets[targetMessage.vaultType];

        require(
            vaultAddress != address(0) && vaultAssetAddress != address(0),
            "vault-address"
        );

        safeTransferFrom(vaultAssetAddress, vaultAddress, address(this), targetMessage.targetSwapInfo.fromAmount);

        _processTarget(
            vaultAssetAddress,
            targetMessage.targetTokenAddress,
            targetMessage.targetSwapInfo,
            targetMessage.targetRecipient
        );

        success = true;
        result = "";
    }

    function targetVaultAmount(uint256 _vaultType, uint256 _targetChainId, uint256 _sourceVaultAmount) public view returns (uint256) {
        uint256 amount = whitelist[msg.sender] ?
            _sourceVaultAmount :
            _sourceVaultAmount * (systemFeeFactor - systemFee) / systemFeeFactor;

        return _convertVaultDecimals(_vaultType, amount, block.chainid, _targetChainId);    
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return erc20TokenBalance(_tokenAddress);
        }
    }

    function erc20TokenBalance(address _tokenAddress) public view returns (uint256) {
        return TokenBalance(_tokenAddress).balanceOf(address(this));
    }

    function messageFeeEstimate(uint256 _targetChainId, bytes[] calldata _targetRouterDataOptions) public view returns (uint256) {
        if (_targetChainId == block.chainid) {
            return 0;
        }

        uint256 result = 0;

        for (uint256 index; index < _targetRouterDataOptions.length; index++) {
            bytes calldata targetRouterData = _targetRouterDataOptions[index];

            bytes memory messageData = abi.encode(
                TargetMessage({
                    vaultType: uint256(0),
                    targetTokenAddress: address(0),
                    targetSwapInfo: SwapInfo({
                        fromAmount: uint256(0),    
                        routerType: uint256(0),
                        routerData: targetRouterData
                    }),
                    targetRecipient: address(0)
                })
            );

            uint256 value = _messageFeeInternal(_targetChainId, messageData.length);

            if (value > result) {
                result = value;
            }
        }

        return result;
    }

    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][_chainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        OptionalValue storage wildcardOptionalValue = vaultDecimalsTable[_vaultType][CHAIN_ID_WILDCARD];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return 18;
    }

    function _processSource(address _sourceTokenAddress, address _vaultAssetAddress, SwapInfo memory _sourceSwapInfo) private returns (uint256 resultAmount) {
        uint256 vaultAssetBalanceBefore = erc20TokenBalance(_vaultAssetAddress);

        if (_sourceTokenAddress == NATIVE_TOKEN_ADDRESS) {
            address router = routers[_sourceSwapInfo.routerType];

            require(
                router != address(0),
                "source-router"
            );

            (bool success, ) = payable(router).call{value: _sourceSwapInfo.fromAmount}(_sourceSwapInfo.routerData);

            require(
                success,
                "source-swap"
            );
        } else {
            safeTransferFrom(_sourceTokenAddress, msg.sender, address(this), _sourceSwapInfo.fromAmount);
            
            if (_sourceTokenAddress != _vaultAssetAddress) {
                address router = routers[_sourceSwapInfo.routerType];

                require(
                    router != address(0),
                    "source-router"
                );

                safeApprove(_sourceTokenAddress, router, 0);
                safeApprove(_sourceTokenAddress, router, _sourceSwapInfo.fromAmount);

                (bool success, ) = router.call(_sourceSwapInfo.routerData);

                require(
                    success,
                    "source-swap"
                );

                safeApprove(_sourceTokenAddress, router, 0);
            }
        }

        uint256 vaultAssetBalanceAfter = erc20TokenBalance(_vaultAssetAddress);
        return vaultAssetBalanceAfter - vaultAssetBalanceBefore;
    }

    function _processTarget(address _vaultAssetAddress, address _targetTokenAddress, SwapInfo memory _targetSwapInfo, address _targetRecipient) private {
        if (_targetTokenAddress == _vaultAssetAddress) {
            safeTransfer(_targetTokenAddress, _targetRecipient, _targetSwapInfo.fromAmount);
        } else {
            uint256 targetTokenBalanceBefore = tokenBalance(_targetTokenAddress);

            address router = routers[_targetSwapInfo.routerType];

            require(
                router != address(0),
                "target-router"
            );

            safeApprove(_vaultAssetAddress, router, 0);
            safeApprove(_vaultAssetAddress, router, _targetSwapInfo.fromAmount);

            (bool success, ) = router.call(_targetSwapInfo.routerData);

            require(
                success,
                "target-swap"
            );

            safeApprove(_vaultAssetAddress, router, 0);

            uint256 targetTokenBalanceAfter = tokenBalance(_targetTokenAddress);
            uint256 amount = targetTokenBalanceAfter - targetTokenBalanceBefore;

            if (_targetTokenAddress == NATIVE_TOKEN_ADDRESS) {
                safeTransferNative(_targetRecipient, amount);
            } else {
                safeTransfer(_targetTokenAddress, _targetRecipient, amount);
            }
        }
    }

    function _notifyTarget(uint256 _targetChainId, bytes memory _message) private {
        address peer = peers[_targetChainId];

        require(
            peer != address(0),
            "peer"
        );

        uint256 callFee = _messageFeeInternal(_targetChainId, _message.length);

        callProxy.anyCall{value : callFee}(
            peer,
            _message,
            address(0), // no fallback
            _targetChainId,
            2 // fees paid on source chain
        );
    }

    function _messageFeeInternal(uint256 _targetChainId, uint256 _messageSizeInBytes) private view returns (uint256) {
        (uint256 baseFees, uint256 feesPerByte) = callProxy.srcDefaultFees(_targetChainId);
 
        return baseFees + feesPerByte * _messageSizeInBytes;
    }

    function _convertVaultDecimals(uint256 _vaultType, uint256 _amount, uint256 _fromChainId, uint256 _toChainId) private view returns (uint256) {
        if (_toChainId == _fromChainId) {
            return _amount;
        }

        uint256 fromDecimals = vaultDecimals(_vaultType, _fromChainId);
        uint256 toDecimals = vaultDecimals(_vaultType, _toChainId);

        if (fromDecimals == toDecimals) {
            return _amount;
        }

        return _amount * 10 ** fromDecimals / 10 ** toDecimals;
    }


    // Safe transfer functions
    
    function safeApprove(address _token, address _to, uint256 _value) private {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-approve"
        );
    }

    function safeTransfer(address _token, address _to, uint256 _value) private {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer"
        );
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) private {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _value));

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "safe-transfer-from"
        );
    }

    function safeTransferNative(address _to, uint256 _value) private {
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        require(
            success,
            "safe-transfer-native"
        );
    }


    // Data structure helper functions

    function removeArrayValue(uint256[] storage _array, uint256 _value) private {
        uint256 arrayLength = _array.length;

        for (uint256 index; index < arrayLength; index++) {
            if (_array[index] == _value) {
                _array[index] = _array[arrayLength - 1];
                _array.pop();

                break;
            }
        }
    }
}