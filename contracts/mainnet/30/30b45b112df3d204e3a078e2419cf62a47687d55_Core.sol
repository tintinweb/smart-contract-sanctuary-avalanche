/**
 *Submitted for verification at snowtrace.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Core {
    struct Metadata {
        uint256 idx;
        string data;
    }
    struct SubContent {
        uint256 idx;
        address publisher;
        mapping(bytes32 => Metadata) metadata;
        bytes32[] metadataIds;
    }
    struct Content {
        uint256 idx;
        mapping(bytes32 => SubContent) subcontent;
        bytes32[] subcontentIds;
        mapping(bytes32 => Metadata) metadata;
        bytes32[] metadataIds;
    }
    struct Collection {
        uint256 idx;
        mapping(bytes32 => Content) content;
        bytes32[] contentIds;
        mapping(bytes32 => Metadata) metadata;
        bytes32[] metadataIds;
    }
    struct Channel {
        uint256 idx;
        mapping(bytes32 => Collection) collections;
        bytes32[] collectionIds;
        mapping(bytes32 => Metadata) metadata;
        bytes32[] metadataIds;
    }
    struct Publisher {
        uint256 idx;
        mapping(bytes32 => Channel) channels;
        bytes32[] channelIds;
        mapping(bytes32 => Metadata) metadata;
        bytes32[] metadataIds;
    }
    mapping(address => Publisher) db;
    address[] publisherIds;

    // events
    event SetSubContentMetadata(address publisher, address contentPublisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 subcontentId, bytes32 metadataKey, string metadataValue);
    event DeleteSubContent(address publisher, address contentPublisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 subcontentId);
    event SetContentMetadata(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 metadataKey, string metadataValue);
    event DeleteContent(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId);
    event SetCollectionMetadata(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 metadataKey, string metadataValue);
    event DeleteCollection(address publisher, bytes32 channelId, bytes32 collectionId);
    event SetChannelMetadata(address publisher, bytes32 channelId, bytes32 metadataKey, string metadataValue);
    event DeleteChannel(address publisher, bytes32 channelId);
    event SetPublisherMetadata(address publisher, bytes32 metadataKey, string metadataValue);
    event DeletePublisher(address publisher);

    // general
    function setMetadata(Metadata storage metadata, bytes32 metadataKey, string memory metadataValue, bytes32[] storage metadataIds) internal {
        metadata.data = metadataValue;
        if(metadata.idx == 0) {
            uint256 length = metadataIds.length;
            if(length == 0) {
                metadataIds.push(0);
                length++;
            }
            metadata.idx = length;
            metadataIds.push(metadataKey);
        }
    }

    // subcontent
    function setSubContentMetadata(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 subcontentId, bytes32 metadataKey, string calldata metadataValue) public {
        require(db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].idx == 0 || db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].publisher == msg.sender, "Only SubContent publisher can change the value");
        setMetadata(db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadata[metadataKey], metadataKey, metadataValue, db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadataIds);
        if(db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].idx == 0) {
            uint256 length = db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds.length;
            if(length == 0) {
                db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds.push(0);
                length++;
            }
            db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].idx = length;
            db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].publisher = msg.sender;
            db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds.push(subcontentId);
        }
        emit SetSubContentMetadata(msg.sender, publisher, channelId, collectionId, contentId, subcontentId, metadataKey, metadataValue);
    }

    function deleteSubContent(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 subcontentId) public {
        require(db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].publisher == msg.sender, "Only SubContent publisher can delete it");
        db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds[db[msg.sender].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].idx] = 0;
        db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].idx = 0;
        for (uint256 i = 0; i < db[msg.sender].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadataIds.length; i++) {
            delete db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadata[db[msg.sender].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadataIds[i]];
        }
        db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadataIds = new bytes32[](0);
        db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].publisher == address(0);
        emit DeleteSubContent(msg.sender, publisher, channelId, collectionId, contentId, subcontentId);
    }

    function getSubContentList(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, uint256 offset, uint256 limit) public view returns(bytes32[] memory, uint256) {
        bytes32[] memory result = new bytes32[](limit);
        for (uint256 i = 1; i <= limit; i++) {
            if(db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds.length <= offset + i) {
                break;
            }
            result[i] = db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds[offset + i];
        }
        uint256 total = db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontentIds.length;
        return (result, total);
    }

    function getSubContentMetadata(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 subcontentId) public view returns(bytes32[] memory, string[] memory, address) {
        uint256 length = db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadataIds.length;
        bytes32[] memory metadataIds = new bytes32[](length);
        string[] memory metadata = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            metadataIds[i] = db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadataIds[i];
            metadata[i] = db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].metadata[metadataIds[i]].data;
        }
        return (metadataIds, metadata, db[publisher].channels[channelId].collections[collectionId].content[contentId].subcontent[subcontentId].publisher);
    }

    // content
    function setContentMetadata(bytes32 channelId, bytes32 collectionId, bytes32 contentId, bytes32 metadataKey, string calldata metadataValue) public {
        setMetadata(db[msg.sender].channels[channelId].collections[collectionId].content[contentId].metadata[metadataKey], metadataKey, metadataValue, db[msg.sender].channels[channelId].collections[collectionId].content[contentId].metadataIds);
        if(db[msg.sender].channels[channelId].collections[collectionId].content[contentId].idx == 0) {
            uint256 length = db[msg.sender].channels[channelId].collections[collectionId].contentIds.length;
            if(length == 0) {
                db[msg.sender].channels[channelId].collections[collectionId].contentIds.push(0);
                length++;
            }
            db[msg.sender].channels[channelId].collections[collectionId].content[contentId].idx = length;
            db[msg.sender].channels[channelId].collections[collectionId].contentIds.push(contentId);
        }
        emit SetContentMetadata(msg.sender, channelId, collectionId, contentId, metadataKey, metadataValue);
    }

    function deleteContent(bytes32 channelId, bytes32 collectionId, bytes32 contentId) public {
        db[msg.sender].channels[channelId].collections[collectionId].contentIds[db[msg.sender].channels[channelId].collections[collectionId].content[contentId].idx] = 0;
        db[msg.sender].channels[channelId].collections[collectionId].content[contentId].idx = 0;
        for (uint256 i = 0; i < db[msg.sender].channels[channelId].collections[collectionId].content[contentId].metadataIds.length; i++) {
            delete db[msg.sender].channels[channelId].collections[collectionId].content[contentId].metadata[db[msg.sender].channels[channelId].collections[collectionId].content[contentId].metadataIds[i]];
        }
        db[msg.sender].channels[channelId].collections[collectionId].content[contentId].metadataIds = new bytes32[](0);
        emit DeleteContent(msg.sender, channelId, collectionId, contentId);
    }

    function getContentList(address publisher, bytes32 channelId, bytes32 collectionId, uint256 offset, uint256 limit) public view returns(bytes32[] memory, uint256) {
        bytes32[] memory result = new bytes32[](limit);
        for (uint256 i = 1; i <= limit; i++) {
            if(db[publisher].channels[channelId].collections[collectionId].contentIds.length <= offset + i) {
                break;
            }
            result[i] = db[publisher].channels[channelId].collections[collectionId].contentIds[offset + i];
        }
        uint256 total = db[publisher].channels[channelId].collections[collectionId].contentIds.length;
        return (result, total);
    }

    function getContentMetadata(address publisher, bytes32 channelId, bytes32 collectionId, bytes32 contentId) public view returns(bytes32[] memory, string[] memory) {
        uint256 length = db[publisher].channels[channelId].collections[collectionId].content[contentId].metadataIds.length;
        bytes32[] memory metadataIds = new bytes32[](length);
        string[] memory metadata = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            metadataIds[i] = db[publisher].channels[channelId].collections[collectionId].content[contentId].metadataIds[i];
            metadata[i] = db[publisher].channels[channelId].collections[collectionId].content[contentId].metadata[metadataIds[i]].data;
        }
        return (metadataIds, metadata);
    }

    // collection
    function setCollectionMetadata(bytes32 channelId, bytes32 collectionId, bytes32 metadataKey, string calldata metadataValue) public {
        setMetadata(db[msg.sender].channels[channelId].collections[collectionId].metadata[metadataKey], metadataKey, metadataValue, db[msg.sender].channels[channelId].collections[collectionId].metadataIds);
        if(db[msg.sender].channels[channelId].collections[collectionId].idx == 0) {
            uint256 length = db[msg.sender].channels[channelId].collectionIds.length;
            if(length == 0) {
                db[msg.sender].channels[channelId].collectionIds.push(0);
                length++;
            }
            db[msg.sender].channels[channelId].collections[collectionId].idx = length;
            db[msg.sender].channels[channelId].collectionIds.push(collectionId);
        }
        emit SetCollectionMetadata(msg.sender, channelId, collectionId, metadataKey, metadataValue);
    }

    function deleteCollection(bytes32 channelId, bytes32 collectionId) public {
        db[msg.sender].channels[channelId].collectionIds[db[msg.sender].channels[channelId].collections[collectionId].idx] = 0;
        db[msg.sender].channels[channelId].collections[collectionId].idx = 0;
        for (uint256 i = 0; i < db[msg.sender].channels[channelId].collections[collectionId].metadataIds.length; i++) {
            delete db[msg.sender].channels[channelId].collections[collectionId].metadata[db[msg.sender].channels[channelId].collections[collectionId].metadataIds[i]];
        }
        db[msg.sender].channels[channelId].collections[collectionId].metadataIds = new bytes32[](0);
        emit DeleteCollection(msg.sender, channelId, collectionId);
    }

    function getCollectionList(address publisher, bytes32 channelId, uint256 offset, uint256 limit) public view returns(bytes32[] memory, uint256) {
        bytes32[] memory result = new bytes32[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if(db[publisher].channels[channelId].collectionIds.length <= offset + i) {
                break;
            }
            result[i] = db[publisher].channels[channelId].collectionIds[offset + i];
        }
        uint256 total = db[publisher].channels[channelId].collectionIds.length;
        return (result, total);
    }

    function getCollectionMetadata(address publisher, bytes32 channelId, bytes32 collectionId) public view returns(bytes32[] memory, string[] memory) {
        uint256 length = db[publisher].channels[channelId].collections[collectionId].metadataIds.length;
        bytes32[] memory metadataIds = new bytes32[](length);
        string[] memory metadata = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            metadataIds[i] = db[publisher].channels[channelId].collections[collectionId].metadataIds[i];
            metadata[i] = db[publisher].channels[channelId].collections[collectionId].metadata[metadataIds[i]].data;
        }
        return (metadataIds, metadata);
    }

    // channel
    function setChannelMetadata(bytes32 channelId, bytes32 metadataKey, string calldata metadataValue) public {
        setMetadata(db[msg.sender].channels[channelId].metadata[metadataKey], metadataKey, metadataValue, db[msg.sender].channels[channelId].metadataIds);
        if(db[msg.sender].channels[channelId].idx == 0) {
            uint256 length = db[msg.sender].channelIds.length;
            if(length == 0) {
                db[msg.sender].channelIds.push(0);
                length++;
            }
            db[msg.sender].channels[channelId].idx = length;
            db[msg.sender].channelIds.push(channelId);
        }
        emit SetChannelMetadata(msg.sender, channelId, metadataKey, metadataValue);
    }

    function deleteChannel(bytes32 channelId) public {
        db[msg.sender].channelIds[db[msg.sender].channels[channelId].idx] = 0;
        db[msg.sender].channels[channelId].idx = 0;
        for (uint256 i = 0; i < db[msg.sender].channels[channelId].metadataIds.length; i++) {
            delete db[msg.sender].channels[channelId].metadata[db[msg.sender].channels[channelId].metadataIds[i]];
        }
        db[msg.sender].channels[channelId].metadataIds = new bytes32[](0);
        emit DeleteChannel(msg.sender, channelId);
    }

    function getChannelList(address publisher, uint256 offset, uint256 limit) public view returns(bytes32[] memory, uint256) {
        bytes32[] memory result = new bytes32[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if(db[publisher].channelIds.length <= offset + i) {
                break;
            }
            result[i] = db[publisher].channelIds[offset + i];
        }
        uint256 total = db[publisher].channelIds.length;
        return (result, total);
    }

    function getChannelMetadata(address publisher, bytes32 channelId) public view returns(bytes32[] memory, string[] memory) {
        uint256 length = db[publisher].channels[channelId].metadataIds.length;
        bytes32[] memory metadataIds = new bytes32[](length);
        string[] memory metadata = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            metadataIds[i] = db[publisher].channels[channelId].metadataIds[i];
            metadata[i] = db[publisher].channels[channelId].metadata[metadataIds[i]].data;
        }
        return (metadataIds, metadata);
    }

    // publisher
    function setPublisherMetadata(bytes32 metadataKey, string calldata metadataValue) public {
        setMetadata(db[msg.sender].metadata[metadataKey], metadataKey, metadataValue, db[msg.sender].metadataIds);
        if(db[msg.sender].idx == 0) {
            uint256 length = publisherIds.length;
            if(length == 0) {
                publisherIds.push(address(0));
                length++;
            }
            db[msg.sender].idx = length;
            publisherIds.push(msg.sender);
        }
        emit SetPublisherMetadata(msg.sender, metadataKey, metadataValue);
    }

    function deletePublisher() public {
        publisherIds[db[msg.sender].idx] = address(0);
        db[msg.sender].idx = 0;
        for (uint256 i = 0; i < db[msg.sender].metadataIds.length; i++) {
            delete db[msg.sender].metadata[db[msg.sender].metadataIds[i]];
        }
        db[msg.sender].metadataIds = new bytes32[](0);
        emit DeletePublisher(msg.sender);
    }

    function getPublisherList(uint256 offset, uint256 limit) public view returns(address[] memory, uint256) {
        address[] memory result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if(publisherIds.length <= offset + i) {
                break;
            }
            result[i] = publisherIds[offset + i];
        }
        uint256 total = publisherIds.length;
        return (result, total);
    }

    function getPublisherMetadata(address publisher) public view returns(bytes32[] memory, string[] memory) {
        uint256 length = db[publisher].metadataIds.length;
        bytes32[] memory metadataIds = new bytes32[](length);
        string[] memory metadata = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            metadataIds[i] = db[publisher].metadataIds[i];
            metadata[i] = db[publisher].metadata[metadataIds[i]].data;
        }
        return (metadataIds, metadata);
    }
}