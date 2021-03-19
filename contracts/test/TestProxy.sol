
import "../proxy/Proxyable.sol";
import "../proxy/CallProxy.sol";
import "hardhat/console.sol";

contract TestProxy is CallProxy {
    constructor() CallProxy(msg.sender) public {}
    
}

contract TestImpl is Owned, Proxyable {
    address admin;

    modifier onlyAdmin {
        console.log("admin=%s msg.sender=%s", admin, msg.sender);
        require(messageSender == admin, "ERR_ONLY_ADMIN");
        _;
    }

    constructor(address proxy) 
        public 
        Owned(msg.sender)
        Proxyable(payable(proxy)) 
    {
        admin = msg.sender;
    }

    function test() 
        external 
        optionalProxy
        onlyAdmin
    {
        admin = address(0);
    }

    function testView() 
        external 
        view
        // optionalProxy
        // onlyAdmin
        returns (address)
    {
        return admin;
    }
}

contract TestWrapper2 {
    constructor() public {}

    function test(address proxy) external {
        // TestImpl c = new TestImpl(proxy);
        require(TestImpl(proxy).testView() == address(0), "FAILED");
    }
}