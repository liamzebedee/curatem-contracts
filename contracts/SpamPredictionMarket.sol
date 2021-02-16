pragma solidity >=0.6.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./vendor/Owned.sol";
import "./interfaces/IBPool.sol";

interface IBFactory {
    function newBPool() external returns (address);
}

interface IOracle {
}


interface IOutcomeToken is IERC20 {
    function burn(address account, uint amount) external;
    function mint(address account, uint amount) external;
}

import "./vendor/Initializable.sol";

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

import "./vendor/CloneFactory.sol";




contract Factory is Initializable {
    address public outcomeToken;   

    constructor() public {}
    function initialize()
        public 
        uninitialized
    {
        outcomeToken = address(new OutcomeToken());
    }

    function newOutcomeToken(
        string calldata name, 
        string calldata ticker, 
        address _predictionMarket
    )
        external
        returns (address)
    {
        address clone = createClone(outcomeToken);
        OutcomeToken(clone).initialize(name, ticker, _predictionMarket);
        return clone;
    }


function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  } 
}



contract SpamPredictionMarket {
    uint constant MAX_UINT = 2**256 - 1;
    uint constant BALANCER_MIN_BALANCE = 10**6; // 10**18 / 10**12

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
    
    IBFactory bFactory;
    Factory factory;
    IBPool public pool;
    IERC20 public collateralToken;
    IOracle public oracle;
    IOutcomeToken[] public outcomeTokens;

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
        address _bFactory,
        address _factory
    ) 
        public
    {
        oracle = IOracle(_oracle);
        collateralToken = IERC20(_collateralToken);
        bFactory = IBFactory(_bFactory);
        factory = Factory(_factory);
    }

    function initialize() 
        public 
        isInitializing 
    {
        // Create outcome tokens.
        outcomeTokens = new OutcomeToken[](2);
        outcomeTokens[0] = OutcomeToken(factory.newOutcomeToken("Not Spam", "NOT-SPAM", address(this)));
        outcomeTokens[1] = OutcomeToken(factory.newOutcomeToken("Spam", "SPAM", address(this)));

        marketState = uint8(MARKET_STATUS.OPEN);
        emit Initialized();
    }

    function createPool(
        uint amount
    ) 
        public
        isOpen
        returns (address)
    {
        address creator = msg.sender;
        require(address(pool) == address(0), "createPool can only be called once");

        // Create pool.
        pool = IBPool(address(bFactory.newBPool()));
        
        // Approve.
        collateralToken.approve(address(pool), MAX_UINT);
        spamToken().approve(address(pool), MAX_UINT);
        notSpamToken().approve(address(pool), MAX_UINT);

        require(
            collateralToken.balanceOf(creator) >= BALANCER_MIN_BALANCE,
            "collateralToken balance must be greater than 10**6"
        );
        require(
            spamToken().balanceOf(creator) >= BALANCER_MIN_BALANCE,
            "spamToken balance must be greater than 10**6"
        );
        require(
            notSpamToken().balanceOf(creator) >= BALANCER_MIN_BALANCE,
            "notSpamToken balance must be greater than 10**6"
        );

        collateralToken.transferFrom(creator, address(this), amount);
        spamToken().transferFrom(creator, address(this), amount);
        notSpamToken().transferFrom(creator, address(this), amount);
        
        // Bind the pool tokens.
        pool.bind(address(collateralToken), collateralToken.balanceOf(address(this)), outcomeTokens.length * 10**18);
        for(uint i = 0; i < outcomeTokens.length; i++) {
            pool.bind(address(outcomeTokens[i]), outcomeTokens[i].balanceOf(address(this)), 1 * 10**18);
        }

        pool.setPublicSwap(true);
        pool.finalize();

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
}

contract Scripts {
    uint constant MAX_UINT = 2**256 - 1;
    // Approve collateral tokens for this script.
    // Then run the tx.
    // Which will transfer collateralToken to the script,
    // call buy, which mints the outcome tokens
    // and then creates the exchange
    // which mints the lp shares
    // and then send it back to the user
    function buyAndCreatePool(address _market, uint buyAmount, uint liquidityAmount) 
        external
    {
        SpamPredictionMarket market = SpamPredictionMarket(_market);
        IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
        IERC20(market.collateralToken()).approve(_market, MAX_UINT);
        market.buy(buyAmount);

        IERC20(market.spamToken()).approve(_market, MAX_UINT);
        IERC20(market.notSpamToken()).approve(_market, MAX_UINT);
        address pool = market.createPool(liquidityAmount);
        IERC20(pool).transferFrom(address(this), msg.sender, IERC20(pool).balanceOf(address(this)));
    }
}