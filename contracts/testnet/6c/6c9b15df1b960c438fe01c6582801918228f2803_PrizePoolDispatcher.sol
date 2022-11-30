//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


import "../../../abstract/ADispatcher.sol";
import "../../../interfaces/IDispatcherStorage.sol";


contract PrizePoolDispatcher is ADispatcher {
    /// @dev need to set hardcoded address after DispatherStorage deployed
    function _getTarget() internal override view returns (address) {
        IDispatcherStorage dStorage = IDispatcherStorage(0x088E7C3821AD0C8fC214bd3f51199828A29D0ea8);
        return dStorage.getAddress();
    }
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;



interface IDispatcherStorage {
    function getAddress() external view returns(address);
    function setAddress(address lib) external;
}

//SPDX-License-Identifier: UNLICENSED


pragma solidity >0.8.0 <0.9.0;


abstract contract ADispatcher {
    function _getTarget() internal virtual view returns (address);

    function _fallback() internal {
        address target = _getTarget();

        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(sub(gas(), 10000), target, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch result
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }

    fallback() external {
        _fallback();
    }
}