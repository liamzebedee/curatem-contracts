pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./vendor/Owned.sol";
import "./interfaces/BPool.sol";

interface BFactory {
    function newBPool() external returns (address);
}

interface IOracle {

}

// Design
// - Balancer pool.
// - Integration with Gnosis conditional tokens.
// - wrapper around gnosis tokens.


contract SpamToken is ERC20, Owned {
    constructor(uint256 initialSupply) public ERC20("Spam", "SPAM") Owned(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address account, uint amount) public onlyOwner() {
        _mint(account, amount);
    }
}

contract NotSpamToken is ERC20, Owned {
    constructor(uint256 initialSupply) public ERC20("Not Spam", "JAM") Owned(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address account, uint amount) public onlyOwner() {
        _mint(account, amount);
    }
}

contract SpamPredictionMarket {
    BFactory bFactory;
    BPool pool;
    IERC20 spamToken;
    IERC20 notSpamToken;
    IERC20 collateralToken;
    IOracle oracle;

    enum MARKET_STATUS {
        INITIALIZING,
        OPEN,
        REPORTING,
        FINALIZED
    }

    uint marketState = MARKET_STATUS.INITIALIZING;
    uint outcome;
    address[] outcomeTokens;

    uint constant MAX_UINT = 2**256 - 1;
    uint constant INITIAL_OUTCOME_TOKEN_SUPPLY = 10**5 * 10**18;

    modifier isInitializing() {
        require(marketState == MARKET_STATUS.INITIALIZING, "Market is not in INITIALIZING state.");
    }

    modifier isOpen() {
        require(marketState == MARKET_STATUS.OPEN, "Market is not in OPEN state.");
    }

    modifier isReporting() {
        require(marketState == MARKET_STATUS.REPORTING, "Market is not in REPORTING state.");
    }

    modifier isFinalized() {
        require(marketState == MARKET_STATUS.FINALIZED, "Market is not in FINALIZED state.");
    }

    constructor(
        address _oracle,
        address _collateralToken,
        address _bFactory
    ) {
        // outcomes = _outcomes;
        collateralToken = IERC20(_collateralToken);
        bFactory = BFactory(_bFactory);
        oracle = IOracle(_oracle);
    }

    function initialize(uint amountToInvest, uint outcome) public {
        collateralToken.transferFrom(msg.sender, address(this), amountToInvest);

        // Create outcome tokens.
        spamToken = new SpamToken(INITIAL_OUTCOME_TOKEN_SUPPLY);
        notSpamToken = new NotSpamToken(INITIAL_OUTCOME_TOKEN_SUPPLY);
        outcomeTokens = new uint[2](spamToken, notSpamToken);

        // Create pool.
        pool = BPool(bFactory.newPool());
        
        // Approve.
        collateralToken.approve(address(pool), MAX_UINT);
        spamToken.approve(address(pool), MAX_UINT);
        notSpamToken.approve(address(pool), MAX_UINT);
        
        // Mint initial tokens.
        spamToken.mint(address(this), amountToInvest);
        notSpamToken.mint(address(this), amountToInvest);

        // Send the user's preferred token to them.
        // if(outcome == 0) {
        //     spamToken.transferFrom(address(this), msg.sender, amountToInvest);
        // } else {
        //     notSpamToken.transferFrom(address(this), msg.sender, amountToInvest);
        // }

        // And deposit the remaining tokens in the pool.

        // Bind the pool tokens.
        // We use the denorm=5 here for future flexibility.
        pool.bind(address(collateralToken), collateralToken.balanceOf(address(this)), 10);
        pool.bind(address(spamToken),       spamToken.balanceOf(address(this)),        5);
        pool.bind(address(notSpamToken),    notSpamToken.balanceOf(address(this)),     5);

        pool.setPublicSwap(true);
        pool.finalize();
    }

    function invest(uint outcome, uint amountToInvest) public {
        collateralToken.transferFrom(msg.sender, address(this), amountToInvest);
        outcomeTokens[outcome].mint(address(this), amountToInvest);
        pool.joinPool(poolAmountOut, maxAmountsIn);
    }

    function report(uint finalOutcome) public isOpen {
        // ask oracle for outcome.
        require(msg.sender == address(oracle), "Outcome must only be reported by oracle.");
        finalOutcome = outcome;
        marketState = MARKET_STATUS.CLOSED;
    }

    function redeem(uint amount) public isClosed {
        IERC20 outcomeToken = outcomeTokens[outcome];
        require(outcomeToken.balanceOf(msg.sender) >= amount, "amount is larger than outcome token balance");
        outcomeToken.transferFrom(msg.sender, address(this), amount);
        collateralToken.transferFrom(address(this), msg.sender, amount);
    }

    function redeemFromPool() public {
        // withdraw liquidity from balancer pool using LP shares.
    }
}