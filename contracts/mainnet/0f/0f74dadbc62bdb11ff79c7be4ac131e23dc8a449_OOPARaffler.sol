// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./VRFConsumer.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IOOPATraits {
    function batchMint(uint[] calldata traitTypes, uint[] calldata amounts, address user) external; 
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IOOPAShoppingBag {
    function mintShoppingBag(uint _amount, address _recipient) external;
}

interface IOOPACredits {
    function adminSpendCredits(uint _amount, address _user) external;
}



contract OOPARaffler is Ownable, VRFConsumer, ERC1155Holder {
    IOOPATraits immutable public OOPA_TRAITS;
    IOOPACredits immutable public OOPA_CREDITS;
    IOOPAShoppingBag immutable public OOPA_GIFTBOX;

    enum RaffleType{ERC721 , ERC1155, WHITELIST, ERC1155BUNDLE}

    struct Raffle {
        RaffleType raffleType;
        address raffledCollectionERC721; //ERC721
        address raffledCollectionERC1155;
        uint32 tokenIdERC721; //ERC721
        uint32 maxTicketAvailable;
        uint32 ticketsSold; // Mutable
        uint32 pricePerTicket;
        uint64 raffledGoodERC1155; // ERC1155
        uint32 raffledGoodsAmount;
        uint32 startDate;
        uint32 endDate;
        uint256[] ERC1155BundleRewards;
    }

    struct RaffleTicket {
        address participant;
        uint32 ticketsBought;
        uint32 ticketsIndexEnd;
    }

    struct RaffleWinnersData {
        mapping (address => uint256) winners;
        address raffledCollectionAddress;
        uint32 tokenIdERC721;
        uint64 raffledGoodERC1155;
        RaffleType raffleType;
        uint16 rewardsClaimed;
        uint16 totalRewardAmount;
        uint256[] ERC1155BundleRewards;
    }

    uint256 public raffleId;
    mapping(uint => Raffle) public Raffles;
    mapping(uint => RaffleTicket[]) public RaffleTickets;
    mapping(uint => RaffleWinnersData) public RaffleWinners;
    mapping(address => bool) public AdminList;
    mapping(uint => bool) public RaffleFinalizeRequestIssued;

    mapping(uint => address[]) public TEST_RAFFLE_WINNER; //TODO REMOVE


    mapping(uint256 => uint256) private PlayerRequest;


    error Unauthorized();
    error InvalidRaffle();
    error NotEnoughTickets();
    error RaffleIsLive();
    error InvalidCollectionForRewardTransfer();
    error NothingToClaim();

    event RaffleFinalized(uint raflleId, address[] winnerAddresses, uint[] diceRolls);
    event RaffleCreated(Raffle _raffle, uint raffleId);
    event RaffleEdited(Raffle _raffle, uint raffleId);
    event TicketBought(uint raffleId, uint ticketAmount);
    event RewardClaimed(uint raffleId,uint amount);
    event RaffleDeleted(uint raffleId);

    constructor(
        address _oopaTraitsAddress,
        address _oopaCredits,
        address _shoppingBagAddress,
        uint64 subscriptionId
    ) VRFConsumer(subscriptionId) {
        OOPA_TRAITS = IOOPATraits(_oopaTraitsAddress);
        OOPA_GIFTBOX = IOOPAShoppingBag(_shoppingBagAddress);
        OOPA_CREDITS = IOOPACredits(_oopaCredits);
    }

    function editAdminList(address _admin, bool _value) external onlyOwner {
        AdminList[_admin] = _value;
    }

    function editRaffle(uint _raffleId, Raffle memory _raffle ) external onlyOwner {
        Raffles[_raffleId] = _raffle;
        emit RaffleEdited(_raffle,_raffleId);
    }

    function deleteRaffle(uint _raffleId) external onlyOwner {
        delete Raffles[_raffleId];
        emit RaffleDeleted(_raffleId);
    }

    function createRaffle (Raffle memory _raffle, bool _transferRewards) external  returns (uint) {
        if(!AdminList[msg.sender]) {
            revert Unauthorized();
        }
        if ((_raffle.raffledGoodsAmount == 0) || (_raffle.pricePerTicket == 0 ) || (_raffle.endDate < _raffle.startDate + 1 days ) || (_raffle.maxTicketAvailable == 0 ) || (_raffle.ticketsSold != 0 )){
            revert InvalidRaffle(); // TODO FIX DURATION
        }

        if (_raffle.raffleType != RaffleType.ERC1155 && _raffle.raffleType != RaffleType.ERC721 && _raffle.raffleType != RaffleType.WHITELIST && _raffle.raffleType != RaffleType.ERC1155BUNDLE ) {
            revert InvalidRaffle();
        }

        if (_raffle.raffleType == RaffleType.ERC721) {

            if ( _raffle.raffledCollectionERC721 == address(0) ||  _raffle.raffledGoodsAmount != 1 || _raffle.raffledCollectionERC1155 != address(0) ) {
                revert InvalidRaffle();
            }
        }

        else if (_raffle.raffleType == RaffleType.ERC1155) {

            if ( _raffle.raffledGoodERC1155 == 0 ||  _raffle.raffledCollectionERC721 != address(0) || _raffle.raffledCollectionERC1155 == address(0)) {
                revert InvalidRaffle();
            }
        }
        else if (_raffle.raffleType == RaffleType.ERC1155BUNDLE) {

            if ( _raffle.ERC1155BundleRewards.length == 0 || _raffle.raffledGoodERC1155 != 0 ||  _raffle.raffledCollectionERC721 != address(0) || _raffle.raffledCollectionERC1155 == address(0)) {
                revert InvalidRaffle();
            }
        }
        if(_transferRewards) {
            handleTransferRewards(_raffle);
        }
        uint raffleIdTemp = raffleId;
        Raffles[raffleId++] = _raffle;
        emit RaffleCreated(_raffle,raffleIdTemp);
        return raffleIdTemp; // TODO remove for prod, only for testing

    }

    function handleTransferRewards(Raffle memory _raffle) internal {
        if(_raffle.raffleType == RaffleType.ERC721) {
            IERC721(_raffle.raffledCollectionERC721).transferFrom(msg.sender,address(this), _raffle.tokenIdERC721);
        }
        else if(_raffle.raffleType == RaffleType.ERC1155) {
            if(_raffle.raffledCollectionERC1155 == address(OOPA_TRAITS)) {
                uint[] memory traitTypes = new uint[](1);
                traitTypes[0] = _raffle.raffledGoodERC1155;
                uint[] memory amounts = new uint[](1);
                amounts[0] = _raffle.raffledGoodsAmount;
                OOPA_TRAITS.batchMint(traitTypes,amounts,address(this));
            }
            else if(_raffle.raffledCollectionERC1155 == address(OOPA_GIFTBOX)) {
                OOPA_GIFTBOX.mintShoppingBag(_raffle.raffledGoodsAmount,address(this));
            }
            else {
            revert InvalidCollectionForRewardTransfer();
        }
        }
        else if(_raffle.raffleType == RaffleType.ERC1155BUNDLE) {
            if(_raffle.raffledCollectionERC1155 == address(OOPA_TRAITS)) {
                uint len = _raffle.ERC1155BundleRewards.length;
                uint bundleAmount = _raffle.raffledGoodsAmount;
                uint[] memory traitTypes = new uint[](len);
                uint[] memory amounts = new uint[](len);
                for (uint256 i = 0; i < len; i++) {
                    traitTypes[i] = _raffle.ERC1155BundleRewards[i];
                    amounts[i] = bundleAmount;
                }
                OOPA_TRAITS.batchMint(traitTypes,amounts,address(this));
            } 
            else {
                revert InvalidCollectionForRewardTransfer();
            }
        }
        else {
            revert InvalidCollectionForRewardTransfer();
        }
    }

    function emergencyWithdraw (IERC721 _collection, uint _tokenId ) external onlyOwner {
        _collection.transferFrom(address(this), msg.sender, _tokenId);
    }

    function joinRaffle(uint _raffleId, uint _ticketAmount) external {
        if(_ticketAmount < 1) {
            revert Unauthorized();
        }
        Raffle memory raffle = Raffles[_raffleId];
        if (raffle.endDate < block.timestamp || raffle.startDate > block.timestamp) {
            revert InvalidRaffle();
        }

        if (raffle.ticketsSold + _ticketAmount > raffle.maxTicketAvailable) {
            revert NotEnoughTickets();
        }

        raffle.ticketsSold += uint32(_ticketAmount);

        OOPA_CREDITS.adminSpendCredits(raffle.pricePerTicket*_ticketAmount, msg.sender);

        RaffleTickets[_raffleId].push(RaffleTicket(msg.sender, uint32(_ticketAmount), raffle.ticketsSold));

        Raffles[_raffleId] = raffle;

        emit TicketBought(_raffleId, _ticketAmount);

    }

    function finalizeRaffle(uint _raffleId) external {
        if(RaffleFinalizeRequestIssued[_raffleId] && !AdminList[msg.sender]) {
            revert InvalidRaffle();
        }
        else {
            RaffleFinalizeRequestIssued[_raffleId] = true;
        }

        if (Raffles[_raffleId].endDate > block.timestamp && (Raffles[_raffleId].maxTicketAvailable != Raffles[_raffleId].ticketsSold) ) {
            revert RaffleIsLive();
        }
        if(Raffles[_raffleId].ticketsSold == 0) {
            delete Raffles[_raffleId];
            emit RaffleDeleted(_raffleId);
            return;
        }
        
        rollDice(_raffleId);

    }
   

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint raffleID = PlayerRequest[requestId];
        Raffle memory raffle = Raffles[raffleID];
        // handles a very rare case of griefing where multiple finalizeRaffle calls are made before VRF request is served.
        if(raffle.endDate == 0) {
            revert InvalidRaffle();
        }
        uint ticketsSold = raffle.ticketsSold;
        uint amountOfGoods = raffle.raffledGoodsAmount;
        if (raffle.raffleType == RaffleType.ERC1155) {
            RaffleWinners[raffleID].raffledCollectionAddress =  raffle.raffledCollectionERC1155;
            RaffleWinners[raffleID].tokenIdERC721 = 0;
            RaffleWinners[raffleID].raffledGoodERC1155 = raffle.raffledGoodERC1155;
            RaffleWinners[raffleID].raffleType = RaffleType.ERC1155;
            RaffleWinners[raffleID].rewardsClaimed = 0;
            RaffleWinners[raffleID].totalRewardAmount = uint16(amountOfGoods);
            RaffleWinners[raffleID].ERC1155BundleRewards = raffle.ERC1155BundleRewards;
        }
        else if (raffle.raffleType == RaffleType.ERC721) {
            RaffleWinners[raffleID].raffledCollectionAddress =  raffle.raffledCollectionERC721;
            RaffleWinners[raffleID].tokenIdERC721 = raffle.tokenIdERC721;
            RaffleWinners[raffleID].raffledGoodERC1155 = 0;
            RaffleWinners[raffleID].raffleType = RaffleType.ERC721;
            RaffleWinners[raffleID].rewardsClaimed = 0;
            RaffleWinners[raffleID].totalRewardAmount = 1;
            RaffleWinners[raffleID].ERC1155BundleRewards = raffle.ERC1155BundleRewards;
        }
        else if (raffle.raffleType == RaffleType.ERC1155BUNDLE) {
            RaffleWinners[raffleID].raffledCollectionAddress =  raffle.raffledCollectionERC1155;
            RaffleWinners[raffleID].tokenIdERC721 = 0;
            RaffleWinners[raffleID].raffledGoodERC1155 = 0;
            RaffleWinners[raffleID].raffleType = RaffleType.ERC1155BUNDLE;
            RaffleWinners[raffleID].rewardsClaimed = 0;
            RaffleWinners[raffleID].totalRewardAmount = uint16(amountOfGoods);
            RaffleWinners[raffleID].ERC1155BundleRewards = raffle.ERC1155BundleRewards;

        }
        // for logging purposes only
        uint[] memory luckyNumbers = new uint[](raffle.raffledGoodsAmount);
        // we need this list for the graph and also for whitelists
        address[] memory winners = new address[](amountOfGoods);
        uint seed = (randomWords[0]);
        for (uint i; i < amountOfGoods; ) {

            uint randomNumber = (seed % ticketsSold);
            seed = uint(keccak256(abi.encodePacked(seed)));
            address winner = findWinner(RaffleTickets[raffleID], randomNumber);
            // we dont want to populate the winners mapping since there is no claim
            if(raffle.raffleType != RaffleType.WHITELIST) {
                RaffleWinners[raffleID].winners[winner]++;
            }
            luckyNumbers[i] = randomNumber;
            winners[i] = winner;
            unchecked {
                ++i;
            }
        }
        //TEST_RAFFLE_WINNER[raffleID] = winners; // TODO REMOVE AT PRODUCTION
        delete RaffleTickets[raffleID];
        delete Raffles[raffleID];
        delete PlayerRequest[requestId];
        
        emit RaffleFinalized(raffleID, winners,luckyNumbers);
    }

    function rollDice(uint _raffleId) internal {
        uint256 requestId =
            COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        PlayerRequest[requestId] = _raffleId;
    }

    function claimReward(uint _raffleId) external {
        uint amount = RaffleWinners[_raffleId].winners[msg.sender];
        // early revert if user cant claim
        if(amount == 0) { 
            revert NothingToClaim();
        }
        if (RaffleWinners[_raffleId].raffleType == RaffleType.ERC1155 ) { // ERC1155
            RaffleWinners[_raffleId].rewardsClaimed += uint16(amount);
            RaffleWinners[_raffleId].winners[msg.sender]-= amount;

            // create necessary structures for batch transfer
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amount;
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = RaffleWinners[_raffleId].raffledGoodERC1155;

            IERC1155(RaffleWinners[_raffleId].raffledCollectionAddress).safeBatchTransferFrom(address(this), msg.sender,tokenIds,amounts, "");
            
            emit RewardClaimed(_raffleId,amount);
            if(RaffleWinners[_raffleId].rewardsClaimed == RaffleWinners[_raffleId].totalRewardAmount) {
                delete RaffleWinners[_raffleId];
            }
        }
        else if (RaffleWinners[_raffleId].raffleType == RaffleType.ERC1155BUNDLE) { // ERC1155
            RaffleWinners[_raffleId].rewardsClaimed += uint16(amount);
            RaffleWinners[_raffleId].winners[msg.sender]-= amount;

            // create necessary structures for batch transfer 
            // e.g amounts = [2,2,2], traits = [1,10001,20003]
            uint256 rewardsLen = RaffleWinners[_raffleId].ERC1155BundleRewards.length;
            uint256[] memory amounts = new uint256[](rewardsLen);
            for (uint256 j = 0; j < rewardsLen; j++) {
                amounts[j] = amount; 
            }

            IERC1155(RaffleWinners[_raffleId].raffledCollectionAddress).safeBatchTransferFrom(address(this),msg.sender,RaffleWinners[_raffleId].ERC1155BundleRewards,amounts,"");
            
            emit RewardClaimed(_raffleId,amount);
            if(RaffleWinners[_raffleId].rewardsClaimed == RaffleWinners[_raffleId].totalRewardAmount) {
                delete RaffleWinners[_raffleId];
            }
    
        }
        else if (RaffleWinners[_raffleId].raffleType == RaffleType.ERC721) { // ERC721
            if(RaffleWinners[_raffleId].winners[msg.sender] == 1){
                address collection = RaffleWinners[_raffleId].raffledCollectionAddress;
                uint32 tokenId = RaffleWinners[_raffleId].tokenIdERC721;
                IERC721(collection).transferFrom(address(this), msg.sender, tokenId);
                delete RaffleWinners[_raffleId];
                emit RewardClaimed(_raffleId,1);
            }
            else {
                revert NothingToClaim();
            }
        }

    }

    function findWinner(RaffleTicket[] storage _raffleTickets, uint256 _element) internal view returns (address) {

        RaffleTicket[] storage tickets = _raffleTickets;
       
        uint256 low = 0;
        uint256 high = tickets.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            // Note that mid will always be strictly less than high (i.e. it will be a valid tickets index)
            // because Math.average rounds down (it does integer division with truncation).
            if (lowerIndex(tickets[mid]) > _element) {
                high = mid;
            } else if (higherIndex(tickets[mid]) < _element) {
                low = mid + 1;
            }
            else {
                low = mid;
                break;
            }
        }
        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (( higherIndex(tickets[low]) >= _element) &&  (lowerIndex(tickets[low]) <= _element)) {
            return tickets[low].participant;
        } else {
            return tickets[high].participant;
        }
    }

    function lowerIndex(RaffleTicket memory _tickets) internal pure returns(uint){
        return ( _tickets.ticketsIndexEnd - _tickets.ticketsBought);
    }

    function higherIndex(RaffleTicket memory _tickets) internal pure returns(uint){
        return  (_tickets.ticketsIndexEnd - 1);
    }

    function getRaffleTicketPrice(uint _raffleId) view external returns(uint) {
        return Raffles[_raffleId].pricePerTicket;
    }

    function getRaffleWinnerClaimableAmount(uint _raffleId, address winner) view external returns(uint) {
        return RaffleWinners[_raffleId].winners[winner];
    }

    function getRaffleWinners(uint _raffleId) view external returns(address[] memory) {
        return TEST_RAFFLE_WINNER[_raffleId];
    }

    function getRaffleTicketsSold(uint _raffleId) view external returns(uint) {
        return Raffles[_raffleId].ticketsSold;
    }

    function getRaffleERC1155BundleRewards(uint _raffleId) view external returns (uint[] memory) {
        return Raffles[_raffleId].ERC1155BundleRewards;
    }

    function isRaffleRewardsReady(uint _raffleId) view external returns (bool) {
        Raffle memory _raffle =  Raffles[_raffleId];
        if(_raffle.startDate == 0) {
            revert();
        }
        if(_raffle.raffleType == RaffleType.ERC721) {
            return (IERC721(_raffle.raffledCollectionERC721).ownerOf(_raffle.tokenIdERC721) == address(this));
        }
        else if(_raffle.raffleType == RaffleType.ERC1155) {
                uint erc1155TokenId = _raffle.raffledGoodERC1155;
                uint amount = _raffle.raffledGoodsAmount;
                return (IOOPATraits(_raffle.raffledCollectionERC1155).balanceOf(address(this),erc1155TokenId) >= amount); 
        }
        else if(_raffle.raffleType == RaffleType.ERC1155BUNDLE) {
                uint len = _raffle.ERC1155BundleRewards.length;
                uint amount = _raffle.raffledGoodsAmount;
                for (uint256 i = 0; i < len; i++) {
                    uint erc1155TokenId = _raffle.ERC1155BundleRewards[i];
                    if(IOOPATraits(_raffle.raffledCollectionERC1155).balanceOf(address(this),erc1155TokenId) < amount){
                        return false;
                    }
                }
                return true;
            }
        else {
            return false;
        }
    }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.17;

import "chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "chainlink/v0.8/VRFConsumerBaseV2.sol";

abstract contract VRFConsumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //address constant vrfCoordinatorFuji_ = 0x78a0D48cC87Ea0444e521475FCbE84A799090D75;
    // TODO REPLACE WITH THE ACTUAL FUJI COORDINATOR
    //address constant vrfCoordinatorFuji_ = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
    //address constant vrfCoordinatorAVAXMOCK = 0x82C5fA45Fc036c26C67d6c8FDb0e83c36dFc7aC9;
    address constant vrfCoordinatorAVAX = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //bytes32 constant keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61; // FUJI
    bytes32 constant keyHash = 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d; // AVAX

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant callbackGasLimit = 1200000;

    // The default is 3, but you can set this higher.
    uint16 constant requestConfirmations = 1;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant numWords = 1;

    event randomWordGenerated(uint256);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinatorAVAX) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorAVAX);
        s_subscriptionId = subscriptionId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}