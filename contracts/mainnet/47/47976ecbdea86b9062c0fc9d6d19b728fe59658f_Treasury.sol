/**
 *Submitted for verification at snowtrace.io on 2022-05-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface Board {

    function claimDividend(address _shareHolder) external returns(uint256);
    function claimInAnyToken(address _shareHolder, address _token, address _newRouter) external payable;

    function isPlayingFair(address _shareHolder) external view returns(bool);
    function getNextPayoutTime() external view returns(uint256, uint256);
    function getOutstandingBalance(address _shareHolder) external view returns(uint256);
    function getSpendableBalance(address _shareHolder) external view returns(uint256);

    function farmerFunder(address _farmer) external;
    function farmerSettle(address _farmer) external returns(uint256);
    function getFarmerStats(address _farmer) external view returns(uint256, uint256, uint256, uint256, int256, address, uint256);
    function getFarmerActiveTokens(address _farmer) external view returns(address[] memory);
    function getFarmerTokenStats(address _farmer, address _token) external view returns(uint256, address, uint256);

    function getFarmersCurrentBalance(address _farmer) external view returns(uint256);
    function getFarmerOutstandingBalances(address _farmer) external view returns(uint256, uint256);
    function getOperatorsFund(address _operator) external view returns(address);
    function getAllFarmers() external view returns(address[] memory);

    function investInToken(address _operator, address _token, address _router, bool wrap) external payable;

    function operatorSellToken(address _operator, address _router, address _token, uint256 _share) external;
    function operatorUnwrapETH(address _operator, address _router, address _token, uint256 _share) external;
    function operatorSwapToken(address _operator, address _router, address _token, address _newToken, uint256 _share) external;

    function operatorAddToLPToken(address _operator, address _pair) external;
    function operatorRemoveFromLPToken(address _operator, address _pair) external;

    function operatorFarmLPToken(address _operator, address _masterChef, address _pair, uint256 _pid, uint256 _share) external;
    function operatorUnfarmLPToken(address _operator, address _masterChef, address _pair, uint256 _share) external;
    function operatorEmergencyUnfarmLPToken(address _operator, address _masterChef, address _pair) external;

    function proposeAddFund(address _operator, uint256 _successFee, uint256 _shareAUM) external;
    function proposeUpdateFund(address _farmer, uint256 _successFee, uint256 _shareAUM) external;
    function proposeLiquidateFund(address _farmer) external;
    function proposeReplaceOperator(address _farmer, address _newOperator) external;
    function proposeEmergencyReplaceOperator(address _farmer) external;

    function voteOnProposal(address _shareholder, uint256 _proposalID, uint256 _voteShare) external;
    function viewActiveProposal(uint256 _proposalID) external view returns(address, address, uint256, uint256, uint256, uint256, bool);
    function executeProposal(uint256 _proposalID) external;
    function getGlobalState(uint256 _proposalID, address _shareHolder) external view returns(uint256, uint256);

}

interface ERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address to) external view returns (uint);

}

contract Treasury {

    address public owner;
    address public withdrawer;

    Board board;
    
    constructor(address _board) {

        owner = msg.sender;
        withdrawer = msg.sender;
        board = Board(_board);

    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isWithdrawer() {
        require(msg.sender == withdrawer, "Caller is not withdrawer");
        _;
    }

    function revokeWithdrawerRole() public isWithdrawer {
        withdrawer = address(0x0);
    }
    
    function setAddress(address _board) public isOwner {
        board = Board(_board);
    }

    //shareHolder view funcs
    function getOutstandingBalance() public view returns(uint256) {
        return board.getOutstandingBalance(msg.sender);
    }

    function getSpendableBalance() public view returns(uint256) {
        return board.getSpendableBalance(msg.sender);
    }

    function getNextPayoutTime() public view returns(uint256 _timeToNextPayoutPeriod, uint256 _timeToNextFarmingPeriod) {
        (_timeToNextPayoutPeriod, _timeToNextFarmingPeriod) = board.getNextPayoutTime();
    }

    function isPlayingFair(address _shareHolder) public view returns(bool) {
        return board.isPlayingFair(_shareHolder);
    } 

    //shareHolder state changing funcs
    function claimDividend() public {
        uint256 spendableBalance = getSpendableBalance();
        uint256 payout = board.claimDividend(msg.sender);
        require(spendableBalance <= payout, "values mismatch!");
        if (payout > 0) {payable(msg.sender).transfer(payout);}
    }

    function claimAnyToken(address _token, address _newRouter) public {
        uint256 payout = getSpendableBalance();
        //uint256 payout = board.claimDividend(msg.sender);
        //require(payout == getSpendableBalance(), "values mismatch!");
        if (payout > 0) {board.claimInAnyToken{value: payout}(msg.sender, _token, _newRouter);}
    }

    //farmer view funcs
    function getAllFarmers() public view returns(address[] memory) {
        return board.getAllFarmers();
    }

    function getFarmerStats(address _farmer) public view returns(uint256, uint256, uint256, uint256, int256, address, uint256) {
        return board.getFarmerStats(_farmer);
    }

    function getFarmerActiveTokens(address _farmer) public view returns(address[] memory) {
        return board.getFarmerActiveTokens(_farmer);
    }

    function getFarmerTokenStats(address _farmer, address _token) public view returns(uint256, address, uint256) {
        return board.getFarmerTokenStats(_farmer, _token);
    }

    function getFarmerOutstandingBalances(address _farmer) public view returns(uint256, uint256) {
        return board.getFarmerOutstandingBalances(_farmer);
    }

    function getOperatorsFund(address _operator) public view returns(address) {
        return board.getOperatorsFund(_operator);
    }

    //farmer state changing funcs
    function farmerFunder() public {
        board.farmerFunder(msg.sender);
    }

    function farmerSettle() public {
        uint256 farmerPayout = board.farmerSettle(msg.sender);
        if (farmerPayout > 0) {payable(msg.sender).transfer(farmerPayout);}
    }

    //operator direct market operation funcs
    function operatorBuyToken(address _token, address _router, uint256 _amountToInvest) public {
        require(board.getFarmersCurrentBalance(msg.sender) >= _amountToInvest, "insufficient funds");
        board.investInToken{value: _amountToInvest}(msg.sender, _token, _router, false);
    } 

    function operatorWrapETH(address _token, address _router, uint256 _amountToInvest) public {
        require(board.getFarmersCurrentBalance(msg.sender) >= _amountToInvest, "insufficient funds");
        board.investInToken{value: _amountToInvest}(msg.sender, _token, _router, true);
    }

    function operatorSellToken(address _token, address _router, uint256 _share) public {
        board.operatorSellToken(msg.sender, _router, _token, _share);
    } 

    function operatorUnwrapETH(address _token, address _router, uint256 _share) public {
        board.operatorUnwrapETH(msg.sender, _router, _token, _share);
    } 

    function operatorSwapToken(address _token, address _newToken, address _router, uint256 _share) public {
        board.operatorSwapToken(msg.sender, _router, _token, _newToken, _share);
    } 

    function operatorAddToLPToken(address _pair) public {
        board.operatorAddToLPToken(msg.sender, _pair);
    } 

    function operatorRemoveFromLPToken(address _pair) public {
        board.operatorRemoveFromLPToken(msg.sender, _pair);
    } 

    function operatorFarmLPToken(address _masterChef, address _pair, uint256 _pid, uint256 _share) public {
        board.operatorFarmLPToken(msg.sender, _masterChef, _pair, _pid, _share);
    } 

    function operatorUnfarmLPToken(address _masterChef, address _pair, uint256 _share) public {
        board.operatorUnfarmLPToken(msg.sender, _masterChef, _pair,_share);
    } 

    function operatorEmergencyUnfarmLPToken(address _masterChef, address _pair) public {
        board.operatorEmergencyUnfarmLPToken(msg.sender, _masterChef, _pair);
    } 

    //DAO voting funcs
    function proposeAddFund(address _operator, uint256 _successFee, uint256 _shareAUM) public {
        board.proposeAddFund(_operator, _successFee, _shareAUM);
    }

    function proposeUpdateFund(address _farmer, uint256 _successFee, uint256 _shareAUM) public {
        board.proposeUpdateFund(_farmer, _successFee, _shareAUM);
    }

    function proposeLiquidateFund(address _farmer) public {
        board.proposeLiquidateFund(_farmer);
    }

    function proposeReplaceOperator(address _farmer, address _newOperator) public {
        board.proposeReplaceOperator(_farmer, _newOperator);
    }

    function proposeEmergencyReplaceOperator(address _farmer) public {
        board.proposeEmergencyReplaceOperator(_farmer);
    }

    //DAO view + execution funcs
    function voteOnProposal(uint256 _proposalID, uint256 _voteShare) public {
        board.voteOnProposal(msg.sender, _proposalID, _voteShare);
    }

    function viewActiveProposal(uint256 _proposalID) external view returns(address, address, uint256, uint256, uint256, uint256, bool) {
        return board.viewActiveProposal(_proposalID);
    }

    function executeProposal(uint256 _proposalID) public {
        board.executeProposal(_proposalID);    
    }

    function getGlobalState(uint256 _proposalID, address _shareHolder) public view returns(uint256, uint256) {
        return board.getGlobalState(_proposalID, _shareHolder);
    }

    receive() external payable {}
    fallback() external payable {}

    function withdraw(uint256 _balance) public isWithdrawer {

        payable(owner).transfer(_balance);

    }

    function withdrawToken(address _token) public isOwner {

        ERC20(_token).transfer(owner, ERC20(_token).balanceOf(address(this)));

    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}