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

    struct Spaceship {
        uint256 power;
        uint256 points;
        bool staked;
        bool inBattle;
        uint256 stakeStartTime;
        uint256 tokenMissiles;
        uint256 tokenShields;
    }

    uint256 counter = 0;
    uint256 nextId = 0;
    uint256 MAX = 100;
    uint256 stakingCounter = 0;
    uint256 gas = 350000;
    uint256 chainId;
    mapping(uint256 => Spaceship) spaceships;
    mapping(uint256 => Battle) public battles;
    mapping(address => mapping(uint256 => bool)) public tokenTravelled;
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
    uint32 callbackGasLimit = 200000;

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
        uint256 _chainId,
        uint256 startId,
        uint256 _max,
        uint64 subscriptionId
    ) ERC721("OmniChainNFT", "OOCCNFT") VRFConsumerBaseV2(vrfCoordinator) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        nextId = startId;
        chainId = _chainId;
        MAX = _max;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft-fleet-server.herokuapp.com/";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    "?chainId=",
                    chainId,
                    "&power=",
                    spaceships[tokenId].power
                )
            );
    }

    function mint() external payable {
        require(nextId + 1 <= MAX);
        nextId += 1;
        _safeMint(msg.sender, nextId);
        spaceships[nextId] = Spaceship(2, 0, false, false, 0, 0, 0);
        counter += 1;
    }

    function stake(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        require(!spaceships[tokenId].staked);

        spaceships[tokenId] = Spaceship(
            SafeMath.mul(SafeMath.div(spaceships[tokenId].power, 5), 4),
            spaceships[tokenId].points,
            true,
            spaceships[tokenId].inBattle,
            block.timestamp,
            0,
            0
        );

        stakingCounter += 1;
    }

    function unstake(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        require(spaceships[tokenId].staked);

        spaceships[tokenId] = Spaceship(
            SafeMath.mul(SafeMath.div(spaceships[tokenId].power, 4), 5),
            spaceships[tokenId].points,
            false,
            spaceships[tokenId].inBattle,
            block.timestamp,
            0,
            0
        );

        stakingCounter -= 1;
    }

    function claim(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));
        require(spaceships[tokenId].staked);
        uint256 timeDifference = block.timestamp -
            spaceships[tokenId].stakeStartTime;
        spaceships[tokenId] = Spaceship(
            spaceships[tokenId].power,
            SafeMath.add(
                spaceships[tokenId].points,
                SafeMath.div(timeDifference, 86400) * 2
            ),
            spaceships[tokenId].staked,
            spaceships[tokenId].inBattle,
            block.timestamp,
            0,
            0
        );
    }

    function merge(uint256 tokenId1, uint256 tokenId2) public {
        require(
            msg.sender == ownerOf(tokenId1) && msg.sender == ownerOf(tokenId2)
        );
        if (spaceships[tokenId1].power > spaceships[tokenId2].power) {
            handleMerge(tokenId2, tokenId1);
        } else {
            handleMerge(tokenId1, tokenId2);
        }
    }

    function handleMerge(uint256 smaller, uint256 bigger) internal {
        spaceships[bigger] = Spaceship(
            SafeMath.add(
                spaceships[bigger].power,
                SafeMath.mul(SafeMath.div(spaceships[smaller].power, 5), 2)
            ),
            SafeMath.add(spaceships[bigger].points, spaceships[smaller].points),
            spaceships[bigger].staked,
            spaceships[bigger].inBattle,
            spaceships[bigger].stakeStartTime,
            0,
            0
        );

        delete spaceships[smaller];
        _burn(smaller);
    }

    // checks if tokens exists and requests randomness. Returns request id
    function battle(uint256 attackerTokenId, uint256 defenderTokenId)
        public
        returns (uint256 requestId)
    {
        require(msg.sender == ownerOf(attackerTokenId));
        require(_exists(defenderTokenId));
        require(
            !spaceships[attackerTokenId].inBattle &&
                !spaceships[defenderTokenId].inBattle
        );
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        battles[requestId] = Battle(attackerTokenId, defenderTokenId, false);

        spaceships[attackerTokenId] = Spaceship(
            spaceships[attackerTokenId].power,
            spaceships[attackerTokenId].points,
            spaceships[attackerTokenId].staked,
            true,
            spaceships[attackerTokenId].stakeStartTime,
            0,
            0
        );
        spaceships[defenderTokenId] = Spaceship(
            spaceships[defenderTokenId].power,
            spaceships[defenderTokenId].points,
            spaceships[defenderTokenId].staked,
            true,
            spaceships[defenderTokenId].stakeStartTime,
            0,
            0
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        battles[requestId] = Battle(
            battles[requestId].attackerTokenId,
            battles[requestId].defenderTokenId,
            true
        );
        uint256 randomNum = randomWords[0] &
            ((spaceships[battles[requestId].attackerTokenId].power +
                spaceships[battles[requestId].defenderTokenId].power) + 1);
        if (
            battles[requestId].attackerTokenId <
            battles[requestId].defenderTokenId
        ) {
            if (randomNum <= battles[requestId].attackerTokenId) {
                setPointsAfterBattle(
                    battles[requestId].attackerTokenId,
                    battles[requestId].defenderTokenId
                );
            } else {
                setPointsAfterBattle(
                    battles[requestId].defenderTokenId,
                    battles[requestId].attackerTokenId
                );
            }
        } else {
            if (randomNum <= battles[requestId].defenderTokenId) {
                setPointsAfterBattle(
                    battles[requestId].defenderTokenId,
                    battles[requestId].attackerTokenId
                );
            } else {
                setPointsAfterBattle(
                    battles[requestId].attackerTokenId,
                    battles[requestId].defenderTokenId
                );
            }
        }
        spaceships[battles[requestId].attackerTokenId] = Spaceship(
            spaceships[battles[requestId].attackerTokenId].power,
            spaceships[battles[requestId].attackerTokenId].points,
            spaceships[battles[requestId].attackerTokenId].staked,
            false,
            spaceships[battles[requestId].attackerTokenId].stakeStartTime,
            0,
            0
        );
        spaceships[battles[requestId].defenderTokenId] = Spaceship(
            spaceships[battles[requestId].defenderTokenId].power,
            spaceships[battles[requestId].defenderTokenId].points,
            spaceships[battles[requestId].defenderTokenId].staked,
            false,
            spaceships[battles[requestId].defenderTokenId].stakeStartTime,
            0,
            0
        );
    }

    function setPointsAfterBattle(uint256 winner, uint256 loser) internal {
        spaceships[winner] = Spaceship(
            SafeMath.add(
                spaceships[winner].power,
                SafeMath.div(spaceships[loser].power, 2)
            ),
            SafeMath.add(spaceships[winner].points, spaceships[loser].points),
            spaceships[winner].staked,
            false,
            spaceships[winner].stakeStartTime,
            0,
            0
        );

        spaceships[loser] = Spaceship(
            SafeMath.sub(
                spaceships[loser].power,
                SafeMath.div(spaceships[loser].power, 2)
            ),
            0,
            spaceships[loser].staked,
            false,
            spaceships[loser].stakeStartTime,
            0,
            0
        );

        if (spaceships[loser].power == 1) {
            _burn(loser);
            delete spaceships[loser];
        }
    }

    function crossChain(
        uint16 _dstChainId,
        bytes calldata _destination,
        uint256 tokenId
    ) public payable {
        require(msg.sender == ownerOf(tokenId));
        require(!spaceships[tokenId].staked);
        // burn NFT
        _burn(tokenId);
        counter -= 1;
        bytes memory payload = abi.encode(
            msg.sender,
            tokenId,
            spaceships[tokenId].power,
            spaceships[tokenId].points
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
        require(msg.value >= messageFee);
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
        spaceships[tokenId] = Spaceship(power, points, false, false, 0, 0, 0);

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

    function getSpaceByTokenId(uint256 _id)
        public
        view
        returns (Spaceship memory spaceship)
    {
        return spaceships[_id];
    }

    // function getAllSpaceships()
    //     public
    //     view
    //     returns (
    //         uint256[] memory,
    //         uint256[] memory,
    //         uint256[] memory,
    //         uint256[] memory,
    //         uint256[] memory,
    //         bool[] memory,
    //         bool[] memory
    //     )
    // {
    //     uint256 total = totalSupply();
    //     uint256[] memory tokenIds = new uint256[](total);
    //     uint256[] memory powers = new uint256[](total);
    //     uint256[] memory resources = new uint256[](total);
    //     uint256[] memory missiles = new uint256[](total);
    //     uint256[] memory shields = new uint256[](total);
    //     bool[] memory tokensStaked = new bool[](total);
    //     bool[] memory tokensInBattle = new bool[](total);

    //     for (uint256 i = 0; i < total; i++) {
    //         uint256 tokenId = tokenByIndex(i);
    //         tokenIds[i] = tokenId;
    //         powers[i] = spaceships[tokenId].power;
    //         resources[i] = spaceships[tokenId].points;
    //         missiles[i] = spaceships[tokenId].tokenMissiles;
    //         shields[i] = spaceships[tokenId].tokenShields;
    //         tokensStaked[i] = spaceships[tokenId].staked;
    //         tokensInBattle[i] = spaceships[tokenId].inBattle;
    //     }
    //     return (
    //         tokenIds,
    //         powers,
    //         resources,
    //         missiles,
    //         shields,
    //         tokensStaked,
    //         tokensInBattle
    //     );
    // }

    // function getSpaceshipsByOwner(address owner)
    //     public
    //     view
    //     returns (
    //         uint256[] memory,
    //         uint256[] memory,
    //         uint256[] memory,
    //         uint256[] memory,
    //         uint256[] memory,
    //         bool[] memory,
    //         bool[] memory
    //     )
    // {
    //     uint256 balance = balanceOf(owner);
    //     uint256[] memory tokenIds = new uint256[](balance);
    //     uint256[] memory powers = new uint256[](balance);
    //     uint256[] memory resources = new uint256[](balance);
    //     uint256[] memory missiles = new uint256[](balance);
    //     // this is a temporary solution for stack too deep issue
    //     address ownerCopy = owner;
    //     uint256[] memory shields = new uint256[](balance);
    //     bool[] memory tokensStaked = new bool[](balance);
    //     bool[] memory tokensInBattle = new bool[](balance);

    //     for (uint256 i = 0; i < balance; i++) {
    //         uint256 tokenId = tokenOfOwnerByIndex(ownerCopy, i);
    //         tokenIds[i] = tokenId;
    //         powers[i] = spaceships[tokenId].power;
    //         resources[i] = spaceships[tokenId].points;
    //         missiles[i] = spaceships[tokenId].tokenMissiles;
    //         shields[i] = spaceships[tokenId].tokenShields;
    //         tokensStaked[i] = spaceships[tokenId].staked;
    //         tokensInBattle[i] = spaceships[tokenId].inBattle;
    //     }
    //     return (
    //         tokenIds,
    //         powers,
    //         resources,
    //         missiles,
    //         shields,
    //         tokensStaked,
    //         tokensInBattle
    //     );
    // }

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