import "./core.sol";
import "./aave.sol";
import "./atoken.sol";

contract V2Adapter {
    address public aave = 0x76cc67FF2CC77821A70ED14321111Ce381C2594D;
    function depositDelegate(address token, uint256 amount) public {
        Core(address(this)).Approve(token, address(aave), amount);
        IAaveLendingPool(aave).deposit(token, amount, address(this), 0);
    }

    function depositCall(address token, uint256 amount) public {
        Core(address(msg.sender)).Transfer(token, address(this), amount);
        IAToken(token).approve(address(aave), amount);
        IAaveLendingPool(aave).deposit(token, amount, msg.sender, 0);
    }
}