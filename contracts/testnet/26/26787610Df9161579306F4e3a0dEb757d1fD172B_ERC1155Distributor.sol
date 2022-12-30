// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./ResourceDistributor.sol";

contract ERC1155Distributor is ResourceDistributor, ERC1155Receiver {
    IERC1155 public token;
    uint256 public tokenId;
    uint256 public expirationBlocks;
    bool public hasDeposited;

    constructor(
        address _tokenContract,
        uint256 _tokenId,
        uint16 _maxDemandVolume,
        uint256 _epochCapacity,
        uint256 _epochDuration,
        uint16 _etherMultiplier,
        uint256 _expirationBlocks,
        bool _enableWithdraw
    )
        ResourceDistributor(
            _maxDemandVolume,
            _epochCapacity,
            _epochDuration,
            _etherMultiplier,
            _expirationBlocks,
            _enableWithdraw
        )
    {
        token = IERC1155(_tokenContract);
        tokenId = _tokenId;
        expirationBlocks = _expirationBlocks;
        hasDeposited = false;
        etherMultiplier = 1000; // disable ether multiplier
    }

    modifier depositCompleted() {
        require(
            hasDeposited,
            "Token deposit is not done, the contract is not active."
        );
        _;
    }

    function deposit(uint256 _amount) public virtual override onlyOwner {
        require(!hasDeposited, "Token deposit is already done.");
        require(
            _amount >= epochCapacity,
            "The contract must be funded with at least one epoch capacity."
        );

        token.safeTransferFrom(msg.sender, address(this), tokenId, _amount, "");

        blockOffset = block.number; // the distribution will now start!
        hasDeposited = true;
        updateEndingBlock();
    }

    function updateEndingBlock() private {
        /**
         * This function is called after the token deposit by the owner.
         * This process is done only once.
         */

        uint256 deployedTokens = token.balanceOf(address(this), tokenId);
        if (deployedTokens % epochCapacity == 0) {
            distributionEndBlock = (block.number +
                (deployedTokens / epochCapacity) *
                epochDuration);
        } else {
            distributionEndBlock = (block.number +
                ((deployedTokens / epochCapacity) + 1) *
                epochDuration);
        }

        claimEndBlock = distributionEndBlock + expirationBlocks;
    }

    function calculateEndingBlock()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        /**
         * This function is not used. The actual calculation
         * is done in the updateEndingBlock function and the
         * result is stored in the contract later on.
         */
        return 0;
    }

    function handleTransfer(
        address _receiver,
        uint256 _weiAmount
    ) internal virtual override {
        /** 
         * This function will be called by the parent contract,
         * after the share calculation. The call amount will be
         * in wei, so it needs to be converted for the ERC1155 token.
         */
        _handleTransfer(_receiver, _weiAmount / (1 ether));
    }

    function _handleTransfer(
        address _receiver,
        uint256 _amount
    ) private {
        token.safeTransferFrom(address(this), _receiver, tokenId, _amount, "");
    }

    function withdrawExpired() public override onlyOwner {
        require(enableWithdraw, "Withdraw is disabled.");
        require(
            block.number > claimEndBlock,
            "Wait for the end of the distribution."
        );
        _handleTransfer(msg.sender, token.balanceOf(address(this), tokenId));
    }

    function burnExpired() public override onlyOwner {
        require(
            block.number > claimEndBlock,
            "Wait for the end of the distribution."
        );
        _handleTransfer(address(0), token.balanceOf(address(this), tokenId));
    }

    /**
     * Override distribution functions to require deposit completion.
     * The distribution and state changes should not be allowed
     * before the token deposit is completed.
     */

    function demand(uint16 volume) public virtual override depositCompleted {
        super.demand(volume);
    }

    function claim(
        uint256 epochNumber
    ) public virtual override depositCompleted {
        super.claim(epochNumber);
    }

    function claimBulk(
        uint256[] memory epochNumbers
    ) public virtual override depositCompleted {
        super.claimBulk(epochNumbers);
    }

    function updateState() internal virtual override depositCompleted {
        super.updateState();
    }

    function calculateShare()
        internal
        view
        override
        depositCompleted
        returns (uint16 _share, uint256 _amount)
    {
        return super.calculateShare();
    }

    // overrides for accepting ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract ResourceDistributor {
    event Register(address indexed _user);
    event Unregister(address indexed _user);
    event Demand(address indexed _from, uint16 _volume);
    event Claim(address indexed _from, uint256 _epoch, uint16 _share);
    event Share(uint256 _epoch, uint16 _share, uint256 _distribution);

    uint256 public constant milliether = 1e15; // 0.001 ether

    uint16 public maxDemandVolume;
    uint16 public etherMultiplier;

    uint256 public distributionEndBlock;
    uint256 public claimEndBlock;
    bool public enableWithdraw;

    struct User {
        uint256 id; // ids starting from 1
        address payable addr;
        mapping(uint256 => uint16) demandedVolumes; // volume demanded for each epoch
        uint256 lastDemandEpoch;
    }

    address public owner;
    uint256 public numberOfUsers;
    mapping(address => User) public permissionedAddresses;

    uint256 public epochCapacity;
    uint256 public cumulativeCapacity;

    uint16[] public shares; // calculated with calculateShare()

    uint256[] public numberOfDemands; // demand volume array
    uint256 public totalDemand; // total number of demands, D

    uint256 public blockOffset; // block number of the contract creation
    uint256 public epochDuration; // duration of each epoch, in blocks
    uint256 public epoch; // epoch counter

    /**
     * @param _maxDemandVolume maximum demand volume
     * @param _epochCapacity capacity of each epoch
     * @param _epochDuration duration of each epoch, in blocks
     * @param _etherMultiplier multiplier for the milliether value. To send 1 ether for shares, set it to 1000.
     * @param _expirationBlocks number of blocks after the distribution ends that the contract will be active
     * @param _enableWithdraw if true, the owner can withdraw the remaining balance after the expirationBlocks
     */
    constructor(
        uint16 _maxDemandVolume,
        uint256 _epochCapacity,
        uint256 _epochDuration,
        uint16 _etherMultiplier,
        uint256 _expirationBlocks,
        bool _enableWithdraw
    ) payable {
        require(
            _epochCapacity > 0 && _epochDuration > 0,
            "Epoch capacity and duration must be greater than 0."
        );

        owner = msg.sender;
        numberOfUsers = 0;
        blockOffset = block.number;

        maxDemandVolume = _maxDemandVolume;
        numberOfDemands = new uint256[](maxDemandVolume + 1);

        epochCapacity = _epochCapacity;
        epochDuration = _epochDuration;
        cumulativeCapacity = epochCapacity;
        epoch = 1;
        shares.push(0);

        etherMultiplier = _etherMultiplier;
        enableWithdraw = _enableWithdraw;

        distributionEndBlock = calculateEndingBlock();
        claimEndBlock = distributionEndBlock + _expirationBlocks;
    }

    function calculateEndingBlock() internal view virtual returns (uint256);

    function handleTransfer(address _receiver, uint256 _amount)
        internal
        virtual;

    function deposit(uint256 _amount) public virtual;

    function withdrawExpired() public virtual;

    function burnExpired() public virtual;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function addPermissionedUser(address payable _addr) public onlyOwner {
        // if the user does not exist, the id field should return the default value 0
        require(permissionedAddresses[_addr].id == 0, "User already exists.");
        numberOfUsers++; // user ids start from 1

        User storage currentUser = permissionedAddresses[_addr];
        currentUser.id = numberOfUsers;
        currentUser.addr = _addr;

        emit Register(_addr);
    }

    function removePermissionedUser(address _addr) public onlyOwner {
        require(permissionedAddresses[_addr].id != 0, "User does not exist.");
        delete permissionedAddresses[_addr];
        numberOfUsers--;

        emit Unregister(_addr);
    }

    function demand(uint16 volume) public virtual {
        require(
            permissionedAddresses[msg.sender].id != 0,
            "User does not have the permission."
        );
        require(
            (volume > 0) &&
                (volume <= maxDemandVolume) &&
                (volume <= epochCapacity),
            "Invalid volume."
        );

        // stop collecting demands after the distribution ends
        require(block.number < distributionEndBlock, "Demand period is over.");

        updateState();
        require(
            permissionedAddresses[msg.sender].lastDemandEpoch < epoch,
            "Wait for the next epoch."
        );
        numberOfDemands[volume]++;
        totalDemand++;

        permissionedAddresses[msg.sender].demandedVolumes[epoch] = volume;
        permissionedAddresses[msg.sender].lastDemandEpoch = epoch;

        emit Demand(msg.sender, volume);
    }

    function claim(uint256 epochNumber) public virtual {
        require(
            permissionedAddresses[msg.sender].id != 0,
            "User does not have the permission."
        );

        // stop allowing claims after the distribution's ending + expirationBlocks
        require(block.number < claimEndBlock, "Claim period is over.");

        updateState();
        require(epochNumber < epoch, "You can only claim past epochs.");

        uint16 demandedVolume = permissionedAddresses[msg.sender]
            .demandedVolumes[epochNumber];

        require(
            demandedVolume != 0,
            "You do not have a demand for this epoch."
        );

        // send min(share, User.demanded) to User.addr
        uint16 share = shares[epochNumber];

        // first, update the balance of the user
        permissionedAddresses[msg.sender].demandedVolumes[epochNumber] = 0;

        // then, send the transfer
        handleTransfer(msg.sender, min(share, demandedVolume) * (etherMultiplier * milliether));

        emit Claim(msg.sender, epochNumber, uint16(min(share, demandedVolume)));
    }

    function claimBulk(uint256[] memory epochNumbers) public virtual {
        require(
            permissionedAddresses[msg.sender].id != 0,
            "User does not have the permission."
        );

        require(
            epochNumbers.length <= 255,
            "You can only claim up to 255 epochs at once."
        );

        require(block.number < claimEndBlock, "Claim period is over.");
        updateState();

        uint256 totalClaim;

        uint16 demandedVolume;
        uint16 share;
        for (uint16 i = 0; i < epochNumbers.length; i++) {
            uint256 currentEpoch = epochNumbers[i];
            require(currentEpoch < epoch, "You can only claim past epochs.");

            demandedVolume = permissionedAddresses[msg.sender].demandedVolumes[
                currentEpoch
            ];
            require(
                demandedVolume != 0,
                "You do not have a demand for one of the epochs."
            );

            share = shares[currentEpoch];

            // first, update the balance of the user (in case of reentrancy)
            permissionedAddresses[msg.sender].demandedVolumes[currentEpoch] = 0;
            totalClaim += min(share, demandedVolume);

            emit Claim(
                msg.sender,
                currentEpoch,
                uint16(min(share, demandedVolume))
            );
        }

        // then send the transfer:
        handleTransfer(msg.sender, totalClaim * (etherMultiplier * milliether));
    }

    function updateState() internal virtual {
        uint256 currentEpoch = ((block.number - blockOffset) / epochDuration) +
            1;
        if (epoch < currentEpoch) {
            // if the current epoch is over
            uint256 epochDifference = currentEpoch - epoch;
            epoch = currentEpoch;

            uint16 share;
            uint256 distribution;
            (share, distribution) = calculateShare();

            emit Share(currentEpoch, share, distribution);

            shares.push(share);

            for (uint256 i = 0; i < epochDifference - 1; i++) {
                // add 0 shares for the epochs that are skipped
                shares.push(0);
            }

            cumulativeCapacity -= distribution; // subtract the distributed amount
            cumulativeCapacity += (epochCapacity) * epochDifference; // add the capacity of the new epoch

            totalDemand = 0;
            for (uint256 i = 0; i <= maxDemandVolume; i++) {
                numberOfDemands[i] = 0;
            }
        }
        // TODO: refund the remaining gas to the caller
    }

    function calculateShare()
        internal
        view
        virtual
        returns (uint16 _share, uint256 _amount)
    {
        /*
         * This function calculates the maximum share that can be distributed
         * in the current epoch to the users. In addition to that,it also
         * calculates the total distribution amount for the calculated maximum
         * share.
         *
         * These two values mentioned above are returned in a tuple as (share, amount).
         *
         * Note: only called by updateState(), hence, assumes that the state is updated
         */

        uint256 cumulativeNODSum = 0;
        uint256 cumulativeTDVSum = 0;

        uint256 necessaryCapacity = 0; // necessary capacity to meet demands at ith volume
        uint256 sufficientCapacity = 0; // the latest necessaryCapacity that can be distributed

        for (uint16 i = 1; i <= maxDemandVolume; i++) {
            // always point to the previous necessaryCapacity
            sufficientCapacity = necessaryCapacity;

            // use the previous values of cumulativeNODSum and cumulativeTDVSum
            necessaryCapacity =
                cumulativeTDVSum +
                i *
                (totalDemand - cumulativeNODSum);

            uint256 currentNOD = numberOfDemands[i];

            // then calculate the new values
            cumulativeNODSum += currentNOD;
            cumulativeTDVSum += currentNOD * i;

            if (necessaryCapacity > cumulativeCapacity) {
                // necessaryCapacity for this volume is larger than the cumulativeCapacity
                // so, sufficientCapacity stores the maximum amount that can be distributed
                return (i - 1, sufficientCapacity);
            }
        }

        // cumulative capacity was enough for all demands
        return (maxDemandVolume, necessaryCapacity);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}