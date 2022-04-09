/**
 *Submitted for verification at snowtrace.io on 2022-04-09
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

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

interface iPEFI is IERC20 {
    function leave(uint256 share) external;
}


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function transferFrom( address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IPenguinEmperorManager {
    function roll(address) external;
}

contract PenguinDatabase {
    // User profile
    struct Profile {
        uint8 activeAvatarType;                             // Type of avatar: 1 - use "built-in" avatar, 2 - use NFT avatar
        uint32 lastNameChange;                              // UTC timestamp at which player last changed their name
        address avatarNFTContract;                          // NFT contract address in the case of NFT-avatar; otherwise, value = 0x0
        uint256 avatarId;                                   // ID of avatar. In the case of NFT avatar, this is the NFT token ID
        string nickname;                                    // Player nickname
    }

    struct BuiltInStyle {
        uint128 style;
        string color;
    }

    uint8 private constant AVATAR_TYPE_BUILT_IN = 1;
    uint8 private constant AVATAR_TYPE_NFT = 2;

    mapping(address => Profile) public profiles;    // user profiles
    mapping(address => BuiltInStyle) public builtInStyles;
    // Nickname DB
    mapping(string => bool) public nicknameExists;

    modifier onlyRegistered() {
        require(isRegistered(msg.sender), "must be registered");
        _;
    }

    function isRegistered(address penguinAddress) public view returns(bool) {
        return (profiles[penguinAddress].activeAvatarType != 0) && (bytes(profiles[penguinAddress].nickname).length != 0);
    }

    function nickname(address penguinAddress) external view returns(string memory) {
        return profiles[penguinAddress].nickname;
    }

    function color(address penguinAddress) external view returns(string memory) {
        return builtInStyles[penguinAddress].color;
    }

    function style(address penguinAddress) external view returns(uint256) {
        return builtInStyles[penguinAddress].style;
    }
    
    function avatar(address _player) external view returns(uint8 _activeAvatarType, uint256 _avatarId, IERC721 _avatarNFTContract) {
         Profile storage info = profiles[_player];
         (_activeAvatarType, _avatarId, _avatarNFTContract) = 
         (info.activeAvatarType, info.avatarId, IERC721(info.avatarNFTContract));
    }

    function currentProfile(address _player) external view returns(Profile memory, BuiltInStyle memory) {
        return (profiles[_player], builtInStyles[_player]);
    }

    function canChangeName(address penguinAddress) public view returns(bool) {
        if (uint256(profiles[penguinAddress].lastNameChange) + 86400 <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function changeStyle(uint128 _newStyle) external {
        builtInStyles[msg.sender].style = _newStyle;
    }

    function changeColor(string memory _newColor) external {
        builtInStyles[msg.sender].color = _newColor;
    }

    function setNickname(string memory _newNickname) external onlyRegistered {
        _setNickname(msg.sender, _newNickname);
    }

    // Set Penguin built-in avatar
    function setAvatarBuiltIn(uint128 _style, string memory _color) external {
        _setAvatarBuiltIn(msg.sender, _style, _color);
    }

    // set NFT avatar
    function setAvatarNFT(IERC721 _nftContract, uint256 _tokenId) external {
        _setAvatarNFT(msg.sender, _nftContract, _tokenId);
    }

    function _setNickname(address _player, string memory _newNickname) internal {
        require(!nicknameExists[_newNickname], "Choose a different nickname, that one is already taken.");
        require(canChangeName(_player), "Can only change name once daily");
        Profile memory currentPenguinInfo = profiles[_player];
        nicknameExists[currentPenguinInfo.nickname] = false;
        nicknameExists[_newNickname] = true;
        currentPenguinInfo.nickname = _newNickname;
        currentPenguinInfo.lastNameChange = uint32(block.timestamp);
        //commit changes to storage
        profiles[_player] = currentPenguinInfo;
    }
    
    function _setAvatarNFT(address _player, IERC721 _nftContract, uint256 _tokenId) internal {
        require(_nftContract.ownerOf(_tokenId) == _player, "NFT token does not belong to user");
        Profile memory currentPenguinInfo = profiles[_player];
        currentPenguinInfo.activeAvatarType = AVATAR_TYPE_NFT;
        currentPenguinInfo.avatarNFTContract = address(_nftContract);
        currentPenguinInfo.avatarId = _tokenId; 
        //commit changes to storage
        profiles[_player] = currentPenguinInfo;
    }

    function _setAvatarBuiltIn(address _player, uint128 _style, string memory _color) internal {
        BuiltInStyle memory currentPenguinStyle = builtInStyles[_player];
        profiles[_player].activeAvatarType = AVATAR_TYPE_BUILT_IN;
        currentPenguinStyle.style = _style;
        currentPenguinStyle.color = _color;
        //commit changes to storage
        builtInStyles[_player] = currentPenguinStyle;
    }

    function registerYourPenguin(string memory _nickname, IERC721 _nftContract, uint256 _tokenId, uint128 _style, string memory _color) external {
        require(address(_nftContract) != address(0) || bytes(_color).length > 0, "must set at least one profile preference");

        // Penguins can only register their nickname once. Each nickname must be unique.
        require(bytes(_nickname).length != 0, "cannot have empty nickname");
        require(!isRegistered(msg.sender), "already registered");
        require(nicknameExists[_nickname] != true, "Choose a different nickname, that one is already taken.");
        nicknameExists[_nickname] = true;

        Profile memory currentPenguinInfo = profiles[msg.sender];
        currentPenguinInfo.nickname = _nickname;
        currentPenguinInfo.lastNameChange = uint32(block.timestamp);
        //commit changes to storage
        profiles[msg.sender] = currentPenguinInfo;

        //if color is not the empty string, set the user's built in style preferences
        if (bytes(_color).length > 0) {
            _setAvatarBuiltIn(msg.sender, _style, _color);
        }
        //if user wishes to set an NFT avatar, do so.
        if (address(_nftContract) != address(0)) {
            _setAvatarNFT(msg.sender, _nftContract, _tokenId);
        }
    }
    
    function updateProfile(string memory _newNickname, uint128 _newStyle, string memory _newColor) external {
        require(isRegistered(msg.sender), "not registered yet");
        //require(profiles[msg.sender].activeAvatarType == AVATAR_TYPE_BUILT_IN, "only for built-in avatar");
        
        bool emptyInputNickname = (bytes(_newNickname).length == 0);
        bool emptyInputStyle = (_newStyle == type(uint128).max);
        bool emptyInputColor = (bytes(_newColor).length == 0);
        require(!emptyInputNickname || !emptyInputStyle || !emptyInputColor, "Nothing to update");
        
        // update nickname if applied
        if(!emptyInputNickname) {
            if (keccak256(abi.encodePacked(_newNickname)) != keccak256(abi.encodePacked(profiles[msg.sender].nickname))){
                _setNickname(msg.sender, _newNickname);   
            }
        }
        
        // update style if applied
        if(!emptyInputStyle){
            if(_newStyle != builtInStyles[msg.sender].style) {
                builtInStyles[msg.sender].style = _newStyle;
            }
        }
        
        // update color if applied
        if(!emptyInputColor) {
            if (keccak256(abi.encodePacked(_newColor)) != keccak256(abi.encodePacked(builtInStyles[msg.sender].color))){
                builtInStyles[msg.sender].color = _newColor;   
            }
        }
    }
}