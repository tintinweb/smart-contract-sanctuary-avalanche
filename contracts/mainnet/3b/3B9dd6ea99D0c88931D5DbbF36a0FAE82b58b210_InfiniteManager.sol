// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IAscendMembershipManager {
    function getNameOf(uint256 _id) external view returns (string memory);
    function getMintOf(uint256 _id) external view returns (uint64);
    function getMembershipsOf(address _account) external view returns (uint256[] memory);
    function presaleNFT() external view returns (IERC721 );
    function founderL1NFT() external view returns (IERC721 );
    function founderL2NFT() external view returns (IERC721 );
    function founderL3NFT() external view returns (IERC721 );
    function getUserMultiplier(address from) external view returns (uint256);
    function meta_membership() external view returns (IERC721 );
    function platinum_membership() external view returns (IERC721 );
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface InfiniteManagerV1 {
   function ownerOf(uint256 tokenId) external view returns (address);
   function transferFrom(address from, address to, uint256 tokenId) external;
   function balanceOf(address owner) external view returns (uint256 balance);
   function getInfinitesOf(address _account) external view returns (uint256[] memory);
   function getMintOf(uint256 _id) external view returns (uint64);
}

interface InfiniteHelperV1 {
   function seeNodeClaim(uint256 _id) external view returns (uint64);
}


interface RewardsCalculator {
  function calculateAllRewards(address from) external view returns (uint);
}
interface AmsHelper {
  function calculator() external view returns (RewardsCalculator);
  function claimRewardsForCompoundInfinite(address sender, uint256 nodePrice ) external returns (uint256);
}


contract InfiniteManager is Ownable, IERC721, IERC721Metadata {

    using Address for address;
    using SafeMath for uint256;
    struct Infinite {
        string name;
        string metadata;
        uint256 id;
        uint64 mint;
        uint64 claim;
    }

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => Infinite) private _nodes;
    mapping(address => uint256[]) private _bags;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) private _blacklist;

    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    string public defaultUri = "";
    uint256 public nodeAscendTokenPrice = 500;
    uint256 public nodeAscendMembershipPrice = 40;
    uint256 public nodePlatinumPrice = 1;

    uint256 private nodeCounter = 1;
    uint public maxInfiniteWallet = 1;

    bool public transferIsEnabled = true;

    IERC20 public ASCEND;
    IAscendMembershipManager public amsManager;
    AmsHelper public amsHelper;

    InfiniteManagerV1 public infiniteManagerV1;
    InfiniteHelperV1 public infiniteHelperV1;

    bool enableClaims = true;

      struct RewardsParameters {
          uint64 reward;
          uint64 claimTime;
          uint64 precision;
          uint64 cliffPeriods;
      }

      RewardsParameters public rewardsParameters = RewardsParameters({
         reward: 190000,
         claimTime: 86400,
         precision: 1000,
         cliffPeriods: 1
      });


      struct BoostersParameters {
          uint256 presaleBooster;
          uint256 founderL1Booster;
          uint256 founderL2Booster;
          uint256 founderL3Booster;
          uint256 metaBooster;
      }

      BoostersParameters public boostersParameters = BoostersParameters({
          presaleBooster: 28500, // 15%
          founderL1Booster: 19000, // 10%
          founderL2Booster: 28500, // 15%
          founderL3Booster: 38000, // 20%
          metaBooster: 0
      });

    event CreateInfinite(address from, uint id);
    event RemoveInfinite(address from, uint id);
    event ClaimInfinite(address account, uint rewardNode);
    event CreateInfiniteWithRewards(address sender, uint256 rewardAmount);

    constructor(address _ASCEND_TOKEN, address _ascendMembership, address _amsHelper )  {
        ASCEND = IERC20(_ASCEND_TOKEN);
        amsManager = IAscendMembershipManager(_ascendMembership);
        amsHelper = AmsHelper(_amsHelper);
    }

    modifier onlyIfExists(uint256 _id) {
        require(_exists(_id), "ERC721: operator query for nonexistent token");
        _;
    }

    function setInfiniteManagerV1(address _infiniteManagerV1 ) external onlyOwner {
        infiniteManagerV1 = InfiniteManagerV1(_infiniteManagerV1);
    }

    function setInfiniteHelperV1(address _infiniteHelperV1 ) external onlyOwner {
        infiniteHelperV1 = InfiniteHelperV1(_infiniteHelperV1);
    }

    function updateAmsHelper(address _amsHelper) onlyOwner external {
      amsHelper = AmsHelper(_amsHelper);
    }

    function setBoosters(uint256 _founderL1Booster, uint256 _founderL2Booster,
      uint256 _founderL3Booster, uint256 _presaleBooster,
        uint256 _metaBooster) onlyOwner external {
          boostersParameters.founderL1Booster = _founderL1Booster;
          boostersParameters.founderL2Booster = _founderL2Booster;
          boostersParameters.founderL3Booster = _founderL3Booster;
          boostersParameters.presaleBooster =  _presaleBooster;
          boostersParameters.metaBooster = _metaBooster;
    }

    function enableTransfer(bool _enable) external onlyOwner {
        transferIsEnabled = _enable;
    }

    function totalNodesCreated() view external returns (uint) {
        return nodeCounter - 1;
    }

    function isBlacklisted(address wallet) view external returns (bool) {
        return _blacklist[wallet];
    }

    function updateInfinite(uint256 id, string calldata metadata) external {
        require(ownerOf(id) == msg.sender, "MANAGER: You are not the owner");
        Infinite storage infinite = _nodes[id];
        infinite.metadata = metadata;
    }

    function _changeEnableClaims(bool _newVal) onlyOwner external {
        enableClaims = _newVal;
    }

    function changeRewardsParameters(uint64 newReward, uint64 newTime, uint64 newPrecision, uint64 newCliffPeriods) onlyOwner external {
        rewardsParameters.reward = newReward;
        rewardsParameters.claimTime = newTime;
        rewardsParameters.precision = newPrecision;
        rewardsParameters.cliffPeriods = newCliffPeriods;
    }

    function getInfinites(uint256 _id) public view onlyIfExists(_id) returns (Infinite memory) {
        return _nodes[_id];
    }

    function getNameOf(uint256 _id) public view onlyIfExists(_id) returns (string memory) {
        return _nodes[_id].name;
    }

    function getMintOf(uint256 _id) public view onlyIfExists(_id) returns (uint64) {
        return _nodes[_id].mint;
    }

    function getInfinitesOf(address _account) public view returns (uint256[] memory) {
        return _bags[_account];
    }

    function updatePlatinumMembershipPrice(uint256 _price) external onlyOwner {
        nodePlatinumPrice = _price;
    }

    function seeNodeClaim(uint256 _id) external view returns (uint64) {
        return _nodes[_id].claim;
    }

    function claimTime() external view returns (uint64) {
       return rewardsParameters.claimTime;
    }

    function precision() external view returns (uint64) {
       return rewardsParameters.precision;
    }

    function cliffPeriods() external view returns (uint64) {
       return rewardsParameters.cliffPeriods;
    }

    function setASCEND(address _ASCEND) onlyOwner external {
        ASCEND = IERC20(_ASCEND);
    }

    function setAMS(address _ams) onlyOwner external {
        amsManager = IAscendMembershipManager(_ams);
    }

    function updateNodeTokenPrice (uint256 _nodeAscendTokenPrice) external onlyOwner {
        nodeAscendTokenPrice = _nodeAscendTokenPrice;
    }

    function updateNodeAscendMembershipPrice (uint256 _nodeAscendMembershipPrice) external onlyOwner {
        nodeAscendMembershipPrice = _nodeAscendMembershipPrice;
    }

    function _setTokenUriFor(uint256 nodeId, string memory uri) onlyOwner external {
        _nodes[nodeId].metadata = uri;
    }

    function _setDefaultTokenUri(string memory uri) onlyOwner external {
        defaultUri = uri;
    }

    function _setBlacklist(address malicious, bool value) onlyOwner external {
        _blacklist[malicious] = value;
    }

    function _addInfinite(string calldata _name, uint64 _mint, uint64 _claim, string calldata _metadata, address _to) onlyOwner external {
        uint256 nodeId = nodeCounter;
        _createInfinite(nodeId, _name, _mint, _claim, _metadata, _to);
        nodeCounter += 1;
    }

    function setMaxInfiniteWallet (uint256 _max) external onlyOwner {
        maxInfiniteWallet = _max;
    }

    function setAscend(IERC20 _ASCEND) external onlyOwner {
        ASCEND = IERC20(_ASCEND);
    }

    function getUserBooster(address from) public view returns (uint256) {
        uint256 booster = 0;
        if(amsManager.presaleNFT().balanceOf(from) >= 1){
          booster += boostersParameters.presaleBooster;
        }
        if (amsManager.founderL3NFT().balanceOf(from) >= 1){
          booster += boostersParameters.founderL3Booster;
        } else if (amsManager.founderL2NFT().balanceOf(from) >= 1){
          booster += boostersParameters.founderL2Booster;
        } else if (amsManager.founderL1NFT().balanceOf(from) >= 1){
          booster += boostersParameters.founderL1Booster;
        }
        return booster;
    }

    function getUserAdditionalRewardsInfinite(address from) public view returns (uint256) {
      if(amsManager.meta_membership().balanceOf(from) >= 1){
        return boostersParameters.metaBooster;
      }
      return 0;
    }


    function getAddressRewards(address account) external view returns (uint) {
        uint256 rewardAmount = 0;
        uint256[] memory userMemberships = getInfinitesOf(account);
        uint interval = 0;
        for (uint256 i = 0; i < userMemberships.length; i++) {
            Infinite memory _node = _nodes[userMemberships[i]];
            interval = (block.timestamp - _nodes[_node.id].claim) / rewardsParameters.claimTime;
            if (interval >= rewardsParameters.cliffPeriods){
              rewardAmount +=  (interval * getReward(account) * 10 ** 18) / rewardsParameters.precision;
            }
        }
        return rewardAmount;
    }

    function getReward(address from) public view returns(uint256) {
        uint rewardNode = rewardsParameters.reward + getUserAdditionalRewardsInfinite(from) + getUserBooster(from);
        return rewardNode;
    }

    function claim(address account, uint256 _id) external onlyIfExists(_id) returns (uint) {
      require(enableClaims, "Claims are disabled");
      require(ownerOf(_id) == account, "You are not the owner");
      Infinite memory _node = _nodes[_id];
      uint64 interval = (uint64(block.timestamp) - _node.claim) / rewardsParameters.claimTime;
      if (interval < rewardsParameters.cliffPeriods){
          return 0;
      }
      //require(interval >= rewardsParameters.cliffPeriods, "Not enough time has passed between claims");
      uint rewardNode = (interval * getReward(account) * 10 ** 18) / rewardsParameters.precision;
      require(rewardNode >= 1, "MANAGER: You don't have enough reward");
      _node.claim = _node.claim + (interval*rewardsParameters.claimTime);   // uint64(block.timestamp);
      _nodes[_id] = _node;
      emit ClaimInfinite(account, rewardNode);
      return rewardNode;
    }


    function _createInfinite(uint256 _id, string memory _name, uint64 _mint, uint64 _claim, string memory _metadata, address _to) internal {
        require(!_exists(_id), "MANAGER: Infinite already exist");
        _nodes[_id] = Infinite({
            name: _name,
            mint: _mint,
            claim: _claim,
            id: _id,
            metadata: _metadata
        });
        _owners[_id] = _to;
        _balances[_to] += 1;
        _bags[_to].push(_id);
        emit CreateInfinite(_to, _id);
    }

    function _remove(uint256 _id, address _account) internal {
        uint256[] storage _ownerNodes = _bags[_account];
        uint length = _ownerNodes.length;
        uint _index = length;
        for (uint256 i = 0; i < length; i++) {
            if(_ownerNodes[i] == _id) {
                _index = i;
            }
        }
        if (_index >= _ownerNodes.length) return;
        _ownerNodes[_index] = _ownerNodes[length - 1];
        _ownerNodes.pop();
        emit RemoveInfinite(_account, _id);
    }

    function name() external override pure returns (string memory) {
        return "Infinite Membership";
    }

    function symbol() external override pure returns (string memory) {
        return "INFINITE";
    }

    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        Infinite memory _node = _nodes[uint64(tokenId)];
        if(bytes(_node.metadata).length == 0) {
            return defaultUri;
        } else {
            return _node.metadata;
        }
    }

    function balanceOf(address owner) public override view returns (uint256 balance){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view onlyIfExists(uint64(tokenId)) returns (address owner) {
        address theOwner = _owners[uint64(tokenId)];
        return theOwner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId ) external override {
        if (transferIsEnabled == true){
            safeTransferFrom(from, to, tokenId, "");
        }  else {
            require (to == address(0) || to == address(deadAddress), "Infinite Transfers are not allowed");
            safeTransferFrom(from, to, tokenId, "");
        }
    }

    function createNode(address account, string memory nodeName) internal {
        require(keccak256(bytes(nodeName)) != keccak256(bytes("V1 NODE")), "MANAGER: V1 NODE is reserved name");
        uint256 nodeId = nodeCounter;
        _createInfinite(nodeId, nodeName, uint64(block.timestamp), uint64(block.timestamp), "", account);
        nodeCounter += 1;
    }

    function migrateNodes(uint64[] memory userNodes) public {
      address sender = _msgSender();
      require(userNodes.length + balanceOf(sender) <= maxInfiniteWallet, "HELPER: Exceeds max Infinite per wallet");
      uint64[] memory _claims = new uint64[](userNodes.length);
      for (uint256 i = 0; i < userNodes.length; i++) {
           require(sender ==  infiniteManagerV1.ownerOf(userNodes[i]), "You are not the owner of the Node" );
           uint64 nodeclaim = infiniteHelperV1.seeNodeClaim(userNodes[i]);
           if  (nodeclaim == 0){
             nodeclaim = infiniteManagerV1.getMintOf(userNodes[i]);
           }
           _claims[i] = nodeclaim;
           infiniteManagerV1.transferFrom(_msgSender(), address(deadAddress), userNodes[i] );
      }
      migrateInfinites(_claims, sender);
    }

    function migrateInfinites( uint64[] memory _claims, address _to) internal {
        for (uint256 i = 0; i < _claims.length; i++) {
            uint256 nodeId = nodeCounter;
            _createInfinite(nodeId, "Infinite", _claims[i],  _claims[i], "", _to);
            nodeCounter += 1;
        }
    }


    function createMultipleNodeWithRewards(string memory _name, uint64[] memory ascendNodes, uint64[] memory userPlatinumNodes) public {
        require(bytes(_name).length > 0 && bytes(_name).length < 33, "HELPER: name size is invalid");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        uint256 nodePrice = nodeAscendTokenPrice * 10 ** 18;
        require(nodePrice > 0, "HELPER error: nodeAscendTokenPrice");
        uint256 allRewards = amsHelper.calculator().calculateAllRewards(sender) * 10 ** 18;
        require(ASCEND.balanceOf(sender) + allRewards  >= nodePrice, "HELPER: Ascend Tokens balance too low for creation.");
        require(balanceOf(sender) + 1 <= maxInfiniteWallet, "HELPER: Exceeds max wallet amount");
        require(amsManager.balanceOf(sender) >= nodeAscendMembershipPrice, "HELPER: Ascend Membership balance too low for creation.");
        require(amsManager.platinum_membership().balanceOf(sender) >= nodePlatinumPrice, "HELPER: Platinum Membership balance too low for creation.");
        require(ascendNodes.length == nodeAscendMembershipPrice, "HELPER: AMS Nodes (Invalid amount)");
        require(userPlatinumNodes.length == nodePlatinumPrice, "HELPER: Platinum Membership Nodes (Invalid amount)");


        uint256 rewardAmount = amsHelper.claimRewardsForCompoundInfinite( sender, nodePrice );

        for (uint256 i = 0; i < nodeAscendMembershipPrice; i++) {
            amsManager.transferFrom(_msgSender(), address(deadAddress), ascendNodes[i]);
        }
        for (uint256 i = 0; i < nodePlatinumPrice; i++) {
            amsManager.platinum_membership().transferFrom(_msgSender(), address(deadAddress), userPlatinumNodes[i]);
        }
        if (nodePrice > rewardAmount  ){
            uint256 difference = nodePrice - rewardAmount;
            ASCEND.transferFrom(sender, address(amsHelper), difference);
        }
        emit CreateInfiniteWithRewards( sender,  rewardAmount);
        createNode(sender, _name);
    }


    function createNodeWithTokens(string memory _name, uint64[] memory ascendNodes, uint64[] memory userPlatinumNodes) public {
        require(bytes(_name).length > 0 && bytes(_name).length < 33, "HELPER: name size is invalid");
        address sender = _msgSender();
        require(sender != address(0), "HELPER:  Creation from the zero address");
        uint256 nodePrice = nodeAscendTokenPrice * 10 ** 18;
        require(nodePrice > 0, "HELPER error: nodeAscendTokenPrice");
        require(ASCEND.balanceOf(sender) >= nodePrice, "HELPER: Ascend Tokens balance too low for creation.");
        require(balanceOf(sender) + 1 <= maxInfiniteWallet, "HELPER: Exceeds max wallet amount");

        require(amsManager.balanceOf(sender) >= nodeAscendMembershipPrice, "HELPER: Ascend Membership balance too low for creation.");
        require(amsManager.platinum_membership().balanceOf(sender) >= nodePlatinumPrice, "HELPER: Platinum Membership balance too low for creation.");
        require(ascendNodes.length == nodeAscendMembershipPrice, "HELPER: AMS Nodes (Invalid amount)");
        require(userPlatinumNodes.length == nodePlatinumPrice, "HELPER: Platinum Membership Nodes (Invalid amount)");

        for (uint256 i = 0; i < nodeAscendMembershipPrice; i++) {
            amsManager.transferFrom(_msgSender(), address(deadAddress), ascendNodes[i]);
        }
        for (uint256 i = 0; i < nodePlatinumPrice; i++) {
            amsManager.platinum_membership().transferFrom(_msgSender(), address(deadAddress), userPlatinumNodes[i]);
        }
        ASCEND.transferFrom(_msgSender(), address(amsHelper),  nodePrice);
        createNode(sender, _name);
    }

    function renameInfinite(uint64 id, string memory newName) external {
        require(keccak256(bytes(newName)) != keccak256(bytes("V1 NODE")), "MANAGER: V1 NODE is reserved name");
        require(ownerOf(id) == msg.sender, "MANAGER: You are not the owner");
        Infinite storage infinite = _nodes[id];
        infinite.name = newName;
    }

    function transferFrom(address from, address to,uint256 tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        if (transferIsEnabled == true){
            _transfer(from, to, tokenId);
        } else {
            require (to == address(0) || to == deadAddress, "Infinite Transfers are not allowed");
            _transfer(from, to, tokenId);
        }
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function approveAll(address to, uint64[] memory userNodes) external {
        uint256 total = userNodes.length;
        for (uint64  i = 0; i < total; i++) {
            address owner = ownerOf(userNodes[i]);
            require(to != owner, "ERC721: approval to current owner");
            require(
                _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
                "ERC721: approve caller is not owner nor approved for all"
            );
            _approve(to, userNodes[i]);
        }
    }

    function getApproved(uint256 tokenId) public override view onlyIfExists(uint64(tokenId)) returns (address operator){
        return _tokenApprovals[uint64(tokenId)];
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        if (transferIsEnabled == true){
            _safeTransfer(from, to, tokenId, _data);
        } else {
            require (to == address(0) || to == address(deadAddress), "Infinite Transfers are not allowed");
            _safeTransfer(from, to, tokenId, _data);
        }
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint64 _id = uint64(tokenId);
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(!_blacklist[to], "MANAGER: You can't transfer to blacklisted user");
        require(!_blacklist[from], "MANAGER: You can't transfer as blacklisted user");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[_id] = to;
        _bags[to].push(_id);
        _remove(_id, from);
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[uint64(tokenId)] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view onlyIfExists(uint64(tokenId)) returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[uint64(tokenId)] != address(0);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
      require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
      if (transferIsEnabled == true){
        _transfer(from, to, tokenId);
      } else {
        require (to == address(0) || to == address(deadAddress), "Infinite Transfers are not allowed");
        _transfer(from, to, tokenId);
      }
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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