
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOutcomeToken.sol";

interface ISpamPredictionMarket {
    function createPool(
        uint256[3] calldata amounts
    ) external;
    
    function buy(uint amount) external;
    
    function collateralToken() external view returns (IERC20);

    function getOutcomeTokens()
        external
        view
        returns (IOutcomeToken[2] memory);
}