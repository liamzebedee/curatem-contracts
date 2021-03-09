pragma solidity >=0.6.6;

import "./interfaces/ISpamPredictionMarket.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

import "hardhat/console.sol";

contract Scripts {
    uint256 constant MAX_UINT = 2**256 - 1;
    uint256 constant UNISWAP_MINIMUM_LIQUIDITY = 1000;

    // Approve collateral tokens for this script.
    // Then run the tx.
    // Which will transfer collateralToken to the script,
    // call buy, which mints the outcome tokens
    // and then creates the exchange
    // which mints the lp shares
    // and then send it back to the user
    // NOTE: we need to buy a different amount to liquidity amount, as the collateral token is needed to provide liquidity to the pool.
    // function buyAndCreatePool(address _market, uint buyAmount, uint liquidityAmount) 
    //     external
    // {
    //     SpamPredictionMarket market = SpamPredictionMarket(_market);
    //     IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
    //     IERC20(market.collateralToken()).approve(_market, MAX_UINT);
    //     market.buy(buyAmount);

    //     IERC20(market.spamToken()).approve(_market, MAX_UINT);
    //     IERC20(market.notSpamToken()).approve(_market, MAX_UINT);
    //     uint256[3] memory amounts;
    //     amounts[0] = liquidityAmount;
    //     amounts[1] = liquidityAmount;
    //     amounts[2] = liquidityAmount;
    //     address pool = market.createPool(amounts);
    //     IERC20(pool).transferFrom(address(this), msg.sender, IERC20(pool).balanceOf(address(this)));
    // }

    function buyCreatePoolAndKeepOneOutcome(address _market, uint buyAmount, uint liquidityAmount, address outcomeTokenToKeep) 
        external
    {
        // SpamPredictionMarket market = SpamPredictionMarket(_market);
        // IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
        // IERC20(market.collateralToken()).approve(_market, MAX_UINT);
        // market.buy(buyAmount);

        // IERC20(market.spamToken()).approve(_market, MAX_UINT);
        // IERC20(market.notSpamToken()).approve(_market, MAX_UINT);

        // // Create the pool.
        // uint256[3] memory amounts;
        // amounts[0] = liquidityAmount;
        // amounts[1] = liquidityAmount;
        // amounts[2] = liquidityAmount;
        // // Contribute 50-50-25 liquidity, where 
        // if(outcomeTokenToKeep == address(market.spamToken())) {
        //     amounts[1] /= 2;
        //     // amounts[1] = 1;
        // } else {
        //     amounts[2] /= 2;
        //     // amounts[2] = 1;
        // }
        // address pool = market.createPool(amounts);

        // // Transfer LP shares and remaining outcomeTokenToKeep balance.
        // IERC20(pool).transferFrom(address(this), msg.sender, IERC20(pool).balanceOf(address(this)));
        // IERC20(outcomeTokenToKeep).transfer(
        //     msg.sender,
        //     IERC20(outcomeTokenToKeep).balanceOf(address(this))
        // );
    }

    function buy(address _market, uint buyAmount, address outcomeToken) 
        external
    {
        // SpamPredictionMarket market = SpamPredictionMarket(_market);



        // // If the outcome token is cheaper to mint, we mint it.
        // // Else, we buy it from the AMM.
        
        // // (uint tokenAmountOut, uint spotPriceAfter) = pool.swapExactAmountIn(
        // //     market.collateralToken(),
        // //     // tokenAmountIn is always buyAmount, since outcome tokens are
        // //     // minted 1:1 with the collateral token.
        // //     buyAmount,
        // //     outcomeToken,
        // //     buyAmount,
        // //     uint maxPrice
        // // );
        
        // // Record storage inRecord = _records[address(tokenIn)];
        // // Record storage outRecord = _records[address(tokenOut)];

        // // require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");
        // address inToken = market.collateralToken();
        // address outToken = outcomeToken;

        // // uint spotPriceBefore = pool.calcSpotPrice(
        // //                             pool.getBalance(inToken),
        // //                             pool.getDenormalizedWeight(inToken),
        // //                             pool.getBalance(outToken),
        // //                             pool.getDenormalizedWeight(outToken),
        // //                             pool.getSwapFee()
        // //                         );

        // uint tokenAmountOut = calcOutGivenIn(
        //                             pool.getBalance(inToken),
        //                             pool.getDenormalizedWeight(inToken),
        //                             pool.getBalance(outToken),
        //                             pool.getDenormalizedWeight(outToken),
        //                             buyAmount,
        //                             pool.getSwapFee()
        //                         );
        
        // IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
        // IERC20(market.collateralToken()).approve(_market, MAX_UINT);
        // market.buy(buyAmount);

        // IERC20(market.spamToken()).approve(_market, MAX_UINT);
        // IERC20(market.notSpamToken()).approve(_market, MAX_UINT);
    }

    struct buyOutcomeElseProvideLiquidity_vars {
        uint256 collateralTokenInAmount;
        uint256 buyAmount;
        IOutcomeToken x_token;
        IOutcomeToken notX_token;
        IERC20 collateralToken;
        uint256 ammTokenInAmount;
        uint256 xAmount;
        uint256 notXAmount;
    }

    function buyOutcomeElseProvideLiquidity(
        address _market, 
        uint8 outcome,
        uint256 buyAmount,
        uint256 outcomeOddsNumerator,
        uint256 outcomeOddsDenominator,
        // Uniswap params.
        address _uniswapRouterV2,
        uint256 amountAMin,
        uint256 amountBMin
    ) external {
        require(buyAmount > UNISWAP_MINIMUM_LIQUIDITY, "ERR_UNISWAP_MINIMUM_LIQUIDITY");

        // Parameters.
        buyOutcomeElseProvideLiquidity_vars memory vars;
        vars.collateralTokenInAmount = buyAmount;
        vars.buyAmount = buyAmount / 2;

        ISpamPredictionMarket market = ISpamPredictionMarket(_market);
        IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), vars.collateralTokenInAmount);
        
        
        // Check market liquidity.
        IOutcomeToken[2] memory outcomeTokens = market.getOutcomeTokens();
        require(outcomeTokens.length == 2, "unexpected outcome tokens array length");
        vars.x_token = outcomeTokens[outcome];
        vars.notX_token = outcomeTokens[(outcome + 1) % 2];
        vars.collateralToken = market.collateralToken();
        
        // Market is determined to be liquid, if we can buy `outcomeToken` at a cheaper
        // price than minting it.
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(_uniswapRouterV2);
        
        // 1. Get the price from uniswap for swapping in 1 collateraltoken
        {
            // SANITY CHECK Uniswap reserves.
            (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(
                uniswapRouter.factory(), 
                address(vars.collateralToken),
                address(vars.x_token)
            );
            console.log("reserves %s %s", reserveA, reserveB);

            // TODO: could probably move this into an internal function flow.
            if(reserveA == 0 
                || reserveB == 0
                || vars.buyAmount >= reserveB) {
                vars.ammTokenInAmount = MAX_UINT;
            } else {
                vars.ammTokenInAmount = uniswapRouter.getAmountIn(vars.buyAmount, reserveA, reserveB);
            }
        }

        // 2. If AMM price was cheaper than minting outcome tokens, then buy from AMM.
        // NOTE: exchange rate is 1:1 from minting outcome shares, so
        // we reuse collateralTokenInAmount here.
        if(vars.ammTokenInAmount < vars.collateralTokenInAmount) {
            vars.collateralToken.approve(address(uniswapRouter), MAX_UINT);
            // market is liquid, buy tokens.
            address[] memory path = new address[](2);
            path[0] = address(vars.collateralToken);
            path[1] = address(vars.x_token);
            uniswapRouter.swapExactTokensForTokens(
                vars.ammTokenInAmount,
                vars.buyAmount,
                path,
                msg.sender,
                block.timestamp
            );
            return;

        } else {

            // Else, provide liquidity in the form of SubredditToken to AMM with probability skewed to “Spam”.
            // Collateral is split across two transactions:
            // (1) odds % is sent to mint outcome shares.
            // (2) (1 - odds) % is deposited as liquidity in the Uniswap pool. 
            // 
            // collateralTokenInAmount = 1.0 eth
            // outcomeOddsNumerator = 4
            // outcomeOddsDenominator = 5
            // to 1.0 * (4/5) = 0.8
            
            // Deposit 50% REP to mint outcome shares.
            // Use 50% of REP to provide liquidity.
            // 50% * betAmount REP
            // -> 50% * 10% = 0.05 REP + notX shares
            // -> 50% * 90% = 0.45 REP +    X shares
            uint liquidityAmount = (vars.collateralTokenInAmount / 2);
            vars.xAmount = liquidityAmount * outcomeOddsNumerator / outcomeOddsDenominator;
            vars.notXAmount = liquidityAmount - vars.xAmount;

            vars.collateralToken.approve(address(market), liquidityAmount);
            market.buy(liquidityAmount);
            
            // Sell the notX_token to the Uniswap pool.
            vars.collateralToken.approve(address(uniswapRouter), liquidityAmount);
            vars.x_token.approve(address(uniswapRouter), liquidityAmount);
            vars.notX_token.approve(address(uniswapRouter), liquidityAmount);

            uniswapRouter.addLiquidity(
                address(vars.collateralToken),
                address(vars.notX_token),
                vars.notXAmount,
                liquidityAmount,
                amountAMin,
                amountBMin,
                msg.sender,
                block.timestamp + 1
            );

            uniswapRouter.addLiquidity(
                address(vars.collateralToken),
                address(vars.x_token),
                vars.xAmount,
                liquidityAmount,
                amountAMin,
                amountBMin,
                msg.sender,
                block.timestamp + 1
            );

            return;
        }
    }


}