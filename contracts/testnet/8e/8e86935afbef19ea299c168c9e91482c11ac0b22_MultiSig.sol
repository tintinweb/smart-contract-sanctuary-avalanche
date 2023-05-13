/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigStruct {

    // Batch Import Strcut

    struct BatchNFTsStruct {
        uint256[] tokenIds;
        address contractAddress;
    }
}
contract SegMintNFTVault is MultiSigStruct {

    function batchLockNFTs(BatchNFTsStruct[] memory _lockData)  public {
    }

    function batchUnlockNFTs(BatchNFTsStruct[] memory _lockData)  public {

    }


 }
contract MultiSig is MultiSigStruct {
    uint256 public minSignatures;
    address[] public signatories;

    uint256 public proposalCount;
    uint256 public lockProposalCount;





    struct Proposal {
        uint256 id;
        address proposedBy;
        address signatoryModified;
        bool approved;
    }
    


    struct LockProposal {
        uint256 id;
        address proposedBy;
        bool approved;
        address SegMintVault;
        string _type; // LOCK OR UNLOCK
    }

    mapping(address => bool) public isSignatory;
    mapping(uint256 => Proposal) public proposals;

    mapping(uint256 => LockProposal) public _lockProposals;


    // proposal id to address to boolean
    mapping(uint256=>mapping(address => bool)) public approvedBy;


    mapping(uint256=>mapping(address => bool)) public unlockApprovedBy;

    mapping(uint256=>BatchNFTsStruct[]) public _lockData;
    mapping(uint256=>BatchNFTsStruct[]) public _unLockData;


    event SignatoryAdded(address indexed signatory);
    event SignatoryRemoved(address indexed signatory);
    event ProposalCreated(uint256 indexed id, address indexed signatory, address indexed newSignatory);
    event ProposalApproved(uint256 indexed id, address indexed signatory, address indexed approver);
    event LockProposalCreated(uint256 id, BatchNFTsStruct[] data);
    event unLockProposalCreated(uint256 id, BatchNFTsStruct[] data);
 
    constructor(uint256 _minSignatures, address[] memory _signatories) {
        require(_minSignatures > 0 && _minSignatures <= _signatories.length, "Invalid min signatures");
        minSignatures = _minSignatures;
        for (uint256 i = 0; i < _signatories.length; i++) {
            address signatory = _signatories[i];
            require(signatory != address(0), "Invalid signatory address");
            require(!isSignatory[signatory], "Duplicate signatory address");
            signatories.push(signatory);
            isSignatory[signatory] = true;
            emit SignatoryAdded(signatory);
        }
    }

    function addSignatory(address _newSignatory) public {
        require(_newSignatory != address(0), "Invalid signatory address");
        require(!isSignatory[_newSignatory], "Signatory address already added");
        require(isSignatory[msg.sender], "Not authorized to create proposals");

        if (signatories.length >= 2) {
            // create a proposal for new signatory
            uint256 proposalId = ++proposalCount;
            proposals[proposalId] = Proposal({
                id: proposalId,
                proposedBy: msg.sender,
                signatoryModified: _newSignatory,
                approved: false
            });
            approvedBy[proposalId][msg.sender] = true;
            emit ProposalCreated(proposalId, msg.sender, _newSignatory);
        } else {
            // add the new signatory directly
            signatories.push(_newSignatory);
            isSignatory[_newSignatory] = true;
            emit SignatoryAdded(_newSignatory);
        }
    }

    function removeSignatory(address _signatory) public {
        require(isSignatory[_signatory], "Signatory address not found");
        require(isSignatory[msg.sender], "Not authorized to create proposals");

        if (signatories.length > 2) {
            // create a proposal for removing signatory
            uint256 proposalId = ++proposalCount;
            proposals[proposalId] = Proposal({
                id: proposalId,
                proposedBy: msg.sender,
                signatoryModified: address(0),
                approved: false
            });
            approvedBy[proposalId][msg.sender] = true;
            emit ProposalCreated(proposalId, msg.sender, address(0));
        } else {
            // require at least 2 signatories
            require(signatories.length > minSignatures, "Minimum signatories requirement not met");

            // remove signatory
            isSignatory[_signatory] = false;
            for (uint256 i = 0; i < signatories.length; i++) {
                if (signatories[i] == _signatory) {
                    signatories[i] = signatories[signatories.length - 1];
                    break;
                }
            }
            signatories.pop();
            emit SignatoryRemoved(_signatory);
        }
    }

    function approveProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Invalid proposal ID");
        require(!proposal.approved, "Proposal already approved");
        require(isSignatory[msg.sender], "Not authorized to approve proposals");
        require(!approvedBy[_proposalId][msg.sender], "Already approved by this signatory");

        approvedBy[_proposalId][msg.sender] = true;
        emit ProposalApproved(_proposalId, proposal.proposedBy, msg.sender);

        // check if enough signatories have approved the proposal
        uint256 approvalCount = 0;
        for (uint256 i = 0; i < signatories.length; i++) {
            address signatory = signatories[i];
            if (approvedBy[_proposalId][signatory]) {
                approvalCount++;
                if (approvalCount >= minSignatures) {
                    // add the new signatory
                    signatories.push(proposal.signatoryModified);
                    isSignatory[proposal.signatoryModified] = true;
                    emit SignatoryAdded(proposal.proposedBy);
                    break;
                }
            }
        }
    }




    function createLockProposal(BatchNFTsStruct[] memory lockData, address _SegMintVault) public {
        require(lockData.length > 0, "No unlock data provided");
        uint256 proposalId = ++lockProposalCount;
        require(isSignatory[msg.sender], "Not authorized to approve proposals");

        _lockProposals[proposalId] = LockProposal({
            id: proposalId,
            proposedBy: msg.sender,
            approved: false,
            _type: "LOCK",
            SegMintVault: _SegMintVault
        });

        for (uint256 i = 0; i < lockData.length; i++) {
            BatchNFTsStruct memory data = lockData[i];
            require(data.contractAddress != address(0), "Invalid contract address");

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
                require(data.tokenIds.length != 0, "Invalid token ID");
                _lockData[proposalId].push(lockData[i]);
            }
        }
        approvedBy[proposalId][msg.sender] = true;
        emit LockProposalCreated(proposalId, lockData);
    }


    function createUnlockProposal(BatchNFTsStruct[] memory lockData, address _SegMintVault) public {
        require(lockData.length > 0, "No unlock data provided");
        uint256 proposalId = ++lockProposalCount;
        _lockProposals[proposalId] = LockProposal({
            id: proposalId,
            proposedBy: msg.sender,
            approved: false,
            _type: "UNLOCK",
            SegMintVault: _SegMintVault
        });

        for (uint256 i = 0; i < lockData.length; i++) {
            BatchNFTsStruct memory data = lockData[i];
            require(data.contractAddress != address(0), "Invalid contract address");

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
                require(data.tokenIds.length != 0, "Invalid token ID");
                _lockData[proposalId].push(lockData[i]);
            }
        }
        approvedBy[proposalId][msg.sender] = true;
        emit unLockProposalCreated(proposalId, lockData);
    }

    function approveLockProposal(uint256 _proposalId) public {
        LockProposal storage proposal = _lockProposals[_proposalId];
        require(proposal.id != 0, "Invalid proposal ID");
        require(!proposal.approved, "Proposal already approved");
        require(isSignatory[msg.sender], "Not authorized to approve proposals");
        require(!unlockApprovedBy[_proposalId][msg.sender], "Already approved by this signatory");

        unlockApprovedBy[_proposalId][msg.sender] = true;
        
        // check if enough signatories have approved the proposal
        uint256 approvalCount = 0;
        for (uint256 i = 0; i < signatories.length; i++) {
            address signatory = signatories[i];
            if (unlockApprovedBy[_proposalId][signatory]) {
                approvalCount++;
                if (approvalCount >= minSignatures) {
                    // change the approve status
                    proposal.approved = true;
                    if(keccak256(abi.encodePacked((proposal._type))) == keccak256(abi.encodePacked(("LOCK")))) {
                        SegMintNFTVault(proposal.SegMintVault).batchLockNFTs(_lockData[_proposalId]);
                    } else {
                        SegMintNFTVault(proposal.SegMintVault).batchUnlockNFTs(_unLockData[_proposalId]);
                    }
                }
            }
        }
    }

}