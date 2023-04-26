/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProductMarketplace {
    struct Product {
        address seller;
        string title;
        uint256 price;
        string tags;
        string image;
    }

    Product[] public products;

    function addProduct(
        address seller,
        string memory title,
        uint256 price,
        string memory tags,
        string memory image
    ) public {
        Product memory newProduct = Product({
            seller: seller,
            title: title,
            price: price,
            tags: tags,
            image: image
        });

        products.push(newProduct);
    }
}