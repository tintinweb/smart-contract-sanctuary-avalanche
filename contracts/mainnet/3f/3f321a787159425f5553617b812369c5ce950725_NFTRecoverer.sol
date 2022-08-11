/**
 *Submitted for verification at snowtrace.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IMulticall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) external returns (uint256 blockNumber, bytes[] memory returnData);
}

interface IERC721Minimal {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract NFTRecoverer is Ownable, IERC721Receiver {
    /* Structure */

    struct NFT {
        address nftAddress;
        uint96 tokenId;
    }

    /* Events */

    event ERC721Claimed(address indexed sender, address indexed user, address indexed nft, uint256 tokenId);
    event PauseSet(bool indexed state);
    event BlacklistSet(address indexed user, bool indexed state);

    /* Variables */

    bool public claimPaused;

    IMulticall private immutable _multicall;
    mapping(address => NFT[]) private _recoveredNFTs;
    mapping(address => bool) private _blacklist;

    /* Modifier */

    modifier notPaused() {
        require(!claimPaused, "Claim is not allowed");
        _;
    }

    constructor(IMulticall multicall_) {
        claimPaused = true;
        _multicall = multicall_;

        emit PauseSet(true);
    }

    /* User function */

    function batchClaim(uint256 _nb) external notPaused {
        require(!_blacklist[msg.sender], "Not allowed");

        uint256 _max = numberOfUnclaimedRecoveredNft(msg.sender);
        _nb = _nb > _max ? _max : _nb;

        require(_nb > 0, "No NFT to claim");

        for (uint256 i; i < _nb; ++i) {
            NFT memory _nft = _recoveredNFTs[msg.sender][--_max];
            _recoveredNFTs[msg.sender].pop();

            require(
                !IERC721Minimal(_nft.nftAddress).isApprovedForAll(msg.sender, address(_multicall)),
                "First revoke multicall contract"
            );

            IERC721Minimal(_nft.nftAddress).safeTransferFrom(address(this), msg.sender, _nft.tokenId);
            emit ERC721Claimed(msg.sender, msg.sender, _nft.nftAddress, _nft.tokenId);
        }
    }

    /* Owner functions */

    function whitehatNFTs(
        address[] calldata _nfts,
        address[] calldata _owners,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        uint256 _len = _nfts.length;
        require(_owners.length == _len && _tokenIds.length == _len, "bad length");
        IMulticall.Call[] memory _calls = new IMulticall.Call[](_len);

        unchecked {
            for (uint256 i; i < _len; ++i) {
                _recoveredNFTs[_owners[i]].push(NFT({nftAddress: _nfts[i], tokenId: toUint96(_tokenIds[i])}));

                _calls[i] = IMulticall.Call({
                    target: _nfts[i],
                    callData: abi.encodeWithSelector(
                        IERC721Minimal.safeTransferFrom.selector,
                        _owners[i],
                        address(this),
                        _tokenIds[i]
                    )
                });
            }
        }
        _multicall.aggregate(_calls);
    }

    function pauseSet(bool _state) external onlyOwner {
        require(claimPaused != _state, "claim is in the same state");

        claimPaused = _state;
        emit PauseSet(_state);
    }

    function blacklistSet(address _user, bool _state) external onlyOwner {
        _blacklist[_user] = _state;
        emit BlacklistSet(_user, _state);
    }

    function batchClaimFor(address _user, uint256 _nb) external onlyOwner {
        uint256 _max = numberOfUnclaimedRecoveredNft(_user);
        _nb = _nb > numberOfUnclaimedRecoveredNft(_user) ? _max : _nb;

        for (uint256 i; i < _nb; ++i) {
            NFT memory _nft = _recoveredNFTs[_user][--_max];
            _recoveredNFTs[_user].pop();

            require(
                !IERC721Minimal(_nft.nftAddress).isApprovedForAll(_user, address(_multicall)),
                "First revoke multicall contract"
            );

            IERC721Minimal(_nft.nftAddress).safeTransferFrom(address(this), _user, _nft.tokenId);
            emit ERC721Claimed(msg.sender, _user, _nft.nftAddress, _nft.tokenId);
        }
    }

    // carefull here
    function delegatecall(address _target, bytes calldata _data) external payable onlyOwner {
        (bool _success, ) = _target.delegatecall(_data);
        require(_success, "Delegatecall failed");
    }

    /* View functions */

    function getUnclaimedRecoveredNft(address _owner, uint256 _index) external view returns (NFT memory) {
        return _recoveredNFTs[_owner][_index];
    }

    function numberOfUnclaimedRecoveredNft(address _owner) public view returns (uint256) {
        return _recoveredNFTs[_owner].length;
    }

    /* Callbacks functions */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /* Internal functions */

    function toUint96(uint256 x) internal pure returns (uint96) {
        require(x < type(uint96).max, "uint96 overflow");
        return uint96(x);
    }
}