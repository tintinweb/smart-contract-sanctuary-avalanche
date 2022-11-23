// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./interfaces/IJoePair.sol";

contract TraderJoeHelper {
    struct BinData {
        uint256 id;
        uint256 reserveX;
        uint256 reserveY;
    }

    function getBins(IJoePair pair, uint24 startBin, uint24 endBin, bool swapY)
        external
        view
        returns (BinData[] memory data, uint24 i)
    {
        uint256 counter = 0;
        uint256 length = endBin - startBin;
        data = new BinData[](length);
        for (
            i = pair.findFirstNonEmptyBinId(startBin, swapY);
            i < endBin;
            i = pair.findFirstNonEmptyBinId(i, swapY)
        ) {
            (data[counter].reserveX, data[counter].reserveY) = pair.getBin(i);
            data[counter].id = i;
            unchecked{ ++counter; }
        }

        // cut array size down
        assembly {  // solhint-disable-line no-inline-assembly
            mstore(data, counter)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IJoePair {
	function findFirstNonEmptyBinId(uint24 _id, bool _swapForY) external view returns (uint24);
    function getBin(uint24 _id) external view returns (uint256 reserveX, uint256 reserveY);
}