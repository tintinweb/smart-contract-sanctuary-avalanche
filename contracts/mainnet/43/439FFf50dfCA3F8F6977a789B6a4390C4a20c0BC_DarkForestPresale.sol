// SPDX-License-Identifier: UNLICENSED
/*
    ██████╗  █████╗ ██████╗ ██╗  ██╗    ███████╗ ██████╗ ██████╗ ███████╗███████╗████████╗
    ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝    ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██║  ██║███████║██████╔╝█████╔╝     █████╗  ██║   ██║██████╔╝█████╗  ███████╗   ██║   
    ██║  ██║██╔══██║██╔══██╗██╔═██╗     ██╔══╝  ██║   ██║██╔══██╗██╔══╝  ╚════██║   ██║   
    ██████╔╝██║  ██║██║  ██║██║  ██╗    ██║     ╚██████╔╝██║  ██║███████╗███████║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝       
    PRESALE                                                                                  
*/

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./OwnerRecovery.sol";
import "./LiquidityPoolManagerImplementationPointer.sol";
import "./WalletObserverImplementationPointer.sol";

contract DarkForestPresale is
    ERC20,
    ERC20Burnable,
    Ownable,
    OwnerRecovery,
    LiquidityPoolManagerImplementationPointer,
    WalletObserverImplementationPointer
{
    using SafeMath for uint256;
    address public immutable planetsManager;

    uint256 public transferFee = 2;

    event SetTransferFee(uint256 newTransferFee);

    modifier onlyPlanetsManager() {
        address sender = _msgSender();
        require(
            sender == address(planetsManager),
            "Implementations: Not PlanetsManager"
        );
        _;
    }

    constructor(address _planetsManager) ERC20("DarkForestPresale", "DF") {
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
        fees = amount.mul(transferFee).div(100);
        amount = amount.sub(fees);
        super._transfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
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
            "DarkForest: Use liquidityReward to reward liquidity"
        );
        super._mint(account, amount);
    }

    function liquidityReward(uint256 amount) external onlyPlanetsManager {
        require(
            address(liquidityPoolManager) != address(0),
            "DarkForest: LiquidityPoolManager is not set"
        );
        super._mint(address(liquidityPoolManager), amount);
    }

    function setTransferFee(uint256 transferFee_) external onlyOwner {
        transferFee = transferFee_;
        emit SetTransferFee(transferFee_);       
    }
}