// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libs/ERC721MintMore.sol';
import './libs/IERC20Mint.sol';
import './libs/SafeERC20Mint.sol';
import './Marketplace.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFT is ERC721MintMore, Ownable {
    using SafeERC20Mint for IERC20Mint;
    IERC20Mint public tokenProduct;
    IERC20Mint public tokenUpgrade;
    IERC20Mint public tokenFactory;
    Marketplace public marketplace;
    uint private rndCounter;
    uint public nftCount;
    uint public collectionsCount;
    uint public devFeePercent;
    address public devFeeAddress;
    address public burnAddress;
    string public nftName;
    string public nftSymbol;
    mapping(uint => Collection) public collections;
    mapping (uint => NFTDetails) public nfts;
    event eventTransfer(address indexed _fromAddress, address indexed _toAddress, uint indexed _nftID);
    event eventNFTRename(uint indexed _nftID, string indexed _nameOld, string indexed _nameNew);
    event eventNFTSetNFTProperty(uint indexed _nftID, uint indexed _valueOld, uint indexed _value);
    event eventNFTLevelUpgrade(uint indexed _nftID, uint indexed _levelOld, uint indexed _levelNew);
    event eventNFTHarvestTokenProduct(uint indexed _nftID, address indexed _toAddress, uint indexed _amount);
    event eventFactory(uint indexed _nftMaleID, uint indexed _nftFemaleID, uint indexed _newID);
    event eventCollectionAdd(uint indexed _collectionID, string indexed _name, uint indexed _tokenProductEmission);
    event eventCollectionRename(uint indexed _collectionID, string indexed _nameOld, string indexed _nameNew);
    event eventCollectionSetFactoryTime(uint indexed _collectionID, uint indexed _factoryTimeOld, uint indexed _factoryTimeNew);
    event eventCollectionSetTokenProductEmission(uint _collectionID, uint indexed _emissionOld, uint indexed _emissionNew);
    event eventCollectionSetTokenUpgradePriceLevel(uint indexed _collectionID, uint indexed _priceOld, uint indexed _price);
    event eventCollectionSetTokenUpgradePriceSetProperty(uint indexed _collectionID, uint indexed _priceOld, uint indexed _price);
    event eventCollectionSetTokenFactoryPrice(uint indexed _collectionID, uint indexed _priceOld, uint indexed _price);
    event eventCollectionRemove(uint indexed _collectionID);
    event eventCollectionPropertyAdd(uint indexed _collectionID, uint indexed _propertyID, string indexed _name);
    event eventCollectionPropertyRename(uint indexed _collectionID, uint indexed _propertyID, string indexed _name);
    event eventCollectionPropertySetBasicCount(uint indexed _collectionID, uint _propertyID, uint _basicCount);
    event eventCollectionPropertyRemove(uint indexed _collectionID, uint indexed _propertyID);
    event eventSetDevFeeAddress(address indexed devFeeAddressOld, address indexed _devFeeAddress);
    
    struct Collection {
        bool exists;
        string name;
        uint factoryTime; // 50400 = 1 day
        uint tokenProductEmission;
        uint tokenUpgradePriceLevel;
        uint tokenUpgradePriceSetProperty;
        uint tokenFactoryPrice;
        Property[] properties;
        uint nftCount;
        uint createdTime;
    }
    
    struct Property {
        string name;
        uint basicCount;
        uint createdTime;
    }

    struct NFTDetails {
        bool exists;
        bool sex;
        bool hasParents;
        uint parentMaleID;
        uint parentFemaleID;
        string name;
        uint collectionID;
        uint level;
        uint lastEmissionBlock;
        uint[] properties;
        uint createdTime;
    }
    
    constructor(string memory _nftName, string memory _nftSymbol, uint _devFeePercent, address _devFeeAddress, address _burnAddress, address _marketplaceAddress, address _tokenFactoryAddress, address _tokenProductAddress, address _tokenUpgradeAddress) ERC721MintMore(_nftName, _nftSymbol) {
        nftName = _nftName;
        nftSymbol = _nftSymbol;
        devFeePercent = _devFeePercent;
        devFeeAddress = _devFeeAddress;
        burnAddress = _burnAddress;
        marketplace = Marketplace(_marketplaceAddress);
        tokenFactory = IERC20Mint(_tokenFactoryAddress);
        tokenProduct = IERC20Mint(_tokenProductAddress);
        tokenUpgrade = IERC20Mint(_tokenUpgradeAddress);
    }

    function transfer(address _fromAddress, address _toAddress, uint _nftID) public {
        require(ownerOf(_nftID) == msg.sender, 'transfer: You are not the owner of this NFT');
        nftHarvestTokenProduct(_nftID);
        safeTransferFrom(_fromAddress, address(this), _nftID);
        safeTransferFrom(address(this), _toAddress, _nftID);
        emit eventTransfer(_fromAddress, _toAddress, _nftID);
    }

    function nftRename(uint _nftID, string memory _name) public {
        require(nfts[_nftID].exists, 'nftRename: Wrong NFT ID');
        require(ownerOf(_nftID) == msg.sender, 'nftRename: You are not the owner of this NFT');
        require(getUTFStrLen(_name) <= 16, 'nftRename: Name is too long. Maximum: 16 characters');
        require(getCharMatch(_name), 'nftRename: Name can contain only a-z, A-Z, 0-9, space and dot');
        string memory nameOld = nfts[_nftID].name;
        nfts[_nftID].name = _name;
        emit eventNFTRename(_nftID, nameOld, _name);
    }

    function nftLevelUpgrade(uint _nftID, uint _levels) public {
        require(nfts[_nftID].exists, 'nftLevelUpgrade: Wrong NFT ID');
        uint amount = _levels * collections[nfts[_nftID].collectionID].tokenUpgradePriceLevel;
        require(tokenUpgrade.allowance(msg.sender, address(this)) >= amount, 'nftLevelUpgrade: Token Upgrade allowance is too low');
        require(tokenUpgrade.balanceOf(msg.sender) >= amount, 'nftLevelUpgrade: Not enough Token Upgrade in your wallet');
        tokenUpgrade.safeTransferFrom(msg.sender, address(this), amount);
        tokenUpgrade.safeTransfer(devFeeAddress, amount * devFeePercent / 10000);
        tokenUpgrade.safeTransfer(burnAddress, amount * (10000 - devFeePercent) / 10000);
        nftHarvestTokenProduct(_nftID);
        uint levelOld = nfts[_nftID].level;
        nfts[_nftID].level += _levels;
        emit eventNFTLevelUpgrade(_nftID, levelOld, nfts[_nftID].level);
    }

    function nftSetProperty(uint _nftID, uint _propertyID, uint _value) public {
        require(nfts[_nftID].exists, 'nftSetProperty: Wrong NFT ID');
        require(ownerOf(_nftID) == msg.sender, 'nftSetProperty: You are not the owner of this NFT');
        require(collections[nfts[_nftID].collectionID].properties.length >= _propertyID, 'nftSetProperty: Property does not exist');
        require(collections[nfts[_nftID].collectionID].properties[_propertyID].basicCount <= _value , 'nftSetProperty: This property is not available');
        uint amount = collections[nfts[_nftID].collectionID].tokenUpgradePriceSetProperty;
        require(tokenUpgrade.allowance(msg.sender, address(this)) >= amount, 'nftSetProperty: Token Upgrade allowance is too low');
        require(tokenUpgrade.balanceOf(msg.sender) >= amount, 'nftSetProperty: Not enough Token Upgrade in your wallet');
        tokenUpgrade.safeTransferFrom(msg.sender, address(this), amount);
        tokenUpgrade.safeTransfer(devFeeAddress, amount * devFeePercent / 10000);
        tokenUpgrade.safeTransfer(burnAddress, amount * (10000 - devFeePercent) / 10000);
        uint valueOld = nfts[_nftID].properties[_propertyID];
        nfts[_nftID].properties[_propertyID] = _value;
        emit eventNFTSetNFTProperty(_nftID, valueOld, _value);
    }

    function nftHarvestTokenProduct(uint _nftID) public {
        uint toHarvest = getTokenProductToHarvest(_nftID);
        if (ownerOf(_nftID) != owner()) {
            tokenProduct.mint(toHarvest);
            tokenProduct.safeTransfer(ownerOf(_nftID), toHarvest);
        }
        nfts[_nftID].lastEmissionBlock = block.number;
        emit eventNFTHarvestTokenProduct(_nftID, msg.sender, toHarvest);
    }

    function getTokenProductToHarvest(uint _nftID) public view returns(uint) {
        if (ownerOf(_nftID) != owner()) return 0;
        else return (block.number - nfts[_nftID].lastEmissionBlock) * nfts[_nftID].level * collections[nfts[_nftID].collectionID].tokenProductEmission;
    }

    function mint(address _recipient, uint _collectionID, string memory _name, bool _hasParents, uint _parentMaleID, uint _parentFemaleID) public onlyOwner returns (uint) {
        require(collections[_collectionID].exists, 'mint: Wrong collection ID');
        require(collections[_collectionID].properties.length > 0, 'mint: This collection has no properties');
        require(getUTFStrLen(_name) <= 16, 'mint: Name is too long. Maximum: 16 characters');
        require(getCharMatch(_name), 'mint: Name can contain only a-z, A-Z, 0-9, space and dot');
        if (_hasParents) {
            require(nfts[_parentMaleID].exists, 'mint: parentMaleID does not exist');
            require(nfts[_parentMaleID].collectionID == _collectionID, 'mint: parentMaleID is from different collection');
            require(nfts[_parentMaleID].sex, 'mint: parentMaleID does not refer to male NFT');
            require(nfts[_parentFemaleID].exists, 'mint: parentFemaleID does not exist');
            require(nfts[_parentFemaleID].collectionID == _collectionID, 'mint: parentFemaleID is from different collection');
            require(!nfts[_parentFemaleID].sex, 'mint: parentFemaleID does not refer to female NFT');
        } else {
            require(_parentMaleID == 0, 'mint: parentMaleID has to be 0');
            require(_parentFemaleID == 0, 'mint: parentFemaleID has to be 0');
        }
        _safeMint(_recipient, nftCount);
        mintAddDetails(_collectionID, _name, _hasParents, _parentMaleID, _parentFemaleID);
        return nftCount - 1;
    }

    function mintMore(address _recipient, uint _collectionID, string memory _name, uint _count) public onlyOwner returns (uint) {
        require(collections[_collectionID].exists, 'mintMore: Wrong collection ID');
        require(collections[_collectionID].properties.length > 0, 'mintMore: This collection has no properties');
        require(getUTFStrLen(_name) <= 16, 'mintMore: Name is too long. Maximum: 16 characters');
        require(getCharMatch(_name), 'mintMore: Name can contain only a-z, A-Z, 0-9, space and dot');
        _mintMore(_recipient, nftCount, _count);
        for (uint i = 0; i < _count; i++) mintAddDetails(_collectionID, string(abi.encodePacked(_name, ' ', Strings.toString(nftCount + 1))), false, 0, 0);
        return nftCount - 1;
    }

    function mintToMarketplace(uint _collectionID, string memory _name, uint _price) public onlyOwner {
        uint nftID = mint(address(this), _collectionID, _name, false, 0, 0);
        marketplace.deposit(address(this), nftID, _price);
    }

    function mintMoreToMarketplace(uint _collectionID, string memory _name, uint _price, uint _count) public onlyOwner {
        uint startID = nftCount;
        mintMore(address(this), _collectionID, _name, _count);
        for (uint i = 0; i < _count; i++) marketplace.deposit(address(this), startID + i, _price);
    }

    function mintAddDetails(uint _collectionID, string memory _name, bool _hasParents, uint _parentMaleID, uint _parentFemaleID) private onlyOwner {
        nfts[nftCount].exists = true;
        nfts[nftCount].sex = getRandomNumber(2) == 1 ? true : false;
        nfts[nftCount].hasParents = _hasParents;
        nfts[nftCount].parentMaleID = _parentMaleID;
        nfts[nftCount].parentFemaleID = _parentFemaleID;
        nfts[nftCount].name = _name;
        nfts[nftCount].collectionID = _collectionID;
        nfts[nftCount].level = 1;
        nfts[nftCount].lastEmissionBlock = block.number;
        for (uint i = 0; i < collections[_collectionID].properties.length - 1; i++) {
            nfts[nftCount].properties[i] = getRandomNumber(collections[_collectionID].properties[i].basicCount);
        }
        nfts[nftCount].createdTime = block.timestamp;
        collections[_collectionID].nftCount++;
        nftCount++;
    }

    function factory(uint _nftMaleID, uint _nftFemaleID, string memory _name) public {
        require(ownerOf(_nftMaleID) == msg.sender, 'factory: First ID is not in your wallet');
        require(ownerOf(_nftFemaleID) == msg.sender, 'factory: Second ID is not in your wallet');
        require(nfts[_nftMaleID].collectionID == nfts[_nftFemaleID].collectionID, 'factory: Male ID and female ID are not from the same collection.');
        require(nfts[_nftMaleID].sex, 'factory: First ID is not male');
        require(!nfts[_nftFemaleID].sex, 'factory: Second ID is not female');
        require(nfts[_nftMaleID].createdTime + collections[nfts[_nftMaleID].collectionID].factoryTime < block.timestamp, 'factory: Male NFT is too young');
        require(nfts[_nftFemaleID].createdTime + collections[nfts[_nftFemaleID].collectionID].factoryTime < block.timestamp, 'factory: Female NFT is too young');
        tokenFactory.safeTransferFrom(msg.sender, address(this), collections[nfts[_nftMaleID].collectionID].tokenFactoryPrice);
        tokenFactory.safeTransfer(devFeeAddress, collections[nfts[_nftMaleID].collectionID].tokenFactoryPrice * devFeePercent / 10000);
        tokenFactory.safeTransfer(burnAddress, collections[nfts[_nftMaleID].collectionID].tokenFactoryPrice * (10000 - devFeePercent) / 10000);
        uint newID = mint(msg.sender, nfts[_nftMaleID].collectionID, _name, true, _nftMaleID, _nftFemaleID);
        emit eventFactory(_nftMaleID, _nftFemaleID, newID);
    }

    function getNFTProperty(uint _nftID, uint _propertyID) view public returns (uint) {
        require(nfts[_nftID].exists, 'getNFTProperty: Wrong NFT ID');
        require(_propertyID < collections[nfts[_nftID].collectionID].properties.length, 'getNFTProperty: Wrong property ID');
        return nfts[_nftID].properties[_propertyID];
    }

    function getCollectionProperty(uint _collectionID, uint _propertyID) view public returns (Property memory) {
        require(collections[_collectionID].exists, 'getCollectionProperty: Wrong collection ID');
        require(_propertyID < collections[_collectionID].properties.length, 'getCollectionProperty: Wrong property ID');
        return collections[_collectionID].properties[_propertyID];
    }

    function collectionAdd(string memory _name, uint _factoryTime, uint _tokenProductEmission, uint _tokenUpgradePriceLevel, uint _tokenUpgradePriceSetProperty, uint _tokenFactoryPrice) public onlyOwner returns (uint) {
        collections[collectionsCount].exists = true;
        collections[collectionsCount].name = _name;
        collections[collectionsCount].factoryTime = _factoryTime;
        collections[collectionsCount].tokenProductEmission = _tokenProductEmission;
        collections[collectionsCount].tokenUpgradePriceLevel = _tokenUpgradePriceLevel;
        collections[collectionsCount].tokenUpgradePriceSetProperty = _tokenUpgradePriceSetProperty;
        collections[collectionsCount].tokenFactoryPrice = _tokenFactoryPrice;
        collections[collectionsCount].nftCount = 0;
        collections[collectionsCount].createdTime = block.timestamp;
        collectionsCount++;
        emit eventCollectionAdd(collectionsCount - 1, _name, _tokenProductEmission);
        return collectionsCount - 1;
    }

    function collectionRename(uint _collectionID, string memory _name) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionRename: Wrong collection ID');
        string memory nameOld = collections[_collectionID].name;
        collections[_collectionID].name = _name;
        emit eventCollectionRename(_collectionID, nameOld, _name);
    }

    function collectionSetFactoryTime(uint _collectionID, uint _factoryTime) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionSetFactoryTime: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionSetFactoryTime: Cannot set factory time in collection that has NFTs.');
        uint factoryTimeOld = collections[_collectionID].factoryTime;
        collections[_collectionID].factoryTime = _factoryTime;
        emit eventCollectionSetFactoryTime(_collectionID, factoryTimeOld, _factoryTime);
    }

    function collectionSetTokenProductEmission(uint _collectionID, uint _emission) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionSetTokenProductEmission: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionSetTokenProductEmission: Cannot set token Product emission in collection that has NFTs.');
        uint emissionOld = collections[_collectionID].tokenProductEmission;
        collections[_collectionID].tokenProductEmission = _emission;
        emit eventCollectionSetTokenProductEmission(_collectionID, emissionOld, _emission);
    }

    function collectionSetTokenUpgradePriceLevel(uint _collectionID, uint _price) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionSetTokenUpgradePriceLevel: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionSetTokenUpgradePriceLevel: Cannot set token Upgrade price in collection that has NFTs.');
        uint priceOld = collections[_collectionID].tokenUpgradePriceLevel;
        collections[_collectionID].tokenUpgradePriceLevel = _price;
        emit eventCollectionSetTokenUpgradePriceLevel(_collectionID, priceOld, _price);
    }

    function collectionSetTokenUpgradePriceSetProperty(uint _collectionID, uint _price) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionSetTokenUpgradePriceSetProperty: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionSetTokenUpgradePriceSetProperty: Cannot set token Upgrade price in collection that has NFTs.');
        uint priceOld = collections[_collectionID].tokenUpgradePriceSetProperty;
        collections[_collectionID].tokenUpgradePriceSetProperty = _price;
        emit eventCollectionSetTokenUpgradePriceSetProperty(_collectionID, priceOld, _price);
    }

    function collectionSetTokenFactoryPrice(uint _collectionID, uint _price) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionSetTokenFactoryPrice: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionSetTokenFactoryPrice: Cannot set token Upgrade price in collection that has NFTs.');
        uint priceOld = collections[_collectionID].tokenFactoryPrice;
        collections[_collectionID].tokenFactoryPrice = _price;
        emit eventCollectionSetTokenFactoryPrice(_collectionID, priceOld, _price);
    }

    function collectionRemove(uint _collectionID) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionRemove: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionRemove: Cannot remove collection that has NFTs.');
        delete collections[_collectionID];
        emit eventCollectionRemove(_collectionID);
    }

    function collectionPropertyAdd(uint _collectionID, string memory _name, uint _basicCount) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionPropertyAdd: Wrong collection ID');
        require(collections[_collectionID].nftCount == 0, 'collectionPropertyAdd: Cannot add property, because it was already used in collection that has NFTs.');
        collections[_collectionID].properties.push(Property(_name, _basicCount, block.timestamp));
        emit eventCollectionPropertyAdd(_collectionID, collections[_collectionID].properties.length - 1, _name);
    }

    function collectionPropertyRename(uint _collectionID, uint _propertyID, string memory _name) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionPropertyRename: Wrong collection ID');
        require(_propertyID < collections[_collectionID].properties.length, 'collectionPropertyRename: Wrong property ID');
        collections[_propertyID].name = _name;
        emit eventCollectionPropertyRename(_collectionID, _propertyID, _name);
    }

    function collectionPropertySetBasicCount(uint _collectionID, uint _propertyID, uint _basicCount) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionPropertySetBasicCount: Wrong collection ID');
        require(_propertyID < collections[_collectionID].properties.length, 'collectionPropertySetBasicCount: Wrong property ID');
        require(collections[_collectionID].nftCount == 0, 'collectionPropertySetBasicCount: Cannot remove property, because it was already used in collection that has NFTs.');
        collections[_collectionID].properties[_propertyID].basicCount = _basicCount;
        emit eventCollectionPropertySetBasicCount(_collectionID, _propertyID, _basicCount);
    }

    function collectionPropertyRemove(uint _collectionID, uint _propertyID) public onlyOwner {
        require(collections[_collectionID].exists, 'collectionPropertyRemove: Wrong collection ID');
        require(_propertyID < collections[_collectionID].properties.length, 'collectionPropertyRemove: Wrong property ID');
        require(collections[_collectionID].nftCount == 0, 'collectionPropertyRemove: Cannot remove property, because it was already used in collection that has NFTs.');
        delete collections[_collectionID].properties[_propertyID];
        emit eventCollectionPropertyRemove(_collectionID, _propertyID);
    }

    function getRandomNumber(uint _num) private returns (uint) {
        if (rndCounter == 2**256 - 1) rndCounter = 0;
        else rndCounter++;
        return uint(uint(keccak256(abi.encodePacked(block.timestamp, rndCounter))) % _num);
    }

    function getUTFStrLen(string memory str) pure internal returns (uint) {
        uint length = 0;
        uint i = 0;
        bytes memory string_rep = bytes(str);
        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i++;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E))) i += 4;
            else i++;
            length++;
        }
        return length;
    }
    
    function getCharMatch(string memory str) pure internal returns (bool) { // ASCII table: https://www.asciitable.com/
        bytes memory b = bytes(str);
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char == 0x20) && // Space
                !(char == 0x2E) // Dot
            ) return false;
        }
        return true;
    }

    function setDevFeeAddress(address _devFeeAddress) public onlyOwner {
        address devFeeAddressOld = devFeeAddress;
        devFeeAddress = _devFeeAddress;
        emit eventSetDevFeeAddress(devFeeAddressOld, _devFeeAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract ERC721MintMore is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint;
    string private _name;
    string private _symbol;
    mapping(uint => address) private _owners;
    mapping(address => uint) private _balances;
    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        return _balances[owner];
    }

    function ownerOf(uint tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), 'ERC721: owner query for nonexistent token');
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint tokenId) public virtual override {
        address owner = ERC721MintMore.ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), 'ERC721: approve caller is not owner nor approved for all');
        _approve(to, tokenId);
    }

    function getApproved(uint tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), 'ERC721: approved query for nonexistent token');
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from,address to, uint tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), 'ERC721: transfer to non ERC721Receiver implementer');
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        address owner = ERC721MintMore.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(address to, uint tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), 'ERC721: transfer to non ERC721Receiver implementer');
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        address owner = ERC721MintMore.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint tokenId) internal virtual {
        require(ERC721MintMore.ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
        require(to != address(0), 'ERC721: transfer to the zero address');
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721MintMore.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, 'ERC721: approve to caller');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) revert('ERC721: transfer to non ERC721Receiver implementer');
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else return true;
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint tokenId) internal virtual {}

    function _mintMore(address to, uint startTokenID, uint count) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(startTokenID), 'ERC721: token already minted');
        for (uint i = startTokenID; i < startTokenID + count; i++) {
            _beforeTokenTransfer(address(0), to, i);
            _owners[i] = to;
            _afterTokenTransfer(address(0), to, i);
        }
        _balances[to] += count;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Mint {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function mint(uint _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20Mint.sol';
import '@openzeppelin/contracts/utils/Address.sol';

library SafeERC20Mint {
    using Address for address;

    function safeTransfer(IERC20Mint token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Mint token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20Mint token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), 'SafeERC20: approve from non-zero to non-zero allowance');
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Mint token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Mint token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20Mint token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './libs/INFT.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Marketplace is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 currency;
    address devFeeAddress;
    uint16 devFeePercent;
    uint totalDeposits;
    uint totalDeposited;
    uint totalWithdraws;
    uint totalBuys;
    mapping (address => bool) public acceptedContracts;
    mapping (uint => Details) public deposited;
    event eventDeposit(uint indexed _depositID, Deposit indexed _deposit);
    event eventWithdraw(uint indexed _withdrawID, Withdraw indexed _withdraw);
    event eventBuy(uint indexed _buyID, Buy indexed _buy);

    struct Deposit {
        address _addressContract;
        uint _nftID;
        address _owner;
        uint _price;
        uint _timestamp;
    }

    struct Withdraw {
        address _addressContract;
        uint _nftID;
        address _owner;
        uint _price;
        uint _timestamp;
    }

    struct Buy {
        address _addressContract;
        uint _nftID;
        address _ownerPrevious;
        address _ownerNew;
        uint _price;
        uint _timestamp;
    }

    struct Details {
        bool exists;
        address addressContract;
        uint nftID;
        address owner;
        uint price;
    }

    constructor(address _currencyAddress, uint16 _devFeePercent) {
        currency = IERC20(_currencyAddress);
        devFeeAddress = msg.sender;
        devFeePercent = _devFeePercent;
    }
    
    function deposit(address _addressContract, uint _nftID, uint _price) public nonReentrant {
        INFT nft = INFT(_addressContract);
        require(acceptedContracts[_addressContract], 'deposit: this NFT is not accepted by this Marketplace');
        require(nft.ownerOf(_nftID) == msg.sender, 'deposit: You are not the owner of this NFT');
        nft.transfer(msg.sender, address(this), _nftID);
        deposited[totalDeposits] = Details(true, address(nft), _nftID, msg.sender, _price);
        totalDeposits++;
        totalDeposited++;
        emit eventDeposit(totalDeposits, Deposit(_addressContract, _nftID, msg.sender, _price, block.timestamp));
    }

    function withdraw(uint _id) public nonReentrant {
        require(deposited[_id].exists, 'withdraw: Item ID not found');
        require(deposited[_id].owner == msg.sender, 'withdraw: You are not the owner of this NFT');
        INFT nft = INFT(deposited[_id].addressContract);
        nft.transfer(address(this), msg.sender, deposited[_id].nftID);
        delete deposited[_id];
        totalWithdraws++;
        totalDeposited--;
        emit eventWithdraw(totalWithdraws, Withdraw(deposited[_id].addressContract, deposited[_id].nftID, deposited[_id].owner, deposited[_id].price, block.timestamp));
    }

    function buy(uint _id) public nonReentrant {
        INFT nft = INFT(deposited[_id].addressContract);
        require(nft.getApproved(deposited[_id].nftID) != address(0), 'buy: This NFT is not approved');
        require(currency.allowance(msg.sender, address(this)) >= deposited[_id].price, 'buy: Currency allowance is too low');
        currency.safeTransferFrom(msg.sender, address(this), deposited[_id].price);
        currency.safeTransfer(deposited[_id].owner, deposited[_id].price * (10000 - devFeePercent) / 10000);
        currency.safeTransfer(devFeeAddress, deposited[_id].price * devFeePercent / 10000);
        nft.transfer(address(this), msg.sender, deposited[_id].nftID);
        totalBuys++;
        totalDeposited--;
        emit eventBuy(totalBuys, Buy(deposited[_id].addressContract, deposited[_id].nftID, deposited[_id].owner, msg.sender, deposited[_id].price, block.timestamp));
        delete deposited[_id];
    }

    function addAcceptedContract(address _addressContract) public onlyOwner {
        acceptedContracts[_addressContract] = true;
    }

    function setDevFeeAddress(address _devFeeAddress) public onlyOwner {
        devFeeAddress = _devFeeAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

pragma solidity ^0.8.0;

interface INFT {
    struct Property {
        string name;
        uint basicCount;
        uint createdTime;
    }
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
    function totalSupply() external view returns (uint);
    function transfer(address _fromAddress, address _toAddress, uint _nftID) external;
    function nftRename(uint _nftID, string memory _name) external;
    function nftLevelUpgrade(uint _nftID, uint _levels) external;
    function nftSetProperty(uint _nftID, uint _propertyID, uint _value) external;
    function nftHarvestTokenProduct(uint _nftID) external;
    function getTokenProductToHarvest(uint _nftID) external view returns(uint);
    function mint(address _recipient, uint _collectionID, string memory _name, bool _hasParents, uint _parentMaleID, uint _parentFemaleID) external returns (uint);
    function mintMore(address _recipient, uint _collectionID, string memory _name, uint _count) external returns (uint);
    function mintToMarketplace(uint _collectionID, string memory _name, uint _price) external;
    function mintMoreToMarketplace(uint _collectionID, string memory _name, uint _price, uint _count) external;
    function factory(uint _nftMaleID, uint _nftFemaleID, string memory _name) external;
    function getNFTProperty(uint _nftID, uint _propertyID) view external returns (uint);
    function getCollectionProperty(uint _collectionID, uint _propertyID) view external returns (Property memory);
    function collectionAdd(string memory _name, uint _factoryTime, uint _tokenProductEmission, uint _tokenUpgradePriceLevel, uint _tokenUpgradePriceSetProperty, uint _tokenFactoryPrice) external returns (uint);
    function collectionRename(uint _collectionID, string memory _name) external;
    function collectionSetFactoryTime(uint _collectionID, uint _factoryTime) external;
    function collectionSetTokenProductEmission(uint _collectionID, uint _emission) external;
    function collectionSetTokenUpgradePriceLevel(uint _collectionID, uint _price) external;
    function collectionSetTokenUpgradePriceSetProperty(uint _collectionID, uint _price) external;
    function collectionSetTokenFactoryPrice(uint _collectionID, uint _price) external;
    function collectionRemove(uint _collectionID) external;
    function collectionPropertyAdd(uint _collectionID, string memory _name, uint _basicCount) external;
    function collectionPropertyRename(uint _collectionID, uint _propertyID, string memory _name) external;
    function collectionPropertySetBasicCount(uint _collectionID, uint _propertyID, uint _basicCount) external;
    function collectionPropertyRemove(uint _collectionID, uint _propertyID) external;
    function setDevFeeAddress(address _devFeeAddress) external;
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event eventTransfer(address indexed _fromAddress, address indexed _toAddress, uint indexed _nftID);
    event eventNFTRename(uint indexed _nftID, string indexed _nameOld, string indexed _nameNew);
    event eventNFTSetNFTProperty(uint indexed _nftID, uint indexed _valueOld, uint indexed _value);
    event eventNFTLevelUpgrade(uint indexed _nftID, uint indexed _levelOld, uint indexed _levelNew);
    event eventNFTHarvestTokenProduct(uint indexed _nftID, address indexed _toAddress, uint indexed _amount);
    event eventFactory(uint indexed _nftMaleID, uint indexed _nftFemaleID, uint indexed _newID);
    event eventCollectionAdd(uint indexed _collectionID, string indexed _name, uint indexed _tokenProductEmission);
    event eventCollectionRename(uint indexed _collectionID, string indexed _nameOld, string indexed _nameNew);
    event eventCollectionSetFactoryTime(uint indexed _collectionID, uint indexed _factoryTimeOld, uint indexed _factoryTimeNew);
    event eventCollectionSetTokenProductEmission(uint _collectionID, uint indexed _emissionOld, uint indexed _emissionNew);
    event eventCollectionSetTokenUpgradePriceLevel(uint indexed _collectionID, uint indexed _priceOld, uint indexed _price);
    event eventCollectionSetTokenUpgradePriceSetProperty(uint indexed _collectionID, uint indexed _priceOld, uint indexed _price);
    event eventCollectionSetTokenFactoryPrice(uint indexed _collectionID, uint indexed _priceOld, uint indexed _price);
    event eventCollectionRemove(uint indexed _collectionID);
    event eventCollectionPropertyAdd(uint indexed _collectionID, uint indexed _propertyID, string indexed _name);
    event eventCollectionPropertyRename(uint indexed _collectionID, uint indexed _propertyID, string indexed _name);
    event eventCollectionPropertySetBasicCount(uint indexed _collectionID, uint _propertyID, uint _basicCount);
    event eventCollectionPropertyRemove(uint indexed _collectionID, uint indexed _propertyID);
    event eventSetDevFeeAddress(address indexed devFeeAddressOld, address indexed _devFeeAddress);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}