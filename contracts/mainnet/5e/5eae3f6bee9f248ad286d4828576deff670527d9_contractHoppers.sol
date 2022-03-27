/**
 *Submitted for verification at snowtrace.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
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

interface IERC721 {
    /**
     * @dev Emitted when tokenId token is transferred from from to to.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    /**
     * @dev Emitted when owner enables approved to manage the tokenId token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    /**
     * @dev Emitted when owner enables or disables (`approved`) operator to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    /**
     * @dev Returns the owner of the tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    /**
     * @dev Safely transfers tokenId token from from to to, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    /**
     * @dev Transfers tokenId token from from to to.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    /**
     * @dev Gives permission to to to transfer tokenId token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - tokenId must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;
    /**
     * @dev Returns the account approved for tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
    /**
     * @dev Approve or remove operator as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The operator cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;
    /**
     * @dev Returns if the operator is allowed to manage all of the assets of owner.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
    /**@dev Safely transfers tokenId token from from to to.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns a token ID owned by owner at a given index of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    
    /**
     * @dev Returns a token ID at a given index of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} tokenId token is transferred to this contract via {IERC721-safeTransferFrom}
     * by operator from from, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with IERC721.onERC721Received.selector.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IAVAX20 {
    function totalSupply() external view returns (uint256);
    function deposit(uint256 amount) external payable;
    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address who) external view returns (uint256);
}


library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}


interface Ihoppers is IERC721Enumerable, IERC721Receiver{
    function levelUp(uint256 tokenId, bool useOwnRewards) external payable;
    function balanceOf() external view returns (uint256);
    function ownerOf() external view returns (address);
    function emissionRate() external view returns (uint256);
    function baseSharesBalance(address user) external view returns (uint256);
    function totalBaseShare() external view returns (uint256);
    function bonusEmissionRate() external view returns (uint256);
    function totalVeShare() external view returns (uint256);
    function veSharesBalance(address user) external view returns (uint256);
    function hoppers(uint256 tokenId) external view returns (uint200 level, uint200 rebirths, uint200 strength, uint200 agility, uint200 vitality, uint200 intelligence, uint200 fertility);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

interface veFly{
    function deposit(uint256 amount) external payable;
    function withdraw(uint256 amount) external payable;
}



contract contractHoppers is Ownable, IERC721Receiver{

    address private _addressPond = 0x85e66216fB0e80F87b54eb39a415c3bbD40E37f9;
    address private _addressStream = 0x780Feb71117157A039E682668D79584D18579E90;
    address private _addressSwamp = 0xEc7E923E7e0BD2DC7bB2Ac0FabCCf4E650C5418C;
    address private _addressRiver = 0x4eEf52B71Bd64d54d736Cf2F3073e6DBbfCc7E31;
    address private _addressForest = 0xcD32Ed513a86484688cd3DbaDA05a9eD3c0c0Eb6;
    address private _addressGreatLake = 0x1009CbA3c0A50a2A0E8A92bC070aC5ffB8A3efE2;
    address private _addressBreeding = 0x16D5791f7C31d7e13dD7b18ae2011764C4DA8fbC;
    address private _addressMarket = 0xbbF9287aFbf1CdBf9f7786E98fC6CEa73A78B6aB;

    Ihoppers h = Ihoppers(0x4245a1bD84eB5f3EBc115c2Edf57E50667F98b0b);

    function populationPond() public view returns (uint256) {
        return h.balanceOf(_addressPond);
    }

    function populationStream() public view returns (uint256) {
        return h.balanceOf(_addressStream);
    }

    function populationSwamp() public view returns (uint256) {
        return h.balanceOf(_addressSwamp);
    }

    function populationRiver() public view returns (uint256) {
        return h.balanceOf(_addressRiver);
    }

    function populationForest() public view returns (uint256) {
        return h.balanceOf(_addressForest);
    }

    function populationGreatLake() public view returns (uint256) {
        return h.balanceOf(_addressGreatLake);
    }

    function populationBreeding() public view returns (uint256) {
        return h.balanceOf(_addressBreeding);
    }

    function populationMarket() public view returns (uint256) {
        return h.balanceOf(_addressMarket);
    }

    function getFlyPerDay(uint256 tokenId, address user) public view returns (uint256 actual, uint256 pond, uint256 stream, uint256 swamp, uint256 river, uint256 forest, uint256 lake) {
        uint256 actualRewards = 0;
        address actualOwner = h.ownerOf(tokenId);
        uint200 [] memory infos;
        
        
        if(actualOwner == _addressPond){
            Ihoppers z = Ihoppers(_addressPond);
            uint256 emissionRate = z.emissionRate();

        }
    }

    function getInfos(uint256 tokenId) public view returns (uint200 level, uint200 rebirths, uint200 strength, uint200 agility, uint200 vitality, uint200 intelligence, uint200 fertility){
        return h.hoppers(tokenId);
    }
    using SafeMath for uint;
    fallback() external payable{
          
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function withdrawAVAX() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 amount, address token) onlyOwner external{
        IAVAX20(token).transfer(msg.sender, amount);
    }
    
    function safeTransfer_Back(uint256 id) onlyOwner external {
        h.safeTransferFrom(address(this), msg.sender, id);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}