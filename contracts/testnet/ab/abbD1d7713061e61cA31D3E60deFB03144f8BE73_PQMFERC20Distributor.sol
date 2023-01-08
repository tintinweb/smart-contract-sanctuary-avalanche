// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Permissioned is Ownable {
    event Register(address indexed _user);
    event Unregister(address indexed _user);

    uint256 public numberOfUsers;
    mapping(address => uint256) public registeredIds;

    modifier onlyRegistered() {
        require(
            registeredIds[msg.sender] != 0,
            "Permissioned: User is not registered"
        );
        _;
    }

    function addPermissionedUser(address payable _addr) public onlyOwner {
        require(
            registeredIds[_addr] == 0,
            "Permissioned: User already exists"
        );
        numberOfUsers++;
        registeredIds[_addr] = numberOfUsers; // ids starting from 1
        emit Register(_addr);
    }

    function removePermissionedUser(address _addr) public onlyOwner {
        require(
            registeredIds[_addr] != 0,
            "Permissioned: User does not exist"
        );
        delete registeredIds[_addr];
        numberOfUsers--;
        emit Unregister(_addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IResourceDistributor {
    function deposit(uint256 _amount) external;

    function withdrawExpired() external;

    function burnExpired() external;

    function demand(uint16 volume) external;

    function claim(uint256 epochNumber) external;

    function claimBulk(uint256[] memory epochNumbers) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PResourceDistributor.sol";
import "../../../lib/ShareCalculator.sol";

abstract contract PQMFResourceDistributor is PResourceDistributor {
    constructor(
        uint16 _maxDemandVolume,
        uint256 _epochCapacity,
        uint256 _epochDuration,
        uint16 _etherMultiplier,
        uint256 _expirationBlocks,
        bool _enableWithdraw
    )
        payable
        PResourceDistributor(
            _maxDemandVolume,
            _epochCapacity,
            _epochDuration,
            _etherMultiplier,
            _expirationBlocks,
            _enableWithdraw
        )
    {}

    function calculateShare()
        internal
        view
        virtual
        override
        returns (uint16 _share, uint256 _amount)
    {
        return
            ShareCalculator.calculateQMFShare(
                maxDemandVolume,
                totalDemand,
                numberOfDemands,
                cumulativeCapacity
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../../allowance/Permissioned.sol";
import "../ResourceDistributor.sol";

abstract contract PResourceDistributor is Permissioned, ResourceDistributor {
    constructor(
        uint16 _maxDemandVolume,
        uint256 _epochCapacity,
        uint256 _epochDuration,
        uint16 _etherMultiplier,
        uint256 _expirationBlocks,
        bool _enableWithdraw
    )
        payable
        ResourceDistributor(
            _maxDemandVolume,
            _epochCapacity,
            _epochDuration,
            _etherMultiplier,
            _expirationBlocks,
            _enableWithdraw
        )
    {}

    function demand(uint16 volume) public virtual override onlyRegistered {
        super.demand(volume);
    }

    function claim(uint256 epochNumber) public virtual override onlyRegistered {
        super.claim(epochNumber);
    }

    function claimBulk(
        uint256[] memory epochNumbers
    ) public virtual override onlyRegistered {
        super.claimBulk(epochNumbers);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IResourceDistributor.sol";
import "../../lib/ShareCalculator.sol";
import "../../miscellaneous/GasRefunder.sol";

/**
 * @title ResourceDistributor
 * @dev In this contract, permissioned addresses do not exist,
 * and anyone can interact with the contract functions. If the
 * subnet is already permissioned and no additional restrictions
 * are needed, this contract can be used.
 */
abstract contract ResourceDistributor is
    Ownable,
    IResourceDistributor,
    GasRefunder
{
    event Demand(address indexed _from, uint256 _epoch, uint16 _volume);
    event Claim(address indexed _from, uint256 _epoch, uint16 _share);
    event Share(uint256 indexed _epoch, uint16 _share, uint256 _distribution);

    uint256 public constant milliether = 1e15; // 0.001 ether

    uint16 public maxDemandVolume;
    uint16 public etherMultiplier;

    uint256 public distributionEndBlock;
    uint256 public claimEndBlock;
    bool public enableWithdraw;

    struct User {
        mapping(uint256 => uint16) demandedVolumes; // volume demanded for each epoch
        uint256 lastDemandEpoch;
    }

    mapping(address => User) public users;

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

    function handleTransfer(
        address _receiver,
        uint256 _amount
    ) internal virtual;

    function deposit(uint256 _amount) public virtual;

    function withdrawExpired() public virtual;

    function burnExpired() public virtual;

    function demand(uint16 volume) public virtual {
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
            users[msg.sender].lastDemandEpoch < epoch,
            "Wait for the next epoch."
        );
        numberOfDemands[volume]++;
        totalDemand++;

        users[msg.sender].demandedVolumes[epoch] = volume;
        users[msg.sender].lastDemandEpoch = epoch;

        emit Demand(msg.sender, epoch, volume);
    }

    function claim(uint256 epochNumber) public virtual {
        // stop allowing claims after the distribution's ending + expirationBlocks
        require(block.number < claimEndBlock, "Claim period is over.");

        updateState();
        require(epochNumber < epoch, "You can only claim past epochs.");

        uint16 demandedVolume = users[msg.sender]
            .demandedVolumes[epochNumber];

        require(
            demandedVolume != 0,
            "You do not have a demand for this epoch."
        );

        // send min(share, User.demanded) to User.addr
        uint16 share = shares[epochNumber];

        // first, update the balance of the user
        users[msg.sender].demandedVolumes[epochNumber] = 0;

        // then, send the transfer
        handleTransfer(
            msg.sender,
            min(share, demandedVolume) * (etherMultiplier * milliether)
        );

        emit Claim(msg.sender, epochNumber, uint16(min(share, demandedVolume)));
    }

    function claimBulk(uint256[] memory epochNumbers) public virtual {
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

            demandedVolume = users[msg.sender].demandedVolumes[currentEpoch];
            require(
                demandedVolume != 0,
                "You do not have a demand for one of the epochs."
            );

            share = shares[currentEpoch];

            // first, update the balance of the user (in case of reentrancy)
            users[msg.sender].demandedVolumes[currentEpoch] = 0;
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
            
            uint256 startGas = gasleft();

            uint16 share;
            uint256 distribution;
            (share, distribution) = calculateShare();
            
            emit Share(currentEpoch, share, distribution);

            uint256 epochDifference = currentEpoch - epoch;
            epoch = currentEpoch;

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

            uint256 gasUsed = startGas - gasleft();
            uint256 gasPrice = tx.gasprice;
            
            // +500 for the gas used in the calculations
            uint256 gasCost = (500 + gasUsed) * gasPrice;
            
            refunds[msg.sender] += gasCost;
        }
    }

    function calculateShare()
        internal
        view
        virtual
        returns (uint16 _share, uint256 _amount);

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../abstract/permissioned/PQMFResourceDistributor.sol";

contract PQMFERC20Distributor is PQMFResourceDistributor {
    IERC20 public token;
    uint256 public expirationBlocks;
    bool public hasDeposited;

    constructor(
        address _tokenContract,
        uint16 _maxDemandVolume,
        uint256 _epochCapacity,
        uint256 _epochDuration,
        uint16 _etherMultiplier,
        uint256 _expirationBlocks,
        bool _enableWithdraw
    )
        PQMFResourceDistributor(
            _maxDemandVolume,
            _epochCapacity,
            _epochDuration,
            _etherMultiplier,
            _expirationBlocks,
            _enableWithdraw
        )
    {
        token = IERC20(_tokenContract);
        expirationBlocks = _expirationBlocks;
        hasDeposited = false;
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
            _amount >= epochCapacity * (etherMultiplier * milliether),
            "The contract must be funded with at least one epoch capacity."
        );

        token.transferFrom(msg.sender, address(this), _amount);

        blockOffset = block.number; // the distribution will now start!
        hasDeposited = true;
        _updateEndingBlock();
    }

    function _updateEndingBlock() private {
        /**
         * This function is called after the token deposit by the owner.
         * This process is done only once.
         */

        uint256 deployedTokens = token.balanceOf(address(this)) /
            (etherMultiplier * milliether);
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
        uint256 _amount
    ) internal virtual override {
        token.transfer(_receiver, _amount);
    }

    function withdrawExpired() public override onlyOwner {
        require(enableWithdraw, "Withdraw is disabled.");
        require(
            block.number > claimEndBlock,
            "Wait for the end of the distribution."
        );
        handleTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function burnExpired() public override onlyOwner {
        require(
            block.number > claimEndBlock,
            "Wait for the end of the distribution."
        );
        handleTransfer(address(0), token.balanceOf(address(this)));
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Heapified {
    struct Heap {
        uint16[] heap;
    }

    function heapify(
        uint16[] memory arr
    ) public pure returns (Heap memory) {
        Heap memory self;
        self.heap = arr;
        for (uint256 i = self.heap.length / 2; i > 0; i--) {
            heapifyDown(self, i);
        }
        return self;
    }

    function heapifyDown(
        Heap memory self,
        uint256 i
    ) public pure returns (Heap memory) {
        uint256 left = 2 * i;
        uint256 right = 2 * i + 1;
        uint256 smallest = i;
        if (
            left <= self.heap.length &&
            self.heap[left - 1] < self.heap[smallest - 1]
        ) {
            smallest = left;
        }
        if (
            right <= self.heap.length &&
            self.heap[right - 1] < self.heap[smallest - 1]
        ) {
            smallest = right;
        }
        if (smallest != i) {
            uint16 temp = self.heap[i - 1];
            self.heap[i - 1] = self.heap[smallest - 1];
            self.heap[smallest - 1] = temp;
            heapifyDown(self, smallest);
        }
        return self;
    }

    function heapifyUp(
        Heap memory self,
        uint256 i
    ) public pure returns (Heap memory) {
        uint256 parent = i / 2;
        if (parent > 0 && self.heap[parent - 1] > self.heap[i - 1]) {
            uint16 temp = self.heap[i - 1];
            self.heap[i - 1] = self.heap[parent - 1];
            self.heap[parent - 1] = temp;
            heapifyUp(self, parent);
        }
        return self;
    }

    function insert(
        Heap memory self,
        uint16 value
    ) public pure returns (Heap memory) {
        self.heap = toUint16Array(abi.encodePacked(self.heap, value));
        heapifyUp(self, self.heap.length);
        return self;
    }

    function extractMin(
        Heap memory self
    ) public pure returns (Heap memory, uint16) {
        if (self.heap.length == 0) {
            return (self, 0);
        }
        uint16 min = self.heap[0];
        self.heap[0] = self.heap[self.heap.length - 1];
        // apply self.heap.pop() but building the array manually
        uint16[] memory newHeap = new uint16[](self.heap.length - 1);
        for (uint256 i = 0; i < self.heap.length - 1; i++) {
            newHeap[i] = self.heap[i];
        }
        self.heap = newHeap;
        heapifyDown(self, 1);
        return (self, min);
    }

    function getMin(Heap memory self) public pure returns (uint16) {
        if (self.heap.length == 0) {
            return 0;
        }
        return self.heap[0];
    }

    function toUint16Array(
        bytes memory b
    ) private pure returns (uint16[] memory) {
        uint16[] memory arr = new uint16[](b.length / 2);
        for (uint256 i = 0; i < b.length / 2; i++) {
            arr[i] =
                uint16(uint8(b[i * 2])) +
                (uint16(uint8(b[i * 2 + 1])) << 8);
        }
        return arr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Heapified.sol";

library ShareCalculator {
    /*
     * Share calculation functions calculate the maximum share that can be distributed
     * in the current epoch to the users. In addition to that, they also
     * calculate the total distribution amount for the calculated maximum
     * share.
     *
     * These two values mentioned above are returned in a tuple as (share, amount).
     *
     * Note: They should be called after the updateState() call.
     */

    function calculateQMFShare(
        uint16 maxDemandVolume,
        uint256 totalDemand,
        uint256[] calldata numberOfDemands,
        uint256 cumulativeCapacity
    ) external pure returns (uint16 _share, uint256 _amount) {
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

    function calculateSMFShare(
        uint16 maxDemandVolume,
        uint16[] calldata epochDemands,
        uint256 cumulativeCapacity
    ) external pure returns (uint16 _share, uint256 _amount) {
        if (epochDemands.length == 0) {
            return (maxDemandVolume, 0);
        }

        Heapified.Heap memory heap = Heapified.heapify(epochDemands);

        uint256 simulatedCapacity = cumulativeCapacity;
        uint256 heapSize = heap.heap.length;
        uint16 simulatedShare = uint16(simulatedCapacity / heapSize);
        uint16 result = 0;

        while (heapSize > 0 && simulatedCapacity >= heapSize) {
            while (heap.heap[0] <= simulatedShare) {
                simulatedCapacity -= heap.heap[0];
                (heap, ) = Heapified.extractMin(heap);
                heapSize--;
                if (heapSize == 0) {
                    return (
                        maxDemandVolume,
                        cumulativeCapacity - simulatedCapacity
                    );
                }
            }

            simulatedCapacity -= simulatedShare * heapSize;

            for (uint256 i = 0; i < heapSize; i++)
                heap.heap[i] -= simulatedShare;

            result += simulatedShare;
            simulatedShare = uint16(simulatedCapacity / heapSize);
        }
        return (result, cumulativeCapacity - simulatedCapacity);
    }

    function calculateEqualShare(
        uint16 maxDemandVolume,
        uint256 totalDemand,
        uint256 cumulativeCapacity
    ) external pure returns (uint16 _share, uint256 _amount) {
        if (totalDemand == 0) {
            return (maxDemandVolume, 0);
        }
        uint256 share = cumulativeCapacity / totalDemand;
        if (share > maxDemandVolume) {
            return (maxDemandVolume, maxDemandVolume * totalDemand);
        }
        return (uint16(share), share * totalDemand);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GasRefunder is Ownable {
    event Refund(address indexed _to, uint256 _amount);

    mapping(address => uint256) public refunds;
    uint256 public refundAllocation;

    constructor() {}

    receive() external payable onlyOwner {
        refundAllocation += msg.value;
    }

    function withdrawRefundAllocation(uint256 amount) external onlyOwner {
        require(
            refundAllocation >= amount,
            "GasRefunder: You cannot withdraw more than the refund allocation"
        );
        refundAllocation -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdraw failed");
    }

    function claimRefund() external {
        uint256 amount = refunds[msg.sender];
        require(amount > 0, "GasRefunder: No refund available");
        require(
            refundAllocation >= amount,
            "GasRefunder: Refund allocation is insufficient"
        );
        refundAllocation -= amount;
        refunds[msg.sender] = 0;
        emit Refund(msg.sender, amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund failed");
    }
}