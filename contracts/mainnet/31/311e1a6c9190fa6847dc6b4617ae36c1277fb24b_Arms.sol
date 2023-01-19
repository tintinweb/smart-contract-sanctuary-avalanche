// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";
import {LogisticVRGDA} from "./LogisticVRGDA.sol";

/// @title Logistic To Linear Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice VRGDA with a piecewise logistic and linear issuance curve.
abstract contract LogisticToLinearVRGDA is LogisticVRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The number of tokens that must be sold for the switch to occur.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable soldBySwitch;

    /// @dev The time soldBySwitch tokens were targeted to sell by.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable switchTime;

    /// @dev The total number of tokens to target selling every full unit of time.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable perTimeUnit;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _logisticAsymptote The asymptote (minus 1) of the pre-switch logistic curve, scaled by 1e18.
    /// @param _timeScale The steepness of the pre-switch logistic curve, scaled by 1e18.
    /// @param _soldBySwitch The number of tokens that must be sold for the switch to occur.
    /// @param _switchTime The time soldBySwitch tokens were targeted to sell by, scaled by 1e18.
    /// @param _perTimeUnit The number of tokens to target selling in 1 full unit of time, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _logisticAsymptote,
        int256 _timeScale,
        int256 _soldBySwitch,
        int256 _switchTime,
        int256 _perTimeUnit
    ) LogisticVRGDA(_targetPrice, _priceDecayPercent, _logisticAsymptote, _timeScale) {
        soldBySwitch = _soldBySwitch;

        switchTime = _switchTime;

        perTimeUnit = _perTimeUnit;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        // If we've not yet reached the number of sales required for the switch
        // to occur, we'll continue using the standard logistic VRGDA schedule.
        if (sold < soldBySwitch) return LogisticVRGDA.getTargetSaleTime(sold);

        unchecked {
            return unsafeWadDiv(sold - soldBySwitch, perTimeUnit) + switchTime;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadLn, unsafeDiv, unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title Logistic Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice VRGDA with a logistic issuance curve.
abstract contract LogisticVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @dev The maximum number of tokens of tokens to sell + 1. We add
    /// 1 because the logistic function will never fully reach its limit.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable logisticLimit;

    /// @dev The maximum number of tokens of tokens to sell + 1 multiplied
    /// by 2. We could compute it on the fly each time but this saves gas.
    /// @dev Represented as a 36 decimal fixed point number.
    int256 internal immutable logisticLimitDoubled;

    /// @dev Time scale controls the steepness of the logistic curve,
    /// which affects how quickly we will reach the curve's asymptote.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable timeScale;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _maxSellable The maximum number of tokens to sell, scaled by 1e18.
    /// @param _timeScale The steepness of the logistic curve, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _maxSellable,
        int256 _timeScale
    ) VRGDA(_targetPrice, _priceDecayPercent) {
        // Add 1 wad to make the limit inclusive of _maxSellable.
        logisticLimit = _maxSellable + 1e18;

        // Scale by 2e18 to both double it and give it 36 decimals.
        logisticLimitDoubled = logisticLimit * 2e18;

        timeScale = _timeScale;
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        unchecked {
            return -unsafeWadDiv(wadLn(unsafeDiv(logisticLimitDoubled, sold + logisticLimit) - 1e18), timeScale);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Variable Rate Gradual Dutch Auction
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Sell tokens roughly according to an issuance schedule.
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                            VRGDA PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets target price and per time unit price decay for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    constructor(int256 _targetPrice, int256 _priceDecayPercent) {
        targetPrice = _targetPrice;

        decayConstant = wadLn(1e18 - _priceDecayPercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of tokens that have been sold so far.
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) public view virtual returns (uint256) {
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1))
            ))));
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title GOO (Gradual Ownership Optimization) Issuance
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Implementation of the GOO Issuance mechanism.
library LibGOO {
    using FixedPointMathLib for uint256;

    /// @notice Compute goo balance based on emission multiple, last balance, and time elapsed.
    /// @param emissionMultiple The multiple on emissions to consider when computing the balance.
    /// @param lastBalanceWad The last checkpointed balance to apply the emission multiple over time to, scaled by 1e18.
    /// @param timeElapsedWad The time elapsed since the last checkpoint, scaled by 1e18.
    function computeGOOBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 timeElapsedWad
    ) internal pure returns (uint256) {
        unchecked {
            // We use wad math here because timeElapsedWad is, as the name indicates, a wad.
            uint256 timeElapsedSquaredWad = timeElapsedWad.mulWadDown(timeElapsedWad);

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * timeElapsedSquaredWad) >> 2) +

            timeElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LibString} from "solmate/utils/LibString.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LogisticToLinearVRGDA} from "VRGDAs/LogisticToLinearVRGDA.sol";

import {ArmsERC721} from "./utils/token/ArmsERC721.sol";

import {Shirak} from "./Shirak.sol";
import {MechAvax} from "./MechAvax.sol";



/// @title Armaments NFT
/// @notice Forked by 0xBoots
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Arms is an ERC721 that can hold custom art.
contract Arms is ArmsERC721, LogisticToLinearVRGDA {
    using LibString for uint256;

    

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the shirak ERC20 token contract.
    Shirak public immutable shirak;

    /// @notice The address which receives arms reserved for the community.
    address public immutable community;

    /*//////////////////////////////////////////////////////////////
                                  URIS
    //////////////////////////////////////////////////////////////*/

    /// @notice Base URI for minted arms.
    string public BASE_URI;
    
    /// @notice Uri file type extension.
    string public URI_EXTENSION = ".json";

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of the VRGDA mint.
    uint256 public immutable mintStart;

    /// @notice Id of the most recently minted arm.
    /// @dev Will be 0 if no arms have been minted yet.
    uint128 public currentId;

    /*//////////////////////////////////////////////////////////////
                          COMMUNITY PAGES STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of arms minted to the community reserve.
    uint128 public numMintedForCommunity;

    /*//////////////////////////////////////////////////////////////
                            PRICING CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The day the switch from a logistic to translated linear VRGDA is targeted to occur.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SWITCH_DAY_WAD = 233e18;

    /// @notice The minimum amount of arms that must be sold for the VRGDA issuance
    /// schedule to switch from logistic to the "post switch" translated linear formula.
    /// @dev Computed off-chain by plugging SWITCH_DAY_WAD into the uninverted pacing formula.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal constant SOLD_BY_SWITCH_WAD = 8336.760939794622713006e18;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PagePurchased(address indexed user, uint256 indexed armId, uint256 price);

    event CommunityArmsMinted(address indexed user, uint256 lastMintedPageId, uint256 numArms);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ReserveImbalance();

    error PriceExceededMax(uint256 currentPrice);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRGDA parameters, mint start, relevant addresses, and base URI.
    /// @param _mintStart Timestamp for the start of the VRGDA mint.
    /// @param _shirak Address of the Shirak contract.
    /// @param _community Address of the community reserve.
    /// @param _mechAvax Address of the MechAvax contract.
    /// @param _baseUri Base URI for token metadata.
    constructor(
        // Mint config:
        uint256 _mintStart,
        // Addresses:
        Shirak _shirak,
        address _community,
        MechAvax _mechAvax,
        // URIs:
        string memory _baseUri
    )
        ArmsERC721(_mechAvax, "Mechavax Blank Armament", "MARM")
        LogisticToLinearVRGDA(
            4.2069e18, // Target price.
            0.31e18, // Price decay percent.
            9000e18, // Logistic asymptote.
            0.014e18, // Logistic time scale.
            SOLD_BY_SWITCH_WAD, // Sold by switch.
            SWITCH_DAY_WAD, // Target switch day.
            9e18 // Arms to target per day.
        )
    {
        mintStart = _mintStart;

        shirak = _shirak;

        community = _community;

        BASE_URI = _baseUri;
    }

    /*//////////////////////////////////////////////
                        ROYALTY FUNCTION
    //////////////////////////////////////////////*/

    function updateRoyalties() external {
    
        _setDefaultRoyalty(mechAvax.royaltyPayout(), mechAvax.tokenRoyalties());
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a arm with shirak, burning the cost.
    /// @param maxPrice Maximum price to pay to mint the arm.
    /// @param useVirtualBalance Whether the cost is paid from the
    /// user's virtual shirak balance, or from their ERC20 shirak balance.
    /// @return armId The id of the arm that was minted.
    function mintFromShirak(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 armId) {
        // Will revert if prior to mint start.
        uint256 currentPrice = armPrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        // Decrement the user's shirak balance by the current
        // price, either from virtual balance or ERC20 balance.
        useVirtualBalance
            ? mechAvax.burnShirakForArms(msg.sender, currentPrice)
            : shirak.burnForArms(msg.sender, currentPrice);

        unchecked {
            emit PagePurchased(msg.sender, armId = ++currentId, currentPrice);

            _mint(msg.sender, armId);
        }
    }

    /// @notice Calculate the mint cost of a arm.
    /// @dev If the number of sales is below a pre-defined threshold, we use the
    /// VRGDA pricing algorithm, otherwise we use the post-switch pricing formula.
    /// @dev Reverts due to underflow if minting hasn't started yet. Done to save gas.
    function armPrice() public view returns (uint256) {
        // We need checked math here to cause overflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        unchecked {
            // The number of arms minted for the community reserve
            // should never exceed 10% of the total supply of arms.
            return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), currentId - numMintedForCommunity);
        }
    }

    /*//////////////////////////////////////////////////////////////
                      COMMUNITY PAGES MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of arms to the community reserve.
    /// @param numArms The number of arms to mint to the reserve.
    /// @dev Arms minted to the reserve cannot comprise more than 10% of the sum of the
    /// supply of shirak minted arms and the supply of arms minted to the community reserve.
    function mintCommunityArms(uint256 numArms) external returns (uint256 lastMintedPageId) {
        unchecked {
            // Optimistically increment numMintedForCommunity, may be reverted below.
            // Overflow in this calculation is possible but numArms would have to be so
            // large that it would cause the loop in _batchMint to run out of gas quickly.
            uint256 newNumMintedForCommunity = numMintedForCommunity += uint128(numArms);

            // Ensure that after this mint arms minted to the community reserve won't comprise more than
            // 10% of the new total arm supply. currentId is equivalent to the current total supply of arms.
            if (newNumMintedForCommunity > ((lastMintedPageId = currentId) + numArms) / 10) revert ReserveImbalance();

            // Mint the arms to the community reserve and update lastMintedPageId once minting is complete.
            lastMintedPageId = _batchMint(mechAvax.owner(), numArms, lastMintedPageId);

            currentId = uint128(lastMintedPageId); // Update currentId with the last minted arm id.

            emit CommunityArmsMinted(msg.sender, lastMintedPageId, numArms);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string calldata baseURI_) external {
        require(msg.sender == mechAvax.owner(), "not auth");
        BASE_URI = baseURI_;
    }

    function setBaseExtension(string memory newBaseExtension) public {
        require(msg.sender == mechAvax.owner(), "not auth");
         URI_EXTENSION = newBaseExtension;
    }

    /*//////////////////////////////////////////////////////////////
                             TOKEN URI LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns a arm's URI if it has been minted.
    /// @param armId The id of the arm to get the URI for.
    function tokenURI(uint256 armId) public view virtual override returns (string memory) {
        if (armId == 0 || armId > currentId) revert("NOT_MINTED");

        return string.concat(BASE_URI, armId.toString(), URI_EXTENSION);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LibGOO} from "shirak-issuance/LibGOO.sol";
import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

import {RandProvider} from "./utils/rand/RandProvider.sol";
import {MechsERC721} from "./utils/token/MechsERC721.sol";

import {Shirak} from "./Shirak.sol";
import {Arms} from "./Arms.sol";
import {MintERC721} from "./MintERC721.sol";

/// @title Mechavax NFT
/// @notice Forked by 0xBoots
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice An experimental decentralized art factory by Justin Roiland and Paradigm.
contract MechAvax is MechsERC721, LogisticVRGDA, Owned, ERC1155TokenReceiver {
    using LibString for uint256;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ROYALTIES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice The royalty precentage.
    uint96 public tokenRoyalties = 1000; // 10% royalty

    /// @notice The address for rewards.
    address public royaltyPayout;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Shirak ERC20 token contract.
    Shirak public immutable shirak;

    /// @notice The address of the Arms ERC721 token contract.
    Arms public immutable arms;

    /// @notice The address of the ticket minted by other ERC721 token contract.
    address public immutable ticket;

    /// @notice The address of the ticket minted by initial ERC721 token contract.
    address public immutable EP;

    /// @notice The address of the new ticket minted by new ERC721 token contract.
    address public newEP;

    /// @notice The address which receives mechs reserved for the team.
    address public immutable team;

    /// @notice The address of a randomness provider. This provider will initially be
    /// a wrapper around Chainlink VRF v1, but can be changed in case it is fully sunset.
    RandProvider public randProvider;

    ///@notice the address of the approved stake locking contract. Initially set to null. Must be set via deploy.
    address public stakeLocker;

    /*//////////////////////////////////////////////////////////////
                            SUPPLY CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable mechs.
    uint256 public constant MAX_SUPPLY = 4500;

    /// @notice Maximum amount of mechs mintable via claimMech.
    uint256 public constant MINTLIST_SUPPLY = 2206;

    /// @notice Maximum amount of mintable legendary mechs.
    uint256 public constant LEGENDARY_SUPPLY = 12;

    /// @notice Maximum amount of mechs split between the reserves.
    /// @dev Set to comprise 20% of the sum of shirak mintable mechs + reserved mechs.
    uint256 public constant RESERVED_SUPPLY = 312;

    /// @notice Maximum amount of mechs that can be minted via VRGDA.
    // prettier-ignore
    uint256 public constant MAX_MINTABLE = MAX_SUPPLY
        - MINTLIST_SUPPLY
        - LEGENDARY_SUPPLY
        - RESERVED_SUPPLY;

    /*//////////////////////////////////////////////////////////////
                           METADATA CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Provenance hash for mech metadata.
    bytes32 public PROVENANCE_HASH;

    /// @notice URI for mechs pending reveal.
    string public UNREVEALED_URI;

    /// @notice Base URI for minted mechs.
    string public BASE_URI;

    /// @notice Uri file type extension.
    string public URI_EXTENSION = ".json";

    /*//////////////////////////////////////////////////////////////
                            VRGDA INPUT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of minting.
    uint256 public immutable mintStart;

    /// @notice Number of mechs minted from shirak.
    uint128 public numMintedFromShirak;

    /*//////////////////////////////////////////////////////////////
                         STAKING & TRANSFER STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct containing staked bool.
    struct MechStaked {
        // if true and noTransferStaking == true then no transfer allowed.
        bool isStaked;
    }
    /// @notice Mapping of staked struct to tokenID.
    mapping(uint256 => MechStaked) public mechStaked;

    /// @notice Check if transfers are allowed while staked
    bool public noTransferStaking = false;


    /*//////////////////////////////////////////////////////////////
                         LGENDARY LOCK STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if legendary mint lock is on
    bool public legLock = false;

    /// @notice address of the permitted legendary minter
    address public legMinter;


    /*//////////////////////////////////////////////////////////////
                         STANDARD MECH STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Id of the most recently minted non legendary mech.
    /// @dev Will be 0 if no non legendary mechs have been minted yet.
    uint128 public currentNonLegendaryId;

    /// @notice The number of mechs minted to the reserves.
    uint256 public numMintedForReserves;

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY MECH AUCTION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Initial legendary mech auction price.
    uint256 public constant LEGENDARY_MECH_INITIAL_START_PRICE = 42;

    /// @notice The last LEGENDARY_SUPPLY ids are reserved for legendary mechs.
    uint256 public constant FIRST_LEGENDARY_MECH_ID = MAX_SUPPLY - LEGENDARY_SUPPLY + 1;

    /// @notice Legendary auctions begin each time a multiple of these many mechs have been minted from shirak.
    /// @dev We add 1 to LEGENDARY_SUPPLY because legendary auctions begin only after the first interval.
    uint256 public constant LEGENDARY_AUCTION_INTERVAL = MAX_MINTABLE / (LEGENDARY_SUPPLY + 1);

    /// @notice Struct holding data required for legendary mech auctions.
    struct LegendaryMechAuctionData {
        // Start price of current legendary mech auction.
        uint128 startPrice;
        // Number of legendary mechs sold so far.
        uint128 numSold;
    }

    /// @notice Data about the current legendary mech auction.
    LegendaryMechAuctionData public legendaryMechAuctionData;

    /*//////////////////////////////////////////////////////////////
                          MECH REVEAL STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding data required for mech reveals.
    struct MechRevealsData {
        // Last randomness obtained from the rand provider.
        uint64 randomSeed;
        // Next reveal cannot happen before this timestamp.
        uint64 nextRevealTimestamp;
        // Id of latest mech which has been revealed so far.
        uint64 lastRevealedId;
        // Remaining mechs to be revealed with the current seed.
        uint56 toBeRevealed;
        // Whether we are waiting to receive a seed from the provider.
        bool waitingForSeed;
    }

    /// @notice Data about the current state of mech reveals.
    MechRevealsData public mechRevealsData;

    /*//////////////////////////////////////////////////////////////
                            SOULBOUND ARMAMENT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps mech ids to NFT contracts and their ids to the # of those NFT ids gobbled by the mech.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public getCopiesOfArmsBondedToMech;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ShirakBalanceUpdated(address indexed user, uint256 newShirakBalance);

    event MechClaimed(address indexed user, uint256 indexed mechId);
    event MechPurchased(address indexed user, uint256 indexed mechId, uint256 price);
    event LegendaryMechMinted(address indexed user, uint256 indexed mechId, uint256[] burnedMechIds);
    event ReservedMechsMinted(address indexed user, uint256 lastMintedMechId, uint256 numMechsEach);

    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event RandProviderUpgraded(address indexed user, RandProvider indexed newRandProvider);

    event MechsRevealed(address indexed user, uint256 numMechs, uint256 lastRevealedId);

    event ArmsBonded(address indexed user, uint256 indexed mechId, address indexed nft, uint256 id);

    event PhashUpdated(bytes32 oldPhash, bytes32 newPhash, address updater);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidProof();
    error AlreadyClaimed();
    error MintStartPending();

    error SeedPending();
    error RevealsPending();
    error RequestTooEarly();
    error ZeroToBeRevealed();
    error NotRandProvider();

    error ReserveImbalance();

    error Cannibalism();
    error OwnerMismatch(address owner);

    error NoRemainingLegendaryMechs();
    error CannotBurnLegendary(uint256 mechId);
    error InsufficientMechAmount(uint256 cost);
    error LegendaryAuctionNotStarted(uint256 mechsLeft);

    error PriceExceededMax(uint256 currentPrice);

    error NotEnoughRemainingToBeRevealed(uint256 totalRemainingToBeRevealed);

    error UnauthorizedCaller(address caller);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets VRGDA parameters, mint config, relevant addresses, and URIs.
    /// @param _ep address of initial EP
    /// @param _ticket address of second ticket
    /// @param _mintStart Timestamp for the start of the VRGDA mint.
    /// @param _shirak Address of the Shirak contract.
    /// @param _team Address of the team reserve.
    /// @param _randProvider Address of the randomness provider.
    /// @param _baseUri Base URI for revealed mechs.
    /// @param _unrevealedUri URI for unrevealed mechs.
    /// @param _provenanceHash Provenance Hash for mech metadata.
    constructor(
        // Mint config:
        address _ep,
        uint256 _mintStart,
        // Addresses:
        Shirak _shirak,
        Arms _arms,
        address _team,
        address _ticket, 
        RandProvider _randProvider,
        // URIs:
        string memory _baseUri,
        string memory _unrevealedUri,
        // Provenance:
        bytes32 _provenanceHash
    )
        MechsERC721("Mechavax", "MECH")
        Owned(msg.sender)
        LogisticVRGDA(
            69.42e18, // Target price.
            0.39e18, // Price decay percent.
            // Max mechs mintable via VRGDA.
            toWadUnsafe(MAX_MINTABLE),
            0.0042e18 // Time scale.
        )
    {
  
        mintStart = _mintStart;
        EP = _ep;
                
        shirak = _shirak;
        arms = _arms;
        team = _team;
        ticket = _ticket;
        randProvider = _randProvider;

        BASE_URI = _baseUri;
        UNREVEALED_URI = _unrevealedUri;

        PROVENANCE_HASH = _provenanceHash;

        // Set the starting price for the first legendary mech auction.
        legendaryMechAuctionData.startPrice = uint128(LEGENDARY_MECH_INITIAL_START_PRICE);

        // Reveal for initial mint must wait a day from the start of the mint.
        mechRevealsData.nextRevealTimestamp = uint64(_mintStart + 1 days);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /*//////////////////////////////////////////////
                        NEWEP FUNCTION
    //////////////////////////////////////////////*/

    function setNewEP(address _newEP) external onlyOwner {
        newEP = _newEP;
    }

    /*//////////////////////////////////////////////
                PROVENANCE HASH FUNCTION
    //////////////////////////////////////////////*/

    function setPHash(bytes32 _provenanceHash) external onlyOwner {
        bytes32 oldHash = PROVENANCE_HASH;
        PROVENANCE_HASH = _provenanceHash;
        emit PhashUpdated(oldHash, PROVENANCE_HASH, msg.sender);
    }

    /*//////////////////////////////////////////////
                        ROYALTY FUNCTION
    //////////////////////////////////////////////*/

    function setTokenRoyalties(uint96 _royalties) external onlyOwner {
        tokenRoyalties = _royalties;
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);
    }

    function setRoyaltyPayoutAddress(address _payoutAddress) external onlyOwner
    {
        royaltyPayout = _payoutAddress;
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);
    }

    /*//////////////////////////////////////////////////////////////
                          MINTLIST CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim from mintlist, using a ticket system.
    /// @dev Function does not directly enforce the MINTLIST_SUPPLY limit for gas efficiency. The
    /// limit is enforced during the creation of the ticket system, which will be shared publicly.
    /// @param _ticketIds the ID of tickets user wants to burn.
    /// @return mechId The id of the mech that was claimed.
    function claimMech(uint256[] calldata _ticketIds) payable external callerIsUser returns (uint256 mechId) {
        // If minting has not yet begun, revert.
        if (mintStart > block.timestamp) revert MintStartPending();
        //check for empty array
        require(_ticketIds.length > 0, "empty array");

        if(msg.value == 0){

            for (uint256 i = 0; i < _ticketIds.length; ++i) {

                ERC721(ticket).transferFrom(msg.sender, address(this), _ticketIds[i]);

                unchecked {
                    // Overflow should be impossible due to supply cap of 10,000.
                    emit MechClaimed(msg.sender, mechId = ++currentNonLegendaryId);
                }

                _mint(msg.sender, mechId); 
            }
        }

        else if(msg.value >= 1 ether * _ticketIds.length){
            
            require(payable(owner).send(msg.value));

            for (uint256 i = 0; i < _ticketIds.length; ++i) {
                 
                ERC721(EP).transferFrom(msg.sender, address(this), _ticketIds[i]);
                MintERC721(newEP).mint(msg.sender, _ticketIds[i]);
                unchecked {
                    // Overflow should be impossible due to supply cap of 10,000.
                    emit MechClaimed(msg.sender, mechId = ++currentNonLegendaryId);
                }

                _mint(msg.sender, mechId); 
            }
        }

        else revert("mint condition mismatch");
        

    }
    

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a mech, paying with shirak.
    /// @param maxPrice Maximum price to pay to mint the mech.
    /// @param useVirtualBalance Whether the cost is paid from the
    /// user's virtual shirak balance, or from their ERC20 shirak balance.
    /// @return mechId The id of the mech that was minted.
    function mintFromShirak(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 mechId) {
        // No need to check if we're at MAX_MINTABLE,
        // mechPrice() will revert once we reach it due to its
        // logistic nature. It will also revert prior to the mint start.
        uint256 currentPrice = mechPrice();

        // If the current price is above the user's specified max, revert.
        if (currentPrice > maxPrice) revert PriceExceededMax(currentPrice);

        // Decrement the user's shirak balance by the current
        // price, either from virtual balance or ERC20 balance.
        useVirtualBalance
            ? updateUserShirakBalance(msg.sender, currentPrice, ShirakBalanceUpdateType.DECREASE)
            : shirak.burnForMechs(msg.sender, currentPrice);

        unchecked {
            ++numMintedFromShirak; // Overflow should be impossible due to the supply cap.

            emit MechPurchased(msg.sender, mechId = ++currentNonLegendaryId, currentPrice);
        }

        _mint(msg.sender, mechId);
    }

    /// @notice Mech pricing in terms of shirak.
    /// @dev Will revert if called before minting starts
    /// or after all mechs have been minted via VRGDA.
    /// @return Current price of a mech in terms of shirak.
    function mechPrice() public view returns (uint256) {
        // We need checked math here to cause underflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - mintStart;

        return getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), numMintedFromShirak);
    }

    /*//////////////////////////////////////////////////////////////
                     LEGENDARY GOBBLER AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a legendary mech by burning multiple standard mechs.
    /// @param mechIds The ids of the standard mechs to burn.
    /// @return mechId The id of the legendary mech that was minted.
    function mintLegendaryMech(uint256[] calldata mechIds) external returns (uint256 mechId) {
        if (legLock == true){
            require(msg.sender == legMinter, "not authorized");
        }
        // Get the number of legendary mechs sold up until this point.
        uint256 numSold = legendaryMechAuctionData.numSold;

        mechId = FIRST_LEGENDARY_MECH_ID + numSold; // Assign id.

        // This will revert if the auction hasn't started yet or legendaries
        // have sold out entirely, so there is no need to check here as well.
        uint256 cost = legendaryMechPrice();

        if (mechIds.length < cost) revert InsufficientMechAmount(cost);

        // Overflow should not occur in here, as most math is on emission multiples, which are inherently small.
        unchecked {
            uint256 burnedMultipleTotal; // The legendary's emissionMultiple will be 2x the sum of the mechs burned.

            /*//////////////////////////////////////////////////////////////
                                    BATCH BURN LOGIC
            //////////////////////////////////////////////////////////////*/

            uint256 id; // Storing outside the loop saves ~7 gas per iteration.

            for (uint256 i = 0; i < cost; ++i) {
                id = mechIds[i];

                if (id >= FIRST_LEGENDARY_MECH_ID) revert CannotBurnLegendary(id);

                MechData storage mech = getMechData[id];

                require(mech.owner == msg.sender, "WRONG_FROM");

                burnedMultipleTotal += mech.emissionMultiple;

                delete getApproved[id];

                emit Transfer(msg.sender, mech.owner = address(0), id);
            }

            /*//////////////////////////////////////////////////////////////
                                 LEGENDARY MINTING LOGIC
            //////////////////////////////////////////////////////////////*/

            // The legendary's emissionMultiple is 2x the sum of the multiples of the mechs burned.
            getMechData[mechId].emissionMultiple = uint32(burnedMultipleTotal * 2);

            // Update the user's user data struct in one big batch. We add burnedMultipleTotal to their
            // emission multiple (not burnedMultipleTotal * 2) to account for the standard mechs that
            // were burned and hence should have their multiples subtracted from the user's total multiple.
            getUserData[msg.sender].lastBalance = uint128(shirakBalance(msg.sender)); // Checkpoint balance.
            getUserData[msg.sender].lastTimestamp = uint64(block.timestamp); // Store time alongside it.
            getUserData[msg.sender].emissionMultiple += uint32(burnedMultipleTotal); // Update multiple.
            // Update the total number of mechs owned by the user. The call to _mint
            // below will increase the count by 1 to account for the new legendary mech.
            getUserData[msg.sender].mechsOwned -= uint32(cost);

            // New start price is the max of LEGENDARY_MECH_INITIAL_START_PRICE and cost * 2.
            legendaryMechAuctionData.startPrice = uint128(
                cost <= LEGENDARY_MECH_INITIAL_START_PRICE / 2 ? LEGENDARY_MECH_INITIAL_START_PRICE : cost * 2
            );
            legendaryMechAuctionData.numSold = uint128(numSold + 1); // Increment the # of legendaries sold.

            // If mechIds has 1,000 elements this should cost around ~270,000 gas.
            emit LegendaryMechMinted(msg.sender, mechId, mechIds[:cost]);

            _mint(msg.sender, mechId);
        }
    }

    /// @notice Calculate the legendary mech price in terms of mechs, according to a linear decay function.
    /// @dev The price of a legendary mech decays as mechs are minted. The first legendary auction begins when
    /// 1 LEGENDARY_AUCTION_INTERVAL worth of mechs are minted, and the price decays linearly while the next interval of
    /// mechs are minted. Every time an additional interval is minted, a new auction begins until all legendaries have been sold.
    /// @dev Will revert if the auction hasn't started yet or legendaries have sold out entirely.
    /// @return The current price of the legendary mech being auctioned, in terms of mechs.
    function legendaryMechPrice() public view returns (uint256) {
        // Retrieve and cache various auction parameters and variables.
        uint256 startPrice = legendaryMechAuctionData.startPrice;
        uint256 numSold = legendaryMechAuctionData.numSold;

        // If all legendary mechs have been sold, there are none left to auction.
        if (numSold == LEGENDARY_SUPPLY) revert NoRemainingLegendaryMechs();

        unchecked {
            // Get and cache the number of standard mechs sold via VRGDA up until this point.
            uint256 mintedFromShirak = numMintedFromShirak;

            // The number of mechs minted at the start of the auction is computed by multiplying the # of
            // intervals that must pass before the next auction begins by the number of mechs in each interval.
            uint256 numMintedAtStart = (numSold + 1) * LEGENDARY_AUCTION_INTERVAL;

            // If not enough mechs have been minted to start the auction yet, return how many need to be minted.
            if (numMintedAtStart > mintedFromShirak) revert LegendaryAuctionNotStarted(numMintedAtStart - mintedFromShirak);

            // Compute how many mechs were minted since the auction began.
            uint256 numMintedSinceStart = mintedFromShirak - numMintedAtStart;

            // prettier-ignore
            // If we've minted the full interval or beyond it, the price has decayed to 0.
            if (numMintedSinceStart >= LEGENDARY_AUCTION_INTERVAL) return 0;
            // Otherwise decay the price linearly based on what fraction of the interval has been minted.
            else return FixedPointMathLib.unsafeDivUp(startPrice * (LEGENDARY_AUCTION_INTERVAL - numMintedSinceStart), LEGENDARY_AUCTION_INTERVAL);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            RANDOMNESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Request a new random seed for revealing mechs.
    function requestRandomSeed() external returns (bytes32) {
        uint256 nextRevealTimestamp = mechRevealsData.nextRevealTimestamp;

        // A new random seed cannot be requested before the next reveal timestamp.
        if (block.timestamp < nextRevealTimestamp) revert RequestTooEarly();

        // A random seed can only be requested when all mechs from the previous seed have been revealed.
        // This prevents a user from requesting additional randomness in hopes of a more favorable outcome.
        if (mechRevealsData.toBeRevealed != 0) revert RevealsPending();

        unchecked {
            // Prevent revealing while we wait for the seed.
            mechRevealsData.waitingForSeed = true;

            // Compute the number of mechs to be revealed with the seed.
            uint256 toBeRevealed = currentNonLegendaryId - mechRevealsData.lastRevealedId;

            // Ensure that there are more than 0 mechs to be revealed,
            // otherwise the contract could waste LINK revealing nothing.
            if (toBeRevealed == 0) revert ZeroToBeRevealed();

            // Lock in the number of mechs to be revealed from seed.
            mechRevealsData.toBeRevealed = uint56(toBeRevealed);

            // We enable reveals for a set of mechs every 24 hours.
            // Timestamp overflow is impossible on human timescales.
            mechRevealsData.nextRevealTimestamp = uint64(nextRevealTimestamp + 1 days);

            emit RandomnessRequested(msg.sender, toBeRevealed);
        }

        // Call out to the randomness provider.
        return randProvider.requestRandomBytes();
    }

    /// @notice Callback from rand provider. Sets randomSeed. Can only be called by the rand provider.
    /// @param randomness The 256 bits of verifiable randomness provided by the rand provider.
    function acceptRandomSeed(bytes32, uint256 randomness) external {
        // The caller must be the randomness provider, revert in the case it's not.
        if (msg.sender != address(randProvider)) revert NotRandProvider();

        // The unchecked cast to uint64 is equivalent to moduloing the randomness by 2**64.
        mechRevealsData.randomSeed = uint64(randomness); // 64 bits of randomness is plenty.

        mechRevealsData.waitingForSeed = false; // We have the seed now, open up reveals.

        emit RandomnessFulfilled(randomness);
    }

    /// @notice Upgrade the rand provider contract. Useful if current VRF is sunset.
    /// @param newRandProvider The new randomness provider contract address.
    function upgradeRandProvider(RandProvider newRandProvider) external onlyOwner {
        // Reset reveal state when we upgrade while the seed is pending. This gives us a
        // safeguard against malfunctions since we won't be stuck waiting for a seed forever.
        if (mechRevealsData.waitingForSeed) {
            mechRevealsData.waitingForSeed = false;
            mechRevealsData.toBeRevealed = 0;
            mechRevealsData.nextRevealTimestamp -= 1 days;
        }

        randProvider = newRandProvider; // Update the randomness provider.

        emit RandProviderUpgraded(msg.sender, newRandProvider);
    }

    /*//////////////////////////////////////////////////////////////
                          GOBBLER REVEAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Knuth shuffle to progressively reveal
    /// new mechs using entropy from a random seed.
    /// @param numMechs The number of mechs to reveal.
    function revealMechs(uint256 numMechs) external {
        uint256 randomSeed = mechRevealsData.randomSeed;

        uint256 lastRevealedId = mechRevealsData.lastRevealedId;

        uint256 totalRemainingToBeRevealed = mechRevealsData.toBeRevealed;

        // Can't reveal if we're still waiting for a new seed.
        if (mechRevealsData.waitingForSeed) revert SeedPending();

        // Can't reveal more mechs than are currently remaining to be revealed with the seed.
        if (numMechs > totalRemainingToBeRevealed) revert NotEnoughRemainingToBeRevealed(totalRemainingToBeRevealed);

        // Implements a Knuth shuffle. If something in
        // here can overflow, we've got bigger problems.
        unchecked {
            for (uint256 i = 0; i < numMechs; ++i) {
                /*//////////////////////////////////////////////////////////////
                                      DETERMINE RANDOM SWAP
                //////////////////////////////////////////////////////////////*/

                // Number of ids that have not been revealed. Subtract 1
                // because we don't want to include any legendaries in the swap.
                uint256 remainingIds = FIRST_LEGENDARY_MECH_ID - lastRevealedId - 1;

                // Randomly pick distance for swap.
                uint256 distance = randomSeed % remainingIds;

                // Current id is consecutive to last reveal.
                uint256 currentId = ++lastRevealedId;

                // Select swap id, adding distance to next reveal id.
                uint256 swapId = currentId + distance;

                /*//////////////////////////////////////////////////////////////
                                       GET INDICES FOR IDS
                //////////////////////////////////////////////////////////////*/

                // Get the index of the swap id.
                uint64 swapIndex = getMechData[swapId].idx == 0
                    ? uint64(swapId) // Hasn't been shuffled before.
                    : getMechData[swapId].idx; // Shuffled before.

                // Get the owner of the current id.
                address currentIdOwner = getMechData[currentId].owner;

                // Get the index of the current id.
                uint64 currentIndex = getMechData[currentId].idx == 0
                    ? uint64(currentId) // Hasn't been shuffled before.
                    : getMechData[currentId].idx; // Shuffled before.

                /*//////////////////////////////////////////////////////////////
                                  SWAP INDICES AND SET MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Determine the current id's new emission multiple.
                uint256 newCurrentIdMultiple = 9; // For beyond 7963.

                // The branchless expression below is equivalent to:
                //      if (swapIndex <= 3054) newCurrentIdMultiple = 6;
                // else if (swapIndex <= 5672) newCurrentIdMultiple = 7;
                // else if (swapIndex <= 7963) newCurrentIdMultiple = 8;
                assembly {
                    // prettier-ignore
                    newCurrentIdMultiple := sub(sub(sub(
                        newCurrentIdMultiple,
                        lt(swapIndex, 3584)),
                        lt(swapIndex, 2552)),
                        lt(swapIndex, 1374)
                    )
                }

                // Swap the index and multiple of the current id.
                getMechData[currentId].idx = swapIndex;
                getMechData[currentId].emissionMultiple = uint32(newCurrentIdMultiple);

                // Swap the index of the swap id.
                getMechData[swapId].idx = currentIndex;

                /*//////////////////////////////////////////////////////////////
                                   UPDATE CURRENT ID MULTIPLE
                //////////////////////////////////////////////////////////////*/

                // Update the user data for the owner of the current id.
                getUserData[currentIdOwner].lastBalance = uint128(shirakBalance(currentIdOwner));
                getUserData[currentIdOwner].lastTimestamp = uint64(block.timestamp);
                getUserData[currentIdOwner].emissionMultiple += uint32(newCurrentIdMultiple);

                // Update the random seed to choose a new distance for the next iteration.
                // It is critical that we cast to uint64 here, as otherwise the random seed
                // set after calling revealMechs(1) thrice would differ from the seed set
                // after calling revealMechs(3) a single time. This would enable an attacker
                // to choose from a number of different seeds and use whichever is most favorable.
                // Equivalent to randomSeed = uint64(uint256(keccak256(abi.encodePacked(randomSeed))))
                assembly {
                    mstore(0, randomSeed) // Store the random seed in scratch space.

                    // Moduloing by 2 ** 64 is equivalent to a uint64 cast.
                    randomSeed := mod(keccak256(0, 32), exp(2, 64))
                }
            }

            // Update all relevant reveal state.
            mechRevealsData.randomSeed = uint64(randomSeed);
            mechRevealsData.lastRevealedId = uint64(lastRevealedId);
            mechRevealsData.toBeRevealed = uint56(totalRemainingToBeRevealed - numMechs);

            emit MechsRevealed(msg.sender, numMechs, lastRevealedId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string calldata baseURI_) external onlyOwner {
    BASE_URI = baseURI_;
    }

    function setUnrevealedURI(string calldata UnrevealedURI_) external onlyOwner {
    UNREVEALED_URI = UnrevealedURI_;
    }

    function setBaseExtension(string memory newBaseExtension) public onlyOwner {
    URI_EXTENSION = newBaseExtension;
    }

    /// @notice Returns a token's URI if it has been minted.
    /// @param mechId The id of the token to get the URI for.
    function tokenURI(uint256 mechId) public view virtual override returns (string memory) {
        // Between 0 and lastRevealed are revealed normal mechs.
        if (mechId <= mechRevealsData.lastRevealedId) {
            if (mechId == 0) revert("NOT_MINTED"); // 0 is not a valid id for Art Mechs.

            return string.concat(BASE_URI, uint256(getMechData[mechId].idx).toString(), URI_EXTENSION);
        }

        // Between lastRevealed + 1 and currentNonLegendaryId are minted but not revealed.
        if (mechId <= currentNonLegendaryId) return UNREVEALED_URI;

        // Between currentNonLegendaryId and FIRST_LEGENDARY_MECH_ID are unminted.
        if (mechId < FIRST_LEGENDARY_MECH_ID) revert("NOT_MINTED");

        // Between FIRST_LEGENDARY_MECH_ID and FIRST_LEGENDARY_MECH_ID + numSold are minted legendaries.
        if (mechId < FIRST_LEGENDARY_MECH_ID + legendaryMechAuctionData.numSold)
            return string.concat(BASE_URI, mechId.toString(), URI_EXTENSION);

        revert("NOT_MINTED"); // Unminted legendaries and invalid token ids.
    } 

    /*//////////////////////////////////////////////////////////////
                            EQUIP ARM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Soulbond armament to a mech.
    /// @param mechId The mech to feed the work of art.
    /// @param nft The ERC721 or ERC1155 contract of the armament.
    /// @param id The id of the armament.
    /// @param isERC1155 Whether the armament is an ERC1155 token.
    function bondArms(
        uint256 mechId,
        address nft,
        uint256 id,
        bool isERC1155
    ) external {
        // Get the owner of the mech to feed.
        address owner = getMechData[mechId].owner;

        // The caller must own the mech they're feeding.
        if (owner != msg.sender) revert OwnerMismatch(owner);

        // Mechs have taken a vow not to eat other mechs.
        if (nft == address(this)) revert Cannibalism();

        unchecked {
            // Increment the # of copies gobbled by the mech. Unchecked is
            // safe, as an NFT can't have more than type(uint256).max copies.
            ++getCopiesOfArmsBondedToMech[mechId][nft][id];
        }

        emit ArmsBonded(msg.sender, mechId, nft, id);

        isERC1155
            ? ERC1155(nft).safeTransferFrom(msg.sender, address(this), id, 1, "")
            : ERC721(nft).transferFrom(msg.sender, address(this), id);
    }

    /*//////////////////////////////////////////////////////////////
                                SHIRAK LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate a user's virtual shirak balance.
    /// @param user The user to query balance for.
    function shirakBalance(address user) public view returns (uint256) {
        // Compute the user's virtual shirak balance using LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].lastBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    /// @notice Add shirak to your emission balance,
    /// burning the corresponding ERC20 balance.
    /// @param shirakAmount The amount of shirak to add.
    function addShirak(uint256 shirakAmount) external {
        // Burn shirak being added to mech.
        shirak.burnForMechs(msg.sender, shirakAmount);

        // Increase msg.sender's virtual shirak balance.
        updateUserShirakBalance(msg.sender, shirakAmount, ShirakBalanceUpdateType.INCREASE);
    }

    /// @notice Remove shirak from your emission balance, and
    /// add the corresponding amount to your ERC20 balance.
    /// @param shirakAmount The amount of shirak to remove.
    function removeShirak(uint256 shirakAmount) external {
        // Decrease msg.sender's virtual shirak balance.
        updateUserShirakBalance(msg.sender, shirakAmount, ShirakBalanceUpdateType.DECREASE);

        // Mint the corresponding amount of ERC20 shirak.
        shirak.mintForMechs(msg.sender, shirakAmount);
    }

    /// @notice Burn an amount of a user's virtual shirak balance. Only callable
    /// by the Arms contract to enable purchasing arms with virtual balance.
    /// @param user The user whose virtual shirak balance we should burn from.
    /// @param shirakAmount The amount of shirak to burn from the user's virtual balance.
    function burnShirakForArms(address user, uint256 shirakAmount) external {
        // The caller must be the Arms contract, revert otherwise.
        if (msg.sender != address(arms)) revert UnauthorizedCaller(msg.sender);

        // Burn the requested amount of shirak from the user's virtual shirak balance.
        // Will revert if the user doesn't have enough shirak in their virtual balance.
        updateUserShirakBalance(user, shirakAmount, ShirakBalanceUpdateType.DECREASE);
    }

    /// @dev An enum for representing whether to
    /// increase or decrease a user's shirak balance.
    enum ShirakBalanceUpdateType {
        INCREASE,
        DECREASE
    }

    /// @notice Update a user's virtual shirak balance.
    /// @param user The user whose virtual shirak balance we should update.
    /// @param shirakAmount The amount of shirak to update the user's virtual balance by.
    /// @param updateType Whether to increase or decrease the user's balance by shirakAmount.
    function updateUserShirakBalance(
        address user,
        uint256 shirakAmount,
        ShirakBalanceUpdateType updateType
    ) internal {
        // Will revert due to underflow if we're decreasing by more than the user's current balance.
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = updateType == ShirakBalanceUpdateType.INCREASE
            ? shirakBalance(user) + shirakAmount
            : shirakBalance(user) - shirakAmount;

        // Snapshot the user's new shirak balance with the current timestamp.
        getUserData[user].lastBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint64(block.timestamp);

        emit ShirakBalanceUpdated(user, updatedBalance);
    }

    /*//////////////////////////////////////////////////////////////
                     RESERVED MECHS MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a number of mechs to the reserves.
    /// @param numMechsEach The number of mechs to mint to each reserve.
    /// @dev Mechs minted to reserves cannot comprise more than reserved supply.
    function mintReservedMechs(uint256 numMechsEach) external returns (uint256 lastMintedMechId) {
        unchecked {
            // Optimistically increment numMintedForReserves, may be reverted below.
            // Overflow in this calculation is possible but numMechsEach would have to
            // be so large that it would cause the loop in _batchMint to run out of gas quickly.
            uint256 newNumMintedForReserves = numMintedForReserves += (numMechsEach);

            // Ensure that after this mint mechs minted to reserves won't comprise more then the 
            // calculated reserve supply.
            if (newNumMintedForReserves > RESERVED_SUPPLY) revert ReserveImbalance();
        }

        // Mint numMechsEach mechs to the team for auction.
        lastMintedMechId = _batchMint(team, numMechsEach, currentNonLegendaryId);

        currentNonLegendaryId = uint128(lastMintedMechId); // Set currentNonLegendaryId.

        emit ReservedMechsMinted(msg.sender, lastMintedMechId, numMechsEach);
    }

    /*//////////////////////////////////////////////////////////////
                          CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Convenience function to get emissionMultiple for a mech.
    /// @param mechId The mech to get emissionMultiple for.
    function getMechEmissionMultiple(uint256 mechId) external view returns (uint256) {
        return getMechData[mechId].emissionMultiple;
    }

    /// @notice Convenience function to get emissionMultiple for a user.
    /// @param user The user to get emissionMultiple for.
    function getUserEmissionMultiple(address user) external view returns (uint256) {
        return getUserData[user].emissionMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                              ENUMERABLE SIMULATION
    //////////////////////////////////////////////////////////////*/

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            address ownership;
            uint256 tokenIdsLength = getUserData[owner].mechsOwned;
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 1; tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = getMechData[i].owner;
                if (ownership == address(0)) {
                    continue;
                }
                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < getUserData[owner].mechsOwned, "ERC721Enumerable: owner index out of bounds");
        return tokensOfOwner(owner)[index];
    }

    /*//////////////////////////////////////////////////////////////
                              STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

    function setNoTransferStaking (bool _bool) external onlyOwner {
        noTransferStaking = _bool;
    }

    function setStakeLocker (address _stakeLocker) external onlyOwner {
        stakeLocker = _stakeLocker;
    }

    function setMechStaked (uint256 _id, bool _staked) external {
        require(msg.sender == stakeLocker, "not authorized" );
        MechStaked storage mech = mechStaked[_id];
        mech.isStaked  = _staked;
    }

    /*//////////////////////////////////////////////////////////////
                              LEGENDARY LOCK LOGIC
    //////////////////////////////////////////////////////////////*/

    function setLegLock (bool _bool) external onlyOwner {
        legLock = _bool;
    }

    function setLegMinter (address _legMinter) external onlyOwner {
        legMinter = _legMinter;
    }

   
    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        if (noTransferStaking == true) {
            require (mechStaked[id].isStaked == false, "Token is staked");
        }

        require(from == getMechData[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        delete getApproved[id];

        getMechData[id].owner = to;

        unchecked {
            uint32 emissionMultiple = getMechData[id].emissionMultiple; // Caching saves gas.

            // We update their last balance before updating their emission multiple to avoid
            // penalizing them by retroactively applying their new (lower) emission multiple.
            getUserData[from].lastBalance = uint128(shirakBalance(from));
            getUserData[from].lastTimestamp = uint64(block.timestamp);
            getUserData[from].emissionMultiple -= emissionMultiple;
            getUserData[from].mechsOwned -= 1;

            // We update their last balance before updating their emission multiple to avoid
            // overpaying them by retroactively applying their new (higher) emission multiple.
            getUserData[to].lastBalance = uint128(shirakBalance(to));
            getUserData[to].lastTimestamp = uint64(block.timestamp);
            getUserData[to].emissionMultiple += emissionMultiple;
            getUserData[to].mechsOwned += 1;
        }

        emit Transfer(from, to, id);
    }
}

pragma solidity ^0.8.13;

interface MintERC721 {
   function mint(address, uint256) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";



/// @title Shirak Token (SHK)
/// @notice Forked by 0xBoots
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Shirak is the in-game token for ArtMechs. It's a standard ERC20
/// token that can be burned and minted by the mechs and arms contract.
contract Shirak is ERC20("Shirak", "SHK", 18) {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Art Mechs contract.
    address public immutable mechAvax;

    /// @notice The address of the Arms contract.
    address public immutable arms;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the addresses of relevant contracts.
    /// @param _mechAvax Address of the ArtMechs contract.
    /// @param _arms Address of the Arms contract.
    constructor(address _mechAvax, address _arms) {
        mechAvax = _mechAvax;
        arms = _arms;
    }

    /*//////////////////////////////////////////////////////////////
                             MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /// @notice Mint any amount of shirak to a user. Can only be called by ArtMechs.
    /// @param to The address of the user to mint shirak to.
    /// @param amount The amount of shirak to mint.
    function mintForMechs(address to, uint256 amount) external only(mechAvax) {
        _mint(to, amount);
    }

    /// @notice Burn any amount of shirak from a user. Can only be called by ArtMechs.
    /// @param from The address of the user to burn shirak from.
    /// @param amount The amount of shirak to burn.
    function burnForMechs(address from, uint256 amount) external only(mechAvax) {
        _burn(from, amount);
    }

    /// @notice Burn any amount of shirak from a user. Can only be called by Arms.
    /// @param from The address of the user to burn shirak from.
    /// @param amount The amount of shirak to burn.
    function burnForArms(address from, uint256 amount) external only(arms) {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Randomness Provider Interface.
/// @author FrankieIsLost <[email protected]>
/// @author transmissions11 <[email protected]>
/// @notice Generic asynchronous randomness provider interface.
interface RandProvider {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RandomBytesRequested(bytes32 requestId);
    event RandomBytesReturned(bytes32 requestId, uint256 randomness);

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Request random bytes from the randomness provider.
    function requestRandomBytes() external returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {MechAvax} from "../../MechAvax.sol";


/// @notice ERC721 implementation optimized for Arms by pre-approving them to the MechAvax contract.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ArmsERC721 is ERC2981{
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);


    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    MechAvax public immutable mechAvax;

    constructor(
        MechAvax _mechAvax,
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;
        mechAvax = _mechAvax;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) internal _isApprovedForAll;

    function isApprovedForAll(address owner, address operator) public view returns (bool isApproved) {
        if (operator == address(mechAvax)) return true; // Skip approvals for the MechAvax contract.

        return _isApprovedForAll[owner][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll(from, msg.sender) || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override(ERC2981) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for 
            super.supportsInterface(interfaceId); //ERC2981 support
           
            
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        // Does not check the token has not been already minted
        // or is being minted to address(0) because ids in Arms.sol
        // are set using a monotonically increasing counter and only
        // minted to safe addresses or msg.sender who cannot be zero.

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _batchMint(
        address to,
        uint256 amount,
        uint256 lastMintedId
    ) internal returns (uint256) {
        // Doesn't check if the tokens were already minted or the recipient is address(0)
        // because Arms.sol manages its ids in a way that it ensures it won't double
        // mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            _balanceOf[to] += amount;

            for (uint256 i = 0; i < amount; ++i) {
                _ownerOf[++lastMintedId] = to;

                emit Transfer(address(0), to, lastMintedId);
            }
        }

        return lastMintedId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/// @notice ERC721 implementation optimized for MechAvax by packing balanceOf/ownerOf with user/attribute data.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract MechsERC721 is ERC2981{
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                         GOBBLERS/ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding mech data.
    struct MechData {
        // The current owner of the mech.
        address owner;
        // Index of token after shuffle.
        uint64 idx;
        // Multiple on shirak issuance.
        uint32 emissionMultiple;
    }

    /// @notice Maps mech ids to their data.
    mapping(uint256 => MechData) public getMechData;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of mechs currently owned by the user.
        uint32 mechsOwned;
        // The sum of the multiples of all mechs the user holds.
        uint32 emissionMultiple;
        // User's shirak balance at time of last checkpointing.
        uint128 lastBalance;
        // Timestamp of the last shirak balance checkpoint.
        uint64 lastTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = getMechData[id].owner) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return getUserData[owner].mechsOwned;
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external {
        address owner = getMechData[id].owner;

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }


    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override(ERC2981) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f ||  // ERC165 Interface ID for ERC721Metadata
            super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        // Does not check if the token was already minted or the recipient is address(0)
        // because MechAvax.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            ++getUserData[to].mechsOwned;
        }

        getMechData[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _batchMint(
        address to,
        uint256 amount,
        uint256 lastMintedId
    ) internal returns (uint256) {
        // Doesn't check if the tokens were already minted or the recipient is address(0)
        // because MechAvax.sol manages its ids in such a way that it ensures it won't
        // double mint and will only mint to safe addresses or msg.sender who cannot be zero.

        unchecked {
            getUserData[to].mechsOwned += uint32(amount);

            for (uint256 i = 0; i < amount; ++i) {
                getMechData[++lastMintedId].owner = to;

                emit Transfer(address(0), to, lastMintedId);
            }
        }

        return lastMintedId;
    }
}