/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-28
*/

// Sources flattened with hardhat v2.10.0 https://hardhat.org

// File contracts/lib/Ownable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Unlicense

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}


// File contracts/intf/IDODO.sol

/*

    Copyright 2020 DODO ZOO.
    

*/

pragma solidity 0.6.9;

interface IDODO {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(uint256 amount)
        external
        view
        returns (uint256 receiveQuote);

    function queryBuyBaseToken(uint256 amount)
        external
        view
        returns (uint256 payQuote);

    function getExpectedTarget()
        external
        view
        returns (uint256 baseTarget, uint256 quoteTarget);

    function depositBaseTo(address to, uint256 amount)
        external
        returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(address to, uint256 amount)
        external
        returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function buyBaseTokenTo(
        address _address,
        uint256 amount,
        bool _isFillingSwap,
        bytes calldata data
    ) external returns (uint256);

    function sellBaseTokenTo(
        address _address,
        uint256 amount,
        bool _isFillingSwap,
        bytes calldata data
    ) external returns (uint256);
}


// File contracts/helper/CloneFactory.sol

/*

    Copyright 2020 DODO ZOO.
    

*/

pragma solidity 0.6.9;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}


// File contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    

*/

pragma solidity 0.6.9;

/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


// File contracts/DODOZoo.sol

/*

    Copyright 2020 DODO ZOO.
    

*/

pragma solidity 0.6.9;




/**
 * @title DODOZoo
 * @author DODO Breeder
 *
 * @notice Register of All DODO
 */
contract DODOZoo is Ownable {
    using SafeMath for uint256;
    address public _DODO_LOGIC_;
    address public _CLONE_FACTORY_;

    address public _DEFAULT_SUPERVISOR_;

    mapping(bytes32 => bool) public _FILLED_TX_;
    uint16 public _CHAIN_ID_;

    mapping(address => mapping(address => address)) internal _DODO_REGISTER_;
    address[] public _DODOs;
    address _VAULT_TOKEN_;
    // ============ Events ============

    event DODOBirth(address newBorn, address baseToken, address quoteToken);
    event SwapStarted(
        address to,
        uint256 amount,
        uint16 chainId,
        address token,
        uint256 receiveQuote
    );
    event SwapCompleted(
        address to,
        uint256 amount,
        uint16 chainId,
        address token,
        uint256 receiveQuote
    );

    // ============ Constructor Function ============

    constructor(
        address _dodoLogic,
        address _cloneFactory,
        address _defaultSupervisor,
        uint16 _chainId
    ) public {
        _DODO_LOGIC_ = _dodoLogic;
        _CLONE_FACTORY_ = _cloneFactory;
        _DEFAULT_SUPERVISOR_ = _defaultSupervisor;
        _CHAIN_ID_ = _chainId;
    }

    // ============ Admin Function ============

    function setDODOLogic(address _dodoLogic) external onlyOwner {
        _DODO_LOGIC_ = _dodoLogic;
    }

    function setCloneFactory(address _cloneFactory) external onlyOwner {
        _CLONE_FACTORY_ = _cloneFactory;
    }

    function setDefaultSupervisor(address _defaultSupervisor)
        external
        onlyOwner
    {
        _DEFAULT_SUPERVISOR_ = _defaultSupervisor;
    }

    function removeDODO(address dodo) external onlyOwner {
        address baseToken = IDODO(dodo)._BASE_TOKEN_();
        address quoteToken = IDODO(dodo)._QUOTE_TOKEN_();
        require(isDODORegistered(baseToken, quoteToken), "DODO_NOT_REGISTERED");
        _DODO_REGISTER_[baseToken][quoteToken] = address(0);
        for (uint256 i = 0; i <= _DODOs.length - 1; i++) {
            if (_DODOs[i] == dodo) {
                _DODOs[i] = _DODOs[_DODOs.length - 1];
                _DODOs.pop();
                break;
            }
        }
    }

    function addDODO(address dodo) public onlyOwner {
        address baseToken = IDODO(dodo)._BASE_TOKEN_();
        address quoteToken = IDODO(dodo)._QUOTE_TOKEN_();
        require(!isDODORegistered(baseToken, quoteToken), "DODO_REGISTERED");
        _DODO_REGISTER_[baseToken][quoteToken] = dodo;
        _DODOs.push(dodo);
    }

    // ============ Breed DODO Function ============

    function breedDODO(
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external onlyOwner returns (address newBornDODO) {
        require(!isDODORegistered(baseToken, quoteToken), "DODO_REGISTERED");
        newBornDODO = ICloneFactory(_CLONE_FACTORY_).clone(_DODO_LOGIC_);
        IDODO(newBornDODO).init(
            _OWNER_,
            _DEFAULT_SUPERVISOR_,
            maintainer,
            baseToken,
            quoteToken,
            oracle,
            lpFeeRate,
            mtFeeRate,
            k,
            gasPriceLimit
        );
        addDODO(newBornDODO);
        emit DODOBirth(newBornDODO, baseToken, quoteToken);
        return newBornDODO;
    }

    // ============ View Functions ============

    function isDODORegistered(address baseToken, address quoteToken)
        public
        view
        returns (bool)
    {
        if (
            _DODO_REGISTER_[baseToken][quoteToken] == address(0) &&
            _DODO_REGISTER_[quoteToken][baseToken] == address(0)
        ) {
            return false;
        } else {
            return true;
        }
    }

    function getDODO(address baseToken, address quoteToken)
        external
        view
        returns (address)
    {
        return _DODO_REGISTER_[baseToken][quoteToken];
    }

    function getDODOs() external view returns (address[] memory) {
        return _DODOs;
    }

    function fillSwap(
        address dodo,
        address token,
        address receipient,
        uint256 amount,
        bool baseToken,
        bytes32 txHash,
        bytes calldata data
    ) external returns (uint256) {
        require(!_FILLED_TX_[txHash], "__TX_ALREADY_FILLED__");
        _FILLED_TX_[txHash] = true;
        uint256 receiveQuote;
        if (baseToken) {
            receiveQuote = IDODO(dodo).sellBaseTokenTo(
                receipient,
                amount,
                true,
                data
            );
        } else {
            receiveQuote = IDODO(dodo).buyBaseTokenTo(
                receipient,
                amount,
                true,
                data
            );
        }

        emit SwapCompleted(receipient, amount, _CHAIN_ID_, token, receiveQuote);
        return receiveQuote;
    }

    function initCrossChainSwap(
        address dodo,
        address targetToken,
        uint256 amount,
        uint16 tagetChainId,
        bool baseToken,
        bytes calldata data
    ) external returns (uint256) {
        uint256 receiveQuote = 0;

        if (baseToken) {
            receiveQuote = IDODO(dodo).sellBaseTokenTo(
                msg.sender,
                amount,
                false,
                data
            );
        } else {
            receiveQuote = IDODO(dodo).buyBaseTokenTo(
                msg.sender,
                amount,
                false,
                data
            );
        }

        emit SwapStarted(
            msg.sender,
            amount,
            tagetChainId,
            targetToken,
            receiveQuote
        );
        return receiveQuote;
    }

    function querySwap(
        address dodo,
        uint256 amount,
        bool baseToken
    ) external view returns (uint256) {
        if (baseToken) {
            return IDODO(dodo).querySellBaseToken(amount);
        } else {
            return IDODO(dodo).queryBuyBaseToken(amount);
        }
    }
}