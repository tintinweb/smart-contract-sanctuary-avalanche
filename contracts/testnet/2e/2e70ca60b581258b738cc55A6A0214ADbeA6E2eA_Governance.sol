pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./zksync/Config.sol";

/// @title Governance Contract
/// @author zk.link
contract Governance is Config {
    /// @notice Token added to ZkLink net
    event NewToken(uint16 indexed tokenId, address indexed token);

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    /// @notice Token pause status update
    event TokenPausedUpdate(uint16 indexed token, bool paused);

    /// @notice Token address update
    event TokenAddressUpdate(uint16 indexed token, address newAddress);

    /// @notice Address which will exercise governance over the network i.e. add tokens, change validator set, conduct upgrades
    address public networkGovernor;

    /// @notice List of permitted validators
    mapping(address => bool) public validators;

    struct RegisteredToken {
        bool registered; // whether token registered to ZkLink or not, default is false
        bool paused; // whether token can deposit to ZkLink or not, default is false
        address tokenAddress; // the token address, zero represents eth, can be updated
    }

    /// @notice A map of registered token infos
    mapping(uint16 => RegisteredToken) public tokens;

    /// @notice A map of token address to id, 0 is invalid token id
    mapping(address => uint16) public tokenIds;

    modifier onlyGovernor {
        require(msg.sender == networkGovernor, "Gov: no auth");
        _;
    }

    /// @notice Governance contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    ///     _networkGovernor The address of network governor
    function initialize(bytes calldata initializationParameters) external {
        address _networkGovernor = abi.decode(initializationParameters, (address));

        networkGovernor = _networkGovernor;
    }

    /// @notice Governance contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Gov: address not set");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Add token to the list of networks tokens
    /// @param _tokenId Token id
    /// @param _tokenAddress Token address
    function addToken(uint16 _tokenId, address _tokenAddress) public onlyGovernor {
        // token id MUST be in a valid range
        require(_tokenId > 0 && _tokenId < MAX_AMOUNT_OF_REGISTERED_TOKENS, "Gov: invalid tokenId");
        // token MUST be not zero address
        require(_tokenAddress != address(0), "Gov: invalid tokenAddress");
        // revert duplicate register
        RegisteredToken memory rt = tokens[_tokenId];
        require(!rt.registered, "Gov: tokenId registered");
        require(tokenIds[_tokenAddress] == 0, "Gov: tokenAddress registered");

        rt.registered = true;
        rt.tokenAddress = _tokenAddress;
        tokens[_tokenId] = rt;
        tokenIds[_tokenAddress] = _tokenId;
        emit NewToken(_tokenId, _tokenAddress);
    }

    /// @notice Add tokens to the list of networks tokens
    /// @param _tokenIdList Token id list
    /// @param _tokenAddressList Token address list
    function addTokens(uint16[] calldata _tokenIdList, address[] calldata _tokenAddressList) external {
        require(_tokenIdList.length == _tokenAddressList.length, "Gov: invalid array length");
        for (uint i; i < _tokenIdList.length; i++) {
            addToken(_tokenIdList[i], _tokenAddressList[i]);
        }
    }

    /// @notice Pause token deposits for the given token
    /// @param _tokenId Token id
    /// @param _tokenPaused Token paused status
    function setTokenPaused(uint16 _tokenId, bool _tokenPaused) external onlyGovernor {
        RegisteredToken memory rt = tokens[_tokenId];
        require(rt.registered, "Gov: token not registered");

        if (rt.paused != _tokenPaused) {
            rt.paused = _tokenPaused;
            tokens[_tokenId] = rt;
            emit TokenPausedUpdate(_tokenId, _tokenPaused);
        }
    }

    /// @notice Update token address
    /// @param _tokenId Token id
    /// @param _newTokenAddress Token address to replace
    function setTokenAddress(uint16 _tokenId, address _newTokenAddress) external onlyGovernor {
        // new token address MUST not be zero address or eth address
        require(_newTokenAddress != address(0) && _newTokenAddress != ETH_ADDRESS, "Gov: invalid address");
        // tokenId MUST be registered
        RegisteredToken memory rt = tokens[_tokenId];
        require(rt.registered, "Gov: tokenId not registered");
        // tokenAddress MUST not be registered
        require(tokenIds[_newTokenAddress] == 0, "Gov: tokenAddress registered");
        // token represent ETH MUST not be updated
        require(rt.tokenAddress != ETH_ADDRESS, "Gov: eth address update disabled");

        if (rt.tokenAddress != _newTokenAddress) {
            delete tokenIds[rt.tokenAddress];
            rt.tokenAddress = _newTokenAddress;
            tokens[_tokenId] = rt;
            tokenIds[_newTokenAddress] = _tokenId;
            emit TokenAddressUpdate(_tokenId, _newTokenAddress);
        }
    }

    /// @notice Change validator status (active or not active)
    /// @param _validator Validator address
    /// @param _active Active flag
    function setValidator(address _validator, bool _active) external onlyGovernor {
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    /// @notice Checks if validator is active
    /// @param _address Validator address
    function requireActiveValidator(address _address) external view {
        require(validators[_address], "Gov: not validator");
    }

    /// @notice Get registered token info by id
    function getToken(uint16 _tokenId) external view returns (RegisteredToken memory) {
        return tokens[_tokenId];
    }

    /// @notice Get registered token id by address
    function getTokenId(address _tokenAddress) external view returns (uint16) {
        return tokenIds[_tokenAddress];
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    bytes32 internal constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @dev ERC20 tokens and ETH withdrawals gas limit, used only for complete withdrawals
    uint256 internal constant WITHDRAWAL_GAS_LIMIT = 100000;

    /// @dev Bytes in one chunk
    uint8 internal constant CHUNK_BYTES = 14;

    /// @dev Bytes of L2 Pubkey hash
    uint8 internal constant PUBKEY_HASH_BYTES = 20;

    /// @dev Max amount of tokens registered in the network
    uint16 internal constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 8192;

    /// @dev Max account id that could be registered in the network
    uint32 internal constant MAX_ACCOUNT_ID = 16777215;

    /// @dev Max sub account id that could be bound to account id
    uint8 internal constant MAX_SUB_ACCOUNT_ID = 7;

    /// @dev Expected average period of block creation
    uint256 internal constant BLOCK_PERIOD = 2 seconds;

    /// @dev Operation chunks
    uint256 internal constant DEPOSIT_BYTES = 4 * CHUNK_BYTES;
    uint256 internal constant FULL_EXIT_BYTES = 4 * CHUNK_BYTES;
    uint256 internal constant WITHDRAW_BYTES = 4 * CHUNK_BYTES;
    uint256 internal constant FORCED_EXIT_BYTES = 4 * CHUNK_BYTES;
    uint256 internal constant CHANGE_PUBKEY_BYTES = 4 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 internal constant PRIORITY_EXPIRATION_PERIOD = 14 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 internal constant PRIORITY_EXPIRATION =
        PRIORITY_EXPIRATION_PERIOD/BLOCK_PERIOD;

    /// @dev Maximum number of priority request that wait to be proceed
    /// to prevent an attacker submit a large number of priority requests
    /// that exceeding the processing power of the l2 server
    /// and force the contract to enter exodus mode
    /// this attack may occur on some blockchains with high tps but low gas prices
    uint256 internal constant MAX_PRIORITY_REQUESTS = 4096;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant MASS_FULL_EXIT_PERIOD = 5 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 internal constant UPGRADE_NOTICE_PERIOD =
        0;

    /// @dev Timestamp - seconds since unix epoch
    uint256 internal constant COMMIT_TIMESTAMP_NOT_OLDER = 24 hours;

    /// @dev Maximum available error between real commit block timestamp and analog used in the verifier (in seconds)
    /// @dev Must be used cause miner's `block.timestamp` value can differ on some small value (as we know - 15 seconds)
    uint256 internal constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 15 minutes;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 internal constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 internal constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev Max deposit of ERC20 token that is possible to deposit
    uint128 internal constant MAX_DEPOSIT_AMOUNT = 20282409603651670423947251286015;

    /// @dev Chain id
    uint8 internal constant CHAIN_ID = 2;

    /// @dev Address represent eth when deposit or withdraw
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}