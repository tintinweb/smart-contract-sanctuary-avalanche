// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './utils/Ownable.sol';
import './utils/HelperOwnable.sol';
import './utils/WeigthOwnable.sol';
import './interface/IERC721Metadata.sol';
import './interface/IERC721Receiver.sol';
import './interface/IManager.sol';
import './library/Address.sol';


contract Manager is Ownable, HelperOwnable, IERC721, IERC721Metadata, IManager {
    using Address for address;

    struct Solar {
        uint id;
        string name;

        uint64 mintTimestamp;
        uint64 claimTimestamp;
        uint8 tier;

        uint compoundedQuantity;

        // base 8 : bonus acquired when compounding
        uint64 bonusRewardPercent;
    }

    mapping(address => uint) public _balances;
    mapping(uint => address) public _owners;
    mapping(uint => Solar) public _nodes;
    mapping(address => uint[]) public _bags;

    // base 8
    mapping(uint8 => uint64) public _baseRewardPercentByTier;
    uint public precisionReward = 10**8;

    mapping(uint8 => uint64) public _bonusRewardPercentPerTimelapseByTier;
    mapping(uint8 => uint64) public _maxBonusRewardPercentPerTimelapseByTier;

    uint8 tierCount;

    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint public minimumNodePrice;

    uint64 public claimTimelapse = 86400;
    string public defaultUri;
    string public defaultUriExt;

    uint private nodeCounter = 1;

    constructor (uint _minimumNodePrice, string memory _defaultUri, string memory _defaultUriExt, uint64[] memory baseRewardPercentByTier,
    uint64[] memory bonusRewardPercentPerTimelapseByTier, uint64[] memory maxBonusRewardPercentPerTimelapseByTier){
        minimumNodePrice = _minimumNodePrice;
        defaultUri = _defaultUri;
        defaultUriExt = _defaultUriExt;
        
        for (uint8 i = 0; i < baseRewardPercentByTier.length; i++){
            _baseRewardPercentByTier[i + 1] = baseRewardPercentByTier[i];
        }
        for (uint8 i = 0; i < bonusRewardPercentPerTimelapseByTier.length; i++){
            _bonusRewardPercentPerTimelapseByTier[i + 1] = bonusRewardPercentPerTimelapseByTier[i];
        }
        for (uint8 i = 0; i < maxBonusRewardPercentPerTimelapseByTier.length; i++){
            _maxBonusRewardPercentPerTimelapseByTier[i + 1] = maxBonusRewardPercentPerTimelapseByTier[i];
        }
        require(baseRewardPercentByTier.length == bonusRewardPercentPerTimelapseByTier.length &&
        baseRewardPercentByTier.length == maxBonusRewardPercentPerTimelapseByTier.length, "Tier arrays length not matching");
        
        tierCount = uint8(baseRewardPercentByTier.length);
    }

    function name() external override pure returns (string memory) {
        return "STAR";
    }

    function symbol() external override pure returns (string memory) {
        return "STAR";
    }

    modifier onlyIfExists(uint _id) {
        require(_exists(_id), "ERC721: operator query for nonexistent token");
        _;
    }

    function createNode(address account, string memory nodeName, uint8 tier, uint paidAmount) onlyHelper override external {
        require(paidAmount >= minimumNodePrice, "MANAGER: paid amount is lower than minimum price");
        uint nodeId = nodeCounter;
        nodeCounter += 1;

        _createNode(nodeId, nodeName, uint64(block.timestamp), uint64(block.timestamp), tier, paidAmount, 0, account);
    }

    function getRewardsNode(Solar memory node) internal view returns (uint) {
        return (node.compoundedQuantity * (_baseRewardPercentByTier[node.tier] + node.bonusRewardPercent) * (block.timestamp - node.claimTimestamp))
         / precisionReward / claimTimelapse;
    }

    function claim(address account, uint id) external onlyIfExists(id) onlyHelper override returns (uint) {
        require(ownerOf(id) == account, "MANAGER: account not the owner");
        Solar storage node = _nodes[id];

        uint rewardNode = getRewardsNode(node);

        if(rewardNode > 0) {
            node.claimTimestamp = uint64(block.timestamp);
            return rewardNode;
        } else {
            return 0;
        }
    }

    function claimAndCompound(address account, uint id) external onlyIfExists(id) onlyHelper override {
        require(ownerOf(id) == account, "MANAGER: account not the owner");
        Solar storage node = _nodes[id];

        uint rewardNode = getRewardsNode(node);

        if(rewardNode > 0) {
            compoundNode(node, rewardNode);
        }
    }

    function compoundNode(Solar storage node, uint rewardNode) internal {

        if(node.bonusRewardPercent < _maxBonusRewardPercentPerTimelapseByTier[node.tier]){
            node.bonusRewardPercent = node.bonusRewardPercent + (uint64(block.timestamp) - node.claimTimestamp) * _bonusRewardPercentPerTimelapseByTier[node.tier] / claimTimelapse;
            if(node.bonusRewardPercent > _maxBonusRewardPercentPerTimelapseByTier[node.tier])
                node.bonusRewardPercent = _maxBonusRewardPercentPerTimelapseByTier[node.tier];
        }

        node.claimTimestamp = uint64(block.timestamp);
        node.compoundedQuantity = node.compoundedQuantity + rewardNode;
    }

    function stake(address account, uint id, uint amountToStake) external onlyIfExists(id) onlyHelper override {
        require(ownerOf(id) == account, "MANAGER: account not the owner");
        claimAndCompoundInternal(id);
        Solar storage node = _nodes[id];
        node.compoundedQuantity = node.compoundedQuantity + amountToStake;
    }

    function claimAll(address account) external onlyHelper override returns (uint) {
        uint rewards = 0;
        for (uint i = 0; i < _bags[account].length; i++) {
            rewards += claimInternal(_bags[account][i]);
        }
        return rewards;
    }

    function claimAndCompoundAll(address account) external onlyHelper override {
        for (uint i = 0; i < _bags[account].length; i++) {
            claimAndCompoundInternal(_bags[account][i]);
        }
    }

    // Internal functions used to compound or claim multiple node in one call
    function claimInternal(uint id) internal returns (uint) {
        Solar storage node = _nodes[id];

        uint rewardNode = getRewardsNode(node);

        node.claimTimestamp = uint64(block.timestamp);
        return rewardNode;
    }
    function claimAndCompoundInternal(uint id) internal {
        Solar storage node = _nodes[id];

        uint rewardNode = getRewardsNode(node);

        if(rewardNode > 0) {
            compoundNode(node, rewardNode);
        }
    }

    function adminCreateNode(address account, string memory nodeName, uint8 tier, uint paidAmount) onlyOwner external {
        uint nodeId = nodeCounter;
        nodeCounter += 1;
        _createNode(nodeId, nodeName, uint64(block.timestamp), uint64(block.timestamp), tier, paidAmount, 0, account);
    }

    function transferHelperOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit HelperOwnershipTransferred(_helperContract, newOwner);
        _helperContract = newOwner;
    }

    // <------------ VIEWS ------------

    function totalSupply() view external returns (uint) {
        return nodeCounter;
    }

    function getNodesByAccount(address account) public view returns (Solar [] memory){
        Solar[] memory solars = new Solar[](_bags[account].length);

        for (uint i = 0; i < _bags[account].length; i++) {
            uint nodeId = _bags[account][i];
            solars[i] = _nodes[nodeId];
        }
        return solars;
    }

    function getNode(uint _id) public view onlyIfExists(_id) returns (Solar memory) {
        return _nodes[_id];
    }

    function balanceOf(address owner) public override view returns (uint balance){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint tokenId) public override view onlyIfExists(tokenId) returns (address owner) {
        address theOwner = _owners[tokenId];
        return theOwner;
    }

    function getNodesOf(address _account) public view returns (uint[] memory) {
        return _bags[_account];
    }

    function tokenURI(uint tokenId) external override view returns (string memory) {
        return string(abi.encodePacked(defaultUri, uint2str(_nodes[tokenId].tier), defaultUriExt));
    }
    // -------------- VIEWS -----------------/>

    function setMinimumNodePrice(uint newPrice) onlyOwner external {
        minimumNodePrice = newPrice;
    }

    function setDefaultTokenUri(string memory uri) onlyOwner external {
        defaultUri = uri;
    }
    function setDefaultTokenUriExt(string memory uri) onlyOwner external {
        defaultUriExt = uri;
    }

    function _deleteNode(uint _id) onlyOwner external {
        address owner = ownerOf(_id);
        _balances[owner] -= 1;
        delete _owners[_id];
        delete _nodes[_id];
        _remove(_id, owner); 
    }

    function _deleteMultipleNode(uint[] calldata _ids) onlyOwner external {
        for (uint i = 0; i < _ids.length; i++) {
            uint _id = _ids[i];
            address owner = ownerOf(_id);
            _balances[owner] -= 1;
            delete _owners[_id];
            delete _nodes[_id];
            _remove(_id, owner);
        }
    }

    function _createNode(uint _id, string memory _name, uint64 _mint, uint64 _claim, uint8 _tier, uint _compoundedQuantity, uint16 _bonusRewardPercent, address _to) internal {
        require(!_exists(_id), "MANAGER: Solar already exist");
        require(_tier <= tierCount && _tier != 0, "MANAGER: Tier isn't valid");

        _nodes[_id] = Solar({
            id: _id,
            name: _name,
            mintTimestamp: _mint,
            claimTimestamp: _claim,
            tier: _tier,
            compoundedQuantity: _compoundedQuantity,
            bonusRewardPercent: _bonusRewardPercent
        });
        _owners[_id] = _to;
        _balances[_to] += 1;
        _bags[_to].push(_id);

        emit Transfer(address(0), _to, _id);
    }

    function _remove(uint _id, address _account) internal {
        uint[] storage _ownerNodes = _bags[_account];
        uint length = _ownerNodes.length;

        uint _index = length;
        
        for (uint i = 0; i < length; i++) {
            if(_ownerNodes[i] == _id) {
                _index = i;
            }
        }
        if (_index >= _ownerNodes.length) return;
        
        _ownerNodes[_index] = _ownerNodes[length - 1];
        _ownerNodes.pop();
    }

    function renameNode(uint id, string memory newName) external {
        require(ownerOf(id) == msg.sender, "MANAGER: You are not the owner");
        Solar storage solar = _nodes[id];
        solar.name = newName;
    }

    function safeTransferFrom(address from, address to, uint tokenId ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to,uint tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint tokenId) public override view onlyIfExists(tokenId) returns (address operator){
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        _bags[to].push(tokenId);
        _remove(tokenId, from);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view onlyIfExists(tokenId) returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data) private returns (bool) {
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

    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _nodes[tokenId];
        _remove(tokenId, owner);
        emit Transfer(owner, address(0), tokenId);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

contract WeigthOwnable is Context {
    address internal _weigthContract;

    event WeigthOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _weigthContract = msgSender;
        emit WeigthOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function weigthContract() public view returns (address) {
        return _weigthContract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyWeigth() {
        require(_weigthContract == _msgSender(), "Ownable: caller is not the weight");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

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
pragma solidity ^0.8.0;

import './Context.sol';

contract HelperOwnable is Context {
    address internal _helperContract;

    event HelperOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the current owner.
     */
    function helperContract() public view returns (address) {
        return _helperContract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyHelper() {
        require(_helperContract == _msgSender(), "Ownable: caller is not the helper");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import './IERC721.sol';

interface IManager is IERC721 {
    // function price() external returns(uint256);
    function createNode(address account, string memory nodeName, uint8 tier, uint paidAmount) external;
    function claim(address account, uint256 _id) external returns (uint);
    function claimAndCompound(address account, uint _id) external;
    function claimAll(address account) external returns (uint);
    function claimAndCompoundAll(address account) external;
    function stake(address account, uint id, uint amountToStake) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import './IERC721.sol';

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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