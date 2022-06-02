// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./Owners.sol";
import "./INodeType.sol";
import "./IPolarNode.sol";
import "./IPolarLuckyBox.sol";
import "./ISwapper_3_1.sol";


contract Handler_3_1_Migration is Owners {
	event NewNode(
		address indexed owner,
		string indexed name,
		uint count
	);

	struct NodeType {
		string[] keys; // nodeTypeName to address
		mapping(string => address) values;
		mapping(string => uint256) indexOf;
		mapping(string => bool) inserted;
	}

	struct Token {
		uint[] keys; // token ids to nodeTypeName
		mapping(uint => string) values;
		mapping(uint => uint) indexOf;
		mapping(uint => bool) inserted;
	}

	NodeType private mapNt;
	Token private mapToken;

	address public nft;
	IPolarLuckyBox public lucky;
	ISwapper_3_1 public swapper;

	uint public lastId;

	// init
	function init(
		address _nft,
		IPolarLuckyBox _lucky,
		ISwapper_3_1 _swapper,
		address[] calldata nt,
		string[] calldata names
	)
		external
		onlyOwners
	{
		nft = _nft;
		lucky = _lucky;
		swapper = _swapper;

		require(nt.length == names.length);

		for (uint i = 0; i < nt.length; i++) {
			mapNtSet(names[i], nt[i]);
		}
	}

	// mapToken
	function setUpNodes(
		uint[] calldata tokenIds,
		string[] calldata names
	) external onlyOwners {
		require(tokenIds.length == names.length, "length");

		for (uint i = 0; i < tokenIds.length; i++) {
			mapTokenSet(tokenIds[i], names[i]);
		}

		lastId += tokenIds.length;	   
	}

	// internal

	// private
	// maps
	function mapNtSet(
        string memory key,
        address value
    ) private {
        if (mapNt.inserted[key]) {
            mapNt.values[key] = value;
        } else {
            mapNt.inserted[key] = true;
            mapNt.values[key] = value;
            mapNt.indexOf[key] = mapNt.keys.length;
            mapNt.keys.push(key);
        }
    }
	
	function mapTokenSet(
        uint key,
        string memory value
    ) private {
        if (mapToken.inserted[key]) {
            mapToken.values[key] = value;
        } else {
            mapToken.inserted[key] = true;
            mapToken.values[key] = value;
            mapToken.indexOf[key] = mapToken.keys.length;
            mapToken.keys.push(key);
        }
    }

	function mapNtRemove(string memory key) private {
        if (!mapNt.inserted[key]) {
            return;
        }

        delete mapNt.inserted[key];
        delete mapNt.values[key];

        uint256 index = mapNt.indexOf[key];
        uint256 lastIndex = mapNt.keys.length - 1;
        string memory lastKey = mapNt.keys[lastIndex];

        mapNt.indexOf[lastKey] = index;
        delete mapNt.indexOf[key];

		if (lastIndex != index)
			mapNt.keys[index] = lastKey;
        mapNt.keys.pop();
    }

	function mapTokenRemove(uint key) private {
        if (!mapToken.inserted[key]) {
            return;
        }

        delete mapToken.inserted[key];
        delete mapToken.values[key];

        uint256 index = mapToken.indexOf[key];
        uint256 lastIndex = mapToken.keys.length - 1;
        uint lastKey = mapToken.keys[lastIndex];

        mapToken.indexOf[lastKey] = index;
        delete mapToken.indexOf[key];

		if (lastIndex != index)
			mapToken.keys[index] = lastKey;
        mapToken.keys.pop();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


contract Owners {
	
	address[] public owners;
	mapping(address => bool) public isOwner;

	constructor() {
		owners.push(msg.sender);
		isOwner[msg.sender] = true;
	}

	modifier onlySuperOwner() {
		require(owners[0] == msg.sender, "Owners: Only Super Owner");
		_;
	}
	
	modifier onlyOwners() {
		require(isOwner[msg.sender], "Owners: Only Owner");
		_;
	}

	function addOwner(address _new, bool _change) external onlySuperOwner {
		require(!isOwner[_new], "Owners: Already owner");
		isOwner[_new] = true;
		if (_change) {
			owners.push(owners[0]);
			owners[0] = _new;
		} else {
			owners.push(_new);
		}
	}

	function removeOwner(address _new) external onlySuperOwner {
		require(isOwner[_new], "Owners: Not owner");
		require(_new != owners[0], "Owners: Cannot remove super owner");
		for (uint i = 1; i < owners.length; i++) {
			if (owners[i] == _new) {
				owners[i] = owners[owners.length - 1];
				owners.pop();
				break;
			}
		}
		isOwner[_new] = false;
	}

	function getOwnersSize() external view returns(uint) {
		return owners.length;
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface INodeType {

	function transferFrom(address from, address to, uint tokenId) external;
	function burnFrom(address from, uint[] memory tokenIds) external returns(uint);

	function createNodesWithTokens(
		address user,
		uint[] memory tokenIds
	) external returns(uint);

	function createNodesLevelUp(
		address user,
		uint[] memory tokenIds
	) external returns(uint);

	function createNodesWithPendings(
		address user,
		uint[] memory tokenIds
	) external returns(uint);
	
	function createNodeWithLuckyBox(
		address user,
		uint[] memory tokenIds,
		string memory feature
	) external;

	function createNodesMigration(
		address user,
		uint[] memory tokenIds
	) external;

	function createNodeCustom(
		address user,
		uint isBoostedAirDropRate,
		uint[] memory tokenIds,
		bool[] memory areBoostedNft,
		bool isBoostedToken,
		string memory feature
	) external;

	function getTotalNodesNumberOf(address user) external view returns(uint);
	function getAttribute(uint tokenId) external view returns(string memory);

	function claimRewardsAll(address user) external returns(uint, uint);
	function claimRewardsBatch(address user, uint[] memory tokenIds) external returns(uint, uint);
	function calculateUserRewards(address user) external view returns(uint, uint);

	function name() external view returns(string memory);
	function totalCreatedNodes() external view returns(uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPolarNode {
	function generateNfts(
		string memory name,
		address user,
		uint count
	)
		external
		returns(uint[] memory);
	
	function burnBatch(address user, uint[] memory tokenIds) external;

	function setTokenIdToType(uint tokenId, string memory nodeType) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPolarLuckyBox {
	function createLuckyBoxesWithTokens(
		string memory name,
		uint count,
		address user
	) external returns(uint);
	
	function createLuckyBoxesAirDrop(
		string memory name,
		uint count,
		address user
	) external;
	
	function createNodesWithLuckyBoxes(
		address user,
		uint[] memory tokenIds
	)
		external
		returns(
			string[] memory,
			string[] memory
		);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


interface ISwapper_3_1 {
	function swapCreate(
		address tokenIn, 
		address user, 
		uint price,
		string calldata sponso
	) external;
	
	function swapClaim(
		address tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) external;
}