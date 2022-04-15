/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-15
*/

// File: contracts/NEIBRMembershipTypeLib.sol


pragma solidity ^0.8.0;

library NEIBRMembershipTypeLib {
    using NEIBRMembershipTypeLib for membershipTypes;

    struct membershipType {
        string name; 
        uint256 price; 
        uint dailyReward; 
       }

    struct membershipTypes {
        membershipType[] array;
    }

    event membershipTypeUpdated(
        uint256 indexed membershipTypeIndex,
        address indexed creator
    );

   
    function exists(membershipTypes storage self, uint256 _membershipTypeIndex)
        internal
        view
        returns (bool)
    {
        return _membershipTypeIndex < self.array.length;
    }

    function get(membershipTypes storage self, uint256 _membershipTypeIndex)
        internal
        view
        membershipTypeExists(self, _membershipTypeIndex)
        returns (membershipType storage)
    {
        return self.array[_membershipTypeIndex];
    }

    // Modfier to check if property exists or not
    modifier membershipTypeExists(
        membershipTypes storage self,
        uint256 _membershipTypeIndex
    ) {
        require(
            self.exists(_membershipTypeIndex),
            "NEIBRMembership: The Membership type doesn't exists."
        );
        _;
    }

    function length(membershipTypes storage self)
        internal
        view
        returns (uint256)
    {
        return self.array.length;
    }

    function nameExists(membershipTypes storage self, string memory _name)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < self.array.length; index++) {
            if (
                keccak256(abi.encodePacked(self.array[index].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return true;
            }
        }
        return false;
    }


    function create(
        membershipTypes storage self,
        string memory _name,
        uint256 _price,
        uint256 _dailyReward
    ) internal {
        // Check if name is avaialable.
        require(
            !self.nameExists(_name),
            "NEIBRMembership: Name already in use."
        );

        // Create furnitureCategory memory struct.
        membershipType memory _membershipType;
        _membershipType.name = _name;
        _membershipType.price = _price;
        _membershipType.dailyReward = _dailyReward;
        // Create new furniture category.
        self.array.push(_membershipType);

        emit membershipTypeUpdated(self.array.length - 1, msg.sender);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/membsership.sol


pragma solidity ^0.8.0;




contract NEIBRMembership is Ownable {
    using NEIBRMembershipTypeLib for NEIBRMembershipTypeLib.membershipTypes;

    address public neighbour;
    address private _signer;

    struct membership {
        uint256 boughtAt;
        uint256 lastRewardClaimed;
    }

    mapping(address => mapping(uint256 => membership)) public memberships;
    mapping(uint256 => bool) public membershipNonce;
    mapping(uint256 => bool) public rewardNonce;

    NEIBRMembershipTypeLib.membershipTypes membershipTypes;

    event MembershipStarted(
        address indexed user,
        uint256 indexed membershipType,
        uint256 time
    );

    event MembershipEnded(
        address indexed user,
        uint256 indexed membershipType,
        uint256 time
    );

    event RewardClaimed(
        address indexed user,
        uint256 indexed membershipType,
        uint256 amount,
        uint256 claimedTill,
        uint256 time
    );

    function setNeighbour(address _value) external onlyOwner {
        neighbour = _value;
    }

    function setSigner(address _value) external onlyOwner {
        _signer = _value;
    }

    function getSigner() external view onlyOwner returns (address) {
        return _signer;
    }

    function createMembershipType(
        string memory _name,
        uint256 _price,
        uint256 _dailyReward
    ) external onlyOwner {
        membershipTypes.create(_name, _price, _dailyReward);
    }

    function getMembershipType(uint256 _membershipTypeIndex)
        external
        view
        returns (NEIBRMembershipTypeLib.membershipType memory)
    {
        return membershipTypes.get(_membershipTypeIndex);
    }

    function getMembershipTypesLength() external view returns (uint256) {
        return membershipTypes.length();
    }

    function invalidateMemberships(
        address[] memory _users,
        uint256[] memory _membershipTypes
    ) external onlyOwner {
        require(
            _users.length == _membershipTypes.length,
            "NEIBRMembership: Length must be same for users and membershipTypeIndicies"
        );

        for (uint256 index = 0; index < _users.length; index++) {
            delete memberships[_users[index]][_membershipTypes[index]];
            emit MembershipEnded(
                _users[index],
                _membershipTypes[index],
                block.timestamp
            );
        }
    }

    function buyMembership(
        uint256 _membershipTypeIndex,
        uint256 _membershipNonce,
        bytes memory _signature
    ) external {
        require(
            memberships[msg.sender][_membershipTypeIndex].boughtAt == 0,
            "NEIBRMembership: Memership already exists"
        );

        require(
            !membershipNonce[_membershipNonce],
            "NEIBRMembership: Signature already used."
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                address(this),
                _membershipTypeIndex,
                _membershipNonce,
                msg.sender
            )
        );

        bytes32 signedMessageHash = getEthSignedMessageHash(messageHash);

        address signer_ = recoverSigner(signedMessageHash, _signature);

        require(_signer == signer_, "NEIBRMembership: Signature not verfied.");

        IERC20 _neighbour = IERC20(neighbour);

        require(
            _neighbour.allowance(msg.sender, address(this)) >=
                membershipTypes.get(_membershipTypeIndex).price,
            "NEIBRMembership: Insufficient NEIBR allowance"
        );

        _neighbour.transferFrom(
            msg.sender,
            address(this),
            membershipTypes.get(_membershipTypeIndex).price
        );

        memberships[msg.sender][_membershipTypeIndex].boughtAt = block
            .timestamp;
        memberships[msg.sender][_membershipTypeIndex].lastRewardClaimed =
            (block.timestamp / 1 days) *
            1 days;

        membershipNonce[_membershipNonce] = true;

        emit MembershipStarted(
            msg.sender,
            _membershipTypeIndex,
            block.timestamp
        );
    }

    function claim(
        uint256 _membershipTypeIndex,
        uint256 claimTill,
        uint256 _rewardNonce,
        bytes memory _signature
    ) external {
        require(
            memberships[msg.sender][_membershipTypeIndex].boughtAt != 0,
            "NEIBRMembership: Memership doesn't exists"
        );

        require(
            claimTill <= block.timestamp,
            "NEIBRMembership: Can't claim for future."
        );

        require(
            !rewardNonce[_rewardNonce],
            "NEIBRMembership: Signature already used."
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                address(this),
                _membershipTypeIndex,
                _rewardNonce,
                claimTill,
                msg.sender
            )
        );

        bytes32 signedMessageHash = getEthSignedMessageHash(messageHash);

        address signer_ = recoverSigner(signedMessageHash, _signature);

        require(_signer == signer_, "NEIBRMembership: Signature not verfied.");

        claimTill = (claimTill / 1 days) * 1 days;

        uint256 rewardDays = (claimTill -
            memberships[msg.sender][_membershipTypeIndex].lastRewardClaimed) /
            1 days;

        uint256 reward = rewardDays *
            membershipTypes.get(_membershipTypeIndex).dailyReward;

        IERC20(neighbour).transfer(msg.sender, reward);

        memberships[msg.sender][_membershipTypeIndex]
            .lastRewardClaimed = claimTill;

        rewardNonce[_rewardNonce] = true;

        emit RewardClaimed(
            msg.sender,
            _membershipTypeIndex,
            reward,
            claimTill,
            block.timestamp
        );
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    constructor() {
        string[7] memory names = [
            "Golden Citizenship",
            "Gold Drivers Licence",
            "Gold Boat Licence",
            "Gold Taxi Licence",
            "Gold Farming Permit",
            "Gold Business Permit",
            "Gold Construction Permit"
        ];

        uint256[7] memory prices = [
            uint256(1 ether),
            2 ether,
            2 ether,
            2 ether,
            2 ether,
            3 ether,
            3 ether
        ];

        uint256[7] memory dailyRewards = [
            uint256(0.03 ether),
            0.06 ether,
            0.06 ether,
            0.06 ether,
            0.06 ether,
            0.1 ether,
            0.1 ether
        ];

        for (uint256 index = 0; index < names.length; index++) {
            membershipTypes.create(
                names[index],
                prices[index],
                dailyRewards[index]
            );
        }
    }
}