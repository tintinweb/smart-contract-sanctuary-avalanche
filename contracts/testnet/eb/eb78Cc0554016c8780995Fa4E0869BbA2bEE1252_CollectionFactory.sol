// SPDX-License-Identifier: MIT
// Omnisea Contracts v0.0.1

pragma solidity ^0.8.7;

import "../interfaces/ICollectionsRepository.sol";
import "../interfaces/IOmniERC721.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";

contract CollectionFactory is IOmniApp {

    struct CreateParams {
        string dstChainName;
        string collName;
        string collURI;
        string fileURI;
        uint256 price;
        string assetName;
        uint256 from;
        uint256 to;
        string[] URIs;
        uint gas;
        uint256 redirectFee;
    }

    event Created(address addr, address creator);
    event FailedCreate(uint16 srcId, bytes src, uint64 nonce, bytes _payload);
    event OmReceived(string srcChain, address srcUA);

    address public repository;
    address private _owner;
    string public chainName;
    mapping(address => address[]) public createdBy;
    mapping(string => address) public chainToUA;
    ICollectionsRepository private _collectionsRepository;
    IOmnichainRouter public omnichainRouter;

    constructor(IOmnichainRouter _router) {
        _owner = msg.sender;
        chainName = "Avalanche";
        omnichainRouter = _router;
    }

    function setRepository(address repo) external {
        require(msg.sender == _owner && repository == address(0));
        _collectionsRepository = ICollectionsRepository(repo);
        repository = repo;
    }

    function create(CreateParams calldata params) public payable {
        require(bytes(params.collName).length >= 2);
        if (keccak256(bytes(params.dstChainName)) == keccak256(bytes(chainName))) {
            IOmniERC721 collection = _add(params.collName, params.collURI, msg.sender, params.price);
            _setDetails(collection, params.fileURI, params.URIs, params.from, params.to, params.assetName);
            createdBy[msg.sender].push(collection.getAddress());
            emit Created(collection.getAddress(), msg.sender);
            return;
        }
        bytes memory payload = _getPayload(params.collName, params.collURI, params.fileURI, params.price, params.from, params.to, msg.sender, params.URIs, params.assetName);
        omnichainRouter.send{value : msg.value}(params.dstChainName, chainToUA[params.dstChainName], payload, params.gas, msg.sender, params.redirectFee);
    }

    function omReceive(bytes calldata _payload, address srcUA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcUA);
        //        require(isUA(srcChain, srcUA));
        (string memory collName, string memory collectionURI, string memory fileURI, address creator, uint256 mintPrice, uint256 dropFrom, uint256 dropTo, string[] memory metadataURIs, string memory assetName)
        = abi.decode(_payload, (string, string, string, address, uint256, uint256, uint256, string[], string));
        IOmniERC721 collection = _add(collName, collectionURI, creator, mintPrice);
        _setDetails(collection, fileURI, metadataURIs, dropFrom, dropTo, assetName);
        createdBy[creator].push(collection.getAddress());
        emit Created(collection.getAddress(), creator);
    }

    function setUA(string calldata _chainName, address chainUA) external {
        require(msg.sender == _owner);
        chainToUA[_chainName] = chainUA;
    }

    function isUA(string memory _chainName, address chainUA) public view returns (bool) {
        return chainToUA[_chainName] == chainUA;
    }

    function _getPayload(string memory collName, string memory URI, string memory fileURI, uint256 price, uint256 from, uint256 to, address tokenOwner, string[] memory URIs, string memory assetName) private pure returns (bytes memory) {
        return abi.encode(collName, URI, fileURI, tokenOwner, price, from, to, URIs, assetName);
    }

    function _add(string memory collName, string memory collURI, address tokenOwner, uint256 price) internal returns (IOmniERC721) {
        return _collectionsRepository.addCollection(collName, collURI, tokenOwner, price);
    }

    function _setDetails(IOmniERC721 collection, string memory fileURI, string[] memory metadataURIs, uint256 from, uint256 to, string memory assetName) internal {
        return _collectionsRepository.setDetails(collection, fileURI, metadataURIs, from, to, assetName);
    }

    receive() external payable {}
}

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";

interface ICollectionsRepository {
    function addCollection(
        string memory _collName,
        string memory _collectionURI,
        address _creator,
        uint256 _mintPrice
    ) external returns (IOmniERC721);

    function setDetails(IOmniERC721 collection, string memory fileURI, string[] memory metadataURIs, uint256 from, uint256 to, string memory assetName) external;
}

pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner) external;
    function getTotalSupply() external view returns (uint256);
    function getMintPrice() external view returns (uint256);
    function getMintedCount() external view returns (uint256);
    function getCreator() external view returns (address);
    function getCreatedAt() external view returns (uint256);
    function getFrom() external view returns (uint256);
    function getAddress() external view returns (address);
    function getDetails() external view returns (string memory, address, uint256, uint256, uint256);
    function getAsset() external view returns (string memory);
    function setFileURI(string memory fileURI) external;
    function setDates(uint256 _from, uint256 _to) external;
    function setAsset(string memory asset) external;
    function addMetadataURIs(string[] memory _metadataURIs) external;
}

pragma solidity ^0.8.7;

interface IOmniApp {
    function omReceive(bytes calldata _payload, address srcUA, string memory srcChain) external;
}

pragma solidity ^0.8.7;

interface IOmnichainRouter {
    function send(string memory dstChainName, address dstUA, bytes memory _fnData, uint gas, address origin, uint256 redirectFee) external payable;
}