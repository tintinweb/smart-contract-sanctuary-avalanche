// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AcceptedToken.sol";

interface IERC1155Mint {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

contract GLXTicketSale is Ownable, AcceptedToken {
    using SafeERC20 for IERC20;

    uint256 public constant TICKET_ID_1 = 1;
    uint256 public constant TICKET_PRICE_1 = 1;
    uint256 public constant TOTAL_TICKET_1 = 10000;

    uint256 public constant TICKET_ID_5 = 2;
    uint256 public constant TICKET_PRICE_5 = 5;
    uint256 public constant TOTAL_TICKET_5 = 2000;

    uint256 public constant TICKET_ID_10 = 3;
    uint256 public constant TICKET_PRICE_10 = 10;
    uint256 public constant TOTAL_TICKET_10 = 1000;

    uint256 private nativeTokenUnitPrice = 5 * 10**16;

    uint256 public soldTicket1 = 0;
    uint256 public soldTicket5 = 0;
    uint256 public soldTicket10 = 0;

    uint256 public startTime;
    uint256 public endTime;

    IERC1155Mint private _ticket;

    event TicketBought(
        address indexed owner,
        uint256 indexed ticketID,
        uint256 amount
    );

    constructor(address[] memory tokens, address glxTicket, uint256 stime, uint256 etime) {
        startTime = stime;
        endTime = etime;

        _ticket = IERC1155Mint(glxTicket);
        addAcceptedTokens(tokens);
    }

    modifier onlyAcceptedToken(address token) {
        require(_isAcceptedToken(token), "GLXTicketSale: not accepted token");
        _;
    }

    modifier onlyValidTime() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "GLXTicketSale: time run out"
        );
        _;
    }

    function setNativeTokenPriceUnit(uint256 unitPrice) external onlyOwner {
        nativeTokenUnitPrice = unitPrice;
    }

    function getTicketPrice(address token, uint256 ticketId) external view returns (uint256 price) {
        if (ticketId == TICKET_ID_1) {
            price = TICKET_PRICE_1;
        } else if (ticketId == TICKET_ID_5) {
            price = TICKET_PRICE_5;
        } else if (ticketId == TICKET_ID_10) {
            price = TICKET_PRICE_10;
        }

        if (token == address(0x0)) {
            price = price * nativeTokenUnitPrice;
        } else {
            price = price * 10**IERC20Extended(token).decimals();
        }
    }

    function buyTicket1(address token, uint256 amount) external payable onlyAcceptedToken(token) onlyValidTime {
        require(soldTicket1 + amount <= TOTAL_TICKET_1, "ticket_1 sold out");

        if (token == address(0x0)) {
            require(amount * TICKET_PRICE_1 * nativeTokenUnitPrice <= msg.value, "insufficient balance");
        } else {
            uint256 balance = IERC20(token).balanceOf(msg.sender);
            uint256 totalPrice = amount * TICKET_PRICE_1 * 10**IERC20Extended(token).decimals();
            require(totalPrice <= balance, "insufficient balance");
            IERC20(token).safeTransferFrom(msg.sender, address(this), totalPrice);
        }

        soldTicket1 += amount;
        _ticket.mint(msg.sender, TICKET_ID_1, amount);

        emit TicketBought(msg.sender, TICKET_ID_1, amount);
    }

    function buyTicket5(address token, uint256 amount) external payable onlyAcceptedToken(token) onlyValidTime {
        require(soldTicket5 + amount <= TOTAL_TICKET_5, "ticket_5 sold out");

        if (token == address(0x0)) {
            require(amount * TICKET_PRICE_5 * nativeTokenUnitPrice <= msg.value, "insufficient balance");
        } else {
            uint256 balance = IERC20(token).balanceOf(msg.sender);
            uint256 totalPrice = amount * TICKET_PRICE_5 * 10**IERC20Extended(token).decimals();
            require(totalPrice <= balance, "insufficient balance");
            IERC20(token).safeTransferFrom(msg.sender, address(this), totalPrice);
        }

        soldTicket5 += amount;
        _ticket.mint(msg.sender, TICKET_ID_5, amount);

        emit TicketBought(msg.sender, TICKET_ID_5, amount);
    }

    function buyTicket10(address token, uint256 amount) external payable onlyAcceptedToken(token) onlyValidTime {
        require(soldTicket10 + amount <= TOTAL_TICKET_10, "ticket_10 sold out");

        if (token == address(0x0)) {
            require(amount * TICKET_PRICE_10 * nativeTokenUnitPrice <= msg.value, "insufficient balance");
        } else {
            uint256 balance = IERC20(token).balanceOf(msg.sender);
            uint256 totalPrice = amount * TICKET_PRICE_10 * 10**IERC20Extended(token).decimals();
            require(totalPrice <= balance, "insufficient balance");
            IERC20(token).safeTransferFrom(msg.sender, address(this), totalPrice);
        }

        soldTicket10 += amount;
        _ticket.mint(msg.sender, TICKET_ID_10, amount);

        emit TicketBought(msg.sender, TICKET_ID_10, amount);
    }

    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        _tokenTransfer(token, to, amount);
    }

    function _tokenTransfer(address token, address to, uint256 amount) internal {
        require(to != address(0x0), "GLXTicketSale: transfer to zero address");
        if (token == address(0x0)) {
            (bool success, ) = payable(to).call{ value: amount }('');
            require(success, "GLXTicketSale: fail to transfer native token");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    receive() external payable {}
}