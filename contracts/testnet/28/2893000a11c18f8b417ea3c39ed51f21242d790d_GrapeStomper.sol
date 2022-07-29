/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-28
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// Interface for the GrapeRewardsPool
interface GrapeRewardsPool {
    function pendingShare(uint256 pid, address user) external view returns(uint256);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}

// Interface for the TraderJoeXYZ Router
interface TraderJoe {
    function SwapExactTokensforAVAX(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) external;
}

// Main
contract GrapeStomper {
    
    // Contracts for tokens
    address grapeToken = address(0x5541D83EFaD1f281571B343977648B75d95cdAC2); // Contract address for GRAPE
    address wineToken = address(0xC55036B5348CfB45a932481744645985010d3A44); // Contract address for WINE
    address mimToken = address(0x130966628846BFd36ff31a822705796e8cb8C18D); // Contract address for MIM
    address wavaxToken = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); // Contract address for WAVAX

    // Contracts for GRAPE rewards and TraderJoe
    address stakeContract = address(0x28c65dcB3a5f0d456624AFF91ca03E4e315beE49); // Contract address of the GRAPE Reward Pools
    address joeRouter = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4); // TraderJoe XYZ router

    // Contract owner
    address owner;
    address dev;
    bool doStake;
    bool doTrade;

    // Leaderboard and score state variables
    mapping(address=>uint256) highScores;
    mapping(address=>bytes32) activeGames;
    struct scoreEntry {
        address player;
        uint256 score;
    }
    uint256 costToPlay = 5*1e17;
    scoreEntry[10] leaderboard;

    // TODO - Remove tokenAddress when deploying to mainnet
    constructor() {
        owner = msg.sender;
        dev = msg.sender;        
    }

    // Modifiers
    modifier OwnerOnly {
        require(msg.sender == owner, "[Ownable] Access Denied");
        _;
    }

    modifier DevOnly {
        require(msg.sender == dev, "[Ownable] Access Denied");
        _;
    }

    // Getters
    function GetOwner() public view returns(address) {
        return owner;
    }

    function GetDev() public view returns(address) {
        return dev;
    }

    function GetTokenContract() public view returns(address) {
        return grapeToken;
    }

    // Returns the amount of GRAPE currently in the winnings pot
    function GetPot() public view returns(uint256) {        
        uint256 balance = ERC20(grapeToken).balanceOf(address(this));
        return balance;
    }

    // Setters
    function SetOwner(address newOwner) public OwnerOnly {        
        owner = newOwner;
    }

    function SetDev(address newDev) public OwnerOnly DevOnly {        
        dev = newDev;
    }

    function SetTokenContract(address newTC) public OwnerOnly DevOnly {
        grapeToken = newTC;
    }

    /*
        Update the cost to play the game, minimum cost is .01 GRAPE
    */
    function SetCost(uint256 newCost) public OwnerOnly DevOnly {        
        costToPlay = newCost;
    }

    /*
        Toggles whether the contract will deposit the grape
        into the Grape Single Staking Reward Pool
    */
    function ToggleStake() public OwnerOnly returns(bool) {        
        doStake = !doStake;
        return doStake;
    }

    /*
        Toggles whether the contract will sell the wine
        for AVAX using the TraderJoe router
    */
    function ToggleTrade() public OwnerOnly returns(bool) {
        doTrade = !doTrade;
        return doTrade;
    }

    /* 
        Deposit grape into the contract to start the game
    */
    function PlayGame() public returns(bytes32) {                        
        require(ERC20(grapeToken).allowance(msg.sender, address(this)) >= costToPlay, "[Allowance] Please approve the game contract to spend .5 GRAPE");
        ERC20(grapeToken).transferFrom(msg.sender, address(this), costToPlay);
        activeGames[msg.sender] = keccak256(abi.encode(msg.sender, block.number));
        return activeGames[msg.sender];
    }

    // Record a users score to the global array and leaderboard
    function RecordScore(bytes32 hash, uint256 score) public {
        //require(player != address(0), "[Address] Player address cannot be 0");
        require(score >= 1, "[Score] Minimum score must be above 0");
        require(activeGames[msg.sender] == hash, "[Game] User doesn't have any active games...");

        // Clear the hash for this players game
        activeGames[msg.sender] = 0;

        // Update individual player high score
        if(score > highScores[msg.sender])
            highScores[msg.sender] = score;

        // Check to see if the user already has a score on the leaderboard
        // and remove it if his new score is better. 
        for(uint i = 0; i < 10; i++) {
            if(leaderboard[i].player == msg.sender) {
                if(leaderboard[i].score > score)
                    return;
                // Shift existing entries up
                for(uint j = i; j < 9; j++)
                    leaderboard[j] = leaderboard[j+1];
                // Clear the duplicate final entry
                leaderboard[9].player = address(0);
                leaderboard[9].score = 0;                
            }
        }

        // Check player score against the leaderboard scores
        for(uint i = 0; i < 10; i++) {
            // If this entry is blank fill it and break
            if(leaderboard[i].player == address(0)) {
                leaderboard[i].player = msg.sender;
                leaderboard[i].score = score;                
                break;
            }
            // If this entry is greater than another entry
            // shift it down and put this entry in its place
            else if(score > leaderboard[i].score) {
                // Shift
                for(uint j = 9; j > i; j--)
                    leaderboard[j] = leaderboard[j-1];

                leaderboard[i].player = msg.sender;
                leaderboard[i].score = score;
                break;
            }
        }
    }

    /*
        Runs every 7 days via autonomous docker instance

        Takes the winnings pot and distributes it as follows:
        25% - Burned
        10% - Dev
        15% - Staked in GRAPE Single Stake Pool, contract
            sells the wine to help pay for gas
        50% - Distributed amongst the top 3 players
            25% - 1st Place
            15% - 2nd Place
            10% - 3rd Place
    */
    function DistributeWinnings() public OwnerOnly {
        GrapeRewardsPool pool = GrapeRewardsPool(stakeContract);
        TraderJoe router = TraderJoe(joeRouter);

        // Get the balance of the winnings pot
        uint256 grapeBalance = ERC20(grapeToken).balanceOf(address(this));
        // Calculate dev profit
        uint256 devAmount = (grapeBalance/20)*2;
        // Calculate amount to stake
        uint256 stakeAmount = (grapeBalance/20)*3;
        // Calculate winnings
        uint256[3] memory winnings = [
            (grapeBalance/20)*5,
            (grapeBalance/20)*3,
            (grapeBalance/20)*2
        ];
        // Burn amount is whatever remains
        uint256 burnAmount = grapeBalance - (devAmount + stakeAmount + winnings[0] + winnings[1] + winnings[2]);

        // Transfer winnings to the winners
        ERC20(grapeToken).transfer(leaderboard[0].player, winnings[0]);
        ERC20(grapeToken).transfer(leaderboard[1].player, winnings[1]);
        ERC20(grapeToken).transfer(leaderboard[2].player, winnings[2]);

        // Pay the dev
        ERC20(grapeToken).transfer(dev, devAmount);

        // Stake
        if(doStake)
            pool.deposit(3, stakeAmount);

        if(doTrade) {
            // Convert wine to AVAX for gas
            uint256 wineBalance = ERC20(wineToken).balanceOf(address(this));
            address[] memory path = new address[](3);
            path[0] = wineToken; path[1] = mimToken; path[2] = wavaxToken;
            router.SwapExactTokensforAVAX(wineBalance, 0, path, address(this), block.timestamp);
        }
        // Finally burn the remainder
        ERC20(grapeToken).transfer(address(0xdead), burnAmount);
    }

    // Returns the highscore for a given player
    function GetHighScore() public view returns(uint256) {
        return highScores[msg.sender];
    }

    // Returns the 10 player leaderboard
    function GetLeaderboard(uint256 index) public view returns(address, uint256) {
        return ( leaderboard[index].player, leaderboard[index].score );
    }

    function ClearLeaderboard() public OwnerOnly DevOnly {
        for(uint i = 0; i < 10; i++) {
            leaderboard[i].player = address(0);
            leaderboard[i].score = 0;
        }
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function Nuke() public OwnerOnly DevOnly {
        address payable addr = payable(address(msg.sender));
        selfdestruct(addr);
    }
}