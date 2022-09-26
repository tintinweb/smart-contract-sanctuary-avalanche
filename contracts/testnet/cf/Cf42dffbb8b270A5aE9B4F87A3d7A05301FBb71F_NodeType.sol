// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Owners.sol";


contract NodeType is Owners {

	struct Node {
		address owner;
		uint creationTime;
		uint lastClaimTime;
		uint isBoostedAirDropRate;
		string feature;
		uint price;
		uint futurUse0;
		uint futurUse1;
		uint futurUse2;
	}

	struct User {
		uint[] keys; // userTokenId
		mapping(uint => Node) values;
		mapping(uint => uint) indexOf;
		mapping(uint => bool) inserted;
		uint countLevelUp;
		uint countPending;
	}

	mapping(address => User) private userOf;
	mapping(uint => address) public tokenIdToOwner;

	string public name;

	uint public totalCreatedNodes;

	uint public maxCount;
	uint public price;
	uint public claimTime;
	uint public rewardAmount;
	uint public claimTaxRoi;
	uint public maxLevelUpUser;
	uint public maxLevelUpTotal;
	uint public maxCreationPendingUser;
	uint public maxCreationPendingTotal;
	uint public maxUser;
	uint public noClaimRewardAmount;
	uint public noClaimTimeReference;
	uint public globalTax;
	uint public claimTimeReference;
	uint public claimTimeRate;
	uint public maxMultiClaim;

	bool public openCreateNodesWithTokens = false;
	bool public openCreateNodesLevelUp = false;
	bool public openCreateNodesWithPending = false;
	bool public openCreateNodesWithLuckyBoxes = false;

	string[] features;
	mapping(string => uint) public featureToBoostRate;
	mapping(string => uint) public featureCount;
	
	address[] public nodeOwners;
	mapping(address => bool) public nodeOwnersInserted;

	address public handler;

	uint private nonce;
	bool private initialized;

	modifier onlyOnce() {
		require(!initialized, "NodeType: Already initialized");
		_;
		initialized = true;
	}

	function init(
		string memory _name, 
		uint[] memory values, 
		address _handler 
	) 
		external
		onlyOnce
		onlyOwners
	{
		require(bytes(_name).length > 0, "NodeType: Name cannot be empty");
		name = _name;

		require(values.length == 16, "NodeType: Values.length mismatch");
		maxCount = values[0];
		price = values[1];
		claimTime = values[2];
		rewardAmount = values[3];
		claimTaxRoi = values[4];
		maxLevelUpUser = values[5];
		maxLevelUpTotal = values[6];
		maxCreationPendingUser = values[7];
		maxCreationPendingTotal = values[8];
		maxUser = values[9];
		noClaimTimeReference = values[10];
		noClaimRewardAmount = values[11];
		globalTax = values[12];
		claimTimeReference = values[13];
		claimTimeRate = values[14];
		maxMultiClaim = values[15];

		handler = _handler;
	}

	modifier onlyHandler() {
		require(msg.sender == handler, "NodeType: Only Handler");
		_;
	}

	// External tokens like
	function transferFrom(address from, address to, uint tokenId) external onlyHandler {
		require(userOf[from].inserted[tokenId], "NodeType: Transfer failure");
		if (nodeOwnersInserted[to] == false) {
			nodeOwners.push(to);
			nodeOwnersInserted[to] = true;
		}
		User storage u = userOf[from];
		u.values[tokenId].owner = to;
		userSet(userOf[to], tokenId, u.values[tokenId]);
		userRemove(userOf[from], tokenId);
		tokenIdToOwner[tokenId] = to;
	}

	function burnFrom(address from, uint[] calldata tokenIds) external onlyHandler returns(uint) {
		for (uint i = 0; i < tokenIds.length; i++) {
			require(userOf[from].inserted[tokenIds[i]], "NodeType: Burn failure");

			Node memory n = userOf[from].values[tokenIds[i]];
			if (featureCount[n.feature] > 0)
				featureCount[n.feature]--;

			userRemove(userOf[from], tokenIds[i]);
			tokenIdToOwner[tokenIds[i]] = address(0);
		}
		totalCreatedNodes -= tokenIds.length;
		return price * tokenIds.length;
	}

	// External Nodes Creations
	function createNodesWithTokens(
		address user, 
		uint[] calldata tokenIds 
	)
		external
		onlyHandler
		returns(uint)
	{
		require(openCreateNodesWithTokens, "NodeType: Not open");
		_createNodes(user, tokenIds, "", 0);
		require(totalCreatedNodes <= maxCount, "NodeType: Too many nodes requested");
		require(userOf[user].keys.length <= maxUser, "NodeType: User too many nodes requested");
		return tokenIds.length * price; // transfer from user
	}

	function createNodesLevelUp(
		address user,
		uint[] calldata tokenIds 
	)
		external 
		onlyHandler
		returns(uint)
	{
		require(openCreateNodesLevelUp, "NodeType: Not open");
		require(
			maxLevelUpTotal >= tokenIds.length, 
			"NodeType: Not enough level up spots left"
		);
		maxLevelUpTotal -= tokenIds.length;

		userOf[user].countLevelUp += tokenIds.length;
		require(userOf[user].countLevelUp <= maxLevelUpUser,
			"NodeType: Not enough level up spots left for this user"
		);
		
		_createNodes(user, tokenIds, "", 0);
		require(totalCreatedNodes <= maxCount, "NodeType: Too many nodes requested");
		require(userOf[user].keys.length <= maxUser, "NodeType: User too many nodes requested");
		return tokenIds.length * price; // price to destroy
	}

	function createNodesWithPendings(
		address user,
		uint[] calldata tokenIds
	)
		external 
		onlyHandler
		returns(uint)
	{
		require(openCreateNodesWithPending, "NodeType: Not open");
		require(
			maxCreationPendingTotal >= tokenIds.length, 
			"NodeType: Not enough creation with pending spots left"
		);
		maxCreationPendingTotal -= tokenIds.length;

		userOf[user].countPending += tokenIds.length;
		require(userOf[user].countPending <= maxCreationPendingUser,
			"NodeType: Not enough creation with pending spots left for this user"
		);
		
		_createNodes(user, tokenIds, "", 0);
		require(totalCreatedNodes <= maxCount, "NodeType: Too many nodes requested");
		require(userOf[user].keys.length <= maxUser, "NodeType: User too many nodes requested");
		return tokenIds.length * price; // to claim
	}
	
	function createNodeWithLuckyBox(
		address user, 
		uint[] calldata tokenIds,
		string calldata feature
	)
		external
		onlyHandler
	{
		require(openCreateNodesWithLuckyBoxes, "NodeType: Not open");
		_createNodes(user, tokenIds, feature, 0);
	}

	function createNodeCustom(
		address user,
		uint isBoostedAirDropRate,
		uint[] calldata tokenIds, 
		string calldata feature
	)
		external
		onlyHandler
	{
		if (bytes(feature).length > 0)
			require(featureToBoostRate[feature] != 0, "NodeType: Feature doesnt exist");
		_createNodes(
			user, 
			tokenIds, 
			feature, 
			isBoostedAirDropRate
		);
	}

	function claimRewardsAll(address user) external onlyHandler returns(uint, uint) {
		uint rewardsTotal;
		uint feesTotal;
		User storage u = userOf[user];

		for (uint i = 0; i < u.keys.length; i++) {
			Node storage userNode = u.values[u.keys[i]];
			(uint rewards, uint fees) = _calculateNodeRewards(userNode);
			rewardsTotal += rewards;
			feesTotal += fees;
			userNode.lastClaimTime = block.timestamp;
		}

		return (rewardsTotal, feesTotal); // transfer to user
	}
	
	function claimRewardsBatch(
		address user, 
		uint[] calldata tokenIds
	) 
		external 
		onlyHandler
		returns(uint, uint) 
	{
		uint rewardsTotal;
		uint feesTotal;
		User storage u = userOf[user];

		for (uint i = 0; i < tokenIds.length; i++) {
			require(u.inserted[tokenIds[i]], "NodeType: User doesnt own this node");
			Node storage userNode = u.values[tokenIds[i]];
			(uint rewards, uint fees) = _calculateNodeRewards(userNode);
			rewardsTotal += rewards;
			feesTotal += fees;
			userNode.lastClaimTime = block.timestamp;
		}

		return (rewardsTotal, feesTotal);
	}

	// External setters
	function addFeature(string calldata _name, uint _rate) external onlyOwners {
		require(featureToBoostRate[_name] == 0, "NodeType: Feature already exist");
		require(bytes(_name).length > 0, "NodeType: Name cannot be empty");
		features.push(_name);
		featureToBoostRate[_name] = _rate;
	}

	function updateFeature(string calldata _name, uint _rate) external onlyOwners {
		require(featureToBoostRate[_name] != 0, "NodeType: Feature doesnt exist");
		featureToBoostRate[_name] = _rate;
	}

	function setHandler(address _new) external onlySuperOwner {
		require(_new != address(0), "NodeType: Handler cannot be address zero");
		handler = _new;
	}
	
	function setBasics(
		uint _price,
		uint _claimTime,
		uint _rewardAmount
	) 
		external 
		onlyOwners 
	{
		require(_price > 0, "NodeType: Price cannot be zero");
		price = _price;
		require(_claimTime > 0, "NodeType: Claim Time cannot be zero");
		claimTime = _claimTime;
		require(_rewardAmount > 0, "NodeType: Reward Amount cannot be zero");
		rewardAmount = _rewardAmount;
	}

	function setTax(
		uint _claimTaxRoi,
		uint _globalTax
	) 
		external 
		onlyOwners 
	{
		claimTaxRoi = _claimTaxRoi;
		globalTax = _globalTax;
	}

	function setMax(
		uint _maxUser,
		uint _maxCount
	) 
		external 
		onlyOwners 
	{
		maxUser = _maxUser;
		maxCount = _maxCount;
	}
	
	function setMaxLevelUp(
		uint _maxLevelUpUser,
		uint _maxLevelUpTotal
	) 
		external 
		onlyOwners 
	{
		maxLevelUpUser = _maxLevelUpUser;
		maxLevelUpTotal = _maxLevelUpTotal;
	}
	
	function setMaxCreationPending(
		uint _maxCreationPendingUser,
		uint _maxCreationPendingTotal
	) 
		external 
		onlyOwners 
	{
		maxCreationPendingUser = _maxCreationPendingUser;
		maxCreationPendingTotal = _maxCreationPendingTotal;
	}
	
	function setTokenIdSpecs(
		uint tokenId, 
		uint _isBoostedAirDropRate,
		string calldata _feature
	)
		external 
		onlyOwners 
	{
		Node storage node = userOf[tokenIdToOwner[tokenId]].values[tokenId];

		node.isBoostedAirDropRate = _isBoostedAirDropRate;
		require(featureToBoostRate[_feature] != 0, "NodeType: Feature doesnt exist");
		node.feature = _feature;
	}
	
	function setNoClaimBoost(
		uint _noClaimRewardAmount,
		uint _noClaimTimeReference
	)
		external 
		onlyOwners 
	{
		noClaimRewardAmount = _noClaimRewardAmount;
		require(_noClaimTimeReference > 0, "NodeType: NoClaimTimeReference must be greater than zero");
		noClaimTimeReference = _noClaimTimeReference;
	}
	
	function setClaimTimeBoost(
		uint _claimTimeReference,
		uint _claimTimeRate
	) 
		external 
		onlyOwners 
	{
		require(_claimTimeReference > 0, "NodeType: Claim Time Reference cannot be zero");
		claimTimeReference = _claimTimeReference;
		claimTimeRate = _claimTimeRate;
	}
	
	function setMaxMulti(
		uint _maxMultiClaim
	) 
		external 
		onlyOwners 
	{
		maxMultiClaim = _maxMultiClaim;
	}
	
	function setOpenCreate(
		bool _openCreateNodesWithTokens,
		bool _openCreateNodesLevelUp,
		bool _openCreateNodesWithPending,
		bool _openCreateNodesWithLuckyBoxes
	) 
		external 
		onlyOwners 
	{
		openCreateNodesWithTokens = _openCreateNodesWithTokens;
		openCreateNodesLevelUp = _openCreateNodesLevelUp;
		openCreateNodesWithPending = _openCreateNodesWithPending;
		openCreateNodesWithLuckyBoxes = _openCreateNodesWithLuckyBoxes;
	}

	// external view
	function getTotalNodesNumberOf(address user) external view returns(uint) {
		return userOf[user].keys.length;
	}
	
	function getNodeFromTokenId(uint tokenId) external view returns(Node memory) {
		return userOf[tokenIdToOwner[tokenId]].values[tokenId];
	}
	
	function getNodesCountLevelUpOf(address user) external view returns(uint) {
		return userOf[user].countLevelUp;
	}
	
	function getNodesCountPendingOf(address user) external view returns(uint) {
		return userOf[user].countPending;
	}
	
	function getTokenIdsOfBetweenIndexes(
		address user, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(uint[] memory)
	{
		uint[] memory tokenIds = new uint[](iEnd - iStart);
		User storage u = userOf[user];
		for (uint256 i = iStart; i < iEnd; i++)
			tokenIds[i - iStart] = u.keys[i];
		return tokenIds;
	}

	function getNodesOfBetweenIndexes(
		address user, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(Node[] memory)
	{
		Node[] memory nodes = new Node[](iEnd - iStart);
		User storage u = userOf[user];
		for (uint256 i = iStart; i < iEnd; i++)
			nodes[i - iStart] = u.values[u.keys[i]];
		return nodes;
	}

	function getTimeRoiOfBetweenIndexes(
		address user, 
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(uint[] memory)
	{
		uint[] memory rois = new uint[](iEnd - iStart);
		User storage u = userOf[user];
		for (uint256 i = iStart; i < iEnd; i++) {
			Node memory node = u.values[u.keys[i]];
			rois[i - iStart] = node.price * claimTime / rewardAmount + node.creationTime;
		}
		return rois;
	}

	function getFeaturesSize() external view returns(uint) {
		return features.length;
	}
	
	function getFeaturesBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(string[] memory)
	{
		string[] memory f = new string[](iEnd - iStart);
		for (uint256 i = iStart; i < iEnd; i++)
			f[i - iStart] = features[i];
		return f;
	}

	function getNodeOwnersSize() external view returns(uint) {
		return nodeOwners.length;
	}

	function getAttribute(uint tokenId) external view returns(string memory) {
		Node memory node = userOf[tokenIdToOwner[tokenId]].values[tokenId];

        return node.feature;
	}
	
	function getNodeOwnersBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(address[] memory)
	{
		address[] memory no = new address[](iEnd - iStart);
		for (uint256 i = iStart; i < iEnd; i++)
			no[i - iStart] = nodeOwners[i];
		return no;
	}
	
	function calculateUserRewardsBatch(
		address user,
		uint[] memory tokenIds
	) 
		external 
		view
		returns(uint[] memory, uint[] memory) 
	{
		uint[] memory rewardsTotal = new uint[](tokenIds.length);
		uint[] memory feesTotal = new uint[](tokenIds.length);
		User storage u = userOf[user];

		for (uint i = 0; i < tokenIds.length; i++) {
			require(u.inserted[tokenIds[i]], "NodeType: User doesnt own this node");
			Node memory userNode = u.values[tokenIds[i]];
			(uint rewards, uint fees) = _calculateNodeRewards(userNode);
			rewardsTotal[i] = rewards;
			feesTotal[i] = fees;
		}

		return (rewardsTotal, feesTotal);
	}

	// public
	function calculateUserRewards(address user) public view returns(uint, uint) {
		uint rewardsTotal;
		uint feesTotal;
		User storage u = userOf[user];

		for (uint i = 0; i < u.keys.length; i++) {
			(uint rewards, uint fees) = _calculateNodeRewards(u.values[u.keys[i]]);
			rewardsTotal += rewards;
			feesTotal += fees;
		}

		return (rewardsTotal, feesTotal);
	}

	// internal

	// private
	function _createNodes(
		address user, 
		uint[] memory tokenIds, 
		string memory feature,
		uint isBoostedAirDropRate
	) private {
		require(tokenIds.length > 0, "NodeType: Nothing to create");

		if (nodeOwnersInserted[user] == false) {
			nodeOwners.push(user);
			nodeOwnersInserted[user] = true;
		}

		for (uint i = 0; i < tokenIds.length; i++) {
			Node memory node = Node ({
				owner: user,
				creationTime: block.timestamp,
				lastClaimTime: block.timestamp,
				isBoostedAirDropRate: isBoostedAirDropRate,
				feature: feature,
				price: price,
				futurUse0: 0,
				futurUse1: 0,
				futurUse2: 0
			});
			userSet(userOf[user], tokenIds[i], node);
			tokenIdToOwner[tokenIds[i]] = user;
		}

		featureCount[feature] += tokenIds.length;
		totalCreatedNodes += tokenIds.length;
	}

	function _calculateNodeRewards(Node memory node)
		private 
		view
		returns(uint, uint)
	{
		uint rewardsTotal;
		uint fees;

		rewardsTotal = rewardAmount * (block.timestamp - node.lastClaimTime) / claimTime;

		uint multi = (block.timestamp - node.lastClaimTime) / claimTimeReference;
		if (multi > 0) {
			multi = multi <= maxMultiClaim ? multi : maxMultiClaim;
			rewardsTotal = rewardsTotal * (10000 + claimTimeRate * multi) / 10000;
		}

		if (node.isBoostedAirDropRate > 0)
			rewardsTotal = rewardsTotal * (10000 + node.isBoostedAirDropRate) / 10000;

		if (featureToBoostRate[node.feature] > 0)
			rewardsTotal = rewardsTotal * (10000 + featureToBoostRate[node.feature]) / 10000;

		if (block.timestamp - node.lastClaimTime > noClaimTimeReference)
			rewardsTotal += noClaimRewardAmount;

		if (rewardAmount * (block.timestamp - node.creationTime) / claimTime < node.price && 
				claimTaxRoi > 0)
			rewardsTotal -= rewardsTotal * claimTaxRoi / 10000;
		else if (globalTax > 0)
			fees += rewardsTotal * globalTax / 10000;

		return (rewardsTotal - fees, fees);
	}

	function userSet(
        User storage user,
        uint key,
        Node memory value
    ) private {
        if (user.inserted[key]) {
            user.values[key] = value;
        } else {
            user.inserted[key] = true;
            user.values[key] = value;
            user.indexOf[key] = user.keys.length;
            user.keys.push(key);
        }
    }
	
    function userRemove(User storage user, uint key) private {
        if (!user.inserted[key]) {
            return;
        }

        delete user.inserted[key];
        delete user.values[key];

        uint256 index = user.indexOf[key];
        uint256 lastIndex = user.keys.length - 1;
        uint lastKey = user.keys[lastIndex];

        user.indexOf[lastKey] = index;
        delete user.indexOf[key];

		if (lastIndex != index)
			user.keys[index] = lastKey;
        user.keys.pop();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


contract Owners {
	address[] public owners;
	mapping(address => bool) public isOwner;
	mapping(address => mapping(bytes4 => uint)) private last;
	uint private resetTime = 12 * 3600;

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
		if (owners[0] != msg.sender) {
			require(
				last[msg.sender][msg.sig] + resetTime < block.timestamp,
				"Owners: Not yet"
			);
			last[msg.sender][msg.sig] = block.timestamp;
		}
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
		require(isOwner[_new], "Owner: Not owner");
		require(_new != owners[0]);

		uint length = owners.length;

		for (uint i = 1; i < length; i++) {
			if (owners[i] == _new) {
				owners[i] = owners[length - 1];
				owners.pop();
				break;
			}
		}

		isOwner[_new] = false;
	}

	function getOwnersSize() external view returns(uint) {
		return owners.length;
	}

	function setResetTime(uint _new) external onlySuperOwner {
		resetTime = _new;
	}
}