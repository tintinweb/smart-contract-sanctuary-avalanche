/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyPolicy {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyPolicy
    {
        require(
            newOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface INFTStaking {
    function stake(
        address _user,
        uint256 _tokenID,
        uint256[] memory _tokenIDs
    ) external;

    function unStake(address _user, uint256[] memory _tokenIDs) external;

    function claim(address _user) external;
}

interface ICoinStaking {
    function stake(
        address _user,
        uint256 _amount,
        uint256 _tokenID
    ) external;

    function unStake(address _user, uint256 _amount) external;

    function claim(address _user) external;
}

contract StakingHelper is Ownable {
    address public NFTStaking;
    address public cashStaking;
    address public drugStaking;

    constructor(
        address _NFTStaking,
        address _drugStaking,
        address _cashStaking
    ) {
        NFTStaking = _NFTStaking;
        drugStaking = _drugStaking;
        cashStaking = _cashStaking;
    }

    function stake(
        uint256 _tokenID,
        address[] memory _stakings,
        uint256[][] memory amounts
    ) external {
        for (uint256 i = 0; i < _stakings.length; i++) {
            if (_stakings[i] == NFTStaking) {
                if (amounts[i].length > 0) {
                    INFTStaking(NFTStaking).stake(
                        msg.sender,
                        _tokenID,
                        amounts[i]
                    );
                }
            } else if (_stakings[i] == cashStaking) {
                if (amounts[i].length > 0) {
                    ICoinStaking(cashStaking).stake(
                        msg.sender,
                        _tokenID,
                        amounts[i][0]
                    );
                }
            } else if (_stakings[i] == drugStaking) {
                if (amounts[i].length > 0) {
                    ICoinStaking(drugStaking).stake(
                        msg.sender,
                        _tokenID,
                        amounts[i][0]
                    );
                }
            }
        }
    }

    function unStake(address[] memory _stakings, uint256[][] memory amounts)
        external
    {
        bool nftIs = false;
        uint256 index;
        for (uint256 i = 0; i < _stakings.length; i++) {
            if (_stakings[i] == NFTStaking) {
                if (amounts[i].length > 0) {
                    nftIs = true;
                    index = i + 1;
                    continue;
                }
            } else if (_stakings[i] == cashStaking) {
                if (amounts[i].length > 0) {
                    ICoinStaking(cashStaking).unStake(
                        msg.sender,
                        amounts[i][0]
                    );
                }
            } else if (_stakings[i] == drugStaking) {
                if (amounts[i].length > 0) {
                    ICoinStaking(drugStaking).unStake(
                        msg.sender,
                        amounts[i][0]
                    );
                }
            }
        }
        if (nftIs) {
            INFTStaking(NFTStaking).unStake(msg.sender, amounts[index - 1]);
        }
    }

    function claim(address[] memory _stakings) external {
        for (uint256 i = 0; i < _stakings.length; i++) {
            if (_stakings[i] == NFTStaking) {
                INFTStaking(NFTStaking).claim(msg.sender);
            } else if (_stakings[i] == cashStaking) {
                ICoinStaking(cashStaking).claim(msg.sender);
            } else if (_stakings[i] == drugStaking) {
                ICoinStaking(drugStaking).claim(msg.sender);
            }
        }
    }
}