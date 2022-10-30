// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "Ownable.sol";

/*

 _____                       ___                          
/__   \ _ __   ___   ___    / _ \  __ _  _ __ ___    ___  
  / /\/| '__| / _ \ / _ \  / /_\/ / _` || '_ ` _ \  / _ \ 
 / /   | |   |  __/|  __/ / /_\\ | (_| || | | | | ||  __/ 
 \/    |_|    \___| \___| \____/  \__,_||_| |_| |_| \___| 
                                                          
   ___                         __        ___              
  /___\ _ __    ___   /\   /\ / _\      /___\ _ __    ___ 
 //  //| '_ \  / _ \  \ \ / / \ \      //  //| '_ \  / _ \
/ \_// | | | ||  __/   \ V /  _\ \    / \_// | | | ||  __/
\___/  |_| |_| \___|    \_/   \__/    \___/  |_| |_| \___|
                                                          
Discord: http://discord.io/PlantATree
Website: https://treegame.live/onevsone.html
*/

interface ERC721Interface {
    function ownerOf(uint256) external view returns (address);
}

interface PlantATreeRewardSystem {
    function PlantATree(address ref) external payable;
}

contract TreeGameOneVsOne is VRFConsumerBaseV2, Ownable {
    // [Chainlink VRF config block]
    VRFCoordinatorV2Interface COORDINATOR;
    // subscription ID.
    uint64 s_subscriptionId;

    bytes32 keyHash;

    uint32 callbackGasLimit = 2500000; //100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant numWords = 1;
    // [End of Chainlink VRF config block]

    // Win percentages and Race track values

    enum SORT_TYPE {
        TOTAL_WIN,
        TOTAL_GAMES
    }

    uint256[] private WIN_PERCENTAGES = [0, 50, 100];

    uint256 public constant MAX_NFT_SUPPLY = 600;
    uint256 public constant PLAYERS_COUNT = 2;
    uint256 private pvtIndex;
    uint256 private pvtGamesCount;

    // TressGame Data Structure

    struct Game {
        uint256 id;
        uint256[PLAYERS_COUNT] players;
        uint256 timestamp;
        uint256 winnerTokenId;
        uint256 map;
        uint256 text;
        uint256 rndResult;
    }

    struct TreesToken {
        uint256 tokenId;
        uint256 totalGamesPlayed;
        uint256 totalWonGames;
        uint256 totalLostGames;
        uint256 balance;
    }

    // Dev addresses
    address public artist;
    address public dev;
    address public PAT_Address;
    address public ref;



    // Total Games Value
    uint256 public totalGamesValues = 0 ether;

    // Balances & Shares

    uint256 public teamBalance = 0 ether;

    // NFT TressContract . Used to check ownership of a token
    ERC721Interface internal TREES_CONTRACT;
    address public TreesNFTContractAddress;

    //  Minimum Game Value set to 2. This means minimum entry fee is 1
    uint256 public constant MINIMUM_GAME_VALUE = 0.2 ether; //2 ether;

    // Initial values of total game value and their disturbtions. Initial values don't matter here as it has to be passed in the constructor anyway.
    uint256 public GAME_VALUE = 0.2 ether; //2 ether;
    // disturbtions based on total game value
    uint256 public ENTRY_FEE = 1 ether; //1 ether;
    uint256 public WIN_SHARE = 1.75 ether; //1.75 ether;
    uint256 public TEAM_SHARE = 0.15 ether; //0.15 ether;
    uint256 public DynamicRewardsSystem_Share = 0.1 ether; //0.1 ether;
    uint256 public DynamicRewards_Balance = 0;

    // Players waiting to start the game
    mapping(uint256 => uint256) public pendingPlayers;
    uint256 public pendingPlayersCount;

    // Games & Tokens data
    mapping(uint256 => TreesToken) public treesTokens;
    mapping(uint256 => Game) public games;
    uint256 public gamesCounter;
    bool public GameIsAcive = false;

    // Random range minimum and maximum
    uint256 private constant min = 1;
    uint256 private constant max = 100;

    // VRF Request Id => Games Ids
    mapping(uint256 => uint256) public requestIdToGameId;

    // Limit of top trees
    uint256 public constant TOP_LIMIT = 30;

    // index to tokenId
    mapping(uint256 => uint256) public topTokensBytotalWonGames;
    mapping(uint256 => uint256) public topTokensByTotalGamesPlayed;

    // Game Events
    event GameJoined(uint256 _TreeTokenId);
    event GameStarted(Game _game);
    event GameEnded(uint256 _GameId, uint256 _TreeTokenId);

    // Config Events
    event VRFConfigUpdated(
        uint64 subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    );
    event EntryFeeUpdated(uint256 totalGameValue);
    event TeamAddressesUpdated(address artist, address dev);

    constructor(
        uint256 _gamesCounter,
        uint64 subscriptionId,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address TreesNFTAddress_,
        address _PAT_Address,
        address _ref,
        address _dev,
        address _artist
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        require(TreesNFTAddress_ != address(0));
        require(_vrfCoordinator != address(0));
        TreesNFTContractAddress = TreesNFTAddress_;
        TREES_CONTRACT = ERC721Interface(TreesNFTContractAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        PAT_Address = _PAT_Address;
        ref = _ref;
        setTeamAddresses(_artist, _dev);

        //scores migrated from old contract
        gamesCounter = _gamesCounter;
        totalGamesValues = gamesCounter * GAME_VALUE;
    }

    // change VRF config if needed. for example, if subscription Id changed ...etc.
    function setVRFConfig(
        uint64 subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    ) external onlyOwner {
        s_subscriptionId = subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
        emit VRFConfigUpdated(
            subscriptionId,
            _callbackGasLimit,
            _requestConfirmations,
            _keyHash
        );
    }

    // Requets a random number from ChainLink
    function getRandomNumber() internal returns (uint256 requestId) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    // Receive the requested random number from ChainLink
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 gameId = requestIdToGameId[requestId];
        uint256 randomResult = (randomWords[0] % max) + min;
        pickWinner(gameId, randomResult);
    }

    // get game map
    function getMap(uint256 baseNum) internal pure returns (uint256) {
        return ((baseNum * 7) % 4) + 1;
    }

    // get game text
    function getText(uint256 baseNum) internal pure returns (uint256) {
        return (baseNum % 10) + 1;
    }

    // get game effect
    function getEffect(uint256 baseNum, uint256 MBTokenId)
        internal
        pure
        returns (uint256)
    {
        return ((baseNum + MBTokenId) % 6) + 1;
    }

    // Select the winner based on the random result considering total games played for each player
    function pickWinner(uint256 gameId, uint256 randomResult) internal {
        Game storage game = games[gameId];
        game.winnerTokenId = getWinnerTokenId(gameId, randomResult);
        game.rndResult = randomResult;
        game.timestamp = block.timestamp;
        // randomResult is between 1 and 100
        game.map = getMap(randomResult + gamesCounter);
        game.text = getText(randomResult + gamesCounter + 3);

        // Winner and Losers shares
        calculateShares(gameId);

        // Keep track of top winners
        bool alreadyAdded = false;
        uint256 smallestTokenIdIndex = 1; //topTokensBytotalWonGames[1];
        if (
            topTokensBytotalWonGames[smallestTokenIdIndex] == game.winnerTokenId
        ) {
            alreadyAdded = true;
        }
        if (!alreadyAdded) {
            for (uint256 k = 2; k <= TOP_LIMIT; k++) {
                if (topTokensBytotalWonGames[k] == game.winnerTokenId) {
                    alreadyAdded = true;
                    break;
                }
                if (
                    treesTokens[topTokensBytotalWonGames[k]].totalWonGames <
                    treesTokens[topTokensBytotalWonGames[smallestTokenIdIndex]]
                        .totalWonGames
                ) {
                    smallestTokenIdIndex = k;
                }
            }
        }
        // update only if it wasn't added before
        if (
            !alreadyAdded &&
            treesTokens[topTokensBytotalWonGames[smallestTokenIdIndex]]
                .totalWonGames <
            treesTokens[game.winnerTokenId].totalWonGames
        ) {
            topTokensBytotalWonGames[smallestTokenIdIndex] = game.winnerTokenId;
        }

        emit GameEnded(gameId, games[gameId].winnerTokenId);
    }

    // sort players by total games played . index 0 -> lowest . index 3 -> highest
    function sortPlayersByTotalGamesPlayed(uint256 gameId) internal {
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (
                    treesTokens[game.players[i]].totalGamesPlayed >
                    treesTokens[game.players[j]].totalGamesPlayed
                ) {
                    uint256 temp = game.players[i];
                    game.players[i] = game.players[j];
                    game.players[j] = temp;
                }
            }
        }
    }

    // get the winner token id based on WIN_PERCENTAGES and the random result
    function getWinnerTokenId(uint256 gameId, uint256 randomResult)
        internal
        view
        returns (uint256 winnerTokenId)
    {
        require(
            randomResult >= 1 && randomResult <= 100,
            "Random result is out of range"
        );
        uint256 l = WIN_PERCENTAGES.length;
        for (uint256 i = 1; i < l; i++) {
            if (
                randomResult > WIN_PERCENTAGES[i - 1] &&
                randomResult <= WIN_PERCENTAGES[i]
            ) {
                return games[gameId].players[i - 1];
            }
        }
    }

    // get games as array within the range from-to
    function getGames(uint256 gameIdFrom, uint256 gameIdTo)
        external
        view
        returns (Game[] memory)
    {
        uint256 length = gameIdTo - gameIdFrom;
        Game[] memory gamesArr = new Game[](length + 1);
        uint256 j = 0;
        for (uint256 i = gameIdFrom; i <= gameIdTo; i++) {
            gamesArr[j] = games[i];
            j++;
        }
        return gamesArr;
    }

    // get top Trees by wins or total played games
    function getTopTreesNFT(SORT_TYPE sortType)
        external
        view
        returns (TreesToken[] memory)
    {
        TreesToken[] memory treesArr = new TreesToken[](TOP_LIMIT);
        if (sortType == SORT_TYPE.TOTAL_WIN) {
            for (uint256 i = 1; i <= TOP_LIMIT; i++) {
                treesArr[i - 1] = treesTokens[topTokensBytotalWonGames[i]];
            }
        }
        if (sortType == SORT_TYPE.TOTAL_GAMES) {
            for (uint256 i = 1; i <= TOP_LIMIT; i++) {
                treesArr[i - 1] = treesTokens[topTokensByTotalGamesPlayed[i]];
            }
        }
        return treesArr;
    }

    // get players by game
    function getGamePlayers(uint256 gameId)
        external
        view
        returns (uint256[PLAYERS_COUNT] memory)
    {
        return games[gameId].players;
    }

    // calculate the players (including the winner), community and dev shares
    function calculateShares(uint256 gameId) internal {
        Game storage game = games[gameId];
        // Winner specific
        // Add the wining share to the winner token
        uint256 winnerTokenId = game.winnerTokenId;
        treesTokens[winnerTokenId].totalWonGames++;
        treesTokens[winnerTokenId].totalGamesPlayed++;
        treesTokens[winnerTokenId].balance += WIN_SHARE;

        // Distribute the losing share to the losers tokens
        uint256 l = game.players.length;
        for (uint256 i = 0; i < l; i++) {
            uint256 tokenId = game.players[i];
            if (tokenId != winnerTokenId) {
                treesTokens[tokenId].totalGamesPlayed++;
                treesTokens[tokenId].totalLostGames++;
            }
        }

        // Dev share
        teamBalance += TEAM_SHARE;
    }

    // Claim the balance of a Trees token
    function claim(uint256 _tokenId) external {
        require(
            _tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY,
            "Tresstoken Id must be between 1 and 600"
        );
        require(
            ownerOfTreesNFT(_tokenId),
            "Please make sure you own this Tresstoken"
        );
        uint256 mbBalance = treesTokens[_tokenId].balance;
        require(mbBalance > 0, "Balance is zero");
        require(
            address(this).balance >= mbBalance,
            "Insufficient contract balance"
        );
        treesTokens[_tokenId].balance = 0;
        payable(msg.sender).transfer(mbBalance);
    }

    // Claim the balance of the dev
    function devClaim() public  {
        require(_msgSender() == artist || _msgSender() == dev , "not allowed");
        require(artist != address(0), "artist address can not be zero");
        require(dev != address(0), "dev address can not be zero");
        require(teamBalance > 0, "team Balance must be greater than zero");
        uint256 _teamBalance = teamBalance;
        teamBalance = 0;
        uint256 _artist = _teamBalance / 3; //5%
        _teamBalance = _teamBalance - _artist;
        uint256 _dev = _teamBalance; //10%
        payable(artist).transfer(_artist);
        payable(dev).transfer(_dev);
    }

    // Set addresses of the team
    function setTeamAddresses(address _artist, address _dev) public onlyOwner {
        require(
            _artist != address(0) && _dev != address(0),
            "address can not be zero"
        );
        artist = _artist;
        dev = _dev;

        emit TeamAddressesUpdated(_artist, _dev);
    }

    // Set Entry Fee
    function setEntryFeeWithGameShare(
        uint256 _totalGameValue,
        uint256 _ENTRY_FEE,
        uint256 _WIN_SHARE,
        uint256 _TEAM_SHARE,
        uint256 _DyanmicRewardsSystem_Share
    ) public onlyOwner {
        require(_totalGameValue >= MINIMUM_GAME_VALUE);

        // set the game value
        GAME_VALUE = _totalGameValue;
        ENTRY_FEE = _ENTRY_FEE;
        TEAM_SHARE = _TEAM_SHARE;
        WIN_SHARE = _WIN_SHARE;
        DynamicRewardsSystem_Share = _DyanmicRewardsSystem_Share;

        if (
            WIN_SHARE + TEAM_SHARE + DynamicRewardsSystem_Share  !=
            _totalGameValue
        ) {
            revert();
        }

        emit EntryFeeUpdated(_totalGameValue);
    }

    // Join a new game
    function joinGame(uint256 _tokenId) external payable {
        require(GameIsAcive == true, "Game not Active");

        require(_tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY);
        require(ownerOfTreesNFT(_tokenId));
        require(
            treesTokenIsNotPlaying(_tokenId),
            "This Tress token is already in a game"
        );
        require(
            pendingPlayersCount < PLAYERS_COUNT,
            "Please wait few seconds and try joining again"
        );
        require(msg.value == ENTRY_FEE, "ENTRY FEE incorrect");

        pendingPlayersCount++;
        pendingPlayers[pendingPlayersCount] = _tokenId;
        treesTokens[_tokenId].tokenId = _tokenId;

        // Keep track of top by total games played
        // get top of the 2 players
        uint256 playerTokenId = _tokenId;
        bool alreadyAdded = false;
        uint256 smallestTokenIdIndex = 1;
        if (
            topTokensByTotalGamesPlayed[smallestTokenIdIndex] == playerTokenId
        ) {
            alreadyAdded = true;
        }
        if (!alreadyAdded) {
            for (uint256 k = 2; k <= TOP_LIMIT; k++) {
                if (topTokensByTotalGamesPlayed[k] == playerTokenId) {
                    alreadyAdded = true;
                    break;
                }
                if (
                    treesTokens[topTokensByTotalGamesPlayed[k]]
                        .totalGamesPlayed <
                    treesTokens[
                        topTokensByTotalGamesPlayed[smallestTokenIdIndex]
                    ].totalGamesPlayed
                ) {
                    smallestTokenIdIndex = k;
                }
            }
        }
        // update only if it wasn't added before
        if (
            !alreadyAdded &&
            treesTokens[topTokensByTotalGamesPlayed[smallestTokenIdIndex]]
                .totalGamesPlayed <
            treesTokens[playerTokenId].totalGamesPlayed
        ) {
            topTokensByTotalGamesPlayed[smallestTokenIdIndex] = playerTokenId;
        }

        emit GameJoined(_tokenId);

        if (pendingPlayersCount == PLAYERS_COUNT) {
            // Start the game as we have already 2 players
            startGame();
        }
    }


    function setTreeNFTContract(address TreesNFTAddress_) public onlyOwner {
        TreesNFTContractAddress = TreesNFTAddress_;
        TREES_CONTRACT = ERC721Interface(TreesNFTContractAddress);
    }

    function ownerOfTreesNFT(uint256 _tokenId) internal view returns (bool) {
        address tokenOwnerAddress = TREES_CONTRACT.ownerOf(_tokenId);
        return (tokenOwnerAddress == msg.sender);
    }

    function treesTokenIsNotPlaying(uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pendingPlayersCount; i++) {
            if (pendingPlayers[i + 1] == _tokenId) {
                return false;
            }
        }
        return true;
    }

    // Start the game and clear daata including pending players for a new game
    function startGame() private {
        gamesCounter++;
        totalGamesValues += GAME_VALUE;
        uint256[PLAYERS_COUNT] memory _players;
        _players[0] = pendingPlayers[1];
        _players[1] = pendingPlayers[2];

        games[gamesCounter] = Game(gamesCounter, _players, 0, 0, 0, 0, 0);

        // reset
        pendingPlayers[1] = 0;
        pendingPlayers[2] = 0;
        pendingPlayersCount = 0;
        // end

        emit GameStarted(games[gamesCounter]);

        uint256 requestId = getRandomNumber();
        requestIdToGameId[requestId] = gamesCounter;

        // feed the DyanmicRewardsSystem
        DynamicRewards_Balance += DynamicRewardsSystem_Share;
    }

    function processGame(uint256 gameId, uint256 rnd) internal {
        pickWinner(gameId, rnd);
    }

    function setGameActive(bool _isActive) public onlyOwner {
        GameIsAcive = _isActive;
    }

    function feedRewardsPool() public {
        require(DynamicRewards_Balance >= 0.1 ether, "no enough balance");
            PlantATreeRewardSystem(PAT_Address).PlantATree{
                value: DynamicRewards_Balance
            }(ref);
            DynamicRewards_Balance = 0;
    }

    function setConfig(
        address PATaddr,
        address _ref
    ) external onlyOwner {
        if (PATaddr != address(0)) PAT_Address = PATaddr;
        if (_ref != address(0)) ref = _ref;
    }


}