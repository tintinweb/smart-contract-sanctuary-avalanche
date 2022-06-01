/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-31
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

// Fly 0x6136dc5c7898fad266224b6e4bcc10d5ef79ec59
// KOTH 0x42e875caa1ed80b9c060c4b3ba59a8e7da4ca481

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

contract Fly is ERC20 {
    address public owner;

    // whitelist for minting mechanisms
    mapping(address => bool) public zones;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);

    constructor(string memory _NAME, string memory _SYMBOL)
        ERC20(_NAME, _SYMBOL, 18)
    {
        owner = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                            Zones - can mint
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            zones[_zones[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(address zone) external onlyOwner {
        delete zones[zone];
    }

    /*///////////////////////////////////////////////////////////////
                                MINT / BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address receiver, uint256 amount) external onlyZone {
        _mint(receiver, amount);
    }

    function burn(address from, uint256 amount) external onlyZone {
        _burn(from, amount);
    }
}

contract KOTH {
    address public immutable FLY;
    uint256 public immutable period = 5 minutes;
    uint256 public immutable step = 3; // 30 percent
    uint256 public immutable reward = 1; // 10 percent
    uint256 public enterAmount = 100 ether;
    uint256 public startTs = 0;
    uint256 public cycle = 0;
    address public owner;
    Winner currentWinner;

    struct Winner {
        address adr;
        uint256 flies;
    }

    // Mappings
    mapping(uint256 => Winner) public historicalWinners;

    // Events
    event UpdatedOwner(address indexed owner);
    event WinnerChanged(Winner winner);
    event CycleFinished(uint256 cycle, Winner winner);

    // Errors
    error Unauthorized();
    error NotStarted();
    error AlreadyStarted();

    constructor(address fly) {
        owner = msg.sender;
        FLY = fly;
    }

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    // Management methods
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setEnterAmount(uint256 amount) external onlyOwner {
        enterAmount = amount;
    }

    // Methods
    function isStarted() external view returns (bool) {
        unchecked {
            return (startTs + period) > block.timestamp;
        }
    }

    function _isStarted() private view returns (bool) {
        unchecked {
            return (startTs + period) > block.timestamp;
        }
    }

    function start() external {
        if (_isStarted()) {
            revert AlreadyStarted();
        }
        if (currentWinner.flies > 0) {
            unchecked {
                historicalWinners[cycle] = currentWinner;
            }
            emit CycleFinished(cycle, currentWinner);
        }
        currentWinner = Winner({
            adr: address(0),
            flies: 0
        });
        unchecked {
            cycle++;
        }
        startTs = block.timestamp;
    }

    function getEnterAmount() public view returns (uint256) {
        if (!_isStarted()) {
            revert NotStarted();
        }
        if (currentWinner.flies == 0) {
            return enterAmount;
        }
        unchecked {
            return currentWinner.flies + ((currentWinner.flies * step) / 10);
        }
    }

    function enter() public {
        if (!_isStarted()) {
            revert NotStarted();
        }
        uint256 amount = getEnterAmount();
        uint256 burnAmount = amount;
        Fly fly = Fly(FLY);
        if (currentWinner.flies > 0) {
            // We have a winner
            unchecked {
                uint256 rewardAmount = currentWinner.flies + ((currentWinner.flies * reward) / 10);
                fly.transferFrom(msg.sender, currentWinner.adr, rewardAmount);
                burnAmount = amount - rewardAmount;
            }
        }
        fly.burn(msg.sender, burnAmount);
        currentWinner.adr = msg.sender;
        currentWinner.flies = amount;
        emit WinnerChanged(currentWinner);
    }
}