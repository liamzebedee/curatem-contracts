import "../vendor/CloneFactory.sol";
import "../vendor/Initializable.sol";
import "../tokens/OutcomeToken.sol";

contract Factory is Initializable, CloneFactory {
    address public outcomeToken;   

    constructor() public {}
    function initialize()
        public 
        uninitialized
    {
        outcomeToken = address(new OutcomeToken());
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
}