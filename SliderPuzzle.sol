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

contract SliderPuzzle {

    event PUZZLE_GENERATED( address player, bytes shuffledBoard, bytes targetBoard );

    mapping( address => bytes ) public userData;
    uint8 public puzzleDimension = 3;
    bytes public puzzleTarget;

    constructor() {
        puzzleTarget = abi.encodePacked(uint8(2),uint8(6),uint8(3),
                                        uint8(6),uint8(6),uint8(6),
                                        uint8(1),uint8(6),uint8(0));
    }

    function permute(bytes memory board, uint8 index, bool backward, uint8 dimension, bool isCol) internal view returns(bytes memory) {

        uint8 rowCoefficient = dimension;
        uint8 colCoefficient = 1;

        if( isCol ) {
            (rowCoefficient, colCoefficient) = (colCoefficient, rowCoefficient);
        }
        
        uint curIndex = index * rowCoefficient;
        uint endIndex = curIndex + colCoefficient * (dimension-1);
        if( backward ) {
            (curIndex, endIndex) = (endIndex, curIndex);
        }

        bytes1 stored = board[curIndex];

        while( curIndex != endIndex ) {
            uint next = backward ? curIndex - colCoefficient : curIndex + colCoefficient;
            board[curIndex] = board[next];
            curIndex = next;
        }
        board[endIndex] = stored;
    }

    function generatePuzzle() external {
        require( userData[msg.sender].length == 0, "Puzzle has already been generated" );

        // many potential gas optimisations to be made here!
        bytes32 rBytes = getPsuedoRandomBytes( msg.sender );
        bytes memory board = puzzleTarget;
        uint8 dimension = puzzleDimension;

        // shuffle the board 15 times - odd number ensures that no player can get a pre-solved solution
        // savvy devs may use this as a way to find their solution :)

        /* future puzzles could use inline assembly to make it slightly more difficult for devs to tell whats going on
            + source will not be published so  bytecode would need to be decompiled*/
        for( uint i = 0; i < 15; i++) {
            permute(
                board,
                byteToCappedInt(rBytes[i], dimension),
                false,
                dimension,
                rBytes[i] < 0x7F );
        }
        userData[msg.sender] = board;

        emit PUZZLE_GENERATED( msg.sender , board, puzzleTarget );
    }

    function validatePuzzle(address solver, bytes calldata solution) external view returns(bool) {
        /* validate puzzle will not be doing array bounds checking for performance reasons
            as a result evm oob errors simply indicate an invalid solution */
        
        // copy back to mem
        bytes memory shuffledBoard = userData[solver];
        console.log(shuffledBoard.length);
        uint8 dimension = puzzleDimension;

        for(uint i = 0; i < solution.length-1; i+=2) {
            uint8 typeAndDirection = uint8(solution[i]);
            permute( 
                shuffledBoard, 
                uint8(solution[i+1]), 
                typeAndDirection%2==1, 
                dimension,
                typeAndDirection>=2 );
        }
        // compare board hashes
        return keccak256(shuffledBoard) == keccak256(puzzleTarget);
    }

    function byteToCappedInt( bytes1 src, uint8 max ) internal pure returns(uint8) {
        // skewed distribution towards lower indices but v cheap - having uniformity not all that important
        return uint8(src) % max;
    }
    
    function getPsuedoRandomBytes( address requester ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(requester) );
    }
}