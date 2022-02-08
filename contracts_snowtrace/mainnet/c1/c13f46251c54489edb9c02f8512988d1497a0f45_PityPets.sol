//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Dependencies.sol";
import "./Base64.sol";
import "./ICreatureVector.sol";
import "./Utils.sol";
import "./EyesLips.sol";

contract PityPets is ERC721Enumerable, ReentrancyGuard, Ownable {
    struct CreatureData {
        string creature;
        string attributes;
        string colors;
        string background; 
    }

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 private constant SEWS_LAYER = 3;
    uint256 private constant EYES_NUM = 14; //should correspond EyesLips contract
    uint256 private constant LIPS_NUM = 11; //should correspond EyesLips contract

    uint256[7] private LAYER_SEQUENCE = [6, 2, 1, 5, 4, 3, 0];

    string[] private partNames = [
        "Head", //0
        "Body", //1
        "RightHand", //2
        "LeftHand", //3
        "LeftLeg", //4
        "RightLeg", //5
        "Addition" //6
    ];

    mapping(uint256 => ICreatureVector) public creatures;
    EyesLips public eyesLips;
    uint256 private totalCreatures;
    uint256 public price = 15000000000000000;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isBurner;
    mapping (uint256 => uint256) private idSeeds;
    uint256 private lastSeed = 200;

    uint256 public ownerReserveLeft = 200;
    uint256 public ownerReserveMaxId;
    uint256 public claimsLeft;
    bool public isMintStarted = false;

    mapping (address => bool) public hasMintPrority;
    bool public isPriorityMintStarted = false;

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function startMint(bool _priority) public onlyOwner {
        if (_priority) {
            isPriorityMintStarted = true;
        } else {
            isMintStarted = true;
        }
    }

    function addToPriortyMint(address _minter, bool add) public onlyOwner {
        if (add) {
            hasMintPrority[_minter] = true;
        } else {
            hasMintPrority[_minter] = false;
        }
    }

    function whitelist(address _who, bool add) public onlyOwner {
        if (add) {
            isWhitelisted[_who] = true;
        } else {
            delete isWhitelisted[_who];
        }
    }

    function setBurner(address _who, bool add) public onlyOwner {
        if (add) {
            isBurner[_who] = true;
        } else {
            delete isBurner[_who];
        }
    }

    function burn(uint256 tokenId) public {
        require(isBurner[msg.sender], "Not burner");
        require(msg.sender == ownerOf(tokenId), "Not owner");

        _burn(tokenId);
        delete idSeeds[tokenId];
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function getTokenData(uint256 tokenId, bool isSeed) public view returns (CreatureData memory) {
        require(isWhitelisted[msg.sender], "not whitelisted");

        uint256 id = tokenId;

        if (!isSeed) {
            id = idSeeds[tokenId];
        }

        return _getToken(id);
    }

    function getTokenPartData(uint256 tokenId, uint256 partId, bool isSeed) public view returns (string memory, string memory, string memory) {
        require(isWhitelisted[msg.sender], "not whitelisted");

        uint256 creatureN;
        uint256 id = tokenId;

        if (!isSeed) {
            id = idSeeds[tokenId];
        }

        if (id >= totalCreatures) {
            uint256 rand = Utils.random(string(abi.encodePacked(partNames[partId], Utils.toString(id))));
            creatureN = rand % totalCreatures;
        } else {
            creatureN = id;
        }

        ICreatureVector creature = creatures[creatureN];
        string memory creatureName = creature.name();

        uint256 randColor = Utils.random(string(abi.encodePacked(creatureName, Utils.toString(id))));
        (string memory color, string memory colorId) = creature.getColor(randColor % 10);
        string memory colorString = string(abi.encodePacked( '#', colorId, '{stroke: #05000e;fill: #',color, ';stroke-width:24px;}'));

        return (
            creature.getPart(partId),
            string(abi.encodePacked('{"trait_type":"', partNames[partId], '","value":"', creatureName,'"}')),
            colorString
        );
    }

    function getTokenSeed(uint256 tokenId) public view returns (uint256) {
        require(isWhitelisted[msg.sender], "not whitelisted");

        return idSeeds[tokenId];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 seed = idSeeds[tokenId];

        CreatureData memory creatureData = _getToken(seed);

        string memory output = string(abi.encodePacked(
            Utils.getSvgHeader(),
            creatureData.background, 
            creatureData.creature, 
            Utils.getDefs(creatureData.colors), 
            '</svg>'
        ));

        //TODO: Description
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Pity Pet #', Utils.toString(tokenId), 
            '", "description": "We are 9999 crippled creatures living on the Avalanche blockchain. ADOPT US, MORTAL!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), 
            '","attributes":[', creatureData.attributes, ']}'))));

        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 amount) payable public nonReentrant {
        require(isMintStarted, "Minting not started");
        require(amount <= claimsLeft, "All tokens are minted");
        require(amount <= 10, "Max 10 tokens per claim");
        require(msg.value >= price * amount, "AVAX value sent is not correct");

        uint256 seed = lastSeed + (Utils.random(Utils.toString(block.timestamp + lastSeed)) % 10) + 1;
        uint256 tokenId = totalSupply() + ownerReserveLeft;

        for (uint256 i = 0; i < amount; i++) {
            idSeeds[tokenId] = seed + i;
            _safeMint(_msgSender(), tokenId);
            tokenId++;
        }

        lastSeed = seed + amount;
        claimsLeft -= amount;
    }

    function priorityClaim() payable public nonReentrant {
        require(isPriorityMintStarted, "Minting not started");
        require(claimsLeft > 0, "All tokens are minted");
        require(msg.value >= price, "AVAX value sent is not correct");
        require(hasMintPrority[_msgSender()], "Not in priority list");

        uint256 seed = lastSeed + (Utils.random(Utils.toString(block.timestamp + lastSeed)) % 10) + 1;
        uint256 tokenId = totalSupply() + ownerReserveLeft;

        idSeeds[tokenId] = seed;
        _safeMint(_msgSender(), tokenId);

        lastSeed = seed;
        claimsLeft--;
        hasMintPrority[_msgSender()] = false;
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId <= ownerReserveMaxId, "Token ID invalid");
        require(ownerReserveLeft > 0, "Claimed all owner tokens");
        
        ownerReserveLeft--;

        _safeMint(owner(), tokenId);
        idSeeds[tokenId] = tokenId;
    }
        
    constructor(address[] memory _creatures, address _eyesLips) ERC721("Pity Pets", "PTY") Ownable() {
        require (_creatures.length > 0, "aaa");
        for (uint256 i = 0; i < _creatures.length; i++) {
            creatures[i] = ICreatureVector(_creatures[i]);
            totalCreatures++;
        }

        eyesLips = EyesLips(_eyesLips);

        claimsLeft = MAX_SUPPLY - ownerReserveLeft;
        ownerReserveMaxId = ownerReserveLeft - 1;

        isWhitelisted[msg.sender] = true;
    }

    function _getToken(uint256 tokenId) private view returns (CreatureData memory) {
        CreatureData memory creatureData;
        creatureData.colors = '<style type="text/css"><![CDATA[';

        uint256[] memory composedFrom = new uint256[](totalCreatures);
        uint256 uniqueCreatures = 0;
        uint256 maxParts = 0;

        for (uint256 i = 0; i < LAYER_SEQUENCE.length; i++) {
            uint256 part = LAYER_SEQUENCE[i];
            uint256 creatureN;

            if (tokenId >= totalCreatures) {
                uint256 rand = Utils.random(string(abi.encodePacked(partNames[part], Utils.toString(tokenId))));
                creatureN = rand % totalCreatures;
            } else {
                creatureN = tokenId;
            }

            ICreatureVector creature = creatures[creatureN];
            string memory creatureName = creature.name();

            if (composedFrom[creatureN] == 0) {
                uniqueCreatures++;
                uint256 rand = Utils.random(string(abi.encodePacked(creatureName, Utils.toString(tokenId))));
                (string memory color, string memory colorId) = creature.getColor(rand % 10);
                creatureData.colors = string(abi.encodePacked(creatureData.colors, '#', colorId, '{stroke: #05000e;fill: #',color, ';stroke-width:24px;}'));
            }

            composedFrom[creatureN]++;

            if (composedFrom[creatureN] > maxParts) {
                maxParts = composedFrom[creatureN];
            } 
            
            creatureData.creature = string(abi.encodePacked(creatureData.creature, creature.getPart(part)));
            
            if (i > 0) {
                creatureData.attributes = string(abi.encodePacked(creatureData.attributes, ','));
            }

            creatureData.attributes = string(abi.encodePacked(creatureData.attributes, '{"trait_type":"', partNames[part], '","value":"', creatureName,'"}'));

            if (part == SEWS_LAYER) {
                creatureData.creature = string(abi.encodePacked(
                    creatureData.creature,
                    '<g id="sews"><g><path d="M529.087,550.89c13.681,2.736 28.169,15.941 38.293,24.684" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M504.555,588.106c12.605,10.084 29.699,13.919 41.774,25.065" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M480.606,634.826c16.113,4.834 31.624,12.757 47.661,18.102" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M462.884,673.815c17.326,6.931 37.236,10.94 55.826,11.457" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M991.635,741.167c0.117,0.621 -6.482,1.13 -6.955,1.201c-3.831,0.571 -7.562,1.878 -11.165,3.452c-11.334,4.95 -21.448,12.805 -29.911,21.817" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M1025.46,757.65c0.376,0.341 -3.599,3.862 -3.867,4.136c-2.174,2.22 -3.927,4.863 -5.47,7.614c-4.852,8.655 -7.517,18.577 -8.567,28.44" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M975.105,697.049c-19.267,-1.6 -41.715,1.96 -57.012,16.23" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M986.363,660.325c-15.161,-17.717 -42.087,-18.615 -64.964,-17.267" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M1009.46,627.992c-3.713,-12.595 -25.566,-41.501 -54.96,-27.571" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M461.267,882.589c-14.682,-3.902 -46.783,26.385 -53.331,36.932" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M501.698,941.055c-13.876,-8.007 -36.866,5.678 -46.82,14.217" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M517.016,1007.71c-13.238,-14.1 -36.797,-15.16 -54.222,-8.891" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M504.698,1069.98c-8.975,-16.049 -27.194,-24.753 -45.65,-23.363" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M1009.77,997.539c-13.012,6.523 -18.162,32.533 -19.349,44.918" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M924.023,979.459c-1.052,17.918 10.17,39.035 18.143,54.251" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M852.009,1007.8c1.326,5.645 42.631,37.944 49.441,51.588" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M814.921,1071.88c20.344,-0.453 39.174,-0.096 57.054,11.257" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M808.11,1125.54c19.487,-5.859 37.731,-10.534 57.99,-4.358" style="fill:none;stroke:#05000e;stroke-width:23px;"/></g><g id="sews_head_cat"><path d="M606.382,508.989c4.081,1.367 40.902,43.512 121.524,63.498c86.876,21.536 192.952,3.328 252.68,-49.876" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M642.672,512.294c-12.752,7.689 -21.55,27.742 -28.087,39.566" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M682.662,530.57c-10.608,15.253 -22.554,29.735 -19.409,47.675" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M728.007,544.726c-13.867,13.586 -16.692,35.246 -11.94,55.97" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M786.909,553.683c-3.926,18.638 -5.406,40.485 -0,58.816" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M848.937,553.683c2.879,19.773 5.936,39.351 -0,58.816" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M890.374,545.576c15.023,13.303 20.502,39.694 17.351,56.739" style="fill:none;stroke:#05000e;stroke-width:23px;"/><path d="M939.39,526.968c17.824,12.66 34.821,29.789 34.017,42.516" style="fill:none;stroke:#05000e;stroke-width:23px;"/></g></g>'
                ));     
            }
        }

        //add eyes and lips
        uint256 eyesId = Utils.random(string(abi.encodePacked("Eyes", Utils.toString(tokenId)))) % EYES_NUM;
        uint256 lipsId = Utils.random(string(abi.encodePacked("Lips", Utils.toString(tokenId)))) % LIPS_NUM;
        creatureData.creature = string(abi.encodePacked(creatureData.creature, eyesLips.getEyes(eyesId), eyesLips.getLips(lipsId)));
        creatureData.attributes = string(abi.encodePacked(creatureData.attributes, ',{"trait_type":"Eyes","value":"', eyesLips.getEyesType(eyesId),'"}'));
        creatureData.attributes = string(abi.encodePacked(creatureData.attributes, ',{"trait_type":"Lips","value":"', eyesLips.getLipsType(lipsId),'"}'));

        //add numeric attributes
        creatureData.attributes = string(abi.encodePacked(creatureData.attributes, ',{"trait_type":"Unique pets","value":', Utils.toString(uniqueCreatures),'}'));
        creatureData.attributes = string(abi.encodePacked(creatureData.attributes, ',{"trait_type":"Max same pet parts","value":', Utils.toString(maxParts),'}'));

        for (uint256 i = 0; i < composedFrom.length; i++) {
            creatureData.attributes = string(abi.encodePacked(creatureData.attributes, ',{"trait_type":"', ICreatureVector(creatures[i]).name(),' parts","value":', Utils.toString(composedFrom[i]),'}'));
        }

        creatureData.colors = string(abi.encodePacked(creatureData.colors, ']]></style>'));

        uint256 bckgndColorId = Utils.random(string(abi.encodePacked("Background", Utils.toString(tokenId)))) % 74;
        creatureData.background = string(abi.encodePacked('<rect width="100%" height="100%" fill="#', Utils.getBackgroungColor(bckgndColorId), '"/>'));

        return creatureData;
    }
}