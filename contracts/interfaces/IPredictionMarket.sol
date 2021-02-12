// pragma solidity ^0.5.5;


interface IPredictionMarket {
    function reportPayouts(bytes32 id, uint[] calldata payouts) external;
}