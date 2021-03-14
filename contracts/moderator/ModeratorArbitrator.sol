pragma solidity >=0.6.0;
import "../interfaces/IArbitrator.sol";
import "../proxy/Proxy.sol";
import "../proxy/Proxyable.sol";

/**
 * The ModeratorArbitrator is an upgradeable [1] arbitrator for Realitio.
 * 
 * Since Realitio questions are identified by a hash which includes the
 * arbitrator contract address, we must maintain a fixed identity. 
 * For this, we use a proxy based on `CALL`. TrailOfBits published an
 * interesting post [2] which convinced me that `DELEGATECALL` is
 * an error-prone solution to contract upgrades. 
 *
 * [1]: Upgrades in future might include changing core contract logic, like
 *      adding support for ERC20 fees that go into a lending pool, etc.
 * [2]: https://blog.trailofbits.com/2018/09/05/contract-upgrade-anti-patterns/ 
 */
contract ModeratorArbitrator is Proxy {
    constructor()
        public
        Proxy(msg.sender)
    {
    }

    /**
     * Returns the underlying implementation, suitable for use with
     * view functions.
     * 
     * This is needed as Proxy changes state (`messageSender`), and thus
     * any staticcall's will inevitably revert the tx.
     */
    function impl() public view returns (IArbitrator) {
        return IArbitrator(address(target));
    }
}
