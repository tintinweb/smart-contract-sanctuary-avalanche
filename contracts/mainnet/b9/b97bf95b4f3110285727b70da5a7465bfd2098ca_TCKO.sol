/**
 *Submitted for verification at snowtrace.io on 2022-05-31
*/

//SPDX-License-Identifier: MIT
//🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿

pragma solidity ^0.8.14;

/*
 * TCKO: KimlikDAO Token
 *
 * Utility
 * =======
 * 1 TCKO represents a share of all assets of the KimlikDAO treasury located
 * at `kimlikdao.eth` and 1 voting right for all treasury investment decisions.
 *
 * Any TCKO holder can redeem their share of the DAO treasury assets by
 * transferring their TCKOs to `kimlikdao.eth` on Avalanche C-chain. Such a
 * transfer burns the transferred TCKOs and sends the redeemer their share of
 * the treasury. The share of the redeemer is `sentAmount / totalSupply()`
 * fraction of all the ERC20 tokens and AVAX the treasury has.
 * Note however that the market value TCKO is ought to be higher than the
 * redemption amount, as TCKO represents a share in KimlikDAO's future cash
 * flow as well. The redemption amount is merely a lower bound on TCKOs value
 * and this functionality should only be used as a last resort.
 *
 * Investment decisions are made through proposals to swap some treasury assets
 * to other assets on a DEX, which are voted on-chain by all TCKO holders.
 *
 * Combined with a TCKT, TCKO gives a person voting rights for non-financial
 * decisions of KimlikDAO also; however in such decisions the voting weight is
 * not necessarily proportional to one's TCKO holdings (guaranteed to be
 * sub-linear in one's TCKO holdings). Since TCKT is an ID token, it allows us
 * to enforce the sub-linear voting weight.
 *
 * Supply Cap
 * ==========
 * There will be 100M TCKOs minted ever, distributed over 5 rounds of 20M TCKOs
 * each.
 *
 * Inside the contract, we keep track of another variable `distroStage`, which
 * ranges between 0 and 7 inclusive, and can be mapped to the `distroRound` as
 * follows.
 *
 *   distroRound :=  distroStage / 2 + (distroStage == 0 ? 1 : 2)
 *
 * The `distroStage` has 8 values, corresponding to the beginning and the
 * ending of the 5 distribution rounds; see `DistroStage` enum.
 * The `distroStage` can only be incremented, and only by `dev.kimlikdao.eth`
 * by calling the `incrementDistroStage()` method of this contract.
 *
 * In distribution rounds 3 and 4, 20M TCKOs are minted to `kimlikdao.eth`
 * automatically, to be sold / distributed to the public by `kimlikdao.eth`.
 * In the rest of the rounds (1, 2, and 5), the minting is manually managed
 * by `dev.kimlikdao.eth`, however the total minted TCKOs is capped at
 * distroRound * 20M TCKOs at any moment during the lifetime of the contract.
 * Additionally, in round 2, the `presale2Contract` is also given minting
 * rights, again respecting the 20M * distroRound supply cap.
 *
 * Since the `releaseRound` cannot be incremented beyond 5, this ensures that
 * there can be at most 100M TCKOs minted.
 *
 * Locking
 * =======
 * Each mint to external parties results in some unlocked and some locked
 * TCKOs, and the ratio is fixed globally. Only the 40M TCKOs minted to
 * `kimlikdao.eth` across rounds 3 and 4 are fully unlocked.
 *
 * The unlocking schedule is as follows:
 *
 *  /------------------------------------
 *  | Minted in round  |  Unlock time
 *  |------------------------------------
 *  |   Round 1        |  End of round 3
 *  |   Round 2        |  End of round 4
 *  |   Round 3        |  Unlocked
 *  |   Round 4        |  Unlocked
 *  |   Round 5        |  Year 2028
 *
 * Define:
 *   (D1) distroRound := distroStage / 2 + (distroStage == 0 ? 1 : 2)
 *
 * Facts:
 *   (F1) 1 <= distroRound <= 5
 *
 * Invariants:
 *   (I1) supplyCap() <= 20M * 1M * distroRound
 *   (I2) sum_a(balanceOf[a]) == totalSupply <= totalMinted
 *   (I3) totalMinted <= supplyCap()
 *   (I4) balanceOf[KILITLI_TCKO] == KilitliTCKO.totalSupply()
 *
 * (F1) follows because DistroStage has 8 values and floor(7/2) + 2 = 5.
 * Combining (F1) and (I1) gives the 100M TCKO supply cap.
 */

// dev.kimlikdao.eth
address constant DEV_KASASI = 0xC152e02e54CbeaCB51785C174994c2084bd9EF51;

// kimlikdao.eth
address payable constant DAO_KASASI = payable(
    0xd2BF9043A2Ad0Bd7D0BA48Aed57BD923f9558b05
);

address constant KILITLI_TCKO = 0x7B9be0B5F38Ea789e23926CB8F49Da041671aCac;

enum DistroStage {
    Presale1,
    Presale2,
    DAOSaleStart,
    DAOSaleEnd,
    DAOAMMStart,
    Presale2Unlock,
    FinalMint,
    FinalUnlock
}

interface HasDistroStage {
    function distroStage() external view returns (DistroStage);
}

interface IDAOKasasi {
    function redeem(
        address payable redeemer,
        uint256 burnedTokens,
        uint256 totalTokens
    ) external;

    function distroStageUpdated(DistroStage) external;

    function versionHash() external pure returns (bytes32);

    function migrateToCode(address codeAddress) external;
}

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

/**
 * @title TCKO-k: KimlikDAO Locked Token
 *
 * A KilitliTCKO represents a locked TCKO, which cannot be redeemed or
 * transferred, but turns into a TCKO automatically at the prescribed
 * `DistroStage`.
 *
 * The unlocking is triggered by the `DEV_KASASI` using the `unlockAllEven()`
 * or `unlockAllOdd()` methods and the gas is paid by KimlikDAO; the user does
 * not need to take any action to unlock their tokens.
 *
 * Invariants:
 *   (I1) sum_a(balances[a][0]) + sum_a(balances[a][1]) == totalSupply
 *   (I2) totalSupply == TCKO.balanceOf(address(this))
 *   (I3) balance[a][0] > 0 => accounts0.includes(a)
 *   (I4) balance[a][1] > 0 => accounts1.includes(a)
 */
contract KilitliTCKO is IERC20 {
    uint256 public override totalSupply;

    IERC20 private tcko;
    mapping(address => uint128[2]) private balances;
    address[] private accounts0;
    // Split Presale2 accounts out, so that even if we can't unlock them in
    // one shot due to gas limit, we can still unlock others in one shot.
    address[] private accounts1;

    function name() external pure override returns (string memory) {
        return "KimlikDAO Kilitli Tokeni";
    }

    function symbol() external pure override returns (string memory) {
        return "TCKO-k";
    }

    function decimals() external pure override returns (uint8) {
        return 6;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        unchecked {
            return balances[account][0] + balances[account][1];
        }
    }

    function transfer(address to, uint256) external override returns (bool) {
        if (to == address(this)) return unlock(msg.sender);
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        return false;
    }

    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return false;
    }

    function mint(
        address account,
        uint256 amount,
        DistroStage stage
    ) external {
        require(msg.sender == address(tcko));
        unchecked {
            if (uint256(stage) & 1 == 0) {
                accounts0.push(account);
                balances[account][0] += uint128(amount);
            } else {
                accounts1.push(account);
                balances[account][1] += uint128(amount);
            }
            totalSupply += amount;
            emit Transfer(address(this), account, amount);
        }
    }

    function unlock(address account) public returns (bool) {
        unchecked {
            DistroStage stage = HasDistroStage(address(tcko)).distroStage();
            uint256 locked = 0;
            if (
                stage >= DistroStage.DAOSaleEnd &&
                stage != DistroStage.FinalMint
            ) {
                locked += balances[account][0];
                delete balances[account][0];
            }
            if (stage >= DistroStage.Presale2Unlock) {
                locked += balances[account][1];
                delete balances[account][1];
            }
            if (locked > 0) {
                emit Transfer(account, address(this), locked);
                totalSupply -= locked;
                tcko.transfer(account, locked);
                return true;
            }
            return false;
        }
    }

    function unlockAllEven() external {
        DistroStage stage = HasDistroStage(address(tcko)).distroStage();
        require(
            stage >= DistroStage.DAOSaleEnd && stage != DistroStage.FinalMint,
            "TCKO-k: Not matured"
        );
        unchecked {
            uint256 length = accounts0.length;
            uint256 totalUnlocked;
            for (uint256 i = 0; i < length; ++i) {
                address account = accounts0[i];
                uint256 locked = balances[account][0];
                if (locked > 0) {
                    delete balances[account][0];
                    emit Transfer(account, address(this), locked);
                    totalUnlocked += locked;
                    tcko.transfer(account, locked);
                }
            }
            totalSupply -= totalUnlocked;
        }
    }

    function unlockAllOdd() external {
        require(
            HasDistroStage(address(tcko)).distroStage() >=
                DistroStage.Presale2Unlock,
            "TCKO-k: Not matured"
        );

        unchecked {
            uint256 length = accounts1.length;
            uint256 totalUnlocked;
            for (uint256 i = 0; i < length; ++i) {
                address account = accounts1[i];
                uint256 locked = balances[account][1];
                if (locked > 0) {
                    delete balances[account][1];
                    emit Transfer(account, address(this), locked);
                    totalUnlocked += locked;
                    tcko.transfer(account, locked);
                }
            }
            totalSupply -= totalUnlocked;
        }
    }

    /**
     * Set the TCKO contract address.
     *
     * This method can be called only once, during the setup by `DEV_KASASI`.
     */
    function setTCKOAddress(IERC20 tckoAddress) external {
        require(msg.sender == DEV_KASASI);
        require(address(tcko) == address(0));
        tcko = tckoAddress;
    }

    /**
     * Deletes the contract if all TCKO-k's have been unlocked.
     */
    function selfDestruct() external {
        // We restrict this method to `DEV_KASASI` as there may be ERC20 tokens
        // sent to this contract by accident waiting to be rescued.
        require(msg.sender == DEV_KASASI);
        require(
            HasDistroStage(address(tcko)).distroStage() ==
                DistroStage.FinalUnlock
        );
        require(totalSupply == 0);
        selfdestruct(DAO_KASASI);
    }

    /**
     * Moves ERC20 tokens sent to this address by accident to `DAO_KASASI`.
     */
    function rescueToken(IERC20 token) external {
        // We restrict this method to `DEV_KASASI` only, as we call a method of
        // an unkown contract, which could potentially be a security risk.
        require(msg.sender == DEV_KASASI);
        // Disable sending out TCKO to ensure the invariant TCKO.(I4).
        require(token != tcko);
        token.transfer(DAO_KASASI, token.balanceOf(address(this)));
    }
}

/**
 * @title TCKO: KimlikDAO Token
 *
 * Utility
 * =======
 * 1 TCKO represents a share of all assets of the KimlikDAO treasury located
 * at `kimlikdao.eth` and 1 voting right for all treasury investment decisions.
 *
 * Any TCKO holder can redeem their share of the DAO treasury assets by
 * transferring their TCKOs to `kimlikdao.eth` on Avalanche C-chain. Such a
 * transfer burns the transferred TCKOs and sends the redeemer their share of
 * the treasury. The share of the redeemer is `sentAmount / totalSupply()`
 * fraction of all the ERC20 tokens and AVAX the treasury has.
 * Note however that the market value TCKO is ought to be higher than the
 * redemption amount, as TCKO represents a share in KimlikDAO's future cash
 * flow as well. The redemption amount is merely a lower bound on TCKOs value
 * and this functionality should only be used as a last resort.
 *
 * Investment decisions are made through proposals to swap some treasury assets
 * to other assets on a DEX, which are voted on-chain by all TCKO holders.
 *
 * Combined with a TCKT, TCKO gives a person voting rights for non-financial
 * decisions of KimlikDAO also; however in such decisions the voting weight is
 * not necessarily proportional to one's TCKO holdings (guaranteed to be
 * sub-linear in one's TCKO holdings). Since TCKT is an ID token, it allows us
 * to enforce the sub-linear voting weight.
 *
 * Supply Cap
 * ==========
 * There will be 100M TCKOs minted ever, distributed over 5 rounds of 20M TCKOs
 * each.
 *
 * Inside the contract, we keep track of another variable `distroStage`, which
 * ranges between 0 and 7 inclusive, and can be mapped to the `distroRound` as
 * follows.
 *
 *   distroRound :=  distroStage / 2 + (distroStage == 0 ? 1 : 2)
 *
 * The `distroStage` has 8 values, corresponding to the beginning and the
 * ending of the 5 distribution rounds; see `DistroStage` enum.
 * The `distroStage` can only be incremented, and only by `dev.kimlikdao.eth`
 * by calling the `incrementDistroStage()` method of this contract.
 *
 * In distribution rounds 3 and 4, 20M TCKOs are minted to `kimlikdao.eth`
 * automatically, to be sold / distributed to the public by `kimlikdao.eth`.
 * In the rest of the rounds (1, 2, and 5), the minting is manually managed
 * by `dev.kimlikdao.eth`, however the total minted TCKOs is capped at
 * distroRound * 20M TCKOs at any moment during the lifetime of the contract.
 * Additionally, in round 2, the `presale2Contract` is also given minting
 * rights, again respecting the 20M * distroRound supply cap.
 *
 * Since the `releaseRound` cannot be incremented beyond 5, this ensures that
 * there can be at most 100M TCKOs minted.
 *
 * Locking
 * =======
 * Each mint to external parties results in some unlocked and some locked
 * TCKOs, and the ratio is fixed globally. Only the 40M TCKOs minted to
 * `kimlikdao.eth` across rounds 3 and 4 are fully unlocked.
 *
 * The unlocking schedule is as follows:
 *
 *  /------------------------------------
 *  | Minted in round  |  Unlock time
 *  |------------------------------------
 *  |   Round 1        |  End of round 3
 *  |   Round 2        |  End of round 4
 *  |   Round 3        |  Unlocked
 *  |   Round 4        |  Unlocked
 *  |   Round 5        |  Year 2028
 *
 * Define:
 *   (D1) distroRound := distroStage / 2 + (distroStage == 0 ? 1 : 2)
 *
 * Facts:
 *   (F1) 1 <= distroRound <= 5
 *
 * Invariants:
 *   (I1) supplyCap() <= 20M * 1M * distroRound
 *   (I2) sum_a(balanceOf[a]) == totalSupply <= totalMinted
 *   (I3) totalMinted <= supplyCap()
 *   (I4) balanceOf[KILITLI_TCKO] == KilitliTCKO.totalSupply()
 *
 * (F1) follows because DistroStage has 8 values and floor(7/2) + 2 = 5.
 * Combining (F1) and (I1) gives the 100M TCKO supply cap.
 */
contract TCKO is IERC20, HasDistroStage {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    DistroStage public override distroStage;
    // The total number of TCKOs in existence, locked or unlocked.
    uint256 public override totalSupply;
    // The total TCKOs minted so far, including ones that have been redeemed
    // later (i.e., burned).
    uint256 public totalMinted;

    address private presale2Contract;

    function name() external pure override returns (string memory) {
        return "KimlikDAO Tokeni";
    }

    function symbol() external pure override returns (string memory) {
        return "TCKO";
    }

    function decimals() external pure override returns (uint8) {
        return 6;
    }

    /**
     * The total number of TCKOs that will be minted ever.
     */
    function maxSupply() external pure returns (uint256) {
        return 100_000_000 * 1_000_000;
    }

    /**
     * The total number of TCKOs in existence, excluding the locked ones.
     */
    function circulatingSupply() external view returns (uint256) {
        unchecked {
            return totalSupply - balanceOf[KILITLI_TCKO]; // No overflow due to (I2)
        }
    }

    /**
     * The max number of TCKOs that can be minted at the current stage.
     *
     * Ensures:
     *   (E2) supplyCap() <= 20M * 1M * distroRound
     *
     * Recall that distroRound := distroStage / 2 + distroStage == 0 ? 1 : 2,
     * so combined with distroRound <= 5, we get 100M TCKO supply cap.
     */
    function supplyCap() public view returns (uint256) {
        unchecked {
            uint256 stage = uint256(distroStage);
            uint256 cap = 20_000_000 *
                1_000_000 *
                (stage / 2 + (stage == 0 ? 1 : 2));
            return cap;
        }
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        // Disable sending to the 0 address, which is a common software / user
        // error.
        require(to != address(0));
        // Disable sending TCKOs to this contract address, as `rescueToken()` on
        // TCKOs would result in a redemption to this contract, which is *bad*.
        require(to != address(this));
        // We disallow sending to `kilitliTCKO` as we want to enforce (I4)
        // at all times.
        require(to != KILITLI_TCKO);
        uint256 fromBalance = balanceOf[msg.sender];
        require(amount <= fromBalance); // (*)

        unchecked {
            balanceOf[msg.sender] = fromBalance - amount;
            // If sent to `DAO_KASASI`, the tokens are burned and the portion
            // of the treasury is sent back to the msg.sender (i.e., redeemed).
            // The redemption amount is `amount / totalSupply()` of all
            // treasury assets.
            if (to == DAO_KASASI) {
                IDAOKasasi(DAO_KASASI).redeem(
                    payable(msg.sender),
                    amount,
                    totalSupply
                );
                totalSupply -= amount; // No overflow due to (I2)
            } else {
                balanceOf[to] += amount; // No overflow due to (*) and (I1)
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(to != address(0));
        require(to != address(this));
        require(to != KILITLI_TCKO); // For (I4)
        uint256 fromBalance = balanceOf[from];
        require(amount <= fromBalance);
        uint256 senderAllowance = allowance[from][msg.sender];
        require(amount <= senderAllowance);

        unchecked {
            balanceOf[from] = fromBalance - amount;
            allowance[from][msg.sender] = senderAllowance - amount;
            if (to == DAO_KASASI) {
                IDAOKasasi(DAO_KASASI).redeem(
                    payable(from),
                    amount,
                    totalSupply
                );
                totalSupply -= amount;
            } else {
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedAmount)
        external
        returns (bool)
    {
        uint256 newAmount = allowance[msg.sender][spender] + addedAmount; // Checked addition
        allowance[msg.sender][spender] = newAmount;
        emit Approval(msg.sender, spender, newAmount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedAmount)
        external
        returns (bool)
    {
        uint256 newAmount = allowance[msg.sender][spender] - subtractedAmount; // Checked subtraction
        allowance[msg.sender][spender] = newAmount;
        emit Approval(msg.sender, spender, newAmount);
        return true;
    }

    /**
     * Mints given number of TCKOs, respecting the supply cap.
     *
     * A fixed locked / unlocked ratio is used across all mints to external
     * participants.
     *
     * To mint TCKOs to `DAO_KASASI`, a separate code path is used, in which
     * all TCKOs are unlocked.
     */
    function mint(address account, uint256 amount) external {
        require(
            msg.sender == DEV_KASASI ||
                (distroStage == DistroStage.Presale2 &&
                    msg.sender == presale2Contract)
        );
        require(totalMinted + amount <= supplyCap()); // Checked addition (*)
        // We need this to satisfy (I4).
        require(account != KILITLI_TCKO);
        // If minted to `DAO_KASASI` unlocking would lead to redemption.
        require(account != DAO_KASASI);
        unchecked {
            uint256 unlocked = (amount + 3) / 4;
            uint256 locked = amount - unlocked;
            totalMinted += amount; // No overflow due to (*) and (I1)
            totalSupply += amount; // No overflow due to (*) and (I1)
            balanceOf[account] += unlocked; // No overflow due to (*) and (I1)
            balanceOf[KILITLI_TCKO] += locked; // No overflow due to (*) and (I1)
            emit Transfer(address(this), account, unlocked);
            emit Transfer(address(this), KILITLI_TCKO, locked);
            KilitliTCKO(KILITLI_TCKO).mint(account, locked, distroStage);
        }
    }

    function setPresale2Contract(address addr) external {
        require(msg.sender == DEV_KASASI);
        presale2Contract = addr;
    }

    /**
     * Advances the distribution stage.
     *
     * If we've advanced to DAOSaleStart stage or DAOAMMStart stage,
     * automatically mints 20M unlocked TCKOs to `DAO_KASASI`.
     *
     * @param newStage value to double check to prevent user error.
     */
    function incrementDistroStage(DistroStage newStage) external {
        require(msg.sender == DEV_KASASI);
        // Ensure the user provided round number matches, to prevent user error.
        require(uint256(distroStage) + 1 == uint256(newStage));
        // Make sure all minting has been done for the current stage
        require(supplyCap() == totalMinted, "Mint all!");
        // Ensure that we cannot go to FinalUnlock before 2028.
        if (newStage == DistroStage.FinalUnlock) {
            require(block.timestamp > 1832306400);
        }

        distroStage = newStage;

        if (
            newStage == DistroStage.DAOSaleStart ||
            newStage == DistroStage.DAOAMMStart
        ) {
            // Mint 20M TCKOs to `DAO_KASASI` bypassing the standard locked
            // ratio.
            unchecked {
                uint256 amount = 20_000_000 * 1_000_000;
                totalMinted += amount;
                totalSupply += amount;
                balanceOf[DAO_KASASI] += amount;
                emit Transfer(address(this), DAO_KASASI, amount);
            }
        }
        IDAOKasasi(DAO_KASASI).distroStageUpdated(newStage);
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