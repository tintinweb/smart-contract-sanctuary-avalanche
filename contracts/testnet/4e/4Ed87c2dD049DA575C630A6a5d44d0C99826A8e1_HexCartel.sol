// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./HexCartelLibrary.sol";

/// @title Hex Cartel NFTs Collection
/// @author cd33
contract HexCartel is Ownable, ERC1155, IERC2981, PaymentSplitter {
    using Strings for uint256;

    // address private recipient = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    enum Step {
        Before,
        WhitelistPremiumSale,
        WhitelistSale,
        PublicSale
    }

    Step public sellingStep;

    // Number of addresses in the PaymentSplitter
    uint8 private teamLength;

    // NORMAL CARDS
    uint8 public normal1NumberLimit = 72;
    uint8 public normal13NumberLimit = 144;
    uint8 public normal12NumberLimit = 216;
    uint16 public normal11NumberLimit = 288;
    uint16 public normal10NumberLimit = 432;
    uint16 public normal9NumberLimit = 504;
    uint16 public normal8NumberLimit = 576;
    uint16 public normal7NumberLimit = 648;
    uint16 public normal6NumberLimit = 720;
    uint16 public normal5NumberLimit = 792;
    uint16 public normal4NumberLimit = 864;
    uint16 public normal3NumberLimit = 936;
    uint16 public normal2NumberLimit = 1008;
    uint16 public normalTotalCards = 7200;

    // MUTANT CARDS
    uint8 public mutant1NumberLimit = 36;
    uint8 public mutant13NumberLimit = 72;
    uint8 public mutant12NumberLimit = 108;
    uint8 public mutant11NumberLimit = 144;
    uint8 public mutant10NumberLimit = 216;
    uint8 public mutant9NumberLimit = 252;
    uint16 public mutant8NumberLimit = 288;
    uint16 public mutant7NumberLimit = 324;
    uint16 public mutant6NumberLimit = 360;
    uint16 public mutant5NumberLimit = 396;
    uint16 public mutant4NumberLimit = 432;
    uint16 public mutant3NumberLimit = 468;
    uint16 public mutant2NumberLimit = 504;
    uint16 public mutantTotalCards = 3600;

    // CYBORG CARDS
    uint8 public cyborg1NumberLimit = 12;
    uint8 public cyborg13NumberLimit = 24;
    uint8 public cyborg12NumberLimit = 36;
    uint8 public cyborg11NumberLimit = 48;
    uint8 public cyborg10NumberLimit = 72;
    uint8 public cyborg9NumberLimit = 84;
    uint8 public cyborg8NumberLimit = 96;
    uint8 public cyborg7NumberLimit = 108;
    uint8 public cyborg6NumberLimit = 120;
    uint8 public cyborg5NumberLimit = 132;
    uint8 public cyborg4NumberLimit = 144;
    uint8 public cyborg3NumberLimit = 156;
    uint8 public cyborg2NumberLimit = 168;
    uint16 public cyborgTotalCards = 1200;

    uint16 public totalCardsRemaining = 12000;

    // uint256 public cardPriceWhitelistPremium = 0.5 ether;
    // uint256 public boosterPriceWhitelistPremium = 2 ether;
    // uint256 public cardPriceWhitelist = 0.75 ether;
    // uint256 public boosterPriceWhitelist = 3 ether;
    // uint256 public cardPricePublicSale = 1 ether;
    // uint256 public boosterPricePublicSale = 2.25 ether;
    uint256 public cardPriceWhitelistPremium = 0.0005 ether;
    uint256 public boosterPriceWhitelistPremium = 0.002 ether;
    uint256 public cardPriceWhitelist = 0.00075 ether;
    uint256 public boosterPriceWhitelist = 0.003 ether;
    uint256 public cardPricePublicSale = 0.001 ether;
    uint256 public boosterPricePublicSale = 0.00225 ether;

    uint32 public whitelistPremiumStartTime = 1652565600; // 15/05 à minuit
    uint32 public whitelistStartTime = 1652738400; // 17/05 à minuit
    uint32 public publicSaleStartTime = 1652997600; // 20/05 à minuit
    uint32 public firstExchangeAllowedStartTime = 1653861600; // 30/05 à minuit

    mapping(address => uint8) public amountCardsPerWalletWhitelistPremium;
    mapping(address => uint8) public amountBoostersPerWalletWhitelistPremium;
    mapping(address => uint8) public amountCardsPerWalletWhitelist;
    mapping(address => uint8) public amountBoostersPerWalletWhitelist;

    string public baseURI;

    bytes32 private merkleRoot;

    /**
     * @notice Emitted when the msg.sender buy a card.
     */
    event CardMinted(address _to, uint8 _cardId);

    /**
     * @notice Constructor of the contract ERC1155.
     * @param _team Addresses of the team members.
     * @param _teamShares Percentages of each member.
     * @param _merkleRoot Used for the whitelist.
     * @param _baseURI Metadatas for the ERC1155.
     */
    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        bytes32 _merkleRoot,
        string memory _baseURI
    ) ERC1155(_baseURI) PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        teamLength = uint8(_team.length);
    }

    /**
     * @notice Overrides safeTransferFrom of the parent ERC1155 to add a time delay.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            block.timestamp >= firstExchangeAllowedStartTime,
            "Not before 1 week after the first card game"
        );
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Overrides safeBatchTransferFrom of the parent ERC1155 to add a time delay.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            block.timestamp >= firstExchangeAllowedStartTime,
            "Not before 1 week after the first card game"
        );
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Enables only externally owned accounts (= users) to mint.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is a contract");
        _;
    }

    /**
     * @notice Allows to change the step of the contract.
     * @param _step Step to change.
     */
    function setStep(uint8 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
     * @notice Change the base URI.
     * @param _newBaseURI New base URI.
     **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Change the token's image URI, override for OpenSea traits compatibility.
     * @param _tokenId Id of the token.
     * @return string Token's metadatas URI.
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId > 0 && _tokenId < 40, "NFT doesn't exist");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
     * @notice Determines the card to be minted.
     * @param _num Value used to add randomness.
     */
    function _getCard(uint8 _num) private {
        uint16[14] memory _dataNormal = [
            totalCardsRemaining,
            normalTotalCards,
            normal2NumberLimit,
            normal3NumberLimit,
            normal4NumberLimit,
            normal5NumberLimit,
            normal6NumberLimit,
            normal7NumberLimit,
            normal8NumberLimit,
            normal9NumberLimit,
            normal10NumberLimit,
            normal11NumberLimit,
            normal12NumberLimit,
            normal13NumberLimit
        ];
        uint16[13] memory _dataMutant = [
            mutantTotalCards,
            mutant2NumberLimit,
            mutant3NumberLimit,
            mutant4NumberLimit,
            mutant5NumberLimit,
            mutant6NumberLimit,
            mutant7NumberLimit,
            mutant8NumberLimit,
            mutant9NumberLimit,
            mutant10NumberLimit,
            mutant11NumberLimit,
            mutant12NumberLimit,
            mutant13NumberLimit
        ];
        uint16[13] memory _dataCyborg = [
            cyborgTotalCards,
            cyborg2NumberLimit,
            cyborg3NumberLimit,
            cyborg4NumberLimit,
            cyborg5NumberLimit,
            cyborg6NumberLimit,
            cyborg7NumberLimit,
            cyborg8NumberLimit,
            cyborg9NumberLimit,
            cyborg10NumberLimit,
            cyborg11NumberLimit,
            cyborg12NumberLimit,
            cyborg13NumberLimit
        ];
        HexCartelLibrary.Card memory card = HexCartelLibrary._getRandomCard(
            _num,
            _dataNormal,
            _dataMutant,
            _dataCyborg
        );
        _decrementLimitNumber(card.cardId);
        _mint(
            msg.sender,
            card.cardId,
            1,
            bytes(abi.encodePacked(card.cardDescription))
        );
        emit CardMinted(msg.sender, card.cardId);
    }

    /**
     * @notice Determines the cards to be minted from the booster.
     */
    function _getBooster(uint8 _num) private {
        if (sellingStep == Step.WhitelistPremiumSale) {
            uint16[13] memory _dataCyborg = [
                cyborgTotalCards,
                cyborg2NumberLimit,
                cyborg3NumberLimit,
                cyborg4NumberLimit,
                cyborg5NumberLimit,
                cyborg6NumberLimit,
                cyborg7NumberLimit,
                cyborg8NumberLimit,
                cyborg9NumberLimit,
                cyborg10NumberLimit,
                cyborg11NumberLimit,
                cyborg12NumberLimit,
                cyborg13NumberLimit
            ];
            HexCartelLibrary.Card memory card = HexCartelLibrary._getCyborgCard(
                22222,
                _num,
                normalTotalCards,
                mutantTotalCards,
                _dataCyborg
            );
            _decrementLimitNumber(card.cardId);
            _mint(
                msg.sender,
                card.cardId,
                1,
                bytes(abi.encodePacked(card.cardDescription))
            );
            emit CardMinted(msg.sender, card.cardId);
            _getCard(1);
            _getCard(2);
            _getCard(3);
            _getCard(4);
        } else if (sellingStep == Step.WhitelistSale) {
            uint16[13] memory _dataMutant = [
                mutantTotalCards,
                mutant2NumberLimit,
                mutant3NumberLimit,
                mutant4NumberLimit,
                mutant5NumberLimit,
                mutant6NumberLimit,
                mutant7NumberLimit,
                mutant8NumberLimit,
                mutant9NumberLimit,
                mutant10NumberLimit,
                mutant11NumberLimit,
                mutant12NumberLimit,
                mutant13NumberLimit
            ];
            HexCartelLibrary.Card memory card = HexCartelLibrary._getMutantCard(
                22222,
                _num,
                normalTotalCards,
                _dataMutant
            );
            _decrementLimitNumber(card.cardId);
            _mint(
                msg.sender,
                card.cardId,
                1,
                bytes(abi.encodePacked(card.cardDescription))
            );
            emit CardMinted(msg.sender, card.cardId);
            _getCard(1);
            _getCard(2);
            _getCard(3);
            _getCard(4);
        } else {
            _getCard(0);
            _getCard(1);
            _getCard(2);
        }
    }

    /**
     * @notice Decreases the limit of the minted card.
     * @param _cardId Id of the token.
     */
    function _decrementLimitNumber(uint8 _cardId) private {
        if (_cardId > 0 && _cardId < 14) {
            if (_cardId == 1) {
                normal1NumberLimit--;
            }
            if (_cardId == 2) {
                normal2NumberLimit--;
            }
            if (_cardId == 3) {
                normal3NumberLimit--;
            }
            if (_cardId == 4) {
                normal4NumberLimit--;
            }
            if (_cardId == 5) {
                normal5NumberLimit--;
            }
            if (_cardId == 6) {
                normal6NumberLimit--;
            }
            if (_cardId == 7) {
                normal7NumberLimit--;
            }
            if (_cardId == 8) {
                normal8NumberLimit--;
            }
            if (_cardId == 9) {
                normal9NumberLimit--;
            }
            if (_cardId == 10) {
                normal10NumberLimit--;
            }
            if (_cardId == 11) {
                normal11NumberLimit--;
            }
            if (_cardId == 12) {
                normal12NumberLimit--;
            }
            if (_cardId == 13) {
                normal13NumberLimit--;
            }
            normalTotalCards--;
        } else if (_cardId > 13 && _cardId < 27) {
            if (_cardId == 14) {
                mutant1NumberLimit--;
            }
            if (_cardId == 15) {
                mutant2NumberLimit--;
            }
            if (_cardId == 16) {
                mutant3NumberLimit--;
            }
            if (_cardId == 17) {
                mutant4NumberLimit--;
            }
            if (_cardId == 18) {
                mutant5NumberLimit--;
            }
            if (_cardId == 19) {
                mutant6NumberLimit--;
            }
            if (_cardId == 20) {
                mutant7NumberLimit--;
            }
            if (_cardId == 21) {
                mutant8NumberLimit--;
            }
            if (_cardId == 22) {
                mutant9NumberLimit--;
            }
            if (_cardId == 23) {
                mutant10NumberLimit--;
            }
            if (_cardId == 24) {
                mutant11NumberLimit--;
            }
            if (_cardId == 25) {
                mutant12NumberLimit--;
            }
            if (_cardId == 26) {
                mutant13NumberLimit--;
            }
            mutantTotalCards--;
        } else {
            if (_cardId == 27) {
                cyborg1NumberLimit--;
            }
            if (_cardId == 28) {
                cyborg2NumberLimit--;
            }
            if (_cardId == 29) {
                cyborg3NumberLimit--;
            }
            if (_cardId == 30) {
                cyborg4NumberLimit--;
            }
            if (_cardId == 31) {
                cyborg5NumberLimit--;
            }
            if (_cardId == 32) {
                cyborg6NumberLimit--;
            }
            if (_cardId == 33) {
                cyborg7NumberLimit--;
            }
            if (_cardId == 34) {
                cyborg8NumberLimit--;
            }
            if (_cardId == 35) {
                cyborg9NumberLimit--;
            }
            if (_cardId == 36) {
                cyborg10NumberLimit--;
            }
            if (_cardId == 37) {
                cyborg11NumberLimit--;
            }
            if (_cardId == 38) {
                cyborg12NumberLimit--;
            }
            if (_cardId == 39) {
                cyborg13NumberLimit--;
            }
            cyborgTotalCards--;
        }
        totalCardsRemaining--;
    }

    // MINTS
    /**
     * @notice Mint a card during the whitelist premium.
     * @param _proof Merkle Proof.
     */
    function whitelistPremiumSaleMintCard(
        uint8 _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        // require(
        //     block.timestamp >= whitelistPremiumStartTime,
        //     "Whitelist Premium Sale has not started yet"
        // );
        // require(
        //     block.timestamp < whitelistPremiumStartTime + 1 days,
        //     "Whitelist Premium Sale is finished"
        // );
        require(
            sellingStep == Step.WhitelistPremiumSale,
            "Whitelist Premium sale not active"
        );
        require(_quantity > 0 && _quantity < 6, "Quantity between 1 & 5");
        require(totalCardsRemaining >= _quantity, "Sold out");
        require(_isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountCardsPerWalletWhitelistPremium[msg.sender] + _quantity <= 5,
            "Max 5 Cards per wallet"
        );
        require(
            msg.value >= cardPriceWhitelistPremium * _quantity,
            "Not enough funds"
        );
        // payable(recipient).transfer(address(this).balance);
        amountCardsPerWalletWhitelistPremium[msg.sender] += _quantity;
        for (uint8 i = 0; i < _quantity; i++) {
            _getCard(i);
        }
    }

    /**
     * @notice Mint a booster during the whitelist premium.
     * @param _proof Merkle Proof.
     */
    function whitelistPremiumSaleMintBooster(
        uint8 _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        // require(
        //     block.timestamp >= whitelistPremiumStartTime,
        //     "Whitelist Premium Sale has not started yet"
        // );
        // require(
        //     block.timestamp < whitelistPremiumStartTime + 1 days,
        //     "Whitelist Premium Sale is finished"
        // );
        require(
            sellingStep == Step.WhitelistPremiumSale,
            "Whitelist Premium sale not active"
        );
        require(_quantity > 0 && _quantity < 3, "Quantity between 1 & 2");
        require(totalCardsRemaining >= _quantity * 5, "Sold out");
        require(_isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountBoostersPerWalletWhitelistPremium[msg.sender] + _quantity <=
                2,
            "Max 2 Boosters per wallet"
        );
        require(
            msg.value >= boosterPriceWhitelistPremium * _quantity,
            "Not enough funds"
        );
        // payable(recipient).transfer(address(this).balance);
        amountBoostersPerWalletWhitelistPremium[msg.sender] += _quantity;
        for (uint8 i = 0; i < _quantity; i++) {
            _getBooster(i);
        }
    }

    /**
     * @notice Mint a card during the whitelist.
     * @param _proof Merkle Proof.
     */
    function whitelistSaleMintCard(uint8 _quantity, bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        // require(
        //     block.timestamp >= whitelistStartTime,
        //     "Whitelist Sale has not started yet"
        // );
        // require(
        //     block.timestamp < whitelistStartTime + 1 days,
        //     "Whitelist Sale is finished"
        // );
        require(sellingStep == Step.WhitelistSale, "Whitelist sale not active");
        require(_quantity > 0 && _quantity < 6, "Quantity between 1 & 5");
        require(totalCardsRemaining >= _quantity, "Sold out");
        require(_isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountCardsPerWalletWhitelist[msg.sender] + _quantity <= 5,
            "Max 5 Cards per wallet"
        );
        require(
            msg.value >= cardPriceWhitelist * _quantity,
            "Not enough funds"
        );
        // payable(recipient).transfer(address(this).balance);
        amountCardsPerWalletWhitelist[msg.sender] += _quantity;
        for (uint8 i = 0; i < _quantity; i++) {
            _getCard(i);
        }
    }

    /**
     * @notice Mint a booster during the whitelist.
     * @param _proof Merkle Proof.
     */
    function whitelistSaleMintBooster(bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        // require(
        //     block.timestamp >= whitelistStartTime,
        //     "Whitelist Sale has not started yet"
        // );
        // require(
        //     block.timestamp < whitelistStartTime + 1 days,
        //     "Whitelist Sale is finished"
        // );
        require(sellingStep == Step.WhitelistSale, "Whitelist sale not active");
        require(totalCardsRemaining >= 5, "Sold out");
        require(_isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountBoostersPerWalletWhitelist[msg.sender] < 1,
            "Max 1 Booster per wallet"
        );
        require(msg.value >= boosterPriceWhitelist, "Not enough funds");
        // payable(recipient).transfer(address(this).balance);
        amountBoostersPerWalletWhitelist[msg.sender]++;
        _getBooster(0);
    }

    /**
     * @notice Mint a card during the public sale.
     */
    function publicSaleMintCard(uint8 _quantity) external payable callerIsUser {
        // require(
        //     block.timestamp >= publicSaleStartTime,
        //     "Public Sale has not started yet"
        // );
        require(sellingStep == Step.PublicSale, "Public sale not active");
        require(_quantity > 0, "Quantity min 1");
        require(totalCardsRemaining >= _quantity, "Sold out");
        require(
            msg.value >= cardPricePublicSale * _quantity,
            "Not enough funds"
        );
        // payable(recipient).transfer(address(this).balance);
        for (uint8 i = 0; i < _quantity; i++) {
            _getCard(i);
        }
    }

    /**
     * @notice Mint a booster during the public sale.
     */
    function publicSaleMintBooster(uint8 _quantity)
        external
        payable
        callerIsUser
    {
        // require(
        //     block.timestamp >= publicSaleStartTime,
        //     "Public Sale has not started yet"
        // );
        require(sellingStep == Step.PublicSale, "Public sale not active");
        require(_quantity > 0, "Quantity min 1");
        require(totalCardsRemaining >= _quantity * 3, "Sold out");
        require(
            msg.value >= boosterPricePublicSale * _quantity,
            "Not enough funds"
        );
        // payable(recipient).transfer(address(this).balance);
        for (uint8 i = 0; i < _quantity; i++) {
            _getBooster(i);
        }
    }

    /**
     * @notice Allows the owner to offer NFTs.
     * @param _to Receiving address.
     * @param _tokenId Id of tokens to mint.
     * @param _name Name of tokens to mint.
     */
    function gift(
        address _to,
        uint8 _tokenId,
        string memory _name
    ) external onlyOwner {
        _decrementLimitNumber(_tokenId);
        _mint(_to, _tokenId, 1, bytes(abi.encodePacked(_name)));
        emit CardMinted(msg.sender, _tokenId);
    }

    // WHITELIST
    /**
     * @notice Change Merkle root to update the whitelist.
     * @param _merkleRoot Merkle Root.
     **/
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Return true or false if the account is whitelisted or not.
     * @param _account User's account.
     * @param _proof Merkle Proof.
     * @return bool Account whitelisted or not.
     **/
    function _isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(_leafHash(_account), _proof);
    }

    /**
     * @notice Return the account hashed.
     * @param _account Account to hash.
     * @return bytes32 Account hashed.
     **/
    function _leafHash(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /**
     * @notice Returns true if a leaf can be proven to be part of a Merkle tree defined by root.
     * @param _leaf Leaf.
     * @param _proof Merkle Proof.
     * @return bool Be part of the Merkle tree or not.
     **/
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // ROYALTIES
    /**
     * @notice EIP2981 standard royalties return.
     * @dev Returns how much royalty is owed and to whom.
     * @param _tokenId Id of the token.
     * @param _salePrice Price of the token.
     * @return receiver Address of receiver.
     * @return royaltyAmount Amount of royalty.
     **/
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * 2000) / 10000);
    }

    /**
     * @notice Returns true if this contract implements the interface IERC2981.
     * @param interfaceId Id of the interface.
     * @return bool Implements IERC2981 or not.
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /**
     * @notice Release money from all accounts.
     **/
    function releaseAll() external {
        for (uint8 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    /**
     * @notice Release specific token from all accounts.
     **/
    function releaseSpecificToken(IERC20 _token) external {
        for (uint8 i = 0; i < teamLength; i++) {
            release(_token, payee(i));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Hex Cartel Library
/// @author cd33
library HexCartelLibrary {
    struct Card {
        uint8 cardId;
        string cardDescription;
    }

    // NORMAL CARDS
    uint8 constant NORMAL1 = 1;
    uint8 constant NORMAL2 = 2;
    uint8 constant NORMAL3 = 3;
    uint8 constant NORMAL4 = 4;
    uint8 constant NORMAL5 = 5;
    uint8 constant NORMAL6 = 6;
    uint8 constant NORMAL7 = 7;
    uint8 constant NORMAL8 = 8;
    uint8 constant NORMAL9 = 9;
    uint8 constant NORMAL10 = 10;
    uint8 constant NORMAL11 = 11;
    uint8 constant NORMAL12 = 12;
    uint8 constant NORMAL13 = 13;

    // MUTANT CARDS
    uint8 constant MUTANT1 = 14;
    uint8 constant MUTANT2 = 15;
    uint8 constant MUTANT3 = 16;
    uint8 constant MUTANT4 = 17;
    uint8 constant MUTANT5 = 18;
    uint8 constant MUTANT6 = 19;
    uint8 constant MUTANT7 = 20;
    uint8 constant MUTANT8 = 21;
    uint8 constant MUTANT9 = 22;
    uint8 constant MUTANT10 = 23;
    uint8 constant MUTANT11 = 24;
    uint8 constant MUTANT12 = 25;
    uint8 constant MUTANT13 = 26;

    // CYBORG CARDS
    uint8 constant CYBORG1 = 27;
    uint8 constant CYBORG2 = 28;
    uint8 constant CYBORG3 = 29;
    uint8 constant CYBORG4 = 30;
    uint8 constant CYBORG5 = 31;
    uint8 constant CYBORG6 = 32;
    uint8 constant CYBORG7 = 33;
    uint8 constant CYBORG8 = 34;
    uint8 constant CYBORG9 = 35;
    uint8 constant CYBORG10 = 36;
    uint8 constant CYBORG11 = 37;
    uint8 constant CYBORG12 = 38;
    uint8 constant CYBORG13 = 39;

    /**
     * @notice Generates a random number.
     * @param _mod Maximum value returned.
     * @param _num Value used to add randomness.
     */
    function _generateRandomNumber(uint256 _mod, uint8 _num)
        private
        view
        returns (uint16)
    {
        return
            uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _num,
                            block.timestamp,
                            block.difficulty,
                            msg.sender
                        )
                    )
                ) % _mod
            );
    }

    /**
     * @notice Designates a card and returns the necessary information to the mint.
     * @param _num Value used to add randomness.
     * @param _dataNormal Necessary information about the normal cards.
     * @param _dataMutant Necessary information about the mutant cards.
     * @param _dataCyborg Necessary information about the cyborg cards.
     */
    function _getRandomCard(
        uint8 _num,
        uint16[14] memory _dataNormal,
        uint16[13] memory _dataMutant,
        uint16[13] memory _dataCyborg
    ) public view returns (Card memory) {
        uint16 randomNumber = _generateRandomNumber(_dataNormal[0], _num);
        if (randomNumber < _dataNormal[1]) {
            if (randomNumber < _dataNormal[2]) {
                return Card(NORMAL2, "HexCartel Type Normal #2");
            } else if (
                randomNumber >= _dataNormal[2] &&
                randomNumber < _dataNormal[2] + _dataNormal[3]
            ) {
                return Card(NORMAL3, "HexCartel Type Normal #3");
            } else if (
                randomNumber >= _dataNormal[2] + _dataNormal[3] &&
                randomNumber < _dataNormal[2] + _dataNormal[3] + _dataNormal[4]
            ) {
                return Card(NORMAL4, "HexCartel Type Normal #4");
            } else if (
                randomNumber >=
                _dataNormal[2] + _dataNormal[3] + _dataNormal[4] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5]
            ) {
                return Card(NORMAL5, "HexCartel Type Normal #5");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6]
            ) {
                return Card(NORMAL6, "HexCartel Type Normal #6");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7]
            ) {
                return Card(NORMAL7, "HexCartel Type Normal #7");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8]
            ) {
                return Card(NORMAL8, "HexCartel Type Normal #8");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9]
            ) {
                return Card(NORMAL9, "HexCartel Type Normal #9");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10]
            ) {
                return Card(NORMAL10, "HexCartel Type Normal #10");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11]
            ) {
                return Card(NORMAL11, "HexCartel Type Normal #11");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] +
                    _dataNormal[12]
            ) {
                return Card(NORMAL12, "HexCartel Type Normal #12");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] +
                    _dataNormal[12] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] +
                    _dataNormal[12] +
                    _dataNormal[13]
            ) {
                return Card(NORMAL13, "HexCartel Type Normal #13");
            } else {
                return Card(NORMAL1, "HexCartel Type Normal #1");
            }
        } else if (
            randomNumber >= _dataNormal[1] &&
            randomNumber < _dataNormal[1] + _dataMutant[0]
        ) {
            return _getMutantCard(randomNumber, 0, _dataNormal[1], _dataMutant);
        } else {
            return
                _getCyborgCard(
                    randomNumber,
                    0,
                    _dataNormal[1],
                    _dataMutant[0],
                    _dataCyborg
                );
        }
    }

    /**
     * @notice Designates a mutant card and returns the necessary information to the mint.
     * @param _randomNumber Random number already generated.
     * @param _num Value used to add randomness.
     * @param normalTotalCards Total number of normal cards.
     * @param _dataMutant Necessary information about the mutant cards.
     */
    function _getMutantCard(
        uint16 _randomNumber,
        uint8 _num,
        uint16 normalTotalCards,
        uint16[13] memory _dataMutant
    ) public view returns (Card memory) {
        uint16 randomNumber;
        if (_randomNumber != 22222) {
            randomNumber = _randomNumber - normalTotalCards;
        } else {
            randomNumber = _generateRandomNumber(_dataMutant[0] + 1, _num);
        }
        if (randomNumber < _dataMutant[1]) {
            return Card(MUTANT2, "HexCartel Type Mutant #2");
        } else if (
            randomNumber >= _dataMutant[1] &&
            randomNumber < _dataMutant[1] + _dataMutant[2]
        ) {
            return Card(MUTANT3, "HexCartel Type Mutant #3");
        } else if (
            randomNumber >= _dataMutant[1] + _dataMutant[2] &&
            randomNumber < _dataMutant[1] + _dataMutant[2] + _dataMutant[3]
        ) {
            return Card(MUTANT4, "HexCartel Type Mutant #4");
        } else if (
            randomNumber >= _dataMutant[1] + _dataMutant[2] + _dataMutant[3] &&
            randomNumber <
            _dataMutant[1] + _dataMutant[2] + _dataMutant[3] + _dataMutant[4]
        ) {
            return Card(MUTANT5, "HexCartel Type Mutant #5");
        } else if (
            randomNumber >=
            _dataMutant[1] + _dataMutant[2] + _dataMutant[3] + _dataMutant[4] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5]
        ) {
            return Card(MUTANT6, "HexCartel Type Mutant #6");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6]
        ) {
            return Card(MUTANT7, "HexCartel Type Mutant #7");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7]
        ) {
            return Card(MUTANT8, "HexCartel Type Mutant #8");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8]
        ) {
            return Card(MUTANT9, "HexCartel Type Mutant #9");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9]
        ) {
            return Card(MUTANT10, "HexCartel Type Mutant #10");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10]
        ) {
            return Card(MUTANT11, "HexCartel Type Mutant #11");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] +
                _dataMutant[11]
        ) {
            return Card(MUTANT12, "HexCartel Type Mutant #12");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] +
                _dataMutant[11] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] +
                _dataMutant[11] +
                _dataMutant[12]
        ) {
            return Card(MUTANT13, "HexCartel Type Mutant #13");
        } else {
            return Card(MUTANT1, "HexCartel Type Mutant #1");
        }
    }

    /**
     * @notice Designates a cyborg card and returns the necessary information to the mint.
     * @param _randomNumber Random number already generated.
     * @param _num Value used to add randomness.
     * @param normalTotalCards Total number of normal cards.
     * @param mutantTotalCards Total number of mutant cards.
     * @param _dataCyborg Necessary information about the cyborg cards.
     */
    function _getCyborgCard(
        uint16 _randomNumber,
        uint8 _num,
        uint16 normalTotalCards,
        uint16 mutantTotalCards,
        uint16[13] memory _dataCyborg
    ) public view returns (Card memory) {
        uint16 randomNumber;
        if (_randomNumber != 22222) {
            randomNumber = _randomNumber - normalTotalCards - mutantTotalCards;
        } else {
            randomNumber = _generateRandomNumber(_dataCyborg[0] + 1, _num);
        }
        if (randomNumber < _dataCyborg[1]) {
            return Card(CYBORG2, "HexCartel Type Cyborg #2");
        } else if (
            randomNumber >= _dataCyborg[1] &&
            randomNumber < _dataCyborg[1] + _dataCyborg[2]
        ) {
            return Card(CYBORG3, "HexCartel Type Cyborg #3");
        } else if (
            randomNumber >= _dataCyborg[1] + _dataCyborg[2] &&
            randomNumber < _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3]
        ) {
            return Card(CYBORG4, "HexCartel Type Cyborg #4");
        } else if (
            randomNumber >= _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3] &&
            randomNumber <
            _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3] + _dataCyborg[4]
        ) {
            return Card(CYBORG5, "HexCartel Type Cyborg #5");
        } else if (
            randomNumber >=
            _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3] + _dataCyborg[4] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5]
        ) {
            return Card(CYBORG6, "HexCartel Type Cyborg #6");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6]
        ) {
            return Card(CYBORG7, "HexCartel Type Cyborg #7");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7]
        ) {
            return Card(CYBORG8, "HexCartel Type Cyborg #8");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8]
        ) {
            return Card(CYBORG9, "HexCartel Type Cyborg #9");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9]
        ) {
            return Card(CYBORG10, "HexCartel Type Cyborg #10");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10]
        ) {
            return Card(CYBORG11, "HexCartel Type Cyborg #11");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] +
                _dataCyborg[11]
        ) {
            return Card(CYBORG12, "HexCartel Type Cyborg #12");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] +
                _dataCyborg[11] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] +
                _dataCyborg[11] +
                _dataCyborg[12]
        ) {
            return Card(CYBORG13, "HexCartel Type Cyborg #13");
        } else {
            return Card(CYBORG1, "HexCartel Type Cyborg #1");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}