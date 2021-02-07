pragma solidity ^0.7.0;

interface Realitio {
    function askQuestion(uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
}

interface ConditionalTokens {
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external;
}

interface FPMMDeterministicFactory {
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
    address public token;
    address public moderator;

    constructor(
        address _token,
        address _moderator
    ) public {
        token = _token;
        moderator = _moderator;
    }
}

contract Curatem {
    // event MarketCreated(bytes32 multihash1, bytes32 multihash2);
    // event NewCommunity(address community);
    event MarketCreated(address community, bytes32 hashDigest, bytes32 conditionId, bytes32 questionId);

    mapping(bytes32 => address) itemToMarket;
    // event CommunityCreated();
    address moderator;

    address REALITYIO_GNOSIS_PROXY_ADDRESS;
    Realitio realitio;
    ConditionalTokens conditionalTokens;
    FPMMDeterministicFactory fpmmFactory;
    address WETH9;


    uint32 constant timeoutResolution = 5 minutes;
    // string constant REALITIO_UNICODE_SEPERATOR = string(0xE2909F);
    string constant REALITIO_UNICODE_SEPERATOR = "\uE2909F";
    
    constructor(
        address _realitio,
        address _conditionalTokens,
        address _REALITYIO_GNOSIS_PROXY_ADDRESS,
        address _FPMMDeterministicFactory,
        address _WETH9
    ) public {
        moderator = msg.sender;
        realitio = Realitio(_realitio);
        conditionalTokens = ConditionalTokens(_conditionalTokens);
        fpmmFactory = FPMMDeterministicFactory(_FPMMDeterministicFactory);
        WETH9 = _WETH9;
        REALITYIO_GNOSIS_PROXY_ADDRESS = _REALITYIO_GNOSIS_PROXY_ADDRESS;
    }

    struct QuestionIdVars {
        uint256 template_id;
        string question; 
        address arbitrator; 
        uint32 timeout; 
        uint32 opening_ts;
        uint256 nonce;
        uint outcomeSlotCount;
    }

    function createMarket(
        address communityId,
        bytes32 hashDigest
    ) public {
        CuratemCommunity community = CuratemCommunity(communityId);
        
        QuestionIdVars memory questionId_vars = QuestionIdVars({
            template_id: 2,
            // "Is this spam? https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/␟"Spam","Not spam"␟Spam Classification␟en_US"
            question: string(abi.encodePacked(
                "Is this spam?", REALITIO_UNICODE_SEPERATOR, "\"Spam\",\"Not spam\"", REALITIO_UNICODE_SEPERATOR, "Spam Classification", REALITIO_UNICODE_SEPERATOR, "en_US")),
            arbitrator: community.moderator(),
            // timeoutResolution
            timeout: 180,
            opening_ts: uint32(block.timestamp + timeoutResolution),
            nonce: uint256(hashDigest),

            // constants
            outcomeSlotCount: 2
        });

        // Calculate the questionId
        bytes32 content_hash = keccak256(abi.encodePacked(
            questionId_vars.template_id, 
            questionId_vars.opening_ts, 
            questionId_vars.question));
        bytes32 questionId = keccak256(abi.encodePacked(
            content_hash, 
            questionId_vars.arbitrator, 
            questionId_vars.timeout, 
            msg.sender, 
            questionId_vars.nonce));
        bytes32 conditionId = keccak256(abi.encodePacked(
            REALITYIO_GNOSIS_PROXY_ADDRESS, 
            questionId, 
            questionId_vars.outcomeSlotCount));

        // Create the market for the post ID.
        realitio.askQuestion(
            questionId_vars.template_id, 
            questionId_vars.question, 
            questionId_vars.arbitrator, 
            questionId_vars.timeout, 
            questionId_vars.opening_ts, 
            questionId_vars.nonce);
        
        conditionalTokens.prepareCondition(
            REALITYIO_GNOSIS_PROXY_ADDRESS, // oracle
            questionId, questionId_vars.outcomeSlotCount);


        uint[] memory distributionHint;
        bytes32[] memory conditionIds = new bytes32[](1);
        conditionIds[0] = conditionId;

        fpmmFactory.create2FixedProductMarketMaker(
            questionId_vars.nonce, // saltNonce, 
            address(conditionalTokens), 
            community.token(), // collateralAddress, 
            conditionIds,
            0, // fee, 
            0, 
            distributionHint
        );

        emit MarketCreated(address(community), hashDigest, conditionId, questionId);
    }
}

