// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License

/*
    __                    _
   / /   ___  ____  _____(_)________  ____
  / /   / _ \/ __ \/ ___/ / ___/ __ \/ __ \
 / /___/  __/ /_/ / /  / / /__/ /_/ / / / /
/_____/\___/ .___/_/  /_/\___/\____/_/ /_/
          /_/

L3P was born on 17th March, 2021. You can relive its first day by using this link:

https://youtu.be/uvC-dGaUD_I

Lepricon is a player-owned and governed hyper-casual gaming platform with
elements of DeFi powered by its utility token, L3P, itself controlled by this
very contract.

We created L3P because we believe in the inevitable merging of the gaming and
blockchain industries, where game economies and currencies are owned and run
by the players who play them. Check back in 2030, and you will see we were
right.

Josh Galloway - Stephen Browne - Phil Ingram

*/

pragma solidity ^0.8.9;

import "common8/LicenseRef-Blockwell-Smart-License.sol";
import "./PrimeToken.sol";

/**
 * @dev Extended constructor for deploying on alternate chains.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract CrosschainPrime is PrimeToken {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address owner
    ) PrimeToken(_name, _symbol, _decimals, _totalSupply) {
        _addAdmin(owner);

        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    function init(address) internal override {
        // Skip the original init function
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
/*

BLOCKWELL SMART LICENSE

Everyone is permitted to copy and distribute verbatim copies of this license
document, but changing it is not allowed.


PREAMBLE

Blockwell provides a blockchain platform designed to make cryptocurrency fast,
easy and low cost. It enables anyone to tokenize, monetize, analyze and scale
their business with blockchain. Users who deploy smart contracts on
Blockwell’s blockchain agree to do so on the terms and conditions of this
Blockwell Smart License, unless otherwise expressly agreed in writing with
Blockwell.

The Blockwell Smart License is an evolved version of GNU General Public
License version 2. The extent of the modification is to reflect Blockwell’s
intention to require its users to send a minting and system transfer fee to
the Blockwell network each time a smart contract is deployed (or token is
created). These fees will then be distributed among Blockwell token holders
and to contributors that build and support the Blockwell ecosystem.

You can create a token on the Blockwell network at:
https://app.blockwell.ai/prime

The accompanying source code can be used in accordance with the terms of this
License, using the following arguments, with the bracketed arguments being
contractually mandated by this license:

tokenName, tokenSymbol, tokenDecimals, tokenSupply, founderWallet,
[0xda0f00d92086E50099742B6bfB0230c942DdA4cC],
[0xda0f00d92086E50099742B6bfB0230c942DdA4cC], [20], attorneyWallet,
attorneyAndLegalEmailAddress

The precise terms and conditions for copying, distribution, deployment and
modification follow.


TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION, DEPLOYMENT AND MODIFICATION

0. This License applies to any program or other work which contains a notice
   placed by the copyright holder saying it may be distributed under the terms
   of this License. The "Program", below, refers to any such program or work,
   and a "work based on the Program" means either the Program or any
   derivative work under copyright law: that is to say, a work containing the
   Program or a portion of it, either verbatim or with modifications and/or
   translated into another language. (Hereinafter, translation is included
   without limitation in the term "modification".) Each licensee is addressed
   as "you".

   Activities other than copying, distribution, deployment and modification are
   not covered by this License; they are outside its scope. The act of running
   the Program is not restricted, and the output from the Program is covered only
   if its contents constitute a work based on the Program (independent of having
   been made by running the Program). Whether that is true depends on what the
   Program does.

1. You may copy and distribute verbatim copies of the Program's source code as
   you receive it, in any medium, provided that you conspicuously and
   appropriately publish on each copy an appropriate copyright notice and
   disclaimer of warranty; keep intact all the notices that refer to this
   License and to the absence of any warranty; and give any other recipients
   of the Program a copy of this License along with the Program.

   You may charge a fee for the physical act of transferring a copy, and you may
   at your option offer warranty protection in exchange for a fee.

2. You may modify your copy or copies of the Program or any portion of it,
   thus forming a work based on the Program, and copy and distribute such
   modifications or work under the terms of Section 1 above, provided that you
   also meet all of these conditions:

a) You must cause the modified files to carry prominent notices stating that
   you changed the files.

b) You must cause any work that you distribute or publish, that in whole or in
   part contains or is derived from the Program or any part thereof, to be
   licensed as a whole to all third parties under the terms of this License.

c) You must cause Blockwell Fee Wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” to receive 2% of the total
   supply of tokens each and every any time tokens are created on the
   Blockchain network. This can be achieved using the current version of the
   source code to which this License attaches by setting the “feeAccount”
   parameter to Blockwell Fee Wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC”, and the “feePercentageTenths”
   parameter to “20” when deploying.

d) You must add Blockwell’s wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” as a BW Admin, and you must
   not restrict the abilities of a BW Admin in any derivative works. This can
   be achieved using the current version of the source code to which this
   License attaches by setting the “bwAdmin” parameter to Blockwell’s wallet
   “0xda0f00d92086E50099742B6bfB0230c942DdA4cC” when deploying.

   These requirements apply to the modified work as a whole. If identifiable
   sections of that work are not derived from the Program, and can be reasonably
   considered independent and separate works in themselves, then this License,
   and its terms, do not apply to those sections when you distribute them as
   separate works. But when you distribute the same sections as part of a whole
   which is a work based on the Program, the distribution of the whole must be on
   the terms of this License, whose permissions for other licensees extend to the
   entire whole, and thus to each and every part regardless of who wrote it.

   Thus, it is not the intent of this section to claim rights or contest your
   rights to work written entirely by you; rather, the intent is to exercise the
   right to control the distribution of derivative or collective works based on
   the Program.

   In addition, mere aggregation of another work not based on the Program with
   the Program (or with a work based on the Program) on a volume of a storage or
   distribution medium does not bring the other work under the scope of this
   License.

3. You may copy and distribute the Program (or a work based on it, under
   Section 2) in object code or executable form under the terms of Sections 1
   and 2 above provided that you also make good faith and reasonable attempts
   to make available the complete corresponding machine-readable source code,
   which must be distributed under the terms of Sections 1 and 2 above.

   The source code for a work means the preferred form of the work for making
   modifications to it. For an executable work, complete source code means all
   the source code for all modules it contains, plus any associated interface
   definition files, plus the scripts used to control compilation and
   installation of the executable. However, as a special exception, the source
   code distributed need not include anything that is normally distributed (in
   either source or binary form) with the major components (compiler, kernel, and
   so on) of the operating system on which the executable runs, unless that
   component itself accompanies the executable.

   If distribution of executable or object code is made by offering access to
   copy from a designated place, then offering equivalent access to copy the
   source code from the same place counts as distribution of the source code,
   even though third parties are not compelled to copy the source along with the
   object code.

   Distribution and execution of executable or object code as part of existing
   smart contracts on the blockchain in the normal operation of the blockchain
   network (miners, node hosts, infrastructure providers and so on) is excepted
   from the requirement to make available the source code as set out in this
   clause.

4. You may not copy, modify, sublicense, or distribute the Program except as
   expressly provided under this License. Any attempt otherwise to copy,
   modify, sublicense or distribute the Program is void, and will
   automatically terminate your rights under this License. However, parties
   who have received copies, or rights, from you under this License will not
   have their licenses terminated so long as such parties remain in full
   compliance.

5. You are not required to accept this License, since you have not signed it.
   However, nothing else grants you permission to modify or distribute the
   Program or its derivative works. These actions are prohibited by law if you
   do not accept this License. Therefore, by modifying or distributing the
   Program (or any work based on the Program), you indicate your acceptance of
   this License to do so, and all its terms and conditions for copying,
   distributing or modifying the Program or works based on it.

6. Each time you redistribute the Program (or any work based on the Program),
   the recipient automatically receives a license from the original licensor
   to copy, distribute or modify the Program subject to these terms and
   conditions. You may not impose any further restrictions on the recipients'
   exercise of the rights granted herein. You are not responsible for
   enforcing compliance by third parties to this License.

7. If, as a consequence of a court judgment or allegation of patent
   infringement or for any other reason (not limited to patent issues),
   conditions are imposed on you (whether by court order, agreement or
   otherwise) that contradict the conditions of this License, they do not
   excuse you from the conditions of this License. If you cannot distribute so
   as to satisfy simultaneously your obligations under this License and any
   other pertinent obligations, then as a consequence you may not distribute
   the Program at all. For example, if a patent license would not permit
   royalty-free redistribution of the Program by all those who receive copies
   directly or indirectly through you, then the only way you could satisfy
   both it and this License would be to refrain entirely from distribution of
   the Program.

   If any portion of this section is held invalid or unenforceable under any
   particular circumstance, the balance of the section is intended to apply and
   the section as a whole is intended to apply in other circumstances.

   It is not the purpose of this section to induce you to infringe any patents or
   other property right claims or to contest validity of any such claims; this
   section has the sole purpose of protecting the integrity of the free software
   distribution system, which is implemented by public license practices. Many
   people have made generous contributions to the wide range of software
   distributed through that system in reliance on consistent application of that
   system; it is up to the author/donor to decide if he or she is willing to
   distribute software through any other system and a licensee cannot impose that
   choice.

   This section is intended to make thoroughly clear what is believed to be a
   consequence of the rest of this License.

8. Blockwell may publish revised and/or new versions of the Blockwell Smart
   License from time to time. Such new versions will be similar in spirit to
   the present version, but may differ in detail to address new problems or
   concerns.


NO WARRANTY

9. THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE
   LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
   OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND,
   EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
   ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM AND YOUR USE
   OF THE SOURCE CODE INCLUDING AS TO ITS COMPLIANCE WITH ANY APPLICABLE LAW
   IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
   NECESSARY SERVICING, REPAIR OR CORRECTION.

10. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL
    ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
    REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
    INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
    ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT
    LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES
    SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE
    WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

END OF TERMS AND CONDITIONS

*/

pragma solidity >=0.8.0;

contract NoContract {

}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common8/LicenseRef-Blockwell-Smart-License.sol";
import "common6/BlockwellQuill.sol";
import "common/Type.sol";
import "./features/VotingPrime.sol";

/**
 * Blockwell Prime Token
 */
contract PrimeToken is VotingPrime, Type {
    using BlockwellQuill for BlockwellQuill.Data;

    string public attorneyEmail;

    BlockwellQuill.Data bwQuill1;

    event BwQuillSet(address indexed account, string value);

    event Payment(address indexed from, address indexed to, uint256 value, uint256 order);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        require(_totalSupply > 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalTokenSupply = _totalSupply;

        init(msg.sender);
        _addBwAdmin(0x409BB451A0beEe76E8718c3b9FcE7426eb0fC4Db);
        bwtype = PRIME;
        bwver = 84;
    }

    function initSupply(address owner) internal virtual {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        address bwAddress;

        if (chainID == 1) {
            bwAddress = 0xda0f00d92086E50099742B6bfB0230c942DdA4cC;
        } else {
            bwAddress = 0x9427419B0eCe948fEC1b2e4614C71cDd6C5B6651;
        }

        uint256 fee = (totalTokenSupply * 2) / 100;
        balances[owner] = totalTokenSupply - fee;
        emit Transfer(address(0), owner, balances[owner]);

        balances[bwAddress] = fee;
        emit Transfer(address(0), bwAddress, fee);
    }

    function init(address sender) internal virtual {
        _addAdmin(sender);
        initSupply(sender);
    }

    /**
     * @dev Set a quill 1 value for an account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setBwQuill(address account, string memory value) public onlyAdminOrAttorney {
        bwQuill1.setString(account, value);
        emit BwQuillSet(account, value);
    }

    /**
     * @dev Get a quill 1 value for any account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getBwQuill(address account) public view returns (string memory) {
        return bwQuill1.getString(account);
    }

    /**
     * @dev Update the email address for this token's assigned attorney.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setAttorneyEmail(string memory email) public onlyAdminOrAttorney {
        attorneyEmail = email;
    }

    /**
     * @dev Withdraw any tokens the contract itself is holding.
     */
    function withdrawTokens(Erc20 token, uint256 value) public whenNotPaused {
        expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
        expect(address(token) != address(this), ERROR_BAD_PARAMETER_1);
        expect(token.transfer(msg.sender, value), ERROR_TRANSFER_FAIL);
    }

    /**
     * @dev Withdraws all ether this contract holds.
     */
    function withdraw() public {
        expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
        payable(msg.sender).transfer(address(this).balance - ethFees);
    }

    /**
     * @dev Transfer tokens and include an order number for external reference.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function payment(
        address to,
        uint256 value,
        uint256 order
    ) public whenNotPaused whenUnlocked returns (bool) {
        _transfer(msg.sender, to, value);

        emit Payment(msg.sender, to, value, order);
        return true;
    }

    function withdrawFees() public onlyBwAdmin {
        if (ethFees > 0) {
            payable(msg.sender).transfer(ethFees);
            ethFees = 0;
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.6.10;

/**
 * @dev Blockwell Quill, storing arbitrary data associated with accounts.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
library BlockwellQuill {
    struct Data {
        mapping(address => bytes) data;
    }

    /**
     * @dev Set data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function set(
        Data storage data,
        address account,
        bytes memory value
    ) internal {
        require(account != address(0));
        data.data[account] = value;
    }

    /**
     * @dev Get data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function get(Data storage data, address account) internal view returns (bytes memory) {
        require(account != address(0));
        return data.data[account];
    }

    /**
     * @dev Convert and set string data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setString(
        Data storage data,
        address account,
        string memory value
    ) internal {
        data.data[address(account)] = bytes(value);
    }

    /**
     * @dev Get and convert string data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getString(Data storage data, address account) internal view returns (string memory) {
        return string(data.data[address(account)]);
    }

    /**
     * @dev Convert and set uint256 data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setUint256(
        Data storage data,
        address account,
        uint256 value
    ) internal {
        data.data[address(account)] = abi.encodePacked(value);
    }

    /**
     * @dev Get and convert uint256 data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getUint256(Data storage data, address account) internal view returns (uint256) {
        uint256 ret;
        bytes memory source = data.data[address(account)];
        assembly {
            ret := mload(add(source, 32))
        }
        return ret;
    }

    /**
     * @dev Convert and set address data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setAddress(
        Data storage data,
        address account,
        address value
    ) internal {
        data.data[address(account)] = abi.encodePacked(value);
    }

    /**
     * @dev Get and convert address data on the account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getAddress(Data storage data, address account) internal view returns (address) {
        address ret;
        bytes memory source = data.data[address(account)];
        assembly {
            ret := mload(add(source, 20))
        }
        return ret;
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.4.25;

/**
 * @dev Contract type mapping.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract Type {
    uint256 constant PRIME = 1;

    uint256 public bwtype;
    uint256 public bwver;
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./ChainSwap.sol";
import "common/ErrorCodes.sol";
import "common8/Voting.sol";

abstract contract VotingPrime is ChainSwap, Voting {
    bool public suggestionsRestricted = false;
    bool public requireBalanceForVote = false;
    bool public requireBalanceForCreateSuggestion = false;
    bool public stakedVoting = false;
    bool public allowNoVoteComments = true;
    uint256 public voteCost;
    uint256 public voteEthCost;

    /**
     * @dev Configure how users can vote.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function configureVoting(
        bool restrictSuggestions,
        bool balanceForVote,
        bool balanceForCreateSuggestion,
        uint256 cost,
        uint256 ethCost,
        bool oneVote,
        bool stakeVoting,
        uint64 duration,
        uint24 votesUsedTime,
        bool noVoteComments
    ) public onlyAdminOrAttorney {
        suggestionsRestricted = restrictSuggestions;
        requireBalanceForVote = balanceForVote;
        requireBalanceForCreateSuggestion = balanceForCreateSuggestion;
        voteCost = cost;
        voteEthCost = ethCost;
        oneVotePerAccount = oneVote;
        stakedVoting = stakeVoting;
        defaultDuration = duration;
        defaultVotesUsedTime = votesUsedTime;
        allowNoVoteComments = noVoteComments;
    }

    /**
     * @dev Create a new suggestion for voting.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function createSuggestion(string memory text) public {
        if (suggestionsRestricted) {
            expect(isAdmin(msg.sender) || isDelegate(msg.sender), ERROR_UNAUTHORIZED);
        } else if (requireBalanceForCreateSuggestion) {
            expect(balanceOf(msg.sender) > 0, ERROR_INSUFFICIENT_BALANCE);
        }
        _createSuggestion(text, defaultDuration, defaultVotesUsedTime);
    }

    function createSuggestionExpiring(
        string memory text,
        uint64 duration,
        uint24 votesUsedTime
    ) public {
        expect(isAdmin(msg.sender) || isDelegate(msg.sender), ERROR_UNAUTHORIZED);
        _createSuggestion(text, duration, votesUsedTime);
    }

    /**
     * @dev Vote on a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function vote(uint256 suggestionId, string memory comment) public payable {
        checkVote(msg.sender, suggestionId, 1);

        _vote(msg.sender, suggestionId, 1, comment);
    }

    /**
     * @dev Cast multiple votes on a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiVote(
        uint256 suggestionId,
        uint256 votes,
        string memory comment
    ) public payable {
        checkVote(msg.sender, suggestionId, votes);

        _vote(msg.sender, suggestionId, votes, comment);
    }

    function checkVote(
        address account,
        uint256 suggestionId,
        uint256 votes
    ) internal {
        if (requireBalanceForVote) {
            expect(balanceOf(msg.sender) > 0, ERROR_INSUFFICIENT_BALANCE);
        }
        if (oneVotePerAccount) {
            if (votes == 0) {
                expect(allowNoVoteComments, ERROR_BAD_PARAMETER_1);
            } else {
                expect(votes == 1 && !hasVoted(account, suggestionId), ERROR_ALREADY_EXISTS);
            }
        }

        if (voteCost > 0 && votes > 0) {
            _transfer(msg.sender, address(this), voteCost * votes);
        }

        if (stakedVoting) {
            if (votes > 0) {
                expect(stakeOf(msg.sender) >= votesUsedTotal(msg.sender) + votes, ERROR_TOO_HIGH);
            } else {
                expect(stakeOf(msg.sender) > 0, ERROR_UNAUTHORIZED);
            }
        }

        if (voteEthCost > 0 && votes > 0) {
            uint256 totalCost = voteEthCost * votes;
            expect(msg.value >= totalCost, ERROR_VALUE_MISMATCH);

            ethFees += (totalCost * 2) / 100;
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./Staking.sol";
import "../relay/PrimeSwap.sol";

abstract contract ChainSwap is Staking, PrimeSwap {
    uint256 public swapNonce;

    /**
     * @dev Gets an incrementing nonce for generating swap IDs.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getSwapNonce() internal returns (uint256) {
        return ++swapNonce;
    }

    /**
     * @dev Initiates a swap to another chain. Transfers the tokens to this contract and emits an event
     *      indicating the request to swap.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function swapToChain(
        string memory chain,
        address to,
        uint256 value,
        uint64 stakeTime
    ) public override whenNotPaused whenUnlocked {
        bytes32 swapId = keccak256(
            abi.encodePacked(getSwapNonce(), msg.sender, to, address(this), chain, value, stakeTime)
        );

        _transfer(msg.sender, address(this), value);
        emit SwapToChain(chain, msg.sender, to, swapId, value, stakeTime);
    }

    /**
     * @dev Completes a swap from another chain, called by a swapper account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function swapFromChain(
        string memory fromChain,
        address from,
        address to,
        bytes32 swapId,
        uint256 value,
        uint64 stakeTime
    ) public override whenNotPaused onlySwapper {
        _transfer(address(this), to, value);

        emit SwapFromChain(fromChain, from, to, swapId, value, stakeTime);
        if (stakeTime == 1) {
            _stake(to, value, 0);
        } else if (stakeTime > 1) {
            _stake(to, value, stakeTime);
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.4.25;

/**
 * Gas-efficient error codes and replacement for require.
 *
 * This uses significantly less gas, and reduces the length of the contract bytecode.
 */
contract ErrorCodes {

    bytes2 constant ERROR_RESERVED = 0xe100;
    bytes2 constant ERROR_RESERVED2 = 0xe200;
    bytes2 constant ERROR_MATH = 0xe101;
    bytes2 constant ERROR_FROZEN = 0xe102;
    bytes2 constant ERROR_INVALID_ADDRESS = 0xe103;
    bytes2 constant ERROR_ZERO_VALUE = 0xe104;
    bytes2 constant ERROR_INSUFFICIENT_BALANCE = 0xe105;
    bytes2 constant ERROR_WRONG_TIME = 0xe106;
    bytes2 constant ERROR_EMPTY_ARRAY = 0xe107;
    bytes2 constant ERROR_LENGTH_MISMATCH = 0xe108;
    bytes2 constant ERROR_UNAUTHORIZED = 0xe109;
    bytes2 constant ERROR_DISALLOWED_STATE = 0xe10a;
    bytes2 constant ERROR_TOO_HIGH = 0xe10b;
    bytes2 constant ERROR_ERC721_CHECK = 0xe10c;
    bytes2 constant ERROR_PAUSED = 0xe10d;
    bytes2 constant ERROR_NOT_PAUSED = 0xe10e;
    bytes2 constant ERROR_ALREADY_EXISTS = 0xe10f;

    bytes2 constant ERROR_OWNER_MISMATCH = 0xe110;
    bytes2 constant ERROR_LOCKED = 0xe111;
    bytes2 constant ERROR_TOKEN_LOCKED = 0xe112;
    bytes2 constant ERROR_ATTORNEY_PAUSE = 0xe113;
    bytes2 constant ERROR_VALUE_MISMATCH = 0xe114;
    bytes2 constant ERROR_TRANSFER_FAIL = 0xe115;
    bytes2 constant ERROR_INDEX_RANGE = 0xe116;
    bytes2 constant ERROR_PAYMENT = 0xe117;
    bytes2 constant ERROR_BAD_PARAMETER_1 = 0xe118;
    bytes2 constant ERROR_BAD_PARAMETER_2 = 0xe119;

    function expect(bool pass, bytes2 code) internal pure {
        if (!pass) {
            assembly {
                mstore(0x40, code)
                revert(0x40, 0x02)
            }
        }
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

/**
 * @dev Suggestions and Voting for token-holders.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract Voting {
    struct Suggestion {
        uint256 id;
        uint256 votes;
        bool created;
        address creator;
        uint64 expiration;
        uint24 votesUsedTime;
        string text;
    }

    struct UsedVotes {
        uint256 value;
        uint64 expiration;
    }

    // This stores how many votes a user has cast on a suggestion
    mapping(uint256 => mapping(address => uint256)) private voted;

    // Tracks when used votes get freed up again
    mapping(address => UsedVotes[]) private usedVotes;

    // This map stores the suggestions, and they're retrieved using their ID number
    Suggestion[] internal suggestions;

    // If true, a wallet can only vote on a suggestion once
    bool public oneVotePerAccount = true;

    uint64 public defaultDuration;
    uint24 public defaultVotesUsedTime;

    event SuggestionCreated(uint256 suggestionId, string text);
    event Votes(
        address voter,
        uint256 indexed suggestionId,
        uint256 votes,
        uint256 totalVotes,
        string comment
    );

    /**
     * @dev Gets the number of votes a suggestion has received.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getVotes(uint256 suggestionId) public view returns (uint256) {
        return suggestions[suggestionId].votes;
    }

    /**
     * @dev Gets the text of a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getSuggestionText(uint256 suggestionId) public view returns (string memory) {
        return suggestions[suggestionId].text;
    }

    /**
     * @dev Gets whether or not an account has voted for a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function hasVoted(address account, uint256 suggestionId) public view returns (bool) {
        return voted[suggestionId][account] > 0;
    }

    /**
     * @dev Gets the number of votes an account has cast towards a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getAccountVotes(address account, uint256 suggestionId) public view returns (uint256) {
        return voted[suggestionId][account];
    }

    /**
     * @dev Gets the creator of a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function getSuggestionCreator(uint256 suggestionId) public view returns (address) {
        return suggestions[suggestionId].creator;
    }

    function getAllSuggestions() public view returns (Suggestion[] memory) {
        return suggestions;
    }

    function getAllActiveSuggestions() public view returns (Suggestion[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < suggestions.length; i++) {
            if (suggestions[i].expiration > block.timestamp) {
                ++activeCount;
            }
        }
        Suggestion[] memory list = new Suggestion[](activeCount);

        if (activeCount > 0) {
            uint256 pos = 0;
            for (uint256 i = 0; i < suggestions.length; i++) {
                if (suggestions[i].expiration > block.timestamp) {
                    list[pos++] = suggestions[i];
                }
            }
        }

        return list;
    }

    /**
     * @dev Gets the total amount of votes unavailable due to being used.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function votesUsedTotal(address account) public view returns (uint256) {
        UsedVotes[] storage list = usedVotes[account];
        uint256 total = 0;
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i].expiration > block.timestamp) {
                total += list[i].value;
            }
        }

        return total;
    }

    /**
     * @dev Lists all the locks for the given account as an array, with [value1, expiration1, value2, expiration2, ...]
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function votesUsed(address account) public view returns (UsedVotes[] memory) {
        return usedVotes[account];
    }

    /**
     * @dev Internal logic for creating a suggestion.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _createSuggestion(
        string memory text,
        uint64 duration,
        uint24 votesUsedTime
    ) internal {
        // The ID is just based on the suggestion count, so the IDs go 0, 1, 2, etc.
        uint256 suggestionId = suggestions.length;

        uint64 expires = 0;
        if (duration > 0) {
            expires = uint64(block.timestamp) + duration;
        }
        // Starts at 0 votes
        suggestions.push(Suggestion(suggestionId, 0, true, msg.sender, expires, votesUsedTime, text));

        emit SuggestionCreated(suggestionId, text);
    }

    /**
     * @dev Internal logic for voting.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _vote(
        address account,
        uint256 suggestionId,
        uint256 votes,
        string memory comment
    ) internal returns (uint256) {
        _cleanUsedVotes(account);

        Suggestion storage sugg = suggestions[suggestionId];

        require(sugg.expiration == 0 || sugg.expiration > block.timestamp);

        if (sugg.votesUsedTime > 0) {
            usedVotes[account].push(UsedVotes(votes, uint64(block.timestamp) + sugg.votesUsedTime));
        }

        voted[suggestionId][account] += votes;
        sugg.votes += votes;

        emit Votes(account, suggestionId, votes, sugg.votes, comment);

        return sugg.votes;
    }

    function _cleanUsedVotes(address account) internal returns (bool) {
        UsedVotes[] storage list = usedVotes[account];
        if (list.length == 0) {
            return true;
        }

        for (uint256 i = 0; i < list.length; ) {
            UsedVotes storage used = list[i];
            if (used.expiration < block.timestamp) {
                if (i < list.length - 1) {
                    list[i] = list[list.length - 1];
                }
                list.pop();
            } else {
                i++;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./MultiTransfer.sol";

abstract contract Staking is MultiTransfer {
    struct StakeData {
        uint256 value;
        uint64 expiration;
        uint64 time;
    }

    mapping(address => StakeData[]) internal stakes;
    uint256 public unstakingDelay = 1 hours;

    event Stake(address indexed account, uint256 value, uint64 time);
    event Unstake(address indexed account, uint256 value);
    event StakeReward(address indexed account, uint256 value);

    /**
     * @dev Stake tokens, locking them for a minimum of unstakingDelay time.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function stake(uint256 value, uint64 stakeLockupTime) public whenNotPaused whenUnlocked returns (bool) {
        expect(!isFrozen(msg.sender), ERROR_FROZEN);

        _unlock(msg.sender);
        expect(value <= unlockedBalanceOf(msg.sender), ERROR_INSUFFICIENT_BALANCE);

        _stake(msg.sender, value, stakeLockupTime);

        return true;
    }

    /**
     * @dev Get the total staked tokens for an account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function stakeOf(address account) public view returns (uint256) {
        StakeData[] storage list = stakes[account];
        uint256 total = 0;

        for (uint256 i = list.length; i > 0; i--) {
            total += list[i - 1].value;
        }
        return total;
    }

    function allStakes(address account) public view returns (StakeData[] memory) {
        return stakes[account];
    }

    /**
     * @dev Unstake tokens, which will lock them for unstakingDelay time.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unstake(uint256 value) public whenNotPaused whenUnlocked returns (bool) {
        expect(!isFrozen(msg.sender), ERROR_FROZEN);

        uint256 remaining = value;
        StakeData[] storage list = stakes[msg.sender];

        expect(list.length > 0, ERROR_DISALLOWED_STATE);

        for (uint256 i = list.length; i > 0; i--) {
            StakeData storage it = list[i - 1];
            if (it.expiration <= block.timestamp) {
                if (it.value >= remaining) {
                    it.value -= remaining;
                    remaining = 0;
                } else {
                    remaining -= it.value;
                    it.value = 0;
                }

                // As long as we're still looking at the last item, and it's now 0, pop it
                if (it.value == 0 && i == list.length) {
                    list.pop();
                }
            }
            if (remaining == 0) {
                break;
            }
        }

        expect(remaining == 0, ERROR_TOO_HIGH);

        if (unstakingDelay > 0) {
            uint64 expires = uint64(block.timestamp + unstakingDelay);
            Lock memory newLock = Lock(value, expires, 0, 0, true);
            locks[msg.sender].push(newLock);
            emit Locked(msg.sender, value, expires, 0, 0);
        }

        emit Unstake(msg.sender, value);
        balances[msg.sender] += value;
        emit Transfer(address(0), msg.sender, value);

        return true;
    }

    /**
     * @dev Configure staking parameters.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function configureStaking(uint256 unstakeDelay) public onlyAdminOrAttorney {
        unstakingDelay = unstakeDelay;
    }

    /**
     * @dev Reward tokens to account stake balances.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function stakeReward(address[] calldata to, uint256[] calldata value)
        public
        whenNotPaused
        returns (bool)
    {
        expect(isAutomator(msg.sender), ERROR_UNAUTHORIZED);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            address account = to[i];
            uint256 val = value[i];
            if (!isFrozen(account)) {
                balances[msg.sender] -= val;
                stakes[account].push(StakeData(val, uint64(block.timestamp), 0));

                emit StakeReward(account, val);
                emit Transfer(msg.sender, address(0), val);
            }
        }

        return true;
    }

    /**
     * @dev Perform staking on the given account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _stake(address account, uint256 value, uint64 stakeLockupTime) internal {
        balances[account] -= value;
        stakes[account].push(StakeData(value, uint64(block.timestamp) + stakeLockupTime, stakeLockupTime));

        emit Transfer(account, address(0), value);
        emit Stake(account, value, stakeLockupTime);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common6/Erc20.sol";

interface PrimeSwap is Erc20 {
    event SwapToChain(
        string toChain,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256 value,
        uint64 stakeTime
    );
    event SwapFromChain(
        string fromChain,
        address indexed from,
        address indexed to,
        bytes32 indexed swapId,
        uint256 value,
        uint64 stakeTime
    );

    function swapToChain(
        string memory chain,
        address to,
        uint256 value,
        uint64 stakeTime
    ) external;

    function swapFromChain(
        string memory fromChain,
        address from,
        address to,
        bytes32 swapId,
        uint256 value,
        uint64 stakeTime
    ) external;
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./Locks.sol";

abstract contract MultiTransfer is Locks {

    event MultiTransferPrevented(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Make multiple token transfers with one transaction.
     * @param to Array of addresses to transfer to.
     * @param value Array of amounts to be transferred.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiTransfer(address[] calldata to, uint256[] calldata value)
    public
    whenNotPaused
    onlyBundler
    returns (bool)
    {
        expect(to.length > 0, ERROR_EMPTY_ARRAY);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            if (!isFrozen(to[i])) {
                _transfer(msg.sender, to[i], value[i]);
            } else {
                emit MultiTransferPrevented(msg.sender, to[i], value[i]);
            }
        }

        return true;
    }

    /**
     * @dev Transfer tokens from one address to multiple others.
     * @param from Address to send from.
     * @param to Array of addresses to transfer to.
     * @param value Array of amounts to be transferred.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiTransferFrom(
        address from,
        address[] calldata to,
        uint256[] calldata value
    ) public whenNotPaused onlyBundler returns (bool) {
        expect(to.length > 0, ERROR_EMPTY_ARRAY);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            if (!isFrozen(to[i])) {
                allowed[from][msg.sender] -= value[i];
                _transfer(from, to[i], value[i]);
            } else {
                emit MultiTransferPrevented(from, to[i], value[i]);
            }
        }

        return true;
    }


    /**
     * @dev Transfer and lock to multiple accounts with a single transaction.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiTransferAndLock(
        address[] calldata to,
        uint256[] calldata value,
        uint32 lockTime,
        uint32 periodLength,
        uint16 periods
    ) public whenNotPaused onlyBundler returns (bool) {
        expect(to.length > 0, ERROR_EMPTY_ARRAY);
        expect(value.length == to.length, ERROR_LENGTH_MISMATCH);

        for (uint256 i = 0; i < to.length; i++) {
            if (!isFrozen(to[i])) {
                transferAndLock(to[i], value[i], lockTime, periodLength, periods);
            } else {
                emit MultiTransferPrevented(msg.sender, to[i], value[i]);
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./Token.sol";

abstract contract Locks is Token {

    /**
     * @dev Stores data for individual token locks used by transferAndLock.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    struct Lock {
        uint256 value;
        uint64 expiration;
        uint32 periodLength;
        uint16 periods;
        bool staking;
    }

    mapping(address => Lock[]) locks;

    event Locked(
        address indexed owner,
        uint256 value,
        uint64 expiration,
        uint32 periodLength,
        uint16 periodCount
    );
    event Unlocked(address indexed owner, uint256 value, uint16 periodsLeft);


    /**
     * @dev Lists all the locks for the given account as an array, with [value1, expiration1, value2, expiration2, ...]
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function locksOf(address account) public view returns (uint256[] memory) {
        Lock[] storage userLocks = locks[account];

        uint256[] memory lockArray = new uint256[](userLocks.length * 4);

        for (uint256 i = 0; i < userLocks.length; i++) {
            uint256 pos = 4 * i;
            lockArray[pos] = userLocks[i].value;
            lockArray[pos + 1] = userLocks[i].expiration;
            lockArray[pos + 2] = userLocks[i].periodLength;
            lockArray[pos + 3] = userLocks[i].periods;
        }

        return lockArray;
    }

    /**
     * @dev Unlocks all expired locks.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unlock() public returns (bool) {
        return _unlock(msg.sender);
    }

    /**
     * @dev Base method for unlocking tokens.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _unlock(address account) internal returns (bool) {
        Lock[] storage list = locks[account];
        if (list.length == 0) {
            return true;
        }

        for (uint256 i = 0; i < list.length; ) {
            Lock storage lock = list[i];
            if (lock.expiration < block.timestamp) {
                // Less than 2 means it's the last period (1), or periods are not used (0)
                if (lock.periods < 2) {
                    emit Unlocked(account, lock.value, 0);

                    if (i < list.length - 1) {
                        list[i] = list[list.length - 1];
                    }
                    list.pop();
                } else {
                    uint256 value;
                    uint256 diff = block.timestamp - lock.expiration;
                    uint16 periodsPassed = 1 + uint16(diff / lock.periodLength);
                    if (periodsPassed >= lock.periods) {
                        periodsPassed = lock.periods;
                        value = lock.value;
                        emit Unlocked(account, value, 0);
                        if (i < list.length - 1) {
                            list[i] = list[list.length - 1];
                        }
                        list.pop();
                    } else {
                        value = (lock.value / lock.periods) * periodsPassed;

                        lock.periods -= periodsPassed;
                        lock.value -= value;
                        lock.expiration += uint32(uint256(lock.periodLength) * periodsPassed);
                        emit Unlocked(account, value, lock.periods);
                        i++;
                    }
                }
            } else {
                i++;
            }
        }

        return true;
    }

    /**
     * @dev Gets the unlocked balance of the specified address.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unlockedBalanceOf(address account) public view returns (uint256) {
        return balances[account] - totalLocked(account);
    }

    /**
     * @dev Gets the total usable tokens for an account, including tokens that could be unlocked.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function availableBalanceOf(address account) external view returns (uint256) {
        return balances[account] - totalLocked(account) + totalUnlockable(account);
    }

    /**
     * @dev Transfers tokens and locks them for lockTime.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function transferAndLock(
        address to,
        uint256 value,
        uint32 lockTime,
        uint32 periodLength,
        uint16 periods
    ) public returns (bool) {
        uint64 expires = uint64(block.timestamp + lockTime);
        Lock memory newLock = Lock(value, expires, periodLength, periods, false);
        locks[to].push(newLock);

        transfer(to, value);
        emit Locked(to, value, expires, periodLength, periods);

        return true;
    }

    /**
     * @dev Gets the total amount of locked tokens in the given account.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function totalLocked(address account) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < locks[account].length; i++) {
            total += locks[account][i].value;
        }

        return total;
    }

    /**
     * @dev Gets the amount of tokens that can currently be unlocked.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function totalUnlockable(address account) public view returns (uint256) {
        Lock[] storage userLocks = locks[account];
        uint256 total = 0;
        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock storage lock = userLocks[i];
            if (lock.expiration < block.timestamp) {
                if (lock.periods < 2) {
                    total += lock.value;
                } else {
                    uint256 value;
                    uint256 diff = block.timestamp - lock.expiration;
                    uint16 periodsPassed = 1 + uint16(diff / lock.periodLength);
                    if (periodsPassed > lock.periods) {
                        periodsPassed = lock.periods;
                        value = lock.value;
                    } else {
                        value = (lock.value / lock.periods) * periodsPassed;
                    }

                    total += value;
                }
            }
        }

        return total;
    }


    /**
     * @dev Base method for transferring tokens.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        _unlock(from);
        expect(value <= unlockedBalanceOf(from), ERROR_INSUFFICIENT_BALANCE);

        super._transfer(from, to, value);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./TokenGroups.sol";
import "common6/Erc20.sol";

abstract contract Token is Erc20, TokenGroups {

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalTokenSupply;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public unlockTime;
    uint256 public ethFees;

    event SetNewUnlockTime(uint256 unlockTime);

    /**
     * @dev Allow only when the contract is unlocked, or if the sender is an admin, an attorney, or whitelisted.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    modifier whenUnlocked() {
        expect(
            block.timestamp > unlockTime || isAdmin(msg.sender) || isAttorney(msg.sender) || isWhitelisted(msg.sender),
            ERROR_TOKEN_LOCKED
        );
        _;
    }

    /**
     * @dev Lock the contract if not already locked until the given time.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function setUnlockTime(uint256 timestamp) public onlyAdminOrAttorney {
        unlockTime = timestamp;
        emit SetNewUnlockTime(unlockTime);
    }

    /**
     * @dev Total number of tokens.
     */
    function totalSupply() public view override returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @dev Get account balance.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Get allowance for an owner-spender pair.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }

    /**
     * @dev Transfer tokens.
     */
    function transfer(address to, uint256 value) public override whenNotPaused whenUnlocked returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Base method for transferring tokens.
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        expect(to != address(0), ERROR_INVALID_ADDRESS);
        expect(!isFrozen(from), ERROR_FROZEN);
        expect(!isFrozen(to), ERROR_FROZEN);

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
    }


    /**
     * @dev Approve a spender to transfer the given amount of the sender's tokens.
     */
    function approve(address spender, uint256 value)
    public
    override
    isNotFrozen
    whenNotPaused
    whenUnlocked
    returns (bool)
    {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens a spender can transfer from the sender's account.
     */
    function increaseAllowance(address spender, uint256 addedValue)
    public
    isNotFrozen
    whenNotPaused
    whenUnlocked
    returns (bool)
    {
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens a spender can transfer from the sender's account.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    isNotFrozen
    whenNotPaused
    whenUnlocked
    returns (bool)
    {
        allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Transfer tokens from an account the sender has been approved to send from.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override whenNotPaused whenUnlocked returns (bool) {
        allowed[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }


}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./Pausable.sol";
import "common/ErrorCodes.sol";
import "common8/Groups.sol";

/**
 * @dev User groups for Prime Token.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract TokenGroups is Pausable, ErrorCodes {
    uint8 public constant ADMIN = 1;
    uint8 public constant ATTORNEY = 2;
    uint8 public constant BUNDLER = 3;
    uint8 public constant WHITELIST = 4;
    uint8 public constant FROZEN = 5;
    uint8 public constant BW_ADMIN = 6;
    uint8 public constant SWAPPERS = 7;
    uint8 public constant DELEGATE = 8;
    uint8 public constant AUTOMATOR = 11;

    using Groups for Groups.GroupMap;

    Groups.GroupMap groups;

    event AddedToGroup(uint8 indexed groupId, address indexed account);
    event RemovedFromGroup(uint8 indexed groupId, address indexed account);

    event BwAddedAttorney(address indexed account);
    event BwRemovedAttorney(address indexed account);
    event BwRemovedAdmin(address indexed account);

    modifier onlyAdminOrAttorney() {
        expect(isAdmin(msg.sender) || isAttorney(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }

    // Pausing

    /**
     * @dev Pause the contract, preventing transfers.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function pause() public whenNotPaused {
        bool attorney = isAttorney(msg.sender);
        expect(attorney || isAdmin(msg.sender), ERROR_UNAUTHORIZED);

        _pause(attorney);
    }

    /**
     * @dev Resume the contract.
     *
     * If the contract was originally paused by an attorney, only an attorney can resume.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function unpause() public whenPaused {
        if (!isAttorney(msg.sender)) {
            expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
            expect(!pausedByAttorney(), ERROR_ATTORNEY_PAUSE);
        }
        _unpause();
    }

    // ATTORNEY

    function _addAttorney(address account) internal {
        _add(ATTORNEY, account);
    }

    function addAttorney(address account) public whenNotPaused onlyAdminOrAttorney {
        _add(ATTORNEY, account);
    }

    /**
     * @dev Allows BW admins to add an attorney to the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwAddAttorney(address account) public onlyBwAdmin {
        _add(ATTORNEY, account);
        emit BwAddedAttorney(account);
    }

    function removeAttorney(address account) public whenNotPaused onlyAdminOrAttorney {
        _remove(ATTORNEY, account);
    }

    /**
     * @dev Allows BW admins to remove an attorney from the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwRemoveAttorney(address account) public onlyBwAdmin {
        _remove(ATTORNEY, account);
        emit BwRemovedAttorney(account);
    }

    function isAttorney(address account) public view returns (bool) {
        return _contains(ATTORNEY, account);
    }

    // ADMIN

    function _addAdmin(address account) internal {
        _add(ADMIN, account);
    }

    function addAdmin(address account) public whenNotPaused onlyAdminOrAttorney {
        _addAdmin(account);
    }

    function removeAdmin(address account) public whenNotPaused onlyAdminOrAttorney {
        _remove(ADMIN, account);
    }

    /**
     * @dev Allows BW admins to remove an admin from the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwRemoveAdmin(address account) public onlyBwAdmin {
        _remove(ADMIN, account);
        emit BwRemovedAdmin(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _contains(ADMIN, account);
    }

    // BUNDLER

    function addBundler(address account) public onlyAdminOrAttorney {
        _add(BUNDLER, account);
    }

    function removeBundler(address account) public onlyAdminOrAttorney {
        _remove(BUNDLER, account);
    }

    function isBundler(address account) public view returns (bool) {
        return _contains(BUNDLER, account);
    }

    modifier onlyBundler() {
        expect(isBundler(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }

    // SWAPPERS

    function addSwapper(address account) public onlyAdminOrAttorney {
        _addSwapper(account);
    }

    function _addSwapper(address account) internal {
        _add(SWAPPERS, account);
    }

    function removeSwapper(address account) public onlyAdminOrAttorney {
        _remove(SWAPPERS, account);
    }

    function isSwapper(address account) public view returns (bool) {
        return _contains(SWAPPERS, account);
    }

    modifier onlySwapper() {
        expect(isSwapper(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }

    // WHITELIST

    function addToWhitelist(address account) public onlyAdminOrAttorney {
        _add(WHITELIST, account);
    }

    function removeFromWhitelist(address account) public onlyAdminOrAttorney {
        _remove(WHITELIST, account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _contains(WHITELIST, account);
    }

    // BW_ADMIN

    function _addBwAdmin(address account) internal {
        _add(BW_ADMIN, account);
    }

    function addBwAdmin(address account) public onlyBwAdmin {
        _addBwAdmin(account);
    }

    function renounceBwAdmin() public {
        _remove(BW_ADMIN, msg.sender);
    }

    function isBwAdmin(address account) public view returns (bool) {
        return _contains(BW_ADMIN, account);
    }

    modifier onlyBwAdmin() {
        expect(isBwAdmin(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }

    // FROZEN

    function _freeze(address account) internal {
        _add(FROZEN, account);
    }

    function freeze(address account) public onlyAdminOrAttorney {
        _freeze(account);
    }

    function _unfreeze(address account) internal {
        _remove(FROZEN, account);
    }

    function unfreeze(address account) public onlyAdminOrAttorney {
        _unfreeze(account);
    }

    /**
     * @dev Freeze multiple accounts with a single transaction.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiFreeze(address[] calldata account) public onlyAdminOrAttorney {
        expect(account.length > 0, ERROR_EMPTY_ARRAY);

        for (uint256 i = 0; i < account.length; i++) {
            _freeze(account[i]);
        }
    }

    /**
     * @dev Unfreeze multiple accounts with a single transaction.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiUnfreeze(address[] calldata account) public onlyAdminOrAttorney {
        expect(account.length > 0, ERROR_EMPTY_ARRAY);

        for (uint256 i = 0; i < account.length; i++) {
            _unfreeze(account[i]);
        }
    }

    function isFrozen(address account) public view returns (bool) {
        return _contains(FROZEN, account);
    }

    modifier isNotFrozen() {
        expect(!isFrozen(msg.sender), ERROR_FROZEN);
        _;
    }

    // DELEGATE

    function addDelegate(address account) public onlyAdminOrAttorney {
        _add(DELEGATE, account);
    }

    function removeDelegate(address account) public onlyAdminOrAttorney {
        _remove(DELEGATE, account);
    }

    function isDelegate(address account) public view returns (bool) {
        return _contains(DELEGATE, account);
    }

    // AUTOMATOR

    function addAutomator(address account) public onlyAdminOrAttorney {
        _add(AUTOMATOR, account);
    }

    function removeAutomator(address account) public onlyAdminOrAttorney {
        _remove(AUTOMATOR, account);
    }

    function isAutomator(address account) public view returns (bool) {
        return _contains(AUTOMATOR, account);
    }

    // Internal functions

    function _add(uint8 groupId, address account) internal {
        groups.add(groupId, account);
        emit AddedToGroup(groupId, account);
    }

    function _remove(uint8 groupId, address account) internal {
        groups.remove(groupId, account);
        emit RemovedFromGroup(groupId, account);
    }

    function _contains(uint8 groupId, address account) internal view returns (bool) {
        return groups.contains(groupId, account);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.6.10;

interface Erc20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

/**
 * @dev Pausing logic that includes whether the pause was initiated by an attorney.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
abstract contract Pausable {
    struct PauseState {
        bool paused;
        bool pausedByAttorney;
    }

    PauseState private pauseState;

    event Paused(address account, bool attorney);
    event Unpaused(address account);

    constructor() {
        pauseState = PauseState(false, false);
    }

    modifier whenNotPaused() {
        require(!pauseState.paused);
        _;
    }

    modifier whenPaused() {
        require(pauseState.paused);
        _;
    }

    function paused() public view returns (bool) {
        return pauseState.paused;
    }

    /**
     * @dev Check if the pause was initiated by an attorney.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function pausedByAttorney() public view returns (bool) {
        return pauseState.paused && pauseState.pausedByAttorney;
    }

    /**
     * @dev Internal logic for pausing the contract.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _pause(bool attorney) internal {
        pauseState.paused = true;
        pauseState.pausedByAttorney = attorney;
        emit Paused(msg.sender, attorney);
    }

    /**
     * @dev Internal logic for unpausing the contract.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function _unpause() internal {
        pauseState.paused = false;
        pauseState.pausedByAttorney = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.8.9;

error Unauthorized(uint8 group);

/**
 * @dev Unified system for arbitrary user groups.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
library Groups {
    struct MemberMap {
        mapping(address => bool) members;
    }

    struct GroupMap {
        mapping(uint8 => MemberMap) groups;
    }

    /**
     * @dev Add an account to a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function add(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(!groupContains(group, account));

        group.members[account] = true;
    }

    /**
     * @dev Remove an account from a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function remove(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(groupContains(group, account));

        group.members[account] = false;
    }

    /**
     * @dev Returns true if the account is in the group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     * @return bool
     */
    function contains(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal view returns (bool) {
        MemberMap storage group = map.groups[groupId];
        return groupContains(group, account);
    }

    function groupContains(MemberMap storage group, address account) internal view returns (bool) {
        require(account != address(0));
        return group.members[account];
    }
}