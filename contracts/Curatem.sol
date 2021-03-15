import "./CuratemCommunity.sol";
import "./vendor/Owned.sol";
import "./proxy/Proxyable.sol";
import "./proxy/Proxy.sol";


contract Curatem is Proxy {
    constructor()
        public
        Proxy(msg.sender)
    {
    }
}

contract CuratemV1 is Owned, Proxyable {
    address public realitio;
    address public uniswapFactory;
    address public factory;

    event NewCommunity(address community);
    bytes32 private constant NEW_COMMUNITY_SIG = keccak256("NewCommunity(address)");

    constructor(
        address payable _proxy,
        address _realitio,
        address _uniswapFactory,
        address _factory
    ) 
        public 
        Owned(msg.sender)
        Proxyable(_proxy)
    {
        realitio = _realitio;
        uniswapFactory = _uniswapFactory;
        factory = _factory;
    }

    function createCommunity(
        address _token,
        address _moderatorArbitrator
    ) 
        public 
        returns (address) 
    {
        address community = Factory(factory).newCommunity(
            realitio,
            uniswapFactory,
            factory,
            _token, 
            payable(_moderatorArbitrator)
        );
        
        proxy._emit(
            abi.encode(address(community)),
            1,
            NEW_COMMUNITY_SIG,
            0,
            0,
            0
        );

        return address(community);
    }
}

