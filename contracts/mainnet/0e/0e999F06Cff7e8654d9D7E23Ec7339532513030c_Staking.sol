// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./TreasureHuntGame.sol";
import "./TRSR.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract Staking is Ownable, Pausable {

    uint256 public constant minimumToExitPirateAndMarine = 2 days ;
    uint256 public constant minimumToExitCorsair = 1 days ;
    uint256 public totalTokenEarned;
    uint public brideMarine = 20;
    uint public brideCorsair = 20;
    uint public maximumTokenStaking = 9950000000;
    uint public burnPirate = 0;
    uint public burnMarine = 0;
    // Daily reward based on level
    uint public power1 = 2000;
    uint public power2 = 4000;
    uint public power3 = 6000;
    uint public power4 = 8000;
    uint public power5 = 10000;
    uint public power6 = 1000;
    uint public power7 = 3000;

    uint256 public unaccountedMarineRewards = 0;
    uint256 public unaccountedCorsairRewards = 0;

    uint256 public totalPirateStaked = 0;
    uint256 public totalMarineStaked = 0;
    uint256 public totalCorsairStaked = 0;

    uint256 public tokenPerMarine = 0;
    uint256 public tokenPerCorsair = 0;

    uint256 public claimingFee = 0.01 ether;
    uint256 public unstakeFee = 0.05 ether;

    uint initialNumber;
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
    uint[] powerSeam;
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

    function getMaximunGlobalToken() view external returns(uint global){
        return trsr.getMaximunGlobalToken();
    }

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
        if (totalTokenEarned + owed > maximumTokenStaking) return;
        trsr.mint(msg.sender, owed * 10**18);
        totalTokenEarned += owed;
    }

    function getMinimalToExit(uint tokenId)
    public
    view
    returns (uint time)
    {
        time = poolStack[tokenId].timeDepot;
        return time + minimumToExitPirateAndMarine;
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
            Staking memory user =  poolStack[tokenId]; // based on token id returns the stake
            _removeValueAddressStake(tokenId,user.owner);

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
            owed = ((block.timestamp - stake.timeDepot) * powerSeam[tokenId - 1]) / 1 days;
        }

        if (unstake) {
            Staking memory user =  poolStack[tokenId]; // based on token id returns the stake
            _removeValueAddressStake(tokenId,user.owner); // based on address and return tokenId
            uint random = _random(100);

            if (random == 55) { // 1% chance to burn
                seam.burn(tokenId);
                burnMarine += 1;
                statut = 3;

            }
            else if (random == 70) { // 1% chance to loss
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
            Staking memory user =  poolStack[tokenId];
            _removeValueAddressStake(tokenId, user.owner);
            seam.safeTransferFrom(address(this),msg.sender, tokenId);
            delete poolStack[tokenId];
            totalNftStaked -= 1;
            totalCorsairStaked -= 1;
        }
        else {
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
        if (powerSeam[index - 1] == 0) return 0;
        if (powerSeam[index - 1] == 1) return power1;
        if (powerSeam[index - 1] == 2) return power2;
        if (powerSeam[index - 1] == 3) return power3;
        if (powerSeam[index - 1] == 4) return power4;
        if (powerSeam[index - 1] == 5) return power5;
        if (powerSeam[index - 1] == 6) return power6;
        if (powerSeam[index - 1] == 7) return power7;
    }

    function setPower1 (uint _newPower)
    public
    onlyOwner
    {
        power1 = _newPower;
    }

    function setPower2 (uint _newPower)
    public
    onlyOwner
    {
        power2 = _newPower;
    }

    function setPower3 (uint _newPower)
    public
    onlyOwner
    {
        power3 = _newPower;
    }

    function setPower4 (uint _newPower)
    public
    onlyOwner
    {
        power4 = _newPower;
    }

    function setPower5 (uint _newPower)
    public
    onlyOwner
    {
        power5 = _newPower;
    }

    function setPower6 (uint _newPower)
    public
    onlyOwner
    {
        power6 = _newPower;
    }

    function setPower7 (uint _newPower)
    public
    onlyOwner
    {
        power7 = _newPower;
    }

    // set the type of an nft if error in json generation
    function setTypeNft(uint _tokenId, uint8 _typeNft)
    public
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
    public
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

    function getNombreType()
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

    function setUnstakeFee(uint _newunstakeFee)
    public
    onlyOwner
    {
        unstakeFee = _newunstakeFee;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./RoyaltiesImpl.sol";
import "./LibPart.sol";
import "./LibRoyalties.sol";
import "./Pausable.sol";
import "./TRSR.sol";

contract TreasureHuntGame is ERC721Enumerable, Ownable, RoyaltiesImpl, Pausable {
    using Strings for uint256;

    TRSR public trsr;
    //mapping accounts autorise call fonction owner
    mapping(address => bool) controllers;
    string public baseURI;
    // Time to start mint
    uint256 public startTime;
    string public notRevealedURI;
    bool public revealed = false;
    // Open mint Gen 1 with $TRSR
    bool public nextGen = false;
    string public baseExtension = ".json";
    // Cost start buy nft Avax
    uint256 public cost = 1.5 ether;
    // Max supply
    uint256 public maxSupply = 20000;
    // Amout per transaction
    uint256 public maxMintAmount = 10;
    // Number buy with avax
    uint256 public paidTokens = 10000;
    // Price mint in TRSE
    uint public priceToBuyTRSR = 25000;
    // Reserve for giveaway
    uint public premintLimite = 500;
    // Total mint giveaway
    uint public totalPremint = 0;
    // Variable interface Tax
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // Royalties address
    address public royaltiesAddress;
    address payable royaltiesAddressPayable = payable(royaltiesAddress);
    address public multiSign = 0x1fC9f18A1E15707F3f7c8EfFc216Dab478dF8724;
    // Mapping Autorize address mint giveaway
    mapping(address=>FreeMint) freeSeamPerWallet;
    // struct to store a stake's owner, amount values
    struct FreeMint {
        address owner;
        uint amount;
    }

    constructor(string memory _initBaseURI, string memory _notRevealedURI, address _royaltiesAddress, uint _startTime, address _trsr) ERC721("SeaMan", "SEAM")
    {
        setBaseURI(_initBaseURI);
        notRevealedURI = _notRevealedURI;
        setAddressRoyalties(_royaltiesAddress);
        setStartTime(_startTime);
        trsr = TRSR(_trsr);
    }


    function mint(address to, uint256 mintAmount) public payable whenNotPaused {
        uint256 supply = totalSupply() + (premintLimite - totalPremint);
        require(block.timestamp >= startTime, "Mint is not start");
        require(mintAmount > 0, "Please at least one");
        require(mintAmount <= maxMintAmount, "leave some of those for everybody else");
        require(supply + mintAmount <= maxSupply, "Oh no all NFT is sold");

        if (supply  < paidTokens) {
            require(supply + mintAmount <= paidTokens, "All tokens on-sale already sold in Avax");

            if (msg.sender != owner())
                require(msg.value >= cost * mintAmount, "Price too low");
        } else {
            require(nextGen, "Please wait until gen 1 is available");
            require(msg.value == 0);
        }

        uint256 totalTrsrCost = 0;
        for (uint256 i = 1; i <= mintAmount; i++) {
            totalTrsrCost += mintCost(supply+i);
            if (totalTrsrCost > 0) trsr.burn(msg.sender, totalTrsrCost);
            _safeMint(to, supply + i);
            // royalties fixed 5%
            setRoyalties(supply+i,royaltiesAddressPayable,500);

        }
    }

    function mintGiveAway(address to, uint mintAmount) public payable whenNotPaused {
        require(freeSeamPerWallet[to].owner == msg.sender, "Sorry you are not in the list");
        require(freeSeamPerWallet[to].amount > 0, "Sorry you no longer have FreeMint");
        require(block.timestamp >= startTime, "Mint is not start");
        require(mintAmount > 0, "Please at least one");
        require(mintAmount <= freeSeamPerWallet[to].amount, "leave some of those for everybody else");
        require(totalPremint + mintAmount <= premintLimite, "Oh no all NFT is sold");

        for (uint256 i = 1; i <= mintAmount; i++) {
            _safeMint(to, totalPremint + i);
            freeSeamPerWallet[to].amount -= 1;
            // royalties fixed 5%
            setRoyalties(totalPremint+i,royaltiesAddressPayable,500);
            totalPremint += 1;
        }
    }

    // the first 10 000 are paid in AVAX
    // the next 10 001 are 20 000 $TRSR
    function mintCost(uint256 tokenId) internal view returns (uint256 costReturn) {
        if (tokenId <= paidTokens) return 0;
        if (tokenId <= paidTokens + 10000) return priceToBuyTRSR;
    }

    function getCategorieSeam(uint tokenId) public view returns(uint categorie){
        if (tokenId <= paidTokens) return 1;
        if (tokenId <= paidTokens + 10000) return 2;
    }

    function burn(uint256 tokenId) external  {
        require(controllers[msg.sender], "Only controllers can burn nft");
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setRoyalties(uint tokenId, address payable royaltiesRecipientAddress, uint96 percentageBasisPoints ) private {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0].value = percentageBasisPoints;
        royalties[0].account = royaltiesRecipientAddress;
        _saveRoyalties(tokenId, royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if (interfaceId == LibRoyalties._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(revealed, "Not transferable before reveal");
        if (!controllers[msg.sender])
            require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    // --- For Admin ---
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        startTime = _newStartTime;
    }

    function setAddressRoyalties (address _newRoyaltiesAddress) public onlyOwner {
        royaltiesAddressPayable = payable(_newRoyaltiesAddress);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function addAutorise(address[] memory newsAddress, uint[] memory newsAmount) public onlyOwner {
        for(uint i = 0; i < newsAddress.length; i++) {
            freeSeamPerWallet[newsAddress[i]].owner =  newsAddress[i];
            freeSeamPerWallet[newsAddress[i]].amount = newsAmount[i];
        }
    }

    function setNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setPriceToBuyTRSR (uint newPrice) public onlyOwner {
        priceToBuyTRSR = newPrice;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function OpenGen1() external onlyOwner {
        nextGen = true;
    }

    function withdraw() public payable {
        require(msg.sender == multiSign, "Sorry your are not Multisign");
        require(payable(msg.sender).send(address(this).balance));
    }

    function approve(address account, address to, uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            account == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(revealed, "Not transferable before reveal");
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(revealed, "Not transferable before reveal");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TRSR is ERC20, Ownable {

    uint256 public MAXIMUM_GLOBAL_TOKEN = 10000000000 ether; // 100 000 000 000 $TRSR
    uint public BURN_GLOBAL_TOKEN = 0;

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    constructor() ERC20("TRSR", "TRSR") {
        _mint(msg.sender,50000000 ether);
        _mint(address(0xC3bc6EBE8435F8af5bA23a48FF3d17012371c1c7),50000000 ether);
        _mint(address(0xF7cFE2eBC18bE1356fc7A6fD7B8bDa9db1cEA3f4) ,50000000 ether);

    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        BURN_GLOBAL_TOKEN += amount;
        _burn(from, amount);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function getMaximunGlobalToken() external view returns(uint total) {
        return MAXIMUM_GLOBAL_TOKEN;
    }

    function approve( address owner,address spender,uint256 amount) public
    {
        require(controllers[msg.sender], "Only controllers approve");
        _approve(owner,spender,amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AbstractRoyalties.sol";
import "./Royalties.sol";

contract RoyaltiesImpl is AbstractRoyalties, Royalties {

    function getRaribleRoyalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

interface Royalties {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleRoyalties(uint256 id) external view returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyalties {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

import "./Context.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

abstract contract AbstractRoyalties {
    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}