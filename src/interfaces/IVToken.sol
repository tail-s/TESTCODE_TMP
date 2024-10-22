// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
import "./IComptroller.sol";

interface IVToken {

    //
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function accrualBlockNumber() external view returns (uint);
    function reduceReserves(uint256 reduceAmount) external;
    //

    //admin function
    function _setPendingAdmin(address payable newPendingAdmin)  external returns (uint);
    
    function _acceptAdmin()  external returns (uint);
    
    function _setComptroller(IComptroller newComptroller)  external returns (uint);
    
    function _setReserveFactor(uint newReserveFactorMantissa)  external returns (uint);
    
    function _reduceReserves(uint reduceAmount)  external returns (uint);

    
    
    // function _setInterestRateModel(InterestRateModel newInterestRateModel)  external returns (uint);

    function implementation() external returns(address);

    function initialize(
        address underlying_,
        address comptroller_,
        address interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address admin_,
        address accessControlManager_,
        address riskManagement,
        uint256 reserveFactorMantissa_
    ) external;

    //
    
    function balanceOf(address owner) external view returns (uint256);

    function mint() external payable;
    
    function mint(uint256 mintAmount) external  returns (uint256);
    
    function mintBehalf(address minter) external  payable;
    
    function mintBehalf(address minter, uint256 mintAllowed) external  returns (uint256);

    function redeem(uint256 redeemTokens) external  returns (uint256);

    function redeemBehalf(address redeemer, uint256 redeemTokens) external  returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external  returns (uint256);

    function redeemUnderlyingBehalf(address redeemer, uint256 redeemAmount) external  returns (uint256);

    function borrow(uint256 borrowAmount) external  returns (uint256);

    function borrowBehalf(address borrwwer, uint256 borrowAmount) external  returns (uint256);

    function repayBorrow(uint256 repayAmount) external  returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external  returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        IVToken vTokenCollateral
    ) external  returns (uint256);

    function healBorrow(address payer, address borrower, uint256 repayAmount) external ;

    function forceLiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address vTokenCollateral,
        bool skipCloseFactorCheck
    ) external ;

    function seize(address liquidator, address borrower, uint256 seizeTokens) external ;

    function transfer(address dst, uint256 amount) external  returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external  returns (bool);

    function accrueInterest() external  returns (uint256);

    function sweepToken(address token) external;

    function borrowBalanceCurrent(address account) external  returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);
    
    function totalReserves() external  returns (uint256);

    function totalSupply() external  returns (uint256);

    function badDebt() external  returns (uint256);

    function getCash() external view returns (uint256);
}