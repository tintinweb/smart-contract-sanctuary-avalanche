// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/*
    @title BluMintRenting
    @dev facilitates listing/renting of NFTs
*/

// TODO: reentrancy guards
// TODO: upgradable contract via proxy

contract BluMintRenting {
  address public owner;
  address public companyWalletAddress;
  uint256 public listingFee;

  struct Listing {
    address nftAddress;
    address listerAddress;
    address renterAddress;
    uint256 maxRentDays;
    uint256 priceDaily;
    uint256 rentRoyalty;
    bool exists;
  }
  event RemoveOrder(
    address indexed nftAddress,
    address indexed listerAddress,
    address indexed renterAddress
  );
  event PutOrder(
    address indexed nftAddress,
    address indexed listerAddress,
    address indexed renterAddress,
    uint256 maxRentDays,
    uint256 priceDaily,
    uint256 rentRoyalty
  );
  event TakeOrder(
    address indexed nftAddress,
    address indexed renterAddress,
    uint256 rentDays
  );

  mapping(address => Listing) nftToListingMap;

  modifier onlyOwner() {
    require(
      msg.sender == owner,
      'This function can only be called by the contract owner.'
    );
    _;
  }

  modifier rentDuration(uint256 maxRentDays) {
    require(
      maxRentDays > 0,
      'The duration of the listing order must exceed 1 day.'
    );
    require(
      maxRentDays <= 14,
      'The duration of the listing order must not exceed 14 days (2 weeks).'
    );
    _;
  }

  modifier priceConstraints(uint256 rentPrice) {
    require(rentPrice > 0, 'Daily rent price must be greater than 0');
    _;
  }

  modifier royaltyConstraints(uint256 rentRoyalty) {
    require(rentRoyalty > 0, 'Rent royalty must be greater than 0.');
    require(
      rentRoyalty <= 100,
      'Rent royalty must be less than or equal to 100.'
    );
    _;
  }
  modifier listingFeeConstraints(uint256 _listingFee) {
    require(_listingFee > 0, 'Listing fee must be greater than 0.');
    require(
      _listingFee <= 100,
      'Listing fee must be less than or equal to 100.'
    );
    _;
  }

  modifier listingExists(address nftAddress) {
    require(
      nftToListingMap[nftAddress].exists,
      'Order must exist to be removed/modified/taken.'
    );
    _;
  }

  modifier listingDoesNotExist(address nftAddress) {
    require(
      !nftToListingMap[nftAddress].exists,
      'Order already exists. Modify your listing if you wish to update it.'
    );
    _;
  }

  constructor() payable {
    owner = payable(msg.sender);
  }

  function upgradeListingFee(uint256 _listingFee)
    public
    onlyOwner
    listingFeeConstraints(_listingFee)
  {
    listingFee = _listingFee;
  }

  function upgradeCompanyWalletAddress(address _companyWalletAddress)
    public
    onlyOwner
  {
    companyWalletAddress = _companyWalletAddress;
  }

  function emitPutOrder(Listing memory listing) internal {
    emit PutOrder(
      listing.nftAddress,
      listing.listerAddress,
      listing.renterAddress,
      listing.maxRentDays,
      listing.priceDaily,
      listing.rentRoyalty
    );
  }

  function emitRemoveOrder(Listing memory listing) internal {
    emit RemoveOrder(
      listing.nftAddress,
      listing.listerAddress,
      listing.renterAddress
    );
  }

  function putOrder(Listing calldata listing)
    public
    onlyOwner
    listingDoesNotExist(listing.nftAddress)
    rentDuration(listing.maxRentDays)
    priceConstraints(listing.priceDaily)
    royaltyConstraints(listing.rentRoyalty)
  {
    // we will check that:
    // 1. listAddress owns the asset at nftAddress
    // 2. renterAddress != listerAddress
    // off chain prior to call
    nftToListingMap[listing.nftAddress] = listing;
    emitPutOrder(listing);
  }

  function modifyOrder(Listing calldata updatedListing)
    public
    onlyOwner
    listingExists(updatedListing.nftAddress)
  {
    emitRemoveOrder(updatedListing);
    emitPutOrder(updatedListing);
    delete nftToListingMap[updatedListing.nftAddress];
    nftToListingMap[updatedListing.nftAddress] = updatedListing;
  }

  function takeOrder(address nftAddress, uint256 rentDays)
    public
    payable
    listingExists(nftAddress)
  {
    emit TakeOrder(nftAddress, msg.sender, rentDays);
    checkRenterAddress(nftAddress, msg.sender);
    checkCost(nftAddress, msg.value, rentDays);

    Listing memory listing = nftToListingMap[nftAddress];
    address listerAddress = listing.listerAddress;
    delete nftToListingMap[nftAddress];

    transferAndClaimFee(listerAddress, msg.value);
  }

  function deposit() public payable {}

  function transferAndClaimFee(address listerAddress, uint256 amount) internal {
    uint256 fee = (amount * listingFee) / 100;
    uint256 listerPayout = amount - fee;
    payable(listerAddress).transfer(listerPayout);
    payable(companyWalletAddress).transfer(fee);
  }

  function checkCost(
    address nftAddress,
    uint256 msgValue,
    uint256 rentDays
  ) internal view {
    Listing memory listing = getListing(nftAddress);
    require(
      msgValue >= listing.priceDaily * rentDays,
      'Message value too low to take order'
    );
  }

  function checkRenterAddress(address nftAddress, address _renterAddress)
    internal
    view
  {
    Listing memory listing = getListing(nftAddress);
    require(
      listing.renterAddress == _renterAddress,
      'Not authorised to fulfill this rental order'
    );
  }

  function removeOrder(address nftAddress)
    public
    onlyOwner
    listingExists(nftAddress)
  {
    Listing memory listingToRemove = nftToListingMap[nftAddress];
    emitRemoveOrder(listingToRemove);
    delete nftToListingMap[nftAddress];
  }

  function getListing(address nftAddress)
    public
    view
    listingExists(nftAddress)
    returns (Listing memory)
  {
    return nftToListingMap[nftAddress];
  }
}