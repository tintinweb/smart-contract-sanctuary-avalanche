// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.12;

// import "hardhat/console.sol";

library ERC721Validator {

    function isERC721(address token) public returns(bool b){
        // bytes4(keccak256(bytes("supportsInterface(bytes4)")))
        (bool success,bytes memory data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x80ac58cd))); // ERC721ID
        if(success && data.length > 0 && abi.decode(data, (bool))){
            (success,data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x5b5e139f))); // ERC721MetadataID
            /**
             * DEV no need to check ERC721Enumerable since it's OPTIONAL (only for token to be able to publish its full list of NFTs - see:
             * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#specification
             */
            // if(success && data.length > 0 && abi.decode(data, (bool))){
                // (success,data) = token.call(abi.encodeWithSelector(0x01ffc9a7,bytes4(0x780e9d63))); // ERC721EnumerableID
                b = success && data.length > 0 && abi.decode(data, (bool));
                // if(b) console.log("isERC721 ERC721EnumerableID");
            // }
        }
        // console.log(token); console.log(b);
    }

    function isERC721Owner(address token, address account, uint256 tokenId) public returns(bool result){
        // bytes4(keccak256(bytes('ownerOf(uint256)')));
        (, bytes memory data) = token.call(abi.encodeWithSelector(0x6352211e, tokenId));
        address owner = abi.decode(data, (address));
        result = owner==account;
    }

}