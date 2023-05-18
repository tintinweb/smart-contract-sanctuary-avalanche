/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-17
*/

// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: Events.sol


pragma solidity ^0.8.0;


contract Factory {
    address immutable target = address(new Wallet());

    event CreateWallet(address indexed owner, uint256 nonce);

    function createWallet(address owner, uint256 nonce) external returns (address wallet) {
        wallet = Clones.cloneDeterministic(
            target,
            keccak256(abi.encodePacked(owner, nonce))
        );
        emit CreateWallet(owner, nonce);
    }
}

contract Wallet {
    event ExecTransaction(
        bytes32 indexed hash,
        uint256 gasUsed,
        bool success,
        bytes data
    );

    event Receive(address indexed sender, uint256 amount);

    function execTransaction(
        bytes32 hash,
        uint256 gasUsed,
        bool success,
        bytes calldata data
    ) external {
        emit ExecTransaction(hash, gasUsed, success, data);
    }

    function _receive(address sender, uint256 amount) external {
        emit Receive(sender, amount);
    }
}

contract SgReceiver {
    struct Transaction {
        address owner;
        address tokenIn;
        address tokenOut;
        address receiver;
        uint256 amountOutMin;
        bytes32 relayersRoot;
    }

    event Deposit(
        bytes32 indexed _hash,
        address indexed _owner,
        Transaction _transaction,
        uint256 _balance,
        uint256 _total
    );

    function deposit(
        bytes32 _hash,
        address _owner,
        Transaction calldata _transaction,
        uint256 _balance,
        uint256 _total
    ) external {
        emit Deposit(_hash, _owner, _transaction, _balance, _total);
    }
}

contract ERC20 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    function transfer(address _from, address _to, uint256 _amount) external {
        emit Transfer(_from, _to, _amount);
    }
}

contract ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    function transfer(address _from, address _to, uint256 _tokenId) external {
        emit Transfer(_from, _to, _tokenId);
    }
}

contract Deployer {
    event Deploy(string name, address _contract);
    
    constructor() {
        address owner = address(bytes20(keccak256("owner")));
        address sender = address(bytes20(keccak256("sender")));
        bytes32 hash = keccak256("urbHash");

        Factory factory = new Factory();
        Wallet wallet = Wallet(factory.createWallet(owner, 0));
        wallet._receive(sender, 123456789);
        wallet.execTransaction(hash, 12345, true, hex"badc0dee");

        SgReceiver receiver = new SgReceiver();
        hash = keccak256("sgHash");

        receiver.deposit(
            hash,
            owner,
            SgReceiver.Transaction(
                owner,
                address(bytes20(keccak256("tokenIn"))),
                address(bytes20(keccak256("tokenOut"))),
                address(bytes20(keccak256("destReceiver"))),
                0x1000000000,
                keccak256("relayersRoot")
            ),
            0x12345678,
            1
        );

        ERC20 erc20 = new ERC20();
        erc20.transfer(
            address(bytes20(keccak256("from1"))),
            address(wallet),
            0x1111111111
        );
        erc20.transfer(
            address(wallet),
            address(bytes20(keccak256("from2"))),
            0x111111
        );
        
        ERC721 erc721 = new ERC721();
        erc721.transfer(
            address(bytes20(keccak256("from3"))),
            address(wallet),
            0x1
        );
        erc721.transfer(
            address(wallet),
            address(bytes20(keccak256("from4"))),
            0x1
        );

        emit Deploy("factory", address(factory));
        emit Deploy("wallet", address(wallet));
        emit Deploy("receiver", address(receiver));
        emit Deploy("erc20", address(erc20));
        emit Deploy("erc721", address(erc721));
    }
}