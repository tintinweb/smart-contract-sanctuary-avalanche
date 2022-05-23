// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Proof.sol";
import "./MarketPojo.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MarketCore is MarketPojo{

    // 0 订单不存在， 1 订单进行中(并经过签名者授权)， 2 订单已经完成， 3 订单取消  0-10属于上传订单，10-20 购买部分  20 - 30属于提供offer给心意玩家的nft
    
    mapping(address => mapping(bytes32 => bool)) public orderState;
    mapping(bytes32 => bytes) public orderInfo;

  //  function hashOrder(Order memory order ) internal pure returns (bytes32 hash){    
  //   return keccak256(abi.encodePacked(Proof.strConcat(Proof.addrToStr(order.callTarget),Proof.addrToStr(order.maker),
  //   Strings.toString(order.salt),Strings.toString(order.listingTime),Strings.toString(order.expirationTime),
  //   Proof.bytesToStr(order.selctor),Proof.bytesToStr(order.callData))));
  //  }


 function toEthSignedMessageHash(bytes32 hash) external pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    
    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

  function checkOrderPermissions(bytes32 hash, address signer, bytes calldata signature) public view returns(bool){
         return SignatureChecker.isValidSignatureNow(signer,hash,signature);
    }

   function hashOrder( 
        address maker,  // order maker address
        uint256 salt,
        uint listingTime,
        uint expirationTime)   //data 中要求对方订单 需要支付多少
        public pure returns (bytes32 hash){    
    return keccak256(abi.encodePacked(Proof.strConcat(Proof.addrToStr(maker),
    Strings.toString(salt),Strings.toString(listingTime),Strings.toString(expirationTime))));
   }

  function testHash(string memory data)public view returns(bytes32) {
      return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(data)));
  }

     function checkOrderPermissions2(bytes32 hash, address signer, bytes calldata signature) external view returns(bool){
         return SignatureChecker.isValidSignatureNow(signer,hash,signature);
    }

    function hashSignature(bytes32 hashOrder, bytes memory data, bytes memory orderData, address target) internal pure returns(bytes32){
      return  ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(Proof.strConcat(Proof.bytes32ToString(hashOrder), Proof.bytesToStr(data),Proof.bytesToStr(orderData), Proof.addrToStr(target)))));
    }
  

    function hashSignature2(bytes32 hashOrder, bytes memory data, bytes memory orderData, address target) external pure returns(bytes32){
      return  ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(Proof.strConcat(Proof.bytes32ToString(hashOrder), Proof.bytesToStr(data),Proof.bytesToStr(orderData), Proof.addrToStr(target)))));
    }
  
  
    function testString2(bytes32 hashOrder, bytes memory data,bytes memory orderData, address target) external pure returns(string memory){
      return Proof.strConcat(Proof.bytes32ToString(hashOrder), Proof.bytesToStr( Proof.getBehindBytes(data)),Proof.bytesToStr(orderData), Proof.addrToStr(target) );
    }
  
   function testString( 
        address maker,  // order maker address
        uint256 salt,
        uint listingTime,
        uint expirationTime)   //data 中要求对方订单 需要支付多少
        public pure returns (string memory hash){    
    return Proof.strConcat(Proof.addrToStr(maker),
    Strings.toString(salt),Strings.toString(listingTime),Strings.toString(expirationTime));
   }
   

  //  function hashSignature(bytes memory hashOrder ,bytes memory data,address target) external pure returns(bytes memory){
  //    return keccak256(abi.encodePacked(Proof.strConcat(Proof.bytesToStr(hashOrder),Proof.bytesToStr(data)),Proof.addrToStr(target)));
  //  }

  //  function  hashSignature(bytes hashOrder ,bytes memory data,address target) external pure returns(bytes memory){
  //    return keccak256(abi.encodePacked(Proof.bytesToStr(hashOrder)));
  //  }


    bytes4 public constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 public constant transferFrom_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 public constant Erc721_transferFrom_SELECTOR = bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256)')));



     function testHashErc20(address from,address to,uint256 value) public view returns(bytes memory){
    return abi.encodeWithSelector(transferFrom_SELECTOR,from,to,value);
  }


    //上架思路，不需要消耗gas费用，如果是项目方上架，可以让项目方打资产到一个代理合约中，然后那个合约授权给市场合约
    //如果不这样做，就得资产合约授权给市场合约，那样风险太大，如果市场合约被盗，资产合约会受印象
    // function commitOrder(Order memory order,bytes calldata signature) external {     
    //     bytes32 hash = hashOrder(order);
    //     Proof.checkOrderPermissions(hash,msg.sender,signature);
    //     emit commitOrderEvent(order.callTarget,order.maker,order.salt,order.selctor
    //     ,order.callData,order.listingTime,order.expirationTime);
    // }

    function commitOrder(  
        address maker,  // order maker address
        uint256 salt,
        uint listingTime,
        uint expirationTime,
        address target,  //要检查订单参数
        bytes memory data, //tokenAddress, from ,to
        bytes memory orderData,
        bytes calldata signature) external {
        bytes32 orderHash = hashOrder(maker,salt,listingTime,expirationTime);
        bytes32 signatureHash = hashSignature(orderHash,Proof.getBehindBytes(data),orderData,target);
        require(Proof.checkOrderPermissions(signatureHash,maker,signature) == true,"Please provide correct proof");
        orderState[msg.sender][orderHash] = true;
        orderInfo[orderHash] = data;  // 可以改成签名
        emit commitOrderEvent(maker,salt,listingTime,expirationTime,target,data,orderData,signature);
    }


  //   //firstcallData 跟 secondcallData是在订单匹配的时候才产生的 且前48个字节不能出现作假的情况，只能运行一个函数选择器，一个地址
  //    fisrtCallData 跟 secondCallData 的from 地址可以进行一个排序进行验证,然后再是order maker 顺序的一个排序，必须要匹配上
  // 后面要抽象成core 核心合约 , 把签名放在order额外数据中  通过订单hash生产需要的call跟对方调用的call
  // 比如 firstCallData: 把erc721资产转走  secondCallData:  把erc20资产转走
  
    function orderMatch(bytes32 firstOrderHash,address firstsinger, bytes memory firstcallData,address firstcallTarget,address secondCallTarget,bytes memory secondcallData, bytes memory signatures,bytes memory orderData,
    address secondsinger, bytes32 secondOrderHash) external {
            
            (bytes memory firstSignature, bytes memory secondSignature) = abi.decode(signatures, (bytes, bytes));

            //还需要验证from 跟函数选择器
            bytes32 firstSignatureHash = hashSignature(firstOrderHash,Proof.getBehindBytes(secondcallData),orderData,secondCallTarget);
            bytes32 seccondSignatureHash = hashSignature(secondOrderHash,Proof.getBehindBytes(firstcallData),orderData,firstcallTarget);

            require( Proof.checkOrderPermissions(firstSignatureHash,firstsinger,firstSignature) == true, "Please provide correct proof" );            
            require( Proof.checkOrderPermissions(seccondSignatureHash,secondsinger,secondSignature) == true, "Please provide correct proof" );            

            executeCall(firstcallTarget,firstcallData);
            executeCall(secondCallTarget,secondcallData);

            //然后计算一个匹配完成后的调用的集合，说明这个已经完成了
            //然后发送事件
    }


    function encodeSignature(bytes memory firstSignature, bytes memory secondSignature) external view returns(bytes memory signature){
        return abi.encode(firstSignature,secondSignature);
    }

    
    function decodeSignature(bytes memory signatures) external view returns(bytes memory,bytes memory){
          (bytes memory firstSignature, bytes memory secondSignature) = abi.decode(signatures, (bytes, bytes));
          return (firstSignature,secondSignature);
    }

    //如果是erc721的value就是0, 否则就是erc1155
    function endeOrderInfo(address tokenAddress, uint256 tokenId, uint256 value) external view returns(bytes memory){
      return abi.encode(tokenAddress,tokenId,value);
    }

    function decodeOrderInfo(bytes memory data) public view returns(address tokenAddress, uint256 tokenId, uint256 value)  {
      return abi.decode(data, (address, uint256,uint256));
    }

    function testDecode(bytes memory data) public view returns(uint256 , string memory) {
      return abi.decode(data,(uint256,string));
    } 

    // function orderMatch(Order calldata firstOrder,bytes calldata firstSignature,Order calldata secondOrder,bytes calldata secondSignature) external {
    //         bytes32 firstHash = hashOrder(firstOrder);
    //         Proof.checkOrderPermissions(firstHash,msg.sender,firstSignature);            
    //         bytes32 secondHash = hashOrder(secondOrder);
    //         Proof.checkOrderPermissions(secondHash,msg.sender,secondSignature);
    //         require(firstHash != secondHash,"match failed");

    //         //判断 firstCall跟secondCall 是符合要求的 并且是由我们系统正确生成的，如果玩家进行修改呢，这该怎么办
    //         executeCall(firstOrder.callTarget,firstOrder.callData);
    //         executeCall(secondOrder.callTarget,secondOrder.callData);                      
    // }

    function executeCall(address callTarget, bytes memory callData) public {
        (bool success, bytes memory data) = callTarget.call(callData);
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'cyberpop: TRANSFER_FAILED'); 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import  "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MarketPojo.sol";

library Proof {


  function getBehindBytes(bytes memory data) internal pure returns(bytes memory){
    bytes memory result = new bytes(data.length-48);
    uint i = 0;
    uint j = 0;
    for(i = 48 ; i<data.length;i++){
      result[j] = data[i];
      j++;
    }
    return result;
  }

  function bytes32ToString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

 //Convert parameter types from bytes to string
  function bytesToStr(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
     }
      return string(str);
   }
  
   function strConcat(string memory str1, string memory str2,string memory str3,string memory str4)
    internal pure returns (string memory){
        bytes memory _str1 = bytes(str1);
        bytes memory _str2 = bytes(str2);
        bytes memory _str3 = bytes(str3);
        bytes memory _str4 = bytes(str4);
        string memory ret = new string(_str1.length + _str2.length + _str3.length + _str4.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _str1.length; i++)bret[k++] = _str1[i];
        for (uint i = 0; i < _str2.length; i++) bret[k++] = _str2[i];
        for (uint i = 0; i < _str3.length; i++) bret[k++] = _str3[i];
        for (uint i = 0; i < _str4.length; i++) bret[k++] = _str4[i];
        return string(ret);
   }  


  //Convert parameter types from address to string
    function addrToStr(address account) internal pure returns (string memory) {
        return bytesToStr(abi.encodePacked(account));
   }

     function checkOrderPermissions(bytes32 hash, address signer, bytes memory signature) internal view returns(bool){
         return SignatureChecker.isValidSignatureNow(signer,hash,signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract MarketPojo{

    error Unauthorized(address caller);
    error UnMatchTime(address caller,uint256 listingTime,uint256 expirationTime,uint256 timestamp);
    error exitOrder(address caller,bytes32 orderhash,uint256 orderstate);
    error IncorrectOrderStatus(address caller,bytes32 orderhash,uint256 orderstate);
  
    event commitOrderEvent(
        address maker,  // order maker address
        uint256 salt,
        uint listingTime,
        uint expirationTime,
        address target,
        bytes data,
        bytes orderData,  //还应该有个订单额外数据
        bytes signature);

    struct Order{
        address maker;  // order maker address
        uint256 salt;
        uint listingTime;
        uint expirationTime;
        bytes orderData;
    }

       struct Call {
        /* Target */
        address target;
        /* Calldata */
        bytes data;
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}