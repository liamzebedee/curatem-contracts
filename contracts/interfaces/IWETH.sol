
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface WETH9 is IERC20 {
    function deposit() external payable;
}