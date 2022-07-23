/**
 *Submitted for verification at snowtrace.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITreeNFT {
    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract RefundCoreNft {
    address private seedNFT = 0x42ecA91e6AA2aB734b476108167ad71396db564d;
    address private saplingNFT = 0x37Cc7304DB8Fc9b01E81352dcEF4e05abE4D180D;
    address private treeNFT = 0x8f07f8D305423F790099b3AF58743a0D2E21Ba4D;

    function getEligibleTreeNfts() public view returns (uint256) {
        address _owner = msg.sender;

        uint256 numberOf = ITreeNFT(treeNFT).balanceOf(_owner);
        return numberOf;

        //tree nft first do balanceOf to get the number of tree nfts
        //then loop through that amount and you'll get the token ids by using tokenOfOwnerByIndex
        //now have the tree nfts of this guy so we then must check if it was in a secondary market or not
    }

    function getEligibleSaplingNfts() public view {}

    function getEligibleSeedNfts() public view {}

    // function hasNftSwappedThroughMarket(string memory nftType) public {
    //     if(nftType == 'seed') {

    //     } else if(nftType == 'sapling') {

    //     } else if(nftType == 'tree') {

    //     }
    // }
}