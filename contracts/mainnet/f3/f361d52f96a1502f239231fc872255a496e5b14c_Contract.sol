/**
 *Submitted for verification at snowtrace.io on 2022-03-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
//slither-disable-next-line locked-ether
contract Market {
    using SafeTransferLib for address;

    address public owner;

    struct Listing {
        uint256 id;
        uint256 tokenId;
        uint256 price;
        address tokenAddress;
        address owner;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingsLength;

    mapping(address => bool) public validTokenAddresses;

    /*///////////////////////////////////////////////////////////////
                       MARKET MANAGEMENT SETTINGS
    //////////////////////////////////////////////////////////////*/

    uint256 public marketFee;
    bool public isMarketOpen;
    bool public emergencyDelisting;

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event AddListingEv(
        uint256 listingId,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event UpdateListingEv(uint256 listingId, uint256 price);
    event CancelListingEv(uint256 listingId);
    event FulfillListingEv(uint256 listingId);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/

    error Percentage0to100();
    error ClosedMarket();
    error InvalidListing();
    error InactiveListing();
    error InsufficientValue();
    error Unauthorized();
    error OnlyEmergency();
    error InvalidTokenAddress();

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _marketFee) {
        owner = msg.sender;
        marketFee = _marketFee;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = _newOwner;
        emit OwnerUpdated(_newOwner);
    }

    function addTokenAddress(address _tokenAddress) external onlyOwner {
        validTokenAddresses[_tokenAddress] = true;
    }

    function removeTokenAddress(address _tokenAddress) external onlyOwner {
        delete validTokenAddresses[_tokenAddress];
    }

    /*///////////////////////////////////////////////////////////////
                      MARKET MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function openMarket() external onlyOwner {
        if (emergencyDelisting) {
            delete emergencyDelisting;
        }
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        delete isMarketOpen;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function adjustFees(uint256 newMarketFee) external onlyOwner {
        marketFee = newMarketFee;
    }

    // If something goes wrong, we can close the market and enable emergencyDelisting
    //    After that, anyone can delist active listings
    //slither-disable-next-line calls-loop
    function emergencyDelist(uint256[] calldata listingIDs) external {
        if (!(emergencyDelisting && !isMarketOpen)) revert OnlyEmergency();

        uint256 len = listingIDs.length;
        //slither-disable-next-line uninitialized-local
        for (uint256 i; i < len; ) {
            uint256 id = listingIDs[i];
            Listing memory listing = listings[id];
            if (listing.active) {
                listings[id].active = false;
                ERC721(listing.tokenAddress).transferFrom(
                    address(this),
                    listing.owner,
                    listing.tokenId
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external onlyOwner {
        msg.sender.safeTransferETH(address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function addListing(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _price
    ) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (!validTokenAddresses[_tokenAddress]) revert InvalidTokenAddress();

        // overflow is unrealistic
        unchecked {
            uint256 id = listingsLength++;

            listings[id] = Listing(
                id,
                _tokenId,
                _price,
                _tokenAddress,
                msg.sender,
                true
            );

            emit AddListingEv(id, _tokenAddress, _tokenId, _price);

            ERC721(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        }
    }

    function updateListing(uint256 id, uint256 price) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (id >= listingsLength) revert InvalidListing();
        if (listings[id].owner != msg.sender) revert Unauthorized();

        listings[id].price = price;
        emit UpdateListingEv(id, price);
    }

    function cancelListing(uint256 id) external {
        if (id >= listingsLength) revert InvalidListing();

        Listing memory listing = listings[id];

        if (!listing.active) revert InactiveListing();
        if (listing.owner != msg.sender) revert Unauthorized();

        delete listings[id];

        emit CancelListingEv(id);

        ERC721(listing.tokenAddress).transferFrom(
            address(this),
            listing.owner,
            listing.tokenId
        );
    }

    function fulfillListing(uint256 id) external payable {
        if (!isMarketOpen) revert ClosedMarket();
        if (id >= listingsLength) revert InvalidListing();

        Listing memory listing = listings[id];

        if (!listing.active) revert InactiveListing();
        if (msg.value < listing.price) revert InsufficientValue();

        address listingOwner = listing.owner;
        if (msg.sender == listingOwner) revert Unauthorized();

        delete listings[id];

        emit FulfillListingEv(id);

        ERC721(listing.tokenAddress).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        listingOwner.safeTransferETH(
            listing.price - ((listing.price * marketFee) / 100)
        );
    }

    function getListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 numListings = listingsLength;
            if (from + length > numListings) {
                length = numListings - from;
            }

            Listing[] memory _listings = new Listing[](length);
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < length; ) {
                _listings[i] = listings[from + i];
                ++i;
            }
            return _listings;
        }
    }
}

contract Contract {

    address owner;
    address immutable market;

    mapping(address => uint256) partners;
    mapping(address => uint256) claimed;
    uint256 withdrawn;

    constructor() {
        owner = msg.sender;
        market = 0xbbF9287aFbf1CdBf9f7786E98fC6CEa73A78B6aB;

        partners[0xc899b9992397601c5e84FF238ac9DcA286B6dAc6] = 33333;
        partners[0x60A16f9349290BCfa6C660062a86bA0D953e9075] = 16666;
        partners[0x0e1E482af12f84fBcEA5806F61059CcDe3230813] = 16666;
        partners[0x181Ad17E5F1C50fFcf9805F7319bfA6E138Cf9b4] = 16666;
        partners[0xC2200981F04CE503EB980271980939Ce47FE4157] = 16666;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "");

        owner = newOwner;
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner, "");

        payable(msg.sender).transfer(address(this).balance);
    }

    function revoke() external {
        require(msg.sender == owner, "");

        Market(market).setOwner(msg.sender);
    }

    function change(address from, address to) public {
        require(from == msg.sender, "");

        claimed[to] = claimed[from];
        partners[to] = partners[from];

        delete partners[from];
        delete claimed[from];
    }

    function claimable(address partner) external view returns (uint256) {
        uint256 _withdrawn = withdrawn + market.balance;
        return (_withdrawn * partners[partner]) / 100000 -  claimed[partner];
    }

    function claim() external {
        withdrawn += market.balance;
        Market(market).withdraw();
        
        uint256 share = partners[msg.sender];

        uint256 amount = ((withdrawn * share) / 100000) -  claimed[msg.sender];

        claimed[msg.sender] += amount;

        payable(msg.sender).transfer(amount); 

    }

    function deposit() external payable {
        withdrawn += msg.value;
    }

    fallback() external payable {}

}