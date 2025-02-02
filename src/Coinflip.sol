// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error SeedTooShort();

/// @title Coinflip 10 in a Row
/// @author Tianchan Dong
/// @notice Contract used as part of the course Solidity and Smart Contract development
contract Coinflip is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    string public seed;

    // Initializer instead of a constructor for UUPS
    function initialize(address initialOwner) initializer public {
        __Ownable_init(initialOwner);  // Initialize Ownable logic
        __UUPSUpgradeable_init();  // Initialize UUPS logic
        seed = "It is a good practice to rotate seeds often in gambling";
        transferOwnership(initialOwner);
    }

    /// @notice Checks user input against contract generated guesses
    /// @param Guesses is a fixed array of 10 elements which holds the user's guesses. The guesses are either 1 or 0 for heads or tails
    /// @return true if user correctly guesses each flip correctly or false otherwise
    function userInput(uint8[10] calldata Guesses) external view returns(bool){
        uint8[10] memory generatedFlips = getFlips();

        for (uint i = 0; i < 10; i++) {
            if (Guesses[i] != generatedFlips[i]) {
                return false;
            }
        }
        return true;
    }

    /// @notice allows the owner of the contract to change the seed to a new one
    /// @param NewSeed is a string which represents the new seed
    function seedRotation(string memory NewSeed) public onlyOwner {
        bytes memory newSeedBytes = bytes(NewSeed);
        uint256 seedlength = newSeedBytes.length;

        if (seedlength < 10) {
            revert SeedTooShort();
        }
        seed = NewSeed;
    }

// -------------------- helper functions -------------------- //
    /// @notice This function generates 10 random flips by hashing characters of the seed
    /// @return a fixed 10 element array of type uint8 with only 1 or 0 as its elements
    function getFlips() public view returns (uint8[10] memory) {
        // Casting the seed into a bytes array and getting its length
        bytes memory stringInBytes = bytes(seed);
        uint seedLength = stringInBytes.length;

        // Initializing an empty fixed array with 10 uint8 elements
        uint8[10] memory flips;

        // Setting the interval for grabbing characters
        uint interval = seedLength / 10;

        // Defining a for loop that iterates 10 times to generate each flip
        for (uint i = 0; i < 10; i++){
            // Generating a pseudo-random number by hashing together the character and the block timestamp
            uint randomNum = uint(keccak256(abi.encode(stringInBytes[i*interval], block.timestamp)));
            
            // If the result is an even unsigned integer, record it as 1 in the results array, otherwise record it as zero
            if (randomNum % 2 == 0) {
                flips[i] = 1;
            } else {
                flips[i] = 0;
            }
        }
        // Returning the resulting fixed array
        return flips;
    }

    // Implementation of _authorizeUpgrade to control who can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
