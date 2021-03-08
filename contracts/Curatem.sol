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
        address _moderatorArbitrator,
        address _uniswapFactory,
        address _factory
    ) public returns (address) {
        CuratemCommunity community = new CuratemCommunity();
        
        community.initialize(
            realitio,
            realityIoGnosisProxy,
            conditionalTokens,
            fpmmFactory,
            _uniswapFactory,
            _factory,
            _token, 
            _moderatorArbitrator
        );
        
        emit NewCommunity(address(community));
        return address(community);
    }
}

