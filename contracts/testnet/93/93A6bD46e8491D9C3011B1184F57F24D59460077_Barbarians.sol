// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";


import "./OwnerRecovery.sol";
import "./LiquidityPoolManagerPointer.sol";
import "./WalletObserverPointer.sol";
import "./PyramidsManagerPointer.sol";
import "./IJoePair.sol";

contract Barbarians is
  ERC20,
  ERC20Burnable,
  Ownable,
  OwnerRecovery,
  LiquidityPoolManagerPointer,
  WalletObserverPointer,
  PyramidsManagerPointer
{
  bool private isSwapping = false;
  uint256 public buyFee;
  uint256 public sellFee;

  constructor() ERC20("The Barbarians brains", "BRB") {
    isSwapping = true;
    _mint(owner(), 333_000_000 * (10**18));
    isSwapping = false;
    setBuyFee(0); // 0% buy tax
    setSellFee(150); // 15% sell tax
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (isSwapping) return;

    isSwapping = true;

    // Require that only privileged users can add initial liquidity
    (uint112 reserves0, , ) = IJoePair(liquidityPoolManager.getPair())
      .getReserves();
    require(
      reserves0 > 0 || // LP is initialized
        !liquidityPoolManager.isPair(to) || // OR LP is not being added
        walletObserver.isExcludedFromObserver(from), // OR sender is privileged
      "Only privileged users can add initial liquidity"
    );

    if (address(walletObserver) != address(0)) {
      walletObserver.beforeTokenTransfer(_msgSender(), from, to, amount);
    }
    isSwapping = false;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    if (isSwapping) return;

    isSwapping = true;
    if (
      liquidityPoolManager.isPair(to) &&
      !walletObserver.isExcludedFromObserver(from)
    ) {
      // Sell
      uint256 tax = (amount * sellFee) / 1000;
      super._burn(to, tax);
      super._mint(address(liquidityPoolManager), tax);
    }
    if (
      liquidityPoolManager.isPair(from) &&
      !walletObserver.isExcludedFromObserver(to)
    ) {
      // Buy
      uint256 tax = (amount * buyFee) / 1000;
      super._burn(to, tax);
      super._mint(address(liquidityPoolManager), tax);
    }

    if (address(liquidityPoolManager) != address(0)) {
      liquidityPoolManager.afterTokenTransfer(_msgSender());
    }
    isSwapping = false;
  }

  function accountBurn(address account, uint256 amount)
    external
    onlyPyramidsManager
  {
    // Note: _burn will call _beforeTokenTransfer which will ensure no denied addresses can create cargos
    // effectively protecting PyramidsManager from suspicious addresses
    super._burn(account, amount);
  }

  function accountReward(address account, uint256 amount)
    external
    onlyPyramidsManager
  {
    require(
      address(liquidityPoolManager) != account,
      "Pyramid: Use liquidityReward to reward liquidity"
    );
    super._mint(account, amount);
  }

  function liquidityReward(uint256 amount) external onlyPyramidsManager {
    require(
      address(liquidityPoolManager) != address(0),
      "Pyramid: LiquidityPoolManager is not set"
    );
    super._mint(address(liquidityPoolManager), amount);
  }

  function setPyramidsManager(IPyramidsManager manager) external onlyOwner {
    require(
      address(manager) != address(0),
      "Pyramid: PyramidsManager is not set"
    );
    pyramidsManager = manager;
  }

  function setWalletObserver(IWalletObserver observer) external onlyOwner {
    require(
      address(observer) != address(0),
      "Pyramid: WalletObserver is not set"
    );
    walletObserver = observer;
  }

  function setLiquidityPoolManager(ILiquidityPoolManager manager)
    external
    onlyOwner
  {
    require(
      address(manager) != address(0),
      "Pyramid: LiquidityPoolManager is not set"
    );
    liquidityPoolManager = manager;
  }

  function setBuyFee(uint256 _fee) public onlyOwner {
    require(_fee < 1000, "Pyramid: Buy Fee cannot be 100%");
    buyFee = _fee;
  }

  function setSellFee(uint256 _fee) public onlyOwner {
    require(_fee < 1000, "Pyramid: Sell Fee cannot be 100%");
    sellFee = _fee;
  }
}