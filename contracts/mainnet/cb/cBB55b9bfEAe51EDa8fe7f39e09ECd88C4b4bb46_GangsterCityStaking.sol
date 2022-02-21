/**
 *Submitted for verification at snowtrace.io on 2022-02-21
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: StakingV3.sol


pragma solidity ^0.8.10;

error InsufficientFunds();
error Unauthorized();
error AllTokensAwarded();





library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        uint256[] keys;
        mapping(uint256 => uint256) values;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 key) public view returns (uint256) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (uint256)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        uint256 key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, uint256 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function checkIfWorker(uint256 tokenId) external view returns (bool);

    function checkIfLandlord(uint256 tokenId) external view returns (bool);

    function checkIfBusinessOwner(uint256 tokenId) external view returns (bool);

    function checkIfGangster(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

contract GangsterCityStaking is IERC721Receiver, Ownable {


    /*
    -----------------------------------------------------
    Gangster City Staking | https://thegangstercity.xyz/
    -----------------------------------------------------
    Coded by !vscorpio for Gangster City
    - Discord: !vik#1337
    - GitHub: https://github.com/vscorpio
    - Business inquiries: [email protected]
    -----------------------------------------------------
    */


    function hasContractAwardedAllTokens() internal view returns (bool) {
        if (tokensAwarded >= tokensToAward) return true;
        else return false;
    }

    //ERC721 fallback

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    address public ercAddress;
    address public nftAddress;

    constructor(address ercAddr, address nftAddr) {
        ercAddress = ercAddr;
        nftAddress = nftAddr;
    }

    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private workerMap;
    IterableMapping.Map private landlordMap;
    IterableMapping.Map private businessOwnerMap;
    IterableMapping.Map private gangsterMap;

    mapping(uint256 => uint256) lastClaimedReward;
    mapping(uint256 => uint256) public tokenIdReward;
    mapping(uint256 => address) public ownerOfDeposit;
    mapping(string => bool) consumedRandomness;

    // Events

    event WOStaked(uint256 tokenId, uint256 timestamp, address owner);
    event LLStaked(uint256 tokenId, uint256 timestamp, address owner);
    event BOStaked(uint256 tokenId, uint256 timestamp, address owner);
    event GAStaked(uint256 tokenId, uint256 timestamp, address owner);

    event WOUnstaked(uint256 tokenId, uint256 timestamp, address owner);
    event LLUnstaked(uint256 tokenId, uint256 timestamp, address owner);
    event BOUnstaked(uint256 tokenId, uint256 timestamp, address owner);
    event GAUnstaked(uint256 tokenId, uint256 timestamp, address owner);

    event EtherJsLogger(uint256 messageNumber, uint256 value);

    event StakingEnabledChanged(bool newValue);
    event ErcNftAddressChanged(address _newErcAddress, address _newNftAddress);

    uint256 public stakedWorkers;
    uint256 public stakedLandlords;
    uint256 public stakedBusinessOwners;
    uint256 public stakedGangsters;

    address randomnessProviderV2 = 0x512F7437fc6eeb514B962bB247F645091372f9c0; // ORACLE ADDR - CAN SEND RANDOMENSS AND EXECUTE

    uint256 constant dayTimeInSeconds = 1 days;

    uint256 public constant tokensToAward = 3000000000 ether; //3B $CASH TOKENS
    uint256 public tokensAwarded = 0;

    bool isStakingEnabled = false;

    struct Request {
        uint256 id;
        uint256 tokenId;
        uint256 generatedRandomness;
        bool isFullfilled;
    }

    Request[] public unstakeWORequestQueue;
    Request[] public unstakeLLRequestQueue;
    Request[] public unstakeBORequestQueue;
    Request[] public unstakeGARequestQueue;

    Request[] public claimBORequestQueue;
    Request[] public claimGARequestQueue;

    event WOUnstakeRequest(uint256 requestId, uint256 tokenId);
    event LLUnstakeRequest(uint256 requestId, uint256 tokenId);
    event BOUnstakeRequest(uint256 requestId, uint256 tokenId);
    event GAUnstakeRequest(uint256 requestId, uint256 tokenId);

    event BOClaimRequest(uint256 requestId, uint256 tokenId);
    event GAClaimRequest(uint256 requestId, uint256 tokenId);

    function transferRewards(uint256 tokenId, uint256 funds) internal {
        tokenIdReward[tokenId] = 0;
        lastClaimedReward[tokenId] = block.timestamp;
        tokensAwarded += funds;
        IERC20(ercAddress).transfer(ownerOfDeposit[tokenId], funds);
    }

    // EXECUTE UNSTAKE REQUEST FUNCTIONS

    function executeWOUnstakeRequest(uint256 requestId, uint256 randomness)
        external
        returns (bool)
    {
        uint256 finalWorkerReward = getWorkerTimeLockReward(
            unstakeWORequestQueue[requestId].tokenId
        );
        uint256 returnedMsgNumber = 1;

        if (msg.sender != randomnessProviderV2) revert Unauthorized();
        if (unstakeWORequestQueue[requestId].isFullfilled == true)
            revert Unauthorized();

        stakedWorkers--;
        workerMap.remove(unstakeWORequestQueue[requestId].tokenId);

        if (finalWorkerReward < 10000 * 1 ether) revert InsufficientFunds();
        uint256 chance = (randomness % 100) + 1;

        // 5% chance for income to be split among all landlords
        if ((chance >= 1 && chance <= 5))
            if (stakedLandlords > 0) {
                uint256 eachLandlordCut = finalWorkerReward / (stakedLandlords);
                finalWorkerReward = 0;
                returnedMsgNumber = 2;
                if (stakedLandlords == 1) {
                    tokenIdReward[
                        landlordMap.getKeyAtIndex(0)
                    ] += eachLandlordCut;
                } else {
                    for (uint256 i = 0; i <= stakedLandlords - 1; i++) {
                        tokenIdReward[
                            landlordMap.getKeyAtIndex(i)
                        ] += eachLandlordCut;
                    }
                }
            }

        // 10% chance for income to be split among all BO
        if ((chance >= 6 && chance <= 15))
            if (stakedBusinessOwners > 0) {
                returnedMsgNumber = 3;
                uint256 eachBusinessOwnerCut = finalWorkerReward /
                    (stakedBusinessOwners);
                finalWorkerReward = 0;
                if (stakedBusinessOwners == 1) {
                    tokenIdReward[
                        businessOwnerMap.getKeyAtIndex(0)
                    ] += eachBusinessOwnerCut;
                } else {
                    for (uint256 i = 0; i <= stakedBusinessOwners - 1; i++) {
                        tokenIdReward[
                            businessOwnerMap.getKeyAtIndex(i)
                        ] += eachBusinessOwnerCut;
                    }
                }
            }

        // 20% chance for income to be split among all GA
        if ((chance >= 16 && chance <= 35))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 4;
                uint256 eachGangsterCut = finalWorkerReward / (stakedGangsters);
                finalWorkerReward = 0;
                if (stakedGangsters == 1) {
                    tokenIdReward[
                        gangsterMap.getKeyAtIndex(0)
                    ] += eachGangsterCut;
                } else {
                    for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                        tokenIdReward[
                            gangsterMap.getKeyAtIndex(i)
                        ] += eachGangsterCut;
                    }
                }
            }

        // 15% chance for all tokens to get burned
        if ((chance >= 36 && chance <= 50)) {
            IERC20(ercAddress).transfer(address(0), finalWorkerReward);
            finalWorkerReward = 0;
            returnedMsgNumber = 5;
        }

        if (finalWorkerReward != 0) {
            transferRewards(
                unstakeWORequestQueue[requestId].tokenId,
                finalWorkerReward
            );
        }

        IERC721(nftAddress).safeTransferFrom(
            address(this),
            ownerOfDeposit[unstakeWORequestQueue[requestId].tokenId],
            unstakeWORequestQueue[requestId].tokenId
        );

        emit EtherJsLogger(returnedMsgNumber, finalWorkerReward);
        emit WOUnstaked(
            unstakeWORequestQueue[requestId].tokenId,
            block.timestamp,
            ownerOfDeposit[unstakeWORequestQueue[requestId].tokenId]
        );

        unstakeWORequestQueue[requestId].isFullfilled = true;
        ownerOfDeposit[unstakeWORequestQueue[requestId].tokenId] = address(0);

        return true;
    }

    function executeLLUnstakeRequest(uint256 requestId, uint256 randomness)
        external
        returns (bool)
    {
        uint256 returnedMsgNumber = 1;
        if (msg.sender != randomnessProviderV2) revert Unauthorized();
        if (unstakeLLRequestQueue[requestId].isFullfilled == true)
            revert Unauthorized();

        uint256 finalLandlordReward = tokenIdReward[
            unstakeLLRequestQueue[requestId].tokenId
        ];

        stakedLandlords--;
        landlordMap.remove(unstakeLLRequestQueue[requestId].tokenId);

        if (finalLandlordReward < 25000 * 1 ether) revert InsufficientFunds();
        uint256 chance = (randomness % 100) + 1;
        bool hasLostNft = false;

        // 15% chance for token burn
        if ((chance >= 1 && chance <= 15)) {
            IERC20(ercAddress).transfer(address(0), finalLandlordReward);
            finalLandlordReward = 0;
            returnedMsgNumber = 2;
        }

        // 10% chance for income to be split among all GA
        if ((chance >= 16 && chance <= 25))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 3;
                uint256 eachGangsterCut = finalLandlordReward /
                    (stakedGangsters);
                finalLandlordReward = 0;
                if (stakedGangsters == 1) {
                    tokenIdReward[
                        gangsterMap.getKeyAtIndex(0)
                    ] += eachGangsterCut;
                } else {
                    for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                        tokenIdReward[
                            gangsterMap.getKeyAtIndex(i)
                        ] += eachGangsterCut;
                    }
                }
            }

        // 2% chance for NFT to be rewarded among a random gangster
        if ((chance >= 26 && chance <= 27))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 4;
                if (stakedGangsters == 1) {
                    hasLostNft = true;

                    IERC721(nftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[gangsterMap.getKeyAtIndex(0)],
                        unstakeLLRequestQueue[requestId].tokenId
                    );
                } else {
                    hasLostNft = true;

                    IERC721(nftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[
                            gangsterMap.getKeyAtIndex(
                                (randomness % stakedGangsters) + 1
                            )
                        ],
                        unstakeLLRequestQueue[requestId].tokenId
                    );
                }
            }

        if (hasLostNft == false) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[unstakeLLRequestQueue[requestId].tokenId],
                unstakeLLRequestQueue[requestId].tokenId
            );
        }

        if (finalLandlordReward != 0) {
            transferRewards(
                unstakeLLRequestQueue[requestId].tokenId,
                finalLandlordReward
            );
        }

        emit EtherJsLogger(returnedMsgNumber, finalLandlordReward);
        emit LLUnstaked(
            unstakeLLRequestQueue[requestId].tokenId,
            block.timestamp,
            ownerOfDeposit[unstakeLLRequestQueue[requestId].tokenId]
        );

        unstakeLLRequestQueue[requestId].isFullfilled = true;
        ownerOfDeposit[unstakeLLRequestQueue[requestId].tokenId] = address(0);

        return true;
    }

    function executeBOUnstakeRequest(uint256 requestId, uint256 randomness)
        external
        returns (bool)
    {
        if (msg.sender != randomnessProviderV2) revert Unauthorized();
        if (unstakeBORequestQueue[requestId].isFullfilled == true)
            revert Unauthorized();

        uint256 finalBusinessOwnerReward = tokenIdReward[
            unstakeBORequestQueue[requestId].tokenId
        ];
        uint256 returnedMsgNumber = 1;

        stakedBusinessOwners--;
        businessOwnerMap.remove(unstakeBORequestQueue[requestId].tokenId);

        uint256 chance = (randomness % 100) + 1;

        bool hasLostNft = false;
        bool haveTokensBurned = false;

        // 10% chance for token burn
        if ((chance >= 1 && chance <= 10)) {
            haveTokensBurned = true;
            IERC20(ercAddress).transfer(address(0), finalBusinessOwnerReward);
            finalBusinessOwnerReward = 0;
            returnedMsgNumber = 2;
        }

        // 5% chance for income to be split among gangsters
        if ((chance >= 11 && chance <= 15))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 3;
                uint256 eachGangsterCut = finalBusinessOwnerReward /
                    (stakedGangsters);
                finalBusinessOwnerReward = 0;
                if (stakedGangsters == 1) {
                    tokenIdReward[
                        gangsterMap.getKeyAtIndex(0)
                    ] += eachGangsterCut;
                } else {
                    for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                        tokenIdReward[
                            gangsterMap.getKeyAtIndex(i)
                        ] += eachGangsterCut;
                    }
                }
            }

        // 1% chance for NFT to be rewarded among a random gangster
        if (chance == 16)
            if (stakedGangsters > 0) {
                returnedMsgNumber = 4;
                if (stakedGangsters == 1) {
                    hasLostNft = true;

                    IERC721(nftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[gangsterMap.getKeyAtIndex(0)],
                        unstakeBORequestQueue[requestId].tokenId
                    );
                } else {
                    hasLostNft = true;

                    IERC721(nftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[
                            (gangsterMap.getKeyAtIndex(
                                randomness % stakedGangsters
                            ) + 1)
                        ],
                        unstakeBORequestQueue[requestId].tokenId
                    );
                }
            }

        //85% chance to unstake and claim token

        if (hasLostNft == false)
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[unstakeBORequestQueue[requestId].tokenId],
                unstakeBORequestQueue[requestId].tokenId
            );

        if (finalBusinessOwnerReward != 0 && haveTokensBurned == false) {
            transferRewards(
                unstakeBORequestQueue[requestId].tokenId,
                finalBusinessOwnerReward
            );
        }

        emit EtherJsLogger(returnedMsgNumber, finalBusinessOwnerReward);
        emit BOUnstaked(
            unstakeBORequestQueue[requestId].tokenId,
            block.timestamp,
            ownerOfDeposit[unstakeBORequestQueue[requestId].tokenId]
        );

        unstakeBORequestQueue[requestId].isFullfilled = true;
        ownerOfDeposit[unstakeBORequestQueue[requestId].tokenId] = address(0);
        return true;
    }

    function executeGAUnstakeRequest(uint256 requestId, uint256 randomness)
        external
        returns (bool)
    {
        if (msg.sender != randomnessProviderV2) revert Unauthorized();
        if (unstakeGARequestQueue[requestId].isFullfilled == true)
            revert Unauthorized();

        uint256 returnedMsgNumber = 2;
        uint256 finalGangsterReward = tokenIdReward[
            unstakeGARequestQueue[requestId].tokenId
        ];

        uint256 chance = (randomness % 100) + 1;

        stakedGangsters--;
        gangsterMap.remove(unstakeGARequestQueue[requestId].tokenId);

        if (hasContractAwardedAllTokens()) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[unstakeGARequestQueue[requestId].tokenId],
                unstakeGARequestQueue[requestId].tokenId
            );
            emit GAUnstaked(
                unstakeGARequestQueue[requestId].tokenId,
                block.timestamp,
                ownerOfDeposit[unstakeGARequestQueue[requestId].tokenId]
            );
            return true;
        }

        if (finalGangsterReward < 75000 * 1 ether) revert InsufficientFunds();

        if ((chance >= 1 && chance <= 75)) {
            finalGangsterReward = 0;
            returnedMsgNumber = 1;
        }

        if (finalGangsterReward != 0) {
            transferRewards(
                unstakeGARequestQueue[requestId].tokenId,
                finalGangsterReward
            );
        }

        IERC721(nftAddress).safeTransferFrom(
            address(this),
            ownerOfDeposit[unstakeGARequestQueue[requestId].tokenId],
            unstakeGARequestQueue[requestId].tokenId
        );

        emit EtherJsLogger(returnedMsgNumber, finalGangsterReward);
        emit GAUnstaked(
            unstakeGARequestQueue[requestId].tokenId,
            block.timestamp,
            ownerOfDeposit[unstakeGARequestQueue[requestId].tokenId]
        );

        unstakeGARequestQueue[requestId].isFullfilled = true;
        ownerOfDeposit[unstakeGARequestQueue[requestId].tokenId] = address(0);
        return true;
    }

    // EXECUTE CLAIM REQUEST FUNCTIONS

    function executeBOClaimRequest(uint256 requestId, uint256 randomness)
        external
        returns (bool)
    {
        if (msg.sender != randomnessProviderV2) revert Unauthorized();
        if (claimBORequestQueue[requestId].isFullfilled == true)
            revert Unauthorized();
        uint256 finalBusinessOwnerReward = tokenIdReward[
            claimBORequestQueue[requestId].tokenId
        ];
        uint256 returnedMsgNumber = 1;
        uint256 chance = (randomness % 100) + 1;

        // Distribute Gangster cut 5%
        if (stakedGangsters > 0) {
            uint256 gangsterBonus = (finalBusinessOwnerReward * (5)) / (100);
            uint256 eachGangsterCut = gangsterBonus / (stakedGangsters);
            finalBusinessOwnerReward -= gangsterBonus;
            if (stakedGangsters == 1) {
                tokenIdReward[gangsterMap.getKeyAtIndex(0)] += eachGangsterCut;
            } else {
                for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                    tokenIdReward[
                        gangsterMap.getKeyAtIndex(i)
                    ] += eachGangsterCut;
                }
            }
        }

        if ((chance >= 1 && chance <= 50)) {
            finalBusinessOwnerReward -=
                (finalBusinessOwnerReward * (25)) /
                (100);
            IERC20(ercAddress).transfer(
                address(0),
                (finalBusinessOwnerReward * (25)) / (100)
            );
            returnedMsgNumber = 2;
        }

        if (finalBusinessOwnerReward != 0) {
            transferRewards(
                claimBORequestQueue[requestId].tokenId,
                finalBusinessOwnerReward
            );
        }

        emit EtherJsLogger(returnedMsgNumber, finalBusinessOwnerReward);
        claimBORequestQueue[requestId].isFullfilled = true;

        return true;
    }

    function executeGAClaimRequest(uint256 requestId, uint256 randomness)
        external
        returns (bool)
    {
        if (msg.sender != randomnessProviderV2) revert Unauthorized();
        if (claimGARequestQueue[requestId].isFullfilled == true)
            revert Unauthorized();

        uint256 returnedMsgNumber = 1;
        uint256 chance = (randomness % 100) + 1;
        uint256 finalGangsterReward = tokenIdReward[
            claimGARequestQueue[requestId].tokenId
        ];

        if ((chance >= 1 && chance <= 50)) {
            finalGangsterReward -= (finalGangsterReward * (25)) / (100);
            returnedMsgNumber = 2;
        }

        if (finalGangsterReward != 0) {
            transferRewards(
                claimGARequestQueue[requestId].tokenId,
                finalGangsterReward
            );
        }

        emit EtherJsLogger(returnedMsgNumber, finalGangsterReward);
        claimGARequestQueue[requestId].isFullfilled = true;
        return true;
    }

    function changeERCNFTAddr(address ercAddr, address nftAddr)
        external
        onlyOwner
    {
        require(ercAddr != address(0) && nftAddr != address(0));

        ercAddress = ercAddr;
        nftAddress = nftAddr;

        emit ErcNftAddressChanged(ercAddr, nftAddr);
    }

    function changeStakingEnabled(bool value) external onlyOwner {
        isStakingEnabled = value;
        emit StakingEnabledChanged(value);
    }

    function getRandomStakedGangsterOwnerAddr()
        external
        view
        returns (address)
    {
        // If we dont use this simplified version of RNG Contract will be too large to compile

        if (stakedGangsters > 0) {
            uint256 key1 = gangsterMap.getKeyAtIndex(
                ((uint256(
                    keccak256(
                        abi.encodePacked(block.difficulty, block.timestamp)
                    )
                ) % stakedGangsters) + 1) - 1
            );
            return ownerOfDeposit[key1];
        }

        return address(0);
    }

    function getWorkerTimeLockReward(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (ownerOfDeposit[tokenId] == address(0)) return 0;

        uint256 timeStackedForTokenId = block.timestamp -
            lastClaimedReward[tokenId];
        uint256 currentTimeLockReward = (((timeStackedForTokenId * (100000)) /
            dayTimeInSeconds) *
            5000 *
            1 ether) / (100000);

        return currentTimeLockReward;
    }

    function getTotalStakedNFTs() external view returns (uint256) {
        return
            stakedWorkers +
            stakedLandlords +
            stakedBusinessOwners +
            stakedGangsters;
    }

    function stakeNft(uint256 tokenId) external returns (bool) {
        if (isStakingEnabled == false) revert Unauthorized();

        lastClaimedReward[tokenId] = block.timestamp;
        ownerOfDeposit[tokenId] = msg.sender;

        if (IERC721(nftAddress).checkIfWorker(tokenId)) {
            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            workerMap.set(tokenId, 1);
            stakedWorkers++;
            emit WOStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }
        if (IERC721(nftAddress).checkIfLandlord(tokenId)) {
            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            landlordMap.set(tokenId, 1);
            stakedLandlords++;
            emit LLStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }
        if (IERC721(nftAddress).checkIfBusinessOwner(tokenId)) {
            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            businessOwnerMap.set(tokenId, 1);
            stakedBusinessOwners++;
            emit BOStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }
        if (IERC721(nftAddress).checkIfGangster(tokenId)) {
            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            gangsterMap.set(tokenId, 1);
            stakedGangsters++;
            emit GAStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }

        revert();
    }

    function transferRandomnessCost(uint256 sentAvax) internal {
        require(sentAvax >= 0.007 * 1 ether);
        (bool sent, bytes memory data) = randomnessProviderV2.call{
            value: sentAvax
        }("");
        require(sent, "Failed to send AVAX");
    }

    function claimRewardWorker(uint256 tokenId) external returns (uint256) {
        if (hasContractAwardedAllTokens()) revert AllTokensAwarded();

        if (IERC721(nftAddress).checkIfWorker(tokenId) != true)
            revert Unauthorized();
        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();

        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        uint256 finalWorkerReward = getWorkerTimeLockReward(tokenId);
        uint256 finalWorkerRewardCopy = finalWorkerReward;

        // Distribute BO cut 20%
        if (stakedBusinessOwners > 0) {
            uint256 businessOwnerBonus = (finalWorkerRewardCopy * (20)) / (100);
            uint256 eachBusinessOwnerCut = businessOwnerBonus /
                (stakedBusinessOwners);
            finalWorkerReward -= businessOwnerBonus;
            if (stakedBusinessOwners == 1) {
                uint256 key1 = businessOwnerMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachBusinessOwnerCut;
            } else {
                for (uint256 i = 0; i <= stakedBusinessOwners - 1; i++) {
                    uint256 key = businessOwnerMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachBusinessOwnerCut;
                }
            }
        }

        // Distribute Landlord cut 15%
        if (stakedLandlords > 0) {
            uint256 landlordBonus = (finalWorkerRewardCopy * (15)) / (100);
            uint256 eachLandlordCut = landlordBonus / (stakedLandlords);
            finalWorkerReward -= landlordBonus;
            if (stakedLandlords == 1) {
                uint256 key1 = landlordMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachLandlordCut;
            } else {
                for (uint256 i = 0; i <= stakedLandlords - 1; i++) {
                    uint256 key = landlordMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachLandlordCut;
                }
            }
        }

        // Distribute Gangster cut 5%
        if (stakedGangsters > 0) {
            uint256 gangsterBonus = (finalWorkerRewardCopy * (5)) / (100);
            uint256 eachGangsterCut = gangsterBonus / (stakedGangsters);
            finalWorkerReward -= gangsterBonus;
            if (stakedGangsters == 1) {
                uint256 key1 = gangsterMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachGangsterCut;
            } else {
                for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                    uint256 key = gangsterMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachGangsterCut;
                }
            }
        }

        if (finalWorkerReward != 0) {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            tokensAwarded += finalWorkerReward;
            IERC20(ercAddress).transfer(
                ownerOfDeposit[tokenId],
                finalWorkerReward
            );
        }

        emit EtherJsLogger(1, finalWorkerReward);
        return finalWorkerReward;
    }

    function claimRewardLandlord(uint256 tokenId) external returns (bool) {
        uint256 finalLandlordReward = tokenIdReward[tokenId];

        if (hasContractAwardedAllTokens()) revert AllTokensAwarded();
        if (IERC721(nftAddress).checkIfLandlord(tokenId) != true)
            revert Unauthorized();
        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if (finalLandlordReward < 25000 * 1 ether) revert InsufficientFunds();
        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        // Distribute Gangster cut 5%
        if (stakedGangsters > 0) {
            uint256 gangsterBonus = (finalLandlordReward * (5)) / (100);
            uint256 eachGangsterCut = gangsterBonus / (stakedGangsters);
            finalLandlordReward -= gangsterBonus;
            if (stakedGangsters == 1) {
                uint256 key1 = gangsterMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachGangsterCut;
            } else {
                for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                    uint256 key = gangsterMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachGangsterCut;
                }
            }
        }

        if (finalLandlordReward != 0) {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            tokensAwarded += finalLandlordReward;
            IERC20(ercAddress).transfer(
                ownerOfDeposit[tokenId],
                finalLandlordReward
            );
        }

        emit EtherJsLogger(1, finalLandlordReward);

        return true;
    }

    function claimRewardBusinessOwner(uint256 tokenId)
        external
        payable
        returns (bool)
    {
        transferRandomnessCost(msg.value);

        uint256 finalBusinessOwnerReward = tokenIdReward[tokenId];

        if (hasContractAwardedAllTokens()) revert AllTokensAwarded();

        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        if (IERC721(nftAddress).checkIfBusinessOwner(tokenId) != true)
            revert Unauthorized();
        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if (finalBusinessOwnerReward < 50000 * 1 ether) revert Unauthorized();

        uint256 requestId = claimBORequestQueue.length;

        claimBORequestQueue.push(Request(requestId, tokenId, 0, false));

        emit BOClaimRequest(requestId, tokenId);

        return true;
    }

    function claimRewardGangster(uint256 tokenId)
        external
        payable
        returns (bool)
    {
        transferRandomnessCost(msg.value);

        if (hasContractAwardedAllTokens()) revert AllTokensAwarded();

        uint256 finalGangsterReward = tokenIdReward[tokenId];

        if (IERC721(nftAddress).checkIfGangster(tokenId) != true)
            revert Unauthorized();
        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if (finalGangsterReward < 75000 * 1 ether) revert InsufficientFunds();
        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        uint256 requestId = claimGARequestQueue.length;

        claimGARequestQueue.push(Request(requestId, tokenId, 0, false));

        emit GAClaimRequest(requestId, tokenId);

        return true;
    }

    // UNSTAKE

    function unstakeWorker(uint256 tokenId) external payable returns (bool) {
        transferRandomnessCost(msg.value);

        uint256 finalWorkerReward = getWorkerTimeLockReward(tokenId);

        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();
        if (IERC721(nftAddress).checkIfWorker(tokenId) != true)
            revert Unauthorized();

        if (hasContractAwardedAllTokens()) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );
            emit WOUnstaked(tokenId, block.timestamp, ownerOfDeposit[tokenId]);
            return true;
        }

        if (finalWorkerReward < 10000 * 1 ether) revert InsufficientFunds();

        uint256 requestId = unstakeWORequestQueue.length;

        unstakeWORequestQueue.push(Request(requestId, tokenId, 0, false));

        emit WOUnstakeRequest(requestId, tokenId);
        return true;
    }

    function unstakeLandlord(uint256 tokenId) external payable returns (bool) {
        transferRandomnessCost(msg.value);
        uint256 finalLandlordReward = tokenIdReward[tokenId];

        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();

        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        if (IERC721(nftAddress).checkIfLandlord(tokenId) != true)
            revert Unauthorized();

        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        if (finalLandlordReward < 25000 * 1 ether) revert InsufficientFunds();

        if (hasContractAwardedAllTokens()) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );
            emit LLUnstaked(tokenId, block.timestamp, ownerOfDeposit[tokenId]);
            return true;
        }

        uint256 requestId = unstakeLLRequestQueue.length;

        unstakeLLRequestQueue.push(Request(requestId, tokenId, 0, false));

        emit LLUnstakeRequest(requestId, tokenId);
        return true;
    }

    function unstakeBusinessOwner(uint256 tokenId)
        external
        payable
        returns (bool)
    {
        transferRandomnessCost(msg.value);
        uint256 finalBusinessOwnerReward = tokenIdReward[tokenId];

        if (finalBusinessOwnerReward < 50000 * 1 ether)
            revert InsufficientFunds();

        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();

        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        if (IERC721(nftAddress).checkIfBusinessOwner(tokenId) != true)
            revert Unauthorized();

        if (hasContractAwardedAllTokens()) {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );
            emit BOUnstaked(tokenId, block.timestamp, ownerOfDeposit[tokenId]);
            return true;
        }

        uint256 requestId = unstakeBORequestQueue.length;

        unstakeBORequestQueue.push(Request(requestId, tokenId, 0, false));

        emit BOUnstakeRequest(requestId, tokenId);

        return true;
    }
    function unstakeGangster(uint256 tokenId) external payable returns (bool) {
        transferRandomnessCost(msg.value);

        uint256 finalGangsterReward = tokenIdReward[tokenId];

        if (ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();

        if (IERC721(nftAddress).ownerOf(tokenId) != address(this))
            revert Unauthorized();

        if (IERC721(nftAddress).checkIfGangster(tokenId) != true)
            revert Unauthorized();

        if (finalGangsterReward < 75000 * 1 ether) revert InsufficientFunds();

        uint256 requestId = unstakeGARequestQueue.length;

        unstakeGARequestQueue.push(Request(requestId, tokenId, 0, false));

        emit GAUnstakeRequest(requestId, tokenId);

        return true;
    }
}