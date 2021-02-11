pragma solidity >=0.6.0;

import "./SpamPredictionMarket.sol";

interface Realitio {
    function askQuestion(uint256 template_id, string calldata question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) external payable returns (bytes32);
}

interface ConditionalTokens {
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external;

    /// @dev This function splits a position. If splitting from the collateral, this contract will attempt to transfer `amount` collateral from the message sender to itself. Otherwise, this contract will burn `amount` stake held by the message sender in the position being split worth of EIP 1155 tokens. Regardless, if successful, `amount` stake will be minted in the split target positions. If any of the transfers, mints, or burns fail, the transaction will revert. The transaction will also revert if the given partition is trivial, invalid, or refers to more slots than the condition is prepared with.
    /// @param collateralToken The address of the positions' backing collateral token.
    /// @param parentCollectionId The ID of the outcome collections common to the position being split and the split target positions. May be null, in which only the collateral is shared.
    /// @param conditionId The ID of the condition to split on.
    /// @param partition An array of disjoint index sets representing a nontrivial partition of the outcome slots of the given condition. E.g. A|B and C but not A|B and B|C (is not disjoint). Each element's a number which, together with the condition, represents the outcome collection. E.g. 0b110 is A|B, 0b010 is B, etc.
    /// @param amount The amount of collateral or stake to split.
    function splitPosition(
        address collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint[] calldata partition,
        uint amount
    ) external;
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


library GnosisHelpers {
    function generateBasicPartition(uint outcomeSlotCount)
        private
        pure
        returns (uint[] memory partition)
    {
        partition = new uint[](outcomeSlotCount);
        for(uint i = 0; i < outcomeSlotCount; i++) {
            partition[i] = 1 << i;
        }
    }

    // function getPositionIdsForOutcomeSlotCount(uint outcomeSlotCount) 
    //     returns (uint[] memory positionIds)
    // {
    //     positionIds = new uint[](partition.length);
    //     positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(parentCollectionId, conditionId, indexSet));
    // }

    // function splitPositionThroughAllConditions(uint amount)
    //     private
    // {
    //     for(uint i = conditionIds.length - 1; int(i) >= 0; i--) {
    //         uint[] memory partition = generateBasicPartition(outcomeSlotCounts[i]);
    //         for(uint j = 0; j < collectionIds[i].length; j++) {
    //             conditionalTokens.splitPosition(collateralToken, collectionIds[i][j], conditionIds[i], partition, amount);
    //         }
    //     }
    // }
}




contract CuratemCommunity {
    address public token;
    address public moderator;
    mapping(bytes32 => string) public itemUrlForDigest;

    event NewMarket(address market);
    event MarketCreated(bytes32 hashDigest, bytes32 conditionId, bytes32 questionId, address fixedProductMarketMaker);

    Realitio realitio;
    ConditionalTokens conditionalTokens;
    FPMMDeterministicFactory fpmmFactory;
    address realityIoGnosisProxy;
    address bFactory;

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
        address _bFactory,
        address _token,
        address _moderator
    ) 
        public 
    {
        realitio = Realitio(_realitio);
        realityIoGnosisProxy = _realityIoGnosisProxy;
        conditionalTokens = ConditionalTokens(_conditionalTokens);
        fpmmFactory = FPMMDeterministicFactory(_fpmmFactory);
        bFactory = _bFactory;

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
    ) 
        external returns (address) 
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
            timeout: 180,
            opening_ts: uint32(block.timestamp + timeoutResolution),
            nonce: uint256(hashDigest)
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

        
        // conditionalTokens.prepareCondition(
        //     realityIoGnosisProxy, // oracle
        //     questionId, 
        //     SPAM_MARKET_OUTCOME_SLOT_COUNT);
        bytes32 conditionId = 0x0;
        bytes32 fixedProductMarketMaker = 0x0;

        address market = new SpamPredictionMarket(
            realityIoGnosisProxy,
            token,
            bFactory
        );

        return market;
        // emit MarketCreated(hashDigest, conditionId, questionId, fixedProductMarketMaker);
    }

    function getUrl(bytes32 digest) public view returns (string memory) {
        return itemUrlForDigest[digest];
    }

    // function buy(
    //     bytes32 conditionId,
    //     uint investmentAmount, 
    //     uint outcomeIndex
    // ) external {
    //     require(token.transferFrom(msg.sender, address(this), investmentAmount), "cost transfer failed");
    //     require(token.approve(address(conditionalTokens), investmentAmount), "approval for splits failed");

    //     // Generate a set of partitions for the outcome collection.
    //     // Partitions are useful for more complicated use cases, where we have more than two sets of outcomes.
    //     // Here there are only two outcome sets, and thus two partitions.
    //     // 
    //     // Partitions are represented as index sets.
    //     // For an outcome collection containing two slots, SPAM and NOT SPAM,
    //     // There are only two possible partitions (SPAM and NOT SPAM).
    //     // These partitions are represented using an index set,
    //     // So for the above, it is a binary string of 1 bit.
    //     uint[] partitions = CTHelpers.generateBasicPartition(SPAM_MARKET_OUTCOME_SLOT_COUNT);
    //     uint partition = partitions[outcomeIndex];

    //     bytes32 NULL_PARENT_COLLECTION = 0x0;

    //     // Split the collateral into outcome tokens.
    //     conditionalTokens.splitPosition(
    //         token, 
    //         NULL_PARENT_COLLECTION, 
    //         conditionId, 
    //         partitions[outcomeIndex], 
    //         investmentAmount
    //     );

    //     // Compute the ERC1155 position token ID, for the partition.
    //     uint256 positionId = CTHelpers.getPositionId(token, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, partition));

    //     // positionIds = new uint[](partition.length);
    //     // positionIds[i] = CTHelpers.getPositionId(collateralToken, CTHelpers.getCollectionId(NULL_PARENT_COLLECTION, conditionId, indexSet));

    //     // Now transfer those tokens to the sender.
    //     conditionalTokens.safeTransferFrom(
    //         address(this), 
    //         msg.sender, 
    //         positionId, 
    //         investmentAmount, 
    //         ""
    //     );
    // }


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