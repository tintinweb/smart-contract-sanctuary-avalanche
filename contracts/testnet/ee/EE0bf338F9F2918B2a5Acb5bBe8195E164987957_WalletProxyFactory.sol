// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IWallet {
    function initWallet(address owner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
import "./interfaces/IWallet.sol";

contract WalletProxyFactory {
    bytes private initCode;

    event InitCodeChanged(bytes initCode);
    event WalletDeployed(address walletAddress);

    /// @dev Constructor
    /// @param _initCode Init code of the WalletProxy without the constructor arguments
    constructor(bytes memory _initCode) {
        initCode = _initCode;
        emit InitCodeChanged(initCode);
    }

    /**
     * Setters
     */

    /// @dev Setter for the proxy initCode without the constructor arguments
    /// @param _initCode Init code of the WalletProxy without the constructor arguments
    function setInitCode(bytes memory _initCode) public {
        initCode = _initCode;
        emit InitCodeChanged(initCode);
    }

    /**
     *  Getters
     */

    /// @dev Getter for the proxy initCode without the constructor arguments
    /// @return Init code
    function getInitCode() public view returns (bytes memory) {
        return initCode;
    }

    /// @dev Create Wallet Proxy and iterate through initialize data
    /// @notice This is used when a user creates an account e.g. on V5, but V1,2,3,
    /// @param _salt A uint256 value to add randomness to the account creation
    /// @param _implementation Address of the logic contract that the proxy will point to
    function createWallet(uint256 _salt, address _implementation)
        public
        returns (address)
    {
        address payable addr;
        bytes32 create2Salt = _getCreate2Salt(_salt, _implementation);
        bytes memory initCodeWithConstructor = abi.encodePacked(
            initCode,
            abi.encode(_implementation)
        );

        // Create proxy
        assembly {
            addr := create2(
                0,
                add(initCodeWithConstructor, 0x20),
                mload(initCodeWithConstructor),
                create2Salt
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        IWallet(addr).initWallet(msg.sender);

        emit WalletDeployed(addr);
        return (addr);
    }

    /// @dev Generate a salt out of a uint256 value and the init data
    /// @param _salt A uint256 value to add randomness to the account creation
    /// @param _implementation Address of the logic contract that the proxy will point to
    function _getCreate2Salt(uint256 _salt, address _implementation)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_salt, _implementation));
    }
}