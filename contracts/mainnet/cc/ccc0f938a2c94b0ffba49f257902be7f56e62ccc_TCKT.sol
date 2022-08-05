/**
 *Submitted for verification at snowtrace.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

// dev.kimlikdao.eth
address constant DEV_KASASI = 0xC152e02e54CbeaCB51785C174994c2084bd9EF51;

address constant TCKT_2OF2_EXPOSURE_REPORTER = 0xCD2eD882620A6A3Aa90E65AF4C6ae2298336E305;
address constant TCKT_PRICE_FEEDER = 0xCD2eD882620A6A3Aa90E65AF4C6ae2298336E305;
address constant TCKT_ADDR = 0xcCc0A37839d58810827e02C023938d2Bc624EcCc;
address constant TCKT_DEPLOYER = 0xB71C7DB841549c44cC87A621501f8caB646476Ea;

address constant TCKO_ADDR = 0xcCc0F938A2C94b0fFBa49F257902Be7F56E62cCc;
address constant TCKO_DEPLOYER = 0xd6A717E0ED829bC951fcfe2F5b7583ED575Cdd26;

address constant TCKOK = 0x393E0fcd01379eDF18a68e842eD5AAb735415863;
address constant TCKOK_DEPLOYER = TCKO_DEPLOYER;

// kimlikdao.eth
address payable constant DAO_KASASI = payable(
    0xcCc000eFBcCca45cb11835C93c1a28c1C8779cCc
);
address constant DAO_KASASI_DEPLOYER = 0xD0C8568eb0E0f99786882511eD24762dCA447E06;

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

IERC20Permit constant FRAX = IERC20Permit(
    0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64
);

IERC20Permit constant MIM = IERC20Permit(
    0x130966628846BFd36ff31a822705796e8cb8C18D
);

IERC20Permit constant TCKO = IERC20Permit(TCKO_ADDR);

IERC20 constant TRYB = IERC20(0x564A341Df6C126f90cf3ECB92120FD7190ACb401);

IERC20Permit constant USDC = IERC20Permit(
    0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
);

IERC20Permit constant USDD = IERC20Permit(
    0xcf799767d366d789e8B446981C2D578E241fa25c
);

IERC20Permit constant USDT = IERC20Permit(
    0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7
);

IERC20Permit constant YUSD = IERC20Permit(
    0x111111111111ed1D73f860F57b2798b683f2d325
);

/**
 * @title KimlikDAO TCKT contract.
 * @author KimlikDAO
 */
contract TCKT is IERC721 {
    event RevokerAssignment(
        address indexed owner,
        address indexed revoker,
        uint256 weight
    );
    /// @notice When a TCKT holder gets their wallet private key exposed
    /// they can either revoke it themselves, or use social revoking.
    /// If they are unable to do either, an exposure report needs to be
    /// filed through a KimlikAŞ authentication.
    event ExposureReport(bytes32 indexed humanID, uint256 timestamp);
    event PriceChange(address indexed token, uint256 price);

    mapping(address => uint256) public handles;
    mapping(address => mapping(address => uint256)) public revokerWeight;
    mapping(address => uint256) public revokesRemaining;

    /// Maps a HumanID("KimlikDAO:TCKT:exposure") to a reported exposure
    /// timestamp, or zero if no exposure has been reported.
    mapping(bytes32 => uint256) public exposureReported;

    mapping(address => uint256) public priceIn;
    uint256 private revokerlessPremium = (3 << 128) | uint256(2);

    function name() external pure override returns (string memory) {
        return unicode"Test TC Kimlik Tokeni (Geçersiz)";
    }

    function symbol() external pure override returns (string memory) {
        return unicode"Test TCKT (Geçersiz)";
    }

    /**
     * @notice Returns the number of TCKTs in a given account, which is 0 or 1.
     *
     * Each wallet can hold at most one TCKT, however a new TCKT can be minted
     * to the same address at any time replacing the previous one, say after
     * a personal information change occurs.
     */
    function balanceOf(address addr) external view override returns (uint256) {
        return handles[addr] == 0 ? 0 : 1;
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
                memory out = "ipfs://Qm____________________________________________";
            out[52] = toChar[id % 58];
            id /= 58;
            for (uint256 p = 51; p > 9; --p) {
                uint256 t = id + (magic & 63);
                out[p] = toChar[t % 58];
                magic >>= 6;
                id = t / 58;
            }
            out[9] = toChar[id + 21];
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
        handles[msg.sender] = handle;
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
     * Further, KimlikDAO does daily sweeps, again using this method and
     * covering the gas fee.
     */
    function sweepNativeToken() external {
        DAO_KASASI.transfer(address(this).balance);
    }

    /**
     * @notice Creates a new TCKT with the given social revokers and collects
     * the fee in the native token.
     *
     * @param handle           IPFS handle of the persisted TCKT.
     * @param revokers         A list of pairs (weight, address), bit packed
     *                         into a single word, where the weight is a uint96
     *                         and the address is 20 bytes.
     */
    function createWithRevokers(uint256 handle, uint256[5] calldata revokers)
        external
        payable
    {
        require(msg.value >= uint128(priceIn[address(0)]));
        handles[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
        setRevokers(revokers);
    }

    // TODO(KimlikDAO-bot) We need IERC20Permit support from BiLira.

    /**
     * @param handle           IPFS handle of the persisted TCKT.
     * @param token            Contract address of a IERC20 token.
     */
    function createWithTokenPayment(uint256 handle, IERC20 token) external {
        uint256 price = priceIn[address(token)] >> 128;
        require(price > 0);
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handles[msg.sender] = handle;
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
     * @param r                random curve point x coordinate.
     * @param ss               mapped curve point of the signature.
     */
    function createWithTokenPermit(
        uint256 handle,
        uint256 deadlineAndToken,
        bytes32 r,
        uint256 ss
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
                uint8(ss >> 255) + 27,
                r,
                bytes32(ss & ((1 << 255) - 1))
            );
        }
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handles[msg.sender] = handle;
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
        handles[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
        setRevokers(revokers);
    }

    /**
     * @param handle           IPFS handle of the persisted TCKT.
     * @param revokers         A list of pairs (weight, address), bit packed
     *                         into a single word, where the weight is a uint96
     *                         and the address is 20 bytes.
     * @param deadlineAndToken Contract address of a IERC20Permit token.
     * @param r                random curve point x coordinate.
     * @param ss               mapped curve point of the signature.
     */
    function createWithRevokersWithTokenPermit(
        uint256 handle,
        uint256[5] calldata revokers,
        uint256 deadlineAndToken,
        bytes32 r,
        uint256 ss
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
                uint8(ss >> 255) + 27,
                r,
                bytes32(ss & ((1 << 255) - 1))
            );
        }
        token.transferFrom(msg.sender, DAO_KASASI, price);
        handles[msg.sender] = handle;
        emit Transfer(address(this), msg.sender, handle);
        setRevokers(revokers);
    }

    /**
     * @notice Add a HumanID("KimlikDAO:TCKT:exposure") to exposed list.
     * This can be invoked only by a 2-of-2 threshold signature of
     * KimlikDAO and KimlikAŞ.
     *
     * @param humanID          HumanID("KimlikDAO:TCKT:exposure") of the person
     *                         who reported the private key exposure.
     *
     * TCKT validators are expected to consider all presented TCKTs with
     * the HumanID("KimlikDAO:TCKT:exposure") equaling `humanID` and issuance
     * date earlier than `exposureReported[humanID]` as invalid.
     */
    function reportExposure(bytes32 humanID) external {
        require(msg.sender == TCKT_2OF2_EXPOSURE_REPORTER);
        exposureReported[humanID] = block.timestamp;
        emit ExposureReport(humanID, block.timestamp);
    }

    /**
     * @notice Revokes users own TCKT.
     *
     * The user has the right to delete their own TCKT any time they want using
     * this method.
     */
    function revoke() external {
        emit Transfer(msg.sender, address(this), handles[msg.sender]);
        delete handles[msg.sender];
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
        uint256 remaining = revokesRemaining[friend];
        uint256 senderWeight = revokerWeight[friend][msg.sender];

        require(senderWeight > 0);
        delete revokerWeight[friend][msg.sender];

        unchecked {
            if (senderWeight >= remaining) {
                delete revokesRemaining[friend];
                if (handles[friend] != 0) {
                    emit Transfer(friend, address(this), handles[friend]);
                    delete handles[friend];
                }
            } else revokesRemaining[friend] = remaining - senderWeight;
        }
    }

    /**
     * @notice Add a revoker or increase a revokers weight.
     *
     * @param revoker          Address who is given the revoke vote permission.
     * @param add              Additional weight given to the revoker.
     */
    function addRevoker(address revoker, uint256 add) external {
        uint256 weight = revokerWeight[msg.sender][revoker] + add;
        revokerWeight[msg.sender][revoker] = weight;
        emit RevokerAssignment(msg.sender, revoker, weight);
    }

    /**
     * @notice Reduce revoker threshold by given amount.
     *
     * @param reduce           The amount to reduce.
     */
    function reduceRevokeThreshold(uint256 reduce) external {
        revokesRemaining[msg.sender] -= reduce;
    }

    /**
     * @notice Updates TCKT prices in a given list of tokens.
     *
     * @param premium          The multiplicative price premium for getting a
     *                         TCKT without specifying a social revokers list.
     *                         The 256-bit value is understood as 128-bit
     *                         numerator followed by 128-bit denominator.
     * @param prices           A list of tuples (price, address) where the
     *                         price is an uint96 and the address is 20 bytes.
     *                         Note if the price for a token does not fit in 96
     *                         bits, the `updatePrice()` method should be used
     *                         instead.
     */
    function updatePricesBulk(uint256 premium, uint256[] calldata prices)
        external
    {
        require(msg.sender == TCKT_PRICE_FEEDER);
        unchecked {
            revokerlessPremium = premium;
            for (uint256 i = 0; i < prices.length; ++i) {
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
     * @param token            Contract address for a IERC20Permit token or the
     *                         zero address, which is understood as the native
     *                         token.
     * @param price            Price of TCKT denominated in given token.
     */
    function updatePrice(address token, uint256 price) external {
        require(msg.sender == TCKT_PRICE_FEEDER);
        unchecked {
            uint256 premium = revokerlessPremium;
            uint256 t = (price * premium) / uint128(premium);
            priceIn[token] = (t & (type(uint256).max << 128)) | price;
            emit PriceChange(token, price);
        }
    }

    function setRevokers(uint256[5] calldata revokers) internal {
        revokesRemaining[msg.sender] = revokers[0] >> 192;

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
     * Move ERC20 tokens sent to this address by accident to `DAO_KASASI`.
     */
    function rescueToken(IERC20 token) external {
        // We restrict this method to `DEV_KASASI` only, as we call a method of
        // an unkown contract, which could potentially be a security risk.
        require(msg.sender == DEV_KASASI);
        token.transfer(DAO_KASASI, token.balanceOf(address(this)));
    }
}