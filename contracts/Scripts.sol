pragma solidity >=0.6.4;

import "./SpamPredictionMarket.sol";

contract Scripts {
    uint constant MAX_UINT = 2**256 - 1;

    // Approve collateral tokens for this script.
    // Then run the tx.
    // Which will transfer collateralToken to the script,
    // call buy, which mints the outcome tokens
    // and then creates the exchange
    // which mints the lp shares
    // and then send it back to the user
    // NOTE: we need to buy a different amount to liquidity amount, as the collateral token is needed to provide liquidity to the pool.
    function buyAndCreatePool(address _market, uint buyAmount, uint liquidityAmount) 
        external
    {
        SpamPredictionMarket market = SpamPredictionMarket(_market);
        IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
        IERC20(market.collateralToken()).approve(_market, MAX_UINT);
        market.buy(buyAmount);

        IERC20(market.spamToken()).approve(_market, MAX_UINT);
        IERC20(market.notSpamToken()).approve(_market, MAX_UINT);
        uint256[3] memory amounts;
        amounts[0] = liquidityAmount;
        amounts[1] = liquidityAmount;
        amounts[2] = liquidityAmount;
        address pool = market.createPool(amounts);
        IERC20(pool).transferFrom(address(this), msg.sender, IERC20(pool).balanceOf(address(this)));
    }

    function buyCreatePoolAndKeepOneOutcome(address _market, uint buyAmount, uint liquidityAmount, address outcomeTokenToKeep) 
        external
    {
        SpamPredictionMarket market = SpamPredictionMarket(_market);
        IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
        IERC20(market.collateralToken()).approve(_market, MAX_UINT);
        market.buy(buyAmount);

        IERC20(market.spamToken()).approve(_market, MAX_UINT);
        IERC20(market.notSpamToken()).approve(_market, MAX_UINT);

        // Create the pool.
        uint256[3] memory amounts;
        amounts[0] = liquidityAmount;
        amounts[1] = liquidityAmount;
        amounts[2] = liquidityAmount;
        // Contribute 50-50-25 liquidity, where 
        if(outcomeTokenToKeep == address(market.spamToken())) {
            amounts[1] /= 2;
            // amounts[1] = 1;
        } else {
            amounts[2] /= 2;
            // amounts[2] = 1;
        }
        address pool = market.createPool(amounts);

        // Transfer LP shares and remaining outcomeTokenToKeep balance.
        IERC20(pool).transferFrom(address(this), msg.sender, IERC20(pool).balanceOf(address(this)));
        IERC20(outcomeTokenToKeep).transfer(
            msg.sender,
            IERC20(outcomeTokenToKeep).balanceOf(address(this))
        );
    }

    function buy(address _market, uint buyAmount, address outcomeToken) 
        external
    {
        SpamPredictionMarket market = SpamPredictionMarket(_market);



        // If the outcome token is cheaper to mint, we mint it.
        // Else, we buy it from the AMM.
        
        // (uint tokenAmountOut, uint spotPriceAfter) = pool.swapExactAmountIn(
        //     market.collateralToken(),
        //     // tokenAmountIn is always buyAmount, since outcome tokens are
        //     // minted 1:1 with the collateral token.
        //     buyAmount,
        //     outcomeToken,
        //     buyAmount,
        //     uint maxPrice
        // );
        
        // Record storage inRecord = _records[address(tokenIn)];
        // Record storage outRecord = _records[address(tokenOut)];

        // require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");
        address inToken = market.collateralToken();
        address outToken = outcomeToken;

        // uint spotPriceBefore = pool.calcSpotPrice(
        //                             pool.getBalance(inToken),
        //                             pool.getDenormalizedWeight(inToken),
        //                             pool.getBalance(outToken),
        //                             pool.getDenormalizedWeight(outToken),
        //                             pool.getSwapFee()
        //                         );

        uint tokenAmountOut = calcOutGivenIn(
                                    pool.getBalance(inToken),
                                    pool.getDenormalizedWeight(inToken),
                                    pool.getBalance(outToken),
                                    pool.getDenormalizedWeight(outToken),
                                    buyAmount,
                                    pool.getSwapFee()
                                );
        
        IERC20(market.collateralToken()).transferFrom(msg.sender, address(this), buyAmount + liquidityAmount);
        IERC20(market.collateralToken()).approve(_market, MAX_UINT);
        market.buy(buyAmount);

        IERC20(market.spamToken()).approve(_market, MAX_UINT);
        IERC20(market.notSpamToken()).approve(_market, MAX_UINT);
    }

    function buyOutcome(address outcomeToken) 
        external
    {
        SpamPredictionMarket market = SpamPredictionMarket(_market);
        address pool = market.pool;
        
        if(pool == address(0)) {
            // Case A: Pool doesn't exist, we must provide liquidity.
        } else {
            
        }
    }
}