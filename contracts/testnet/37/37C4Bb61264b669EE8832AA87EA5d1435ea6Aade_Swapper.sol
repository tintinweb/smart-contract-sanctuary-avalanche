// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./SplitterTeam.sol";
import "./IJoeRouter02.sol";
import "./Owners.sol";


contract Swapper is SplitterTeam, Owners {
	struct Path {
		address[] pathIn;
		address[] pathOut;
	}

	struct MapPath {
		address[] keys;
		mapping(address => Path) values;
		mapping(address => uint256) indexOf;
		mapping(address => bool) inserted;
	}

	struct Sponso {
		address to;
		uint rate;
		uint until;
		uint released;
		uint claimable;
		address[] path;
		uint discountRate;
	}

	MapPath private mapPath;

	string[] public allInflus;
	mapping(string => bool) public influInserted;
	mapping(string => Sponso) public influData;
	
	address public token;
	address public futur;
	address public distri;
	address public lpHandler;
	address public router;
	address public native;

	uint public futurFee;
	uint public rewardsFee;
	uint public lpFee;

	bool private swapping = false;
	bool private swapLiquifyCreate = true;
	bool private swapLiquifyClaim = true;
	bool private swapFutur = true;
	bool private swapRewards = true;
	bool private swapLpPool = true;
	bool private swapPayee = true;

	uint public swapTokensAmountCreate;

	address public handler;

	bool public openSwapCreate = false;
	bool public openSwapClaim = false;

	constructor(
		address[] memory splitters,
		uint256[] memory duration,
		uint256[][] memory shares,
		address[] memory addresses,
		uint256[] memory fees,
		uint256 _swAmount,
		address _handler
	) SplitterTeam(splitters, duration, shares) {
		token = addresses[0];
		futur = addresses[1];
		distri = addresses[2];
		lpHandler = addresses[3];
		router = addresses[4];
		native = addresses[5];

		futurFee = fees[0];
		rewardsFee = fees[1];
		lpFee = fees[2];

		swapTokensAmountCreate = _swAmount;

		handler = _handler;
	}
	
	modifier onlyHandler() {
		require(msg.sender == handler, "Swapper: Only Handler");
		_;
	}

	function addMapPath(
		address _token, 
		address[] calldata pathIn,
		address[] calldata pathOut
	)
		external
		onlyOwners
	{
		require(!mapPath.inserted[_token], "Swapper: Token already exists");
		mapPathSet(_token, Path({
			pathIn: pathIn,
			pathOut: pathOut
		}));
	}

	function updateMapPath(
		address _token, 
		address[] calldata pathIn,
		address[] calldata pathOut
	)
		external
		onlyOwners
	{
		require(mapPath.inserted[_token], "Swapper: Token doesnt exist");
		mapPathSet(_token, Path({
			pathIn: pathIn,
			pathOut: pathOut
		}));
	}
	
	function removeMapPath(
		address _token
	)
		external
		onlyOwners
	{
		require(mapPath.inserted[_token], "Swapper: Token doesnt exist");
		mapPathRemove(_token);
	}

	function addInflu(
		string calldata name,
		address to,
		uint until,
		uint rate,
		address[] calldata path,
		uint discountRate
	) 
		external
		onlyOwners
	{
		require(!influInserted[name], "Swapper: Influ already exists");

		allInflus.push(name);
		influInserted[name] = true;

		influData[name] = Sponso({
			to: to,
			rate: rate,
			until: until,
			released: 0,
			claimable: 0,
			path: path,
			discountRate: discountRate
		});
	}

	function updateInflu(
		string calldata name,
		address to,
		uint until,
		uint rate,
		address[] calldata path,
		uint discountRate
	)
		external
		onlyOwners
	{
		require(influInserted[name], "Swapper: Influ doesnt exist exists");

		Sponso memory cur = influData[name];

		influData[name] = Sponso({
			to: to,
			rate: rate,
			until: until,
			released: cur.released,
			claimable: cur.claimable,
			path: path,
			discountRate: discountRate
		});
	}

	function releaseInflu(
		string calldata name
	) external
	{
		require(influInserted[name], "Swapper: Influ doesnt exist exists");
		
		Sponso storage cur = influData[name];
		
		require(cur.claimable > 0, "Swapper: Nothing to claim");

		uint amount;
		if (cur.path[cur.path.length - 1] != token)
			amount =  IJoeRouter02(router).getAmountsOut(
				cur.claimable,
				cur.path
			)[cur.path.length - 1];
		else
			amount = cur.claimable;

		cur.released += cur.claimable;
		cur.claimable = 0;

		IERC20(cur.path[cur.path.length - 1])
			.transferFrom(futur, cur.to, amount);
	}

	function swapCreate(
		address _tokenIn, 
		address user, 
		uint price,
		string calldata sponso
	) 
		external
		onlyHandler
	{
		require(openSwapCreate, "Swapper: Not open");
		_swapCreation(_tokenIn, user, price, sponso);
	}

	function swapClaim(
		address _tokenOut, 
		address user, 
		uint rewardsTotal,
		uint feesTotal
	) 
		external
		onlyHandler
	{
		require(openSwapClaim, "Swapper: Not open");
		_swapClaim(_tokenOut, user, rewardsTotal, feesTotal);
	}
	
	// external setters
	function setToken(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: Token cannot be address zero");
		token = _new;
	}

	function setFutur(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: Futur cannot be address zero");
		futur = _new;
	}

	function setDistri(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: Distri cannot be address zero");
		distri = _new;
	}

	function setLpHandler(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: LpHandler cannot be address zero");
		lpHandler = _new;
	}

	function setRouter(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: Router cannot be address zero");
		router = _new;
	}

	function setNative(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: Native cannot be address zero");
		native = _new;
	}

	function setHandler(address _new) external onlySuperOwner {
		require(_new != address(0), "Swapper: Handler cannot be address zero");
		handler = _new;
	}

	function setFuturFee(uint _new) external onlySuperOwner {
		futurFee = _new;
	}

	function setRewardsFee(uint _new) external onlySuperOwner {
		rewardsFee = _new;
	}

	function setLpFee(uint _new) external onlySuperOwner {
		lpFee = _new;
	}

	function setSwapLiquifyCreate(bool _new) external onlyOwners {
		swapLiquifyCreate = _new;
	}
	
	function setSwapLiquifyClaim(bool _new) external onlyOwners {
		swapLiquifyClaim = _new;
	}
	
	function setSwapFutur(bool _new) external onlySuperOwner {
		swapFutur = _new;
	}
	
	function setSwapRewards(bool _new) external onlySuperOwner {
		swapRewards = _new;
	}
	
	function setSwapLpPool(bool _new) external onlySuperOwner {
		swapRewards = _new;
	}
	
	function setSwapPayee(bool _new) external onlySuperOwner {
		swapPayee = _new;
	}

	function setSwapTokensAmountCreate(uint _new) external onlyOwners {
		swapTokensAmountCreate = _new;
	}

	function setOpenSwapCreate(bool _new) external onlyOwners {
		openSwapCreate = _new;
	}
	
	function setOpenSwapClaim(bool _new) external onlyOwners {
		openSwapClaim = _new;
	}
	
	// external view
	function getMapPathSize() external view returns(uint) {
		return mapPath.keys.length;
	}
	
	function getMapPathKeysBetweenIndexes(
		uint iStart,
		uint iEnd
	) 
		external 
		view 
		returns(address[] memory)
	{
		address[] memory keys = new address[](iEnd - iStart);
		for (uint i = iStart; i < iEnd; i++)
			keys[i - iStart] = mapPath.keys[i];
		return keys;
	}
	
	function getMapPathBetweenIndexes(
		uint iStart,
		uint iEnd
	)
		external
		view
		returns (Path[] memory)
	{
		Path[] memory path = new Path[](iEnd - iStart);
		for (uint i = iStart; i < iEnd; i++)
			path[i - iStart] = mapPath.values[mapPath.keys[i]];
		return path;
	}

	function getMapPathForKey(address key) external view returns(Path memory) {
		require(mapPath.inserted[key], "Swapper: Key doesnt exist");
		return mapPath.values[key];
	}

	function getAllInfluSize() external view returns(uint) {
		return allInflus.length;
	}
	
	function getInfluDataPath(string calldata name) external view returns(address[] memory) {
		return influData[name].path;
	}
	
	function getAllInflusBetweenIndexes(
		uint iStart,
		uint iEnd
	)
		external
		view
		returns (string[] memory)
	{
		string[] memory influ = new string[](iEnd - iStart);
		for (uint i = iStart; i < iEnd; i++)
			influ[i - iStart] = allInflus[i];
		return influ;
	}

	// internal
	function _swapCreation(
		address _tokenIn, 
		address user, 
		uint price,
		string memory sponso
	) 
		internal
	{
		require(price > 0, "Swapper: Nothing to swap");
		
		if (influInserted[sponso]) {
			if (block.timestamp <= influData[sponso].until) {
				if (influData[sponso].discountRate > 0)
					price -= price * influData[sponso].discountRate / 10000;
				influData[sponso].claimable += price * influData[sponso].rate / 10000;
			}
		}

		if (_tokenIn == token) {
			IERC20(token).transferFrom(user, address(this), price);
			_swapCreationToken();
		} else {
			_swapCreationOtherToken(_tokenIn, user, price);
			_swapCreationToken();
		}
	}

	function _swapCreationToken() internal {
		uint256 contractTokenBalance = IERC20(token).balanceOf(address(this));

		if (contractTokenBalance >= swapTokensAmountCreate && swapLiquifyCreate && !swapping) {
			swapping = true;
        
			if (swapFutur) {
				uint256 futurTokens = contractTokenBalance * futurFee / 10000;
				swapAndSendToFee(futur, futurTokens);
			}

			if (swapRewards) {
				uint256 rewardsPoolTokens = contractTokenBalance * rewardsFee / 10000;
				IERC20(token).transfer(distri, rewardsPoolTokens);
			}

			if (swapLpPool) {
				uint256 swapTokens = contractTokenBalance * lpFee / 10000;
				swapAndLiquify(swapTokens);
			}

			if (swapPayee)
				swapTokensForEth(IERC20(token).balanceOf(address(this)));

			swapping = false;
		}
	}

	function _swapCreationOtherToken(address _tokenIn, address user, uint price) internal {
		require(mapPath.inserted[_tokenIn], "Swapper: Unknown _token");

		uint toTransfer = IJoeRouter02(router).getAmountsIn(
			price,
			mapPath.values[_tokenIn].pathIn
		)[0];

		IERC20(_tokenIn).transferFrom(user, address(this), toTransfer);

        IERC20(_tokenIn).approve(router, toTransfer);

        IJoeRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            toTransfer,
            0, // if transfer fee
            mapPath.values[_tokenIn].pathIn,
            address(this),
            block.timestamp
        );
	}

	function _swapClaim(
		address _tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) 
		internal 
	{
		if (rewardsTotal + feesTotal > 0) {
			if (swapLiquifyClaim)
				IERC20(token).transferFrom(distri, address(this), rewardsTotal + feesTotal);
			else if (rewardsTotal > 0)
				IERC20(token).transferFrom(distri, address(this), rewardsTotal);

			if (_tokenOut == token) {
				if (rewardsTotal > 0)
					IERC20(token).transfer(user, rewardsTotal);
			} else {
				require(mapPath.inserted[_tokenOut], "Swapper: Unknown _token");

				IERC20(token).approve(router, rewardsTotal);

				IJoeRouter02(router)
					.swapExactTokensForTokensSupportingFeeOnTransferTokens(
						rewardsTotal,
						0,
						mapPath.values[_tokenOut].pathOut,
						user,
						block.timestamp
					);
			}
		}
	}
		
	function swapAndSendToFee(address destination, uint256 _tokens) private {
        uint256 initialETHBalance = address(this).balance;

		swapTokensForEth(_tokens);

		uint256 newBalance = (address(this).balance) - initialETHBalance;

		payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 _tokens) private {
        uint256 half = _tokens / 2;
        uint256 otherHalf = _tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForEth(uint256 _tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = token;
		path[1] = native;

        IERC20(token).approve(router, _tokenAmount);

        IJoeRouter02(router).swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 _tokenAmount, uint256 ethAmount) private {
        IERC20(token).approve(router, _tokenAmount);

        IJoeRouter02(router).addLiquidityAVAX{value: ethAmount}(
            token,
            _tokenAmount,
            0,
            0,
            lpHandler,
            block.timestamp
        );
    }

	function mapPathSet(
        address key,
        Path memory value
    ) private {
        if (mapPath.inserted[key]) {
            mapPath.values[key] = value;
        } else {
            mapPath.inserted[key] = true;
            mapPath.values[key] = value;
            mapPath.indexOf[key] = mapPath.keys.length;
            mapPath.keys.push(key);
        }
    }

	function mapPathRemove(address key) private {
        if (!mapPath.inserted[key]) {
            return;
        }

        delete mapPath.inserted[key];
        delete mapPath.values[key];

        uint256 index = mapPath.indexOf[key];
        uint256 lastIndex = mapPath.keys.length - 1;
        address lastKey = mapPath.keys[lastIndex];

        mapPath.indexOf[lastKey] = index;
        delete mapPath.indexOf[key];

		if (lastIndex != index)
			mapPath.keys[index] = lastKey;
        mapPath.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract SplitterTeam is Context {
	struct Data {
		uint duration;
		uint totalShares;
		uint[] shares;
	}

	struct Last {
		uint updateTime;
		uint index;
	}

	address[] public splitters;

	Data[] public datas;

	mapping(address => uint) public releasedNative;
	Last public lastNative;

	mapping(IERC20 => mapping(address => uint)) public releasedErc20;
	mapping(IERC20 => Last) public lastErc20;

	bool private lock;

	modifier nonReentrant() {
		require(!lock, "SplitterTeam: Reentrancy");
		lock = true;
		_;
		lock = false;
	}

	// Deployment
	constructor(
		address[] memory _splitters,
		uint[] memory _duration,
		uint[][] memory _shares
	)
	{
		require(
			_splitters.length > 0, 
			"SplitterTeam: Splitters length cannot be zero"
		);
		require(
			_duration.length > 0, 
			"SplitterTeam: Duration length cannot be zero"
		);
		require(
			_duration.length == _shares.length, 
			"SplitterTeam: Duration/Shares length mismatch"
		);

		for (uint i = 0; i < _splitters.length; i++)
			_addSplitter(_splitters[i]);

		for (uint i = 0; i < _duration.length; i++) {
			require(
				_splitters.length == _shares[i].length, 
				"SplitterTeam: Splitters/Shares length mismatch"
			);
			_addData(_duration[i], _shares[i]);
		}
	}
	
	function _addSplitter(address _splitter) private {
		require(
			_splitter != address(0), 
			"SplitterTeam: Splitter cannot be address zero"
		);

		splitters.push(_splitter);
	}

	function _addData(
		uint _duration, 
		uint[] memory _shares
	) 
		private 
	{
		uint _totalShares;

		for (uint i = 0; i < _shares.length; i++) {
			require(_shares[i] > 0, "SplitterTeam: Share cannot be zero");
			_totalShares += _shares[i];
		}

		datas.push(Data({
			duration: _duration,
			totalShares: _totalShares,
			shares: _shares
		}));
	}

	// Native requirement
	receive() external payable {}

	// Core
	function release() external nonReentrant {
		Data storage data = datas[lastNative.index];

		uint balance = address(this).balance;
		uint totalShares = data.totalShares;
		uint length = splitters.length;

		for (uint i = 0; i < length; i++) {
			uint amount = balance * data.shares[i] / totalShares;

			require(amount > 0, "SplitterTeam: Amount cannot be zero");

			address splitter = splitters[i];
			
			releasedNative[splitter] += amount;
			Address.sendValue(payable(splitter), amount);
		}

		_update(lastNative, data.duration);
	}

	function release(IERC20 token) external nonReentrant {
		Last storage last = lastErc20[token];
		Data storage data = datas[last.index];

		uint balance = token.balanceOf(address(this));
		uint totalShares = data.totalShares;
		uint length = splitters.length;

		for (uint i = 0; i < length; i++) {
			uint amount = balance * data.shares[i] / totalShares;

			require(amount > 0, "SplitterTeam: Amount cannot be zero");
			
			address splitter = splitters[i];
			
			releasedErc20[token][splitter] += amount;
			SafeERC20.safeTransfer(token, splitter, amount);
		}
		
		_update(last, data.duration);
	}
	
	function _update(Last storage last, uint duration) private {
		if (last.index < datas.length - 1) {
			uint lastUpdate = last.updateTime;

			if (lastUpdate == 0) {
				last.updateTime = block.timestamp;
			} else if (lastUpdate + duration < block.timestamp) {
				last.updateTime = block.timestamp;
				last.index += 1;
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


contract Owners {
	address[] public owners;
	mapping(address => bool) public isOwner;
	mapping(address => mapping(bytes4 => uint)) private last;
	uint private resetTime = 12 * 3600;

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
		if (owners[0] != msg.sender) {
			require(
				last[msg.sender][msg.sig] + resetTime < block.timestamp,
				"Owners: Not yet"
			);
			last[msg.sender][msg.sig] = block.timestamp;
		}
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
		require(isOwner[_new], "Owner: Not owner");
		require(_new != owners[0]);

		uint length = owners.length;

		for (uint i = 1; i < length; i++) {
			if (owners[i] == _new) {
				owners[i] = owners[length - 1];
				owners.pop();
				break;
			}
		}

		isOwner[_new] = false;
	}

	function getOwnersSize() external view returns(uint) {
		return owners.length;
	}

	function setResetTime(uint _new) external onlySuperOwner {
		resetTime = _new;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}