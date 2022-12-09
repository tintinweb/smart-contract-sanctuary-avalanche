// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract EtherDistributor {

    uint16 public constant MAX_DEMAND_VOLUME = 10;
    uint16 public constant DEMAND_EXPIRATION_TIME = 100; // in epochs

    uint256 public distributionEndBlock;
    uint256 public claimEndBlock;
    bool public enableWithdraw;

    struct User {
        uint256 id; // ids starting from 1
        address payable addr;
        // list of structs [(epochMultiplier, volume), ...]
        uint256[DEMAND_EXPIRATION_TIME] epochMultipliers;
        uint16[DEMAND_EXPIRATION_TIME] demandedVolumes;
        uint256 lastDemandEpoch;
    }

    address public owner;
    uint256 public numberOfUsers;
    mapping(address => User) public permissionedAddresses;

    uint256 public epochCapacity;
    uint256 public cumulativeCapacity;

    uint16[DEMAND_EXPIRATION_TIME] public shares; // calculated with calculateShare()

    uint256[MAX_DEMAND_VOLUME + 1] public numberOfDemands; // demand volume array
    uint256 public totalDemand; // total number of demands, D

    uint256 public blockOffset; // block number of the contract creation
    uint256 public epochDuration; // duration of each epoch, in blocks
    uint256 public epoch; // epoch counter

    constructor(
        uint256 _epochCapacity,
        uint256 _epochDuration,
        bool _enableWithdraw
    ) payable {
        require(
            _epochCapacity > 0 && _epochDuration > 0,
            "Epoch capacity and duration must be greater than 0."
        );
        require(msg.value > 0, "Distribution capacity must be greater than 0.");

        owner = msg.sender;
        numberOfUsers = 0;
        blockOffset = block.number;
        epochCapacity = _epochCapacity;
        epochDuration = _epochDuration;
        cumulativeCapacity = epochCapacity;
        epoch = 1;

        enableWithdraw = _enableWithdraw;

        uint256 deployedEthers = msg.value / (0.01 ether);

        if (deployedEthers % epochCapacity == 0) {
            distributionEndBlock =
                blockOffset +
                (deployedEthers / epochCapacity) *
                epochDuration;
        } else {
            distributionEndBlock =
                blockOffset +
                ((deployedEthers / epochCapacity) + 1) *
                epochDuration;
        }

        claimEndBlock =
            distributionEndBlock +
            epochDuration *
            DEMAND_EXPIRATION_TIME;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function withdrawExpired() public onlyOwner {
        require(enableWithdraw, "Withdraw is disabled.");
        require(
            block.number > claimEndBlock,
            "Wait for the end of the distribution."
        );
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function burnExpired() public onlyOwner {
        require(
            block.number > claimEndBlock,
            "Wait for the end of the distribution."
        );
        selfdestruct(payable(address(0)));
    }

    function addPermissionedUser(address payable _addr) public onlyOwner {
        // if the user does not exist, the id field should return the default value 0
        require(permissionedAddresses[_addr].id == 0, "User already exists.");
        numberOfUsers++; // user ids start from 1

        uint256[DEMAND_EXPIRATION_TIME] memory _epochMultipliers;
        uint16[DEMAND_EXPIRATION_TIME] memory _demandedVolumes;

        User memory currentUser = User(
            numberOfUsers,
            _addr,
            _epochMultipliers,
            _demandedVolumes,
            0
        );

        permissionedAddresses[_addr] = currentUser;
    }

    function demand(uint16 volume) public {
        require(
            permissionedAddresses[msg.sender].id != 0,
            "User does not have the permission."
        );
        require(
            (volume > 0) &&
                (volume <= MAX_DEMAND_VOLUME) &&
                (volume <= epochCapacity),
            "Invalid volume."
        );

        // stop collecting demands after the distribution ends
        require(block.number < distributionEndBlock, "Distribution is over.");

        updateState();
        require(
            permissionedAddresses[msg.sender].lastDemandEpoch < epoch,
            "Wait for the next epoch."
        );
        numberOfDemands[volume]++;
        totalDemand++;

        permissionedAddresses[msg.sender].epochMultipliers[
            epoch % DEMAND_EXPIRATION_TIME
        ] = epoch / DEMAND_EXPIRATION_TIME;
        permissionedAddresses[msg.sender].demandedVolumes[
            epoch % DEMAND_EXPIRATION_TIME
        ] = volume;
        permissionedAddresses[msg.sender].lastDemandEpoch = epoch;
    }

    function claim(uint256 epochNumber) public {
        require(
            permissionedAddresses[msg.sender].id != 0,
            "User does not have the permission."
        );

        // stop allowing claims after the distribution's ending + DEMAND_EXPIRATION_TIME
        require(block.number < claimEndBlock, "Distribution is over.");

        updateState();
        require(epochNumber < epoch, "Invalid epoch number.");
        require(
            epochNumber + DEMAND_EXPIRATION_TIME > epoch,
            "Epoch is too old."
        );

        uint256 index = epochNumber % DEMAND_EXPIRATION_TIME;
        uint256 epochMultiplierAtIndex = permissionedAddresses[msg.sender]
            .epochMultipliers[index];
        uint256 volumeAtIndex = permissionedAddresses[msg.sender]
            .demandedVolumes[index];

        require(
            epochMultiplierAtIndex * DEMAND_EXPIRATION_TIME + index ==
                epochNumber &&
                volumeAtIndex != 0,
            "You do not have a demand for this epoch."
        );

        // send min(share, User.demanded) to User.addr

        uint256 share = shares[epochNumber % DEMAND_EXPIRATION_TIME];

        // first, update the balance of the user
        permissionedAddresses[msg.sender].demandedVolumes[index] = 0;

        // then, send the ether

        (bool success, ) = msg.sender.call{
            value: min((share * (0.01 ether)), (volumeAtIndex * (0.01 ether)))
        }("");
        require(success, "Transfer failed.");
    }

    function claimAll() public {
        require(block.number < claimEndBlock, "Distribution is over.");
        updateState();

        uint256 totalClaim;

        uint256 epochMultiplierAtIndex;
        uint256 volumeAtIndex;
        uint256 share;
        uint256 index;
        for (uint256 i = 0; i < DEMAND_EXPIRATION_TIME; i++) {
            if (epoch == i) break;

            index = (epoch - i) % DEMAND_EXPIRATION_TIME;
            epochMultiplierAtIndex = permissionedAddresses[msg.sender]
                .epochMultipliers[index];
            volumeAtIndex = permissionedAddresses[msg.sender].demandedVolumes[
                index
            ];

            if (
                epochMultiplierAtIndex * DEMAND_EXPIRATION_TIME + index ==
                epoch - i &&
                volumeAtIndex != 0
            ) {
                share = shares[index];

                // first, update the balance of the user (in case of reentrancy)
                permissionedAddresses[msg.sender].demandedVolumes[index] = 0;
                totalClaim += min(share, volumeAtIndex);
            }
        }

        // then, send the ether
        (bool success, ) = msg.sender.call{
            value: totalClaim * (0.01 ether)
        }("");
        require(success, "Transfer failed.");
    }

    function updateState() internal {
        uint256 currentEpoch = ((block.number - blockOffset) / epochDuration) +
            1;
        if (epoch < currentEpoch) {
            // if the current epoch is over
            uint256 epochDifference = currentEpoch - epoch;
            epoch = currentEpoch;

            uint256 distribution;
            (
                shares[(epoch - epochDifference) % DEMAND_EXPIRATION_TIME],
                distribution
            ) = calculateShare();
            cumulativeCapacity -= distribution; // subtract the distributed amount
            cumulativeCapacity += (epochCapacity) * epochDifference; // add the capacity of the new epoch

            totalDemand = 0;
            for (uint256 i = 0; i < MAX_DEMAND_VOLUME + 1; i++) {
                numberOfDemands[i] = 0;
            }
        }
        // TODO: refund the remaining gas to the caller
    }

    function calculateShare()
        internal
        view
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

        for (uint16 i = 1; i <= MAX_DEMAND_VOLUME; i++) {
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
        return (MAX_DEMAND_VOLUME, necessaryCapacity);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}