pragma solidity >=0.6.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "../vendor/Owned.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IOutcomeToken.sol";
import "../interfaces/ISpamPredictionMarket.sol";
import "../tokens/OutcomeToken.sol";
import "../factories/Factory.sol";
import "./RealitioOracleResolverMixin.sol";

interface IFlashLoanReceiver {
    function onFlashLoan(uint256 amount) external;
}

contract SpamPredictionMarket is ISpamPredictionMarket, RealitioOracleResolverMixin {
    uint constant MAX_UINT = 2**256 - 1;
    uint constant UNISWAP_MINIMUM_LIQUIDITY = 1000;

    enum MARKET_STATUS {
        INITIALIZING,
        OPEN,
        FINALIZED
    }

    event Initialized();
    event PoolCreated(address pool);
    event SharesBought(address user, uint amount);
    event SharesSold(address user, uint amount);
    event Finalized();
    event SharesRedeemed(address user, uint amount);
    
    IUniswapV2Factory public uniswapFactory;
    Factory factory;
    IBPool public pool;
    IERC20 public override collateralToken;
    address public override oracle;
    IOutcomeToken[2] public outcomeTokens;

    uint8 marketState = uint8(MARKET_STATUS.INITIALIZING);
    uint256[2] payouts;
    uint256 totalPayouts;

    modifier isInitializing() {
        require(marketState == uint(MARKET_STATUS.INITIALIZING), "Market is not in INITIALIZING state.");
        _;
    }

    modifier isOpen() {
        require(marketState == uint(MARKET_STATUS.OPEN), "Market is not in OPEN state.");
        _;
    }

    modifier isFinalized() {
        require(marketState == uint(MARKET_STATUS.FINALIZED), "Market is not in FINALIZED state.");
        _;
    }

    constructor() 
        public
    {
    }

    function initialize(
        address _oracle,
        address _collateralToken,
        address _uniswapFactory,
        address _factory,
        bytes32 _questionId
    ) 
        public 
        isInitializing 
    {
        RealitioOracleResolverMixin.initialize(_questionId);

        oracle = _oracle;
        collateralToken = IERC20(_collateralToken);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        factory = Factory(_factory);
        
        // Create outcome tokens.
        outcomeTokens[0] = OutcomeToken(factory.newOutcomeToken("Not Spam", "NOT-SPAM", address(this)));
        outcomeTokens[1] = OutcomeToken(factory.newOutcomeToken("Spam", "SPAM", address(this)));

        // Create Uniswap pairs.
        uniswapFactory.createPair(address(this.collateralToken()), address(outcomeTokens[0]));
        uniswapFactory.createPair(address(this.collateralToken()), address(outcomeTokens[1]));

        marketState = uint8(MARKET_STATUS.OPEN);
        emit Initialized();
    }

    function createPool(
        uint256[3] calldata amounts
    ) 
        external
        isOpen
        returns (address)
    {
    }

    function buy(uint256 amount) 
        public 
        override
        isOpen 
    {
        require(
            collateralToken.balanceOf(msg.sender) >= amount,
            "cannot buy outcome tokens, collateral token amount >= balance"
        );
        require(
            collateralToken.allowance(msg.sender, address(this)) >= amount, 
            "cannot buy outcome tokens, collateral token amount >= allowance"
        );
        collateralToken.transferFrom(msg.sender, address(this), amount);
        for(uint i = 0; i < outcomeTokens.length; i++) {
            outcomeTokens[i].mint(msg.sender, amount);
        }
        emit SharesBought(msg.sender, amount);
    }

    function sell(uint256 amount) 
        public 
        isOpen 
    {
        for(uint i = 0; i < outcomeTokens.length; i++) {
            require(
                outcomeTokens[i].balanceOf(msg.sender) >= amount,
                "cannot sell outcome tokens, amount >= balance"
            );
            require(
                outcomeTokens[i].allowance(msg.sender, address(this)) >= amount, 
                "cannot sell outcome tokens, amount >= allowance"
            );
            outcomeTokens[i].burn(address(msg.sender), amount);
        }
        collateralToken.transfer(msg.sender, amount);
        emit SharesSold(msg.sender, amount);
    }

    // TODO: use ERC3156
    function flashloan(
        address receiver,
        uint amount
    )
        public
        isOpen 
    {
        for(uint i = 0; i < outcomeTokens.length; i++) {
            outcomeTokens[i].mint(receiver, amount);
        }

        IFlashLoanReceiver(receiver).onFlashLoan(amount);

        for(uint i = 0; i < outcomeTokens.length; i++) {
            outcomeTokens[i].burn(receiver, amount);
        }
    }
    
    function reportPayouts(
        uint256[] calldata _payouts
    ) 
        external 
        override
        isOpen 
    {
        // the oracle is responsible for implementing the market timeout.
        require(msg.sender == address(oracle), "ERR_ONLY_ORACLE");
        require(_payouts.length == outcomeTokens.length, "payouts must be specified for all outcomes");
        
        uint sum = 0;
        for(uint i = 0; i < _payouts.length; i++) {
            // TODO: in future, we will support fractional payouts.
            require(_payouts[i] <= 1, "ERR_FRACTIONAL_PAYOUT"); 
            sum += _payouts[i];
            payouts[i] = _payouts[i];
        }
        require(sum >= 1, "at least one payout must be made");
        totalPayouts = sum;

        marketState = uint8(MARKET_STATUS.FINALIZED);
        emit Finalized();
    }

    /**
     * Burns `amount` outcome token for every winning outcome, and
     * sends the caller the equivalent collateralToken.
     */
    function redeem(uint256 amount)
        public
        isFinalized
    {
        for(uint256 i = 0; i < payouts.length; i++) {
            if(payouts[i] == 1) {
                redeemOutcome(i, amount);
            }
        }
    }

    /**
     * Burns one outcome token and sends the caller the equivalent collateral amount,
     */
    function redeemOutcome(uint256 outcome, uint256 amount) 
        public
        isFinalized
    {
        require(payouts[outcome] == 1, "ERR_NO_PAYOUT");
        IERC20 outcomeToken = outcomeTokens[outcome];
        uint256 redeemable = amount * payouts[outcome] / totalPayouts;
        require(
            outcomeToken.balanceOf(msg.sender) >= amount,
            "cannot redeem outcome tokens, amount >= balance"
        );
        require(
            outcomeToken.allowance(msg.sender, address(this)) >= amount, 
            "cannot redeem outcome tokens, amount >= allowance"
        );
        outcomeToken.transferFrom(msg.sender, address(this), amount);
        collateralToken.transfer(msg.sender, redeemable);
        emit SharesRedeemed(msg.sender, redeemable);
    }

    function getPayouts()
        public 
        view
        isFinalized
        returns (uint256[2] memory)
    {
        return payouts;
    }

    function notSpamToken()
        public 
        view
        returns (IOutcomeToken)
    {
        return outcomeTokens[0];
    }

    function spamToken()
        public 
        view
        returns (IOutcomeToken)
    {
        return outcomeTokens[1];
    }

    function getOutcomeTokens()
        external
        override
        view
        returns (IOutcomeToken[2] memory)
    {
        return outcomeTokens;
    }
}