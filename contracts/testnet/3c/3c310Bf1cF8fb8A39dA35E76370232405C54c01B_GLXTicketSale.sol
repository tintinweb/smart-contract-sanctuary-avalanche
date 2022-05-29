// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface IERC1155Mint {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

contract GLXTicketSale is Context, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant TICKET_ID_1 = 1;
    uint256 public constant TICKET_PRICE_1 = 1 * 10**6;
    uint256 public constant TOTAL_TICKET_1 = 3000;

    uint256 public constant TICKET_ID_5 = 2;
    uint256 public constant TICKET_PRICE_5 = 5 * 10**6;
    uint256 public constant TOTAL_TICKET_5 = 3000;

    uint256 public constant TICKET_ID_10 = 3;
    uint256 public constant TICKET_PRICE_10 = 10 * 10**6;
    uint256 public constant TOTAL_TICKET_10 = 3000;

    uint256 public soldTicket1 = 0;
    uint256 public soldTicket5 = 0;
    uint256 public soldTicket10 = 0;

    uint256 public startTime;
    uint256 public endTime;

    IERC1155Mint private _ticket;
    IERC20 private _token;

    event TicketBought(
        address indexed owner,
        uint256 indexed ticketID,
        uint256 amount
    );

    constructor(address glxTicket, address token, uint256 stime, uint256 etime) {
        require(glxTicket != address(0x0), "zero address for GLXTicket");
        require(token != address(0x0), "zero address for ERC20 token");
        require(stime >= block.timestamp && stime < etime, "invalid time range");

        startTime = stime;
        endTime = etime;

        _ticket = IERC1155Mint(glxTicket);
        _token = IERC20(token);
    }

    function buyTicket1(uint256 amount) external {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "time run out"
        );
        require(soldTicket1 + amount <= TOTAL_TICKET_1, "ticket_1 sold out");
        uint256 balance = _token.balanceOf(_msgSender());
        require(amount * TICKET_PRICE_1 <= balance, "insufficient balance");

        soldTicket1 += amount;
	emit TicketBought(_msgSender(), TICKET_ID_1, amount);

        _token.safeTransferFrom(_msgSender(), address(this), amount * TICKET_PRICE_1);
        _ticket.mint(_msgSender(), TICKET_ID_1, amount);
    }

    function buyTicket5(uint256 amount) external {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "time run out"
        );
        require(soldTicket5 + amount <= TOTAL_TICKET_5, "amount exceed limit");
        uint256 balance = _token.balanceOf(_msgSender());
        require(amount * TICKET_PRICE_5 <= balance, "insufficient balance");

        soldTicket5 += amount;
	emit TicketBought(_msgSender(), TICKET_ID_5, amount);

        _token.safeTransferFrom(_msgSender(), address(this), amount * TICKET_PRICE_5);
        _ticket.mint(_msgSender(), TICKET_ID_5, amount);
    }

    function buyTicket10(uint256 amount) external {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "time run out"
        );
        require(soldTicket10 + amount <= TOTAL_TICKET_10, "amount exceed limit");
        uint256 balance = _token.balanceOf(_msgSender());
        require(amount * TICKET_PRICE_10 <= balance, "insufficient balance");

        soldTicket10 += amount;
	emit TicketBought(_msgSender(), TICKET_ID_10, amount);

        _token.safeTransferFrom(_msgSender(), address(this), amount * TICKET_PRICE_10);
        _ticket.mint(_msgSender(), TICKET_ID_10, amount);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        _token.safeTransfer(to, amount);
    }
}