/**
 *Submitted for verification at snowtrace.io on 2022-02-22
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/gov/interfaces/IOAXDEX_VotingExecutor.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOAXDEX_VotingExecutor {
    function execute(bytes32[] calldata params) external;
}


// File contracts/commons/interfaces/IOSWAP_PausableFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_PausableFactory {
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);

    function governance() external view returns (address);

    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
}


// File contracts/commons/interfaces/IOSWAP_FactoryBase.sol


pragma solidity =0.6.11;

interface IOSWAP_FactoryBase is IOSWAP_PausableFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint newSize);

    function pairCreator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// File contracts/range/interfaces/IOSWAP_RangeFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_RangeFactory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);

    function oracleFactory() external view returns (address);
    function rangeLiquidityProvider() external view returns (address);

    function getCreateAddresses() external view returns (address _governance, address _rangeLiquidityProvider, address _oracleFactory);
    function tradeFee() external view returns (uint256);
    function stakeAmount(uint256) external view returns (uint256);
    function liquidityProviderShare(uint256) external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function setRangeLiquidityProvider(address _rangeLiquidityProvider) external;

    function setTradeFee(uint256) external;
    function setLiquidityProviderShare(uint256[] calldata, uint256[] calldata) external;
    function getAllLiquidityProviderShare() external view returns (uint256[] memory _stakeAmount, uint256[] memory _liquidityProviderShare);
    function getLiquidityProviderShare(uint256 stake) external view returns (uint256 _liquidityProviderShare);
    function setProtocolFeeTo(address) external;

    function checkAndGetSwapParams() external view returns (uint256 _tradeFee);
}


// File contracts/gov/interfaces/IOAXDEX_Governance.sol


pragma solidity =0.6.11;

interface IOAXDEX_Governance {

    struct NewStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct VotingConfig {
        uint256 minExeDelay;
        uint256 minVoteDuration;
        uint256 maxVoteDuration;
        uint256 minOaxTokenToCreateVote;
        uint256 minQuorum;
    }

    event ParamSet(bytes32 indexed name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event AddVotingConfig(bytes32 name, 
        uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    event SetVotingConfig(bytes32 indexed configName, bytes32 indexed paramName, uint256 minExeDelay);

    event Stake(address indexed who, uint256 value);
    event Unstake(address indexed who, uint256 value);

    event NewVote(address indexed vote);
    event NewPoll(address indexed poll);
    event Vote(address indexed account, address indexed vote, uint256 option);
    event Poll(address indexed account, address indexed poll, uint256 option);
    event Executed(address indexed vote);
    event Veto(address indexed vote);

    function votingConfigs(bytes32) external view returns (uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    function votingConfigProfiles(uint256) external view returns (bytes32);

    function oaxToken() external view returns (address);
    function votingToken() external view returns (address);
    function freezedStake(address) external view returns (uint256 amount, uint256 timestamp);
    function stakeOf(address) external view returns (uint256);
    function totalStake() external view returns (uint256);

    function votingRegister() external view returns (address);
    function votingExecutor(uint256) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256);
    function isVotingExecutor(address) external view returns (bool);
    function admin() external view returns (address);
    function minStakePeriod() external view returns (uint256);

    function voteCount() external view returns (uint256);
    function votingIdx(address) external view returns (uint256);
    function votings(uint256) external view returns (address);


	function votingConfigProfilesLength() external view returns(uint256);
	function getVotingConfigProfiles(uint256 start, uint256 length) external view returns(bytes32[] memory profiles);
    function getVotingParams(bytes32) external view returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum);

    function setVotingRegister(address _votingRegister) external;
    function votingExecutorLength() external view returns (uint256);
    function initVotingExecutor(address[] calldata _setVotingExecutor) external;
    function setVotingExecutor(address _setVotingExecutor, bool _bool) external;
    function initAdmin(address _admin) external;
    function setAdmin(address _admin) external;
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external;
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external;
    function setMinStakePeriod(uint _minStakePeriod) external;

    function stake(uint256 value) external;
    function unlockStake() external;
    function unstake(uint256 value) external;
    function allVotings() external view returns (address[] memory);
    function getVotingCount() external view returns (uint256);
    function getVotings(uint256 start, uint256 count) external view returns (address[] memory _votings);

    function isVotingContract(address votingContract) external view returns (bool);

    function getNewVoteId() external returns (uint256);
    function newVote(address vote, bool isExecutiveVote) external;
    function voted(bool poll, address account, uint256 option) external;
    function executed() external;
    function veto(address voting) external;
    function closeVote(address vote) external;
}


// File contracts/router/interfaces/IOSWAP_HybridRouterRegistry.sol


pragma solidity =0.6.11;

interface IOSWAP_HybridRouterRegistry {
    event ProtocolRegister(address indexed factory, bytes32 name, uint256 fee, uint256 feeBase, uint256 typeCode);
    event PairRegister(address indexed factory, address indexed pair, address token0, address token1);
    event CustomPairRegister(address indexed pair, uint256 fee, uint256 feeBase, uint256 typeCode);

    struct Protocol {
        bytes32 name;
        uint256 fee;
        uint256 feeBase;
        uint256 typeCode;
    }
    struct Pair {
        address factory;
        address token0;
        address token1;
    }
    struct CustomPair {
        uint256 fee;
        uint256 feeBase;
        uint256 typeCode;
    }


    function protocols(address) external view returns (
        bytes32 name,
        uint256 fee,
        uint256 feeBase,
        uint256 typeCode
    );
    function pairs(address) external view returns (
        address factory,
        address token0,
        address token1
    );
    function customPairs(address) external view returns (
        uint256 fee,
        uint256 feeBase,
        uint256 typeCode
    );
    function protocolList(uint256) external view returns (address);
    function protocolListLength() external view returns (uint256);

    function governance() external returns (address);

    function registerProtocol(bytes32 _name, address _factory, uint256 _fee, uint256 _feeBase, uint256 _typeCode) external;

    function registerPair(address token0, address token1, address pairAddress, uint256 fee, uint256 feeBase, uint256 typeCode) external;
    function registerPairByIndex(address _factory, uint256 index) external;
    function registerPairsByIndex(address _factory, uint256[] calldata index) external;
    function registerPairByTokens(address _factory, address _token0, address _token1) external;
    function registerPairByTokensV3(address _factory, address _token0, address _token1, uint256 pairIndex) external;
    function registerPairsByTokens(address _factory, address[] calldata _token0, address[] calldata _token1) external;
    function registerPairsByTokensV3(address _factory, address[] calldata _token0, address[] calldata _token1, uint256[] calldata pairIndex) external;
    function registerPairByAddress(address _factory, address pairAddress) external;
    function registerPairsByAddress(address _factory, address[] memory pairAddress) external;
    function registerPairsByAddress2(address[] memory _factory, address[] memory pairAddress) external;

    function getPairTokens(address[] calldata pairAddress) external view returns (address[] memory token0, address[] memory token1);
    function getTypeCode(address pairAddress) external view returns (uint256 typeCode);
    function getFee(address pairAddress) external view returns (uint256 fee, uint256 feeBase);
}


// File contracts/range/OSWAP_VotingExecutor3.sol


pragma solidity =0.6.11;




contract OSWAP_VotingExecutor3 is IOAXDEX_VotingExecutor {

    address public immutable governance;
    address public immutable factory;
    address public immutable hybridRegistry;

    constructor(address _governance, address _factory, address _hybridRegistry) public {
        factory = _factory;
        governance = _governance;//IOSWAP_RangeFactory(_factory).governance();
        hybridRegistry = _hybridRegistry;
    }

    function execute(bytes32[] calldata params) external override {
        require(IOAXDEX_Governance(governance).isVotingContract(msg.sender), "Not from voting");
        require(params.length > 1, "Invalid length");
        bytes32 name = params[0];
        bytes32 param1 = params[1];
        // most frequenly used parameter comes first
        if (name == "setProtocolFee") {
            uint256 length = params.length - 1;
            require(length % 2 == 0, "Invalid length");
            length = length / 2;
            uint256[] memory stakeAmount;
            uint256[] memory protocolFee;
            assembly {
                let size := mul(length, 0x20)
                let mark := mload(0x40)
                mstore(0x40, add(mark, add(size, 0x20))) // malloc
                mstore(mark, length) // array length
                calldatacopy(add(mark, 0x20), 0x64, size) // copy data to list
                stakeAmount := mark

                mark := mload(0x40)
                mstore(0x40, add(mark, add(size, 0x20))) // malloc
                mstore(mark, length) // array length
                calldatacopy(add(mark, 0x20), add(0x64, size), size) // copy data to list
                protocolFee := mark
            }
            IOSWAP_RangeFactory(factory).setLiquidityProviderShare(stakeAmount, protocolFee);
        } else if (params.length == 2) {
            if (name == "setTradeFee") {
                IOSWAP_RangeFactory(factory).setTradeFee(uint256(param1));
            } else if (name == "setProtocolFeeTo") {
                IOSWAP_RangeFactory(factory).setProtocolFeeTo(address(bytes20(param1)));
            } else if (name == "setLive") {
                IOSWAP_RangeFactory(factory).setLive(uint256(param1)!=0);
            } else {
                revert("Unknown command");
            }
        } else if (params.length == 3) {
            if (name == "setLiveForPair") {
                IOSWAP_RangeFactory(factory).setLiveForPair(address(bytes20(param1)), uint256(params[2])!=0);
            } else {
                revert("Unknown command");
            }
        } else if (params.length == 6) {
            if (name == "registerProtocol") {
                IOSWAP_HybridRouterRegistry(hybridRegistry).registerProtocol(bytes20(param1), address(bytes20(params[2])), uint256(params[3]), uint256(params[4]), uint256(params[5]));
            } else {
                revert("Unknown command");
            }
        } else {
            revert("Invalid parameters");
        }
    }
}