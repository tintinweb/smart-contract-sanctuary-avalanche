/**
 *Submitted for verification at snowtrace.io on 2022-10-27
*/

// A demo showing connect Aboard to Geode for AVAX dynamic staking 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPortal {
    function stake(
      uint256 planetId,
      uint256 minGavax,
      uint256 deadline
    ) external payable returns (uint256 totalgAvax);
}

interface IgAVAX {
    function setApprovalForAll(address operator, bool approved) external;
}

interface ISwap {
    function calculateSwap(
      uint8 tokenIndexFrom,
      uint8 tokenIndexTo,
      uint256 dx
    ) external view returns (uint256);
    function swap(
      uint8 tokenIndexFrom,
      uint8 tokenIndexTo,
      uint256 dx,
      uint256 minDy,
      uint256 deadline
    ) external payable returns (uint256);
}

contract PerpGeodeDemo {
    uint256 constant NOT_ENTERED = 1;
    uint256 constant ENTERED = type(uint256).max;
    uint256 immutable PLANETID;
    address immutable PORTAL;
    address immutable WPOOL;
    address immutable GAVAX;
    address immutable GATEWAY;

    uint256 private _STATUS_;

    event LogDeposit(
        address indexed account,
        uint256 amount,
        uint256 avaxIn,
        uint256 gavaxOut
    );

    event LogWithdraw(
        address indexed account,
        address destination,
        uint256 amount,
        uint256 gavaxIn,
        uint256 avaxout
    );

    modifier nonReentrant() {
        require(_STATUS_ != ENTERED, "ReentrancyGuard: reentrant call");
        _STATUS_ = ENTERED;
        _;
        _STATUS_ = NOT_ENTERED;
    }

    modifier isGateway() {
        require(msg.sender == GATEWAY, "Sender Is Not Gateway");
        _;
    }

    /**
     * @dev The constructor of the contract.
     *
     * @param  planetid The planet ID on Geode
     * @param  portal   Geode portal contract address
     * @param  wpool    Geode withdraw pool contract address for the planetid
     * @param  gAVAX    Geode gAVAX erc1155 token address
     */
    constructor (
        uint256 planetid,
        address portal,
        address wpool,
        address gAVAX
    )
    {
        PLANETID = planetid;
        PORTAL = portal;
        WPOOL = wpool;
        GAVAX = gAVAX;
        GATEWAY = msg.sender;
    }

    /**
     * @notice Deposit native token from the msg.sender into an account.
     * @dev Emits LogDeposit events.
     *
     * @param  account  The account for which to credit the deposit.
     */
    function depositNative(
        address account
    )
        external
        payable
        nonReentrant
    {
        //add requirement to check active state
        uint256 avaxIn = address(this).balance;
        uint256 gavaxOut = IPortal(PORTAL).stake{value: avaxIn}(PLANETID, 0, ENTERED);

        emit LogDeposit(
            account,
            msg.value,
            avaxIn,
            gavaxOut
        );
    }

    function approve(
        address operator
    )
        external
        isGateway
    {
        IgAVAX(GAVAX).setApprovalForAll(operator, true);
    }

    /**
     * @dev necessary for Geode stake function
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function withdraw(
        address account,
        address payable destination,
        uint256 amount
    )    
        external
        nonReentrant
        isGateway
    {
        //calculate how much gAVAX into pool to get amount AVAX out
        uint256 gavaxRaw = ISwap(WPOOL).calculateSwap(0, 1, amount);
        uint256 gavaxIn = gavaxRaw + gavaxRaw >> 10;
        uint256 avaxOut = ISwap(WPOOL).swap(1, 0, gavaxIn, 0, ENTERED);
        destination.transfer(amount);

        emit LogWithdraw(
            account,
            destination,
            amount,
            gavaxIn,
            avaxOut
        );
    }

    receive() external payable {}

}