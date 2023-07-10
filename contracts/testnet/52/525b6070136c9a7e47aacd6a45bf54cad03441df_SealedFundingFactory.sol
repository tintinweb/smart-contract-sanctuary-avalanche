pragma solidity ^0.8.7;

interface IExchange {
    function deposit(address receiver) external payable;
}

contract SealedFunding {
    constructor(address _owner, address _exchange){
        IExchange(_exchange).deposit{value: address(this).balance}(_owner);
    }

    // Decided against including functions to retrieve tokens incorrently sent to this contract because they'd increase gas cost 100%-150%
    // Since I expect a lot of these contracts to be created it's not worth it as these mistakes seem unlikely
}

pragma solidity ^0.8.7;
import "./SealedFunding.sol";

contract SealedFundingFactory {
    address immutable public exchange;
    constructor(address _exchange){
        exchange = _exchange;
    }

    event SealedFundingRevealed(bytes32 salt, address owner);
    function deploySealedFunding(bytes32 salt, address owner) public {
        new SealedFunding{salt: salt}(owner, exchange);
        emit SealedFundingRevealed(salt, owner);
    }

    function computeSealedFundingAddress(bytes32 salt, address owner) external view returns(address predictedAddress, bool isDeployed){
        predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(type(SealedFunding).creationCode, abi.encode(owner, exchange)))
        )))));
        isDeployed = predictedAddress.code.length != 0;
    }
}