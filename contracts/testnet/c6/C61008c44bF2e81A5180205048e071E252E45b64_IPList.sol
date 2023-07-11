pragma solidity ^0.8.15;

contract IPList {
    struct IPInfo {
        string IP;
        address walletId;
        uint256 port;
    }
    
    IPInfo[] private ipInfos;
    
    function addIPInfo(string memory _IP, address _walletId, uint256 _port) public {
        IPInfo memory newIPInfo = IPInfo(_IP, _walletId, _port);
        ipInfos.push(newIPInfo);
    }
    
    function getIPInfos() public view returns (IPInfo[] memory) {
        return ipInfos;
    }
}