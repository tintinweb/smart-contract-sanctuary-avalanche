/***
Fatih Belediyesi Evlendirme Memurluğuna

Taraflar: service1 - taraf2
Taraf Cüzdanları: 0xe6B8312aC2731d1F606f4d6686aA60Fa0EAffEaf - 0xe6B8312aC2731d1F606f4d6686aA60Fa0EAffEaf

Biz 01.01.1970 evlenme tarihinden itibaren “… Mal Ayrılığı Rejimine” tabi olmak istediğimizi bildirir, bu seçimlik mal rejimimizi kayda geçmesini saygıyla dileriz.

***/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

  	/**
	 * @title EvlilikSozlesmesi
	 *
	 * A crude, simple single file implementation of ERC721 standard
	 * @dev See https://github.com/ethereum/eips/issues/721
	 *
	 * Incomplete, the standard itself is not finalized yet (Done before the issue 841, see: https://github.com/ethereum/EIPs/pull/841)
	*/

contract EvlilikSozlesmesi {
    using SafeMath for uint256;

    // ------------- Variables

    uint256 public totalSupply2;

    // Basic references
    mapping(uint => address) internal tokenIdToOwner;
    mapping(address => uint[]) internal listOfOwnerTokens;
    mapping(uint => uint) internal tokenIndexInOwnerArray;
    // Approval mapping
    mapping(uint => address) internal approvedAddressToTransferTokenId;
    // Metadata infos
    mapping(uint => string) internal referencedMetadata;

    // ------------- Events

    event Minted(address indexed _to, uint256 indexed _tokenId);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // ------------- Modifier

    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }

    modifier onlyExtantToken(uint _tokenId) {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

    // ------------- (View) Functions

    // @dev Returns the address currently marked as the owner of _tokenID.
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }

    // @dev Get the total supply of token held by this contract.
    function totalSupply() public view returns (uint256 _totalSupply)
    {
        return totalSupply2;
    }

    function balanceOf(address _owner) public view returns (uint _balance)
    {
        return listOfOwnerTokens[_owner].length;
    }

    // @dev Returns a multiaddress string referencing an external resource bundle that contains
    function tokenMetadata(uint _tokenId) public view returns (string memory _infoUrl)
    {
        return referencedMetadata[_tokenId];
    }

    // ------------- (Core) Functions

    // @dev Anybody can create a token and give it to an owner
    // TODO, in the next version, add a Contract Owner
    function mint(address _owner, uint256 _tokenId) public onlyNonexistentToken (_tokenId)
    {
        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);

        totalSupply2 = totalSupply2.add(1);
        emit Minted(_owner, _tokenId);
    }

    // @dev Anybody can create a token and give it to an owner
    // TODO, in the next version, add a Contract Owner
    // @notice only one of these functions(Mint, mintWithMetadata) must remain depending on the use case, should separate the files
    function mintWithMetadata(address _owner, uint256 _tokenId, string memory _metadata) public onlyNonexistentToken (_tokenId)
    {
        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);

        totalSupply2 = totalSupply2.add(1);

        _insertTokenMetadata(_tokenId, _metadata);
        emit Minted(_owner, _tokenId);
    }

	// @dev Assigns the ownership of the NFT with ID _tokenId to _to
    function transfer(address _to, uint _tokenId) public onlyExtantToken (_tokenId)
    {
        require(ownerOf(_tokenId) == msg.sender);
        require(_to != address(0));

        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);

       emit Transfer(msg.sender, _to, _tokenId);
    }

    // @dev Grants approval for address _to to take possession of the NFT with ID _tokenId.
    function approve(address _to, uint _tokenId) public onlyExtantToken(_tokenId)
    {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        if (approvedAddressToTransferTokenId[_tokenId] != address(0) || _to != address(0)) {
            approvedAddressToTransferTokenId[_tokenId] = _to;
            emit Approval(msg.sender, _to, _tokenId);
        }
    }

    // @dev transfer token From _from to _to
    // @notice address _from is unnecessary
    function transferFrom(address _from, address _to, uint _tokenId) public onlyExtantToken(_tokenId)
    {
        require(approvedAddressToTransferTokenId[_tokenId] == msg.sender);
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        emit Approval(_from, _to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    // ---------------------------- Internal, helper functions

    function _setTokenOwner(uint _tokenId, address _owner) internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    function _addTokenToOwnersList(address _owner, uint _tokenId) internal
    {
        listOfOwnerTokens[_owner].push(_tokenId);
        tokenIndexInOwnerArray[_tokenId] = listOfOwnerTokens[_owner].length - 1;
    }

    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId) internal
    {
        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);
        _setTokenOwner(_tokenId, _to);
        _addTokenToOwnersList(_to, _tokenId);
    }

    function _removeTokenFromOwnersList(address _owner, uint _tokenId) internal
    {
        uint length = listOfOwnerTokens[_owner].length; // length of owner tokens
        uint index = tokenIndexInOwnerArray[_tokenId]; // index of token in owner array
        uint swapToken = listOfOwnerTokens[_owner][length - 1]; // last token in array

        listOfOwnerTokens[_owner][index] = swapToken; // last token pushed to the place of the one that was transfered
        tokenIndexInOwnerArray[swapToken] = index; // update the index of the token we moved

        delete listOfOwnerTokens[_owner][length - 1]; // remove the case we emptied
        listOfOwnerTokens[_owner].length; // shorten the array's length
    }

    function _clearTokenApproval(uint _tokenId) internal
    {
        approvedAddressToTransferTokenId[_tokenId] = address(0);
    }

    function _insertTokenMetadata(uint _tokenId, string memory _metadata) internal
    {
        referencedMetadata[_tokenId] = _metadata;
    }
}