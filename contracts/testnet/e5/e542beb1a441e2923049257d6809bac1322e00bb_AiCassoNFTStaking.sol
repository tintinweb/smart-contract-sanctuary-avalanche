/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC721Receiver is IERC721Receiver, IERC165 {
    bytes4 private constant _ERC165_INTERFACE_ID = type(IERC165).interfaceId;
    bytes4 private constant _ERC721_RECEIVER_INTERFACE_ID = type(IERC721Receiver).interfaceId;

    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;
    bytes4 internal constant _ERC721_REJECTED = 0xffffffff;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _ERC165_INTERFACE_ID || interfaceId == _ERC721_RECEIVER_INTERFACE_ID;
    }
}

interface IAiCassoNFTStaking {
    function balanceOf(address _user) external view returns (uint256);
}

contract AiCassoNFTStaking is IAiCassoNFTStaking, Ownable, ERC721Receiver {
    using Strings for uint256;

    struct Staker {
        uint256[] tokenIds;
        uint256 stakerIndex;
        uint256 balance;
        uint256 lastRewardCalculate;
        uint256 rewardCalculated;
        uint256 rewardWithdrawed;
    }

    struct Reward {
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 perMinute;
    }

    struct Withdraw {
        uint256 date;
        uint256 amount;
    }

    mapping (address => Staker) public stakers;
    mapping (uint256 => Reward) public rewards;
    mapping (uint256 => Withdraw) public withdraws;
    address[] public stakersList;

    uint256 public stakedCount;
    uint256 public rewardsCount;
    uint256 public withdrawsCount;
    uint256 private recoveryIndex;

    address public AiCassoNFT;

    modifier onlyParent() {
        require(AiCassoNFT == msg.sender);
        _;
    }

    constructor() {
        recoveryStake(0x03c3a50132Ade4600Eb522927e6bc038833251Ef, 1, 9141480973331254);
        recoveryStake(0xa84546e35B27933F83596838EE958615B7062196, 1, 9141480973331254);
        recoveryStake(0x1EFd12b8e01337CCd4839f9580Fc685C202f1702, 1, 9153246071109028);
        recoveryStake(0x4C293D1F0bbb8fB6762f325D250B3582cd0EdAd0, 1, 9153246071109028);
        recoveryStake(0x29713dec3F1d7f9BE176F15d7d10bEa91F18EBe5, 1, 9153246071109028);
        recoveryStake(0x0E5e74B274cbf68dECaaec85240805D35C9361DF, 7, 64168068811003933);
        recoveryStake(0x925e716073e15905218264e66Da4Db1147D10a8c, 2, 18306492142218060);
        recoveryStake(0x91B85C0aD32f7711fF142771896126ca91Ce522a, 1, 9153246071109028);
        recoveryStake(0xf3F291A19A6d5674241757a9EABd2784e4a085e8, 3, 27459738213327090);
        recoveryStake(0xD515b88473D9310e63eD6a201Ca79D45E2803536, 1, 9153246071109028);
        recoveryStake(0xe08707eAe41b7a8213175Af061254eE8154A8Fbc, 1, 9153246071109028);
        recoveryStake(0x9d48176B453d58d163baf8C9B9F884A4AB64B55f, 1, 9153246071109028);
        recoveryStake(0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D, 19, 174150041134173382);
        recoveryStake(0x648213045D8c2c373cc40F73E13c67C8e0Ff81Bc, 1, 9153246071109028);
        recoveryStake(0x249D7449338b3f6719Eb46c4A4Bc3362b68d5a9b, 1, 9153246071109028);
        recoveryStake(0xebd746FEF9952aeC908DF471b65aCE4E05210ADB, 2, 18306492142218060);
        recoveryStake(0x90b26Ce42D4735e927E3ADfaaF70522DeC0bc0fC, 1, 9153246071109028);
        recoveryStake(0x10c90204F4815bDd50B401AEC1B56fc48b67F31B, 1, 9153246071109028);
        recoveryStake(0x9010995cC801d8897e969ADB7e3C86b30bf70353, 4, 36660657441056481);
        recoveryStake(0x01eE6d1869aD3cf4EBe6fE651B7F2c966bF4bFE3, 1, 9153246071109028);
        recoveryStake(0x1F9182c496DE27a5081713A4F431045ECd539108, 1, 9153246071109028);
    }

    function deposit() public onlyOwner payable {
        addReward(msg.value);
    }

    function setContractNFT(address aicassoContract) public onlyOwner {
        require(AiCassoNFT == address(0));
        AiCassoNFT = aicassoContract;
    }

    function withdrawForOwner(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Insufficient funds');
        payable(msg.sender).transfer(amount);
    }

    function withdraw() public {
        updateReward(msg.sender);

    unchecked {
        Staker storage _staker = stakers[msg.sender];
        Withdraw storage _withdraw = withdraws[withdrawsCount];

        uint256 toWithdraw = _staker.rewardCalculated - _staker.rewardWithdrawed;
        uint256 balance = address(this).balance;

        require(balance >= toWithdraw, 'The function is not available at the moment, try again later');
        _staker.rewardWithdrawed += toWithdraw;

        withdrawsCount += 1;
        _withdraw.date = block.timestamp;
        _withdraw.amount = toWithdraw;

        payable(msg.sender).transfer(toWithdraw);
    }
    }


    function recoveryStake(address client, uint256 count, uint256 reReward) private {
        Staker storage _staker = stakers[client];
    unchecked {
        for (uint256 i = 0; i < count; i++) {
            if (_staker.balance == 0 && _staker.lastRewardCalculate == 0) {
                _staker.lastRewardCalculate = block.timestamp;
                _staker.stakerIndex = stakersList.length;
                _staker.rewardCalculated = reReward;
                stakersList.push(client);
            }

            _staker.balance += 1;
            recoveryIndex += 1;
            _staker.tokenIds.push(recoveryIndex);

            stakedCount += 1;
        }
    }
    }

    function stake(uint256[] calldata tokens) public virtual {
        require(IERC721(AiCassoNFT).isApprovedForAll(msg.sender, address(this)));

        updateRewardAll();

    unchecked {
        Staker storage _staker = stakers[msg.sender];

        for (uint256 i = 0; i < tokens.length; i++) {
            require(IERC721(AiCassoNFT).ownerOf(tokens[i]) == msg.sender);

            if (_staker.balance == 0 && _staker.lastRewardCalculate == 0) {
                _staker.lastRewardCalculate = block.timestamp;
                _staker.stakerIndex = stakersList.length;
                stakersList.push(msg.sender);
            }

            _staker.balance += 1;
            _staker.tokenIds.push(tokens[i]);

            stakedCount += 1;

            IERC721(AiCassoNFT).transferFrom(
                msg.sender,
                address(this),
                tokens[i]
            );
        }
    }
    }

    function unstake(uint256 numberOfTokens) public {
    unchecked {
        Staker storage _staker = stakers[msg.sender];

        require(_staker.balance >= numberOfTokens);

        updateReward(msg.sender);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _staker.balance -= 1;

            uint256 lastIndex = _staker.tokenIds.length - 1;
            uint256 lastIndexKey = _staker.tokenIds[lastIndex];
            _staker.tokenIds.pop();

            stakedCount -= 1;

            IERC721(AiCassoNFT).transferFrom(
                address(this),
                msg.sender,
                lastIndexKey
            );
        }
    }
    }

    function addReward(uint256 amount) private {
    unchecked {
        Reward storage _reward = rewards[rewardsCount];
        rewardsCount += 1;
        _reward.start = block.timestamp;
        _reward.end = block.timestamp + 30 days;
        _reward.amount = amount;
        _reward.perMinute = amount / 30 days * 60;
    }
    }

    function updateRewardAll() private {
        for (uint256 i = 0; i < stakersList.length; i++) {
            updateReward(stakersList[i]);
        }
    }

    function updateReward(address _user) private {
    unchecked {
        Staker storage _staker = stakers[_user];
        uint256 _rewardCalculated = _getReward(_user);
        _staker.lastRewardCalculate = block.timestamp;
        _staker.rewardCalculated += _rewardCalculated;
    }
    }

    function _getReward(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        if (_staker.balance > 0) {
            uint256 rewardCalculated = 0;

        unchecked {
            for (uint256 i = 0; i < rewardsCount; i++) {
                Reward storage _reward = rewards[i];
                if (_reward.end > _staker.lastRewardCalculate) {
                    uint256 startCalculate = _staker.lastRewardCalculate;
                    if (_reward.start > _staker.lastRewardCalculate) {
                        startCalculate = _reward.start;
                    }

                    uint256 minutesReward = (block.timestamp - startCalculate) / 60;
                    uint256 totalReward = minutesReward * _reward.perMinute;
                    uint256 userReward = ((_staker.balance * 10_000 / stakedCount) * totalReward) / 10_000;

                    rewardCalculated += userReward;
                }
            }
        }

            return rewardCalculated;
        }

        return 0;
    }

    function totalStaked() public view returns (uint256) {
        return stakedCount;
    }

    function totalLastWeekWithdraws() public view returns (uint256) {
        uint256 weekStart = block.timestamp - 7 days;
        uint256 total = 0;

        for (uint256 i = 0; i < withdrawsCount; i++) {
            Withdraw storage _withdraw = withdraws[i];
            if (_withdraw.date >= weekStart) {
                total += _withdraw.amount;
            }
        }
        return total;
    }

    function totalRewardOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _getReward(_user) + _staker.rewardCalculated;
    }

    function percentOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        if (_staker.balance > 0) {
            return (_staker.balance * 10000 / stakedCount) / 100;
        }
        return 0;
    }

    function balanceOf(address _user) public view override returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _staker.balance;
    }

    function rewardOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _getReward(_user) + _staker.rewardCalculated - _staker.rewardWithdrawed;
    }

    event Received();

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
    external
    override
    returns(bytes4)
    {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }
}