//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./SafeMath.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract OmniChainNFT is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ILayerZeroReceiver,
    VRFConsumerBaseV2
{
    struct Battle {
        uint256 attackerTokenId;
        uint256 defenderTokenId;
        bool battleFinished;
    }

    uint256 counter = 0;
    uint256 nextId = 0;
    uint256 MAX = 100;
    uint256 stakingCounter = 0;
    uint256 gas = 350000;
    mapping(uint256 => uint256) fleetPowers;
    mapping(uint256 => uint256) stakeStartTime;
    mapping(uint256 => uint256) tokenPoints;
    mapping(uint256 => bool) fleetStaked;
    mapping(uint256 => bool) fleetsInBattle;
    mapping(uint256 => Battle) battles;
    // chianlink vars
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 s_keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    ILayerZeroEndpoint public endpoint;
    event ReceiveNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );

    constructor(
        address _endpoint,
        uint256 startId,
        uint256 _max,
        uint64 subscriptionId
    ) ERC721("OmniChainNFT", "OOCCNFT") VRFConsumerBaseV2(vrfCoordinator) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        nextId = startId;
        MAX = _max;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function mint() external payable {
        require(nextId + 1 <= MAX, "Exceeds supply");
        nextId += 1;
        _safeMint(msg.sender, nextId);
        fleetPowers[nextId] = 2;
        fleetStaked[nextId] = false;
        counter += 1;
    }

    function stake(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        require(!fleetStaked[tokenId], "Already staked");
        fleetStaked[tokenId] = true;
        fleetPowers[tokenId] = SafeMath.mul(
            SafeMath.div(fleetPowers[tokenId], 5),
            4
        );
        stakeStartTime[tokenId] = block.timestamp;
        stakingCounter += 1;
    }

    function unstake(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        require(fleetStaked[tokenId], "Not staked");
        fleetStaked[tokenId] = false;
        fleetPowers[tokenId] = SafeMath.mul(
            SafeMath.div(fleetPowers[tokenId], 4),
            5
        );
        stakingCounter -= 1;
    }

    function claim(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        require(fleetStaked[tokenId], "Not staked");
        uint256 timeDifference = block.timestamp - stakeStartTime[tokenId];
        tokenPoints[tokenId] += SafeMath.div(timeDifference, 86400) * 2;
        stakeStartTime[tokenId] = block.timestamp;
    }

    // checks if tokens exists and requests randomness. Returns request id
    function battle(uint256 attackerTokenId, uint256 defenderTokenId)
        public
        returns (uint256 requestId)
    {
        require(msg.sender == ownerOf(attackerTokenId), "Not the owner");
        require(_exists(defenderTokenId), "Defender does not exist");
        require(
            !fleetsInBattle[attackerTokenId] &&
                !fleetsInBattle[defenderTokenId],
            "Attacker Or defender cannot be in battle"
        );
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        battles[requestId] = Battle(attackerTokenId, defenderTokenId, false);

        fleetsInBattle[attackerTokenId] = true;
        fleetsInBattle[defenderTokenId] = true;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // CALLBACK FUNCTION
        // ISSUE IS ACSESSING ATTACKERTOKENID AND DEFENDERTOKENID FROM BATTLE FUNCTION IN HERE
        Battle storage curBattle = battles[requestId];
        battles[requestId] = Battle(
            curBattle.attackerTokenId,
            curBattle.defenderTokenId,
            true
        );
        uint256 randomNum = randomWords[0] &
            ((fleetPowers[curBattle.attackerTokenId] +
                fleetPowers[curBattle.defenderTokenId]) + 1);
        if (curBattle.attackerTokenId < curBattle.defenderTokenId) {
            if (randomNum <= curBattle.attackerTokenId) {
                setPointsAfterBattle(
                    curBattle.attackerTokenId,
                    curBattle.defenderTokenId
                );
            } else {
                setPointsAfterBattle(
                    curBattle.defenderTokenId,
                    curBattle.attackerTokenId
                );
            }
        } else {
            if (randomNum <= curBattle.defenderTokenId) {
                setPointsAfterBattle(
                    curBattle.defenderTokenId,
                    curBattle.attackerTokenId
                );
            } else {
                setPointsAfterBattle(
                    curBattle.attackerTokenId,
                    curBattle.defenderTokenId
                );
            }
        }
        delete fleetsInBattle[curBattle.attackerTokenId];
        delete fleetsInBattle[curBattle.defenderTokenId];
    }

    function setPointsAfterBattle(uint256 winner, uint256 loser) internal {
        fleetPowers[winner] += SafeMath.div(fleetPowers[loser], 2);
        fleetPowers[loser] -= SafeMath.div(fleetPowers[loser], 2);
    }

    function crossChain(
        uint16 _dstChainId,
        bytes calldata _destination,
        uint256 tokenId
    ) public payable {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        require(!fleetStaked[tokenId], "Token cannot be staked");
        // burn NFT
        _burn(tokenId);
        counter -= 1;
        bytes memory payload = abi.encode(
            msg.sender,
            tokenId,
            fleetPowers[tokenId],
            tokenPoints[tokenId]
        );
        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint256 messageFee, ) = endpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= messageFee,
            "Must send enough value to cover messageFee"
        );
        endpoint.send{value: msg.value}(
            _dstChainId,
            _destination,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint));
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        (
            address toAddress,
            uint256 tokenId,
            uint256 power,
            uint256 points
        ) = abi.decode(_payload, (address, uint256, uint256, uint256));
        // mint the tokens
        _safeMint(toAddress, tokenId);
        counter += 1;
        fleetPowers[tokenId] = power;
        tokenPoints[tokenId] = points;
        emit ReceiveNFT(_srcChainId, toAddress, tokenId, counter);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                _payInZRO,
                _adapterParams
            );
    }

    function getAllSpaceships() public view returns (uint256[] memory) {
        uint256 total = totalSupply();
        uint256[] memory list = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            list[i] = tokenByIndex(i);
        }
        return list;
    }

    function getSpaceshipsByOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory list = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            list[i] = tokenOfOwnerByIndex(owner, i);
        }
        return list;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}