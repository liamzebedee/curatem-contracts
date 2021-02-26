
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOutcomeToken is IERC20 {
    function burn(address account, uint amount) external;
    function mint(address account, uint amount) external;
}