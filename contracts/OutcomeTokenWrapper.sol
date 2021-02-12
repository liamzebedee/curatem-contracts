pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./vendor/Owned.sol";

contract OutcomeTokenWrapped is ERC20, Owned {
    constructor(uint256 initialSupply, string memory name, string memory ticker) public ERC20(name, ticker) Owned(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address account, uint amount) public onlyOwner() {
        _mint(account, amount);
    }
}