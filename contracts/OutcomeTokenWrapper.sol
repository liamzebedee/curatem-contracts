import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract OutcomeTokenWrapped is ERC20, Owned {
    constructor(uint256 initialSupply, string name, string ticker) public ERC20(name, ticker) Owned(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address account, uint amount) public onlyOwner() {
        _mint(account, amount);
    }
}