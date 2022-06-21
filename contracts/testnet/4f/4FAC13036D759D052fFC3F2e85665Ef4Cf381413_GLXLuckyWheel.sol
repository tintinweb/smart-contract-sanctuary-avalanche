// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract GLXLuckyWheel is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant REWARD_TYPE_TOKEN = 0;
    uint256 public constant REWARD_TYPE_BLUEPRINT_WARGEAR_NORMAL = 1;
    uint256 public constant REWARD_TYPE_BLUEPRINT_WARGEAR_RARE = 2;
    uint256 public constant REWARD_TYPE_BLUEPRINT_WARGEAR_MYTHICAL = 3;
    uint256 public constant REWARD_TYPE_BLUEPRINT_SHIP_NORMAL = 4;
    uint256 public constant REWARD_TYPE_BLUEPRINT_SHIP_RARE = 5;
    uint256 public constant REWARD_TYPE_BLUEPRINT_SHIP_MYTHICAL = 6;
    uint256 public constant REWARD_TYPE_SHIP_SPECIAL_ATROPOS = 7;
    uint256 public constant REWARD_TYPE_SHIP_SPECIAL_LACHESIS = 8;
    uint256 public constant REWARD_TYPE_SHIP_SPECIAL_MORTA = 9;

    mapping(uint256 => bool) _claimIds;

    uint256 private _wargearNormalBpId;
    uint256 private _wargearRareBpId;
    uint256 private _wargearMythicalBpId;
    uint256 private _shipNormalBpId;
    uint256 private _shipRareBpId;
    uint256 private _shipMythicalBpId;
    uint256 private _atroposShipId;
    uint256 private _lachesisShipId;
    uint256 private _mortaShipId;

    IERC20 private _token;
    IERC721 private _ship;
    IERC1155 private _item;

    event RewardClaimed(uint256 indexed claimId, address indexed receiver);

    constructor(address token, address ship, address item) {
        _token = IERC20(token);
        _ship = IERC721(ship);
        _item = IERC1155(item);
    }

    function claim(
        uint256 claimId,
        uint256 rewardType,
        uint256 amount,
        bytes memory signature
    ) public {
        require(!_claimIds[claimId], "GLXLuckyWheel: already claimed");
        _claimIds[claimId] = true;

        bytes32 structHash = keccak256(abi.encode(claimId, rewardType, amount));
        bytes32 hash = ECDSA.toEthSignedMessageHash(structHash);

        address signer = ECDSA.recover(hash, signature);
        require(signer == owner(), "GLXLuckyWheel: invalid signature");

        if (rewardType == REWARD_TYPE_TOKEN) {
            _token.safeTransfer(msg.sender, amount);
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_WARGEAR_NORMAL) {
            _item.safeTransferFrom(address(this), msg.sender, _wargearNormalBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_WARGEAR_RARE) {
            _item.safeTransferFrom(address(this), msg.sender, _wargearRareBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_WARGEAR_MYTHICAL) {
            _item.safeTransferFrom(address(this), msg.sender, _wargearMythicalBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_SHIP_NORMAL) {
            _item.safeTransferFrom(address(this), msg.sender, _shipNormalBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_SHIP_RARE) {
            _item.safeTransferFrom(address(this), msg.sender, _shipRareBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_SHIP_MYTHICAL) {
            _item.safeTransferFrom(address(this), msg.sender, _shipMythicalBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_SHIP_SPECIAL_ATROPOS) {
            _ship.safeTransferFrom(address(this), msg.sender, _atroposShipId);
        } else if (rewardType == REWARD_TYPE_SHIP_SPECIAL_LACHESIS) {
            _ship.safeTransferFrom(address(this), msg.sender, _lachesisShipId);
        } else if (rewardType == REWARD_TYPE_SHIP_SPECIAL_MORTA) {
            _ship.safeTransferFrom(address(this), msg.sender, _mortaShipId);
        }

        emit RewardClaimed(claimId, msg.sender);
    }

    function setReward(
        uint256 wargearNormalBpId,
        uint256 wargearRareBpId,
        uint256 wargearMythicalBpId,
        uint256 shipNormalBpId,
        uint256 shipRareBpId,
        uint256 shipMythicalBpId,
        uint256 atroposShipId,
        uint256 lachesisShipId,
        uint256 mortaShipId
    ) external onlyOwner {
        _wargearNormalBpId = wargearNormalBpId;
        _wargearRareBpId = wargearRareBpId;
        _wargearMythicalBpId = wargearMythicalBpId;
        _shipNormalBpId = shipNormalBpId;
        _shipRareBpId = shipRareBpId;
        _shipMythicalBpId = shipMythicalBpId;
        _atroposShipId = atroposShipId;
        _lachesisShipId = lachesisShipId;
        _mortaShipId = mortaShipId;
    }
}