/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-31
*/

//SPDX-License-Identifier: MIT
//🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿

pragma solidity ^0.8.14;

// dev.kimlikdao.eth
address constant DEV_KASASI = 0x333Bc913264B6E4a10fd38F30264Ff9c9801176D;

// bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
bytes32 constant ERC1967_CODE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

enum DistroStage {
    Presale1,
    Presale2,
    DAOSaleStart,
    DAOSaleEnd,
    DAOAMMStart,
    Presale2Unlock,
    FinalMint,
    FinalUnlock
}

interface IDAOKasasi {
    function redeem(
        address payable redeemer,
        uint256 burnedTokens,
        uint256 totalTokens
    ) external;

    function distroStageUpdated(DistroStage) external;

    function versionHash() external pure returns (bytes32);

    function migrateToCode(address codeAddress) external;
}

contract DAOKasasiV1 is IDAOKasasi {
    function redeem(
        address payable,
        uint256,
        uint256
    ) external {}

    function distroStageUpdated(DistroStage) external {}

    /**
     * @dev Does snowtrace show this comment in write method?
     */
    function migrateToCode(address codeAddress) external {
        require(tx.origin == DEV_KASASI);
        require(
            bytes32(
                // ethers.utils.keccak256(ethers.utils.toUtf8Bytes("DAOKasasiV1"))
                0x3f5e44c15812e7a9bd6973fd9e7c7da4afea4649390f7a1652d5b56caa8afeff
            ) == IDAOKasasi(codeAddress).versionHash()
        );
        assembly {
            sstore(ERC1967_CODE_SLOT, codeAddress)
        }
    }

    /**
     * @dev Does snowtrace show this comment in read method?
     */
    function versionHash() external pure returns (bytes32) {
        return 0x3f5e44c15812e7a9bd6973fd9e7c7da4afea4649390f7a1652d5b56caa8afeff;
    }
}