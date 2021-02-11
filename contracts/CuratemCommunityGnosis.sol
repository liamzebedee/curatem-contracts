contract CuratemCommunity {
    address public token;
    address public moderator;
    mapping(bytes32 => string) public itemUrlForDigest;

    event MarketCreated(bytes32 hashDigest, bytes32 conditionId, bytes32 questionId, address fixedProductMarketMaker);

    Realitio realitio;
    ConditionalTokens conditionalTokens;
    FPMMDeterministicFactory fpmmFactory;
    address realityIoGnosisProxy;

    uint32 constant timeoutResolution = 5 minutes;
    uint constant SPAM_MARKET_OUTCOME_SLOT_COUNT = 2;
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
            SPAM_MARKET_OUTCOME_SLOT_COUNT);


        uint[] memory distributionHint;
        bytes32[] memory conditionIds = new bytes32[](1);
        conditionIds[0] = conditionId;

        address fixedProductMarketMaker = fpmmFactory.create2FixedProductMarketMaker(
            questionId_vars.nonce, // saltNonce, 
            address(conditionalTokens), 
            token, // collateralAddress, 
            conditionIds,
            0, // fee, 
            0, 
            distributionHint
        );

        emit MarketCreated(hashDigest, conditionId, questionId, fixedProductMarketMaker);
    }

    function getUrl(bytes32 digest) public view returns (string memory) {
        return itemUrlForDigest[digest];
    }

    function buy(
        bytes32 conditionId,
        uint investmentAmount, 
        uint outcomeIndex
    ) external {
        require(token.transferFrom(msg.sender, address(this), investmentAmount), "cost transfer failed");
        require(token.approve(address(conditionalTokens), investmentAmount), "approval for splits failed");

        // Generate a set of partitions for the outcome collection.
        // Partitions are useful for more complicated use cases, where we have more than two sets of outcomes.
        // Here there are only two outcome sets, and thus two partitions.
        // 
        // Partitions are represented as index sets.
        // For an outcome collection containing two slots, SPAM and NOT SPAM,
        // There are only two possible partitions (SPAM and NOT SPAM).
        // These partitions are represented using an index set,
        // So for the above, it is a binary string of 1 bit.
        uint[] partitions = CTHelpers.generateBasicPartition(SPAM_MARKET_OUTCOME_SLOT_COUNT);
        uint partition = partitions[outcomeIndex];

        bytes32 NULL_PARENT_COLLECTION = 0x0;

        // Split the collateral into outcome tokens.
        conditionalTokens.splitPosition(
            token, 
            NULL_PARENT_COLLECTION, 
            conditionId, 
            partitions[outcomeIndex], 
            investmentAmount
        );

        // Compute the ERC1155 position token ID, for the partition.
        uint256 positionId = CTHelpers.getPositionId(token, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, partition));

        // positionIds = new uint[](partition.length);
        // positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, indexSet));

        // Now transfer those tokens to the sender.
        conditionalTokens.safeTransferFrom(
            address(this), 
            msg.sender, 
            positionId, 
            investmentAmount, 
            ""
        );
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