// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";
import "../libraries/LERC721.sol";
import "../libraries/LPausable.sol";
import "../libraries/LRewards.sol";

error NodeManagementFacet__InactiveNode();
error NodeManagementFacet__InvalidAccount();
error NodeManagementFacet__InvalidDepositFee();
error NodeManagementFacet__UnregistredNode();

/// @title NodeManagementFacet
/// @author mektigboy
/// @notice Facet in charge of ...
contract NodeManagementFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    //////////////
    /// EVENTS ///
    //////////////

    event NodeClaimed();

    event NodeCompounded();

    event NodeCreated(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );

    event NodeIncreased(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );

    event NodeMerged(
        address indexed account,
        uint256 sourceTimestamp,
        uint256 destinationTimestamp
    );

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Create node
    /// @param _account User account
    /// @param _name New node name
    /// @param _amount New node amount
    function create(
        address _account,
        string memory _name,
        uint256 _amount
    ) external {
        // LAuthorizable.enforceIsAuthorized(s, msg.sender);
        // LPausable.enforceIsUnpaused(s);

        if (_account == address(0))
            revert NodeManagementFacet__InvalidAccount();

        // if (_amount < IERC20(s.vpnd).balanceOf(_account)) revert Error();

        Node memory node;

        node.name = _name;
        node.creation = block.timestamp;
        node.lastClaim = block.timestamp;
        node.lastCompound = block.timestamp;
        node.amount = _amount;
        node.active = true;

        s.usersNodes[_account].push(node);

        s.tvl += node.amount;

        ++s.tokenCounter;
        ++s.activeNodes;

        s.nodeByTokenId[s.tokenCounter] = node;

        LERC721.safeMint(s, _account, s.tokenCounter);

        emit NodeCreated(_account, _amount, node.creation);
    }

    /// @notice Compound node
    /// @param _account User account
    /// @param _id Node ID
    /// @param _fee Deposit fee
    function compound(
        address _account,
        uint256 _id,
        uint256 _fee
    ) external returns (uint256) {
        // LAuthorizable.enforceIsAuthorized(s, msg.sender);
        // LPausable.enforceIsUnpaused(s);

        if (_account == address(0))
            revert NodeManagementFacet__InvalidAccount();

        if (_fee == 0) revert NodeManagementFacet__InvalidDepositFee();

        Node storage node = s.usersNodes[_account][_id];

        if (node.amount == 0) revert NodeManagementFacet__UnregistredNode();

        uint256 amountMinusFee = node.amount - _fee;
        uint256 previousAmount = node.amount;

        node.amount += amountMinusFee;

        uint256 previousRewardDebt = node.rewardDebt;

        // CHECK MATH
        node.rewardDebt = (node.amount * s.accumulatedRewardPerShare) / 1e24;

        if (previousAmount != 0) {
            // CHECK MATH
            uint256 pending = (previousAmount * s.accumulatedRewardPerShare) /
                1e24 -
                previousRewardDebt;

            if (pending != 0) {
                LRewards.transfer(msg.sender, pending);
            }
        }

        node.lastCompound = block.timestamp;

        s.balance += amountMinusFee;

        IERC20(s.vpnd).transferFrom(msg.sender, s.rewardsPool, _fee);
        IERC20(s.vpnd).transferFrom(msg.sender, address(this), amountMinusFee);

        emit NodeCompounded();
    }

    /// @notice Claim node
    /// @param _account User account
    /// @param _id Node ID
    function claim(address _account, uint256 _id) external {
        // LAuthorizable.enforceIsAuthorized(s, msg.sender);
        // LPausable.enforceIsUnpaused(s);

        if (_account == address(0))
            revert NodeManagementFacet__InvalidAccount();

        Node storage node = s.usersNodes[_account][_id];

        if (node.amount == 0) revert NodeManagementFacet__UnregistredNode();

        uint256 previousAmount = node.amount;

        node.amount -= node.amount;

        if (previousAmount != 0) {
            uint256 pending = (previousAmount * s.accumulatedRewardPerShare) /
                1e24 -
                node.rewardDebt;

            node.rewardDebt = (node.amount * s.accumulatedRewardPerShare) / 1e24;

            if (pending != 0) {
                LRewards.transfer(msg.sender, pending);
            }
        }

        node.lastClaim = block.timestamp;
        node.lastCompound = block.timestamp;

        s.balance - node.amount;

        IERC20(s.vpnd).transfer(msg.sender, node.amount);

        emit NodeClaimed();
    }

    /// @notice Rename node
    /// @param _account User account
    /// @param _id Node ID
    /// @param _name New node name
    function rename(
        address _account,
        uint256 _id,
        string memory _name
    ) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.usersNodes[_account][_id];

        node.name = _name;
    }

    /// @notice ...
    /// @param _account User account
    /// @param _id Node ID
    /// @param _amount New node amount
    function increase(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.usersNodes[_account][_id];

        if (node.amount == 0) revert NodeManagementFacet__UnregistredNode();

        // (, , uint256 rewards) = LRewards.updateRewards(
        //     s,
        //     node.lastClaim,
        //     node.lastCompound,
        //     node.amount
        // );

        // node.amount += (_amount + rewards);
        node.lastCompound = block.timestamp;
    }

    /// @notice ...
    /// @param _account User account
    /// @param _id Node ID
    function reactivate(address _account, uint256 _id) external {
        LAuthorizable.enforceIsAuthorized(s, msg.sender);

        Node storage node = s.usersNodes[_account][_id];

        if (!node.active) revert NodeManagementFacet__InactiveNode();

        // node.clock = node.clock + 7776000; // 90 days
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

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    /////////////
    /// LOGIC ///
    /////////////

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    uint256 lastClaim;
    uint256 lastCompound;
    ///
    uint256 amount;
    uint256 rewardDebt;
    ///
    bool active;
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
    uint256 depositFee;
    uint256 accumulatedRewardPerShare;
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address rewardsPool;
    address nodeStorage;
    ///
    uint256 tvl;
    uint256 balance;
    uint256 dailyReception;
    uint256 dailySplit;
    mapping(uint256 => uint256) balances;
    mapping(uint256 => uint256) dailyReceptions;
    mapping(uint256 => uint256) dailySplits;
    uint256 transactionCounter;
    ///////////////////////
    /// NODE MANAGEMENT ///
    ///////////////////////
    mapping(address => Node[]) usersNodes;
    /////////////
    /// NODES ///
    /////////////
    uint256 activeNodes;
    mapping(address => bool) alreadyMigrated;
    mapping(uint256 => Node) nodeByTokenId;
    //////////////
    /// ERC721 ///
    //////////////
    string name;
    string symbol;
    uint256 tokenCounter;
    mapping(uint256 => address) ownerOf;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
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

    /// @notice ...
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(AppStorage storage s, address _address)
        internal
        view
    {
        if (!s.authorized[_address]) revert LAuthorizable__OnlyAuthorized();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AppStorage.sol";
import "./LPausable.sol";

error LERC721__AlreadyMinted();
error LERC721__InexistentAddress();
error LERC721__InexistentMint();
error LERC721__InexistentToken();
error LERC721__InvalidRecipient();
error LERC721__InvalidSender();
error LERC721__Unauthorized();
error LERC721__UnsafeAddress();

library LERC721 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    ///////////////
    /// STORAGE ///
    ///////////////

    bytes4 internal constant ON_ERC721_RECEIVED = 0x150b7a02;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Approve spending of token
    /// @param s AppStorage
    /// @param _spender User that will be allowed to spend the token
    /// @param _id Token ID
    function approve(
        AppStorage storage s,
        address _spender,
        uint256 _id
    ) internal {
        address owner = s.ownerOf[_id];

        if (owner != msg.sender) revert LERC721__Unauthorized();

        // if (!isApprovedForAll[owner][msg.sender]) revert LERC721__Unauthorized();

        s.getApproved[_id] = _spender;

        emit Approval(owner, _spender, _id);
    }

    /// @notice ...
    /// @param s AppStorage
    /// @param _operator Token operator
    /// @param _approved Is approved
    function setApprovalForAll(
        AppStorage storage s,
        address _operator,
        bool _approved
    ) internal {
        s.isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Transfer tokens from sender to recipient
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function transferFrom(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id
    ) internal {
        LPausable.enforceIsUnpaused(s);

        if (_from != s.ownerOf[_id]) revert LERC721__InvalidSender();

        if (_to == address(0)) revert LERC721__InvalidRecipient();

        if (_from != msg.sender) revert LERC721__Unauthorized();

        // if (!isApprovedForAll[_from][msg.sender])
        //     revert LERC721__Unauthorized();

        // if (s.getApproved[_id] != msg.sender)
        //     revert LERC721__Unauthorized();

        --s.balanceOf[_from];
        ++s.balanceOf[_to];

        s.ownerOf[_id] = _to;

        delete s.getApproved[_id];

        emit Transfer(_from, _to, _id);
    }

    /// @notice Transfer tokens from sender to recipient in a safe manner
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function safeTransferFrom(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id
    ) internal {
        transferFrom(s, _from, _to, _id);

        if (_to.code.length != 0) revert LERC721__UnsafeAddress();

        // if (
        //     ERC721TokenReceiver(_to).onERC721Received(
        //         msg.sender,
        //         _from,
        //         _id,
        //         ""
        //     ) != ERC721TokenReceiver.onERC721Received.selector
        // ) revert LERC721__UnsafeAddress();
    }

    /// @notice Transfer tokens from sender to recipient in a safe manner
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _calldata Data
    function safeTransferFrom(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id,
        bytes calldata _calldata
    ) internal {
        transferFrom(s, _from, _to, _id);

        if (_to.code.length != 0) revert LERC721__UnsafeAddress();

        // if (
        //     ERC721TokenReceiver(_to).onERC721Received(
        //         msg.sender,
        //         _from,
        //         _id,
        //         _calldata
        //     ) != ERC721TokenReceiver.onERC721Received.selector
        // ) revert LERC721__UnsafeAddress();
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
        if (_to == address(0)) revert LERC721__InvalidRecipient();

        if (s.ownerOf[_id] != address(0)) revert LERC721__AlreadyMinted();

        ++s.balanceOf[_to];

        s.ownerOf[_id] = _to;

        emit Transfer(address(0), _to, _id);
    }

    /// @notice Burn a token
    /// @param s AppStorage
    /// @param _id Token ID
    function burn(AppStorage storage s, uint256 _id) internal {
        address owner = s.ownerOf[_id];

        if (owner == address(0)) revert LERC721__InexistentMint();

        --s.balanceOf[owner];

        delete s.ownerOf[_id];

        delete s.getApproved[_id];

        emit Transfer(owner, address(0), _id);
    }

    /// @notice ...
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function safeMint(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        mint(s, _to, _id);

        if (_to.code.length != 0) revert LERC721__UnsafeAddress();

        // if (
        //     ERC721TokenReceiver(_to).onERC721Received(
        //         msg.sender,
        //         address(0),
        //         _id,
        //         ""
        //     ) != ERC721TokenReceiver.onERC721Received.selector
        // ) revert LERC721__UnsafeAddress();
    }

    /// @notice ...
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _calldata ...
    function safeMint(
        AppStorage storage s,
        address _to,
        uint256 _id,
        bytes memory _calldata
    ) internal {
        mint(s, _to, _id);

        if (_to.code.length != 0) revert LERC721__UnsafeAddress();

        // if (
        //     ERC721TokenReceiver(_to).onERC721Received(
        //         msg.sender,
        //         address(0),
        //         _id,
        //         _calldata
        //     ) != ERC721TokenReceiver.onERC721Received.selector
        // ) revert LERC721__UnsafeAddress();
    }

    //////////////
    /// ERC165 ///
    //////////////

    function supportsInterface(bytes4 interfaceId)
        internal
        pure
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LPausable__AlreadyPaused();
error LPausable__AlreadyUnpaused();
error LPausable__PausedFeature();

/// @title LPausable
/// @author mektigboy
library LPausable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice ...
    /// @param s AppStorage
    function enforceIsUnpaused(AppStorage storage s) internal view {
        if (s.paused) revert LPausable__PausedFeature();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

/// @title LRewards
/// @author mektigboy
library LRewards {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Distribute rewards
    /// @param s AppStorage
    function distributeRewards(AppStorage storage s) internal {
        s.dailySplit = (s.dailyReception * 1e18) / s.tvl;
        s.dailySplits[s.transactionCounter] = s.dailySplit;
    }

    /// @notice Update rewards
    /// @param s AppStorage
    function updateRewards(AppStorage storage s)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // s.balance;
        // s.accumulatedRewardsPerShare = accruedReward * 1e18;
    }

    /// @notice Transfer tokens in a safe manner
    function transfer(address _to, uint256 _amount) internal {}
}