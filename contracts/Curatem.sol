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
    mapping(bytes32 => string) public itemUrlForDigest;

    event MarketCreated(bytes32 hashDigest, bytes32 conditionId, bytes32 questionId);

    Realitio realitio;
    ConditionalTokens conditionalTokens;
    FPMMDeterministicFactory fpmmFactory;
    address realityIoGnosisProxy;

    uint32 constant timeoutResolution = 5 minutes;
    string constant REALITIO_UNICODE_SEPERATOR = "\u241F";
    // string constant REALITIO_UNICODE_SEPERATOR = string(0xE2909F);

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    // bytes32 private constant CONTRACT_FPMMDeterministicFactory = "FPMMDeterministicFactory";
    // bytes32 private constant CONTRACT_ConditionalTokens = "ConditionalTokens";
    // bytes32 private constant CONTRACT_RealitioProxy = "RealitioProxy";
    // bytes32 private constant CONTRACT_Realitio = "Realitio";
    // bytes32 private constant CONTRACT_WETH9 = "WETH9";    

    constructor(
        address _realitio,
        address _realityIoGnosisProxy,
        address _conditionalTokens,
        address _fpmmFactory,
        address _token,
        address _moderator
    ) 
        public 
    {
        realitio = Realitio(_realitio);
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = ConditionalTokens(_conditionalTokens);
        fpmmFactory = FPMMDeterministicFactory(_fpmmFactory);

        token = _token;
        moderator = _moderator;
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
        string calldata url
    ) external {
        bytes32 hashDigest = sha256(abi.encodePacked(url));
        require(bytes(itemUrlForDigest[hashDigest]).length == 0, "Market already created for URL");
        itemUrlForDigest[hashDigest] = url;
        
        QuestionIdVars memory questionId_vars = QuestionIdVars({
            template_id: 2,
            // "Is this spam? https://www.reddit.com/r/ethereum/comments/hbjx25/the_great_reddit_scaling_bakeoff/␟"Spam","Not spam"␟Spam Classification␟en_US"
            question: string(abi.encodePacked(
                "Is this spam?", REALITIO_UNICODE_SEPERATOR, "\"Spam\",\"Not spam\"", REALITIO_UNICODE_SEPERATOR, "Spam Classification", REALITIO_UNICODE_SEPERATOR, "en_US")),
            arbitrator: moderator,
            timeout: 180,
            opening_ts: uint32(block.timestamp + timeoutResolution),
            nonce: uint256(hashDigest),

            // constants
            outcomeSlotCount: 2
        });

        // Calculate the questionId
        // bytes32 content_hash = keccak256(abi.encodePacked(
        //     questionId_vars.template_id, 
        //     questionId_vars.opening_ts, 
        //     questionId_vars.question));
        // bytes32 questionId = keccak256(abi.encodePacked(
        //     content_hash, 
        //     questionId_vars.arbitrator, 
        //     questionId_vars.timeout, 
        //     address(this), 
        //     questionId_vars.nonce));

        // Create the market for the post ID.
        bytes32 questionId = realitio.askQuestion(
            questionId_vars.template_id, 
            questionId_vars.question, 
            questionId_vars.arbitrator, 
            questionId_vars.timeout, 
            questionId_vars.opening_ts, 
            questionId_vars.nonce);

        bytes32 conditionId = keccak256(abi.encodePacked(
            realityIoGnosisProxy, 
            questionId, 
            questionId_vars.outcomeSlotCount));

        
        conditionalTokens.prepareCondition(
            realityIoGnosisProxy, // oracle
            questionId, 
            questionId_vars.outcomeSlotCount);


        uint[] memory distributionHint;
        bytes32[] memory conditionIds = new bytes32[](1);
        conditionIds[0] = conditionId;

        fpmmFactory.create2FixedProductMarketMaker(
            questionId_vars.nonce, // saltNonce, 
            address(conditionalTokens), 
            token, // collateralAddress, 
            conditionIds,
            0, // fee, 
            0, 
            distributionHint
        );

        emit MarketCreated(hashDigest, conditionId, questionId);
    }

    function getUrl(bytes32 digest) public view returns (string memory) {
        return itemUrlForDigest[digest];
    }


    // function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
    //     // bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
    //     bytes32[] memory newAddresses = new bytes32[](5);
    //     newAddresses[0] = CONTRACT_FPMMDeterministicFactory;
    //     newAddresses[1] = CONTRACT_ConditionalTokens;
    //     newAddresses[2] = CONTRACT_RealitioProxy;
    //     newAddresses[3] = CONTRACT_Realitio;
    //     newAddresses[4] = CONTRACT_WETH9;
    //     addresses = newAddresses;
    //     // addresses = combineArrays(existingAddresses, newAddresses);
    // }

    // function fpmmFactory() internal view returns (FPMMDeterministicFactory) {
    //     return FPMMDeterministicFactory(requireAndGetAddress(CONTRACT_FPMMDeterministicFactory));
    // }

    // function conditionalTokens() internal view returns (address) {
    //     return FPMMDeterministicFactory(requireAndGetAddress(CONTRACT_ConditionalTokens));
    // }
}

contract Curatem {
    address realitio;
    address conditionalTokens;
    address fpmmFactory;
    address realityIoGnosisProxy;
    address weth9;

    event NewCommunity(address community);

    constructor(
        address _realitio,
        address _realityIoGnosisProxy,
        address _conditionalTokens,
        address _fpmmFactory
    ) 
        public 
    {
        realitio = _realitio;
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = _conditionalTokens;
        fpmmFactory = _fpmmFactory;
    }

    function createCommunity(
        bytes32 salt,
        address _token,
        address _moderator
    ) public returns (address) {
        CuratemCommunity community = new CuratemCommunity{ salt: salt }(
            realitio,
            realityIoGnosisProxy,
            conditionalTokens,
            fpmmFactory,
            _token, 
            msg.sender
        );
        
        emit NewCommunity(address(community));
        
        return address(community);
    }
}

