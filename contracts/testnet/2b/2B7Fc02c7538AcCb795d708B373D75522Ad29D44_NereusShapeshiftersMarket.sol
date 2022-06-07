// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/INereusShapeshiftersMarket.sol";

contract NereusShapeshiftersMarket is Ownable, ReentrancyGuard, IERC721Receiver, INereusShapeshiftersMarket {

    address private _nftContractAddress;

    // received token ids by the contract
    mapping(uint256 => uint256) private _allowedTokenIds;
    // counter of received tokens
    uint256 private _allowedTokenIdsCounter;
    // counter of distributed tokens
    uint256 private _allowedTokenIdsTransferTracker;
    
    // erc20 addresses allowed for purchases
    mapping(address => bool) private _allowedErc20Tokens;

    // sales wave configuration
    mapping(uint256 => SaleWave) private _saleWaves;
    // counter of sale waves added to contract
    uint256 private _saleWavesCounter;
    // id of current sale wave set
    uint256 private _currentSaleWave;

    // sales waves allowed token prices per token address
    mapping(uint256 => mapping(address => uint256)) public _salesWaveTokenPrices;

    // correlation between whitelistable sales wave and claimed amount per whitelisted address
    mapping(uint256 => mapping(address => uint256)) public _saleWavesWhitelistClaimed;

    constructor(address nftContractAddress) {
        _nftContractAddress = nftContractAddress;
        // starting from 1 to let set to 0 if need to turn off sales
        _saleWavesCounter = 1;
    }

    modifier isSalesAllowed(uint256 amount) {
        require(_saleWaves[_currentSaleWave].active, "NereusShapeshiftersMarket: sales not active at the moment");
        require(amount > 0, "NereusShapeshiftersMarket: specified amount should be more than zero");
        require(_allowedTokenIdsCounter >= _allowedTokenIdsTransferTracker + amount, "NereusShapeshiftersMarket: requested amount exceed NFTs balance on contract");
        _;
    }

    modifier allowedERC20BuyToken(address erc20BuyToken) {
        require(_allowedErc20Tokens[erc20BuyToken], "NereusShapeshiftersMarket: specified ERC20 is not allowed");
        _;
    }

    /**
    * Checks if erc20 token allowance is enough to cover purchase
    * Takes current wave price as purchase price
     */
    modifier buyPriceCompliance(address erc20BuyToken, uint256 amount) {
        uint256 currentWaveCost = _salesWaveTokenPrices[_currentSaleWave][erc20BuyToken];

        require(
            IERC20(erc20BuyToken)
            .allowance(_msgSender(), address(this)) >= currentWaveCost * amount,
            "NereusShapeshiftersMarket: insufficient ERC20 token balance"
        );
        _;
    }

    /**
    * Allows to insert wave prices into sales wave
     */
    function addSalesWaveTokenPrices(uint256 salesWaveId, SaleWaveTokenPrice[] calldata wavePrices) public onlyOwner {
        for(uint256 i = 0; i < wavePrices.length; i++) {
            require(_allowedErc20Tokens[wavePrices[i].token], "NereusShapeshiftersMarket: specified token is not allowed.");
            require(wavePrices[i].price > 0, "NereusShapeshiftersMarket: specified token price should be more than 0.");

            _salesWaveTokenPrices[salesWaveId][wavePrices[i].token] = wavePrices[i].price;
        }
    }

    /**
    * Allows to add new sale wave
     */
    function addSaleWave(SaleWaveTokenPrice[] calldata wavePrices) public onlyOwner returns (uint256) {
        uint256 saleWaveId = _saleWavesCounter;
    
        addSalesWaveTokenPrices(saleWaveId, wavePrices);
    
        _saleWaves[saleWaveId] = SaleWave(false, "", 0, true);
        _saleWavesCounter++;

        emit SalesWaveAdded(saleWaveId, false);

        return saleWaveId;
    }

    /**
    * Allows to add new sale wave
     */
    function addWhitelistableSaleWave(
        SaleWaveTokenPrice[] calldata wavePrices,
        bytes32 merkleRoot,
        uint256 whitelistClaimAllowance
        ) public onlyOwner returns (uint256) {
        
        require(whitelistClaimAllowance > 0, "NereusShapeshiftersMarket: whitelist claim allowance should be more than 0");

        uint256 saleWaveId = _saleWavesCounter;

        addSalesWaveTokenPrices(saleWaveId, wavePrices); 

        _saleWaves[saleWaveId] = SaleWave(true, merkleRoot, whitelistClaimAllowance, true);
        _saleWavesCounter++;

        emit SalesWaveAdded(saleWaveId, true);

        return saleWaveId;
    }

    /**
    * Turns on sale wave 
    * saleWaveId - sale wave id to turn on
    * should: receive existing and active sale wave
     */
    function setCurrentSaleWave(uint256 saleWaveId) public onlyOwner {
        require(_saleWaves[saleWaveId].active, "NereusShapeshiftersMarket: specified sale wave does not exists or not active");
        _currentSaleWave = saleWaveId;
        emit SalesWaveSet(_currentSaleWave);
    }

    /**
    * Allows new ERC20 token to be used for buy
    * erc20BuyToken - erc20 token address
    * should: specified token to be not allowed
     */
    function allowERC20BuyToken(address erc20BuyToken) public onlyOwner {
        require(erc20BuyToken != address(0), "NereusShapeshiftersMarket: invalid address specified");
        require(!_allowedErc20Tokens[erc20BuyToken], "NereusShapeshiftersMarket: specified token already added");

        _allowedErc20Tokens[erc20BuyToken] = true;

        emit BuyTokenAllowed(erc20BuyToken);
    }

    /**
    * Disallows existing ERC20 token to be used for buy
    * erc20BuyToken - erc20 token address
    * should: specified token to be already allowed
     */
    function disallowERC20BuyToken(address erc20BuyToken) public onlyOwner {
        require(erc20BuyToken != address(0), "NereusShapeshiftersMarket: invalid address specified");
        require(_allowedErc20Tokens[erc20BuyToken], "NereusShapeshiftersMarket: specified token does not exists");

        _allowedErc20Tokens[erc20BuyToken] = false;

        emit BuyTokenDisallowed(erc20BuyToken);
    }

    /**
    * Performs buy specied amount of tokens from those which is on hold in the contract
    * Uses current sale wave to determine the price
    * erc20BuyToken - token used to buy NFTs
    * amount - amount of NFTs to buy from contract
    * _merkleProof - proof of being in whitelist
    * should: receive allowed erc20 token for buy
    * should: have allowance of erc20 by user set to NFT price * purchase amount
    * if whitelist wave should: address to be whitelisted, address requested amount does not exceed allowance per wave
     */
    function buy(address erc20BuyToken, uint256 amount, bytes32[] calldata _merkleProof)
        public
        nonReentrant
        isSalesAllowed(amount)
        allowedERC20BuyToken(erc20BuyToken)
        buyPriceCompliance(erc20BuyToken, amount)
    {
        if(_saleWaves[_currentSaleWave].isWhitelistable) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(MerkleProof.verify(_merkleProof, _saleWaves[_currentSaleWave].merkleRoot, leaf), "NereusShapeshiftersMarket: address is not whitelisted.");

            uint256 requestedAmount = _saleWavesWhitelistClaimed[_currentSaleWave][_msgSender()] + amount;
            require(_saleWaves[_currentSaleWave].whitelistClaimAllowance >= requestedAmount, "NereusShapeshiftersMarket: wave whitelist amount per address exceeded.");
        }

        uint256 currentWaveCost = _salesWaveTokenPrices[_currentSaleWave][erc20BuyToken];

        IERC20(erc20BuyToken).transferFrom(
            _msgSender(),
            address(this),
            currentWaveCost * amount
        );

        // batch transfer of specific amount of tokens from contract address to buyer address 
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _allowedTokenIds[_allowedTokenIdsTransferTracker++];
            IERC721(_nftContractAddress).safeTransferFrom(address(this), _msgSender(), tokenId);

            emit NFTPurchased(_msgSender(), tokenId, _currentSaleWave, erc20BuyToken, currentWaveCost);
        }
        
        if(_saleWaves[_currentSaleWave].isWhitelistable) {
            _saleWavesWhitelistClaimed[_currentSaleWave][_msgSender()] += amount;
        }
    }

    /**
    * Withdraw specified ERC20 token balance from contract address to owner
     */
    function withdrawERC20Balance(address erc20BuyToken) public onlyOwner nonReentrant {
        require(_allowedErc20Tokens[erc20BuyToken], "NereusShapeshiftersMarket: specified token does not exists");
        IERC20(erc20BuyToken).transfer(_msgSender(), IERC20(erc20BuyToken).balanceOf(address(this)));

        emit PaymentTokenBalanceWithdrawn(erc20BuyToken);
    }

    /**
    * Allows contract to receive ERC721 tokens
    * Sets received tokenId into _allowedTokenIds to distribute on buy
    * Tracks only NFTs sent from specified nft contract address
     */
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes calldata
    ) external returns (bytes4) {

        // keep track only nfts sent from specified NFT contract address
        if(_msgSender() == _nftContractAddress) {
            _allowedTokenIds[_allowedTokenIdsCounter++] = _tokenId;
            emit NFTReceived(_tokenId);
        }

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface INereusShapeshiftersMarket {
    struct SaleWave {
        bool isWhitelistable;
        bytes32 merkleRoot;
        uint256 whitelistClaimAllowance;
        bool active;
    }

    struct SaleWaveTokenPrice {
        address token;
        uint256 price;
    }

    // emits when new sales wave added
    event SalesWaveAdded(uint256 waveId, bool isWhitelistable);
    // emits when current sales wave set
    event SalesWaveSet(uint256 waveId);
    // emits when new erc20 token allowed to use for buys
    event BuyTokenAllowed(address tokenAddress);
    // emits when erc20 token disallowed for buy
    event BuyTokenDisallowed(address tokenAddress);
    // emits when nft from specified contract received by the contract
    event NFTReceived(uint256 tokenId);
    // emits when user performs a purchase of nft
    event NFTPurchased(address buyer, uint256 tokenId, uint256 waveId, address erc20BuyToken, uint256 price);
    // emits when admin withdraws specified erc20 token balance
    event PaymentTokenBalanceWithdrawn(address token);
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