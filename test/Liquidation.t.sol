// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";

contract CollateralSupply is Test, Tester {

    address liquidator = address(0x1234);
    address liquidator2 = address(0x2345);
    uint amount = 1000 * 1e18;
    uint borrowAmount = 100 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), liquidator, amount);
        deal(address(USDD), liquidator2, borrowAmount * 10);

        vm.startPrank(liquidator);
        USDT.approve(address(vUSDT), amount);
        vm.stopPrank();

        vm.startPrank(liquidator2);
        USDD.approve(address(vUSDD), borrowAmount * 10);
        vm.stopPrank();

        // liquidator's Borrowing
        vm.startPrank(liquidator);
        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(liquidator);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(liquidator), borrowAmount);
        vm.stopPrank();
    }

    function test_liquidate_checkMarket() public {

        vm.startPrank(liquidator2);
        uint factor = gComptroller.closeFactorMantissa();
        uint borrowed = vUSDD.borrowBalanceCurrent(liquidator);
        uint liquidateAmount = (borrowed * factor) / 1e18;

        vm.expectRevert();  // EvmError: Revert
        vUSDD.liquidateBorrow(liquidator, liquidateAmount, NOT_REGISTERED_VTOKEN);
        // set_oracle();
        // vUSDD.liquidateBorrow(liquidator, liquidateAmount, vUSDT);
        vm.stopPrank();
    }

    function test_liquidate_checkLTV() public {
        vm.startPrank(liquidator2);
        uint factor = gComptroller.closeFactorMantissa();
        uint borrowed = vUSDD.borrowBalanceCurrent(liquidator);
        uint liquidateAmount = (borrowed * factor) / 1e18;

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientShortfall()"))));
        vUSDD.liquidateBorrow(liquidator, liquidateAmount, vUSDT);
        vm.stopPrank();

    }

    // function set_oracle() public {
    //     uint newPrice = oracle.getUnderlyingPrice(address(vUSDT)) / 9;
    //     vm.mockCall(
    //         address(oracle),
    //         abi.encodeWithSelector(oracle.getUnderlyingPrice.selector, address(vUSDT)),
    //         abi.encode(newPrice) 
    //     );
    // }
    
}
