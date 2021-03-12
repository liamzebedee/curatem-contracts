// import "../market/RealitioOracleResolverMixin.sol";
// import "../interfaces/ISpamPredictionMarket.sol";

// contract MockMarket is ISpamPredictionMarket, RealitioOracleResolverMixin {
//     address override oracle;
//     constructor() 
//         public
//     {
//     }

//     function buy(uint amount) external {}

//     function collateralToken() external view returns (IERC20) {
//         return address(0);
//     }


//     function initialize(
//         address _oracle,
//         address _collateralToken,
//         address _uniswapFactory,
//         address _factory,
//         bytes32 _questionId
//     ) 
//         public 
//     {
//         oracle = _oracle;
//         RealitioOracleResolverMixin.initialize(_questionId);
//     }
// }