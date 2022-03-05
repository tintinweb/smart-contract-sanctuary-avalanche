// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PolyientTransfer  {
    uint256  public eth_price;
    address payable public owner;

    struct TokenOwners {
        address new_owner;
        uint256 amount_or_id;
    }

    struct AddressTokenOwners {
        address tokenAddress;
        address new_owner;
        uint256 amount_or_id;
    }

    modifier restricted() {
        require(msg.sender == owner,"Sender is not an owner!");
         _;
    }

    constructor(uint256 _eth_price){
      eth_price = _eth_price;
      owner = payable(msg.sender);
    }

    function setEthPrice(uint256 _eth_price) public restricted{
      eth_price = _eth_price;
    }

   function setOwner(address payable _owner) public restricted{
      owner = _owner;
   }

    function multiNftTransfer(address _nftAddress,uint256[] memory _tokenIds,address _newOwner) payable public{
      require(eth_price == msg.value,"Fee Required");
      require(_tokenIds.length > 0 ,"Please Add Token IDs");

      IERC721 nft = IERC721(_nftAddress);
      require(nft.isApprovedForAll(msg.sender,address(this)) ,"Not Approved");

       for (uint j = 0; j<_tokenIds.length; j++) {  
         uint256 tokenId = _tokenIds[j];
         nft.safeTransferFrom(msg.sender,_newOwner,tokenId);
       }

      if(eth_price > 0){
        owner.transfer(msg.value);
      }

     }

    function multiNftTransferToAssociated(address _nftAddress,TokenOwners[] memory _newTokenOwners) payable public{
      require(eth_price == msg.value,"Fee Required");
      require(_newTokenOwners.length > 0 ,"Associated Tokens Incorrect");

      IERC721 nft = IERC721(_nftAddress);
      require(nft.isApprovedForAll(msg.sender,address(this)) ,"Not Approved");

       for (uint j = 0; j<_newTokenOwners.length; j++) {  
         TokenOwners memory tokenOwner = _newTokenOwners[j];
         nft.safeTransferFrom(msg.sender,tokenOwner.new_owner,tokenOwner.amount_or_id);
       }
       
      if(eth_price > 0){
        owner.transfer(msg.value);
      }
     }

    function multiNftTokensToAssociated(AddressTokenOwners [] memory _AddressTokenOwners) payable public{
      require(eth_price == msg.value,"Fee Required");
      require(_AddressTokenOwners.length > 0 ,"Associated Tokens Incorrect");

      for (uint j = 0; j<_AddressTokenOwners.length; j++) {  
         AddressTokenOwners memory tokenOwner = _AddressTokenOwners[j];
         IERC721 nft = IERC721(tokenOwner.tokenAddress);
         require(nft.isApprovedForAll(msg.sender,address(this)) ,"Not Approved");
         nft.safeTransferFrom(msg.sender,tokenOwner.new_owner,tokenOwner.amount_or_id);
       }
       
      if(eth_price > 0){
        owner.transfer(msg.value);
      }
     }

    function multiAmountToMultiAddress(address _tokenAddress,TokenOwners[] memory _newTokenOwners) payable public{
      require(eth_price == msg.value,"Fee Required");
      require(_newTokenOwners.length > 0 ,"Associated Tokens Incorrect");

      IERC20 token = IERC20(_tokenAddress);

       for (uint j = 0; j<_newTokenOwners.length; j++) {  
         TokenOwners memory tokenOwner = _newTokenOwners[j];
        require(token.allowance(msg.sender,address(this)) >= tokenOwner.amount_or_id,"Not Allowed");
         token.transferFrom(msg.sender,tokenOwner.new_owner,tokenOwner.amount_or_id);
       }
       
      if(eth_price > 0){
        owner.transfer(msg.value);
      }
    }

    function multiTokeAmountToMultiAddress(AddressTokenOwners[] memory _AddressTokenOwners) payable public{
      require(eth_price == msg.value,"send fees");
      require(_AddressTokenOwners.length > 0 ,"associated not found");

       for (uint j = 0; j<_AddressTokenOwners.length; j++) {  
         AddressTokenOwners memory tokenOwner = _AddressTokenOwners[j];
        IERC20 token = IERC20(tokenOwner.tokenAddress);
        require(token.allowance(msg.sender,address(this)) >= tokenOwner.amount_or_id,"Not Allowed");
        token.transferFrom(msg.sender,tokenOwner.new_owner,tokenOwner.amount_or_id);
       }
       
      if(eth_price > 0){
        owner.transfer(msg.value);
      }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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