// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./libraries/LibSignature.sol";
import "solmate/utils/MerkleProofLib.sol";

contract Voting {
    uint256 public electionId;

    struct Election {
        string title;
        uint256[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        mapping(uint256 => uint256) votePerCandidate;
        uint8 maxCandidateNo;
        bool active;
        bytes32 merkleRoot;
        uint256 totalVotes;
    }

    struct VoteData {
        bytes signature;
        uint256 candidateId;
        address voter;
        bytes32 voterHash;
        bytes32[] proof;
    }

    struct ElectionM {
        string title;
        uint256[] candidates;
        uint40 timeStarted;
        uint40 duration;
        uint40 endTime;
        bytes32 merkleRoot;
        bool active;
        uint256 totalVotes;
    }
    mapping(uint256 => Election) elections;
    //admin whitelists
    mapping(address => mapping(uint256 => bool)) voted;
    address owner;

    event ElectionCreated(
        uint256[] candidates,
        string title,
        uint40 endTime,
        uint256 id
    );
    event Voted(address voter, uint256 electionId, uint256 candidate);

    constructor() {
        owner = (msg.sender);
    }

    function _isOwner() private view {
        if (msg.sender != owner) revert("NotOwner");
    }

    //confirm if the user is a registered voter in the given election
    function _isVoter(
        address _voter,
        bytes32 _voterHash,
        bytes32[] calldata _merkleProof,
        uint256 _electionId
    ) internal view {
        //short-circuit election id
        bytes32 root = _assertElection(_electionId);
        //compute the leaf/node hash
        bytes32 node = keccak256(
            abi.encodePacked(_voter, _voterHash, _electionId)
        );

        if (!MerkleProofLib.verify(_merkleProof, root, node))
            revert("InvalidVoter");
    }

    function _voted(address _voter, uint256 _electionId) private view {
        if (voted[_voter][_electionId]) revert("Unable To Vote");
    }

    function _assertTime(uint40 _startTime, uint40 _duration) private view {
        if (_startTime < block.timestamp) revert("StartTimeTooLow");
        if (_duration > 1 days) revert("1 Day duration Max");
        uint40 _endTime = _startTime + _duration;
        if (_endTime <= _startTime) revert("EndTimeTooLow");
        if (_duration < 3 hours) revert("3 hours duration Min");
        //put in a check for startTime restriction
        //   if (_endTime > 3 days) revert("3 Days Duration Max ");
    }

    function _assertElection(
        uint256 _electionId
    ) private view returns (bytes32 root_) {
        if (_electionId >= electionId) revert("InvalidElectionID");
        if (elections[_electionId].endTime < block.timestamp)
            revert("ElectionFinished");
        root_ = elections[_electionId].merkleRoot;

        if (!elections[_electionId].active) revert("InactiveElection");
    }

    function createElection(
        uint256[] calldata _candidates,
        uint40 _startTime,
        uint40 _duration,
        string calldata _title,
        uint8 _maxCandidates
    ) external {
        _isOwner();
        if (_candidates.length > 5) revert("max candidate length is 5");
        _assertTime(_startTime, _duration);
        Election storage e = elections[electionId];
        e.candidates = _candidates;
        e.title = _title;
        e.duration = _duration;
        e.timeStarted = _startTime;
        e.endTime = _startTime + _duration;
        e.maxCandidateNo = _maxCandidates;
        emit ElectionCreated(_candidates, _title, e.endTime, electionId);
        electionId++;
    }

    function activateElection(
        uint256 _electionId,
        bytes32 _merkleRoot
    ) external {
        _isOwner();
        elections[_electionId].merkleRoot = _merkleRoot;
        elections[_electionId].active = true;
    }

    //_data[i] should be a hash of vote details e.g consisting of candidate id and voter detail hash
    function submitVotes(
        VoteData[] calldata _data,
        uint256 _electionId
    ) external {
        //assert(_sigs.length == _data.length);
        if (_data.length > 0) {
            for (uint256 i = 0; i < _data.length; ) {
                VoteData memory data = _data[i];
                //check voter eligibility
                _voted(data.voter, _electionId);
                _isVoter(
                    data.voter,
                    data.voterHash,
                    _data[i].proof,
                    _electionId
                );
                Election storage e = elections[_electionId];
                //check sig
                bytes32 mHash = LibSignature.getMessageHash(
                    data.voter,
                    _electionId,
                    data.candidateId
                );
                mHash = LibSignature.getEthSignedMessageHash(mHash);
                LibSignature.isValid(mHash, data.signature, data.voter);
                if (_data[i].candidateId > e.maxCandidateNo - 1)
                    revert("NoSuchCandidate");
                //increase vote count for candidate
                e.votePerCandidate[data.candidateId]++;
                emit Voted(data.voter, _electionId, data.candidateId);
                e.totalVotes++;
                unchecked {
                    ++i;
                }
            }
        }
    }

    function viewResults(
        uint256 _electionId
    )
        public
        view
        returns (uint256[] memory candidateIds, uint256[] memory _votes)
    {
        candidateIds = new uint256[](elections[_electionId].maxCandidateNo);
        _votes = new uint256[](elections[_electionId].maxCandidateNo);
        for (uint256 i = 0; i < _votes.length; i++) {
            candidateIds[i] = i;
            _votes[i] = elections[_electionId].votePerCandidate[i];
        }
    }

    function viewElection(
        uint256 _id
    ) public view returns (ElectionM memory e_) {
        Election storage e = elections[_id];
        e_.candidates = e.candidates;
        e_.title = e.title;
        e_.timeStarted = e.timeStarted;
        e_.duration = e.duration;
        e_.endTime = e.endTime;
        e_.merkleRoot = e.merkleRoot;
        e_.active = e.active;
        e_.totalVotes = e.totalVotes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibSignature {
    function isValid(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal pure {
        if (recoverSigner(messageHash, signature) != signer)
            revert("InvalidSignature");
    }

    function getEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }

    function getMessageHash(
        address _voter,
        uint256 _electionId,
        uint256 _candidateId
    ) internal pure returns (bytes32 hash_) {
        hash_ = keccak256(abi.encodePacked(_voter, _electionId, _candidateId));
    }
}