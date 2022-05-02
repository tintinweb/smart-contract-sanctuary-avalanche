// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IGOLD.sol";
import "./IERC20.sol";

contract GoldPot is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI;
    uint256 public cost = 1 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountForTX = 20;
    uint256 public MaxNFTMintableForWhithelistedAddresses = 3;
    bool public paused = false;
    bool public PaidInGold = false;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    address[] public blacklistedAddresses;
    address public usdc;
    address public gold;
    address public Treasury;

    mapping(address => uint256) public addressMintedBalance;
    IERC20 USDC = IERC20(usdc);
    IGOLD GOLD = IGOLD(gold);

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        uint256 price = cost * _mintAmount;

        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmountForTX,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(_isWhitelisted(msg.sender), "user is not whitelisted");
                require(
                    ownerMintedCount + _mintAmount <=
                        MaxNFTMintableForWhithelistedAddresses,
                    "max NFT per address exceeded"
                );
                require(_payNFTUSDC(price, msg.sender),"Payment Failed");
            } else {
                if (PaidInGold = true) {
                   require(_payNFTGOLD(price, msg.sender),"Payment Failed");
                } else {
                    require(_payNFTUSDC(price, msg.sender),"Payment Failed");
                }
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function _payNFTUSDC(uint256 _amount, address _buyer) internal returns (bool Confirmed) {
        uint256  balanceTreasury = USDC.balanceOf(Treasury);
        require(USDC.balanceOf(_buyer) >= (_amount), "insufficient funds");
        USDC.transferFrom(_buyer, Treasury, _amount);
        require(USDC.balanceOf(Treasury) == balanceTreasury + _amount, "Payment Failed" );
        return Confirmed = true;

    }

    function _payNFTGOLD(uint256 _amount, address _buyer) internal returns (bool Confirmed) {
        uint256  balanceTreasury = GOLD.balanceOf(Treasury);
        require(GOLD.balanceOf(_buyer) >= (_amount), "insufficient funds");
        GOLD.transferFrom(_buyer, Treasury, _amount);
        require(GOLD.balanceOf(Treasury) == balanceTreasury + _amount, "Payment Failed" );
        return Confirmed = true;
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

        return baseURI;
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

    function transferFromEX(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transferFrom(from, to, tokenId);
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

   

    //only owner

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

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmountForTX(uint256 _newmaxMintAmountForTX) public onlyOwner {
        maxMintAmountForTX = _newmaxMintAmountForTX;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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