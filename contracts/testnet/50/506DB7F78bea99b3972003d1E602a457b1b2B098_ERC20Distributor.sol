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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ResourceDistributor.sol";

contract ERC20Distributor is ResourceDistributor {
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
        ResourceDistributor(
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