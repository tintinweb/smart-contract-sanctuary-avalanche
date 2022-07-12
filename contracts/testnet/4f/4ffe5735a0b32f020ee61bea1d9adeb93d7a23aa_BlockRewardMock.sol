/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-11
*/

// File: contracts/interfaces/IBlockReward.sol

pragma solidity 0.4.24;

interface IBlockReward {
    function addExtraReceiver(uint256 _amount, address _receiver) external;
    function mintedTotally() external view returns (uint256);
    function mintedTotallyByBridge(address _bridge) external view returns (uint256);
    function bridgesAllowedLength() external view returns (uint256);
    function addBridgeTokenRewardReceivers(uint256 _amount) external;
    function addBridgeNativeRewardReceivers(uint256 _amount) external;
    function blockRewardContractId() external pure returns (bytes4);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/mocks/BlockRewardMock.sol

pragma solidity 0.4.24;



contract BlockRewardMock {
    using SafeMath for uint256;

    event BridgeTokenRewardAdded(uint256 amount, uint256 cumulativeAmount, address indexed bridge);

    address[] public validatorList;
    uint256[] public validatorRewardList;
    uint256 public mintedCoins = 0;
    uint256 public feeAmount = 0;
    mapping(bytes32 => uint256) internal uintStorage;
    bytes32 internal constant MINTED_TOTALLY_BY_BRIDGE = "mintedTotallyByBridge";
    bytes4 internal constant MINT_REWARD = 0x91c0aabf; // mintReward(uint256)
    address public token;
    uint256 public bridgeTokenReward = 0;

    function() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    function addExtraReceiver(uint256 _amount, address _receiver) external {
        require(_amount > 0);
        require(_receiver != address(0));
        mintedCoins = mintedCoins.add(_amount);
        this.addMintedTotallyByBridge(_amount, msg.sender);
        _receiver.transfer(_amount);
    }

    function mintedTotally() public view returns (uint256) {
        return mintedCoins;
    }

    function mintedTotallyByBridge(address _bridge) public view returns (uint256) {
        return uintStorage[keccak256(abi.encode(MINTED_TOTALLY_BY_BRIDGE, _bridge))];
    }

    function addMintedTotallyByBridge(uint256 _amount, address _bridge) external {
        bytes32 hash = keccak256(abi.encode(MINTED_TOTALLY_BY_BRIDGE, _bridge));
        uintStorage[hash] = uintStorage[hash].add(_amount);
    }

    function setValidatorsRewards(address[] _initialValidators) external {
        validatorList = _initialValidators;
    }

    function setToken(address _token) external {
        token = _token;
    }

    function addBridgeNativeRewardReceivers(uint256 _amount) external {
        feeAmount = _amount;
        uint256 feePerValidator = _amount.div(validatorList.length);

        uint256 randomValidatorIndex;
        uint256 diff = _amount.sub(feePerValidator.mul(validatorList.length));
        if (diff > 0) {
            randomValidatorIndex = random(validatorList.length);
        }

        for (uint256 i = 0; i < validatorList.length; i++) {
            uint256 feeToDistribute = feePerValidator;
            if (diff > 0 && randomValidatorIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }
            this.addExtraReceiver(feeToDistribute, validatorList[i]);
        }
    }

    function addBridgeTokenRewardReceivers(uint256 _amount) external {
        require(_amount != 0);
        validatorRewardList = new uint256[](validatorList.length);
        feeAmount = _amount;
        uint256 feePerValidator = _amount.div(validatorList.length);

        uint256 randomValidatorIndex;
        uint256 diff = _amount.sub(feePerValidator.mul(validatorList.length));
        if (diff > 0) {
            randomValidatorIndex = random(validatorList.length);
        }

        for (uint256 i = 0; i < validatorList.length; i++) {
            uint256 feeToDistribute = feePerValidator;
            if (diff > 0 && randomValidatorIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }
            validatorRewardList[i] = feeToDistribute;
        }

        bridgeTokenReward = bridgeTokenReward.add(_amount);
        emit BridgeTokenRewardAdded(_amount, bridgeTokenReward, msg.sender);
        require(token.call(abi.encodeWithSelector(MINT_REWARD, _amount)));
    }

    function random(uint256 _count) public view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }

    function blockRewardContractId() public pure returns (bytes4) {
        return bytes4(keccak256("blockReward"));
    }
}