// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    // favorite number gets initialized to 0 if no value is given
    // default visibility is set to internal unless specified
    uint256 myFavoriteNumber;

    //  0.   1.  2
    // [77, 78, 90]
    // uint256[] listofFavoriteNumbers;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    // Person public pat = Person({favoriteNumber: 7, name: "Pat"});

    // dynamic array
    Person[] public listOfPeople; // []

    // good for key value pairs -> instead of iterating thru an array, you can just look up the value
    mapping(string => uint256) public nameToFavoriteNumber;

    // whenever we call the store function, we're going to set our favoriteNumber variable to whatever we pass
    // changing the state of the blockchain
    function store(uint256 _favoriteNumber) public virtual {
        myFavoriteNumber = _favoriteNumber;
    }

    // view - just reading the state from the blockchain
    // view/pure does cost gas only when a gas costing transaction is calling it
    function retrieve() public view returns (uint256) {
        return myFavoriteNumber;
    }
    // calldata, memory means that this variable is only going to exist temporarily for the duration of function call
    // most functions automatically default to memory
    // strings are a special type so you have to specify memory or calldata
    // memory can be manipulated and changed
    // calldata are temp variables that cannot be modified
    // storage are permanent variables that can be modified
    // array, struct, or mapping types are special types - need to be specified
    // uint256 are primitive types, so Solidity knows where to put this under the hood

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //Person memory newPerson = Person(_favoriteNumber, _name);
        listOfPeople.push(Person(_favoriteNumber, _name));
        // anytime you look up a name, you'll automatically get the favorite number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
