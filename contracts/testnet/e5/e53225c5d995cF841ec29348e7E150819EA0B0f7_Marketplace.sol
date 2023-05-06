// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interfaces/IMarketplace.sol";

contract Marketplace is
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    IMarketPlace
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => Royalty) public royaltyInfos;
    mapping(address => mapping(uint256 => bool)) private blacklistedTokenIds;
    mapping(uint256 => SellInfo) public sellInfos;
    mapping(uint256 => AuctionInfo) public auctionInfos;
    mapping(address => bool) public allowedTokens;
    mapping(address => bool) public blacklistedUser;
    mapping(address => EnumerableSet.UintSet) private userSaleIds;
    mapping(address => EnumerableSet.UintSet) private userAuctionIds;
    mapping(address => mapping(address => EnumerableSet.UintSet))
        private userOfferIds;
    mapping(uint256 => OfferInfo) public offerInfos;

    ILaunchPad public launchPad;
    address public wrapperGateway;

    uint256 public saleId;
    uint256 public auctionId;
    uint256 public offerId;
    uint256 public maxAuctionTime;

    uint16 public platformFee;
    uint16 public constant FIXED_POINT = 1000;

    EnumerableSet.UintSet private availableSaleIds;
    EnumerableSet.UintSet private availableAuctionIds;
    EnumerableSet.UintSet private availableOfferIds;

    modifier whenNotScammer() {
        require(!blacklistedUser[msg.sender], "blacklisted user");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _launchPad,
        uint16 _platformFee
    ) public initializer {
        __Ownable_init();
        require(_launchPad != address(0), "zero launchPad address");
        require(_platformFee < FIXED_POINT, "invalid platform fee");

        platformFee = _platformFee;
        launchPad = ILaunchPad(_launchPad);
        maxAuctionTime = 10 days;
    }

    /// @inheritdoc IMarketPlace
    function setWrapperGateway(
        address _wrapperGateway
    ) external override onlyOwner {
        require(
            _wrapperGateway != address(0),
            "invalid wrapperGateway contract address"
        );
        wrapperGateway = _wrapperGateway;
    }

    /// @inheritdoc IMarketPlace
    function setPlatformFee(uint16 _platformFee) external override onlyOwner {
        require(_platformFee < FIXED_POINT, "invalid platform fee");
        platformFee = _platformFee;

        emit PlatformFeeSet(_platformFee);
    }

    /// @inheritdoc IMarketPlace
    function setMaxAuctionTime(
        uint256 _maxAuctionTime
    ) external override onlyOwner {
        require(_maxAuctionTime > 0, "invalid maxAuctionTime");
        emit MaxAuctionTimeSet(maxAuctionTime = _maxAuctionTime);
    }

    /// @inheritdoc IMarketPlace
    function setLaunchPad(address _launchPad) external override onlyOwner {
        require(_launchPad != address(0), "zero launchPad address");
        launchPad = ILaunchPad(_launchPad);

        emit LaunchPadSet(_launchPad);
    }

    /// @inheritdoc IMarketPlace
    function setAllowedToken(
        address[] memory _tokens,
        bool _isAdd
    ) external override onlyOwner {
        uint256 length = _tokens.length;
        require(length > 0, "invalid length");
        for (uint256 i = 0; i < length; i++) {
            allowedTokens[_tokens[i]] = _isAdd;
        }

        emit AllowedTokenSet(_tokens, _isAdd);
    }

    /// @inheritdoc IMarketPlace
    function setBlockedTokenIds(
        address[] memory _collections,
        uint256[] memory _tokenIds,
        bool _isAdd
    ) external override onlyOwner {
        uint256 length = _collections.length;
        require(length > 0 && length == _tokenIds.length, "length dismatched");

        for (uint256 i = 0; i < length; i++) {
            blacklistedTokenIds[_collections[i]][_tokenIds[i]] = _isAdd;
        }

        emit BlockedTokenIdsSet(_collections, _tokenIds, _isAdd);
    }

    /// @inheritdoc IMarketPlace
    function setBlacklistedUser(
        address[] memory _users,
        bool _isAdd
    ) external override onlyOwner {
        uint256 length = _users.length;
        require(length > 0, "invalid length");
        for (uint256 i = 0; i < length; i++) {
            blacklistedUser[_users[i]] = _isAdd;
        }

        emit BlacklistedUserSet(_users, _isAdd);
    }

    /// @inheritdoc IMarketPlace
    function setRoyalty(
        address _collection,
        uint16 _royaltyRate
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        require(_collection != address(0), "zero collection address");
        require(_royaltyRate < FIXED_POINT, "invalid royalty fee");
        require(
            ICollection(_collection).owner() == sender,
            "not collection owner"
        );

        royaltyInfos[_collection] = Royalty(sender, _royaltyRate);

        emit RoyaltySet(sender, _collection, _royaltyRate);
    }

    /// @inheritdoc IMarketPlace
    function pause() external override whenNotPaused onlyOwner {
        _pause();
        emit Pause();
    }

    /// @inheritdoc IMarketPlace
    function unpause() external override whenPaused onlyOwner {
        _unpause();
        emit Unpause();
    }

    /// @inheritdoc IMarketPlace
    function createERC721Collection(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        address deployedCollection = launchPad.deployCollection(
            _maxSupply,
            _mintPrice,
            _startTimestamp,
            _endTimestamp,
            sender,
            _name,
            _symbol,
            _baseURI
        );

        emit ERC721CollectionCreated(
            sender,
            deployedCollection,
            _maxSupply,
            _mintPrice,
            _endTimestamp,
            _name,
            _symbol
        );
    }

    /// Buy

    /// @inheritdoc IMarketPlace
    function listERC1155ForSale(
        address _tokenAddress,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        _checkListERC1155Condition(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenId,
            _quantity
        );

        _setSaleId(saleId, sender, true);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        sellInfos[saleId++] = SellInfo(
            sender,
            _tokenAddress,
            _paymentToken,
            tokenIds,
            _quantity,
            _price,
            false
        );
        IERC1155(_tokenAddress).safeTransferFrom(
            sender,
            address(this),
            _tokenId,
            _quantity,
            ""
        );

        emit ERC1155ForSaleListed(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenId,
            _quantity,
            _price,
            saleId - 1
        );
    }

    /// @inheritdoc IMarketPlace
    function listERC721ForSale(
        address _tokenAddress,
        address _paymentToken,
        uint256[] memory _tokenIds,
        uint256 _price
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        _checkListERC721Condition(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenIds
        );

        _setSaleId(saleId, sender, true);
        sellInfos[saleId++] = SellInfo(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenIds,
            1,
            _price,
            true
        );
        _batchERC721Transfer(sender, address(this), _tokenAddress, _tokenIds);

        emit ERC721ForSaleListed(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenIds,
            _price,
            saleId - 1
        );
    }

    /// @inheritdoc IMarketPlace
    function closeSale(
        uint256 _saleId
    ) external override nonReentrant whenNotPaused {
        require(availableSaleIds.contains(_saleId), "not exists saleId");
        SellInfo memory sellInfo = sellInfos[_saleId];
        require(msg.sender == sellInfo.seller, "no permission");

        _transferNFT(
            address(this),
            sellInfo.seller,
            sellInfo.collectionAddress,
            sellInfo.tokenIds,
            sellInfo.quantity,
            sellInfo.isERC721
        );
        _setSaleId(_saleId, sellInfo.seller, false);

        emit SaleClosed(_saleId);
    }

    /// @inheritdoc IMarketPlace
    function changeSalePrice(
        uint256 _saleId,
        uint256 _newPrice,
        address _paymentToken
    ) external override nonReentrant whenNotPaused {
        address sender = msg.sender;
        require(availableSaleIds.contains(_saleId), "not exists saleId");
        require(sellInfos[_saleId].seller == sender, "not seller");
        require(allowedTokens[_paymentToken], "not allowed payment token");

        emit SalePriceChanged(
            _saleId,
            sellInfos[_saleId].paymentToken,
            sellInfos[_saleId].price,
            _paymentToken,
            _newPrice
        );
        sellInfos[_saleId].price = _newPrice;
        sellInfos[_saleId].paymentToken = _paymentToken;
    }

    /// @inheritdoc IMarketPlace
    function getAvailableSaleIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return availableSaleIds.values();
    }

    /// @inheritdoc IMarketPlace
    function buyNFT(
        uint256 _saleId
    ) external override whenNotPaused nonReentrant whenNotScammer {
        address sender = msg.sender;
        SellInfo memory sellInfo = sellInfos[_saleId];
        require(availableSaleIds.contains(_saleId), "not exists saleId");
        require(sellInfo.seller != sender, "caller is seller");

        address paymentToken = sellInfo.paymentToken;
        _transferPaymentTokenWithFee(
            sellInfo.collectionAddress,
            paymentToken,
            sender,
            sellInfo.seller,
            sellInfo.price,
            true
        );
        _transferNFT(
            address(this),
            sender != wrapperGateway ? sender : tx.origin,
            sellInfo.collectionAddress,
            sellInfo.tokenIds,
            sellInfo.quantity,
            sellInfo.isERC721
        );

        _setSaleId(_saleId, sellInfo.seller, false);

        emit NFTBought(
            sender,
            sellInfo.collectionAddress,
            sellInfo.tokenIds,
            sellInfo.quantity,
            paymentToken,
            sellInfo.price,
            _saleId
        );
    }

    /// Auction

    /// @inheritdoc IMarketPlace
    function listERC721ForAuction(
        address _tokenAddress,
        address _paymentToken,
        uint256[] memory _tokenIds,
        uint256 _startPrice,
        uint256 _endTimestamp,
        bool _isTimeAuction
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        _checkListERC721Condition(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenIds
        );
        uint256 endTime = _checkAuctionTime(_isTimeAuction, _endTimestamp);
        uint256 curAuctionId = auctionId++;

        _setAuctionId(curAuctionId, sender, true);
        auctionInfos[curAuctionId] = AuctionInfo(
            sender,
            _tokenAddress,
            _paymentToken,
            address(0),
            _tokenIds,
            1,
            _startPrice,
            endTime,
            _startPrice,
            true,
            _isTimeAuction
        );
        _batchERC721Transfer(sender, address(this), _tokenAddress, _tokenIds);

        emit ERC721ForAuctionListed(
            sender,
            _tokenAddress,
            _paymentToken,
            curAuctionId,
            _tokenIds,
            _startPrice,
            endTime,
            _isTimeAuction
        );
    }

    /// @inheritdoc IMarketPlace
    function listERC1155ForAuction(
        address _tokenAddress,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _startPrice,
        uint256 _endTimestamp,
        bool _isTimeAuction
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        _checkListERC1155Condition(
            sender,
            _tokenAddress,
            _paymentToken,
            _tokenId,
            _quantity
        );
        uint256 endTime = _checkAuctionTime(_isTimeAuction, _endTimestamp);
        uint256 curAuctionId = (auctionId++);

        _setAuctionId(curAuctionId, sender, true);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        auctionInfos[curAuctionId] = AuctionInfo(
            sender,
            _tokenAddress,
            _paymentToken,
            address(0),
            tokenIds,
            1,
            _startPrice,
            endTime,
            _startPrice,
            false,
            _isTimeAuction
        );
        IERC1155(_tokenAddress).safeTransferFrom(
            sender,
            address(this),
            _tokenId,
            _quantity,
            ""
        );

        emit ERC1155ForAuctionListed(
            sender,
            _tokenAddress,
            _paymentToken,
            curAuctionId,
            _tokenId,
            _quantity,
            _startPrice,
            endTime,
            _isTimeAuction
        );
    }

    /// @inheritdoc IMarketPlace
    function getAvailableAuctionIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return availableAuctionIds.values();
    }

    /// @inheritdoc IMarketPlace
    function placeBid(
        uint256 _auctionId,
        uint256 _amount
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        AuctionInfo storage auctionInfo = auctionInfos[_auctionId];
        require(
            availableAuctionIds.contains(_auctionId),
            "not exists auctionId"
        );
        require(auctionInfo.auctionMaker != sender, "bider is auction maker");
        require(auctionInfo.startPrice < _amount, "low price");
        require(
            auctionInfo.winPrice < _amount,
            "lower price than last win price"
        );

        if (auctionInfo.isTimeAuction) {
            require(
                block.timestamp < auctionInfo.endTimestamp,
                "over auction duration"
            );
        }

        address prevWinner = auctionInfo.winner;
        uint256 prevWinPrice = auctionInfo.winPrice;
        auctionInfo.winner = sender;
        auctionInfo.winPrice = _amount;

        /// Return bid amount to prev winner.
        if (prevWinner != address(0)) {
            IERC20(auctionInfo.paymentToken).safeTransfer(
                prevWinner,
                prevWinPrice
            );
        }
        IERC20(auctionInfo.paymentToken).safeTransferFrom(
            sender,
            address(this),
            _amount
        );

        emit BidPlaced(sender, _auctionId, _amount);
    }

    /// @inheritdoc IMarketPlace
    function closeAuction(
        uint256 _auctionId
    ) external override whenNotPaused onlyOwner {
        AuctionInfo memory auctionInfo = auctionInfos[_auctionId];
        require(
            availableAuctionIds.contains(_auctionId),
            "not exists auctionId"
        );
        _setAuctionId(_auctionId, auctionInfo.auctionMaker, false);

        _transferNFT(
            address(this),
            auctionInfo.auctionMaker,
            auctionInfo.collectionAddress,
            auctionInfo.tokenIds,
            auctionInfo.quantity,
            auctionInfo.isERC721
        );

        if (auctionInfo.winner == address(0)) {
            return;
        }

        _transferPaymentTokenWithFee(
            auctionInfo.collectionAddress,
            auctionInfo.paymentToken,
            address(this),
            auctionInfo.winner,
            auctionInfo.winPrice,
            false
        );

        emit AuctionClosed(_auctionId);
    }

    /// @inheritdoc IMarketPlace
    function getAuctionCollection(
        uint256 _auctionId
    ) external view override returns (address, uint256[] memory) {
        AuctionInfo memory auctionInfo = auctionInfos[_auctionId];
        return (auctionInfo.collectionAddress, auctionInfo.tokenIds);
    }

    /// @inheritdoc IMarketPlace
    function finishAuction(uint256 _auctionId) external override whenNotPaused {
        address sender = msg.sender;
        AuctionInfo memory auctionInfo = auctionInfos[_auctionId];
        require(
            availableAuctionIds.contains(_auctionId),
            "not exists auctionId"
        );
        if (auctionInfo.isTimeAuction) {
            require(
                block.timestamp >= auctionInfo.endTimestamp,
                "before auction maturity"
            );
            require(
                auctionInfo.auctionMaker == sender ||
                    auctionInfo.winner == sender,
                "no permission"
            );
        } else {
            require(auctionInfo.auctionMaker == sender, "no permission");
        }

        _setAuctionId(_auctionId, auctionInfo.auctionMaker, false);

        address collectionRecipient = auctionInfo.winner == address(0)
            ? auctionInfo.auctionMaker
            : auctionInfo.winner;

        _transferNFT(
            address(this),
            collectionRecipient,
            auctionInfo.collectionAddress,
            auctionInfo.tokenIds,
            auctionInfo.quantity,
            auctionInfo.isERC721
        );

        if (auctionInfo.winner == address(0)) {
            return;
        }

        _transferPaymentTokenWithFee(
            auctionInfo.collectionAddress,
            auctionInfo.paymentToken,
            address(this),
            auctionInfo.auctionMaker,
            auctionInfo.winPrice,
            true
        );

        emit AuctionFinished(
            _auctionId,
            auctionInfo.auctionMaker,
            collectionRecipient,
            auctionInfo.collectionAddress,
            auctionInfo.tokenIds,
            auctionInfo.paymentToken,
            auctionInfo.winPrice
        );
    }

    /// Offer

    /// @inheritdoc IMarketPlace
    function placeOffer(
        OfferInfo memory _offerInfo
    ) external override whenNotPaused whenNotScammer {
        address sender = msg.sender;
        require(_offerInfo.offeror == sender, "not correct offeror");
        require(_offerInfo.quantity > 0, "zero quantity");
        require(
            allowedTokens[_offerInfo.paymentToken],
            "not allowed payment token"
        );
        require(
            !blacklistedTokenIds[_offerInfo.collectionAddress][
                _offerInfo.tokenId
            ],
            "blacklisted collectionId"
        );
        require(
            IERC20(_offerInfo.paymentToken).allowance(sender, address(this)) >=
                _offerInfo.offerPrice,
            "not enough allowance"
        );

        if (_offerInfo.isERC721) {
            require(
                IERC721(_offerInfo.collectionAddress).ownerOf(
                    _offerInfo.tokenId
                ) == _offerInfo.owner,
                "not correct collection owner"
            );
            require(_offerInfo.quantity == 1, "not correct quantity");
        } else {
            require(
                IERC1155(_offerInfo.collectionAddress).balanceOf(
                    _offerInfo.owner,
                    _offerInfo.tokenId
                ) >= _offerInfo.quantity,
                "not enough NFT balance"
            );
        }

        availableOfferIds.add(offerId);
        userOfferIds[_offerInfo.owner][_offerInfo.collectionAddress].add(
            offerId
        );
        offerInfos[offerId++] = _offerInfo;

        emit OfferPlaced(
            _offerInfo.owner,
            _offerInfo.offeror,
            _offerInfo.collectionAddress,
            _offerInfo.tokenId,
            _offerInfo.quantity,
            _offerInfo.offerPrice,
            offerId - 1
        );
    }

    /// @inheritdoc IMarketPlace
    function getAvailableOffers(
        address _account,
        address _tokenAddress
    )
        external
        view
        override
        whenNotScammer
        returns (OfferInfo[] memory, uint256[] memory)
    {
        uint256 length = userOfferIds[_account][_tokenAddress].length();
        OfferInfo[] memory availableOffers = new OfferInfo[](length);
        uint256[] memory availableIds = userOfferIds[_account][_tokenAddress]
            .values();
        if (length == 0) {
            return (availableOffers, availableIds);
        }

        for (uint256 i = 0; i < length; i++) {
            uint256 id = availableIds[i];
            availableOffers[i] = offerInfos[id];
        }

        return (availableOffers, availableIds);
    }

    /// @inheritdoc IMarketPlace
    function acceptOffer(uint256 _offerId) external override whenNotPaused {
        address sender = msg.sender;
        OfferInfo memory offerInfo = offerInfos[_offerId];
        require(availableOfferIds.contains(_offerId), "not exists offerId");
        require(offerInfo.owner == sender, "no permission");
        if (offerInfo.isERC721) {
            IERC721(offerInfo.collectionAddress).transferFrom(
                offerInfo.owner,
                offerInfo.offeror,
                offerInfo.tokenId
            );
        } else {
            IERC1155(offerInfo.collectionAddress).safeTransferFrom(
                offerInfo.owner,
                offerInfo.offeror,
                offerInfo.tokenId,
                offerInfo.quantity,
                ""
            );
        }

        _transferPaymentTokenWithFee(
            offerInfo.collectionAddress,
            offerInfo.paymentToken,
            offerInfo.offeror,
            offerInfo.owner,
            offerInfo.offerPrice,
            true
        );

        _removeAllOfferIds(sender, offerInfo.collectionAddress);

        emit OfferAccepted(
            offerInfo.owner,
            offerInfo.offeror,
            offerInfo.collectionAddress,
            offerInfo.tokenId,
            offerInfo.quantity,
            offerInfo.offerPrice,
            _offerId
        );
    }

    function _batchERC721Transfer(
        address _from,
        address _to,
        address _collection,
        uint256[] memory _tokenIds
    ) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_collection).transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function _setSaleId(
        uint256 _saleId,
        address _seller,
        bool _isAdd
    ) internal {
        if (_isAdd) {
            availableSaleIds.add(_saleId);
            userSaleIds[_seller].add(_saleId);
        } else {
            availableSaleIds.remove(_saleId);
            userSaleIds[_seller].remove(_saleId);
        }
    }

    function _setAuctionId(
        uint256 _auctionId,
        address _auctionMaker,
        bool _isAdd
    ) internal {
        if (_isAdd) {
            availableAuctionIds.add(_auctionId);
            userAuctionIds[_auctionMaker].add(_auctionId);
        } else {
            availableAuctionIds.remove(_auctionId);
            userAuctionIds[_auctionMaker].remove(_auctionId);
        }
    }

    function _checkListERC721Condition(
        address _lister,
        address _tokenAddress,
        address _paymentToken,
        uint256[] memory _tokenIds
    ) internal view {
        uint256 length = _tokenIds.length;
        require(_tokenAddress != address(0), "zero collection address");
        require(length > 0, "zero tokenIDs");
        require(allowedTokens[_paymentToken], "not allowed payment token");

        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(
                !blacklistedTokenIds[_tokenAddress][tokenId],
                "blacklisted collectionId"
            );
            require(
                IERC721(_tokenAddress).ownerOf(tokenId) == _lister,
                "not collection Owner"
            );
        }
    }

    function _checkListERC1155Condition(
        address _lister,
        address _tokenAddress,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _quantity
    ) internal view {
        require(_tokenAddress != address(0), "zero collection address");
        require(_quantity > 0, "zero quantity");
        require(
            !blacklistedTokenIds[_tokenAddress][_tokenId],
            "blacklisted collectionId"
        );
        require(
            IERC1155(_tokenAddress).balanceOf(_lister, _tokenId) > _quantity,
            "not enough balance"
        );
        require(allowedTokens[_paymentToken], "not allowed payment token");
    }

    function _removeAllOfferIds(
        address _owner,
        address _collectionAddress
    ) internal {
        uint256[] memory values = userOfferIds[_owner][_collectionAddress]
            .values();
        uint256 length = values.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 value = values[i];
            userOfferIds[_owner][_collectionAddress].remove(value);
            availableOfferIds.remove(value);
        }
    }

    function _transferPaymentTokenWithFee(
        address _collectionAddress,
        address _paymentToken,
        address _from,
        address _to,
        uint256 _amount,
        bool _takeFee
    ) internal {
        if (_from != address(this)) {
            IERC20(_paymentToken).safeTransferFrom(
                _from,
                address(this),
                _amount
            );
        }

        if (_takeFee) {
            Royalty memory royalty = royaltyInfos[_collectionAddress];
            uint256 feeAmount = (_amount * platformFee) / FIXED_POINT;
            uint256 royaltyAmount = (_amount * royalty.royaltyRate) /
                FIXED_POINT;
            uint256 transferAmount = _amount - feeAmount - royaltyAmount;
            IERC20(_paymentToken).safeTransfer(_to, transferAmount);
            if (royaltyAmount > 0 && royalty.collectionOwner != address(0)) {
                IERC20(_paymentToken).safeTransfer(
                    royalty.collectionOwner,
                    royaltyAmount
                );
            }
        } else {
            IERC20(_paymentToken).safeTransfer(_to, _amount);
        }
    }

    function _transferNFT(
        address _from,
        address _to,
        address _collectionAddress,
        uint256[] memory _tokenIds,
        uint256 _quantity,
        bool _isERC721
    ) internal {
        if (_isERC721) {
            _batchERC721Transfer(_from, _to, _collectionAddress, _tokenIds);
        } else {
            IERC1155(_collectionAddress).safeTransferFrom(
                _from,
                _to,
                _tokenIds[0],
                _quantity,
                ""
            );
        }
    }

    function _checkAuctionTime(
        bool _isTimeAuction,
        uint256 _endTimestamp
    ) internal view returns (uint256) {
        require(
            !_isTimeAuction || _endTimestamp > block.timestamp,
            "invalid endTime"
        );
        if (_isTimeAuction) {
            uint256 auctionDuration = _endTimestamp - block.timestamp;
            require(auctionDuration <= maxAuctionTime, "over maxAuctionTime");
        }

        return _isTimeAuction ? _endTimestamp : 0;
    }

    uint256[100] private __gaps;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ICollection.sol";
import "./ILaunchPad.sol";

interface IMarketPlace {
    struct SellInfo {
        address seller;
        address collectionAddress;
        address paymentToken;
        uint256[] tokenIds;
        uint256 quantity;
        uint256 price;
        bool isERC721;
    }

    struct AuctionInfo {
        address auctionMaker;
        address collectionAddress;
        address paymentToken;
        address winner;
        uint256[] tokenIds;
        uint256 quantity;
        uint256 startPrice;
        uint256 endTimestamp;
        uint256 winPrice;
        bool isERC721;
        bool isTimeAuction;
    }

    struct OfferInfo {
        address owner;
        address offeror;
        address paymentToken;
        address collectionAddress;
        uint256 tokenId;
        uint256 quantity;
        uint256 offerPrice;
        bool isERC721;
    }

    struct Royalty {
        address collectionOwner;
        uint16 royaltyRate;
    }

    /// @notice Set marketplace platform fee.
    /// @dev Only owner can call this function.
    function setPlatformFee(uint16 _platformFee) external;

    /// @notice Set wrapperGateway contract address.
    /// @dev Only owner can call this function.
    function setWrapperGateway(address _wrapperGateway) external;

    /// @notice Set maxAuctionTime.
    /// @dev Only owner can call this function.
    function setMaxAuctionTime(uint256 _maxAuctionTime) external;

    /// @notice Set launch pad address.
    /// @dev Only owner can call this function.
    function setLaunchPad(address _launchPad) external;

    /// @notice Set allowed payment token.
    /// @dev Users can't trade NFT with token that not allowed.
    ///      Only owner can call this function.
    /// @param _tokens The token addresses.
    /// @param _isAdd Add/Remove = true/false
    function setAllowedToken(address[] memory _tokens, bool _isAdd) external;

    /// @notice Set blocked collections for trading.
    /// @dev The collections that registered as blocked collection can't be trade.
    ///      Only owner can call this function.
    function setBlockedTokenIds(
        address[] memory _collections,
        uint256[] memory _tokenIds,
        bool _isAdd
    ) external;

    /// @notice Add/Remove users to blacklist.
    /// @dev Only owner can call this function.
    function setBlacklistedUser(address[] memory _users, bool _isAdd) external;

    /// @notice Set royalty for collection.
    /// @dev Only collection owner can call this function.
    ///      To do this, collection should inherit Ownable contract so that
    ///      marketplace can get owner of that and check the permission.
    ///      Collections that didn't inherit ownable, can't set royalty for them.
    function setRoyalty(address _collection, uint16 _royaltyRate) external;

    /// @notice Pause marketplace
    /// @dev Only owner can call this function.
    function pause() external;

    /// @notice Unpause marketplace
    /// @dev Only owner can call this function.
    function unpause() external;

    /// Create ERC721A

    /// @notice Create collection using ERC721A.
    /// @param _maxSupply       Max number of ERC721A can be mint.
    /// @param _mintPrice       Price to mint. (ETH)
    /// @param _startTimestamp  The unix timestamp that users can start to mint.
    /// @param _endTimestamp    The unix timestamp to finish minting.
    /// @param _name            Collection name.
    /// @param _symbol          Collection symbol.
    /// @param _baseURI         Collection baseURI.
    function createERC721Collection(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external;

    /// Buy

    /// @notice List ERC1155 collection for sale.
    /// @dev Only collection owner can call this function.
    ///      Btw, collection owners should send their collection to marketplace.
    function listERC1155ForSale(
        address _tokenAddress,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price
    ) external;

    /// @notice List ERC721 collection for sale.
    /// @dev Only collection owner can call this function.
    ///      Btw, collection owners should send their collection to marketplace.
    function listERC721ForSale(
        address _tokenAddress,
        address _paymentToken,
        uint256[] memory _tokenIds,
        uint256 _price
    ) external;

    /// @notice Close sale and retrived listed NFT for sale.
    /// @dev Only sale creator can call this function.
    function closeSale(uint256 _saleId) external;

    /// @notice Change sale price after listed collection for sale.
    /// @dev Only sale creator can call this function.
    function changeSalePrice(
        uint256 _saleId,
        uint256 _newPrice,
        address _paymentToken
    ) external;

    /// @notice Get available saleIds.
    function getAvailableSaleIds() external view returns (uint256[] memory);

    /// @notice Buy collection with saleId.
    /// @dev Buyer can't same as seller.
    function buyNFT(uint256 _saleId) external;

    /// Auction

    /// @notice list ERC721 collection for auction.
    /// @dev Similar to sale, sellers should transfer their collection to marketplace.
    /// @param _tokenAddress    The address of collection.
    /// @param _paymentToken    The address of token that winner should pay with.
    /// @param _tokenIds        The ids of collection.
    /// @param _startPrice      Min price for sell.
    /// @param _endTimestamp    Auction endTimestamp.
    /// @param _isTimeAuction   Status that this is time auction or not.
    function listERC721ForAuction(
        address _tokenAddress,
        address _paymentToken,
        uint256[] memory _tokenIds,
        uint256 _startPrice,
        uint256 _endTimestamp,
        bool _isTimeAuction
    ) external;

    /// @notice list ERC1155 collection for auction.
    /// @dev Similar to sale, sellers should transfer their collection to marketplace.
    /// @param _tokenAddress    The address of collection.
    /// @param _paymentToken    The address of token that winner should pay with.
    /// @param _tokenId         The id of collection.
    /// @param _quantity        The number of collection for auction.
    /// @param _startPrice      Min price for sell.
    /// @param _endTimestamp    Auction duration time. it's available when only it's time auction.
    /// @param _isTimeAuction   Status that this is time auction or not.
    function listERC1155ForAuction(
        address _tokenAddress,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _startPrice,
        uint256 _endTimestamp,
        bool _isTimeAuction
    ) external;

    /// @notice Get available ids of auction.
    function getAvailableAuctionIds() external view returns (uint256[] memory);

    /// @notice Get collection information by auctionId.
    function getAuctionCollection(
        uint256 _auctionId
    ) external view returns (address, uint256[] memory);

    /// @notice Bid to auction with certain auction Id.
    /// @dev Users can get auctionIds from `getAvailableAuctionIds`
    /// @dev Bidder should bid with amount that higher than last winner's bid amount.
    /// @param _auctionId The id of auction.
    /// @param _amount The amount of token to bid.
    function placeBid(uint256 _auctionId, uint256 _amount) external;

    /// @notice Close auction with the certain auction id.
    /// @dev Caller should be platform owner. This function is for emergency.
    ///      If auction maker didn't finish auction for a long time, owner can finish this.
    function closeAuction(uint256 _auctionId) external;

    /// @notice Finish auction.
    /// @dev Caller should be the auction maker.
    ///      Winner receives the collection and auction maker gets token.
    function finishAuction(uint256 _auctionId) external;

    /// Offer

    /// @notice Anyone can place offer to certain collection.
    function placeOffer(OfferInfo memory _offerInfo) external;

    /// @notice Collection owner can get available offers by each collection.
    function getAvailableOffers(
        address _account,
        address _tokenAddress
    ) external view returns (OfferInfo[] memory, uint256[] memory);

    /// @notice Collection owner accept offer with certain offer Id.
    /// @dev Collection owner can get available offer ids from `geetAvailableOffers` function.
    function acceptOffer(uint256 _offerId) external;

    event PlatformFeeSet(uint16 platformFee);

    event MaxAuctionTimeSet(uint256 maxAuctionTime);

    event LaunchPadSet(address launchPad);

    event AllowedTokenSet(address[] tokens, bool isAdd);

    event BlockedTokenIdsSet(
        address[] collections,
        uint256[] tokenIds,
        bool isAdd
    );

    event BlacklistedUserSet(address[] users, bool isAdd);

    event RoyaltySet(address setter, address collection, uint16 royaltyRate);

    event Pause();

    event Unpause();

    event ERC721CollectionCreated(
        address creator,
        address collectionAddress,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 endTimestamp,
        string name,
        string symbol
    );

    event ERC1155ForSaleListed(
        address seller,
        address tokenAddress,
        address paymentToken,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 saleId
    );

    event ERC721ForSaleListed(
        address seller,
        address tokenAddress,
        address paymentToken,
        uint256[] tokenIds,
        uint256 price,
        uint256 saleId
    );

    event SaleClosed(uint256 saleId);

    event SalePriceChanged(
        uint256 saleId,
        address oldPaymentToken,
        uint256 oldPrice,
        address newPaymentToken,
        uint256 newPrice
    );

    event NFTBought(
        address buyer,
        address collection,
        uint256[] tokenIds,
        uint256 quantity,
        address paymentToken,
        uint256 price,
        uint256 saleId
    );

    event ERC721ForAuctionListed(
        address auctionMaker,
        address tokenAddress,
        address paymentToken,
        uint256 auctionId,
        uint256[] tokenIds,
        uint256 startPrice,
        uint256 endTimestamp,
        bool isTimeAuction
    );

    event ERC1155ForAuctionListed(
        address auctionMaker,
        address tokenAddress,
        address paymentToken,
        uint256 auctionId,
        uint256 tokenId,
        uint256 quantity,
        uint256 startPrice,
        uint256 endTimestamp,
        bool isTimeAuction
    );

    event BidPlaced(address bidder, uint256 auctionId, uint256 bidPrice);

    event AuctionClosed(uint256 auctionId);

    event AuctionFinished(
        uint256 auctionId,
        address auctionMaker,
        address auctionWinner,
        address collection,
        uint256[] tokenIds,
        address paymentToken,
        uint256 winPrice
    );

    event OfferPlaced(
        address collectionOwner,
        address offeror,
        address collectionAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 offerPrice,
        uint256 offerId
    );

    event OfferAccepted(
        address acceptor,
        address offeror,
        address collectionAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 offerPrice,
        uint256 offerId
    );
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
 */
library EnumerableSet {
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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
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
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

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
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
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
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.17;

interface ICollection {
    function owner() external view returns (address);

    function getTimestamp() external view returns (uint256 currentTime, uint256 endTime);

    function setBaseUri(string memory _uri) external;

    function changeStartTime(uint256 _startTime) external;

    function changeEndTime(uint256 _endTime) external;

    function enableWhitelistMode(bool _enable) external;

    function forceFinishMinting() external;

    function changeMaxTotalSupply(uint256 _maxTotalSupply) external;

    function setMultipleRecipients(
        address[] memory _recipients, 
        uint16[] memory _weights
    ) external;

    function setCollectionFeeRate(uint16 _feeRate) external;

    function setPriceForWhitelist(uint256 _price) external;

    function setWhitelist(address[] memory _users, bool _isAdd) external;

    function mintNFTTo(
        address _recipient, 
        uint256 _quantity
    ) external payable;

    function mintAvailable() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ICollection.sol";

interface ILaunchPad {
    struct CollectionStatus {
        address collectionAddress;
        bool availableMint;
    }

    /// @notice Deploy new ERC721A collection.
    /// @dev Anyone can call this function.
    /// @param _maxSupply The limit supply amount that users can mint.
    /// @param _mintPrice The price to mint.
    /// @param _startTime Unix timestamp that users can start minting.
    /// @param _endTime Unix timestamp to finish minting.
    /// @param _creator The address of collection creator.
    /// @param _name The collections's name.
    /// @param _symbol The collection's symbol.
    /// @param _baseUri The collection's base uri.
    /// @return The deployed address of the collection.
    function deployCollection(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _startTime,
        uint256 _endTime,
        address _creator,
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) external returns (address);

    /// @notice Get collection addresses and minting available status of user deployed.
    /// @param _owner The address of collection deployer.
    /// @return Information of collections. collection address and minting available status.
    function getDeployedCollections(
        address _owner
    ) external view returns (CollectionStatus[] memory);

    /// @notice Set collection's base uri.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _baseUri The base uri of collection.
    function setCollectionBaseUri(
        address _collection,
        string memory _baseUri
    ) external;

    /// @notice Change collection's minting start timestamp.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _startTime The timestamp to start collection minting.
    function changeStartTime(address _collection, uint256 _startTime) external;

    /// @notice Change collection's minting end timestamp.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _endTime The timestamp to finish collection minting.
    function changeEndTime(address _collection, uint256 _endTime) external;

    /// @notice Change collection's whitelist mode.
    /// @dev Only collection deployer can call this function.
    ///      If whitelist mode is true, only whitelisted users can mint collections.
    /// @param _collection The address of collection.
    /// @param _enable Enable/Disable whitelist mode = true/false.
    function enableWhitelistMode(address _collection, bool _enable) external;

    /// @notice Add/Remove whitelist addresses.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _users The address of users.
    /// @param _isAdd Add/Remove whitelists = true/false.
    function setWhitelistAddrs(
        address _collection,
        address[] memory _users,
        bool _isAdd
    ) external;

    /// @notice Finish collection's minting process any time.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    function forceFinishMinting(address _collection) external;

    /// @notice Change max total supply amount of collection.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _maxTotalSupply The max total suppy of collection.
    function changeMaxTotalSupply(
        address _collection,
        uint256 _maxTotalSupply
    ) external;

    /// @notice Add/Remove multiple fee recipients.
    /// @dev Only collection deployer can call this function.
    ///      The platform fee goes to recipients.
    /// @param _collection The address of collection.
    /// @param _recipients The address of recipients.
    /// @param _weights The rate wights by each recipient.
    function setMultiRecipients(
        address _collection,
        address[] memory _recipients,
        uint16[] memory _weights
    ) external;

    /// @notice Set fee rate for minting.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _feeRate The fee rate.
    function setCollectionFeeRate(
        address _collection,
        uint16 _feeRate
    ) external;

    /// @notice Set fee rate for minting.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _quantity Amount of collection to mint.
    function mintCollection(
        address _collection,
        uint256 _quantity
    ) external payable;

    /// @notice Modify minting price for whitelisted users.
    /// @dev Only collection deployer can call this function.
    /// @param _collection The address of collection.
    /// @param _price The minting price for whitelisted users.
    function setPriceForWhitelist(address _collection, uint256 _price) external;

    /// @notice withdraw tokens stored as fee.
    /// @dev Only owner can call this function.
    /// @param _token The address of token.
    function withdraw(address _token) external;

    event CollectionDeployed(
        address indexed collectionOwner,
        address indexed collectionAddress,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 startTime,
        uint256 endTime,
        string name,
        string symbol,
        string baseUri
    );

    event CollectionBaseUriSet(
        address indexed collectionOwner,
        address indexed collectionAddress,
        string baseUri
    );

    event StartTimeChanged(
        address indexed collectionOwner,
        address indexed collectionAddress,
        uint256 startTime
    );

    event EndTimeChanged(
        address indexed collectionOwner,
        address indexed collectionAddress,
        uint256 endtime
    );

    event WhitelistModeEnabled(
        address indexed collectionOwner,
        address indexed collectionAddress,
        bool enable
    );

    event WhitelistAddrsSet(
        address indexed collectionOwner,
        address indexed collectionAddress,
        address[] indexed users,
        bool isAdd
    );

    event FinishMintingForced(
        address indexed collectionOwner,
        address indexed collectionAddress
    );

    event MaxTotalSupplyChanged(
        address indexed collectionOwner,
        address indexed collectionAddress,
        uint256 maxTotalSupply
    );

    event MultiRecipientsSet(
        address indexed collectionOwner,
        address indexed collectionAddress,
        address[] indexed recipients,
        uint16[] weights
    );

    event CollectionFeeRateSet(
        address indexed collectionOwner,
        address indexed collectionAddress,
        uint16 feeRate
    );

    event CollectionMinted(
        address indexed minter,
        address indexed collectionAddress,
        uint256 quantity
    );

    event PriceForWhitelistSet(
        address indexed collectionOwner,
        address indexed collectionAddress,
        uint256 price
    );

    event Withdrawn(address indexed tokenAddress, uint256 withdrawnAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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