// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../../Interfaces/ICFContainer.sol';
import '../../Interfaces/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';


/**
 * @title MintControl.sol
 * @author ehrab
 * @notice Control minting calls to Containers
 * @dev Use this contract for selling Containers before Factory system is finished
 */
contract MintControl is Ownable, Pausable {
	// ============================ DEPENDANCIES ============================ //
	using Counters for Counters.Counter;

	// ================================ STRUCTS ================================ //
	/**
	 * @notice Container data struct
	 * @dev Allocation gets added to maxNfts if needed
	 */
	struct Container {
		string label;
		address location;
		uint16 price;
		uint16 maxNfts;
		Counters.Counter idCounter;
	}

	// ================================ STATE VARS ================================ //
	mapping(string => Container) containers;
	address internal usdc;
	
	// ================================== EVENTS ================================== //
	error InsufficientSupply(string error);
	error MintError(string error);

	// ================================ CONSTRUCTOR ================================ //
	constructor() {
		//TODO - Ownership handoff to hardware wallet advisable
	}

	/**
	 * @notice Direct minting calls to Containers
	 * @param label string Container to purchase from
	 * @param nftToMint uint256 How many nfts to purchase
	 */
	function callForMint(string calldata label, uint16 nftToMint) public whenNotPaused {
		Container storage info = containers[label];
		require(info.price > 0, string(abi.encodePacked('Container with label', label, ' does not exist!')));
		require(_checkSupply(label) >= nftToMint, "Not enough supply remaining.");

		// if (nftToMint > 1){
		// 	for (uint16 i = nftToMint; i > 0; i--) {
		// 		ICFContainer(info.location).safeMint(msg.sender, info.idCounter.current());
		// 		containers[label].idCounter.increment();
		// 	}
		// } else {
			// ICFContainer(info.location).safeMint(msg.sender, info.idCounter.current());
			// containers[label].idCounter.increment();
		// }
	}

	// ================================ ADMIN FUNCTION ================================ //
	//TODO - Admin function for changing price on Containers

	/**
	 * @notice Add container to state for tracking
	 * @param containerLabel string Label for Container
	 * @param location address Address of Container
	 * @param price uint16 Price per nft
	 * @param maxNfts uint16 How many nfts for purchase, add supply as needed
	 */
	function addContainer(
		string calldata containerLabel,
		address location,
		uint16 price,
		uint16 maxNfts
	) external onlyOwner whenNotPaused returns (string memory container) {
		require(containers[containerLabel].price == 0, string(abi.encodePacked('Container with label', containerLabel, ' already exists!')));
		_createEntry(containerLabel, location, price, maxNfts);

		return container;
	}

	// function allocateFounders(address[] calldata _founders) external onlyRole(FACTORY) {
	// 	for (uint16 i = 0; i < _founders.length; i++) {
	// 		safeMint(_founders[i]);
	// 	}
	// }

	// ================================ HELPER FUNCTIONS ================================ //
	/**
	 * @notice Create entry in state for Container
	 * @param _containerLabel string Label for Container
	 * @param _location address Address of Container
	 * @param _price uint16 Cost of nfts
	 * @param _maxNfts uint16 How many nfts to purchase
	 */
	function _createEntry(
		string calldata _containerLabel,
		address _location,
		uint16 _price,
		uint16 _maxNfts
	) internal {
		Counters.Counter memory newCounter;
		containers[_containerLabel] = Container({ label: _containerLabel, location: _location, price: _price, maxNfts: _maxNfts, idCounter: newCounter });
	}

	/**
	 * @notice Check supply remaining of container queried
	 * @param _containerLabel string label of Container
	 */
	function _checkSupply(string calldata _containerLabel) internal view returns (uint16) {
		Container memory containerToQuery = containers[_containerLabel];

		try ICFContainer(containerToQuery.location).totalSupply() returns (uint16 supply) {
			require (supply < containerToQuery.maxNfts, "No supply on Container queried!");
			uint16 remaining = (containerToQuery.maxNfts -= supply);
			return (remaining);
		} catch Error(string memory reason) {
			revert InsufficientSupply(reason);
		}
	}

	// ================================ ADMIN FUNCTIONS ================================ //
	/**
	 * @notice Set new stablecoin for payment
	 * @param token address Contract address
	 */
	function setPaymentToken(address token) external onlyOwner returns (bool) {
		require(token != usdc, "This address is already set for payment!");
		usdc = token;

		return true;
	}
}

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

		/// @param _owner The address from which the balance will be retrieved
		/// @return balance the balance
		function balanceOf(address _owner) external view returns (uint256 balance);

		/// @notice send `_value` token to `_to` from `msg.sender`
		/// @param _to The address of the recipient
		/// @param _value The amount of token to be transferred
		/// @return success Whether the transfer was successful or not
		function transfer(address _to, uint256 _value) external returns (bool success);

		/// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
		/// @param _from The address of the sender
		/// @param _to The address of the recipient
		/// @param _value The amount of token to be transferred
		/// @return success Whether the transfer was successful or not
		function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

		/// @notice `msg.sender` approves `_addr` to spend `_value` tokens
		/// @param _spender The address of the account able to transfer the tokens
		/// @param _value The amount of wei to be approved for transfer
		/// @return success Whether the approval was successful or not
		function approve(address _spender, uint256 _value) external returns (bool success);

		/// @param _owner The address of the account owning tokens
		/// @param _spender The address of the account able to transfer the tokens
		/// @return remaining Amount of remaining tokens allowed to spent
		function allowance(address _owner, address _spender) external view returns (uint256 remaining);

		event Transfer(address indexed _from, address indexed _to, uint256 _value);
		event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface ICFContainer {

	function getUri() external view returns (string memory);
	function getSerial() external view returns (string memory);
	function royaltyWallet() external view returns (address);
	function paymentWallet() external view returns (address);
	function totalSupply() external view returns (uint16);
	function safeMint(address, uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}