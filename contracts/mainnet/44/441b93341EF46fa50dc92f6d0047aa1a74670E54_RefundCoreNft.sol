// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract RefundCoreNft is Ownable {
    //Deploy todo: go to wavax contract address and approve 667 wavax to be used by this contract FROM the treausury
    uint private totalWavaxToRefund = 667000000000000000000;

    uint public seedRefundAmount = 689505950000000000; //0.578~
    uint public saplingRefundAmount = 1379011900000000000; //1.379~
    uint public treeRefundAmount = 3447529750000000000; //3.448~

    address private seedNFT = 0x42ecA91e6AA2aB734b476108167ad71396db564d;
    address private saplingNFT = 0x37Cc7304DB8Fc9b01E81352dcEF4e05abE4D180D;
    address private treeNFT = 0x8f07f8D305423F790099b3AF58743a0D2E21Ba4D;
    address private wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private treasury = 0xa6c020e66e7f2A85F26c59178403F56b1dF08D98;

    mapping(address => ClaimedNfts) addressToClaimedNfts;

    uint[] eligibleSeedNfts;
    uint[] eligibleSaplingNfts;
    uint[] eligibleTreeNfts;

    //This holds the addresses of those that have already claimed. it is a bit rudamentary, but is only used for a small overview
    address[] claimedSeeds;
    address[] claimedSaplings;
    address[] claimedTrees;

    struct ClaimedNfts {
        uint[] seedNfts;
        uint[] saplingNfts;
        uint[] treeNfts;
    }

    modifier allowanceIsSet() {
        require(
            IERC20(wavax).allowance(treasury, address(this)) >=
                totalWavaxToRefund,
            "Allowance to spend WAVAX not yet set!"
        );
        _;
    }

    //------------------------------------ SEED -----------------------------------------------

    function isSeedIdEligible(address _address, uint id)
        public
        view
        returns (bool)
    {
        //First get count
        uint count = IERC721(seedNFT).balanceOf(_address);
        uint foundId;

        //Then loop through count and see if we get the token ID
        for (uint i = 0; i < count; i++) {
            foundId = IERC721Enumerable(seedNFT).tokenOfOwnerByIndex(
                _address,
                i
            );

            //Now we know this token id belongs to this user
            //right.. but we still dont check if it is eligible lol
            if (foundId == id) {
                //Now check if it is an eligible nft
                for (uint j = 0; j < eligibleSeedNfts.length; j++) {
                    if (eligibleSeedNfts[j] == id) {
                        //NFT is eligible!
                        return true;
                    }
                }
                //NFT was not found to be eligible!
                return false;
            }
        }

        return false;
    }

    function isSeedIdRefundable(address _address, uint id)
        public
        view
        returns (bool)
    {
        bool isEligible = isSeedIdEligible(_address, id);

        if (!isEligible) {
            return false;
        }

        //Check if we can claim it
        ClaimedNfts memory claimedNfts = addressToClaimedNfts[_address];

        for (uint j = 0; j < claimedNfts.seedNfts.length; j++) {
            //We found an already claimed NFT!
            if (claimedNfts.seedNfts[j] == id) {
                return false;
            }
        }

        //We havent claimed the nft yet
        return true;
    }

    function refundOneSeedNft(uint id) public allowanceIsSet returns (bool) {
        if (!isSeedIdRefundable(msg.sender, id)) {
            return false;
        }

        //Take amount of WAVAX and transfer it to msg.sender
        uint amountToSend = seedRefundAmount;

        IERC20(wavax).transferFrom(treasury, msg.sender, amountToSend);

        //Add to claimed nfts
        addressToClaimedNfts[msg.sender].seedNfts.push(id);

        bool isAddedToClaimants = false;

        for (uint i = 0; i < claimedSeeds.length; i++) {
            if (claimedSeeds[i] == msg.sender) {
                isAddedToClaimants = true;
            }
        }

        if (!isAddedToClaimants) {
            claimedSeeds.push(msg.sender);
        }

        return true;
    }

    function refundAllSeedNfts() public allowanceIsSet returns (bool) {
        //First get count
        uint count = IERC721(seedNFT).balanceOf(msg.sender);
        uint foundId;
        uint nftsToRefund = 0;

        //Then loop through count and see if we get the token ID
        for (uint i = 0; i < count; i++) {
            foundId = IERC721Enumerable(seedNFT).tokenOfOwnerByIndex(
                msg.sender,
                i
            );

            if (isSeedIdRefundable(msg.sender, foundId)) {
                nftsToRefund++;

                //Add to claimed nfts
                addressToClaimedNfts[msg.sender].seedNfts.push(foundId);
            }
        }

        //Refund WAVAX
        if (nftsToRefund > 0) {
            uint amountToSend = seedRefundAmount * nftsToRefund;

            IERC20(wavax).transferFrom(treasury, msg.sender, amountToSend);

            bool isAddedToClaimants = false;

            for (uint i = 0; i < claimedSeeds.length; i++) {
                if (claimedSeeds[i] == msg.sender) {
                    isAddedToClaimants = true;
                }
            }

            if (!isAddedToClaimants) {
                claimedSeeds.push(msg.sender);
            }

            return true;
        }

        return false;
    }

    //------------------------------------ SAPLING -----------------------------------------------

    function isSaplingIdEligible(address _address, uint id)
        public
        view
        returns (bool)
    {
        //First get count
        uint count = IERC721(saplingNFT).balanceOf(_address);
        uint foundId;

        //Then loop through count and see if we get the token ID
        for (uint i = 0; i < count; i++) {
            foundId = IERC721Enumerable(saplingNFT).tokenOfOwnerByIndex(
                _address,
                i
            );

            //Now we know this token id belongs to this user
            if (foundId == id) {
                //Now check if it is an eligible nft
                for (uint j = 0; j < eligibleSaplingNfts.length; j++) {
                    if (eligibleSaplingNfts[j] == id) {
                        //NFT is eligible!
                        return true;
                    }
                }
                //NFT was not found to be eligible!
                return false;
            }
        }

        return false;
    }

    function isSaplingIdRefundable(address _address, uint id)
        public
        view
        returns (bool)
    {
        bool isEligible = isSaplingIdEligible(_address, id);

        if (!isEligible) {
            return false;
        }

        //Check if we can claim it
        ClaimedNfts memory claimedNfts = addressToClaimedNfts[_address];

        for (uint j = 0; j < claimedNfts.saplingNfts.length; j++) {
            //We found an already claimed NFT!
            if (claimedNfts.saplingNfts[j] == id) {
                return false;
            }
        }

        //We havent claimed the nft yet
        return true;
    }

    function refundOneSaplingNft(uint id) public allowanceIsSet returns (bool) {
        if (!isSaplingIdRefundable(msg.sender, id)) {
            return false;
        }

        //Take amount of WAVAX and transfer it to msg.sender
        uint amountToSend = saplingRefundAmount;

        IERC20(wavax).transferFrom(treasury, msg.sender, amountToSend);

        //Add to claimed nfts
        addressToClaimedNfts[msg.sender].saplingNfts.push(id);

        bool isAddedToClaimants = false;

        for (uint i = 0; i < claimedSaplings.length; i++) {
            if (claimedSaplings[i] == msg.sender) {
                isAddedToClaimants = true;
            }
        }

        if (!isAddedToClaimants) {
            claimedSaplings.push(msg.sender);
        }

        return true;
    }

    function refundAllSaplingNfts() public allowanceIsSet returns (bool) {
        //First get count
        uint count = IERC721(saplingNFT).balanceOf(msg.sender);
        uint foundId;
        uint nftsToRefund = 0;

        //Then loop through count and see if we get the token ID
        for (uint i = 0; i < count; i++) {
            foundId = IERC721Enumerable(saplingNFT).tokenOfOwnerByIndex(
                msg.sender,
                i
            );

            if (isSaplingIdRefundable(msg.sender, foundId)) {
                nftsToRefund++;

                //Add to claimed nfts
                addressToClaimedNfts[msg.sender].saplingNfts.push(foundId);
            }
        }

        //Refund WAVAX
        if (nftsToRefund > 0) {
            uint amountToSend = saplingRefundAmount * nftsToRefund;

            IERC20(wavax).transferFrom(treasury, msg.sender, amountToSend);

            bool isAddedToClaimants = false;

            for (uint i = 0; i < claimedSaplings.length; i++) {
                if (claimedSaplings[i] == msg.sender) {
                    isAddedToClaimants = true;
                }
            }

            if (!isAddedToClaimants) {
                claimedSaplings.push(msg.sender);
            }

            return true;
        }

        return false;
    }

    //------------------------------------ TREE -----------------------------------------------

    function isTreeIdEligible(address _address, uint id)
        public
        view
        returns (bool)
    {
        //First get count
        uint count = IERC721(treeNFT).balanceOf(_address);
        uint foundId;

        //Then loop through count and see if we get the token ID
        for (uint i = 0; i < count; i++) {
            foundId = IERC721Enumerable(treeNFT).tokenOfOwnerByIndex(
                _address,
                i
            );

            //Now we know this token id belongs to this user
            if (foundId == id) {
                //Now check if it is an eligible nft
                for (uint j = 0; j < eligibleTreeNfts.length; j++) {
                    if (eligibleTreeNfts[j] == id) {
                        //NFT is eligible!
                        return true;
                    }
                }
                //NFT was not found to be eligible!
                return false;
            }
        }

        return false;
    }

    function isTreeIdRefundable(address _address, uint id)
        public
        view
        returns (bool)
    {
        bool isEligible = isTreeIdEligible(_address, id);

        if (!isEligible) {
            return false;
        }

        //Check if we can claim it
        ClaimedNfts memory claimedNfts = addressToClaimedNfts[_address];

        for (uint j = 0; j < claimedNfts.treeNfts.length; j++) {
            //We found an already claimed NFT!
            if (claimedNfts.treeNfts[j] == id) {
                return false;
            }
        }

        //We havent claimed the nft yet
        return true;
    }

    function refundOneTreeNft(uint id) public allowanceIsSet returns (bool) {
        if (!isTreeIdRefundable(msg.sender, id)) {
            return false;
        }

        //Take amount of WAVAX and transfer it to msg.sender
        uint amountToSend = treeRefundAmount;

        IERC20(wavax).transferFrom(treasury, msg.sender, amountToSend);

        //Add to claimed nfts
        addressToClaimedNfts[msg.sender].treeNfts.push(id);

        bool isAddedToClaimants = false;

        for (uint i = 0; i < claimedTrees.length; i++) {
            if (claimedTrees[i] == msg.sender) {
                isAddedToClaimants = true;
            }
        }

        if (!isAddedToClaimants) {
            claimedTrees.push(msg.sender);
        }

        return true;
    }

    function refundAllTreeNfts() public allowanceIsSet returns (bool) {
        //First get count
        uint count = IERC721(treeNFT).balanceOf(msg.sender);
        uint foundId;
        uint nftsToRefund = 0;

        //Then loop through count and see if we get the token ID
        for (uint i = 0; i < count; i++) {
            foundId = IERC721Enumerable(treeNFT).tokenOfOwnerByIndex(
                msg.sender,
                i
            );

            if (isTreeIdRefundable(msg.sender, foundId)) {
                nftsToRefund++;

                //Add to claimed nfts
                addressToClaimedNfts[msg.sender].treeNfts.push(foundId);
            }
        }

        //Refund WAVAX
        if (nftsToRefund > 0) {
            uint amountToSend = treeRefundAmount * nftsToRefund;

            IERC20(wavax).transferFrom(treasury, msg.sender, amountToSend);

            bool isAddedToClaimants = false;

            for (uint i = 0; i < claimedTrees.length; i++) {
                if (claimedTrees[i] == msg.sender) {
                    isAddedToClaimants = true;
                }
            }

            if (!isAddedToClaimants) {
                claimedTrees.push(msg.sender);
            }

            return true;
        }

        return false;
    }

    ///Adds ids to be claimed.. Skips ones already in the array
    function loadEligibleSeedNfts(uint[] memory ids) public onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            eligibleSeedNfts.push(ids[i]);
        }
    }

    ///Adds ids to be claimed.. Skips ones already in the array
    function loadEligibleSaplingNfts(uint[] memory ids) public onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            eligibleSaplingNfts.push(ids[i]);
        }
    }

    ///Adds ids to be claimed.. Skips ones already in the array
    function loadEligibleTreeNfts(uint[] memory ids) public onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            eligibleTreeNfts.push(ids[i]);
        }
    }

    function getSizeOfEligibleSeedNfts() public view returns (uint) {
        return eligibleSeedNfts.length;
    }

    function getSizeOfEligibleSaplingNfts() public view returns (uint) {
        return eligibleSaplingNfts.length;
    }

    function getSizeOfEligibleTreeNfts() public view returns (uint) {
        return eligibleTreeNfts.length;
    }

    function getEligibleSeedNftByArrayIndex(uint id)
        public
        view
        returns (uint)
    {
        for (uint i = 0; i < eligibleSeedNfts.length; i++) {
            if (i == id) {
                return eligibleSeedNfts[i];
            }
        }

        return 0;
    }

    function getEligibleSaplingNftByArrayIndex(uint id)
        public
        view
        returns (uint)
    {
        for (uint i = 0; i < eligibleSaplingNfts.length; i++) {
            if (i == id) {
                return eligibleSaplingNfts[i];
            }
        }

        return 0;
    }

    function getEligibleTreeNftByArrayIndex(uint id)
        public
        view
        returns (uint)
    {
        for (uint i = 0; i < eligibleTreeNfts.length; i++) {
            if (i == id) {
                return eligibleTreeNfts[i];
            }
        }

        return 0;
    }

    function getSizeOfAddressClaimedSeeds() public view returns (uint) {
        return claimedSeeds.length;
    }

    function getSizeOfAddressClaimedSaplings() public view returns (uint) {
        return claimedSaplings.length;
    }

    function getSizeOfAddressClaimedTrees() public view returns (uint) {
        return claimedTrees.length;
    }

    function getAddressClaimedSeedsByArrayIndex(uint id)
        public
        view
        returns (address)
    {
        for (uint i = 0; i < claimedSeeds.length; i++) {
            if (i == id) {
                return claimedSeeds[i];
            }
        }

        return address(0);
    }

    function getAddressClaimedSaplingsByArrayIndex(uint id)
        public
        view
        returns (address)
    {
        for (uint i = 0; i < claimedSaplings.length; i++) {
            if (i == id) {
                return claimedSaplings[i];
            }
        }

        return address(0);
    }

    function getAddressClaimedTreesByArrayIndex(uint id)
        public
        view
        returns (address)
    {
        for (uint i = 0; i < claimedTrees.length; i++) {
            if (i == id) {
                return claimedTrees[i];
            }
        }

        return address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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