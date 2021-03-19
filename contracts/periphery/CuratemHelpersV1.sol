
import "../tokens/OutcomeToken.sol";
import "../market/SpamPredictionMarket.sol";


contract CuratemHelpersV1 {

    function canRedeem(address _market, address _user)
        external
        view
        returns (bool canRedeem)
    {
        SpamPredictionMarket market = SpamPredictionMarket(_market);
        IOutcomeToken[2] memory tokens = market.getOutcomeTokens();
        uint[2] memory payouts = market.getPayouts();
        for(uint i = 0; i < payouts.length; i++) {
            if(payouts[i] == 0) continue;
            canRedeem = canRedeem || tokens[i].balanceOf(_user) > 0;
        }
    }

}