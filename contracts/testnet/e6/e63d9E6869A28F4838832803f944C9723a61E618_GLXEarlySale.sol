// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./VRFConsumerBase.sol";

interface IERC721Mint {
    function mint(address to, uint64 rarity) external;
}

interface IERC1155Mint {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}


contract GLXEarlySale is VRFConsumerBase, Context, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant EARLY_SALE_BOX_ID = 1000;
    uint256 public constant MAX_TOTAL_BOXES = 200;
    uint256 public constant BOX_PRICE = 125 * 10**6;

    uint256 private soldBoxes = 0;
    uint256 private openedBoxes = 0;
    uint256 private remainShips = MAX_TOTAL_BOXES;
    uint256 private remainNormal = 90;
    uint256 private remainRare = 66;
    uint256 private remainSuperRare = 33;
    uint256 private remainSuperSuperRare = 10;
    uint256 private remainUltraRare = 1;

    bytes32 private _keyHash;
    mapping(bytes32 => address) private _randomnessRequests;
    uint256 public startTime;
    uint256 public endTime;

    IERC1155Mint private _item;
    IERC721Mint private _ship;
    IERC20 private _token;

    event BoxMinted(address owner, uint256 boxId, uint256 amount);
    event BoxOpened(address owner, uint256 boxId, uint256 amount);

    constructor(
        address glxItem,
        address glxShip,
	address token,
        address vrfCoordinatorAddr,
        bytes32 keyHash,
	uint256 stime,
	uint256 etime
    )
        VRFConsumerBase(vrfCoordinatorAddr)
    {
        _keyHash = keyHash;
        startTime = stime;
        endTime = etime;

        _item = IERC1155Mint(glxItem);
        _ship = IERC721Mint(glxShip);
	_token = IERC20(token);
    }

    function buy(uint256 amount) external {
        require(
	    block.timestamp >= startTime && block.timestamp <= endTime,
	    "time run out"
	);
        require(soldBoxes + amount <= MAX_TOTAL_BOXES, "amount exceed limit");
        uint256 balance = _token.balanceOf(_msgSender());
        require(amount * BOX_PRICE <= balance, "insufficient balance");

        soldBoxes += amount;
        emit BoxMinted(_msgSender(), EARLY_SALE_BOX_ID, amount);

        _token.safeTransferFrom(_msgSender(), address(this), amount * BOX_PRICE);
        _item.mint(_msgSender(), EARLY_SALE_BOX_ID, amount);
    }

    function unbox(uint256 amount) external {
        require(amount > 0, "amount is zero");
        require(amount+openedBoxes <= MAX_TOTAL_BOXES, "open too many boxes");

	openedBoxes += amount;
        emit BoxOpened(_msgSender(), EARLY_SALE_BOX_ID, amount);

        for (uint256 i = 0; i < amount; i++) {
            bytes32 requestID = requestRandomness(_keyHash);
            _randomnessRequests[requestID] = _msgSender();
        }

        _item.burn(_msgSender(), EARLY_SALE_BOX_ID, amount);
    }

    function fulfillRandomness(bytes32 requestID, uint256 randomness) internal override {
        address reqOwner = _randomnessRequests[requestID];
        require(reqOwner != address(0x0), "invalid request id");
        require(remainShips > 0, "all boxes opened");

        delete _randomnessRequests[requestID];
        randomness = randomness % remainShips + 1;
        remainShips -= 1;

        if (randomness <= remainNormal) {
            remainNormal -= 1;
            _ship.mint(reqOwner, 1);
            return;
        }

        randomness -= remainNormal;
        if (randomness <= remainRare) {
            remainRare -= 1;
            _ship.mint(reqOwner, 2);
            return;
        }

        randomness -= remainRare;
        if (randomness <= remainSuperRare) {
            remainSuperRare -= 1;
            _ship.mint(reqOwner, 3);
            return;
        }

        randomness -= remainSuperRare;
        if (randomness <= remainSuperSuperRare) {
            remainSuperSuperRare -= 1;
            _ship.mint(reqOwner, 4);
            return;
        }

        remainUltraRare -= 1;
        _ship.mint(reqOwner, 5);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        _token.safeTransfer(to, amount);
    }
}