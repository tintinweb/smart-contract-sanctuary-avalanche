// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

// TODO(zx): Replace all instances of SafeMath with OZ implementation
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0\
pragma solidity 0.7.5;

import {SafeMath} from "../libraries/SafeMath.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract MHUBCirculatingSupplyContract {
    using SafeMath for uint;

    bool public isInitialized;

    address public MHUB;
    address public owner;
    address[] public nonCirculatingMHUBAddresses;

    constructor( address _owner ) {
        owner = _owner;
    }

    function initialize( address _mhub ) external returns ( bool ) {
        require( msg.sender == owner, "caller is not owner" );
        require( isInitialized == false );

        MHUB = _mhub;

        isInitialized = true;

        return true;
    }

    function MHUBCirculatingSupply() external view returns ( uint ) {
        uint _totalSupply = IERC20( MHUB ).totalSupply();

        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingMHUB() );

        return _circulatingSupply;
    }

    function getNonCirculatingMHUB() public view returns ( uint ) {
        uint _nonCirculatingMHUB;

        for( uint i=0; i < nonCirculatingMHUBAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingMHUB = _nonCirculatingMHUB.add( IERC20( MHUB ).balanceOf( nonCirculatingMHUBAddresses[i] ) );
        }

        return _nonCirculatingMHUB;
    }

    function setNonCirculatingMHUBAddresses( address[] calldata _nonCirculatingAddresses ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );
        nonCirculatingMHUBAddresses = _nonCirculatingAddresses;

        return true;
    }

    function transferOwnership( address _owner ) external returns ( bool ) {
        require( msg.sender == owner, "Sender is not owner" );

        owner = _owner;

        return true;
    }
}