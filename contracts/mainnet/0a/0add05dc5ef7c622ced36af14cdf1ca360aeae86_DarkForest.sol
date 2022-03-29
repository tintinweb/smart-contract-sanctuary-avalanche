// SPDX-License-Identifier: UNLICENSED
/*
    ██████╗  █████╗ ██████╗ ██╗  ██╗    ███████╗ ██████╗ ██████╗ ███████╗███████╗████████╗
    ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝    ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██║  ██║███████║██████╔╝█████╔╝     █████╗  ██║   ██║██████╔╝█████╗  ███████╗   ██║   
    ██║  ██║██╔══██║██╔══██╗██╔═██╗     ██╔══╝  ██║   ██║██╔══██╗██╔══╝  ╚════██║   ██║   
    ██████╔╝██║  ██║██║  ██║██║  ██╗    ██║     ╚██████╔╝██║  ██║███████╗███████║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝                                                                                         
*/

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./OwnerRecovery.sol";
import "./LiquidityPoolManagerImplementationPointer.sol";
import "./WalletObserverImplementationPointer.sol";

contract DarkForest is
    ERC20,
    ERC20Burnable,
    Ownable,
    OwnerRecovery,
    LiquidityPoolManagerImplementationPointer,
    WalletObserverImplementationPointer
{
    using SafeMath for uint256;
    address public immutable planetsManager;

    uint256 public sellDevFee = 3;
    uint256 public sellNftFee = 3;
    uint256 public sellTreasuryFee = 4;

    address public devWallet = 0x1981d1dd51f51f7Ffc16Dd13d69bFFBA942dACCe;
    address public nftWallet = 0xE76357c518248BFb079C3A82Bd5e12EFE8a99645;

    uint256 public transferFee = 2;

    event SetSellFee(uint256 newSellFee);
    event SetTransferFee(uint256 newTransferFee);

    modifier onlyPlanetsManager() {
        address sender = _msgSender();
        require(
            sender == address(planetsManager),
            "Implementations: Not PlanetsManager"
        );
        _;
    }

    constructor(address _planetsManager) ERC20("DarkForest", "NART") {
        require(
            _planetsManager != address(0),
            "Implementations: PlanetsManager is not set"
        );
        planetsManager = _planetsManager;
        _mint(owner(), 42_000_000_000 * (10**18));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (address(walletObserver) != address(0)) {
            walletObserver.beforeTokenTransfer(_msgSender(), from, to, amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fees;
        uint256 devFees;
        uint256 nftFees;
        uint256 treasuryFees;
        if(to == liquidityPoolManager.getPair()) {
            devFees = amount.mul(sellDevFee).div(100);
            nftFees = amount.mul(sellNftFee).div(100);
            treasuryFees = amount.mul(sellTreasuryFee).div(100);
            amount = amount.sub(devFees).sub(nftFees).sub(treasuryFees);
            address treasuryAddress = liquidityPoolManager.getTreasuryAddress();
            super._transfer(from, treasuryAddress, treasuryFees);
            super._transfer(from, devWallet, devFees);
            super._transfer(from, nftWallet, nftFees);
        } else {
            fees = amount.mul(transferFee).div(100);
            amount = amount.sub(fees);
        }

        super._transfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (address(liquidityPoolManager) != address(0)) {
            liquidityPoolManager.afterTokenTransfer(_msgSender());
        }
    }

    function accountBurn(address account, uint256 amount)
        external
        onlyPlanetsManager
    {
        // Note: _burn will call _beforeTokenTransfer which will ensure no denied addresses can create cargos
        // effectively protecting PlanetsManager from suspicious addresses
        super._burn(account, amount);
    }

    function accountReward(address account, uint256 amount)
        external
        onlyPlanetsManager
    {
        require(
            address(liquidityPoolManager) != account,
            "ApeUniverse: Use liquidityReward to reward liquidity"
        );
        super._mint(account, amount);
    }

    function liquidityReward(uint256 amount) external onlyPlanetsManager {
        require(
            address(liquidityPoolManager) != address(0),
            "ApeUniverse: LiquidityPoolManager is not set"
        );
        super._mint(address(liquidityPoolManager), amount);
    }

    function setSellDevFee(uint256 sellDevFee_) external onlyOwner {
        sellDevFee = sellDevFee_;    
    }

    function setSellNftFee(uint256 sellNftFee_) external onlyOwner {
        sellNftFee = sellNftFee_;    
    }

    function setSellTreasuryFee(uint256 sellTreasuryFee_) external onlyOwner {
        sellTreasuryFee = sellTreasuryFee_;    
    }

    function setDevWallet(address devWallet_) external onlyOwner {
        devWallet = devWallet_;
    }

    function setNftWallet(address nftWallet_) external onlyOwner {
        nftWallet = nftWallet_;
    }
    
    function setTransferFee(uint256 transferFee_) external onlyOwner {
        transferFee = transferFee_;
        emit SetTransferFee(transferFee_);       
    }
}