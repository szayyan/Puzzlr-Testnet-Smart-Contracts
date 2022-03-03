//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IPuzzle.sol";
import "./ECDSA.sol";

/* The testnet proof of concept implemenation of PuzzleMaster. The produuction version will give
    owner the power to:
    1. set new puzzles
    2. increase the puzzle epoch
    3. deploy liquidity */

contract PuzzleMaster is Ownable, ReentrancyGuard {
    event PUZZLE_SOLVED( address solver );

    mapping( address => bool ) public solvedTestPuzzle;
    IPuzzle public currentPuzzle;

    function verifyPuzzle( bytes calldata solution ) external nonReentrant() {
        address caller = msg.sender;

        require( !solvedTestPuzzle[caller], "This address has already solved the test puzzle" );
        require( currentPuzzle.validatePuzzle( caller, solution ), "Incorrect solution to the puzzle" );

        solvedTestPuzzle[caller] = true;
        emit PUZZLE_SOLVED( caller );
    }

    function verifyPuzzleTrusted( bytes calldata signature ) external nonReentrant() {
        /* used when verified on the backend */
        address caller = msg.sender;

        require( !solvedTestPuzzle[caller], "This address has already solved the test puzzle" );
        
        bytes32 digest = keccak256(abi.encode( caller ));
        bytes32 signedMsg = ECDSA.toEthSignedMessageHash(digest);
        address recovered = ECDSA.recover( signedMsg , signature );
        require( recovered == owner() , "Invalid signature" );

        solvedTestPuzzle[caller] = true;

        emit PUZZLE_SOLVED( caller );

    }

    /* OWNER SPECIFIC FUNCTIONS - has the power to do these things only */

    function setPuzzle( address newPuzzle ) external onlyOwner() {
        currentPuzzle = IPuzzle(newPuzzle);
    }
}