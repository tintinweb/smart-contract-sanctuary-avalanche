//Arkius Public Benefit Corporation Privileged & Confidential
//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import './interfaces/IArkiusMembershipToken.sol';
import './NFTs/AttentionSeekerTokenUpgradeable.sol';
import './utils/Blacklistable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ArkiusAttentionSeekerTokenUpgradeable is Initializable, UUPSUpgradeable, AttentionSeekerTokenUpgradeable, Blacklistable {

    event CreateERC1155_v1(address indexed creator, string name, string symbol);

    event UpdateMembership(address membershipAddress);

    IArkiusMembershipToken private membershipToken;

    uint256 constant INVALID = 0;

    /// @dev Contains Id of all seekers.
    uint256[] private allSeekers;

    /// @dev mapping from seekerId => index of allSeekers.
    mapping(uint256 => uint256) private indexAllSeekers;

    string public constant name = "Arkius Attention Seeker Token";
    string public constant symbol = "AST";


    function initialize(string memory          contractURI,
                        string memory          tokenURIPrefix,
                        IArkiusMembershipToken memberNFTAddress,
                        address                blacklistContractAddress,
                        address                multisigAddress
            ) public initializer {

        __AttentionSeekerToken_init(contractURI, tokenURIPrefix, multisigAddress);
        __Blacklistable_init(blacklistContractAddress);

        membershipToken = memberNFTAddress;

        emit CreateERC1155_v1(msg.sender, name, symbol);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function mint(string calldata uri) external notBlacklisted {

        uint id = membershipToken.memberIdOf(_msgSender());
        require(id != INVALID, "Not an Arkius Member");

        allSeekers.push(id);
        indexAllSeekers[id] = allSeekers.length;

        super.mint(id, 1, uri);
    }

    function burn(address owner, uint256 value) external notBlacklisted {

        require(_msgSender() == owner || _msgSender() == address(membershipToken), "Not Authorised to burn");

        uint256 seekerId = _attentionSeekerIdOf(owner);

        if (seekerId > 0) {
            allSeekers[indexAllSeekers[seekerId] - 1] = allSeekers[allSeekers.length - 1];
            indexAllSeekers[allSeekers[allSeekers.length - 1]] = indexAllSeekers[seekerId];
            indexAllSeekers[seekerId] = 0;
            allSeekers.pop();
        }

        _burn(owner, value);
    }

    function updateMembership(IArkiusMembershipToken membershipTokenAddress) public onlyOwner {
        membershipToken = membershipTokenAddress;
        emit UpdateMembership(address(membershipTokenAddress));
    }

    function membershipAddress() public view returns(IArkiusMembershipToken) {
        return membershipToken;
    }

    function getAllSeekers() public view returns(uint256[] memory) {
        return allSeekers;
    }

    function updateBlacklistContract(IBlacklist _newBlacklist) external override onlyOwner {
        require(
            address(_newBlacklist) != address(0),
            "Blacklistable: new blacklist is the zero address"
        );

        blacklistContract = _newBlacklist;
        emit BlacklistContractChanged(address(_newBlacklist));
    }

}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IArkiusMembershipToken {
    function memberIdOf(address owner) external view returns (uint256);
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import './ERC1155BaseAttentionSeekerUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AttentionSeekerTokenUpgradeable is Initializable, ERC1155BaseAttentionSeekerUpgradeable {

    function __AttentionSeekerToken_init(string memory contractURI,
                                         string memory tokenURIPrefix,
                                         address       multisigAddress) internal initializer  {

        
        __ERC1155BaseAttentionSeeker_init(contractURI, tokenURIPrefix, multisigAddress);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    /**
     *  @dev see {ERC1155BaseAttentionSeeker - _mint}
     */
    function mint(uint256 id, uint256 supply, string memory uri) internal {
        _mint(id, supply, uri);
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;
import "../interfaces/IBlacklist.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Blacklistable is Initializable {

    IBlacklist public blacklistContract;

    event BlacklistContractChanged(address newBlacklist);

    function __Blacklistable_init(address blacklist) internal initializer {
        require(blacklist != address(0), "Blacklistable: Invalid contract address");
        blacklistContract = IBlacklist(blacklist);
    }

    /**
     * @dev Throws if argument account is blacklisted
     */
    modifier notBlacklisted() {
        require(
            !blacklistContract.isBlacklisted(msg.sender),
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    function updateBlacklistContract(IBlacklist _newBlacklist) external virtual;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import './ERC1155Metadata_URIUpgradeable.sol';
import './HasContractURIUpgradeable.sol';
import './ERC1155AttentionSeekerUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC1155BaseAttentionSeekerUpgradeable is Initializable, ERC1155Metadata_URIUpgradeable, HasContractURIUpgradeable, ERC1155AttentionSeekerUpgradeable {

    /// @dev Contains the mapping from TokenId => user who created that token.
    mapping (uint256 => address) private creators;

    function __ERC1155BaseAttentionSeeker_init(string memory contractURI, 
                                                string memory tokenURIPrefix,
                                                address multisigAddress) internal initializer {

            __HasContractURI_init(contractURI);
            __ERC1155Metadata_URI_init(tokenURIPrefix);
            __ERC1155AttentionSeeker_init(multisigAddress);
    }

    /**
    *  @dev Transfer the token from address(0) to the caller address.
    *
    *  @param id      Id of the token that is to be generated.
    *  @param supply  The amount of token to be minted.
    *  @param uri     Uri of the token to store its metadata
    *
    * It Emits {TransferSingle} and {URI} after successful minting
    */
    function _mint(uint256 id, uint256 supply, string memory uri) internal {

        require(id     != 0, "Invalid token ID");
        require(supply != 0, "Supply should be positive");
        require(bytes(uri).length > 0, "Uri should be set");
        require(creators[id] == address(0), "Token is already minted");
        require(attentionSeekerIDs[_msgSender()] == 0, "AttentionSeekerID is already minted for this user");

        creators[id] = _msgSender();
        balances[id][_msgSender()] = supply;
        attentionSeekerIDs[_msgSender()] = id;

        _setTokenURI(id, uri);

        // Transfer event with mint semantic
        emit TransferSingle(_msgSender(), address(0x0), _msgSender(), id, supply);
        emit URI(uri, id);
    }

    /**
     * @dev Transfer the NFT of the caller at address(0).
     * The caller will no longer hold the NFT this particular NFT.
     *
     * @param owner Owner of the NFT that is to be burned.
     * @param value Amount of NFT to be burned.
     *
     * Emits {TransferSingle} after the token is burned.
     */
    function _burn(address owner, uint256 value) internal {

        uint256 id =  _attentionSeekerIdOf(owner);
        require(balances[id][owner] > 0, "You don't posses attention seeker token");
        require(value == 1, "Only 1 Token can be burned");
        
        balances[id][owner]       = 0;
        attentionSeekerIDs[owner] = 0;
        creators[id]              = address(0);

        emit TransferSingle(_msgSender(), owner, address(0), id, value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.

     * @param tokenId uint256 ID of the token to set its URI
     * @param uri     string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal override {
        require(creators[tokenId] != address(0), "_setTokenURI: Token should exist");
        super._setTokenURI(tokenId, uri);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    function creator(uint256 id) public view returns(address) {
        return creators[id];
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import '../interfaces/IERC1155Metadata_URI.sol';
import './HasTokenURIUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
contract ERC1155Metadata_URIUpgradeable is Initializable, IERC1155Metadata_URI, HasTokenURIUpgradeable {

    function __ERC1155Metadata_URI_init(string memory tokenURIPrefix) internal initializer {
        __HasTokenURI_init(tokenURIPrefix);
    }

    function uri(uint256 id) external override view returns (string memory) {
        return _tokenURI(id);
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import './ERC165Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract HasContractURIUpgradeable is Initializable, ERC165Upgradeable {

    string private _contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant interfaceIdContractUri = 0xe8a3d485;

    function __HasContractURI_init(string memory contractUri) internal initializer {
        _contractURI = contractUri;
        _registerInterface(interfaceIdContractUri);
    }

    function contractURI() public view returns(string memory) {
        return _contractURI;
    }

    /**
     * @dev Internal function to set the contract URI
     * @param contractUri string URI prefix to assign
     */
    function _setContractURI(string memory contractUri) internal {
        _contractURI = contractUri;
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import '../interfaces/IERC1155.sol';
import '../interfaces/ERC1155TokenReceiver.sol';
import './CommonConstants.sol';
import './ERC165Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// A sample implementation of core ERC1155 function.
contract ERC1155AttentionSeekerUpgradeable is Initializable, OwnableUpgradeable, IERC1155, ERC165Upgradeable, CommonConstants {
    
    using AddressUpgradeable for address;

    /// @dev mapping from tokenId => (tokenOwner => amount of tokenId at tokenOwner address)
    mapping(uint256 => mapping(address => uint256)) internal balances;

    /// @dev mapping from ownerAddress => tokenId
    mapping(address => uint256) internal attentionSeekerIDs;

    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /////////////////////////////////////////// CONSTRUCTOR //////////////////////////////////////////

    function __ERC1155AttentionSeeker_init(address multisigAddress) internal initializer {

        __Ownable_init();

        _registerInterface(INTERFACE_SIGNATURE_ERC1155);

        _transferOwnership(multisigAddress);
    }

    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
     * @notice Transfers `value` amount of an `id` from the `_from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section
     * of the standard).
     * 
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so,
     * it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * 
     * @param from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(address      from,
                              address      to,
                              uint256      id,
                              uint256      value,
                              bytes memory data) internal override {

        require(to != address(0), "to must be non-zero.");
        require(from == _msgSender(), "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if id is not valid (balance will be 0)
        balances[id][from] = balances[id][from] - value;
        balances[id][to]   = value + balances[id][to];

        // MUST emit event
        emit TransferSingle(_msgSender(), from, to, id, value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (to.isContract()) {
            _doSafeTransferAcceptanceCheck(_msgSender(), from, to, id, value, data);
        }
    }

    /**
     * @notice Transfers `values` amount(s) of `ids` from the `_from` address to the `to` address specified
     *      (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account 
     *      (see "Approval" section of the standard).
     * 
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `ids` is not the same as length of `values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * 
     * Balance changes and events MUST follow the ordering of the arrays (ids[0]/values[0] before ids[1]/values[1], etc).
     * 
     * After the above conditions for the transfer(s) in the batch are met, 
     *      this function MUST check if `to` is a smart contract (e.g. code size > 0).
     * If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * 
     * @param from    Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match values array)
     * @param values  Transfer amounts per token type (order and length must match ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(address          from,
                                   address          to,
                                   uint256[] memory ids, 
                                   uint256[] memory values, 
                                   bytes     memory data) internal override {

        // MUST Throw on errors
        require(to != address(0), "destination address must be non-zero.");
        require(ids.length == values.length, "_ids and values array lenght must match.");
        require(from == _msgSender(), "No 3rd party transfers.");

        for (uint256 idx = 0; idx < ids.length; ++idx) {
            uint256 id = ids[idx];
            uint256 value = values[idx];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][from] = balances[id][from] - value;
            balances[id][to]    = value + balances[id][to];
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(_msgSender(), from, to, ids, values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(_msgSender(), from, to, ids, values, data);
        }
    }

    /**
     * @notice Get the balance of an account's Tokens.
     * @param owner  The address of the token holder.
     * @param id     ID of the Token.
     * @return       The owner's balance of the Token type requested.
     */
    function balanceOf(address owner, uint256 id) external override view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[id][owner];
    }

    /**
     * @notice Get the Member ID of an account.
     * 
     * @param owner  The address of the token holder.
     * @return       The owner's balance of the Token type requested.
     */
    function attentionSeekerIdOf(address owner) external view returns (uint256) {
        
        uint256 id = _attentionSeekerIdOf(owner);
        return id;
    }

    function _attentionSeekerIdOf(address owner) internal view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return attentionSeekerIDs[owner];
    }


    /**
     * @notice Get the balance of multiple account/token pairs
     * @param owners The addresses of the token holders
     * @param ids  ID of the Tokens
     * @return     The owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
             external override view returns (uint256[] memory) {

        require(owners.length == ids.length);

        uint256[] memory balancesBatch = new uint256[](owners.length);

        for (uint256 idx = 0; idx < owners.length; ++idx) {
            balancesBatch[idx] = balances[ids[idx]][owners[idx]];
        }

        return balancesBatch;
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address      operator,
                                            address      from,
                                            address      to,
                                            uint256      id,
                                            uint256      value,
                                            bytes memory data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(to).supportsInterface(0x4e2312e0) here,
        //     but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. to isn't a receiver, 
        //     or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


        // Note: if the below reverts in the onERC1155Received function of the to address you will have an undefined revert 
        //     reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level to.call() style instead so
        //     the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(ERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address          operator,
                                                 address          from,
                                                 address          to,
                                                 uint256[] memory ids, 
                                                 uint256[] memory values, 
                                                 bytes     memory data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(to).supportsInterface(0x4e2312e0) here,
        //     but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. to isn't a receiver, 
        //     or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the to address you will have an undefined 
        //     revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level to.call() style instead,
        //     so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(ERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import '../utils/StringLibrary.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract HasTokenURIUpgradeable is Initializable {

    using StringLibrary for string;

    //Token URI prefix
    string private _tokenURIPrefix;

    // Optional mapping for token URIs
    mapping(uint256 => string) private tokenURIs;

    function __HasTokenURI_init(string memory tokenUriPrefix) internal initializer {
        _tokenURIPrefix = tokenUriPrefix;
    }

    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function tokenURIPrefix() public view returns(string memory) {
        return _tokenURIPrefix;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return _tokenURIPrefix.append(tokenURIs[tokenId]);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param tokenUriPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory tokenUriPrefix) internal {
        _tokenURIPrefix = tokenUriPrefix;
    }

    function _clearTokenURI(uint256 tokenId) internal {
        if (bytes(tokenURIs[tokenId]).length != 0) {
            delete tokenURIs[tokenId];
        }
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

import './UintLibrary.sol';

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

//SPDX-License-Identifier:None
pragma solidity ^0.8.2;

import '../interfaces/IERC165.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165Upgradeable is Initializable, IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant interfaceIdERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private supportedInterfaces;

    function __ERC165_init() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(interfaceIdERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        supportedInterfaces[interfaceId] = true;
    }
}

//SPDX-License-Identifier:None
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

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

import './IERC165.sol';

/**
 * @title ERC-1155 Multi Token Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
 * Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
abstract contract IERC1155 is IERC165 {
    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, 
     *      including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `operator` argument MUST be msg.sender.
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `to` argument MUST be the address of the recipient whose balance is increased.
     * The `id` argument MUST be the token type being transferred.
     * The `value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient 
     *      balance is increased by.
     * 
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed operator, address indexed _from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers 
     *      as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `operator` argument MUST be msg.sender.
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `to` argument MUST be the address of the recipient whose balance is increased.
     * The `ids` argument MUST be the list of tokens being transferred.
     * The `values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) 
     *      the holder balance is decreased by and match what the recipient balance is increased by.
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed operator, address indexed _from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev MUST emit when the URI is updated for a token ID.
     * URIs are defined in RFC 3986.
     * The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string value, uint256 indexed id);

    /**
     * @notice Transfers `value` amount of an `id` from the `_from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account 
     *      (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). 
     *      If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(address _from, address to, uint256 id, uint256 value, bytes memory data) internal virtual;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `to` address specified 
     *      (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account 
     *      (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `_ids` is not the same as length of `_values`.
     * UST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) 
     *      in `_values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected 
     *      (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract 
     *      (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately 
     *      (see "Safe Transfer Rules" section of the standard).
     * 
     * @param _from   Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match _values array)
     * @param values  Transfer amounts per token type (order and length must match _ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(address _from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal virtual;

    /**
     * @notice Get the balance of an account's Tokens.
     * @param owner  The address of the token holder
     * @param id     ID of the Token
     * @return       The _owner's balance of the Token type requested
     */
    function balanceOf(address owner, uint256 id) external virtual view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param owners The addresses of the token holders
     * @param ids    ID of the Tokens
     * @return       The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external virtual view returns (uint256[] memory);

}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;


/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param sender    The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return         `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address operator, address sender, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param sender    The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param data      Additional data with no specified format
        @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address operator, address sender, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

contract CommonConstants {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; 

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier:None
pragma solidity ^0.8.0;

interface IBlacklist {

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}