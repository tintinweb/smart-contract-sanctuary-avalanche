// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";

contract USDC is ERC20, Ownable {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    constructor() ERC20("USDC", "USDC") {}

    uint256 public MAX_GOLD_SUPPLY;
    uint256 public Tax;
    address public TaxReciver;
    bool public TaxActive;

    address[] public TaxwhitelistedAddresses;
    address[] public TxblacklistedAddresses;

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
        require(
            _isBlacklisted(_msgSender()) == false,
            "You are blacklisted, you can't no longer trade this token"
        );
        if (
            (TaxActive = true) &&
            (_isExcludedFromTax(_msgSender()) == false) &&
            (_isExcludedFromTax(recipient) == false)
        ) {
            uint256 netTax = (amount * Tax) / 100;
            uint256 afterTax = amount - netTax;
            _transfer(_msgSender(), recipient, afterTax);
            _transfer(_msgSender(), TaxReciver, netTax);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20) returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        require(
            _isBlacklisted(_msgSender()) == false,
            "You are blacklisted, you can't no longer trade this token"
        );
        if (
            (TaxActive = true) &&
            (_isExcludedFromTax(_msgSender()) == false) &&
            (_isExcludedFromTax(recipient) == false)
        ) {
            uint256 netTax = (amount * Tax) / 100;
            uint256 afterTax = amount - netTax;
            _transfer(_msgSender(), recipient, afterTax);
            _transfer(_msgSender(), TaxReciver, netTax);
        } else {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    /**
     * Adding multiple wallet to the No Tax List
     * @param _users the list of wallet to Add
     */
    function AddWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            TaxwhitelistedAddresses.push(_users[i]);
        }
    }

    function RemoveWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = 0; a < TaxwhitelistedAddresses.length; a++) {
                if (TaxwhitelistedAddresses[a] == _users[i]) {
                    TaxwhitelistedAddresses[a] = TaxwhitelistedAddresses[
                        TaxwhitelistedAddresses.length - 1
                    ];
                    TaxwhitelistedAddresses.pop();
                }
            }
        }
    }

    /**
     * Adding multiple wallet to the BlackList
     * @param _users the list of wallet to Add
     */
    function AddBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            TxblacklistedAddresses.push(_users[i]);
        }
    }

    function RemoveBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = TxblacklistedAddresses.length; a == 0; a--) {
                if (TxblacklistedAddresses[a] == _users[i]) {
                    TxblacklistedAddresses[a] = TxblacklistedAddresses[
                        TxblacklistedAddresses.length - 1
                    ];
                    TxblacklistedAddresses.pop();
                }
            }
        }
    }

    /**
     * Chekign if the wallet is excluded from tax
     * @param _wallet the wallet to check
     */
    function _isExcludedFromTax(address _wallet) internal view returns (bool) {
        for (uint256 i = 0; i < TaxwhitelistedAddresses.length; i++) {
            if (TaxwhitelistedAddresses[i] == _wallet) {
                return true;
            }
        }
        return false;
    }

    /**
     * Chekign if the wallet is blacklisted
     * @param _wallet the wallet to check
     */
    function _isBlacklisted(address _wallet) internal view returns (bool) {
        for (uint256 i = 0; i < TxblacklistedAddresses.length; i++) {
            if (TxblacklistedAddresses[i] == _wallet) {
                return true;
            }
        }
        return false;
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
     * @param _Active to determinate if the tax is active or not
     */
    function SetTaxAndTaxCollector(
        bool _Active,
        address _TaxReciver,
        uint256 _Tax
    ) external onlyOwner {
        TaxActive = _Active;
        TaxReciver = _TaxReciver;
        Tax = _Tax;
    }

    /**
     * mints $GOLD to a recipient
     * @param to the recipient of the $GOLD
     * @param amount the amount of $GOLD to mint
     */
    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalSupply() <= MAX_GOLD_SUPPLY,
            "All the GOLD is already been minted"
        );
        uint256 finalAmount = amount * 1 ether;
        _mint(to, finalAmount);
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