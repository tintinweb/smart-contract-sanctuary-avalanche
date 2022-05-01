// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Owners.sol";
import "./IHandler_3_1.sol";


contract Lottery is Owners {
	event Winner(
		uint indexed i,
		address winner
	);

	struct Draw {
		uint price; // polar price
		uint winnersNb; // nb of remaining winners
		address to; // address to call, irrelevant if iStart == 0
		uint value; // native value
		uint iStart; // replace start index
		bool executed; // draw executed
		bool withTokens; // create with tokens
		bool withPending; // create with pending
		bool withBurning; // create with burning
		address[] participants; // address owning tickets
		address[] winners; // winners
		bytes data; // call data
		string description; // draw description
	}

	Draw[] public draws;
	uint private nonce;
	address public handler;
	mapping(uint => mapping(address => uint)) public userNbTickets; // user nb of tickets
	mapping(address => bool) public isBlacklisted;

	constructor(address _handler) {
		handler = _handler;
	}

	modifier notBlacklisted(address user) {
		require(!isBlacklisted[user], "Lottery: Blacklisted");
		_;
	}

	// Draw setup
	function createDraw(
		uint _price,
		uint _winnersNb,
		address _to,
		uint _value,
		uint _iStart,
		bool _withTokens,
		bool _withPending,
		bool _withBurning,
		bytes calldata _data,
		string calldata _description
	) 
		external 
		onlyOwners 
	{
		address[] memory _empty;

		draws.push(
			Draw({
				price: _price,
				winnersNb: _winnersNb,
				to: _to,
				value: _value,
				iStart: _iStart,
				executed: false,
				withTokens: _withTokens,
				withPending: _withPending,
				withBurning: _withBurning,
				participants: _empty,
				winners: _empty,
				data: _data,
				description: _description
			})
		);
	}

	function updateDraw(
		uint i,
		uint _price,
		uint _winnersNb,
		address _to,
		uint _value,
		uint _iStart,
		bool _withTokens,
		bool _withPending,
		bool _withBurning,
		bytes calldata _data,
		string memory _description // stack
	)
		external 
		onlyOwners 
	{
		Draw storage draw = draws[i];

		draw.price = _price;
		draw.winnersNb = _winnersNb;
		draw.to = _to;
		draw.value = _value;
		draw.iStart = _iStart;
		draw.executed = _winnersNb > 0 ? false : true;
		draw.withTokens = _withTokens;
		draw.withPending = _withPending;
		draw.withBurning = _withBurning;
		draw.data = _data;
		draw.description = _description;
	}

	// Buy Tickets
	function buyTicketsWithTokens(
		uint i,
		address tokenIn,
		address user,
		uint count,
		string calldata sponso
	)
		external
		notBlacklisted(msg.sender)
		notBlacklisted(user)
	{
		Draw storage draw = draws[i];

		require(draw.withTokens, "Lottery: With tokens not supported");

		uint price = _storeParticipant(draw, user, count);

		userNbTickets[i][user] += count;

		/*
		IHandler_3_1(handler).createWithTokens(
			tokenIn,
			msg.sender,
			price,
			sponso
		);
	   */
	}

	function buyTicketsWithPending(
		uint i,
		address tokenOut,
		string[] calldata nameFrom,
		uint[][] calldata tokenIdsToClaim,
		uint count
	)
		external
		notBlacklisted(msg.sender)
	{
		Draw storage draw = draws[i];
		
		require(draw.withPending, "Lottery: With pending not supported");

		uint price = _storeParticipant(draw, msg.sender, count);
		
		userNbTickets[i][msg.sender] += count;

		/*
		IHandler_3_1(handler).createWithPending(
			tokenOut,
			nameFrom,
			tokenIdsToClaim,
			msg.sender,
			price
		);
	   */
	}
	
	function buyTicketsWithBurning(
		uint i,
		address tokenOut,
		string[] calldata nameFrom,
		uint[][] calldata tokenIdsToClaim,
		uint count
	)
		external
		notBlacklisted(msg.sender)
	{
		Draw storage draw = draws[i];
		
		require(draw.withBurning, "Lottery: With burning not supported");

		uint price = _storeParticipant(draw, msg.sender, count);
		
		userNbTickets[i][msg.sender] += count;

		/*
		IHandler_3_1(handler).createWithBurning(
			tokenOut,
			nameFrom,
			tokenIdsToClaim,
			msg.sender,
			price
		);
	   */
	}

	function buyTicketsAirDrop(
		uint i,
		address user,
		uint count
	)
		external
		onlyOwners
		notBlacklisted(user)
	{
		Draw storage draw = draws[i];
		
		userNbTickets[i][user] += count;

		_storeParticipant(draw, user, count);
	}
	
	function _storeParticipant(
		Draw storage draw,
		address user, 
		uint count
	) 
		internal 
		returns (uint) 
	{
		require(count > 0, "Lottery: Count is zero");

		require(!draw.executed, "Lottery: Draw is already over");

		for (uint j = 0; j < count; j++)
			draw.participants.push(user);

		return draw.price * count;
	}

	// Draw Execute
	function drawExecuteSingle(uint i) external onlyOwners {
		Draw storage draw = draws[i];

		require(!draw.executed, "Lottery: Draw is already over");

		draw.winnersNb -= 1;

		if (draw.winnersNb == 0)
			draw.executed = true;

		_drawExecute(
			i,
			draw, 
			draw.iStart, 
			draw.participants.length,
			draw.value, 
			draw.data
		);
	}
	
	function drawExecuteBatch(uint i, uint count) external onlyOwners {
		Draw storage draw = draws[i];

		require(!draw.executed, "Lottery: Draw is already over");
		require(count <= draw.winnersNb, "Lottery: Not enough winners left");

		draw.winnersNb -= count;

		if (draw.winnersNb == 0)
			draw.executed = true;

		uint iStart = draw.iStart; // gas
		uint size = draw.participants.length; // gas
		uint value = draw.value; // gas
		bytes memory data = draw.data; // gas

		for (uint j = 0; j < count; j++) {
			size = _drawExecute(
				i,
				draw, 
				iStart, 
				size,
				value, 
				data
			);
		}
	}

	function _drawExecute(
		uint i,
		Draw storage draw,
		uint iStart,
		uint size,
		uint value,
		bytes memory data
	) 
		internal 
		returns (uint)
	{
		uint iWin = _generatePseudoRandom(size);
		address winner = draw.participants[iWin];

		draw.participants[iWin] = draw.participants[size - 1];
		draw.participants.pop();

		draw.winners.push(winner);

		if (iStart > 0)
			_externalCall(
				draw.to, 
				value, 
				updateData(
					data,
					winner,
					iStart
				)
			);
		else
			_externalCall(
				winner,
				value,
				data
			);

		emit Winner(i, winner);

		return size - 1;
	}

	function _externalCall(
		address to,
		uint value,
		bytes memory data
	) internal {
		(bool success, ) = to.call{value: value}(data);
		require(success, "Lottery: Call failure");
	}

	function updateData(
		bytes memory data,
		address user,
		uint iStart
	) 
		public 
		pure 
		returns (bytes memory) 
	{
		bytes memory addr =  abi.encodePacked(user);

		assembly {
			let d := mload(add(addr, 0x20))
			mstore(add(data, add(0x20, iStart)), d)
		}

		return data;
	}

	function _generatePseudoRandom(uint size) internal returns(uint) {
		uint r = uint(
			keccak256(
				abi.encodePacked(
					nonce, 
					msg.sender, 
					block.difficulty, 
					block.timestamp
				)
			)
		);
		unchecked { nonce += 1; }
		return r % size;
	}

	// Owners external call
	function ownersExternalCall(
		address to,
		uint value,
		bytes calldata data
	) 
		external
		onlyOwners
	{
		(bool success, ) = to.call{value: value}(data);
		require(success, "Lottery: Call failure");
	}

	// Native requirement
	receive() external payable {}

	// Setters
	function setHandler(address _handler) external onlyOwners {
		handler = _handler;
	}

	// Getters
	function getDrawsSize() external view returns (uint) {
		return draws.length;
	}

	function getParticipantsSize(uint i) external view returns (uint) {
		return draws[i].participants.length;
	}
	
	function getWinnersSize(uint i) external view returns (uint) {
		return draws[i].winners.length;
	}

	function getData(uint i) external view returns (bytes memory) {
		return draws[i].data;
	}
	
	function getDescription(uint i) external view returns (string memory) {
		return draws[i].description;
	}

	function getParticipantsBetweenIndexes(
		uint i,
		uint iStart,
		uint iEnd
	)
		external
		view
		returns (address[] memory)
	{
		address[] memory res = new address[](iEnd - iStart);
		address[] storage participants = draws[i].participants;
		
		for (uint j = iStart; j < iEnd; j++)
			res[j - iStart] = participants[j];

		return res;
	}

	function getWinnersBetweenIndexes(
		uint i,
		uint iStart,
		uint iEnd
	)
		external
		view
		returns (address[] memory)
	{
		address[] memory res = new address[](iEnd - iStart);
		address[] storage winners = draws[i].winners;
		
		for (uint j = iStart; j < iEnd; j++)
			res[j - iStart] = winners[j];

		return res;
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

interface IHandler_3_1 {
	function createNodesAirDrop(
		string memory name,
		address user,
		uint isBoostedAirDropRate,
		bool[] memory areBoostedNft,
		bool isBoostedToken,
		string memory feature,
		uint count
	) external;

	function createLuckyBoxesAirDrop(
		string memory name,
		address user,
		uint count
	) external;

	function createWithTokens(
		address tokenIn,
		address user,
		uint price,
		string memory sponso
	) external;

	function createWithPending(
		address tokenOut,
		string[] memory nameFrom,
		uint[][] memory tokenIdsToClaim,
		address user,
		uint price
	) external;
	
	function createWithBurning(
		address tokenOut,
		string[] memory nameFrom,
		uint[][] memory tokenIdsToBurn,
		address user,
		uint price
	) external;
}