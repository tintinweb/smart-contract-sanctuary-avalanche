// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";

import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./ERC2981.sol";

contract Market is IERC721Receiver {
    address public owner;
    address public ownerCandidate;

    address public immutable nftContract;
    address public immutable PTP_TOKEN;

    struct Listing {
        uint256 activeIndexes; // uint128(activeListingIndex),uint128(userActiveListingIndex)
        uint256 id;
        uint256 tokenId;
        uint256 price;
        address owner;
        bool active;
    }

    mapping(uint256 => Listing) public listings;

    // next listing unique identifier
    uint256 public nextListingId;

    uint256[] public activeListings; // list of listingIDs which are active
    mapping(address => uint256[]) public userActiveListings; // list of listingIDs which are active and belong to the user

    /*///////////////////////////////////////////////////////////////
                       MARKET MANAGEMENT SETTINGS
    //////////////////////////////////////////////////////////////*/

    uint256 public marketFeePercent;
    bool public isMarketOpen;
    bool public emergencyDelisting;

    /*///////////////////////////////////////////////////////////////
                        MARKET GLOBAL STATISTICS
    //////////////////////////////////////////////////////////////*/

    uint256 public totalVolume;
    uint256 public totalSales;
    uint256 public highestSalePrice;

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event AddListingEv(
        uint256 listingId,
        uint256 indexed tokenId,
        uint256 price
    );
    event UpdateListingEv(uint256 listingId, uint256 price);
    event CancelListingEv(uint256 listingId);
    event FulfillListingEv(uint256 listingId);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/

    error Percentage0to100();
    error ClosedMarket();
    error InvalidListing();
    error InactiveListing();
    error InvalidOwner();
    error NoActiveListings();
    error WrongIndex();
    error OnlyEmergency();
    error Unauthorized();
    error ZeroAddress();

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    constructor(
        address nft_address,
        uint256 market_fee,
        address ptp_address
    ) {
        owner = msg.sender;

        if (nft_address == address(0x0)) revert ZeroAddress();
        if (ptp_address == address(0x0)) revert ZeroAddress();

        if (market_fee > 100) {
            revert Percentage0to100();
        }

        PTP_TOKEN = ptp_address;
        nftContract = nft_address;

        marketFeePercent = market_fee;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function proposeOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0x0)) revert ZeroAddress();

        ownerCandidate = newOwner;
    }

    function acceptOwnership() external {
        if (ownerCandidate != msg.sender) revert Unauthorized();

        owner = msg.sender;
        emit OwnerUpdated(msg.sender);
    }

    function cancelOwnerProposal() external {
        if (ownerCandidate != msg.sender && owner != msg.sender)
            revert Unauthorized();

        ownerCandidate = address(0x0);
    }

    /*///////////////////////////////////////////////////////////////
                      MARKET MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function openMarket() external onlyOwner {
        if (emergencyDelisting) {
            emergencyDelisting = false;
        }
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        isMarketOpen = false;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function adjustFees(uint256 newMarketFee) external onlyOwner {
        if (newMarketFee > 100) {
            revert Percentage0to100();
        }

        marketFeePercent = newMarketFee;
    }

    // If something goes wrong, we can close the market and enable emergencyDelisting
    //    After that, anyone can delist active listings
    //slither-disable-next-line calls-loop
    function emergencyDelist(uint256[] calldata listingIDs) external {
        if (!(emergencyDelisting && !isMarketOpen)) revert OnlyEmergency();

        uint256 len = listingIDs.length;
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < len; ++i) {
            uint256 id = listingIDs[i];
            Listing memory listing = listings[id];
            if (listing.active) {
                removeActiveListing(listing.activeIndexes >> (8 * 16));
                removeUserActiveListing(
                    listing.owner,
                    uint256(uint128(listing.activeIndexes))
                );

                listings[id].active = false;
                IERC721(nftContract).transferFrom(
                    address(this),
                    listing.owner,
                    listing.tokenId
                );
            }
        }
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransfer(
            ERC20(PTP_TOKEN),
            msg.sender,
            ERC20(PTP_TOKEN).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS READ OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function totalActiveListings() external view returns (uint256) {
        return activeListings.length;
    }

    function getListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 totalListings = nextListingId;
            if (from + length > totalListings) {
                length = totalListings - from;
            }

            Listing[] memory _listings = new Listing[](length);
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < length; ++i) {
                _listings[i] = listings[from + i];
            }
            return _listings;
        }
    }

    function getActiveListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 numActive = activeListings.length;
            if (from + length > numActive) {
                length = numActive - from;
            }

            Listing[] memory _listings = new Listing[](length);
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < length; ++i) {
                _listings[i] = listings[activeListings[from + i]];
            }
            return _listings;
        }
    }

    function getMyActiveListingsCount() external view returns (uint256) {
        return userActiveListings[msg.sender].length;
    }

    function getMyActiveListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 numActive = userActiveListings[msg.sender].length;

            if (from + length > numActive) {
                length = numActive - from;
            }

            Listing[] memory myListings = new Listing[](length);

            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < length; ++i) {
                myListings[i] = listings[
                    userActiveListings[msg.sender][i + from]
                ];
            }
            return myListings;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LISTINGS STORAGE MANIPULATION
    //////////////////////////////////////////////////////////////*/

    /// Moves the last element to the one to be removed
    function removeActiveListing(uint256 index) internal {
        uint256 numActive = activeListings.length;

        if (numActive == 0) revert NoActiveListings();
        if (index >= numActive) revert WrongIndex();

        // cannot underflow
        unchecked {
            uint256 listingID = activeListings[numActive - 1];

            activeListings[index] = listingID;

            listings[listingID].activeIndexes =
                uint256(index << (8 * 16)) |
                uint128(listings[listingID].activeIndexes);
        }
        //slither-disable-next-line costly-loop
        activeListings.pop();
    }

    /// Moves the last element to the one to be removed
    function removeUserActiveListing(address user, uint256 index) internal {
        uint256 numActive = userActiveListings[user].length;

        if (numActive == 0) revert NoActiveListings();
        if (index >= numActive) revert WrongIndex();

        // cannot underflow
        unchecked {
            uint256 listingID = userActiveListings[user][numActive - 1];

            userActiveListings[user][index] = listingID;

            listings[listingID].activeIndexes =
                (listings[listingID].activeIndexes &
                    (type(uint256).max << (8 * 16))) |
                uint128(index);
        }
        userActiveListings[user].pop();
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function addListing(uint256 tokenId, uint256 price) external {
        if (!isMarketOpen) revert ClosedMarket();

        uint256 id;

        // overflow is unrealistic
        unchecked {
            id = nextListingId++;
        }

        uint256[] storage _senderActiveListings = userActiveListings[
            msg.sender
        ];

        listings[id] = Listing(
            (activeListings.length << (8 * 16)) |
                uint128(_senderActiveListings.length),
            id,
            tokenId,
            price,
            msg.sender,
            true
        );

        _senderActiveListings.push(id);
        activeListings.push(id);

        emit AddListingEv(id, tokenId, price);
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

    function updateListing(uint256 id, uint256 price) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (id >= nextListingId) revert InvalidListing();

        Listing storage listing = listings[id];
        if (listing.owner != msg.sender) revert InvalidOwner();

        listing.price = price;
        emit UpdateListingEv(id, price);
    }

    function cancelListing(uint256 id) external {
        if (id >= nextListingId) revert InvalidListing();

        Listing memory listing = listings[id];

        if (!listing.active) revert InactiveListing();
        if (listing.owner != msg.sender) revert InvalidOwner();

        removeActiveListing(listing.activeIndexes >> (8 * 16));
        removeUserActiveListing(
            msg.sender,
            uint256(uint128(listing.activeIndexes))
        );

        delete listings[id];

        emit CancelListingEv(id);

        IERC721(nftContract).transferFrom(
            address(this),
            listing.owner,
            listing.tokenId
        );
    }

    function fulfillListing(uint256 id) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (id >= nextListingId) revert InvalidListing();

        Listing memory listing = listings[id];
        delete listings[id];

        if (!listing.active) revert InactiveListing();
        if (msg.sender == listing.owner) revert InvalidOwner();

        (address royaltyReceiver, uint256 royaltyAmount) = IERC2981Royalties(
            nftContract
        ).royaltyInfo(listing.tokenId, listing.price);

        // Update active listings
        removeActiveListing(listing.activeIndexes >> (8 * 16));
        removeUserActiveListing(
            listing.owner,
            uint256(uint128(listing.activeIndexes))
        );

        // Update global stats
        unchecked {
            totalVolume += listing.price;
            totalSales += 1;
        }

        if (listing.price > highestSalePrice) {
            highestSalePrice = listing.price;
        }

        uint256 marketFee = (listing.price * marketFeePercent) / 100;

        SafeTransferLib.safeTransferFrom(
            ERC20(PTP_TOKEN),
            msg.sender,
            listing.owner,
            listing.price - royaltyAmount - marketFee
        );

        SafeTransferLib.safeTransferFrom(
            ERC20(PTP_TOKEN),
            msg.sender,
            royaltyReceiver,
            royaltyAmount
        );

        SafeTransferLib.safeTransferFrom(
            ERC20(PTP_TOKEN),
            msg.sender,
            address(this),
            marketFee
        );

        emit FulfillListingEv(id);

        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
    }

    function onERC721Received(
        address _operator, // solhint-disable-line
        address _from, // solhint-disable-line
        uint256 _id, // solhint-disable-line
        bytes calldata _data // solhint-disable-line
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./interfaces/IERC2981Royalties.sol";

abstract contract ERC2981 is IERC2981Royalties {
    address public ROYALTY_ADDRESS;
    uint256 public ROYALTY_FEE; // 0 - 100 %

    event ChangeRoyalty(address newAddress, uint256 newFee);

    constructor(address _ROYALTY_ADDRESS, uint256 _ROYALTY_FEE) {
        ROYALTY_ADDRESS = _ROYALTY_ADDRESS;
        ROYALTY_FEE = _ROYALTY_FEE;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == 0x01ffc9a7; //erc165
    }

    function royaltyInfo(
        uint256 _tokenId, // solhint-disable-line
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount) {
        return (ROYALTY_ADDRESS, (_value * ROYALTY_FEE) / 100);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
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