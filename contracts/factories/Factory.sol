import "../vendor/CloneFactory.sol";
import "../vendor/Initializable.sol";
import "../tokens/OutcomeToken.sol";
import "../market/SpamPredictionMarket.sol";
import "../CuratemCommunity.sol";

contract Factory is Initializable, CloneFactory {
    address public outcomeToken;
    address public spamPredictionMarket;
    address public curatemCommunity;

    constructor() public {}
    
    function initialize(
        address _curatemCommunity
    )
        public 
        uninitialized
    {
        outcomeToken = address(new OutcomeToken());
        spamPredictionMarket = address(new SpamPredictionMarket());
        curatemCommunity = _curatemCommunity;
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
        address _factory,
        bytes32 _questionId
    )
        external
        returns (address)
    {
        address clone = createClone(spamPredictionMarket);
        SpamPredictionMarket(clone).initialize(
            _oracle,
            _collateralToken,
            _uniswapFactory,
            _factory,
            _questionId
        );
        return clone;
    }

    function newCommunity(
        address _realitio,
        address _realitioOracle,
        address _uniswapFactory,
        address _factory,
        address _token,
        address payable _moderatorArbitrator
    )
        external
        returns (address)
    {
        address clone = createClone(curatemCommunity);
        CuratemCommunity(clone).initialize(
            _realitio,
            _realitioOracle,
            _uniswapFactory,
            _factory,
            _token,
            _moderatorArbitrator
        );
        return clone;
    }
}