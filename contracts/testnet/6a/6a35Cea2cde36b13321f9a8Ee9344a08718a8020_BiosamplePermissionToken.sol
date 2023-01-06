pragma solidity 0.6.2;

import "../nf-token-metadata.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract BiosamplePermissionToken is
  NFTokenMetadata
{
  string namespace;

  /**
   * @dev MUST emit when the URI is updated for a token ID.
   * URIs are defined in RFC 3986.
   * Inspired by ERC-1155
   */
  event URI(string _value, uint256 indexed _tokenId);

  /**
   * @dev Enum representing supported signature kinds.
   */
  enum SignatureKind
  {
    no_prefix,
    eth_sign
  }

  /**
   * @dev Mapping of all used claims.
   */
  mapping(bytes32 => bool) public usedClaims;

  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   * @param _namespace Namespace for signature.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _namespace
  )
    public
  {
    nftName = _name;
    nftSymbol = _symbol;
    namespace = "io.genobank.test";

    // Mint existing tokens
    NFToken._mint(0x4d5dD2e41c226B63058dC1e972dDfD33415fE820, 0x000000000000000000000001633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x000000000000000000000001633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    NFToken._mint(0xC8c06CbC1D4176A00081447bc9C0BEE970afaC8C, 0x00000000000000000000270f633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x00000000000000000000270f633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    NFToken._mint(0xCef484DEB09B3dad49a51d3283C1e96809FAd2Bb, 0x000000000001000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x000000000001000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x00000000000100000000270fcef484deb09b3dad49a51d3283c1e96809fad2bb,
      'ACTIVE',
      0x000000000000000000000000000000000000000000000000000001762ec69ecf,
      0x526497dfaca30bd36a4e1a5c910ae11f241d2bc1275821ffdc7478ecce3c1e15,
      0x681104f5442818b04841aafa13774d2db1f37777b9680cf2a1a1d5c0c019eea9,
      0x1b,
      SignatureKind.eth_sign
    );

    NFToken._mint(0x82c182381560A5d62241f49321162d2C84911184, 0x01d656c0e675000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x01d656c0e675000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x01d656c0e67500000000270f82c182381560a5d62241f49321162d2c84911184,
      'ACTIVE',
      0x000000000000000000000000000000000000000000000000000001762ed1c68c,
      0xd8f6bd8d302c42541f56d9483d312c3be987683f6eaf00dd034ef3bce276dbb9,
      0x1e89dbc7ec056ba46204a350059ddc3478b25261b1685df16d6938c2284a7fdf,
      0x1b,
      SignatureKind.eth_sign
    );

    NFToken._mint(0xE068f8f195Ac72F03748e0b652db802D69Bc1Ec0, 0x00e8990a4600000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x00e8990a4600000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x00e8990a4600000000000001e068f8f195ac72f03748e0b652db802d69bc1ec0,
      'ACTIVE',
      0x000000000000000000000000000000000000000000000000000001762eec4bc7,
      0xacef912709b9a227ba69859454556c109c4cb1247e9d70c29a6aa76f20e7d5b4,
      0x03259947085e4ab3d26856ebc23969db79a886f681dfa266cc6cdd77dc5d8c1c,
      0x1b,
      SignatureKind.eth_sign
    );

    NFToken._mint(0x4312Ae73e398df66FBcC2FA82C235B9B14fd3307, 0x01d656c0e67e000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x01d656c0e67e000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x01d656c0e67e0000000000014312ae73e398df66fbcc2fa82c235b9b14fd3307,
      'ACTIVE',
      0x000000000000000000000000000000000000000000000000000001763f25e2f2,
      0xd7b2a19bcc9c1ba62c00a4ecbc5f6be383fc4827d9d215c7aef30950be6ed713,
      0x79122d05ce6e605be95bfdd507c26dc97845855a5746eec5610a2802e167cf64,
      0x1c,
      SignatureKind.eth_sign
    );

    NFToken._mint(0x4B235F7B5c1b21a55fA0A88f98cC9efD16bD6Bb3, 0x01d656c0e67c000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x01d656c0e67c000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x01d656c0e67c0000000000014b235f7b5c1b21a55fa0a88f98cc9efd16bd6bb3,
      'ACTIVE',
      0x0000000000000000000000000000000000000000000000000000017662db3639,
      0x20a884704f4fcb632263c1443191995fe7613eaf655bac3c3735acbe9933c81f,
      0x160b757da765ca8da758634a472139b0ca8a922023ce1bb9f541edb5f920efbe,
      0x1b,
      SignatureKind.eth_sign
    );

    NFToken._mint(0x6ce3C7AB2Dd4F4d7D1cF51cD0DB62C4952Ef80ae, 0x01d656c0e688000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x01d656c0e688000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x01d656c0e6880000000000016ce3c7ab2dd4f4d7d1cf51cd0db62c4952ef80ae,
      'ACTIVE',
      0x000000000000000000000000000000000000000000000000000001766c91fa3d,
      0x4ca7742b3532b6a87c972bf60124ac3a5ab6bf53fd1129612f7eabd6fc19a61f,
      0x67a0008113ac6a14c6a2b2c1a7b39a53215844e5619df23b45fbf33c76bff46d,
      0x1c,
      SignatureKind.eth_sign
    );

    NFToken._mint(0xA866502223C3b995fbaB48A9dF939bcaD90c2Aa6, 0x01d656c0e677000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x01d656c0e677000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x01d656c0e677000000000001a866502223c3b995fbab48a9df939bcad90c2aa6,
      'ACTIVE',
      0x000000000000000000000000000000000000000000000000000001767c5e576b,
      0x5c528613bdfcddb37abfec9a3ffe608f19c259ffe80c18ddfb361315aae6f64f,
      0x4f124411d5b70c9fc3d4c514fd90ef55573b1a496b821f2b6b8346ca443b597f,
      0x1c,
      SignatureKind.eth_sign
    );

    NFToken._mint(0xbfE116a470F83465391c0c939db264Dea9777d12, 0x01d656c0e679000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184);
    NFTokenMetadata._setTokenUri(0x01d656c0e679000000000000633f5500a87c3dbb9c15f4d41ed5a33dacaf4184, 'ACTIVE');

    createWithSignature(
      0x01d656c0e679000000000001bfe116a470f83465391c0c939db264dea9777d12,
      'ACTIVE',
      0x0000000000000000000000000000000000000000000000000000017681f60716,
      0x92fcb8caf0445cf3efe3bd4400287cafb27414bb15c3b8ffe1ddc6b29fb4e009,
      0x2cecdb2741cd0ebc6ad1022befaea44bbc2aab0fdcffdfe0a4ce8b0d88b6b67c,
      0x1c,
      SignatureKind.eth_sign
    );

    namespace = _namespace;
  }

  /**
   * @dev Mints a new NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _receiverId The address that will own the minted NFT.
   * @param _permission String representing permission.
   */
  function mint(
    uint256 _tokenId,
    address _receiverId,
    string calldata _permission
  )
    external
  {
    require(address(_tokenId) == msg.sender, "TokenIds are namespaced to permitters");
    NFToken._mint(msg.sender, _tokenId);
    NFTokenMetadata._setTokenUri(_tokenId, _permission);
    emit URI(_permission, _tokenId);
    if (msg.sender != _receiverId) {
      NFToken._transfer(_receiverId, _tokenId);
    }
  }

  /**
   * @dev Set a permission for a given NFT ID.
   * @param _tokenId Id for which we want URI.
   * @param _permission String representing permission.
   */
  function setTokenUri(
    uint256 _tokenId,
    string calldata _permission
  )
    external
  {
    require(address(_tokenId) == msg.sender, "TokenIds are namespaced to permitters");
    NFTokenMetadata._setTokenUri(_tokenId, _permission);
    emit URI(_permission, _tokenId);
  }

  /**
   * @dev Mints token in the name of signature provider.
   * @param _tokenId of the NFT that will be minted.
   * @param _permission String representing permission.
   * @param _seed Parameter to create hash randomnes (usually timestamp).
   * @param _signatureR Parameter R of the signature.
   * @param _signatureS Parameter S of the signature.
   * @param _signatureV Parameter V of the signature.
   * @param _signatureKind Signature kind.
   */
  function createWithSignature(
    uint256 _tokenId,
    string memory _permission,
    uint256 _seed,
    bytes32 _signatureR,
    bytes32 _signatureS,
    uint8 _signatureV,
    SignatureKind _signatureKind
  )
    public
  {
    bytes32 _claim = getCreateClaim(_tokenId, _seed);
    require(
      isValidSignature(
        address(_tokenId),
        _claim,
        _signatureR,
        _signatureS,
        _signatureV,
        _signatureKind
      ),
      "Signature is not valid."
    );
    require(!usedClaims[_claim], "Claim already used.");
    usedClaims[_claim] = true;
    NFToken._mint(address(_tokenId), _tokenId);
    NFTokenMetadata._setTokenUri(_tokenId, _permission);
    emit URI(_permission, _tokenId);
  }

  /**
   * @dev Set a permission for a given NFT ID in the name of signature provider.
   * @param _tokenId of the NFT which permission will get set.
   * @param _permission String representing permission.
   * @param _seed Parameter to create hash randomnes (usually timestamp).
   * @param _signatureR Parameter R of the signature.
   * @param _signatureS Parameter S of the signature.
   * @param _signatureV Parameter V of the signature.
   * @param _signatureKind Signature kind.
   */
  function setTokenUriWithSignature(
    uint256 _tokenId,
    string calldata _permission,
    uint256 _seed,
    bytes32 _signatureR,
    bytes32 _signatureS,
    uint8 _signatureV,
    SignatureKind _signatureKind
  )
    external
  {
    bytes32 _claim = getUpdateUriClaim(_tokenId, _permission, _seed);
    require(
      isValidSignature(
        address(_tokenId),
        _claim,
        _signatureR,
        _signatureS,
        _signatureV,
        _signatureKind
      ),
      "Signature is not valid."
    );
    require(!usedClaims[_claim], "Claim already used.");
    usedClaims[_claim] = true;
    NFTokenMetadata._setTokenUri(_tokenId, _permission);
    emit URI(_permission, _tokenId);
  }

  /**
   * @dev Cheks if signature is indeed provided by the signer.
   * @param _signer Address of the signer.
   * @param _claim Claim that was signed.
   * @param _r Parameter R of the signature.
   * @param _s Parameter S of the signature.
   * @param _v Parameter V of the signature.
   * @param _kind Signature kind.
   */
  function isValidSignature(
    address _signer,
    bytes32 _claim,
    bytes32 _r,
    bytes32 _s,
    uint8 _v,
    SignatureKind _kind
  )
    public
    pure
    returns (bool)
  {
    if (_kind == SignatureKind.no_prefix) {
      return _signer == ecrecover(
        _claim,
        _v,
        _r,
        _s
      );
    } else if (_kind == SignatureKind.eth_sign) {
      return _signer == ecrecover(
          keccak256(
            abi.encodePacked(
              "\x19Ethereum Signed Message:\n32",
              _claim
            )
          ),
          _v,
          _r,
          _s
        );
    } else {
      revert("Invalid signature kind.");
    }
  }

  /**
   * @dev Generates claim for creating a token.
   * @param _tokenId of the NFT we are creating.
   * @param _seed Parameter to create hash randomnes (usually timestamp).
   */
  function getCreateClaim(
    uint256 _tokenId,
    uint256 _seed
  )
    public
    view
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        namespace,
        ".create",
        _tokenId,
        _seed
      )
    );
  }

 /**
   * @dev Generates claim for updating a token permission.
   * @param _tokenId of the NFT we are updating permission.
   * @param _permission String representing permission.
   * @param _seed Parameter to create hash randomnes (usually timestamp).
   */
  function getUpdateUriClaim(
    uint256 _tokenId,
    string memory _permission,
    uint256 _seed
  )
    public
    view
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        namespace,
        ".permit",
        _tokenId,
        _permission,
        _seed
      )
    );
  }

}