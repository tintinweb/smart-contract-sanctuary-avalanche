// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Owners.sol";


contract Lottery is Owners, ReentrancyGuard {
	event Winner(
		uint indexed i,
		address winner
	);

	struct Draw {
		uint price; // price
		address token; // token to purchase ticket
		uint winnersNb; // nb of remaining winners
		address to; // address to call, irrelevant if iStart == 0
		uint value; // native value
		uint iStart; // replace start index
		bool native; // purchase in native
		bool open; // purchase available
		bool executed; // draw executed
		address[] participants; // address owning tickets
		address[] winners; // winners
		bytes data; // call data
		string description; // draw description
		string descriptionShort; // draw descriptionShort
		string url; // draw picture
	}

	Draw[] public draws;
	uint private nonce;
	address public splitter;
	mapping(uint => mapping(address => uint)) public userNbTickets; // user nb of tickets
	mapping(address => bool) public isBlacklisted;

	constructor(address _splitter) {
		splitter = _splitter;
	}

	modifier notBlacklisted(address user) {
		require(!isBlacklisted[user], "Lottery: Blacklisted");
		_;
	}

	// Draw setup
	function createDraw(
		uint _price,
		address _token,
		uint _winnersNb,
		address _to,
		uint _value,
		uint _iStart,
		bool _native,
		bool _open,
		bytes memory _data, // stack
		string memory _description, // stack
		string memory _descriptionShort // stack
	) 
		external 
		onlyOwners 
	{
		address[] memory _empty;

		draws.push(
			Draw({
				price: _price,
				token: _token,
				winnersNb: _winnersNb,
				to: _to,
				value: _value,
				iStart: _iStart,
				native: _native,
				open: _open,
				executed: false,
				participants: _empty,
				winners: _empty,
				data: _data,
				description: _description,
				descriptionShort: _descriptionShort,
				url: ""
			})
		);
	}

	function updateDraw(
		uint i,
		uint _price,
		address _token,
		uint _winnersNb,
		address _to,
		uint _value,
		uint _iStart,
		bool _native,
		bool _open,
		bytes memory _data, // stack
		string memory _description, // stack
		string memory _descriptionShort // stack
	)
		external 
		onlyOwners 
	{
		Draw storage draw = draws[i];

		draw.price = _price;
		draw.token = _token;
		draw.winnersNb = _winnersNb;
		draw.to = _to;
		draw.value = _value;
		draw.iStart = _iStart;
		draw.native = _native;
		draw.open = _open;
		draw.executed = _winnersNb > 0 ? false : true;
		draw.data = _data;
		draw.description = _description;
		draw.descriptionShort = _descriptionShort;
	}

	// Buy Tickets
	function buyTickets(
		uint i,
		uint count
	)
		external
		payable
		notBlacklisted(msg.sender)
		nonReentrant
	{
		Draw storage draw = draws[i];

		require(draw.open, "Lottery: Not open");

		uint price = _storeParticipant(draw, msg.sender, count);

		userNbTickets[i][msg.sender] += count;

		if (draw.native) {
			require(msg.value >= price);
			_externalCall(splitter, msg.value, "");
		} else {
			IERC20(draw.token).transferFrom(msg.sender, splitter, price);
		}
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
	function drawExecute(
		uint i
	) 
		external 
		onlyOwners 
		nonReentrant
	{
		Draw storage draw = draws[i];

		require(!draw.executed, "Lottery: Draw is already over");

		draw.winnersNb -= 1;

		if (draw.winnersNb == 0) {
			draw.open = false;
			draw.executed = true;
		}

		_drawExecute(
			i,
			draw, 
			draw.iStart, 
			draw.participants.length,
			draw.value, 
			draw.data
		);
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
		_externalCall(to, value, data);
	}

	// Native requirement
	receive() external payable {}

	// Setters
	function setSplitter(address _splitter) external onlyOwners {
		splitter = _splitter;
	}
	
	function setPrice(uint i, uint _new) external onlyOwners {
		draws[i].price = _new;
	}
	
	function setToken(uint i, address _new) external onlyOwners {
		draws[i].token = _new;
	}
	
	function setWinnersNb(uint i, uint _new) external onlyOwners {
		Draw storage draw = draws[i];

		if (_new > 0)
			draw.executed = false;
		else
			draw.executed = true;

		draw.winnersNb = _new;
	}
	
	function setTo(uint i, address _new) external onlyOwners {
		draws[i].to = _new;
	}
	
	function setValue(uint i, uint _new) external onlyOwners {
		draws[i].value = _new;
	}
	
	function setIStart(uint i, uint _new) external onlyOwners {
		draws[i].iStart = _new;
	}
	
	function setNative(uint i, bool _new) external onlyOwners {
		draws[i].native = _new;
	}
	
	function setOpen(uint i, bool _new) external onlyOwners {
		draws[i].open = _new;
	}
	
	function setData(uint i, bytes calldata _new) external onlyOwners {
		draws[i].data = _new;
	}
	
	function setDescription(uint i, string calldata _new) external onlyOwners {
		draws[i].description = _new;
	}
	
	function setDescriptionShort(uint i, string calldata _new) external onlyOwners {
		draws[i].descriptionShort = _new;
	}
	
	function setUrl(uint i, string calldata _new) external onlyOwners {
		draws[i].url = _new;
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

	function getDrawsBetweenIndexes(
		uint iStart,
		uint iEnd
	)
		external
		view
		returns (Draw[] memory)
	{
		Draw[] memory res = new Draw[](iEnd - iStart);
		
		for (uint i = iStart; i < iEnd; i++)
			res[i - iStart] = draws[i];

		return res;
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
	
	function getUserNbTicketsBetweenIndexes(
		address user,
		uint iStart,
		uint iEnd
	)
		external
		view
		returns (uint[] memory)
	{
		uint[] memory res = new uint[](iEnd - iStart);
		
		for (uint i = iStart; i < iEnd; i++)
			res[i - iStart] = userNbTickets[i][user];

		return res;
	}
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