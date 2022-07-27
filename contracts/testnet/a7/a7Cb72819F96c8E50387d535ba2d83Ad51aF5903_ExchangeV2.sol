// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../transfer-manager/BridgeTowerTransferManager.sol";

import "../securitize/WhitelistableUpgradeable.sol";

import "./ExchangeV2Core.sol";

contract ExchangeV2 is
    ExchangeV2Core,
    BridgeTowerTransferManager,
    WhitelistableUpgradeable
{
    function __ExchangeV2_init(
        address transferProxy,
        address erc20TransferProxy,
        uint256 newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider,
        address securitizeRegistryProxy,
        address contractsRegistryProxy
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __TransferExecutor_init_unchained(transferProxy, erc20TransferProxy);
        __BridgeTowerTransferManager_init_unchained(
            newProtocolFee,
            newDefaultFeeReceiver,
            newRoyaltiesProvider
        );
        __OrderValidator_init_unchained();
        __Whitelistable_init_unchained(
            securitizeRegistryProxy,
            contractsRegistryProxy
        );
    }

    function cancel(LibOrder.Order memory order) public override {
        onlyWhitelistedAddress(_msgSender());

        super.cancel(order);
    }

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) public payable override {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(orderLeft.maker);
        onlyWhitelistedAddress(orderRight.maker);

        if (orderLeft.taker != address(0)) {
            onlyWhitelistedAddress(orderLeft.taker);
        }
        if (orderRight.taker != address(0)) {
            onlyWhitelistedAddress(orderRight.taker);
        }

        require(
            isValidPaymentAssetType(orderLeft.makeAsset.assetType) ||
                isValidPaymentAssetType(orderLeft.takeAsset.assetType),
            "ExchangeV2: orderLeft - one of the payment asset isn't supported"
        );
        require(
            isValidPaymentAssetType(orderRight.makeAsset.assetType) ||
                isValidPaymentAssetType(orderRight.takeAsset.assetType),
            "ExchangeV2: orderRight - one of the payment asset isn't supported"
        );

        super.matchOrders(orderLeft, signatureLeft, orderRight, signatureRight);
    }

    function setAssetMatcher(bytes4 assetType, address matcher)
        public
        override
    {
        onlyWhitelistedAddress(_msgSender());

        super.setAssetMatcher(assetType, matcher);
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver)
        public
        override
    {
        onlyWhitelistedAddress(_msgSender());

        super.setDefaultFeeReceiver(newDefaultFeeReceiver);
    }

    function setFeeReceiver(address token, address wallet) public override {
        onlyWhitelistedAddress(_msgSender());

        super.setFeeReceiver(token, wallet);
    }

    function setProtocolFee(uint256 newProtocolFee) public override {
        onlyWhitelistedAddress(_msgSender());

        super.setProtocolFee(newProtocolFee);
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry)
        public
        override
    {
        onlyWhitelistedAddress(_msgSender());

        super.setRoyaltiesRegistry(newRoyaltiesRegistry);
    }

    function setTransferProxy(bytes4 assetType, address proxy) public override {
        onlyWhitelistedAddress(_msgSender());

        super.setTransferProxy(assetType, proxy);
    }

    function transferOwnership(address newOwner) public override {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(newOwner);

        super.transferOwnership(newOwner);
    }

    function renounceOwnership() public override {
        onlyWhitelistedAddress(_msgSender());

        super.renounceOwnership();
    }

    function whitelistPaymentToken(address token, bool whitelist)
        public
        override
    {
        onlyWhitelistedAddress(_msgSender());

        super.whitelistPaymentToken(token, whitelist);
    }

    function whitelistNativePaymentToken(bool whitelist) public override {
        onlyWhitelistedAddress(_msgSender());

        super.whitelistNativePaymentToken(whitelist);
    }

    function getProtocolFee() internal view override returns (uint256) {
        return protocolFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import "../lazy-mint/erc-1155/LibERC1155LazyMint.sol";
import "../lazy-mint/erc-721/LibERC721LazyMint.sol";

import "../royalties/IRoyaltiesProvider.sol";

import "../interfaces/ITransferManager.sol";

import "../libraries/BpLibrary.sol";

abstract contract BridgeTowerTransferManager is
    OwnableUpgradeable,
    ITransferManager
{
    using SafeMathUpgradeable for uint256;
    using BpLibrary for uint256;

    uint256 public protocolFee;

    IRoyaltiesProvider public royaltiesRegistry;

    address public defaultFeeReceiver;

    mapping(address => address) public feeReceivers;

    event ProtocolFeeChanged(uint256 oldValue, uint256 newValue);

    function __BridgeTowerTransferManager_init_unchained(
        uint256 newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) internal initializer {
        protocolFee = newProtocolFee;
        defaultFeeReceiver = newDefaultFeeReceiver;
        royaltiesRegistry = newRoyaltiesProvider;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry)
        public
        virtual
        onlyOwner
    {
        royaltiesRegistry = newRoyaltiesRegistry;
    }

    function setProtocolFee(uint256 newProtocolFee) public virtual onlyOwner {
        uint256 prevProtocolFee = protocolFee;

        protocolFee = newProtocolFee;

        emit ProtocolFeeChanged(prevProtocolFee, newProtocolFee);
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver)
        public
        virtual
        onlyOwner
    {
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    function setFeeReceiver(address token, address wallet)
        public
        virtual
        onlyOwner
    {
        feeReceivers[token] = wallet;
    }

    function getFeeReceiver(address token) internal view returns (address) {
        address wallet = feeReceivers[token];

        if (wallet != address(0)) {
            return wallet;
        }

        return defaultFeeReceiver;
    }

    function doTransfers(
        LibDeal.DealSide memory left,
        LibDeal.DealSide memory right,
        LibFeeSide.FeeSide feeSide,
        uint256 _protocolFee
    )
        internal
        override
        returns (uint256 totalLeftValue, uint256 totalRightValue)
    {
        totalLeftValue = left.asset.value;
        totalRightValue = right.asset.value;

        if (feeSide == LibFeeSide.FeeSide.LEFT) {
            totalLeftValue = doTransfersWithFees(left, right, _protocolFee);

            transferPayouts(
                right.asset.assetType,
                right.asset.value,
                right.from,
                left.payouts,
                right.proxy
            );
        } else if (feeSide == LibFeeSide.FeeSide.RIGHT) {
            totalRightValue = doTransfersWithFees(right, left, _protocolFee);

            transferPayouts(
                left.asset.assetType,
                left.asset.value,
                left.from,
                right.payouts,
                left.proxy
            );
        } else {
            transferPayouts(
                left.asset.assetType,
                left.asset.value,
                left.from,
                right.payouts,
                left.proxy
            );
            transferPayouts(
                right.asset.assetType,
                right.asset.value,
                right.from,
                left.payouts,
                right.proxy
            );
        }
    }

    function doTransfersWithFees(
        LibDeal.DealSide memory calculateSide,
        LibDeal.DealSide memory nftSide,
        uint256 _protocolFee
    ) internal returns (uint256 totalAmount) {
        totalAmount = calculateTotalAmount(
            calculateSide.asset.value,
            _protocolFee,
            calculateSide.originFees
        );

        uint256 rest = transferProtocolFee(
            totalAmount,
            calculateSide.asset.value,
            calculateSide.from,
            _protocolFee,
            _protocolFee,
            calculateSide.asset.assetType,
            calculateSide.proxy
        );

        rest = transferRoyalties(
            calculateSide.asset.assetType,
            nftSide.asset.assetType,
            nftSide.payouts,
            rest,
            calculateSide.asset.value,
            calculateSide.from,
            calculateSide.proxy
        );

        if (
            calculateSide.originFees.length == 1 &&
            nftSide.originFees.length == 1 &&
            nftSide.originFees[0].account == calculateSide.originFees[0].account
        ) {
            LibPart.Part[] memory origin = new LibPart.Part[](1);

            origin[0].account = nftSide.originFees[0].account;
            origin[0].value =
                nftSide.originFees[0].value +
                calculateSide.originFees[0].value;

            (rest, ) = transferFees(
                calculateSide.asset.assetType,
                rest,
                calculateSide.asset.value,
                origin,
                calculateSide.from,
                calculateSide.proxy
            );
        } else {
            (rest, ) = transferFees(
                calculateSide.asset.assetType,
                rest,
                calculateSide.asset.value,
                calculateSide.originFees,
                calculateSide.from,
                calculateSide.proxy
            );
            (rest, ) = transferFees(
                calculateSide.asset.assetType,
                rest,
                calculateSide.asset.value,
                nftSide.originFees,
                calculateSide.from,
                calculateSide.proxy
            );
        }

        transferPayouts(
            calculateSide.asset.assetType,
            rest,
            calculateSide.from,
            nftSide.payouts,
            calculateSide.proxy
        );
    }

    function transferProtocolFee(
        uint256 totalAmount,
        uint256 amount,
        address from,
        uint256 feeSideProtocolFee,
        uint256 nftSideProtocolFee,
        LibAsset.AssetType memory matchCalculate,
        address proxy
    ) internal returns (uint256) {
        (uint256 rest, uint256 fee) = subFeeInBp(
            totalAmount,
            amount,
            feeSideProtocolFee + nftSideProtocolFee
        );

        if (fee > 0) {
            address tokenAddress = address(0);

            if (matchCalculate.assetClass == LibAsset.ERC20_ASSET_CLASS) {
                tokenAddress = abi.decode(matchCalculate.data, (address));
            } else if (
                matchCalculate.assetClass == LibAsset.ERC1155_ASSET_CLASS
            ) {
                uint256 tokenId;

                (tokenAddress, tokenId) = abi.decode(
                    matchCalculate.data,
                    (address, uint256)
                );
            }

            transfer(
                LibAsset.Asset(matchCalculate, fee),
                from,
                getFeeReceiver(tokenAddress),
                proxy
            );
        }

        return rest;
    }

    function transferRoyalties(
        LibAsset.AssetType memory matchCalculate,
        LibAsset.AssetType memory matchNft,
        LibPart.Part[] memory payouts,
        uint256 rest,
        uint256 amount,
        address from,
        address proxy
    ) internal returns (uint256) {
        LibPart.Part[] memory fees = getRoyaltiesByAssetType(matchNft);

        if (
            fees.length == 1 &&
            payouts.length == 1 &&
            fees[0].account == payouts[0].account
        ) {
            require(fees[0].value <= 5000, "Royalties are too high (>50%)");

            return rest;
        }

        (uint256 result, uint256 totalRoyalties) = transferFees(
            matchCalculate,
            rest,
            amount,
            fees,
            from,
            proxy
        );

        require(totalRoyalties <= 5000, "Royalties are too high (>50%)");

        return result;
    }

    function getRoyaltiesByAssetType(LibAsset.AssetType memory matchNft)
        internal
        returns (LibPart.Part[] memory)
    {
        if (
            matchNft.assetClass == LibAsset.ERC1155_ASSET_CLASS ||
            matchNft.assetClass == LibAsset.ERC721_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(
                matchNft.data,
                (address, uint256)
            );

            return royaltiesRegistry.getRoyalties(token, tokenId);
        } else if (
            matchNft.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS
        ) {
            (, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(
                matchNft.data,
                (address, LibERC1155LazyMint.Mint1155Data)
            );

            return data.royalties;
        } else if (
            matchNft.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS
        ) {
            (, LibERC721LazyMint.Mint721Data memory data) = abi.decode(
                matchNft.data,
                (address, LibERC721LazyMint.Mint721Data)
            );

            return data.royalties;
        }

        LibPart.Part[] memory empty;

        return empty;
    }

    function transferFees(
        LibAsset.AssetType memory matchCalculate,
        uint256 rest,
        uint256 amount,
        LibPart.Part[] memory fees,
        address from,
        address proxy
    ) internal returns (uint256 restValue, uint256 totalFees) {
        restValue = rest;
        totalFees = 0;

        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);

            (uint256 newRestValue, uint256 feeValue) = subFeeInBp(
                restValue,
                amount,
                fees[i].value
            );

            restValue = newRestValue;

            if (feeValue > 0) {
                transfer(
                    LibAsset.Asset(matchCalculate, feeValue),
                    from,
                    fees[i].account,
                    proxy
                );
            }
        }
    }

    function transferPayouts(
        LibAsset.AssetType memory matchCalculate,
        uint256 amount,
        address from,
        LibPart.Part[] memory payouts,
        address proxy
    ) internal {
        require(payouts.length > 0, "transferPayouts: nothing to transfer");

        uint256 restValue = amount;
        uint256 sumBps = 0;

        for (uint256 i = 0; i < payouts.length - 1; i++) {
            uint256 currentAmount = amount.bp(payouts[i].value);

            sumBps = sumBps.add(payouts[i].value);

            if (currentAmount > 0) {
                restValue = restValue.sub(currentAmount);

                transfer(
                    LibAsset.Asset(matchCalculate, currentAmount),
                    from,
                    payouts[i].account,
                    proxy
                );
            }
        }

        LibPart.Part memory lastPayout = payouts[payouts.length - 1];

        sumBps = sumBps.add(lastPayout.value);

        require(sumBps == 10000, "Sum payouts Bps not equal 100%");

        if (restValue > 0) {
            transfer(
                LibAsset.Asset(matchCalculate, restValue),
                from,
                lastPayout.account,
                proxy
            );
        }
    }

    function calculateTotalAmount(
        uint256 amount,
        uint256 feeOnTopBp,
        LibPart.Part[] memory orderOriginFees
    ) internal pure returns (uint256 total) {
        total = amount.add(amount.bp(feeOnTopBp));

        for (uint256 i = 0; i < orderOriginFees.length; i++) {
            total = total.add(amount.bp(orderOriginFees[i].value));
        }
    }

    function subFeeInBp(
        uint256 value,
        uint256 total,
        uint256 feeInBp
    ) internal pure returns (uint256 newValue, uint256 realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint256 value, uint256 fee)
        internal
        pure
        returns (uint256 newValue, uint256 realFee)
    {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    function parseFeeData(uint256 data)
        internal
        pure
        returns (address, uint96)
    {
        return (address(uint160(data)), uint96(data >> 160));
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "../openzeppelin-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ISecuritizeRegistryProxy.sol";
import "./interfaces/IContractsRegistryProxy.sol";

abstract contract WhitelistableUpgradeable is OwnableUpgradeable {
    using AddressUpgradeable for address;

    address public securitizeRegistryProxy;
    address public contractsRegistryProxy;

    modifier onlyContract(address addr) {
        require(addr.isContract(), "Whitelistable: not contract address");
        _;
    }

    function __Whitelistable_init(
        address initialSecuritizeRegistryProxy,
        address initialContractsRegistryProxy
    ) internal {
        __Ownable_init_unchained();
        __Whitelistable_init_unchained(
            initialSecuritizeRegistryProxy,
            initialContractsRegistryProxy
        );
    }

    function __Whitelistable_init_unchained(
        address initialSecuritizeRegistryProxy,
        address initialContractsRegistryProxy
    )
        internal
        onlyContract(initialSecuritizeRegistryProxy)
        onlyContract(initialContractsRegistryProxy)
    {
        securitizeRegistryProxy = initialSecuritizeRegistryProxy;
        contractsRegistryProxy = initialContractsRegistryProxy;
    }

    function setSecuritizeRegistryProxy(address newSecuritizeRegistryProxy)
        external
        onlyOwner
        onlyContract(newSecuritizeRegistryProxy)
    {
        onlyWhitelistedAddress(_msgSender());

        securitizeRegistryProxy = newSecuritizeRegistryProxy;
    }

    function setContractsRegistryProxy(address newContractsRegistryProxy)
        external
        onlyOwner
        onlyContract(newContractsRegistryProxy)
    {
        onlyWhitelistedAddress(_msgSender());

        contractsRegistryProxy = newContractsRegistryProxy;
    }

    function onlyWhitelistedAddress(address addr) public view {
        require(
            ISecuritizeRegistryProxy(securitizeRegistryProxy)
                .isWhitelistedWallet(addr) ||
                IContractsRegistryProxy(contractsRegistryProxy)
                    .isWhitelistedContract(addr),
            "Whitelistable: address is not whitelisted"
        );
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/structs/EnumerableSetUpgradeable.sol";

import "../openzeppelin-upgradeable/utils/AddressUpgradeable.sol";

import "../transfer-manager/TransferExecutor.sol";

import "../interfaces/ITransferManager.sol";

import "../libraries/LibOrderData.sol";
import "../libraries/LibFeeSide.sol";
import "../libraries/BpLibrary.sol";
import "../libraries/LibFill.sol";
import "../libraries/LibDeal.sol";

import "./OrderValidator.sol";
import "./AssetMatcher.sol";

abstract contract ExchangeV2Core is
    Initializable,
    OwnableUpgradeable,
    AssetMatcher,
    TransferExecutor,
    OrderValidator,
    ITransferManager
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using LibTransfer for address;

    uint256 private constant UINT256_MAX = 2**256 - 1;

    // AVAX token is acceptable for payments in orders or not
    bool public isWhitelistedNativePaymentToken;

    // State of the orders
    mapping(bytes32 => uint256) public fills;

    // Whitelisted tokens which is acceptable for payments in orders
    EnumerableSetUpgradeable.AddressSet private whitelistedPaymentTokens;

    // Events
    event Match(uint256 newLeftFill, uint256 newRightFill);
    event Cancel(bytes32 hash);
    event WhitelistedPaymentToken(address indexed token, bool whitelisted);
    event WhitelistedNativePaymentToken(bool whitelisted);

    function whitelistPaymentToken(address token, bool whitelist)
        public
        virtual
        onlyOwner
    {
        require(token.isContract(), "ExchangeV2Core: not contract address");

        whitelist
            ? whitelistedPaymentTokens.add(token)
            : whitelistedPaymentTokens.remove(token);

        emit WhitelistedPaymentToken(token, whitelist);
    }

    function whitelistNativePaymentToken(bool whitelist)
        public
        virtual
        onlyOwner
    {
        isWhitelistedNativePaymentToken = whitelist;

        emit WhitelistedNativePaymentToken(whitelist);
    }

    function cancel(LibOrder.Order memory order) public virtual {
        require(_msgSender() == order.maker, "ExchangeV2Core: not a maker");
        require(order.salt != 0, "ExchangeV2Core: 0 salt can't be used");

        bytes32 orderKeyHash = LibOrder.hashKey(order);

        fills[orderKeyHash] = UINT256_MAX;

        emit Cancel(orderKeyHash);
    }

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) public payable virtual {
        validateFull(orderLeft, signatureLeft);
        validateFull(orderRight, signatureRight);

        if (orderLeft.taker != address(0)) {
            require(
                orderRight.maker == orderLeft.taker,
                "ExchangeV2Core: leftOrder.taker verification failed"
            );
        }

        if (orderRight.taker != address(0)) {
            require(
                orderRight.taker == orderLeft.maker,
                "ExchangeV2Core: rightOrder.taker verification failed"
            );
        }

        matchAndTransfer(orderLeft, orderRight);
    }

    function matchAndTransfer(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    ) internal {
        (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        ) = matchAssets(orderLeft, orderRight);

        bytes32 leftOrderKeyHash = LibOrder.hashKey(orderLeft);
        bytes32 rightOrderKeyHash = LibOrder.hashKey(orderRight);

        LibOrderDataV2.DataV2 memory leftOrderData = LibOrderData.parse(
            orderLeft
        );
        LibOrderDataV2.DataV2 memory rightOrderData = LibOrderData.parse(
            orderRight
        );

        LibFill.FillResult memory newFill = getFillSetNew(
            orderLeft,
            orderRight,
            leftOrderKeyHash,
            rightOrderKeyHash,
            leftOrderData.isMakeFill,
            rightOrderData.isMakeFill
        );

        (uint256 totalMakeValue, uint256 totalTakeValue) = doTransfers(
            LibDeal.DealSide(
                LibAsset.Asset(makeMatch, newFill.leftValue),
                leftOrderData.payouts,
                leftOrderData.originFees,
                proxies[orderLeft.makeAsset.assetType.assetClass],
                orderLeft.maker
            ),
            LibDeal.DealSide(
                LibAsset.Asset(takeMatch, newFill.rightValue),
                rightOrderData.payouts,
                rightOrderData.originFees,
                proxies[orderRight.makeAsset.assetType.assetClass],
                orderRight.maker
            ),
            LibFeeSide.getFeeSide(makeMatch.assetClass, takeMatch.assetClass),
            getProtocolFee()
        );

        if (makeMatch.assetClass == LibAsset.AVAX_ASSET_CLASS) {
            require(
                takeMatch.assetClass != LibAsset.AVAX_ASSET_CLASS,
                "ExchangeV2Core: wrong asset class"
            );
            require(
                msg.value >= totalMakeValue,
                "ExchangeV2Core: not enough AVAX"
            );

            if (msg.value > totalMakeValue) {
                address(msg.sender).transferAvax(msg.value.sub(totalMakeValue));
            }
        } else if (takeMatch.assetClass == LibAsset.AVAX_ASSET_CLASS) {
            require(
                msg.value >= totalTakeValue,
                "ExchangeV2Core: not enough AVAX"
            );

            if (msg.value > totalTakeValue) {
                address(msg.sender).transferAvax(msg.value.sub(totalTakeValue));
            }
        }

        emit Match(newFill.rightValue, newFill.leftValue);
    }

    function getFillSetNew(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight,
        bytes32 leftOrderKeyHash,
        bytes32 rightOrderKeyHash,
        bool leftMakeFill,
        bool rightMakeFill
    ) internal returns (LibFill.FillResult memory) {
        uint256 leftOrderFill = getOrderFill(orderLeft.salt, leftOrderKeyHash);
        uint256 rightOrderFill = getOrderFill(
            orderRight.salt,
            rightOrderKeyHash
        );

        LibFill.FillResult memory newFill = LibFill.fillOrder(
            orderLeft,
            orderRight,
            leftOrderFill,
            rightOrderFill,
            leftMakeFill,
            rightMakeFill
        );

        require(
            newFill.rightValue > 0 && newFill.leftValue > 0,
            "ExchangeV2Core: nothing to fill"
        );

        if (orderLeft.salt != 0) {
            if (leftMakeFill) {
                fills[leftOrderKeyHash] = leftOrderFill.add(newFill.leftValue);
            } else {
                fills[leftOrderKeyHash] = leftOrderFill.add(newFill.rightValue);
            }
        }

        if (orderRight.salt != 0) {
            if (rightMakeFill) {
                fills[rightOrderKeyHash] = rightOrderFill.add(
                    newFill.rightValue
                );
            } else {
                fills[rightOrderKeyHash] = rightOrderFill.add(
                    newFill.leftValue
                );
            }
        }

        return newFill;
    }

    function getOrderFill(uint256 salt, bytes32 hash)
        internal
        view
        returns (uint256 fill)
    {
        if (salt == 0) {
            fill = 0;
        } else {
            fill = fills[hash];
        }
    }

    function matchAssets(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    )
        internal
        view
        returns (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        )
    {
        makeMatch = matchAssets(
            orderLeft.makeAsset.assetType,
            orderRight.takeAsset.assetType
        );

        require(
            makeMatch.assetClass != 0,
            "ExchangeV2Core: assets don't match"
        );

        takeMatch = matchAssets(
            orderLeft.takeAsset.assetType,
            orderRight.makeAsset.assetType
        );

        require(
            takeMatch.assetClass != 0,
            "ExchangeV2Core: assets don't match"
        );
    }

    function validateFull(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        LibOrder.validate(order);

        validate(order, signature);
    }

    function isValidPaymentAssetType(LibAsset.AssetType memory assetType)
        internal
        view
        override
        returns (bool)
    {
        if (assetType.assetClass == LibAsset.AVAX_ASSET_CLASS) {
            return isWhitelistedNativePaymentToken;
        } else if (assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(assetType.data, (address));

            return isWhitelistedPaymentToken(token);
        } else if (
            assetType.assetClass == LibAsset.ERC721_ASSET_CLASS ||
            assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS
        ) {
            (address token, ) = abi.decode(assetType.data, (address, uint256));

            return isWhitelistedPaymentToken(token);
        }

        return false;
    }

    function isWhitelistedPaymentToken(address token)
        public
        view
        returns (bool)
    {
        return whitelistedPaymentTokens.contains(token);
    }

    function getProtocolFee() internal view virtual returns (uint256);

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;

import "../../royalties/LibPart.sol";

library LibERC1155LazyMint {
    /**
     * keccak256("Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)")
     */
    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        0xfb988707ebb338694f318760b0fd5cfe756d00a2ade251fda110b80c336a3c7f;

    /**
     * bytes4(keccak256("ERC1155_LAZY")) == 0x1cdfaa40
     */
    bytes4 public constant ERC1155_LAZY_ASSET_CLASS = 0x1cdfaa40;
    bytes4 internal constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

    struct Mint1155Data {
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);

        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }

        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);

        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }

        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    data.supply,
                    keccak256(bytes(data.tokenURI)),
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../royalties/LibPart.sol";

library LibERC721LazyMint {
    /**
     * keccak256("Mint721(uint256 tokenId,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)")
     */
    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        0xf64326045af5fd7e15297ba939f85b550474d3899daa47d2bc1ffbdb9ced344e;

    /**
     * bytes4(keccak256("ERC721_LAZY")) == 0xd8f960c1
     */
    bytes4 public constant ERC721_LAZY_ASSET_CLASS = 0xd8f960c1;
    bytes4 internal constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

    struct Mint721Data {
        uint256 tokenId;
        string tokenURI;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);

        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }

        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);

        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }

        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    keccak256(bytes(data.tokenURI)),
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "./LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint256 tokenId)
        external
        returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../libraries/LibFeeSide.sol";
import "../libraries/LibDeal.sol";

import "./ITransferExecutor.sol";

abstract contract ITransferManager is ITransferExecutor {
    function doTransfers(
        LibDeal.DealSide memory left,
        LibDeal.DealSide memory right,
        LibFeeSide.FeeSide feeSide,
        uint256 protocolFee
    ) internal virtual returns (uint256 totalMakeValue, uint256 totalTakeValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/utils/math/SafeMathUpgradeable.sol";

library BpLibrary {
    using SafeMathUpgradeable for uint256;

    function bp(uint256 value, uint256 bpValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(bpValue).div(10000);
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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(
                _initialized < version,
                "Initializable: contract is already initialized"
            );
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    /**
     * keccak256("Part(address account,uint96 value)") == 0x397e04204c1e1a60ee8724b71f8244e10ab5f2e9009854d80f602bda21b59ebb
     */
    bytes32 public constant TYPE_HASH =
        0x397e04204c1e1a60ee8724b71f8244e10ab5f2e9009854d80f602bda21b59ebb;

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibAsset.sol";

library LibFeeSide {
    enum FeeSide {
        NONE,
        LEFT,
        RIGHT
    }

    function getFeeSide(bytes4 leftClass, bytes4 rightClass)
        internal
        pure
        returns (FeeSide)
    {
        if (leftClass == LibAsset.AVAX_ASSET_CLASS) {
            return FeeSide.LEFT;
        }

        if (rightClass == LibAsset.AVAX_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }

        if (leftClass == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.LEFT;
        }

        if (rightClass == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }

        if (leftClass == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.LEFT;
        }

        if (rightClass == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }

        return FeeSide.NONE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../royalties/LibPart.sol";

import "./LibAsset.sol";

library LibDeal {
    struct DealSide {
        LibAsset.Asset asset;
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        address proxy;
        address from;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../libraries/LibAsset.sol";

abstract contract ITransferExecutor {
    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        address proxy
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibAsset {
    // bytes4(keccak256("AVAX")) == 0x49f18ed7
    bytes4 public constant AVAX_ASSET_CLASS = 0x49f18ed7;
    // bytes4(keccak256("ERC20")) == 0x8ae85d84
    bytes4 public constant ERC20_ASSET_CLASS = 0x8ae85d84;
    // bytes4(keccak256("ERC721")) == 0x73ad2146
    bytes4 public constant ERC721_ASSET_CLASS = 0x73ad2146;
    // bytes4(keccak256("ERC1155")) == 0x973bb640
    bytes4 public constant ERC1155_ASSET_CLASS = 0x973bb640;
    // bytes4(keccak256("COLLECTION")) == 0xf63c2825
    bytes4 public constant COLLECTION = 0xf63c2825;
    // keccak256("AssetType(bytes4 assetClass,bytes data)")
    bytes32 internal constant ASSET_TYPE_TYPEHASH =
        0x452a0dc408cb0d27ffc3b3caff933a5208040a53a9dbecd8d89cad2c0d40e00c;
    // keccak256("Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)")
    bytes32 internal constant ASSET_TYPEHASH =
        0xdb6f72e915676cfc289da13bc4ece054fd17b1df6d77ffc4a60510718c236b08;

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }
    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_TYPEHASH,
                    assetType.assetClass,
                    keccak256(assetType.data)
                )
            );
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value)
            );
    }
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

pragma solidity ^0.8.0;

interface ISecuritizeRegistryProxy {
    function setSecuritizeRegistry(address newSecuritizeRegistry) external;

    function isWhitelistedWallet(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IContractsRegistryProxy {
    function setContractsRegistry(address newContractsRegistry) external;

    function setSecuritizeRegistryProxy(address newSecuritizeRegistryProxy)
        external;

    function isWhitelistedContract(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import "../openzeppelin-upgradeable/proxy/utils/Initializable.sol";

import "../transfer-manager/lib/LibTransfer.sol";

import "../interfaces/IERC20TransferProxy.sol";
import "../interfaces/INftTransferProxy.sol";
import "../interfaces/ITransferExecutor.sol";
import "../interfaces/ITransferProxy.sol";

abstract contract TransferExecutor is
    Initializable,
    OwnableUpgradeable,
    ITransferExecutor
{
    using LibTransfer for address;

    mapping(bytes4 => address) internal proxies;

    event ProxyChange(bytes4 indexed assetType, address proxy);

    function __TransferExecutor_init_unchained(
        address transferProxy,
        address erc20TransferProxy
    ) internal {
        proxies[LibAsset.ERC20_ASSET_CLASS] = erc20TransferProxy;
        proxies[LibAsset.ERC721_ASSET_CLASS] = transferProxy;
        proxies[LibAsset.ERC1155_ASSET_CLASS] = transferProxy;
    }

    function setTransferProxy(bytes4 assetType, address proxy)
        public
        virtual
        onlyOwner
    {
        proxies[assetType] = proxy;

        emit ProxyChange(assetType, proxy);
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        address proxy
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            // Not using transfer proxy when transfering from this contract
            (address token, uint256 tokenId) = abi.decode(
                asset.assetType.data,
                (address, uint256)
            );

            require(asset.value == 1, "TransferExecutor: erc721 value error");

            if (from == address(this)) {
                IERC721Upgradeable(token).safeTransferFrom(
                    address(this),
                    to,
                    tokenId
                );
            } else {
                INftTransferProxy(proxy).erc721safeTransferFrom(
                    IERC721Upgradeable(token),
                    from,
                    to,
                    tokenId
                );
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            // Not using transfer proxy when transfering from this contract
            address token = abi.decode(asset.assetType.data, (address));

            if (from == address(this)) {
                IERC20Upgradeable(token).transfer(to, asset.value);
            } else {
                IERC20TransferProxy(proxy).erc20safeTransferFrom(
                    IERC20Upgradeable(token),
                    from,
                    to,
                    asset.value
                );
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            // Not using transfer proxy when transfering from this contract
            (address token, uint256 tokenId) = abi.decode(
                asset.assetType.data,
                (address, uint256)
            );

            if (from == address(this)) {
                IERC1155Upgradeable(token).safeTransferFrom(
                    address(this),
                    to,
                    tokenId,
                    asset.value,
                    ""
                );
            } else {
                INftTransferProxy(proxy).erc1155safeTransferFrom(
                    IERC1155Upgradeable(token),
                    from,
                    to,
                    tokenId,
                    asset.value,
                    ""
                );
            }
        } else if (asset.assetType.assetClass == LibAsset.AVAX_ASSET_CLASS) {
            if (to != address(this)) {
                to.transferAvax(asset.value);
            }
        } else {
            ITransferProxy(proxy).transfer(asset, from, to);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibOrder.sol";

library LibOrderData {
    function parse(LibOrder.Order memory order)
        internal
        pure
        returns (LibOrderDataV2.DataV2 memory dataOrder)
    {
        if (order.dataType == LibOrderDataV1.V1) {
            LibOrderDataV1.DataV1 memory dataV1 = LibOrderDataV1
                .decodeOrderDataV1(order.data);

            dataOrder.payouts = dataV1.payouts;
            dataOrder.originFees = dataV1.originFees;
            dataOrder.isMakeFill = false;
        } else if (order.dataType == LibOrderDataV2.V2) {
            dataOrder = LibOrderDataV2.decodeOrderDataV2(order.data);
        } else if (order.dataType == 0xffffffff) {} else {
            revert("LibOrderData: unknown order data type");
        }

        if (dataOrder.payouts.length == 0) {
            dataOrder.payouts = payoutSet(order.maker);
        }
    }

    function payoutSet(address orderAddress)
        internal
        pure
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory payout = new LibPart.Part[](1);

        payout[0].account = payable(orderAddress);
        payout[0].value = 10000;

        return payout;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../openzeppelin-upgradeable/utils/math/MathUpgradeable.sol";

import "./LibOrder.sol";

library LibFill {
    using SafeMathUpgradeable for uint256;

    struct FillResult {
        uint256 leftValue;
        uint256 rightValue;
    }

    struct IsMakeFill {
        bool leftMake;
        bool rightMake;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     * @param leftIsMakeFill true if left orders fill is calculated from the make side, false if from the take side
     * @param rightIsMakeFill true if right orders fill is calculated from the make side, false if from the take side
     */
    function fillOrder(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        uint256 leftOrderFill,
        uint256 rightOrderFill,
        bool leftIsMakeFill,
        bool rightIsMakeFill
    ) internal pure returns (FillResult memory) {
        (uint256 leftMakeValue, uint256 leftTakeValue) = LibOrder
            .calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
        (uint256 rightMakeValue, uint256 rightTakeValue) = LibOrder
            .calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);

        // We have 3 cases here
        if (rightTakeValue > leftMakeValue) {
            // 1nd: left order should be fully filled
            return
                fillLeft(
                    leftMakeValue,
                    leftTakeValue,
                    rightOrder.makeAsset.value,
                    rightOrder.takeAsset.value
                );
        } // 2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return
            fillRight(
                leftOrder.makeAsset.value,
                leftOrder.takeAsset.value,
                rightMakeValue,
                rightTakeValue
            );
    }

    function fillRight(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 makerValue = LibMath.safeGetPartialAmountFloor(
            rightTakeValue,
            leftMakeValue,
            leftTakeValue
        );

        require(makerValue <= rightMakeValue, "fillRight: unable to fill");

        return FillResult(rightTakeValue, makerValue);
    }

    function fillLeft(
        uint256 leftMakeValue,
        uint256 leftTakeValue,
        uint256 rightMakeValue,
        uint256 rightTakeValue
    ) internal pure returns (FillResult memory result) {
        uint256 rightTake = LibMath.safeGetPartialAmountFloor(
            leftTakeValue,
            rightMakeValue,
            rightTakeValue
        );

        require(rightTake <= leftMakeValue, "fillLeft: unable to fill");

        return FillResult(leftMakeValue, leftTakeValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "../openzeppelin-upgradeable/utils/AddressUpgradeable.sol";
import "../openzeppelin-upgradeable/utils/ContextUpgradeable.sol";

import "../libraries/LibSignature.sol";
import "../libraries/LibOrder.sol";

import "./interfaces/IERC1271.sol";

abstract contract OrderValidator is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable
{
    using AddressUpgradeable for address;
    using LibSignature for bytes32;

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Exchange", "2");
    }

    function validate(LibOrder.Order memory order, bytes memory signature)
        internal
        view
    {
        if (order.salt == 0) {
            if (order.maker != address(0)) {
                require(
                    _msgSender() == order.maker,
                    "OrderValidator: maker is not tx sender"
                );
            } else {
                order.maker = _msgSender();
            }
        } else {
            if (_msgSender() != order.maker) {
                bytes32 hash = LibOrder.hash(order);
                address signer;

                if (signature.length == 65) {
                    signer = _hashTypedDataV4(hash).recover(signature);
                }

                if (signer != order.maker) {
                    if (order.maker.isContract()) {
                        require(
                            IERC1271(order.maker).isValidSignature(
                                _hashTypedDataV4(hash),
                                signature
                            ) == MAGICVALUE,
                            "OrderValidator: contract order signature verification error"
                        );
                    } else {
                        revert(
                            "OrderValidator: order signature verification error"
                        );
                    }
                } else {
                    require(
                        order.maker != address(0),
                        "OrderValidator: no maker"
                    );
                }
            }
        }
    }

    function isValidPaymentAssetType(LibAsset.AssetType memory assetType)
        internal
        view
        virtual
        returns (bool)
    {}

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import "../openzeppelin-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAssetMatcher.sol";

abstract contract AssetMatcher is Initializable, OwnableUpgradeable {
    bytes internal constant EMPTY = "";

    mapping(bytes4 => address) internal matchers;

    event MatcherChange(bytes4 indexed assetType, address matcher);

    function setAssetMatcher(bytes4 assetType, address matcher)
        public
        virtual
        onlyOwner
    {
        matchers[assetType] = matcher;

        emit MatcherChange(assetType, matcher);
    }

    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) internal view returns (LibAsset.AssetType memory) {
        LibAsset.AssetType memory result = matchAssetOneSide(
            leftAssetType,
            rightAssetType
        );

        if (result.assetClass == 0) {
            return matchAssetOneSide(rightAssetType, leftAssetType);
        } else {
            return result;
        }
    }

    function matchAssetOneSide(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) private view returns (LibAsset.AssetType memory) {
        bytes4 classLeft = leftAssetType.assetClass;
        bytes4 classRight = rightAssetType.assetClass;

        if (classLeft == LibAsset.AVAX_ASSET_CLASS) {
            if (classRight == LibAsset.AVAX_ASSET_CLASS) {
                return leftAssetType;
            }

            return LibAsset.AssetType(0, EMPTY);
        }

        if (classLeft == LibAsset.ERC20_ASSET_CLASS) {
            if (classRight == LibAsset.ERC20_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }

            return LibAsset.AssetType(0, EMPTY);
        }

        if (classLeft == LibAsset.ERC721_ASSET_CLASS) {
            if (classRight == LibAsset.ERC721_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }

            return LibAsset.AssetType(0, EMPTY);
        }

        if (classLeft == LibAsset.ERC1155_ASSET_CLASS) {
            if (classRight == LibAsset.ERC1155_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }

            return LibAsset.AssetType(0, EMPTY);
        }

        address matcher = matchers[classLeft];

        if (matcher != address(0)) {
            return
                IAssetMatcher(matcher).matchAssets(
                    leftAssetType,
                    rightAssetType
                );
        }

        if (classLeft == classRight) {
            return simpleMatch(leftAssetType, rightAssetType);
        }

        revert("IAssetMatcher not found");
    }

    function simpleMatch(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) private pure returns (LibAsset.AssetType memory) {
        bytes32 leftHash = keccak256(leftAssetType.data);
        bytes32 rightHash = keccak256(rightAssetType.data);

        if (leftHash == rightHash) {
            return leftAssetType;
        }

        return LibAsset.AssetType(0, EMPTY);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibTransfer {
    function transferAvax(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");

        require(success, "LibTransfer: transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../openzeppelin-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface INftTransferProxy {
    function erc721safeTransferFrom(
        IERC721Upgradeable token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../libraries/LibAsset.sol";

interface ITransferProxy {
    function transfer(
        LibAsset.Asset calldata asset,
        address from,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibOrderDataV1.sol";
import "./LibOrderDataV2.sol";

import "./LibAsset.sol";

import "./LibMath.sol";

library LibOrder {
    using SafeMathUpgradeable for uint256;

    uint256 internal constant ON_CHAIN_ORDER = 0;

    /**
     * keccak256("Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)")
     */
    bytes32 internal constant ORDER_TYPEHASH =
        0x477ed43b8020849b755512278536c3766a3b4ab547519949a75f483372493f8d;

    bytes4 internal constant DEFAULT_ORDER_TYPE = 0xffffffff;

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        uint256 salt;
        uint256 start;
        uint256 end;
        bytes4 dataType;
        bytes data;
    }

    struct MatchedAssets {
        LibAsset.AssetType makeMatch;
        LibAsset.AssetType takeMatch;
    }

    function calculateRemaining(
        Order memory order,
        uint256 fill,
        bool isMakeFill
    ) internal pure returns (uint256 makeValue, uint256 takeValue) {
        if (isMakeFill) {
            makeValue = order.makeAsset.value.sub(fill);
            takeValue = LibMath.safeGetPartialAmountFloor(
                order.takeAsset.value,
                order.makeAsset.value,
                makeValue
            );
        } else {
            takeValue = order.takeAsset.value.sub(fill);
            makeValue = LibMath.safeGetPartialAmountFloor(
                order.makeAsset.value,
                order.takeAsset.value,
                takeValue
            );
        }
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        // order.data is in hash for V2 orders
        if (order.dataType == LibOrderDataV2.V2) {
            return
                keccak256(
                    abi.encode(
                        order.maker,
                        LibAsset.hash(order.makeAsset.assetType),
                        LibAsset.hash(order.takeAsset.assetType),
                        order.salt,
                        order.data
                    )
                );
        } else {
            return
                keccak256(
                    abi.encode(
                        order.maker,
                        LibAsset.hash(order.makeAsset.assetType),
                        LibAsset.hash(order.takeAsset.assetType),
                        order.salt
                    )
                );
        }
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    LibAsset.hash(order.makeAsset),
                    order.taker,
                    LibAsset.hash(order.takeAsset),
                    order.salt,
                    order.start,
                    order.end,
                    order.dataType,
                    keccak256(order.data)
                )
            );
    }

    function validate(LibOrder.Order memory order) internal view {
        require(
            order.start == 0 || order.start < block.timestamp,
            "Order start validation failed"
        );

        require(
            order.end == 0 || order.end > block.timestamp,
            "Order end validation failed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../royalties/LibPart.sol";

library LibOrderDataV1 {
    /**
     * bytes4(keccak256("V1")) == 0x4c234266
     */
    bytes4 public constant V1 = 0x4c234266;

    struct DataV1 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
    }

    function decodeOrderDataV1(bytes memory data)
        internal
        pure
        returns (DataV1 memory orderData)
    {
        orderData = abi.decode(data, (DataV1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../royalties/LibPart.sol";

library LibOrderDataV2 {
    /**
     * bytes4(keccak256("V2")) == 0x23d235ef
     */
    bytes4 public constant V2 = 0x23d235ef;

    struct DataV2 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        bool isMakeFill;
    }

    function decodeOrderDataV2(bytes memory data)
        internal
        pure
        returns (DataV2 memory orderData)
    {
        orderData = abi.decode(data, (DataV2));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/utils/math/SafeMathUpgradeable.sol";

library LibMath {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Calculates partial value given a numerator and denominator rounded down.
     *      Reverts if rounding error is >= 0.1%
     * @param numerator Numerator.
     * @param denominator Denominator.
     * @param target Value to calculate partial of.
     * @return partialAmount value of target rounded down.
     */
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("LibMath: rounding error");
        }

        partialAmount = numerator.mul(target).div(denominator);
    }

    /**
     * @dev Checks if rounding error >= 0.1% when rounding down.
     * @param numerator Numerator.
     * @param denominator Denominator.
     * @param target Value to multiply with numerator/denominator.
     * @return isError Rounding error is present.
     */
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("LibMath: division by zero");
        }

        /**
         * The absolute rounding error is the difference between the rounded
         * value and the ideal value. The relative rounding error is the
         * absolute rounding error divided by the absolute value of the
         * ideal value. This is undefined when the ideal value is zero.
         *
         * The ideal value is `numerator * target / denominator`.
         * Let's call `numerator * target % denominator` the remainder.
         * The absolute error is `remainder / denominator`.
         *
         * When the ideal value is zero, we require the absolute error to
         * be zero. Fortunately, this is always the case. The ideal value is
         * zero iff `numerator == 0` and/or `target == 0`. In this case the
         * remainder and absolute error are also zero.
         */
        if (target == 0 || numerator == 0) {
            return false;
        }

        /**
         * Otherwise, we want the relative rounding error to be strictly
         * less than 0.1%.
         * The relative error is `remainder / (numerator * target)`.
         * We want the relative error less than 1 / 1000:
         *        remainder / (numerator * target)  <  1 / 1000
         * or equivalently:
         *        1000 * remainder  <  numerator * target
         * so we have a rounding error if:
         *        1000 * remainder  >=  numerator * target
         */
        uint256 remainder = mulmod(target, numerator, denominator);

        isError = remainder.mul(1000) >= numerator.mul(target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("LibMath: rounding error");
        }

        partialAmount = numerator.mul(target).add(denominator.sub(1)).div(
            denominator
        );
    }

    /**
     * @dev Checks if rounding error >= 0.1% when rounding up.
     * @param numerator Numerator.
     * @param denominator Denominator.
     * @param target Value to multiply with numerator/denominator.
     * @return isError Rounding error is present.
     */
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("LibMath: division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            /**
             * When either is zero, the ideal value and rounded value are zero
             * and there is no rounding error.
             * Although the relative error is undefined.
             */
            return false;
        }

        // Compute remainder as before
        uint256 remainder = mulmod(target, numerator, denominator);

        remainder = denominator.sub(remainder) % denominator;

        isError = remainder.mul(1000) >= numerator.mul(target);

        return isError;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "../../proxy/utils/Initializable.sol";

import "./ECDSAUpgradeable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        onlyInitializing
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibSignature {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;

        if (v > 30) {
            require(
                v - 4 == 27 || v - 4 == 28,
                "ECDSA: invalid signature 'v' value"
            );

            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash Hash of the data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    StringsUpgradeable.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../libraries/LibAsset.sol";

interface IAssetMatcher {
    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) external view returns (LibAsset.AssetType memory);
}