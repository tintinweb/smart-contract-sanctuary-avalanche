// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Owners.sol";
import "./IPolarNft.sol";


contract PolarMarketPlace is Owners, ReentrancyGuard {
	event NewOffer(
		address indexed _nft, 
		uint _tokenId, 
		uint _price
	);
	
	event PurchaseOffer(
		address indexed _nft, 
		uint _tokenId 
	);
	
	event NewAuction(
		address indexed _nft, 
		uint _tokenId, 
		uint _currentPrice, 
		uint _end
	);
	
	event PurchaseAuction(
		address indexed _nft, 
		uint _tokenId, 
		uint _currentPrice
	);

	struct Offer {
		address owner;
		uint tokenId;
		uint price;
		uint creationTime;
	}

	struct Auction {
		address owner;
		uint tokenId;
		uint currentPrice;
		address nextOwner;
		uint end;
		uint creationTime;
	}

	struct MapOffer {
		uint[] keys; // tokenId to offers
		mapping(uint => Offer) values;
		mapping(uint => uint256) indexOf;
		mapping(uint => bool) inserted;
	}

	struct MapAuction {
		uint[] keys; // tokenId to auctions
		mapping(uint => Auction) values;
		mapping(uint => uint) indexOf;
		mapping(uint => bool) inserted;
	}
	
	struct Nft {
		MapOffer mapOffer;
		MapAuction mapAuction;
	}

	struct MapNft {
		address[] keys; // nft address to Nft struct
		mapping(address => Nft) values;
		mapping(address => uint) indexOf;
		mapping(address => bool) inserted;
	}

	struct MinPrices {
		uint offerPrice;
		uint auctionPrice;
	}

	struct MapPrices {
		string[] keys; // token name to min prices struct
		mapping(string => MinPrices) values;
		mapping(string => uint) indexOf;
		mapping(string => bool) inserted;
	}

	struct MapNftPrices {
		address[] keys; // nft address to MapPrices struct
		mapping(address => MapPrices) values;
		mapping(address => uint) indexOf;
		mapping(address => bool) inserted;
	}
	
	MapNft private nft;
	MapNftPrices private nftPrices;
	
	address public polar;
	address public swapper;
	uint public fee;

	bool public openOffer;
	bool public openAuction;
	mapping(address => bool) public onlyAttribute;

	mapping(address => bool) public isBlacklistedNft;

	uint public auctionBeforeRef;
	uint public auctionBeforeAdd;

	constructor(
		address _polar, 
		address _swapper, 
		uint _fee,
		uint _auctionBeforeRef,
		uint _auctionBeforeAdd
	) 
	{
		polar = _polar;
		swapper = _swapper;
		fee = _fee;
		auctionBeforeRef = _auctionBeforeRef;
		auctionBeforeAdd = _auctionBeforeAdd;
	}

	function setMinPrices(
		address _nft,
		string[] memory _names,
		uint[] memory _offerPrices,
		uint[] memory _auctionPrices	
	) 
		external 
		onlyOwners 
	{
		require(_names.length == _offerPrices.length, "PolarMarketPlace: Length mismatch");
		require(_names.length == _auctionPrices.length, "PolarMarketPlace: Length mismatch");
			
		IPolarNft(_nft).tokenIdsToType(0); // pseudo check polar standard
		//IPolarNft(_nft).getAttribute(0); // zero nft

		mapNftPricesAdd(_nft);
		for (uint i = 0; i < _names.length; i++) {
			mapPricesSet(nftPrices.values[_nft], _names[i], MinPrices({
				offerPrice: _offerPrices[i],
				auctionPrice: _auctionPrices[i]
			}));
		}
	}

	function deleteMapPrice(address _nft, string[] memory names) external onlyOwners {
		MapPrices storage mapPrices = nftPrices.values[_nft];
		
		for (uint i = 0; i < names.length; i++)
			mapPricesRemove(mapPrices, names[i]);
		mapNftPricesDelete(_nft);
	}

	// external offer
	function sellOfferItem(address _nft, uint _tokenId, uint _price) external nonReentrant {
		require(_price > 0, "PolarMarketPlace: Price must be greater than 0");
		require(!isBlacklistedNft[_nft], "PolarMarketPlace: Not authorized contract");
		require(openOffer, "PolarMarketPlace: Not open");

		if (nftPrices.inserted[_nft]) {
			string memory name = IPolarNft(_nft).tokenIdsToType(_tokenId);

			MapPrices storage mapPrices = nftPrices.values[_nft];
			require(mapPrices.inserted[name], "PolarMarketPlace: Contact core team");
			require(mapPrices.values[name].offerPrice <= _price, 
					"PolarMarketPlace: Price lower than min price");

			if (onlyAttribute[_nft]) {
				string memory attribute = IPolarNft(_nft).getAttribute(_tokenId);
				require(bytes(attribute).length > 0, 
						"PolarMarketPlace: Only special Nft");
			}
		}

		IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);
		
		mapNftAdd(_nft);
		mapOfferSet(nft.values[_nft].mapOffer, _tokenId, Offer({
			owner: msg.sender,
			tokenId: _tokenId,
			price: _price,
			creationTime: block.timestamp
		}));

		emit NewOffer(_nft, _tokenId, _price);
	}

	function purchaseOfferItem(address _nft, uint _tokenId) external nonReentrant {
		require(nft.inserted[_nft], "PolarMarketPlace: Nft contract is not setup");
		require(nft.values[_nft].mapOffer.inserted[_tokenId], "PolarMarketPlace: Item doesnt exist");

		Offer memory offer = nft.values[_nft].mapOffer.values[_tokenId];

		require(offer.owner != msg.sender, "PolarMarketPlace: You cannot buy your own nft");

		uint feePrice = offer.price * fee / 10000;

		IERC20(polar).transferFrom(msg.sender, offer.owner, offer.price - feePrice);
		if (feePrice > 0)
			IERC20(polar).transferFrom(msg.sender, swapper, feePrice);
		IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);

		mapOfferRemove(nft.values[_nft].mapOffer, _tokenId);
		mapNftDelete(_nft);
		
		emit PurchaseOffer(_nft, _tokenId);
	}

	function recoverOfferItem(address _nft, uint _tokenId) external nonReentrant {
		require(nft.inserted[_nft], "PolarMarketPlace: Nft contract is not setup");
		require(nft.values[_nft].mapOffer.inserted[_tokenId], "PolarMarketPlace: Item doesnt exist");
		
		Offer memory offer = nft.values[_nft].mapOffer.values[_tokenId];

		require(offer.owner == msg.sender || isOwner[msg.sender], "PolarMarketPlace: Unauthorized");

		IERC721(_nft).transferFrom(address(this), offer.owner, _tokenId);
		
		mapOfferRemove(nft.values[_nft].mapOffer, _tokenId);
		mapNftDelete(_nft);
	}

	// external auction
	function sellAuctionItem(
		address _nft, 
		uint _tokenId, 
		uint _currentPrice, 
		uint _end
	) 
		external
		nonReentrant
	{
		require(!isBlacklistedNft[_nft], "PolarMarketPlace: Not authorized contract");
		require(openAuction, "PolarMarketPlace: Not open");
		
		if (nftPrices.inserted[_nft]) {
			string memory name = IPolarNft(_nft).tokenIdsToType(_tokenId);

			MapPrices storage mapPrices = nftPrices.values[_nft];
			require(mapPrices.inserted[name], "PolarMarketPlace: Contact core team");
			require(mapPrices.values[name].auctionPrice <= _currentPrice, 
					"PolarMarketPlace: Price lower than min price");
			
			if (onlyAttribute[_nft]) {
				string memory attribute = IPolarNft(_nft).getAttribute(_tokenId);
				require(bytes(attribute).length > 0, 
						"PolarMarketPlace: Only special Nft");
			}
		}
		
		IERC721(_nft).transferFrom(msg.sender, address(this), _tokenId);

		mapNftAdd(_nft);
		mapAuctionSet(nft.values[_nft].mapAuction, _tokenId, Auction({
			owner: msg.sender,
			tokenId: _tokenId,
			currentPrice: _currentPrice,
			nextOwner: msg.sender,
			end: _end,
			creationTime: block.timestamp
		}));
		
		emit NewAuction(_nft, _tokenId, _currentPrice, _end);
	}
	
	function purchaseAuctionItem(address _nft, uint _tokenId, uint _currentPrice) external nonReentrant {
		require(nft.inserted[_nft], "PolarMarketPlace: Nft contract is not setup");
		require(nft.values[_nft].mapAuction.inserted[_tokenId], "PolarMarketPlace: Item doesnt exist");

		Auction memory auction = nft.values[_nft].mapAuction.values[_tokenId];

		require(auction.owner != msg.sender, "PolarMarketPlace: You cannot buy your own nft");
		require(block.timestamp < auction.end, "PolarMarketPlace: Auction already finished");
		require(_currentPrice > auction.currentPrice, 
				"PolarMarketPlace: New price must be bigger than current one");

		if (auction.owner != auction.nextOwner)
			IERC20(polar).transfer(auction.nextOwner, auction.currentPrice);
		IERC20(polar).transferFrom(msg.sender, address(this), _currentPrice);

		uint endTime = auction.end;
		if (block.timestamp + auctionBeforeRef > auction.end)
			endTime = block.timestamp + auctionBeforeAdd;

		mapAuctionSet(nft.values[_nft].mapAuction, _tokenId, Auction({
			owner: auction.owner,
			tokenId: auction.tokenId,
			currentPrice: _currentPrice,
			nextOwner: msg.sender,
			end: endTime,
			creationTime: auction.creationTime
		}));
		
		emit PurchaseAuction(_nft, _tokenId, _currentPrice);
	}

	function recoverAuctionItem(address _nft, uint _tokenId) external nonReentrant {
		require(nft.inserted[_nft], "PolarMarketPlace: Nft contract is not setup");
		require(nft.values[_nft].mapAuction.inserted[_tokenId], "PolarMarketPlace: Item doesnt exist");
		
		Auction memory auction = nft.values[_nft].mapAuction.values[_tokenId];

		require(auction.nextOwner == msg.sender || isOwner[msg.sender], "PolarMarketPlace: Unauthorized");
		require(block.timestamp >= auction.end, "PolarMarketPlace: Auction not finished yet");

		if (auction.owner != auction.nextOwner) {
			uint feePrice = auction.currentPrice * fee / 10000;

			IERC20(polar).transfer(auction.owner, auction.currentPrice - feePrice);
			if (feePrice > 0)
				IERC20(polar).transfer(swapper, feePrice);
		}

		IERC721(_nft).transferFrom(address(this), auction.nextOwner, _tokenId);

		mapAuctionRemove(nft.values[_nft].mapAuction, _tokenId);
		mapNftDelete(_nft);
	}
	
	function forceAuctionEnd(address _nft, uint _tokenId) external onlyOwners {
		require(nft.inserted[_nft], "PolarMarketPlace: Nft contract is not setup");
		require(nft.values[_nft].mapAuction.inserted[_tokenId], "PolarMarketPlace: Item doesnt exist");
		
		Auction memory auction = nft.values[_nft].mapAuction.values[_tokenId];

		if (auction.owner != auction.nextOwner) {
			uint feePrice = auction.currentPrice * fee / 10000;

			IERC20(polar).transfer(auction.owner, auction.currentPrice - feePrice);
			if (feePrice > 0)
				IERC20(polar).transfer(swapper, feePrice);
		}

		IERC721(_nft).transferFrom(address(this), auction.nextOwner, _tokenId);

		mapAuctionRemove(nft.values[_nft].mapAuction, _tokenId);
		mapNftDelete(_nft);
	}

	// external setters
	function setPolar(address _new) external onlyOwners {
		polar = _new;
	}
	
	function setSwapper(address _new) external onlyOwners {
		polar = _new;
	}
	
	function setFee(uint _new) external onlyOwners {
		fee = _new;
	}
	
	function setIsBlacklistedNft(address _nft, bool _new) external onlyOwners {
		isBlacklistedNft[_nft] = _new;
	}
	
	function setOpenOffer(bool _new) external onlyOwners {
		openOffer = _new;
	}
	
	function setOpenAuction(bool _new) external onlyOwners {
		openAuction = _new;
	}
	
	function setOnlyAttribute(address _addr, bool _new) external onlyOwners {
		onlyAttribute[_addr] = _new;
	}
	
	function setAuctionBefore(
		uint _auctionBeforeRef,
		uint _auctionBeforeAdd
	) 
		external 
		onlyOwners 
	{
		auctionBeforeRef = _auctionBeforeRef;
		auctionBeforeAdd = _auctionBeforeAdd;
	}

	//external view
	// map nft
	function getNftSize() external view returns(uint) {
		return nft.keys.length;
	}

	function getNftAddressBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(
			address[] memory
		) 
	{
		address[] memory addresses = new address[](iEnd - iStart);
		for (uint256 i = iStart; i < iEnd; i++)
			addresses[i - iStart] = nft.keys[i];
		return addresses;
	}

	function getNftAddressAll() external view returns(address[] memory) {
		return nft.keys;
	}

	// map offer
	function getOfferOfSize(address _nft) external view returns(uint) {
		return nft.values[_nft].mapOffer.keys.length;
	}
	
	function getOfferOfKeysBetweenIndexes(
		address _nft, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view
		returns(
			uint[] memory
		)
	{
		uint[] memory tokenIds = new uint[](iEnd - iStart);
		MapOffer storage mapOffer = nft.values[_nft].mapOffer;
		for (uint256 i = iStart; i < iEnd; i++)
			tokenIds[i - iStart] = mapOffer.keys[i];
		return tokenIds;
	}

	function getOfferOfBetweenIndexes(
		address _nft, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view
		returns(
			Offer[] memory
		)
	{
		Offer[] memory offers = new Offer[](iEnd - iStart);
		MapOffer storage mapOffer = nft.values[_nft].mapOffer;
		for (uint256 i = iStart; i < iEnd; i++)
			offers[i - iStart] = mapOffer.values[mapOffer.keys[i]];
		return offers;
	}

	// map auction
	function getAuctionOfSize(address _nft) external view returns(uint) {
		return nft.values[_nft].mapAuction.keys.length;
	}
	
	function getAuctionOfKeysBetweenIndexes(
		address _nft, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view
		returns(
			uint[] memory
		)
	{
		uint[] memory tokenIds = new uint[](iEnd - iStart);
		MapAuction storage mapAuction = nft.values[_nft].mapAuction;
		for (uint256 i = iStart; i < iEnd; i++)
			tokenIds[i - iStart] = mapAuction.keys[i];
		return tokenIds;
	}

	function getAuctionOfBetweenIndexes(
		address _nft, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view
		returns(
			Auction[] memory
		)
	{
		Auction[] memory auctions = new Auction[](iEnd - iStart);
		MapAuction storage mapAuction = nft.values[_nft].mapAuction;
		for (uint256 i = iStart; i < iEnd; i++)
			auctions[i - iStart] = mapAuction.values[mapAuction.keys[i]];
		return auctions;
	}

	// map nft price
	function getNftPricesSize() external view returns(uint) {
		return nftPrices.keys.length;
	}

	function getNftPricesAddressBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(
			address[] memory
		) 
	{
		address[] memory addresses = new address[](iEnd - iStart);
		for (uint256 i = iStart; i < iEnd; i++)
			addresses[i - iStart] = nftPrices.keys[i];
		return addresses;
	}

	function getNftPricesAddressAll() external view returns(address[] memory) {
		return nftPrices.keys;
	}

	// map prices
	function getPricesOfSize(address _nft) external view returns(uint) {
		return nftPrices.values[_nft].keys.length;
	}
	
	function getPricesOfKeysBetweenIndexes(
		address _nft, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view
		returns(
			string[] memory
		)
	{
		string[] memory names = new string[](iEnd - iStart);
		MapPrices storage mapPrices = nftPrices.values[_nft];
		for (uint256 i = iStart; i < iEnd; i++)
			names[i - iStart] = mapPrices.keys[i];
		return names;
	}

	function getPricesOfBetweenIndexes(
		address _nft, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view
		returns(
			MinPrices[] memory
		)
	{
		MinPrices[] memory prices = new MinPrices[](iEnd - iStart);
		MapPrices storage mapPrices = nftPrices.values[_nft];
		for (uint256 i = iStart; i < iEnd; i++)
			prices[i - iStart] = mapPrices.values[mapPrices.keys[i]];
		return prices;
	}

	// maps
	function mapOfferSet(
		MapOffer storage map,
        uint key,
        Offer memory value
    ) private {
        if (map.inserted[key]) {
            map.values[key] = value;
        } else {
            map.inserted[key] = true;
            map.values[key] = value;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
	
	function mapOfferRemove(MapOffer storage map, uint key) private {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

		if (lastIndex != index)
			map.keys[index] = lastKey;
        map.keys.pop();
    }
	
	function mapAuctionSet(
		MapAuction storage map,
        uint key,
        Auction memory value
    ) private {
        if (map.inserted[key]) {
            map.values[key] = value;
        } else {
            map.inserted[key] = true;
            map.values[key] = value;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
	
	function mapAuctionRemove(MapAuction storage map, uint key) private {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

		if (lastIndex != index)
			map.keys[index] = lastKey;
        map.keys.pop();
    }
	
	function mapNftAdd(
        address key
    ) private {
        if (nft.inserted[key]) {
			return;
        } else {
            nft.inserted[key] = true;
            nft.indexOf[key] = nft.keys.length;
            nft.keys.push(key);
        }
    }
	
	function mapNftDelete(
        address key
    ) private {
        if (!nft.inserted[key]) {
			return;
        } else {
			uint sizeOffer = nft.values[key].mapOffer.keys.length;
			uint sizeAuction = nft.values[key].mapAuction.keys.length;
			if (sizeOffer == 0 && sizeAuction == 0) {
				delete nft.inserted[key];
				delete nft.values[key];

				uint256 index = nft.indexOf[key];
				uint256 lastIndex = nft.keys.length - 1;
				address lastKey = nft.keys[lastIndex];

				nft.indexOf[lastKey] = index;
				delete nft.indexOf[key];

				if (lastIndex != index)
					nft.keys[index] = lastKey;
				nft.keys.pop();
			}
        }
    }
	
	function mapPricesSet(
		MapPrices storage map,
        string memory key,
        MinPrices memory value
    ) private {
        if (map.inserted[key]) {
            map.values[key] = value;
        } else {
            map.inserted[key] = true;
            map.values[key] = value;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
	
	function mapPricesRemove(MapPrices storage map, string memory key) private {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        string memory lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

		if (lastIndex != index)
			map.keys[index] = lastKey;
        map.keys.pop();
    }
	
	function mapNftPricesAdd(
        address key
    ) private {
        if (nftPrices.inserted[key]) {
			return;
        } else {
            nftPrices.inserted[key] = true;
            nftPrices.indexOf[key] = nftPrices.keys.length;
            nftPrices.keys.push(key);
        }
    }
	
	function mapNftPricesDelete(
        address key
    ) private {
        if (!nftPrices.inserted[key]) {
			return;
        } else {
			uint sizePrices = nftPrices.values[key].keys.length;
			if (sizePrices == 0) {
				delete nftPrices.inserted[key];
				delete nftPrices.values[key];

				uint256 index = nftPrices.indexOf[key];
				uint256 lastIndex = nftPrices.keys.length - 1;
				address lastKey = nftPrices.keys[lastIndex];

				nftPrices.indexOf[lastKey] = index;
				delete nftPrices.indexOf[key];

				if (lastIndex != index)
					nftPrices.keys[index] = lastKey;
				nftPrices.keys.pop();
			}
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


contract Owners {
	
	address[] public owners;
	mapping(address => bool) public isOwner;

	constructor() {
		owners.push(msg.sender);
		isOwner[msg.sender] = true;
	}

	modifier onlySuperOwner() {
		require(owners[0] == msg.sender, "Owners: Only Super Owner");
		_;
	}
	
	modifier onlyOwners() {
		require(isOwner[msg.sender], "Owners: Only Owner");
		_;
	}

	function addOwner(address _new, bool _change) external onlySuperOwner {
		require(!isOwner[_new], "Owners: Already owner");
		isOwner[_new] = true;
		if (_change) {
			owners.push(owners[0]);
			owners[0] = _new;
		} else {
			owners.push(_new);
		}
	}

	function removeOwner(address _new) external onlySuperOwner {
		require(isOwner[_new], "Owners: Not owner");
		require(_new != owners[0], "Owners: Cannot remove super owner");
		for (uint i = 1; i < owners.length; i++) {
			if (owners[i] == _new) {
				owners[i] = owners[owners.length - 1];
				owners.pop();
				break;
			}
		}
		isOwner[_new] = false;
	}

	function getOwnersSize() external view returns(uint) {
		return owners.length;
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPolarNft {
	function tokenIdsToType(uint tokenId) external view returns(string memory);
	function getAttribute(uint tokenId) external view returns(string memory);
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