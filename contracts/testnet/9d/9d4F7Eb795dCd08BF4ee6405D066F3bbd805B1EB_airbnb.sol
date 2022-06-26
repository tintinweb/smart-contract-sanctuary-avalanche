/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract airbnb{

    address public owner;
    uint256 private counter;

    constructor(){
        owner = msg.sender;
        counter = 0;
    }

    struct rentalInfo{
        string name;
        string city;
        string lat;
        string long;
        string unoDescription;
        string dosDescription;
        string imgUrl;
        uint256 maxGuests;
        uint256 pricePerDay;
        string[]  datesBooked;
        uint256 id;
        address renter;
    }

    event rentalCreated(
        string name,
        string city, 
        string lat, 
        string long, 
        string unoDescription, 
        string dosDescription, 
        string imgUrl, 
        uint256 maxGuests, 
        uint256 pricePerDay, 
        string[]  datesBooked, 
        uint256 id, 
        address renter     
    );

    event newDatesBooked(
        string[] datesBooked,
        uint256 id, 
        address booker,
        string city,
        string imgUrl
    );

    mapping(uint256 => rentalInfo) rentals;
    uint256[] public rentalIds;

    function addRentals(
        string memory name,
        string memory city, 
        string memory lat, 
        string memory long, 
        string memory unoDescription, 
        string memory dosDescription, 
        string memory imgUrl, 
        uint256 maxGuests, 
        uint256 pricePerDay, 
        string[] memory datesBooked
    ) public {
        require(msg.sender == owner, "Only the owner of the smartcontract can add rentals" );
        rentalInfo storage newRental = rentals[counter];
        newRental.name = name;
        newRental.city = city;
        newRental.lat = lat;
        newRental.long = long;
        newRental.unoDescription = unoDescription;
        newRental.dosDescription = dosDescription;
        newRental.imgUrl = imgUrl;
        newRental.maxGuests = maxGuests;
        newRental.pricePerDay = pricePerDay;
        newRental.datesBooked = datesBooked;
        newRental.id = counter;
        newRental.renter = owner;
        rentalIds.push(counter);
        emit rentalCreated(
         name,
         city,
         lat,
         long,
         unoDescription,
         dosDescription,
         imgUrl,
         maxGuests,
         pricePerDay,
         datesBooked,
         counter,
         owner);

         counter++;
    }

    function checkBookings( uint256 id, string[] memory newBookings) private view returns (bool){

        for(uint i=0; i < newBookings.length; i++){
            for(uint j=0; j < rentals[i].datesBooked.length; j++){
                if (keccak256(abi.encodePacked(rentals[id].datesBooked[j])) == keccak256(abi.encodePacked(newBookings[i]))){
                    return false;
                }
            }
        }
        return true;
    }

    function addDatesBooked( uint256 id, string[] memory newBookings) public payable{
        require(id < counter, "There is not such booking");
        require(checkBookings(id, newBookings), "The dates for the booking are already");
        require(msg.value == (rentals[id].pricePerDay * 1 ether * newBookings.length),"Please submit the asking price");

        for(uint i=0; i<newBookings.length; i++){
            rentals[id].datesBooked.push(newBookings[i]);
        }

        payable(owner).transfer(msg.value);
        
        emit newDatesBooked(newBookings, id, msg.sender, rentals[id].city, rentals[id].imgUrl);    
    }

    function getRental(uint256 id) public view returns(string memory, uint256, string[] memory){
        require(id < counter, "The booking does not exists");

        rentalInfo storage s = rentals[id];
        return(s.name, s.pricePerDay, s.datesBooked);
    }

    function getRental2(uint256 id) public view returns(string memory, uint256, string[] memory){
        require(id < counter, "The booking does not exists");

        return(rentals[id].name, rentals[id].pricePerDay, rentals[id].datesBooked);
    }

}