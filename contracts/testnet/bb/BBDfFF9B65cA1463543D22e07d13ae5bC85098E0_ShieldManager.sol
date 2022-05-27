// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '@thirdweb-dev/contracts/ThirdwebContract.sol';

import '../../interfaces/IERC20.sol';
import '../../interfaces/ICategories.sol';
import '../../interfaces/IEmblemWeaver.sol';
import '../../interfaces/IShieldManager.sol';
import '../../interfaces/IAccessManager.sol';
import '../../utils/tokens/erc721/ERC721.sol';

import '../../libraries/HexStrings.sol';

contract ShieldManager is ThirdwebContract, ERC721, IShieldManager {
	using HexStrings for uint16;

	/*///////////////////////////////////////////////////////////////
													EVENTS
	//////////////////////////////////////////////////////////////*/

	event ShieldBuilt(
		address builder,
		uint256 indexed tokenId,
		bytes32 shieldHash,
		uint16 field,
		uint16[9] hardware,
		uint16 frame,
		uint24[4] colors
	);

	event ShieldEdited(
		address groupMultisig,
		uint256 indexed tokenId,
		bytes32 oldShieldHash,
		bytes32 newShieldHash,
		uint16 field,
		uint16[9] hardware,
		uint16 frame,
		uint24[4] colors
	);

	event ShieldMinted(address account, uint256 indexed tokenId, bytes32 shieldHash);

	event MintingStatus(bool live);

	/*///////////////////////////////////////////////////////////////
													ERRORS
	//////////////////////////////////////////////////////////////*/

	error MintingClosed();

	error DuplicateShield();

	error InvalidShield();

	error ColorError();

	error InvalidMember();

	error IncorrectValue();

	error Unauthorised();

	error GroupMissing();

	error MemberLimitExceeded();

	error NotOwner();

	/*///////////////////////////////////////////////////////////////
												SHIELD	STORAGE
	//////////////////////////////////////////////////////////////*/

	// Contracts
	IEmblemWeaver public immutable emblemWeaver;
	IAccessManager public immutable accessManager;

	// Roundtable Contract Addresses
	address payable public preLaunchWhitelister;
	address payable public roundtableFactory;
	address payable public roundtableRelay;

	// Access Levels
	uint256 constant NONE = uint256(IAccessManager.AccessLevels.NONE);
	uint256 constant EARLY_SHIELD_PASS = uint256(IAccessManager.AccessLevels.EARLY_SHIELD_PASS);
	uint256 constant FREE_SHIELD_PASS = uint256(IAccessManager.AccessLevels.FREE_SHIELD_PASS);
	uint256 constant HALF_PRICE_SHIELD = uint256(IAccessManager.AccessLevels.HALF_PRICE_SHIELD);
	uint256 constant FREE_SHIELD = uint256(IAccessManager.AccessLevels.FREE_SHIELD);
	uint256 constant HALF_PRICE_EDIT = uint256(IAccessManager.AccessLevels.HALF_PRICE_EDIT);
	uint256 constant FREE_EDIT = uint256(IAccessManager.AccessLevels.FREE_EDIT);
	uint256 constant BRONZE = uint256(IAccessManager.AccessLevels.BRONZE);
	uint256 constant SILVER = uint256(IAccessManager.AccessLevels.SILVER);
	uint256 constant GOLD = uint256(IAccessManager.AccessLevels.GOLD);

	// Fees
	uint256 epicFieldFee = 0.05 ether;
	uint256 heroicFieldFee = 0.1 ether;
	uint256 olympicFieldFee = 0.5 ether;
	uint256 legendaryFieldFee = 1 ether;

	uint256 epicHardwareFee = 0.1 ether;
	uint256 doubleHardwareFee = 0.1 ether;
	uint256 multiHardwareFee = 0.15 ether;

	uint256 publicMintPrice = 0.2 ether;

	uint256 private _currentId = 1;
	uint256 public unusedItem = 999;

	bool public publicMintActive = false;

	// transient variable that's immediately cleared after checking for duplicate colors
	mapping(uint24 => bool) private _checkDuplicateColors;
	mapping(uint256 => Shield) private _shields;
	mapping(bytes32 => bool) public shieldHashes;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

	constructor(
		string memory name_,
		string memory symbol_,
		IEmblemWeaver _emblemWeaver,
		IAccessManager _accessManager
	) ERC721(name_, symbol_) {
		owner = msg.sender; // TODO consider this is deployed through thirdweb

		emblemWeaver = _emblemWeaver;

		accessManager = _accessManager;
	}

	// ============ MODIFIERS ============

	modifier onlyOwner() {
		if (msg.sender != owner) revert NotOwner();
		_;
	}

	// ============ OWNER INTERFACE ============

	function collectFees() external onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
		require(success, 'Shields: ether transfer failed');
	}

	function collectERC20(IERC20 erc20) external onlyOwner {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	function setPublicMintActive(bool setting) external onlyOwner {
		publicMintActive = setting;

		emit MintingStatus(setting);
	}

	// Unused item is entered when a shield value is not assigned. Keeping it variable is useful incase we add over 999 items
	function setUnusedItem(uint256 item) external onlyOwner {
		unusedItem = item;
	}

	function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
		publicMintPrice = _publicMintPrice;
	}

	// allows for price adjustments
	function setDistribution(uint256[] calldata itemSettings) external onlyOwner {
		epicFieldFee = itemSettings[0];
		heroicFieldFee = itemSettings[1];
		olympicFieldFee = itemSettings[2];
		legendaryFieldFee = itemSettings[3];
		epicHardwareFee = itemSettings[4];
		doubleHardwareFee = itemSettings[5];
		multiHardwareFee = itemSettings[6];
	}

	function setRoundtableRelay(address payable relay) external onlyOwner {
		roundtableRelay = relay;
	}

	function setRoundtableFactory(address payable factory) external onlyOwner {
		roundtableFactory = factory;
	}

	function ownerMintShields(address t) public onlyOwner {
		// mint batch of passes to owner
	}

	function ownerBuildAndDropShields(Shield[] calldata shields, address t) public onlyOwner {
		// for each shield, build
		//
	}

	// ============ PUBLIC INTERFACE ============

	// TODO consider when WL people can mint
	function mintShieldPass(address to) public payable returns (uint256) {
		// If public mint not active, only WL accounts can mint
		if (!publicMintActive)
			if (!accessManager.roundtableWhitelist(msg.sender, EARLY_SHIELD_PASS)) revert MintingClosed();

		// If mint fee not paid, check if WL or called by a Roundtable account
		if (
			msg.value != publicMintPrice &&
			!(msg.sender == roundtableFactory || msg.sender == roundtableRelay)
		) {
			if (accessManager.roundtableWhitelist(to, FREE_SHIELD_PASS)) {
				accessManager.toggleItemWhitelist(to, FREE_SHIELD_PASS);
			} else revert IncorrectValue();
		}

		_mint(to, _currentId);

		unchecked {
			return _currentId++;
		}
	}

	function buildShield(
		uint16 field,
		uint16[9] calldata hardware,
		uint16 frame,
		uint24[4] memory colors,
		uint256 tokenId
	) external payable {
		if (_shields[tokenId].colors[0] != 0) revert InvalidShield();

		// TODO should be able to build shield if staked in pfpStaker

		if (msg.sender != ownerOf[tokenId]) revert Unauthorised();

		validateColors(colors, field);

		bytes32 tmpHardwareConfig = validConfiguration(hardware);

		bytes32 shieldHash = keccak256(
			abi.encodePacked(
				field.toHexStringNoPrefix(2),
				tmpHardwareConfig,
				frame.toHexStringNoPrefix(2)
			)
		);

		if (shieldHashes[shieldHash]) revert DuplicateShield();
		shieldHashes[shieldHash] = true;

		// TODO revove built. replace with checks on color[0] since this must be set and can not be 0.
		_shields[tokenId] = Shield({
			field: field,
			hardware: hardware,
			frame: frame,
			colors: colors,
			shieldHash: shieldHash,
			hardwareConfiguration: tmpHardwareConfig
		});

		// TODO how do we measure level of a multisig?
		uint256 minterLevel = accessManager.memberLevel(msg.sender);

		uint256 fee;

		ICategories.FieldCategories fieldType = emblemWeaver
			.fieldGenerator()
			.generateField(field, colors)
			.fieldType;

		if (fieldType == ICategories.FieldCategories.EPIC) {
			if (minterLevel < BRONZE) fee += epicFieldFee;
		} else {
			if (fieldType == ICategories.FieldCategories.HEROIC) {
				if (minterLevel < SILVER) fee += heroicFieldFee;
			} else {
				if (fieldType == ICategories.FieldCategories.OLYMPIC) {
					if (minterLevel < GOLD) fee += olympicFieldFee;
				} else {
					if (fieldType == ICategories.FieldCategories.LEGENDARY)
						if (minterLevel < GOLD) fee += legendaryFieldFee;
				}
			}
		}

		ICategories.HardwareCategories hardwareType = emblemWeaver
			.hardwareGenerator()
			.generateHardware(hardware)
			.hardwareType;

		if (hardwareType == ICategories.HardwareCategories.EPIC) {
			if (minterLevel < BRONZE) fee += epicHardwareFee;
		} else {
			if (hardwareType == ICategories.HardwareCategories.DOUBLE) {
				if (minterLevel < SILVER) fee += doubleHardwareFee;
			} else {
				if (hardwareType == ICategories.HardwareCategories.MULTI)
					if (minterLevel < GOLD) fee += multiHardwareFee;
			}
		}

		fee += calculateFrameFee(frame, minterLevel);

		if (msg.value != fee) {
			if (accessManager.roundtableWhitelist(msg.sender, HALF_PRICE_SHIELD)) {
				fee = (fee * 50) / 100;
				accessManager.toggleItemWhitelist(msg.sender, HALF_PRICE_SHIELD);
			}
			if (accessManager.roundtableWhitelist(msg.sender, FREE_SHIELD)) {
				fee = 0;
				accessManager.toggleItemWhitelist(msg.sender, FREE_SHIELD);
			}
			if (msg.value != fee) revert IncorrectValue();
		}

		emit ShieldBuilt(msg.sender, tokenId, shieldHash, field, hardware, frame, colors);
	}

	function editShield(uint256 tokenId, Shield calldata newShield) public payable {
		// TODO should be able to build shield if staked in pfpStaker

		if (msg.sender != ownerOf[tokenId]) revert Unauthorised();

		if (_shields[tokenId].colors[0] == 0) revert InvalidShield();

		validateColors(newShield.colors, newShield.field);

		bytes32 validHardware = validConfiguration(newShield.hardware);

		bytes32 newShieldHash = keccak256(
			abi.encodePacked(
				newShield.field.toHexStringNoPrefix(2),
				validHardware,
				newShield.frame.toHexStringNoPrefix(2)
			)
		);

		if (shieldHashes[newShieldHash]) revert DuplicateShield();

		Shield memory oldShield = _shields[tokenId];

		// Set new shield hash to prevent duplicates, and remove old shield to free design
		shieldHashes[oldShield.shieldHash] = false;
		shieldHashes[newShieldHash] = true;

		uint256 fee;
		uint256 tmpOldPrice;
		uint256 tmpNewPrice;

		if (newShield.field != oldShield.field) {
			tmpOldPrice = calculateFieldFee(
				oldShield.field,
				oldShield.colors,
				accessManager.memberLevel(msg.sender)
			);
			tmpNewPrice = calculateFieldFee(
				newShield.field,
				newShield.colors,
				accessManager.memberLevel(msg.sender)
			);

			fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
		}

		if (validHardware != oldShield.hardwareConfiguration) {
			tmpOldPrice = calculateHardwareFee(oldShield.hardware, accessManager.memberLevel(msg.sender));
			tmpNewPrice = calculateHardwareFee(newShield.hardware, accessManager.memberLevel(msg.sender));

			fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
		}

		if (newShield.frame != oldShield.frame) {
			tmpOldPrice = calculateFrameFee(oldShield.frame, accessManager.memberLevel(msg.sender));
			tmpNewPrice = calculateFrameFee(newShield.frame, accessManager.memberLevel(msg.sender));

			fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
		}

		if (msg.value != fee) {
			if (accessManager.roundtableWhitelist(msg.sender, HALF_PRICE_EDIT)) {
				fee = (fee * 50) / 100;
				accessManager.toggleItemWhitelist(msg.sender, HALF_PRICE_EDIT);
			}
			if (accessManager.roundtableWhitelist(msg.sender, FREE_EDIT)) {
				fee = 0;
				accessManager.toggleItemWhitelist(msg.sender, FREE_EDIT);
			}
			if (msg.value != fee) revert IncorrectValue();
		}

		_shields[tokenId] = newShield;
		_shields[tokenId].hardwareConfiguration = validHardware;
		_shields[tokenId].shieldHash = newShieldHash;

		emit ShieldEdited(
			msg.sender,
			tokenId,
			oldShield.shieldHash,
			newShieldHash,
			newShield.field,
			newShield.hardware,
			newShield.frame,
			newShield.colors
		);
	}

	// ============ PUBLIC VIEW FUNCTIONS ============

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		if (tokenId >= _currentId || tokenId == 0) revert InvalidShield();

		Shield memory shield = _shields[tokenId];

		if (shield.colors[0] != 0) {
			return emblemWeaver.generateShieldURI(shield);
		} else {
			return emblemWeaver.generateShieldPass();
		}
	}

	function totalSupply() public view returns (uint256) {
		unchecked {
			// starts with 1
			return _currentId - 1;
		}
	}

	function shields(uint256 tokenId)
		external
		view
		returns (
			uint16 field,
			uint16[9] memory hardware,
			uint16 frame,
			uint24 color1,
			uint24 color2,
			uint24 color3,
			uint24 color4
		)
	{
		// require(_exists(tokenId), 'Shield: tokenID does not exist');
		Shield memory shield = _shields[tokenId];
		return (
			shield.field,
			shield.hardware,
			shield.frame,
			shield.colors[0],
			shield.colors[1],
			shield.colors[2],
			shield.colors[3]
		);
	}

	function priceInfo()
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		return (
			epicFieldFee,
			heroicFieldFee,
			olympicFieldFee,
			legendaryFieldFee,
			epicHardwareFee,
			doubleHardwareFee,
			multiHardwareFee,
			publicMintPrice
		);
	}

	// ============ INTERNAL INTERFACE ============

	// TODO funcion cannot be declared view error
	function calculateFieldFee(
		uint16 field,
		uint24[4] memory colors,
		uint256 minterLevel
	) internal returns (uint256 fee) {
		ICategories.FieldCategories fieldType = emblemWeaver
			.fieldGenerator()
			.generateField(field, colors)
			.fieldType;

		if (fieldType == ICategories.FieldCategories.EPIC) {
			if (minterLevel < BRONZE) fee += epicFieldFee;
		} else {
			if (fieldType == ICategories.FieldCategories.HEROIC) {
				if (minterLevel < SILVER) fee += heroicFieldFee;
			} else {
				if (fieldType == ICategories.FieldCategories.OLYMPIC) {
					if (minterLevel < GOLD) fee += olympicFieldFee;
				} else {
					if (fieldType == ICategories.FieldCategories.LEGENDARY)
						if (minterLevel < GOLD) fee += legendaryFieldFee;
				}
			}
		}
	}

	function calculateHardwareFee(uint16[9] memory hardware, uint256 minterLevel)
		internal
		returns (uint256 fee)
	{
		ICategories.HardwareCategories hardwareType = emblemWeaver
			.hardwareGenerator()
			.generateHardware(hardware)
			.hardwareType;

		if (hardwareType == ICategories.HardwareCategories.EPIC) {
			if (minterLevel < BRONZE) fee += epicHardwareFee;
		} else {
			if (hardwareType == ICategories.HardwareCategories.DOUBLE) {
				if (minterLevel < SILVER) fee += doubleHardwareFee;
			} else {
				if (hardwareType == ICategories.HardwareCategories.MULTI)
					if (minterLevel < GOLD) fee += multiHardwareFee;
			}
		}
	}

	function calculateFrameFee(uint16 frame, uint256 minterLevel) internal returns (uint256 fee) {
		fee = emblemWeaver.frameGenerator().generateFrame(frame).fee;

		if (frame == 1) {
			if (minterLevel >= BRONZE) fee = 0;
		} else {
			if (frame == 2 || frame == 3) {
				if (minterLevel >= SILVER) fee = 0;
			} else {
				if (frame == 4) {
					if (minterLevel >= GOLD) fee = 0;
				} else {
					if (frame == 5)
						if (minterLevel >= GOLD) fee = 0;
				}
			}
		}
	}

	function validConfiguration(uint16[9] calldata hardware) internal pure returns (bytes32) {
		string memory fullHardware;
		string memory tmp;

		// Will not over or underflow due to i > 0 check and array length = 9
		unchecked {
			for (uint16 i; i < 9; ) {
				if (i > 0) {
					// if new hardware item, generate the padded string
					if (hardware[i] != hardware[i - 1]) tmp = hardware[i].toHexStringNoPrefix(2);
					fullHardware = string(abi.encodePacked(fullHardware, tmp));
				} else {
					tmp = hardware[i].toHexStringNoPrefix(2);
					fullHardware = tmp;
				}
				++i;
			}
		}

		return keccak256(bytes(fullHardware));
	}

	function validateColors(uint24[4] memory colors, uint16 field) internal {
		if (field == 0) {
			checkExistsDupsMax(colors, 1);
		} else if (field <= 242) {
			checkExistsDupsMax(colors, 2);
		} else if (field <= 293) {
			checkExistsDupsMax(colors, 3);
		} else {
			checkExistsDupsMax(colors, 4);
		}
	}

	function checkExistsDupsMax(uint24[4] memory colors, uint8 nColors) private {
		for (uint8 i = 0; i < nColors; i++) {
			if (_checkDuplicateColors[colors[i]] == true) revert ColorError();
			if (!emblemWeaver.fieldGenerator().colorExists(colors[i])) revert ColorError();
			_checkDuplicateColors[colors[i]] = true;
		}
		for (uint8 i = 0; i < nColors; i++) {
			_checkDuplicateColors[colors[i]] = false;
		}
		for (uint8 i = nColors; i < 4; i++) {
			if (colors[i] != 0) revert ColorError();
		}
	}

	function padString(string memory s) internal pure returns (string memory) {
		if (bytes(s).length < 3)
			for (uint256 i = 0; i <= 3 - bytes(s).length; i++) {
				s = string(abi.encodePacked('0', s));
			}
		return string(s);
	}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./feature/Ownable.sol";
import "./interfaces/IContractDeployer.sol";

contract ThirdwebContract is Ownable {
    uint256 private hasSetOwner;

    /// @dev Initializes the owner of the contract.
    function tw_initializeOwner(address deployer) external {
        require(hasSetOwner == 0, "Owner already initialized");
        hasSetOwner = 1;
        owner = deployer;
    }

    /// @dev Returns whether owner can be set
    function _canSetOwner() internal virtual override returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Enable access to the original contract deployer in the constructor. If this function is called outside of a constructor, it will return address(0) instead.
    function _contractDeployer() internal view returns (address) {
        if (address(this).code.length == 0) {
            try IContractDeployer(msg.sender).getContractDeployer(address(this)) returns (address deployer) {
                return deployer;
            } catch {
                return address(0);
            }
        }
        return address(0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/// @dev Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface ICategories {
	// enum FieldCategories {
	//     MYTHIC,
	//     HERALDIC
	// }

	// enum HardwareCategories {
	//     STANDARD,
	//     SPECIAL
	// }
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		OLYMPIC,
		LEGENDARY
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IShieldManager.sol';
import './IFrameGenerator.sol';
import './IFieldGenerator.sol';
import './IHardwareGenerator.sol';

/// @dev Generate Customizable Shields
interface IEmblemWeaver {
	function fieldGenerator() external returns (IFieldGenerator);

	function hardwareGenerator() external returns (IHardwareGenerator);

	function frameGenerator() external returns (IFrameGenerator);

	function generateShieldPass() external pure returns (string memory);

	function generateShieldURI(IShieldManager.Shield memory shield)
		external
		view
		returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

/// @dev Build Customizable Shields for an NFT
interface IShieldManager {
	struct Shield {
		uint16 field;
		uint16[9] hardware;
		uint16 frame;
		uint24[4] colors;
		bytes32 shieldHash;
		bytes32 hardwareConfiguration;
	}

	function mintShieldPass(address to) external payable returns (uint256);

	function buildShield(
		uint16 field,
		uint16[9] memory hardware,
		uint16 frame,
		uint24[4] memory colors,
		uint256 tokenId
	) external payable;

	function editShield(uint256 tokenId, Shield memory newShield) external payable;

	function shields(uint256 tokenId)
		external
		view
		returns (
			uint16 field,
			uint16[9] memory hardware,
			uint16 frame,
			uint24 color1,
			uint24 color2,
			uint24 color3,
			uint24 color4
			// ShieldBadge shieldBadge
		);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

/// @dev Access Level Manager for Roundtable
interface IAccessManager {
	enum AccessLevels {
		NONE,
		EARLY_SHIELD_PASS,
		FREE_SHIELD_PASS,
		HALF_PRICE_SHIELD,
		FREE_SHIELD,
		HALF_PRICE_EDIT,
		FREE_EDIT,
		BASIC,
		BRONZE,
		SILVER,
		GOLD
	}

	// resaleRoyalty is based off 10000 basis points (eg. resaleRoyalty = 100 => 1.00%)
	struct Item {
		bool live;
		uint256 price;
		uint256 maxSupply;
		uint256 currentSupply;
		uint256 accessLevel;
		uint256 resaleRoyalty;
	}

	function memberLevel(address) external view returns (uint256);

	function roundtableWhitelist(address, uint256) external view returns (bool);

	function toggleItemWhitelist(address, uint256) external;

	function addItem(
		uint256 price,
		uint256 itemSupply,
		uint256 accessLevel,
		uint256 resaleRoyalty
	) external;

	function mintItem(uint256, address) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// License-Identifier: AGPL-3.0-only
interface ERC721TokenReceiver {
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation.
abstract contract ERC721 {
	/*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

	error NotApproved();

	error NotTokenOwner();

	error InvalidRecipient();

	error SignatureExpired();

	error InvalidSignature();

	error AlreadyMinted();

	error NotMinted();

	/*///////////////////////////////////////////////////////////////
                            METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

	string public name;

	string public symbol;

	function tokenURI(uint256 tokenId) public view virtual returns (string memory);

	/*///////////////////////////////////////////////////////////////
                            ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(address => uint256) public balanceOf;

	mapping(uint256 => address) public ownerOf;

	mapping(uint256 => address) public getApproved;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/

	bytes32 public constant PERMIT_TYPEHASH =
		keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');

	bytes32 public constant PERMIT_ALL_TYPEHASH =
		keccak256('Permit(address owner,address spender,uint256 nonce,uint256 deadline)');

	uint256 internal immutable INITIAL_CHAIN_ID;

	bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

	mapping(uint256 => uint256) public nonces;

	mapping(address => uint256) public noncesForAll;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(string memory name_, string memory symbol_) {
		name = name_;

		symbol = symbol_;

		INITIAL_CHAIN_ID = block.chainid;

		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
	}

	/*///////////////////////////////////////////////////////////////
                            ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

	function approve(address spender, uint256 tokenId) public virtual {
		address owner = ownerOf[tokenId];

		if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NotApproved();

		getApproved[tokenId] = spender;

		emit Approval(owner, spender, tokenId);
	}

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function transfer(address to, uint256 tokenId) public virtual returns (bool) {
		if (msg.sender != ownerOf[tokenId]) revert NotTokenOwner();

		if (to == address(0)) revert InvalidRecipient();

		// underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow
		unchecked {
			balanceOf[msg.sender]--;

			balanceOf[to]++;
		}

		delete getApproved[tokenId];

		ownerOf[tokenId] = to;

		emit Transfer(msg.sender, to, tokenId);

		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual {
		if (from != ownerOf[tokenId]) revert NotTokenOwner();

		if (to == address(0)) revert InvalidRecipient();

		if (
			msg.sender != from &&
			msg.sender != getApproved[tokenId] &&
			!isApprovedForAll[from][msg.sender]
		) revert NotApproved();

		// underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow
		unchecked {
			balanceOf[from]--;

			balanceOf[to]++;
		}

		delete getApproved[tokenId];

		ownerOf[tokenId] = to;

		emit Transfer(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual {
		transferFrom(from, to, tokenId);

		if (
			to.code.length != 0 &&
			ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, '') !=
			ERC721TokenReceiver.onERC721Received.selector
		) revert InvalidRecipient();
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public virtual {
		transferFrom(from, to, tokenId);

		if (
			to.code.length != 0 &&
			ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
			ERC721TokenReceiver.onERC721Received.selector
		) revert InvalidRecipient();
	}

	/*///////////////////////////////////////////////////////////////
                            ERC-165 LOGIC
    //////////////////////////////////////////////////////////////*/

	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x80ac58cd || // ERC-165 Interface ID for ERC-721
			interfaceId == 0x5b5e139f || // ERC-165 Interface ID for ERC-165
			interfaceId == 0x01ffc9a7; // ERC-165 Interface ID for ERC-721 Metadata
	}

	/*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		address owner = ownerOf[tokenId];

		// cannot realistically overflow on human timescales
		unchecked {
			bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					DOMAIN_SEPARATOR(),
					keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
				)
			);

			address recoveredAddress = ecrecover(digest, v, r, s);

			if (recoveredAddress == address(0)) revert InvalidSignature();

			if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress])
				revert InvalidSignature();
		}

		getApproved[tokenId] = spender;

		emit Approval(owner, spender, tokenId);
	}

	function permitAll(
		address owner,
		address operator,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		// cannot realistically overflow on human timescales
		unchecked {
			bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					DOMAIN_SEPARATOR(),
					keccak256(
						abi.encode(PERMIT_ALL_TYPEHASH, owner, operator, noncesForAll[owner]++, deadline)
					)
				)
			);

			address recoveredAddress = ecrecover(digest, v, r, s);

			if (recoveredAddress == address(0)) revert InvalidSignature();

			if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress])
				revert InvalidSignature();
		}

		isApprovedForAll[owner][operator] = true;

		emit ApprovalForAll(owner, operator, true);
	}

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
	}

	function _computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256(
						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
					),
					keccak256(bytes(name)),
					keccak256(bytes('1')),
					block.chainid,
					address(this)
				)
			);
	}

	/*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

	function _mint(address to, uint256 tokenId) internal virtual {
		// // Added to force safe mint - check revert string, error 'function selector was not recognized and there's no fallback function' seen in testing
		// require(
		// 	to.code.length == 0 ||
		// 		ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, '') ==
		// 		ERC721TokenReceiver.onERC721Received.selector,
		// 	'UNSAFE_RECIPIENT'
		// );

		if (to == address(0)) revert InvalidRecipient();

		if (ownerOf[tokenId] != address(0)) revert AlreadyMinted();

		// cannot realistically overflow on human timescales
		unchecked {
			balanceOf[to]++;
		}

		ownerOf[tokenId] = to;

		emit Transfer(address(0), to, tokenId);
	}

	function _burn(uint256 tokenId) internal virtual {
		address owner = ownerOf[tokenId];

		if (ownerOf[tokenId] == address(0)) revert NotMinted();

		// ownership check ensures no underflow
		unchecked {
			balanceOf[owner]--;
		}

		delete ownerOf[tokenId];

		delete getApproved[tokenId];

		emit Transfer(owner, address(0), tokenId);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IOwnable.sol";

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public override owner;

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) public override {
        require(_canSetOwner(), "Not authorized");

        address _prevOwner = owner;
        owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractDeployer {
    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a contract is deployed.
    event ContractDeployed(address indexed deployer, address indexed publisher, address deployedContract);

    /**
     *  @notice Deploys an instance of a published contract directly.
     *
     *  @param publisher        The address of the publisher.
     *  @param contractBytecode The bytecode of the contract to deploy.
     *  @param constructorArgs  The encoded constructor args to deploy the contract with.
     *  @param salt             The salt to use in the CREATE2 contract deployment.
     *  @param value            The native token value to pass to the contract on deployment.
     *  @param publishMetadataUri     The publish metadata URI for the contract to deploy.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstance(
        address publisher,
        bytes memory contractBytecode,
        bytes memory constructorArgs,
        bytes32 salt,
        uint256 value,
        string memory publishMetadataUri
    ) external returns (address deployedAddress);

    /**
     *  @notice Deploys a clone pointing to an implementation of a published contract.
     *
     *  @param publisher        The address of the publisher.
     *  @param implementation   The contract implementation for the clone to point to.
     *  @param initializeData   The encoded function call to initialize the contract with.
     *  @param salt             The salt to use in the CREATE2 contract deployment.
     *  @param value            The native token value to pass to the contract on deployment.
     *  @param publishMetadataUri     The publish metadata URI and for the contract to deploy.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstanceProxy(
        address publisher,
        address implementation,
        bytes memory initializeData,
        bytes32 salt,
        uint256 value,
        string memory publishMetadataUri
    ) external returns (address deployedAddress);

    function getContractDeployer(address _contract) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
    struct FrameSVGs {
        IFrameSVGs frameSVGs1;
        IFrameSVGs frameSVGs2;
    }

    /// @param Frame uint representing Frame selection
    /// @return FrameData containing svg snippet and Frame title and Frame type
    function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IFieldSVGs.sol';
import './IColors.sol';

/// @dev Generate Field SVG
interface IFieldGenerator {
	/// @param field uint representing field selection
	/// @param colors to be rendered in the field svg
	/// @return FieldData containing svg snippet and field title
	function generateField(uint16 field, uint24[4] memory colors)
		external
		view
		returns (IFieldSVGs.FieldData memory);

	event ColorAdded(uint24 color, string title);

	struct Color {
		string title;
		bool exists;
	}

	function addColors(uint24[] calldata colors, string[] calldata titles) external;

	/// @notice Returns true if color exists in contract, else false.
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorExists(uint24 color) external view returns (bool);

	/// @notice Returns the title string corresponding to the 3-byte color
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorTitle(uint24 color) external view returns (string memory);

	struct FieldSVGs {
		IFieldSVGs fieldSVGs1;
		IFieldSVGs fieldSVGs2;
		IFieldSVGs fieldSVGs3;
		IFieldSVGs fieldSVGs4;
		IFieldSVGs fieldSVGs5;
		IFieldSVGs fieldSVGs6;
		IFieldSVGs fieldSVGs7;
		IFieldSVGs fieldSVGs8;
		IFieldSVGs fieldSVGs9;
		IFieldSVGs fieldSVGs10;
		IFieldSVGs fieldSVGs11;
		IFieldSVGs fieldSVGs12;
		IFieldSVGs fieldSVGs13;
		IFieldSVGs fieldSVGs14;
		IFieldSVGs fieldSVGs15;
		IFieldSVGs fieldSVGs16;
		IFieldSVGs fieldSVGs17;
		IFieldSVGs fieldSVGs18;
		IFieldSVGs fieldSVGs19;
		IFieldSVGs fieldSVGs20;
		IFieldSVGs fieldSVGs21;
		IFieldSVGs fieldSVGs22;
		IFieldSVGs fieldSVGs23;
		IFieldSVGs fieldSVGs24;
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {
	/// @param hardware uint representing hardware selection
	/// @return HardwareData containing svg snippet and hardware title and hardware type
	function generateHardware(uint16[9] calldata hardware)
		external
		view
		returns (IHardwareSVGs.HardwareData memory);

	struct HardwareSVGs {
		IHardwareSVGs hardwareSVGs1;
		IHardwareSVGs hardwareSVGs2;
		IHardwareSVGs hardwareSVGs3;
		IHardwareSVGs hardwareSVGs4;
		IHardwareSVGs hardwareSVGs5;
		IHardwareSVGs hardwareSVGs6;
		IHardwareSVGs hardwareSVGs7;
		IHardwareSVGs hardwareSVGs8;
		IHardwareSVGs hardwareSVGs9;
		IHardwareSVGs hardwareSVGs10;
		IHardwareSVGs hardwareSVGs11;
		IHardwareSVGs hardwareSVGs12;
		IHardwareSVGs hardwareSVGs13;
		IHardwareSVGs hardwareSVGs14;
		IHardwareSVGs hardwareSVGs15;
		IHardwareSVGs hardwareSVGs16;
		IHardwareSVGs hardwareSVGs17;
		IHardwareSVGs hardwareSVGs18;
		IHardwareSVGs hardwareSVGs19;
		IHardwareSVGs hardwareSVGs20;
		IHardwareSVGs hardwareSVGs21;
		IHardwareSVGs hardwareSVGs22;
		IHardwareSVGs hardwareSVGs23;
		IHardwareSVGs hardwareSVGs24;
		IHardwareSVGs hardwareSVGs25;
		IHardwareSVGs hardwareSVGs26;
		IHardwareSVGs hardwareSVGs27;
		IHardwareSVGs hardwareSVGs28;
		IHardwareSVGs hardwareSVGs29;
		IHardwareSVGs hardwareSVGs30;
		IHardwareSVGs hardwareSVGs31;
		IHardwareSVGs hardwareSVGs32;
		IHardwareSVGs hardwareSVGs33;
		IHardwareSVGs hardwareSVGs34;
		IHardwareSVGs hardwareSVGs35;
		IHardwareSVGs hardwareSVGs36;
		IHardwareSVGs hardwareSVGs37;
		IHardwareSVGs hardwareSVGs38;
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IFrameSVGs {
    struct FrameData {
        string title;
        uint256 fee;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IFieldSVGs {
    struct FieldData {
        string title;
        ICategories.FieldCategories fieldType;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface IColors {
    event ColorAdded(uint24 color, string title);

    struct Color {
        string title;
        bool exists;
    }

    /// @notice Returns true if color exists in contract, else false.
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorExists(uint24 color) external view returns (bool);

    /// @notice Returns the title string corresponding to the 3-byte color
    /// @param color 3-byte uint representing color
    /// @return true or false
    function colorTitle(uint24 color) external view returns (string memory);
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}