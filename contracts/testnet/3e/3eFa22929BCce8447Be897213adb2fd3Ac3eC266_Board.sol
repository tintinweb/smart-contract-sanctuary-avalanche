/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-08
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.6.12;

contract Board {
    /* Constants */
    uint256 constant size = 1000;
    uint256 constant tileSize = 10;
    uint256 constant tilesNb = size / tileSize;
    uint256 constant buyRate = 13;
    uint256 counter = 0;
    /* State */
    address private owner;
    mapping(uint8 => mapping(uint8 => Tile)) public tiles;
    mapping(address => uint256) private pendingWithdrawals;

    /* Tile information */
    struct Tile {
        uint256 price;
        address owner;
        address referer;
    }

    /* Events */
    event Buy(
        uint8 x,
        uint8 y,
        uint8 dx,
        uint8 dy,
        uint256 price,
        string url,
        bool buy_self,
        address owner,
        address referer
    );
    event DrawPixel(
        uint16 x,
        uint16 y,
        uint8[4] color,
        bool overlay,
        address emiter
    );
    event DrawText(
        uint16 x,
        uint16 y,
        string text,
        uint16 text_height,
        uint8[4] text_color,
        uint8[4] background_color,
        string font_family,
        string font_name,
        bool overlay,
        address emiter
    );
    event DrawImage(
        uint16 x,
        uint16 y,
        string url,
        bool overlay,
        address emiter
    );

    /* Constructor initialise board where every tile's price is set to initPrice. */
    constructor() public {
        owner = msg.sender;
    }

    // Init board 0 10 10 20 ... 90 100
    function init(
        uint256 initPrice,
        uint8 alpha,
        uint8 beta
    ) public {
        for (uint8 i = alpha * 10; i < ((tilesNb / 10) * (1 + alpha)); i++) {
            for (uint8 j = beta * 10; j < ((tilesNb / 10) * (1 + beta)); j++) {
                tiles[i][j] = Tile(initPrice, owner, owner);
            }
        }
    }

    /* Count price of selected zone */
    function countPrice(
        uint8 x,
        uint8 y,
        uint8 width,
        uint8 height,
        bool buy_self
    ) internal view returns (uint256 count) {
        for (uint8 i = x; i < x + width; i++) {
            for (uint8 j = y; j < y + height; j++) {
                if (buy_self || tiles[i][j].owner != msg.sender) {
                    count += tiles[i][j].price;
                }
            }
        }
    }

    /* Modifiers */
    modifier correctZone(
        uint8 x,
        uint8 y,
        uint8 width,
        uint8 height
    ) {
        require(
            0 <= x && x + width < tilesNb && width > 0,
            "Wrong zone provided"
        );
        require(
            0 <= y && y + height < tilesNb && height > 0,
            "Wrong zone provided"
        );
        _;
    }

    modifier correctPixel(uint16 x, uint16 y) {
        require(0 <= x && x < size, "Wrong pixel provided");
        require(0 <= y && y < size, "Wrong pixel provided");
        _;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "Sender not authorized.");
        _;
    }

    /* Change owner address */
    function changeOwner(address newOwner) public onlyBy(owner) {
        owner = newOwner;
    }

    /* Withdrawing funds from contract */
    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /* Buy tiles */
    function buy(
        uint8 x,
        uint8 y,
        uint8 dx,
        uint8 dy,
        bool buy_self,
        string calldata ulr
     ) public payable correctZone(x, y, dx, dy) {
        /* uint256 initPrice = countPrice(x, y, dx, dy, buy_self);
        uint256 price = msg.value;
        require(
            price >= (initPrice * buyRate) / 10,
            "Provided price is unsufficient"
        );
        for (uint8 i = x; i < x + dx; i++) {
            for (uint8 j = y; j < y + dy; j++) {
                if (buy_self || tiles[i][j].owner != msg.sender) {
                    uint256 oldTilePrice = tiles[i][j].price;
                    uint256 newTilePrice = oldTilePrice * (price / initPrice);
                    uint256 part = (newTilePrice - oldTilePrice) / 3;
                    tiles[i][j].price = newTilePrice;
                    tiles[i][j].owner = msg.sender;
                    tiles[i][j].referer = referer;
                    pendingWithdrawals[tiles[i][j].owner] +=
                        oldTilePrice +
                        part;
                    pendingWithdrawals[tiles[i][j].referer] += part;
                    pendingWithdrawals[owner] += part;
                }
            }
        } */
         uint256 price =1000;
        emit Buy(x, y, dx, dy, price, ulr, buy_self, msg.sender, msg.sender);
    }

    /* Draw pixel on the board */
    function drawPixel(
        uint16 x,
        uint16 y,
        uint8[4] calldata color,
        bool overlay
    ) public correctPixel(x, y) {
        emit DrawPixel(x, y, color, overlay, msg.sender);
    }

    /* Draw image on the board */
    function drawImage(
        uint16 x,
        uint16 y,
        string calldata url,
        bool overlay
    ) public correctPixel(x, y) {
        emit DrawImage(x, y, url, overlay, msg.sender);
    }

    /* Draw text on the board */
    function drawText(
        uint16 x,
        uint16 y,
        string memory text,
        uint16 text_height,
        uint8[4] calldata text_color,
        uint8[4] calldata background_color,
        string memory font_family,
        string memory font_name,
        bool overlay
    ) public correctPixel(x, y) {
        emit DrawText(
            x,
            y,
            text,
            text_height,
            text_color,
            background_color,
            font_family,
            font_name,
            overlay,
            msg.sender
        );
    }
}