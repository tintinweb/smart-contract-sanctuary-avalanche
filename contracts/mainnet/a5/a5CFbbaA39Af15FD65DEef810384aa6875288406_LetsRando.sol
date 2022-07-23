pragma solidity ^0.8.6;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEngineEcosystemContract.sol";

interface IRandomEngine {
    function requestDice(uint8 _type, uint8 _nDie, uint8 _nSides) external returns (uint256);
    function getResult(uint256 _result) external view returns (uint256);

    event DiceRequested (address  indexed _caller, uint8 _type, uint8 _numberofdie, uint8 _diesides, uint256 indexed _request);
    event RequestProcessed (address indexed _caller, uint256 _request, uint256 indexed _result);
}

contract LetsRando is Ownable {

    IEngineEcosystemContract internal _ecosystem;

    mapping(address => uint256) public UserRequestCount;
    mapping(uint256 => Request) public Requests;
    mapping(address => uint256[]) public UserRequests;

    uint256 public RequestCount;
    struct Request {
        address Player;
        uint256 RandoRequestNumber;
        uint256 Result;
        bool Processed;
        bool PlayerProcessed;
    }

    constructor(address _ecosystemAddress) {
        setEcosystem(_ecosystemAddress);
    }

    function setEcosystem(address _ecosystemAddress) public onlyOwner {
        _ecosystem = IEngineEcosystemContract(_ecosystemAddress);
    }
    function ecosystem() public view returns (address) {
        return address(_ecosystem);
    }

    function setRollCost(uint256 _amount) public onlyOwner {
        _rollCost = _amount;
    }
    function rollCost() public view returns (uint256) {
        return _rollCost;
    }
    uint256 private _rollCost = 10000000000000000;

    function setAutoBuyThreshold(uint256 _amount) public onlyOwner {
        _autoBuyThreshold = _amount;
    }
    function autoBuyThreshold() public view returns (uint256) {
        return _autoBuyThreshold;
    }
    uint256 private _autoBuyThreshold = 10;

    function pullResult(uint256 _request) internal {
        IRandomEngine engine = IRandomEngine(_ecosystem.returnAddress("RandoEngine"));
        Requests[_request].Result = engine.getResult(Requests[_request].RandoRequestNumber);
        Requests[_request].Processed = true;
    }
    function requestDieRoll(uint8 _type, uint8 _nDie, uint8 _nSides) internal returns (uint256) {
        RequestCount++;

        IERC20 token = IERC20(_ecosystem.returnAddress("RANDO"));
        if (token.balanceOf(address(this)) < (_autoBuyThreshold * 10 ** 18)) {
            purchaseRando();
        }

        IRandomEngine engine = IRandomEngine(_ecosystem.returnAddress("RandoEngine"));
        uint256 _request = engine.requestDice(_type, _nDie, _nSides);

        Requests[RequestCount].Player = msg.sender;
        Requests[RequestCount].RandoRequestNumber = _request;
        UserRequestCount[msg.sender]++;
        UserRequests[msg.sender].push(RequestCount);

        return RequestCount;
    }
    function purchaseRando() public payable {
        address engineAddress = payable(_ecosystem.returnAddress("RandoEngine"));
        (bool result, ) = engineAddress.call{gas:3000000, value: _rollCost}(abi.encodeWithSignature("purchaseRando()"));
        require(result, "Engine: failed to paid oracle cost");
    }

    receive() external payable {}

    function withdrawEth() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        IERC20 erc20 = IERC20(tokenAddress);
        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(msg.sender, balance);
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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IEngineEcosystemContract {
    function isEngineContract(address _address) external view returns (bool);
    function returnAddress(string memory _contract) external view returns (address);
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