// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/INodeStorage.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LERC721.sol";

error MigrationFacet__UserAlreadyHasNodesInThisContract();
error MigrationFacet__UserNodesAlreadyMigrated();
error MigrationFacet__UserHasNoNodesToMigrate();

/// @title MigrationFacet
/// @author mektigboy, Thehitesh172
/// @notice Facet in charge of migrating the data from the old contract to this contract
contract MigrationFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Migrate nodes from old contract to this contract
    /// @param _account User account
    function migrate(address _account) external {
        if (s.alreadyMigrated[_account])
            revert MigrationFacet__UserNodesAlreadyMigrated();

        if (s.userNodes[_account].length != 0)
            revert MigrationFacet__UserAlreadyHasNodesInThisContract();

        INodeStorage.NodeEntity[] memory nodesToMigrate;

        nodesToMigrate = INodeStorage(s.nodeStorage).getAllNodes(_account);

        if (nodesToMigrate.length == 0)
            revert MigrationFacet__UserHasNoNodesToMigrate();

        s.alreadyMigrated[_account] = true;

        for (uint256 i; i < nodesToMigrate.length; ++i) {
            INodeStorage.NodeEntity memory oldNode = nodesToMigrate[i];

            if (!oldNode.deleted) {
                Node memory node;

                node.name = oldNode.name;
                node.creation = oldNode.creationTime;
                node.lastClaim = oldNode.lastClaimTime;
                node.lastCompound = oldNode.lastCompoundTime;
                node.amount = oldNode.amount;
                node.active = true;

                s.userNodes[_account].push(node);

                s.tvl += node.amount;

                ++s.tokenCounter;
                ++s.activeNodes;

                s.nodeByTokenId[s.tokenCounter] = node;

                LERC721.safeMint(s, _account, s.tokenCounter);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title INodeStorage
/// @author mejiasd3v, mektigboy
interface INodeStorage {
    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 lastCompoundTime;
        uint256 amount;
        bool deleted;
    }

    function getAllActiveNodes(address _account)
        external
        view
        returns (NodeEntity[] memory);

    function getAllDeletedNodes(address _account)
        external
        view
        returns (NodeEntity[] memory);

    function getAllNodes(address _account)
        external
        view
        returns (NodeEntity[] memory);

    function getNode(address _account, uint256 _creationTime)
        external
        view
        returns (NodeEntity memory);

    function getNodesCount(address _account) external view returns (uint256);
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
    uint256 depositFeePercent;
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
    uint256 transactionId;
    ///////////////////////
    /// NODE MANAGEMENT ///
    ///////////////////////
    mapping(address => Node[]) userNodes;
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

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Approve spending of token
    /// @param s AppStorage
    /// @param _spender User that will be allowed to spend
    /// @param _id Token ID
    function approve(
        AppStorage storage s,
        address _spender,
        uint256 _id
    ) internal {
        address owner = s.ownerOf[_id];

        if (msg.sender != owner) revert LERC721__Unauthorized();

        // if (!isApprovedForAll[owner][msg.sender]) revert LERC721__Unauthorized();

        s.getApproved[_id] = _spender;

        emit Approval(owner, _spender, _id);
    }

    /// @notice ...
    /// @param s AppStorage
    /// @param _operator ...
    /// @param _approved ...
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

        if (msg.sender != _from) revert LERC721__Unauthorized();

        // if (!isApprovedForAll[_from][msg.sender])
        //     revert LERC721__Unauthorized();

        // if (msg.sender != s.getApproved[_id])
        //     revert LERC721__Unauthorized();

        unchecked {
            --s.balanceOf[_from];
            ++s.balanceOf[_to];
        }

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

        ++s.tokenCounter;
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