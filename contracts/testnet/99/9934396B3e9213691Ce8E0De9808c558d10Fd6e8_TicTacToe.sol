/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TicTacToe {
    string internal value_1_1;
    string internal value_1_2;
    string internal value_1_3;
    string internal value_2_1;
    string internal value_2_2;
    string internal value_2_3;
    string internal value_3_1;
    string internal value_3_2;
    string internal value_3_3;
    

    string public winner;
    bool public hasWinner;
    //bool public isPlaying;

    function newGame() public returns(bool){
        hasWinner = false;
        winner = "";
        return hasWinner;
    }


    function setValue_1_1(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_1_1 = _value;
        checkWinner();
        return value_1_1;
    }

    function setValue_1_2(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_1_2 = _value;
        checkWinner();
        return value_1_2;
    }

    function setValue_1_3(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_1_3 = _value;
        checkWinner();
        return value_1_3;
    }

    function setValue_2_1(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_2_1 = _value;
        checkWinner();

        return value_2_1;
    }

    function setValue_2_2(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_2_2 = _value;
        checkWinner();

        return value_2_2;
    }

    function setValue_2_3(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_2_3 = _value;
        checkWinner();

        return value_2_3;
    }

    function setValue_3_1(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_3_1 = _value;
        checkWinner();

        return value_3_1;
    }

    function setValue_3_2(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_3_2 = _value;
        checkWinner();

        return value_3_2;
    }

    function setValue_3_3(string memory _value) public returns(string memory){
        require(!hasWinner);
        value_3_3 = _value;
        checkWinner();
        return value_3_3;
    }

    function checkWinner() public returns(string memory){
        //check row
        if(checkValue_1_1_One() && checkValue_1_2_One() && checkValue_1_3_One()){
            winner = "One";
            hasWinner= true;
        } else if(checkValue_2_1_One() && checkValue_2_2_One() && checkValue_2_3_One()){
            winner = "One";
            hasWinner= true;
        } else if (checkValue_3_1_One() && checkValue_3_2_One() && checkValue_3_3_One()){
            winner = "One";
            hasWinner= true;
        }

        if(checkValue_1_1_Two() && checkValue_1_2_Two() && checkValue_1_3_Two()){
            winner = "Two";
            hasWinner= true;
        } else if(checkValue_2_1_Two() && checkValue_2_2_Two() && checkValue_2_3_Two()){
            winner = "One";
            hasWinner= true;
        } else if (checkValue_3_1_Two() && checkValue_3_2_Two() && checkValue_3_3_Two()){
            winner = "One";
            hasWinner= true;
        }

        //column
        if(checkValue_1_1_One() && checkValue_2_1_One() && checkValue_3_1_One()){
            winner = "Two";
            hasWinner= true;
        } else if(checkValue_1_2_One() && checkValue_2_2_One() && checkValue_3_2_One()){
            winner = "Two";
            hasWinner= true;
        } else if (checkValue_1_3_One() && checkValue_2_3_One() && checkValue_3_3_One()){
            winner = "Two";
            hasWinner= true;
        }

        if(checkValue_1_1_Two() && checkValue_2_1_Two() && checkValue_3_1_Two()){
            winner = "Two";
            hasWinner= true;
        } else if(checkValue_1_2_Two() && checkValue_2_2_Two() && checkValue_3_2_Two()){
            winner = "Two";
            hasWinner= true;
        } else if (checkValue_1_3_Two() && checkValue_2_3_Two() && checkValue_3_3_Two()){
            winner = "Two";
            hasWinner= true;
        }

        //diagonal
        if(checkValue_1_1_One() && checkValue_2_2_One() && checkValue_3_3_One()){
            winner = "One";
            hasWinner= true;
        } else if(checkValue_1_3_One() && checkValue_2_2_One() && checkValue_3_1_One()){
            winner = "One";
            hasWinner= true;
        }

        if(checkValue_1_1_Two() && checkValue_2_2_Two() && checkValue_3_3_Two()){
            winner = "Two";
            hasWinner= true;
        } else if(checkValue_1_3_Two() && checkValue_2_2_Two() && checkValue_3_1_Two()){
            winner = "Two";
            hasWinner= true;
        }

        return winner;
    }


    // Checks
    //Player One
    function checkValue_1_1_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_1_1)) == keccak256(abi.encodePacked("one"));
    }
    
    function checkValue_1_2_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_1_2)) == keccak256(abi.encodePacked("one"));
    }

    function checkValue_1_3_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_1_3)) == keccak256(abi.encodePacked("one"));
    }

    function checkValue_2_1_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_2_1)) == keccak256(abi.encodePacked("one"));
    }
    
    function checkValue_2_2_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_2_2)) == keccak256(abi.encodePacked("one"));
    }

    function checkValue_2_3_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_2_3)) == keccak256(abi.encodePacked("one"));
    }

    function checkValue_3_1_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_3_1)) == keccak256(abi.encodePacked("one"));
    }
    
    function checkValue_3_2_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_3_2)) == keccak256(abi.encodePacked("one"));
    }

    function checkValue_3_3_One() internal view returns(bool){
        return keccak256(abi.encodePacked(value_3_3)) == keccak256(abi.encodePacked("one"));
    }

    //Player Two
    function checkValue_1_1_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_1_1)) == keccak256(abi.encodePacked("two"));
    }
    
    function checkValue_1_2_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_1_2)) == keccak256(abi.encodePacked("two"));
    }

    function checkValue_1_3_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_1_3)) == keccak256(abi.encodePacked("two"));
    }

    function checkValue_2_1_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_2_1)) == keccak256(abi.encodePacked("two"));
    }
    
    function checkValue_2_2_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_2_2)) == keccak256(abi.encodePacked("two"));
    }

    function checkValue_2_3_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_2_3)) == keccak256(abi.encodePacked("two"));
    }

    function checkValue_3_1_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_3_1)) == keccak256(abi.encodePacked("two"));
    }
    
    function checkValue_3_2_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_3_2)) == keccak256(abi.encodePacked("two"));
    }

    function checkValue_3_3_Two() internal view returns(bool){
        return keccak256(abi.encodePacked(value_3_3)) == keccak256(abi.encodePacked("two"));
    }
}