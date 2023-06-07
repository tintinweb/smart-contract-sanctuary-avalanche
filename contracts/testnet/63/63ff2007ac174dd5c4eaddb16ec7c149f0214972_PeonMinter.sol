// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

import {IPeonsV2} from "./interfaces/IPeonsV2.sol";
import {IPeonMinter} from "./interfaces/IPeonMinter.sol";

/**
 * @title PeonMinter
 * @notice Contract used to burn PeonTokens, roll Peons V2 (while burning Pickaxes) and mint Peons V2, when roll accepted
 */
contract PeonMinter is Ownable2Step, IPeonMinter {
    //* Public variables */

    /**
     * @dev The Pickaxes NFT contract
     */
    IERC721 public pickaxes;

    /**
     * @dev The Rich Peon Poor Peon NFT contract
     */
    IERC721 public peonToken;

    /**
     * @dev The Peons V2 NFT contract
     */
    IPeonsV2 public peonsV2;

    /**
     * @dev Mapping from user address to the amount of rerolls left
     */
    mapping(address => uint256) public rerollAmount;

    /**
     * @dev Mapping from user address to currently rolled Peon data
     */
    mapping(address => RolledPeonData) public currentlyRolledPeon;

    /**
     * @dev Amount of Rare Peons that are reserved for Golden PeonToken Burners
     */
    uint256 public rarePeonsReserved = 561;

    /**
     * @dev Amount of Unique Peons that are reserved for Diamond PeonToken Burners
     */
    uint256 public uniquePeonsReserved = 8;

    //* Public constants */

    /**
     * @dev Time, that Peon can be rolled after last reroll
     */
    uint256 public constant TIME_TO_ROLL = 5 minutes;

    /**
     * @dev When PeonTokens can be burned to roll Peons V2
     */
    uint256 public mintStartTime;

    //* Private variables */

    /**
     * @dev Address where the burned tokens are sent
     */
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
     * @dev Increases with every pseudorandomness usage
     */
    uint256 private _randomnessNonce;

    /**
     * @dev Mapping from PeonClass to array of Peons that are not minted yet
     */
    mapping(PeonClass => uint16[]) private _peonClassToUnmintedIds;

    /**
     * @dev Packed data about Pickaxe Types
     * Every byte stores data about 2 Pickaxes
     */
    bytes private constant _pickaxeTypes =
        "\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x30\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x30\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x01\x00\x00\x01\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x10\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x30\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x02\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";

    //* Constructor */
    /**
     * @notice Constructor
     * @param _pickaxes address of the Pickaxes contract
     * @param _peonToken address of the Peon Token contract
     * @param _peonsV2 address of the PeonsV2 contract
     */
    constructor(address _pickaxes, address _peonToken, address _peonsV2, uint256 _mintStartTime) {
        // 30 unique, 1656 rich, 3314 any = 5000
        _peonClassToUnmintedIds[PeonClass.UNIQUE] = new uint16[](30);
        _peonClassToUnmintedIds[PeonClass.RICH] = new uint16[](1656);
        _peonClassToUnmintedIds[PeonClass.ANY] = new uint16[](3314);
        pickaxes = IERC721(_pickaxes);
        peonToken = IERC721(_peonToken);
        peonsV2 = IPeonsV2(_peonsV2);
        mintStartTime = _mintStartTime;
    }

    //* External view functions */

    //* TODO test function

    function showArray(PeonClass class, uint256 start, uint256 amount) external view returns (uint16[] memory) {
        uint16[] memory result = new uint16[](amount);
        for (uint256 i = 0; i < amount; i++) {
            result[i] = _peonClassToUnmintedIds[class][start + i];
        }
        return result;
    }

    /**
     * @notice Returns the amount of Peons available to roll for a given class
     * @param class PeonClass to check
     * @return amount of Peons available to roll
     */
    function getAmountAvailable(PeonClass class) external view returns (uint256) {
        return _peonClassToUnmintedIds[class].length;
    }

    //* External functions */

    /**
     * @notice Burns a Peon Token and rolls a new Peon V2
     * @dev Doesn't mint the new Peon V2 yet - needs to be accepted by user
     * @param peonTokenId Peon Token to burn
     */
    function rollPeonFirstTime(uint256 peonTokenId) external {
        if (block.timestamp < mintStartTime) {
            revert PeonMinter__NotStarted();
        }

        if (currentlyRolledPeon[msg.sender].rollTimestamp != 0) {
            revert PeonMinter__PendingReroll();
        }

        PeonTokenType burnedPeonTokenType = _checkPeonTokenType(peonTokenId);
        _verifyOwnership(peonToken, peonTokenId);
        _burn(peonToken, peonTokenId);

        if (burnedPeonTokenType == PeonTokenType.DIAMOND) {
            uniquePeonsReserved -= 1;
            _rollPeon(PeonClass.UNIQUE, PeonTokenType.DIAMOND);
        } else if (burnedPeonTokenType == PeonTokenType.GOLDEN) {
            rarePeonsReserved -= 1;
            _rollRareOrUnique(PeonTokenType.GOLDEN);
        } else if (burnedPeonTokenType == PeonTokenType.REGULAR) {
            _rollAny(PeonTokenType.REGULAR);
        }
    }

    /**
     * @notice Mints rolled Peon V2
     * @dev Can only be called by the user who burned the Peon Token
     */
    function acceptPeon() external {
        RolledPeonData memory rolledPeonData = currentlyRolledPeon[msg.sender];
        if (rolledPeonData.rollTimestamp == 0) {
            revert PeonMinter__NoActiveReroll();
        }
        uint256 acceptedPeon = rolledPeonData.rolledPeon;
        delete currentlyRolledPeon[msg.sender];
        peonsV2.mint(msg.sender, acceptedPeon);
        emit PeonAccepted(msg.sender, acceptedPeon);
    }

    /**
     * @notice Roll a new Peon V2, when rerrol is available
     * @dev Can be called only before TIME_TO_ROLL passed
     */
    function rollPeonWithoutPickaxe() external {
        RolledPeonData memory rolledPeonData = currentlyRolledPeon[msg.sender];
        _checkRerollTimestamp(rolledPeonData.rollTimestamp);

        if (rerollAmount[msg.sender] == 0) {
            revert PeonMinter__NotEnoughRerolls();
        }
        rerollAmount[msg.sender] -= 1;

        _chooseCategoryAndRoll(rolledPeonData.peonTokenBurned);
    }

    /**
     * @notice Roll a new Peon V2, burning a Pickaxe (BRONZE, SILVER, GOLD, DIAMOND types only) and adding credits for rerolls
     * @dev Can be called only before TIME_TO_ROLL passed
     * @param pickaxeToBurn Pickaxe to burn
     */
    function rollPeonWithOnePickaxe(uint256 pickaxeToBurn) external {
        RolledPeonData memory rolledPeonData = currentlyRolledPeon[msg.sender];
        _checkRerollTimestamp(rolledPeonData.rollTimestamp);

        PickaxeType pickaxeType = _checkPickaxeType(pickaxeToBurn);
        _verifyOwnership(pickaxes, pickaxeToBurn);
        _burn(pickaxes, pickaxeToBurn);
        if (pickaxeType == PickaxeType.DIAMOND) {
            _rollPeon(PeonClass.UNIQUE, PeonTokenType.DIAMOND);
            return;
        } else {
            //includes -1 from rolling inside _addRerolls here
            _addRerolls(pickaxeType);
        }

        _chooseCategoryAndRoll(rolledPeonData.peonTokenBurned);
    }

    /**
     * @notice Roll a new Peon V2, burning exactly two Pickaxes (IRON type only)
     * @dev Can be called only before TIME_TO_ROLL passed
     * @param pickaxeIds Pickaxes to burn
     */
    function rollPeonWithIronPickaxes(uint256[] calldata pickaxeIds) external {
        if (pickaxeIds.length != 2) {
            revert PeonMinter__WrongAmount();
        }
        RolledPeonData memory rolledPeonData = currentlyRolledPeon[msg.sender];
        _checkRerollTimestamp(rolledPeonData.rollTimestamp);

        if (
            _checkPickaxeType(pickaxeIds[0]) != PickaxeType.IRON || _checkPickaxeType(pickaxeIds[1]) != PickaxeType.IRON
        ) {
            revert PeonMinter__WrongPickaxeType();
        }
        _verifyOwnership(pickaxes, pickaxeIds[0]);
        _verifyOwnership(pickaxes, pickaxeIds[1]);
        _burn(pickaxes, pickaxeIds[0]);
        _burn(pickaxes, pickaxeIds[1]);

        _chooseCategoryAndRoll(rolledPeonData.peonTokenBurned);
    }

    /**
     * @notice Burn any even amount of pickaxes (IRON type only) and add credits for rerolls
     * @param pickaxeIds Pickaxes to burn
     */
    function burnIronPickaxesForRerolls(uint256[] calldata pickaxeIds) external {
        uint256 pickaxesAmount = pickaxeIds.length;
        if (pickaxesAmount % 2 != 0) {
            revert PeonMinter__WrongAmount();
        }

        for (uint256 i = 0; i < pickaxesAmount;) {
            if (
                _checkPickaxeType(pickaxeIds[i]) != PickaxeType.IRON
                    || _checkPickaxeType(pickaxeIds[i + 1]) != PickaxeType.IRON
            ) {
                revert PeonMinter__WrongPickaxeType();
            }
            _verifyOwnership(pickaxes, pickaxeIds[i]);
            _verifyOwnership(pickaxes, pickaxeIds[i + 1]);
            _burn(pickaxes, pickaxeIds[i]);
            _burn(pickaxes, pickaxeIds[i + 1]);

            unchecked {
                i += 2;
            }
        }
        rerollAmount[msg.sender] += pickaxesAmount / 2;
    }

    //* External onlyOwner functions */

    /**
     * @notice Populate array of unminted Peon V2 ids for given PeonClass
     * @param peonClass PeonClass to populate
     * @param data Array of unminted Peon V2 ids
     */
    function populateArray(PeonClass peonClass, uint16[] calldata data) external onlyOwner {
        for (uint256 i = 0; i < data.length; i++) {
            _peonClassToUnmintedIds[peonClass][i] = data[i];
        }
    }

    //* Internal view functions */

    /**
     * @notice Check if reroll is still available
     * @param rollTimestamp Timestamp of last roll
     */
    function _checkRerollTimestamp(uint256 rollTimestamp) internal view {
        if (rollTimestamp == 0) {
            revert PeonMinter__NoActiveReroll();
        }
        if (block.timestamp - rollTimestamp > TIME_TO_ROLL) {
            revert PeonMinter__RollTimeIsOver();
        }
    }

    /**
     * @notice Returns available amounts of Peons for each PeonClass
     * @return uniqueAmount Amount of Peons of PeonClass UNIQUE
     * @return rareAmount Amount of Peons of PeonClass RICH
     * @return anyAmount Amount of Peons of PeonClass ANY
     */
    function _getAvailablePeonsAmounts()
        internal
        view
        returns (uint256 uniqueAmount, uint256 rareAmount, uint256 anyAmount)
    {
        uniqueAmount = _peonClassToUnmintedIds[PeonClass.UNIQUE].length;
        rareAmount = _peonClassToUnmintedIds[PeonClass.RICH].length;
        anyAmount = _peonClassToUnmintedIds[PeonClass.ANY].length;
    }

    /**
     * @notice Check PeonTokenType for given PeonToken ID
     * @param peonTokenId PeonToken ID to check
     * @return PeonTokenType
     */
    function _checkPeonTokenType(uint256 peonTokenId) internal pure returns (PeonTokenType) {
        if (peonTokenId < 7) {
            return PeonTokenType.DIAMOND;
        } else if (peonTokenId < 568) {
            return PeonTokenType.GOLDEN;
        } else if (peonTokenId < 5000) {
            return PeonTokenType.REGULAR;
        } else {
            revert PeonMinter__WrongTokenID();
        }
    }

    /**
     * @notice Check PickaxeType for given Pickaxe ID
     * @param pickaxeId Pickaxe ID to check
     * @return PickaxeType
     */
    function _checkPickaxeType(uint256 pickaxeId) internal pure returns (PickaxeType) {
        uint256 bytePos = pickaxeId / 2;
        uint256 bitPos = pickaxeId % 2;

        uint8 byteValue = uint8(_pickaxeTypes[bytePos]);

        return PickaxeType((byteValue >> (4 * bitPos)) & 0xf);
    }

    //* Internal functions */

    /**
     * @notice Credit rerolls for burning GOLD, SILVER or BRONZE pickaxe
     * @dev Already deducts one, that will be used for reroll - burning these pickaxes is
     * only possible with rollPeonWithOnePickaxe function
     * @param pickaxeType PickaxeType of burned pickaxe
     */
    function _addRerolls(PickaxeType pickaxeType) internal {
        if (pickaxeType == PickaxeType.GOLD) {
            rerollAmount[msg.sender] += 19;
        } else if (pickaxeType == PickaxeType.SILVER) {
            rerollAmount[msg.sender] += 9;
        } else if (pickaxeType == PickaxeType.BRONZE) {
            rerollAmount[msg.sender] += 4;
        } else {
            revert PeonMinter__WrongPickaxeType();
        }
    }

    /**
     * @notice Roll Peon V2 for given PeonTokenType
     * @param peonTokenType PeonTokenType to roll
     */
    function _chooseCategoryAndRoll(PeonTokenType peonTokenType) internal {
        if (peonTokenType == PeonTokenType.DIAMOND) {
            _rollPeon(PeonClass.UNIQUE, PeonTokenType.DIAMOND);
        } else if (peonTokenType == PeonTokenType.GOLDEN) {
            _rollRareOrUnique(PeonTokenType.GOLDEN);
        } else if (peonTokenType == PeonTokenType.REGULAR) {
            _rollAny(PeonTokenType.REGULAR);
        }
    }

    /**
     * @notice Roll RARE or UNIQUE Peon V2
     * @dev Uses pseudo randomness to determinte PeonClass of newly rolled Peon. Chance is based on amount of Peons left
     * @param burnedPeonTokenType PeonTokenType of initially burned PeonToken for this reroll
     */
    function _rollRareOrUnique(PeonTokenType burnedPeonTokenType) internal {
        (uint256 uniqueAmount, uint256 rareAmount,) = _getAvailablePeonsAmounts();
        bool uniquesAvailable = uniqueAmount > uniquePeonsReserved;
        bool raresAvailable = rareAmount > rarePeonsReserved;

        uint256 randomNumber = _getPseudoRandomness(rareAmount);
        if (uniquesAvailable) {
            // can roll unique
            uint256 randomIndex = randomNumber % (uniqueAmount + rareAmount);
            if (randomIndex < uniqueAmount) {
                _rollPeon(PeonClass.UNIQUE, burnedPeonTokenType);
            } else {
                _rollPeon(PeonClass.RICH, burnedPeonTokenType);
            }
        } else if (raresAvailable) {
            // no uniques left to roll
            _rollPeon(PeonClass.RICH, burnedPeonTokenType);
        } else {
            revert PeonMinter__NoAvailableItemsLeft();
        }
    }

    /**
     * @notice Roll ANY Peon V2
     * @dev Uses pseudo randomness to determinte PeonClass of newly rolled Peon. Chance is based on amount of Peons left
     * @param burnedPeonTokenType PeonTokenType of initially burned PeonToken for this reroll
     */
    function _rollAny(PeonTokenType burnedPeonTokenType) internal {
        (uint256 uniqueAmount, uint256 rareAmount, uint256 anyAmount) = _getAvailablePeonsAmounts();
        uint256 randomNumber = _getPseudoRandomness(anyAmount);

        bool uniquesAvailable = uniqueAmount > uniquePeonsReserved;
        bool raresAvailable = rareAmount > rarePeonsReserved;
        bool anyAvailable = anyAmount > 0;

        if (uniquesAvailable && raresAvailable) {
            // can roll any - regular, rare and unique are available
            // most probable case throughout the mint
            uint256 randomIndex = randomNumber % (uniqueAmount + rareAmount + anyAmount);

            if (randomIndex < uniqueAmount) {
                _rollPeon(PeonClass.UNIQUE, burnedPeonTokenType);
            } else if (randomIndex < uniqueAmount + rareAmount) {
                _rollPeon(PeonClass.RICH, burnedPeonTokenType);
            } else {
                _rollPeon(PeonClass.ANY, burnedPeonTokenType);
            }
        } else if (raresAvailable && !uniquesAvailable) {
            // can roll rare or regular - all uniques are reserved
            uint256 randomIndex = randomNumber % (rareAmount + anyAmount);
            if (randomIndex < rareAmount) {
                _rollPeon(PeonClass.RICH, burnedPeonTokenType);
            } else {
                _rollPeon(PeonClass.ANY, burnedPeonTokenType);
            }
        } else if (anyAvailable) {
            // can roll only regular - all rares and uniques are reserved
            _rollPeon(PeonClass.ANY, burnedPeonTokenType);
        } else {
            revert PeonMinter__NoAvailableItemsLeft();
        }
    }

    /**
     * @notice Roll Peon V2
     * @param peonClassToRoll PeonClass to roll determinted earlier
     * @param burnedPeonTokenType PeonTokenType of initially burned PeonToken for this reroll
     */
    function _rollPeon(PeonClass peonClassToRoll, PeonTokenType burnedPeonTokenType) internal {
        RolledPeonData memory currentlyRolledPeonData = currentlyRolledPeon[msg.sender];
        uint256 randomNumber = _getPseudoRandomness(currentlyRolledPeonData.rolledPeon);

        uint16 tokenIdRolled = _pickToken(randomNumber, peonClassToRoll);

        if (currentlyRolledPeonData.rollTimestamp != 0) {
            _restorePreviouslyRolledPeonToAvailables(currentlyRolledPeonData);
        }

        currentlyRolledPeon[msg.sender] =
            RolledPeonData(block.timestamp, tokenIdRolled, peonClassToRoll, burnedPeonTokenType);

        emit TokenIdRolled(msg.sender, tokenIdRolled, peonClassToRoll);
    }

    /**
     * @notice Pick token from array of available tokens
     * @param randomNumber Pseudo random number to pick token from array
     * @param peonClassToRoll PeonClass to roll determinted earlier
     * @return tokenIdRolled TokenId of rolled Peon
     */
    function _pickToken(uint256 randomNumber, PeonClass peonClassToRoll) internal returns (uint16 tokenIdRolled) {
        uint16[] storage arrayToMint = _peonClassToUnmintedIds[peonClassToRoll];
        uint256 arrayToMintLength = arrayToMint.length;
        uint256 randomIndex = randomNumber % arrayToMintLength;
        tokenIdRolled = arrayToMint[randomIndex];

        arrayToMint[randomIndex] = arrayToMint[arrayToMintLength - 1];
        arrayToMint.pop();
    }

    /**
     * @notice Restore previously rolled Peon to availables
     * @param currentlyRolledPeonData Data of previously rolled Peon
     */
    function _restorePreviouslyRolledPeonToAvailables(RolledPeonData memory currentlyRolledPeonData) internal {
        _peonClassToUnmintedIds[currentlyRolledPeonData.peonClassRolled].push(currentlyRolledPeonData.rolledPeon);
    }

    /**
     * @notice Get pseudo randomness
     * @param integer Integer to use in pseudo randomness
     * @return randomNumber Pseudo random number
     */
    function _getPseudoRandomness(uint256 integer) internal returns (uint256 randomNumber) {
        randomNumber = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, integer, _randomnessNonce++))
        );
        return randomNumber;
    }

    /**
     * @dev Verify that the caller owns the token that is meant to be burnt
     * @param collection The collection to check ownership in
     * @param tokenId The token ID to check ownership for
     */
    function _verifyOwnership(IERC721 collection, uint256 tokenId) internal view {
        if (collection.ownerOf(tokenId) != msg.sender) {
            revert PeonMinter__TokenOwnershipRequired();
        }
    }

    /**
     * @dev Burns a token by sending it to `address(dead)`
     * @param collection The collection to burn the token from
     * @param tokenId The token ID to burn
     */
    function _burn(IERC721 collection, uint256 tokenId) internal {
        collection.transferFrom(msg.sender, BURN_ADDRESS, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IOZNFTBaseUpgradeable} from "nft-base-contracts/interfaces/IOZNFTBaseUpgradeable.sol";

interface IPeonsV2 is IOZNFTBaseUpgradeable {
    error PeonsV2__ZeroAddress();
    error PeonsV2__InvalidTokenId();
    error PeonsV2__TokenIdOverCollectionSize();
    error PeonsV2__OnlyPeonMinter();

    /// @dev Emitted on setDescriptor()
    event DescriptorSet(address indexed descriptor);

    /// @dev Emitted on setPeonMinter()
    event PeonMinterSet(address indexed peonMinter);

    function mint(address user, uint256 amount) external;

    function setPeonMinter(address _peonMinter) external;

    function setDescriptor(address _descriptor) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IPeonMinter {
    error PeonMinter__NotStarted();
    error PeonMinter__PendingReroll();
    error PeonMinter__NoActiveReroll();
    error PeonMinter__NotEnoughRerolls();
    error PeonMinter__RollTimeIsOver();
    error PeonMinter__TokenOwnershipRequired();
    error PeonMinter__WrongTokenID();
    error PeonMinter__WrongAmount();
    error PeonMinter__WrongPickaxeType();
    error PeonMinter__NoAvailableItemsLeft();

    enum PeonTokenType {
        REGULAR,
        GOLDEN,
        DIAMOND
    }

    enum PeonClass {
        ANY,
        RICH,
        UNIQUE
    }

    enum PickaxeType {
        IRON,
        BRONZE,
        SILVER,
        GOLD,
        DIAMOND
    }

    struct RolledPeonData {
        uint256 rollTimestamp;
        uint16 rolledPeon;
        PeonClass peonClassRolled;
        PeonTokenType peonTokenBurned;
    }

    event TokenIdRolled(address indexed user, uint256 tokenIdRolled, PeonClass peonClass);
    event PeonAccepted(address indexed user, uint256 tokenIdRolled);
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
pragma solidity 0.8.13;

import {
    IONFT721Upgradeable,
    IERC165Upgradeable
} from "solidity-examples/contracts/contracts-upgradable/token/ONFT721/IONFT721Upgradeable.sol";

import {INFTBaseUpgradeable} from "./INFTBaseUpgradeable.sol";

interface IOZNFTBaseUpgradeable is INFTBaseUpgradeable, IONFT721Upgradeable {
    error OZNFTBaseUpgradeable__InvalidAddress();

    event BaseURISet(string baseURI);
    event UnrevealedURISet(string unrevealedURI);
    event LZEndpointSet(address lzEndpoint);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function setBaseURI(string calldata baseURI) external;

    function setUnrevealedURI(string calldata baseURI) external;

    function setLzEndpoint(address lzEndpoint) external;

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override(INFTBaseUpgradeable, IERC165Upgradeable)
        returns (bool);
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

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IONFT721CoreUpgradeable.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT721Upgradeable is IONFT721CoreUpgradeable, IERC721Upgradeable {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

import {ISafePausableUpgradeable} from "./utils/ISafePausableUpgradeable.sol";

interface INFTBaseUpgradeable is ISafePausableUpgradeable {
    error OperatorNotAllowed(address operator);
    error NFTBase__InvalidPercent();
    error NFTBase__InvalidJoeFeeCollector();
    error NFTBase__WithdrawAVAXNotAvailable();
    error NFTBase__TransferFailed();
    error NFTBase__NotEnoughAVAX(uint256 amountNeeded);
    error NFTBase__InvalidRoyaltyInfo();

    event OperatorFilterRegistryUpdated(address indexed operatorFilterRegistry);
    event JoeFeeInitialized(uint256 feePercent, address feeCollector);
    event WithdrawAVAXStartTimeSet(uint256 withdrawAVAXStartTime);
    event AvaxWithdraw(address indexed sender, uint256 amount, uint256 fee);
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);

    function getProjectOwnerRole() external pure returns (bytes32);

    function operatorFilterRegistry() external view returns (IOperatorFilterRegistry);

    function joeFeeCollector() external view returns (address);

    function joeFeePercent() external view returns (uint256);

    function withdrawAVAXStartTime() external view returns (uint256);

    function setWithdrawAVAXStartTime(uint256 newWithdrawAVAXStartTime) external;

    function withdrawAVAX(address to) external;

    function setOperatorFilterRegistryAddress(address newOperatorFilterRegistry) external;

    function setRoyaltyInfo(address receiver, uint96 feePercent) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT721CoreUpgradeable is IERC165Upgradeable {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _tokenId - token Id to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParams - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address _from, uint16 _dstChainId, bytes calldata _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    /**
     * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce from
     */
    event SendToChain(address indexed _sender, uint16 indexed _dstChainId, bytes indexed _toAddress, uint _tokenId, uint64 _nonce);

    /**
     * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, bytes indexed _srcAddress, address indexed _toAddress, uint _tokenId, uint64 _nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ISafeAccessControlEnumerableUpgradeable} from "./ISafeAccessControlEnumerableUpgradeable.sol";

interface ISafePausableUpgradeable is ISafeAccessControlEnumerableUpgradeable {
    error SafePausableUpgradeable__AlreadyPaused();
    error SafePausableUpgradeable__AlreadyUnpaused();

    function getPauserRole() external pure returns (bytes32);

    function getUnpauserRole() external pure returns (bytes32);

    function getPauserAdminRole() external pure returns (bytes32);

    function getUnpauserAdminRole() external pure returns (bytes32);

    function pause() external;

    function unpause() external;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IAccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import {IPendingOwnableUpgradeable} from "./IPendingOwnableUpgradeable.sol";

interface ISafeAccessControlEnumerableUpgradeable is IAccessControlEnumerableUpgradeable, IPendingOwnableUpgradeable {
    error SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin();
    error SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner(bytes32 role, address sender);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IPendingOwnableUpgradeable is IERC165Upgradeable {
    error PendingOwnableUpgradeable__NotOwner();
    error PendingOwnableUpgradeable__NotPendingOwner();
    error PendingOwnableUpgradeable__AddressZero();
    error PendingOwnableUpgradeable__PendingOwnerAlreadySet();
    error PendingOwnableUpgradeable__NoPendingOwner();

    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}