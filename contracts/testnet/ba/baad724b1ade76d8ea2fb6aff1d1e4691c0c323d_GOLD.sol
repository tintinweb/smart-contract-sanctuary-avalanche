// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract GOLD is ERC20, Ownable, ReentrancyGuard {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    constructor() ERC20("GOLD", "GOLD") {}
    bool public TransferActive = true;
    uint256 public MAX_GOLD_SUPPLY ;
    uint256 public Tax;
    address public TaxReciver;
    bool public TaxActive = false;

    bytes32 public TaxwhitelistMerkleRoot;
    bytes32[] public TaxwhitelistMerkleProof;
    bytes32 public TxblacklistMerkleRoot;
    bytes32[] public TxblacklistMerkleProof;

    /**
     * the transfer fuction with the tax
     * @param recipient the wallet that will recive the GOLD
     * @param amount the amount of GOLD sent
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override(ERC20)
        returns (bool)
    {
        bytes32 leafSender = keccak256(abi.encodePacked(_msgSender()));
        bytes32 leafRecipiant = keccak256(abi.encodePacked(recipient));
       require(TransferActive = true, "Transfer of the token is not active");
       require(MerkleProof.verify(TxblacklistMerkleProof, TxblacklistMerkleRoot, leafSender),"You are blacklisted, you can't no longer trade this token");
        if (
            (_isTaxActive() ) &&
            (!MerkleProof.verify(TaxwhitelistMerkleProof, TaxwhitelistMerkleRoot, leafSender)) &&
            (!MerkleProof.verify(TaxwhitelistMerkleProof, TaxwhitelistMerkleRoot, leafRecipiant) )
        ) {
            uint256 netTax = (amount * Tax) / 100;
            uint256 afterTax = amount - netTax;
            _transfer(_msgSender(), recipient, afterTax);
            _transfer(_msgSender(), TaxReciver, netTax);
            return true;
        } else {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20) returns (bool) {
       bytes32 leafSender = keccak256(abi.encodePacked(_msgSender()));
        bytes32 leafRecipiant = keccak256(abi.encodePacked(recipient));
       require(TransferActive = true, "Transfer of the token is not active");
       require(!MerkleProof.verify(TxblacklistMerkleProof, TxblacklistMerkleRoot, leafSender),"You are blacklisted, you can't no longer trade this token");
        if (
            (_isTaxActive() ) &&
            (!MerkleProof.verify(TaxwhitelistMerkleProof, TaxwhitelistMerkleRoot, leafSender)) &&
            (!MerkleProof.verify(TaxwhitelistMerkleProof, TaxwhitelistMerkleRoot, leafRecipiant) )
        ) {
            uint256 netTax = (amount * Tax) / 100;
            uint256 afterTax = amount - netTax;
            _transfer(sender, recipient, afterTax);
            _transfer(sender, TaxReciver, netTax);
            return true;
        } else {
            _transfer(sender, recipient, amount);
            return true;
        }
    }

    /**
     * Set the root hash for the Tax Whitelist 
     * @param _TaxwhitelistMerkleRoot the Root Hash to Set
     */
    function SetWhitelistMerkleRoot(bytes32 _TaxwhitelistMerkleRoot) public onlyOwner {
        TaxwhitelistMerkleRoot = _TaxwhitelistMerkleRoot;
    }

    /**
     * Set the root hash for the Tax Whitelist 
     * @param _WhitlelistMerkleProof the Root Hash to Set
     */
    function SetWhitelistMerkleProof(bytes32[] calldata _WhitlelistMerkleProof) public onlyOwner {
        TaxwhitelistMerkleProof = _WhitlelistMerkleProof;
    }

    /**
     * Set the root hash for the Blacklist 
     * @param _TxblacklistMerkleRoot the Root Hash to Set
     */
    function SetBlacklistMerkleRoot(bytes32 _TxblacklistMerkleRoot) public onlyOwner {
        TxblacklistMerkleRoot = _TxblacklistMerkleRoot;
    }

    /**
     * Set the root hash for the Blacklist 
     * @param _TxblacklistMerkleProof the Root Hash to Set
     */
    function SetTxblacklistMerkleProof(bytes32[] calldata _TxblacklistMerkleProof) public onlyOwner {
        TxblacklistMerkleProof = _TxblacklistMerkleProof;
    }

    function _isTaxActive() internal view returns (bool) {
        if(TaxActive == true){
            return true;
        }else{
            return false;
        }
    }

    /**
     * set the GOLD max supply
     * @param _MaxSupply the max number of gold possible to mint
     */
    function SetMaxGoldSupply(uint256 _MaxSupply) external onlyOwner {
        uint256 MaxSupply = _MaxSupply * 1 ether;
        MAX_GOLD_SUPPLY = MaxSupply;
    }

    /**
     * set the Tax and TaxReciver
     * @param _TaxReciver the recipient of the Tax
     * @param _Tax the amount of Tax
     */
    function SetTaxAndTaxCollector(
        address _TaxReciver,
        uint256 _Tax
    ) external onlyOwner {
        TaxReciver = _TaxReciver;
        Tax = _Tax;
    }

    /**
    * set the Tax and TaxReciver
    * @param _Active to determinate if the tax is active or not
    */
    function TaxStatus (bool _Active) public onlyOwner{
        TaxActive = _Active;
    }
    

    /**
     * mints $GOLD to a recipient
     * @param to the recipient of the $GOLD
     * @param amount the amount of $GOLD to mint
     */
    function MintinEther(address to, uint256 amount) external onlyOwner nonReentrant() {
        
        require(
            totalSupply() <= MAX_GOLD_SUPPLY,
            "All the GOLD is already been minted"
        );
        uint256 finalAmount = amount * 1 ether;
        _mint(to, finalAmount);
    }

    /**
     * mints $GOLD to a recipient
     * @param to the recipient of the $GOLD
     * @param amount the amount of $GOLD to mint
     */
    function mint(address to, uint256 amount) external nonReentrant() {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalSupply() <= MAX_GOLD_SUPPLY,
            "All the GOLD is already been minted"
        );
        
        _mint(to, amount);
    }

    /**
     * burns $GOLD from a holder
     * @param from the holder of the $GOLD
     * @param amount the amount of $GOLD to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }
    
    /**
     * Set the Transfer of NFT state
     * @param _state the State to set
     */
    function setTransferActive(bool _state) public onlyOwner {
        TransferActive = _state;
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }
    

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}