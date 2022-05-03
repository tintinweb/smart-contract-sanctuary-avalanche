// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IGOLD.sol";
import "./IERC20.sol";

contract CloversNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public maxMintAmountForTX;
    uint256 public MaxNFTMintableForWhithelistedAddresses;
    bool public paused = false;
    bool public onlyWhitelisted = true;
    bool public PaidInGold = false;
    address[] public whitelistedAddresses;
    address[] public blacklistedAddresses;
    address public usdc;
    address public gold;
    address public Treasury;

    struct ClovesInfo {
        string rarity;
        uint256 maxsupply;
        uint256 price;
        string BaseURI;
        uint256 bonus;
        uint256 supply;
    }

    mapping(string => ClovesInfo) public ClovesType;
    mapping(uint256 => string) public typeofbaseuri;

    mapping(address => uint256) public addressMintedBalance;
    IERC20 USDC = IERC20(usdc);
    IGOLD GOLD = IGOLD(gold);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
       
    {}

    // public
    function mint(uint256 _mintAmount, string memory _ClovesType)
        public
        
    {
        ClovesInfo memory cloves = ClovesType[_ClovesType];
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        uint256 price = cloves.price * _mintAmount;
        uint256 supply = totalSupply();
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmountForTX,
            "max mint amount per session exceeded"
        );
        require(
            cloves.supply + _mintAmount <= cloves.maxsupply,
            "max NFT limit exceeded"
        );

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(_isWhitelisted(msg.sender), "user is not whitelisted");
                require(
                    ownerMintedCount + _mintAmount <=
                        MaxNFTMintableForWhithelistedAddresses,
                    "max NFT per address exceeded"
                );
                _payNFTUSDC(price, msg.sender);
            } else {
                if (PaidInGold = true) {
                    require(
                        cloves.supply + _mintAmount <= cloves.maxsupply,
                        "max NFT already minted"
                    );
                    _payNFTGOLD(price, msg.sender);
                } else {
                    require(
                        cloves.supply + _mintAmount <= cloves.maxsupply,
                        "max NFT already minted"
                    );
                    _payNFTUSDC(price, msg.sender);
                }
            }
        }
        ClovesType[_ClovesType] = ClovesInfo({
            rarity: cloves.rarity,
            maxsupply: cloves.maxsupply,
            price: cloves.price,
            BaseURI: cloves.BaseURI,
            bonus: cloves.bonus,
            supply: cloves.supply + _mintAmount
        });
        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
            typeofbaseuri[(supply++)] = _ClovesType;
        }
    }

    function _payNFTUSDC(uint256 _amount, address _buyer) internal {
        require(USDC.balanceOf(_buyer) >= (_amount), "insufficient funds");
        USDC.transferFrom(_buyer, Treasury, _amount);
    }

    function _payNFTGOLD(uint256 _amount, address _buyer) internal {
        require(GOLD.balanceOf(_buyer) >= (_amount), "insufficient funds");
        GOLD.transferFrom(_buyer, Treasury, _amount);
    }

    function _isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function _isBlacklisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < blacklistedAddresses.length; i++) {
            if (blacklistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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
        string memory _clovestype = typeofbaseuri[tokenId];
        ClovesInfo memory cloves = ClovesType[_clovestype];

        return cloves.BaseURI;
    }

    /**ADDING BLACKLIST ON TRANSFERS
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(_isBlacklisted(msg.sender) == false, "You are BlackListed");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isBlacklisted(msg.sender) == false, "You are BlackListed");
        safeTransferFrom(from, to, tokenId, "");
    }


    function getBonusvalue(uint256 tokenId)
        external
        view
        returns (uint256 bonus)
    {
        string memory _clovestype = typeofbaseuri[tokenId];
        ClovesInfo memory cloves = ClovesType[_clovestype];
        return cloves.bonus;
    }

    function getRarityType(uint256 tokenId)
        external
        view
        returns (string memory rarity)
    {
        string memory _clovestype = typeofbaseuri[tokenId];
        ClovesInfo memory cloves = ClovesType[_clovestype];
        return cloves.rarity;
    }

    //only owner

    function setClovesInfo(
        string memory _Cloves,
        uint256 _maxsupply,
        uint256 _price,
        string memory _baseuri,
        uint256 _bonus,
        uint256 _supply
    ) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        ClovesType[_Cloves] = ClovesInfo({
            rarity: _Cloves,
            maxsupply: _maxsupply,
            price: _price,
            BaseURI: _baseuri,
            bonus: _bonus,
            supply: cloves.supply + _supply
        });
    }

    function getCloversInfo(string memory _rarity)
        external
        view
        returns (
            string memory rarity,
            uint256 maxsupply,
            uint256 price,
            string memory BaseURI,
            uint256 bonus,
            uint256 supply
        )
    {
        ClovesInfo memory cloves = ClovesType[_rarity];
        return (
            rarity = cloves.rarity,
            maxsupply = cloves.maxsupply,
            price = cloves.price,
            BaseURI = cloves.BaseURI,
            bonus = cloves.bonus,
            supply = cloves.supply
        );
    }

    function setPaidInGold(bool _PaidInGold) public onlyOwner {
        PaidInGold = _PaidInGold;
    }

    function setTreasury(address _Treasury) public onlyOwner {
        Treasury = _Treasury;
    }

    function setGOLDContract(address _gold) public onlyOwner {
        gold = _gold;
    }

    function setUSDCContract(address _usdc) public onlyOwner {
        usdc = _usdc;
    }

    function setMaxNFTMintableForWhithelistedAddresses(uint256 _MaxNFTMintableForWhithelistedAddresses)
        public
        onlyOwner
    {
        MaxNFTMintableForWhithelistedAddresses = _MaxNFTMintableForWhithelistedAddresses;
    }

    function setmaxMintAmountForTX(uint256 _newmaxMintAmountForTX) public onlyOwner {
        maxMintAmountForTX = _newmaxMintAmountForTX;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function AddWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistedAddresses.push(_users[i]);
        }
    }

    function RemoveWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = 0; a < whitelistedAddresses.length; a++) {
                if (whitelistedAddresses[a] == _users[i]) {
                    whitelistedAddresses[a] = whitelistedAddresses[
                        whitelistedAddresses.length - 1
                    ];
                    whitelistedAddresses.pop();
                }
            }
        }
    }

    function AddBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklistedAddresses.push(_users[i]);
        }
    }

    function RemoveBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = blacklistedAddresses.length; a == 0; a--) {
                if (blacklistedAddresses[a] == _users[i]) {
                    blacklistedAddresses[a] = blacklistedAddresses[
                        blacklistedAddresses.length - 1
                    ];
                    blacklistedAddresses.pop();
                }
            }
        }
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).call{value: address(this).balance};
    }
}