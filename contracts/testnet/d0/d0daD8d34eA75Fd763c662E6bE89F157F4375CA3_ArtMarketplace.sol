//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibRoyalty {
	// calculated royalty
	struct Part {
		address account; // receiver address
		uint256 value; // receiver amount
	}

	// royalty information
	struct Royalty {
		address account; // receiver address
		uint96 value; // percentage of the royalty
	}
}

interface IRoyalty {
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
	function multiRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (LibRoyalty.Part[] memory);
	function getTokenRoyalties(uint256 _tokenId) external view returns (LibRoyalty.Royalty[] memory);
}

interface INFTCollectible {
	function owner() external returns (address);
}


// TODO 3 gün içinde harvest edebileceği bir fonksiyon lazım

contract ArtMarketplace is Ownable, ReentrancyGuard, ERC721Holder, Pausable {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;
	bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
	bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
	bytes4 private constant _INTERFACE_ID_MULTI_ROYALTY = 0x85f0c5d6;

	struct Node {
		uint256 price;
		uint64 previousIndex;
		uint64 nextIndex;
		uint256 tokenId;
		bool isActive;
	}

	struct Order {
		address seller;
		uint256 startedAt;
		uint256 price; // listing price
		bool isRewardable;
		uint64 nodeIndex;
	}
	/// @notice
	/// `amount` LP token amount the user has provided.
	/// `rewardDebt` The amount of ART entitled to the user.
	struct UserInfo {
		uint256 rewardableNftCount;
		uint256 rewardDebt;
	}

	/// @notice
	/// Also known as the amount of ART to distribute per block.
	struct PoolInfo {
		uint256 generationRate;
		uint256 accArtPerShare;
		uint256 lastRewardTimestamp;
		mapping(address => UserInfo) users;
		mapping(uint256 => Order) listedNfts;
		uint256 totalRewardableNftCount; //TODO activeNodeCount
		uint96 maxRoyalty;
		uint96 floorPriceIncreasePercentage;
		uint256 floorPrice;
		uint256 withdrawDuration;
		uint256 floorPriceThresholdNodeCount;
		uint96 commissionPercentage;
		Node[] nodes;
		uint64 floorPriceIndex;
		uint256 activeNodeCount;
	}

	/// @notice Address of ART contract.
	IERC20 public immutable ART;
	uint256 public maximumRoyaltyReceiversLimit;
	/**
	* @notice failed transfer amounts for each account are accumulated in this mapping.
    * e.g failedTransferBalance[bidder_address] = failed_balance;
    */
	mapping(address => uint256) public failedTransferBalance;

	mapping(address => PoolInfo) public pools;
	// Set of all LP tokens that have been added as pools
	EnumerableSet.AddressSet private lpCollections;
	uint256 private constant ACC_TOKEN_PRECISION = 1e18;

	/**
	* @notice the address that commission amounts will be transferred.
    */
	address payable public companyWallet;

	event Add(address indexed lpAddress, uint256 generationRate, uint96 maxRoyalty, uint256 floorPrice);
	event Deposit(address indexed user, address indexed lpAddress, uint256 tokenId, uint256 price);
	event Withdraw(address indexed user, address indexed lpAddress, uint256 tokenId);
	event Buy(address indexed user, address indexed lpAddress, uint256 tokenId, uint256 price);
	event UpdatePool(address indexed lpAddress, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accArtPerShare);
	event Harvest(address indexed user, address indexed lpAddress, uint256 amount);
	event MaximumRoyaltyReceiversLimitSet(uint256 maximumRoyaltyReceiversLimit);
	event WithdrawnFailedBalance(uint256 amount);
	event FailedTransfer(address indexed receiver, uint256 amount);
	event CompanyWalletSet(address indexed companyWalletset);
	event CommissionSent(address indexed collection, uint256 indexed tokenId, address _seller, uint256 commission, uint256 _price);
	event PayoutCompleted(address indexed collection, uint256 indexed tokenId, address indexed _seller, uint256 _price);
	event RoyaltyReceived(address indexed collection, uint256 indexed tokenId, address _seller, address indexed royaltyReceiver, uint256 amount);
	event FloorPriceUpdated(address indexed collection, uint256 floorPrice);
	event EndRewardPeriod(address indexed _lpAddress, uint256 _tokenId);
	/// @param _art The ART token contract address.
	constructor(IERC20 _art) {
		ART = _art;
		maximumRoyaltyReceiversLimit = 5;
	}

	receive() external payable {}

	function pause() external onlyOwner {
		_pause();
	}

	function unpause() external onlyOwner {
		_unpause();
	}

	function harvest(address _lpAddress) external {
		updatePool(_lpAddress);
		// Harvest ART
		uint256 pending = pools[_lpAddress].users[msg.sender].rewardableNftCount
		.mul(pools[_lpAddress].accArtPerShare)
		.div(ACC_TOKEN_PRECISION)
		.sub(pools[_lpAddress].users[msg.sender].rewardDebt);

		ART.transfer(msg.sender, pending);
		pools[_lpAddress].users[msg.sender].rewardDebt = pools[_lpAddress].users[msg.sender].rewardableNftCount.mul(pools[_lpAddress].accArtPerShare).div(ACC_TOKEN_PRECISION);
		emit Harvest(msg.sender, _lpAddress, pending);
	}

	function addNode(address _lpAddress, uint256 _tokenId, uint256 _price, uint64 _freeIndex, uint64 _previousIndex) internal {
		bool isFreeIndexExisting = _freeIndex < pools[_lpAddress].nodes.length && !pools[_lpAddress].nodes[_freeIndex].isActive;
		require(_freeIndex == pools[_lpAddress].nodes.length || isFreeIndexExisting, "freeIndex is not eligible");

		if (pools[_lpAddress].activeNodeCount == 0) {
			uint64 nodeIndex = 0;
			if (isFreeIndexExisting) {
				nodeIndex = _freeIndex;
				pools[_lpAddress].nodes[_freeIndex].price = _price;
				pools[_lpAddress].nodes[_freeIndex].previousIndex = _freeIndex;
				pools[_lpAddress].nodes[_freeIndex].nextIndex = _freeIndex;
				pools[_lpAddress].nodes[_freeIndex].isActive = true;
				pools[_lpAddress].nodes[_freeIndex].tokenId = _tokenId;
			} else {
				pools[_lpAddress].nodes.push(Node({
				price: _price,
				previousIndex: 0,
				nextIndex: 0,
				tokenId: _tokenId,
				isActive: true
				}));
			}

			pools[_lpAddress].listedNfts[_tokenId] = Order({
			seller: msg.sender,
			startedAt: block.timestamp,
			price: _price,
			isRewardable: true,
			nodeIndex: nodeIndex
			});
			pools[_lpAddress].floorPriceIndex = nodeIndex;
			pools[_lpAddress].activeNodeCount += 1;
		} else {
			// start
			if (_previousIndex == _freeIndex) {
				Node storage nextNode = pools[_lpAddress].nodes[pools[_lpAddress].floorPriceIndex];
				require(nextNode.isActive, "x"); // could not be tested
				require(nextNode.price > _price, "b");
				if (isFreeIndexExisting) {
					pools[_lpAddress].nodes[_freeIndex].price = _price;
					pools[_lpAddress].nodes[_freeIndex].previousIndex = _freeIndex;
					pools[_lpAddress].nodes[_freeIndex].nextIndex = pools[_lpAddress].floorPriceIndex;
					pools[_lpAddress].nodes[_freeIndex].isActive = true;
					pools[_lpAddress].nodes[_freeIndex].tokenId = _tokenId;
				} else {
					pools[_lpAddress].nodes.push(Node({
					price: _price,
					previousIndex: _freeIndex,
					nextIndex: pools[_lpAddress].floorPriceIndex,
					tokenId: _tokenId,
					isActive: true
					}));
				}
				nextNode.previousIndex = _freeIndex;

				pools[_lpAddress].floorPriceIndex = _freeIndex;
				pools[_lpAddress].listedNfts[_tokenId] = Order({
				seller: msg.sender,
				startedAt: block.timestamp,
				price: _price,
				isRewardable: true,
				nodeIndex: _freeIndex
				});
			} else {
				Node storage previousNode = pools[_lpAddress].nodes[_previousIndex];
				require(previousNode.isActive, "y");
				require(previousNode.price <= _price, "d");
				// end
				uint64 nextIndex = _freeIndex;
				if (previousNode.nextIndex != _previousIndex) {
					Node storage nextNode = pools[_lpAddress].nodes[previousNode.nextIndex];
					require(previousNode.price <= _price && _price <= nextNode.price, "f");
					nextNode.previousIndex = _freeIndex;
					nextIndex = previousNode.nextIndex;
				}
				previousNode.nextIndex = _freeIndex;


				if (isFreeIndexExisting) {
					pools[_lpAddress].nodes[_freeIndex].price = _price;
					pools[_lpAddress].nodes[_freeIndex].previousIndex = _previousIndex;
					pools[_lpAddress].nodes[_freeIndex].nextIndex = nextIndex;
					pools[_lpAddress].nodes[_freeIndex].isActive = true;
					pools[_lpAddress].nodes[_freeIndex].tokenId = _tokenId;
				} else {
					pools[_lpAddress].nodes.push(Node({
					price: _price,
					previousIndex: _previousIndex,
					nextIndex: nextIndex,
					tokenId: _tokenId,
					isActive: true
					}));
				}


				pools[_lpAddress].listedNfts[_tokenId] = Order({
				seller: msg.sender,
				startedAt: block.timestamp,
				price: _price,
				isRewardable: true,
				nodeIndex: _freeIndex
				});
			}
			pools[_lpAddress].activeNodeCount += 1;
		}
	}

	function dropNode(address _lpAddress, uint256 _tokenId) internal {
		uint64 nodeIndex = pools[_lpAddress].listedNfts[_tokenId].nodeIndex;

		Node storage currentNode = pools[_lpAddress].nodes[nodeIndex];
		Node storage previousNode = pools[_lpAddress].nodes[currentNode.previousIndex];
		Node storage nextNode = pools[_lpAddress].nodes[currentNode.nextIndex];

		if (nodeIndex == currentNode.previousIndex) {
			nextNode.previousIndex = currentNode.nextIndex;
			pools[_lpAddress].floorPriceIndex = currentNode.nextIndex;

			currentNode.isActive = false;
			currentNode.previousIndex = 0;
			currentNode.nextIndex = 0;
			currentNode.tokenId = 0;
			currentNode.price = 0;
		} else if (nodeIndex == currentNode.nextIndex) {
			previousNode.nextIndex = currentNode.previousIndex;

			currentNode.isActive = false;
			currentNode.previousIndex = 0;
			currentNode.nextIndex = 0;
			currentNode.tokenId = 0;
			currentNode.price = 0;
		} else {
			previousNode.nextIndex = currentNode.nextIndex;
			nextNode.previousIndex = currentNode.previousIndex;

			currentNode.isActive = false;
			currentNode.previousIndex = 0;
			currentNode.nextIndex = 0;
			currentNode.tokenId = 0;
			currentNode.price = 0;
		}

		pools[_lpAddress].nodes[nodeIndex].isActive = false;
		pools[_lpAddress].nodes[nodeIndex].nextIndex = 0;
		pools[_lpAddress].nodes[nodeIndex].previousIndex = 0;
		pools[_lpAddress].activeNodeCount -= 1;
	}

	function listNodes(address _lpAddress) external view returns (Node[] memory) {
		return pools[_lpAddress].nodes;
	}

	function getNode(address _lpAddress, uint64 _index) external view returns (Node memory) {
		return pools[_lpAddress].nodes[_index];
	}

	/**
	* @notice allows the owner to set a commission receiver address.
    * @param _companyWallet wallet address
    */
	function setCompanyWallet(address payable _companyWallet) external onlyOwner {
		companyWallet = _companyWallet;
		emit CompanyWalletSet(_companyWallet);
	}

	/**
* @notice Allows the owner to change maximumRoyaltyReceiversLimit.
    * @param _maximumRoyaltyReceiversLimit royalty receivers limit
    */
	function setMaximumRoyaltyReceiversLimit(uint256 _maximumRoyaltyReceiversLimit) external onlyOwner {
		maximumRoyaltyReceiversLimit = _maximumRoyaltyReceiversLimit;
		emit MaximumRoyaltyReceiversLimitSet(_maximumRoyaltyReceiversLimit);
	}

	function updatePoolFloorPrice(address _lpAddress, uint256 _floorPrice) external onlyOwner {
		require(lpCollections.contains(_lpAddress), "there is no any lp for this collection");

		pools[_lpAddress].floorPrice = _floorPrice;
		emit FloorPriceUpdated(_lpAddress, _floorPrice);
	}

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// @param _lpAddress Address of the LP ERC-721.
	function add(
		address _lpAddress,
		uint256 _generationRate,
		uint256 _floorPrice,
		uint256 _floorPriceThresholdNodeCount,
		uint96 _floorPriceIncreasePercentage,
		uint256 _withdrawDuration,
		uint96 _commissionPercentage,
		uint96 _maxRoyalty
	) external onlyOwner {
		require(!lpCollections.contains(_lpAddress), "add: LP already added");
		// check to ensure _lpCollection is an ERC721 address
		require(IERC721(_lpAddress).supportsInterface(_INTERFACE_ID_ERC721), "only erc721 is supported");

		pools[_lpAddress].generationRate = _generationRate;
		pools[_lpAddress].lastRewardTimestamp = block.timestamp;
		pools[_lpAddress].accArtPerShare = 0;
		pools[_lpAddress].maxRoyalty = _maxRoyalty;
		pools[_lpAddress].floorPrice = _floorPrice;
		pools[_lpAddress].floorPriceIncreasePercentage = _floorPriceIncreasePercentage;
		pools[_lpAddress].withdrawDuration = _withdrawDuration;
		pools[_lpAddress].commissionPercentage = _commissionPercentage;
		pools[_lpAddress].floorPriceThresholdNodeCount = _floorPriceThresholdNodeCount;


		lpCollections.add(_lpAddress);
		emit Add(_lpAddress, _generationRate, _maxRoyalty, _floorPrice);
	}

	function getListedNft(address _lpAddress, uint256 _tokenId) external view returns (Order memory) {
		return pools[_lpAddress].listedNfts[_tokenId];
	}

	function getUser(address _lpAddress, address _user) external view returns (UserInfo memory) {
		return pools[_lpAddress].users[_user];
	}

	function depositNft(address _lpAddress, uint256 _tokenId, uint256 _price, uint64 _freeIndex, uint64 _previousIndex) external priceAccepted(_price) whenNotPaused nonReentrant {
		require(lpCollections.contains(_lpAddress), "there is no any lp for this collection");
		require(pools[_lpAddress].listedNfts[_tokenId].seller == address(0), "nft already listed");
		require(IERC721(_lpAddress).ownerOf(_tokenId) == msg.sender, "sender doesn't own NFT");
		uint256 floorPrice = pools[_lpAddress].floorPrice;
		if (pools[_lpAddress].activeNodeCount > 0 && pools[_lpAddress].activeNodeCount >= pools[_lpAddress].floorPriceThresholdNodeCount) {
			floorPrice = pools[_lpAddress].nodes[pools[_lpAddress].floorPriceIndex].price;
		}
		require(_price <= floorPrice.mul((10000 + pools[_lpAddress].floorPriceIncreasePercentage)).div(10000), "cannot be higher than floor price");
		addNode(_lpAddress, _tokenId, _price, _freeIndex, _previousIndex);
		updatePool(_lpAddress);
		if (pools[_lpAddress].users[msg.sender].rewardableNftCount > 0) {
			// Harvest ART
			uint256 pending = pools[_lpAddress].users[msg.sender].rewardableNftCount
			.mul(pools[_lpAddress].accArtPerShare)
			.div(ACC_TOKEN_PRECISION)
			.sub(pools[_lpAddress].users[msg.sender].rewardDebt);

			ART.transfer(msg.sender, pending);
			emit Harvest(msg.sender, _lpAddress, pending);
		}

		IERC721(_lpAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
		pools[_lpAddress].listedNfts[_tokenId].seller = msg.sender;
		pools[_lpAddress].listedNfts[_tokenId].price = _price;
		pools[_lpAddress].listedNfts[_tokenId].startedAt = block.timestamp;
		pools[_lpAddress].listedNfts[_tokenId].isRewardable = true;


		pools[_lpAddress].users[msg.sender].rewardableNftCount = pools[_lpAddress].users[msg.sender].rewardableNftCount.add(1);
		pools[_lpAddress].totalRewardableNftCount = pools[_lpAddress].totalRewardableNftCount.add(1);
		pools[_lpAddress].users[msg.sender].rewardDebt = pools[_lpAddress].users[msg.sender].rewardableNftCount.mul(pools[_lpAddress].accArtPerShare).div(ACC_TOKEN_PRECISION);

		emit Deposit(msg.sender, _lpAddress, _tokenId, _price);
	}

	/// @notice View function to see pending ART on frontend.
	/// @param _lpAddress The address of the pool. See `pools`.
	/// @param _user Address of user.
	function pendingTokens(address _lpAddress, address _user)
	external
	view
	returns (uint256)
	{
		PoolInfo storage pool = pools[_lpAddress];
		UserInfo storage user = pools[_lpAddress].users[_user];
		uint256 accArtPerShare = pool.accArtPerShare;
		if (block.timestamp > pool.lastRewardTimestamp && pool.totalRewardableNftCount != 0) {
			uint256 secondsElapsed = block.timestamp.sub(pool.lastRewardTimestamp);
			uint256 artReward = secondsElapsed.mul(pool.generationRate);
			accArtPerShare = accArtPerShare.add(artReward.mul(ACC_TOKEN_PRECISION).div(pool.totalRewardableNftCount));
		}
		return user.rewardableNftCount.mul(accArtPerShare).div(ACC_TOKEN_PRECISION).sub(user.rewardDebt);
	}

	/// @notice Update reward variables for all pools. Be careful of gas spending!
	/// @param _lpAddresses Pool Addresses of all to be updated. Make sure to update all active pools.
	function massEndRewardPeriod(address[] calldata _lpAddresses, uint256[] calldata _tokenIds) external whenNotPaused {
		uint256 len = _lpAddresses.length;
		for (uint256 i = 0; i < len; ++i) {
			endRewardPeriod(_lpAddresses[i], _tokenIds[i]);
		}
	}

	function endRewardPeriod(address _lpAddress, uint256 _tokenId) public whenNotPaused {
		address seller = pools[_lpAddress].listedNfts[_tokenId].seller;
		require(lpCollections.contains(_lpAddress), "there is no any lp for this collection");
		require(seller != address(0), "nft is not listed");
		require(pools[_lpAddress].listedNfts[_tokenId].isRewardable, "nft already unstaked");
		require(block.timestamp - pools[_lpAddress].listedNfts[_tokenId].startedAt > pools[_lpAddress].withdrawDuration, "the minimum withdraw duration has not expired");

		updatePool(_lpAddress);
		if (pools[_lpAddress].users[seller].rewardableNftCount > 0) {
			// Harvest ART
			uint256 pending = pools[_lpAddress].users[seller].rewardableNftCount
			.mul(pools[_lpAddress].accArtPerShare)
			.div(ACC_TOKEN_PRECISION)
			.sub(pools[_lpAddress].users[seller].rewardDebt);

			ART.transfer(seller, pending);
			emit Harvest(seller, _lpAddress, pending);
		}

		// Effects
		pools[_lpAddress].users[seller].rewardableNftCount = pools[_lpAddress].users[seller].rewardableNftCount.sub(1);
		pools[_lpAddress].totalRewardableNftCount = pools[_lpAddress].totalRewardableNftCount.sub(1);
		pools[_lpAddress].users[seller].rewardDebt = pools[_lpAddress].users[seller].rewardableNftCount.mul(pools[_lpAddress].accArtPerShare).div(ACC_TOKEN_PRECISION);

		pools[_lpAddress].listedNfts[_tokenId].isRewardable = false;
		emit EndRewardPeriod(_lpAddress, _tokenId);
	}

	/// @notice Withdraw
	/// @param _lpAddress The address of the pool. See `poolInfo`.
	/// @param _tokenId LP tokenId to withdraw.
	function withdraw(address _lpAddress, uint256 _tokenId) external whenNotPaused nonReentrant {
		require(pools[_lpAddress].listedNfts[_tokenId].seller == msg.sender, "nft is not listed for msg.sender");
		require(block.timestamp - pools[_lpAddress].listedNfts[_tokenId].startedAt > pools[_lpAddress].withdrawDuration, "the minimum withdraw duration has not expired");
		dropNode(_lpAddress, _tokenId);

		updatePool(_lpAddress);

		if (pools[_lpAddress].users[msg.sender].rewardableNftCount > 0) {
			// Harvest ART
			uint256 pending = pools[_lpAddress].users[msg.sender].rewardableNftCount
			.mul(pools[_lpAddress].accArtPerShare)
			.div(ACC_TOKEN_PRECISION)
			.sub(pools[_lpAddress].users[msg.sender].rewardDebt);

			ART.transfer(msg.sender, pending);
			emit Harvest(msg.sender, _lpAddress, pending);
		}

		// Effects
		if (pools[_lpAddress].listedNfts[_tokenId].isRewardable) {
			pools[_lpAddress].users[msg.sender].rewardableNftCount = pools[_lpAddress].users[msg.sender].rewardableNftCount.sub(1);
			pools[_lpAddress].totalRewardableNftCount = pools[_lpAddress].totalRewardableNftCount.sub(1);
		}
		pools[_lpAddress].users[msg.sender].rewardDebt = pools[_lpAddress].users[msg.sender].rewardableNftCount.mul(pools[_lpAddress].accArtPerShare).div(ACC_TOKEN_PRECISION);

		pools[_lpAddress].listedNfts[_tokenId].seller = address(0x0);
		pools[_lpAddress].listedNfts[_tokenId].price = 0;
		pools[_lpAddress].listedNfts[_tokenId].startedAt = 0;
		pools[_lpAddress].listedNfts[_tokenId].isRewardable = false;
		pools[_lpAddress].listedNfts[_tokenId].nodeIndex = 0;

		IERC721(_lpAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

		emit Withdraw(msg.sender, _lpAddress, _tokenId);
	}


	/// @notice
	/// @param _lpAddress The address of the pool. See `poolInfo`.
	/// @param _tokenId LP tokenId to withdraw.
	function buyNft(address _lpAddress, uint256 _tokenId) external payable nonReentrant whenNotPaused {
		address seller = pools[_lpAddress].listedNfts[_tokenId].seller;
		require(seller != address(0x0), "nft is not listed");
		require(seller != msg.sender, "cannot buy own nft");
		require(msg.value >= pools[_lpAddress].listedNfts[_tokenId].price, "insufficient payment");
		dropNode(_lpAddress, _tokenId);
		updatePool(_lpAddress);

		if (pools[_lpAddress].users[seller].rewardableNftCount > 0) {
			// Harvest ART
			uint256 pending = pools[_lpAddress].users[seller].rewardableNftCount
			.mul(pools[_lpAddress].accArtPerShare)
			.div(ACC_TOKEN_PRECISION)
			.sub(pools[_lpAddress].users[seller].rewardDebt);

			ART.transfer(seller, pending);
			emit Harvest(seller, _lpAddress, pending);
		}

		if (pools[_lpAddress].listedNfts[_tokenId].isRewardable) {
			pools[_lpAddress].users[seller].rewardableNftCount = pools[_lpAddress].users[seller].rewardableNftCount.sub(1);
			pools[_lpAddress].totalRewardableNftCount = pools[_lpAddress].totalRewardableNftCount.sub(1);
		}
		pools[_lpAddress].users[seller].rewardDebt = pools[_lpAddress].users[seller].rewardableNftCount.mul(pools[_lpAddress].accArtPerShare).div(ACC_TOKEN_PRECISION);

		uint256 price = pools[_lpAddress].listedNfts[_tokenId].price;
		pools[_lpAddress].listedNfts[_tokenId].seller = address(0x0);
		pools[_lpAddress].listedNfts[_tokenId].price = 0;
		pools[_lpAddress].listedNfts[_tokenId].startedAt = 0;
		pools[_lpAddress].listedNfts[_tokenId].isRewardable = false;
		pools[_lpAddress].listedNfts[_tokenId].nodeIndex = 0;

		IERC721(_lpAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
		if (price > 0) {
			_payout(payable(seller), _lpAddress, _tokenId, price, pools[_lpAddress].commissionPercentage);
		}
		if (msg.value > price) {
			payable(msg.sender).transfer(msg.value - price);
		}

		emit Buy(msg.sender, _lpAddress, _tokenId, price);
	}

	/**
	* @notice failed transfers are stored in `failedTransferBalance`. In the case of failure, users can withdraw failed balances.
    */
	function withdrawFailedCredits(address _address) external whenNotPaused nonReentrant {
		uint256 amount = failedTransferBalance[_address];

		require(amount > 0, "no credits to withdraw");

		failedTransferBalance[_address] = 0;
		(bool successfulWithdraw, ) = payable(_address).call{value: amount}("");
		require(successfulWithdraw, "withdraw failed");
		emit WithdrawnFailedBalance(amount);
	}

	/// @notice Update reward variables of the given pool.
	/// @param _lpAddress The address of the pool. See `poolInfo`.
	function updatePool(address _lpAddress) internal {
		PoolInfo storage pool = pools[_lpAddress];
		if (block.timestamp > pool.lastRewardTimestamp) {
			if (pool.totalRewardableNftCount > 0) {
				uint256 secondsElapsed = block.timestamp.sub(pool.lastRewardTimestamp);
				uint256 artReward = secondsElapsed.mul(pool.generationRate);
				pool.accArtPerShare = pool.accArtPerShare.add((artReward.mul(ACC_TOKEN_PRECISION).div(pool.totalRewardableNftCount)));
			}
			pool.lastRewardTimestamp = block.timestamp;
			emit UpdatePool(_lpAddress, pool.lastRewardTimestamp, pool.totalRewardableNftCount, pool.accArtPerShare);
		}
	}

	/**
	* @notice process the payment for the allowed requests. Process is completed in 3 steps; commission transfer, royalty transfers and revenue share transfers.
    * Commission Transfer: if commission rate higher than 0, the amount of commission is deducted from the main amount. The remaining amount will be processed at royalty transfers.
    * Royalty Transfer: Firstly checks whether the nft contract address supports multi royalty or not. If supported, the royalties will be sent to each user defined for the nft. If not, it runs the single royalty protocol for the nft and sends calculated royalty to the receiver. The remaining amount will be processed at revenue share.
    * Revenue Share: Remaining amount split into the accounts that defined on _shareholders parameter.
    * @param _seller an address the payment will be sent
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
	function _payout(
		address payable _seller,
		address _nftContractAddress,
		uint256 _tokenId,
		uint256 _price,
		uint96 _commissionPercentage
	) internal {
		uint256 remainder = _price;
		// commission step
		uint256 commission = _getPortionOfBid(_price, _commissionPercentage);
		if (commission > 0) {
			remainder -= commission;
			companyWallet.transfer(commission);
			emit CommissionSent(_nftContractAddress, _tokenId, _seller, commission, _price);
		}

		if (IERC721(_nftContractAddress).supportsInterface(_INTERFACE_ID_EIP2981)) {
			(address royaltyReceiver, uint256 royaltyAmount) = IRoyalty(_nftContractAddress).royaltyInfo(_tokenId, _price);
			if (royaltyReceiver != _seller && royaltyReceiver != address(0)) {
				if (royaltyAmount.mul(10000).div(_price) > pools[_nftContractAddress].maxRoyalty) {
					royaltyAmount = _price.mul(pools[_nftContractAddress].maxRoyalty).div(10000);
				}
				remainder -= royaltyAmount;
				_safeTransferTo(payable(royaltyReceiver), royaltyAmount);
				emit RoyaltyReceived(_nftContractAddress, _tokenId, _seller, royaltyReceiver, royaltyAmount);
			}
		}

		// if still there is a remainder amount then send to the seller
		if (remainder > 0) {
			_safeTransferTo(_seller, remainder);
		}
		emit PayoutCompleted(_nftContractAddress, _tokenId, _seller, remainder);
	}

	function _safeTransferTo(address _recipient, uint256 _amount) internal {
		(bool success, ) = payable(_recipient).call{value: _amount, gas: 20000}("");
		// if it fails, it updates their credit balance so they can withdraw later
		if (!success) {
			failedTransferBalance[_recipient] += _amount;
			emit FailedTransfer(_recipient, _amount);
		}
	}

	function _getPortionOfBid(uint256 _totalBid, uint256 _percentage) internal pure returns (uint256) { return (_totalBid * (_percentage)) / 10000; }

	/**
	* @notice makes sure price is greater than 0
    */
	modifier priceAccepted(uint256 _price) {
		require(_price > 0, "Price must be grater then zero");
		_;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}