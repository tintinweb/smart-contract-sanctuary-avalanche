// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC1238/extensions/ERC1238URIStorage.sol";

contract Badge is ERC1238, ERC1238URIStorage {
    address public owner;
    uint256 public holders;

    constructor(address owner_, string memory baseURI_) ERC1238(baseURI_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: sender is not the owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address for new owner");
        owner = newOwner;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setBaseURI(newBaseURI);
    }

    function mint(
        address to,
        string memory uri,
        bytes memory data
    ) external onlyOwner {
        _mintWithURI(to, uri, data);
        holders++;
    }

    function holdersLength() public view returns (uint256) {
        return holders;
    }

    function burn(address from, bool deleteURI) external onlyOwner {
        if (deleteURI) {
            _burnAndDeleteURI(from);
        } else {
            _burn(from);
        }
        holders--;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../ERC1238.sol";
import "./IERC1238URIStorage.sol";

/**
 * @dev Proposal for ERC1238 token with storage based token URI management.
 */
abstract contract ERC1238URIStorage is IERC1238URIStorage, ERC1238 {
    string private _tokenURI = "";

    /**
     * @dev See {IERC1238URIStorage-tokenURI}.
     */
    function tokenURI() public view virtual override returns (string memory) {
        // Returns the token URI if there is a specific one set that overrides the base URI
        if (_isTokenURISet()) {
            return _tokenURI;
        }

        string memory base = _baseURI();

        return base;
    }

    /**
     * @dev Sets `_tokenURI` as the token URI for the tokens of type `id`.
     *
     */
    function _setTokenURI(string memory _tURI) internal virtual {
        _tokenURI = _tURI;

        //emit URI(_tURI);
    }

    /**
     * @dev Deletes the tokenURI for the tokens of type `id`.
     *
     * Requirements:
     *  - A token URI must be set.
     *
     *  Possible improvement:
     *  - The URI can only be deleted if all tokens of type `id` have been burned.
     */
    function _deleteTokenURI() internal virtual {
        if (_isTokenURISet()) {
            delete _tokenURI;
        }
    }

    /**
     * @dev Returns whether a tokenURI is set or not for a specific `id` token type.
     *
     */
    function _isTokenURISet() private view returns (bool) {
        return bytes(_tokenURI).length > 0;
    }

    /**
     * @dev Creates `amount` tokens of token type `id` and URI `uri`, and assigns them to `to`.
     *
     * Emits a {MintSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1238Receiver-onERC1238Mint} and return the
     * acceptance magic value.
     */
    function _mintWithURI(
        address to,
        string memory uri,
        bytes memory data
    ) internal virtual {
        _mint(to, data);
        _setTokenURI(uri);
    }

    /**
     * @dev Destroys `amount` of tokens with id `id` owned by `from` and deletes the associated URI.
     *
     * Requirements:
     *  - A token URI must be set.
     *  - All tokens of this type must have been burned.
     */
    function _burnAndDeleteURI(address from) internal virtual {
        super._burn(from);

        _deleteTokenURI();
        // emit ?
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
contract ERC1238 is IERC1238 {
    using Address for address;

    mapping(address => bool) internal _balances;
    string private baseURI;

    /**
     * @dev Initializes the contract by setting a `baseURI`.
     * See {_setBaseURI}
     */
    constructor(string memory baseURI_) {
        _setBaseURI(baseURI_);
    }

    // TODO: Add support for ERC165
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    //     return
    //
    // }

    /**
     * @dev This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism as in EIP-1155:
     * https://eips.ethereum.org/EIPS/eip-1155#metadata
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC1238-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account) public view virtual override returns (bool) {
        require(account != address(0), "ERC1238: balance query for the zero address");
        return _balances[account];
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
    function _setBaseURI(string memory newBaseURI) internal virtual {
        baseURI = newBaseURI;
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
    function _mint(address to, bytes memory data) internal virtual {
        require(to != address(0), "ERC1238: mint to the zero address");

        address minter = msg.sender;

        _beforeMint(minter, to, data);

        // verify is _balances[to] is not already equals to true
        require(_balances[to] != true, "ERC1238: address already own the badge");
        _balances[to] = true;
        emit MintSingle(minter, to);

        _doSafeMintAcceptanceCheck(minter, to, data);
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
    function _burn(address from) internal virtual {
        require(from != address(0), "ERC1238: burn from the zero address");
        require(_balances[from] != true, "ERC1238: address doesnt own the badge");

        address burner = msg.sender;

        _beforeBurn(burner, from);

        _balances[from] = false;

        emit BurnSingle(burner, from);
    }

    /**
     * @dev Hook that is called before an `amount` of tokens are minted.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeMint(
        address minter,
        address to,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called before an `amount` of tokens are burned.
     *
     * Calling conditions:
     * - `minter` and `to` cannot be the zero address
     *
     */
    function _beforeBurn(address burner, address from) internal virtual {}

    function _doSafeMintAcceptanceCheck(
        address minter,
        address to,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1238Receiver(to).onERC1238Mint(minter, data) returns (bytes4 response) {
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

import "../IERC1238.sol";

/**
 * @dev Proposal of an interface for ERC1238 token with storage based token URI management.
 */
interface IERC1238URIStorage is IERC1238 {
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     */
    event URI(uint256 indexed id, string value);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `id` token.
     */
    function tokenURI() external view returns (string memory);
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

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account) external view returns (bool);
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
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1238Mint(address,uint256,uint256,bytes)"))` if minting is allowed
     */
    function onERC1238Mint(address minter, bytes calldata data) external returns (bytes4);

    /**
     * @dev Handles the receipt of multiple ERC1238 token types.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1238BatchMint(address,address,uint256[],uint256[],bytes)"))`
     *
     * @param minter The address which initiated minting (i.e. msg.sender)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1238BatchMint(address,uint256[],uint256[],bytes)"))` if minting is allowed
     */
    function onERC1238BatchMint(address minter, bytes calldata data) external returns (bytes4);
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