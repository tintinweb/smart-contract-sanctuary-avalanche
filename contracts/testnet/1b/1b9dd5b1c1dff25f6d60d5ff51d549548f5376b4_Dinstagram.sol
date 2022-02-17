/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Dinstagram {
    string public name = "Dinstagram";

    // Store Images
    uint256 public imageCount = 0;
    mapping(uint256 => Image) public images;

    struct Image {
        uint256 id;
        string hash;
        string description;
        uint256 tipAmount;
        address payable author;
    }

    event ImageCreated(
        uint256 id,
        string hash,
        string description,
        uint256 tipAmount,
        address payable author
    );

    event ImageTipped(
        uint256 id,
        string hash,
        string description,
        uint256 tipAmount,
        address payable author
    );

    //  Create Images
    function uploadImage(string memory _imgHash, string memory _description)
        public
    {
        // Make sure image hash exists
        require(bytes(_imgHash).length > 0);

        // Make sure image description exists
        require(bytes(_description).length > 0);

        // Make sure uploader address exists
        require(msg.sender != address(0x0));

        // Increment image count
        imageCount++;

        // Add Image to contract
        images[imageCount] = Image(
            imageCount,
            _imgHash,
            _description,
            0,
            payable(msg.sender)
        );

        // Trigger an event
        emit ImageCreated(
            imageCount,
            _imgHash,
            _description,
            0,
            payable(msg.sender)
        );
    }

    //  Tip Images
    function tipImageOwner(uint256 _id) public payable {

        // Make sure _id is valid 
        require(_id > 0 && _id <= imageCount);
        
        // Fetch image from storage
        Image memory _image = images[_id];

        // Fetch image author / owner
        address payable _author = _image.author;

        // Pay Author / owner with Ether
        _author.transfer(msg.value);

        // Increment the tip amount
        _image.tipAmount = _image.tipAmount + msg.value;

        // Update image
        images[_id] = _image;

        // Trigger an event
        emit ImageTipped(
            _id,
            _image.hash,
            _image.description,
            _image.tipAmount,
            _author
        );
    }
}