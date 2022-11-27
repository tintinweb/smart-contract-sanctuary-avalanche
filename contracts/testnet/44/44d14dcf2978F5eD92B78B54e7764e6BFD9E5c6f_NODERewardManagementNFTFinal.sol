// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../interfaces/IMasterOfCoinV3.sol";
import "../interfaces/IMasterOfCoin.sol";
import "../interfaces/INodeRewardMangement.sol";
import "../interfaces/INodeRewardMangementV2.sol";
import "../interfaces/IThorOracle.sol";
import "../interfaces/IERC721Receiver.sol";
import "../libraries/Strings.sol";
import "../interfaces/IERC721Enumerable.sol";
import "../interfaces/IERC721Metadata.sol";
import "./Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


import {Base64} from "../libraries/Base64.sol";


abstract contract ERC721 is IERC721Enumerable, IERC721Metadata, Context {
    string _name;
    string _symbol;
    address _owner;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}


contract NODERewardManagementNFTFinal is
    IMasterOfCoinV3,
    ERC721
{
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 dueDate;
        string image;
        uint256 tempBooster; // in basis points
        uint256 fixedBooster; // in basis points
        uint256 tempBoosterDaysCounter;
        uint256 tokenId;
    }

    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    NodeEntity[] public _nodeList;
    mapping(uint256 => uint256) private _tokenIdToNodeListIndex;    // tokenIds -> nodeListIndex + 1 mapping

    // mapping(address => uint256[]) public _nodesOfUser;
    mapping(address => mapping(uint256 => uint256)) public _tokensOfUser;
    mapping(uint256 => uint256) private _tokensOfUserIndex;
    // mapping(address => mapping(uint256 => uint256)) private _userTokenIdToNodeIndex;

    mapping(address => uint256) public _compoundTime;


    address public collector = 0x8e2ff009Df7D3611efAF1AAE63A05020669fdCF8;

    mapping(address => bool) public sentry;

    mapping(uint256 => address) private _owners;
    // mapping(address => bool) public nodeOwners;
    // address[] public allNodeOwners;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    uint256 public claimTime;
    uint256 public cashOutFee;
    uint256 public feeCycle = 30 days;
    uint256 public FEE = 15;
    uint256 rewards;

    // uint256 public totalNodesCreated = 0;       // includes burnt tokens

    string public tierName;

    string public placeholderImage;

    IThorOracle private thorOracle;

    bool internal creating = false;

    uint256[] private cashoutFeeDue = new uint256[](4);
    uint256[] private cashoutFeeTax = new uint256[](4);

    event CreateNode(
        address owner,
        string name,
        uint256 creationTime,
        uint256 lastClaimTime
    );

    event Cashout(address owner, uint256 index);

    event CashoutAll(address owner);

    event Minted(uint256 tokenId);

    event Burned(uint256 tokenId);

    constructor(
        uint256 _nodePrice,
        uint256 _rewardPerDay,
        string memory _tierName,
        uint256 _cashOutFee,
        address _oracle,
        uint256 _rewards,
        string memory symbol_,
        string memory imgUrl
    ) ERC721(_tierName, symbol_) {
        require(_oracle != address(0), "zero address");
        thorOracle = IThorOracle(
            _oracle //0xd29fBEC3F29658E4fa1bD29886F0B1a92Cdb94B9
        );
        rewards = _rewards;
        placeholderImage = imgUrl;
        nodePrice = _nodePrice;
        rewardPerNode = _rewardPerDay.div(86400);
        claimTime = 1;
        tierName = _tierName;
        cashOutFee = _cashOutFee;
        sentry[msg.sender] = true;
        _owner = msg.sender;

        changeCashOutInfo(50, 40, 30, 20, 604800, 1209600, 1814400, 2332800);
    }

    modifier onlySentry() {
        require(sentry[msg.sender], "Fuck off");
        _;
    }

    modifier createLock() {
        require(!creating, "Creating Lock");
        creating = true;
        _;
        creating = false;
    }

    modifier indexAvailable(uint256 index) {
        require(index >= 0 || index < _nodeList.length, "NODE: Index Error");
        _;
    }

    modifier validToken(uint256 tokenId) {
        require(_tokenIdToNodeListIndex[tokenId] > 0, "NODE: tokenId Error");
        _;
    }

    // onchain tokenURI generated from NodeEntity
    function tokenURI(uint256 tokenId) public view virtual override  validToken(tokenId) returns (string memory) {
        uint256 nodeIndex = _tokenIdToNodeListIndex[tokenId] - 1;
        if (nodeIndex >= 0 || nodeIndex < _nodeList.length) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"',
                                    _nodeList[nodeIndex].name,
                                    '","description":"',
                                    "NFT Node for tier => ",
                                    tierName,
                                    '","image":"',
                                    bytes(_nodeList[nodeIndex].image).length > 0
                                        ? _nodeList[nodeIndex].image
                                        : placeholderImage,
                                    '"',
                                    ',"attributes":[',
                                    "{",
                                    '"trait_type":"Temp Booster",',
                                    '"value":',
                                    uint2str(_nodeList[nodeIndex].tempBooster),
                                    "}",
                                    ",",
                                    "{"
                                    '"trait_type":"Fixed Booster",',
                                    '"value":',
                                    uint2str(_nodeList[nodeIndex].fixedBooster),
                                    "}",
                                    "]",
                                    "}"
                                )
                            )
                        )
                    )
                );
        }
        return "";
    }

    //private
    function _createNodeForAddress(
        address _owner,
        string memory name_,
        uint256 creationTime,
        uint256 lastClaimTime,
        string memory _image
    ) private createLock returns (uint256) {
        emit CreateNode(_owner, name_, creationTime, lastClaimTime);
        uint nodeListIdx = _nodeList.length;

        _tokenIds.increment();
        uint tokenIdCurrent = _tokenIds.current();
        // _userTokenIdToNodeIndex[_owner][tokenIdCurrent] = nodeListIdx + 1;

        _nodeList.push(
            NodeEntity({
                name: name_,
                creationTime: creationTime,
                lastClaimTime: lastClaimTime,
                dueDate: creationTime + feeCycle,
                image: _image,
                tempBooster: 0,
                fixedBooster: 0,
                tempBoosterDaysCounter: 0,
                tokenId: tokenIdCurrent
            })
        );

        _tokenIdToNodeListIndex[tokenIdCurrent] = nodeListIdx + 1;
        _safeMint(_owner, tokenIdCurrent, "");
        _setOwner(tokenIdCurrent, _owner);
        emit Minted(tokenIdCurrent);
        return nodeListIdx;
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        _addTokenToOwnerEnumeration(to, tokenId);
        emit Transfer(address(0), to, tokenId);
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

    function _burn(uint256 tokenId) internal virtual {
        address _owner = ownerOf(tokenId);

        // require(_nodesOfUser[_owner].length > 0, "no nodes to burn");
        require(balanceOf(_owner) > 0, "no nodes to burn");

        // Clear approvals
        _approve(address(0), tokenId);

        _removeTokenFromOwnerEnumeration(_owner, tokenId);
        _removeTokenFromNodeList(tokenId);

        delete _owners[tokenId];
        _balances[_owner]--;

        emit Transfer(_owner, address(0), tokenId);
    }

    function _addTokenToOwnerEnumeration(address _owner, uint256 tokenId) private {
        uint256 pos = balanceOf(_owner);
        _tokensOfUser[_owner][pos] = tokenId;
        _tokensOfUserIndex[tokenId] = pos;
        _balances[_owner]++;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _tokensOfUserIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _tokensOfUser[from][lastTokenIndex];

            _tokensOfUser[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _tokensOfUserIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _tokensOfUserIndex[tokenId];
        delete _tokensOfUser[from][lastTokenIndex];
    }

    function _removeTokenFromNodeList(uint256 tokenId) private {
        uint256 nodeListIndex = _tokenIdToNodeListIndex[tokenId] - 1;

        // update tokenId -> nodeListIndex mapping for the node to swap with
        uint256 lastTokenId = _nodeList[_nodeList.length - 1].tokenId;
        _tokenIdToNodeListIndex[lastTokenId] = nodeListIndex + 1;

        _nodeList[_nodeList.length - 1] = _nodeList[nodeListIndex];
        _nodeList.pop();

        delete _tokenIdToNodeListIndex[tokenId];
    }


    function _calculateReward(
        uint256 tokenId
    ) private view returns (uint256) {
        uint nodeIndex = _tokenIdToNodeListIndex[tokenId] - 1;
        address nodeOwner = ownerOf(tokenId);

        uint256 currentTime = block.timestamp;
        NodeEntity memory node = _nodeList[nodeIndex];

        if (currentTime == 0 || _isDelinquent(nodeIndex)) return 0;

        uint256 lastClaim = node.lastClaimTime;
        // _getLastClaimTime(
        //     node.owner,
        //     node.lastClaimTime,
        //     node.creationTime
        // );
        if (_compoundTime[nodeOwner] > lastClaim) {
            lastClaim = _compoundTime[nodeOwner];
        }
        uint256 claims = (currentTime.sub(lastClaim)).div(claimTime);
        uint256 totalRewards = rewardPerNode.mul(claims);
        uint256 tempBoostedRewards = 0;
        uint256 fixedBoostedRewards = 0;

        if (
            _nodeList[nodeIndex].tempBooster > 0 &&
            _nodeList[nodeIndex].tempBoosterDaysCounter > 0
        ) {
            tempBoostedRewards =
                totalRewards *
                ((1000 + _nodeList[nodeIndex].tempBooster) / 1000);
        }
        if (_nodeList[nodeIndex].fixedBooster > 0) {
            fixedBoostedRewards =
                totalRewards *
                ((1000 + _nodeList[nodeIndex].fixedBooster) / 1000);
        }
        return totalRewards + tempBoostedRewards + fixedBoostedRewards;
    }

    function _isNameAvailable(
        address account,
        string memory nodeName
    ) private view returns (bool) {
        // uint256[] memory tokensOfUser = _tokensOfUser[account];
        for (uint256 i = 0; i < balanceOf(account); i++) {
            // uint nodeListIdx = _userTokenIdToNodeIndex[account][_tokensOfUser[][i]] - 1;
            uint tokenId = _tokensOfUser[account][i];
            uint nodeListIndex = _tokenIdToNodeListIndex[tokenId] - 1;
            if (
                keccak256(bytes(_nodeList[nodeListIndex].name)) ==
                keccak256(bytes(nodeName))
            ) {
                return false;
            }
        }
        return true;
    }

    function _setOwner(uint tokenId, address _owner) private {
        _owners[tokenId] = _owner;
    }

    function _getNodeId(
        string memory _name,
        uint256 creationTime,
        string memory _tierName,
        address _owner
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _name,
                    uint2str(creationTime),
                    _tierName,
                    toAsciiString(_owner)
                )
            );
    }


    function _tokenToNodeId(
        uint256 tokenId
    ) private view returns (string memory) {
        NodeEntity memory node = _nodeList[_tokenIdToNodeListIndex[tokenId]-1];
        return _getNodeId(node.name, node.creationTime, tierName, ownerOf(tokenId));
    }

    function _cashOutReward(uint256 tokenId) private returns (uint256) {
        uint256 nodeReward = _calculateReward(tokenId);
        uint nodeIndex = _tokenIdToNodeListIndex[tokenId] - 1;
        // always update last claim time
        _nodeList[nodeIndex].lastClaimTime = block.timestamp;
        if (_nodeList[nodeIndex].tempBoosterDaysCounter > 0) {
            _nodeList[nodeIndex].tempBoosterDaysCounter--;
        }
        return nodeReward;
    }

    // public & external
    // this is our mint function
    function createNodeForAddress(
        address _owner,
        string memory _name,
        uint256 creationTime,
        uint256 lastClaimTime,
        string memory _image
    ) external onlySentry returns (uint256) {
        require(_isNameAvailable(_owner, _name), "CN:Name not available");
        return
            _createNodeForAddress(
                _owner,
                _name,
                creationTime,
                lastClaimTime,
                _image
            );
    }

    function boostNode(
        uint256 nodeIndex,
        uint256 tempBooster,
        uint256 tempBoosterDays,
        uint256 fixedBoosterBasis
    ) external indexAvailable(nodeIndex) onlySentry {
        _nodeList[nodeIndex].tempBooster = tempBooster;
        _nodeList[nodeIndex].tempBoosterDaysCounter = tempBoosterDays;
        _nodeList[nodeIndex].fixedBooster = fixedBoosterBasis;
    }

    function burn(uint256 tokenId) external validToken(tokenId) {
        require(
            _msgSender() == ownerOf(tokenId),
            "not authorized to burn this node"
        );
        _burn(tokenId);
        emit Burned(tokenId);
    }

    function getRewardAmountOf(
        uint256 tokenId
    ) external view validToken(tokenId) returns (uint256) {
        return _calculateReward(tokenId);
    }

    function getRewardAmountOf(
        address account
    ) external view returns (uint256) {
        return _getRewardAmountOf(account);
    }

    function _getRewardAmountOf(
        address account
    ) internal view returns (uint256 totalReward) {
        // uint256[] memory nodesIndex = _nodesOfUser[account];
        // uint256[] memory tokensOfUser = _tokensOfUser[account];
        for (uint256 i = 0; i < balanceOf(account); i++) {
            // uint nodeListIdx = _userTokenIdToNodeIndex[account][tokensOfUser[i]] - 1;
            // uint tokenId = _tokensOfUser[i];
            totalReward += _calculateReward(_tokensOfUser[account][i]);
        }
        return totalReward;
    }

    function cashOutReward(
        address account,
        uint256 tokenId
    ) external onlySentry validToken(tokenId) returns (uint256) {
        require(account == ownerOf(tokenId), "Not node owner");
        emit Cashout(account, tokenId);
        return _cashOutReward(tokenId);
    }

    // function _getLastClaimTime(
    //     address owner,
    //     uint256 _claimTime,
    //     uint256 createTime
    // ) internal view returns (uint256) {
    //     uint256 __claimTime = _claimTime;
    //     if (createTime > claimTime) {
    //         __claimTime = createTime;
    //     }

    //     return
    //         lastCashoutAllTime[owner] > __claimTime
    //             ? lastCashoutAllTime[owner]
    //             : __claimTime;
    // }

    // we were already iterating through all nodes in reward calculation
    // lastCashoutAllTime doesn't help much, also we need to decrement tempboost counter
    // for each node
    function cashOutAllReward(
        address _owner
    ) external onlySentry returns (uint256) {
        uint256 totalReward = 0;
        // uint256[] memory nodesIndex = _nodesOfUser[_owner];
        // uint256[] memory tokensOfUser = _tokensOfUser[_owner];
        for (uint256 i = 0; i < balanceOf(_owner); i++) {
            // uint nodeListIdx = _userTokenIdToNodeIndex[_owner][tokensOfUser[i]] - 1;
            totalReward += _cashOutReward(_tokensOfUser[_owner][i]);
        }
        // lastCashoutAllTime[_owner] = block.timestamp;
        emit CashoutAll(_owner);
        return totalReward;
    }

    function getNodeId(
        uint256 tokenId
    ) public view validToken(tokenId) returns (string memory) {
        return _tokenToNodeId(tokenId);
    }

    // function _getNodeNumberOf(address _owner) external view returns (uint256) {
    //     return _tokensOfUser[_owner].length;
    // }

    function updateCompoundTime(address account) external onlySentry {
        _compoundTime[account] = block.timestamp;
    }

    function renameNode(
        address account,
        string memory _name,
        uint256 tokenId
    ) external onlySentry validToken(tokenId) {
        uint nodeIndex = _tokenIdToNodeListIndex[tokenId] - 1;
        require(account == ownerOf(tokenId), "Not node owner");
        require(_isNameAvailable(account, _name), "CN:Name not available");
        _nodeList[nodeIndex].name = _name;
    }

    function _isNodeOwner(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(
                uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i))))
            );
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _changeNodePrice(uint256 newNodePrice) external onlySentry {
        nodePrice = newNodePrice;
    }

    function _changeRewardPerNode(uint256 newPrice) external onlySentry {
        rewardPerNode = newPrice;
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function _changeNodeCashOutFee(
        uint256 newNodeCashOutFee
    ) external onlySentry {
        cashOutFee = newNodeCashOutFee;
    }

    function setSentry(address a, bool isPermitted) external onlySentry {
        sentry[a] = isPermitted;
    }

    function setMultiSentry(
        address[] memory addresses,
        bool isPermitted
    ) external onlySentry {
        for (uint256 i = 0; i < addresses.length; i++) {
            sentry[addresses[i]] = isPermitted;
        }
    }

    function setCollector(address newCollector) external onlySentry {
        collector = newCollector;
    }

    function updateFee(uint256 newFee) external onlySentry {
        FEE = newFee;
    }

    function setPlaceHolderImage(string memory newImg) external onlySentry {
        placeholderImage = newImg;
    }

    function fixNodes(uint256[] memory nodeIndexes) external onlySentry {
        for (uint256 i = 0; i < nodeIndexes.length; i++) {
            _nodeList[nodeIndexes[i]].dueDate = block.timestamp + feeCycle;
        }
    }

    function withdrawFees() external onlySentry {
        payable(collector).transfer(address(this).balance);
    }

    function changeCashOutInfo(
        uint256 tax1,
        uint256 tax2,
        uint256 tax3,
        uint256 tax4,
        uint256 dueTime1,
        uint256 dueTime2,
        uint256 dueTime3,
        uint256 dueTime4
    ) public onlySentry {
        cashoutFeeTax[0] = tax1;
        cashoutFeeTax[1] = tax2;
        cashoutFeeTax[2] = tax3;
        cashoutFeeTax[3] = tax4;
        cashoutFeeDue[0] = dueTime1;
        cashoutFeeDue[1] = dueTime2;
        cashoutFeeDue[2] = dueTime3;
        cashoutFeeDue[3] = dueTime4;
    }


    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    function balanceOf(
        address _owner
    ) public view virtual override returns (uint256 balance) {
        balance = _balances[_owner];
    }

    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address _owner) {
        _owner = _owners[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        this.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override validToken(tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "NRMV3: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "NRMV3: transfer to non ERC721Receiver implementer"
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override validToken(tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "NRMV3: caller is not token owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "NRMV3: transfer from incorrect owner"
        );
        require(to != address(0), "NRMV3: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);
        _balances[from]--;
        _addTokenToOwnerEnumeration(to, tokenId);
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function approve(
        address to,
        uint256 tokenId
    ) external override validToken(tokenId) {
        address _owner = ownerOf(tokenId);
        require(to != ownerOf(tokenId), "NRMV3: approval to current owner");
        require(
            _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),
            "NRMV3: approve caller is not token owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool _approved
    ) external override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "NRMV3: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function getApproved(
        uint256 tokenId
    ) public view virtual override validToken(tokenId) returns (address operator) {
        operator = _tokenApprovals[tokenId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function name() public view virtual override returns (string memory) {
        return tierName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address _owner = ownerOf(tokenId);
        return (spender == _owner ||
            isApprovedForAll(_owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("NRMV3: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _nodeList.length;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 index
    ) public view virtual override returns (uint256) {
        require(index >= 0 && index < balanceOf(_owner), 'index out of bound');
        return _tokensOfUser[_owner][index];
    }

    function tokenByIndex(
        uint256 index
    ) public view virtual override indexAvailable(index) returns (uint256) {
        return _nodeList[index].tokenId;
    }

    // function allNodesOfUser(address _owner) public view returns (uint[] memory)  {
    //     uint[] memory nodesOfUser = new uint[](balanceOf(_owner));
    //     for(uint i=0; i < balanceOf(_owner); i++) {
    //         nodesOfUser[i] = ;
    //     }
    //     return nodesOfUser;
    // }

    function _calcRestoreFee(
        uint256 nodeIndex
    ) internal view returns (uint256) {
        uint256 dueDate = _nodeList[nodeIndex].dueDate;
        uint256 missedFees = uint256(block.timestamp - dueDate)
            .div(feeCycle)
            .mul(_getFee());

        return _getFee() + missedFees;
    }

    function _getThorPrice(
        uint256 _amountIn
    ) internal view returns (uint256 price) {
        price = thorOracle.thor2Avax(_amountIn);
    }

    function isDelinquent(
        uint256 tokenId
    ) public view override validToken(tokenId) returns (bool) {
        return _isDelinquent(_tokenIdToNodeListIndex[tokenId]-1);
    }

    function _isDelinquent(uint256 nodeIndex) internal view returns (bool) {
        return block.timestamp > _nodeList[nodeIndex].dueDate;
    }

    function getFee(
        uint256 tokenId
    ) public view validToken(tokenId) returns (uint256) {
        uint nodeIndex = _tokenIdToNodeListIndex[tokenId]-1;
        if (_isDelinquent(nodeIndex)) {
            return _calcRestoreFee(nodeIndex);
        }
        return _getFee();
    }

    function _getFee() internal view returns (uint256) {
        return _getThorPrice(rewards).mul(FEE).div(100);
    }

    function _payFee(uint256 tokenId) internal validToken(tokenId) {
        uint nodeIndex = _tokenIdToNodeListIndex[tokenId] - 1;
        require(!_isDelinquent(nodeIndex), "Node has expired, pay restore fee");
        _nodeList[nodeIndex].dueDate = _nodeList[nodeIndex].dueDate.add(
            feeCycle
        );
        emit PaidFee(tokenId, _nodeList[nodeIndex].dueDate);
    }

    function payFee(uint256 tokenId) external payable override validToken(tokenId) {
        require(msg.value >= _getFee(), "Amount less than fee");
        payable(collector).transfer(msg.value);
        _payFee(tokenId);
    }

    function payFeeBifrost(uint256 tokenId) external onlySentry {
        _payFee(tokenId);
    }

    function payFees(uint256[] memory _tokensIds) external payable override {
        require(
            msg.value >= _tokensIds.length.mul(_getFee()),
            "Amount less than fee"
        );
        payable(collector).transfer(msg.value);
        for (uint256 i = 0; i < _tokensIds.length; i++) {
            _payFee(_tokensIds[i]);
        }
    }

    function restoreNode(
        uint256 tokenId
    ) external payable override validToken(tokenId) {
        uint nodeIndex = _tokenIdToNodeListIndex[tokenId] - 1;
        uint256 totalFee = _calcRestoreFee(nodeIndex);
        require(msg.value >= totalFee, "Amount less than fee");
        payable(collector).transfer(msg.value);
        _nodeList[nodeIndex].dueDate = block.timestamp + feeCycle;
        _cashOutReward(nodeIndex);
        emit Cashout(msg.sender, nodeIndex);
        emit RestoreNode(
            tokenId,
            _nodeList[nodeIndex].dueDate
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INodeRewardManagement {
    function _nodesOfUser(address, uint256)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256
        );

    function _getNodeNumberOf(address) external view returns (uint256);

    function _migrateNodes(
        address owner,
        string[] memory names,
        uint256[] memory creationTimes,
        uint256[] memory lastClaimTimes,
        uint256[] memory rewardsAvailable
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMasterOfCoin {
    function isDelinquent(string memory nodeId) external view returns (bool);

    function payFee(string memory nodeId) external;

    function payFees(string[] memory nodeIds, string memory tierName)
        external
        payable;

    function restoreNode(string memory nodeId, string memory tierName)
        external
        payable;

    function activeNodes(string[] memory nodeIds)
        external
        view
        returns (bool[] memory active);
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INodeRewardManagementV2 {

  struct NodeEntity {
      address owner;
      string name;
      uint256 creationTime;
      uint256 lastClaimTime;
      uint256 rewardAvailable;
  }

    function _nodesOfUser(address, uint256)
        external
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256
        );

    function _getNodeNumberOf(address) external view returns (uint256);

    function _getNodesIndex(address _owner)
    external
    view
    returns (uint256[] memory);

    function _nodeList(uint256) external returns(address owner, string memory name,
      uint256 creationTime, uint256 lastClaimTime, uint256 rewardAvailable);

    function _compoundTime(address) external returns(uint256);

    function lastCashoutAllTime(address) external returns(uint256);


    function _migrateNodes(
        address owner,
        string[] memory names,
        uint256[] memory creationTimes,
        uint256[] memory lastClaimTimes,
        uint256[] memory rewardsAvailable
    ) external;
}

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMasterOfCoinV3 {
    event PaidFee(uint256 tokenId, uint256 dueDate);
    event RestoreNode(uint256 tokenId, uint256 dueDate);

    function isDelinquent(uint256 nodeIndex) external view returns (bool);

    function payFee(uint256 nodeIndex) external payable;

    function payFeeBifrost(uint256 nodeIndex) external;

    function payFees(uint256[] memory nodeIndex)
        external
        payable;

    function restoreNode(uint256 nodeIndex)
        external
        payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IThorOracle  {

  function thor2Avax(uint256 _amountIn) external view returns (uint256);

  function avax2thor(uint256 _amountIn) external view returns (uint256);

  function thor2Usd(uint256 _amountIn) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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