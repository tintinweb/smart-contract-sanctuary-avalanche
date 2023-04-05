/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-03
*/

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
pragma solidity ^0.8.0;

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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


pragma solidity ^0.8.0;

/// IAnycallConfig interface of the anycall config
interface IAnycallConfig {
    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);

    function calcSrcFees(
        string calldata _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);

    function checkCall(
        address _sender,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags
    ) external view returns (string memory _appID, uint256 _srcFees);

    function checkExec(
        string calldata _appID,
        address _from,
        address _to
    ) external view;

    function chargeFeeOnDestChain(address _from, uint256 _prevGasLeft) external;
}


pragma solidity ^0.8.0;
/// IAnycallProxy interface of the anycall proxy
interface IAnycallProxy {
    function executor() external view returns (address);

    function config() external view returns (address);

    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function anyCall(
        string calldata _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result);

    function anyFallback(bytes calldata _data) external returns (bool success, bytes memory result);
}


pragma solidity ^0.8.19;
contract Messenger is Ownable {
    address public anycallContract;
    address public anycallConfig;
    address public executor;

    string public messageReceived;

    mapping(uint256 => address) public destination;

    modifier onlyExecutor {
        require(msg.sender == executor, "!executor");
        _;
    }

    constructor(
        address _anycallContract,
        address _anycallConfig
    ){
        anycallContract = _anycallContract;
        anycallConfig = _anycallConfig;
        executor = IAnycallProxy(_anycallContract).executor();
    }

    /* Flags of gas
        0: Gas fee paid on source chain. Fallback not allowed.

        2: Gas fee paid on destination chain. Fallback not allowed.

        4: Gas fee paid on source chain. Allow fallback 

        6: Gas fee paid on destination chain. Allow fallback 
    */

    function sendMessage(uint256 _toChainID, string calldata _msg) external virtual onlyOwner {
        IAnycallProxy(anycallContract).anyCall{value: 0}(
            destination[_toChainID],
            encodeMessage(_msg),
            _toChainID,
            6,
            ""
        );
    }

    function anyExecute(bytes calldata _data) external onlyExecutor returns (bool success, bytes memory result) {
        messageReceived = abi.decode(_data, (string));
        success = true;
        result = new bytes(0);
    }

    function anyFallback(bytes calldata _data) external onlyExecutor returns (bool success, bytes memory result) {
        _data;
        messageReceived = "Message Failed to Sent";
        success = true;
        result = new bytes(0);

    }

    function encodeMessage(string calldata _msg) public virtual pure returns(bytes memory) {
        return abi.encode(_msg);
    }

    function estimateFees(uint256 _toChainID, string calldata _msg) public virtual view returns (uint256){
        return IAnycallConfig(anycallConfig).calcSrcFees(address(0), _toChainID, bytes(_msg).length);
    }

    function setDst(uint256 _chainID, address _contractAddress) external virtual onlyOwner {
        destination[_chainID] = _contractAddress;
    }

    function withdrawNative() external onlyOwner {
        require(address(this).balance > 0, "!wd");
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "bad");
    }

    receive() external payable { }
}