// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import "./ERC2981ContractWideRoyalties.sol";

contract AiCasso is
ERC721Enumerable,
Ownable,
ERC2981ContractWideRoyalties {
    using Strings for uint256;

    uint256 public constant AIC_PUBLIC = 10_000;
    uint256 public constant AIC_GENERATOR = 10_000;
    uint256 public constant PURCHASE_LIMIT = 10;

    uint256 public PRICE = 1 ether;
    uint256 public WHITELIST_PRICE = 0.95 ether;

    bool public isActive = false;
    string public proof;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;
    uint256 public totalGeneratorSupply;

    mapping(address => bool) private _allowList;
    mapping(uint256 => string) private _generatorImage;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';

    address private _generator;

    modifier onlyGenerator() {
        require(_generator == msg.sender);
        _;
    }

    mapping(uint256 => address) private toRecovery;
    mapping(address => uint) public toRecoveryCount;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    unchecked {
        toRecovery[0] = address(0x0E5e74B274cbf68dECaaec85240805D35C9361DF);
        toRecoveryCount[0x0E5e74B274cbf68dECaaec85240805D35C9361DF] = 7;
        toRecovery[1] = address(0xC0a7227819C3e253c73037d8ec0E0782018dE893);
        toRecoveryCount[0xC0a7227819C3e253c73037d8ec0E0782018dE893] = 274;
        toRecovery[2] = address(0xb2fe488641228Ea847DECD2776E1E40ff0B37783);
        toRecoveryCount[0xb2fe488641228Ea847DECD2776E1E40ff0B37783] = 2;
        toRecovery[3] = address(0x03c3a50132Ade4600Eb522927e6bc038833251Ef);
        toRecoveryCount[0x03c3a50132Ade4600Eb522927e6bc038833251Ef] = 76;
        toRecovery[4] = address(0xb026f92820EbFe16E88132468b32a149D0626b7B);
        toRecoveryCount[0xb026f92820EbFe16E88132468b32a149D0626b7B] = 1;
        toRecovery[5] = address(0x4D4aFeDb99924E9Bcadd8D316770041E586A08EA);
        toRecoveryCount[0x4D4aFeDb99924E9Bcadd8D316770041E586A08EA] = 53;
        toRecovery[6] = address(0xED2e2c5385d5242fCf71E3671458Ce849EE2c9E7);
        toRecoveryCount[0xED2e2c5385d5242fCf71E3671458Ce849EE2c9E7] = 6;
        toRecovery[7] = address(0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D);
        toRecoveryCount[0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D] = 19;
        toRecovery[8] = address(0x648213045D8c2c373cc40F73E13c67C8e0Ff81Bc);
        toRecoveryCount[0x648213045D8c2c373cc40F73E13c67C8e0Ff81Bc] = 1;
        toRecovery[9] = address(0x9B14e5E96f45995ae74fF491924398A5b02869c4);
        toRecoveryCount[0x9B14e5E96f45995ae74fF491924398A5b02869c4] = 1;
        toRecovery[10] = address(0x7B5D762BCFD3303bca1fcE30CD3Bc4D416D85757);
        toRecoveryCount[0x7B5D762BCFD3303bca1fcE30CD3Bc4D416D85757] = 3;
        toRecovery[11] = address(0x30F24484b383655150D5b767b68A891E215B8881);
        toRecoveryCount[0x30F24484b383655150D5b767b68A891E215B8881] = 2;
        toRecovery[12] = address(0xe08707eAe41b7a8213175Af061254eE8154A8Fbc);
        toRecoveryCount[0xe08707eAe41b7a8213175Af061254eE8154A8Fbc] = 1;
        toRecovery[13] = address(0x39b2eC93f9296Cbf272aFc3f132DCD669aB61f8F);
        toRecoveryCount[0x39b2eC93f9296Cbf272aFc3f132DCD669aB61f8F] = 3;
        toRecovery[14] = address(0x8797B4Ee93B987f606E3DBeCcc9103EC3d32b2D6);
        toRecoveryCount[0x8797B4Ee93B987f606E3DBeCcc9103EC3d32b2D6] = 10;
        toRecovery[15] = address(0x9010995cC801d8897e969ADB7e3C86b30bf70353);
        toRecoveryCount[0x9010995cC801d8897e969ADB7e3C86b30bf70353] = 4;
        toRecovery[16] = address(0x9d48176B453d58d163baf8C9B9F884A4AB64B55f);
        toRecoveryCount[0x9d48176B453d58d163baf8C9B9F884A4AB64B55f] = 1;
        toRecovery[17] = address(0xb18A551aeEc4069C85Fe7651C145C6b08e9Ab23e);
        toRecoveryCount[0xb18A551aeEc4069C85Fe7651C145C6b08e9Ab23e] = 1;
        toRecovery[18] = address(0x463ecf308dF1061Dc8c36e48c46993b6C523a51f);
        toRecoveryCount[0x463ecf308dF1061Dc8c36e48c46993b6C523a51f] = 4;
        toRecovery[19] = address(0x0Ee05F77514F1FbC71D6B647B4EFf5D12C246E9d);
        toRecoveryCount[0x0Ee05F77514F1FbC71D6B647B4EFf5D12C246E9d] = 1;
        toRecovery[20] = address(0x2D1CaB1B697Ba0eb1FfEF9653D3e29B8c631D847);
        toRecoveryCount[0x2D1CaB1B697Ba0eb1FfEF9653D3e29B8c631D847] = 4;
        toRecovery[21] = address(0xB8ad1597a6795F45237e99438035885AA2A8F769);
        toRecoveryCount[0xB8ad1597a6795F45237e99438035885AA2A8F769] = 5;
        toRecovery[22] = address(0xa84546e35B27933F83596838EE958615B7062196);
        toRecoveryCount[0xa84546e35B27933F83596838EE958615B7062196] = 1;
        toRecovery[23] = address(0x8A6ea1e51Ce90F02A8CB94db9721B31355769000);
        toRecoveryCount[0x8A6ea1e51Ce90F02A8CB94db9721B31355769000] = 2;
        toRecovery[24] = address(0x91B85C0aD32f7711fF142771896126ca91Ce522a);
        toRecoveryCount[0x91B85C0aD32f7711fF142771896126ca91Ce522a] = 1;
        toRecovery[25] = address(0x689a185c6181Bee755bb824dE547e159D87245aD);
        toRecoveryCount[0x689a185c6181Bee755bb824dE547e159D87245aD] = 1;
        toRecovery[26] = address(0xebd746FEF9952aeC908DF471b65aCE4E05210ADB);
        toRecoveryCount[0xebd746FEF9952aeC908DF471b65aCE4E05210ADB] = 2;
        toRecovery[27] = address(0xCf6CA3d4155f99e5262c85f1d8ED207a3625E929);
        toRecoveryCount[0xCf6CA3d4155f99e5262c85f1d8ED207a3625E929] = 1;
        toRecovery[28] = address(0xD13F5ab20CEa9A47B6D92BE737513e7A67926f7a);
        toRecoveryCount[0xD13F5ab20CEa9A47B6D92BE737513e7A67926f7a] = 1;
        toRecovery[29] = address(0x925e716073e15905218264e66Da4Db1147D10a8c);
        toRecoveryCount[0x925e716073e15905218264e66Da4Db1147D10a8c] = 2;
        toRecovery[30] = address(0xb66fd793beBb6D1a3Eb2a5c33b82090a976244F9);
        toRecoveryCount[0xb66fd793beBb6D1a3Eb2a5c33b82090a976244F9] = 1;
        toRecovery[31] = address(0x12f6F95Fdd25A9530d7B149B81dc1351baFDdB82);
        toRecoveryCount[0x12f6F95Fdd25A9530d7B149B81dc1351baFDdB82] = 1;
        toRecovery[32] = address(0xc7aCaCd1f7790Cd06B5b88413777c6c055C892b3);
        toRecoveryCount[0xc7aCaCd1f7790Cd06B5b88413777c6c055C892b3] = 2;
        toRecovery[33] = address(0xd8b2B7F42873F111348c835563e26865474337db);
        toRecoveryCount[0xd8b2B7F42873F111348c835563e26865474337db] = 1;
        toRecovery[34] = address(0xD515b88473D9310e63eD6a201Ca79D45E2803536);
        toRecoveryCount[0xD515b88473D9310e63eD6a201Ca79D45E2803536] = 1;
        toRecovery[35] = address(0x70fadd97fd7513901c566c3C94A2c68f96F59b5f);
        toRecoveryCount[0x70fadd97fd7513901c566c3C94A2c68f96F59b5f] = 1;
        toRecovery[36] = address(0x413158AC3D89DE2716Cc169a219ccBF8a8d3295B);
        toRecoveryCount[0x413158AC3D89DE2716Cc169a219ccBF8a8d3295B] = 1;
        toRecovery[37] = address(0x4C293D1F0bbb8fB6762f325D250B3582cd0EdAd0);
        toRecoveryCount[0x4C293D1F0bbb8fB6762f325D250B3582cd0EdAd0] = 1;
        toRecovery[38] = address(0x35065b4a23719CB0D8eB5fF4578374b8E8F423C9);
        toRecoveryCount[0x35065b4a23719CB0D8eB5fF4578374b8E8F423C9] = 1;
        toRecovery[39] = address(0x765DFeA3054841351C5603BC7Fc9822aF72AddfD);
        toRecoveryCount[0x765DFeA3054841351C5603BC7Fc9822aF72AddfD] = 1;
        toRecovery[40] = address(0x1EFd12b8e01337CCd4839f9580Fc685C202f1702);
        toRecoveryCount[0x1EFd12b8e01337CCd4839f9580Fc685C202f1702] = 1;
        toRecovery[41] = address(0x29713dec3F1d7f9BE176F15d7d10bEa91F18EBe5);
        toRecoveryCount[0x29713dec3F1d7f9BE176F15d7d10bEa91F18EBe5] = 1;
        toRecovery[42] = address(0x88c31f648bDbC89ecdfBaBE18b5A800E63ed8eE6);
        toRecoveryCount[0x88c31f648bDbC89ecdfBaBE18b5A800E63ed8eE6] = 1;
    }
    }

    function recoveryTokens(uint256 _count) external onlyOwner {
        unchecked {
            uint j;
            uint i;
            while(toRecovery[j] != address(0)) {
                if (i >= _count) {
                    break;
                } else {
                    uint count = toRecoveryCount[toRecovery[j]];
                    if (count > 0) {
                        uint256 tokenId = totalGeneratorSupply + 1;
                        totalGeneratorSupply += 1;
                        toRecoveryCount[toRecovery[j]] -= 1;
                        i++;
                        _mint(toRecovery[j], tokenId);
                    } else {
                        j++;
                    }
                }
            }
        }
    }

    function setGeneratorContract(address generator) external onlyOwner {
        require(generator != address(0), "Can't add the null address");
        _generator = generator;
    }

    function setPrice(uint256 _price, uint256 _wl_price) external onlyOwner {
        require(_price >= 0.01 ether);
        require(_wl_price >= 0.01 ether);
        PRICE = _price;
        WHITELIST_PRICE = _wl_price;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = true;
        }
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function _getPrice(address addr) private view returns (uint256) {
        return _allowList[addr] ? WHITELIST_PRICE : PRICE;
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _allowList[addresses[i]] = false;
        }
    }

    function mintGenerator(string memory ipfs, address buyer) external onlyGenerator {
        require(_generator != address(0), 'Generator is not active');
        require(isActive, 'Contract is not active');
        require(totalGeneratorSupply < AIC_GENERATOR, 'All tokens have been minted');

        uint256 tokenId = AIC_PUBLIC + totalGeneratorSupply + 1;
        totalGeneratorSupply += 1;
        _generatorImage[tokenId] = ipfs;
        _safeMint(buyer, tokenId);
    }

    function purchase(uint256 numberOfTokens) external payable {
        require(isActive, 'Contract is not active');
        require(totalSupply() < AIC_PUBLIC, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < AIC_PUBLIC, 'Purchase would exceed AIC_PUBLIC');
        require(_getPrice(msg.sender) * numberOfTokens <= msg.value, 'AVAX amount is not sufficient');

    unchecked {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < AIC_PUBLIC) {
                uint256 tokenId = totalPublicSupply + 1;
                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }
    }

    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function setProof(string calldata proofString) external onlyOwner {
        proof = proofString;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        if (tokenId > AIC_PUBLIC) {
            return string(abi.encodePacked('ipfs://', _generatorImage[tokenId]));
        }

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
        _tokenBaseURI;
    }

    function setRoyalties(address recipient, uint256 value) onlyOwner external {
        _setRoyalties(recipient, value);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, ERC2981Base)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}