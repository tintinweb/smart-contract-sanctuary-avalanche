// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./VRFConsumerBase.sol";

interface IERC721Mint {
    function mint(address to, uint32 empire, uint32 rarity) external;
}

interface IERC1155Mint {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function balanceOf(address owner, uint256 id) external view returns (uint256);
}


contract GLXAtroposSale is VRFConsumerBase, Context, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_TOTAL_NORMAL_BPS = 644;
    uint256 public constant MAX_TOTAL_RARE_BPS = 270;
    uint256 public constant MAX_TOTAL_MYTHICAL_BPS = 86;

    uint256 public constant NORMAL_BP_ID = 1;
    uint256 public constant RARE_BP_ID = 2;
    uint256 public constant MYTHICAL_BP_ID = 3;

    uint256 public constant NORMAL_BP_PRICE = 100 * 10**6;
    uint256 public constant RARE_BP_PRICE = 150 * 10 ** 6;
    uint256 public constant MYTHICAL_BP_PRICE = 300 * 10 ** 6;

    uint256 private soldNormalBps = 0;
    uint256 private soldRareBps = 0;
    uint256 private soldMythicalBps = 0;

    uint256 private openedNormalBps = 0;
    uint256 private openedRareBps = 0;
    uint256 private openedMythicalBps = 0;

    uint256 private remainShips = 1000;
    uint256 private remainNormalBps = 644;
    uint256 private remainRareBps = 270;
    uint256 private remainMythicalBps = 86;

    uint256 private remainNN = 500;
    uint256 private remainNR = 116;
    uint256 private remainNSR = 28;

    uint256 private remainRR = 184;
    uint256 private remainRSR = 73;
    uint256 private remainRSSR = 13;

    uint256 private remainMSR = 39;
    uint256 private remainMSSR = 37;
    uint256 private remainMUR = 10;

    struct RandomnessRequest {
        address sender;
        uint256 blueprintId;
    }

    bytes32 private _keyHash;
    mapping(bytes32 => RandomnessRequest) private _randomnessRequests;
    uint256 public startTime;
    uint256 public endWhitelistTime;
    uint256 public endTime;

    IERC1155Mint private _item;
    IERC721Mint private _ship;
    IERC20 private _token;
    IERC1155Mint private _ticket;

    event BlueprintMinted(address owner, uint256 blueprintId, uint256 amount);
    event BlueprintOpened(address owner, uint256 blueprintId, uint256 amount);

    constructor(
        address glxItem,
        address glxShip,
        address token,
        address ticket,
        address vrfCoordinatorAddr,
        bytes32 keyHash,
        uint256 stime,
        uint256 eWhitelistTime,
        uint256 etime
    )
        VRFConsumerBase(vrfCoordinatorAddr)
    {
        _keyHash = keyHash;
        startTime = stime;
        endWhitelistTime = eWhitelistTime;
        endTime = etime;

        _item = IERC1155Mint(glxItem);
        _ship = IERC721Mint(glxShip);
        _token = IERC20(token);
        _ticket = IERC1155Mint(ticket);
    }

    modifier onlyValidTime() {
        require(block.timestamp >= startTime, "GLXAtroposSale: sale not start yet");
        require(block.timestamp <= endTime, "GLXAtroposSale: sale ended");
        _;
    }

    modifier onlyValidNormalTime() {
        require(block.timestamp >= endWhitelistTime, "GLXAtroposSale: sale not start yet");
        require(block.timestamp <= endTime, "GLXAtroposSale: sale ended");
        _;
    }

    function buyNormalWithTicket(uint256 amount, uint256 ticketId) external onlyValidTime {
        require(soldNormalBps + amount <= MAX_TOTAL_NORMAL_BPS, "GLXAtroposSale: amount exceed limit");

        uint256 ticketBalance = _ticket.balanceOf(_msgSender(), ticketId);
        require(ticketBalance >= amount, "GLXAtroposSale: not enough ticket");

        uint256 totalPrice = amount * NORMAL_BP_PRICE * _getDiscountByTicketId(ticketId) / 100;
        uint256 balance = _token.balanceOf(_msgSender());
        require(totalPrice <= balance, "insufficient balance");

        soldNormalBps += amount;

        _ticket.burn(_msgSender(), ticketId, amount);
        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _item.mint(_msgSender(), NORMAL_BP_ID, amount);

        emit BlueprintMinted(_msgSender(), NORMAL_BP_ID, amount);
    }

    function buyNormal(uint256 amount) external onlyValidNormalTime {
        require(soldNormalBps + amount <= MAX_TOTAL_NORMAL_BPS, "GLXAtroposSale: amount exceed limit");

        uint256 totalPrice = amount * NORMAL_BP_PRICE;
        uint256 balance = _token.balanceOf(_msgSender());
        require(totalPrice <= balance, "insufficient balance");

        soldNormalBps += amount;

        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _item.mint(_msgSender(), NORMAL_BP_ID, amount);

        emit BlueprintMinted(_msgSender(), NORMAL_BP_ID, amount);
    }

    function buyRareWithTicket(uint256 amount, uint256 ticketId) external onlyValidTime {
        require(soldRareBps + amount <= MAX_TOTAL_RARE_BPS, "GLXAtroposSale: amount exceed limit");

        uint256 ticketBalance = _ticket.balanceOf(_msgSender(), ticketId);
        require(ticketBalance >= amount, "GLXAtroposSale: not enough ticket");

        uint256 totalPrice = amount * RARE_BP_PRICE * _getDiscountByTicketId(ticketId) / 100;
        uint256 balance = _token.balanceOf(_msgSender());
        require(totalPrice <= balance, "insufficient balance");

        soldRareBps += amount;

        _ticket.burn(_msgSender(), ticketId, amount);
        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _item.mint(_msgSender(), RARE_BP_ID, amount);

        emit BlueprintMinted(_msgSender(), RARE_BP_ID, amount);
    }

    function buyRare(uint256 amount) external onlyValidNormalTime {
        require(soldRareBps + amount <= MAX_TOTAL_RARE_BPS, "GLXAtroposSale: amount exceed limit");

        uint256 totalPrice = amount * RARE_BP_PRICE;
        uint256 balance = _token.balanceOf(_msgSender());
        require(totalPrice <= balance, "insufficient balance");

        soldRareBps += amount;

        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _item.mint(_msgSender(), RARE_BP_ID, amount);

        emit BlueprintMinted(_msgSender(), RARE_BP_ID, amount);
    }

    function buyMythicalWithTicket(uint256 amount, uint256 ticketId) external onlyValidTime {
        require(soldMythicalBps + amount <= MAX_TOTAL_MYTHICAL_BPS, "GLXAtroposSale: amount exceed limit");

        uint256 ticketBalance = _ticket.balanceOf(_msgSender(), ticketId);
        require(ticketBalance >= amount, "GLXAtroposSale: not enough ticket");

        uint256 totalPrice = amount * MYTHICAL_BP_PRICE * _getDiscountByTicketId(ticketId) / 100;
        uint256 balance = _token.balanceOf(_msgSender());
        require(totalPrice <= balance, "insufficient balance");

        soldMythicalBps += amount;

        _ticket.burn(_msgSender(), ticketId, amount);
        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _item.mint(_msgSender(), MYTHICAL_BP_ID, amount);

        emit BlueprintMinted(_msgSender(), MYTHICAL_BP_ID, amount);
    }

    function buyMythical(uint256 amount) external onlyValidNormalTime {
        require(soldMythicalBps + amount <= MAX_TOTAL_MYTHICAL_BPS, "GLXAtroposSale: amount exceed limit");

        uint256 totalPrice = amount * MYTHICAL_BP_PRICE;
        uint256 balance = _token.balanceOf(_msgSender());
        require(totalPrice <= balance, "insufficient balance");

        soldMythicalBps += amount;

        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _item.mint(_msgSender(), MYTHICAL_BP_ID, amount);

        emit BlueprintMinted(_msgSender(), MYTHICAL_BP_ID, amount);
    }

    function unbox(uint256 blueprintId, uint256 amount) external {
        require(
            blueprintId == NORMAL_BP_ID || blueprintId == RARE_BP_ID || blueprintId == MYTHICAL_BP_ID,
            "GLXAtroposSale: invalid blueprint id"
        );
        require(amount > 0, "GLXAtroposSale: amount is zero");

        if (blueprintId == NORMAL_BP_ID) {
            openedNormalBps += amount;
        } else if (blueprintId == RARE_BP_ID) {
            openedRareBps += amount;
        } else {
            openedMythicalBps += amount;
        }

        for (uint256 i = 0; i < amount; i++) {
            bytes32 requestID = requestRandomness(_keyHash);
            RandomnessRequest storage req = _randomnessRequests[requestID];
            req.sender = _msgSender();
            req.blueprintId = blueprintId;
        }

        _item.burn(_msgSender(), blueprintId, amount);

        emit BlueprintOpened(_msgSender(), blueprintId, amount);
    }

    function fulfillRandomness(bytes32 requestID, uint256 randomness) internal override {
        RandomnessRequest storage req = _randomnessRequests[requestID];
        require(req.sender != address(0x0), "GLXAtroposSale: invalid request id");
        require(remainShips > 0, "GLXAtroposSale: all blueprint opened");

        delete _randomnessRequests[requestID];
        remainShips -= 1;

        if (req.blueprintId == NORMAL_BP_ID) {
            randomness = randomness % remainNormalBps + 1;
            remainNormalBps -= 1;
            if (randomness <= remainNN) {
                remainNN -= 1;
                _ship.mint(req.sender, 2, 1);
                return;
            }

            randomness -= remainNN;
            if (randomness <= remainNR) {
                remainNR -= 1;
                _ship.mint(req.sender, 2, 2);
                return;
            }

            remainNSR -= 1;
            _ship.mint(req.sender, 2, 3);
            return;
        } else if (req.blueprintId == RARE_BP_ID) {
            randomness = randomness % remainRareBps + 1;
            remainRareBps -= 1;
            if (randomness <= remainRR) {
                remainRR -= 1;
                _ship.mint(req.sender, 2, 2);
                return;
            }

            randomness -= remainRR;
            if (randomness <= remainRSR) {
                remainRSR -= 1;
                _ship.mint(req.sender, 2, 3);
                return;
            }

            remainRSSR -= 1;
            _ship.mint(req.sender, 2, 4);
            return;
        } else {
            randomness = randomness % remainMythicalBps + 1;
            remainMythicalBps -= 1;
            if (randomness <= remainMSR) {
                remainMSR -= 1;
                _ship.mint(req.sender, 2, 3);
                return;
            }

            randomness -= remainMSR;
            if (randomness <= remainMSSR) {
                remainMSSR -= 1;
                _ship.mint(req.sender, 2, 4);
                return;
            }

            remainMUR -= 1;
            _ship.mint(req.sender, 2, 5);
            return;
        }
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        _token.safeTransfer(to, amount);
    }

    function getSoldNormals() external view returns (uint256) {
        return soldNormalBps;
    }

    function getSoldRares() external view returns (uint256) {
        return soldRareBps;
    }

    function getSoldMythicals() external view returns (uint256) {
        return soldMythicalBps;
    }

    function _getDiscountByTicketId(uint256 ticketId) private pure returns (uint256) {
        if (ticketId == 1) {
            return 95;
        }
        if (ticketId == 2) {
            return 90;
        }
        if (ticketId == 3) {
            return 85;
        }
        return 100;
    }
}