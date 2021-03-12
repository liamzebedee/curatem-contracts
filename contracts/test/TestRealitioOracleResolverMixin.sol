import "../market/RealitioOracleResolverMixin.sol";

contract TestRealitioOracleResolverMixin is RealitioOracleResolverMixin {
    address private oracle;
    
    uint256[] public payouts;

    function initialize(
        bytes32 _questionId,
        address _oracle
    ) 
        public
    {
        oracle = _oracle;
        RealitioOracleResolverMixin.initialize(_questionId);
    }

    // 
    // ISpamPredictionMarket
    // 

    function reportPayouts(uint256[] calldata _payouts) external {
        payouts = _payouts;
    }

    function realitio() internal override returns (IRealitio) {
        return IRealitio(oracle);
    }
}