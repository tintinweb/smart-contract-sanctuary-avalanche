// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// dev.kimlikdao.eth
// dev.kimlikdao.avax
address constant DEV_KASASI = 0xC152e02e54CbeaCB51785C174994c2084bd9EF51;

// kimlikdao.eth
// kimlikdao.avax
address payable constant DAO_KASASI = payable(
    0xcCc0106Dbc0291A0d5C97AAb42052Cb46dE60cCc
);
address constant DAO_KASASI_DEPLOYER = 0x0DabB96F2320A170ac0dDc985d105913D937ea9A;

// OYLAMA addresses
address constant OYLAMA = 0xcCc01Ec0E6Fb38Cce8b313c3c8dbfe66efD01cCc;
address constant OYLAMA_DEPLOYER = 0xD808C187Ef7D6f9999b6D9538C72E095db8c6df9;

// TCKT addresses
address constant TCKT_ADDR = 0xcCc0a9b023177549fcf26c947edb5bfD9B230cCc;
address constant TCKT_DEPLOYER = 0x305166299B002a9aDE0e907dEd848878FD2237D7;
address constant TCKT_SIGNERS = 0xcCc09aA0d174271259D093C598FCe9Feb2791cCc;
address constant TCKT_SIGNERS_DEPLOYER = 0x4DeA92Bcb2C22011217C089797A270DfA5A51d53;

// TCKO addresses
address constant TCKO_ADDR = 0xcCc0AC04C9251B74b0b30A20Fc7cb26EB62B0cCc;
address constant TCKO_DEPLOYER = 0xe7671eb60A45c905387df2b19A3803c6Be0Eb8f9;

// TCKOK addresses
address constant TCKOK = 0xcCc0c4e5d57d251551575CEd12Aba80B43fF1cCc;
address constant TCKOK_DEPLOYER = 0x2EF1308e8641a20b509DC90d0568b96359498BBa;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

uint256 constant END_TS_OFFSET = 112;

uint256 constant END_TS_MASK = uint256(type(uint64).max) << 112;

uint256 constant WITHDRAW_OFFSET = 176;

uint256 constant WITHDRAW_MASK = uint256(type(uint48).max) << 176;

interface IDIDSigners {
    /**
     * Maps a signer node address to a bit packed struct.
     *
     *`signerInfo` layout:
     * |-- color --|-- withdraw --|--  endTs --|-- deposit --|-- startTs --|
     * |--   32  --|--    48    --|--   64   --|--   48    --|--   64    --|
     */
    function signerInfo(address signer) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function balanceOf(address) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DAO_KASASI, OYLAMA, TCKT_DEPLOYER, TCKT_SIGNERS} from "interfaces/Addresses.sol";
import {IDIDSigners, END_TS_OFFSET} from "interfaces/IDIDSigners.sol";
import {IERC20, IERC20Permit} from "interfaces/IERC20Permit.sol";
import {IERC721} from "interfaces/IERC721.sol";

struct Signature {
    bytes32 r;
    uint256 yParityAndS;
}

/**
 * @title KimlikDAO TCKT contract.
 *
 * TCKT is a non-transferable ID NFT, compliant with the ERC721 interface. The
 * transfer methods revert. The token URIs point to KimlikDAO protocol ipfs
 * endpoints and the metadata contents implement ERC721Unlockable, which is
 * a novel extension of ERC721Metadata.
 *
 * @author KimlikDAO
 */
contract TCKT is IERC721 {
    mapping(address => uint256) public handleOf;

    function name() external pure override returns (string memory) {
        return "KimlikDAO Kimlik Tokeni";
    }

    function symbol() external pure override returns (string memory) {
        return "TCKT";
    }

    /**
     * @notice Returns the number of TCKTs in a given account, which is 0 or 1.
     *
     * Each wallet can hold at most one TCKT, however a new TCKT can be minted
     * to the same address at any time replacing the previous one, say after
     * a personal information change occurs.
     */
    function balanceOf(address addr) external view override returns (uint256) {
        return handleOf[addr] == 0 ? 0 : 1;
    }

    /**
     * @notice The URI of a given TCKT.
     *
     * Note the tokenID of a TCKT is simply a compact representation of its
     * IPFS handle so we simply base58 encode the array [0x12, 0x20, tokenID].
     */
    function tokenURI(uint256 id)
        external
        pure
        override
        returns (string memory)
    {
        unchecked {
            bytes memory toChar = bytes(
                "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
            );
            uint256 magic = 0x4e5a461f976ce5b9229582822e96e6269e5d6f18a5960a04480c6825748ba04;
            bytes
                memory out = "https://ipfs.kimlikdao.org/ipfs/Qm____________________________________________";
            out[77] = toChar[id % 58];
            id /= 58;
            for (uint256 p = 76; p > 34; --p) {
                uint256 t = id + (magic & 63);
                out[p] = toChar[t % 58];
                magic >>= 6;
                id = t / 58;
            }
            out[34] = toChar[id + 21];
            return string(out);
        }
    }

    /**
     * @notice Here we claim to support the full ERC721 interface so that
     * wallets recognize TCKT as an NFT, even though TCKTs transfer methods are
     * disabled.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @notice Creates a new TCKT and collects the fee in the native token.
     */
    function create(uint256 handle) external payable {
        require(msg.value >= (priceIn[address(0)] >> 128));
        handleOf[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
    }

    /**
     * @notice To minimize gas fees for TCKT buyers to the maximum extent, we
     * do not forward fees collected in the networks native token to
     * `DAO_KASASI` in each TCKT creation.
     *
     * Instead, the following method gives anyone the right to transfer the
     * entire native token balance of this contract to `DAO_KASASI` at any
     * time.
     *
     * Further, KimlikDAO does weekly sweeps, again using this method and
     * covering the gas fee.
     */
    function sweepNativeToken() external {
        DAO_KASASI.transfer(address(this).balance);
    }

    /**
     * Moves ERC20 tokens sent to this address by accident to `DAO_KASASI`.
     */
    function sweepToken(IERC20 token) external {
        token.transfer(DAO_KASASI, token.balanceOf(address(this)));
    }

    /**
     * @notice Creates a new TCKT with the given social revokers and collects
     * the fee in the native token.
     *
     * @param handle           IPFS handle of the persisted TCKT.
     * @param revokers         A list of pairs (weight, address), bit packed
     *                         into a single word, where the weight is a uint96
     *                         and the address is 20 bytes. Further, the first
     *                         word contains the revokeThreshold in the
     *                         leftmost 64 bits.
     */
    function createWithRevokers(uint256 handle, uint256[5] calldata revokers)
        external
        payable
    {
        require(msg.value >= uint128(priceIn[address(0)]));
        handleOf[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
        setRevokers(revokers);
    }

    /**
     * @param handle           IPFS handle of the persisted TCKT.
     * @param token            Contract address of a IERC20 token.
     */
    function createWithTokenPayment(uint256 handle, IERC20 token) external {
        uint256 price = priceIn[address(token)] >> 128;
        require(price > 0);
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handleOf[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
    }

    /**
     * @notice Creates a TCKT and collects the fee in the provided `token`.
     *
     * The provided token has to be IERC20Permit, in particular, it needs to
     * support approval by signature.
     *
     * Note if a price change occurs between the moment the user signs off the
     * payment and this method is called, the method call will fail as the
     * signature will be invalid. However, the price changes happen at most
     * once a week and off peak hours by an autonomous vote of TCKO holders.
     *
     * @param handle           IPFS handle of the persisted TCKT.
     * @param deadlineAndToken Contract address of a IERC20Permit token and
     *                         the timestamp until which the payment
     *                         authorization is valid for.
     * @param signature        Signature authorizing the token spend.
     */
    function createWithTokenPermit(
        uint256 handle,
        uint256 deadlineAndToken,
        Signature calldata signature
    ) external {
        IERC20Permit token = IERC20Permit(address(uint160(deadlineAndToken)));
        uint256 price = priceIn[address(token)] >> 128;
        require(price > 0);
        unchecked {
            token.permit(
                msg.sender,
                address(this),
                price,
                deadlineAndToken >> 160,
                uint8(signature.yParityAndS >> 255) + 27,
                signature.r,
                bytes32(signature.yParityAndS & ((1 << 255) - 1))
            );
        }
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handleOf[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
    }

    /**
     * @param handle           IPFS handle of the persisted TCKT.
     * @param revokers         A list of pairs (weight, address), bit packed
     *                         into a single word, where the weight is a uint96
     *                         and the address is 20 bytes.
     * @param token            Contract address of a IERC20Permit token.
     */
    function createWithRevokersWithTokenPayment(
        uint256 handle,
        uint256[5] calldata revokers,
        IERC20 token
    ) external {
        uint256 price = uint128(priceIn[address(token)]);
        require(price > 0);
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handleOf[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
        setRevokers(revokers);
    }

    /**
     * @param handle           IPFS handle of the persisted TCKT.
     * @param revokers         A list of pairs (weight, address), bit packed
     *                         into a single word, where the weight is a uint96
     *                         and the address is 20 bytes.
     * @param deadlineAndToken Contract address of a IERC20Permit token.
     * @param signature        Signature authorizing the token spend.
     */
    function createWithRevokersWithTokenPermit(
        uint256 handle,
        uint256[5] calldata revokers,
        uint256 deadlineAndToken,
        Signature calldata signature
    ) external {
        IERC20Permit token = IERC20Permit(address(uint160(deadlineAndToken)));
        uint256 price = uint128(priceIn[address(token)]);
        require(price > 0);
        unchecked {
            token.permit(
                msg.sender,
                address(this),
                price,
                deadlineAndToken >> 160,
                uint8(signature.yParityAndS >> 255) + 27,
                signature.r,
                bytes32(signature.yParityAndS & ((1 << 255) - 1))
            );
        }
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handleOf[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
        setRevokers(revokers);
    }

    // keccak256(
    //     abi.encode(
    //         keccak256(
    //             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    //         ),
    //         keccak256(bytes("TCKT")),
    //         keccak256(bytes("1")),
    //         43114,
    //         0xcCc0FD2f0D06873683aC90e8d89B79d62236BcCc
    //     )
    // );
    bytes32 public constant DOMAIN_SEPARATOR =
        0x76544360dada4b1a4aeb98d22b02240624f80ef20056cb83f74930f2ee736972;

    // keccak256("CreateFor(uint256 handle)")
    bytes32 public constant CREATE_FOR_TYPEHASH =
        0xe0b70ef26ac646b5fe42b7831a9d039e8afa04a2698e03b3321e5ca3516efe70;

    /**
     * Creates a TCKT on users behalf, covering the tx fee.
     *
     * The user has to explicitly authorize the TCKT creation with the
     * `createSig` and the token payment with the `paymentSig`.
     *
     * The gas fee is paid by the transaction sender, which can be either
     * `OYLAMA` or `TCKT_DEPLOYER`. We gate the method to these two addresses
     * since the intent of a signature request is not as clear as that of a
     * transaction and therefore a user may be tricked into creating a TCKT
     * with incorrect and invalid contents. Note this restriction is not about
     * TCKTs soundness; even if we made this method unrestricted, only the
     * account owner could have created a valid TCKT. Still, we don't want
     * users to be tricked into creating invalid TCKTs for whatever reason.
     *
     * @param handle           IPFS handle with which to create the TCKT.
     * @param createSig        Signature endorsing the TCKT creation.
     * @param deadlineAndToken The payment token and the deadline for the token
     *                         permit signature.
     * @param paymentSig       Token spend permission from the TCKT creator.
     */
    function createFor(
        uint256 handle,
        Signature calldata createSig,
        uint256 deadlineAndToken,
        Signature calldata paymentSig
    ) external {
        require(msg.sender == OYLAMA || msg.sender == TCKT_DEPLOYER);
        IERC20Permit token = IERC20Permit(address(uint160(deadlineAndToken)));
        uint256 price = priceIn[address(token)] >> 128;
        require(price > 0);
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(CREATE_FOR_TYPEHASH, handle))
                )
            );
            address signer = ecrecover(
                digest,
                uint8(createSig.yParityAndS >> 255) + 27,
                createSig.r,
                bytes32(createSig.yParityAndS & ((1 << 255) - 1))
            );
            require(signer != address(0) && handleOf[signer] == 0);
            token.permit(
                signer,
                address(this),
                price,
                deadlineAndToken >> 160,
                uint8(paymentSig.yParityAndS >> 255) + 27,
                paymentSig.r,
                bytes32(paymentSig.yParityAndS & ((1 << 255) - 1))
            );
            token.transferFrom(signer, DAO_KASASI, price);
            handleOf[signer] = handle;
            emit Transfer(address(this), signer, handle);
        }
    }

    /**
     * @param handle           Updates the contents of the TCKT with the given
     *                         IFPS handle.
     */
    function update(uint256 handle) external {
        require(handleOf[msg.sender] != 0);
        handleOf[msg.sender] = handle;
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // Revoking related fields and methods
    //
    ///////////////////////////////////////////////////////////////////////////

    event RevokerAssignment(
        address indexed owner,
        address indexed revoker,
        uint256 weight
    );

    // keccak256("RevokeFriendFor(address friend)");
    bytes32 public constant REVOKE_FRIEND_FOR_TYPEHASH =
        0xfbf2f0fb915c060d6b3043ea7458b132e0cbcd7973bac5644e78e4f17cd28b8e;

    uint256 private constant REVOKES_REMAINING_MASK =
        uint256(type(uint64).max) << 192;

    mapping(address => mapping(address => uint256)) public revokerWeight;

    // `revokeInfo` layout:
    // |-- revokesRemaining --|--   empty   --|-- lastRevokeTimestamp --|
    // |--        64        --|--    128    --|--          64         --|
    mapping(address => uint256) public revokeInfo;

    function revokesRemaining() external view returns (uint256) {
        return revokeInfo[msg.sender] >> 192;
    }

    function lastRevokeTimestamp(address addr) external view returns (uint64) {
        return uint64(revokeInfo[addr]);
    }

    function setRevokers(uint256[5] calldata revokers) internal {
        revokeInfo[msg.sender] =
            (revokeInfo[msg.sender] & type(uint64).max) |
            (revokers[0] & REVOKES_REMAINING_MASK);

        address rev0Addr = address(uint160(revokers[0]));
        uint256 rev0Weight = (revokers[0] >> 160) & type(uint32).max;
        require(rev0Addr != address(0) && rev0Addr != msg.sender);
        revokerWeight[msg.sender][rev0Addr] = rev0Weight;
        emit RevokerAssignment(msg.sender, rev0Addr, rev0Weight);

        address rev1Addr = address(uint160(revokers[1]));
        require(rev1Addr != address(0) && rev1Addr != msg.sender);
        require(rev1Addr != rev0Addr);
        revokerWeight[msg.sender][rev1Addr] = revokers[1] >> 160;
        emit RevokerAssignment(msg.sender, rev1Addr, revokers[1] >> 160);

        address rev2Addr = address(uint160(revokers[2]));
        require(rev2Addr != address(0) && rev2Addr != msg.sender);
        require(rev2Addr != rev1Addr && rev2Addr != rev0Addr);
        revokerWeight[msg.sender][rev2Addr] = revokers[2] >> 160;
        emit RevokerAssignment(msg.sender, rev2Addr, revokers[2] >> 160);

        address rev3Addr = address(uint160(revokers[3]));
        if (rev3Addr == address(0)) return;
        revokerWeight[msg.sender][rev3Addr] = revokers[3] >> 160;
        emit RevokerAssignment(msg.sender, rev3Addr, revokers[3] >> 160);

        address rev4Addr = address(uint160(revokers[4]));
        if (rev4Addr == address(0)) return;
        revokerWeight[msg.sender][rev4Addr] = revokers[4] >> 160;
        emit RevokerAssignment(msg.sender, rev4Addr, revokers[4] >> 160);
    }

    /**
     * @notice Revokes users own TCKT.
     *
     * The user has the right to delete their own TCKT at any time using this
     * method.
     */
    function revoke() external {
        emit Transfer(msg.sender, address(this), handleOf[msg.sender]);
        revokeInfo[msg.sender] = block.timestamp;
        delete handleOf[msg.sender];
    }

    /**
     * @notice Cast a "social revoke" vote to a friends TCKT.
     *
     * If a friend gave the user a nonzero social revoke weight, the user can
     * use this method to vote "social revoke" of their friends TCKT. After
     * calling this method, the users revoke weight is zeroed.
     *
     * @param friend           The wallet address of a friends TCKT.
     */
    function revokeFriend(address friend) external {
        uint256 revInfo = revokeInfo[friend];
        uint256 senderWeight = revokerWeight[friend][msg.sender] << 192;

        require(senderWeight > 0);
        delete revokerWeight[friend][msg.sender];

        unchecked {
            if (senderWeight >= (revInfo & REVOKES_REMAINING_MASK)) {
                revokeInfo[friend] = block.timestamp;
                if (handleOf[friend] != 0) {
                    emit Transfer(friend, address(this), handleOf[friend]);
                    delete handleOf[friend];
                }
            } else revokeInfo[friend] = revInfo - senderWeight;
        }
    }

    /**
     * Cast a social revoke vote for a friend on `signature` creators behalf.
     *
     * This method is particularly useful when the revoker is virtual; the TCKT
     * owner generates a private key and immediately signs a `revokeFriendFor`
     * request and e-mails the signature to a fiend. This way a friend who
     * doesn't have an EVM adress (but an email address) can cast a social
     * revoke vote.
     *
     * @param friend           Account whose TCKT will be cast a revoke vote.
     * @param signature        Signature from the revoker, authorizing a revoke
     *                         for `friend`.
     */
    function revokeFriendFor(address friend, Signature calldata signature)
        external
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(REVOKE_FRIEND_FOR_TYPEHASH, friend))
            )
        );
        unchecked {
            address revoker = ecrecover(
                digest,
                uint8(signature.yParityAndS >> 255) + 27,
                signature.r,
                bytes32(signature.yParityAndS & ((1 << 255) - 1))
            );
            require(revoker != address(0));
            uint256 revInfo = revokeInfo[friend];
            uint256 revokerW = revokerWeight[friend][revoker] << 192;
            // revokerW > 0 if and only if revokerWeight[friend][revoker] > 0.
            require(revokerW > 0);
            delete revokerWeight[friend][revoker];

            if (revokerW >= (revInfo & REVOKES_REMAINING_MASK)) {
                revokeInfo[friend] = block.timestamp;
                if (handleOf[friend] != 0) {
                    emit Transfer(friend, address(this), handleOf[friend]);
                    delete handleOf[friend];
                }
            } else revokeInfo[friend] = revInfo - revokerW;
        }
    }

    /**
     * @notice Add a revoker or increase a revokers weight.
     *
     * @param deltaAndRevoker  Address who is given the revoke vote permission.
     */
    function addRevoker(uint256 deltaAndRevoker) external {
        address revoker = address(uint160(deltaAndRevoker));
        unchecked {
            uint256 weight = revokerWeight[msg.sender][revoker] +
                (deltaAndRevoker >> 160);
            // Even after a complete compromise of the wallet private key, the
            // attacker should not be able to decrease revoker weights by
            // overflowing.
            require(weight <= type(uint64).max);
            revokerWeight[msg.sender][revoker] = weight;
            emit RevokerAssignment(msg.sender, revoker, weight);
        }
    }

    /**
     * @notice Reduce revoker threshold by given amount.
     *
     * @param reduce           The amount to reduce.
     */
    function reduceRevokeThreshold(uint256 reduce) external {
        uint256 threshold = revokeInfo[msg.sender] >> 192;
        revokeInfo[msg.sender] = (threshold - reduce) << 192; // Checked substraction
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // Price fields and methods
    //
    ///////////////////////////////////////////////////////////////////////////

    event PriceChange(address indexed token, uint256 price);

    /// The multiplicative premium for getting a TCKT wihout setting up social
    /// revoke. The initial value is 3/2, and adjusted by DAO vote.
    uint256 private revokerlessPremium = (3 << 128) | uint256(2);

    mapping(address => uint256) public priceIn;

    /**
     * @notice Updates TCKT prices in a given list of tokens.
     *
     * @param premium          The multiplicative price premium for getting a
     *                         TCKT without specifying a social revokers list.
     *                         The 256-bit value is understood as 128-bit
     *                         numerator followed by 128-bit denominator.
     * @param prices           A list of tuples (price, address) where the
     *                         price is an uint96 and the address is 20 bytes.
     */
    function updatePricesBulk(uint256 premium, uint256[5] calldata prices)
        external
    {
        require(msg.sender == OYLAMA);
        unchecked {
            revokerlessPremium = premium;
            for (uint256 i = 0; i < 5; ++i) {
                if (prices[i] == 0) break;
                address token = address(uint160(prices[i]));
                uint256 price = prices[i] >> 160;
                uint256 t = (price * premium) / uint128(premium);
                priceIn[token] = (t & (type(uint256).max << 128)) | price;
                emit PriceChange(token, price);
            }
        }
    }

    /**
     * Updates the price of a TCKT denominated in a certain token.
     *
     * @param priceAndToken    The price as a 96 bit integer, followed by the
     *                         token address for a IERC20 token or the zero
     *                         address, which is understood as the native
     *                         token.
     */
    function updatePrice(uint256 priceAndToken) external {
        require(msg.sender == OYLAMA);
        unchecked {
            address token = address(uint160(priceAndToken));
            uint256 price = priceAndToken >> 160;
            uint256 premium = revokerlessPremium;
            uint256 t = (price * premium) / uint128(premium);
            priceIn[token] = (t & (type(uint256).max << 128)) | price;
            emit PriceChange(token, price);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    //
    // Exposure report related fields and methods
    //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice When a TCKT holder gets their wallet private key exposed
    /// they can either revoke their TCKT themselves, or use social revoking.
    ///
    /// If they are unable to do either, they need to obtain a new TCKT (to a
    /// new address), with which they can file an exposure report via the
    /// `reportExposure()` method. Doing so invalidates all TCKTs they have
    /// obtained before the timestamp of their most recent TCKT.
    event ExposureReport(bytes32 indexed exposureReportID, uint256 timestamp);

    /// Maps a `exposureReportID` to a reported exposure timestamp,
    /// or zero if no exposure has been reported.
    mapping(bytes32 => uint256) public exposureReported;

    /**
     * @notice Add a `exposureReportID` to exposed list.
     * A nonce is not needed since the `exposureReported[exposureReportID]`
     * value can only be incremented.
     *
     * @param exposureReportID of the person whose wallet keys were exposed.
     * @param timestamp        of the exposureReportID signatures.
     * @param signatures       Signer node signatures for the exposureReportID.
     */
    function reportExposure(
        bytes32 exposureReportID,
        uint64 timestamp,
        Signature[3] calldata signatures
    ) external {
        unchecked {
            bytes32 digest = keccak256(
                abi.encode(
                    uint256(bytes32("\x19KimlikDAO hash\n")) | timestamp,
                    exposureReportID
                )
            );
            address[3] memory signer;
            for (uint256 i = 0; i < 3; ++i) {
                signer[i] = ecrecover(
                    digest,
                    uint8(signatures[i].yParityAndS >> 255) + 27,
                    signatures[i].r,
                    bytes32(signatures[i].yParityAndS & ((1 << 255) - 1))
                );
                uint256 info = IDIDSigners(TCKT_SIGNERS).signerInfo(signer[i]);
                uint256 endTs = uint64(info >> END_TS_OFFSET);
                require(
                    info != 0 &&
                        uint64(info) <= timestamp &&
                        (endTs == 0 || timestamp < endTs)
                );
            }
            require(
                signer[0] != signer[1] &&
                    signer[0] != signer[2] &&
                    signer[1] != signer[2]
            );
        }
        // Exposure report timestamp can only be incremented.
        require(exposureReported[exposureReportID] < timestamp);
        exposureReported[exposureReportID] = timestamp;
        emit ExposureReport(exposureReportID, timestamp);
    }
}