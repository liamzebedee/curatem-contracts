import "../vendor/CloneFactory.sol";
import "../vendor/Initializable.sol";
import "../tokens/OutcomeToken.sol";
import "../SpamPredictionMarket.sol";

contract Factory is Initializable, CloneFactory {
    address public outcomeToken;
    address public spamPredictionMarket;

    constructor() public {}
    function initialize()
        public 
        uninitialized
    {
        outcomeToken = address(new OutcomeToken());
        spamPredictionMarket = address(new SpamPredictionMarket());
    }

    function newOutcomeToken(
        string calldata name, 
        string calldata ticker, 
        address _predictionMarket
    )
        external
        returns (address)
    {
        address clone = createClone(outcomeToken);
        OutcomeToken(clone).initialize(name, ticker, _predictionMarket);
        return clone;
    }

    function newSpamPredictionMarket(
        address _oracle,
        address _collateralToken,
        address _uniswapFactory,
        address _factory
    )
        external
        returns (address)
    {
        address clone = createClone(spamPredictionMarket);
        SpamPredictionMarket(clone).initialize(
            _oracle,
            _collateralToken,
            _uniswapFactory,
            _factory
        );
        return clone;
    }

    // function newModeratorArbitrator(
    // )
    //     external
    //     returns (address)
    // {

    // }
}