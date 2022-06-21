/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-21
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
* @title Registration of domain names for IPFS.
* @author Arthur Fleck
* @notice Use a contract to register domain names.
* @dev A contract being developed that allows domain names to be registered.
 */
contract AVADoma is Context {

    /**
     * @dev A list of top-level domain names.
     */
    enum TLDs {
        ava,
        web3,
        dapp,
        ipfs,
        defi,
        gamefi
    }

    /**
     * @dev A new domain registration event.
     *
     * @param domain  - Domain name.
     * @param ipfs    - IPFS hash.
     * @param owner   - The owner of the domain name.
     * @param created - The start date of the domain name registration.
     * @param deleted - The end date of the domain name registration.
     */
    event RegisterDomain(
        string indexed domain,
        string indexed ipfs,
        address indexed owner,
        uint256 created,
        uint256 deleted
    );

    /**
     * @dev The domain name update event.
     *
     * @param domain   - Domain name.
     * @param ipfs     - IPFS base32 CID.
     * @param owner    - The owner of the domain name.
     * @param transfer - Permission to transfer the domain to this address.
     * @param price    - The price of the domain to transfer.
     * @param created  - The start date of the domain name registration.
     * @param deleted  - The end date of the domain name registration.
     */
    event UpdateDomain(
        string indexed domain,
        string indexed ipfs,
        address indexed owner,
        address transfer,
        uint256 price,
        uint256 created,
        uint256 deleted
    );

    /**
     * @dev Domain transfer event to a new owner.
     *
     * @param domain   - Domain name.
     * @param owner    - The owner of the domain name.
     * @param transfer - Permission to transfer the domain to this address.
     * @param price    - The price of the domain to transfer.
     * @param created  - The start date of the domain name registration.
     * @param deleted  - The end date of the domain name registration.
     */
    event TransferDomain(
        string indexed domain,
        address indexed owner,
        address indexed transfer,
        uint256 price,
        uint256 created,
        uint256 deleted
    );

    /**
     * @dev Lottery event result.
     *
     * @param domain     - Domain name.
     * @param owner      - The owner of the domain name.
     * @param id_lottery - Lottery ID.
     */
    event WinnerLottery(
        string indexed domain,
        address indexed owner,
        uint256 indexed id_lottery
    );

    /**
     * @dev The structure of domain name data.
     *
     * @param tld        - Top-level domain name.
     * @param hostname   - Second-level domain name.
     * @param ipfs       - IPFS CID.
     * @param owner      - The owner of the domain name.
     * @param transfer   - Permission to transfer the domain to this address.
     * @param price      - The price of the domain to transfer.
     * @param created_at - The start date of the domain name registration.
     * @param deleted_at - The end date of the domain name registration.
     */
    struct Domain {
        TLDs tld;
        string hostname;
        string ipfs;
        address owner;
        address transfer;
        uint256 price;
        uint256 created_at;
        uint256 deleted_at;
    }

    /**
     * @dev The structure of domain name data.
     *
     * @param id     - ID lottery.
     * @param owner  - The owner of the domain name.
     * @param domain - ID of the winning domain.
     */
    struct Winner {
        uint256 id;
        address owner;
        uint256 domain;
    }

    address payable private _owner;

    Domain[] public domains;

    Winner[] public winners;
    uint256 public id_lottery = 1;

    string[36] symbols = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9"];

    //       owner     id_domains
    mapping(address => uint256[]) private _owner2domains;
    //    domain.tld  id_domain
    mapping(string => uint256) private _hostname2domain;
    //    id_lottery     users
    mapping(uint256 => address[]) private _lottery;
    //       user     id_lottery
    mapping(address => uint256) private _user_lottery;

    constructor() {
        _owner = payable(msg.sender);
        Domain memory d; // Genesis domain
        domains.push(d);
    }
    
    /**
     * @dev Only the contract owner can call the function.
     */
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only owner can call this."
        );
        _;
    }

    /**
     * @dev A new domain registration.
     *
     * @param _tld      - Top-level domain name.
     * @param _hostname - Second-level domain name.
     * @param _ipfs     - IPFS hash.
     * @return added_id - Domain ID.
     */
    function registerDomain(
        TLDs _tld,
        string memory _hostname,
        string memory _ipfs
    ) public payable returns (uint256 added_id) {
        string memory _hostname_tld = getDomain(_hostname, _tld);
        uint256 _domain_id = _hostname2domain[_hostname_tld];
        bool _domain_active;

        if (_domain_id != 0) {
            if (domains[_domain_id].deleted_at > block.timestamp) {
                revert("The domain name is already registered.");
            } else {
                _domain_active = true;
            }
        }
        if (msg.value <= 0) {
            revert("Top up your wallet balance.");
        }

        uint256 _domain_price = getPrice(_hostname, _tld);

        if (!checkPriceDomain(_hostname, _domain_price, msg.value)) {
            revert("Your wallet balance is not enough to register a domain name.");
        }

        uint256 _domain_created_at = block.timestamp;
        uint256 _domain_deleted_at = _domain_created_at + ((365 days) * (msg.value / _domain_price));

        if (_domain_active) {
            Domain storage _domain = domains[_domain_id];

            uint256[] storage _ids = _owner2domains[_domain.owner];
            for (uint256 i = 0; i < _ids.length; i++) {
                if (_ids[i] == _domain_id) {
                    _ids[i] = _ids[_ids.length - 1];
                    _ids.pop();
                    break;
                }
            }

            _domain.tld = _tld;
            _domain.hostname = _hostname;
            _domain.ipfs = _ipfs;
            _domain.owner = _msgSender();
            _domain.transfer = address(0);
            _domain.price = 0;
            _domain.created_at = _domain_created_at;
            _domain.deleted_at = _domain_deleted_at;

            require(domains[_domain_id].owner == _msgSender(), "Domain name registration error.");

            added_id = _domain_id;
        } else {
            Domain memory _domain;
            _domain.tld = _tld;
            _domain.hostname = _hostname;
            _domain.ipfs = _ipfs;
            _domain.owner = _msgSender();
            _domain.created_at = _domain_created_at;
            _domain.deleted_at = _domain_deleted_at;

            domains.push(_domain);

            added_id = domains.length - 1;

            _hostname2domain[_hostname_tld] = added_id;
            _owner2domains[_msgSender()].push(added_id);

            require(domains[added_id].owner == _msgSender(), "Domain name registration error.");
        }

        emit RegisterDomain(
            string(_hostname_tld),
            _ipfs,
            _msgSender(),
            _domain_created_at,
            _domain_deleted_at
        );
    }

    /**
     * @dev The domain name update.
     * In order to clear the `_transfer` field, you need to pass the address:
     * `0x000000000000000000000000000000000000dEaD`
     * In order to clear the `_price` field, you need to pass the number:
     * `1`
     *
     * @param _tld      - Top-level domain name.
     * @param _hostname - Second-level domain name.
     * @param _ipfs     - IPFS hash.
     * @param _transfer - Permission to transfer the domain to this address.
     * @param _price    - The price of the domain to transfer.
     * @return success  - true/false
     */
    function updateDomain(
        TLDs _tld,
        string memory _hostname,
        string memory _ipfs,
        address _transfer,
        uint256 _price
    ) public payable returns (bool success) {
        string memory _hostname_tld = getDomain(_hostname, _tld);

        if (_hostname2domain[_hostname_tld] == 0) {
            revert("The domain name has not been registered yet.");
        }

        Domain storage _domain = domains[_hostname2domain[_hostname_tld]];

        require(_domain.owner == _msgSender(), "Only the owner of the domain name can update it.");

        if (msg.value <= 0 && _domain.deleted_at < block.timestamp) {
            revert("Extend the domain name registration period.");
        }

        if (msg.value > 0) {
            uint256 _price_domain = getPrice(_hostname, _tld);
            if (checkPriceDomain(_hostname, _price_domain, msg.value)) {
                _domain.deleted_at += ((365 days) * (msg.value / _price_domain));
            } else {
                revert("Your wallet balance is not enough to register a domain name.");
            }
        }

        if (bytes(_ipfs).length != 0) {
            _domain.ipfs = _ipfs;
        }

        if (_transfer != address(0) && _transfer != _domain.owner) {
            _domain.transfer = _transfer;
        } else if (_transfer == 0x000000000000000000000000000000000000dEaD) {
            _domain.transfer = address(0);
        }

        
        if (_price > 0) {
            if (_price == 1) {
                _domain.price = 0;
            } else {
                _domain.price = _price;
            }
        }

        success = true;

        emit UpdateDomain(
            _hostname_tld,
            _domain.ipfs,
            _domain.owner,
            _domain.transfer,
            _domain.price,
            _domain.created_at,
            _domain.deleted_at
        );
    }

    /**
     * @dev Domain transfer to a new owner.
     * The new domain owner must call and pay for the function.
     *
     * @param _tld      - Top-level domain name.
     * @param _hostname - Second-level domain name.
     * @param _ipfs     - IPFS hash.
     * @return success  - true/false
     */
    function transferDomain(
        TLDs _tld,
        string memory _hostname,
        string memory _ipfs
    ) public payable returns (bool success) {
        string memory _hostname_tld = getDomain(_hostname, _tld);

        if (_hostname2domain[_hostname_tld] == 0) {
            revert("The domain name has not been registered yet.");
        }
        if (msg.value <= 0) {
            revert("Top up your wallet balance.");
        }

        uint256 _domain_id = _hostname2domain[_hostname_tld];
        Domain storage _domain = domains[_domain_id];

        require(
            (_domain.transfer == address(0) && _domain.price != 0) || 
            _domain.transfer == _msgSender(),
            "You do not have the rights to purchase this domain name."
        );

        uint256 _price_domain = getPrice(_hostname, _tld);
        
        if (!checkPriceDomain(_hostname, _price_domain, msg.value)) {
            revert("Your wallet balance is not enough to register a domain name.");
        }

        uint256[] storage _ids = _owner2domains[_domain.owner];
        for (uint256 i = 0; i < _ids.length; i++) {
            if (_ids[i] == _domain_id) {
                _ids[i] = _ids[_ids.length - 1];
                _ids.pop();
                break;
            }
        }

        bool sent = payable(_domain.owner).send(msg.value);
        require(sent, "The domain transfer failed with an error.");

        _domain.owner = _domain.transfer;
        _domain.ipfs = _ipfs;
        _domain.transfer = address(0);
        _domain.price = 0;

        _owner2domains[_msgSender()].push(_domain_id);

        success = true;
        
        emit TransferDomain(
            string(_hostname_tld),
            _domain.owner,
            _domain.transfer,
            _domain.price,
            _domain.created_at,
            _domain.deleted_at
        );
    }

    /**
     * @dev Registration in the lottery.
     */
    function regInLottery() public returns (bool success) {
        require(_user_lottery[_msgSender()] == 0 || _user_lottery[_msgSender()] != id_lottery, "You have already registered for the nearest domain name lottery.");
        _user_lottery[_msgSender()] = id_lottery;
        _lottery[id_lottery].push(_msgSender());
        success = true;
    }

    /**
     * @dev Determination of the lottery winner.
     */
    function winnerLottery() public onlyOwner returns (Winner memory) {
        require(_lottery[id_lottery].length >= 10, "The winner will be determined when there are more than 10 participants.");
        uint256 _r = random();
        uint256 _r_owner = _r % _lottery[id_lottery].length;
        address _win = _lottery[id_lottery][_r_owner];
        (string memory _hostname, TLDs _tld) = randomDomain(_r);
        string memory _hostname_tld = getDomain(_hostname, _tld);
        require(_hostname2domain[_hostname_tld] == 0, "Couldn't find a free domain name.");

        Domain memory _domain;
        _domain.tld = _tld;
        _domain.hostname = _hostname;
        _domain.ipfs = 'QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco';
        _domain.owner = _win;
        _domain.created_at = block.timestamp;
        _domain.deleted_at = block.timestamp + 3650 days;

        domains.push(_domain);

        uint256 added_id = domains.length - 1;

        _hostname2domain[_hostname_tld] = added_id;
        _owner2domains[_win].push(added_id);

        require(domains[added_id].owner == _win, "Domain name registration error.");

        Winner memory winner;
        winner.owner = _win;
        winner.domain = added_id;
        winner.id = id_lottery;

        winners.push(winner);

        emit RegisterDomain(
            _hostname_tld,
            "",
            _win,
            _domain.created_at,
            _domain.deleted_at
        );

        emit WinnerLottery(
            _hostname_tld,
            _win,
            id_lottery
        );

        id_lottery += 1;

        return winner;
    }

    /**
     * @dev Getting a pseudo-random number.
     * The function will be replaced by Chainlink VRF when the 
     * Avalanche blockchain implementation appears.
     */
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _lottery[id_lottery].length)));
    }

    /**
     * @dev Generate random hostname.tld
     */
    function randomDomain(uint256 _r) internal view returns (string memory _hostname, TLDs _tld) {
        string memory _hostname_tld;
        uint256 _letter1 = _r % 133;
        uint256 _letter2 = _r % 177;
        uint256 plus = 0;
        uint256 name = 1;
        while (name < 100) {
            _hostname = string(abi.encodePacked(symbols[(_letter1 + plus) % 36], symbols[(_letter2 + plus) % 36]));
            uint _t = (_letter1 + _letter2 + plus) % 6;
            _tld = TLDs(_t);
            _hostname_tld = getDomain(_hostname, _tld);
            if (_hostname2domain[_hostname_tld] == 0) {
                name = 100;
            } else {
                name++;
            }
            plus = plus + _t + 1;
        }
    }

    /**
     * @dev Checking the balance to pay for the domain name.
     */
    function checkPriceDomain(string memory _hostname, uint256 _price, uint256 _value) private pure returns (bool) {
        uint256 _words = utfStringLength(_hostname);
        return 
            _words <= 0 || _words > 63
                ? false 
                : (
                    (_words <= 1 && _value >= _price) ||
                    (_words <= 3 && _value >= _price) ||
                    (_words <= 5 && _value >= _price) ||
                    (_words <= 63 && _value >= _price)
                );
    }

    /**
     * @dev Calculating the length of a domain name.
     */
    function utfStringLength(string memory _hostname) pure internal returns (uint length) {
        uint i = 0;
        bytes memory string_rep = bytes(_hostname);

        while (i < string_rep.length) {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                i+=1;
            length++;
        }
    }

    /**
     * @dev Concatenation of a second-level and top-level domain name.
     */
    function getDomain(
        string memory _hostname,
        TLDs _tld
    ) internal pure returns (string memory) {
        string memory t;
        if (_tld == TLDs.ava) {
            t = 'ava';
        } else if (_tld == TLDs.web3) {
           t = 'web3';
        } else if (_tld == TLDs.dapp) {
           t = 'dapp';
        } else if (_tld == TLDs.ipfs) {
           t = 'ipfs';
        } else if (_tld == TLDs.defi) {
           t = 'defi';
        } else if (_tld == TLDs.gamefi) {
           t = 'gamefi';
        }
        return string(abi.encodePacked(_hostname, '.', t));
    }

    /**
     * @dev Getting the IPFS CID.
     */
    function getIPFS(
        string memory _domain
    ) external view returns (string memory) {
        return domains[_hostname2domain[_domain]].ipfs;
    }

    /**
     * @dev Getting the owner.
     */
    function getOwner(
        string memory _domain
    ) external view returns (address) {
        return domains[_hostname2domain[_domain]].owner;
    }

    /** 
     * @dev Getting the created date.
     */
    function getStartDate(
        string memory _domain
    ) external view returns (uint256) {
        return domains[_hostname2domain[_domain]].created_at;
    }

    /**
     * @dev Getting the deleted date.
     */
    function getEndDate(
        string memory _domain
    ) external view returns (uint256) {
        return domains[_hostname2domain[_domain]].deleted_at;
    }

    /**
     * @dev Getting the new owner address.
     */
    function getTransferAddress(
        string memory _domain
    ) external view returns (address) {
        return domains[_hostname2domain[_domain]].transfer;
    }

    /**
     * @dev Getting the ID domain name.
     */
    function getId(
        string memory _domain
    ) external view returns (uint256) {
        return _hostname2domain[_domain];
    }

    /**
     * @dev Getting the price domain name.
     */
    function getPrice(
        string memory _hostname,
        TLDs _tld
    ) public view returns (uint256 _price) {
        uint256 words = utfStringLength(_hostname);
        string memory _hostname_tld = getDomain(_hostname, _tld);
        Domain memory _domain;

        if (words <= 0 || words > 63) {
            return 0;
        }

        if (_hostname2domain[_hostname_tld] != 0) {
            _domain = domains[_hostname2domain[_hostname_tld]];
            if (_domain.deleted_at > block.timestamp) {
                if (_domain.price > 1 && _domain.owner != _msgSender()) {
                    _price = _domain.price;
                }
            }
        }

        if (_price == 0) {
            if (words <= 1) {
                _price = 10 * 10**18;
            } else if (words <= 3) {
                _price = 1 * 10**18;
            } else if (words <= 5) {
                _price = 0.1 * 10**18;
            } else if (words <= 63) {
                _price = 0.01 * 10**18;
            }
        }
    }

    /**
     * @dev Getting count domain names.
     */
    function getCount(address owner) external view returns (uint256) {
        if (owner != address(0)) {
            return _owner2domains[owner].length;
        } else {
            return domains.length;
        }
    }

    /**
     * @dev Getting count lottery users.
     */
    function getLotteryCount() external view returns (uint256) {
        return _lottery[id_lottery].length;
    }

    /**
     * @dev Getting the domains list.
     */
    function getDomains(
        address owner,
        uint256 page,
        uint256 limit
    ) external view returns (Domain[] memory) {
        Domain[] memory emptyRes;
        Domain[] memory _domains = domains;
        uint256 dLength = _domains.length;

        uint256 _page = page == 0 ? 1 : page;
        uint256 _limit = limit == 0 ? 5 : limit;

        uint256 end = _page * _limit;
        uint256 start = end - _limit;

        uint256[] memory _id_domains;

        if (owner != address(0)) {
            _id_domains = _owner2domains[owner];
            dLength = _id_domains.length;
        }

        if (dLength < end) {
            if (dLength >= start) {
                end = dLength;
                _limit = end - start;
            } else {
                return emptyRes;
            }
        }

        Domain[] memory _results = new Domain[](_limit);

        uint256 j = 0;
        for (uint i = start; i < end; i++) {
            if (owner == address(0) && _domains[i].created_at != 0) {
                _results[j] = _domains[i];
            }
            if (owner != address(0) && _domains[_id_domains[i]].created_at != 0) {
                _results[j] = _domains[_id_domains[i]];
            }
            j++;
        }

        return _results;
    }

    /**
     * @dev String -> Bytes32
     */
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev Bytes32 -> String
     */
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    receive() external payable {}

    function withdraw() external onlyOwner returns(bool) {
        _owner.transfer(address(this).balance);
        return true;
    }
}