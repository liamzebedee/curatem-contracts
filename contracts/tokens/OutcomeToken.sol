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
        // ERC20(name, ticker) 
        _name = name;
        _symbol = ticker;
        // Owned(_predictionMarket) 
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
