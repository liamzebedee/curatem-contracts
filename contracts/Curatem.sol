import "./CuratemCommunity.sol";


contract Curatem {
    address realitio;
    address realityIoGnosisProxy;

    event NewCommunity(address community);

    constructor(
        address _realitio,
        address _realityIoGnosisProxy
    ) 
        public 
    {
        realitio = _realitio;
        realityIoGnosisProxy = _realityIoGnosisProxy;
    }

    function createCommunity(
        bytes32 salt,
        address _uniswapFactory,
        address _factory,
        address _token,
        address _moderatorArbitrator
    ) public returns (address) {
        CuratemCommunity community = new CuratemCommunity();
        
        community.initialize(
            realitio,
            realityIoGnosisProxy,
            _uniswapFactory,
            _factory,
            _token, 
            payable(_moderatorArbitrator)
        );
        
        emit NewCommunity(address(community));
        return address(community);
    }
}

