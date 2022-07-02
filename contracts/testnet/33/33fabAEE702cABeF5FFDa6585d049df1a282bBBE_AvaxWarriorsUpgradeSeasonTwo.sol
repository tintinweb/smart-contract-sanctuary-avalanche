// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ReentrancyGuard.sol";

contract AvaxWarriorsUpgradeSeasonTwo is Ownable, ReentrancyGuard {
    IERC721 ERC721;

    uint256 public constant WRS_LOCATION_SCENIC_HEIGHTS = 0xc1d5673acfb4513ab1eb5622302705be5d9f3db9ff0f5bbcae32f1c1abbe8fd5;
    uint256 public constant WRS_LOCATION_GHETTO = 0x0269a6e45de04ed6874f037a3cab2b240208727762974d887a101b82668a576b;
    uint256 public constant WRS_LOCATION_LYS = 0x939177796d7ff6e286815842f520a18be4910dba72fb6f746540cd15d215c7eb;
    uint256 public constant WRS_HELMET_ASH = 0x325217beed7b10b5dd460010783abede2ea829a762384a9f3a5fb138ef6cb684;
    uint256 public constant WRS_HELMET_BLUE_TAC = 0x69188525654120c98d82ed2c0d1a5401d15a74975da36808d88617c6ff954972;
    uint256 public constant WRS_HELMET_FROSTBITE = 0xf70bd89d9247de328c645a23a7ee886d116cf3e50e1026b73aa1d03ef7364521;
    uint256 public constant WRS_HELMET_GARGOYLE = 0xab93d2f59680b9bcc2641352c63d46a592cbfd52809812d68e6af696babf21fc;
    uint256 public constant WRS_HELMET_LAVA = 0xd5d8369243de398efecbe19515a45f202cf0c9a394ad1d545909e1ce5bf0605c;
    uint256 public constant WRS_HELMET_MINTY_SPIT = 0x160fcc29c3e60e19681fe999813b4ec5e20c73adbd63d4b5609e9eee4686d870;
    uint256 public constant WRS_HELMET_OIL_SPILL = 0xaefd2cda268bc941e5aeb597eeab1a26eba7653f92a13cf1efd18f6ed4b3f360;
    uint256 public constant WRS_HELMET_PIXIE_DUST = 0x4d0d6d4e6e9eaa47582fb56a1d20268868a58926d06b662642f7831ee927faa3;
    uint256 public constant WRS_HELMET_RAINBOW_JELLY = 0xb15a89d40e9083888842438280e99cf3252977dbf68e2c12a0c226f8e1ecee6a;
    uint256 public constant WRS_HELMET_SAPPHIRE = 0x1c69a5a017462160fe37a4aec0ad0431d0f5a103943653399fc9015038f05c23;
    uint256 public constant WRS_MUSCLES_ASH = 0x5b8ffc0a35a804af8eedc18bb692673e4fc4349ff9ac2c8f735476099498701e;
    uint256 public constant WRS_MUSCLES_BLUE_TAC = 0x2ab3350e0cf3475e8ac39d6c0208b10458ba9c47706c16da9fc53cdf30f3dee0;
    uint256 public constant WRS_MUSCLES_FROSTBITE = 0x8238586cdc7860a6772578c9e8fb5b8b6c6382ca7edc63e115e7a23316ea6da6;
    uint256 public constant WRS_MUSCLES_GARGOYLE = 0x45712592207afa0ad36cde0b042965bb17c85e1785550cb3a1d1e2bc13109197;
    uint256 public constant WRS_MUSCLES_LAVA = 0x580df20282187643ab797ac5c1ceb77cfe1eb53791b72cfbe6c262bf7cb3e851;
    uint256 public constant WRS_MUSCLES_MINTY_SPIT = 0xf56dcf80d15e04fc6e29f52b2070ba5366eebd76ecb08ac021d921c3bda4407a;
    uint256 public constant WRS_MUSCLES_OIL_SPILL = 0xadfb4f6ff23a5e6085f9ef2195e0418fc46e8016aa2a778e9c19f55e83b3982c;
    uint256 public constant WRS_MUSCLES_PIXIE_DUST = 0xd9dae700b10c9172e2e0ee69756fc44bcacf1acbaeccf3eb9cab294013b64e29;
    uint256 public constant WRS_MUSCLES_RAINBOW_JELLY = 0x18920038c7c51871d5c678703b57347540a9718d373afeff942cedc63d9d42a1;
    uint256 public constant WRS_MUSCLES_SAPPHIRE = 0x4b46d38580e8ec426c164bf6ae3032add6227c2812497c3273dc4a22a88a4d7e;
    uint256 public constant WRS_ARMOUR_ASH = 0xf6aa2107ec566453d8c1d93462de44359c45844ddae36b170dbb3acc79d858f3;
    uint256 public constant WRS_ARMOUR_BLUE_TAC = 0xe400bfca671e088f29efd0652715209bcdf67c36ba5f6831b95750829ade3837;
    uint256 public constant WRS_ARMOUR_FROSTBITE = 0x7589a956282fdd80ae8699b25be03a7b20d01015c77837c605ef72ab403496f0;
    uint256 public constant WRS_ARMOUR_GARGOYLE = 0xbee52bde7fe2450259d6fe43f7113f85e9ac71e982e81ce0c698b4dfd6f9940d;
    uint256 public constant WRS_ARMOUR_LAVA = 0x098b03d37c33f7d0ddbbe5ad60299cd54446b19d3af7c22e6a8cb895d10fa967;
    uint256 public constant WRS_ARMOUR_MINTY_SPIT = 0x2d29c83c9e8221fc0aad468c873a2bc2ff393338d73c9d9eab830fc5e30e9a25;
    uint256 public constant WRS_ARMOUR_OIL_SPILL = 0x2e44f5d7d423c1acdfc11a8a5bc8c61c8da1da57347d6f0cefe216c504696362;
    uint256 public constant WRS_ARMOUR_PIXIE_DUST = 0xdc925bb2fe4e43e239e7d65d9ba16efa6240e10c43d63d8921ad4e5f2985dca4;
    uint256 public constant WRS_ARMOUR_RAINBOW_JELLY = 0xfb695ce0ce718b55b4fd15586253dd3e1c758d68d98cd0ac0c94f7fd7e8e719c;
    uint256 public constant WRS_ARMOUR_SAPPHIRE = 0x70ff93dd87c6598c83def458194d4acefd41ba7130430decaec42797bfb6be0d;
    uint256 public constant WRS_ACCESSORY_GOLDCLOAK = 0x7eafd1403e7aba23624d6bf8961317ee04cdad5c487b45bc78006e7ef6046711;
    uint256 public constant WRS_WEAPON_COMBAT_WINGS = 0xca024fbfbbcf5bebde5c576a39cc20a5856ccdbbe41128956df4afc14dab29b6;   

    enum WRSType { LOCATION, HELMET, MUSCLES, ARMOUR, ACCESSORY, WEAPON }

    struct UpgradeDetails { 
        uint256 location;
        uint256 helmet;
        uint256 muscle;
        uint256 armour;
        uint256 accessory;
        uint256 weapon;
        uint256 tokenIdToUpgrade;
        uint256[] tokenIdsToBurn;
    }

    UpgradeDetails[] _allUpgradingWarriors;

    mapping(uint256 => uint256) private _burnPrices;
    mapping(uint256 => WRSType) private _wrsToType;
    mapping(uint256 => uint256) private _supplys;

    bool public open = false;

    mapping(uint256 => bool) public hasUpgradedAlready;
    mapping(uint256 => UpgradeDetails) public upgradeDetails;
    mapping(address => uint256[]) public upgrading;

    uint256[] _allWarriorsBurnt;

    constructor(address avaxwarrior) {
        ERC721 = IERC721(avaxwarrior);

        setBurnPriceAndSupply(WRS_LOCATION_SCENIC_HEIGHTS, WRSType.LOCATION, 1, 100);
        setBurnPriceAndSupply(WRS_LOCATION_GHETTO, WRSType.LOCATION, 1, 100);
        setBurnPriceAndSupply(WRS_LOCATION_LYS, WRSType.LOCATION, 2, 50);
        setBurnPriceAndSupply(WRS_HELMET_ASH, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_HELMET_BLUE_TAC, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_HELMET_FROSTBITE, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_HELMET_GARGOYLE, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_HELMET_LAVA, WRSType.HELMET, 2, 20);
        setBurnPriceAndSupply(WRS_HELMET_MINTY_SPIT, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_HELMET_OIL_SPILL, WRSType.HELMET, 2, 20);
        setBurnPriceAndSupply(WRS_HELMET_PIXIE_DUST, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_HELMET_RAINBOW_JELLY, WRSType.HELMET, 2, 20);
        setBurnPriceAndSupply(WRS_HELMET_SAPPHIRE, WRSType.HELMET, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_ASH, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_BLUE_TAC, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_FROSTBITE, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_GARGOYLE, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_LAVA, WRSType.MUSCLES, 2, 20);
        setBurnPriceAndSupply(WRS_MUSCLES_MINTY_SPIT, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_OIL_SPILL, WRSType.MUSCLES, 2, 20);
        setBurnPriceAndSupply(WRS_MUSCLES_PIXIE_DUST, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_MUSCLES_RAINBOW_JELLY, WRSType.MUSCLES, 2, 20);
        setBurnPriceAndSupply(WRS_MUSCLES_SAPPHIRE, WRSType.MUSCLES, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_ASH, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_BLUE_TAC, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_FROSTBITE, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_GARGOYLE, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_LAVA, WRSType.ARMOUR, 2, 20);
        setBurnPriceAndSupply(WRS_ARMOUR_MINTY_SPIT, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_OIL_SPILL, WRSType.ARMOUR, 2, 20);
        setBurnPriceAndSupply(WRS_ARMOUR_PIXIE_DUST, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ARMOUR_RAINBOW_JELLY, WRSType.ARMOUR, 2, 20);
        setBurnPriceAndSupply(WRS_ARMOUR_SAPPHIRE, WRSType.ARMOUR, 1, 40);
        setBurnPriceAndSupply(WRS_ACCESSORY_GOLDCLOAK, WRSType.ACCESSORY, 2, 25);
        setBurnPriceAndSupply(WRS_WEAPON_COMBAT_WINGS, WRSType.WEAPON, 3, 20); 
    }

    function updateBurnPrice(uint256 item, uint256 burnPrice) external onlyOwner {
        _burnPrices[item] = burnPrice;
    }

    function updateSupply(uint256 item, uint256 supply) external onlyOwner {
        _supplys[item] = supply;
    }

    function openOnToggle() external onlyOwner {
        open = !open;
    }

    function setBurnPriceAndSupply(uint256 item, WRSType wrsType, uint256 burnPrice, uint256 supply) public {
        _burnPrices[item] = burnPrice;
        _wrsToType[item] = wrsType;
        _supplys[item] = supply;
    }

    function allUpgradingWarriors() external view returns (UpgradeDetails[] memory) {
        return _allUpgradingWarriors;
    }

    function allWarriorsBurnt() external view returns (uint256[] memory) {
        return _allWarriorsBurnt;
    }

    function isInStock (uint256 item) public view returns (bool) {
        return _supplys[item] > 0;
    }

    struct StockResponse { 
        uint256 item;
        bool isInStock;
    }

    function isInStocks (uint256[] memory items) external view returns (StockResponse[] memory) {
        StockResponse[] memory response = new StockResponse[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            response[i] = StockResponse(items[i], isInStock(items[i]));
        }

        return response;
    }

    struct BurnPriceResponse { 
        uint256 item;
        uint256 burnPrice;
    }

    function burnPrices (uint256[] memory items) external view returns (BurnPriceResponse[] memory) {
        BurnPriceResponse[] memory response = new BurnPriceResponse[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            response[i] = BurnPriceResponse(items[i], _burnPrices[items[i]]);
        }

        return response;
    }

    struct WRSTypeResponse { 
        uint256 item;
        WRSType wrsType;
    }

    function wrsToType (uint256[] memory items) external view returns (WRSTypeResponse[] memory) {
        WRSTypeResponse[] memory response = new WRSTypeResponse[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            response[i] = WRSTypeResponse(items[i], _wrsToType[items[i]]);
        }

        return response;
    }

    function upgradeSet(uint256 item, string memory errorMessage) private returns (uint256) {
        // doesnt matter if item doesnt exist as default of uint256 = 0
        require(_supplys[item] > 0, errorMessage);
        _supplys[item]--;
        return _burnPrices[item];
    }

    // must approve the `AvaxWarriorsUpgradeSeasonTwo` for moving tokens on
    function upgrade(UpgradeDetails memory upgradeRequest) public reentrancyGuard {
        require(open, "AvaxWarriorsUpgradeSeasonTwo: Workshop is off");
        require(ERC721.ownerOf(upgradeRequest.tokenIdToUpgrade) == msg.sender, "AvaxWarriorsUpgradeSeasonTwo: You are not the owner of this warrior!");
        require(hasUpgradedAlready[upgradeRequest.tokenIdToUpgrade] == false, "AvaxWarriorsUpgradeSeasonTwo: You have already upgraded this warrior!");

        uint256 requiredWarriorBurn = 0;

        if (upgradeRequest.location != 0) {
            requiredWarriorBurn += upgradeSet(upgradeRequest.location, "AvaxWarriorsUpgradeSeasonTwo: This location is now sold out.");
        }

        if (upgradeRequest.helmet != 0) {
            requiredWarriorBurn += upgradeSet(upgradeRequest.helmet, "AvaxWarriorsUpgradeSeasonTwo: This helmet is now sold out.");
        }

        if (upgradeRequest.muscle != 0) {
            requiredWarriorBurn += upgradeSet(upgradeRequest.muscle, "AvaxWarriorsUpgradeSeasonTwo: This muscle is now sold out.");
        }

        if (upgradeRequest.armour != 0) {
            requiredWarriorBurn += upgradeSet(upgradeRequest.armour, "AvaxWarriorsUpgradeSeasonTwo: This armour is now sold out.");
        }

        if (upgradeRequest.accessory != 0) {
           requiredWarriorBurn += upgradeSet(upgradeRequest.accessory, "AvaxWarriorsUpgradeSeasonTwo: This accessory is now sold out.");
        }

        if (upgradeRequest.weapon != 0) {
           requiredWarriorBurn += upgradeSet(upgradeRequest.weapon, "AvaxWarriorsUpgradeSeasonTwo: This weapon is now sold out.");
        }

        require(upgradeRequest.tokenIdsToBurn.length == requiredWarriorBurn, "AvaxWarriorsUpgradeSeasonTwo: The amount of warriors sent to burn is not enough for the upgrade");

        upgrading[msg.sender].push(upgradeRequest.tokenIdToUpgrade);
        hasUpgradedAlready[upgradeRequest.tokenIdToUpgrade] = true;
        _allUpgradingWarriors.push(upgradeRequest);
        
        for (uint256 i = 0; i < upgradeRequest.tokenIdsToBurn.length; i++) { 
            require(ERC721.ownerOf(upgradeRequest.tokenIdsToBurn[i]) == msg.sender, "AvaxWarriorsUpgradeSeasonTwo: You are not the owner of this warrior so you can not burn!"); 
            _allWarriorsBurnt.push(upgradeRequest.tokenIdsToBurn[i]);
            ERC721.transferFrom(msg.sender, address(0xdead), upgradeRequest.tokenIdsToBurn[i]);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier reentrancyGuard() {
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