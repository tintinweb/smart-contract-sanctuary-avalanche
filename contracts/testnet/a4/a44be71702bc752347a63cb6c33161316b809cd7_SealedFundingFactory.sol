pragma solidity ^0.8.7;

interface IExchange {
    function deposit(address receiver) external payable;
}

contract SealedFunding {
    constructor(address _owner, address _exchange) {
        IExchange(_exchange).deposit{value: address(this).balance}(_owner);
        assembly {
            // Ensures the runtime bytecode is a single opcode: `INVALID`. This reduces contract
            // deploy costs & ensures that no one can accidentally send ETH to the contract once
            // deployed.
            mstore8(0, 0xfe)
            return(0, 1)
        }
    }
}

pragma solidity ^0.8.7;

import "./SealedFunding.sol";

contract SealedFundingFactory {
    address public immutable exchange;

    constructor(address _exchange) {
        exchange = _exchange;
    }

    event SealedFundingRevealed(bytes32 salt, address owner);

    function deploySealedFunding(bytes32 salt, address owner) public {
        new SealedFunding{salt: salt}(owner, exchange);
        emit SealedFundingRevealed(salt, owner);
    }

    function computeSealedFundingAddress(bytes32 salt, address owner)
        external
        view
        returns (address predictedAddress, bool isDeployed)
    {
        predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(abi.encodePacked(type(SealedFunding).creationCode, abi.encode(owner, exchange)))
                        )
                    )
                )
            )
        );
        isDeployed = predictedAddress.code.length != 0;
    }
}