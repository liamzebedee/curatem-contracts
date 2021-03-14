
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOutcomeToken.sol";

interface ISpamPredictionMarket {
    function buy(uint amount) external;
    
    function collateralToken() external view returns (IERC20);

    function getOutcomeTokens()
        external
        view
        returns (IOutcomeToken[2] memory);
    
    function oracle() external view returns (address);

    function reportPayouts(uint256[] calldata payouts) external;
}