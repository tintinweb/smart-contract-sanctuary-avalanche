/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Provider {
    constructor() { owner = msg.sender; }
    address owner;
    struct AggregatedReaction {
        uint256 idx;
        uint256 qty;
    }
    struct Reaction {
        uint256 idx;
        address author;
        bytes32 value;
    }
    struct Comment {
        uint256 idx;
        address author;
        string value;
        bool approved;
    }
    struct Keyword {
        uint256 idx;
        string value;
    }
    struct Setting {
        uint256 idx;
        string value;
    }
    struct Entry {
        uint256 idx;
        address publisher;
        bytes32 channelId;
        bytes32 collectionId;
        bytes32 contentId;
        mapping(bytes32 => Reaction) reactions;
        bytes32[] reactionIds;
        mapping(bytes32 => AggregatedReaction) aggregatedReactions;
        bytes32[] aggregatedReactionIds;
        mapping(bytes32 => Comment) comments;
        bytes32[] commentIds;
        mapping(bytes32 => Keyword) keywords;
        bytes32[] keywordIds;
        mapping(bytes32 => Setting) settings;
        bytes32[] settingIds;
    }
    mapping(bytes32 => Entry) db;
    bytes32[] entryIds;

    event CreateEntry(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 publicationId);
    event RemoveEntry(bytes32 id, string reason);
    event CreateKeyword(bytes32 publicationId, bytes32 id, string value);
    event RemoveKeyword(bytes32 publicationId, bytes32 id);
    event CreateReaction(bytes32 publicationId, bytes32 id, bytes32 value);
    event RemoveReaction(bytes32 publicationId, bytes32 id);
    event CreateComment(bytes32 publicationId, bytes32 id, string value);
    event RemoveComment(bytes32 publicationId, bytes32 id);
    event CreateSetting(bytes32 publicationId, bytes32 id, string value);
    event RemoveSetting(bytes32 publicationId, bytes32 id);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function createEntry(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId) onlyOwner public returns(bytes32) {
        if(entryIds.length == 0) {
            entryIds.push(0);
        }
        bytes32 id = keccak256(abi.encodePacked(publisher, channelId, collectionId, contentId));
        assert(db[id].idx == 0);
        db[id].idx = entryIds.length;
        entryIds.push(id);
        db[id].publisher = publisher;
        db[id].channelId = channelId;
        db[id].collectionId = collectionId;
        db[id].contentId = contentId;
        emit CreateEntry(publisher, channelId, collectionId, contentId);
        return id;
    }

    function removeEntry(bytes32 id, string calldata reason) onlyOwner public {
        entryIds[db[id].idx] = 0;
        db[id].idx = 0;
        db[id].publisher = address(0);
        emit RemoveEntry(id, reason);
    }

    function createKeyword(bytes32 publicationId, bytes32 id, string calldata value) onlyOwner public {
        assert(db[publicationId].keywords[id].idx == 0);
        if(db[publicationId].keywordIds.length == 0) {
            db[publicationId].keywordIds.push(0);
        }
        db[publicationId].keywords[id].value = value;
        db[publicationId].keywords[id].idx = db[publicationId].keywordIds.length;
        db[publicationId].keywordIds.push(id);
        emit CreateKeyword(publicationId, id, value);
    }

    function removeKeyword(bytes32 publicationId, bytes32 id) onlyOwner public {
        db[publicationId].keywordIds[db[publicationId].keywords[id].idx] = 0;
        db[publicationId].keywords[id].idx = 0;
        db[publicationId].keywords[id].value = "";
        emit RemoveKeyword(publicationId, id);
    }

    function createReaction(bytes32 publicationId, bytes32 id, bytes32 value, address[] calldata subcontentPublishers) public payable {
        require(db[publicationId].reactions[id].idx == 0, "Reaction already exists");
        require(msg.value > 0, "Creating reaction is not free");
        if(db[publicationId].reactionIds.length == 0) {
            db[publicationId].reactionIds.push(0);
        }
        db[publicationId].reactions[id].idx = db[publicationId].reactionIds.length;
        db[publicationId].reactionIds.push(id);
        db[publicationId].reactions[id].value = value;
        db[publicationId].reactions[id].author = msg.sender;

        if(db[publicationId].aggregatedReactionIds.length == 0) {
            db[publicationId].aggregatedReactionIds.push(0);
        }
        if(db[publicationId].aggregatedReactions[value].idx == 0) {
            db[publicationId].aggregatedReactionIds.push(value);
            db[publicationId].aggregatedReactions[value].idx = db[publicationId].aggregatedReactionIds.length;
        }
        db[publicationId].aggregatedReactions[value].qty += 1;
        withdraw(db[publicationId].publisher, subcontentPublishers);
        emit CreateReaction(publicationId, id, value);
    }

    function removeReaction(bytes32 publicationId, bytes32 id) public {
        require(db[publicationId].reactions[id].author == msg.sender, "Only reaction author can remove it");
        bytes32 value = db[publicationId].reactions[id].value;
        db[publicationId].aggregatedReactions[value].qty -= 1;

        db[publicationId].reactionIds[db[publicationId].reactions[id].idx] = 0;
        db[publicationId].reactions[id].idx = 0;
        db[publicationId].reactions[id].value = "";
        db[publicationId].reactions[id].author = address(0);
        emit RemoveReaction(publicationId, id);
    }

    function createComment(bytes32 publicationId, bytes32 id, address[] calldata subcontentPublishers, string calldata value) public payable {
        require(db[publicationId].comments[id].idx == 0, "Comment already exists");
        require(msg.value > 0, "Creating comment is not free");
        if(db[publicationId].commentIds.length == 0) {
            db[publicationId].commentIds.push(0);
        }
        db[publicationId].comments[id].idx = db[publicationId].commentIds.length;
        db[publicationId].commentIds.push(id);
        db[publicationId].comments[id].value = value;
        db[publicationId].comments[id].author = msg.sender;
        withdraw(db[publicationId].publisher, subcontentPublishers);
        emit CreateComment(publicationId, id, value);
    }

    function removeComment(bytes32 publicationId, bytes32 id) public {
        require(db[publicationId].comments[id].author == msg.sender, "Only comment author can remove it");
        db[publicationId].commentIds[db[publicationId].comments[id].idx] = 0;
        db[publicationId].comments[id].idx = 0;
        db[publicationId].comments[id].value = "";
        db[publicationId].comments[id].author = address(0);
        emit RemoveComment(publicationId, id);
    }

    function createSetting(bytes32 publicationId, bytes32 id, string calldata value) public {
        require(db[publicationId].publisher == msg.sender, "Only publisher can create setting");
        if(db[publicationId].settingIds.length == 0) {
            db[publicationId].settingIds.push(0);
        }
        db[publicationId].comments[id].idx = db[publicationId].settingIds.length;
        db[publicationId].settingIds.push(id);
        db[publicationId].settings[id].value = value;
        emit CreateSetting(publicationId, id, value);
    }

    function removeSetting(bytes32 publicationId, bytes32 id) public {
        require(db[publicationId].publisher == msg.sender, "Only publisher can remove setting");
        db[publicationId].settingIds[db[publicationId].settings[id].idx] = 0;
        db[publicationId].settings[id].idx = 0;
        db[publicationId].settings[id].value = "";
        emit RemoveSetting(publicationId, id);
    }

    function getEntryList(uint256 offset, uint256 limit) public view returns(bytes32[] memory, uint256) {
        bytes32[] memory result = new bytes32[](limit);
        for (uint256 i = 1; i <= limit; i++) {
            if(entryIds.length <= offset + i) {
                break;
            }
            result[i] = entryIds[offset + i];
        }
        uint256 total = entryIds.length;
        return (result, total);
    }

    function getEntry(bytes32 id) public view returns(address, bytes32, bytes32, bytes32) {
        return (db[id].publisher, db[id].channelId, db[id].collectionId, db[id].contentId);
    }

    function getKeywords(bytes32 id, uint256 offset, uint256 limit) public view returns(bytes32[] memory, string[] memory) {
        uint256 length = db[id].keywordIds.length;
        bytes32[] memory ids = new bytes32[](length);
        string[] memory values = new string[](length);
        for (uint256 i = 0; i <= limit; i++) {
            if(db[id].keywordIds.length <= offset + i) {
                break;
            }
            ids[i] = db[id].keywordIds[offset + i];
            values[i] = db[id].keywords[ids[offset + i]].value;
        }
        return (ids, values);
    }

    function getComments(bytes32 id, uint256 offset, uint256 limit) public view returns(bytes32[] memory, address[] memory, string[] memory, bool[] memory) {
        uint256 length = db[id].commentIds.length;
        bytes32[] memory ids = new bytes32[](length);
        address[] memory authors = new address[](length);
        string[] memory values = new string[](length);
        bool[] memory statuses = new bool[](length);
        for (uint256 i = 0; i <= limit; i++) {
            if(db[id].commentIds.length <= offset + i) {
                break;
            }
            ids[i] = db[id].commentIds[offset + i];
            authors[i] = db[id].comments[ids[offset + i]].author;
            values[i] = db[id].comments[ids[offset + i]].value;
            statuses[i] = db[id].comments[ids[offset + i]].approved;
        }
        return (ids, authors, values, statuses);
    }

    function getReactions(bytes32 id, uint256 offset, uint256 limit) public view returns(bytes32[] memory, bytes32[] memory) {
        uint256 length = db[id].reactionIds.length;
        bytes32[] memory ids = new bytes32[](length);
        bytes32[] memory values = new bytes32[](length);
        for (uint256 i = 0; i <= limit; i++) {
            if(db[id].reactionIds.length <= offset + i) {
                break;
            }
            ids[i] = db[id].reactionIds[offset + i];
            values[i] = db[id].reactions[ids[offset + i]].value;
        }
        return (ids, values);
    }

    function getAggregatedReactions(bytes32 id, uint256 offset, uint256 limit) public view returns(bytes32[] memory, uint256[] memory) {
        uint256 length = db[id].aggregatedReactionIds.length;
        bytes32[] memory values = new bytes32[](length);
        uint256[] memory qtys = new uint256[](length);
        for (uint256 i = 0; i <= limit; i++) {
            if(db[id].aggregatedReactionIds.length <= offset + i) {
                break;
            }
            values[i] = db[id].aggregatedReactionIds[offset + i];
            qtys[i] = db[id].aggregatedReactions[values[offset + i]].qty;
        }
        return (values, qtys);
    }

    function getSettings(bytes32 id, uint256 offset, uint256 limit) public view returns(bytes32[] memory, string[] memory) {
        uint256 length = db[id].settingIds.length;
        bytes32[] memory ids = new bytes32[](length);
        string[] memory values = new string[](length);
        for (uint256 i = 0; i <= limit; i++) {
            if(db[id].settingIds.length <= offset + i) {
                break;
            }
            ids[i] = db[id].settingIds[offset + i];
            values[i] = db[id].settings[ids[offset + i]].value;
        }
        return (ids, values);
    }

    function withdraw(address publisher, address[] calldata subcontentPublishers) internal {
        uint256 fee = msg.value / 100;
        uint256 subcontentPublisherReward = subcontentPublishers.length > 0 ? msg.value / 10 / subcontentPublishers.length  : 0;
        uint256 publisherReward = msg.value - fee - subcontentPublisherReward * subcontentPublishers.length;

        (bool successFee,) = owner.call{value: fee}("");
        assert(successFee);

        (bool successPublisherReward,) = publisher.call{value: publisherReward}("");
        assert(successPublisherReward);

        for (uint256 i = 0; i < subcontentPublishers.length; i++) {
            (bool success,) = subcontentPublishers[i].call{value: subcontentPublisherReward}("");
            assert(success);
        }
    }

    function updateOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}