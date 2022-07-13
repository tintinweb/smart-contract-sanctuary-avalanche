/**
 *Submitted for verification at snowtrace.io on 2022-07-13
*/

// File: contracts/RedEnvelop.sol


pragma solidity ^0.8.4;

contract RedEnvelope {
    mapping(address => uint) public nonce;
    mapping(bytes32 => uint) public leftAmount;
    mapping(bytes32 => uint) public packCount;
    mapping(bytes32 => uint) public claimedCount;
    mapping(bytes32 => mapping(address => bool)) public claimed;

    event Pack(bytes32 id, address _sender, uint256 _amount, uint256 _count);
    event Claim(bytes32 id, address user, uint256 _amount, uint256 _leftCount);

    function pack(uint256 _count) external payable {
        require(msg.value >= 0.01 ether, "Value too small");
        require(_count >= 1, "Count too small");
        require(msg.value / _count >= 0.01 ether, "Value / Count too small");
        uint _nonce = nonce[msg.sender]++;
        bytes32 id = keccak256(abi.encode(msg.sender, _nonce, block.timestamp));

        leftAmount[id] = msg.value;
        packCount[id] = _count;

        emit Pack(id, msg.sender, msg.value, _count);
    }

    function claim(bytes32 _id) external {
        require(tx.origin == msg.sender, "No support contract call");
        require(leftAmount[_id] > 0, "No left amount");
        require(!claimed[_id][msg.sender], "You have already claimed");

        uint leftCount = packCount[_id] - claimedCount[_id];
        require(leftCount > 0, "No left packs");

        uint getAmount = getRandomAmount(leftAmount[_id], leftCount);
        claimedCount[_id]++;
        leftAmount[_id] -= getAmount;
        claimed[_id][msg.sender] = true;
        payable(msg.sender).transfer(getAmount);
        leftCount--;
        emit Claim(_id, msg.sender, getAmount, leftCount);
    }

    function getRandomAmount(uint _leftAmount, uint _leftCount) internal view returns (uint256) {
        if(_leftCount == 1) {
            return _leftAmount;
        }
        uint r     = uint256(keccak256(abi.encode(block.timestamp, msg.sender)));
        uint min   = 0.01 ether;
        uint max   = _leftAmount / _leftCount * 2;
        uint money = r % max;
        money = money <= min ? min : money;
        return money;
    }
}