// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./TreasureHuntGame.sol";
import "./TRSR.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Staking is Ownable, Pausable {

    uint256 public constant minimumToExitPirateAndMarine = 2 days;
    uint256 public constant minimumToExitCorsair = 1 days;
    uint256 public minimumToClaim = 43200;
    uint256 public totalTokenEarned = 0;
    uint public brideMarine = 20;
    uint public brideCorsair = 20;
    uint public maximumTokenStaking = 9950000000;
    uint public burnPirate = 0;
    uint public burnMarine = 0;
    // Daily reward based on level
    uint256[] public rewards = [0,2000,4000,6000,8000,10000,1000,3000];

    uint256 public unaccountedMarineRewards = 0;
    uint256 public unaccountedCorsairRewards = 0;

    uint256 public totalPirateStaked = 0;
    uint256 public totalMarineStaked = 0;
    uint256 public totalCorsairStaked = 0;

    uint256 public tokenPerMarine = 0;
    uint256 public tokenPerCorsair = 0;

    uint256 public claimingFee = 0.01 ether;
    uint256 public unstakeFee = 0.05 ether;

    uint initialNumber = 0;
    bool public rescueEnabled = false;
    bool public stopNewEntrance = false;

    constructor (address _seam,address _trsr) {
        seam = TreasureHuntGame(_seam);
        trsr = TRSR(_trsr);
    }

    struct Staking {
        uint tokenId;
        uint8 grade;
        address owner;
        uint80 timeDepot;
        uint power;
    }

    TRSR trsr;
    TreasureHuntGame seam;
    uint8[] typeSeam;
    uint8[] powerSeam;
    uint256 public totalNftStaked;
    mapping(uint256=>Staking) public poolStack; // based on token id returns the stake
    mapping(address=>uint[]) public getAddressStake; // based on address and return tokenId


    uint[] Marines;
    uint[] Corsairs;

    uint statut = 0;
    // 0 = send back pirate
    // 1 = marine bride
    // 2 = Corsair bride
    // 3 = burn
    // 4 = nft transfert marine
    // 5 = nft tranfert corsair
    // 6 = rescue mode

    event NftsAddPoolEvent(address indexed account, uint[] indexed tokenIds);
    event NftRemovePoolEvent(uint tokenIds,uint indexed typeNft, uint indexed owed,uint indexed statut, bool unstake);

    function addManyToStaking(address account, uint[] memory tokenIds)
    external
    _updateEarnings
    whenNotPaused
    {
        require((account == msg.sender && account == tx.origin), "This is not your account");
        require(!stopNewEntrance, "New entrance is desactivate");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (account != address(seam)) {
                require(seam.ownerOf(tokenIds[i]) == account, "Aint yo token");
                seam.approve(account, address(this), tokenIds[i]);
                seam.transferFrom(account, address(this), tokenIds[i]);

            } else if (tokenIds[i] == 0) {
                continue;
            }
            addNftToStaking(msg.sender, tokenIds[i]);
        }
        emit NftsAddPoolEvent(account, tokenIds);
    }

    function addNftToStaking(address _account, uint _tokenId)
    internal
    {
        require(typeIsDefine(_tokenId), "Type your nft is not define");
        require(powerIsDefine(_tokenId), "Your nft power is not define");

        poolStack[_tokenId] = Staking({
        owner: _account,
        tokenId: _tokenId,
        grade : typeSeam[_tokenId-1],
        timeDepot: uint80(block.timestamp),
        power : powerSeam[_tokenId-1]
        });

        if (!_isPresent(_tokenId,_account))
            getAddressStake[_account].push(_tokenId);

        totalNftStaked += 1;

        if (typeSeam[_tokenId-1] == 1){
            totalCorsairStaked += 1;
            Corsairs.push(_tokenId);
        } else if (typeSeam[_tokenId-1] == 2) {
            totalMarineStaked += 1;
            Marines.push(_tokenId);
        } else {
            totalPirateStaked += 1;
        }
    }

    function isPirate(uint256 tokenId) public view returns (bool pirate) {
        if (typeSeam[tokenId-1] == 3) return true;
        else return false;
    }

    function isMarine(uint256 tokenId) public view returns (bool marine) {
        if (typeSeam[tokenId-1] == 2) return true;
        else return false;
    }

    function isCorsair(uint256 tokenId) public view returns (bool corsair) {
        if (typeSeam[tokenId-1] == 1) return true;
        else return false;
    }

    function claimManyFromStaking(uint[] memory tokenIds, bool unstake)
    external
    payable
    whenNotPaused
    {
        require(tokenIds.length > 0, "Select minimal one Seam");
        if (unstake)
            require(msg.value >= tokenIds.length * unstakeFee, "You didnt pay tax for unstake to return seaport");
        else
            require(msg.value >= tokenIds.length * claimingFee, "You didnt pay tax for claim to return seaport");

        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isPirate(tokenIds[i])) {
                owed += _claimPirateFromStake(tokenIds[i], unstake);
                }
            else if (isMarine(tokenIds[i])) {
                owed += _claimMarineFromStake(tokenIds[i], unstake);
            } else if (isCorsair(tokenIds[i])) {
                owed += _claimCorsairFromStake(tokenIds[i],unstake);
            }
        }
        if (owed == 0) return;
        require(totalTokenEarned + owed < maximumTokenStaking , "Sorry maximum token is mint");
        if (totalTokenEarned + owed > maximumTokenStaking) return;
        trsr.mint(msg.sender, owed * 10**18); // convert wei to ether
        totalTokenEarned += owed;
    }

    function getMinimalToExit(uint tokenId)
    public
    view
    returns (uint time)
    {
        time = poolStack[tokenId].timeDepot;
        if (isCorsair(tokenId)) return time + minimumToExitCorsair;
        else return time + minimumToExitPirateAndMarine;
    }

    // unstake | claim Pirate
    function _claimPirateFromStake(uint tokenId, bool unstake)
    internal
    returns (uint256 owed)
    {
        Staking memory stake = poolStack[tokenId];
        uint totalTokens = 0;
        require ((stake.owner == msg.sender), "Is not your NFT hohoh"); // Check if sender is owner
        require(!(unstake && block.timestamp - stake.timeDepot < minimumToExitPirateAndMarine), "Please respect delay to unstack");


        if (totalTokenEarned < maximumTokenStaking) {
            owed = ((block.timestamp - stake.timeDepot) * getPowerNft(tokenId)) / 1 days;
        }

        if (unstake) {
            _removeValueAddressStake(tokenId,stake.owner);
            uint random = _random(100);
            if (random >= 80 && random <= 90) {   //10% chance of bride marine
                seam.safeTransferFrom(address(this),msg.sender, tokenId); // send back pirate
                delete poolStack[tokenId];
                _payMarineTax(owed);
                totalTokens = owed;
                owed = 0;
                statut = 1;

            }
            else if (random >= 10 && random <= 30) { // 20 % chance of bride corsair
                seam.safeTransferFrom(address(this),msg.sender, tokenId); // send back pirate
                delete poolStack[tokenId];
                _payCorsairTax(owed);
                totalTokens = owed;
                owed = 0;
                statut = 2;

            }
            // 1% chance to burn
            else if (random == 1) {
                seam.burn(tokenId);
                burnPirate += 1;
                statut = 3;
                totalTokens = owed;

            }
            // 2% chance to stolen
            else if (random == 2 || random == 3) {
                address winner = poolStack[Marines[_random(totalMarineStaked)-1]].owner;
                seam.safeTransferFrom(address(this),winner,tokenId);
                statut = 4;
                totalTokens = owed;

            }
            // send back pirate
            else {
                seam.safeTransferFrom(address(this),msg.sender, tokenId);
                delete poolStack[tokenId];
                statut = 0;
                totalTokens = owed;
            }
            totalNftStaked -= 1;
            totalPirateStaked -= 1;
        }
        else {
            require(stake.timeDepot + minimumToClaim < block.timestamp, "Sorry respect delay to claim reward");
            // percentage tax to stacked marines
            _payMarineTax((owed * brideMarine) / 100);
            totalTokens = ((owed * brideMarine) / 100);
            // remainder goes to pirate owner
            owed = (owed * (100 - brideMarine)) / 100;
            poolStack[tokenId] = Staking({
            owner: msg.sender,
            tokenId: tokenId,
            grade : typeSeam[tokenId-1],
            timeDepot: uint80(block.timestamp),
            power: getPowerNft(tokenId)
            });
        }

        emit NftRemovePoolEvent(tokenId, getTypeNft(tokenId), totalTokens, statut, unstake);
        return owed;
    }

    function _claimMarineFromStake(uint tokenId, bool unstake) internal returns (uint256 owed){
        Staking memory stake = poolStack[tokenId];
        require ((stake.owner == msg.sender), "Is not your NFT hohoh");
        require(!(unstake && block.timestamp - stake.timeDepot < minimumToExitPirateAndMarine), "Please respect delay to unstack");
        if (totalTokenEarned < maximumTokenStaking) {
            owed = ((block.timestamp - stake.timeDepot) * getPowerNft(tokenId)) / 1 days;
        }

        if (unstake) {
            _removeValueAddressStake(tokenId,stake.owner); // based on address and return tokenId
            uint random = _random(100);

            if (random == 55) { // 1% chance to burn
                seam.burn(tokenId);
                burnMarine += 1;
                statut = 3;

            }
            else if (random == 70) { // 1% chance to lose
                address winner = poolStack[Corsairs[_random(totalCorsairStaked)-1]].owner;
                seam.safeTransferFrom(address(this),winner,tokenId);
                statut = 5;

            }
            else {
                // send back marine
                seam.safeTransferFrom(address(this),msg.sender, tokenId);
                delete poolStack[tokenId];
                statut = 0;

            }
            totalNftStaked -= 1;
            totalMarineStaked -= 1;

        }
        else {
            require(stake.timeDepot + minimumToClaim < block.timestamp, "Sorry respect delay to claim reward");
            // percentage tax to staked Marines
            _payCorsairTax((owed * brideCorsair) / 100);
            // remainder goes to Marine owner
            owed = (owed * (100 - brideCorsair)) / 100;
            owed += tokenPerMarine;
            poolStack[tokenId] = Staking({
            owner: msg.sender,
            tokenId: tokenId,
            grade : typeSeam[tokenId-1],
            timeDepot: uint80(block.timestamp),
            power: getPowerNft(tokenId)
            });
            // reset stake
        }

        emit NftRemovePoolEvent(tokenId, getTypeNft(tokenId), owed, statut, unstake);
        return owed;
    }

    function _claimCorsairFromStake(uint tokenId, bool unstake)
    internal
    returns (uint256 owed)
    {
        Staking memory stake = poolStack[tokenId];
        require ((stake.owner == msg.sender), "Is not your NFT hohoh");
        require(!(unstake && block.timestamp - stake.timeDepot < minimumToExitCorsair), "Please respect delay to unstack");
        if (totalTokenEarned < maximumTokenStaking) {
            owed = tokenPerCorsair;
        }

        if (unstake) {
            _removeValueAddressStake(tokenId, stake.owner);
            seam.safeTransferFrom(address(this),msg.sender, tokenId);
            delete poolStack[tokenId];
            totalNftStaked -= 1;
            totalCorsairStaked -= 1;
        }
        else {
            require(stake.timeDepot + minimumToClaim < block.timestamp, "Sorry respect delay to claim reward");
            owed = tokenPerCorsair;
            poolStack[tokenId] = Staking({
            owner: msg.sender,
            tokenId: tokenId,
            grade : typeSeam[tokenId-1],
            timeDepot: uint80(block.timestamp),
            power: getPowerNft(tokenId)
            }); // reset stake
        }

        emit NftRemovePoolEvent(tokenId, getTypeNft(tokenId), owed, 0, unstake);
        return owed;
    }

    function _isPresent(uint value, address owner)
    internal
    view
    returns (bool check)
    {
        uint[] storage tabTemp = getAddressStake[owner];
        for(uint i=0;i < tabTemp.length; i++) {
            if (tabTemp[i] == value) {
                return true;
            }
        }
        return false;
    }

    function _removeValueAddressStake(uint value, address owner)
    internal
    {
        uint[] storage tabTemp = getAddressStake[owner];
        for(uint i=0;i < tabTemp.length; i++) {
            if (tabTemp[i] == value) {

                uint temp = tabTemp[i];
                uint last = tabTemp[tabTemp.length-1];
                tabTemp[i] = last;
                tabTemp[tabTemp.length-1] = temp;
                tabTemp.pop();
                getAddressStake[owner] = tabTemp;
            }
        }
    }

    function _random(uint value)
    internal
    returns(uint)
    {
        return uint(keccak256(abi.encodePacked(initialNumber++))) % value;
    }

    function resetAleatoireNumber() public onlyOwner {
        initialNumber = 0;
    }

    function _payMarineTax(uint256 amount) internal {
        if (totalMarineStaked == 0) {
            // if there's no staked marine - keep track of $TRSR due to marine
            unaccountedMarineRewards += amount;
            return;
        }
        tokenPerMarine += (amount + unaccountedMarineRewards) / totalMarineStaked;
        unaccountedMarineRewards = 0;
    }

    function _payCorsairTax(uint256 amount)
    internal
    {
        if (totalCorsairStaked == 0) {
            // if there's no staked Corsair - keep track of $TRSR due to Corsair
            unaccountedCorsairRewards += amount;
            return;
        }
        tokenPerCorsair += (amount + unaccountedCorsairRewards) / totalCorsairStaked;
        unaccountedCorsairRewards = 0;
    }

    // 3 Pirate
    // 2 Marine
    // 1 Corsair
    function addTypeSeam(uint8[] memory _types)
    public onlyOwner
    {
        for(uint i = 0; i < _types.length; i++) {
            typeSeam.push(_types[i]);
        }
    }

    function getTypeNft(uint tokenId) public view returns (uint) {
        return typeSeam[tokenId-1];
    }

    function addPowerSeam(uint8[] memory _power)
    public
    onlyOwner
    {
        for(uint i = 0; i < _power.length; i++) {
            powerSeam.push(_power[i]);
        }
    }

    // set the power of an nft if error in json generation
    function setPowerNft(uint _tokenId, uint8 _powerNft)
    public
    onlyOwner
    {
        typeSeam[_tokenId-1] = _powerNft;
    }

    function getPowerNft(uint256 index)
    internal
    view
    returns (uint256 reward)
    {
        // daily reward for pirate and marine
        if (powerSeam[index - 1] == 0) return rewards[0];
        if (powerSeam[index - 1] == 1) return rewards[1];
        if (powerSeam[index - 1] == 2) return rewards[2];
        if (powerSeam[index - 1] == 3) return rewards[3];
        if (powerSeam[index - 1] == 4) return rewards[4];
        if (powerSeam[index - 1] == 5) return rewards[5];
        if (powerSeam[index - 1] == 6) return rewards[6];
        if (powerSeam[index - 1] == 7) return rewards[7];
    }

    function setPower (uint _index , uint _newPower)
    public
    onlyOwner
    {
        rewards[_index] = _newPower;
    }

    function newTimeToClaim(uint _newTimeToClaim)
    public
    onlyOwner
    {
        minimumToClaim = _newTimeToClaim;
    }

    // set the type of an nft if error in json generation
    function setTypeNft(uint _tokenId, uint8 _typeNft)
    public
    onlyOwner
    {
        typeSeam[_tokenId-1] = _typeNft;
    }

    function getTotalEarning()
    public
    view
    returns (uint)
    {
        uint[] memory tokenIds = getAddressStake[msg.sender];
        uint totalReward = 0;

        for (uint i = 0; i < tokenIds.length;i++) {
            uint reward = 0;
            if (totalTokenEarned < maximumTokenStaking) {
                reward =
                ((block.timestamp - poolStack[tokenIds[i]].timeDepot) * getPowerNft(tokenIds[i])) /
                1 days;
            } else
                reward = 0;

            totalReward =  totalReward + reward;
        }
        return totalReward;
    }

    function getMyNftStaking()
    external
    view
    returns (uint[] memory tokenIds)
    {
        tokenIds = getAddressStake[msg.sender];
        return tokenIds;
    }

    // return mapping with token
    function getNftInfo(uint _tokenId)
    public
    view
    returns (Staking memory)
    {
        return poolStack[_tokenId];
    }

    function getNumberType()
    public
    view
    returns (uint)
    {
        return typeSeam.length;
    }

    function setClaimingFee(uint _claimingFee)
    public
    onlyOwner
    {
        claimingFee = _claimingFee;
    }

    function setUnstakeFee(uint _newUnstakeFee)
    public
    onlyOwner
    {
        unstakeFee = _newUnstakeFee;
    }

    modifier _updateEarnings() {
        require(totalTokenEarned < maximumTokenStaking, "All tokens minted");
        _;
    }

    function setStopNewEntrance(bool _newEntrance)
    external
    onlyOwner
    {
        if (_newEntrance) stopNewEntrance = false;
        else stopNewEntrance = true;
    }

    function setPaused(bool _paused)
    external
    onlyOwner
    {
        if (_paused) _pause();
        else _unpause();
    }

    function typeIsDefine(uint tokenId)
    internal
    view
    returns (bool isDefine)
    {
        if (typeSeam[tokenId - 1] >= 1 && typeSeam[tokenId - 1] <= 3) return true;
        else return false;
    }

    function powerIsDefine(uint tokenId)
    internal
    view
    returns (bool isDefine)
    {
        if (getPowerNft(tokenId) >= 0 && getPowerNft(tokenId) <= 10000) return true;
        else return false;
    }

    function setMaximunTokenStaking(uint _newMax)
    public
    onlyOwner
    {
        maximumTokenStaking = _newMax;
    }

    function getTotalSeamBurn()
    public
    returns
    (uint)
    {
        return burnMarine + burnPirate;
    }

    function withdraw()
    external
    onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }

    function setRescueEnabled()
    external
    onlyOwner
    {
        if (rescueEnabled)
            rescueEnabled = false;
        else
        rescueEnabled = true;
    }

    // Rescue if staking problem.
    function rescue(address account, uint256[] memory tokenIds)
    external
    {
        require(rescueEnabled, "Rescue is not activate");
        require(account == msg.sender, "Not your account");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Staking memory stake = poolStack[tokenIds[i]];
            require(stake.owner == account, "Is not your NFT");
            seam.transferFrom(address(this), msg.sender, tokenIds[i]);
            delete poolStack[tokenIds[i]];
            totalNftStaked -= 1;
            if (isPirate(tokenIds[i])) totalPirateStaked -= 1;
            if (isMarine(tokenIds[i])) totalMarineStaked -= 1;
            if (isCorsair(tokenIds[i])) totalCorsairStaked -= 1;
            _removeValueAddressStake(tokenIds[i], stake.owner);
            emit NftRemovePoolEvent(tokenIds[i], getTypeNft(tokenIds[i]), 0, 6, true);
            }
        }
    }