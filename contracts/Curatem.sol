pragma solidity ^0.7.0;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "./vendor/CTHelpers.sol";
import "./CuratemCommunity.sol";


contract Curatem {
    address realitio;
    address conditionalTokens;
    address fpmmFactory;
    address realityIoGnosisProxy;
    address weth9;
    address bFactory;

    event NewCommunity(address community);

    constructor(
        address _realitio,
        address _realityIoGnosisProxy,
        address _conditionalTokens,
        address _fpmmFactory,
        address _bFactory
    ) 
        public 
    {
        realitio = _realitio;
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = _conditionalTokens;
        fpmmFactory = _fpmmFactory;
        bFactory = _bFactory;
    }

    function createCommunity(
        bytes32 salt,
        address _token,
        address _moderator
    ) public returns (address) {
        CuratemCommunity community = new CuratemCommunity{ salt: salt }(
            realitio,
            realityIoGnosisProxy,
            conditionalTokens,
            fpmmFactory,
            bFactory,
            _token, 
            msg.sender
        );
        
        emit NewCommunity(address(community));
        
        return address(community);
    }
}

