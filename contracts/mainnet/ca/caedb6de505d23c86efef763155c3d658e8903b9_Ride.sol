// SPDX-License-Identifier: UNLICENSED
/*
/*
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@&(,///....,***(*(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@///*,///((((((((((/,((*,.**##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@&(/((*(*,///(((((////*,.   ,/**////(//*(/#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@##%%%%%%%%#/(%%%#(/* ,/(#((((((((((((////////**%&@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@&**%%&&&&&&%%%#,,///*,**,//######(((((((//(/***,.... (@@@@@@@@@@@@@@@@@@@@@
/* @@@@@%(*.//#@@@@@@&&%%(**(/,/(/,/,*(####(/*,,*****(((###***. *%/*%@@@@@@@@@@@@@@
/* @@@@@%*      /%%(%&&@&%#(*,#%%%%%%((/.     ,***(#%&@@@@&%#(((*, .#@@@@@@@@@@@@@@
/* @@@@@@@       ,%%.#%#(#%&&&%(*#%%%&&(##*   ,****(#%&&&&&&%#(///*,..,*%@@@@@@@@@@
/* @@@@@@@..      (%%*(%#/%%%&&&@&#/#%%/.,##.  .******(####/,...    .///**,&@@@@@@@
/* @@@@@@@#**,*.  /###,(#/#%%%%%%%&%##/./((%#.   .....     ,*.  ,*(((///**.  #@@@@@
/* @@@@@@@@@&/.   ,##((%%%//#%%%%%%%%%&%%%##%(.     ,//////#%&@@@&#((//****./,&@@@@
/* @@@@@@@@@@@@@@@@@@@@@&%/*#####%%%%%##%%##&&(/##############((((////******...,@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@&((######(/,   .,#&&%*  .*((((((((/////*////*,,,,**,(@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#(((/,..    ,///##(,. ,/((((((/**,.,*****,   #@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#    .   /###((*,,,*/////////***,.,      &@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,. ,   (((((((/*......*,...,..,///%@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%    .,**////.      ,/*,/&&&@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/*
/*    Web:     https://rides.finance
 */

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./OwnerRecovery.sol";
import "./LiquidityPoolManagerImplementationPointer.sol";
import "./WalletObserverImplementationPointer.sol";

contract Ride is
    ERC20,
    ERC20Burnable,
    Ownable,
    OwnerRecovery,
    LiquidityPoolManagerImplementationPointer,
    WalletObserverImplementationPointer
{
    address public immutable garagesManager;

    modifier onlyGaragesManager() {
        address sender = _msgSender();
        require(
            sender == address(garagesManager),
            "Implementations: Not GaragesManager"
        );
        _;
    }

    constructor(address _garagesManager) ERC20("Ride", "RIDES") {
        require(
            _garagesManager != address(0),
            "Implementations: GaragesManager is not set"
        );
        garagesManager = _garagesManager;
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
        onlyGaragesManager
    {
        // Note: _burn will call _beforeTokenTransfer which will ensure no denied addresses can create cargos
        // effectively protecting GaragesManager from suspicious addresses
        super._burn(account, amount);
    }

    function accountReward(address account, uint256 amount)
        external
        onlyGaragesManager
    {
        require(
            address(liquidityPoolManager) != account,
            "Ride: Use liquidityReward to reward liquidity"
        );
        super._mint(account, amount);
    }

    function liquidityReward(uint256 amount) external onlyGaragesManager {
        require(
            address(liquidityPoolManager) != address(0),
            "Ride: LiquidityPoolManager is not set"
        );
        super._mint(address(liquidityPoolManager), amount);
    }
}