pragma solidity >=0.6.0;
import "../interfaces/IArbitrator.sol";
import "../vendor/Initializable.sol";
import "../proxy/Proxyable.sol";
import "../vendor/Owned.sol";

// Arbitrator contracts should expose the following functions to users:
// - getDisputeFee
// - requestArbitration
// https://reality.eth.link/app/docs/html/arbitrators.html#creating-and-using-an-arbitration-contract
contract ModeratorArbitratorV1 is Initializable, IArbitrator, Proxyable {
    // Minimum required by reality.eth.
    uint256 constant ARBITRATION_FEE = 1;
    uint256 constant MAX_UINT = 2**256 - 1;

    IRealitio public _realitio;
    string public _metadata;
    address public moderator;

    modifier onlyModerator() {
        require(messageSender == moderator, "ERR_ONLY_MODERATOR");
        _;
    }

    constructor(address _proxy) 
        public 
        Owned(msg.sender)
        Proxyable(payable(_proxy))
    {}

    function initialize(
        address _realityio, 
        string memory _metadata,
        address _moderator
    ) 
        public 
        uninitialized 
    {
        _realitio = IRealitio(_realityio);
        _metadata = _metadata;
        moderator = _moderator;
    }

    function getDisputeFee(bytes32 question_id) 
        public 
        view 
        override 
        isInitialized
        returns (uint256) 
    {
        return ARBITRATION_FEE;
    }

    function requestArbitration(bytes32 question_id, uint256 max_previous) 
        external
        payable
        override
        optionalProxy
        isInitialized
        returns (bool)
    {
        // Passing `MAX_UINT` prevents frontrunning using submitAnswer(max_previous + 1).
        _realitio.notifyOfArbitrationRequest(question_id, messageSender, MAX_UINT);
        return true;
    }

    function submitAnswer(bytes32 question_id, bytes32 answer) 
        external
        optionalProxy
        onlyModerator
        isInitialized
    {
        // answerer is the account credited with this answer for the purpose of bond claims.
        // Since the dispute fee is 0, we set the answerer to this multisig contract.
        _realitio.submitAnswerByArbitrator(question_id, answer, address(proxy));
    }

    function metadata () external override view returns (string memory) {
        return _metadata;
    }

    function realitio () external override view returns (IRealitio) {
        return _realitio;
    }
}
