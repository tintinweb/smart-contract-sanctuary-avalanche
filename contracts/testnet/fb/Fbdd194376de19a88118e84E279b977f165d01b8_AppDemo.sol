/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/anycall/v7/interfaces/AnycallFlags.sol


pragma solidity ^0.8.10;

library AnycallFlags {
    uint256 public constant FLAG_NONE = 0x0;
    uint256 public constant FLAG_MERGE_CONFIG_FLAGS = 0x1;
    uint256 public constant FLAG_PAY_FEE_ON_DEST = 0x1 << 1;
    uint256 public constant FLAG_ALLOW_FALLBACK = 0x1 << 2;
}


// File contracts/anycall/v7/interfaces/IApp.sol


pragma solidity ^0.8.10;

/// IApp interface of the application
interface IApp {
    /// (required) call on the destination chain to exec the interaction
    function anyExecute(bytes calldata _data)
        external
        returns (bool success, bytes memory result);

    /// (optional,advised) call back on the originating chain if the cross chain interaction fails
    /// `_data` is the orignal interaction arguments exec on the destination chain
    function anyFallback(bytes calldata _data)
        external
        returns (bool success, bytes memory result);
}


// File contracts/access/AdminControl.sol


pragma solidity ^0.8.10;

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    constructor(address _admin) {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}


// File contracts/anycall/v7/interfaces/IAnycallProxy.sol


pragma solidity ^0.8.10;

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
}


// File contracts/anycall/v7/interfaces/IFeePool.sol


pragma solidity ^0.8.10;

interface IFeePool {
    function deposit(address _account) external payable;

    function withdraw(uint256 _amount) external;

    function executionBudget(address _account) external view returns (uint256);
}


// File contracts/anycall/v7/interfaces/IAnycallExecutor.sol


pragma solidity ^0.8.10;

/// IAnycallExecutor interface of the anycall executor
interface IAnycallExecutor {
    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce,
        bytes calldata _extdata
    ) external returns (bool success, bytes memory result);
}


// File contracts/anycall/v7/app-examples/AppBase.sol


pragma solidity ^0.8.10;




abstract contract AppBase is AdminControl {
    address public callProxy;

    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(
            msg.sender == IAnycallProxy(callProxy).executor(),
            "AppBase: onlyExecutor"
        );
        _;
    }

    constructor(address _admin, address _callProxy) AdminControl(_admin) {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    receive() external payable {}

    function withdraw(address _to, uint256 _amount) external onlyAdmin {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function setCallProxy(address _callProxy) external onlyAdmin {
        require(_callProxy != address(0));
        callProxy = _callProxy;
    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }

    function _getAndCheckPeer(uint256 chainId) internal view returns (address) {
        address clientPeer = clientPeers[chainId];
        require(clientPeer != address(0), "AppBase: peer not exist");
        return clientPeer;
    }

    function _getAndCheckContext()
        internal
        view
        returns (
            address from,
            uint256 fromChainId,
            uint256 nonce
        )
    {
        address _executor = IAnycallProxy(callProxy).executor();
        (from, fromChainId, nonce) = IAnycallExecutor(_executor).context();
        require(clientPeers[fromChainId] == from, "AppBase: wrong context");
    }

    // if the app want to support `pay fee on destination chain`,
    // we'd better wrapper the interface `IFeePool` functions here.

    function depositFee() external payable {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).deposit{value: msg.value}(address(this));
    }

    function withdrawFee(address _to, uint256 _amount) external onlyAdmin {
        address _pool = IAnycallProxy(callProxy).config();
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function withdrawAllFee(address _pool, address _to) external onlyAdmin {
        uint256 _amount = IFeePool(_pool).executionBudget(address(this));
        IFeePool(_pool).withdraw(_amount);

        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }

    function executionBudget() external view returns (uint256) {
        address _pool = IAnycallProxy(callProxy).config();
        return IFeePool(_pool).executionBudget(address(this));
    }
}


// File contracts/anycall/v7/app-examples/AppDemo.sol


pragma solidity ^0.8.10;



contract AppDemo is IApp, AppBase {
    event LogCallin(
        string message,
        address sender,
        address receiver,
        uint256 fromChainId
    );
    event LogCallout(
        string message,
        address sender,
        address receiver,
        uint256 toChainId
    );
    event LogCalloutFail(
        string message,
        address sender,
        address receiver,
        uint256 toChainId
    );

    constructor(address _admin, address _callProxy)
        AppBase(_admin, _callProxy)
    {}

    /**
        @dev Call by the user to submit a request for a cross chain interaction
        @param flags The bitwised flags
            FLAG_PAY_FEE_ON_DEST = 2 (pay fee on the destination chain, otherwise pay fee on source chain)
            FLAG_ALLOW_FALLBACK = 4 (allow fallback if cross chain interaction failed)
    */
    function callout(
        string calldata message,
        address receiver,
        uint256 toChainId,
        uint256 flags
    ) external payable {
        address clientPeer = _getAndCheckPeer(toChainId);

        uint256 oldCoinBalance;
        if (msg.value > 0) {
            oldCoinBalance = address(this).balance - msg.value;
        }

        bytes memory data = abi.encode(
            message,
            msg.sender,
            receiver,
            toChainId
        );
        IAnycallProxy(callProxy).anyCall{value: msg.value}(
            clientPeer,
            data,
            toChainId,
            flags,
            ""
        );

        if (msg.value > 0) {
            uint256 newCoinBalance = address(this).balance;
            if (newCoinBalance > oldCoinBalance) {
                // return remaining fees
                (bool success, ) = msg.sender.call{
                    value: newCoinBalance - oldCoinBalance
                }("");
                require(success);
            }
        }

        emit LogCallout(message, msg.sender, receiver, toChainId);
    }

    /// @notice Call by `AnycallProxy` to execute a cross chain interaction on the destination chain
    function anyExecute(bytes calldata data)
        external
        override
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        (, uint256 fromChainId, ) = _getAndCheckContext();

        (string memory message, address sender, address receiver, ) = abi
            .decode(data, (string, address, address, uint256));

        // Testing: add a condition of execute failure situation here to test fallbak function
        require(bytes(message).length < 10, "App: message too long");

        // Testing: add a contition to trigger callback to the originating chain
        if (bytes(message).length == 1) {
            address clientPeer = _getAndCheckPeer(fromChainId);
            string memory callbcakMessage = "received";
            bytes memory callbackData = abi.encode(
                callbcakMessage,
                receiver,
                sender,
                fromChainId
            );
            // we choose pay fee on source here as an example (not set `FLAG_PAY_FEE_ON_DEST`)
            // we should send some gas fees to this contract to use here
            IAnycallProxy(callProxy).anyCall{value: 1e14}(
                clientPeer,
                callbackData,
                fromChainId,
                AnycallFlags.FLAG_NONE,
                ""
            );
        }

        emit LogCallin(message, sender, receiver, fromChainId);
        return (true, "");
    }

    /// @notice call back by `AnycallProxy` if the cross chain interaction fails on the destination chain
    function anyFallback(bytes calldata data)
        external
        override
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        _getAndCheckContext();

        (
            string memory message,
            address sender,
            address receiver,
            uint256 toChainId
        ) = abi.decode(data, (string, address, address, uint256));

        emit LogCalloutFail(message, sender, receiver, toChainId);
        return (true, "");
    }
}