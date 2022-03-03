// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPuzzle {
    function validatePuzzle( address solver, bytes calldata solution) external returns(bool);
}