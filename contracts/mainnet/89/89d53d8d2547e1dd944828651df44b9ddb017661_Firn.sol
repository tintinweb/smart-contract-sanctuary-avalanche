// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./ITransferVerifier.sol";
import "./IWithdrawalVerifier.sol";
import "./Utils.sol";
import "./RedBlack.sol";
import "./Unprivileged.sol";

contract Firn {
    using Utils for uint256;
    using Utils for Utils.Point;

    uint256 constant EPOCH_LENGTH = 60;
    mapping(bytes32 => Utils.Point[2]) acc; // main account mapping
    mapping(bytes32 => Utils.Point[2]) pending; // storage for pending transfers
    mapping(bytes32 => uint256) lastRollOver;
    bytes32[] nonces; // would be more natural to use a mapping (really a set), but they can't be deleted / reset!
    uint32 lastGlobalUpdate = 0; // will be also used as a proxy for "current epoch", seeing as rollovers will be anticipated

    Unprivileged immutable unprivileged = new Unprivileged();
    // could actually deploy the below two on-the-fly, but the gas would be too large in the deployment transaction.
    ITransferVerifier transferVerifier;
    IWithdrawalVerifier withdrawalVerifier;
    uint32 fee; // put `fee` into the same storage slot as withdrawalVerifier; both will have to be read during withdrawal.

    event DepositOccurred(address indexed sender, bytes32 indexed account, uint32 amount); // amount not indexed
    event TransferOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D);
    event WithdrawalOccurred(bytes32[N] Y, bytes32[N] C, bytes32 D, uint32 amount, address indexed destination, bytes data);

    RedBlack immutable tree = new RedBlack();
    struct Info { // try to save storage space by using smaller int types here
        uint32 epoch;
        uint32 amount; // really it's not crucial that this be uint32
        uint32 index; // index in the list
    }
    mapping(bytes32 => Info) public info; // public key --> deposit info
    mapping(uint32 => bytes32[]) public lists; // epoch --> list of depositing accounts

    address owner;
    address treasury;

    // some duplication here, but this is less painful than trying to retrieve it from the IP verifier / elsewhere.
    bytes32 immutable gX;
    bytes32 immutable gY;

    function lengths(uint32 epoch) external view returns (uint256) { // see https://ethereum.stackexchange.com/a/20838.
        return lists[epoch].length;
    }

    constructor() {
        owner = msg.sender; // the rest will be set in administrate
        Utils.Point memory gTemp = Utils.mapInto("g");
        gX = gTemp.x;
        gY = gTemp.y;
    }

    function g() internal view returns (Utils.Point memory) {
        return Utils.Point(gX, gY);
    }

    function administrate(address _owner, uint32 _fee, address _transfer, address _withdrawal, address _treasury) external {
        require(msg.sender == owner, "Forbidden ownership transfer.");
        owner = _owner;
        fee = _fee;
        transferVerifier = ITransferVerifier(_transfer);
        withdrawalVerifier = IWithdrawalVerifier(_withdrawal);
        treasury = _treasury;
    }

    function simulateAccounts(bytes32[] calldata Y, uint32 epoch) external view returns (bytes32[2][] memory result) {
        // interestingly, we lose no efficiency by accepting compressed, because we never have to decompress.
        result = new bytes32[2][](Y.length);
        for (uint256 i = 0; i < Y.length; i++) {
            bytes32 Y_i = Y[i]; // not necessary here, but just for consistency

            Utils.Point[2] memory temp;
            temp[0] = acc[Y_i][0];
            temp[1] = acc[Y_i][1];
            if (lastRollOver[Y_i] < epoch) {
                temp[0] = temp[0].add(pending[Y_i][0]);
                temp[1] = temp[1].add(pending[Y_i][1]);
            }
            result[i][0] = Utils.compress(temp[0]);
            result[i][1] = Utils.compress(temp[1]);
        }
    }

    function rollOver(bytes32 Y) private {
        uint32 epoch = uint32(block.timestamp / EPOCH_LENGTH);
        if (lastRollOver[Y] < epoch) {
            acc[Y][0] = acc[Y][0].add(pending[Y][0]);
            acc[Y][1] = acc[Y][1].add(pending[Y][1]);
            delete pending[Y]; // pending[Y] = [Utils.G1Point(0, 0), Utils.G1Point(0, 0)];
            lastRollOver[Y] = epoch;
        }
    }

    function touch(bytes32 Y, uint32 credit, uint32 epoch) private {
        // could save a few operations if we check for the special case that current.epoch == epoch.
        bytes32[] storage list; // declare here not for efficiency, but to avoid shadowing warning
        Info storage current = info[Y];
        if (current.epoch > 0) { // this guy has deposited before... remove him from old list
            list = lists[current.epoch];
            list[current.index] = list[list.length - 1];
            list.pop();
            if (list.length == 0) tree.remove(current.epoch);
            else if (current.index < list.length) info[list[current.index]].index = current.index;
        }
        current.epoch = epoch;
        current.amount += credit;
        if (!tree.exists(epoch)) {
            tree.insert(epoch);
        }
        list = lists[epoch];
        current.index = uint32(list.length);
        list.push(Y);
    }

    function deposit(bytes32 Y, bytes32[2] calldata signature) external payable {
        require(msg.value >= 1e18, "Deposit amount is too small.");
        require(msg.value % 1e16 == 0, "Must be a multiple of 0.01 AVAX.");

        uint32 epoch = uint32(block.timestamp / EPOCH_LENGTH);
        if (lastGlobalUpdate < epoch) {
            lastGlobalUpdate = epoch;
            delete nonces;
        }
        rollOver(Y);

        require(address(this).balance <= 1e16 * 0xFFFFFFFF, "Escrow pool now too large.");
        uint32 credit = uint32(msg.value / 1e16); // can't overflow, by the above.
        pending[Y][0] = pending[Y][0].add(g().mul(credit)); // convert to uint256?

        if (info[Y].epoch == 0) { // only verify their signature the first time they deposit.
            Utils.Point memory pub = Utils.decompress(Y);
            Utils.Point memory K = g().mul(uint256(signature[1])).add(pub.mul(uint256(signature[0]).neg()));
            uint256 c = uint256(keccak256(abi.encode("Welcome to FIRN", address(this), Y, K))).mod();
            require(bytes32(c) == signature[0], "Signature failed to verify.");
        }
        touch(Y, credit, epoch);

        emit DepositOccurred(msg.sender, Y, credit);
    }

    function transfer(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes32 u, uint32 epoch, uint32 tip, bytes calldata proof) external {
        emit TransferOccurred(Y, C, D);

        require(epoch == block.timestamp / EPOCH_LENGTH, "Wrong epoch."); // conversion of RHS to uint32 is unnecessary / redundant

        if (lastGlobalUpdate < epoch) {
            lastGlobalUpdate = epoch;
            delete nonces;
        }
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] != u, "Nonce already seen.");
        }
        nonces.push(u);

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            bytes32 Y_i = Y[i];
            rollOver(Y_i);

            statement.Y[i] = Utils.decompress(Y_i);
            statement.C[i] = Utils.decompress(C[i]);
            statement.CLn[i] = acc[Y_i][0].add(statement.C[i]);
            statement.CRn[i] = acc[Y_i][1].add(statement.D);
            // mutate their pending, in advance of success.
            pending[Y_i][0] = pending[Y_i][0].add(statement.C[i]);
            pending[Y_i][1] = pending[Y_i][1].add(statement.D);
            // pending[Y_i] = scratch; // can't do this, so have to use 2 sstores _anyway_ (as in above)
            if (info[Y_i].epoch > 0) {
                touch(Y_i, 0, epoch);
            }
        }
        statement.epoch = epoch;
        statement.u = Utils.decompress(u);
        statement.fee = tip;

        transferVerifier.verify(statement, Utils.deserializeTransfer(proof));

        payable(msg.sender).transfer(uint256(tip) * 1e16);
    }

    function withdraw(bytes32[N] calldata Y, bytes32[N] calldata C, bytes32 D, bytes32 u, uint32 epoch, uint32 amount, uint32 tip, bytes calldata proof, address destination, bytes calldata data) external {
        emit WithdrawalOccurred(Y, C, D, amount, destination, data);

        require(epoch == block.timestamp / EPOCH_LENGTH, "Wrong epoch."); // conversion of RHS to uint32 is unnecessary. // could supply epoch ourselves; check early to save gas

        if (lastGlobalUpdate < epoch) {
            lastGlobalUpdate = epoch;
            delete nonces;
        }
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] != u, "Nonce already seen.");
        }
        nonces.push(u);

        Utils.Statement memory statement;
        statement.D = Utils.decompress(D);
        for (uint256 i = 0; i < N; i++) {
            bytes32 Y_i = Y[i]; // this is actually necessary to prevent stacktoodeep in the below.
            rollOver(Y_i);

            statement.Y[i] = Utils.decompress(Y_i);
            statement.C[i] = Utils.decompress(C[i]);
            statement.CLn[i] = acc[Y_i][0].add(statement.C[i]);
            statement.CRn[i] = acc[Y_i][1].add(statement.D);
            // mutate their pending, in advance of success.
            pending[Y_i][0] = pending[Y_i][0].add(statement.C[i]);
            pending[Y_i][1] = pending[Y_i][1].add(statement.D);
            // pending[Y[i]] = scratch; // can't do this, so have to use 2 sstores _anyway_ (as in above)
        }
        uint32 burn = amount >> fee;
        statement.epoch = epoch; // implicit conversion to uint256
        statement.u = Utils.decompress(u);
        statement.fee = tip + burn; // implicit conversion to uint256

        uint256 salt = uint256(keccak256(abi.encode(destination, data))); // .mod();
        withdrawalVerifier.verify(amount, statement, Utils.deserializeWithdrawal(proof), salt);

        payable(msg.sender).transfer(uint256(tip) * 1e16);
//        payable(treasury).transfer(uint256(burn) * 1e16);
        // send the burn---with an arbitrary amount of gas (!) to `treasury`, with no calldata.
        (bool success,) = payable(treasury).call{value: uint256(burn) * 1e16}("");
        require(success, "External treasury call failed.");
//        payable(destination).transfer(uint256(amount) * 1e16);
        unprivileged.dispatch{value: uint256(amount) * 1e16}(destination, data);
    }
}