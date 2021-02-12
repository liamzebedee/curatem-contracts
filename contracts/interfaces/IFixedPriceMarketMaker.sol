import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IConditionalTokens.sol";

interface IFixedProductMarketMaker is IERC20, IERC1155Receiver {
    event FPMMFundingAdded(
        address indexed funder,
        uint[] amountsAdded,
        uint sharesMinted
    );
    event FPMMFundingRemoved(
        address indexed funder,
        uint[] amountsRemoved,
        uint sharesBurnt
    );
    event FPMMBuy(
        address indexed buyer,
        uint investmentAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensBought
    );
    event FPMMSell(
        address indexed seller,
        uint returnAmount,
        uint indexed outcomeIndex,
        uint outcomeTokensSold
    );

    // IConditionalTokens public conditionalTokens;
    // IERC20 public collateralToken;
    // bytes32[] public conditionIds;
    // uint public fee;


    function addFunding(uint addedFunds, uint[] calldata distributionHint)
        external;

    function removeFunding(uint sharesToBurn)
        external;

    // function onERC1155Received(
    //     address operator,
    //     address from,
    //     uint256 id,
    //     uint256 value,
    //     bytes calldata data
    // )
    //     external
    //     returns (bytes4);

    // function onERC1155BatchReceived(
    //     address operator,
    //     address from,
    //     uint256[] calldata ids,
    //     uint256[] calldata values,
    //     bytes calldata data
    // )
    //     external
    //     returns (bytes4);

    function calcBuyAmount(uint investmentAmount, uint outcomeIndex) external view returns (uint);

    function calcSellAmount(uint returnAmount, uint outcomeIndex) external view returns (uint outcomeTokenSellAmount);

    function buy(uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBuy) external;

    function sell(uint returnAmount, uint outcomeIndex, uint maxOutcomeTokensToSell) external;
}
