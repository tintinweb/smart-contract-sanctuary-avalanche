//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "ERC20.sol";
import "ERC20Snapshot.sol";
import "Ownable.sol";
import "Pausable.sol";
import "SafeMath.sol";


contract PAT is ERC20, ERC20Snapshot, Ownable, Pausable {
    using SafeMath for uint256;

    string private constant _name = "PATToken";
    string private constant _symbol = "PAT";
    uint256 public totalMinted = 0;
    uint256 public totalBurned = 0;
    address public StakingAddress;
    address public StakingAddress2;
    address public AirdropAddress;
    address public ExtensionAddress;
    address public GameAddress;

    /* events */
    event Burned(address _from, uint256 _amount);
    event Minted(address _to, uint256 _amount);
    event TransferSent(address _from, address _to, uint256 _amount);

    constructor() ERC20(_name, _symbol) {
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "address is not correct");
        require(
            StakingAddress != address(0) ||
                StakingAddress2 != address(0) ||
                GameAddress != address(0) ||
                ExtensionAddress != address(0) ||
                AirdropAddress != address(0),
            "contracts addresses is not set or not correct"
        );
        require(
            _msgSender() == StakingAddress ||
                _msgSender() == StakingAddress2 ||
                _msgSender() == GameAddress ||
                _msgSender() == ExtensionAddress ||
                _msgSender() == AirdropAddress,
            "sender does not have permission"
        );
        totalMinted = SafeMath.add(totalMinted, _amount);
        _mint(_to, _amount);
        emit Minted(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external whenNotPaused {
        require(_from != address(0), "address is not correct");
        require(
            StakingAddress != address(0) ||
                StakingAddress2 != address(0) ||
                GameAddress != address(0) ||
                ExtensionAddress != address(0),
            "contracts addresses is not set or not correct"
        );
        require(
            _msgSender() == StakingAddress ||
                _msgSender() == StakingAddress2 ||
                _msgSender() == GameAddress ||
                _msgSender() == ExtensionAddress,
            "sender does not have permission"
        );
        totalBurned = SafeMath.add(totalBurned, _amount);
        _burn(_from, _amount);
        emit Burned(_from, _amount);
    }

    function setAirdropAddress(address _airdropAddress) external onlyOwner {
        require(_airdropAddress != address(0), "address is not correct");
        AirdropAddress = _airdropAddress;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        require(_stakingAddress != address(0), "address is not correct");
        StakingAddress = _stakingAddress;
    }

    function setStakingAddress2(address _address) external onlyOwner {
        require(_address != address(0), "address is not correct");
        StakingAddress2 = _address;
    }

    function setGameAddress(address _address) external onlyOwner {
        require(_address != address(0), "address is not correct");
        GameAddress = _address;
    }

    //for further project contract development
    function setExtensionAddress(address _extensionAddress) external onlyOwner {
        require(_extensionAddress != address(0), "address is not correct");
        ExtensionAddress = _extensionAddress;
    }

    function totalBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}