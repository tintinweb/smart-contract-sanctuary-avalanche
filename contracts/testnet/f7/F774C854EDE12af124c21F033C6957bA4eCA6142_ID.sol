// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../Utils/Admin.sol";
import "../Utils/RandomGenerator.sol";

import "./IDStorage.sol";
import "./IDEnumerable.sol";

contract ID is Admin, Pausable, RandomGenerator, IDStorage,IDEnumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter internal  _countriesCounter;
    Counters.Counter internal  _entitiesCounter;
    Counters.Counter internal  _idCounter;

    uint256 public numberLength;
    uint256 public stringLength;
    string  public idSeparator;

    mapping(bytes2  => bytes32) public countries;
    mapping(uint256 => bytes2) public indexCountries;

    mapping(bytes32 => string) public entities;
    mapping(uint256 => bytes32) public indexEntities;

    mapping(bytes32 => Id) public idDB;
    mapping(uint256 => bytes32) public indexId;
    mapping(bytes2 => mapping(bytes32 => Counters.Counter)) public counterParent;

    mapping(bytes32 => mapping (address => bool)) public approvalToId;

    struct Id{  // struct of detail id
        uint256 index;
        bytes2 country;
        bytes32 entity;
        string code;
        address creator;
        uint256 timestamp;
        bool isPrimayId;
    }

    modifier codeExisted(bytes32 _entityCode, bytes2 _countryCode){
        require(bytes(entities[_entityCode]).length != 0 && countries[_countryCode] != bytes32(0), "ID not existed");
        _;
    }

    //pausable ############################
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //country ############################
    function addCountryCode(bytes2 countryCode, bytes32 countryName) whenNotPaused() public onlyAdmin{
        require(countries[countryCode] == bytes32(0), "Country Existed");
        _countriesCounter.increment();

        countries[countryCode] = countryName;
        indexCountries[_countriesCounter.current()] = countryCode;
    }

    function totalCountry() public view returns(uint256){
        return _countriesCounter.current();
    }

    function setCountryCode(bytes2 countryCode,bytes32 countryName) public whenNotPaused onlyAdmin{
        require(countries[countryCode] != bytes32(0), "Country Not Existed");
        countries[countryCode] = countryName;
    }

    function getCountryCode(bytes2 countryCode) public view returns (bytes32) {
        return countries[countryCode];
    }

    //entity ############################
    function addEntityCode(bytes32 entityCode, string memory entityName) whenNotPaused() public onlyAdmin{
        require(bytes(entities[entityCode]).length == 0, "Entity Existed");
        _entitiesCounter.increment();

        entities[entityCode] = entityName;
        indexEntities[_entitiesCounter.current()] = entityCode;
    }

    function totalEntity() public view returns(uint256){
        return _entitiesCounter.current();
    }

    function setEntityCode(bytes32 entityCode, string memory entityName) public whenNotPaused onlyAdmin{
        require(bytes(entities[entityCode]).length == 0, "Entity Not Existed");
        entities[entityCode] = entityName;
    }

    function getEntityCode(bytes32 entityCode) public view returns (string memory) {
        return entities[entityCode];
    }

    //id ############################
    function registerBySelf(
        uint256 _salt,
        bytes32 _entityCode, 
        bytes2 _countryCode
    ) public whenNotPaused() codeExisted(_entityCode, _countryCode) returns(bytes32){
        require(_exists(msg.sender) == false, "not connected to some id");

        //uint256 _salt= 1234;
        return _register(_entityCode, _countryCode, msg.sender, _salt);
    }

    function registerForOther(
        uint256 _salt,
        bytes32 _entityCode, 
        bytes2 _countryCode, 
        address _recipient
    ) public whenNotPaused() codeExisted(_entityCode, _countryCode) returns(bytes32){
        require(_exists(_recipient) == false, "not connected to some id");

        //find sender id
        require(_exists(msg.sender) == true, "sender must connected to some id");
        require(approvalToId[ownerOf(msg.sender)][_recipient] == true, "approval must active"); 

        //uint256 _salt= 1234;
        return _register(_entityCode, _countryCode, _recipient, _salt);
    }

    function registerByAdmin(
        uint256 _salt,
        bytes32 _entityCode, 
        bytes2 _countryCode, 
        address _recipient
    ) public whenNotPaused() codeExisted(_entityCode, _countryCode) onlyAdmin() returns(bytes32){
        require(_exists(_recipient) == false, "not connected to some id");

        //uint256 _salt= 1234;
        return _register(_entityCode, _countryCode, _recipient, _salt);
    }

    function _register(
        bytes32 _entityCode, 
        bytes2 _countryCode, 
        address _address, 
        uint256 _salt
    ) internal returns(bytes32){

        //generate ID
        uint256 nonce = 0;
        bool available = true;
        bytes32 id;
        string memory _idCode;

        while (available == true) {
            _idCode = generateWords(uint256(keccak256(abi.encodePacked(_salt, nonce))), numberLength, stringLength, idSeparator);
            (available,id) = _isIdAvailable(_entityCode, _countryCode, _idCode); //checking availablity
            nonce = nonce.add(1);
        }

        _idCounter.increment();
        idDB[id] = Id(_idCounter.current(),_countryCode,_entityCode, _idCode, _address, block.timestamp, true);
        _registerAddress(id,_address);
        indexId[_idCounter.current()];
        counterParent[_countryCode][_entityCode].increment();

        return id;
    }

    function _isIdAvailable(bytes32 _entityId, bytes2 _countryId, string memory _idCode) 
    internal view returns (bool, bytes32){
        bytes32 id = keccak256(abi.encodePacked(_entityId, _countryId, _idCode));
        if(idDB[id].timestamp == 0){
            return (true, id);
        }
        else{
            return (false, bytes32(0));
        }
    }

    function getCountId(bytes2 _entityCode, bytes2 _countryCode) public view returns (uint256){
        return counterParent[_countryCode][_entityCode].current();
    }

    function getIdDetail(bytes32 _id) public view 
    returns 
    (
        uint256 _index,
        bytes2 _country,
        bytes32 _entity,
        string memory _code,
        address _creator,
        uint256 _timestamp
    ) {
        return(
            idDB[_id].index,
            idDB[_id].country,
            idDB[_id].entity,
            idDB[_id].code,
            idDB[_id].creator,
            idDB[_id].timestamp
        );
    }

    function getAddresses(bytes32 _id) public view returns
    (
        address[] memory _addresses, 
        bool[] memory _stats
    ){
        uint256 amount = balanceOf(_id);

        _addresses = new address[](amount);
        _stats = new bool[](amount);

        for(uint256 i=0; i<amount; i++){
            _addresses[i] = tokenOfOwnerByIndex(_id, i);
            _stats[i] = checkActiveAddress(_addresses[i]);

        }

        return (_addresses, _stats);
    }

    function _approveToId(bytes32 _id, address _addr, bool _stat) internal {        
        approvalToId[_id][_addr] = _stat;
    }

    function _addAddress(address _newAddr, address _sender) internal{
        bytes32 _id = ownerOf(_sender);
        require(approvalToId[_id][_newAddr] == true, "approval must active"); 
        require(_exists(_newAddr) == false, "not connected to some id");

        //approvalToId[_id][_newAddr] = false;
        _registerAddress(_id, _newAddr);
    }

    function _removeAddress(address _addr, address _sender) internal{
        bytes32 _id = ownerOf(_sender);
        require(approvalToId[_id][_addr] == true, "approval must active"); 
        require(_exists(_addr) == true && ownerOf(_addr) == _id, "connected to id");

        //approvalToId[_id][_addr] = false;
        _deleteAddress(_addr);
    }

    function _setStatus(address _addr, bool _stat) internal{
        _setStatusAddress(_addr, _stat);
    }

    function _setExpTime(address _addr, uint256 _expTime) internal{
        _setExpTimeAddress(_addr,_expTime);
    }













    //ID Storage Data
    function _registerAddress(bytes32 to, address tokenId) internal {
        _safeMint(to, tokenId);
    }

    function _deleteAddress(address tokenId) internal {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(bytes32 from, bytes32 to, address tokenId, uint256 batchSize)
        internal
        override(IDStorage, IDEnumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RandomGenerator{
    using SafeMath for uint256;
    bytes public chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    function generateNumber(uint256 _salt, uint256 _range) public view returns(uint256 result, uint256 MIN_NUMBER, uint256 MAX_NUMBER){
        require(_range >= 1, "Length cannot be Zero");
        MIN_NUMBER = 10 ** (_range.sub(1));
        MAX_NUMBER = (MIN_NUMBER.mul(10)).sub(1);

        uint256 seed;
        for(uint256 i=0; i<1000; i++){
            seed = uint256(keccak256(abi.encodePacked(
                _salt,
                blockhash(block.number.sub(1)),
                block.number.sub(1),
                block.chainid,
                block.timestamp, 
                msg.sender,
                address(this),
                i
            )));
            seed = seed.mod(MAX_NUMBER);

            if (seed <= MAX_NUMBER) {
                // Exit loop with break
                break;
            }
        }

        if(seed < MIN_NUMBER){ //if under minimum number
            seed = seed.add(MIN_NUMBER);
        }

        require(seed <= MAX_NUMBER && seed >= MIN_NUMBER, "Error Generate Number, Please Try Again");

        return (seed, MIN_NUMBER, MAX_NUMBER);
    }

    function randomIndex(uint256 number, uint256 _salt) internal view returns (uint256){
            
            uint256 result; 
            for(uint256 i=0; i<1000; i++){
                result = uint256(
                    keccak256(
                        abi.encodePacked(
                            _salt,
                            blockhash(block.number.sub(1)),
                            block.number.sub(1),
                            block.chainid,
                            block.timestamp, 
                            msg.sender,
                            address(this)
                        )
                    )
                ).mod(number);

                if (result < number) {
                    // Exit loop with break
                    break;
                }
            }

            require(result < number, "Error Random Number, Please Try Again");
            return result;
    }

    function generateString(uint256 _salt, uint256 _range) public view returns(string memory){
        require(_range >= 1, "Length cannot be Zero");
        bytes memory randomWord = new bytes(_range);
        for (uint256 i = 0; i < _range; i++) {
            randomWord[i] = chars[randomIndex(chars.length, uint256(keccak256(abi.encodePacked(i, _salt))))];
        }
        return string(randomWord);
    }

    function generateWords(
        uint256 _salt, 
        uint256 _rangeNumber, 
        uint256 _rangeString, 
        string memory _separator
    ) public view returns(string memory){
        (uint256 number,,) = generateNumber(_salt, _rangeNumber);
        string memory words = generateString(_salt, _rangeString);

        return string.concat(
            Strings.toString(number),
            _separator,
            words);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Admin is Ownable{
    event AddAdminLog(address indexed newAdmin);
    event RemoveAdminLog(address indexed removedAdmin);
    address[] admin;
    mapping(address=>bool) records;
    
    /**
    * @dev Modifier to check if function called by registered admins.
    */
    modifier onlyAdmin(){
        require(records[msg.sender]==true, "msg.sender must be admin");
        _;
    }

    /**
    * @dev Constructor. Set the creator of the contract as one of admin.
    */
    constructor() {
        admin.push(msg.sender);
        records[msg.sender] = true;
    }
    
    /**
    * @dev function to add new admin.
    * @param _address Address of new admin.
    */
    function addAdmin(address _address) onlyOwner() external {
        if (!records[_address]) {
            admin.push(_address);
            records[_address] = true;
            emit AddAdminLog(_address);
        }
    }

    /**
    * @dev function to remove an admin
    * @param _address Address of the admin that is going to be removed.
    */
    function removeAdmin(address _address) onlyOwner() external{
        for (uint i = 0; i < admin.length; i++) {
            if (admin[i] == _address) {
                delete admin[i];
                records[_address] = false;
                emit RemoveAdminLog(_address);
            }
        }
    }

    /**
    * @dev function to check whether the address is registered admin or not
    * @param _address Address to be checked.
    */
    function isAdmin(address _address) public view returns(bool) {
        return records[_address];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract IDStorage {
    //token id => address (user)
    //owner => bytes32 (did)

    // Mapping from token ID to owner address
    mapping(address => bytes32) private _owners;

    // Mapping owner address to token count
    mapping(bytes32 => uint256) private _balances;

    mapping (address => bool) private _statusAddress;
    mapping (address => uint256) private _expiredTime;

    function statusAddress(address _tokenId) public view returns(bool){
        return _statusAddress[_tokenId];
    }

    function expTimeAddress(address _tokenId) public view returns(uint256){
        return _expiredTime[_tokenId];
    }

    function _setStatusAddress(address _tokenId, bool _stat) internal{
        _statusAddress[_tokenId] = _stat;
    }

    function _setExpTimeAddress(address _tokenId, uint256 _expTime) internal{
        _expiredTime[_tokenId] = _expTime;
    }
    
    function checkActiveAddress(address _tokenId) public view returns(bool){
        bool stat = statusAddress(_tokenId);
        uint256 expTime = expTimeAddress(_tokenId);

        if(stat == true && expTime == 0) return true; //active without expirity
        else if(stat == true && expTime > block.timestamp) return true; //active with expirity
        else return false; 
    }

    function balanceOf(bytes32 owner) public view returns (uint256) {
        require(owner != bytes32(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(address tokenId) public view returns (bytes32) {
        bytes32 owner = _ownerOf(tokenId);
        require(owner != bytes32(0), "ERC721: invalid token ID");
        return owner;
    }

    function _ownerOf(address tokenId) internal view virtual returns (bytes32) {
        return _owners[tokenId];
    }

    function _exists(address tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != bytes32(0);
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(bytes32 to, address tokenId) internal virtual {

        _mint(to, tokenId);
        // require(
        //     _checkOnERC721Received(address(0), to, tokenId, data),
        //     "ERC721: transfer to non ERC721Receiver implementer"
        // );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(bytes32 to, address tokenId) internal virtual {
        require(to != bytes32(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(bytes32(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        //_setExpTimeAddress(tokenId, 0);
        _setStatusAddress(tokenId, true);

        //emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(bytes32(0), to, tokenId, 1);
    }

    function _burn(address tokenId) internal virtual {
        bytes32 owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, bytes32(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId);


        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        _setExpTimeAddress(tokenId, 0);
        _setStatusAddress(tokenId, false);

        //emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, bytes32(0), tokenId, 1);
    }

    function _beforeTokenTransfer(bytes32 from, bytes32 to, address firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(bytes32 from, bytes32 to, address firstTokenId, uint256 batchSize) internal virtual {}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IDStorage.sol";

abstract contract IDEnumerable is IDStorage {
    //token id => address (user)
    //owner => bytes32 (did)

    // Mapping from owner to list of owned token IDs
    mapping(bytes32 => mapping(uint256 => address)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(address => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    address[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(address => uint256) private _allTokensIndex;



    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(bytes32 owner, uint256 index) public view virtual  returns (address) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual  returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual  returns (address) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        bytes32 from,
        bytes32 to,
        address firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        address tokenId = firstTokenId;

        if (from == bytes32(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == bytes32(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(bytes32 to, address tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(address tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(bytes32 from, address tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            address lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(address tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        address lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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