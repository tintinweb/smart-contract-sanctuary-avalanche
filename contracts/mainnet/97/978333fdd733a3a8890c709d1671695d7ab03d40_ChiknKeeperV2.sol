/**
 *Submitted for verification at snowtrace.io on 2022-12-11
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721Receiver.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: Interface.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol";


interface IChiknNFT {

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    struct ChickenRun {
        uint256 tokenId;
        // string tokenURI;
        address mintedBy;
        address currentOwner;
        uint256 previousPrice;
        uint256 price;
        uint256 numberOfTransfers;
        bool forSale;
        uint256 kg;
    }

    // map id to ChickenRun obj
    function allChickenRun(uint key) external view returns(ChickenRun memory);
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IFeedV2 {
 
    function staking(uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function claimableView(address user) external view returns (uint256);

    function withdrawEgg(uint256 amount) external;

    function claimFeed() external;

    function withdrawAllEggAndClaimFeed() external;

    function feedChikn(uint256 chiknId, uint256 amount) external;

    function swapEggForFeed(uint256 eggAmt) external;

    function mintFeed(address sender, uint256 amount) external;

    function updateBoosterMultiplier(uint256 _value) external;

    function updateFarmingFactor(uint256 _value) external;

    function updateFeedSwapFactor(uint256 _value) external;

    function updateMaxFeedSupply(uint256 _value) external;

    function totalEggHolder() external view returns (uint256);

    function rebalanceStakingPool(uint256 from, uint256 to) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IEggV2 {  

    struct StakedChiknObj {
        // the current kg level (0 -> 16,777,216)
        uint24 kg;
        // when to calculate egg from (max 20/02/36812, 11:36:16)
        uint32 sinceTs;
        // for the skipCooldown's cooldown (max 20/02/36812, 11:36:16)
        uint32 lastSkippedTs;
        // how much this chikn has been fed (in whole numbers)
        uint48 eatenAmount;
        // cooldown time until level up is allow (per kg)
        uint32 cooldownTs;
    }

    function stakedChikn(uint key) external view returns (StakedChiknObj memory);

    function EGGS_PER_DAY_PER_KG() external view returns (uint256);

    function BASE_HOLDER_EGGS() external view returns(uint256);

    function approve(address spender, uint256 amount) external returns (bool);

      function feedLevelingRate(uint256 kg) external view returns (uint256);

      function cooldownRate(uint256 kg) external view returns (uint256);

      function stake(uint256[] calldata tids) external; 

      function claimableView(uint256 tokenId) external view returns (uint256);

      function myClaimableView() external view returns (uint256);
      
      
      function claimEggs(uint256[] calldata tokenIds) external;

      function _unstake(uint256 tokenId) external;
       
      function myStakedChikn() external view returns (uint256[] memory);

      function _stake(uint256 tid) external;

      function _claimEggs(uint256[] calldata tokenIds) external;

      function mint(address account, uint256 amount) external;

      function _unstakeMultiple(uint256[] calldata tids) external;

    function unstake(uint256[] calldata tids) external;

    function withdrawAllChiknAndClaim(uint256[] calldata tids) external;

     function levelUpChikn(uint256 tid) external;

    function _burnEggs(address sender, uint256 eggsAmount) external;

    function burnEggs(address sender, uint256 eggsAmount) external;

     function skipCoolingOff(uint256 tokenId, uint256 eggAmt) external;

    function checkSkipCoolingOffAmt(uint256 kg) external view returns (uint256);

    function feedChikn(uint256 tokenId, uint256 feedAmount) external;

    function updateSkipCooldownValues(
        uint256 a, 
        uint256 b, 
        uint256 c,
        uint256 d,
        uint256 e
    ) external;

    function mintEgg(address sender, uint256 amount) external;

    function airdropToExistingHolder(
        uint256 from,
        uint256 to,
        uint256 amountOfEgg
    ) external;

    function rebalanceEggClaimableToUserWallet(uint256 from, uint256 to) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

} 

// File: restrictedAccessChikn.sol

pragma solidity ^0.8.4;



contract ChiknKeeperV2 is Ownable, IERC721Receiver {
     
    IChiknNFT public constant CHIKN_NFT_CONTRACT = IChiknNFT(0x8927985B358692815E18F2138964679DcA5d3b79);
    IEggV2 public constant EGG_CONTRACT = IEggV2(0x7761E2338B35bCEB6BdA6ce477EF012bde7aE611);
    IFeedV2 public constant FEED_CONTRACT = IFeedV2(0xab592d197ACc575D16C3346f4EB70C703F308D1E);

    address public manager;
    uint256 public totalChiknStaked; //chikn staked


    // Events
    event DistributionOfEgg(address receiver, uint256 amount);
    event NFTDeposited(address owner, uint256 tokenId, uint256 value);
    event NFTWithdrawn(address owner, uint256 tokenId, uint256 value);


    function eggsPerDayPerKg() public view returns (uint256) {
        return EGG_CONTRACT.EGGS_PER_DAY_PER_KG();
    }

    function baseHolderEggs() public view returns (uint256) {
        return EGG_CONTRACT.BASE_HOLDER_EGGS();
    }

        //Deposit chikns to allow use of interface functions below.  If you are not contract owner, do not use this function.
    function deposit(uint256[] calldata tids) external {
            uint256 tid;
            totalChiknStaked += tids.length;
            for (uint i = 0; i < tids.length; i++) {
            tid = tids[i];
            require(CHIKN_NFT_CONTRACT.ownerOf(tid) == msg.sender, "You do not own this token");

            CHIKN_NFT_CONTRACT.transferFrom(msg.sender, address(this), tid);
            _stake(tids);

            emit NFTDeposited(msg.sender, tid, block.timestamp);
            }
    }

        //Begin Chikn Controls
    function claimableView(uint256 tid) external view returns (uint256) {
        return EGG_CONTRACT.claimableView(tid);
    }

    function myClaimableView() external view returns (uint256) {
        return EGG_CONTRACT.myClaimableView();
    }
     
    function myStakedChikn() external view returns (uint256[] memory) {
        return EGG_CONTRACT.myStakedChikn();
    }
            //ChiknRunV5 function that activates chikns to make them eligible for token rewards
    function _stake(uint256[] calldata tids) public onlyOwner {
        EGG_CONTRACT.stake(tids);
    }

    function unstake(uint256[] calldata tids) external onlyOwner {
        EGG_CONTRACT.unstake(tids);
    }

    function withdrawToAddress(uint256 tid, address to) external onlyOwner {
         CHIKN_NFT_CONTRACT.transferFrom(address(this), to, tid);
    }

    function emergencyWithdraw(uint256 tid) external onlyOwner {
         CHIKN_NFT_CONTRACT.transferFrom(address(this), msg.sender, tid);
    }

    function approveFeedToLevel() external restricted {
       address FeedV2  = 0xFA5a0d9ae527B9829a9B8B7D3726F72DD3A0FD7A;//0x159cfD38DEac6BB7B95aBff3AA42063651c3c6F9;
       FEED_CONTRACT.approve(FeedV2, 9e28);
    }

    function approveEggToSkip() external restricted {
       address EggV2  = 0x5104d35A6dE00b19cd5BD0649e3c31c7469fbF1A;//0x159cfD38DEac6BB7B95aBff3AA42063651c3c6F9;
       EGG_CONTRACT.approve(EggV2, 9e28);
    }

    function approve(address contractAddress, address operator, uint256 amount) external onlyOwner {
        IERC20(contractAddress).approve(operator, amount);
    }

     function skipCoolingOff(uint256 tid, uint256 eggAmt) external restricted {
         EGG_CONTRACT.skipCoolingOff(tid, eggAmt);
     }  

    function checkSkipCoolingOffAmt(uint256 kg) external view returns (uint256) {
        return EGG_CONTRACT.checkSkipCoolingOffAmt(kg);
    } 

    function balanceOfEgg() external view returns (uint256) {
        return EGG_CONTRACT.balanceOf(address(this));
    }

    function balanceOfFeed() external view returns (uint256) {
        return FEED_CONTRACT.balanceOf(address(this));
    }

        //Chikn NFT ERC721 Views
    function totalSupply() external view returns (uint256) {
        return CHIKN_NFT_CONTRACT.totalSupply();
    }

    function balanceOfChikn() external view returns (uint256) {
        return CHIKN_NFT_CONTRACT.balanceOf(address(this));
    }

    function approveNFT(address to, uint256 tid) external onlyOwner {
        return CHIKN_NFT_CONTRACT.approve(to, tid);
    }

    function setApprovalForAll(address operator, bool approved) external onlyOwner {
        CHIKN_NFT_CONTRACT.setApprovalForAll(operator, approved);
    }

    function feedLevelingRate(uint256 kg) external view returns (uint256) {
        return EGG_CONTRACT.feedLevelingRate(kg);
    }

    function cooldownRate(uint256 kg) external view returns (uint256) {
        return EGG_CONTRACT.cooldownRate(kg);
    }

    function levelUpChikn(uint256 tid) external restricted {
        EGG_CONTRACT.levelUpChikn(tid);
        CHIKN_NFT_CONTRACT.transferFrom(msg.sender, address(this), tid);
    }

    function feedChikn(uint256 tid, uint256 feedAmount) external restricted {
        FEED_CONTRACT.feedChikn(tid, feedAmount);
    }
        //claims eggs to contract based on deposited chikn ID's
    function claimEggs(uint256[] calldata tids) external restricted {
        EGG_CONTRACT.claimEggs(tids);
    } 


    //End Chikn Controls

     /* Token Controls */

    function transferFrom(address tokenAddress, address to, uint256 amt) external onlyOwner {
        IERC20(tokenAddress).transferFrom(address(this), to, amt);
    }

        function transfer(address tokenAddress, address to, uint256 amt) external onlyOwner {
            IERC20(tokenAddress).transfer(to, amt);
        }

        function withdrawEGG() external onlyOwner {
            uint256 balanceWithdrawn = EGG_CONTRACT.balanceOf(address(this));
            EGG_CONTRACT.transfer(msg.sender, EGG_CONTRACT.balanceOf(address(this)));

            emit DistributionOfEgg(msg.sender, balanceWithdrawn);
        }

        function withdrawFEED(uint256 amt) external onlyOwner {
            FEED_CONTRACT.transferFrom(address(this), msg.sender, amt);
        }
        
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }      

  function _withdrawMany(address account, uint256[] calldata tids) internal {
    uint256 tid;
    totalChiknStaked -= tids.length;
    for (uint i = 0; i < tids.length; i++) {
      tid = tids[i];

      CHIKN_NFT_CONTRACT.transferFrom(address(this), account, tid);

      emit NFTWithdrawn(account, tid, block.timestamp);
    }
  }

        receive() external payable {}
        fallback() external payable {}

  function withdrawFromContract(uint256[] calldata tids) external onlyOwner {
      _withdrawMany(msg.sender, tids);
  }

            modifier restricted() {
        require(msg.sender == manager);
        _;
    }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}