// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./interfaces/IDexV1ERC20.sol";

contract DexV1ERC20 is IDexV1ERC20 {
    string public constant name = "DEX V1";
    string public constant symbol = "BRX V1";
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    address owner_;
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() {
        uint chainId;

        owner_ = msg.sender;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function mints(uint256 value) public {
        require(msg.sender == owner_, "Not Owner");
        _mint(msg.sender, value);
    }

    function _mint(address to, uint value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer1(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply -= value;
        emit Transfer1(from, address(0), value);
    }

    function _approve1(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval1(owner, spender, value);
    }

    function _transfer1(address from, address to, uint value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer1(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        require(value > 0, "Minimum 1");
        _approve1(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer1(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external virtual returns (bool) {
        require(value > 0, "Minimum 1");
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }
        _transfer1(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "DexV1: INVALID_SIGNATURE"
        );
        _approve1(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IDexV1ERC20 {
    event Approval1(address indexed owner, address indexed spender, uint value);
    event Transfer1(address indexed from, address indexed to, uint value);

    function mints(uint256 value) external;

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}