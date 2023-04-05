// SPDX-License-Identifier: GPL-3.0
/*
 *     NOTICE
 *
 *     The Qubistry software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *
 *     This code is based on the original code written by BitBond under the
 *     GPL-3.0 license. BitBond's contributions to this code are acknowledged
 *     and appreciated. Any modifications to the original code have been made
 *     by Qubistry and are also subject to the terms of the GPL-3.0 license.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.7;


import "./FullFeatureToken.sol";
import "./IFullFeatureToken.sol";
import {SharedStruct} from "./Library.sol";

contract TokenSaleContract is IFullFeatureToken, Ownable {

    event tokenCreated(address tokenAddress);

    FullFeatureToken public PBToken;
    SharedStruct.TokenConfigProps public tokenConfigProps;
    address public admin;
    uint256 public tokenInitialPrice;
    uint256 public inicialDate;
    uint256 public endDate;


    constructor(
        SharedStruct.TokenConfigProps memory _tokenConfigProps,
        address _admin,
        uint256 _tokenInitialPrice,
        uint256 _inicialDate,
        uint256 _endDate
    ) {

        tokenConfigProps = _tokenConfigProps;
        admin = _admin;
        tokenInitialPrice = _tokenInitialPrice;
        inicialDate = _inicialDate;
        endDate = _endDate;

    }
    function CreateContract () external {
         FullFeatureToken _PBToken = new FullFeatureToken(
            tokenConfigProps._name,
            tokenConfigProps._symbol,
            tokenConfigProps._totalSupply,
            tokenConfigProps._decimals,
            tokenConfigProps._tokenOwner,
            tokenConfigProps._configProps,
            tokenConfigProps._maxTokenAmount,
            tokenConfigProps._documentUri,
            tokenConfigProps._blockUntil
            );
            PBToken = _PBToken;
            emit tokenCreated(address(PBToken));

    }

    function mint(address _address, uint256 _amount) external override onlyOwner payable {
        require(msg.value == _amount * tokenInitialPrice);
        require(block.timestamp >= inicialDate && block.timestamp <= endDate);
        FullFeatureToken deployedContract = FullFeatureToken(address(PBToken));
       deployedContract.mint(_address,_amount);
    }
    function transfer(address _to, uint256 _amount) external override onlyOwner returns (bool) {
        FullFeatureToken deployedContract = FullFeatureToken(address(PBToken));
        deployedContract.transfer(_to,_amount);
        return true;
    }
    function updateWhitelist(address[] memory _addresses) external override {
        FullFeatureToken deployedContract = FullFeatureToken(address(PBToken));
        deployedContract.updateWhitelist(_addresses);
    }
    function updateWhitelistDocuments(address _address, string memory _document) external override onlyOwner {
        FullFeatureToken deployedContract = FullFeatureToken(address(PBToken));
        deployedContract.updateWhitelistDocuments(_address,_document);
    }
    function bulkUpdateWhitelistDocuments(address[] memory _addresses, string[] memory _documents) external onlyOwner {
        FullFeatureToken deployedContract = FullFeatureToken(address(PBToken));
        for (uint i = 0; i < _addresses.length; i++) {
        deployedContract.updateWhitelistDocuments(_addresses[i],_documents[i]);
        }
    }

    function bulkTransfer(address[] memory _to, uint256[] memory _amounts) external onlyOwner returns (bool) {
        require(_to.length == _amounts.length, "Arrays must have same length");
        FullFeatureToken deployedContract = FullFeatureToken(address(PBToken));
        for(uint i=0; i<_to.length; i++){
            deployedContract.transfer(_to[i],_amounts[i]);
        }
        return true;
    }

    function endSale () external onlyOwner {
            require(PBToken.transfer(admin, PBToken.balanceOf(address(this))));

        // Destroy/Deactivate the contract
        selfdestruct(payable(admin));
    }






}