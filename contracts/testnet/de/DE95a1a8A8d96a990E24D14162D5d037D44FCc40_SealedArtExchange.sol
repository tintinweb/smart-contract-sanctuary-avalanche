// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

abstract contract EIP712 {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// @param v Part of the ECDSA signature
    /// @param r Part of the ECDSA signature
    /// @param s Part of the ECDSA signature
    struct WithdrawalPacket {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        uint256 amount;
        uint256 nonce;
        address account;
    }

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The chain ID used by EIP-712
    uint256 internal immutable INITIAL_CHAIN_ID;

    /// @notice The domain separator used by EIP-712
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// Packet verification
    /// -----------------------------------------------------------------------

    function _verifySig(
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual returns (address) {
        // verify signature
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(data)
                )
            ),
            v,
            r,
            s
        );
        return recoveredAddress;
    }

    /// @notice Verifies whether a packet is valid and returns the result.
    /// @dev The deadline, request, and signature are verified.
    /// @param packet The packet provided by the offchain data provider
    function _verifyWithdrawal(
        WithdrawalPacket calldata packet
    ) internal virtual returns (address) {
        // verify deadline
        require(block.timestamp < packet.deadline, ">deadline");

        // verify signature
        address recoveredAddress = _verifySig(
            abi.encode(
                keccak256(
                    "VerifyWithdrawal(uint256 deadline,uint256 amount,uint256 nonce,address account)"
                ),
                packet.deadline,
                packet.amount,
                packet.nonce,
                packet.account
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return recoveredAddress; // Invariant: sequencer != address(0), we maintain this every time sequencer is set
    }

    struct Bid {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 maxAmount;
    }

    function _verifyBid(
        Bid calldata packet
    ) internal virtual returns (address) {
        address recoveredAddress =  _verifySig(
            abi.encode(
                keccak256("Bid(bytes32 auctionId,uint256 maxAmount)"),
                packet.auctionId,
                packet.maxAmount
            ),
            packet.v,
            packet.r,
            packet.s
        );
        require(recoveredAddress != address(0), "sig");
        return recoveredAddress;
    }

    struct BidWinner {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 amount;
        address winner;
    }

    function _verifyBidWinner(
        BidWinner calldata packet
    ) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256("BidWinner(bytes32 auctionId,uint256 amount,address winner)"),
                packet.auctionId,
                packet.amount,
                packet.winner
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    struct CancelAuction {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 auctionId;
        uint256 deadline;
    }

    function _verifyCancelAuction(
        CancelAuction calldata packet
    ) internal virtual returns (address) {
        require(block.timestamp <= packet.deadline, "deadline");
        return _verifySig(
            abi.encode(
                keccak256("CancelAuction(bytes32 auctionId,uint256 deadline)"),
                packet.auctionId,
                packet.deadline
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    struct Offer {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address nftContract;
        uint256 nftId;
        uint256 amount;
        uint256 deadline;
        uint256 counter;
        uint256 nonce;
    }

    function _verifyBuyOffer(
        Offer calldata packet
    ) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256("BuyOffer(address nftContract,uint256 nftId,uint256 amount,uint256 deadline,uint256 counter,uint256 nonce)"),
                packet.nftContract,
                packet.nftId,
                packet.amount,
                packet.deadline,
                packet.counter,
                packet.nonce
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    function _verifySellOffer(
        Offer calldata packet
    ) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256("SellOffer(address nftContract,uint256 nftId,uint256 amount,uint256 deadline,uint256 counter,uint256 nonce)"),
                packet.nftContract,
                packet.nftId,
                packet.amount,
                packet.deadline,
                packet.counter,
                packet.nonce
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    struct OfferAttestation {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address nftContract;
        uint256 nftId;
        uint256 amount;
        address buyer;
        address seller;
        uint256 deadline;
    }

    function _verifyOfferAttestation(
        OfferAttestation calldata packet
    ) internal virtual returns (address) {
        return _verifySig(
            abi.encode(
                keccak256("OfferAttestation(address nftContract,uint256 nftId,uint256 amount,address buyer,address seller,uint256 deadline)"),
                packet.nftContract,
                packet.nftId,
                packet.amount,
                packet.buyer,
                packet.seller,
                packet.deadline
            ),
            packet.v,
            packet.r,
            packet.s
        );
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 compliance
    /// -----------------------------------------------------------------------

    /// @notice The domain separator used by EIP-712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    /// @notice Computes the domain separator used by EIP-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256("SealedArtExchange"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

pragma solidity ^0.8.7;

import "./EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SealedFundingFactory.sol";

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface RoyaltyEngine {
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);
}

contract SealedArtExchange is EIP712, Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping(address => uint256) private _balances;
    string public constant name = "Sealed ETH";
    string public constant symbol = "SETH";
    uint8 public constant decimals = 18;
    function totalSupply() public view returns (uint){
        return address(this).balance;
    }

    // sequencer and settleSequencer are separated as an extra security measure against key leakage through side attacks
    // If a side channel attack is possible that requires multiple signatures to be made, settleSequencer will be more protected
    // against it because each signature will require an onchain action, which will make the attack extremely expensive
    // It also allows us to use different security systems for the two keys, since settleSequencer is much more sensitive
    address public sequencer; // Invariant: always different than address(0)
    address public settleSequencer; // Invariant: always different than address(0)
    address payable public treasury;
    SealedFundingFactory public immutable sealedFundingFactory;
    uint256 internal constant MAX_PROTOCOL_FEE = 0.1e18; // 10%
    uint public feeMultiplier;
    uint public FORCED_WITHDRAW_DELAY = 2 days;
    RoyaltyEngine public constant royaltyEngine = RoyaltyEngine(0xBc40d21999b4BF120d330Ee3a2DE415287f626C9);
    enum AuctionState {
        NONE, // 0 -> doesnt exist, default state
        CREATED,
        CLOSED
    }
    mapping(bytes32=>AuctionState) public auctionState;
    mapping(address=>mapping(uint=>mapping(uint=>uint))) public pendingWithdrawals;
    mapping(bytes32=>uint) public pendingAuctionCancels;
    mapping(address=>bool) public guardians;
    enum Nonce {
        UNUSED,
        USED
    }
    mapping(uint=>Nonce) public nonceState;
    mapping(address=>mapping(uint=>Nonce)) public orderNonces;
    mapping(address=>uint) public accountCounter;

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    constructor(address _sequencer, address payable _treasury, address _settleSequencer){
        require(_sequencer != address(0) && _settleSequencer != address(0), "0x0 sequencer not allowed");
        sequencer = _sequencer;
        treasury = _treasury;
        settleSequencer = _settleSequencer;
        sealedFundingFactory = new SealedFundingFactory(address(this));
    }

    event SequencerChanged(address newSequencer, address newSettleSequencer);
    function changeSequencer(address newSequencer, address newSettleSequencer) onlyOwner external {
        require(newSequencer != address(0) && newSettleSequencer != address(0), "0x0 sequencer not allowed");
        sequencer = newSequencer;
        settleSequencer = newSettleSequencer;
        emit SequencerChanged(newSequencer, newSettleSequencer);
    }

    event ForcedWithdrawDelayChanged(uint newDelay);
    function changeForcedWithdrawDelay(uint newDelay) onlyOwner external {
        require(newDelay < 10 days, "<10 days");
        FORCED_WITHDRAW_DELAY = newDelay;
        emit ForcedWithdrawDelayChanged(newDelay);
    }

    event TreasuryChanged(address newTreasury);
    function changeTreasury(address payable newTreasury) onlyOwner external {
        treasury = newTreasury;
        emit TreasuryChanged(newTreasury);
    }

    event GuardianSet(address guardian, bool value);
    function setGuardian(address guardian, bool value) onlyOwner external {
        guardians[guardian] = value;
        emit GuardianSet(guardian, value);
    }

    event SequencerDisabled(address guardian);
    function emergencyDisableSequencer() external {
        require(guardians[msg.sender] == true, "not guardian");
        // Maintain the invariant that sequencers are not 0x0
        sequencer = address(0x000000000000000000000000000000000000dEaD);
        settleSequencer = address(0x000000000000000000000000000000000000dEaD);
        emit SequencerDisabled(msg.sender);
    }

    event FeeChanged(uint newFeeMultiplier);
    function changeFee(uint newFeeMultiplier) onlyOwner external {
        require(newFeeMultiplier <= MAX_PROTOCOL_FEE, "fee too high");
        feeMultiplier = newFeeMultiplier;
        emit FeeChanged(newFeeMultiplier);
    }

    function deposit(address receiver) public payable {
        _balances[receiver] += msg.value;
        emit Transfer(address(0), receiver, msg.value);
    }

    function _withdraw(uint amount) internal {
        _balances[msg.sender] -= amount;
        (bool success,) = payable(msg.sender).call{value:amount}("");
        require(success);
        emit Transfer(msg.sender, address(0), amount);
    }

    event WithdrawNonceUsed(uint nonce);
    function withdraw(WithdrawalPacket calldata packet) external {
        require(_verifyWithdrawal(packet) == sequencer, "!sequencer");
        require(nonceState[packet.nonce] == Nonce.UNUSED, "replayed");
        nonceState[packet.nonce] = Nonce.USED;
        require(packet.account == msg.sender, "not sender");
        _withdraw(packet.amount);
        emit WithdrawNonceUsed(packet.nonce);
    }

    event StartWithdrawal(address owner,  uint256 timestamp, uint256 nonce, uint amount);
    function startWithdrawal(uint amount, uint256 nonce) external {
        pendingWithdrawals[msg.sender][block.timestamp][nonce] = amount;
        emit StartWithdrawal(msg.sender, block.timestamp, nonce, amount);
    }

    event CancelWithdrawal(address owner, uint256 timestamp, uint256 nonce);
    function cancelPendingWithdrawal(uint256 timestamp, uint256 nonce) external {
        pendingWithdrawals[msg.sender][timestamp][nonce] = 0;
        emit CancelWithdrawal(msg.sender, timestamp, nonce);
    }

    event ExecuteDelayedWithdrawal(address owner, uint256 timestamp, uint256 nonce);
    function executePendingWithdrawal(uint256 timestamp, uint256 nonce) external {
        require(timestamp + FORCED_WITHDRAW_DELAY < block.timestamp, "too soon");
        uint amount = pendingWithdrawals[msg.sender][timestamp][nonce];
        pendingWithdrawals[msg.sender][timestamp][nonce] = 0;
        _withdraw(amount);
        emit ExecuteDelayedWithdrawal(msg.sender, timestamp, nonce);
    }

    function calculateAuctionHash(address owner, address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve) pure public returns (bytes32) {
        return keccak256(abi.encode(owner, nftContract, auctionDuration, auctionType, nftId, reserve));
    }

    event AuctionCreated(address owner, address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve);
    function _createAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve) internal {
        bytes32 auctionId = calculateAuctionHash(msg.sender, nftContract, auctionDuration, auctionType, nftId, reserve);
        require(auctionState[auctionId] == AuctionState.NONE, "repeated auction id"); // maybe this is not needed?
        auctionState[auctionId] = AuctionState.CREATED;
        emit AuctionCreated(msg.sender, nftContract, auctionDuration, auctionType, nftId, reserve);
    }

    function createAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve) external {
        IERC721(nftContract).transferFrom(msg.sender, address(this), nftId);
        _createAuction(nftContract, auctionDuration, auctionType, nftId, reserve);
    }

    event AuctionCancelled(bytes32 auctionId);
    function _cancelAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve, CancelAuction calldata cancelAuctionPacket) internal {
        require(_verifyCancelAuction(cancelAuctionPacket) == sequencer, "!sequencer");
        bytes32 auctionId = calculateAuctionHash(msg.sender, nftContract, auctionDuration, auctionType, nftId, reserve);
        require(auctionState[auctionId] == AuctionState.CREATED, "bad state");
        require(cancelAuctionPacket.auctionId == auctionId, "!auctionId");
        auctionState[auctionId] = AuctionState.CLOSED;
        emit AuctionCancelled(auctionId);
    }

    function cancelAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve, CancelAuction calldata cancelAuctionPacket) external {
        _cancelAuction(nftContract, auctionDuration, auctionType, nftId, reserve, cancelAuctionPacket);
        IERC721(nftContract).transferFrom(address(this), msg.sender, nftId);
    }

    function changeAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve,
      uint40 newAuctionDuration, uint56 newAuctionType, uint newReserve, CancelAuction calldata cancelAuctionPacket) external {
        _cancelAuction(nftContract, auctionDuration, auctionType, nftId, reserve, cancelAuctionPacket);
        _createAuction(nftContract, newAuctionDuration, newAuctionType, nftId, newReserve);
    }

    event StartDelayedAuctionCancel(bytes32 auctionId);
    function startCancelAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve) external {
        bytes32 auctionId = calculateAuctionHash(msg.sender, nftContract, auctionDuration, auctionType, nftId, reserve);
        require(auctionState[auctionId] == AuctionState.CREATED, "bad auction state");
        pendingAuctionCancels[auctionId] = block.timestamp;
        emit StartDelayedAuctionCancel(auctionId);
    }

    event ExecuteDelayedAuctionCancel(bytes32 auctionId);
    function executeCancelAuction(address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve) external {
        bytes32 auctionId = calculateAuctionHash(msg.sender, nftContract, auctionDuration, auctionType, nftId, reserve);
        uint timestamp = pendingAuctionCancels[auctionId];
        require(timestamp != 0 && (timestamp + FORCED_WITHDRAW_DELAY) < block.timestamp, "too soon");
        require(auctionState[auctionId] == AuctionState.CREATED, "not open");
        auctionState[auctionId] = AuctionState.CLOSED;
        pendingAuctionCancels[auctionId] = 0;
        emit AuctionCancelled(auctionId);
        IERC721(nftContract).transferFrom(address(this), msg.sender, nftId);
        emit ExecuteDelayedAuctionCancel(auctionId);
    }

    function _transferETH(address payable receiver, uint amount) internal {
        (bool success,) = receiver.call{value:amount, gas: 300_000}("");
        if(success == false){
           _balances[receiver] += amount;
           emit Transfer(address(0), receiver, amount);
        }
    }

    function _distributeSale(address nftContract, uint nftId, uint amount, address payable seller) internal {
        uint totalRoyalty = 0;
        require(totalRoyalty <= (amount/3), "Royalty too high"); // Protect against royalty hacks
        uint feeAmount = (amount * feeMultiplier)/1e18;
        _transferETH(treasury, feeAmount);
        _transferETH(seller, amount - (totalRoyalty+feeAmount)); // totalRoyalty+feeAmount <= amount*0.43
    }

    event AuctionSettled(bytes32 auctionId);
    function settleAuction(address payable nftOwner, address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve, Bid calldata bid, BidWinner calldata bidWinner) public {
        bytes32 auctionId = calculateAuctionHash(nftOwner, nftContract, auctionDuration, auctionType, nftId, reserve);
        require(auctionState[auctionId] == AuctionState.CREATED, "bad auction state");
        auctionState[auctionId] = AuctionState.CLOSED;
        require(bidWinner.auctionId == auctionId && bid.auctionId == auctionId, "!auctionId");
        uint amount = bidWinner.amount;
        require(amount <= bid.maxAmount && amount >= reserve, "!amount");
        require(_verifyBid(bid) == bidWinner.winner, "!winner");
        require(_verifyBidWinner(bidWinner) == settleSequencer, "!settleSequencer");
        _balances[bidWinner.winner] -= amount;
        emit Transfer(bidWinner.winner, address(0), amount);
        IERC721(nftContract).transferFrom(address(this), bidWinner.winner, nftId);
        _distributeSale(nftContract, nftId, amount, nftOwner);
        emit AuctionSettled(auctionId);
    }

    function settleAuctionWithSealedBids(bytes32[] calldata salts, address payable nftOwner, address nftContract, uint40 auctionDuration, uint56 auctionType, uint nftId, uint reserve, Bid calldata bid, BidWinner calldata bidWinner) external {
        for(uint i=0; i<salts.length;){
            // We use try/catch here to prevent a griefing attack where someone could deploySealedFunding() one of the
            // sealed fundings of the buyer right before another user calls this function, thus making it revert
            // It's still possible for the buyer to perform this attack by frontrunning the call with a withdraw()
            // but that's trivial to solve by just revealing all the salts of the griefing user
            try sealedFundingFactory.deploySealedFunding{gas: 100_000}(salts[i], bidWinner.winner) {} // cost of deploySealedFunding() is between 55k and 82k
            catch {}
            unchecked {
                ++i;
            }
        }
        settleAuction(nftOwner, nftContract, auctionDuration, auctionType, nftId, reserve, bid, bidWinner);
    }

    event CounterIncreased(address account, uint newCounter);
    function increaseCounter(uint newCounter) external {
        require(newCounter > accountCounter[msg.sender], "too low");
        accountCounter[msg.sender] = newCounter;
        emit CounterIncreased(msg.sender, newCounter);
    }

    event OfferCancelled(address account, uint nonce);
    function cancelOffer(uint nonce) external {
        orderNonces[msg.sender][nonce] = Nonce.USED;
        emit OfferCancelled(msg.sender, nonce);
    }

    function _verifyOffer(Offer calldata offer, address creator) private {
        require(offer.deadline > block.timestamp, "!deadline");
        require(orderNonces[creator][offer.nonce] == Nonce.UNUSED, "!orderNonce");
        orderNonces[creator][offer.nonce] = Nonce.USED;
        require(offer.counter > accountCounter[creator], "!counter");
    }

    event OrdersMatched(bytes32 auctionId, address buyer, address sender, uint buyerNonce, uint sellerNonce);
    function matchOrders(Offer calldata sellerOffer, Offer calldata buyerOffer, OfferAttestation calldata sequencerStamp, uint40 auctionDuration, uint56 auctionType, uint reserve) external {
        // First run verifications that can fail due to a delayed tx
        require(sequencerStamp.deadline > block.timestamp, "!deadline");
        if(msg.sender != sequencerStamp.buyer){
            _verifyOffer(buyerOffer, sequencerStamp.buyer);
            require(_verifyBuyOffer(buyerOffer) == sequencerStamp.buyer && sequencerStamp.buyer != address(0), "!buyer");
        }
        if(msg.sender != sequencerStamp.seller){
            _verifyOffer(sellerOffer, sequencerStamp.seller);
            require(_verifySellOffer(sellerOffer) == sequencerStamp.seller && sequencerStamp.seller != address(0), "!seller");
        }
        // Verify NFT is owned by seller
        bytes32 auctionId = calculateAuctionHash(sequencerStamp.seller, sequencerStamp.nftContract, auctionDuration, auctionType, sequencerStamp.nftId, reserve);
        require(auctionState[auctionId] == AuctionState.CREATED, "bad auction state");
        // Execute sale
        _balances[sequencerStamp.buyer] -= sequencerStamp.amount;
        emit Transfer(sequencerStamp.buyer, address(0), sequencerStamp.amount);
        auctionState[auctionId] = AuctionState.CLOSED;

        // Run verifications that can't fail due to external factors
        require(sequencerStamp.amount == sellerOffer.amount && sequencerStamp.amount == buyerOffer.amount, "!amount");
        require(sequencerStamp.nftContract == sellerOffer.nftContract && sequencerStamp.nftContract == buyerOffer.nftContract, "!nftContract");
        require(sequencerStamp.nftId == sellerOffer.nftId && sequencerStamp.nftId == buyerOffer.nftId, "!nftId");
        require(_verifyOfferAttestation(sequencerStamp) == sequencer, "!sequencer"); // This needs sequencer approval to avoid someone rugging their bids by buying another NFT
        
        // Finish executing sale
        IERC721(sequencerStamp.nftContract).transferFrom(address(this), sequencerStamp.buyer, sequencerStamp.nftId);
        _distributeSale(sequencerStamp.nftContract, sequencerStamp.nftId, sequencerStamp.amount, payable(sequencerStamp.seller));
        emit OrdersMatched(auctionId, sequencerStamp.buyer, msg.sender, buyerOffer.nonce, sellerOffer.nonce);
    }
}

pragma solidity ^0.8.7;

interface IExchange {
    function deposit(address receiver) external payable;
}

contract SealedFunding {
    constructor(address _owner, address _exchange){
        IExchange(_exchange).deposit{value: address(this).balance}(_owner);
    }

    // Decided against including functions to retrieve tokens incorrently sent to this contract because they'd increase gas cost 100%-150%
    // Since I expect a lot of these contracts to be created it's not worth it as these mistakes seem unlikely
}

pragma solidity ^0.8.7;
import "./SealedFunding.sol";

contract SealedFundingFactory {
    address immutable public exchange;
    constructor(address _exchange){
        exchange = _exchange;
    }

    event SealedFundingRevealed(bytes32 salt, address owner);
    function deploySealedFunding(bytes32 salt, address owner) public {
        new SealedFunding{salt: salt}(owner, exchange);
        emit SealedFundingRevealed(salt, owner);
    }

    function computeSealedFundingAddress(bytes32 salt, address owner) external view returns(address predictedAddress, bool isDeployed){
        predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(SealedFunding).creationCode, abi.encode(owner, exchange)))
        )))));
        isDeployed = predictedAddress.code.length != 0;
    }
}