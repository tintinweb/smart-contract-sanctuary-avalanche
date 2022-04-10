/**
 *Submitted for verification at snowtrace.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT

/*
  /$$$$$$  /$$                 /$$                                     /$$$$$$$$ /$$                                                  
 /$$__  $$| $$                |__/                                    | $$_____/|__/                                                  
| $$  \__/| $$$$$$$   /$$$$$$  /$$ /$$$$$$$   /$$$$$$   /$$$$$$       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
| $$      | $$__  $$ |____  $$| $$| $$__  $$ /$$__  $$ /$$__  $$      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
| $$      | $$  \ $$  /$$$$$$$| $$| $$  \ $$| $$  \ $$| $$$$$$$$      | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
| $$    $$| $$  | $$ /$$__  $$| $$| $$  | $$| $$  | $$| $$_____/      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
|  $$$$$$/| $$  | $$|  $$$$$$$| $$| $$  | $$|  $$$$$$$|  $$$$$$$      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
 \______/ |__/  |__/ \_______/|__/|__/  |__/ \____  $$ \_______/      |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/
                                             /$$  \ $$                                                                                
                                            |  $$$$$$/                                                                                
                                             \______/        
                                                                                                                      
*/

pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// import "hardhat/console.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external returns(uint);
}
interface IERC20 {
      function balanceOf(address account) external returns (uint256);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
library RevertReasonParser {
    function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
        // We assume that revert reason is abi-encoded as Error(string)

        // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
        if (data.length >= 68 && data[0] == "\x08" && data[1] == "\xc3" && data[2] == "\x79" && data[3] == "\xa0") {
            string memory reason;
            // solhint-disable no-inline-assembly
            assembly {
                // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
                reason := add(data, 68)
            }

            require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
            return string(abi.encodePacked(prefix, "Error(", reason, ")"));
        }
        // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
        else if (data.length == 36 && data[0] == "\x4e" && data[1] == "\x48" && data[2] == "\x7b" && data[3] == "\x71") {
            uint256 code;
            // solhint-disable no-inline-assembly
            assembly {
                // 36 = 32 bytes data length + 4-byte selector
                code := mload(add(data, 36))
            }
            return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
        }

        return string(abi.encodePacked(prefix, "Unknown()"));
    }

    function _toHex(uint256 value) private pure returns(string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Caller is Ownable {
    using SafeMath for uint;

    address public feeTo;
    uint8 public fee = 1;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'ChaingeAggregationRouter: EXPIRED');
        _;
    }
    
    struct SwapInfo {
        bytes initCodeHash;
        uint swapFeenNumerator;
        uint swapFeeDenominator;
    }
    
    address public WETH;
    // factory => SwapInfo;
    mapping (address => SwapInfo) public swapInfo;

    mapping (address => bool) public controller;

    constructor(address _WETH) {
        WETH = _WETH;
        controller[0x8E5C0875C8DbC2280c9c3f138aEA52BEbd353CB4] = true;
        controller[0xD5f09A996C390b5C82937d0FC0250b8dCc4ED613] = true;
        controller[0x5B548AC8387c166081d33e57eeA2Fbe4602665D0] = true;
        controller[0x23E9d33FE708A847Aa894879BdB525cfcC9d0023] = true;
        controller[0x456325F2AC7067234dD71E01bebe032B0255e039] = true;
        controller[0x1ed64ca5a71bed2ef3cCd57704aF2bFc9e89Fe12] = true;
        controller[0xb5669c546B5FD59dbCC6E554fc7664dab9B0bfFc] = true;
        controller[0x6b67ccd11Fa8016542de569032E557C7335446c4] = true;
        controller[0x8B63CE2b2f626ac5B60A897f4C5e7A7DD4a42048] = true;
        controller[0x786FCC3362DB0A4234adC37f4a9AAD12039A927D] = true;
        controller[0x25319E26f5B099E023776cB2aE0fB303658d79D1] = true;
        controller[0x5c3cC296BD7c7BF1c206D1BBa08d8C56B726B53A] = true;
        controller[0x9b78F4c6E8Ee94e8f69c5ee8D939ec6C80dFCB19] = true;
        controller[0xdAd884F1B0d2b5ACB579FCe21A175983338C05D2] = true;
        controller[0x2748F28039032089B5dbb9A3eC7586902d88D5b9] = true;
        controller[0x86fAEcc626745E500BcE7363d899e27354e6fe5a] = true;
        controller[0xCD4dECfF64dfc24fD26104c489ed631dC73973D1] = true;
        controller[0xE330B49dA436e8D00cAd065283D0ed18C2B77eb9] = true;
        controller[0x6b67Bf3bf28E6D78Df7E6DAd7C4B64031FbeE46c] = true;
        controller[0xCC3B8436eC7aB9B07a80eC14162464598Bb99a1D] = true;
        controller[0x614516d2B1Fa8805f3f8762C15ee242d9A865334] = true;
        controller[0xE8fA064eC2Aa632CD77b2a7579A85043860AdA5F] = true;
        controller[0x181b0318759519dC924D03b218b914577C911f4c] = true;
        controller[0x4e34f5c1C6dc9Af9078Cf4078B272a13c65F005F] = true;
        controller[0x6b6c14De651E65E85e552458592903C6fFadCD52] = true;
        controller[0xF90613C69A9B8Fc7Ad8e9bEAacd1838433136e17] = true;
        controller[0xB84a1cB46E2eCf49809d02c7eB096bd3b99b56b3] = true;
        controller[0x49365DB53b5d4ad0f2F71ce1377EAA8116A4A8A7] = true;
        controller[0x809c09C1547523ad27948f58E3866a0B023c3c8A] = true;
        controller[0x8e84E73b485468166dD5632989086E3d379540A4] = true;
        controller[0xA34438514a6C13157abcF7E8477f0E42774b4Da4] = true;
        controller[0x4b7975B5924B68e2B3755DF3BABfE7d5f0C370e3] = true;
        controller[0xb693c08a0c70A676DE6E290E383B306c9f568504] = true;
        controller[0xbD6C40A48477A5bE369789737CBd655B2abc4aCA] = true;
        controller[0x3F1C9f5202E6Cc2e2Ec808037a582C441f15A46e] = true;
        controller[0x4b19A080Fe5FF15B79ADB347570A005340b80f04] = true;
        controller[0x3F21bcfc751c5ED55c7e1ed5388BDe8E2BAAD08B] = true;
        controller[0x95ac767D6778CADEE8F540A62Ed34cBA3518EdDe] = true;
        controller[0x0283531AC87826a2132e05cEF6e834A9d564F090] = true;
        controller[0xc6b336Dd1d023f946DD88c423C69Aa7FC3068e9b] = true;
        controller[0xF02cCA4385132fE5A4289461961B694B5b0CBbBa] = true;
        controller[0x607dF6914a6238EE48e7f44f15fc066077baa1f1] = true;
        controller[0x1e332ba6a1A4deCb33b4E27cCb2A6a8078b7EF9b] = true;
        controller[0xf7c5AEFf5403818b7A367BBe2581Ca2a85504489] = true;
        controller[0x95B16CAEA9d4596f372427E27fc5b52a256920A1] = true;
        controller[0xd6789b8e913965eDA88434655A9c25941E84670B] = true;
        controller[0x0dfB1599F28589A52Ddc217964009e63C82b9C62] = true;
        controller[0xD4F01e3268c7d43242708f078454EF3584bBD625] = true;
        controller[0x2CE14F8c28b9D1cfaBA2520762608A40d4B9cd3B] = true;
        controller[0x3E7aC12D5fa3C4ae7C2f57e4CFA51B5CFd01666b] = true;
        controller[0x24D67f7913DF71714865B1Ff416f9D058f33266f] = true;
        controller[0x82A489679c1e5E9c3A4f6b275BA288E6A64b5030] = true;
        controller[0xBE177a8Adb7838b62D400344a65F776Ea9253246] = true;
        controller[0xcfA97809515b8B2779BA3c325f005A181F8B0a0f] = true;
        controller[0x84c6f86E8C9c8642dad044F171Fe615281d5743f] = true;
        controller[0x829a3eFCD90d237BbCD9a021D748705ae05b188E] = true;
        controller[0x1A5Dd8A5B7310596Fb80a98ab9647473BD70E2e9] = true;
        controller[0x41bD7f7b8270f8442B8db1723237FD972BFec0DD] = true;
        controller[0x90e887cAEdC8ce7367B90D4515Fbc24f630E08a6] = true;
        controller[0x15402c9b3d8DC4DF52257278729fe733f7a35a8C] = true;
        controller[0xC973413F9139afd70f918DB03706C1AbB795787F] = true;
        controller[0x9006f03D9E29C0492015AB81d8E90907bF59979e] = true;
        controller[0x2e1C4d8E2459cb031292400ebBFCdBd92a8b60dd] = true;
        controller[0x35239716B794908230e1Da58B5f0ddD8127C72Ef] = true;
        controller[0xD35BCcb1aAe4C4B3A0Fc637e17ea3e0d5DAf4b3D] = true;
        controller[0x70896c81281a78D518840Bcb1E61d6eA4738B149] = true;
        controller[0x891218FC89150f34698240565725e6949Aeb5740] = true;
        controller[0x0e4971c156f98e4431001c12674E36481BD067a5] = true;
        controller[0xA7571cc50D0451267a99E56e680dB4357EA7eE35] = true;
        controller[0xa09e053000acfC42744Bc30D904Dc524C505cAf3] = true;
        controller[0x6AfFC78f6241823Bb13B88cb7F2D9095B5Ff4627] = true;
        controller[0x392646b8FB157298444C86cfC901542D576e6d40] = true;
        controller[0xfE0E150f3C148370293433Fc83C0680E93d179F4] = true;
        controller[0x874dE5761900Ee526950d707D8cBD4b93092E290] = true;
        controller[0x267553ed6a0091a426D8eE4D45feC99867Ab24f7] = true;
        controller[0x10c7d2a9a0eF7419Ae8B2166B721fcf9CE407A1c] = true;
        controller[0x829abA91Ea2C7F6a2c9415F73832CfbBfb173A62] = true;
        controller[0x2b19D511831230b9E07D7c3F1eBa457AFDDa4E78] = true;
        controller[0xe3DB79E99183eF820fb8f0EAA2403835ce51561C] = true;
        controller[0x7C511a82A5cD0A628f3bDC2DC358788fef7C7E35] = true;
        controller[0x151c03A6E35b132C765AD0c963ECa2BD52f65Ebc] = true;
        controller[0xBFDA926956BE9Ce3aEcEC2517d5A87d9A3447cde] = true;
        controller[0x1E9e5764C312B279192310c7887276Ff214f7b8c] = true;
        controller[0xc0796821860DC0EBB8119eD84103949Cf8F1f131] = true;
        controller[0x0E9Dd02084BfBe9e885C346cF12C1F27482c230e] = true;
        controller[0xC514dF4c3a95E991E05Ccf157aFa15e939bB9CC3] = true;
        controller[0xc7ba55B2F01C326639C9C8FAbB658791A5cD9de7] = true;
        controller[0x1b76944Bb8E6461307d014Be21046E99a1a2FF58] = true;
        controller[0xEE0b005dab416b60B533c233A86D0BD63f9f3Ec8] = true;
        controller[0x542d214C878C8aa5547fa70d6D4Ff4407505FC6A] = true;
        controller[0x6e552e0191E02C9d4fFba2408EF2FfC02B98A290] = true;
        controller[0x24c976951709a5c92103f0a515014eF995ef8575] = true;
        controller[0x62fEfb17EcBf48F56959f423Bf508280C38A86B6] = true;
        controller[0x5Ce8eaF2bBA018688AdE0f0A264F0A572E56d3a3] = true;
        controller[0x729c1ab632FaBB11bB0B5cD89B0464B7E36dAAB3] = true;
        controller[0x94aa5d1f57D43B560fE212E1e2228586734D74Cc] = true;
        controller[0xec8B658f61b255ED8BdF9718183A3a6C4969eD56] = true;
        controller[0xE74e91048b19C19d3597117173802b1497Bb6Eda] = true;
        controller[0x3EC0AAd733CeF3Bb1e89DA6985BA136B57bB9bd5] = true;
        controller[0x726840A696A6828E333A2629B493FFb307070f63] = true;
        controller[0x3067071815198C0d0C2B5cFF8262fe9Ef17F484d] = true;
        controller[0x8a667700B366AF78050D69B0d72b766cd39d4794] = true;
        controller[0x28d2bb34Cf35a032FEEdd7094499aC1Cba66ccF6] = true;
        controller[0x0a25D6c3c6D8a2b19c2CDAC918eD38B7ec4A8A49] = true;
        controller[0xD6C2bad1Cd90A0F6d956d8842750C7862F44c6d8] = true;
        controller[0x56a581CD3C4e90CA8fF11058b25Ab13998254236] = true;
        controller[0xa91200e5D702c332cD29f10D361b7294F3a9B00E] = true;
        controller[0x717F486c7AbD73Da6aB62f75E509eE3B87039cee] = true;
    }

    function setController(address account, bool allow) public onlyOwner {
        controller[account] = allow;
    }

    function makeCalls(bytes[] calldata datas, uint256 gas) public payable {
        require(controller[msg.sender] || owner() == msg.sender, "caller is not the owner or controller");

        if(msg.value > 0 ) {
             IWETH(WETH).deposit{value: msg.value}();
        }

        for (uint i = 0; i < datas.length;i++){
            (bool success, bytes memory _data) = address(this).delegatecall{gas:gas}(datas[i]);
            require(success, RevertReasonParser.parse(_data, "Swap failed: "));
        }

        uint WethBalance = IWETH(WETH).balanceOf(address(this));
        if( WethBalance > 0) {
            IWETH(WETH).withdraw(WethBalance);
        }
    }

    function setSwapInfo(address factory, bytes calldata initCodeHash, uint swapFeenNumerator, uint swapFeeDenominator ) external onlyOwner {
        swapInfo[factory] = SwapInfo(initCodeHash, swapFeenNumerator, swapFeeDenominator);
    }

    function swapExactTokensForTokens(
        address factory,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )external virtual ensure(deadline) returns (uint[] memory amounts)  {
        require(amountIn <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");

        amounts = getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, to);
    }

    function swapTokensForExactTokens(
        address factory,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ChaingeAggregationRouter: EXCESSIVE_INPUT_AMOUNT');
        require(amounts[0] <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, to);
    }

    function swapExactETHForTokens(
        address factory,
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    )
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        require(amounts[0] <=  msg.value, "insufficient minter balance");
        // IWETH(swapInfo[factory].WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(factory, amounts, path, to);
    }
    function swapTokensForExactETH(
        address factory,
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'ChaingeAggregationRouter: EXCESSIVE_INPUT_AMOUNT');

       require(amounts[0] <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, address(this));
        // IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        address factory,
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        require(amounts[0] <= IERC20(path[0]).balanceOf(msg.sender), "insufficient minter balance");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(factory, amounts, path, address(this));
        // IWETH(swapInfo[factory].WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    
    function swapETHForExactTokens(
        address factory,
        uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'ChaingeAggregationRouter: EXCESSIVE_INPUT_AMOUNT');
        
        // IWETH(swapInfo[factory].WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(factory, amounts, path, to);
        // if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }


     // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(address factory, uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ChaingeAggregationRouter: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ChaingeAggregationRouter: ZERO_ADDRESS');
    }
        // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        bytes memory initCodeHash = swapInfo[factory].initCodeHash;
        pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initCodeHash
        )))));
    }

        // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut,  uint swapFeenNumerator, uint swapFeeDenominator) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ChaingeAggregationRouter: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ChaingeAggregationRouter: INSUFFICIENT_LIQUIDITY');

        // swapFeenNumerator, swapFeeDenominator
        uint amountInWithFee = amountIn.mul(swapFeenNumerator);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(swapFeeDenominator).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut,  uint swapFeenNumerator, uint swapFeeDenominator) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'ChaingeAggregationRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ChaingeAggregationRouter: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(swapFeeDenominator);
        uint denominator = reserveOut.sub(amountOut).mul(swapFeenNumerator);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        uint swapFeenNumerator = swapInfo[factory].swapFeenNumerator;
        uint swapFeeDenominator = swapInfo[factory].swapFeeDenominator;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, swapFeenNumerator, swapFeeDenominator);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ChaingeAggregationRouter: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        uint swapFeenNumerator = swapInfo[factory].swapFeenNumerator;
        uint swapFeeDenominator = swapInfo[factory].swapFeeDenominator;

        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, swapFeenNumerator, swapFeeDenominator);
        }
    }

        // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}