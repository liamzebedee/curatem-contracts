// pragma solidity ^0.5.5;


import "./CuratemCommunity.sol";


contract Curatem {
    address realitio;
    address conditionalTokens;
    address fpmmFactory;
    address realityIoGnosisProxy;
    address weth9;

    event NewCommunity(address community);

    constructor(
        address _realitio,
        address _realityIoGnosisProxy,
        address _conditionalTokens,
        address _fpmmFactory
    ) 
        public 
    {
        realitio = _realitio;
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = _conditionalTokens;
        fpmmFactory = _fpmmFactory;
    }

    function createCommunity(
        bytes32 salt,
        address _token,
        address _moderator,
        address _bFactory,
        address _factory
    ) public returns (address) {
        CuratemCommunity community = new CuratemCommunity(
            realitio,
            realityIoGnosisProxy,
            conditionalTokens,
            fpmmFactory,
            _bFactory,
            _factory,
            _token, 
            msg.sender
        );
        
        emit NewCommunity(address(community));
        
        return address(community);
    }
}

