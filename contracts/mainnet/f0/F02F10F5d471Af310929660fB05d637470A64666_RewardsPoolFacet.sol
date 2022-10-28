// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IRewardsPool.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";
import "../libraries/LRewards.sol";

/// @title RewardsPoolFacet
/// @author mektigboy
/// @notice Facet in charge of features related to the Rewards Pool
/// @dev Utilizes 'IERC20', 'IRewardsPool', 'AppStorage', 'LAuthorizable' and 'LRewards'
contract RewardsPoolFacet {
    error RewardsPoolFacet__NotEnoughBalance();
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Daily update transaction
    /// @dev This function should be automatically triggered
    function dailyUpdate() external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        s.txCounter = IRewardsPool(s.rewardsPool).txCounter();
        s.balances[s.txCounter] = IERC20(s.vpnd).balanceOf(address(this));
        s.dailyReceptions[s.txCounter] = IRewardsPool(s.rewardsPool).dailyEmission();

        LRewards.updateRewards(s);
    }

    /// @notice Get transaction counter
    function totalTransactions() external view returns (uint256) {
        return s.txCounter;
    }

    /// @notice Get balances by transaction ID
    /// @param _id Transaction ID
    function balances(uint256 _id) external view returns (uint256) {
        return s.balances[_id];
    }

    /// @notice Get daily receptions by transaction ID
    /// @param _id Transaction ID
    function dailyReceptions(uint256 _id) external view returns (uint256) {
        return s.dailyReceptions[_id];
    }

    /// @notice Get accPerShare updates by transaction ID
    /// @param _id Transaction ID
    function accPerShareUpdates(uint256 _id) external view returns (uint256) {
        return s.accPerShareUpdates[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
interface IERC20 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /////////////
    /// LOGIC ///
    /////////////

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

////////////
/// NODE ///
////////////

struct Node {
    string name;
    ///
    uint256 creation;
    uint256 lastClaimTime;
    ///
    uint256 amount;
    uint256 rewardPaid;
    ///
    bool active;
    ///
    uint256 lastRewardUpdate;
}

///////////////
/// ROYALTY ///
///////////////

struct RoyaltyInfo {
    address recipient;
    uint256 bps;
}

////////////
/// MATH ///
////////////

enum Rounding {
    Down,
    Up,
    Zero
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    ////////////////////
    /// AUTHORIZABLE ///
    ////////////////////
    mapping(address => bool) authorized;
    ////////////////
    /// PAUSABLE ///
    ////////////////
    bool paused;
    ///////////////
    /// REWARDS ///
    ///////////////
    uint256 _accumulatedRewardPerShare; // DEPRECATED
    uint256 ACCUMULATED_REWARD_PER_SHARE_PRECISION;
    uint256 _lastRewardBalance; // DEPRECATED
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address wavax;
    address stratosphere;
    address rewardsPool;
    address nodeStorage;
    address treasury;
    address referralController;
    ///
    uint256 deployedAt;
    uint256 tvl;
    uint256 _balance; // DEPRECATED
    uint256 _dailyReception; // DEPRECATED
    uint256 txCounter;
    mapping(uint256 => uint256) balances;
    mapping(uint256 => uint256) dailyReceptions;
    /////////////
    /// NODES ///
    /////////////
    uint256 minNodeAmount;
    uint256 maxNodesPerWallet;
    mapping(uint256 => Node) nodeByTokenId;
    /////////////////
    /// MIGRATION ///
    /////////////////
    uint256 totalNodesCreated;
    uint256 totalNodesMigrated;
    mapping(address => bool) alreadyMigrated;
    /////////////
    /// TAXES ///
    /////////////
    uint256 claimFee;
    uint256 compoundFee;
    uint256 depositFee;
    uint256 quoteSlippagePct;
    address dexRouter;
    //////////////
    /// ERC721 ///
    //////////////
    string baseURI;
    string name;
    string symbol;
    bool isTransferable;
    mapping(address => uint256) tokenBalances;
    mapping(uint256 => address) tokenOwners;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    /////////////////////////
    /// ERC721 ENUMERABLE ///
    /////////////////////////
    mapping(address => mapping(uint256 => uint256)) ownedTokens;
    mapping(uint256 => uint256) ownedTokensIndex;
    uint256[] allTokens;
    mapping(uint256 => uint256) allTokensIndex;
    /////////////////
    /// ROYALTIES ///
    /////////////////
    address royaltyRecipient;
    uint16 royaltyBps;
    mapping(uint256 => RoyaltyInfo) royaltyInfoForToken;
    //////////////////////
    /// REWARDS UPDATE ///
    //////////////////////
    mapping(uint256 => uint256) accPerShareUpdates;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LAuthorizable__OnlyAuthorized();

/// @title LAuthorizable
/// @author mektigboy
library LAuthorizable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce only authorized address can call a certain function
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(AppStorage storage s, address _address) internal view {
        if (!s.authorized[_address]) revert LAuthorizable__OnlyAuthorized();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LERC721.sol";

error LRewards__DailyReceptionMismatch();
error LRewards__InvalidNode();
error LRewards__TotalValueLockedIsZero();

/// @title LRewards
/// @author mejiasd3v, mektigboy
library LRewards {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Update rewards
    /// @param s AppStorage
    function updateRewards(AppStorage storage s) internal {
        if (s.tvl == 0) revert LRewards__TotalValueLockedIsZero();

        uint256 txCounter = s.txCounter; // gas optimization

        s.accPerShareUpdates[txCounter] =
            (s.dailyReceptions[txCounter] * s.ACCUMULATED_REWARD_PER_SHARE_PRECISION) /
            s.tvl;
    }

    /// @notice View function that returns pending rewards
    /// @param s AppStorage
    /// @param _node Node
    /// @return Pending rewards
    function pendingRewards(AppStorage storage s, Node memory _node) internal view returns (uint256) {
        uint256 daysSinceLastClaim = (s.txCounter - _node.lastRewardUpdate);

        if (daysSinceLastClaim == 0) return 0;

        uint256 nodeAmount = _node.amount; // gas optimization
        uint256 rewardPaid = _node.rewardPaid; // gas optimization
        uint256 accPrecision = s.ACCUMULATED_REWARD_PER_SHARE_PRECISION; // gas optimization

        uint256 pending;

        // ie: daysSinceLastClaim = 3
        // Run 1: i = 3, s.rewardsDailyUpdates[3]
        // Run 2: i = 2, s.rewardsDailyUpdates[2]
        // Run 3: i = 1, s.rewardsDailyUpdates[1]
        for (uint256 i = daysSinceLastClaim; i > 0; i--) {
            pending += ((nodeAmount * s.accPerShareUpdates[i]) / accPrecision) - rewardPaid;
        }

        return pending;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IRewardsPool
/// @author mektigboy
interface IRewardsPool {
    //////////////
    /// EVENTS ///
    //////////////

    event DailyTransfer();

    /////////////
    /// LOGIC ///
    /////////////

    function dailyEmission() external view returns (uint256);

    function txCounter() external view returns (uint256);

    function updateVaporNodes(address vaporNodes) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AppStorage.sol";
import "./LStrings.sol";
import "../interfaces/IERC721Receiver.sol";

error LERC721__AlreadyMintedToken();
error LERC721__InvalidAddress();
error LERC721__InvalidApproveToCaller();
error LERC721__InvalidMintToAddressZero();
error LERC721__InvalidToken();
error LERC721__InvalidTransferToAddressZero();
error LERC721__OnlyOwnerOrApproved();
error LERC721__SenderIsNotOwner();
error LERC721__TranferToNonERC721Receiver();
error LERC721__UnsupportedConsecutiveTransfers();

/// @title LERC721
/// @author mektigboy
/// @notice ERC721 library
/// @dev Internal use
library LERC721 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get token owner
    /// @param s AppStorage
    /// @param _id Token ID
    function ownerOf(AppStorage storage s, uint256 _id) internal view returns (address) {
        address owner = s.tokenOwners[_id];

        // if (owner == address(0)) revert LERC721__InvalidToken();

        return owner;
    }

    /// @notice Get token balance
    /// @param s AppStorage
    /// @param _account User account
    function balanceOf(AppStorage storage s, address _account) internal view returns (uint256) {
        if (_account == address(0)) revert LERC721__InvalidAddress();

        return s.tokenBalances[_account];
    }

    function tokenURI(AppStorage storage s, uint256 tokenId) internal view returns (string memory) {
        if (!exists(s, tokenId)) revert LERC721__InvalidToken();
        string memory baseURI = s.baseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, LStrings.toString(tokenId))) : "";
    }

    function updateBaseURI(AppStorage storage s, string memory _baseURI) internal {
        s.baseURI = _baseURI;
    }

    /// @notice Hook called before any token transfer
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function beforeTokenTransfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id
    ) internal {
        if (_from == address(0)) {
            addTokenToAllTokensEnumeration(s, _id);
        } else if (_from != _to) {
            removeTokenFromOwnerEnumeration(s, _from, _id);
        }
        if (_to == address(0)) {
            removeTokenFromAllTokensEnumeration(s, _id);
        } else if (_to != _from) {
            addTokenToOwnerEnumeration(s, _to, _id);
        }
    }

    /// @notice Hook called before any consecutive token transfer
    /// @param _size Size
    function beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96 _size
    ) internal pure {
        if (_size > 0) revert LERC721__UnsupportedConsecutiveTransfers();
    }

    /// @notice Add token to owner enumeration
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function addTokenToOwnerEnumeration(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        uint256 length = balanceOf(s, _to);

        s.ownedTokens[_to][length] = _id;
        s.ownedTokensIndex[_id] = length;
    }

    /// @notice Add token to all tokens enumeration
    /// @param s AppStorage
    /// @param _id Token ID
    function addTokenToAllTokensEnumeration(AppStorage storage s, uint256 _id) internal {
        s.allTokensIndex[_id] = s.allTokens.length;

        s.allTokens.push(_id);
    }

    /// @notice Remove token from owner enumeration
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _id Token ID
    function removeTokenFromOwnerEnumeration(
        AppStorage storage s,
        address _from,
        uint256 _id
    ) internal {
        uint256 lastTokenIndex = balanceOf(s, _from) - 1;
        uint256 tokenIndex = s.ownedTokensIndex[_id];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s.ownedTokens[_from][lastTokenIndex];

            s.ownedTokens[_from][tokenIndex] = lastTokenId;
            s.ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete s.ownedTokensIndex[_id];
        delete s.ownedTokens[_from][lastTokenIndex];
    }

    /// @notice Remove token from all tokens enumeration
    /// @param s AppStorage
    /// @param _id Token ID
    function removeTokenFromAllTokensEnumeration(AppStorage storage s, uint256 _id) private {
        uint256 lastTokenIndex = s.allTokens.length - 1;
        uint256 tokenIndex = s.allTokensIndex[_id];

        uint256 lastTokenId = s.allTokens[lastTokenIndex];

        s.allTokens[tokenIndex] = lastTokenId;
        s.allTokensIndex[lastTokenId] = tokenIndex;

        delete s.allTokensIndex[_id];

        s.allTokens.pop();
    }

    /// @notice Transfer token in a safe manner
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function safeTransfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) internal {
        transfer(s, _from, _to, _id);

        if (!checkOnERC721Received(_from, _to, _id, _data)) revert LERC721__TranferToNonERC721Receiver();
    }

    /// @notice Get if token exists
    /// @param s AppStorage s
    /// @param _id Token ID
    function exists(AppStorage storage s, uint256 _id) internal view returns (bool) {
        return ownerOf(s, _id) != address(0);
    }

    /// @notice Check if it is approved or owner
    /// @param _spender Token spender
    /// @param _id Token ID
    function isApprovedOrOwner(
        AppStorage storage s,
        address _spender,
        uint256 _id
    ) internal view returns (bool) {
        address owner = ownerOf(s, _id);

        return (_spender == owner || isApprovedForAll(s, owner, _spender) || getApproved(s, _id) == _spender);
    }

    /// @notice Mint token in a safe manner without data
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function safeMint(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        safeMint(s, _to, _id, "");
    }

    /// @notice Mint token in a safe manner with data
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function safeMint(
        AppStorage storage s,
        address _to,
        uint256 _id,
        bytes memory _data
    ) internal {
        mint(s, _to, _id);

        if (!checkOnERC721Received(address(0), _to, _id, _data)) revert LERC721__TranferToNonERC721Receiver();
    }

    /// @notice Mint token
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function mint(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        if (_to == address(0)) revert LERC721__InvalidMintToAddressZero();

        if (exists(s, _id)) revert LERC721__AlreadyMintedToken();

        beforeTokenTransfer(s, address(0), _to, _id);

        if (exists(s, _id)) revert LERC721__AlreadyMintedToken();

        s.tokenBalances[_to] += 1;
        s.tokenOwners[_id] = _to;

        emit Transfer(address(0), _to, _id);

        afterTokenTransfer(address(0), _to, _id);
    }

    /// @notice Burn token
    /// @param s AppStorage
    /// @param _id Token ID
    function burn(AppStorage storage s, uint256 _id) internal {
        address owner = ownerOf(s, _id);

        beforeTokenTransfer(s, owner, address(0), _id);

        owner = ownerOf(s, _id);

        delete s.tokenApprovals[_id];

        s.tokenBalances[owner] -= 1;

        delete s.tokenOwners[_id];

        emit Transfer(owner, address(0), _id);

        afterTokenTransfer(owner, address(0), _id);
    }

    /// @notice Transfer token
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function transfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id
    ) internal {
        if (_from != ownerOf(s, _id)) revert LERC721__SenderIsNotOwner();

        if (_to == address(0)) revert LERC721__InvalidTransferToAddressZero();

        beforeTokenTransfer(s, _from, _to, _id);

        if (_from != ownerOf(s, _id)) revert LERC721__SenderIsNotOwner();

        delete s.tokenApprovals[_id];

        s.tokenBalances[_from] -= 1;
        s.tokenBalances[_to] += 1;
        s.tokenOwners[_id] = _to;

        emit Transfer(_from, _to, _id);

        afterTokenTransfer(_from, _to, _id);
    }

    /// @notice Approve token
    /// @param s AppStorage
    /// @param _to Spender
    /// @param _id Token ID
    function approve(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        s.tokenApprovals[_id] = _to;

        emit Approval(ownerOf(s, _id), _to, _id);
    }

    /// @notice Get account from token ID
    /// @param s AppStorage
    /// @param _id Token ID
    function getApproved(AppStorage storage s, uint256 _id) internal view returns (address) {
        return s.tokenApprovals[_id];
    }

    /// @notice Set approval for all
    /// @param s AppStorage
    /// @param _account User account
    /// @param _operator Token operator
    /// @param _approved Approved value
    function setApprovalForAll(
        AppStorage storage s,
        address _account,
        address _operator,
        bool _approved
    ) internal {
        if (_account == _operator) revert LERC721__InvalidApproveToCaller();

        s.operatorApprovals[_account][_operator] = _approved;

        emit ApprovalForAll(_account, _operator, _approved);
    }

    /// @notice Get is approved for all
    /// @param s AppStorage
    /// @param _account User account
    /// @param _operator Token operator
    function isApprovedForAll(
        AppStorage storage s,
        address _account,
        address _operator
    ) internal view returns (bool) {
        return s.operatorApprovals[_account][_operator];
    }

    /// @notice Require that token is minted
    /// @param s AppStorage
    /// @param _id Token ID
    function requireMinted(AppStorage storage s, uint256 _id) internal view {
        if (!exists(s, _id)) revert LERC721__InvalidToken();
    }

    /// @notice Hook called after any token transfer
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function afterTokenTransfer(
        address _from,
        address _to,
        uint256 _id
    ) internal {}

    /// @notice Hook called before any consecutive token transfer
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _size Size
    function beforeConsecutiveTokenTransfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256,
        uint96 _size
    ) internal {
        if (_from != address(0)) s.tokenBalances[_from] -= _size;

        if (_to != address(0)) s.tokenBalances[_to] += _size;
    }

    /// @notice Hook called after any consecutive token transfer
    function afterConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96
    ) internal {}

    /// @notice Check on ERC721 Received
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function checkOnERC721Received(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) internal returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _id, _data) returns (bytes4 returnValue) {
                return returnValue == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert LERC721__TranferToNonERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./LMath.sol";

error LStrings__InsufficientHexLength();

/// @title LStrings
/// @author mejiasd3v, mektigboy
library LStrings {
    bytes16 private constant SYMBOLS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /// @notice Convert a 'uint256' to its ASCII 'string' decimal representation
    /// @param _value Value
    function toString(uint256 _value) internal pure returns (string memory) {
        uint256 length = LMath.log10(_value) + 1;
        string memory buffer = new string(length);
        uint256 ptr;

        assembly {
            ptr := add(buffer, add(32, length))
        }

        while (true) {
            ptr--;

            assembly {
                mstore8(ptr, byte(mod(_value, 10), SYMBOLS))
            }

            _value /= 10;

            if (_value == 0) break;
        }
        return buffer;
    }

    /// @notice Convert a 'uint256' to its ASCII 'string' hexadecimal representation
    function toHexString(uint256 _value) internal pure returns (string memory) {
        return toHexString(_value, LMath.log256(_value) + 1);
    }

    /// @notice Convert a 'uint256' to its ASCII 'string' hexadecimal representation with fixed length
    function toHexString(uint256 _value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);

        buffer[0] = "0";
        buffer[1] = "x";

        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = SYMBOLS[_value & 0xf];
            _value >>= 4;
        }

        if (_value != 0) revert LStrings__InsufficientHexLength();

        return string(buffer);
    }

    /// @notice Convert an 'address' with fixed length of 20 bytes to its not checksummed ASCII 'string' hexadecimal representation
    function toHexString(address _address) internal pure returns (string memory) {
        return toHexString(uint256(uint160(_address)), ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC721Receiver
/// @author mektigboy
interface IERC721Receiver {
    /////////////
    /// LOGIC ///
    /////////////

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AppStorage.sol";

/// @title LMath
/// @author mejiasd3v, mektigboy
library LMath {
    /////////////
    /// LOGIC ///
    /////////////

    ///@notice Return the biggest of two numbers
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _a : _b;
    }

    /// @notice Return the smallest of two numbers
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    /// @notice Return the average of two numbers. The result is roundend towards zero
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function average(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a & _b) + (_a ^ _b) / 2;
    }

    /// @notice Return the ceiling of the division of two numbers
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function ceilDiv(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a == 0 ? 0 : (_a - 1) / _b + 1;
    }

    /// @notice Calculate floor(_x * _y / _denominator) with full precision
    /// @param _x Value 'x'
    /// @param _y Value 'y'
    /// @param _denominator Denominator
    function mulDiv(
        uint256 _x,
        uint256 _y,
        uint256 _denominator
    ) internal pure returns (uint256 result_) {
        uint256 prod0;
        uint256 prod1;

        assembly {
            let mm := mulmod(_x, _y, not(0))

            prod0 := mul(_x, _y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            return prod0 / _denominator;
        }

        require(_denominator > prod1);

        uint256 remainder;

        assembly {
            remainder := mulmod(_x, _y, _denominator)
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = _denominator & (~_denominator + 1);

        assembly {
            _denominator := div(_denominator, twos)
            prod0 := div(prod0, twos)
            twos := add(div(sub(0, twos), twos), 1)
        }

        prod0 |= prod1 * twos;

        uint256 inverse = (3 * _denominator) ^ 2;

        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;

        result_ = prod0 * inverse;

        return result_;
    }

    /// @notice Calculate x * y / denominator with full precision
    /// @param _x Value 'x'
    /// @param _y Value 'y'
    /// @param _denominator Denominator
    /// @param _rounding Rounding
    function mulDiv(
        uint256 _x,
        uint256 _y,
        uint256 _denominator,
        Rounding _rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(_x, _y, _denominator);

        if (_rounding == Rounding.Up && mulmod(_x, _y, _denominator) > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the square root of a number
    /// @param _a Value 'a'

    function sqrt(uint256 _a) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 result = 1 << (log2(_a) >> 1);

        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;

        return min(result, _a / result);
    }

    /// @notice Calculate sqrt(a), following the selected rounding direction
    /// @param _a Value 'a'
    /// @param _rounding Rounding
    function sqrt(uint256 _a, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = sqrt(_a);

        return result + (_rounding == Rounding.Up && result * result < _a ? 1 : 0);
    }

    /// @notice Return the log in base 2, rounded down, of a positive value
    /// @param _value Value
    function log2(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;

        if (_value >> 128 > 0) {
            _value >>= 128;
            result += 128;
        }
        if (_value >> 64 > 0) {
            _value >>= 64;
            result += 64;
        }
        if (_value >> 32 > 0) {
            _value >>= 32;
            result += 32;
        }
        if (_value >> 16 > 0) {
            _value >>= 16;
            result += 16;
        }
        if (_value >> 8 > 0) {
            _value >>= 8;
            result += 8;
        }
        if (_value >> 4 > 0) {
            _value >>= 4;
            result += 4;
        }
        if (_value >> 2 > 0) {
            _value >>= 2;
            result += 2;
        }
        if (_value >> 1 > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 2, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log2(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log2(_value);

        return result + (_rounding == Rounding.Up && 1 << result < _value ? 1 : 0);
    }

    /// @notice Return the log in base 10, rounded down, of a positive value
    /// @param _value Value
    function log10(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;

        if (_value >= 10**64) {
            _value /= 10**64;
            result += 64;
        }
        if (_value >= 10**32) {
            _value /= 10**32;
            result += 32;
        }
        if (_value >= 10**16) {
            _value /= 10**16;
            result += 16;
        }
        if (_value >= 10**8) {
            _value /= 10**8;
            result += 8;
        }
        if (_value >= 10**4) {
            _value /= 10**4;
            result += 4;
        }
        if (_value >= 10**2) {
            _value /= 10**2;
            result += 2;
        }
        if (_value >= 10**1) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 10, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log10(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log10(_value);

        return result + (_rounding == Rounding.Up && 10**result < _value ? 1 : 0);
    }

    /// @notice Return the log in base 256, rounded down, of a positive value
    /// @param _value Value
    function log256(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;

        if (_value >> 128 > 0) {
            _value >>= 128;
            result += 16;
        }
        if (_value >> 64 > 0) {
            _value >>= 64;
            result += 8;
        }
        if (_value >> 32 > 0) {
            _value >>= 32;
            result += 4;
        }
        if (_value >> 16 > 0) {
            _value >>= 16;
            result += 2;
        }
        if (_value >> 8 > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 10, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log256(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log256(_value);

        return result + (_rounding == Rounding.Up && 1 << (result << 3) < _value ? 1 : 0);
    }
}