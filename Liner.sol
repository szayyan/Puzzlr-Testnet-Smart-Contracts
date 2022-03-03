//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;


import "hardhat/console.sol";

import "./IPuzzle.sol";

// 0  _|
// 1  |_
// 2  |¯¯
// 3  ¯¯| 
// 4   |
// 5  --
// 6 empty

contract Liner {

    event PUZZLE_GENERATED( address player, bytes board );

    mapping( address => bytes ) public userData;
    uint8 public puzzleDimensionX = 6;
    uint8 public puzzleDimensionY = 8;
    uint8 public puzzleDimensionTotal = 48;

    constructor() {
    }

    function checkValidity( uint8 a, uint8 b) internal view returns(bool) {
        // a is latest b is second latest
        if( a - b == 1 && a%puzzleDimensionX != 0 ) {
            return true;
        } else if( b - a == 1 && a%puzzleDimensionX != puzzleDimensionX -1 ) {
            return true;
        } else if( a - b == puzzleDimensionX ) {
            // we overflow here if there's a problem
            return true;
        } else if( b - a == puzzleDimensionX && a < puzzleDimensionTotal - puzzleDimensionX) {
            return true;
        }
        return false;
    }

    function generatePuzzle() external {
        require( userData[msg.sender].length == 0, "Puzzle has already been generated" );

        // many potential gas optimisations to be made here!
        bytes32 rBytes = getPsuedoRandomBytes( msg.sender );
        bytes memory board = new bytes( puzzleDimensionTotal );

        uint8 prevPos = byteToCappedInt( rBytes[0] , puzzleDimensionTotal );
        board[prevPos] = 0x01;

        for(uint8 i = 1; i < 32; i++) {
            uint8[4] memory potential;
            uint8 counter = 0;
            if( prevPos%puzzleDimensionX != 0 && board[prevPos-1] == 0) {
                potential[counter] = prevPos - 1;
                counter++;
            }
            if( prevPos%puzzleDimensionX != puzzleDimensionX-1 && board[prevPos+1] == 0) {
                potential[counter] = prevPos + 1;
                counter++;
            }
            if( prevPos >= puzzleDimensionX && board[prevPos-puzzleDimensionX] == 0 ) {
                potential[counter] =  prevPos - puzzleDimensionX;
                counter++;
            }
            if( prevPos < puzzleDimensionX && board[prevPos+puzzleDimensionX] == 0 ) {
                potential[counter] = prevPos + puzzleDimensionX;
                counter++;
            }
            if( counter == 0 ) {
                break;
            } else {
                prevPos = uint8( potential[ byteToCappedInt( rBytes[i], counter ) ] );
                board[prevPos] = 0x01;
            }
        }

        userData[msg.sender] = board;

        emit PUZZLE_GENERATED( msg.sender , board  );
    }

    function validatePuzzle(address solver, bytes calldata solution) external view returns(bool) {
        /* validate puzzle will not be doing array bounds checking for performance reasons
            as a result evm oob errors simply indicate an invalid solution */
        
        // copy back to mem
        bytes memory board = userData[solver];

        for( uint8 i = 0; i < solution.length; i++) {
            uint8 a = uint8(solution[i]);
            uint8 b = uint8(solution[i-1]);
            if( i > 0 && !checkValidity(a,b) ) {
                return false;
            }
            if( board[a] == 0x00  ) {
                return false;
            }
            board[a] = 'f';
        }
        return true;
    }

    function byteToCappedInt( bytes1 src, uint8 max ) internal pure returns(uint8) {
        // skewed distribution towards lower indices but v cheap - having uniformity not all that important
        return uint8(src) % max;
    }
    
    function getPsuedoRandomBytes( address requester ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(requester, block.timestamp) );
    }
}