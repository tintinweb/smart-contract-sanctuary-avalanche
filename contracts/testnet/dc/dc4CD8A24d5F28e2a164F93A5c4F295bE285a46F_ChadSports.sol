// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

  ________              __   _____                  __      
  / ____/ /_  ____ _____/ /  / ___/____  ____  _____/ /______
 / /   / __ \/ __ `/ __  /   \__ \/ __ \/ __ \/ ___/ __/ ___/
/ /___/ / / / /_/ / /_/ /   ___/ / /_/ / /_/ / /  / /_(__  ) 
\____/_/ /_/\__,_/\__,_/   /____/ .___/\____/_/   \__/____/  
                               /_/                           


*/

// OpenZeppelin
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./Utils.sol";

contract ChadSports is ERC1155, Ownable {

    constructor() ERC1155("")
        {
        name = "TestCSQ";
        symbol = "TESTCSQ";
        _uriBase = "ipfs://QmQyoRPzJpceXmv3uApjam8hLYXwRgThvg8vQ4wdWX9p4M/"; // IPFS base for ParkPics collection
    }

    string public name;
    string public symbol;
    string public _uriBase;

    function setUriBase(string memory _newUriBase) external onlyOwner {
        _uriBase = _newUriBase;
    }

    /** @dev URI override for OpenSea traits compatibility. */

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
    }

    // V R F
    /** @dev Minting funtions. */

    function mint(uint256 id)
        public
        payable
    {
        _mint(msg.sender, id, 1, "");
    }

    function mintBatch(uint team1, uint team2, uint team3, uint team4)
        public payable
    {
        uint[] memory ids = new uint[](4);
        ids[0] = team1;
        ids[1] = team2;
        ids[2] = team3;
        ids[3] = team4;

        uint[] memory amount = new uint[](4);
        amount[0] = 1;
        amount[1] = 1;
        amount[2] = 1;
        amount[3] = 1;

        _mintBatch(msg.sender, ids, amount, "");
    }


    function withdrawEth(address _receiver) public payable onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }
}