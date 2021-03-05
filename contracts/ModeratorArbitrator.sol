pragma solidity >=0.6.0;
import "./interfaces/IArbitrator.sol";

// Arbitrator contracts should expose the following functions to users:
// - getDisputeFee
// - requestArbitration
// https://reality.eth.link/app/docs/html/arbitrators.html#creating-and-using-an-arbitration-contract
contract ModeratorArbitrator is IArbitrator {
    IRealitio public override realitio;
    string public override metadata;
    address owner;
    
    uint constant ARBITRATION_FEE = 1; // minimum required by reality.eth

    constructor(
        address _realityio,
        string memory _metadata
    ) public {
        owner = msg.sender;
        realitio = IRealitio(_realityio);
        metadata = _metadata;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorised");
        _;
    }

    function getDisputeFee(bytes32 question_id) public override view returns (uint256) {
        return ARBITRATION_FEE;
    }
    
    function requestArbitration(bytes32 question_id, uint256 max_previous) external override payable returns (bool) {
        realitio.notifyOfArbitrationRequest(question_id, msg.sender, max_previous);
        return true;
    }

    function submitAnswer(bytes32 question_id, bytes32 answer) external onlyOwner {
        // answerer is the account credited with this answer for the purpose of bond claims.
        // Since the dispute fee is 0, we set the answerer to this multisig contract.
        realitio.submitAnswerByArbitrator(question_id, answer, address(this));
    }
}