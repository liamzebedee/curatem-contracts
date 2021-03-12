
import "../interfaces/IRealitio.sol";
import "../market/SpamPredictionMarket.sol";

contract RealitioOracle {
  IRealitio public realitio;
  uint256 constant REALITIO_UNANSWERED = 0;
  uint256 constant CURATEM_NUM_OUTCOMES = 2;

  constructor(
    IRealitio _realitio
  ) public {
    realitio = _realitio;
  }

  // function resolveMarket(
  //   address predictionMarket,
  //   bytes32 questionId
  // ) external {
  //   uint256[] memory payouts;
  //   payouts = getSingleSelectPayouts(questionId, CURATEM_NUM_OUTCOMES);
  //   SpamPredictionMarket(predictionMarket).reportPayouts(questionId, payouts);
  // }

  // function isRealitioUnavailable(bytes32 questionId) internal returns (bool unavailable) {
  //   // bytes32 content_hash = realitio.getContentHash(questionId);
  //   uint32 finalize_ts = realitio.getFinalizeTS(questionId);
  //   uint32 opening_ts = realitio.getOpeningTS(questionId);
  //   uint32 timeout = realitio.getTimeout(questionId);
  //   bool isPendingArbitration = realitio.isPendingArbitration(questionId);

  //   unavailable = timeout > 0 &&                         // question exists
  //       (opening_ts == 0 || opening_ts <= uint32(now)) && // question is open for answers
  //       ((opening_ts + timeout) < block.timestamp) &&     // question timeout elapsed
  //       finalize_ts == REALITIO_UNANSWERED   &&           // question had no answer posted
  //       !isPendingArbitration;                            // not pending arbitration
  // }

  function getSingleSelectPayouts(bytes32 questionId, uint256 numOutcomes) internal view returns (uint256[] memory) {
    uint256[] memory payouts = new uint256[](numOutcomes);
    
    // if(isRealitioUnavailable(questionId)) {
    //     // Null/unavailability response.
    //     for (uint256 i = 0; i < numOutcomes; i++) {
    //         payouts[i] = 1;
    //     }
    //     return payouts;
    // }


    // There is a DoS vector in the official Gnosis Realitio Proxy contract,
    // that I spotted while developing this fork.
    // 
    // In the original, `require(answer < numOutcomes)` is asserted in order
    // to prevent invalid answers from being reported to the ConditionalTokens contract.
    // However, this leaves bidders vulnerable to lockup of funds, in the case of
    // an invalid answer being finalized.
    // 
    // An attacker can submit invalid answers using `Realitio.submitAnswer` and upon
    // the question being finalized due to timeout, reclaim their bond using `claimWinnings`.
    // 
    // The mitigating factor is the arbitrator, who can be requested while the question is
    // still open. The standard interface for the arbitrator specifies a `max_previous` argument,
    // which will revert the arbitration request if the current bond exceeds max_previous.
    // 
    // Unfortunately, a well-financed attacker may still be able to frontrun the
    // Realitio.notifyOfArbitrationRequest call, by calling `Realitio.submitAnswer` with a
    // bond of at least `max_previous + 1`.
    // 
    // After reading the RealitioArbitratorProxy [1], 
    // 1: https://github.com/kleros/kleros-interaction/blob/master/contracts/standard/proxy/RealitioArbitratorProxy.sol#L106
    uint256 answer = uint256(realitio.resultFor(questionId));
    if(answer > numOutcomes) {
        for (uint256 i = 0; i < numOutcomes; i++) {
            payouts[i] = 1;
        }
    }
    // require(answer < numOutcomes, "Answer must be between 0 and numOutcomes");
    payouts[answer] = 1;

    return payouts;
  }
}