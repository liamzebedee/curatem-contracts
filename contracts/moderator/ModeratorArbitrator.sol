pragma solidity >=0.6.0;
import "../interfaces/IArbitrator.sol";
import "../proxy/Proxy.sol";
import "../proxy/Proxyable.sol";

/**
 * A proxy contract to a ModeratorArbitrator instance for a community.
 * This allows us to 
 */
contract ModeratorArbitrator is Proxy {
    constructor()
        public
        Proxy(msg.sender)
    {
    }

    function arbitrator() public view returns (IArbitrator) {
        return IArbitrator(address(target));
    }
}
