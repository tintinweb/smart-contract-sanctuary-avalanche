/**
 *Submitted for verification at snowtrace.io on 2022-02-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Utils {
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function getSvgHeader() public pure returns (string memory) {
        return '<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg width="100%" height="100%" viewBox="0 0 1440 1440" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:1.5;">';
    }

    function getDefs(string memory _colors) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<defs>',
            _colors,
            '</defs>'
        ));
    }

    function getBackgroungColor(uint256 _colorId) public pure returns (string memory) {
        string[74] memory colors = [
            'CBC3E3',
            'F0FFFF',
            '00008B',
            '5D3FD3',
            'ADD8E6',
            'A7C7E7',
            'CCCCFF',
            '96DED1',
            '9FE2BF',
            '008080',
            'EADDCA',
            '5C4033',
            '988558',
            'F2D2BD',
            '4A0404',
            'A95C68',
            'C2B280',
            'F5DEB3',
            '722F37',
            'D3D3D3',
            'B2BEB5',
            'D3D3D3',
            'E5E4E2',
            '8A9A5B',
            'AFE1AF',
            'DFFF00',
            '7DF9FF',
            '5F8575',
            '90EE90',
            '8A9A5B',
            'C1E1C1',
            'C9CC3F',
            '2E8B57',
            '9FE2BF',
            'FBCEB1',
            'F2D2BD',
            'CD7F32',
            'CC5500',
            'E97451',
            'FF7F50',
            'F88379',
            '8B4000',
            'FAD5A5',
            'FFDEAD',
            'FF5F1F',
            'FAC898',
            'FFE5B4',
            'F89880',
            'E35335',
            'FFF5EE',
            'E3735E',
            '9F2B68',
            'F2D2BD',
            'DE3163',
            'C9A9A6',
            'FFB6C1',
            'F3CFC6',
            '770737',
            'F8C8DC',
            'FAA0A0',
            'E6E6FA',
            'CBC3E3',
            'CF9FFF',
            'AA98A9',
            '915F6D',
            'EDEADE',
            'F9F6EE',
            'ECFFDC',
            'F5F5DC',
            'FFFDD0',
            'F0EAD6',
            'E9DCC9',
            'FAF9F6',
            'FCF5E5'
        ];

        return colors[_colorId];
    }

    function getBackgroundFill(uint256 _colorId) public pure returns (string memory) {
        return string(abi.encodePacked('<rect width="100%" height="100%" fill="#', getBackgroungColor(_colorId), '"/>'));
    }
}