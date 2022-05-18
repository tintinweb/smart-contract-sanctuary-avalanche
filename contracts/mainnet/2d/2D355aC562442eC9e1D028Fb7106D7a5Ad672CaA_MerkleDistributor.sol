pragma solidity 0.8.14;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}


contract MerkleDistributor {

    address public owner;
    bytes32 public merkleRoot;
    IERC20 public constant rewardToken = IERC20(0x120AD3e5A7c796349e591F1570D9f7980F4eA9cb);

    event Claimed(
        address indexed account,
        uint256 index,
        uint256 amount,
        address receiver
    );

    mapping (address => bool) public isClaimed;

    constructor(bytes32 _root) {
        owner = msg.sender;
        merkleRoot = _root;
    }

    function claim(
        address _claimer,
        uint256 _index,
        uint256 _amount,
        address _receiver,
        bytes32[] calldata _merkleProof
    ) external {
        if (msg.sender != owner) require(msg.sender == _claimer, "Cannot claim for another user");
        require(!isClaimed[_claimer], "Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _claimer, _amount));
        verify(_merkleProof, node);

        // Mark it claimed and send the token.
        isClaimed[_claimer] = true;
        rewardToken.transfer(_receiver, _amount);

        emit Claimed(_claimer, _index, _amount, _receiver);
    }

    function verify(bytes32[] calldata _proof, bytes32 _leaf) internal view {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        require(computedHash == merkleRoot, "Invalid proof.");
    }

}