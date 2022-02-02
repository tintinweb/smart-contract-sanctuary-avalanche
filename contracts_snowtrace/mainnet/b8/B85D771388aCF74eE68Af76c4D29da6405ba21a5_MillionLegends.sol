/**
 *Submitted for verification at snowtrace.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;

interface IERC165 {
function supportsInterface(bytes4 interfaceId) external view returns (bool);}
pragma solidity ^0.8.11;
interface IERC721 is IERC165 {
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
function balanceOf(address owner) external view returns (uint256 balance);
function ownerOf(uint256 tokenId) external view returns (address owner);
function safeTransferFrom(address from, address to, uint256 tokenId) external;
function transferFrom(address from, address to, uint256 tokenId) external;
function approve(address to, uint256 tokenId) external;
function getApproved(uint256 tokenId) external view returns (address operator);
function setApprovalForAll(address operator, bool _approved) external;
function isApprovedForAll(address owner, address operator) external view returns (bool);
function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;}
pragma solidity ^0.8.11;
interface IERC721Receiver {
function onERC721Received(address from, uint256 tokenId, bytes calldata data) external returns (bytes4);}
pragma solidity ^0.8.11;
interface IERC721Metadata is IERC721 {function name() external view returns (string memory);
function symbol() external view returns (string memory);function tokenURI(uint256 tokenId) external view returns (string memory);}
pragma solidity ^0.8.11;
interface IERC721Enumerable is IERC721 {function totalSupply() external view returns (uint256);
function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
function tokenByIndex(uint256 index) external view returns (uint256);}
pragma solidity ^0.8.11;
library Address {
function isContract(address account) internal view returns (bool) { uint256 size; assembly { size := extcodesize(account) } return size > 0;}
function sendValue(address payable recipient, uint256 amount) internal { require(address(this).balance >= amount, "Address: insufficient balance"); (bool success, ) = recipient.call{ value: amount }(""); require(success, "Address: unable to send value, recipient may have reverted");}
function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {require(address(this).balance >= value, "Address: insufficient balance for call");require(isContract(target), "Address: call to non-contract");(bool success, bytes memory returndata) = target.call{ value: value }(data);return _verifyCallResult(success, returndata, errorMessage);}
function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {return functionStaticCall(target, data, "Address: low-level static call failed");}
function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory){require(isContract(target), "Address: static call to non-contract");(bool success, bytes memory returndata) = target.staticcall(data);return _verifyCallResult(success, returndata, errorMessage);}
function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {return functionDelegateCall(target, data, "Address: low-level delegate call failed");}
function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {require(isContract(target), "Address: delegate call to non-contract");(bool success, bytes memory returndata) = target.delegatecall(data);return _verifyCallResult(success, returndata, errorMessage);}
function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {if (success) {return returndata;} else {if (returndata.length > 0) {assembly {let returndata_size := mload(returndata)revert(add(32, returndata), returndata_size)}} else {revert(errorMessage);}}}}
pragma solidity ^0.8.11;
abstract contract Context {
function _msgSender() internal view virtual returns (address) {return msg.sender;}
function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}}
pragma solidity ^0.8.11;
library Strings {bytes16 private constant alphabet = "0123456789abcdef";
function toString(uint256 value) internal pure returns (string memory) {if (value == 0) {return "0";} uint256 temp = value;uint256 digits;while (temp != 0) {digits++;temp /= 10;}bytes memory buffer = new bytes(digits);while (value != 0) {digits -= 1;buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));value /= 10;}return string(buffer);}
function toHexString(uint256 value) internal pure returns (string memory) {if (value == 0) {return "0x00";}uint256 temp = value;uint256 length = 0;while (temp != 0) {length++;temp >>= 8;}return toHexString(value, length);}
function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {bytes memory buffer = new bytes(2 * length + 2);buffer[0] = "0";buffer[1] = "x";for (uint256 i = 2 * length + 1; i > 1; --i) {buffer[i] = alphabet[value & 0xf];value >>= 4;}require(value == 0, "Strings: hex length insufficient");return string(buffer);}}
pragma solidity ^0.8.11;
abstract contract ERC165 is IERC165 {
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {return interfaceId == type(IERC165).interfaceId;}}


/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
pragma solidity ^0.8.11;
contract MillionLegends is Context, ERC165, IERC721, IERC721Metadata {

    address THIS = address(this);
    Oracle ORACLE;
    ERC20 $MM = ERC20(0x993163CaD35162fB579D7B64e6695cB076EF5064);

    function init(address _oracle) public{
        require( address(ORACLE) == address(0) && msg.sender == pineapples);
        ORACLE = Oracle(_oracle);
    }
    
    uint genesis;

    address pineapples;
    address parker = 0xAeA13531Ab3726086A02fD9254ee3dC37c876442;

    constructor(){
        pineapples = msg.sender;
        genesis = block.timestamp;
        _name = "Million Legends";
        _symbol = "CARD";
        _mint(pineapples, 0);
        cards[0].creator = parker;
        cards[0].timeCreated = block.timestamp;
        cardCost = $/1000;
        string memory opening = "You awaken in a grassy field, unable to remember how you got here. You can hear a waterfall in a nearby forest, and you can see smoke rising from a town in the distance.";
        emit Text(0, parker, 0, '', opening);
        situation_text[0] = opening;
        action_text[0] = '';
    }

    bool flat;
    function flattenCost_1Time() public{
        require( !flat && msg.sender == pineapples);
        flat = true;
        cardCost = 0;
    }

    mapping(address => string) public sig;
    mapping(address => string) public link;

    function changeSig(string memory _sig) public{
        sig[msg.sender] = _sig;
    }

    function changeLink(string memory _link) public{
        link[msg.sender] = _link;
    }

    function changeBrand(string memory _sig, string memory _link) public{
        link[msg.sender] = _link;
        sig[msg.sender] = _sig;
    }

    mapping(address => uint) public creator_cardCount;
    mapping(address => mapping(uint => uint)) public creator_cards;
    struct Card{
        uint ID;
        uint timeCreated;
        uint textID;
        string URI;
        uint depth;
        uint parent;
        address creator;
        mapping(uint => uint) storyCards;
        uint storyCardCount;

        uint lead;
        uint rankPosition;
    }
    
    //Hopefully more event capturing can be done so that we wont have to rely on lazy u.i. functions
    function viewCards_ofCreator(address addr) public view returns(
        uint[] memory _cardIDs,
        uint[] memory timeCreated,
        uint[] memory textID,
        uint[] memory depth,
        uint[] memory parent,
        string[] memory URI
    ){
        uint L;

        L = creator_cardCount[addr];

        _cardIDs = new uint[](L);
        timeCreated = new uint[](L);
        textID = new uint[](L);
        depth = new uint[](L);
        parent = new uint[](L);
        URI = new string[](L);

        Card storage c = cards[0];
        for(uint i=0; i<L; i++){
            c = stackThese2(addr,i);
            _cardIDs[i] = c.ID;
            timeCreated[i] = c.timeCreated;
            textID[i] = c.textID;
            depth[i] = c.depth;
            parent[i] = c.parent;
            URI[i] = c.URI;
        }
    }

    function stackThese2(address c,uint i) internal view returns(Card storage){
        return cards[creator_cards[c][i]];
    }

    function stackThese(uint c,uint i) internal view returns(Card storage){
        return cards[cards[c].storyCards[i]];
    }

    function viewGame(uint cardID) public view returns(
        string memory situation,
        string memory URI,
        uint[] memory _cardIDs,
        string[] memory actions
    ){
        uint L = cards[cardID].storyCardCount;

        Card storage c = cards[0];
        c = cards[cardID];
        URI = c.URI;
        situation = situation_text[c.textID];
        _cardIDs = new uint[](L);
        actions = new string[](L);

        for(uint i=0; i<L; i++){
            c = stackThese(cardID,i);
            _cardIDs[i] = c.ID;
            actions[i] = action_text[c.textID];
        }
    }

    function viewCards_ofCard(uint cardID) public view returns(
        uint[] memory _cardIDs,        uint[] memory timeCreated,        uint[] memory textID,        uint[] memory depth,        uint[] memory parent,        string[] memory URI){
        uint L;

        L = cards[cardID].storyCardCount;

        _cardIDs = new uint[](L);
        timeCreated = new uint[](L);
        textID = new uint[](L);
        depth = new uint[](L);
        parent = new uint[](L);
        URI = new string[](L);

        Card storage c = cards[0];
        for(uint i=0; i<L; i++){
            c = stackThese(cardID,i);
            _cardIDs[i] = c.ID;
            timeCreated[i] = c.timeCreated;
            textID[i] = c.textID;
            depth[i] = c.depth;
            parent[i] = c.parent;
            URI[i] = c.URI;
        }
    }

    function viewCard(uint ID, bool choices) public view returns(
        uint timeCreated,
        uint textID,
        uint depth,
        uint parent,
        string memory action,
        string memory situation,
        string memory URI,
        string memory authorSig,
        address creator,
        uint[] memory cardIDs
    ){
        Card storage c = cards[ID];
        timeCreated = c.timeCreated;
        textID = c.textID;
        depth = c.depth;
        parent = c.parent;
        URI = c.URI;
        action = action_text[textID];
        situation = situation_text[textID];
        creator = c.creator;
        authorSig = sig[c.creator];
        cardIDs = new uint[](choices?c.storyCardCount:0);
        for(uint i;(choices?(i<c.storyCardCount):false);i++){
            cardIDs[i] = cards[c.storyCards[i]].ID;
        }
    }
    
    mapping(uint => Card) public cards;
    uint cardCount = 1;//because there is an initial card
    uint texts = 1;//because there is an initial card

    event Text(uint indexed textID, address indexed author , uint indexed previousCard, string action, string situation);
    event TextBundle(address indexed author, uint[] previousCards, string[] actions, string[] situations, uint indexed otID);
    uint constant $ = 1e18;
    mapping(uint =>  mapping(uint => uint)) previous;
    mapping(uint =>  mapping(uint => uint)) textPointer;
    mapping(uint => address) requestor;
    mapping(uint => uint8) requestType;
    mapping(uint => uint) public lockTime;
    mapping(uint => string) situation_text;
    mapping(uint => string) action_text;

    uint public cardCost;
    function newPath(uint[] memory cardIDs, string[] memory actions, string[] memory situations, uint msgValue) public returns(uint otID){
        
        uint[] memory UINTs = new uint[](4);
        UINTs[0] = actions.length; //page count
        (UINTs[1], UINTs[2]) = ORACLE.getFee();
        UINTs[3] = UINTs[1] + UINTs[2];// oracleFee
        
        require( $MM.transferFrom(msg.sender,THIS,msgValue) && msgValue >= UINTs[3]+cardCost*UINTs[0]);
        $MM.approve(address(ORACLE), msgValue);
        otID = ORACLE.fileRequestTicket(1, true, msgValue);

        G_UINT[otID] = UINTs[0];
        requestor[otID] = msg.sender;
        requestType[otID] = 0;//needs to be enforced just in case oracle is updated

        emit TextBundle(msg.sender, cardIDs, actions, situations, otID);
        uint cardID;
        string memory action;
        string memory situation;

        uint _lockTime = block.timestamp+ORACLE.oracleConfigurations(1)*3;

        //caps locktime at 12 hours
        _lockTime = _lockTime>(block.timestamp+43200)?(block.timestamp+43200):_lockTime;
        
        require(_lockTime>block.timestamp);//this is so that the oracle doesn't pass any overflow

        for(uint i; i<UINTs[0]; i++){
            cardID = cardIDs[i];
            action = actions[i];
            situation = situations[i];
            require( cardID < cardCount && block.timestamp > lockTime[cardID]);
            lockTime[cardID] = _lockTime;

            emit Text(texts, msg.sender, cardID, action, situation);

            previous[otID][i] = cardIDs[i];
            textPointer[otID][i] = texts;

            situation_text[texts] = situation;
            action_text[texts] = action;
            texts += 1;
        }

        return otID;
    }

    mapping(address => uint) public pocket;
    function withdraw() public returns(uint balance){
        address sender = msg.sender;
        balance = pocket[sender];
        pocket[sender] = 0;
        $MM.transfer(sender,balance);
        return balance;
    }

    mapping(uint => address) newOracle;
    event OracleUpdateRequest(address _newOracle, uint otID);
    function oracleUpdateRequest(address _newOracle, uint msgValue) public{
        require( $MM.transferFrom(msg.sender,THIS,msgValue) );
        $MM.approve(address(ORACLE),msgValue);
        uint otID = ORACLE.fileRequestTicket(1, true, msgValue);
        newOracle[otID] = _newOracle;
        requestType[otID] = 2;
        emit OracleUpdateRequest(_newOracle, otID);
    }

    event PriceUpdateRequest(uint newPrice, uint otID);
    function priceUpdateRequest(uint newPrice, uint msgValue) public{
        require( $MM.transferFrom(msg.sender,THIS,msgValue) );
        $MM.approve(address(ORACLE),msgValue);
        uint otID = ORACLE.fileRequestTicket(1, true, msgValue);
        G_UINT[otID] = newPrice;
        requestType[otID] = 3;
        emit PriceUpdateRequest(newPrice, otID);
    }

    mapping(uint => uint) G_UINT;
    mapping(uint => string) requestedURI;
    event URIRequest(uint cardID, string URI, uint otID);
    function uriRequest(uint cardID, string memory URI, uint msgValue) public{
        (uint fee1, uint fee2) = ORACLE.getFee();
        address owner = ownerOf(cardID);
        bool isOwner = msg.sender==owner;
        require( $MM.transferFrom(msg.sender,THIS,msgValue) );
        require( msgValue >= (fee1+fee2)*2 || isOwner );
        
        uint toOracle = msgValue-(isOwner?0:(fee1+fee2));
        $MM.approve(address(ORACLE), toOracle);
        uint otID = ORACLE.fileRequestTicket(1, true, toOracle );
        if( !isOwner ){
            pocket[owner] += fee1+fee2;
        }
        requestedURI[otID] = URI;
        G_UINT[otID] = cardID;
        requestType[otID] = 1;
        emit URIRequest(cardID, URI, otID);
    }

    function mintUniqueTokenTo(
        address _to,
        uint textID,
        uint parent
    ) internal {
        _mint(_to, cardCount);
        cards[cardCount].creator = _to;
        creator_cards[_to][creator_cardCount[_to]] = cardCount;
        creator_cardCount[_to] += 1;

        cards[cardCount].ID = cardCount;
        cards[cardCount].textID = textID;
        cards[cardCount].parent = parent;
        uint depth = cards[parent].depth + 1;
        cards[cardCount].depth = depth;
        cards[cardCount].timeCreated = block.timestamp;
    }
    
    event StoryResponse(bool accepted, address indexed author, uint indexed previousCardID, uint newCardID, uint textID);
    event URIRejected(uint indexed cardID, uint  ticketID);
    event URIAccepted(uint indexed cardID, uint  ticketID);
    event newOracleRejected(address _newOracle, uint indexed ticketID);
    event newOracleAccepted(address _newOracle, uint indexed ticketID);
    event newPriceRejected(uint price, uint indexed ticketID);
    event newPriceAccepted(uint price, uint indexed ticketID);

    function oracleIntFallback(uint ticketID, bool requestRejected, uint numberOfOptions, uint[] memory optionWeights, int[] memory intOptions) external{
        uint optWeight;
        uint[] memory U = new uint[](2);

        require( msg.sender == address(ORACLE) );

        if(!requestRejected){
            //YES OR NO?
            if(requestType[ticketID]!=0){
                for(uint i; i < numberOfOptions; i+=1){
                    optWeight = optionWeights[i];
                    if(intOptions[i]>0){
                        U[1] += optWeight;
                    }else{
                        U[0] += optWeight;
                    }
                }
            }

            if(requestType[ticketID]==0){
                address _requestor = requestor[ticketID];
            
                uint textID;
                uint pcID;
                Card storage previousCard;
                uint L = G_UINT[ticketID];
                uint j;
                for(uint i; i<L; i++){
                    U[1]=0;
                    U[0]=0;
                    pcID  = previous[ticketID][i];
                    for(j=0; j < numberOfOptions; j+=1){
                        optWeight = optionWeights[i];
                        if( (uint(intOptions[j])/2**i)%2 == 1 ){
                            U[1] += optWeight;
                        }else{
                            U[0] += optWeight;
                        }
                    }
                    if(U[1]>U[0]){       
                        textID = textPointer[ticketID][i];
                        previousCard = cards[pcID];

                        mintUniqueTokenTo(_requestor, textID, pcID);

                        emit StoryResponse(true, _requestor, pcID, cardCount, textID);
                        previousCard.storyCards[previousCard.storyCardCount] = cardCount;

                        cardCount += 1;
                        previousCard.storyCardCount += 1;
                    }else{
                        emit StoryResponse(false, _requestor, pcID, cardCount, textID);
                    }
                }
            }else if(requestType[ticketID]==1){
                uint cardID = G_UINT[ticketID];
                if(U[1]>U[0]){
                    cards[cardID].URI = requestedURI[ticketID];
                    emit URIAccepted(cardID,ticketID);
                }else{
                    emit URIRejected(cardID,ticketID);
                }
            }else if(requestType[ticketID]==2){
                address _newOracle = newOracle[ticketID];
                if(U[1]>U[0]){
                    ORACLE = Oracle(_newOracle);
                    emit newOracleAccepted(_newOracle,ticketID);
                }else{
                    emit newOracleRejected(_newOracle,ticketID);
                }
            }else if(requestType[ticketID]==3){
                if(U[1]>U[0]){
                    cardCost = G_UINT[ticketID];
                    emit newPriceAccepted(cardCost,ticketID);
                }else{
                    emit newPriceRejected(G_UINT[ticketID],ticketID);
                }
            }
        }
    }

    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/

    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/

    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/
    /*----------------------------------------------------*/

    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return cards[tokenId].URI;
    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    event Mint(address to, uint tokenID);
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0));
        require(!_exists(tokenId));
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Mint(to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);


        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            IERC721Receiver(to).onERC721Received(from, tokenId, _data);
        }
        return true;
    }
}

abstract contract Oracle{
    function fileRequestTicket(uint8 returnType, bool subjective, uint msgValue) external virtual returns(uint ticketID);
    function getFee() public virtual view returns(uint txCoverageFee, uint serviceFee);
    function oracleConfigurations(uint) public virtual view returns(uint);
}

abstract contract ERC20{
    function approve(address guy, uint amount) public virtual returns (bool);
    function transfer(address _to, uint _value) public virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) public virtual returns (bool);
}