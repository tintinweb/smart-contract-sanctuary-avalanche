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
    uint256 public totalPublicSupply = 504;
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
    uint256 private currentIndexRecovery;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        currentIndexRecovery = 1;
        toRecovery[1] = 0x0E5e74B274cbf68dECaaec85240805D35C9361DF;
        toRecovery[2] = 0xC0a7227819C3e253c73037d8ec0E0782018dE893;
        toRecovery[173] = 0xb2fe488641228Ea847DECD2776E1E40ff0B37783;
        toRecovery[174] = 0xb2fe488641228Ea847DECD2776E1E40ff0B37783;
        toRecovery[175] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[176] = 0x0E5e74B274cbf68dECaaec85240805D35C9361DF;
        toRecovery[177] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[194] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[195] = 0xC0a7227819C3e253c73037d8ec0E0782018dE893;
        toRecovery[205] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[215] = 0xC0a7227819C3e253c73037d8ec0E0782018dE893;
        toRecovery[235] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[255] = 0xC0a7227819C3e253c73037d8ec0E0782018dE893;
        toRecovery[328] = 0xb026f92820EbFe16E88132468b32a149D0626b7B;
        toRecovery[329] = 0x4D4aFeDb99924E9Bcadd8D316770041E586A08EA;
        toRecovery[369] = 0xED2e2c5385d5242fCf71E3671458Ce849EE2c9E7;
        toRecovery[375] = 0x4D4aFeDb99924E9Bcadd8D316770041E586A08EA;
        toRecovery[388] = 0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D;
        toRecovery[402] = 0x648213045D8c2c373cc40F73E13c67C8e0Ff81Bc;
        toRecovery[403] = 0xfAB97f628fdCAd65aa67dF39f9EB0eaf075b636D;
        toRecovery[408] = 0x9B14e5E96f45995ae74fF491924398A5b02869c4;
        toRecovery[409] = 0x7B5D762BCFD3303bca1fcE30CD3Bc4D416D85757;
        toRecovery[411] = 0x30F24484b383655150D5b767b68A891E215B8881;
        toRecovery[413] = 0xe08707eAe41b7a8213175Af061254eE8154A8Fbc;
        toRecovery[414] = 0x39b2eC93f9296Cbf272aFc3f132DCD669aB61f8F;
        toRecovery[415] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[425] = 0x8797B4Ee93B987f606E3DBeCcc9103EC3d32b2D6;
        toRecovery[435] = 0x39b2eC93f9296Cbf272aFc3f132DCD669aB61f8F;
        toRecovery[437] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[447] = 0x9010995cC801d8897e969ADB7e3C86b30bf70353;
        toRecovery[449] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[453] = 0x9d48176B453d58d163baf8C9B9F884A4AB64B55f;
        toRecovery[454] = 0xb18A551aeEc4069C85Fe7651C145C6b08e9Ab23e;
        toRecovery[455] = 0x9010995cC801d8897e969ADB7e3C86b30bf70353;
        toRecovery[457] = 0x03c3a50132Ade4600Eb522927e6bc038833251Ef;
        toRecovery[460] = 0x0E5e74B274cbf68dECaaec85240805D35C9361DF;
        toRecovery[461] = 0x463ecf308dF1061Dc8c36e48c46993b6C523a51f;
        toRecovery[465] = 0x0Ee05F77514F1FbC71D6B647B4EFf5D12C246E9d;
        toRecovery[466] = 0x2D1CaB1B697Ba0eb1FfEF9653D3e29B8c631D847;
        toRecovery[470] = 0xB8ad1597a6795F45237e99438035885AA2A8F769;
        toRecovery[475] = 0x0E5e74B274cbf68dECaaec85240805D35C9361DF;
        toRecovery[476] = 0xa84546e35B27933F83596838EE958615B7062196;
        toRecovery[477] = 0x8A6ea1e51Ce90F02A8CB94db9721B31355769000;
        toRecovery[479] = 0x91B85C0aD32f7711fF142771896126ca91Ce522a;
        toRecovery[480] = 0x0E5e74B274cbf68dECaaec85240805D35C9361DF;
        toRecovery[482] = 0x7B5D762BCFD3303bca1fcE30CD3Bc4D416D85757;
        toRecovery[483] = 0x689a185c6181Bee755bb824dE547e159D87245aD;
        toRecovery[484] = 0xebd746FEF9952aeC908DF471b65aCE4E05210ADB;
        toRecovery[485] = 0xebd746FEF9952aeC908DF471b65aCE4E05210ADB;
        toRecovery[486] = 0xCf6CA3d4155f99e5262c85f1d8ED207a3625E929;
        toRecovery[487] = 0xD13F5ab20CEa9A47B6D92BE737513e7A67926f7a;
        toRecovery[488] = 0x925e716073e15905218264e66Da4Db1147D10a8c;
        toRecovery[490] = 0xb66fd793beBb6D1a3Eb2a5c33b82090a976244F9;
        toRecovery[491] = 0x0E5e74B274cbf68dECaaec85240805D35C9361DF;
        toRecovery[492] = 0x12f6F95Fdd25A9530d7B149B81dc1351baFDdB82;
        toRecovery[493] = 0xc7aCaCd1f7790Cd06B5b88413777c6c055C892b3;
        toRecovery[495] = 0xd8b2B7F42873F111348c835563e26865474337db;
        toRecovery[496] = 0xD515b88473D9310e63eD6a201Ca79D45E2803536;
        toRecovery[497] = 0x70fadd97fd7513901c566c3C94A2c68f96F59b5f;
        toRecovery[498] = 0x413158AC3D89DE2716Cc169a219ccBF8a8d3295B;
        toRecovery[499] = 0x4C293D1F0bbb8fB6762f325D250B3582cd0EdAd0;
        toRecovery[500] = 0x35065b4a23719CB0D8eB5fF4578374b8E8F423C9;
        toRecovery[501] = 0x765DFeA3054841351C5603BC7Fc9822aF72AddfD;
        toRecovery[502] = 0x1EFd12b8e01337CCd4839f9580Fc685C202f1702;
        toRecovery[503] = 0x29713dec3F1d7f9BE176F15d7d10bEa91F18EBe5;
        toRecovery[504] = 0x88c31f648bDbC89ecdfBaBE18b5A800E63ed8eE6;
    }

    function recoveryTokens(uint256 _count) external onlyOwner {
        require(currentIndexRecovery + _count < 505);

        address lastViewedAddress;
        unchecked {
            if (toRecovery[currentIndexRecovery] == address(0)) {
                for (uint256 i = currentIndexRecovery; i > 0; i--) {
                    if (toRecovery[i] != address(0)) {
                        lastViewedAddress = toRecovery[i];
                    }
                }
            }

            for (uint256 i = currentIndexRecovery; i < currentIndexRecovery + _count; i++) {
                if (toRecovery[i] != address(0)) {
                    lastViewedAddress = toRecovery[i];
                }
                _mint(lastViewedAddress, i);
            }

            currentIndexRecovery += _count;
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