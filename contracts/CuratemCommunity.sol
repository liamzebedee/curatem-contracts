pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRealitio.sol";
import "./interfaces/IConditionalTokens.sol";
import "./SpamPredictionMarket.sol";
import "./ModeratorArbitrator.sol";


interface IFPMMDeterministicFactory {
    function create2FixedProductMarketMaker(
     uint saltNonce,
     address conditionalTokens,
     address collateralToken,
     bytes32[] calldata conditionIds,
     uint fee,
     uint initialFunds,
     uint[] calldata distributionHint
  ) external returns (address);
}

contract CuratemCommunity {
    IERC20 public token;
    ModeratorArbitrator public moderatorArbitrator;
    mapping(bytes32 => string) public itemUrlForDigest;

    event MarketCreated(bytes32 hashDigest, bytes32 conditionId, bytes32 questionId, address fixedProductMarketMaker);
    event NewSpamPredictionMarket(bytes32 hashDigest, bytes32 questionId, address market);

    IRealitio realitio;
    IConditionalTokens conditionalTokens;
    IFPMMDeterministicFactory fpmmFactory;
    address realityIoGnosisProxy;
    address uniswapFactory;
    Factory factory;

    uint32 timeoutResolution = 5 minutes;
    uint constant SPAM_MARKET_OUTCOME_SLOT_COUNT = 2;
    string constant REALITIO_UNICODE_SEPERATOR = "\u241F";
    uint constant MAX_UINT = 2**256 - 1;

    constructor(
    ) 
        public 
    {   
    }

    function initialize(
        address _realitio,
        address _realityIoGnosisProxy,
        address _conditionalTokens,
        address _fpmmFactory,
        address _uniswapFactory,
        address _factory,
        address _token,
        address _moderatorArbitrator
    )
        public
    {
        realitio = IRealitio(_realitio);
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = IConditionalTokens(_conditionalTokens);
        fpmmFactory = IFPMMDeterministicFactory(_fpmmFactory);
        factory = Factory(_factory);
        uniswapFactory = _uniswapFactory;

        token = IERC20(_token);
        moderatorArbitrator = ModeratorArbitrator(_moderatorArbitrator);
        require(address(moderatorArbitrator.realitio()) == _realitio, "ERR_MODERATOR_ARBITRATOR_REALITIO");
    }

    function createMarket(
        string calldata url
    ) 
        external returns (address) 
    {
        return createPredictionMarket(url);
    }

    struct QuestionIdVars {
        uint256 template_id;
        string question; 
        address arbitrator; 
        uint32 timeout; 
        uint32 opening_ts;
        uint256 nonce;
        address oracle;
    }

    function setTimeout(uint32 _timeoutResolution) public {
        timeoutResolution = _timeoutResolution;
    }

    function createPredictionMarket(
        string memory url
    ) 
        internal returns (address) 
    {
        bytes32 hashDigest = sha256(abi.encodePacked(url));
        require(bytes(itemUrlForDigest[hashDigest]).length == 0, "Market already created for URL");
        itemUrlForDigest[hashDigest] = url;
        
        QuestionIdVars memory questionId_vars = QuestionIdVars({
            template_id: 2,
            // "Is this spam? https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/␟"Spam","Not spam"␟Spam Classification␟en_US"
            question: string(abi.encodePacked(
                "Is this spam? - ", url, REALITIO_UNICODE_SEPERATOR, "\"Not Spam\",\"Spam\"", REALITIO_UNICODE_SEPERATOR, "Spam Classification", REALITIO_UNICODE_SEPERATOR, "en_US")),
            arbitrator: address(moderatorArbitrator),
            timeout: timeoutResolution,
            opening_ts: uint32(block.timestamp),
            nonce: uint256(hashDigest),
            oracle: realityIoGnosisProxy
        });

        // Create the question for the post ID.
        bytes32 questionId = realitio.askQuestion(
            questionId_vars.template_id, 
            questionId_vars.question, 
            questionId_vars.arbitrator, 
            questionId_vars.timeout, 
            questionId_vars.opening_ts, 
            questionId_vars.nonce);
        
        address market = factory.newSpamPredictionMarket(
            questionId_vars.oracle,
            address(token),
            uniswapFactory,
            address(factory)
        );

        emit NewSpamPredictionMarket(hashDigest, questionId, market);
        return market;
    }

    function getUrl(bytes32 digest) public view returns (string memory) {
        return itemUrlForDigest[digest];
    }
}