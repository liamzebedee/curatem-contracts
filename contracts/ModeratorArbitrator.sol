pragma solidity ^0.7.0;

// import "@realitio/realitio-contracts/truffle/contracts/IArbitrator.sol";
abstract contract IArbitrator {
  function metadata (  ) external virtual view returns (string memory);
//   function owner (  ) external view returns ( address );
//   function arbitration_bounties ( bytes32 ) external view returns ( uint256 );
  function realitio (  ) external virtual view returns ( IRealitio );
//   function realitycheck (  ) external view returns ( IRealitio );
//   function setRealitio ( address addr ) external;
//   function setDisputeFee ( uint256 fee ) external;
//   function setCustomDisputeFee ( bytes32 question_id, uint256 fee ) external;
  function getDisputeFee ( bytes32 question_id ) external virtual view returns ( uint256 );
//   function setQuestionFee ( uint256 fee ) external;
//   function submitAnswerByArbitrator ( bytes32 question_id, bytes32 answer, address answerer ) external virtual;
  function requestArbitration ( bytes32 question_id, uint256 max_previous ) external virtual payable returns ( bool );
//   function withdraw ( address addr ) external;
//   function withdrawERC20 ( IERC20 _token, address addr ) external;
//   function callWithdraw (  ) external;
//   function setMetaData ( string _metadata ) external;
//   function foreignProxy() external returns (address);
//   function foreignChainId() external returns (uint256);
}
interface IRealitio {
    function notifyOfArbitrationRequest(bytes32 question_id, address requester, uint256 max_previous) external;
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) external;
}

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