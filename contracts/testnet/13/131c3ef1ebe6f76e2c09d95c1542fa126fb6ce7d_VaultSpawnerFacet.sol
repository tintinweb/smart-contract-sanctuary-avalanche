pragma solidity 0.8.18;

import "../../Vault/VaultDiamond.sol";
import "../libraries/LibAppStorage.sol";
import "../../Vault/libraries/LibKeep.sol";
import "../../interfaces/IVaultDiamond.sol";

import "../../interfaces/IDiamondCut.sol";
import "../../interfaces/IVaultFacet.sol";

contract VaultSpawnerFacet is StorageLayout {
    event VaultCreated(
        address indexed owner,
        address indexed backup,
        uint256 indexed startingBalance,
        uint256 vaultID
    );

    error BackupAddressError();

    function createVault(
        address[] calldata _inheritors,
        uint256[] calldata _weiShare,
        uint256 _startingBal,
        address _backupAddress
    ) external payable returns (address addr) {
        if (_backupAddress == msg.sender) {
            revert BackupAddressError();
        }
        if (_startingBal > 0) {
            assert(_startingBal == msg.value);
        }
        assert(_inheritors.length == _weiShare.length);
        //spawn contract
        bytes memory code = type(VaultDiamond).creationCode;
        bytes32 entropy = keccak256(
            abi.encode(msg.sender, block.timestamp, fs.VAULTID)
        );
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), entropy)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        //init diamond with diamondCut facet
        //insert a constant cut facet...modular and reusable across diamonds
        IVaultDiamond(addr).init(fs.diamondCutFacet, _backupAddress);
        //assert diamond owner
        //confirm for EOA auth in same call frame
        assert(IVaultDiamond(addr).tempOwner() == tx.origin);
        //deposit startingBal
        (bool success, ) = addr.call{value: _startingBal}("");
        assert(success);

        //proceed to upgrade new diamond with default facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: fs.erc20Facet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: fs.ERC20SELECTORS
        });
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: fs.erc721Facet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: fs.ERC721SELECTORS
        });
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: fs.erc1155Facet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: fs.ERC1155SELECTORS
        });
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: fs.diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: fs.DIAMONDLOUPEFACETSELECTORS
        });
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: fs.vaultFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: fs.VAULTFACETSELECTORS
        });
        //upgrade
        IDiamondCut(addr).diamondCut(cut, address(0), "");
        //add inheritors if any
        if (_inheritors.length > 0) {
            IVaultFacet(addr).addInheritors(_inheritors, _weiShare);
        }

        emit VaultCreated(msg.sender, _backupAddress, _startingBal, fs.VAULTID);
        fs.VAULTID++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

import "./libraries/LibLayoutSilo.sol";
import "./libraries/LibStorageBinder.sol";
//import "./libraries/LibVaultStorage.sol";

import "../interfaces/IVaultDiamond.sol";

contract VaultDiamond {
    bool _init;
    event SlotWrittenTo(bytes32 slot);

    constructor() payable {
        address _contractOwner = tx.origin;
        LibDiamond.setVaultOwner(_contractOwner);
    }

    function init(address _diamondCutFacet, address _backup) public {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        assert(!_init);
        assert(
            msg.sender == LibDiamond.vaultOwner() ||
                tx.origin == LibDiamond.vaultOwner()
        );
        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](2);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        functionSelectors[1] = IVaultDiamond.tempOwner.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
        vaultData.backupAddress = _backup;
        _init = true;
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();

        // get facet from function selector
        address facet = fsData.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }

        bytes32 _slott;
        assembly {
            _slott := fsData.slot
        }

        emit SlotWrittenTo(_slott);
    }

    receive() external payable {}
}

pragma solidity 0.8.18;

import "../../Vault/libraries/LibKeepHelpers.sol";

struct FactoryAppStorage {
    //master vaultID
    uint256 VAULTID;
    //mapping(address=>uint[]) userVaults;

    //set during Master Diamond Deployment
    //used to upgrade individual vaults
    address diamondCutFacet;
    address erc20Facet;
    address erc721Facet;
    address erc1155Facet;
    address diamondLoupeFacet;
    address vaultFacet;
    //facet selector data for spawned vaults
    bytes4[] ERC20SELECTORS;
    bytes4[] ERC721SELECTORS;
    bytes4[] ERC1155SELECTORS;
    bytes4[] DIAMONDLOUPEFACETSELECTORS;
    bytes4[] VAULTFACETSELECTORS;
}

library LibAppStorage {
    function factoryAppStorage()
        internal
        pure
        returns (FactoryAppStorage storage fs)
    {
        assembly {
            fs.slot := 0
        }
    }
}

abstract contract StorageLayout {
    FactoryAppStorage internal fs;

    //  function removeArray(uint256 _val,address _inheritor) public {
    //     LibKeepHelpers.removeUint(fs.userVaults[_inheritor],_val);
    //  }

    // function addArray(uint256 _val,address _inheritor) public {
    //     LibKeepHelpers.removeUint(fs.userVaults[_inheritor],_val);
    //  }
}

pragma solidity 0.8.18;

import {Guards} from "./LibVaultStorage.sol";
import "./LibDiamond.sol";
import "./LibKeepHelpers.sol";
import "../../interfaces/IERC20.sol";

import "../../interfaces/IERC721.sol";

import "../../interfaces/IERC1155.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

bytes4 constant ERC1155_ACCEPTED = 0xf23a6e61;
bytes4 constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;
bytes4 constant ERC721WithCall = 0xb88d4fde;

library LibKeep {
    event VaultPinged(uint256 lastPing, uint256 vaultID);
    event InheritorsAdded(address[] newInheritors, uint256 vaultID);
    event InheritorsRemoved(address[] inheritors, uint256 vaultID);
    event EthAllocated(
        address[] inheritors,
        uint256[] amounts,
        uint256 vaultID
    );

    event ERC20TokenWithdrawal(
        address token,
        uint256 amount,
        address to,
        uint256 vaultID
    );

    event ERC721TokenWIthdrawal(
        address token,
        uint256 tokenID,
        address to,
        uint256 vaultID
    );
    event ERC1155TokenWithdrawal(
        address token,
        uint256 tokenID,
        uint256 amount,
        address to,
        uint256 vaultID
    );
    event ERC20ErrorHandled(address);
    event ERC721ErrorHandled(uint256 _failedTokenId, string reason);

    event ERC20TokensAllocated(
        address indexed token,
        address[] inheritors,
        uint256[] amounts,
        uint256 vaultID
    );
    event ERC721TokensAllocated(
        address indexed token,
        address inheritor,
        uint256 tokenID,
        uint256 vaultID
    );
    event ERC1155TokensAllocated(
        address indexed token,
        address inheritor,
        uint256 tokenID,
        uint256 amount,
        uint256 vaultID
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 vaultID
    );
    event BackupTransferred(
        address indexed previousBackup,
        address indexed newBackup,
        uint256 vaultID
    );
    event EthClaimed(
        address indexed inheritor,
        uint256 _amount,
        uint256 vaultID
    );

    event ERC20TokensClaimed(
        address indexed inheritor,
        address indexed token,
        uint256 amount,
        uint256 vaultID
    );

    event ERC721TokenClaimed(
        address indexed inheritor,
        address indexed token,
        uint256 tokenID,
        uint256 vaultID
    );
    event ERC1155TokensClaimed(
        address indexed inheritor,
        address indexed token,
        uint256 tokenID,
        uint256 amount,
        uint256 vaultID
    );
    event SlotWrittenTo(bytes32 indexed slott);

    error LengthMismatch();
    error ActiveInheritor();
    error NotEnoughEtherToAllocate(uint256);
    error EmptyArray();
    error NotInheritor();
    error EtherAllocationOverflow(uint256 overflow);
    error TokenAllocationOverflow(address token, uint256 overflow);
    error InactiveInheritor();
    error InsufficientEth();
    error InsufficientTokens();
    error NoAllocatedTokens();
    error NotERC721Owner();

    //owner check is in external fn
    function _ping() internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        vaultData.lastPing = block.timestamp;
        emit VaultPinged(block.timestamp, _vaultID());
    }

    function getCurrentAllocatedEth() internal view returns (uint256) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 totalEthAllocated;
        for (uint256 x; x < vaultData.inheritors.length; x++) {
            totalEthAllocated += vaultData.inheritorWeishares[
                vaultData.inheritors[x]
            ];
        }
        return totalEthAllocated;
    }

    function getCurrentAllocatedTokens(
        address _token
    ) internal view returns (uint256) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 totalTokensAllocated;
        for (uint256 x; x < vaultData.inheritors.length; x++) {
            totalTokensAllocated += vaultData.inheritorTokenShares[
                vaultData.inheritors[x]
            ][_token];
        }
        return totalTokensAllocated;
    }

    function getCurrentAllocated1155tokens(
        address _token,
        uint256 _tokenID
    ) internal view returns (uint256 alloc_) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 x; x < vaultData.inheritors.length; x++) {
            alloc_ += vaultData.inheritorERC1155TokenAllocations[
                vaultData.inheritors[x]
            ][_token][_tokenID];
        }
    }

    function _vaultID() internal view returns (uint256 vaultID_) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        vaultID_ = vaultData.vaultID;
    }

    function _resetClaimed(address _inheritor) internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        vaultData.inheritorWeishares[_inheritor] = 0;
        //resetting all token allocations if he has any
        if (vaultData.inheritorAllocatedERC20Tokens[_inheritor].length > 0) {
            //remove all token addresses
            delete vaultData.inheritorAllocatedERC20Tokens[_inheritor];
        }

        if (
            vaultData
                .inheritorAllocatedERC721TokenAddresses[_inheritor]
                .length > 0
        ) {
            delete vaultData.inheritorAllocatedERC721TokenAddresses[_inheritor];
        }

        if (
            vaultData
                .inheritorAllocatedERC1155TokenAddresses[_inheritor]
                .length > 0
        ) {
            delete vaultData.inheritorAllocatedERC1155TokenAddresses[
                _inheritor
            ];
        }
    }

    //only used for multiple address elemented arrays
    function reset(address _inheritor) internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        vaultData.inheritorWeishares[_inheritor] = 0;
        //resetting all token allocations if he has any
        if (vaultData.inheritorAllocatedERC20Tokens[_inheritor].length > 0) {
            for (
                uint256 x;
                x < vaultData.inheritorAllocatedERC20Tokens[_inheritor].length;
                x++
            ) {
                vaultData.inheritorTokenShares[_inheritor][
                    vaultData.inheritorAllocatedERC20Tokens[_inheritor][x]
                ] = 0;
                vaultData.inheritorActiveTokens[_inheritor][
                    vaultData.inheritorAllocatedERC20Tokens[_inheritor][x]
                ] = false;
            }
            //remove all token addresses
            delete vaultData.inheritorAllocatedERC20Tokens[_inheritor];
        }

        if (
            vaultData
                .inheritorAllocatedERC721TokenAddresses[_inheritor]
                .length > 0
        ) {
            for (
                uint256 x;
                x <
                vaultData
                    .inheritorAllocatedERC721TokenAddresses[_inheritor]
                    .length;
                x++
            ) {
                address tokenAddress = vaultData
                    .inheritorAllocatedERC721TokenAddresses[_inheritor][x];
                uint256 tokenAllocated = vaultData.inheritorERC721Tokens[
                    _inheritor
                ][tokenAddress];
                if (tokenAllocated == 0) {
                    vaultData.whitelist[tokenAddress][_inheritor] = false;
                }
                vaultData.inheritorERC721Tokens[_inheritor][tokenAddress] = 0;
                vaultData.allocatedERC721Tokens[tokenAddress][
                    tokenAllocated
                ] = false;
                //also reset reverse allocation mapping
                vaultData.ERC721ToInheritor[tokenAddress][
                    tokenAllocated
                ] = address(0);
                delete vaultData.inheritorAllocatedTokenIds[_inheritor][
                    tokenAddress
                ];
            }
            //remove all token addresses
            delete vaultData.inheritorAllocatedERC721TokenAddresses[_inheritor];
        }

        if (
            vaultData
                .inheritorAllocatedERC1155TokenAddresses[_inheritor]
                .length > 0
        ) {
            for (
                uint256 x;
                x <
                vaultData
                    .inheritorAllocatedERC1155TokenAddresses[_inheritor]
                    .length;
                x++
            ) {
                vaultData.inheritorERC1155TokenAllocations[_inheritor][
                    vaultData.inheritorAllocatedERC1155TokenAddresses[
                        _inheritor
                    ][x]
                ][
                        vaultData.inheritorAllocatedTokenIds[_inheritor][
                            vaultData.inheritorAllocatedERC1155TokenAddresses[
                                _inheritor
                            ][x]
                        ][x]
                    ] = 0;
            }

            delete vaultData.inheritorAllocatedERC1155TokenAddresses[
                _inheritor
            ];
        }
    }

    //INHERITOR MUTATING OPERATIONS

    function _addInheritors(
        address[] calldata _newInheritors,
        uint256[] calldata _weiShare
    ) internal {
        if (_newInheritors.length == 0 || _weiShare.length == 0) {
            revert EmptyArray();
        }
        if (_newInheritors.length != _weiShare.length) {
            revert LengthMismatch();
        }
        Guards._notExpired();
        uint256 total;
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 k; k < _newInheritors.length; k++) {
            total += _weiShare[k];

            if (vaultData.activeInheritors[_newInheritors[k]]) {
                revert ActiveInheritor();
            }
            //append the inheritors for a vault
            vaultData.inheritors.push(_newInheritors[k]);
            vaultData.activeInheritors[_newInheritors[k]] = true;
            //   if (total + allocated > address(this).balance)
            //     revert NotEnoughEtherToAllocate(address(this).balance);
            //   vaultData.inheritorWeishares[_newInheritors[k]] = _weiShare[k];
        }
        _allocateEther(_newInheritors, _weiShare);

        _ping();
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
        emit InheritorsAdded(_newInheritors, _vaultID());
        emit EthAllocated(_newInheritors, _weiShare, _vaultID());
    }

    function _removeInheritors(address[] calldata _inheritors) internal {
        if (_inheritors.length == 0) {
            revert EmptyArray();
        }
        Guards._notExpired();

        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 k; k < _inheritors.length; k++) {
            if (!vaultData.activeInheritors[_inheritors[k]]) {
                revert NotInheritor();
            }
            vaultData.activeInheritors[_inheritors[k]] = false;
            //pop out the address from the array
            LibKeepHelpers.removeAddress(vaultData.inheritors, _inheritors[k]);
            reset(_inheritors[k]);
        }
        _ping();
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
        emit InheritorsRemoved(_inheritors, _vaultID());
    }

    //ALLOCATION MUTATING OPERATIONS

    function _allocateEther(
        address[] calldata _inheritors,
        uint256[] calldata _ethShares
    ) internal {
        if (_inheritors.length == 0 || _ethShares.length == 0) {
            revert EmptyArray();
        }
        if (_inheritors.length != _ethShares.length) {
            revert LengthMismatch();
        }

        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 k; k < _inheritors.length; k++) {
            if (!Guards._activeInheritor(_inheritors[k])) {
                revert InactiveInheritor();
            }
            // update storage
            vaultData.inheritorWeishares[_inheritors[k]] = _ethShares[k];
            //make sure limit isn't exceeded
            if (getCurrentAllocatedEth() > address(this).balance) {
                revert EtherAllocationOverflow(
                    getCurrentAllocatedEth() - address(this).balance
                );
            }
        }
        _ping();
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
        emit EthAllocated(_inheritors, _ethShares, _vaultID());
    }

    function _allocateERC20Tokens(
        address token,
        address[] calldata _inheritors,
        uint256[] calldata _shares
    ) internal {
        if (_inheritors.length == 0 || _shares.length == 0) {
            revert EmptyArray();
        }
        if (_inheritors.length != _shares.length) {
            revert LengthMismatch();
        }
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 k; k < _inheritors.length; k++) {
            if (!Guards._anInheritor(_inheritors[k])) {
                revert NotInheritor();
            }
            if (!Guards._activeInheritor(_inheritors[k])) {
                revert InactiveInheritor();
            }
            vaultData.inheritorTokenShares[_inheritors[k]][token] = _shares[k];
            if (
                !vaultData.inheritorActiveTokens[_inheritors[k]][token] &&
                _shares[k] > 0
            ) {
                vaultData.inheritorAllocatedERC20Tokens[_inheritors[k]].push(
                    token
                );
                vaultData.inheritorActiveTokens[_inheritors[k]][token] = true;
            }
            //if allocation is being reduced to zero
            if (_shares[k] == 0) {
                LibKeepHelpers.removeAddress(
                    vaultData.inheritorAllocatedERC20Tokens[_inheritors[k]],
                    token
                );
                //double-checking
                vaultData.inheritorActiveTokens[_inheritors[k]][token] = false;
            }
            //finally check that limit isn't exceeded
            //get vault token balance
            uint256 currentBalance = IERC20(token).balanceOf(address(this));
            if (getCurrentAllocatedTokens(token) > currentBalance) {
                revert TokenAllocationOverflow(
                    token,
                    getCurrentAllocatedTokens(token) - currentBalance
                );
            }
        }
        _ping();
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
        emit ERC20TokensAllocated(token, _inheritors, _shares, _vaultID());
    }

    function _allocateERC721Tokens(
        address _token,
        address[] calldata _inheritors,
        uint256[] calldata _tokenIDs
    ) internal {
        if (_inheritors.length == 0 || _tokenIDs.length == 0) {
            revert EmptyArray();
        }
        if (_inheritors.length != _tokenIDs.length) {
            revert LengthMismatch();
        }
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 k; k < _inheritors.length; k++) {
            if (!Guards._anInheritorOrZero(_inheritors[k])) {
                revert NotInheritor();
            }
            if (!Guards._activeInheritor(_inheritors[k])) {
                revert InactiveInheritor();
            }
            //short-circuit
            if (
                vaultData.ERC721ToInheritor[_token][_tokenIDs[k]] ==
                _inheritors[k]
            ) {
                continue;
            }
            //confirm ownership
            try IERC721(_token).ownerOf(_tokenIDs[k]) returns (address owner) {
                if (owner == address(this)) {
                    if (vaultData.allocatedERC721Tokens[_token][_tokenIDs[k]]) {
                        address current = vaultData.ERC721ToInheritor[_token][
                            _tokenIDs[k]
                        ];
                        //if it is being allocated to someone else
                        if (
                            current != _inheritors[k] &&
                            current != address(0) &&
                            _inheritors[k] != address(0)
                        ) {
                            //Might add an Unallocation event
                            vaultData.whitelist[_token][current] = false;
                            LibKeepHelpers.removeUint(
                                vaultData.inheritorAllocatedTokenIds[current][
                                    _token
                                ],
                                _tokenIDs[k]
                            );
                            //if no tokens remain for that address
                            if (
                                vaultData
                                .inheritorAllocatedTokenIds[current][_token]
                                    .length == 0
                            ) {
                                //remove the address
                                LibKeepHelpers.removeAddress(
                                    vaultData
                                        .inheritorAllocatedERC721TokenAddresses[
                                            current
                                        ],
                                    _token
                                );
                            }
                        }
                        //if it is being unallocated
                        if (_inheritors[k] == address(0)) {
                            vaultData.allocatedERC721Tokens[_token][
                                _tokenIDs[k]
                            ] = false;
                            LibKeepHelpers.removeUint(
                                vaultData.inheritorAllocatedTokenIds[current][
                                    _token
                                ],
                                _tokenIDs[k]
                            );

                            if (
                                vaultData
                                .inheritorAllocatedTokenIds[_inheritors[k]][
                                    _token
                                ].length == 0
                            ) {
                                LibKeepHelpers.removeAddress(
                                    vaultData
                                        .inheritorAllocatedERC721TokenAddresses[
                                            current
                                        ],
                                    _token
                                );
                            }
                        }
                    } else {
                        vaultData.allocatedERC721Tokens[_token][
                            _tokenIDs[k]
                        ] = true;
                    }
                    vaultData.ERC721ToInheritor[_token][
                        _tokenIDs[k]
                    ] = _inheritors[k];
                    if (
                        vaultData
                        .inheritorAllocatedTokenIds[_inheritors[k]][_token]
                            .length == 0
                    ) {
                        vaultData
                            .inheritorAllocatedERC721TokenAddresses[
                                _inheritors[k]
                            ]
                            .push(_token);
                    }

                    vaultData
                    .inheritorAllocatedTokenIds[_inheritors[k]][_token].push(
                            _tokenIDs[k]
                        );

                    if (_tokenIDs[k] == 0) {
                        vaultData.whitelist[_token][_inheritors[k]] = true;
                    }
                    //   vaultData.inheritorERC721Tokens[_inheritors[k]][_token] = _tokenIDs[k];
                    emit ERC721TokensAllocated(
                        _token,
                        _inheritors[k],
                        _tokenIDs[k],
                        _vaultID()
                    );
                }
                if (owner != address(this)) {
                    emit ERC721ErrorHandled(_tokenIDs[k], "Not_Owner");
                    continue;
                }
            } catch Error(string memory r) {
                emit ERC721ErrorHandled(_tokenIDs[k], r);
                continue;
            }
        }
        _ping();
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
    }

    function _allocateERC1155Tokens(
        address _token,
        address[] calldata _inheritors,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) internal {
        if (_inheritors.length == 0 || _tokenIDs.length == 0) {
            revert EmptyArray();
        }
        if (_inheritors.length != _tokenIDs.length) {
            revert LengthMismatch();
        }
        if (_inheritors.length != _amounts.length) {
            revert LengthMismatch();
        }
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        for (uint256 i; i < _inheritors.length; i++) {
            if (!Guards._anInheritor(_inheritors[i])) {
                revert NotInheritor();
            }
            if (!Guards._activeInheritor(_inheritors[i])) {
                revert InactiveInheritor();
            }
            vaultData.inheritorERC1155TokenAllocations[_inheritors[i]][_token][
                _tokenIDs[i]
            ] = _amounts[i];
            //if id is just being added
            if (
                !LibKeepHelpers._inUintArray(
                    vaultData.inheritorAllocatedTokenIds[_inheritors[i]][
                        _token
                    ],
                    _tokenIDs[i]
                )
            ) {
                vaultData
                .inheritorAllocatedTokenIds[_inheritors[i]][_token].push(
                        _tokenIDs[i]
                    );
            }
            //if address is just being added
            if (
                !LibKeepHelpers._inAddressArray(
                    vaultData.inheritorAllocatedERC1155TokenAddresses[
                        _inheritors[i]
                    ],
                    _token
                )
            ) {
                vaultData
                    .inheritorAllocatedERC1155TokenAddresses[_inheritors[i]]
                    .push(_token);
            }
            //if tokens are being unallocated
            if (_amounts[i] == 0) {
                LibKeepHelpers.removeUint(
                    vaultData.inheritorAllocatedTokenIds[_inheritors[i]][
                        _token
                    ],
                    _tokenIDs[i]
                );
            }
            //if no tokens for the token address remain
            if (
                vaultData
                .inheritorAllocatedTokenIds[_inheritors[i]][_token].length == 0
            ) {
                LibKeepHelpers.removeAddress(
                    vaultData.inheritorAllocatedERC1155TokenAddresses[
                        _inheritors[i]
                    ],
                    _token
                );
            }
            //confirm numbers
            uint256 allocated = getCurrentAllocated1155tokens(
                _token,
                _tokenIDs[i]
            );
            uint256 available = IERC1155(_token).balanceOf(
                address(this),
                _tokenIDs[i]
            );
            if (allocated > available) {
                revert TokenAllocationOverflow(_token, allocated - available);
            }

            emit ERC1155TokensAllocated(
                _token,
                _inheritors[i],
                _tokenIDs[i],
                _amounts[i],
                _vaultID()
            );
        }

        _ping();
    }

    ///WITHDRAWALS

    function _withdrawEth(uint256 _amount, address _to) internal {
        //confirm free eth is sufficient
        uint256 allocated = getCurrentAllocatedEth();
        if (address(this).balance >= allocated) {
            if (address(this).balance - allocated < _amount) {
                revert InsufficientEth();
            }
            (bool success, ) = _to.call{value: _amount}("");
            assert(success);
        } else {
            revert InsufficientEth();
        }
    }

    function _withdrawERC20Tokens(
        address[] calldata _tokenAdds,
        uint256[] calldata _amounts,
        address _to
    ) internal {
        if (_tokenAdds.length == 0 || _amounts.length == 0) {
            revert EmptyArray();
        }
        if (_tokenAdds.length != _amounts.length) {
            revert LengthMismatch();
        }
        // VaultData storage vaultData=LibStorageBinder._bindAndReturnVaultStorage();
        for (uint256 x; x < _tokenAdds.length; x++) {
            address token = _tokenAdds[x];
            uint256 amount = _amounts[x];
            uint256 availableTokens = getCurrentAllocatedTokens(token);
            uint256 currentBalance = IERC20(token).balanceOf(address(this));
            bool success;
            if (currentBalance >= availableTokens) {
                if (currentBalance - availableTokens < _amounts[x]) {
                    revert InsufficientTokens();
                }
                //for other errors caused by malformed tokens
                try IERC20(token).transfer(_to, amount) {
                    success;
                } catch {
                    if (success) {
                        emit ERC20TokenWithdrawal(
                            token,
                            amount,
                            _to,
                            _vaultID()
                        );
                    } else {
                        emit ERC20ErrorHandled(token);
                    }
                }
            } else {
                revert InsufficientTokens();
            }
        }
        _ping();
    }

    function _withdrawERC20Token(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        uint256 availableTokens = getCurrentAllocatedTokens(_token);
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        bool success;
        if (currentBalance >= availableTokens) {
            if (currentBalance - availableTokens < _amount) {
                revert InsufficientTokens();
            }
            try IERC20(_token).transfer(_to, _amount) {
                success;
            } catch {
                if (success) {
                    emit ERC20TokenWithdrawal(_token, _amount, _to, _vaultID());
                } else {
                    emit ERC20ErrorHandled(_token);
                }
            }
        } else {
            revert InsufficientTokens();
        }

        _ping();
    }

    function _withdrawERC721Token(
        address _token,
        uint256 _tokenID,
        address _to
    ) internal {
        if (IERC721(_token).ownerOf(_tokenID) != address(this)) {
            revert NotERC721Owner();
        }
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (vaultData.allocatedERC721Tokens[_token][_tokenID]) {
            revert("UnAllocate Token First");
        }
        try
            IERC721(_token).safeTransferFrom(address(this), _to, _tokenID)
        {} catch {
            string memory reason;
            if (bytes(reason).length == 0) {
                emit ERC721TokenWIthdrawal(_token, _tokenID, _to, _vaultID());
            } else {
                emit ERC20ErrorHandled(_token);
            }
        }
    }

    function _withdrawERC1155Token(
        address _token,
        uint256 _tokenID,
        uint256 _amount,
        address _to
    ) internal {
        uint256 allocated = getCurrentAllocated1155tokens(_token, _tokenID);
        uint256 balance = IERC1155(_token).balanceOf(address(this), _tokenID);
        if (balance < _amount) {
            revert InsufficientTokens();
        }

        if (balance - allocated < _amount) {
            revert("UnAllocate TokensFirst");
        }
        IERC1155(_token).safeTransferFrom(
            address(this),
            _to,
            _tokenID,
            _amount,
            ""
        );
        emit ERC1155TokenWithdrawal(_token, _tokenID, _amount, _to, _vaultID());
    }

    //ACCESS TRANSFER

    function _transferOwnerShip(address _newOwner) internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        address prevOwner = vaultData.vaultOwner;
        vaultData.vaultOwner = _newOwner;
        emit OwnershipTransferred(prevOwner, _newOwner, _vaultID());
    }

    function _transferBackup(address _newBackupAddress) internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        address prevBackup = vaultData.backupAddress;
        vaultData.backupAddress = _newBackupAddress;
        emit BackupTransferred(prevBackup, _newBackupAddress, _vaultID());
    }

    ///CLAIMS

    function _claimOwnership(address _newBackup) internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        Guards._expired();
        address prevOwner = vaultData.vaultOwner;
        address prevBackup = vaultData.backupAddress;
        assert(prevOwner != _newBackup);
        vaultData.vaultOwner = msg.sender;
        vaultData.backupAddress = _newBackup;
        emit OwnershipTransferred(prevOwner, msg.sender, _vaultID());
        emit BackupTransferred(prevBackup, _newBackup, _vaultID());
    }

    function _claimERC20Tokens() internal {
        // Guards._anInheritor(msg.sender);
        // Guards._activeInheritor(msg.sender);
        // Guards._expired();
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 tokens = vaultData
            .inheritorAllocatedERC20Tokens[msg.sender]
            .length;
        if (tokens > 0) {
            for (uint256 i; i < tokens; i++) {
                address token = vaultData.inheritorAllocatedERC20Tokens[
                    msg.sender
                ][i];
                if (token == address(0)) {
                    continue;
                }
                uint256 amountToClaim = vaultData.inheritorTokenShares[
                    msg.sender
                ][token];
                if (amountToClaim > 0) {
                    //reset storage
                    vaultData.inheritorTokenShares[msg.sender][token] = 0;
                    IERC20(token).transfer(msg.sender, amountToClaim);
                    emit ERC20TokensClaimed(
                        msg.sender,
                        token,
                        amountToClaim,
                        _vaultID()
                    );
                }
            }
        }
    }

    event ww(bool);

    function _claimERC721Tokens() internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 tokens = vaultData
            .inheritorAllocatedERC721TokenAddresses[msg.sender]
            .length;
        if (tokens > 0) {
            for (uint256 i; i < tokens; i++) {
                address token = vaultData
                    .inheritorAllocatedERC721TokenAddresses[msg.sender][i];
                if (token == address(0)) {
                    continue;
                }
                uint256 tokensToClaim = vaultData
                .inheritorAllocatedTokenIds[msg.sender][token].length;
                if (tokensToClaim > 0) {
                    for (uint256 j; j < tokensToClaim; j++) {
                        uint256 tokenID = vaultData.inheritorAllocatedTokenIds[
                            msg.sender
                        ][token][j];
                        if (tokenID == 0) {
                            //check for whitelist
                            if (vaultData.whitelist[token][msg.sender]) {
                                vaultData.whitelist[token][msg.sender] = false;
                                IERC721(token).transferFrom(
                                    address(this),
                                    msg.sender,
                                    0
                                );
                                emit ERC721TokenClaimed(
                                    msg.sender,
                                    token,
                                    0,
                                    _vaultID()
                                );
                            }
                        } else {
                            //test thorougly for array overflows
                            vaultData.inheritorAllocatedTokenIds[msg.sender][
                                token
                            ][j] = 0;
                            IERC721(token).transferFrom(
                                address(this),
                                msg.sender,
                                tokenID
                            );
                            emit ERC721TokenClaimed(
                                msg.sender,
                                token,
                                tokenID,
                                _vaultID()
                            );
                        }
                    }
                }
            }
        }
    }

    function _claimERC1155Tokens() internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 tokens = vaultData
            .inheritorAllocatedERC1155TokenAddresses[msg.sender]
            .length;
        if (tokens > 0) {
            for (uint256 i; i < tokens; i++) {
                address token = vaultData
                    .inheritorAllocatedERC1155TokenAddresses[msg.sender][i];
                if (token == address(0)) {
                    continue;
                }
                uint256 noOfTokenIds = vaultData
                .inheritorAllocatedTokenIds[msg.sender][token].length;
                if (noOfTokenIds > 0) {
                    for (uint256 k; k < noOfTokenIds; k++) {
                        uint256 tokenID = vaultData.inheritorAllocatedTokenIds[
                            msg.sender
                        ][token][k];
                        uint256 amount = vaultData
                            .inheritorERC1155TokenAllocations[msg.sender][
                                token
                            ][tokenID];
                        if (amount > 0) {
                            vaultData.inheritorERC1155TokenAllocations[
                                msg.sender
                            ][token][tokenID] = 0;
                            IERC1155(token).safeTransferFrom(
                                address(this),
                                msg.sender,
                                tokenID,
                                amount,
                                ""
                            );
                            emit ERC1155TokensClaimed(
                                msg.sender,
                                token,
                                1,
                                amount,
                                _vaultID()
                            );
                        }
                    }
                }
            }
        }
    }

    function _claimAll() internal {
        Guards._anInheritor(msg.sender);
        Guards._activeInheritor(msg.sender);
        Guards._expired();
        Guards._notClaimed(msg.sender);
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (vaultData.inheritorWeishares[msg.sender] > 0) {
            uint256 amountToClaim = vaultData.inheritorWeishares[msg.sender];
            //reset storage
            vaultData.inheritorWeishares[msg.sender] == 0;
            (bool success, ) = msg.sender.call{value: amountToClaim}("");
            assert(success);

            emit EthClaimed(msg.sender, amountToClaim, _vaultID());
        }
        //claim ERC20 tokens..if any
        _claimERC20Tokens();
        //claim ERC721 Tokens if any
        _claimERC721Tokens();
        //claim ERC1155 Tokens if any
        _claimERC1155Tokens();

        //cleanup
        LibKeepHelpers.removeAddress(vaultData.inheritors, msg.sender);
        //clear storage
        //test thorougly
        _resetClaimed(msg.sender);
    }
}

pragma solidity 0.8.18;

interface IVaultDiamond {
    function init(address _diamondCutFacet, address _backupAddress) external;

    //via delegatecall on diamond
    function vaultOwner() external view returns (address);

    function tempOwner() external view returns (address owner_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

pragma solidity 0.8.18;

interface IVaultFacet {
    struct AllInheritorEtherAllocs {
        address inheritor;
        uint256 weiAlloc;
    }

    struct VaultInfo {
        address owner;
        uint256 weiBalance;
        uint256 lastPing;
        uint256 id;
        address backup;
        address[] inheritors;
    }

    event vaultCreated(
        address indexed owner,
        address indexed backup,
        uint256 indexed startingBalance,
        address[] inheritors
    );

    event EthDeposited(uint256 _amount, uint256 _vaultID);

    function addInheritors(
        address[] calldata _newInheritors,
        uint256[] calldata _weiShare
    ) external;

    function transferBackup(address _newBackupAddress) external;

    function allEtherAllocations()
        external
        view
        returns (AllInheritorEtherAllocs[] memory eAllocs);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

library LibDiamond {
    error InValidFacetCutAction();
    error NotVaultOwner();
    error NoSelectorsInFacet();
    error NoZeroAddress();
    error SelectorExists(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error MustBeZeroAddress();
    error NoCode();
    error NonExistentSelector(bytes4 selector);
    error ImmutableFunction(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();
    // bytes32 constant VAULT_STORAGE_POSITION =
    //     keccak256("diamond.standard.keep.storage");

    // function vaultStorage() internal pure returns (VaultStorage storage vaultData) {
    //     bytes32 position = VAULT_STORAGE_POSITION;
    //     assembly {
    //         vaultData.slot := position
    //     }
    // }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SlotWrittenTo(bytes32 indexed slott);

    function setVaultOwner(address _newOwner) internal {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        address previousOwner = vaultData.vaultOwner;
        vaultData.vaultOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function vaultOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibStorageBinder
            ._bindAndReturnVaultStorage()
            .vaultOwner;
    }

    function enforceIsContractOwner() internal view {
        if (
            msg.sender !=
            LibStorageBinder._bindAndReturnVaultStorage().vaultOwner
        ) revert NotVaultOwner();
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            fsData
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors
                .length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(fsData, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = fsData
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(fsData, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
        bytes32 _slott;
        assembly {
            _slott := fsData.slot
        }
        emit SlotWrittenTo(_slott);
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            fsData
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors
                .length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(fsData, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = fsData
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress == _facetAddress)
                revert SameSelectorReplacement(selector);
            removeFunction(fsData, oldFacetAddress, selector);
            addFunction(fsData, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
        bytes32 _slott;
        assembly {
            _slott := fsData.slot
        }

        emit SlotWrittenTo(_slott);
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = fsData
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(fsData, oldFacetAddress, selector);
        }
        bytes32 _slott;
        assembly {
            _slott := fsData.slot
        }
        emit SlotWrittenTo(_slott);
    }

    function addFacet(
        FacetAndSelectorData storage fsData,
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress);
        fsData
            .facetFunctionSelectors[_facetAddress]
            .facetAddressPosition = fsData.facetAddresses.length;
        fsData.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        FacetAndSelectorData storage fsData,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        fsData
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        fsData.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        fsData
            .selectorToFacetAndPosition[_selector]
            .facetAddress = _facetAddress;
    }

    function removeFunction(
        FacetAndSelectorData storage fsData,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = fsData
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = fsData
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = fsData
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            fsData.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            fsData
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        fsData.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete fsData.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = fsData.facetAddresses.length - 1;
            uint256 facetAddressPosition = fsData
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = fsData.facetAddresses[
                    lastFacetAddressPosition
                ];
                fsData.facetAddresses[facetAddressPosition] = lastFacetAddress;
                fsData
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            fsData.facetAddresses.pop();
            delete fsData
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}

pragma solidity 0.8.18;

//A record of data layouts...these are immutable and cannot be extended

///DIAMOND_FACET_SELECTOR
////START/////
struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
}
struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
}
struct FacetAndSelectorData {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
}
/////STOP/////

///INTERFACE_SUPPORTED
/////START////
struct InterFaceData {
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
}
////STOP////

//VAULT_GLOB_DATA
////START////
struct VaultData {
    //Vault ID
    uint256 vaultID;
    // owner of the vault
    address vaultOwner;
    //last time pinged
    uint256 lastPing;
    //backup address
    address backupAddress;
    //array of all inheritors
    address[] inheritors;
    //active inheritors
    mapping(address => bool) activeInheritors;
    //inheritor WEI shares
    mapping(address => uint256) inheritorWeishares;
    //ERC20
    //inheritor active tokens
    mapping(address => mapping(address => bool)) inheritorActiveTokens;
    //inheritor token shares
    mapping(address => mapping(address => uint256)) inheritorTokenShares;
    //address of tokens allocated
    mapping(address => address[]) inheritorAllocatedERC20Tokens;
    //ERC721
    mapping(address => mapping(address => bool)) whitelist;
    mapping(address => mapping(address => uint256)) inheritorERC721Tokens;
    mapping(address => mapping(uint256 => address)) ERC721ToInheritor;
    mapping(address => mapping(uint256 => bool)) allocatedERC721Tokens;
    mapping(address => address[]) inheritorAllocatedERC721TokenAddresses;
    //ERC1155
    mapping(address => mapping(address => mapping(uint256 => uint256))) inheritorERC1155TokenAllocations;
    mapping(address => address[]) inheritorAllocatedERC1155TokenAddresses;
    //GLOBAL
    mapping(address => mapping(address => uint256[])) inheritorAllocatedTokenIds;
    mapping(address => bool) claimed;
}
////STOP////

pragma solidity 0.8.18;

import "../VaultDiamond.sol";
import "../libraries/LibLayoutSilo.sol";
import "../facets/DiamondCutFacet.sol";
import "../facets/DiamondLoupeFacet.sol";
import "../facets/ERC1155Facet.sol";
import "../facets/ERC721Facet.sol";
import "../facets/ERC20Facet.sol";
import "../facets/VaultFacet.sol";

library LibStorageBinder {
    bytes32 constant SLOT_SALT = keccak256(type(LibKeep).creationCode);

    function _getStorageSlot(
        string memory _facetName1
    ) internal pure returns (bytes32 slot) {
        slot = keccak256(bytes(_facetName1));
    }

    function _getStorageSlot(
        string memory _facetName1,
        string memory _facetName2
    ) internal pure returns (bytes32 slot) {
        slot = keccak256(bytes(abi.encode(_facetName1, _facetName2)));
    }

    function _getStorageSlot(
        string memory _facetName1,
        string memory _facetName2,
        string memory _facetName3,
        string memory _facetName4,
        string memory _facetName5
    ) internal pure returns (bytes32 slot) {
        slot = keccak256(
            bytes(
                abi.encode(
                    _facetName1,
                    _facetName2,
                    _facetName3,
                    _facetName4,
                    _facetName5
                )
            )
        );
    }

    function _bindAndReturnFacetStorage()
        internal
        pure
        returns (FacetAndSelectorData storage selectorData)
    {
        bytes32 _slot = _getStorageSlot(
            type(DiamondCutFacet).name,
            type(DiamondLoupeFacet).name
        );
        bytes32 saltedOffset = _slot ^ SLOT_SALT;
        assembly {
            selectorData.slot := saltedOffset
        }
    }

    function _bindAndReturnInterfaceStorage()
        internal
        view
        returns (InterFaceData storage interFaceData)
    {
        bytes32 _slot = _getStorageSlot(type(DiamondLoupeFacet).name);
        bytes32 saltedOffset = _slot ^ SLOT_SALT;
        assembly {
            interFaceData.slot := saltedOffset
        }
    }

    function _bindAndReturnVaultStorage()
        internal
        pure
        returns (VaultData storage vaultData)
    {
        bytes32 _slot = _getStorageSlot(
            type(DiamondCutFacet).name,
            type(ERC20Facet).name,
            type(ERC721Facet).name,
            type(ERC1155Facet).name,
            type(VaultFacet).name
        );
        bytes32 saltedOffset = _slot ^ SLOT_SALT;
        assembly {
            vaultData.slot := saltedOffset
        }
    }
}

pragma solidity 0.8.18;

library LibKeepHelpers {
    function findAddIndex(
        address _item,
        address[] memory addressArray
    ) internal pure returns (uint256 i) {
        for (i; i < addressArray.length; i++) {
            //using the conventional method since we cannot have duplicate addresses
            if (addressArray[i] == _item) {
                return i;
            }
        }
    }

    function findUintIndex(
        uint _item,
        uint[] memory noArray
    ) internal pure returns (uint256 i) {
        for (i; i < noArray.length; i++) {
            if (noArray[i] == _item) {
                return i;
            }
        }
    }

    function removeUint(uint[] storage _noArray, uint to) internal {
        require(_noArray.length > 0, "Non-elemented number array");
        uint256 index = findUintIndex(to, _noArray);
        if (_noArray.length == 1) {
            _noArray.pop();
        }
        if (_noArray.length > 1) {
            for (uint256 i = index; i < _noArray.length - 1; i++) {
                _noArray[i] = _noArray[i + 1];
            }
            _noArray.pop();
        }
    }

    function removeAddress(address[] storage _array, address _add) internal {
        require(_array.length > 0, "Non-elemented address array");
        uint256 index = findAddIndex(_add, _array);
        if (_array.length == 1) {
            _array.pop();
        }

        if (_array.length > 1) {
            for (uint256 i = index; i < _array.length - 1; i++) {
                _array[i] = _array[i + 1];
            }
            _array.pop();
        }
    }

    function _inUintArray(
        uint256[] memory _array,
        uint256 _targ
    ) internal pure returns (bool exists_) {
        if (_array.length > 0) {
            for (uint256 i; i < _array.length; i++) {
                if (_targ == _array[i]) {
                    exists_ = true;
                }
            }
        }
    }

    function _inAddressArray(
        address[] memory _array,
        address _targ
    ) internal pure returns (bool exists_) {
        if (_array.length > 0) {
            for (uint256 i; i < _array.length; i++) {
                if (_targ == _array[i]) {
                    exists_ = true;
                }
            }
        }
    }
}

pragma solidity 0.8.18;

import "./LibDiamond.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

error NotBackupAddress();
error NotOwnerOrBackupAddress();
error NotExpired();
error HasExpired();
error Claimed();
error NoPermissions();

// struct FacetFunctionSelectors {
//     bytes4[] functionSelectors;
//     uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
// }

// struct VaultStorage {
//     ///VAULT DIAMOND VARS
//     // maps function selector to the facet address and
//     // the position of the selector in the facetFunctionSelectors.selectors array
//     mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
//     // maps facet addresses to function selectors
//     mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
//     // facet addresses
//     address[] facetAddresses;
//     // Used to query if a contract implements an interface.
//     // Used to implement ERC-165.
//     mapping(bytes4 => bool) supportedInterfaces;
//     //VAULT INTERNAL VARS

//     //Vault ID
//     uint256 vaultID;
//     // owner of the vault
//     address vaultOwner;
//     //last time pinged
//     uint256 lastPing;
//     //backup address
//     address backupAddress;
//     //array of all inheritors
//     address[] inheritors;
//     //active inheritors
//     mapping(address => bool) activeInheritors;
//     //inheritor WEI shares
//     mapping(address => uint256) inheritorWeishares;
//     //ERC20
//     //inheritor active tokens
//     mapping(address => mapping(address => bool)) inheritorActiveTokens;
//     //inheritor token shares
//     mapping(address => mapping(address => uint256)) inheritorTokenShares;
//     //address of tokens allocated
//     mapping(address => address[]) inheritorAllocatedERC20Tokens;
//     //ERC721
//     mapping(address => mapping(address => bool)) whitelist;
//     mapping(address => mapping(address => uint256)) inheritorERC721Tokens;
//     mapping(address => mapping(uint256 => address)) ERC721ToInheritor;
//     mapping(address => mapping(uint256 => bool)) allocatedERC721Tokens;
//     mapping(address => address[]) inheritorAllocatedERC721TokenAddresses;
//     //ERC1155
//     mapping(address => mapping(address => mapping(uint256 => uint256))) inheritorERC1155TokenAllocations;
//     mapping(address => address[]) inheritorAllocatedERC1155TokenAddresses;
//     //GLOBAL
//     mapping(address => mapping(address => uint256[])) inheritorAllocatedTokenIds;
//     mapping(address => bool) claimed;

// }

library Guards {
    function _onlyVaultOwner() internal view {
        LibDiamond.enforceIsContractOwner();
    }

    function _onlyVaultOwnerOrOrigin() internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (
            tx.origin != vaultData.vaultOwner &&
            msg.sender != vaultData.vaultOwner
        ) {
            revert NoPermissions();
        }
    }

    function _onlyVaultOwnerOrOriginOrBackup() internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (
            tx.origin != vaultData.vaultOwner &&
            msg.sender != vaultData.vaultOwner &&
            msg.sender != vaultData.backupAddress &&
            tx.origin != vaultData.backupAddress
        ) {
            revert NoPermissions();
        }
    }

    function _onlyVaultOwnerOrBackup() internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (
            msg.sender != vaultData.backupAddress &&
            msg.sender != vaultData.vaultOwner
        ) {
            revert NotOwnerOrBackupAddress();
        }
    }

    function _enforceIsBackupAddress() internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (msg.sender != vaultData.backupAddress) {
            revert NotBackupAddress();
        }
    }

    function _activeInheritor(
        address _inheritor
    ) internal view returns (bool active_) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (_inheritor == address(0)) {
            active_ = true;
        } else {
            active_ = (vaultData.activeInheritors[_inheritor]);
        }
    }

    function _anInheritor(address _inheritor) internal view returns (bool inh) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (_inheritor == address(0)) {
            inh = true;
        } else {
            for (uint256 i; i < vaultData.inheritors.length; i++) {
                if (_inheritor == vaultData.inheritors[i]) {
                    inh = true;
                }
            }
        }
    }

    function _anInheritorOrZero(
        address _inheritor
    ) internal view returns (bool inh) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (_inheritor == address(0)) {
            inh = true;
        } else {
            for (uint256 i; i < vaultData.inheritors.length; i++) {
                if (_inheritor == vaultData.inheritors[i]) {
                    inh = true;
                }
            }
        }
    }

    function _expired() internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (block.timestamp - vaultData.lastPing <= 24 weeks) {
            revert NotExpired();
        }
    }

    function _notExpired() internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (block.timestamp - vaultData.lastPing > 24 weeks) {
            revert HasExpired();
        }
    }

    function _notClaimed(address _inheritor) internal view {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (vaultData.claimed[_inheritor]) {
            revert Claimed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.8.18;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC1155 {
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(
        address _owner,
        uint256 _id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";

import {NoPermissions} from "../libraries/LibVaultStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

contract DiamondCutFacet is IDiamondCut {
    event SlotWrittenTo(bytes32 indexed slott);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (tx.origin != vaultData.vaultOwner) revert NoPermissions();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
        bytes32 _slott;
        assembly {
            _slott := vaultData.slot
        }

        emit SlotWrittenTo(_slott);
    }

    //temp call made from factory to confirm ownership
    function tempOwner() public view returns (address owner_) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        owner_ = vaultData.vaultOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

//import  "../libraries/LibVaultStorage.sol";
import "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../../interfaces/IERC165.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        uint256 numFacets = fsData.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = fsData.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = fsData
                .facetFunctionSelectors[facetAddress_]
                .functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        facetFunctionSelectors_ = fsData
            .facetFunctionSelectors[_facet]
            .functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        facetAddresses_ = fsData.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view override returns (address facetAddress_) {
        FacetAndSelectorData storage fsData = LibStorageBinder
            ._bindAndReturnFacetStorage();
        facetAddress_ = fsData
            .selectorToFacetAndPosition[_functionSelector]
            .facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(
        bytes4 _interfaceId
    ) external view override returns (bool) {
        InterFaceData storage iFaceData = LibStorageBinder
            ._bindAndReturnInterfaceStorage();
        return iFaceData.supportedInterfaces[_interfaceId];
    }
}

pragma solidity 0.8.18;

import "../libraries/LibKeep.sol";

import "../libraries/LibTokens.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

contract ERC1155Facet {
    struct AllocatedERC1155Tokens {
        uint256 tokenID;
        uint256 amount;
    }

    struct AllAllocatedERC1155Tokens {
        address token;
        uint256 tokenID;
        uint256 amount;
    }

    //VIEW FUNCTIONS
    function getAllocatedERC1155Tokens(
        address _token,
        address _inheritor
    ) public view returns (AllocatedERC1155Tokens[] memory alloc_) {
        Guards._activeInheritor(_inheritor);
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 tokenCount = vaultData
        .inheritorAllocatedTokenIds[_inheritor][_token].length;
        if (tokenCount > 0) {
            alloc_ = new AllocatedERC1155Tokens[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                uint256 _tid = vaultData.inheritorAllocatedTokenIds[_inheritor][
                    _token
                ][i];
                alloc_[i].tokenID = _tid;
                alloc_[i].amount = vaultData.inheritorERC1155TokenAllocations[
                    _inheritor
                ][_token][_tid];
            }
        }
    }

    function getAllAllocatedERC1155Tokens(
        address _inheritor
    ) public view returns (AllAllocatedERC1155Tokens[] memory alloc_) {
        Guards._activeInheritor(_inheritor);
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 tokenAddressCount = vaultData
            .inheritorAllocatedERC1155TokenAddresses[_inheritor]
            .length;
        for (uint256 j = 0; j < tokenAddressCount; j++) {
            address _token = vaultData.inheritorAllocatedERC1155TokenAddresses[
                _inheritor
            ][j];
            uint256 tokenCount = vaultData
            .inheritorAllocatedTokenIds[_inheritor][_token].length;
            alloc_ = new AllAllocatedERC1155Tokens[](tokenCount);
            for (uint256 i; i < tokenCount; i++) {
                uint256 _tid = vaultData.inheritorAllocatedTokenIds[_inheritor][
                    _token
                ][i];
                alloc_[i].tokenID = _tid;
                alloc_[i].amount = vaultData.inheritorERC1155TokenAllocations[
                    _inheritor
                ][_token][_tid];
                alloc_[i].token = _token;
            }
        }
    }

    function getUnallocatedERC115Tokens(
        address _token,
        uint256 _tokenId
    ) public view returns (uint256 remaining_) {
        // VaultData storage vaultData=LibStorageBinder._bindAndReturnVaultStorage();
        uint256 allocated = LibKeep.getCurrentAllocated1155tokens(
            _token,
            _tokenId
        );
        uint256 available = IERC1155(_token).balanceOf(address(this), _tokenId);
        if (allocated < available) {
            remaining_ = available - allocated;
        }
    }

    //DEPOSITS
    function depositERC1155Token(
        address _token,
        uint256 _tokenID,
        uint256 _amount
    ) external {
        // Guards._onlyVaultOwner();
        LibTokens._safeInputERC1155Token(_token, _tokenID, _amount);
    }

    function batchDepositERC1155Tokens(
        address _token,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) external {
        // Guards._onlyVaultOwner();
        LibTokens._safeBatchInputERC1155Tokens(_token, _tokenIDs, _amounts);
    }

    //WITHDRAWALS

    function withdrawERC1155Token(
        address _token,
        uint256 _tokenID,
        uint256 _amount,
        address _to
    ) public {
        Guards._onlyVaultOwner();
        LibKeep._withdrawERC1155Token(_token, _tokenID, _amount, _to);
    }

    function batchWithdrawERC1155Token(
        address _token,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amount,
        address _to
    ) public {
        Guards._onlyVaultOwner();
        if (_tokenIDs.length > 0) {
            for (uint256 i; i < _tokenIDs.length; i++) {
                withdrawERC1155Token(_token, _tokenIDs[i], _amount[i], _to);
            }
        }
    }

    //APPROVALS
    function approveERC1155Token(
        address _token,
        address _to,
        bool _approved
    ) external {
        Guards._onlyVaultOwner();
        LibTokens._approveAllERC1155Token(_token, _to, _approved);
    }

    //DEPOSIT COMPATIBILITY

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC1155_ACCEPTED;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC1155_BATCH_ACCEPTED;
    }
}

pragma solidity 0.8.18;

import "../libraries/LibKeep.sol";

import "../libraries/LibTokens.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

contract ERC721Facet {
    struct AllocatedERC721Tokens {
        address token;
        uint256[] tokenIDs;
    }

    function getAllocatedERC721Tokens(
        address _inheritor
    ) public view returns (AllocatedERC721Tokens[] memory allocated) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        Guards._activeInheritor(_inheritor);
        uint256 tokenAddressCount = vaultData
            .inheritorAllocatedERC721TokenAddresses[_inheritor]
            .length;
        if (tokenAddressCount > 0) {
            allocated = new AllocatedERC721Tokens[](tokenAddressCount);
            for (uint256 i; i < tokenAddressCount; i++) {
                address _token = vaultData
                    .inheritorAllocatedERC721TokenAddresses[_inheritor][i];
                allocated[i].token = _token;
                allocated[i].tokenIDs = vaultData.inheritorAllocatedTokenIds[
                    _inheritor
                ][_token];
            }
        }
    }

    function getAllocatedERC721TokenIds(
        address _inheritor,
        address _token
    ) external view returns (uint256[] memory) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        Guards._activeInheritor(_inheritor);
        return vaultData.inheritorAllocatedTokenIds[_inheritor][_token];
    }

    function getAllocatedERC721TokenAddresses(
        address _inheritor
    ) public view returns (address[] memory) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        Guards._activeInheritor(_inheritor);
        return vaultData.inheritorAllocatedERC721TokenAddresses[_inheritor];
    }

    //DEPOSITS

    function depositERC721Token(address _token, uint256 _tokenID) external {
        // Guards._onlyVaultOwner();
        LibTokens._inputERC721Token(_token, _tokenID);
    }

    function depositERC721Tokens(
        address _token,
        uint256[] calldata _tokenIDs
    ) external {
        for (uint256 i; i < _tokenIDs.length; i++) {
            LibTokens._inputERC721Token(_token, _tokenIDs[i]);
        }
    }

    function safeDepositERC721Token(address _token, uint256 _tokenID) external {
        // Guards._onlyVaultOwner();
        LibTokens._safeInputERC721Token(_token, _tokenID);
    }

    function safeDepositERC721TokenAndCall(
        address _token,
        uint256 _tokenID,
        bytes calldata data
    ) external {
        //Guards._onlyVaultOwner();
        LibTokens._safeInputERC721TokenAndCall(_token, _tokenID, data);
    }

    //WITHDRAWALS

    function withdrawERC721Token(
        address _token,
        uint256 _tokenID,
        address _to
    ) public {
        Guards._onlyVaultOwner();
        LibKeep._withdrawERC721Token(_token, _tokenID, _to);
    }

    //APPROVALS
    function approveSingleERC721Token(
        address _token,
        address _to,
        uint256 _tokenID
    ) external {
        Guards._onlyVaultOwner();
        LibTokens._approveERC721Token(_token, _tokenID, _to);
    }

    function approveAllERC721Token(
        address _token,
        address _to,
        bool _approved
    ) external {
        Guards._onlyVaultOwner();
        LibTokens._approveAllERC721Token(_token, _to, _approved);
    }

    //DEPOSIT COMPATIBILITY

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC721WithCall;
    }
}

pragma solidity 0.8.18;

import "../libraries/LibKeep.sol";

import "../libraries/LibTokens.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

contract ERC20Facet {
    struct AllocatedERC20Tokens {
        address token;
        uint256 amount;
    }

    function getAllocatedERC20Tokens(
        address _inheritor
    ) public view returns (AllocatedERC20Tokens[] memory tAllocs) {
        Guards._activeInheritor(_inheritor);
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 count = vaultData
            .inheritorAllocatedERC20Tokens[_inheritor]
            .length;
        if (count > 0) {
            tAllocs = new AllocatedERC20Tokens[](count);
            for (uint256 i; i < count; i++) {
                address _t = vaultData.inheritorAllocatedERC20Tokens[
                    _inheritor
                ][i];
                tAllocs[i].amount = vaultData.inheritorTokenShares[_inheritor][
                    _t
                ];
                tAllocs[i].token = _t;
            }
        }
    }

    function inheritorERC20TokenAllocation(
        address _inheritor,
        address _token
    ) public view returns (uint256) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        return vaultData.inheritorTokenShares[_inheritor][_token];
    }

    function getUnallocatedTokens(
        address _token
    ) public view returns (uint256 unallocated_) {
        uint256 bal = IERC20(_token).balanceOf(address(this));
        uint256 allocated = LibKeep.getCurrentAllocatedTokens(_token);
        if (bal > allocated) {
            unallocated_ = bal - allocated;
        }
    }

    //DEPOSITS
    function depositERC20Token(address _token, uint256 _amount) external {
        //  Guards._onlyVaultOwner();
        LibTokens._inputERC20Token(_token, _amount);
    }

    function depositERC20Tokens(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external {
        //Guards._onlyVaultOwner();
        LibTokens._inputERC20Tokens(_tokens, _amounts);
    }

    //WITHDRAWALS

    function withdrawERC20Token(
        address _token,
        uint256 _amount,
        address _to
    ) public {
        Guards._onlyVaultOwner();
        LibKeep._withdrawERC20Token(_token, _amount, _to);
    }

    function batchWithdrawERC20Token(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        address _to
    ) public {
        Guards._onlyVaultOwner();
        LibKeep._withdrawERC20Tokens(_tokens, _amounts, _to);
    }

    //APPROVALS
    function approveERC20Token(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        Guards._onlyVaultOwner();
        LibTokens._approveERC20Token(_token, _to, _amount);
    }
}

pragma solidity 0.8.18;

import "../libraries/LibKeep.sol";

import "../libraries/LibTokens.sol";
import "../libraries/LibDiamond.sol";
import "../../interfaces/IERC20.sol";

import "../libraries/LibLayoutSilo.sol";
import "../libraries/LibStorageBinder.sol";

contract VaultFacet {
    error AmountMismatch();

    ///////////////////
    //VIEW FUNCTIONS//
    /////////////////
    struct VaultInfo {
        address owner;
        uint256 weiBalance;
        uint256 lastPing;
        uint256 id;
        address backup;
        address[] inheritors;
    }

    struct AllInheritorEtherAllocs {
        address inheritor;
        uint256 weiAlloc;
    }

    event EthDeposited(uint256 _amount, uint256 _vaultID);

    function inspectVault() public view returns (VaultInfo memory info) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        info.owner = vaultData.vaultOwner;
        info.weiBalance = address(this).balance;
        info.lastPing = vaultData.lastPing;
        info.id = vaultData.vaultID;
        info.backup = vaultData.backupAddress;
        info.inheritors = vaultData.inheritors;
    }

    function vaultOwner() public view returns (address) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        return vaultData.vaultOwner;
    }

    function allEtherAllocations()
        public
        view
        returns (AllInheritorEtherAllocs[] memory eAllocs)
    {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        uint256 count = vaultData.inheritors.length;
        eAllocs = new AllInheritorEtherAllocs[](count);
        for (uint256 i; i < count; i++) {
            eAllocs[i].inheritor = vaultData.inheritors[i];
            eAllocs[i].weiAlloc = vaultData.inheritorWeishares[
                vaultData.inheritors[i]
            ];
        }
    }

    function inheritorEtherAllocation(
        address _inheritor
    ) public view returns (uint256 _allocatedEther) {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (!Guards._anInheritor(_inheritor)) {
            revert LibKeep.NotInheritor();
        }
        _allocatedEther = vaultData.inheritorWeishares[_inheritor];
    }

    function getAllocatedEther() public view returns (uint256) {
        return LibKeep.getCurrentAllocatedEth();
    }

    function getUnallocatedEther() public view returns (uint256 unallocated_) {
        uint256 currentBalance = address(this).balance;
        if (currentBalance > 0) {
            unallocated_ = currentBalance - LibKeep.getCurrentAllocatedEth();
        }
    }

    function etherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //////////////////////
    ///WRITE FUNCTIONS///
    ////////////////////
    //note: owner restriction is in external fns
    function addInheritors(
        address[] calldata _newInheritors,
        uint256[] calldata _weiShare
    ) external {
        Guards._onlyVaultOwnerOrOrigin();
        LibKeep._addInheritors(_newInheritors, _weiShare);
    }

    function removeInheritors(address[] calldata _inheritors) external {
        Guards._onlyVaultOwner();
        LibKeep._removeInheritors(_inheritors);
    }

    function depositEther(uint256 _amount) external payable {
        VaultData storage vaultData = LibStorageBinder
            ._bindAndReturnVaultStorage();
        if (_amount != msg.value) {
            revert AmountMismatch();
        }
        emit EthDeposited(_amount, vaultData.vaultID);
    }

    function withdrawEther(uint256 _amount, address _to) external {
        Guards._onlyVaultOwner();
        LibKeep._withdrawEth(_amount, _to);
    }

    function allocateEther(
        address[] calldata _inheritors,
        uint256[] calldata _ethShares
    ) external {
        Guards._onlyVaultOwner();
        LibKeep._allocateEther(_inheritors, _ethShares);
    }

    function allocateERC20Tokens(
        address token,
        address[] calldata _inheritors,
        uint256[] calldata _shares
    ) external {
        Guards._onlyVaultOwner();
        LibKeep._allocateERC20Tokens(token, _inheritors, _shares);
    }

    function allocateERC721Tokens(
        address token,
        address[] calldata _inheritors,
        uint256[] calldata _tokenIDs
    ) external {
        Guards._onlyVaultOwner();
        LibKeep._allocateERC721Tokens(token, _inheritors, _tokenIDs);
    }

    function allocateERC1155Tokens(
        address token,
        address[] calldata _inheritors,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _amounts
    ) external {
        Guards._onlyVaultOwner();
        LibKeep._allocateERC1155Tokens(token, _inheritors, _tokenIDs, _amounts);
    }

    function transferOwnership(address _newVaultOwner) public {
        Guards._onlyVaultOwner();
        LibKeep._transferOwnerShip(_newVaultOwner);
    }

    function transferBackup(address _newBackupAddress) public {
        Guards._onlyVaultOwnerOrOriginOrBackup();
        LibKeep._transferBackup(_newBackupAddress);
    }

    function claimOwnership(address _newBackupAddress) public {
        Guards._enforceIsBackupAddress();
        LibKeep._claimOwnership(_newBackupAddress);
    }

    function claimAllAllocations() external {
        LibKeep._claimAll();
    }

    function ping() external {
        Guards._onlyVaultOwner();
        LibKeep._ping();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.18;

import "./LibKeep.sol";
import "../../interfaces/IERC721.sol";
import "../../interfaces/IERC1155.sol";

library LibTokens {
    event ErrorHandled(address);

    event ERC20TokenDeposit(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 vaultID
    );

    event ERC721TokenDeposit(
        address indexed token,
        address indexed from,
        uint256 tokenID,
        uint256 vaultID
    );

    event ERC1155TokenDeposit(
        address indexed token,
        address indexed from,
        uint256 tokenID,
        uint256 amount,
        uint256 vaultID
    );

    event BatchERC1155TokenDeposit(
        address indexed token,
        address indexed from,
        uint256[] tokenIDs,
        uint256[] amounts,
        uint256 vaultID
    );

    //ERC20
    function _inputERC20Tokens(
        address[] calldata _tokenDeps,
        uint256[] calldata _amounts
    ) internal {
        Guards._notExpired();
        if (_tokenDeps.length == 0 || _amounts.length == 0) {
            revert LibKeep.EmptyArray();
        }
        if (_tokenDeps.length != _amounts.length) {
            revert LibKeep.LengthMismatch();
        }
        for (uint256 i; i < _tokenDeps.length; i++) {
            address token = _tokenDeps[i];
            uint256 amount = _amounts[i];
            bool success;
            try IERC20(token).transferFrom(msg.sender, address(this), amount) {
                success;
            } catch {
                if (success) {
                    emit ERC20TokenDeposit(
                        token,
                        msg.sender,
                        amount,
                        LibKeep._vaultID()
                    );
                } else {
                    emit ErrorHandled(token);
                    continue;
                }
            }
        }
        LibKeep._ping();
    }

    function _inputERC20Token(address _token, uint256 _amount) internal {
        Guards._notExpired();
        //   bool success;
        assert(IERC20(_token).transferFrom(msg.sender, address(this), _amount));
        emit ERC20TokenDeposit(_token, msg.sender, _amount, LibKeep._vaultID());
        LibKeep._ping();
    }

    function _approveERC20Token(
        address _spender,
        address _token,
        uint256 _amount
    ) internal {
        IERC20(_token).approve(_spender, _amount);
    }

    //ERC721
    function _inputERC721Token(address _token, uint256 _tokenID) internal {
        Guards._notExpired();
        IERC721(_token).transferFrom(msg.sender, address(this), _tokenID);
        emit ERC721TokenDeposit(
            _token,
            msg.sender,
            _tokenID,
            LibKeep._vaultID()
        );
    }

    function _safeInputERC721Token(address _token, uint256 _tokenID) internal {
        Guards._notExpired();
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenID);
        emit ERC721TokenDeposit(
            _token,
            msg.sender,
            _tokenID,
            LibKeep._vaultID()
        );
    }

    function _safeInputERC721TokenAndCall(
        address _token,
        uint256 _tokenID,
        bytes calldata _data
    ) internal {
        Guards._notExpired();
        IERC721(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID,
            _data
        );
    }

    function _approveERC721Token(
        address _token,
        uint256 _tokenID,
        address _to
    ) internal {
        Guards._notExpired();
        IERC721(_token).approve(_to, _tokenID);
    }

    function _approveAllERC721Token(
        address _token,
        address _to,
        bool _approved
    ) internal {
        Guards._notExpired();
        IERC721(_token).setApprovalForAll(_to, _approved);
    }

    //ERC1155

    function _safeInputERC1155Token(
        address _token,
        uint256 _tokenID,
        uint256 _value
    ) internal {
        Guards._notExpired();
        IERC1155(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID,
            _value,
            ""
        );
        emit ERC1155TokenDeposit(
            _token,
            msg.sender,
            _tokenID,
            _value,
            LibKeep._vaultID()
        );
    }

    function _safeBatchInputERC1155Tokens(
        address _token,
        uint256[] calldata _tokenIDs,
        uint256[] calldata _values
    ) internal {
        Guards._notExpired();
        IERC1155(_token).safeBatchTransferFrom(
            msg.sender,
            address(this),
            _tokenIDs,
            _values,
            ""
        );
        emit BatchERC1155TokenDeposit(
            _token,
            msg.sender,
            _tokenIDs,
            _values,
            LibKeep._vaultID()
        );
    }

    function _approveAllERC1155Token(
        address _token,
        address _to,
        bool _approved
    ) internal {
        Guards._notExpired();
        IERC1155(_token).setApprovalForAll(_to, _approved);
    }
}