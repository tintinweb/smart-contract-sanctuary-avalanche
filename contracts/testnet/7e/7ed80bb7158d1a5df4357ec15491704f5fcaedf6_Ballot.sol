/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
//投票合约
//功能：主席（chairperson）分配投票的资格
//代理投票，自己投票，查看获胜提案
contract Ballot {

    struct Voter {
        uint weight; // 权重由委托累加
        bool voted;  // 如果是true，说明以及投过票了
        address delegate; // 可以将自己的投票权给其他人代理投票
        uint vote;   // 投票提议的索引
    }

    struct Proposal {
        //bytes1 到 bytes32都可以，gas费消耗少.........
        bytes1 name;   // 提议的名称
        uint voteCount; // 累积票数
    }

    address public chairperson;//主席

    mapping(address => Voter) public voters;//地址对应的投票相关信息

    Proposal[] public proposals;//存放所有提议的数组

    //构造函数传入几个提议议案作为投票的对象["0x11","0x22","0x33"]
    constructor(bytes1[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        //将几个提案用循环push推入到proposals数组中
        for (uint i = 0; i < proposalNames.length; i++) {
            // 将对应结构体推入数组
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    //分配投票劝，只能主席来分配
    function giveRightToVote(address voter) public {
        require( msg.sender == chairperson, "Only chairperson can give right to vote.");
        require(!voters[voter].voted, "The voter already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    //to输入的是代理人的地址
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            //如果代表已经投票，直接添加投票数
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // 如果没有投票就增加他的权重
            delegate_.weight += sender.weight;
        }
    }
     //将您的投票（包括委托给您的投票）投给提案 'proposals[proposal].name'.参数为提案数组中提案的索引
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;//将投票设置为已投
        sender.vote = proposal;//更改为对应提案的索引

        // 如果 'proposal' 超出数组的范围，这将自动抛出并恢复所有更改。
        proposals[proposal].voteCount += sender.weight;
    }
    //计算考虑所有先前投票的获胜提案。在提案数组中得到获胜提案的索引
    function winningProposal() public view returns (uint winningProposal_)//给返回值赋值参数
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;//返回时可以隐性返回
            }
        }
    }
    //调用winningProposal()函数获取proposals数组中包含的获胜者的索引，然后返回获胜者的名字
    function winnerName() public view returns (bytes1 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}