// this contract helps to stake any ERC1155 NFT . 
// it takes two contract address as constructor argument , 
// - one is ERC1155 NFT contract and 
// - another is ERC20 token contract 
// (as the staking contract gives ERC20 as a staking reward). 
// you have to approve this (setApproveForAll) this staking contract as a operator to transfer NFTS.

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Staking contract deployed to: 0xcef685aeec13dFB6b84de5575A66b114D751744a
// final : 0x223cc057Bd4F64D83b243F04dE77CcfeeEee893c   => minutes
// fnaal : 0x2A21F96AA852F5fB30bd2176cd7934A0D33e9Ef6   => days
contract TrillStaking {
    //staking id
    uint private stakeId;

    //NFT contract
    IERC1155 public NFTContract;
    //ERC20 token contract
    IERC20 public ERC20tokenContract;

    //ERC20 token decimals
    uint8 private tokenDecimals = 9; // (decimal of Trillest token)

    constructor(address _ERC20tokenContract, address _NFTContract) {
        NFTContract = IERC1155(_NFTContract);
        ERC20tokenContract  = IERC20(_ERC20tokenContract);
    }

    //staking details
    struct Stake{
        address stakeOwner;
        uint tokenId;
        uint tokenAmount;
        uint timeOfStaking;
        uint timeOfLastClaim;
    }

    // mapping staking id => Stake
    mapping( uint => Stake) public stakings;

    //event for staking
    event staked(address indexed staker, uint tokenId, uint tokenAmount,uint stakeId);
    //event for stake withdraw
    event unstaked(address indexed staker, uint tokenId,uint withDrawTokenAmount,uint remainingTokenAmount,uint recievedROI);
    //event for claiming rewards
    event rewardClaimed(uint tokenId, uint claimTokenAmount, uint rewardAmount);

    function stake(uint _tokenId) external {

        require(_tokenId < 3, "Token ID should be less than 3");

        uint tokenAmount = NFTContract.balanceOf(msg.sender, _tokenId);
        require(tokenAmount > 0, "You do not own this node!");

        _stakeTokens(_tokenId, tokenAmount, block.timestamp);

    }

    function unstake(uint _tokenId) external {

        require(_tokenId < 3, "Token ID should be less than 3 (0, 1, 2 : we have only 3 nodes)");

        uint yourStakeId = _findStake(msg.sender, _tokenId);
        require(yourStakeId < stakeId, "You've not staked this node yet");

        _unstakeTokens(yourStakeId, stakings[yourStakeId].tokenAmount, block.timestamp);

    }

    function claim(uint _tokenId) external {

        require(_tokenId < 3, "Token ID should be less than 3 (0, 1, 2 : we have only 3 nodes)");

        uint yourStakeId = _findStake(msg.sender, _tokenId);
        require(yourStakeId < stakeId, "You've not staked this node yet");

        _claimRewards(yourStakeId, block.timestamp);

    }

    function getEstimatedReward(address _owner, uint _tokenId) external view returns(uint) {
        require(_tokenId < 3, "Token ID should be less than 3 (0, 1, 2 : we have only 3 nodes)");
        uint yourStakeId = _findStake(/*msg.sender*/_owner, _tokenId);
        require(yourStakeId < stakeId, "You've not staked this node yet");   
        return _calculateROI(yourStakeId, block.timestamp) / (10**tokenDecimals);
    }

    function _stakeTokens(uint _tokenId, uint _tokenAmount, uint currentTimestamp) private {

        Stake memory newStake = Stake(
            msg.sender,
            _tokenId,
            _tokenAmount,
            currentTimestamp,
            currentTimestamp
        );

        stakings[stakeId] = newStake;
        NFTContract.safeTransferFrom(
            newStake.stakeOwner,
            address(this),
            newStake.tokenId,
            newStake.tokenAmount,
            ""
        );

        stakeId++;

        //emit the stake event
        emit staked(msg.sender,_tokenId,_tokenAmount,stakeId);
    }

    // withdraw the staked tokens with ERC20 in return
    function _unstakeTokens(uint _stakeId, uint _unstakeTokenAmount, uint currentTimestamp) private {
        Stake storage stakeInfo = stakings[_stakeId];
        require(stakeInfo.tokenAmount >= _unstakeTokenAmount,"You have less stake balance");
        
        uint ERC20tokenAmount = _claimRewards(_stakeId, currentTimestamp);
        
        //update the new claiming time
        stakeInfo.tokenAmount = stakeInfo.tokenAmount - _unstakeTokenAmount;
        //return the staked tokens
        NFTContract.safeTransferFrom(
            address(this),
            stakeInfo.stakeOwner,
            stakeInfo.tokenId,
            _unstakeTokenAmount,
            ""
        );
        
        //emit the withdraw event
        emit unstaked(
            stakeInfo.stakeOwner,
            stakeInfo.tokenId,
            _unstakeTokenAmount,
            stakeInfo.tokenAmount,
            ERC20tokenAmount
        );
    }

    // claim the reward tokens for staking
    function _claimRewards(uint _stakeId, uint currentTimestamp) private returns(uint) {
        Stake storage stakeInfo = stakings[_stakeId];
        uint ERC20tokenAmount = _calculateROI(_stakeId, currentTimestamp);

        //update the new claiming time
        stakeInfo.timeOfLastClaim = currentTimestamp;
        
        //return the APR w.r.t ERC20
        ERC20tokenContract.transfer(stakeInfo.stakeOwner, ERC20tokenAmount);

        //emit the withdraw event
        emit rewardClaimed(
            stakeInfo.tokenId,
            stakeInfo.tokenAmount,
            ERC20tokenAmount
        );

        return ERC20tokenAmount;
    }

    // iterates the `stakings` array to see if it has the right stake info (otherwise, returns the length of that array)
    function _findStake(address _owner, uint _tokenId) private view  returns(uint) {
        uint i = 0;
        while ( i < stakeId ) {

            Stake storage stakeInfo = stakings[i];

            if ( stakeInfo.stakeOwner == _owner && stakeInfo.tokenId == _tokenId && stakeInfo.tokenAmount > 0 )
                break;
            
            i = i + 1;
        }

        return i;

    }

    function _calculateROI(uint _stakeId, uint currentTimestamp) private view returns(uint){
        
        Stake memory stakeInfo = stakings[_stakeId];
        uint [3] memory rewardAmount = [uint(30), 510, 7800];
        uint stakingPeriod = currentTimestamp - stakeInfo.timeOfLastClaim;
        uint returnPercentage = 100;
        
        if (stakingPeriod >= 30 days){
            returnPercentage = 150;
        } else if(stakingPeriod >= 20 days){
            returnPercentage = 130;
        } else if(stakingPeriod >= 10 days) {
            returnPercentage = 115;
        } else if(stakingPeriod >= 5 days) {
            returnPercentage = 105;
        }

        return 10**tokenDecimals * (
            rewardAmount[stakeInfo.tokenId] *   // reward amount per day
            stakeInfo.tokenAmount *             // token amount (count) staked
            returnPercentage *                  // bonus reward percentage 
            stakingPeriod / 1 days
        ) / 100 ; 
    }

    //we need this function to recieve ERC1155 NFT
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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