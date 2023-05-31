// SPDX-License-Identifier: MIT

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;

    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    error WETH_ETHTransferFailed();
    error WETH_InvalidSignature();
    error WETH_ExpiredSignature();
    error WETH_InvalidTransferRecipient();

    // ERC20
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address guy) external view returns (uint);

    function allowance(address src, address dst) external view returns (uint);

    function approve(address spender, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

    event Approval(address indexed src, address indexed dst, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    // ERC-165
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    // ERC-2612
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function nonces(address owner) external view returns (uint);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // Permit2
    function permit2(address owner, address spender, uint amount, uint deadline, bytes calldata signature) external;
}

contract WETH is IWETH {
    string public constant override name = "Wrapped Ether";
    string public constant override symbol = "WETH";
    uint8 public override decimals = 18;

    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 private constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9; // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes4 private constant MAGICVALUE = 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    mapping(address => uint) public override nonces;

    uint private immutable INITIAL_CHAIN_ID;
    bytes32 private immutable INITIAL_DOMAIN_SEPARATOR;

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    receive() external payable {
        deposit();
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // ERC-165
            interfaceID == this.permit.selector || // ERC-2612
            interfaceID == this.permit2.selector; // Permit2
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    // keccak256(bytes('Wrapped Ether')),
                    0x00cd3d46df44f2cbb950cf84eb2e92aa2ddd23195b1a009173ea59a063357ed3,
                    // keccak256(bytes("1"))
                    0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
                    block.chainid,
                    address(this)
                )
            );
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint value) external override {
        balanceOf[msg.sender] -= value;
        (bool success, ) = msg.sender.call{value: value}("");
        if (!success) {
            revert WETH_ETHTransferFailed();
        }
        emit Withdrawal(msg.sender, value);
    }

    function totalSupply() external view override returns (uint) {
        return address(this).balance;
    }

    function approve(address spender, uint value) external override returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    modifier ensuresRecipient(address to) {
        // Prevents from burning or sending WETH tokens to the contract.
        if (to == address(0)) {
            revert WETH_InvalidTransferRecipient();
        }
        if (to == address(this)) {
            revert WETH_InvalidTransferRecipient();
        }
        _;
    }

    function transfer(address to, uint value) external override ensuresRecipient(to) returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override ensuresRecipient(to) returns (bool) {
        if (from != msg.sender) {
            uint _allowance = allowance[from][msg.sender];
            if (_allowance != type(uint).max) {
                allowance[from][msg.sender] -= value;
            }
        }

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
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
    ) external override {
        if (block.timestamp > deadline) {
            revert WETH_ExpiredSignature();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress != owner) {
            revert WETH_InvalidSignature();
        }
        if (recoveredAddress == address(0)) {
            revert WETH_InvalidSignature();
        }
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function permit2(
        address owner,
        address spender,
        uint value,
        uint deadline,
        bytes calldata signature
    ) external override {
        if (block.timestamp > deadline) {
            revert WETH_ExpiredSignature();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        if (!_checkSignature(owner, digest, signature)) {
            revert WETH_InvalidSignature();
        }
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _checkSignature(address signer, bytes32 hash, bytes memory signature) private view returns (bool) {
        address recoveredAddress = _recover(hash, signature);
        if (recoveredAddress == signer) {
            if (recoveredAddress != address(0)) {
                return true;
            }
        }

        (bool success, bytes memory result) = signer.staticcall(abi.encodeWithSelector(MAGICVALUE, hash, signature));
        return (success && result.length == 32 && abi.decode(result, (bytes32)) == bytes32(MAGICVALUE));
    }

    function _recover(bytes32 hash, bytes memory signature) private pure returns (address) {
        if (signature.length != 65) {
            return address(0);
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (uint(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        return ecrecover(hash, v, r, s);
    }
}