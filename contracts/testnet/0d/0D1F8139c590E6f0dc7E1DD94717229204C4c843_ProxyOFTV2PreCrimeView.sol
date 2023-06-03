// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin-3/contracts/access/Ownable.sol";
import "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/precrime/PreCrimeView.sol";
import "./IOFTV2View.sol";

/// @title A pre-crime contract for tokens with one ProxyOFTV2 and multiple OFTV2 contracts
/// @notice Ensures that the total supply on all chains will remain the same when tokens are transferred between chains
/// @dev This contract must only be used for tokens with fixed total supply
contract ProxyOFTV2PreCrimeView is PreCrimeView, Ownable {
    struct SimulationResult {
        uint chainTotalSupply;
        bool isProxy;
    }

    /// @notice a view for OFTV2 or ProxyOFTV2
    IOFTV2View public immutable oftView;
    uint16[] public remoteChainIds;
    bytes32[] public remotePrecrimeAddresses;
    uint64 public maxBatchSize;

    constructor(uint16 _localChainId, address _oftView, uint64 _maxSize) PreCrimeView(_localChainId) {
        oftView = IOFTV2View(_oftView);
        setMaxBatchSize(_maxSize);
    }

    function setRemotePrecrimeAddresses(uint16[] memory _remoteChainIds, bytes32[] memory _remotePrecrimeAddresses) public onlyOwner {
        require(_remoteChainIds.length == _remotePrecrimeAddresses.length, "ProxyOFTV2PreCrimeView: invalid size");
        remoteChainIds = _remoteChainIds;
        remotePrecrimeAddresses = _remotePrecrimeAddresses;
    }

    function setMaxBatchSize(uint64 _maxSize) public onlyOwner {
        maxBatchSize = _maxSize;
    }

    function _simulate(Packet[] calldata _packets) internal view override returns (uint16, bytes memory) {
        uint totalSupply = oftView.getCurrentState();

        for (uint i = 0; i < _packets.length; i++) {
            Packet memory packet = _packets[i];
            totalSupply = oftView.lzReceive(packet.srcChainId, packet.srcAddress, packet.payload, totalSupply);
        }

        return (CODE_SUCCESS, abi.encode(SimulationResult({chainTotalSupply: totalSupply, isProxy: oftView.isProxy()})));
    }

    function _precrime(bytes[] memory _simulation) internal pure override returns (uint16 code, bytes memory reason) {
        uint totalLocked = 0;
        uint totalMinted = 0;

        for (uint i = 0; i < _simulation.length; i++) {
            SimulationResult memory result = abi.decode(_simulation[i], (SimulationResult));
            if (result.isProxy) {
                if (totalLocked > 0) {
                    return (CODE_PRECRIME_FAILURE, "more than one proxy simulation");
                }
                totalLocked = result.chainTotalSupply;
            } else {
                totalMinted += result.chainTotalSupply;
            }
        }

        if (totalMinted > totalLocked) {
            return (CODE_PRECRIME_FAILURE, "total minted > total locked");
        }

        return (CODE_SUCCESS, "");
    }

    /// @dev always returns all remote chain ids and precrime addresses
    function _remotePrecrimeAddress(Packet[] calldata) internal view override returns (uint16[] memory chainIds, bytes32[] memory precrimeAddresses) {
        return (remoteChainIds, remotePrecrimeAddresses);
    }

    function _getInboundNonce(Packet memory _packet) internal view override returns (uint64) {
        return oftView.getInboundNonce(_packet.srcChainId);
    }

    function _maxBatchSize() internal view virtual override returns (uint64) {
        return maxBatchSize;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;
pragma abicoder v2;

interface IPreCrimeBase {
    struct Packet {
        uint16 srcChainId; // source chain id
        bytes32 srcAddress; // srouce UA address
        uint64 nonce;
        bytes payload;
    }

    /**
     * @dev get precrime config,
     * @param _packets packets
     * @return bytes of [maxBatchSize, remotePrecrimes]
     */
    function getConfig(Packet[] calldata _packets) external view returns (bytes memory);

    /**
     * @dev
     * @param _simulation all simulation results from difference chains
     * @return code     precrime result code; check out the error code defination
     * @return reason   error reason
     */
    function precrime(
        Packet[] calldata _packets,
        bytes[] calldata _simulation
    ) external view returns (uint16 code, bytes memory reason);

    /**
     * @dev protocol version
     */
    function version() external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IPreCrimeBase.sol";

interface IPreCrime is IPreCrimeBase {
    /**
     * @dev simulate run cross chain packets and get a simulation result for precrime later
     * @param _packets packets, the packets item should group by srcChainId, srcAddress, then sort by nonce
     * @return code   simulation result code; see the error code defination
     * @return result the result is use for precrime params
     */
    function simulate(Packet[] calldata _packets) external returns (uint16 code, bytes memory result);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IPreCrimeBase.sol";

interface IPreCrimeView is IPreCrimeBase {
    /**
     * @dev simulate run cross chain packets and get a simulation result for precrime later
     * @param _packets packets, the packets item should group by srcChainId, srcAddress, then sort by nonce
     * @return code   simulation result code; see the error code defination
     * @return result the result is use for precrime params
     */
    function simulate(Packet[] calldata _packets) external view returns (uint16 code, bytes memory result);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IPreCrime.sol";

abstract contract PreCrimeBase is IPreCrimeBase {
    uint16 public constant CONFIG_VERSION = 1;

    //---------------- error code ----------------------
    // --- UA scope code ---
    uint16 public constant CODE_SUCCESS = 0; // success
    uint16 public constant CODE_PRECRIME_FAILURE = 1; // !!! crimes found

    // --- protocol scope error code ---
    // simualte
    uint16 public constant CODE_PACKETS_OVERSIZE = 2; // packets number bigger then max size
    uint16 public constant CODE_PACKETS_UNSORTED = 3; // packets are unsorted, need backfill and keep order
    // precrime
    uint16 public constant CODE_MISS_SIMULATE_RESULT = 4; // miss simulation result

    uint16 public localChainId;

    constructor(uint16 _localChainId) {
        localChainId = _localChainId;
    }

    /**
     * @dev get precrime config,
     * @param _packets packets
     * @return configation bytes
     */
    function getConfig(Packet[] calldata _packets) external view virtual override returns (bytes memory) {
        (uint16[] memory remoteChains, bytes32[] memory remoteAddresses) = _remotePrecrimeAddress(_packets);
        return
            abi.encodePacked(
                CONFIG_VERSION,
                //---- max packets size for simulate batch ---
                _maxBatchSize(),
                //------------- remote precrimes -------------
                remoteChains.length,
                remoteChains,
                remoteAddresses
            );
    }

    /**
     * @dev
     * @param _simulation all simulation results from difference chains
     * @return code     precrime result code; check out the error code definition
     * @return reason   error reason
     */
    function precrime(
        Packet[] calldata _packets,
        bytes[] calldata _simulation
    ) external view override returns (uint16 code, bytes memory reason) {
        bytes[] memory originSimulateResult = new bytes[](_simulation.length);
        uint16[] memory chainIds = new uint16[](_simulation.length);
        for (uint256 i = 0; i < _simulation.length; i++) {
            (uint16 chainId, bytes memory simulateResult) = abi.decode(_simulation[i], (uint16, bytes));
            chainIds[i] = chainId;
            originSimulateResult[i] = simulateResult;
        }

        (code, reason) = _checkResultsCompleteness(_packets, chainIds);
        if (code != CODE_SUCCESS) {
            return (code, reason);
        }

        (code, reason) = _precrime(originSimulateResult);
    }

    function _checkPacketsMaxSizeAndNonceOrder(
        Packet[] calldata _packets
    ) internal view returns (uint16 code, bytes memory reason) {
        uint64 maxSize = _maxBatchSize();
        if (_packets.length > maxSize) {
            return (CODE_PACKETS_OVERSIZE, abi.encodePacked("packets size exceed limited"));
        }

        // check packets nonce, sequence order
        // packets should group by srcChainId and srcAddress, then sort by nonce ascending
        if (_packets.length > 0) {
            uint16 srcChainId;
            bytes32 srcAddress;
            uint64 nonce;
            for (uint256 i = 0; i < _packets.length; i++) {
                Packet memory packet = _packets[i];
                // start from a new chain packet or a new source UA
                if (packet.srcChainId != srcChainId || packet.srcAddress != srcAddress) {
                    srcChainId = packet.srcChainId;
                    srcAddress = packet.srcAddress;
                    nonce = packet.nonce;
                    uint64 nextInboundNonce = _getInboundNonce(packet) + 1;
                    // the first packet's nonce must equal to dst InboundNonce+1
                    if (nonce != nextInboundNonce) {
                        return (CODE_PACKETS_UNSORTED, abi.encodePacked("skipped inboundNonce forbidden"));
                    }
                } else {
                    // the following packet's nonce add 1 in order
                    if (packet.nonce != ++nonce) {
                        return (CODE_PACKETS_UNSORTED, abi.encodePacked("unsorted packets"));
                    }
                }
            }
        }
        return (CODE_SUCCESS, "");
    }

    function _checkResultsCompleteness(
        Packet[] calldata _packets,
        uint16[] memory _resultChainIds
    ) internal view returns (uint16 code, bytes memory reason) {
        // check if all remote result included
        if (_packets.length > 0) {
            (uint16[] memory remoteChains, ) = _remotePrecrimeAddress(_packets);
            for (uint256 i = 0; i < remoteChains.length; i++) {
                bool resultChainIdChecked;
                for (uint256 j = 0; j < _resultChainIds.length; j++) {
                    if (_resultChainIds[j] == remoteChains[i]) {
                        resultChainIdChecked = true;
                        break;
                    }
                }
                if (!resultChainIdChecked) {
                    return (CODE_MISS_SIMULATE_RESULT, "missing remote simulation result");
                }
            }
        }
        // check if local result included
        bool localChainIdResultChecked;
        for (uint256 j = 0; j < _resultChainIds.length; j++) {
            if (_resultChainIds[j] == localChainId) {
                localChainIdResultChecked = true;
                break;
            }
        }
        if (!localChainIdResultChecked) {
            return (CODE_MISS_SIMULATE_RESULT, "missing local simulation result");
        }

        return (CODE_SUCCESS, "");
    }

    /**
     * @dev
     * @param _simulation all simulation results from difference chains
     * @return code     precrime result code; check out the error code defination
     * @return reason   error reason
     */
    function _precrime(bytes[] memory _simulation) internal view virtual returns (uint16 code, bytes memory reason);

    /**
     * @dev UA return trusted remote precrimes by packets
     * @param _packets packets
     * @return
     */
    function _remotePrecrimeAddress(
        Packet[] calldata _packets
    ) internal view virtual returns (uint16[] memory, bytes32[] memory);

    /**
     * @dev max batch size for simulate
     * @return
     */
    function _maxBatchSize() internal view virtual returns (uint64);

    /**
     * get srcChain & srcAddress InboundNonce by packet
     */
    function _getInboundNonce(Packet memory packet) internal view virtual returns (uint64 nonce);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IPreCrimeView.sol";
import "./PreCrimeBase.sol";

abstract contract PreCrimeView is PreCrimeBase, IPreCrimeView {
    /**
     * @dev 10000 - 20000 is for view mode, 20000 - 30000 is for precrime inherit mode
     */
    uint16 public constant PRECRIME_VERSION = 10001;

    constructor(uint16 _localChainId) PreCrimeBase(_localChainId) {}

    /**
     * @dev simulate run cross chain packets and get a simulation result for precrime later
     * @param _packets packets, the packets item should group by srcChainId, srcAddress, then sort by nonce
     * @return code   simulation result code; see the error code defination
     * @return data the result is use for precrime params
     */
    function simulate(Packet[] calldata _packets) external view override returns (uint16 code, bytes memory data) {
        // params check
        (code, data) = _checkPacketsMaxSizeAndNonceOrder(_packets);
        if (code != CODE_SUCCESS) {
            return (code, data);
        }

        (code, data) = _simulate(_packets);
        if (code == CODE_SUCCESS) {
            data = abi.encode(localChainId, data); // add localChainId to the header
        }
    }

    /**
     * @dev UA execute the logic by _packets, and return simulation result for precrime. would revert state after returned result.
     * @param _packets packets
     * @return code
     * @return result
     */
    function _simulate(Packet[] calldata _packets) internal view virtual returns (uint16 code, bytes memory result);

    function version() external pure override returns (uint16) {
        return PRECRIME_VERSION;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOFTV2View {
    /// @notice simulates receiving of a message
    function lzReceive(uint16 _srcChainId, bytes32 _scrAddress, bytes memory _payload, uint _totalSupply) external view returns (uint);

    function getInboundNonce(uint16 _srcChainId) external view returns (uint64);

    /// @notice returns the total supply for OFTV2 or outbound amount for ProxyOFTV2
    function getCurrentState() external view returns (uint);

    /// @notice indicates whether the view is OFTV2 or ProxyOFTV2
    function isProxy() external view returns (bool);
}