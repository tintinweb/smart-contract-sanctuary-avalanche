// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MultiSigWallet.sol";

/**
 * WalletFactoryV4コントラクト
 */
contract WalletFactoryV4 {
    // MultiSigWallet型の配列
    MultiSigWallet[] public wallets;
    // 関数から返すことのできる最大値
    uint256 constant maxLimit = 20;
    // owner
    address public owner;

    // mapping
    mapping(address => bool) public isRegistered;
    mapping(address => string) public dids;

    //modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "This address is not an owner address!");
        _;
    }

    // event
    event WalletCreated(
        MultiSigWallet indexed wallet,
        string name,
        address[] owners,
        uint256 required
    );
    event Registered(address addr, string did);

    /**
     * コンストラクター
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * MultiSigWalletのインスタンス数を取得する関数
     */
    function walletsCount() public view returns (uint256) {
        return wallets.length;
    }

    /**
     * MultiSigWalletのインスタンス生成関数
     * @param _name ウォレットの名前
     * @param _owners アドレスの配列
     * @param _required 閾値
     */
    function createWallet(
        string memory _name,
        address[] memory _owners,
        uint256 _required
    ) public {
        // インスタンスを生成
        MultiSigWallet wallet = new MultiSigWallet(_name, _owners, _required);
        // 配列に追加する。
        wallets.push(wallet);
        // イベントの発行
        emit WalletCreated(wallet, _name, _owners, _required);
    }

    /**
     * 作成済みウォレットの情報を取得するメソッド
     */
    function getWallets(uint256 limit, uint256 offset)
        public
        view
        returns (MultiSigWallet[] memory coll)
    {
        require(offset <= walletsCount(), "offset out of bounds");
        // 最大値を上回っている場合は、limitを格納する。
        uint256 size = walletsCount() - offset;
        size = size < limit ? size : limit;
        // sizeは、maxLimitを超えてはならない。
        size = size < maxLimit ? size : maxLimit;
        coll = new MultiSigWallet[](size);

        for (uint256 i = 0; i < size; i++) {
            coll[i] = wallets[offset + i];
        }

        return coll;
    }

    /**
     * register
     * @param _addr address
     * @param _did DID
     */
    function register(address _addr, string memory _did) public onlyOwner {
        // check
        require(!isRegistered[_addr], "This address is already registered!!");

        // set
        isRegistered[_addr] = true;
        dids[_addr] = _did;

        emit Registered(_addr, _did);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * MultiSigWalletコントラクト
 */
contract MultiSigWallet {
    // トランザクションデータ用の構造体を定義
    struct Transaction {
        // 送信先のアドレス
        address to;
        // 送金額
        uint256 value;
        // トランザクションのバイトデータ
        bytes data;
        // 実行済みのフラグ
        bool executed;
    }

    // マルチシグウォレットの名前
    string public walletName;
    // Ownerのアドレスを格納する配列
    address[] public owners;
    // 閾値
    uint256 public required;
    // トランザクションデータを格納する配列
    Transaction[] public transactions;

    // アドレスとowner権限の有無を紐付けるmap
    mapping(address => bool) public isOwner;
    // トランザクションID毎にonwerの承認状況を紐づけるmap
    mapping(uint256 => mapping(address => bool)) public approved;

    // 各種イベントの定義
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    // 呼び出し元のアドレスがownerであるかチェックする修飾子
    modifier onlyOwner() {
        require(isOwner[msg.sender], "msg.sender must be owner address");
        _;
    }

    // 指定したIDに該当するトランザクションデータが存在するかチェックする修飾子
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    // 承認ずみかチェックする修飾子
    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    // 指定したIDのトランザクションがブロードキャスト済みかチェックする修飾子
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "this tx already executed");
        _;
    }

    /**
     * コンストラクター
     * @param _name ウォレットの名前
     * @param _owners owner用のアドレスの配列
     * @param _required 閾値
     */
    constructor(
        string memory _name,
        address[] memory _owners,
        uint256 _required
    ) {
        // 引数の内容をチェックする。
        require(
            _owners.length > 0,
            "number of owner addresses must be more than zero!!"
        );
        require(
            _required > 0 && _required <= _owners.length,
            "invalid required number of owners"
        );

        // ownerのアドレス群を配列とmapに詰めていく
        for (uint256 i; i < _owners.length; i++) {
            // ownerアドレスを取得する。
            address owner = _owners[i];
            // ownerのアドレスが条件を満たしているかチェックする。
            require(owner != address(0), "invalid address");
            // 同じアドレスが連続で登録されるのを防ぐ
            require(!isOwner[owner], "owner is not unique");
            // mapと配列にセットする。
            isOwner[owner] = true;
            owners.push(owner);
        }

        // ウォレットの名前を設定
        walletName = _name;
        // 閾値を設定
        required = _required;
    }

    /**
     * 入金用のメソッド
     */
    receive() external payable {
        // イベントの発行
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * トランザクションデータを作成するメソッド
     * @param _to 送金先アドレス
     * @param _value 送金額
     * @param _data バイトデータ
     */
    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        // Transaction型のデータを作成して配列に格納する。
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        // イベントの発行
        emit Submit(transactions.length - 1);
    }

    /**
     * 指定したIDのトランザクションを承認するメソッド
     * @param _txId トランザクションID
     */
    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        // 承認済みのフラグをオンにする。
        approved[_txId][msg.sender] = true;
        // イベントの発行
        emit Approve(msg.sender, _txId);
    }

    /**
     * 指定してIDのトランザクションの承認数を取得する。
     * @param _txId トランザクションID
     */
    function _getApprovalCount(uint256 _txId)
        public
        view
        returns (uint256 count)
    {
        // ループにより承認数を取得する。
        for (uint256 i; i < owners.length; i++) {
            // もし承認されていたらcountをインクリメントする。
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    /**
     * トランザクションをブロードキャストするメソッド
     * @param _txId トランザクションID
     */
    function execute(uint256 _txId)
        external
        payable
        txExists(_txId)
        notExecuted(_txId)
    {
        // 閾値以上の承認が得られているかチェックする。
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        // トランザクションデータを作成する。
        Transaction storage transaction = transactions[_txId];
        // 実行済みのフラグをオンにする
        transaction.executed = true;
        // トランザクションを実行する。
        (bool success, ) = payable(transaction.to).call{
            value: transaction.value
        }(transaction.data);
        // トランザクションが成功したかチェックする。
        require(success, "tx failid");
        // イベントの発行
        emit Execute(_txId);
    }

    /**
     * トランザクションの承認を削除するメソッド
     * @param _txId トランザクションID
     */
    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        // 承認されているかどうかチェックする
        require(approved[_txId][msg.sender] = true);
        // 承認済みのフラグをオフにする。
        approved[_txId][msg.sender] = false;
        // イベントの発行
        emit Revoke(msg.sender, _txId);
    }

    /**
     * ウォレットの名前を取得するメソッド
     */
    function getName() public view returns (string memory) {
        return walletName;
    }

    /**
     * ウォレットの閾値を取得するメソッド
     */
    function getRequired() public view returns (uint256) {
        return required;
    }

    /**
     * ownerのアドレス数を取得するメソッド
     */
    function getOwnersCount() public view returns (uint256) {
        return owners.length;
    }

    /**
     * トランザクションデータを全て取得するメソッド
     */
    function getTxs() public view returns (Transaction[] memory) {
        return transactions;
    }
}