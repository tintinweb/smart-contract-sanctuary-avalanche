// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./VRFConsumerBaseV2Upgradeable.sol";
import "./VRFCoordinatorV2Interface.sol";

interface IERC721Mint {
    function mint(address to, uint32 empire, uint32 rarity, uint32 unlockTime) external;
}

interface IERC1155Mint {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

contract GLXLogic is OwnableUpgradeable, VRFConsumerBaseV2Upgradeable {
    uint256 constant public NORMAL_ASTROPOS_BP = 10;
    uint256 constant public RARE_ASTROPOS_BP = 11;
    uint256 constant public MYTHICAL_ASTROPOS_BP = 12;
    uint256 constant public NORMAL_LACHESIS_BP = 13;
    uint256 constant public RARE_LACHESIS_BP = 14;
    uint256 constant public MYTHICAL_LACHESIS_BP = 15;
    uint256 constant public NORMAL_MORTA_BP = 16;
    uint256 constant public RARE_MORTA_BP = 17;
    uint256 constant public MYTHICAL_MORTA_BP = 18;

    uint256 constant public nnRate = 7750;
    uint256 constant public nrRate = 9560;

    uint256 constant public rrRate = 6750;
    uint256 constant public rsrRate = 8960;

    uint256 constant public msrRate = 6190;
    uint256 constant public mssrRate = 8810;

    struct RandomnessRequest {
        address sender;
        uint256 blueprintId;
    }

    bytes32 private _keyHash;
    VRFCoordinatorV2Interface private _vrfCoordinator;
    mapping(uint256 => RandomnessRequest) private _randomnessRequests;
    uint32 private _callbackGasLimit;
    uint16 private _requestConfirmations;
    uint64 private _subscriptionId;

    IERC721Mint private _ship;
    IERC721Mint private _equipment;
    IERC1155Mint private _item;

    event BlueprintMinted(address indexed owner, uint256 blueprintId, uint256 amount);
    event BlueprintOpened(address indexed owner, uint256 blueprintId, uint256 amount);

    function __GLXLogic_init(
        address glxShip,
        address glxEquipment,
        address glxItem,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    ) public initializer {
        __Ownable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator);

        _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        _subscriptionId = subscriptionId;
        _keyHash = keyHash;

        _ship = IERC721Mint(glxShip);
        _equipment = IERC721Mint(glxEquipment);
        _item = IERC1155Mint(glxItem);

        _callbackGasLimit = 500000;
        _requestConfirmations = 3;
    }

    function craftBox(address to, uint256 blueprintId, uint256 amount)
        external
        onlyOwner
    {
        emit BlueprintMinted(to, blueprintId, amount);
        _item.mint(to, blueprintId, amount);
    }

    function unbox(uint256 blueprintId, uint256 amount)
        external
    {
        require(blueprintId >= 10 && blueprintId <= 18, "GLXLogic: invalid blueprint id");
        require(amount > 0, "GLXLogic: amount is zero");

        for (uint256 i = 0; i < amount; i++) {
            uint256 requestID = _vrfCoordinator.requestRandomWords(
                _keyHash,
                _subscriptionId,
                _requestConfirmations,
                _callbackGasLimit,
                1
            );
            RandomnessRequest storage req = _randomnessRequests[requestID];
            req.sender = _msgSender();
            req.blueprintId = blueprintId;
        }

        _item.burn(msg.sender, blueprintId, amount);
        emit BlueprintOpened(msg.sender, blueprintId, amount);
    }

    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords) internal override {
        RandomnessRequest memory req = _randomnessRequests[requestID];
        require(req.sender != address(0x0), "GLXAtroposSale: invalid request id");
        require(randomWords.length >= 1, "GLXAtroposSale: no random words provided");

        delete _randomnessRequests[requestID];

        if (_isShipBlueprint(req.blueprintId)) {
            uint32 rarity = _getShipRarity(req.blueprintId, randomWords[0] % 10000);
            uint32 empire = _getShipEmpire(req.blueprintId);
            _ship.mint(req.sender, empire, rarity, 0);
        }
    }

    function _getShipRarity(uint256 blueprintId, uint256 randomness) private pure returns (uint32) {
        if (_isNormalShipBp(blueprintId)) {
            if (randomness < nnRate) {
                return 1;
            } else if (randomness < nrRate) {
                return 2;
            } else {
                return 3;
            }
        } else if (_isRareShipBp(blueprintId)) {
            if (randomness < rrRate) {
                return 2;
            } else if (randomness < rsrRate) {
                return 3;
            } else {
                return 4;
            }
        } else {
            if (randomness < msrRate) {
                return 3;
            } else if (randomness < mssrRate) {
                return 4;
            } else {
                return 5;
            }
        }
    }

    function _getShipEmpire(uint256 blueprintId) private pure returns (uint32) {
        if (blueprintId == NORMAL_ASTROPOS_BP || blueprintId == RARE_ASTROPOS_BP || blueprintId == MYTHICAL_ASTROPOS_BP) {
            return 2;
        }
        if (blueprintId == NORMAL_LACHESIS_BP || blueprintId == RARE_LACHESIS_BP || blueprintId == MYTHICAL_LACHESIS_BP) {
            return 3;
        }
        if (blueprintId == NORMAL_MORTA_BP || blueprintId == RARE_MORTA_BP || blueprintId == MYTHICAL_MORTA_BP) {
            return 4;
        }
        return 0;
    }

    function _isNormalShipBp(uint256 blueprintId) private pure returns (bool) {
        return (blueprintId == NORMAL_ASTROPOS_BP || blueprintId == NORMAL_MORTA_BP || blueprintId == NORMAL_LACHESIS_BP);
    }

    function _isRareShipBp(uint256 blueprintId) private pure returns (bool) {
        return (blueprintId == RARE_ASTROPOS_BP || blueprintId == RARE_MORTA_BP || blueprintId == RARE_LACHESIS_BP);
    }

    function _isShipBlueprint(uint256 blueprintId) private pure returns (bool) {
        return blueprintId < 100;
    }
}