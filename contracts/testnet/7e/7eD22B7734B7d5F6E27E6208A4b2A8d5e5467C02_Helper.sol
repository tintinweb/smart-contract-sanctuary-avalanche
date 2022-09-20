// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply () external view returns (uint256);
}



contract Helper {

    // Loops through all the minted tokens of the provided contract and returns the IDs belonging to the wallet
    function tokensOf(address _contract, address _wallet) external view returns (uint256[] memory) {
        uint256 balance = IERC721(_contract).balanceOf(_wallet);
        uint256[] memory tokens = new uint256[](balance);
        uint256 counter = 0;
        uint256 supply = IERC721(_contract).totalSupply();
        for (uint256 id = 1; id <= supply; id++) {
            if (IERC721(_contract).ownerOf(id) == _wallet) {
                tokens[counter] = id;
                counter++;
            }
        }
        return tokens;
    }


}