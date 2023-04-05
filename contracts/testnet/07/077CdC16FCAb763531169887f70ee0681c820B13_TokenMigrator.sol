pragma solidity ^0.8.0;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

interface IERC721Claimable {
    function claim(address to, uint256 tokenId) external;
}

contract TokenMigrator {
    IERC721 public oldToken;
    IERC721Claimable public newToken;

    constructor(address _oldToken, address _newToken) {
        oldToken = IERC721(_oldToken);
        newToken = IERC721Claimable(_newToken);
    }

    function migrateToken(uint256 tokenId) external {
        address owner = oldToken.ownerOf(tokenId);
        require(
            msg.sender == owner,
            "TokenMigrator: caller is not the token owner"
        );
        oldToken.approve(address(this), tokenId);
        oldToken.transferFrom(owner, address(this), tokenId);
        oldToken.burn(tokenId);
        newToken.claim(owner, tokenId);
    }
}