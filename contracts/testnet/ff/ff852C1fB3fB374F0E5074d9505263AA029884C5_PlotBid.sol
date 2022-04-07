//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./utils/Helpers.sol";

interface IPlotCreation {
    function getLatestPlotRelease(uint256 plotID)
        external
        view
        returns (
            uint256 releaseID,
            uint256 editions,
            uint256 totalRelease,
            uint256 releaseScalar,
            uint256 releasedDate
        );
}

contract PlotBid is Helpers {
    //Interface defination
    IPlotCreation private _plotCreation;

    /**
     * @notice Bit Struct that holds bid information.
     *  bidID - Unique ID of the bid.
     *  releasedPlotID - ID of the released plot. Bidder can only bid on the released plot.
     *  bidderAddress - Public wallet address of a bidder.
     *  bidAmount - Amount of the bid.
     *  bidCurrency - Currency of the bid.
     *  bidDate - DateTime of the bid.
     */
    struct Bid {
        uint256 bidID;
        uint256 releasedPlotID;
        address bidderAddress;
        uint256 bidAmount;
        uint256 bidDate;
    }
    // Useraddress => plotID => BidID=> Bid
    mapping(address => mapping(uint256 => mapping(uint256 => Bid))) public bids;
    //bidder=>plotID=>bidID
    mapping(address => mapping(uint256 => uint256)) public plotLastBidID;
    event BidPlot(address bidder, uint256 amount);

    constructor(address _plotCreationAddress) {
        _plotCreation = IPlotCreation(_plotCreationAddress);
    }

    function addBid(
        uint256 plotID,
        uint256 bidAmount,
        bytes memory signature
    )
        public
        payable
        verifySignature(
            keccak256(abi.encodePacked(plotID, bidAmount, msg.sender)),
            signature,
            msg.sender
        )
    {
        (uint256 releaseID, , , , ) = _plotCreation.getLatestPlotRelease(
            plotID
        );
        require(releaseID > 0, "Plot doesnot exist");

        uint256 bidCount = ++plotLastBidID[msg.sender][plotID];
        bids[msg.sender][plotID][bidCount] = Bid(
            bidCount,
            releaseID,
            msg.sender,
            bidAmount,
            block.timestamp
        );
        emit BidPlot(msg.sender, bidAmount);
    }

    function getBid(address bidder, uint256 plotID)
        public
        view
        returns (Bid memory)
    {
        uint256 bidID = plotLastBidID[bidder][plotID];
        require(bidID > 0, "Bid doesnot exist");
        return bids[bidder][plotID][bidID];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title Helpers Contract
 * @dev Contains commain helper methods for other contracts
 */
contract Helpers {
    /**
     * @dev converts uint256 to string
     * @param v integer value
     */
    function uint2str(uint256 v)
        internal
        pure
        returns (string memory uintAsString)
    {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s); // memory isn't implicitly convertible to storage
        return str;
    }

    /**
     * @dev Concats two values. i.e one string and another integer
     * @param identifier Identifier as a first value to concat
     * @param index second value to concat
     */
    function concatValues(
        string memory identifier,
        string memory version,
        uint256 index
    ) internal pure returns (string memory value) {
        return
            string(
                abi.encodePacked(
                    identifier,
                    ":v",
                    version,
                    ":",
                    uint2str(index)
                )
            );
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recoverSigner(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * @dev Compare two string variables
     * @param firstValue First string variable
     * @param secondValue Second string variable
     * @return true if matches else false
     */
    function matchStrings(string memory firstValue, string memory secondValue)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((firstValue))) ==
            keccak256(abi.encodePacked((secondValue))));
    }

    /**
     * @dev Checks if signer address is valid
     * @param message message used for generating signature
     * @param signature signature after signing messages
     * @param signerAddress address of a signer
     */
    modifier verifySignature(
        bytes32 message,
        bytes memory signature,
        address signerAddress
    ) {
        require(
            recoverSigner(toEthSignedMessageHash(message), signature) ==
                signerAddress,
            "Signature error. Methods tampered with."
        );
        _;
    }
}