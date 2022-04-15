//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./LiveSale.sol";
import "./PreSale.sol";
import "./WhiteList.sol";

/*
             -#%%+.                        :#%#*:           
            =%@@@%#:                      [email protected]@@%%%+          
           +%@@@@@@%=                   .#@@@@@@%%+         
          *%@@@@@@@@%*                 -%@@@@@@@@%%-        
         -%@@@@@@@@@@%+               [email protected]@@@@@@@@@%%%        
         *@@@@@@@@@@@@%-             *@@@@@@@@@@@@%%+       
        .%@@@@@@@@@@@@@%:-=+*####*+=*@@@@@@@@@@@@@%%#       
        [email protected]@@@@@@@@@@@@@%%%%@@@@@@%%%@@@@@@@@@@@@@@@%%.      
        [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%.      
        :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%       
        :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#       
..=++*#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%#*=. 
*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%
 #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%
  *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*
   -%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%= 
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*.  
      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%*:    
        .=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.      
          *%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%:       
         +%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%       
         #%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%       
         =%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*       
        .+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#-      
       +%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#:    */

contract HHAppiestFox is WhiteList, PreSale, LiveSale {
    using Strings for uint256;

    string public URI;
    bool public REVEAL = false;

    constructor(
        string memory _name,
        string memory _symbol, //,
        string memory initialURI
    ) ERC721(_name, _symbol) {
        URI = initialURI;
        //set royalty of All NTFs to 5%
        _setDefaultRoyalty(msg.sender, 500);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(URI, tokenId.toString()));
    }

    function setDisclosure(bool reveal, string memory updatedURI) public onlyOwner {
        REVEAL = reveal;
        URI = updatedURI;
    }
    
    function getReveal() public view returns (bool) {
        return REVEAL;
    }


    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}