/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-23
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface API {
    function addStaticData(address token, string memory hashString) external;

    function staticData(address token)
        external
        view
        returns (string memory hashString);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Protocol {
    address public owner;
    uint256 public submitPrice;

    uint256 public firstSortMaxVotes;
    uint256 public firstSortValidationsNeeded;
    uint256 public finalDecisionValidationsNeeded;
    uint256 public finalDecisionMaxVotes;
    uint256 public tokensPerVote;

    uint256 public membersToPromoteToRankI;
    uint256 public membersToPromoteToRankII;
    uint256 public votesNeededToRankIPromotion;
    uint256 public votesNeededToRankIIPromotion;
    uint256 public membersToDemoteFromRankI;
    uint256 public membersToDemoteFromRankII;
    uint256 public votesNeededToRankIDemotion;
    uint256 public votesNeededToRankIIDemotion;

    mapping(address => string) public submittedData;
    mapping(address => string) public firstSortValidated;

    mapping(address => mapping(address => bool)) public firstSortVotes;
    mapping(address => mapping(address => bool)) public finalDecisionVotes;
    mapping(address => address[]) public tokenFirstValidations;
    mapping(address => address[]) public tokenFirstRejections;
    mapping(address => uint256) public tokenFinalValidations;
    mapping(address => uint256) public tokenFinalRejections;

    mapping(address => uint256) public rank;
    mapping(address => uint256) public promoteVotes;
    mapping(address => uint256) public demoteVotes;
    mapping(address => uint256) public goodFirstVotes;
    mapping(address => uint256) public badFirstVotes;
    mapping(address => uint256) public paidFirstVotes;

    address[] public submittedTokens;
    mapping(address => uint256) public indexOfSubmittedTokens;
    address[] public validatedTokens;
    mapping(address => uint256) public indexOfValidatedTokens;

    IERC20 MOBL;
    API ProtocolAPI;

    event DataSubmitted(address indexed token, string hashString);
    event FirstSortValidated(address indexed token, uint256 validations);
    event FirstSortRejected(address indexed token, uint256 rejections);
    event FinalDecisionValidated(address indexed token, uint256 validations);
    event FinalDecisionRejected(address indexed token, uint256 rejections);

    constructor(address _owner, address _mobulaTokenAddress) {
        owner = _owner;
        MOBL = IERC20(_mobulaTokenAddress);
    }

    // Getters for public arrays

    function getSubmittedTokens() external view returns (address[] memory) {
        return submittedTokens;
    }

    function getValidatedTokens() external view returns (address[] memory) {
        return validatedTokens;
    }

    //Protocol variables updaters

    function updateProtocolAPIAddress(address _protocolAPIAddress) external {
        require(owner == msg.sender, "Reserved to DAO.");
        ProtocolAPI = API(_protocolAPIAddress);
    }

    function updateSubmitPrice(uint256 _submitPrice) external {
        require(owner == msg.sender, "Reserved to DAO.");
        submitPrice = _submitPrice;
    }

    function updateFirstSortMaxVotes(uint256 _firstSortMaxVotes) external {
        require(owner == msg.sender, "Reserved to DAO.");
        firstSortMaxVotes = _firstSortMaxVotes;
    }

    function updateFinalDecisionMaxVotes(uint256 _finalDecisionMaxVotes)
        external
    {
        require(owner == msg.sender, "Reserved to DAO.");
        finalDecisionMaxVotes = _finalDecisionMaxVotes;
    }

    function updateFirstSortValidationsNeeded(
        uint256 _firstSortValidationsNeeded
    ) external {
        require(owner == msg.sender, "Reserved to DAO.");
        firstSortValidationsNeeded = _firstSortValidationsNeeded;
    }

    function updateFinalDecisionValidationsNeeded(
        uint256 _finalDecisionValidationsNeeded
    ) external {
        require(owner == msg.sender, "Reserved to DAO.");
        finalDecisionValidationsNeeded = _finalDecisionValidationsNeeded;
    }

    function updateTokensPerVote(uint256 _tokensPerVote) external {
        require(owner == msg.sender, "Reserved to DAO.");
        tokensPerVote = _tokensPerVote;
    }

    function updateMembersToPromoteToRankI(uint256 _membersToPromoteToRankI)
        external
    {
        require(owner == msg.sender, "Reserved to DAO.");
        membersToPromoteToRankI = _membersToPromoteToRankI;
    }

    function updateMembersToPromoteToRankII(uint256 _membersToPromoteToRankII)
        external
    {
        require(owner == msg.sender, "Reserved to DAO.");
        membersToPromoteToRankII = _membersToPromoteToRankII;
    }

    function updateMembersToDemoteFromRankI(uint256 _membersToDemoteToRankI)
        external
    {
        require(owner == msg.sender, "Reserved to DAO.");
        membersToDemoteFromRankI = _membersToDemoteToRankI;
    }

    function updateMembersToDemoteFromRankII(uint256 _membersToDemoteToRankII)
        external
    {
        require(owner == msg.sender, "Reserved to DAO.");
        membersToDemoteFromRankII = _membersToDemoteToRankII;
    }

    function updateVotesNeededToRankIPromotion(
        uint256 _votesNeededToRankIPromotion
    ) external {
        require(owner == msg.sender, "Reserved to DAO.");
        votesNeededToRankIPromotion = _votesNeededToRankIPromotion;
    }

    function updateVotesNeededToRankIIPromotion(
        uint256 _votesNeededToRankIIPromotion
    ) external {
        require(owner == msg.sender, "Reserved to DAO.");
        votesNeededToRankIIPromotion = _votesNeededToRankIIPromotion;
    }

    function updateVotesNeededToRankIDemotion(
        uint256 _votesNeededToRankIDemotion
    ) external {
        require(owner == msg.sender, "Reserved to DAO.");
        votesNeededToRankIDemotion = _votesNeededToRankIDemotion;
    }

    function updateVotesNeededToRankIIDemotion(
        uint256 _votesNeededToRankIIDemotion
    ) external {
        require(owner == msg.sender, "Reserved to DAO.");
        votesNeededToRankIIDemotion = _votesNeededToRankIIDemotion;
    }

    //Protocol data processing

    function submitIPFS(address token, string memory hashString)
        external
        payable
    {
        require(msg.value >= submitPrice, "You must pay the submit fee.");
        require(
            bytes(submittedData[token]).length == 0,
            "The token has already been submitted."
        );
        require(
            bytes(firstSortValidated[token]).length == 0,
            "The token has already been submitted."
        );
        require(
            bytes(ProtocolAPI.staticData(token)).length == 0,
            "The token has already been submitted."
        );
        indexOfSubmittedTokens[token] = submittedTokens.length;
        submittedTokens.push(token);
        submittedData[token] = hashString;
        emit DataSubmitted(token, hashString);
    }

    function firstSortVote(address token, bool validate) external {
        require(rank[msg.sender] >= 1, "You must be Rank I or higher to vote.");
        require(
            bytes(submittedData[token]).length > 0,
            "You can only vote for submitted tokens."
        );
        require(
            !firstSortVotes[msg.sender][token],
            "You cannot vote twice for the same token."
        );

        firstSortVotes[msg.sender][token] = true;

        if (validate) {
            tokenFirstValidations[token].push(msg.sender);
        } else {
            tokenFirstRejections[token].push(msg.sender);
        }

        if (
            tokenFirstValidations[token].length +
                tokenFirstRejections[token].length ==
            firstSortMaxVotes
        ) {
            if (
                tokenFirstValidations[token].length >=
                firstSortValidationsNeeded
            ) {
                firstSortValidated[token] = submittedData[token];
                indexOfValidatedTokens[token] = validatedTokens.length;
                validatedTokens.push(token);
                emit FirstSortValidated(
                    token,
                    tokenFirstValidations[token].length
                );
            } else {
                emit FirstSortRejected(
                    token,
                    tokenFirstRejections[token].length
                );
            }

            submittedTokens[indexOfSubmittedTokens[token]] = submittedTokens[
                submittedTokens.length - 1
            ];
            indexOfSubmittedTokens[
                submittedTokens[submittedTokens.length - 1]
            ] = indexOfSubmittedTokens[token];
            submittedTokens.pop();
            delete submittedData[token];
        }
    }

    function finalDecisionVote(address token, bool validate) external {
        require(
            rank[msg.sender] >= 2,
            "You must be Rank II or higher to vote."
        );
        require(
            bytes(firstSortValidated[token]).length > 0,
            "You can only vote for submitted tokens."
        );
        require(
            !finalDecisionVotes[msg.sender][token],
            "You cannot vote twice for the same token."
        );

        finalDecisionVotes[msg.sender][token] = true;

        if (validate) {
            tokenFinalValidations[token]++;
        } else {
            tokenFinalRejections[token]++;
        }

        if (
            tokenFinalValidations[token] + tokenFinalRejections[token] ==
            finalDecisionMaxVotes
        ) {
            if (
                tokenFinalValidations[token] >= finalDecisionValidationsNeeded
            ) {
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[token].length;
                    i++
                ) {
                    goodFirstVotes[tokenFirstValidations[token][i]]++;
                }

                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[token].length;
                    i++
                ) {
                    badFirstVotes[tokenFirstRejections[token][i]]++;
                }

                ProtocolAPI.addStaticData(token, firstSortValidated[token]);

                emit FinalDecisionValidated(
                    token,
                    tokenFinalValidations[token]
                );
            } else {
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[token].length;
                    i++
                ) {
                    badFirstVotes[tokenFirstValidations[token][i]]++;
                }

                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[token].length;
                    i++
                ) {
                    goodFirstVotes[tokenFirstRejections[token][i]]++;
                }

                emit FinalDecisionRejected(token, tokenFinalRejections[token]);
            }

            validatedTokens[indexOfValidatedTokens[token]] = validatedTokens[
                validatedTokens.length - 1
            ];
            indexOfValidatedTokens[
                validatedTokens[validatedTokens.length - 1]
            ] = indexOfValidatedTokens[token];
            validatedTokens.pop();
            delete firstSortValidated[token];
        }
    }

    function claimRewards() external {
        uint256 amountToPay = (goodFirstVotes[msg.sender] -
            paidFirstVotes[msg.sender]) * tokensPerVote;
        require(amountToPay > 0, "You don't have anything to claim.");
        paidFirstVotes[msg.sender] = goodFirstVotes[msg.sender];
        MOBL.transfer(msg.sender, amountToPay);
    }

    // Hierarchy management

    function emergencyPromote(address promoted) external {
        require(owner == msg.sender, "Only the DAO can promote like this.");
        require(rank[promoted] <= 1, "Impossible to promote to Rank III.");
        rank[promoted]++;
    }

    function emergencyDemote(address demoted) external {
        require(owner == msg.sender, "Only the DAO can demote like this.");
        require(rank[demoted] >= 1, "Impossible to demote from Rank 0.");
        rank[demoted]--;
    }

    function promote(address promoted) external {
        require(
            rank[msg.sender] >= 2,
            "You must be Rank II or higher to promote."
        );
        require(rank[promoted] <= 1, "Impossible to promote to Rank III.");

        if (rank[promoted] == 0) {
            require(
                membersToPromoteToRankI > 0,
                "There is no member to promote to Rank I yet."
            );
            promoteVotes[promoted]++;

            if (promoteVotes[promoted] == votesNeededToRankIPromotion) {
                membersToPromoteToRankI--;
                delete promoteVotes[promoted];
                rank[promoted]++;
            }
        } else {
            require(
                membersToPromoteToRankII > 0,
                "There is no member to promote to Rank II yet."
            );
            promoteVotes[promoted]++;

            if (promoteVotes[promoted] == votesNeededToRankIIPromotion) {
                membersToPromoteToRankII--;
                delete promoteVotes[promoted];
                rank[promoted]++;
            }
        }
    }

    function demote(address demoted) external {
        require(
            rank[msg.sender] >= 2,
            "You must be Rank II or higher to demote."
        );
        require(rank[demoted] >= 1, "Impossible to demote from Rank 0.");

        if (rank[demoted] == 0) {
            require(
                membersToDemoteFromRankI > 0,
                "There is no member to demote to Rank I yet."
            );
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                membersToDemoteFromRankI--;
                delete demoteVotes[demoted];
                rank[demoted]++;
            }
        } else {
            require(
                membersToDemoteFromRankII > 0,
                "There is no member to demote to Rank II yet."
            );
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIIDemotion) {
                membersToDemoteFromRankII--;
                delete demoteVotes[demoted];
                rank[demoted]--;
            }
        }
    }

    // Funds management

    function withdrawFunds(uint256 amount) external {
        require(
            owner == msg.sender,
            "Only the DAO can withdraw funds like this."
        );
        payable(msg.sender).transfer(amount);
    }
}