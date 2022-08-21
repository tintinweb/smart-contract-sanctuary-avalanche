// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Counters.sol";
import "./IERC20.sol";
import "./Ownable.sol";


contract MigratorReciever is Ownable{

struct AvaxDetail{
        uint256 cities;
        uint256 mansions;
        uint256 districts;
        uint256 BIP;
        uint256 playmats;
        //uint256 VIPNft;
        address user;
        address destinationAddress;
    }
    

    struct RequiredNFTDetail{
        uint8 redChains;
        uint8 platChains;
        uint8 blackChain;
        uint256 scarletToken;
        uint256 rlc;
        address user;
        address destinationAddress;
    }
    mapping(uint256  => RequiredNFTDetail) private requiredNFTDetails;
    mapping(address => AvaxDetail) private avaxDetails; 
    mapping (address => bool) private IsMigrated;
    address private tokenAddress ;
    uint256 private migrationCount;

    constructor(address allowedToken){
        tokenAddress = allowedToken;
        migrationCount = 0; 
    }

    function recieveTokens(AvaxDetail memory adetail, RequiredNFTDetail memory rDetails ) public 
    {
        //AvaxDetail memory avDetail = AvaxDetail(noCities, noMansions, noDistricts, noBIPs, noPlaymates, noVIPNfts, msg.sender, _avaxDestinAddress);
        require(!IsMigrated[msg.sender], "Already migrated");
        avaxDetails[msg.sender] = adetail; 
        requiredNFTDetails[migrationCount] = rDetails;
        IsMigrated[msg.sender] = true;
        migrationCount++;
    }

    function ownerTokenWithdraw(address destinationAddress) public onlyOwner{
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(destinationAddress,balance);
    }

    function ownerCurrencyWithdraw (address destinationAddress) public onlyOwner{
        payable(destinationAddress).transfer(address(this).balance);
    }

    function getTokenBalance() public view returns(uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getCurrencyBalance() public view returns(uint256){
        return address(this).balance;
    } 
    function getTotalListCount() public view returns(uint256){
        return migrationCount;
    }

    function getinvestmentList(uint256 page , uint256 size) public view returns(RequiredNFTDetail[] memory){
        uint256 ToSkip = page*size;  //to skip
        uint256 count = 0 ; 
        uint256 EndAt=migrationCount>ToSkip+size?ToSkip+size:migrationCount;
        require(ToSkip<migrationCount, "Overflow Page");
        require(EndAt>ToSkip,"Overflow page");
        RequiredNFTDetail[] memory tokensArray = new RequiredNFTDetail[](EndAt-ToSkip);
        for (uint256 i = ToSkip ; i < EndAt; i++) {
            tokensArray[count] = requiredNFTDetails[i];
            count++;
        }
        return tokensArray;
    }

    function setToken(address token) public onlyOwner{
        tokenAddress = token;
    }
    function getToken() public view returns(address){
        return tokenAddress;
    }

    // function receiveTokens (
    //     uint256 noCities, uint256 noMansions, uint256 noDistricts, uint256 noBIPs, uint256 noPlaymates, uint256 noVIPNfts, address _avaxDestinAddress,
    //     uint8 noRedChains, uint8 noPlatChains, uint8 noBlackChain, uint256 noScarletToken, uint8 noRedLightLink, address _requireDestinAddress) public
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}