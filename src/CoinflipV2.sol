// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error SeedTooShort();

/// @title Coinflip 10 in a Row (Version 2)
/// @notice Contract used as part of the course Solidity and Smart Contract development
contract CoinflipV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    string public seed;

    // Initializer instead of a constructor for UUPS
    function initialize(address initialOwner) initializer public {
        __Ownable_init();  // Initialize Ownable logic
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

    /// @notice allows the owner of the contract to change the seed to a new one, with rotation logic
    /// @param NewSeed is a string which represents the new seed
    /// @param rotations is the number of rotations to apply to the seed
    function seedRotation(string memory NewSeed, uint rotations) public onlyOwner {
        bytes memory newSeedBytes = bytes(NewSeed);
        uint256 seedlength = newSeedBytes.length;

        if (seedlength < 10) {
            revert SeedTooShort();
        }

        // Logic to rotate the seed by the specified number of rotations
        for (uint i = 0; i < rotations; i++) {
            bytes memory rotated = new bytes(seedlength);
            // Shift characters left by 1 and place the first character at the end
            for (uint j = 0; j < seedlength - 1; j++) {
                rotated[j] = newSeedBytes[j + 1];
            }
            rotated[seedlength - 1] = newSeedBytes[0];  // Move first character to end
            newSeedBytes = rotated;
        }

        seed = string(newSeedBytes);  // Update the seed with the rotated string
    }

    // -------------------- helper functions -------------------- //
    /// @notice This function generates 10 random flips by hashing characters of the seed
    /// @return a fixed 10 element array of type uint8 with only 1 or 0 as its elements
    function getFlips() public view returns(uint8[10] memory){
        bytes memory seedBytes = bytes(seed);
        uint8[10] memory flips;

        for (uint i = 0; i < 10; i++) {
            uint randomNum = uint(keccak256(abi.encode(seedBytes, i))); 
            flips[i] = uint8(randomNum % 2);  
        }

        return flips;
    }

    // Implementation of _authorizeUpgrade to control who can upgrade the contract
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
