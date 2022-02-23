/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

struct TicketInfo {
    address account;
    uint32 amount;
}

struct MemberInfo {
    uint256 balance; // Balance membership
    uint256 creditsPlus;
    uint256 creditsMinus;
    uint timeStart;
    uint timeUntil;
    uint timeLastPaid;
}

// struct WinningPrize {
//     uint8 class; // 1-Token, 2-Credit, 3-Goods, 4-Cash
//     string name; // Related class: 1-TokenName, 2-Fixed "Credit", 3-GoodsName, 4-Fixed "Cash"
//     string unit; // Related class: 1-TokenSymbol, 2-Unused, 3-GoodsUnit, 4-CurrencyUnit
//     uint256 amount;
//     uint8 decimals;
// }

struct WinningPrize {
    address token; // any-Token, this-Credit
    uint256 amount;
}

struct Competition {
    uint256 id;
    uint32 countTotal;
    uint32 countSold;
    int256 priceForGuest;
    int256 priceForMember;
    uint32 maxPerPerson;
    uint timeStart;
    uint timeEnd;
    string path;
    // WinningPrize[] winningPrize; // prize1 or prize2 ...
    address winner;
    uint8 status; // 0-Created, 1-Started, 2-SaleEnd, 3-Past
}

contract ProjectXCompetition {
    address private _owner;
    Competition[] public competitions;
    mapping (address => mapping (uint256 => uint32)) public ticketPerson;
    mapping (uint256 => TicketInfo[]) public ticketSold;
    mapping (address => MemberInfo) public members;
    mapping (uint256 => WinningPrize) private winningPrizes;
    address public token = 0xa0B6D4aF16bfd92deD0660894e1aeb22AE00673c;
    uint256 public discount5 = 250;
    uint256 public discount10 = 500;
    uint256 public discountCancel = 5000;
    uint256 public feePerMonth = 1e18;
    uint256 public feePerYear = 10e18;
    uint256 public creditsPerMonth = 5e17;

    constructor() {
        _owner = msg.sender;
    }

    modifier forOwner() {
        require(_owner==msg.sender, "Modifier: Only owner call.");
        _;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function setOwner(address account) public forOwner {
        _owner = account;
    }

    function getCompetitions () public view returns(Competition[] memory) {
        Competition[] memory id = new Competition[](competitions.length);
        for (uint i = 0; i < competitions.length; i++) {
            Competition storage competition = competitions[i];
            id[i] = competition;
        }
        return id;
    }    

    function create(uint32 countTotal, int256 priceForGuest, int256 priceForMember, uint32 maxPerPerson, string memory path) public forOwner returns (uint256) {
        require(countTotal > 0, "Create: CountTotal must be positive.");
        require(maxPerPerson > 0 && maxPerPerson <= countTotal, "Create: MaxPerPerson is invalid.");
        require(priceForGuest > 0 && priceForGuest > priceForMember, "Create: Invalid Price.");
        uint256 idNew = competitions.length+1;
        competitions.push(Competition({
            id: idNew,
            countTotal: countTotal,
            countSold: 0,
            priceForGuest: priceForGuest,
            priceForMember: priceForMember,
            maxPerPerson: maxPerPerson,
            timeStart: 0,
            timeEnd: 0,
            path: path,
            winner: address(0),
            status: 0
        }));        
        return idNew;
    }

    function update(uint256 id, uint32 countTotal, int256 priceForGuest, int256 priceForMember, uint32 maxPerPerson, string memory path) public forOwner {
        require(id > 0 && id <= competitions.length, "Update: Invalid id.");
        require(countTotal > 0, "Update: CountTotal must be positive.");
        require(maxPerPerson > 0 && maxPerPerson <= countTotal, "Update: MaxPerPerson is invalid.");
        require(priceForGuest > 0 &&  priceForGuest > priceForMember, "Update: Invalid Price.");
        Competition storage competition = competitions[id-1];
        require(id==competition.id, "Update: Unregistered competition.");
        require(competition.status==0, "Update: Competition was started.");
        competition.countTotal = countTotal;
        competition.priceForGuest = priceForGuest;
        competition.priceForMember = priceForMember;
        competition.maxPerPerson = maxPerPerson;
        competition.path = path;
    }

    function start(uint256 id, uint endTime) public forOwner {
        require(id > 0 && id <= competitions.length, "Start: Invalid id.");
        Competition storage competition = competitions[id-1];
        require(competition.status==0, "Start: Competition was started.");
        require(endTime > block.timestamp, "Start: EndTime must be later than now.");
        competition.timeStart = block.timestamp;
        competition.timeEnd = endTime;
        competition.status = 1;
    }

    function finish(uint256 id) public forOwner returns (address) {
        require(id > 0 && id <= competitions.length, "Finish: Invalid id.");
        Competition storage competition = competitions[id-1];
        require(competition.status==1, "Finish: Competition was not started.");
        require(competition.timeEnd <= block.timestamp, "Finish: Competition is not ready to finish.");
        require(competition.countSold > 0, "Finish: No ticket was sold.");
        TicketInfo[] storage tickets = ticketSold[id-1];
        require(tickets.length > 0, "Finish: No ticket was sold.");
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp - competition.timeStart) +
                    block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(id)))) / (block.timestamp)) +
                    block.number
                )
            )
        ) % competition.countSold;
        uint256 sum = 0;
        uint256 i = 0;
        for(i = 0;i<tickets.length;i++) {
            if(tickets[i].amount==0) continue;
            sum = sum + tickets[i].amount;
            if(sum > seed) {
                competition.winner = tickets[i].account;
                competition.status = 2;
                return competition.winner;
            }
        }
        return address(0);
    }

    function buy(uint256 id, uint32 count) public {
        require(id > 0 && id <= competitions.length, "Buy: Invalid id.");
        Competition storage competition = competitions[id-1];
        require(competition.status==1, "Buy: Competition is not pending.");
        require(competition.timeEnd > block.timestamp, "Buy: Competition is timeout.");
        bool hasMembership = isMember(msg.sender);
        require(competition.priceForGuest>-1 && !hasMembership, "Buy: Only Members can buy.");
        uint256 price = uint256(hasMembership?competition.priceForMember:competition.priceForGuest) * count;
        if(count >= 10)
            price -= price * discount10 / 10000;
        else if(count >= 5)
            price -= price * discount5 / 10000;
        if(hasMembership && competition.priceForMember>-1) {
            MemberInfo storage member = members[msg.sender];
            uint256 credits = creditBalance(msg.sender);
            if(credits > price) {
                price = 0;
                member.creditsMinus += price;
            } else if(credits > 0) {
                price -= credits;
                member.creditsMinus += credits;
            }
        }
        if(price > 0) {
            require(IERC20(token).balanceOf(address(msg.sender)) >= price, "Buy: Insufficent balance.");
            IERC20(token).transferFrom(address(msg.sender), address(this), price);
        }
        ticketPerson[msg.sender][id] += count;
        competition.countSold += count;
        require(ticketPerson[msg.sender][id] <= competition.maxPerPerson, "Buy: You cannot buy more than MaxPerPerson.");
        TicketInfo[] storage tickets = ticketSold[id-1];
        tickets.push(TicketInfo({
            account: msg.sender, amount: count
        }));        
    }

    function sell(uint256 id, uint32 count) public {
        require(id > 0 && id <= competitions.length, "Sell: Invalid id.");
        Competition storage competition = competitions[id-1];
        require(competition.status==1, "Sell: Competition is not pending.");
        require(competition.timeEnd > block.timestamp, "Sell: Competition is timeout.");
        require(ticketPerson[msg.sender][id] >= count, "Sell: You didnot purchase so.");
        uint256 price = uint256(competition.priceForGuest) * count;
        price -= price * discountCancel / 10000;
        IERC20(token).transfer(address(msg.sender), price);
        ticketPerson[msg.sender][id] -= count;
        competition.countSold -= count;
        TicketInfo[] storage tickets = ticketSold[id-1];
        uint256 i = 0;
        for(i = 0;i<tickets.length;i++) {
            if(msg.sender == tickets[i].account && tickets[i].amount > 0) {
                if(count > tickets[i].amount) {
                    count -= tickets[i].amount;
                    tickets[i].amount = 0;
                } else {
                    tickets[i].amount -= count;
                    count = 0;
                }
                if(count == 0) break;
            }
        }
    }

    function withdraw(uint256 amount) public forOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Withdraw: Insufficent balance.");
        IERC20(token).transfer(address(msg.sender), amount);
    }

    function payFeePerMonth(uint8 count) public {
        require(count > 0 && count < 12, "PayFee: Invalid number of months.");
        MemberInfo storage member = members[msg.sender];
        if(member.timeUntil < block.timestamp) {
            member.balance = 0;
            member.creditsMinus = 0;
            member.creditsPlus = 0;
            member.timeStart = block.timestamp;
            member.timeUntil = block.timestamp + count * 30 days;
        } else {
            member.timeUntil += count * 30 days;
        }
        uint256 fee = feePerMonth * count;
        IERC20(token).transferFrom(address(msg.sender), address(this), fee);
        member.balance += fee;
    }

    function payFeePerYear(uint8 count) public {
        require(count > 0, "PayFee: Invalid number of years.");
        MemberInfo storage member = members[msg.sender];
        if(member.timeUntil < block.timestamp) {
            member.balance = 0;
            member.creditsMinus = 0;
            member.creditsPlus = 0;
            member.timeStart = block.timestamp;
            member.timeUntil = block.timestamp + count * 360 days;
        } else {
            member.timeUntil += count * 360 days;
        }
        uint256 fee = feePerYear * count;
        IERC20(token).transferFrom(address(msg.sender), address(this), fee);
        member.balance += fee;
    }

    function claimTokens(uint256 id) public {
        require(id > 0 && id <= competitions.length, "Claim: Invalid id.");
        Competition storage competition = competitions[id-1];
        require(competition.status==2, "Claim: Competition is not finished.");
        require(competition.timeEnd <= block.timestamp, "Claim: Competition is not finished.");
        require(ticketPerson[msg.sender][id] > 0, "Claim: You purchased no tickets.");
        require(competition.winner == msg.sender, "Claim: You are not a winner.");
        WinningPrize storage winningPrize = winningPrizes[id];
        require(winningPrize.amount > 0, "Claim: There is no prize.");
        IERC20(winningPrize.token).transfer(address(msg.sender), winningPrize.amount);
        competition.status = 3;
    }

    function sendCredits(address account, uint256 amount) public forOwner {
        require(amount > 0, "Send: Invalid amount.");
        require(isMember(account)==true, "Send: Credits can be sent to only a member.");
        MemberInfo storage member = members[account];
        member.creditsPlus += amount;
    }

    function claimCredits(uint256 id) public {
        require(isMember(msg.sender)==true, "Claim: Only Member can claim credits.");
        require(id > 0 && id <= competitions.length, "Claim: Invalid id.");
        Competition storage competition = competitions[id-1];
        require(competition.status==2, "Claim: Competition is not finished.");
        require(competition.timeEnd <= block.timestamp, "Claim: Competition is not finished.");
        require(ticketPerson[msg.sender][id] > 0, "Claim: You purchased no tickets.");
        require(competition.winner == msg.sender, "Claim: You are not a winner.");
        WinningPrize storage winningPrize = winningPrizes[id];
        require(winningPrize.amount > 0, "Claim: There is no prize.");
        MemberInfo storage member = members[msg.sender];
        member.creditsPlus += winningPrize.amount;
        competition.status = 3;
    }

    function setDiscount5(uint256 discount) public forOwner {
        discount5 = discount;
    }

    function setDiscount10(uint256 discount) public forOwner {
        discount10 = discount;
    }
    
    function setDiscountCancel(uint256 discount) public forOwner {
        discountCancel = discount;
    }
    
    function setFeePerMonth(uint256 fee) public forOwner {
        feePerMonth = fee;
    }
    
    function setFeePerYear(uint256 fee) public forOwner {
        feePerYear = fee;
    }

    function setToken(address _token) public forOwner {
        token = _token;
    }

    function setCreditsPerMonth(uint256 credits) public forOwner {
        creditsPerMonth = credits;
    }

    function creditBalance(address account) public view returns (uint256) {
        MemberInfo storage member = members[account];
        if(member.timeUntil < block.timestamp)
            return 0;
        return member.creditsPlus - member.creditsMinus + creditsPerMonth * ((block.timestamp - member.timeStart - 1) / 30 days + 1);
    }

    function isMember(address account) public view returns (bool) {
        MemberInfo storage member = members[account];
        if(member.timeUntil < block.timestamp)
            return false;
        return true;
    }
}