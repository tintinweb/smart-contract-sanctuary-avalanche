//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "../interfaces/IERC20.sol";
import "./Address.sol";

error Failed();
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) public {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) public {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "failed");
        if (returndata.length > 0) {   
            if(!(abi.decode(returndata, (bool)))) { revert Failed();}
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

error InsufficientBalance();
error UnableToSendValue();
error CallToNonContract();
error StaticCallToNonContract();
error DelegateCallToNonContract();
library Address {
    
    function isContract(address account) public view returns (bool) {
        
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) public {
        if(address(this).balance < amount) { revert InsufficientBalance();}

        (bool success, ) = recipient.call{value: amount}("");
        if(!success) { revert UnableToSendValue();}
    }

    
    function functionCall(address target, bytes memory data) public returns (bytes memory) {
        return functionCall(target, data, "low-level call failed");
    }

    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) public returns (bytes memory) {
        return functionCallWithValue(target, data, value, "low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) public returns (bytes memory) {
        if(address(this).balance < value){ revert InsufficientBalance();}
        if(!isContract(target)) { revert CallToNonContract();}

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) public view returns (bytes memory) {
        return functionStaticCall(target, data, "low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public view returns (bytes memory) {
        if(!isContract(target)) { revert StaticCallToNonContract();}

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) public returns (bytes memory) {
        return functionDelegateCall(target, data, "low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) public returns (bytes memory) {
        if(!isContract(target)) { revert DelegateCallToNonContract();}

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) public pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
interface IERC20 {

  function balanceOf(address who) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
}