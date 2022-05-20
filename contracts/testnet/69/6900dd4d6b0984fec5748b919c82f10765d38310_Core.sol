import "./atoken.sol";

contract Core {
    function CallFunction(address a,bytes calldata args) public {
        a.call(args);
    }
    function DelegateCall(address a,bytes calldata args) public {
        a.delegatecall(args);
    }
    function Approve(address a, address target,uint256 amount) public {
        IAToken(a).approve(target, amount);
    }

    function Transfer(address a, address target,uint256 amount) public {
        IAToken(a).transfer(target, amount);
    }
}