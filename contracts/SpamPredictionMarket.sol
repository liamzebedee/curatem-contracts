pragma solidity >=0.6.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "./vendor/Owned.sol";
import "./interfaces/IBPool.sol";
import "./interfaces/IOutcomeToken.sol";
import "./tokens/OutcomeToken.sol";
import "./factories/Factory.sol";

interface IBFactory {
    function newBPool() external returns (address);
}

interface IOracle {
}

interface IFlashLoanReceiver {
    function onFlashLoan(uint256 amount) external;
}



contract SpamPredictionMarket {
    uint constant MAX_UINT = 2**256 - 1;
    uint constant BALANCER_MIN_BALANCE = 10**6; // 10**18 / 10**12
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
    event Finalized(uint finalOutcome);
    event SharesRedeemed(address user, uint amount);
    
    IUniswapV2Factory public uniswapFactory;
    Factory factory;
    IBPool public pool;
    IERC20 public collateralToken;
    IOracle public oracle;
    IOutcomeToken[2] public outcomeTokens;

    uint8 marketState = uint8(MARKET_STATUS.INITIALIZING);
    uint8 finalOutcome = 0;

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

    constructor(
        address _oracle,
        address _collateralToken,
        address _uniswapFactory,
        address _factory
    ) 
        public
    {
        oracle = IOracle(_oracle);
        collateralToken = IERC20(_collateralToken);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        factory = Factory(_factory);
    }

    function initialize() 
        public 
        isInitializing 
    {
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
        address creator = msg.sender;
        require(address(pool) == address(0), "createPool can only be called once");

        // Create pool.
        // pool = IBPool(address(bFactory.newBPool()));
        
        // Approve.
        collateralToken.approve(address(pool), MAX_UINT);
        spamToken().approve(address(pool), MAX_UINT);
        notSpamToken().approve(address(pool), MAX_UINT);

        // require(
        //     collateralToken.balanceOf(creator) >= BALANCER_MIN_BALANCE,
        //     "collateralToken balance must be greater than 10**6"
        // );
        // require(
        //     spamToken().balanceOf(creator) >= BALANCER_MIN_BALANCE,
        //     "spamToken balance must be greater than 10**6"
        // );
        // require(
        //     notSpamToken().balanceOf(creator) >= BALANCER_MIN_BALANCE,
        //     "notSpamToken balance must be greater than 10**6"
        // );

        collateralToken.transferFrom(creator, address(this), amounts[0]); 
        spamToken().transferFrom(creator, address(this), amounts[1]);
        notSpamToken().transferFrom(creator, address(this), amounts[2]);
        
        // Bind the pool tokens.
        // pool.bind(address(collateralToken), collateralToken.balanceOf(address(this)), outcomeTokens.length * 10**18);
        // for(uint i = 0; i < outcomeTokens.length; i++) {
        //     pool.bind(address(outcomeTokens[i]), outcomeTokens[i].balanceOf(address(this)), 1 * 10**18);
        // }

        // pool.setPublicSwap(true);
        // pool.finalize();

        // Transfer LP share to creator.
        pool.transferFrom(address(this), msg.sender, pool.balanceOf(address(this)));

        emit PoolCreated(address(pool));
        return address(pool);
    }

    function buy(uint amount) 
        public 
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

    function sell(uint amount) 
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
        collateralToken.transferFrom(address(this), msg.sender, amount);
        emit SharesSold(msg.sender, amount);
    }

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

    // function report(uint8 _finalOutcome) 
    //     public 
    //     isOpen 
    // {
    //     // ask oracle for outcome.
    //     // the oracle is responsible for implementing the market timeout.
    //     require(msg.sender == address(oracle), "only oracle can report outcome");
    //     require(_finalOutcome < outcomeTokens.length, "outcome must be within range");
    //     finalOutcome = _finalOutcome;
    //     marketState = uint8(MARKET_STATUS.FINALIZED);
    // }

    // TODO: this is to be compatible with the Gnosis Realiio proxy.
    // This should be moved into an external contract.
    function reportPayouts(
        bytes32 questionId,
        uint8[] calldata payouts
    ) 
        external 
        isOpen 
    {
        // the oracle is responsible for implementing the market timeout.
        require(msg.sender == address(oracle), "only oracle can report outcome");
        require(payouts.length == outcomeTokens.length, "payouts must be specified for all outcomes");
        uint sum = 0;
        uint firstPayoutIdx;
        for(uint i = 0; i < payouts.length; i++) {
            sum += payouts[i];
            if(i == 1) {
                firstPayoutIdx = i;
            }
        }
        require(sum == 1, "payouts must resolve to one and only one final outcome");
        finalOutcome = uint8(firstPayoutIdx);
        marketState = uint8(MARKET_STATUS.FINALIZED);
        emit Finalized(finalOutcome);
    }

    function redeem(uint amount) 
        public 
        isFinalized 
    {
        IERC20 outcomeToken = outcomeTokens[finalOutcome];
        require(
            outcomeTokens[finalOutcome].balanceOf(msg.sender) >= amount,
            "cannot redeem outcome tokens, amount >= balance"
        );
        require(
            outcomeTokens[finalOutcome].allowance(msg.sender, address(this)) >= amount, 
            "cannot redeem outcome tokens, amount >= allowance"
        );
        outcomeToken.transferFrom(msg.sender, address(this), amount);
        collateralToken.transferFrom(address(this), msg.sender, amount);
        emit SharesRedeemed(msg.sender, amount);
    }

    function getOutcome()
        public
        isFinalized
        returns (uint8)
    {
        return finalOutcome;
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
        view
        returns (IOutcomeToken[2] memory)
    {
        return outcomeTokens;
    }
}