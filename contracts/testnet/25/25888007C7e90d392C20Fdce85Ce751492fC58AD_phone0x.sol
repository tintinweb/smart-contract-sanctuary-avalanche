/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title phone0x
 * @dev Implements voip nodes network management
 */
contract phone0x {
   
    struct User {
        bytes32 userVoipCredentials;
    }

    struct Node {
        address nodeId;
        bytes32 nodeIPAddress;
    }

    struct CDR {
        address addrCaller;
        address addrCallee;
        uint startCallDate;
        int32 callDuration;
        address nodeIdCallOperator;
        address nodeIdCDRWriter;
    }

    address public adminPerson;
   
    mapping(address => User) public users;

    Node[] public nodes;
    CDR[] public CDRs;
  
    /** 
     * @dev Create a new voip network.
     * @param firstNodeId first node id 
     * @param firstNodeIP first node IP
     */
    constructor(address firstNodeId, bytes32  firstNodeIP) {
        adminPerson = msg.sender;    
      
        //initiate the first node    
        nodes.push(Node({
            nodeId: firstNodeId,
            nodeIPAddress: firstNodeIP
        }));
    }

    /** 
     * @dev Create a new voip node.
     * @param nodeId node id which is the address of the node 
     * @param nodeIP  IP address or domain name of the node
     */
    function addNode(address nodeId, bytes32 nodeIP) public{
        
        require(
            msg.sender == adminPerson, "Only adminPerson can add a node."
        );

        for (uint i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeId == nodeId) {
                //if node already exists, just return.
                return;
            }
        }
        
        //add the new node
        nodes.push(Node({
            nodeId: nodeId,
            nodeIPAddress: nodeIP
        }));

    }

    /** 
     * @dev Update IP of a a voip node.
     * @param nodeId node id which is the address of the node 
     * @param nodeIP  new IP address or domain name of the node
     */
    function updateNode(address nodeId, bytes32 nodeIP) public{

        require(
            msg.sender == adminPerson, "Only adminPerson can update a node."
        );

        for (uint i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeId == nodeId) {
                    nodes[i].nodeIPAddress = nodeIP;
            }
        }
    }

    /** 
     * @dev Remove node IP of a a voip node.
     * @param nodeId node id which is the address of the node 
     */
    function removeNode(address nodeId) external {

        require(
            msg.sender == adminPerson,
            "Only adminPerson can add a node."
        );
        
        uint index;
        for (uint i = 0; i<nodes.length-1; i++){
            if (nodes[i].nodeId == nodeId) {
                index = i;
            }
        }

        if (index >= nodes.length) return;

        for (uint i = index; i<nodes.length-1; i++){
            nodes[i] = nodes[i+1];
        }
        nodes.pop();
    }

    /** 
     * @dev Get the IP of a a voip node.
     * @param nodeId node id which is the address of the node 
     */
    function getNodeIP(address nodeId) public view returns (bytes32 nodeIP) {
    
        // require(
        //     msg.sender == adminPerson,
        //     "Only adminPerson can get a node info."
        // );       

        nodeIP = "";
        for (uint i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeId == nodeId) {
                nodeIP = nodes[i].nodeIPAddress;
            }
        }
        return nodeIP;

    }

    /** 
     * @dev add a new user to the voip network.
     * @param userId user id which is the wallet address of the user 
     * @param userCreds  user's credentials on the voip node
     */
    function addUser(address userId, bytes32 userCreds) public {
    
        require(
            msg.sender == adminPerson,
            "Only adminPerson can add a user."
        );       
        //ignore demand if empty credentials
        if (userCreds != '') {
            users[userId].userVoipCredentials = userCreds;
        }
    }

    /** 
     * @dev update the credentials of a user.
     * @param userId user id which is the wallet address of the user 
     * @param userCreds  new user's credentials 
     */
    function updateUser(address userId, bytes32 userCreds) public {
    
        require(
            msg.sender == adminPerson,
            "Only adminPerson can add a user."
        );       
        //update only if credentials are not empty
        if (users[userId].userVoipCredentials != '') {
            users[userId].userVoipCredentials = userCreds;
        }
    }

    /** 
     * @dev removce a new user from the voip network.
     * @param userId user id which is the wallet address of the user 
     */
    function removeUser(address userId) public {
        
         require(
            msg.sender == adminPerson,
            "Only adminPerson can remove a user."
        );     

        delete(users[userId]);

    }

     /** 
     * @dev get credentials of a user.
     * @param userId user id which is the wallet address of the user 
     */
    function getUserCreds(address userId) public view returns (bytes32 userCreds){
    
        require(
            msg.sender == adminPerson,
            "Only adminPerson can get a user info."
        );       

        userCreds = users[userId].userVoipCredentials;
        return userCreds;

    }

     /** 
     * @dev Gets a random voip node IP from. This is a temporary solution as it provides a pseudo-random number, VRF function of chainlink should be implemented later
     */
    function getRandomNodeIP() public view returns (bytes32 nodeIP) {

        uint maxNumber = nodes.length;
        uint nodeIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % (maxNumber);

        nodeIP = nodes[nodeIndex].nodeIPAddress;
        return nodeIP;
    
    } 

    /** 
     * @dev Write a CDR (Call Data Record). For every call, a CDR will be written by one node only
     * @param addrCaller id of the caller
     * @param addrCallee id of the callee 
     * @param startCallDate start call date 
     * @param callDuration call duration 
     * @param nodeIdCallOperator node id which operated the call 
     * @param nodeIdCDRWriter node id which wrote the CDR 
     */
    function writeCDR(
                    address addrCaller, 
                    address addrCallee, 
                    uint startCallDate, 
                    int32 callDuration, 
                    address nodeIdCallOperator, 
                    address nodeIdCDRWriter) public {

        //requires that the sender to be in the list of registered nodes
        uint i = 0;
        bool foundNode = false;
        while (!foundNode && (i < nodes.length)) {
            if (nodes[i].nodeId == nodeIdCallOperator) {
                foundNode = true;
            }
            i++;
        }
        require(
            foundNode,
            "Only a registered node can write a CDR."
        ); 

        //check all fields except the nodeIdCDRWriter
        for (uint j = 0; j < CDRs.length; j++) {
            if ((CDRs[j].addrCaller == addrCaller) &&
               (CDRs[j].addrCallee == addrCallee) &&
               (CDRs[j].startCallDate == startCallDate) &&
               (CDRs[j].callDuration == callDuration) &&
               (CDRs[j].nodeIdCallOperator == nodeIdCallOperator)) {
                   //the same record was already stored, do not store again
                   return;
            }
        }

        //add the new CDR
        CDRs.push(CDR({
            addrCaller: addrCaller,
            addrCallee: addrCallee,
            startCallDate: startCallDate,
            callDuration: callDuration,
            nodeIdCallOperator: nodeIdCallOperator,
            nodeIdCDRWriter: nodeIdCDRWriter
        }));

    }

    /** 
     * @dev Gets CDRs count by user. 
     * @param userId id of the caller
     */
    function getCDRsCountByUser(address userId) public view returns (uint count){

        require(
            msg.sender == adminPerson,
            "Only adminPerson can get a user CDRs info."
        );       
        uint myCount = 0;
        for (uint i = 0; i < CDRs.length; i++) {
            if ( CDRs[i].addrCaller == userId ) {
                myCount++;
            }
        }
        count = myCount;
        return count;

    }

    /** 
     * @dev Gets CDRs by userId and index for the same userId. 
     * @param userId id of the caller
     * @param index index in the array of the same userId
     */
    function getCDRsByUserIndex(address userId, uint index) public view returns (
                                address addrCaller, 
                                address addrCallee, 
                                uint startCallDate, 
                                int32 callDuration, 
                                address nodeIdCallOperator, 
                                address nodeIdCDRWriter ){

        require(
            msg.sender == adminPerson,
            "Only adminPerson can get a CDRs user info."
        );       

        uint counter;
        uint i = 0;
        while ( i < CDRs.length) {
            if ( CDRs[i].addrCaller == userId ) {
                if (index == counter) {
                    return (CDRs[i].addrCaller, 
                            CDRs[i].addrCallee, 
                            CDRs[i].startCallDate, 
                            CDRs[i].callDuration, 
                            CDRs[i].nodeIdCallOperator, 
                            CDRs[i].nodeIdCDRWriter);
                }
                counter++;
            }
            i++;
        }

        return (address(0),address(0),0, 0, address(0),address(0));

    }

    /** 
     * @dev Gets CDRs count by node operator. 
     * @param nodeId id of the caller
     */
    function getCDRsCountByNodeOperator(address nodeId) public view returns (uint count){

        require(
            msg.sender == adminPerson,
            "Only adminPerson can get a user CDRs info."
        );       
        uint myCount = 0;
        for (uint i = 0; i < CDRs.length; i++) {
            if ( CDRs[i].nodeIdCallOperator == nodeId ) {
                myCount++;
            }
        }
        count = myCount;
        return count;

    }

    /** 
     * @dev Gets CDRs by node operator and index of the same node operator. 
     * @param nodeId id of the caller
     * @param index index in the array of the same node operator 
     */
    function getCDRsByNodeOperatorIndex(address nodeId, uint index) public view returns (
                                address addrCaller, 
                                address addrCallee, 
                                uint startCallDate, 
                                int32 callDuration, 
                                address nodeIdCallOperator, 
                                address nodeIdCDRWriter
    ){

        require(
            msg.sender == adminPerson,
            "Only adminPerson can get CDRs nodes info."
        );       

        uint counter;
        uint i = 0;
        while ( i < CDRs.length) {
            if ( CDRs[i].nodeIdCallOperator == nodeId ) {
                if (index == counter) {
                    return (CDRs[i].addrCaller, 
                            CDRs[i].addrCallee, 
                            CDRs[i].startCallDate, 
                            CDRs[i].callDuration, 
                            CDRs[i].nodeIdCallOperator, 
                            CDRs[i].nodeIdCDRWriter);
                }
                counter++;
            }
            i++;
        }

        return (address(0),address(0),0, 0, address(0),address(0));

    }

}