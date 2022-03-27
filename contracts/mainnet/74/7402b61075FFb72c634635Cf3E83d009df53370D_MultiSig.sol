/**
 *Submitted for verification at snowtrace.io on 2022-03-27
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract MultiSig is Ownable {
    using SafeMath for uint256;

    string public messageToSign;
    address public addressToSign;
    uint256 public amountToSign;
    address public tokenAddress;
    address public FANAddress;
    address public QIAddress;
    address public QIANGAddress;
    address public ZHENAddress;
    address public HAOAddress;
    address public BAIAddress;
    address[] signers;
    mapping (address=>string) namedAddress;
    mapping (address=>uint8) voted;
    uint8[] public isActive;

    function setAddress(
        address addr1,
        address addr2,
        address addr3,
        address addr4,
        address addr5,
        address addr6
    ) public onlyOwner {
        FANAddress = addr1;
        QIAddress = addr2;
        QIANGAddress = addr3;
        ZHENAddress = addr4;
        HAOAddress = addr5;
        BAIAddress = addr6;
    }

    function resetVote() internal {
        for (uint256 i=0;i<signers.length;i++) {
            voted[signers[i]] = 0;
        }
    }
    function vote(bool agree) public onlySigner(msg.sender){
        if (agree){
            voted[msg.sender] = 1;
        } else {
            voted[msg.sender] = 0;
        }
    }

    function getActive() public view returns(uint8[] memory) {
        return isActive;
    }
    function setTokenAddress(address token) public onlyOwner {
        tokenAddress = token;
    }

    function Propose(address to, uint256 amount) public  {
        resetVote();
        string memory text = " proposed transfer ";
        string memory textTo = " to ";
        addressToSign = to;
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) {
            amountToSign = balance;
        } else {
            require(balance >= amount, "Not enough balance");
            amountToSign = amount;
        }
        messageToSign = string(
            abi.encodePacked(
                namedAddress[msg.sender],
                text,
                Strings.toHexString(amountToSign),
                textTo,
                Strings.toHexString(uint256(uint160(to)), 20)
            )
        );
    }

    function Execute() public onlyOwner {
        uint8 sumOf = 0;
        for (uint8 i=0;i<signers.length;i++) {
            sumOf += voted[signers[i]];
            isActive.push(voted[signers[i]]);

        }
        require(sumOf >= signers.length / 2, "Not enough active nodes");
        IERC20(tokenAddress).transfer(addressToSign, amountToSign);
    }

    function isSigner(address _signer) public view returns(bool) {
        for (uint8 i=0;i<signers.length;i++) {
            if (_signer == signers[i]) {
                return true;
            }
        }
        return false;
    }

    modifier onlySigner(address _signer)  {
        require(isSigner(_signer), "caller is not signer");
        _;
    }

    function setNamedAddress(string memory name) public onlySigner(msg.sender) {
        namedAddress[msg.sender] = name;
    }

    function addNamedAddress(address user, string memory name) public onlyOwner {
        namedAddress[user] = name;
    }

    constructor(
        address[] memory _addresses
    ) {
        signers = _addresses;
        tokenAddress = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
        for(uint256 i=0;i<_addresses.length;i++) {
            if (i==0) {
                FANAddress = _addresses[0];
                namedAddress[FANAddress] = "FAN";
            }else if (i==1){
                QIAddress = _addresses[1];
                namedAddress[QIAddress] = "QI";
            }else if(i==2) {
                QIANGAddress = _addresses[2];
                namedAddress[QIANGAddress] = "QIANG";
            }else if(i==3) {
                ZHENAddress = _addresses[3];
                namedAddress[ZHENAddress] = "ZHEN";
            }else if(i==4) {
                HAOAddress =  _addresses[4];
                namedAddress[HAOAddress] = "HAO";
            }else if(i==5) {
                BAIAddress =  _addresses[5];
                namedAddress[BAIAddress] = "BAI";
            }
        }
    }
}