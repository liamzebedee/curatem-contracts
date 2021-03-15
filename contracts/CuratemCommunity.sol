pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRealitio.sol";
import "./interfaces/IArbitrator.sol";
import "./interfaces/IConditionalTokens.sol";
import "./market/SpamPredictionMarket.sol";
import "./moderator/ModeratorArbitrator.sol";
import "hardhat/console.sol";
import "./proxy/Proxyable.sol";
import "./vendor/Owned.sol";
import "./vendor/Initializable.sol";

contract CuratemCommunity is Initializable {
    IERC20 public token;
    IRealitio public realitio;
    address public uniswapFactory;
    Factory public factory;
    address payable public moderatorArbitrator;

    uint32 public timeoutResolution = 5 minutes;
    mapping(bytes32 => string) public itemUrlForDigest;

    string constant REALITIO_UNICODE_SEPERATOR = "\u241F";
    uint256 constant MAX_UINT = 2**256 - 1;

    event NewSpamPredictionMarket(bytes32 hashDigest, bytes32 questionId, address market);

    constructor(
    ) 
        public 
    {
    }

    function initialize(
        address _realitio,
        address _uniswapFactory,
        address _factory,
        address _token,
        address payable _moderatorArbitrator
    )
        public
        uninitialized
    {
        realitio = IRealitio(_realitio);
        factory = Factory(_factory);
        uniswapFactory = _uniswapFactory;

        token = IERC20(_token);
        moderatorArbitrator = _moderatorArbitrator;
        require(
            ModeratorArbitrator(moderatorArbitrator).impl().realitio() == realitio,
            "ERR_MODERATOR_ARBITRATOR_REALITIO"
        );
    }

    // function setTimeout(uint32 _timeoutResolution) public {
    //     timeoutResolution = _timeoutResolution;
    // }

    // function setModeratorArbitrator(
    //     address _moderatorArbitrator
    // )
    //     public 
    // {
    //     ModeratorArbitrator(moderatorArbitrator).setTarget(Proxyable(_moderatorArbitrator));
    // }

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
            // "Is this spam? - https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/␟"Spam","Not spam"␟Spam Classification␟en_US"
            question: string(abi.encodePacked(
                "Is this spam? - ", url, REALITIO_UNICODE_SEPERATOR, "\"Not Spam\",\"Spam\"", REALITIO_UNICODE_SEPERATOR, "Spam Classification", REALITIO_UNICODE_SEPERATOR, "en_US")),
            arbitrator: moderatorArbitrator,
            timeout: timeoutResolution,
            opening_ts: uint32(block.timestamp),
            nonce: uint256(hashDigest)
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
            address(realitio),
            address(token),
            uniswapFactory,
            address(factory),
            questionId
        );

        emit NewSpamPredictionMarket(hashDigest, questionId, market);
        return market;
    }

    function getUrl(bytes32 digest) public view returns (string memory) {
        return itemUrlForDigest[digest];
    }
}