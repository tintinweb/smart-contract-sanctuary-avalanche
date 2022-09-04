// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IFractionalNFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function _tokenId() external view returns (uint256);
}

interface INodeNFT {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RedeemAndFee is Ownable {
    uint public regularNFTFee = 2;
    uint public fractionNFTFee = 3;
    uint public privateNFTFee = 5;

    uint public regularRoyalty = 3;
    uint public fractionalRoyalty = 5;
    uint public privateRoyalty = 10;

    uint _marketplaceGenesisNFT_portion = 10;
    uint _fnft_wl_portion = 10;
    uint _nodenft_wl_portion = 10;
    uint _cheemsx_wl_portion = 10;
    uint _topNftLister_wl_portion = 10;
    uint _nftAngles_wl_portion = 10;
    uint _nftInfluencer_wl_portion = 10;

    uint node_total_supply = 10000;

    mapping (address=>uint) _marketplaceGenesisNFT_WL;
    mapping (address=>uint) _fnft_wl;
    mapping (address=>uint) _nodenft_wl;
    mapping (address=>uint) _cheemsx_wl;
    mapping (address=>uint) _topNftLister_wl;
    mapping (address=>uint) _nftAngles_wl;
    mapping (address=>uint) _nftInfluencer_wl;

    uint cnt_topNftLister_wl;
    uint cnt_nftAngles_wl;
    uint cnt_nftInfluencer_wl;
    uint cnt_fnft_wl;
    uint cnt_nodenft_wl;
    uint cnt_cheemsx_wl;
    uint cnt_marketplaceGenesisNFT_WL;

    bool isCheemsxAddress;
    bool isfNFT;
    bool isNodeNFT;

    address _marketplaceGenesisNFT;
    address _fNFT;
    address _nodeNFT;
    address _cheemsxAddress;

    bool public _isDistribute;

    uint _threshold = 10 * 10 ** 18;
    uint _claimableThreshold = 20 * 10 ** 18;

    mapping(address=>bool) _MarketWideDiscountedTransactionFees;     // If trasnaction fee is usually 2%, for thses wallets transaction fee will be 50% less, that means 1%

    mapping(address=>bool) _MarketWideNoFEEforTransaction;       // no fee

    uint public step = 1;
    uint currentVal;
    constructor() {
        _fNFT = 0xAAF9591d9E62aCB8061599671f3788A875ced8D9;
        _nodeNFT = 0x8138822fB2f421a25E4AE483D1570Bd2406f94aA;
        _cheemsxAddress = 0x1F3fa5ba82eCfE38EB16d522377807Bc0F8C8519;
    }

    // ====================== get functions ===============

    function MarketWideDiscountedTransactionFees(address user) public view returns(bool) {
        return _MarketWideDiscountedTransactionFees[user];
    }

    function MarketWideNoFEEforTransaction(address user) public view returns(bool) {
        return _MarketWideNoFEEforTransaction[user];
    }

    // ============================ set functions =====================

    function setRegularNFTFee (uint _fee) public onlyOwner {
        regularNFTFee = _fee;
    }

    function setFractionNFTFee (uint _fee) public onlyOwner {
        fractionNFTFee = _fee;
    }

    function setPrivateNFTFee (uint _fee) public onlyOwner {
        privateNFTFee = _fee;
    }

    function setRegularRoyalty (uint _fee) public onlyOwner {
        regularRoyalty = _fee;
    }

    function setFractionalRoyalty (uint _fee) public onlyOwner {
        fractionalRoyalty = _fee;
    }

    function setPrivateRoyalty (uint _fee) public onlyOwner {
        privateRoyalty = _fee;
    }

    function add_marketplaceGenesisNFT_WL(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_marketplaceGenesisNFT_WL[user[i]] == 0) {
                    cnt_marketplaceGenesisNFT_WL++;
                }
                _marketplaceGenesisNFT_WL[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_marketplaceGenesisNFT_WL[user[i]] != 0) {
                    cnt_marketplaceGenesisNFT_WL--;
                }
            }
        }
        
    }

    function add_fnft_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_fnft_wl[user[i]] == 0) {
                    cnt_fnft_wl++;
                    if(user[i] == _fNFT){
                        isfNFT = true;
                    }
                }
                _fnft_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_fnft_wl[user[i]] != 0) {
                    cnt_fnft_wl--;
                    if(user[i] == _fNFT){
                        isfNFT = true;
                    }
                }
            }
        }
    }

    function add_nodenft_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_nodenft_wl[user[i]] == 0) {
                    cnt_nodenft_wl++;
                    if(user[i] == _nodeNFT){
                        isNodeNFT = true;
                    }
                }
                _nodenft_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_nodenft_wl[user[i]] != 0) {
                    cnt_nodenft_wl--;
                    if(user[i] == _nodeNFT){
                        isNodeNFT = true;
                    }
                }
            }
        }
    }

    function add_cheemsx_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_cheemsx_wl[user[i]] == 0) {
                    cnt_cheemsx_wl++;
                    if(user[i] == _cheemsxAddress){
                        isCheemsxAddress = true;
                    }
                }
                _cheemsx_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_cheemsx_wl[user[i]] != 0) {
                    cnt_cheemsx_wl--;
                    if(user[i] == _cheemsxAddress){
                        isCheemsxAddress = false;
                    }
                }
            }
        }
    }

    function add_topNftLister_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_topNftLister_wl[user[i]] == 0) {
                    cnt_topNftLister_wl++;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = true;
                    // }
                }
                _topNftLister_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_topNftLister_wl[user[i]] != 0) {
                    cnt_topNftLister_wl--;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = false;
                    // }
                }
            }
        }
    }

    function add_nftAngles_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_nftAngles_wl[user[i]] == 0) {
                    cnt_nftAngles_wl++;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = true;
                    // }
                }
                _nftAngles_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_nftAngles_wl[user[i]] != 0) {
                    cnt_nftAngles_wl--;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = false;
                    // }
                }
            }
        }
    }

    function add_nftInfluencer_wl(address[] memory user, bool isAdd) public onlyOwner {
        if(isAdd) {
            for(uint i = 0; i < user.length; i++) {
                if(_nftInfluencer_wl[user[i]] == 0) {
                    cnt_nftInfluencer_wl++;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = true;
                    // }
                }
                _nftInfluencer_wl[user[i]] = step;
            }
        } else {
            for(uint i = 0; i < user.length; i++) {
                if(_nftInfluencer_wl[user[i]] != 0) {
                    cnt_nftInfluencer_wl--;
                    // if(user[i] == _cheemsxAddress){
                    //     isCheemsxAddress = false;
                    // }
                }
            }
        }
    }

    function set_marketplaceGenesisNFT(address _contractAddress) public onlyOwner {
        _marketplaceGenesisNFT = _contractAddress;
    } 

    function set_fNFT(address _contractAddress) public onlyOwner {
        _fNFT = _contractAddress;
    } 

    function set_nodeNFT(address _contractAddress) public onlyOwner {
        _nodeNFT = _contractAddress;
    } 

    function set_cheemsxAddress(address _contractAddress) public onlyOwner {
        _cheemsxAddress = _contractAddress;
    } 

    function setsDistribute (bool flag) public onlyOwner {
        _isDistribute = flag;
    }

    function set_MarketWideDiscountedTransactionFees(address user, bool flag) public onlyOwner {
        _MarketWideDiscountedTransactionFees[user] = flag;
    }

    function set_MarketWideNoFEEforTransaction(address user, bool flag) public onlyOwner {
        _MarketWideNoFEEforTransaction[user] = flag;
    }

    function accumulateTransactionFee(address user, uint amount) public returns(uint transactionFee, uint royaltyFee, uint income) {
        transactionFee = decisionTransactionFee(user) * amount / 100;
        currentVal += transactionFee;
        royaltyFee = decisionRoyaltyFee(user) * amount / 100;
        income = amount - transactionFee - royaltyFee;
        if (currentVal > _claimableThreshold) {
            step += currentVal / _claimableThreshold;
            currentVal = currentVal % _claimableThreshold;
        }
        return (transactionFee, royaltyFee, income);
    }

    function unCliamedReward(address user) public view returns(uint amount) {
        if(_marketplaceGenesisNFT_WL[user] < step && _marketplaceGenesisNFT_WL[user] > 0) {
            
        }
        
        if(isfNFT) {
            uint total = IFractionalNFT(_fNFT)._tokenId();
            uint balance = IFractionalNFT(_fNFT).balanceOf(user);
            uint step_cnt = _fnft_wl[user] != 0 ? step - _fnft_wl[user] : step - _fnft_wl[_fNFT];
            amount += _claimableThreshold / 7 * balance / total * step_cnt;
        } else {
            if(_fnft_wl[user] < step && _fnft_wl[user] > 0) {
                uint step_cnt = step - _fnft_wl[user];
                amount += _claimableThreshold / 7 / cnt_fnft_wl * step_cnt;
            }
        }

        if(isNodeNFT) {
            uint balance = INodeNFT(_nodeNFT).balanceOf(user);
            uint step_cnt = _nodenft_wl[user] != 0 ? step - _nodenft_wl[user] : step - _nodenft_wl[_nodeNFT];
            amount += _claimableThreshold / 7 * balance / node_total_supply * step_cnt;
        } else {
            if(_nodenft_wl[user] < step && _nodenft_wl[user] > 0) {
                uint step_cnt = step - _nodenft_wl[user];
                amount += _claimableThreshold / 7 / cnt_nodenft_wl * step_cnt;
            }
        }

        if(isCheemsxAddress) {
            uint balance = IERC20(_cheemsxAddress).balanceOf(user);
            uint total = IERC20(_cheemsxAddress).totalSupply();
            uint step_cnt = _cheemsx_wl[user] != 0 ? step - _cheemsx_wl[user] : step - _cheemsx_wl[_cheemsxAddress];
            amount += _claimableThreshold / 7 * balance / total * step_cnt;
        } else {
            if(_cheemsx_wl[user] < step && _cheemsx_wl[user] > 0) {
                uint step_cnt = step - _cheemsx_wl[user];
                amount += _claimableThreshold / 7 / cnt_cheemsx_wl * step_cnt;
            }
        }
        
        if(_topNftLister_wl[user] < step && _topNftLister_wl[user] > 0) {
            
        }
        if(_nftAngles_wl[user] < step && _nftAngles_wl[user] > 0) {
            uint step_cnt = step - _nftAngles_wl[user];
            amount += _claimableThreshold / 7 / cnt_nftAngles_wl * step_cnt;
        }
        if(_nftInfluencer_wl[user] < step && _nftInfluencer_wl[user] > 0) {
            uint step_cnt = step - _nftInfluencer_wl[user];
            amount += _claimableThreshold / 7 / cnt_nftInfluencer_wl * step_cnt;
        }
        return amount;
    }

    function claim(address user) public {
        require(_isDistribute, "REDEEM_AND_FEE: not config");
        if(_marketplaceGenesisNFT_WL[user] < step && _marketplaceGenesisNFT_WL[user] > 0) {
            
        }
        
        if(isfNFT) {
            uint total = IFractionalNFT(_fNFT)._tokenId();
            uint balance = IFractionalNFT(_fNFT).balanceOf(user);
            uint step_cnt = _fnft_wl[user] != 0 ? step - _fnft_wl[user] : step - _fnft_wl[_fNFT];
            uint amount = _claimableThreshold / 7 * balance / total * step_cnt;
            if(amount > 0) _fnft_wl[user] = step;
        } else {
            if(_fnft_wl[user] < step && _fnft_wl[user] > 0) {
                uint step_cnt = step - _fnft_wl[user];
                uint amount = _claimableThreshold / 7 / cnt_fnft_wl * step_cnt;
                if(amount > 0) _fnft_wl[user] = step;
            }
        }

        if(isNodeNFT) {
            uint balance = INodeNFT(_nodeNFT).balanceOf(user);
            uint step_cnt = _nodenft_wl[user] != 0 ? step - _nodenft_wl[user] : step - _nodenft_wl[_nodeNFT];
            uint amount = _claimableThreshold / 7 * balance / node_total_supply * step_cnt;
            if(amount > 0) _nodenft_wl[user] =step;
        } else {
            if(_nodenft_wl[user] < step && _nodenft_wl[user] > 0) {
                uint step_cnt = step - _nodenft_wl[user];
                uint amount = _claimableThreshold / 7 / cnt_nodenft_wl * step_cnt;
                if(amount > 0) _nodenft_wl[user] =step;
            }
        }

        if(isCheemsxAddress) {
            uint balance = IERC20(_cheemsxAddress).balanceOf(user);
            uint total = IERC20(_cheemsxAddress).totalSupply();
            uint step_cnt = _cheemsx_wl[user] != 0 ? step - _cheemsx_wl[user] : step - _cheemsx_wl[_cheemsxAddress];
            uint amount = _claimableThreshold / 7 * balance / total * step_cnt;
            if(amount > 0) _cheemsx_wl[user] = step;
        } else {
            if(_cheemsx_wl[user] < step && _cheemsx_wl[user] > 0) {
                uint step_cnt = step - _cheemsx_wl[user];
                uint amount = _claimableThreshold / 7 / cnt_cheemsx_wl * step_cnt;
                if(amount > 0) _cheemsx_wl[user] = step;
            }
        }
        
        if(_topNftLister_wl[user] < step && _topNftLister_wl[user] > 0) {
            
        }
        if(_nftAngles_wl[user] < step && _nftAngles_wl[user] > 0) {
            uint step_cnt = step - _nftAngles_wl[user];
            uint amount = _claimableThreshold / 7 / cnt_nftAngles_wl * step_cnt;
            if(amount > 0) _nftAngles_wl[user] = step;
        }
        if(_nftInfluencer_wl[user] < step && _nftInfluencer_wl[user] > 0) {
            uint step_cnt = step - _nftInfluencer_wl[user];
            uint amount = _claimableThreshold / 7 / cnt_nftInfluencer_wl * step_cnt;
            if(amount > 0) _nftInfluencer_wl[user] = step;
        }
    }

    function decisionTransactionFee(address user) private view returns(uint) {
        uint fee = regularNFTFee;
        if(_MarketWideDiscountedTransactionFees[user]) fee = fee / 2;
        if(_MarketWideNoFEEforTransaction[user]) fee = 0;
        return fee;
    }

    function decisionRoyaltyFee (address user) private view returns(uint) {
        return regularRoyalty;
    }

    function isContract(address _addr) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}