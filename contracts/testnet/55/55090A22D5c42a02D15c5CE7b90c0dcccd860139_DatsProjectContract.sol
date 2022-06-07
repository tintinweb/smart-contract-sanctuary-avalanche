/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;


contract DatsProjectContract{

    struct User {
        address userAddress;
        bool isActive;
    }

    struct DDos {
        uint256 id;
        address user;
        bool isApprove;
        uint8 trafficScale;
    }

    struct SuperComputer {
        uint256 id;
        address user;
        bool isApprove;
        uint8 cpuValue;
    }

    struct CyberSecurity {
        uint256 id;
        address user;
        bool isApprove;
        bool webSecurity;
        bool serverSecurity;
        bool ransomwareResearch;
        bool malwareResearch;
    }

    struct Vulnerability {
        uint256 id;
        address user;
        bool isApprove;
        bool webPenetration;
        bool serverPenetration;
        bool scadaPenetration;
        bool blockchainPenetration;
        bool contractPenetration;
    }

    struct Blockchain {
        uint256 id;
        address user;
        bool approveAttackPrevention;
    }

    struct UserData {
        DDos[] dDoses;
        SuperComputer[] superComputers;
        CyberSecurity[] cyberSecurities;
        Vulnerability[] vulnerabilities;
        Blockchain[] blockchains;
    }

    address public owner;

    mapping(address => DDos) public ddoses;
    DDos[] public ddosArray;

    mapping(address => SuperComputer) public supers;
    SuperComputer[] public superArray;

    mapping(address => CyberSecurity) public cybers;
    CyberSecurity[] public cyberArray;

    mapping(address => Vulnerability) public vulnerabilities;
    Vulnerability[] public vulnerabilityArray;

    mapping(address => Blockchain) public blockchains;
    Blockchain[] public blockchainArray;

    constructor(){
        owner = msg.sender;
    }

    function getAllUserData() public view returns(UserData memory){
        require(owner == msg.sender, "You are not authorized.");

        UserData memory userData = UserData({
            dDoses: ddosArray,
            superComputers: superArray,
            cyberSecurities: cyberArray,
            vulnerabilities: vulnerabilityArray,
            blockchains: blockchainArray
        });

        return userData;
    }

    function saveDDos(bool _isApprove, uint8 _trafficScale) external {

        DDos memory ddos = DDos({
            id: ddosArray.length + 1,
            user: msg.sender,
            isApprove: _isApprove,
            trafficScale: _trafficScale
        });

        if(ddoses[msg.sender].id == 0)
            ddosArray.push(ddos);

        ddoses[msg.sender] = ddos;  
        
    }

    function deleteDDos() external {
        delete(ddoses[msg.sender]);
    }

    function getDDos() external view returns (DDos memory) {
        return ddoses[msg.sender];
    }

    function getDDosByUser(address _user) external view returns (DDos memory){
        return ddoses[_user];
    }

    function getDDosCount() external view returns(uint256) {
        return ddosArray.length;
    }

    function saveSuperComputer(bool _isApprove, uint8 _cpuValue) external {
        SuperComputer memory superComputer = SuperComputer({
            id: superArray.length + 1,
            user: msg.sender,
            isApprove: _isApprove,
            cpuValue: _cpuValue
        });

        if(supers[msg.sender].id == 0)
            superArray.push(superComputer);

        supers[msg.sender] = superComputer;
        
    }

    function deleteSuperComputer() external {
        delete(supers[msg.sender]);
    }

    function getSuperComputer() external view returns (SuperComputer memory) {
        return supers[msg.sender];
    }

    function getSuperComputerByUser(address _user) external view returns (SuperComputer memory){
        return supers[_user];
    }

    function getSuperComputerCount() external view returns(uint256) {
        return superArray.length;
    }
    
    function saveCyberSecurity(
                bool _isApprove, 
                bool _webSecurity, 
                bool _serverSecurity, 
                bool _ransomwareResearch, 
                bool _malwareResearch) 
            external{

        CyberSecurity memory cyberSecurity = CyberSecurity({
            id: cyberArray.length + 1,
            user: msg.sender,
            isApprove: _isApprove,
            webSecurity: _webSecurity,
            serverSecurity: _serverSecurity,
            ransomwareResearch: _ransomwareResearch,
            malwareResearch: _malwareResearch
        });

        if(cybers[msg.sender].id == 0)
            cyberArray.push(cyberSecurity);
        
        cybers[msg.sender] = cyberSecurity;
        
    }

    function deleteCyberSecurity() external{
        delete(cybers[msg.sender]);
    }

    function getCyberSecurity() external view returns(CyberSecurity memory){
        return cybers[msg.sender];
    }

    function getCyberSecurityCount() external view returns(uint256){
        return cyberArray.length;
    }

    function saveVulnerability(
                bool _isApprove, 
                bool _webPenetration, 
                bool _serverPenetration, 
                bool _scadaPenetration, 
                bool _blockchainPenetration, 
                bool _contractPenetration
            ) external{

        Vulnerability memory vulnerability = Vulnerability({
            id: vulnerabilityArray.length + 1,
            user: msg.sender,
            isApprove: _isApprove,
            webPenetration: _webPenetration,
            serverPenetration: _serverPenetration,
            scadaPenetration: _scadaPenetration,
            blockchainPenetration: _blockchainPenetration,
            contractPenetration: _contractPenetration
        });

        if(vulnerabilities[msg.sender].id == 0)
            vulnerabilityArray.push(vulnerability);
        
        vulnerabilities[msg.sender] = vulnerability;
        
    }

    function deleteVulnerability() external {
        delete(vulnerabilities[msg.sender]);
    }

    function getVulnerability() external view returns(Vulnerability memory) {
        return vulnerabilities[msg.sender];
    }

    function getVulnerabilityCount() external view returns(uint256){
        return vulnerabilityArray.length;
    }

    function saveBlockchain(bool _approveAttackPrevention) external{
        Blockchain memory blockchain = Blockchain({
            id: blockchainArray.length + 1,
            user: msg.sender,
            approveAttackPrevention: _approveAttackPrevention
        });

        if(blockchains[msg.sender].id == 0)
            blockchainArray.push(blockchain); 

        blockchains[msg.sender] = blockchain;
        
    }

    function deleteBlockchain() external{
        delete(blockchains[msg.sender]);
    }

    function getBlockchain() external view returns(Blockchain memory){
        return blockchains[msg.sender];
    }

    function getBlockchainCount() external view returns(uint256){
        return blockchainArray.length;
    }

}