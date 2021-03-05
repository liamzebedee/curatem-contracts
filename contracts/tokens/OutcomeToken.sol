pragma solidity >=0.6.4;

import "../vendor/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../vendor/Owned.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IOutcomeToken.sol";

contract OutcomeToken is ERC20, Owned, IOutcomeToken, Initializable {
    uint constant MAX_UINT = 2**256 - 1;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor() 
        public 
        ERC20("", "")
        Owned(msg.sender)
    {
    }

    function initialize(
        string memory name, 
        string memory ticker, 
        address _predictionMarket
    ) 
        public 
        uninitialized
    {
        _name = name;
        _symbol = ticker;
        _decimals = 18;
        owner = _predictionMarket;
    }

    function mint(address account, uint amount) 
        external 
        override
        onlyOwner() 
    {
        _mint(account, amount);
    }

    function burn(address account, uint amount) 
        external 
        override
        onlyOwner() 
    {
        _burn(account, amount);
    }

    function name()
        public
        view
        override
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        public
        view
        override
        returns (string memory)
    {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // function allowance(address owner, address spender) 
    //     external 
    //     view 
    //     override
    //     returns (uint256)
    // {
    //     // Allow _predictionMarket to transfer without approvals.
    //     // This is use
    //     if(spender == msg.sender) {
    //         return MAX_UINT;
    //     }
    //     return _allowance(owner, spender);
    // }
}
