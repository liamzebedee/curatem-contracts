pragma solidity >=0.6.0;

import "./interfaces/IRealitio.sol";
import "./interfaces/IConditionalTokens.sol";
import "./vendor/CTHelpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//x import "@gnosis.pm/conditional-tokens-market-makers/contracts/FixedProductMarketMaker.sol";
import "./SpamPredictionMarket.sol";


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
    address public moderator;
    mapping(bytes32 => string) public itemUrlForDigest;

    event MarketCreated(bytes32 hashDigest, bytes32 conditionId, bytes32 questionId, address fixedProductMarketMaker);
    event NewSpamPredictionMarket(bytes32 hashDigest, bytes32 questionId, address market);

    IRealitio realitio;
    IConditionalTokens conditionalTokens;
    IFPMMDeterministicFactory fpmmFactory;
    address realityIoGnosisProxy;
    address uniswapFactory;
    address factory;

    uint32 timeoutResolution = 5 minutes;
    uint constant SPAM_MARKET_OUTCOME_SLOT_COUNT = 2;
    string constant REALITIO_UNICODE_SEPERATOR = "\u241F";
    uint constant MAX_UINT = 2**256 - 1;

    constructor(
        address _realitio,
        address _realityIoGnosisProxy,
        address _conditionalTokens,
        address _fpmmFactory,
        address _uniswapFactory,
        address _factory,
        address _token,
        address _moderator
    ) 
        public 
    {
        realitio = IRealitio(_realitio);
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = IConditionalTokens(_conditionalTokens);
        fpmmFactory = IFPMMDeterministicFactory(_fpmmFactory);
        factory = _factory;
        uniswapFactory = _uniswapFactory;

        token = IERC20(_token);
        moderator = _moderator;
    }


    function createMarket(
        string calldata url
    ) 
        external returns (address) 
    {
        return createPredictionMarket(url);
        // return createGnosisMarket(url);
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
                "Is this spam?", REALITIO_UNICODE_SEPERATOR, "\"Spam\",\"Not spam\"", REALITIO_UNICODE_SEPERATOR, "Spam Classification", REALITIO_UNICODE_SEPERATOR, "en_US")),
            arbitrator: moderator,
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
        
        SpamPredictionMarket market = new SpamPredictionMarket(
            questionId_vars.oracle,
            address(token),
            uniswapFactory,
            factory
        );
        market.initialize();

        // Allow market to call transferFrom on these tokens.
        // token.approve(market, MAX_UINT);

        emit NewSpamPredictionMarket(hashDigest, questionId, address(market));
        return address(market);
    }

    function getUrl(bytes32 digest) public view returns (string memory) {
        return itemUrlForDigest[digest];
    }


    // function createGnosisMarket(
    //     string memory url
    // ) 
    //     internal returns (address) 
    // {
    //     bytes32 hashDigest = sha256(abi.encodePacked(url));
    //     require(bytes(itemUrlForDigest[hashDigest]).length == 0, "Market already created for URL");
    //     itemUrlForDigest[hashDigest] = url;
        
    //     QuestionIdVars memory questionId_vars = QuestionIdVars({
    //         template_id: 2,
    //         // "Is this spam? https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/␟"Spam","Not spam"␟Spam Classification␟en_US"
    //         question: string(abi.encodePacked(
    //             "Is this spam?", REALITIO_UNICODE_SEPERATOR, "\"Spam\",\"Not spam\"", REALITIO_UNICODE_SEPERATOR, "Spam Classification", REALITIO_UNICODE_SEPERATOR, "en_US")),
    //         arbitrator: moderator,
    //         timeout: 180,
    //         opening_ts: uint32(block.timestamp + timeoutResolution),
    //         nonce: uint256(hashDigest),
    //         oracle: realityIoGnosisProxy
    //     });

    //     // Create the market for the post ID.
    //     bytes32 questionId = realitio.askQuestion(
    //         questionId_vars.template_id, 
    //         questionId_vars.question, 
    //         questionId_vars.arbitrator, 
    //         questionId_vars.timeout, 
    //         questionId_vars.opening_ts, 
    //         questionId_vars.nonce);
        
    //     bytes32 conditionId = CTHelpers.getConditionId(questionId_vars.oracle, questionId, SPAM_MARKET_OUTCOME_SLOT_COUNT);

    //     conditionalTokens.prepareCondition(
    //         questionId_vars.oracle,
    //         questionId, 
    //         SPAM_MARKET_OUTCOME_SLOT_COUNT);


    //     uint[] memory distributionHint;
    //     bytes32[] memory conditionIds = new bytes32[](1);
    //     conditionIds[0] = conditionId;

    //     address fixedProductMarketMaker = fpmmFactory.create2FixedProductMarketMaker(
    //         questionId_vars.nonce, // saltNonce, 
    //         address(conditionalTokens), 
    //         address(token), // collateralAddress, 
    //         conditionIds,
    //         0, // fee, 
    //         0, 
    //         distributionHint
    //     );

    //     emit MarketCreated(hashDigest, conditionId, questionId, fixedProductMarketMaker);
    //     return fixedProductMarketMaker;
    // }

    // function spamToken(bytes32 conditionId) public view returns (uint256 tokenId) {
    //     bytes32 NULL_PARENT_COLLECTION = bytes32(0);
    //     return CTHelpers.getPositionId(token, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, 0x1));
    // }

    // function notSpamToken(bytes32 conditionId) public view returns (uint256 tokenId) {
    //     bytes32 NULL_PARENT_COLLECTION = bytes32(0);
    //     return CTHelpers.getPositionId(token, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, 0x2));
    // }

    // function getPositionToken(bytes32 conditionId, uint outcome) public view returns (uint256 tokenId) {
    //     uint[] memory partition = CTHelpers.generateBasicPartition(SPAM_MARKET_OUTCOME_SLOT_COUNT);
    //     bytes32 NULL_PARENT_COLLECTION = 0x0;
    //     tokenId = CTHelpers.getPositionId(
    //         token, 
    //         CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, partition[outcome])
    //     );
    //     return tokenId;
    // }

    /**
    //  * @param from The user we are transferring tokens from.
    //  * @param to The external contract requesting proxied transfer.
    //  */
    // function proxyTransfer(address from, uint amount)  
    //     external 
    // {
    //     address to = msg.sender;
    //     // require(to == msg.sender, "proxyTransfer can only be called by contract");
    //     require(token.allowance(from, address(this)) >= amount, "allowance not granted to CuratemCommunity by user");
    //     require(token.allowance(address(this), to) >= amount, "allowance not granted for proxy transfer");
    //     require(token.balanceOf(from) >= amount, "proxy transfer amount >= balance");
    //     token.transferFrom(from, to, amount);
    // }

    // function buy(
    //     bytes32 conditionId,
    //     uint investmentAmount, 
    //     uint outcomeIndex
    // ) external {
    //     require(token.transferFrom(msg.sender, address(this), investmentAmount), "cost transfer failed");
    //     require(token.approve(address(conditionalTokens), investmentAmount), "approval for splits failed");

        // Generate a set of partitions for the outcome collection.
        // Partitions are useful for more complicated use cases, where we have more than two sets of outcomes.
        // Here there are only two outcome sets, and thus two partitions.
        // 
        // Partitions are represented as index sets.
        // For an outcome collection containing two slots, SPAM and NOT SPAM,
        // There are only two possible partitions (SPAM and NOT SPAM).
        // These partitions are represented using an index set,
        // So for the above, it is a binary string of 1 bit.
        // uint[] memory partition = CTHelpers.generateBasicPartition(SPAM_MARKET_OUTCOME_SLOT_COUNT);
        // // uint partition = partitions[outcomeIndex];

        // bytes32 NULL_PARENT_COLLECTION = 0x0;

        // // Split the collateral into outcome tokens.
        // conditionalTokens.splitPosition(
        //     address(token), 
        //     NULL_PARENT_COLLECTION, 
        //     conditionId, 
        //     partition, 
        //     investmentAmount
        // );

        // // Compute the ERC1155 position token ID, for the partition.
        // uint256 positionId = CTHelpers.getPositionId(token, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, partition));

        // // uint[] positionIds = new uint[](partition.length);
        // // positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, indexSet));

        // // Now transfer those tokens to the sender.
        // conditionalTokens.safeTransferFrom(
        //     address(this), 
        //     msg.sender, 
        //     positionId, 
        //     investmentAmount, 
        //     ""
        // );
    // }
}