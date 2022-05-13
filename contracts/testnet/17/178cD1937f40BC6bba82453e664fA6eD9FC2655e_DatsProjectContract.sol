/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DatsProjectContract{

    struct DDos {
        uint256 id;
        bool isApprove;
        uint8 trafficScale;
    }

    struct SuperComputer {
        uint256 id;
        bool isApprove;
        uint8 cpuValue;
    }

    struct CyberSecurity {
        uint256 id;
        bool isApprove;
        bool webSecurity;
        bool serverSecurity;
        bool ransomwareResearch;
        bool malwareResearch;
    }

    struct Vulnerability {
        uint256 id;
        bool isApprove;
        bool webPenetration;
        bool serverPenetration;
        bool scadaPenetration;
        bool blockchainPenetration;
        bool contractPenetration;
    }

    struct Blockchain {
        uint256 id;
        bool approveAttackPrevention;
    }

    address public owner;

    mapping(address => DDos) public ddoses;
    address[] public ddosUsers;

    mapping(address => SuperComputer) public supers;
    address[] public superUsers;

    mapping(address => CyberSecurity) public cybers;
    address[] public cyberUsers;

    mapping(address => Vulnerability) public vulnerabilities;
    address[] public vulnerabilityUsers;

    mapping(address => Blockchain) public blockchains;
    address[] public blockchainUsers;

    constructor(){
        owner = msg.sender;
    }


    function saveDDos(bool _isApprove, uint8 _trafficScale) external {

        DDos memory ddos = DDos({
            id: ddosUsers.length + 1,
            isApprove: _isApprove,
            trafficScale: _trafficScale
        });

        ddoses[msg.sender] = ddos; 
        ddosUsers.push(msg.sender);
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
        return ddosUsers.length;
    }

    function saveSuperComputer(bool _isApprove, uint8 _cpuValue) external {
        SuperComputer memory superComputer = SuperComputer({
            id: superUsers.length + 1,
            isApprove: _isApprove,
            cpuValue: _cpuValue
        });

        supers[msg.sender] = superComputer;
        superUsers.push(msg.sender);
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
        return superUsers.length;
    }
    
    function saveCyberSecurity(
                bool _isApprove, 
                bool _webSecurity, 
                bool _serverSecurity, 
                bool _ransomwareResearch, 
                bool _malwareResearch) 
            external{

        CyberSecurity memory cyberSecurity = CyberSecurity({
            id: cyberUsers.length + 1,
            isApprove: _isApprove,
            webSecurity: _webSecurity,
            serverSecurity: _serverSecurity,
            ransomwareResearch: _ransomwareResearch,
            malwareResearch: _malwareResearch
        });

        cybers[msg.sender] = cyberSecurity;
        cyberUsers.push(msg.sender);
    }

    function deleteCyberSecurity() external{
        delete(cybers[msg.sender]);
    }

    function getCyberSecurity() external view returns(CyberSecurity memory){
        return cybers[msg.sender];
    }

    function getCyberSecurityCount() external view returns(uint256){
        return cyberUsers.length;
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
            id: vulnerabilityUsers.length + 1,
            isApprove: _isApprove,
            webPenetration: _webPenetration,
            serverPenetration: _serverPenetration,
            scadaPenetration: _scadaPenetration,
            blockchainPenetration: _blockchainPenetration,
            contractPenetration: _contractPenetration
        });

        vulnerabilities[msg.sender] = vulnerability;
        vulnerabilityUsers.push(msg.sender);
    }

    function deleteVulnerability() external {
        delete(vulnerabilities[msg.sender]);
    }

    function getVulnerability() external view returns(Vulnerability memory) {
        return vulnerabilities[msg.sender];
    }

    function getVulnerabilityCount() external view returns(uint256){
        return vulnerabilityUsers.length;
    }

    function saveBlockchain(bool _approveAttackPrevention) external{
        Blockchain memory blockchain = Blockchain({
            id: blockchainUsers.length + 1,
            approveAttackPrevention: _approveAttackPrevention
        });

        blockchains[msg.sender] = blockchain;
        blockchainUsers.push(msg.sender);
    }

    function deleteBlockchain() external{
        delete(blockchains[msg.sender]);
    }

    function getBlockchain() external view returns(Blockchain memory){
        return blockchains[msg.sender];
    }

    function getBlockchainCount() external view returns(uint256){
        return blockchainUsers.length;
    }

}