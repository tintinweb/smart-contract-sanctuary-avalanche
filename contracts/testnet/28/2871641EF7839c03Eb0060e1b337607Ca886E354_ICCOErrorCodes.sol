// contracts/Conductor.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

contract ICCOErrorCodes {
    function recieveSaleToken(uint256 code) public pure returns (string memory errorString) {
        if (code == 1) {
            errorString = "wrapped address not found on this chain";
        } else if (code == 2) {
            errorString = "sale token amount too large";
        } else if (code == 3) {
            errorString = "fee-on-transfer tokens are not supported";
        }
    } 

    function createSale(uint256 code) public pure returns (string memory errorString) {
        if (code == 4) {
            errorString = "sale start must be in the future";
        } else if (code == 5) {
            errorString = "sale end must be after sale start";
        } else if (code == 6) {
            errorString = "unlock timestamp should be >= saleEnd";
        } else if (code == 7) {
            errorString = "unlock timestamp must be <= 2 years in the future";
        } else if (code == 8) {
            errorString = "timestamp too large";
        } else if (code == 9) {
            errorString = "sale token amount must be > 0";
        } else if (code == 10) {
            errorString = "must accept at least one token";
        } else if (code == 11) {
            errorString = "too many tokens";
        } else if (code == 12) {
            errorString = "minRaise must be > 0";
        } else if (code == 13) {
            errorString = "maxRaise must be >= minRaise ";
        } else if (code == 14) {
            errorString = "token must not be bytes32(0)"; 
        } else if (code == 15) {
            errorString = "recipient must not be address(0)";
        } else if (code == 16) {
            errorString = "refundRecipient must not be address(0)";
        } else if (code == 17) {
            errorString = "authority must not be address(0) or the owner";
        } else if (code == 18) {
            errorString = "insufficient value";
        } else if (code == 19) {
            errorString = "duplicate tokens not allowed"; 
        } else if (code == 20) {
            errorString = "conversion rate cannot be zero";
        } else if (code == 21) {
            errorString = "acceptedTokens.tokenAddress must not be bytes32(0)";
        } else if (code == 22) {
            errorString = "too many solana tokens";
        } 
    }
        
    function abortSaleBeforeStartTime(uint256 code) public pure returns (string memory errorString) {
        if (code == 23) {
            errorString = "sale not initiated";
        } else if (code == 24) {
            errorString = "only initiator can abort the sale early"; 
        } else if (code == 25) {
            errorString = "already sealed / aborted";
        } else if (code == 26) {
            errorString = "sale must be aborted 20 minutes before saleStart"; 
        } else if (code == 27) {
            errorString = "insufficient value";
        }
    }

    function collectContribution(uint256 code) public pure returns (string memory errorString) {
        if (code == 28) {
            errorString = "invalid emitter";
        } else if (code == 29) {
            errorString = "contribution from wrong chain id";
        } else if (code == 30) {
            errorString = "sale was aborted";
        } else if (code == 31) {
            errorString = "sale has not ended yet";
        } else if (code == 32) {
            errorString = "no contributions";
        } else if (code == 33) {
            errorString = "contribution already collected";
        }
    }

    function sealSale(uint256 code) public pure returns (string memory errorString) {     
         if (code == 34) {
            errorString = "sale not initiated";
        } else if (code == 35) {
            errorString = "already sealed / aborted";
        } else if (code == 36) {
            errorString = "missing contribution info";
        } else if (code == 37) {
            errorString = "insufficient value";
        }
    }
       
    function updateSaleAuthority(uint256 code) public pure returns (string memory errorString) {  
       if (code == 38) {
            errorString = "sale not initiated";
        } else if (code == 39) {
            errorString = "new authority must not be address(0) or the owner";
        } else if (code == 40) {
            errorString = "unauthorized authority key";
        } else if (code == 41) {
            errorString = "already sealed / aborted ";
        } 
    }  
        
    function abortBrickedSale(uint256 code) public pure returns (string memory errorString) {  
        if (code == 42) {
            errorString = "incorrect value for messageFee";
        } else if (code == 43) {
            errorString = "sale not initiated";
        } else if (code == 44) {
            errorString = "already sealed / aborted";
        } else if (code == 45) {
            errorString = "sale not old enough";
        } else if (code == 46) {
            errorString = "incorrect value";
        }
    }

    function registerChain(uint256 code) public pure returns (string memory errorString) {
        if (code == 1) {
            errorString = "address not valid";
        } else if (code == 2) {
            errorString = "chain already registerd";
        }
    }

    function upgrade(uint256 code) public pure returns (string memory errorString) {
        if (code == 3) {
            errorString = "wrong chain id";
        } 
    }

    function updateConsistencyLevel(uint256 code) public pure returns (string memory errorString) {
        if (code == 4) {
            errorString = "wrong chain id";
        } else if (code == 5) {
            errorString = "newConsistencyLevel must be > 0";
        }
    }

    function submitOwnershipTransferRequest(uint256 code) public pure returns (string memory errorString) {
        if (code == 6) {
            errorString = "wrong chain id";
        } else if (code == 7) {
            errorString = "new owner cannot be the zero address";
        }
    }

    function confirmOwnershipTransferRequest(uint256 code) public pure returns (string memory errorString) {
        if (code == 8) {
            errorString = "caller must be pendingOwner";
        }
    }

     function setup(uint256 code) public pure returns (string memory errorString) {
        if (code == 1) {
            errorString = "wormhole address must not be address(0)";
        } else if (code == 2) {
            errorString = "tokenBridge's address must not be address(0)";
        } else if (code == 3) {
            errorString = "implementation's address must not be address(0)";
        }
    }
}