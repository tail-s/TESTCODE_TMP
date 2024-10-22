// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

/**
 * @title ComptrollerInterface
 * @author Venus
 * @notice Interface implemented by the `Comptroller` contract.
 */

 enum Action {
    MINT,
    REDEEM,
    BORROW,
    REPAY,
    SEIZE,
    LIQUIDATE,
    TRANSFER,
    ENTER_MARKET,
    EXIT_MARKET
}

 interface IComptroller {

    struct LiquidationOrder {
        address vTokenBorrowed;
        address vTokenCollateral;
        uint repayAmount;
    }

    function oracle() external view returns (address);

    // Iso
    function setActionsPaused(address[] calldata marketsList, Action[] calldata actionsList, bool paused) external;

    function unlistMarket(address market) external returns (uint256);

    function isMarketListed(address vToken) external view returns (bool);

    function actionPaused(address market, Action action) external view returns (bool);

    function setPriceOracle(address newOracle) external;

    function setCloseFactor(uint256 newCloseFactorMantissa) external;

    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    /*** Policy Hooks ***/

    function checkMembership(address account, address vToken) external view returns (bool);

    function borrowCaps(address vToken) external view returns (uint);
    function supplyCaps(address vToken) external view returns (uint);

    function preMintHook(address vToken, address minter, uint256 mintAmount) external;

    function preRedeemHook(address vToken, address redeemer, uint256 redeemTokens) external;

    function preBorrowHook(address vToken, address borrower, uint256 borrowAmount) external;

    function preRepayHook(address vToken, address borrower) external;

    function preLiquidateHook(
        address vTokenBorrowed,
        address vTokenCollateral,
        address borrower,
        uint256 repayAmount,
        bool skipLiquidityCheck
    ) external;

    function preSeizeHook(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower
    ) external;

    function borrowVerify(address vToken, address borrower, uint borrowAmount) external;

    function mintVerify(address vToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemVerify(address vToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function repayBorrowVerify(
        address vToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external;

    function liquidateBorrowVerify(
        address vTokenBorrowed,
        address vTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external;

    function seizeVerify(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external;

    function transferVerify(address vToken, address src, address dst, uint transferTokens) external;

    function preTransferHook(address vToken, address src, address dst, uint256 transferTokens) external;

    function isComptroller() external view returns (bool);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateAccount(address borrower, LiquidationOrder[] calldata orders) external;

    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);


    function markets(address) external view returns (bool, uint256);

    function getAssetsIn(address) external view returns (address[] memory);

    function closeFactorMantissa() external view returns (uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function minLiquidatableCollateral() external view returns (uint256);
    
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    function updateDelegate(address delegate, bool approved) external;

    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256, uint256, uint256);

}
