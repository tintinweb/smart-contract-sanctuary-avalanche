// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./IJoeRouter02.sol";
import "./IERC20.sol";
import "./IterableNodeTypeMapping.sol";
import "./OldRewardManager.sol";

contract NODERewardManager is PaymentSplitter {
    using IterableNodeTypeMapping for IterableNodeTypeMapping.Map;

    struct NodeEntity {
        string nodeTypeName;        //# name of this node's type 
        uint256 creationTime;
        uint256 lastClaimTime;
    }
    
    IterableNodeTypeMapping.Map private _nodeTypes;
	mapping(string => mapping(address => NodeEntity[])) private _nodeTypeOwner;
	mapping(string => mapping(address => uint256)) private _nodeTypeOwnerLevelUp;
	mapping(string => mapping(address => uint256)) private _nodeTypeOwnerCreatedPending;

    mapping(address => uint) public _oldNodeIndexOfUser;

    address public _gateKeeper;
    address public _gemTokenAddress;
	address public _oldNodeRewardManager;

    string public _defaultNodeTypeName;

    IJoeRouter02 public _uniswapV2Router;

    address public treasuryUsePool;
    address public distributionPool;
    address public liquidityPool;

    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public treasuryFee;
    uint256 public totalFees;

    uint256 public cashoutFee;

    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount;

	bool private openMigrate = false;
	bool private openCreate = false;
	bool private openLevelUp = false;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
		address oldNodeRewardManager,
        address token,
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory fees,
        uint256 swapAmount,
        address uniV2Router
    ) PaymentSplitter(payees, shares) {
        _gateKeeper = msg.sender;
		_oldNodeRewardManager = oldNodeRewardManager;
        _gemTokenAddress = token;
        
		treasuryUsePool = addresses[0];
        distributionPool = addresses[1];
		liquidityPool = addresses[2];

        require(treasuryUsePool != address(0) && 
			distributionPool != address(0) && 
			liquidityPool != address(0), 
			"TREASURY, REWARD & POOL ADDRESS CANNOT BE ZERO");
        
	require(uniV2Router != address(0), "ROUTER CANNOT BE ZERO");
        _uniswapV2Router = IJoeRouter02(uniV2Router);

        require(
            fees[0] != 0 && fees[1] != 0 && fees[2] != 0 && fees[3] != 0,
            "CONSTR: Fees equal 0"
        );
        treasuryFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
        cashoutFee = fees[3];

        totalFees = rewardsFee + liquidityPoolFee + treasuryFee;

        require(swapAmount > 0, "CONSTR: Swap amount incorrect");
        swapTokensAmount = swapAmount * (10**18);
    }

    modifier onlySentry() {
        require(msg.sender == _gemTokenAddress || msg.sender == _gateKeeper, "Fuck off");
        _;
    }

	// Core
	function addNodeType(
		string memory nodeTypeName, 
		uint256[] memory values
	) public onlySentry {
		require(bytes(nodeTypeName).length > 0, "addNodeType: Empty name");
        require(!_doesNodeTypeExist(nodeTypeName), "addNodeType: same nodeTypeName exists.");

        _nodeTypes.set(nodeTypeName, IterableNodeTypeMapping.NodeType({
                nodeTypeName: nodeTypeName,
                nodePrice: values[0],
                claimTime: values[1],
                rewardAmount: values[2],
                claimTaxBeforeTime: values[3],
				count: 0,
				max: values[4],
				earlyClaimTax: values[5],
				maxLevelUpGlobal: values[6],
				maxLevelUpUser: values[7],
				maxCreationPendingGlobal: values[8],
				maxCreationPendingUser: values[9]
            })
        );
    }

	function changeNodeType(
		string memory nodeTypeName, 
		uint256 nodePrice, 
		uint256 claimTime, 
		uint256 rewardAmount, 
		uint256 claimTaxBeforeTime,
		uint256 max,
		uint256 earlyClaimTax,
		uint256 maxLevelUpGlobal,
		uint256 maxLevelUpUser,
		uint256 maxCreationPendingGlobal,
		uint256 maxCreationPendingUser
	) public onlySentry {
        require(_doesNodeTypeExist(nodeTypeName), 
				"changeNodeType: nodeTypeName does not exist");

        IterableNodeTypeMapping.NodeType storage nt = _nodeTypes.get(nodeTypeName);

        if (nodePrice > 0) {
            nt.nodePrice = nodePrice;
        }
        if (claimTime > 0) {
            nt.claimTime = claimTime;
        }
        if (rewardAmount > 0) {
            nt.rewardAmount = rewardAmount;
        }
        if (claimTaxBeforeTime > 0) {
            nt.claimTaxBeforeTime = claimTaxBeforeTime;
        }
        if (max > 0) {
            nt.max = max;
        }
        if (earlyClaimTax > 0) {
            nt.earlyClaimTax = earlyClaimTax;
        }
        if (maxLevelUpGlobal> 0) {
            nt.maxLevelUpGlobal = maxLevelUpGlobal;
        }
        if (maxLevelUpUser > 0) {
            nt.maxLevelUpUser = maxLevelUpUser;
        }
        if (maxCreationPendingGlobal > 0) {
            nt.maxCreationPendingGlobal = maxCreationPendingGlobal;
        }
        if (maxCreationPendingUser > 0) {
            nt.maxCreationPendingUser = maxCreationPendingUser;
        }
    }

	function createNodeWithTokens(string memory nodeTypeName, uint256 count) public {
		require(openCreate, "Node creation not authorized yet");
		require(_doesNodeTypeExist(nodeTypeName), "nodeTypeName does not exist");
		address sender = msg.sender;
		require(
            sender != treasuryUsePool && sender != distributionPool,
            "treasury and rewardsPool cannot create node"
        );
		uint256 nodePrice = _nodeTypes.get(nodeTypeName).nodePrice * count;
		require(
            IERC20(_gemTokenAddress).balanceOf(sender) >= nodePrice,
            "Balance too low for creation."
        );
		IERC20(_gemTokenAddress).transferFrom(sender, address(this), nodePrice);

		uint256 contractTokenBalance = IERC20(_gemTokenAddress).balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping
        ) {
            swapping = true;

            uint256 treasuryTokens = contractTokenBalance * treasuryFee / 100;

            swapAndSendToFee(treasuryUsePool, treasuryTokens);

            uint256 rewardsPoolTokens = contractTokenBalance * rewardsFee / 100;

            IERC20(_gemTokenAddress).transfer(
                distributionPool,
                rewardsPoolTokens
            );

            uint256 swapTokens = contractTokenBalance * liquidityPoolFee / 100;

            swapAndLiquify(swapTokens);

            swapTokensForEth(IERC20(_gemTokenAddress).balanceOf(address(this)));

            swapping = false;
        }

		_createNodes(sender, nodeTypeName, count);
	}

	function createNodeWithPending(string memory nodeTypeName, uint256 count) public {
		require(openCreate, "Node creation not authorized yet");
		require(_doesNodeTypeExist(nodeTypeName), "nodeTypeName does not exist");
		address sender = msg.sender;
		require(
            sender != treasuryUsePool && sender != distributionPool,
            "treasury and rewardsPool cannot create node"
        );
		
		IterableNodeTypeMapping.NodeType storage ntarget = _nodeTypes.get(nodeTypeName);

		require(ntarget.maxCreationPendingGlobal >= count, 
				"Global limit reached");
		ntarget.maxCreationPendingGlobal -= count;
		_nodeTypeOwnerCreatedPending[nodeTypeName][msg.sender] += count;
		require(_nodeTypeOwnerCreatedPending[nodeTypeName][msg.sender] <= ntarget.maxCreationPendingUser, 
				"Creation with pending limit reached for user");
		
		uint256 nodePrice = ntarget.nodePrice * count;
		IterableNodeTypeMapping.NodeType memory nt;
		uint256 rewardAmount;
		
		for (uint256 i=0; i < _nodeTypes.size() && nodePrice > 0; i++) {
			nt = _nodeTypes.getValueAtIndex(i);
			NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
			for (uint256 j=0; j < nes.length && nodePrice > 0; j++) {
				rewardAmount = _calculateNodeReward(nes[j]);
				if (nodePrice >= rewardAmount) {
					nes[j].lastClaimTime = block.timestamp;
					nodePrice -= rewardAmount;
				} else {
					nes[j].lastClaimTime = block.timestamp - rewardAmount * nt.claimTime / nt.rewardAmount;
					nodePrice = 0;
				}
			}
		}
		require(nodePrice == 0, "Insufficient Pending");

		_createNodes(sender, nodeTypeName, count);
	}

	function _createNodes(address account, string memory nodeTypeName, uint256 count)
        private
    {
        require(_doesNodeTypeExist(nodeTypeName), "_createNodes: nodeTypeName does not exist");
        require(count > 0, "_createNodes: count cannot be less than 1.");

		IterableNodeTypeMapping.NodeType storage nt;

		nt = _nodeTypes.get(nodeTypeName);
		nt.count += count;
		require(nt.count <= nt.max, "Max already reached");

        for (uint256 i = 0; i < count; i++) {
			_nodeTypeOwner[nodeTypeName][account].push(
                NodeEntity({
                    nodeTypeName: nodeTypeName,
                    creationTime: block.timestamp,   
                    lastClaimTime: block.timestamp
                })
			);
        }
    }

	function cashoutAll() public {
		address sender = msg.sender;

		IterableNodeTypeMapping.NodeType memory nt;
		uint256 rewardAmount = 0;
		
		for (uint256 i=0; i < _nodeTypes.size(); i++) {
			nt = _nodeTypes.getValueAtIndex(i);
			NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][sender];
			for (uint256 j=0; j < nes.length; j++) {
				rewardAmount += _calculateNodeReward(nes[j]);
				nes[j].lastClaimTime = block.timestamp;
			}
		}
		
		require(rewardAmount > 0, "Nothing to claim");

		IERC20(_gemTokenAddress).transferFrom(distributionPool, address(this), rewardAmount);

		if (swapLiquify) {
			uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount * cashoutFee / 100;
                swapTokensForEth(feeAmount);
            }
            rewardAmount -= feeAmount;
		}

		IERC20(_gemTokenAddress).transfer(sender, rewardAmount);
	}

	function calculateAllClaimableRewards(address user) public view returns (uint256) {
		IterableNodeTypeMapping.NodeType memory nt;
		uint256 rewardAmount = 0;
		
		for (uint256 i=0; i < _nodeTypes.size(); i++) {
			nt = _nodeTypes.getValueAtIndex(i);
			NodeEntity[] storage nes = _nodeTypeOwner[nt.nodeTypeName][user];
			for (uint256 j=0; j < nes.length; j++) {
				rewardAmount += _calculateNodeReward(nes[j]);
			}
		}
		return rewardAmount;
	}

	function _calculateNodeReward(NodeEntity memory node) private view returns(uint256) {
		IterableNodeTypeMapping.NodeType memory nt = _nodeTypes.get(node.nodeTypeName);

		uint256 rewards;
		if (block.timestamp - node.lastClaimTime < nt.claimTime) {
			rewards =  nt.rewardAmount * (block.timestamp - node.lastClaimTime) * (100 - nt.claimTaxBeforeTime) / (nt.claimTime * 100);
		} else {
			rewards = nt.rewardAmount * (block.timestamp - node.lastClaimTime) / nt.claimTime;
		}
		if (nt.rewardAmount * (block.timestamp - node.creationTime) / nt.claimTime < nt.nodePrice) {
			rewards = rewards * (100 - nt.earlyClaimTax) / 100;
		}
		return rewards;
	}

	function levelUp(string[] memory nodeTypeNames, string memory target) public {
		require(openLevelUp, "Node level up not authorized yet");
		require(_doesNodeTypeExist(target), "target doesnt exist");
		IterableNodeTypeMapping.NodeType storage ntarget = _nodeTypes.get(target);

		require(ntarget.maxLevelUpGlobal >= 1, "No one can level up this type of node");
		ntarget.maxLevelUpGlobal -= 1;
		_nodeTypeOwnerLevelUp[target][msg.sender] += 1;
		require(_nodeTypeOwnerLevelUp[target][msg.sender] <= ntarget.maxLevelUpUser, 
				"Level up limit reached for user");

		uint256 targetPrice = ntarget.nodePrice;
		uint256 updatedPrice = targetPrice;
		for (uint256 i = 0; i < nodeTypeNames.length && updatedPrice > 0; i++) {

			string memory name = nodeTypeNames[i];
			require(_doesNodeTypeExist(name), "name doesnt exist");
			require(_nodeTypeOwner[name][msg.sender].length > 0, "Not owned");
			
			IterableNodeTypeMapping.NodeType storage nt;
			nt = _nodeTypes.get(name);

			require(targetPrice > nt.nodePrice, "Cannot level down");

			_nodeTypeOwner[name][msg.sender].pop();
			nt.count -= 1;

			if (nt.nodePrice > updatedPrice) {
				updatedPrice = 0;
			} else {
				updatedPrice -= nt.nodePrice;
			}
		}
		require(updatedPrice == 0, "Not enough sent");
		_createNodes(msg.sender, target, 1);
	}

	function migrateNodes(address user, uint nb) public {
		require(openMigrate || msg.sender == _gateKeeper, "Migration not authorized yet");
		require(_doesNodeTypeExist(_defaultNodeTypeName), 
				"moveAccount: _defaultnodeTypeName does not exist");
		require(nb > 0, "Nb must be greater than 0");

		uint oldNodes = OldRewardManager(_oldNodeRewardManager)._getNodeNumberOf(user);
		require(nb + _oldNodeIndexOfUser[user] <= oldNodes, "Too many nodes requested");
        _createNodes(user, _defaultNodeTypeName, nb);
		_oldNodeIndexOfUser[user] += nb;
	}

	// getters
	function getTotalCreatedNodes() public view returns(uint256) {
		uint256 total = 0;
		for (uint256 i=0; i < _nodeTypes.size(); i++) {
			total += _nodeTypes.getValueAtIndex(i).count;
		}
		return total;
	}

	function getTotalCreatedNodesOf(address who) public view returns(uint256) {
		uint256 total = 0;
		for (uint256 i=0; i < getNodeTypesSize(); i++) {
			string memory name = _nodeTypes.getValueAtIndex(i).nodeTypeName;
			total += getNodeTypeOwnerNumber(name, who);
		}
		return total;
	}
	
	function getNodeTypesSize() public view returns(uint256) {
		return _nodeTypes.size();
	}
	
	function getNodeTypeNameAtIndex(uint256 i) public view returns(string memory) {
        return _nodeTypes.getValueAtIndex(i).nodeTypeName;
	}
	
	function getNodeTypeOwnerNumber(string memory nodeTypeName, address _owner) 
			public view returns(uint256) {
		if (!_doesNodeTypeExist(nodeTypeName)) {
			return 0;
		}
		return _nodeTypeOwner[nodeTypeName][_owner].length;
	}

	function getNodeTypeLevelUp(string memory nodeTypeName, address _owner) 
			public view returns(uint256) {
		if (!_doesNodeTypeExist(nodeTypeName)) {
			return 0;
		}
		return _nodeTypeOwnerLevelUp[nodeTypeName][_owner];
	}

	function getNodeTypeOwnerCreatedPending(string memory nodeTypeName, address _owner) 
			public view returns(uint256) {
		if (!_doesNodeTypeExist(nodeTypeName)) {
			return 0;
		}
		return _nodeTypeOwnerCreatedPending[nodeTypeName][_owner];
	}

	function getNodeTypeNameData(string memory nodeTypeName, uint256 i) public view returns (uint256) {
		if (!_doesNodeTypeExist(nodeTypeName)) {
			return 0;
		}
		if (i == 0) {
			return _nodeTypes.get(nodeTypeName).nodePrice;
		} else if (i == 1) {
			return _nodeTypes.get(nodeTypeName).claimTime;
		} else if (i == 2) {
			return _nodeTypes.get(nodeTypeName).rewardAmount;
		} else if (i == 3) {
			return _nodeTypes.get(nodeTypeName).claimTaxBeforeTime;
		} else if (i == 4) {
			return _nodeTypes.get(nodeTypeName).count;
		} else if (i == 5) {
			return _nodeTypes.get(nodeTypeName).max;
		} else if (i == 6) {
			return _nodeTypes.get(nodeTypeName).earlyClaimTax;
		} else if (i == 7) {
			return _nodeTypes.get(nodeTypeName).maxLevelUpGlobal;
		} else if (i == 8) {
			return _nodeTypes.get(nodeTypeName).maxLevelUpUser;
		} else if (i == 9) {
			return _nodeTypes.get(nodeTypeName).maxCreationPendingGlobal;
		} else if (i == 10) {
			return _nodeTypes.get(nodeTypeName).maxCreationPendingUser;
		}
		return 0;
	}

	function getNodeTypeAll(string memory nodeTypeName) public view returns(uint256[] memory) {
		require(_doesNodeTypeExist(nodeTypeName), "Name doesnt exist");
		uint256[] memory all = new uint256[](11);
		IterableNodeTypeMapping.NodeType memory nt;
		nt = _nodeTypes.get(nodeTypeName);
		all[0] = nt.nodePrice;
		all[1] = nt.claimTime;
		all[2] = nt.rewardAmount;
		all[3] = nt.claimTaxBeforeTime;
		all[4] = nt.count;
		all[5] = nt.max;
		all[6] = nt.earlyClaimTax;
		all[7] = nt.maxLevelUpGlobal;
		all[8] = nt.maxLevelUpUser;
		all[9] = nt.maxCreationPendingGlobal;
		all[10] = nt.maxCreationPendingUser;
		return all;
	}

	function getNodeTypesAllAt(uint256 start, uint256 end) public view returns(uint256[][] memory) {
		uint256[][] memory all = new uint256[][](end - start);
		for (uint256 i = start; i < end; i++) {
			all[i - start] = getNodeTypeAll(_nodeTypes.getValueAtIndex(i).nodeTypeName); 
		}
		return all;
	}

	// Helpers
	function _doesNodeTypeExist(string memory nodeTypeName) private view returns (bool) {
        return _nodeTypes.getIndexOfKey(nodeTypeName) >= 0;
    }

	// Setters
	function setDefaultNodeTypeName(string memory nodeTypeName) public onlySentry {
		require(_doesNodeTypeExist(nodeTypeName), "NodeType doesn exist");
        _defaultNodeTypeName = nodeTypeName;
    }
	
	function setToken (address token) external onlySentry {
        _gemTokenAddress = token;
    }


	function updateUniswapV2Router(address newAddress) public onlySentry {
        require(newAddress != address(_uniswapV2Router), "TKN: The router already has that address");
        _uniswapV2Router = IJoeRouter02(newAddress);
    }

    function updateSwapTokensAmount(uint256 newVal) external onlySentry {
        swapTokensAmount = newVal;
    }

    function updateTreasuryWall(address payable wall) external onlySentry {
        treasuryUsePool = wall;
    }

    function updateRewardsWall(address payable wall) external onlySentry {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlySentry {
        rewardsFee = value;
        totalFees = rewardsFee + liquidityPoolFee + treasuryFee;
    }

    function updateLiquiditFee(uint256 value) external onlySentry {
        liquidityPoolFee = value;
        totalFees = rewardsFee + liquidityPoolFee + treasuryFee;
    }

    function updateTreasuryFee(uint256 value) external onlySentry {
        treasuryFee = value;
        totalFees = rewardsFee + liquidityPoolFee + treasuryFee;
    }

    function updateCashoutFee(uint256 value) external onlySentry {
        cashoutFee = value;
    }
    
	function updateGateKeeper(address _new) external onlySentry {
        _gateKeeper = _new;
    }
	
	function updateOpenMigrate(bool value) external onlySentry {
        openMigrate = value;
    }
	
	function updateOpenCreate(bool value) external onlySentry {
        openCreate = value;
    }
	
	function updateOpenLevelUp(bool value) external onlySentry {
        openLevelUp = value;
    }

	// swaps
	function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance) - initialETHBalance;
		payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = _gemTokenAddress;
        path[1] = _uniswapV2Router.WAVAX();

        IERC20(_gemTokenAddress).approve(address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IERC20(_gemTokenAddress).approve(address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            _gemTokenAddress,                  // token address
            tokenAmount,                    // amountTokenDesired
            0, // slippage is unavoidable   // amountTokenMin
            0, // slippage is unavoidable   // amountAVAXMin
            liquidityPool,                    // to address
            block.timestamp                 // deadline
        );
    }
}