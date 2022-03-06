//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IAHB.sol";
import "./Guest.sol";

contract AHBUpgrade {
    using Counters for Counters.Counter;

    IERC20 public stayToken;
    Guest public guestToken;
    IAvaxHotelBusiness public ahb3dToken;

    uint256 public constant STAR_UPGRADE_COUNTDOWN = 1209600;

    Counters.Counter public threeStarsTracker;
    Counters.Counter public fourStarsTracker;
    Counters.Counter public fiveStarsTracker;
    Counters.Counter public sixStarsTracker;
    Counters.Counter public sevenStarsTracker;

    constructor(
        address _stayTokenAddress,
        address _guestTokenAddress,
        address _ahb3dTokenAddress
    ) {
        stayToken = IERC20(_stayTokenAddress);
        guestToken = Guest(_guestTokenAddress);
        ahb3dToken = IAvaxHotelBusiness(_ahb3dTokenAddress);
    }

    function getRoomUpgradePrice(uint256 _tokenId, uint256 _amount)
        public
        view
        returns (uint256)
    {
        IAvaxHotelBusiness.AvaxHotel memory avaxHotel = ahb3dToken.getAvaxHotel(
            _tokenId
        );
        uint256 price = 0;
        for (uint256 i = 1; i < _amount + 1; i++) {
            price = price + (10 * (avaxHotel.rooms + i - 10)**2);
        }
        return price * 10**18;
    }

    function getStarUpgradePrice(uint256 _stars)
        external
        pure
        returns (uint256)
    {
        require(_stars < 8);
        return (_stars * _stars * 100) * 10**18;
    }

    function readStakedHotel(uint256 _tokenId)
        internal
        view
        returns (
            uint256 nftId,
            uint32 lastClaim,
            uint256 claimedReward,
            address owner
        )
    {
        return (guestToken.stakedHotels(_tokenId));
    }

    function upgradeRoom(uint256 _tokenId, uint256 _amount) external {
        (, uint32 lastClaim, , address owner) = readStakedHotel(_tokenId);
        bool isOwner = ahb3dToken.ownerOf(_tokenId) == msg.sender ||
            owner == msg.sender;
        if (!isOwner) {
            require(false, "Not owner of this token");
        }
        if (owner == msg.sender) {
            require(
                uint32(block.timestamp) - 2628000 < lastClaim,
                "Claim must be made within 1 month."
            );
        }
        require(
            stayToken.transferFrom(
                msg.sender,
                0x000000000000000000000000000000000000dEaD,
                getRoomUpgradePrice(_tokenId, _amount)
            )
        );
        require(ahb3dToken.upgradeRooms(_tokenId, _amount));
    }

    function upgradeStar(uint256 _tokenId) external {
        (, , , address owner) = readStakedHotel(_tokenId);
        bool isOwner = ahb3dToken.ownerOf(_tokenId) == msg.sender ||
            owner == msg.sender;
        if (!isOwner) {
            require(false, "Not owner of this token");
        }
        IAvaxHotelBusiness.AvaxHotel memory avaxHotel = ahb3dToken.getAvaxHotel(
            _tokenId
        );

        require(avaxHotel.stars < 7, "Max stars exceed.");
        require(
            block.timestamp - STAR_UPGRADE_COUNTDOWN >
                avaxHotel.lastStarUpgrade,
            "Upgrade is not ready"
        );
        require(
            hasRoomConditionMet(avaxHotel.stars, avaxHotel.rooms),
            "The minimum room requirement is not met."
        );
        require(
            hasLimitConditionMet(avaxHotel.stars),
            "The limit requirement is not met."
        );
        require(ahb3dToken.upgradeStars(_tokenId));
        setStarCounters(avaxHotel.stars);
    }

    function hasLimitConditionMet(uint256 _stars) public view returns (bool) {
        bool isUpgradable = true;

        if (_stars == 2) {
            if (threeStarsTracker.current() > 1114) {
                isUpgradable = false;
            }
        }

        if (_stars == 3) {
            if (fourStarsTracker.current() > 889) {
                isUpgradable = false;
            }
        }

        if (_stars == 4) {
            if (fiveStarsTracker.current() > 501) {
                isUpgradable = false;
            }
        }

        if (_stars == 5) {
            if (sixStarsTracker.current() > 51) {
                isUpgradable = false;
            }
        }

        if (_stars == 6) {
            if (sevenStarsTracker.current() > 6) {
                isUpgradable = false;
            }
        }

        return isUpgradable;
    }

    function hasRoomConditionMet(uint256 _stars, uint256 _rooms)
        public
        pure
        returns (bool)
    {
        bool isUpgradable = true;

        if (_stars == 1) {
            if (_rooms <= 13) {
                isUpgradable = false;
            }
        }

        if (_stars == 2) {
            if (_rooms <= 16) {
                isUpgradable = false;
            }
        }

        if (_stars == 3) {
            if (_rooms <= 19) {
                isUpgradable = false;
            }
        }

        if (_stars == 4) {
            if (_rooms <= 25) {
                isUpgradable = false;
            }
        }

        if (_stars == 5) {
            if (_rooms <= 30) {
                isUpgradable = false;
            }
        }

        if (_stars == 6) {
            if (_rooms <= 40) {
                isUpgradable = false;
            }
        }

        return isUpgradable;
    }

    function setStarCounters(uint256 _stars) internal {
        if (_stars == 2) {
            threeStarsTracker.increment();
        }

        if (_stars == 3) {
            fourStarsTracker.increment();
            threeStarsTracker.decrement();
        }

        if (_stars == 4) {
            fiveStarsTracker.increment();
            fourStarsTracker.decrement();
        }

        if (_stars == 5) {
            sixStarsTracker.increment();
            fiveStarsTracker.decrement();
        }

        if (_stars == 6) {
            sevenStarsTracker.increment();
            sixStarsTracker.decrement();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IAvaxHotelBusiness is IERC721Enumerable {
    struct AvaxHotel {
        uint256 tokenId;
        uint256 rooms;
        uint256 stars;
        uint256 lastStarUpgrade;
        uint256 lastClaim;
        address owner;
        bool staking;
    }

    function getAvaxHotel(uint256 _tokenId)
        external
        view
        returns (AvaxHotel memory);

    function upgradeRooms(uint256 _tokenId, uint256 _amount)
        external
        returns (bool);

    function upgradeStars(uint256 _tokenId) external returns (bool);

    function getOwnerHotels(address hotelOwner)
        external
        view
        returns (AvaxHotel[] memory);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Guest is IERC20 {
    mapping(uint256 => StakedHotelObject) public stakedHotels;

    struct StakedHotelObject {
        uint256 nftId;
        uint32 lastClaim;
        uint256 claimedReward;
        address owner;
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