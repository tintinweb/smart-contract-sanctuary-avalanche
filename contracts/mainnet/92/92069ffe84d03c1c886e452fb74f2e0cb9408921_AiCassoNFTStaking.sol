// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './Strings.sol';
import './IERC721.sol';
import './ERC721Receiver.sol';
import './IAiCassoNFTStaking.sol';

contract AiCassoNFTStaking is IAiCassoNFTStaking, Ownable, ERC721Receiver {
    using Strings for uint256;

    struct Staker {
        uint256[] tokenIds;
        uint256 stakerIndex;
        uint256 balance;
        uint256 lastRewardCalculate;
        uint256 rewardCalculated;
        uint256 rewardWithdrawed;
    }

    struct Reward {
        uint256 start;
        uint256 end;
        uint256 amount;
        uint256 perMinute;
    }

    struct Withdraw {
        uint256 date;
        uint256 amount;
    }

    mapping (address => Staker) public stakers;
    mapping (uint256 => Reward) public rewards;
    mapping (uint256 => Withdraw) public withdraws;
    address[] public stakersList;

    uint256 public stakedCount;
    uint256 public rewardsCount;
    uint256 public withdrawsCount;
    uint256 private recoveryIndex;

    address public AiCassoNFT;

    modifier onlyParent() {
        require(AiCassoNFT == msg.sender);
        _;
    }

    constructor() {
        recoveryStake(0x03c3a50132Ade4600Eb522927e6bc038833251Ef, 1, 9141480973331254);
        recoveryStake(0xa84546e35B27933F83596838EE958615B7062196, 1, 9141480973331254);
        recoveryStake(0x1EFd12b8e01337CCd4839f9580Fc685C202f1702, 1, 9153246071109028);
        recoveryStake(0x4C293D1F0bbb8fB6762f325D250B3582cd0EdAd0, 1, 9153246071109028);
        recoveryStake(0x29713dec3F1d7f9BE176F15d7d10bEa91F18EBe5, 1, 9153246071109028);
        recoveryStake(0x0E5e74B274cbf68dECaaec85240805D35C9361DF, 7, 64168068811003933);
        recoveryStake(0x925e716073e15905218264e66Da4Db1147D10a8c, 2, 18306492142218060);
        recoveryStake(0x91B85C0aD32f7711fF142771896126ca91Ce522a, 1, 9153246071109028);
        recoveryStake(0xf3F291A19A6d5674241757a9EABd2784e4a085e8, 3, 27459738213327090);
        recoveryStake(0xD515b88473D9310e63eD6a201Ca79D45E2803536, 1, 9153246071109028);
        recoveryStake(0xe08707eAe41b7a8213175Af061254eE8154A8Fbc, 1, 9153246071109028);
        recoveryStake(0x9d48176B453d58d163baf8C9B9F884A4AB64B55f, 1, 9153246071109028);
        recoveryStake(0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D, 19, 174150041134173382);
        recoveryStake(0x648213045D8c2c373cc40F73E13c67C8e0Ff81Bc, 1, 9153246071109028);
        recoveryStake(0x249D7449338b3f6719Eb46c4A4Bc3362b68d5a9b, 1, 9153246071109028);
        recoveryStake(0xebd746FEF9952aeC908DF471b65aCE4E05210ADB, 2, 18306492142218060);
        recoveryStake(0x90b26Ce42D4735e927E3ADfaaF70522DeC0bc0fC, 1, 9153246071109028);
        recoveryStake(0x10c90204F4815bDd50B401AEC1B56fc48b67F31B, 1, 9153246071109028);
        recoveryStake(0x9010995cC801d8897e969ADB7e3C86b30bf70353, 4, 36660657441056481);
        recoveryStake(0x01eE6d1869aD3cf4EBe6fE651B7F2c966bF4bFE3, 1, 9153246071109028);
        recoveryStake(0x1F9182c496DE27a5081713A4F431045ECd539108, 1, 9153246071109028);
    }

    function deposit() public onlyOwner payable {
        addReward(msg.value);
    }

    function setContractNFT(address aicassoContract) public onlyOwner {
        require(AiCassoNFT == address(0));
        AiCassoNFT = aicassoContract;
    }

    function withdrawForOwner(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, 'Insufficient funds');
        payable(msg.sender).transfer(amount);
    }

    function withdraw() public {
        updateReward(msg.sender);

    unchecked {
        Staker storage _staker = stakers[msg.sender];
        Withdraw storage _withdraw = withdraws[withdrawsCount];

        uint256 toWithdraw = _staker.rewardCalculated - _staker.rewardWithdrawed;
        uint256 balance = address(this).balance;

        require(balance >= toWithdraw, 'The function is not available at the moment, try again later');
        _staker.rewardWithdrawed += toWithdraw;

        withdrawsCount += 1;
        _withdraw.date = block.timestamp;
        _withdraw.amount = toWithdraw;

        payable(msg.sender).transfer(toWithdraw);
    }
    }


    function recoveryStake(address client, uint256 count, uint256 reReward) private {
        Staker storage _staker = stakers[client];
    unchecked {
        for (uint256 i = 0; i < count; i++) {
            if (_staker.balance == 0 && _staker.lastRewardCalculate == 0) {
                _staker.lastRewardCalculate = block.timestamp;
                _staker.stakerIndex = stakersList.length;
                _staker.rewardCalculated = reReward;
                stakersList.push(client);
            }

            _staker.balance += 1;
            recoveryIndex += 1;
            _staker.tokenIds.push(recoveryIndex);

            stakedCount += 1;
        }
    }
    }

    function stake(uint256[] calldata tokens) public virtual {
        require(IERC721(AiCassoNFT).isApprovedForAll(msg.sender, address(this)));

        updateRewardAll();

    unchecked {
        Staker storage _staker = stakers[msg.sender];

        for (uint256 i = 0; i < tokens.length; i++) {
            require(IERC721(AiCassoNFT).ownerOf(tokens[i]) == msg.sender);

            if (_staker.balance == 0 && _staker.lastRewardCalculate == 0) {
                _staker.lastRewardCalculate = block.timestamp;
                _staker.stakerIndex = stakersList.length;
                stakersList.push(msg.sender);
            }

            _staker.balance += 1;
            _staker.tokenIds.push(tokens[i]);

            stakedCount += 1;

            IERC721(AiCassoNFT).transferFrom(
                msg.sender,
                address(this),
                tokens[i]
            );
        }
    }
    }

    function unstake(uint256 numberOfTokens) public {
    unchecked {
        Staker storage _staker = stakers[msg.sender];

        require(_staker.balance >= numberOfTokens);

        updateReward(msg.sender);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _staker.balance -= 1;

            uint256 lastIndex = _staker.tokenIds.length - 1;
            uint256 lastIndexKey = _staker.tokenIds[lastIndex];
            _staker.tokenIds.pop();

            stakedCount -= 1;

            IERC721(AiCassoNFT).transferFrom(
                address(this),
                msg.sender,
                lastIndexKey
            );
        }
    }
    }

    function addReward(uint256 amount) private {
    unchecked {
        Reward storage _reward = rewards[rewardsCount];
        rewardsCount += 1;
        _reward.start = block.timestamp;
        _reward.end = block.timestamp + 30 days;
        _reward.amount = amount;
        _reward.perMinute = amount / 30 days * 60;
    }
    }

    function updateRewardAll() private {
        for (uint256 i = 0; i < stakersList.length; i++) {
            updateReward(stakersList[i]);
        }
    }

    function updateReward(address _user) private {
    unchecked {
        Staker storage _staker = stakers[_user];
        uint256 _rewardCalculated = _getReward(_user);
        _staker.lastRewardCalculate = block.timestamp;
        _staker.rewardCalculated += _rewardCalculated;
    }
    }

    function _getReward(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        if (_staker.balance > 0) {
            uint256 rewardCalculated = 0;

        unchecked {
            for (uint256 i = 0; i < rewardsCount; i++) {
                Reward storage _reward = rewards[i];
                if (_reward.end > _staker.lastRewardCalculate) {
                    uint256 startCalculate = _staker.lastRewardCalculate;
                    if (_reward.start > _staker.lastRewardCalculate) {
                        startCalculate = _reward.start;
                    }

                    uint256 minutesReward = (block.timestamp - startCalculate) / 60;
                    uint256 totalReward = minutesReward * _reward.perMinute;
                    uint256 userReward = ((_staker.balance * 10_000 / stakedCount) * totalReward) / 10_000;

                    rewardCalculated += userReward;
                }
            }
        }

            return rewardCalculated;
        }

        return 0;
    }

    function totalStaked() public view returns (uint256) {
        return stakedCount;
    }

    function totalLastWeekWithdraws() public view returns (uint256) {
        uint256 weekStart = block.timestamp - 7 days;
        uint256 total = 0;

        for (uint256 i = 0; i < withdrawsCount; i++) {
            Withdraw storage _withdraw = withdraws[i];
            if (_withdraw.date >= weekStart) {
                total += _withdraw.amount;
            }
        }
        return total;
    }

    function totalRewardOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _getReward(_user) + _staker.rewardCalculated;
    }

    function percentOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        if (_staker.balance > 0) {
            return (_staker.balance * 10000 / stakedCount) / 100;
        }
        return 0;
    }

    function balanceOf(address _user) public view override returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _staker.balance;
    }

    function rewardOf(address _user) public view returns (uint256) {
        Staker storage _staker = stakers[_user];
        return _getReward(_user) + _staker.rewardCalculated - _staker.rewardWithdrawed;
    }

    event Received();

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
    external
    override
    returns(bytes4)
    {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }
}