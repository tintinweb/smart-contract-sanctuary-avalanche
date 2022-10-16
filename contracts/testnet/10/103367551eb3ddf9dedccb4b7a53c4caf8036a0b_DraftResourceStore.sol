/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-13
*/

// File: contracts/interfaces/IDraftResourceStore.sol


pragma solidity ^0.8.7;




interface IDraftResourceStore {    
    event ResourceAdded(uint256 indexed tokenId, string locale, string uri);
    event ResourceRemoved(uint256 indexed tokenId, string locale);    
    event ResourceSigned(uint256 indexed tokenId, string locale, string uri);

    // add localized data
    function addResource(uint256 tokenId, string calldata locale, string calldata uri) external;
    // add signature for the localized resoure
    function addResourceSignature(uint256 tokenId, string calldata locale, bytes calldata signature) external;    
    // get resource uri for the certain locale of the certain passport    
    function getResource(uint256 tokenId, string calldata locale) external view returns (string memory);
    // get signature for the certain locale of the certain passport    
    function getSignature(uint256 tokenId, string calldata locale) external view returns (bytes memory);    
    // remove localized data and signatures
    function purge(uint256 tokenId) external;    
}
// File: node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: contracts/DraftResourceStore.sol


pragma solidity ^0.8.7;



/**
* DRAFT, JUST AN IDEA ... POC
*/
contract DraftResourceStore is ERC165,  IDraftResourceStore {
  // owner
  address private _owner;
  // service
  address private _service;  
  // mapping between passport and locale / uri
  mapping (uint256 => mapping (bytes4 => string)) private resources;
  // mapping between passport and locale / signature
  mapping (uint256 => mapping (bytes4 => bytes)) private signatures;

  mapping (uint256 => bytes4[]) private locales;  

  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165) returns (bool) {
    return
      interfaceId == type(IDraftResourceStore).interfaceId ||
      super.supportsInterface(interfaceId);
  }    

  modifier onlyOwner() {
    require(_owner == msg.sender, "caller is not the owner");
     _;
  }

  modifier onlyService() {
    require(_service == msg.sender, "caller is not the authorized");
     _;
  }    

  constructor()  {
    _owner = msg.sender;
  }

  function setOwner(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "New owner is the zero address");
    _owner = newOwner;
  }

  function setService(address newService) public virtual onlyOwner {
     require(newService != address(0), "New service is the zero address");
    _service = newService;
  } 

  // add localized data
  function addResource(uint256 tokenId, string calldata locale, string calldata uri) override external onlyService {
    require(bytes(uri).length > 0, "resource is empty");         
    bytes4 locale4 = bytes4(bytes(locale));
    require(bytes(resources[tokenId][locale4]).length == 0, "resource already added");
    resources[tokenId][locale4] = uri;
    locales[tokenId].push(locale4);
    emit ResourceAdded(tokenId, locale, uri);
  }

  // add signature for the localized resoure
  function addResourceSignature(uint256 tokenId, string calldata locale, bytes calldata signature) override external onlyService {
    require(signature.length > 0, "signature is empty");          
    bytes4 locale4 = bytes4(bytes(locale));
    require(bytes(resources[tokenId][locale4]).length > 0, "resource is missed");    
    require(signatures[tokenId][locale4].length == 0, "signature already added");    
    signatures[tokenId][locale4] = signature;
  }
    
  // get resource uri for the certain locale of the certain passport    
  function getResource(uint256 tokenId, string calldata locale) override  external view returns (string memory) {
    bytes4 locale4 = bytes4(bytes(locale));
    return resources[tokenId][locale4];
  }

   function purge(uint256 tokenId) override external onlyService {
    for (uint256 i = 0; i < locales[tokenId].length; ++i) {
          delete resources[tokenId][locales[tokenId][i]];
          delete signatures[tokenId][locales[tokenId][i]];
    }
    delete locales[tokenId];
   }

  // get signature for the certain locale of the certain passport
  function getSignature(uint256 tokenId, string calldata locale) override external view returns (bytes memory) {
    bytes4 locale4 = bytes4(bytes(locale));
    return signatures[tokenId][locale4];
  } 
}