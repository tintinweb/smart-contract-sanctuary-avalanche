// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "./IDealStruct.sol";

interface IDealClient is IDealStruct {
    // struct DealRequest {
    //     bytes piece_cid;
    //     uint64 piece_size;
    //     bool verified_deal;
    //     string label;
    //     int64 start_epoch;
    //     int64 end_epoch;
    //     uint256 storage_price_per_epoch;
    //     uint256 provider_collateral;
    //     uint256 client_collateral;
    //     uint64 extra_params_version;
    //     ExtraParamsV1 extra_params;
    // }

    // // Extra parameters associated with the deal request. These are off-protocol flags that
    // // the storage provider will need.
    // struct ExtraParamsV1 {
    //     string location_ref;
    //     uint64 car_size;
    //     bool skip_ipni_announce;
    //     bool remove_unsealed_copy;
    // }

    // struct ProviderSet {
    //     bytes provider;
    //     bool valid;
    // }

    // struct RequestId {
    //     bytes32 requestId; // requestId is randomly generated
    //     bool valid;
    // }

    // /// @notice status of deal
    // enum Status {
    //     None,
    //     RequestSubmitted,
    //     DealPublished,
    //     DealActivated,
    //     DealTerminated
    // }

    // /**
    //  * @notice emitted when new deal proposal is created
    //  */
    // event DealProposalCreate(bytes32 indexed id, uint64 size, bool indexed verified, uint256 price);

    // event BalanceAdded(uint256 amount);

    function makeDealProposal(DealRequest calldata deal) external returns (bytes32);

    function addBalance(uint256 value) external;

    function withdrawBalance(address client, uint256 value) external returns (uint);

    function getDealId(bytes calldata cid) external view returns (uint64);

    function getPieceStatus(bytes calldata cid) external view returns (Status);

    function getProviderSet(bytes calldata cid) external view returns (ProviderSet memory);

    function getProposalIdSet(bytes calldata cid) external view returns (RequestId memory);

    function dealsLength() external view returns (uint256);

    function getDealByIndex(uint256 index) external view returns (DealRequest memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IDealStruct {
    struct DealRequest {
        bytes piece_cid;
        uint64 piece_size;
        bool verified_deal;
        string label;
        int64 start_epoch;
        int64 end_epoch;
        uint256 storage_price_per_epoch;
        uint256 provider_collateral;
        uint256 client_collateral;
        uint64 extra_params_version;
        ExtraParamsV1 extra_params;
    }

    // Extra parameters associated with the deal request. These are off-protocol flags that
    // the storage provider will need.
    struct ExtraParamsV1 {
        string location_ref;
        uint64 car_size;
        bool skip_ipni_announce;
        bool remove_unsealed_copy;
    }

    struct ProviderSet {
        bytes provider;
        bool valid;
    }

    struct RequestId {
        bytes32 requestId; // requestId is randomly generated
        bool valid;
    }

    /// @notice status of deal
    enum Status {
        None,
        RequestSubmitted,
        DealPublished,
        DealActivated,
        DealTerminated
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Deal/IDealClient.sol";
import "../Deal/IDealStruct.sol";
// import "../data-segment/Proof.sol";
// import "./IAggregatorOracle.sol";
// import { Cid } from "../data-segment/Cid.sol";

error ETHER_TRANSFER_FAILED();
error ERC20_TRANSFER_FAILED();
error FUNCTION_LOCKED();
error ONLY_ONWER_CAN_CALL();
error ONLY_WHITELIST_CAN_CALL();
error ALREADY_WHITELISTED();
error NOT_WHITELISTED();

contract Storage is IDealStruct {
    ///@notice address of the dealClient contract
    IDealClient private dealClient;

    /// @notice address of the treasury contract
    address private treasury;

    /// @notice value of locked for reentrancy security
    uint256 private locked;

    /// @notice address of the owner
    address private owner;

    /// @notice Variable to store the total number of storage bundles
    uint256 private bundleStoreID;

    /**
     * @notice modifier to save from the reentrancy attack
     */
    modifier noReentrant() {
        if (locked != 0) {
            revert FUNCTION_LOCKED();
        }

        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @notice modifier to check that only the owner can call the function
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ONLY_ONWER_CAN_CALL();
        }
        _;
    }

    /**
     * @dev modifier to allow only whitelisted addresses and owner address to call the function
     */
    modifier onlyAllowList() {
        if (!(whiteListed[msg.sender]) && msg.sender != owner) {
            revert ONLY_WHITELIST_CAN_CALL();
        }
        _;
    }

    /**
     * @notice struct to store the details of the file
     */
    struct Content {
        address user;
        bytes cid;
        bytes config;
        bytes fileName;
        uint256 fileSize;
    }

    /**
     * @notice struct to store data of the user
     */
    struct UserStorage {
        uint256 totalStored;
        bytes[] cids;
    }

    /**
     * @notice Emitted when bundle storage passes
     */
    event BundleStorageRequest(
        uint256 indexed id,
        uint256 blocknumber,
        address indexed uploader,
        bool didAllSuceed,
        Content[] contents
    );

    /**
     * @notice emitted when new deal proposal is created
     */
    event DealProposalCreate(
        bytes indexed pieceCid,
        uint64 pieceSize,
        bool indexed verified,
        string label,
        int64 startEpoch,
        int64 endEpoch,
        string locationRef,
        uint64 carSize
    );

    /**
     * @notice emit when balance is added to
     * @param amount amount of tokens
     */
    event BalanceAdded(uint256 amount);

    /**
     * @notice Mapping to track the data stored by the user
     */
    mapping(address => UserStorage) public storageList;

    /**
     * @notice mapping to keep track of whitelisted addresses
     */
    mapping(address => bool) public whiteListed;

    /// @notice txIdToCid maps transaction ID to the CID
    mapping(uint256 => bytes) private txIdToCid;

    /// @notice cidToDealIds maps CID to deal IDs
    mapping(bytes => uint64[]) private cidToDealIds;

    /**
     * @notice constructor to set the initial value
     * @param _treasury address of the treasury contract
     * @param _owner address of the owner
     */
    constructor(address _treasury, address _owner /* , address _dealClientAddr */) {
        treasury = _treasury;
        owner = _owner;
        // dealClient = IDealClient(_dealClientAddr);
    }

    ///             STORAGE CONTRACT CORE ///////////////////
    /**
     * @notice function to keep an on-chain record of Bundle Storage Requests
     * @dev inputs are in bytes form, not in string form
     * @param _contents details of the files that will be stored in Filecoin
     */
    function bundleStore(Content[] calldata _contents) external onlyAllowList {
        uint256 length = _contents.length;
        for (uint256 i = 0; i < length; ) {
            updateStorage(_contents[i].user, _contents[i].fileSize, _contents[i].cid);
            unchecked {
                ++i;
            }
        }
        // increase the number of BundleStore
        unchecked {
            ++bundleStoreID;
        }
        emit BundleStorageRequest(bundleStoreID, block.number, msg.sender, true, _contents);
    }

    /**
     *  @notice This function modifies a user's storage balance based on any file update and updates the list of CIDs associated with that user.
     *  @param _user user Address
     *  @param _filesize size of the file
     *  @param _cid CID of the file
     */
    function updateStorage(address _user, uint256 _filesize, bytes calldata _cid) private {
        storageList[_user].cids.push(_cid);
        storageList[_user].totalStored = storageList[_user].totalStored + (_filesize);
    }

    /**
     * @notice function to whitelist an address
     * @param _address address we want to whitelist
     */
    function addWhitelistAddress(address _address) external onlyOwner {
        if (whiteListed[_address]) {
            revert ALREADY_WHITELISTED();
        }
        whiteListed[_address] = true;
    }

    /**
     * @notice function to remove the address from whitelist
     * @param _address address we want to remove from whitelist
     */
    function removeWhitelistAddress(address _address) external onlyOwner {
        if (!whiteListed[_address]) {
            revert NOT_WHITELISTED();
        }
        whiteListed[_address] = false;
    }

    /**
     * @notice function to transfer Storage contract funds to endowment and Treasaury
     * @param _endow address of endowment contract
     * @param _token address of the token
     */
    function transferTo(address _endow, address _token) public noReentrant {
        IERC20 token = IERC20(_token);
        transferToTreasury(_token);
        if (!token.transfer(_endow, token.balanceOf(address(this)))) {
            revert ERC20_TRANSFER_FAILED();
        }
    }

    /////////////////////

    ///                 TREASURY CONTRACT INTERACTION       ///////////
    /**
     * @notice function to transfer tokens to Treasury
     * @param _token address of the token
     */
    function transferToTreasury(address _token) private {
        IERC20 token = IERC20(_token);
        uint treasuryAmount = (token.balanceOf(address(this)) * 25) / 100;
        if (!token.transfer(treasury, treasuryAmount)) {
            revert ERC20_TRANSFER_FAILED();
        }
    }

    /**
     * @notice function to update the address of Treasury contract
     * @param _treasury address of Treasury contract
     */
    function updateTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    ///////////////

    ///                 DEAL CLIENT CONTRACT INTERACTION       ///////////
    /**
     * @notice function to update the address of dealClient contract
     * @param _dealContract address of the new dealClient contract
     */
    function updateDealClient(address _dealContract) public onlyOwner {
        dealClient = IDealClient(_dealContract);
    }

    /**
     * @notice function to create deal proposal for storing data
     * @param deal metadata of deal data
     */
    function makeStorageProposal(DealRequest calldata deal) public {
        dealClient.makeDealProposal(deal);
        emit DealProposalCreate(
            deal.piece_cid,
            deal.piece_size,
            deal.verified_deal,
            deal.label,
            deal.start_epoch,
            deal.end_epoch,
            deal.extra_params.location_ref,
            deal.extra_params.car_size
        );
    }

    /**
     * @notice This function is designed to fund the built-in storage market actor's escrow using funds from the dealClient contract's own balance.
     * @dev dealClient contract should have more balance than the value
     * @param _amount amount of tokens
     */
    function addDealClientBalance(uint _amount) public {
        dealClient.addBalance(_amount);
        emit BalanceAdded(_amount);
    }

    // /////////////////////////
    ///                 AGGREGATOR CONTRACT INTERACTION       ///////////
    /**
     * @notice function to create deal proposal for storing data on Aggreagator side
     * @param deal metadata of deal data
     */
    function aggregatorStorage(DealRequest calldata deal) public {
        emit DealProposalCreate(
            deal.piece_cid,
            deal.piece_size,
            deal.verified_deal,
            deal.label,
            deal.start_epoch,
            deal.end_epoch,
            deal.extra_params.location_ref,
            deal.extra_params.car_size
        );
    }

    // /**
    //  * @dev complete is a callback function that is called by the aggregator
    //  * @param _id is the transaction ID
    //  * @param _dealId is the deal ID
    //  * @param _proof is the inclusion proof
    //  * @param _verifierData is the verifier data
    //  * @return the aux data
    //  */
    // function complete(
    //     uint256 _id,
    //     uint64 _dealId,
    //     InclusionProof memory _proof,
    //     InclusionVerifierData memory _verifierData
    // ) external returns (InclusionAuxData memory) {
    //     // Emit the event
    //     emit CompleteAggregatorRequest(_id, _dealId);

    //     // save the _dealId if it is not already saved
    //     bytes memory cid = txIdToCid[_id];
    //     for (uint i = 0; i < cidToDealIds[cid].length; ) {
    //         if (cidToDealIds[cid][i] == _dealId) {
    //             return this.computeExpectedAuxData(_proof, _verifierData);
    //         }
    //         unchecked {
    //             ++i;
    //         }
    //     }
    //     cidToDealIds[cid].push(_dealId);

    //     // Perform validation logic
    //     // return this.computeExpectedAuxDataWithDeal(_dealId, _proof, _verifierData);
    //     return this.computeExpectedAuxData(_proof, _verifierData);
    // }

    ///////////////////////////////////

    // --------- Getter Functions ----------

    /**
     * @notice function to get the token balance of the contract
     * @param _token address of the token
     */
    function getErc20Balance(address _token) public view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice view total Bundle created
     */
    function getTotalBundle() external view returns (uint256) {
        return bundleStoreID;
    }

    /**
     * @notice get the CIDs store by the user
     * @dev output is in bytes form, not in string
     * @param _user address of the user
     */
    function getUserCids(address _user) external view returns (bytes[] memory) {
        return storageList[_user].cids;
    }

    /**
     * @notice get the total amount storage used by user
     * @param _user addres of the user
     */
    function getUserStorage(address _user) external view returns (uint256) {
        return storageList[_user].totalStored;
    }

    /**
     * @notice check whether this address is whitelisted
     * @param _user address of the user
     */
    function checkWhiteAddress(address _user) external view returns (bool) {
        return whiteListed[_user];
    }

    /**
     * @notice get the address of the treasury contract
     */
    function getTreasury() external view returns (address) {
        return treasury;
    }

    /**
     * @notice get the address of the owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @notice get the current lock value
     * ! @dev can be removed
     */
    function getLockedValue() external view returns (uint256) {
        return locked;
    }

    /**
     * @notice function to get the address of the deal client contract
     */
    function getDealClient() external view returns (address) {
        return address(dealClient);
    }

    /**
     * @notice function to get the deal ID
     * @param _cid CID of the data
     */
    function getDealId(bytes calldata _cid) public view returns (uint64) {
        return dealClient.getDealId(_cid);
    }

    /**
     * @notice function to status of the deal
     * @param _cid CID of the data
     */
    function getDealStatus(bytes calldata _cid) public view returns (Status) {
        return dealClient.getPieceStatus(_cid);
    }

    /**
     * @notice function to get provider data
     * @param _cid CID of the data
     */
    function getProviderSet(bytes calldata _cid) public view returns (ProviderSet memory) {
        return dealClient.getProviderSet(_cid);
    }

    /**
     * @notice function to get the number of deals created
     */
    function dealCount() public view returns (uint256) {
        return dealClient.dealsLength();
    }

    /**
     * @notice function to get the deal by index
     * @param _index index number
     */
    function getDealByIndex(uint256 _index) external view returns (DealRequest memory) {
        return dealClient.getDealByIndex(_index);
    }

    /**
     * @dev getAllDeals returns all deals for a CID
     * @param _cid is the CID
     * @return the deal IDs
     */
    function getAllDeals(bytes memory _cid) external view returns (uint64[] memory) {
        return cidToDealIds[_cid];
    }
}