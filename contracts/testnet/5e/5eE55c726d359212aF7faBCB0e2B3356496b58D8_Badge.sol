// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC1238/ERC1238.sol";

contract Badge is ERC1238 {
    address public owner;

    constructor(address owner_, string memory baseURI_) ERC1238(baseURI_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: sender is not the owner");
        _;
    }

    // function setOwner(address newOwner) external onlyOwner {
    //     require(newOwner != address(0), "Invalid address for new owner");
    //     owner = newOwner;
    // }

    function mint(
        address to,
        string memory role,
        uint256 expirationDate
    ) external onlyOwner {
        if (!_compare(role, "admin") || !_compare(role, "user")) {
            revert("Invalid role");
        }

        if (expirationDate < block.timestamp) {
            revert("Expiration date mus be in the future");
        }

        _mint(to, role, expirationDate);
    }

    function burn(address from) external onlyOwner {
        _burn(from);
    }

    function _compare(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC1238.sol";
import "./IERC1238Receiver.sol";
import "../utils/AddressMinimal.sol";

/**
 * @dev Implementation proposal for non-transferable (Badge) tokens
 * See https://github.com/ethereum/EIPs/issues/1238
 */
abstract contract ERC1238 is IERC1238 {
    using Address for address;

    struct Owner {
        bool isOwner;
        string role;
        uint256 expirationDate;
    }
    mapping(address => Owner) internal _owners;
    uint256 private _ownersLength = 0;
    string public name;

    /**
     * @dev Initializes the contract by setting a `name`.
     * See {_setName}
     */
    constructor(string memory name_) {
        _setName(name_);
    }

    // TODO: Add support for ERC165
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    //     return
    //
    // }

    function isValid(address _owner) internal view returns (bool) {
        Owner memory owner = _owners[_owner];
        return owner.expirationDate < block.timestamp;
    }

    function allOwnersLength() external view virtual returns (uint256) {
        return _ownersLength;
    }

    modifier userExist(address user) {
        require(_owners[user].isOwner, "User does not exist");
        _;
    }

    function getOwner(address user) external view virtual userExist(user) returns (string memory, uint256) {
        Owner memory owner = _owners[user];
        return (owner.role, owner.expirationDate);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism as in EIP-1155
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setName(string memory newName) internal virtual {
        name = newName;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {MintSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1238Receiver-onERC1238Mint} and return the
     * acceptance magic value.
     *
     * Emits a {MintSingle} event.
     */
    function _mint(
        address to,
        string memory role,
        uint256 expirationDate
    ) internal virtual {
        require(to != address(0), "ERC1238: mint to the zero address");

        address minter = msg.sender;

        _beforeMint(minter, to);

        require(_owners[to].isOwner == false, "ERC1238: address already own the badge");
        _owners[to].isOwner = true;
        _owners[to].role = role;
        _owners[to].expirationDate = expirationDate;
        _ownersLength++;

        emit MintSingle(minter, to);
        _doSafeMintAcceptanceCheck(minter, to);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     *
     * Emits a {BurnSingle} event.
     */
    function _burn(address from) internal virtual userExist(from) {
        require(from != address(0), "ERC1238: burn from the zero address");

        address burner = msg.sender;
        _beforeBurn(burner, from);
        delete _owners[from];
        _ownersLength--;
        emit BurnSingle(burner, from);
    }

    /**
     * @dev Hook that is called before an `amount` of tokens are minted.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeMint(address minter, address to) internal virtual {}

    /**
     * @dev Hook that is called before an `amount` of tokens are burned.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeBurn(address burner, address from) internal virtual {}

    function _doSafeMintAcceptanceCheck(address minter, address to) private {
        if (to.isContract()) {
            try IERC1238Receiver(to).onERC1238Mint(minter) returns (bytes4 response) {
                if (response != IERC1238Receiver.onERC1238Mint.selector) {
                    revert("ERC1238: ERC1238Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1238: transfer to non ERC1238Receiver implementer");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface proposal for Badge tokens
 * See https://github.com/ethereum/EIPs/issues/1238
 */
interface IERC1238 {
    /**
     * @dev Emitted when `amount` tokens of token type `id` are minted to `to` by `minter`.
     */
    event MintSingle(address indexed minter, address indexed to);

    /**
     * @dev Emitted when `amount` tokens of token type `id` owned by `owner` are burned by `burner`.
     */
    event BurnSingle(address indexed burner, address indexed owner);

    function allOwnersLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 *
 */
interface IERC1238Receiver {
    /**
     * @dev Handles the receipt of a single ERC1238 token type.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1238Mint(address,address,uint256,uint256,bytes)"))`
     *
     * @param minter The address which initiated minting (i.e. msg.sender)
     * @return `bytes4(keccak256("onERC1238Mint(address,uint256,uint256,bytes)"))` if minting is allowed
     */
    function onERC1238Mint(address minter) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        return account.code.length > 0;
    }
}