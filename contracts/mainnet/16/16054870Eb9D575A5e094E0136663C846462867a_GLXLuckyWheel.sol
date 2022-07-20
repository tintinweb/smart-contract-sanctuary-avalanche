// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";

contract GLXLuckyWheel is Ownable, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    uint256 public constant REWARD_TYPE_TOKEN = 0;
    uint256 public constant REWARD_TYPE_BLUEPRINT_WARGEAR = 1;
    uint256 public constant REWARD_TYPE_BLUEPRINT_SHIP = 2;
    uint256 public constant REWARD_TYPE_SHIP_SPECIAL_ATROPOS = 3;
    uint256 public constant REWARD_TYPE_SHIP_SPECIAL_LACHESIS = 4;
    uint256 public constant REWARD_TYPE_SHIP_SPECIAL_MORTA = 5;

    mapping(uint256 => bool) _claimIds;

    uint256 private _wargearBpId;
    uint256 private _shipBpId;
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

        bytes32 structHash = keccak256(abi.encode(claimId, msg.sender, rewardType, amount));
        bytes32 hash = ECDSA.toEthSignedMessageHash(structHash);

        address signer = ECDSA.recover(hash, signature);
        require(signer == owner(), "GLXLuckyWheel: invalid signature");

        if (rewardType == REWARD_TYPE_TOKEN) {
            _token.safeTransfer(msg.sender, amount);
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_WARGEAR) {
            _item.safeTransferFrom(address(this), msg.sender, _wargearBpId, amount, "");
        } else if (rewardType == REWARD_TYPE_BLUEPRINT_SHIP) {
            _item.safeTransferFrom(address(this), msg.sender, _shipBpId, amount, "");
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
        uint256 wargearBpId,
        uint256 shipBpId,
        uint256 atroposShipId,
        uint256 lachesisShipId,
        uint256 mortaShipId
    ) external onlyOwner {
        _wargearBpId = wargearBpId;
        _shipBpId = shipBpId;
        _atroposShipId = atroposShipId;
        _lachesisShipId = lachesisShipId;
        _mortaShipId = mortaShipId;
    }
}