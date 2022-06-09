// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface PlatinumManager is IERC20 { }
interface InfiniteManager is IERC20 { }
interface MetaManager is IERC20 { }

contract MSPSCalculator is Ownable {

  PlatinumManager public platinum;
  InfiniteManager public infinite;
  MetaManager public meta;

  using SafeMath for uint256;
  using SafeMath for uint64;
  using SafeMath for uint;

  struct Parameters {
      uint64 legendary;
      uint64 epic;
      uint64 rare;
      uint64 common;
      uint64 meta;
      uint64 infinite;
      uint64 platinum;
      uint64 precision;
  }

  Parameters public parameters = Parameters({
     legendary: 20000,
     epic: 10000,
     rare: 5000,
     common: 2500,
     meta: 40000,
     infinite: 20000,
     platinum: 10000,
     precision: 10000
  });

  struct Tier {
      uint legendary;
      uint epic;
      uint rare;
      uint common;
  }

  Tier public tiers = Tier({
     legendary: 400,
     epic: 300,
     rare: 200,
     common: 100
  });


  struct TArray {
      uint[] L;
      uint[] E;
      uint[] R;
      uint[] C;
  }

  constructor( address _platinum, address _infinite,
      address _meta)  {
    platinum = PlatinumManager(_platinum);
    infinite = InfiniteManager(_infinite);
    meta = MetaManager(_meta);
  }


  function updateParameters(uint64 _legendary,
    uint64 _epic, uint64 _rare, uint64 _common,
    uint64 _meta, uint64 _infinite, uint64 _platinum, uint64 _precision
    ) onlyOwner external {
      parameters.legendary = _legendary;
      parameters.epic = _epic;
      parameters.rare = _rare;
      parameters.common = _common;
      parameters.meta = _meta;
      parameters.infinite = _infinite;
      parameters.platinum = _platinum;
      parameters.precision = _precision;
  }


  function calculateMPSP(address from, uint[] memory nfts) external view returns (uint256) {
    uint256 total = 0;
    uint256 platinums = platinum.balanceOf(from);
    uint256 infinites = infinite.balanceOf(from);
    uint256 metas = meta.balanceOf(from);
    if (platinums > 0){
      total = total + parameters.platinum;
    }
    if (infinites > 0){
      total = total + parameters.infinite;
    }
    if (metas > 0){
      total = total + parameters.meta + parameters.precision * metas;
    }

    uint totalLegendary = calculateTotalPerTier(nfts, tiers.legendary );
    if (totalLegendary > 0){
      total = total + mPSPSingles(tiers.legendary, totalLegendary);
      uint pairsLegendary = calculateTotalPairs(nfts, tiers.legendary );
      total = total + mPSPPair(tiers.legendary)*pairsLegendary;
      uint thirdsLegendary = calculateTotalThirds(nfts, tiers.legendary );
      total = total + mPSPThirds(tiers.legendary)*thirdsLegendary;
      uint pokersLegendary = calculateTotalPokers(nfts, tiers.legendary );
      total = total + mPSPPokers(tiers.legendary)*pokersLegendary;
    }

    uint totalEpic = calculateTotalPerTier(nfts, tiers.epic );
    if (totalEpic > 0){
      uint pairsEpic = calculateTotalPairs(nfts, tiers.epic );
      total = total + mPSPPair(tiers.epic)*pairsEpic;
      uint thirdsEpic = calculateTotalThirds(nfts, tiers.epic );
      total = total + mPSPThirds(tiers.epic)*thirdsEpic;
      uint pokersEpic = calculateTotalPokers(nfts, tiers.epic );
      total = total + mPSPPokers(tiers.epic)*pokersEpic;
    }

    uint totalRare = calculateTotalPerTier(nfts, tiers.rare );
    if (totalRare > 0){
      uint pairsRare = calculateTotalPairs(nfts, tiers.rare );
      total = total + mPSPPair(tiers.rare)*pairsRare;
      uint thirdsRare = calculateTotalThirds(nfts, tiers.rare );
      total = total + mPSPThirds(tiers.rare)*thirdsRare;
      uint pokersRare = calculateTotalPokers(nfts, tiers.rare );
      total = total + mPSPPokers(tiers.rare)*pokersRare;
    }

    uint totalCommon = calculateTotalPerTier(nfts, tiers.common );
    if (totalCommon > 0){
      uint pairsCommon = calculateTotalPairs(nfts, tiers.common );
      total = total + mPSPPair(tiers.rare)*pairsCommon;
      uint thirdsCommon = calculateTotalThirds(nfts, tiers.common );
      total = total + mPSPThirds(tiers.rare)*thirdsCommon;
      uint pokersCommon = calculateTotalPokers(nfts, tiers.common );
      total = total + mPSPPokers(tiers.rare)*pokersCommon;
    }

    return total;
  }
  //2212
  //2201

  function calculateNodesMPSP(address from) public view returns (uint, uint, uint, uint) {
    uint total = 0;
    uint256 platinums = platinum.balanceOf(from);
    uint256 infinites = infinite.balanceOf(from);
    uint256 metas = meta.balanceOf(from);
    if (platinums > 0){
      total = total + parameters.platinum;
    }
    if (infinites > 0){
      total = total + parameters.infinite;
    }
    if (metas > 0){
      total = total + parameters.meta + parameters.precision * metas;
    }
    return (platinums, infinites, metas, total);
  }


  function tMPSPAllTiers(uint[] memory nfts) public view returns (Tier memory) {


    Tier memory counters = Tier({
       legendary: 0,
       epic: 0,
       rare: 0,
       common: 0
    });

    TArray memory arrays = TArray({
      L: new uint[](nfts.length),
      E: new uint[](nfts.length),
      R: new uint[](nfts.length),
      C: new uint[](nfts.length)
   });

    uint[] memory groups = new uint[](nfts.length);
    uint[] memory groupCounter = new uint[](nfts.length);
    uint[][] memory groupAll = new uint[][](nfts.length*nfts.length);
    for (uint256 i = 0; i < nfts.length; i++) {
      uint[] memory temp = new uint[](nfts.length);
      groupAll[i] = temp;
    }
    for (uint256 i = 0; i < nfts.length; i++) {
        uint nft = nfts[i];
        uint group = (nft/1000)*1000;
        uint tier = ((nft-group) / 100)*100;
        if ( valueInArray(groups, groupCounter, group) == 0 ){
          uint index = nextIndexArray(groups);
          groups[index] = group;
          groupCounter[index] = 1;
          groupAll[index][0] = nft;
        } else  {
          uint index = indexInArray(groups, group);
          uint totalByGroup = valueInArray(groups, groupCounter, group);
          groupCounter[index] = totalByGroup + 1;
          groupAll[index][totalByGroup] = nft;
        }
    }


     for (uint256 i = 0; i < nextIndexArray(groups); i++) {
        uint group = groups[i];
        uint groupElements = groupCounter[i];
        uint[] memory _tiers = new uint[](4) ;
        uint[] memory tiersCounter = new uint[](4) ;
        uint[][] memory tiersAll = new uint[][](4*groupElements);
        for (uint256 l = 0; l < 4; l++) {
          uint[] memory temp = new uint[](groupElements);
          tiersAll[l] = temp;
        }
        for (uint256 k = 0; k < groupElements; k++) {
            uint nft = groupAll[i][k];
            uint tier = ((nft-group) / 100)*100;
            uint character = (nft-group-tier);
            uint totalInTier = valueInArray(_tiers, tiersCounter, tier);
            uint index = tier/100 -1;
            _tiers[index] = tier;
            tiersCounter[index] = totalInTier + 1;
            tiersAll[index][nextIndexArray(tiersAll[index])] = character;
        }

        //legendary
        uint total = 1;
        arrays.L = tiersAll[3];
        arrays.E = tiersAll[2];
        arrays.R = tiersAll[1];
        arrays.C = tiersAll[0];

        while (total != 0) {
            (uint _total, Tier memory _counters, TArray memory _arrays ) = calculateAllCombinations(groupElements, arrays);
            total = _total;
            counters.legendary = counters.legendary + _counters.legendary;
            counters.epic = counters.epic + _counters.epic;
            counters.rare = counters.rare + _counters.rare;
            counters.common = counters.common + _counters.common;
            arrays.L = _arrays.L;
            arrays.E = _arrays.E;
            arrays.R = _arrays.R;
            arrays.C = _arrays.C;
        }
    }
    return counters;
  }

  function calculateAllCombinations(uint size, TArray memory nfts ) public view returns (uint, Tier memory,  TArray memory) {

      Tier memory counters = Tier({
         legendary: 0,
         epic: 0,
         rare: 0,
         common: 0
      });

      TArray memory arrays = TArray({
        L: new uint[](size),
        E: new uint[](size),
        R: new uint[](size),
        C: new uint[](size)
     });

      uint total = 0;

      uint[] memory uniques= new uint[](size) ;

      for (uint256 i = 0; i < nfts.L.length; i++) {
          uint nft = nfts.L[i];
          if ( !existsInArray(uniques, nft)) {
            uniques[nextIndexArray(uniques)] = nft;
            total++;
            counters.legendary++;
          } else {
            arrays.L[nextIndexArray(arrays.L)] = nft;
          }
      }
      if (total < 4){
        for (uint256 i = 0; i < nfts.E.length; i++) {
            uint nft = nfts.E[i];
            if ( !existsInArray(uniques, nft)) {
              uniques[nextIndexArray(uniques)] = nft;
              total++;
              counters.epic++;
            } else {
              arrays.E[nextIndexArray(arrays.E)] = nft;
            }
        }
      }
      if (total < 4){
        for (uint256 i = 0; i < nfts.R.length; i++) {
            uint nft = nfts.R[i];
            if ( !existsInArray(uniques, nft)) {
              uniques[nextIndexArray(uniques)] = nft;
              total++;
              counters.rare++;
            } else {
              arrays.R[nextIndexArray(arrays.R)] = nft;
            }
        }
      }
      if (total < 4){
        for (uint256 i = 0; i < nfts.C.length; i++) {
            uint nft = nfts.C[i];
            if ( !existsInArray(uniques, nft)) {
              uniques[nextIndexArray(uniques)] = nft;
              total++;
              counters.common++;
            } else {
              arrays.C[nextIndexArray(arrays.C)] = nft;
            }
        }
      }


      if (total < 2){
          return (0, counters, arrays );
      }

      return (total, counters, arrays );
  }



    function calculateTotalPairs(uint[] memory nfts, uint targetTier) public view returns (uint256) {
      uint pairs = 0;
      uint size = nfts.length;
      uint[] memory possibles = new uint[](size) ;
      uint[] memory counter= new uint[](size) ;
      uint[] memory uniques= new uint[](size) ;
      for (uint256 i = 0; i < nfts.length; i++) {
          uint nft = nfts[i];
          uint group = (nft/1000)*1000;
          uint tier = ((nft-group) / 100)*100;
          uint character = (nft-group-tier);
          if ( tier == targetTier ){
              if ( valueInArray(possibles, counter, group) == 0 ){
                possibles[nextIndexArray(possibles)] = group;
                counter[nextIndexArray(counter)] = 1;
                uniques[nextIndexArray(uniques)] = nft;
              } else if ( valueInArray(possibles, counter, group) == 1) {
                if ( !existsInArray(uniques, nft)) {
                  counter[indexInArray(possibles, group)] = 2;
                  uniques[nextIndexArray(uniques)] = nft;
                  pairs++;
                }
              } else if ( valueInArray(possibles, counter, group) == 2 ) {
                if ( !existsInArray(uniques, nft)) {
                  counter[indexInArray(possibles, group)] = 3;
                  uniques[nextIndexArray(uniques)] = nft;
                  pairs--;
                }
              }
          }
      }
      return pairs;
    }



  function calculateTotalThirds(uint[] memory nfts, uint targetTier) public view returns (uint256) {
    uint thirds = 0;
    uint size = nfts.length;
    uint[] memory possibles= new uint[](size) ;
    uint[] memory counter= new uint[](size) ;
    uint[] memory uniques= new uint[](size) ;

    for (uint256 i = 0; i < nfts.length; i++) {
        uint nft = nfts[i];
        uint group = (nft/1000)*1000;
        uint tier = ((nft-group) / 100)*100;
        uint character = (nft-group-tier);
        if ( tier == targetTier ){
          if ( valueInArray(possibles, counter, group) == 0 ){
            possibles[nextIndexArray(possibles)] = group;
            counter[nextIndexArray(counter)] = 1;
              uniques[nextIndexArray(uniques)] = nft;
            } else if ( valueInArray(possibles, counter, group) == 1) {
              if ( !existsInArray(uniques, nft)) {
                counter[indexInArray(possibles, group)] = 2;
                uniques[nextIndexArray(uniques)] = nft;
              }
            } else if ( valueInArray(possibles, counter, group) == 2) {
              if ( !existsInArray(uniques, nft)) {
                counter[indexInArray(possibles, group)] = 3;
                uniques[nextIndexArray(uniques)] = nft;
                thirds++;
              }
            } else if ( valueInArray(possibles, counter, group)  == 3) {
              if ( !existsInArray(uniques, nft)) {
                counter[indexInArray(possibles, group)] = 4;
                uniques[nextIndexArray(uniques)] = nft;
                thirds--;
              }
            }
        }
    }
    return thirds;
  }

  function calculateTotalPokers(uint[] memory nfts, uint targetTier) public view returns (uint256) {
    uint pokers = 0;
    uint size = nfts.length;
    uint[] memory possibles= new uint[](size) ;
    uint[] memory counter= new uint[](size) ;
    uint[] memory uniques= new uint[](size) ;

    for (uint256 i = 0; i < nfts.length; i++) {
        uint nft = nfts[i];
        uint group = (nft/1000)*1000;
        uint tier = ((nft-group) / 100)*100;
        uint character = (nft-group-tier);
        if ( tier == targetTier ){
            if ( valueInArray(possibles, counter, group) == 0){
              possibles[nextIndexArray(possibles)] = group;
              counter[nextIndexArray(counter)] = 1;
              uniques[nextIndexArray(uniques)] = nft;
            } else if ( valueInArray(possibles, counter, group)  == 1) {
              if ( !existsInArray(uniques, nft)) {
                counter[indexInArray(possibles, group)] = 2;
                uniques[nextIndexArray(uniques)] = nft;
              }
            } else if ( valueInArray(possibles, counter, group) == 2) {
              if ( !existsInArray(uniques, nft)) {
                counter[indexInArray(possibles, group)] = 3;
                uniques[nextIndexArray(uniques)] = nft;
              }
            } else if ( valueInArray(possibles, counter, group) == 3) {
              if ( !existsInArray(uniques, nft)) {
                counter[indexInArray(possibles, group)] = 4;
                uniques[nextIndexArray(uniques)] = nft;
                pokers++;
              }
            }
        }
    }
    return pokers;
  }

  function mPSPSingles(uint targetTier, uint singles) public view returns (uint256) {
     if ( targetTier == tiers.legendary ){
       return parameters.legendary * singles;
     } else if ( targetTier == tiers.epic ){
       return parameters.epic * singles;
     } else if ( targetTier == tiers.rare ){
       return parameters.rare * singles;
     } else {
       return parameters.common * singles;
     }
  }

  function mPSPPair(uint targetTier) public view returns (uint256) {
     if ( targetTier == tiers.legendary ){
       return (parameters.legendary*parameters.legendary*2)/parameters.precision;
     } else if ( targetTier == tiers.epic ){
       return (parameters.epic*parameters.epic*2)/parameters.precision;
     } else if ( targetTier == tiers.rare ){
       return (parameters.rare*parameters.rare*2)/parameters.precision;
     } else {
       return (parameters.common*parameters.common*2)/parameters.precision;
     }
  }

  function mPSPThirds(uint targetTier) public view returns (uint256) {
     if ( targetTier == tiers.legendary ){
       return (parameters.legendary*parameters.legendary*3)/parameters.precision;
     } else if ( targetTier == tiers.epic ){
       return (parameters.epic*parameters.epic*3)/parameters.precision;
     } else if ( targetTier == tiers.rare ){
       return (parameters.rare*parameters.rare*3)/parameters.precision;
     } else {
       return (parameters.common*parameters.common*3)/parameters.precision;
     }
  }

  function mPSPPokers(uint targetTier) public view returns (uint256) {
     if ( targetTier == tiers.legendary ){
       return (parameters.legendary*parameters.legendary*4)/parameters.precision;
     } else if ( targetTier == tiers.epic ){
       return (parameters.epic*parameters.epic*4)/parameters.precision;
     } else if ( targetTier == tiers.rare ){
       return (parameters.rare*parameters.rare*4)/parameters.precision;
     } else {
       return (parameters.common*parameters.common*4)/parameters.precision;
     }
  }


  function existsInArray(uint[] memory _array, uint num) internal view returns (bool) {
    for (uint i = 0; i < _array.length; i++) {
        if (_array[i] == num) {
            return true;
        }
    }
    return false;
}

function valueInArray(uint[] memory _array, uint[] memory values, uint num) internal view returns (uint) {
  for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == num) {
          return values[i];
      }
  }
  return 0;
}

function indexInArray(uint[] memory _array, uint num) internal view returns (uint) {
  for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == num) {
          return i;
      }
  }
  return 0;
}

function nextIndexArray(uint[] memory _array) internal view returns (uint) {
  for (uint i = 0; i < _array.length; i++) {
      if (_array[i] == 0) {
          return i;
      }
  }
  return 0;
}


  function calculateTotalPerTier(uint[] memory nfts, uint targetTier) internal view returns (uint256) {
    uint total = 0;
    for (uint256 i = 0; i < nfts.length; i++) {
        uint nft = nfts[i];
        uint group = (nft/1000)*1000;
        uint tier = ((nft-group) / 100)*100;
        if ( tier == targetTier ){
          total++;
        }
    }
    return total;
  }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}