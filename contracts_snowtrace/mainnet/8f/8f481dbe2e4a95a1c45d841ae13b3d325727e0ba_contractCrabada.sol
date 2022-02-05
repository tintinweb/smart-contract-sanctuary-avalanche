/**
 *Submitted for verification at snowtrace.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721 {
    /**
     * @dev Emitted when tokenId token is transferred from from to to.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    /**
     * @dev Emitted when owner enables approved to manage the tokenId token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    /**
     * @dev Emitted when owner enables or disables (`approved`) operator to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);
    /**
     * @dev Returns the owner of the tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    /**
     * @dev Safely transfers tokenId token from from to to, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    /**
     * @dev Transfers tokenId token from from to to.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    /**
     * @dev Gives permission to to to transfer tokenId token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - tokenId must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;
    /**
     * @dev Returns the account approved for tokenId token.
     *
     * Requirements:
     *
     * - tokenId must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);
    /**
     * @dev Approve or remove operator as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The operator cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;
    /**
     * @dev Returns if the operator is allowed to manage all of the assets of owner.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
    /**@dev Safely transfers tokenId token from from to to.
     *
     * Requirements:
     *
     * - from cannot be the zero address.
     * - to cannot be the zero address.
     * - tokenId token must exist and be owned by from.
     * - If the caller is not from, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If to refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns a token ID owned by owner at a given index of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    
    /**
     * @dev Returns a token ID at a given index of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} tokenId token is transferred to this contract via {IERC721-safeTransferFrom}
     * by operator from from, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with IERC721.onERC721Received.selector.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IRouter {
    function factory() external pure returns (address);
    function WTRX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityTRX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountTRX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityTRX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountTRX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityTRXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountTRX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

interface IAVAX20 {
    function totalSupply() external view returns (uint256);
    function deposit(uint256 amount) external payable;
    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address who) external view returns (uint256);
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



interface crabada is IERC721Enumerable, IERC721Receiver{
    function balanceOf() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

interface crabadaGame is IERC721Enumerable, IERC721Receiver{
    function deposit(uint256[] memory amounts) external payable;
    function withdraw(address to, uint256[] memory crabadaIds) external payable;
    function createTeam(uint256 crabadaId1, uint256 crabadaId2, uint256 crabadaId3) external payable;
    function attack(uint256 gameId, uint256 attackTeamId) external payable;
    function settleGame(uint256 gameId) external payable;
    function startGame(uint256 teamId) external payable;
    function closeGame(uint256 gameId) external payable;
    function removeCrabadaFromTeam(uint256 teamId, uint256 position) external payable;
    function addCrabadaToTeam(uint256 teamId, uint256 position, uint256 crabadaId) external payable;
    function reinforceAttack(uint256 gameId, uint256 crabadaId, uint256 borrowPrice) external payable;
    function getStats(uint256 crabadaId) external view returns (uint16 battlePoint, uint16 timePoint);
    function getTeamInfo(uint256 teamId) external view returns (address owner, uint256 crabadaId1, uint256 crabadaId2, uint256 crabadaId3, uint16 battlePoint, uint16 timePoint, uint256 currentGameId, uint128 lockTo);
    function growtotalaugmentteamsMake(uint64 number) external payable;
}

interface crabadaAmulet{
    function deposit(uint256 pglAmount) external payable;
    function startUnstaking(uint256 amount) external payable;
    function unstake(uint256 amount) external payable;
    function claim() external payable;
}

contract contractCrabada is Ownable, IERC721Receiver{
    uint256 private _totalMinted;
    address private dev =  address(0xC8ABe72F6b86422Be83f16361589e5BaCFB28606);
    crabada c = crabada(0x1b7966315eF0259de890F38f1bDB95Acc03caCdD);
    crabadaGame g = crabadaGame(0x82a85407BD612f52577909F4A58bfC6873f14DA8);
    crabadaAmulet a = crabadaAmulet(0xD2cd7a59Aa8f8FDc68d01b1e8A95747730b927d3);
    using SafeMath for uint;
    fallback() external payable{
          
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function withdrawAVAX() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function stakeCRAM(uint256 pglAmount) onlyOwner external{
        a.deposit(pglAmount);
    }

    function unlockCRAM(uint256 pglAmount) onlyOwner external{
        a.startUnstaking(pglAmount);
    }

    function unstakeCRAM(uint256 pglAmount) onlyOwner external{
        a.unstake(pglAmount);
    }

    function addTeamSlot(uint64 number) onlyOwner external{
        g.growtotalaugmentteamsMake(number);
    }

    function claim() onlyOwner external{
        a.claim();
    }

    function approveToken(uint256 amount, address token, address addrContract) onlyOwner external{
        IAVAX20(token).approve(addrContract, amount);
    }
    
    function transferBack(uint256 id) onlyOwner external {
        c.transferFrom(address(this), msg.sender, id);
    }
    function safeTransferBack(uint256 id) onlyOwner external {
        c.safeTransferFrom(address(this), msg.sender, id);
    }
    function approvalCrabada() onlyOwner external {
        c.setApprovalForAll(0x82a85407BD612f52577909F4A58bfC6873f14DA8, true);
    }

    function depositCrab(uint256[] memory amounts) onlyOwner external{
        g.deposit(amounts);
    }

    function withdrawCrab(uint256[] memory crabadaIds) onlyOwner external{
        g.withdraw(address(this), crabadaIds);
    }

    function createTeamCrab(uint256 crabadaId1, uint256 crabadaId2, uint256 crabadaId3) onlyOwner external{
        g.createTeam(crabadaId1, crabadaId2, crabadaId3);
    }

    function attackCrab(uint256 gameId, uint256 attackTeamId) onlyOwner external{
        g.attack(gameId, attackTeamId);
    }

    function reinforceAttackCrab(uint256 gameId, uint256 crabadaId, uint256 borrowPrice) onlyOwner external{
        g.reinforceAttack(gameId, crabadaId, borrowPrice);
    }

    function returnMineForTeam(uint256 teamId) public view returns (uint256 mineId) {
        (,,,,,, uint256 currentGame,) =  g.getTeamInfo(teamId);
        return currentGame;
    }

    function settleGameCrab(uint256 gameId) onlyOwner external{
        g.settleGame(gameId);
    }

    function startGameCrab(uint256 teamId) external{
        g.startGame(teamId);
    }

    function closeGameCrab(uint256 gameId) external{
        g.closeGame(gameId);
    }

    function removeCrabadaFromTeamCrab(uint256 teamId, uint256 position) onlyOwner external{
        g.removeCrabadaFromTeam(teamId, position);
    }

    function addCrabadaToTeamCrab(uint256 teamId, uint256 position, uint256 crabadaId) onlyOwner external{
        g.addCrabadaToTeam(teamId, position, crabadaId);
    }

    function getStatsCrab(uint256 crabadaId) public view returns (uint16 battlePoint, uint16 timePoint) {
        return g.getStats(crabadaId);
    }

    function getTeamInfoCrab(uint256 teamId) public view returns (address owner, uint256 crabadaId1, uint256 crabadaId2, uint256 crabadaId3, uint16 battlePoint, uint16 timePoint, uint256 currentGameId, uint128 lockTo) {
        return g.getTeamInfo(teamId);
    }

    uint256 private _balanceWAVAX;
    
    function balanceWAVAX() public view returns (uint256) {
        return _balanceWAVAX;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IAVAX20(_address).balanceOf(address(this));
    }

    function swapTusForAVAX() external onlyOwner() {
        address pair = address(0x565d20BD591b00EAD0C927e4b6D7DD8A33b0B319);
        address tusAddr =  address(0xf693248F96Fe03422FEa95aC0aFbBBc4a8FdD172);
        address avaxAddr = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        address[] memory path = new address[](2);
        path[0] = tusAddr;
        path[1] = avaxAddr;
        uint256 balanceTus = IAVAX20(tusAddr).balanceOf(address(this));
            
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 reserveIn = path[0] == token0 ? reserve0 : reserve1;
        uint256 reserveOut = path[1] == token1 ? reserve1 : reserve0;
            

        uint256 amountOut = calculate(balanceTus, reserveIn, reserveOut);
        (uint256 amount0Out, uint256 amount1Out) = path[0] == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        
        assert(IWAVAX(path[0]).transfer(pair, balanceTus));

        IUniswapV2Pair(pair).swap(amount0Out.mul(95)/100 , amount1Out.mul(95)/100, address(this), new bytes(0));
        IUniswapV2Pair(pair).swap(amount0Out.mul(5)/100 , amount1Out.mul(5)/100, dev, new bytes(0));  
    
    }

    function withdrawToken(uint256 amount, address token) onlyOwner external{
        IAVAX20(token).transfer(msg.sender, amount.mul(95)/100);
        IAVAX20(token).transfer(dev, amount.mul(5)/100);
    }
    function withdrawTus(uint256 amount) onlyOwner external{
        address tusAddr =  address(0xf693248F96Fe03422FEa95aC0aFbBBc4a8FdD172);
        IAVAX20(tusAddr).transfer(msg.sender, amount.mul(95)/100);
        IAVAX20(tusAddr).transfer(dev, amount.mul(5)/100);
    }

    function calculate(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
}