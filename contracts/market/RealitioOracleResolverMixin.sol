import "../interfaces/IRealitio.sol";
import "../interfaces/ISpamPredictionMarket.sol";


/**
 * Mixin which adds a resolve() function to SpamPredictionMarket,
 * which calls out to the Realitio service and finalizes the
 * reported answer.
 */
contract RealitioOracleResolverMixin {
    uint256 constant REALITIO_UNANSWERED = 0;
    uint256 constant CURATEM_NUM_OUTCOMES = 2;
    bytes32 questionId;

    constructor() public {}

    function initialize(bytes32 _questionId) public {
        questionId = _questionId;
    }

    function resolve() external {
        uint256[] memory payouts;
        payouts = getSingleSelectPayouts(questionId, CURATEM_NUM_OUTCOMES);
        market().reportPayouts(payouts);
    }

    /**
     * Resolves to the market contract we're mixing into.
     */
    function market() internal view returns (ISpamPredictionMarket market) {
        market = ISpamPredictionMarket(address(this));
    }

    function realitio() internal virtual returns (IRealitio realitio) {
        realitio = IRealitio(market().oracle());
    }

    function getSingleSelectPayouts(bytes32 questionId, uint256 numOutcomes) 
        internal 
        returns (uint256[] memory) 
    {
        uint256[] memory payouts = new uint256[](numOutcomes);
        uint256 answer = uint256(realitio().resultFor(questionId));

        if(answer < numOutcomes) {
            payouts[answer] = 1;
        } else {
            // Any invalid answers will result in all outcomes being redeemable.
            // This prevents a DoS vector where invalid answers will lock user funds.
            for (uint256 i = 0; i < numOutcomes; i++) {
                payouts[i] = 1;
            }
        }
        
        return payouts;
    }
}


// if(isRealitioUnavailable(questionId)) {
//         // Null/unavailability response.
//         for (uint256 i = 0; i < numOutcomes; i++) {
//                 payouts[i] = 1;
//         }
//         return payouts;
// }
// function isRealitioUnavailable(bytes32 questionId) internal returns (bool unavailable) {
//     // bytes32 content_hash = realitio.getContentHash(questionId);
//     uint32 finalize_ts = realitio.getFinalizeTS(questionId);
//     uint32 opening_ts = realitio.getOpeningTS(questionId);
//     uint32 timeout = realitio.getTimeout(questionId);
//     bool isPendingArbitration = realitio.isPendingArbitration(questionId);

//     unavailable = timeout > 0 &&                                                 // question exists
//             (opening_ts == 0 || opening_ts <= uint32(now)) && // question is open for answers
//             ((opening_ts + timeout) < block.timestamp) &&         // question timeout elapsed
//             finalize_ts == REALITIO_UNANSWERED     &&                     // question had no answer posted
//             !isPendingArbitration;                                                        // not pending arbitration
// }