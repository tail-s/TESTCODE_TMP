// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";

contract CollateralSupply is Test, Tester {

    address repayer = address(0x1234);
    address repayer2 = address(0x2345);
    uint amount = 10000 * 1e18;
    uint borrowAmount = 10 * 1e18;

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
        deal(address(USDT), repayer, amount);
        deal(address(USDD), repayer2, borrowAmount);

        vm.startPrank(repayer);
        USDT.approve(address(vUSDT), amount);
        USDD.approve(address(vUSDD), borrowAmount);

        vUSDT.mint(amount);

        address[] memory vTokens = new address[](1);
        vTokens[0] = address(vUSDT);
        gComptroller.enterMarkets(vTokens);        

        address[] memory assetsIn = gComptroller.getAssetsIn(repayer);
        assertEq(assetsIn[0], address(vUSDT));

        vUSDD.borrow(borrowAmount);
        assertEq(USDD.balanceOf(repayer), borrowAmount);

        vm.stopPrank();

        vm.startPrank(repayer2);
        USDT.approve(address(vUSDT), amount);
        USDT.approve(address(vUSDD), borrowAmount);
        vm.stopPrank();
    }

    function test_repay_checkMarket() public {
        vm.startPrank(admin);
        assertEq(gComptroller.isMarketListed(address(NOT_REGISTERED_VTOKEN)), false);
        assertEq(gComptroller.isMarketListed(address(vUSDT)), true);
        vm.stopPrank();
    }

    function test_repay_checkAccrueBlock() public {
        vm.startPrank(repayer);

        vUSDD.repayBorrow(borrowAmount);
        assertEq(USDD.balanceOf(repayer), 0);
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function test_repay_checkOut() public {
        vm.startPrank(repayer);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientLiquidity()"))));
        gComptroller.exitMarket(address(vUSDT));

        vUSDD.repayBorrow(borrowAmount);
        gComptroller.exitMarket(address(vUSDT));
        vm.stopPrank();
    }

    function test_repay_checkOutBehalf() public {
        vm.startPrank(repayer);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("InsufficientLiquidity()"))));
        gComptroller.exitMarket(address(vUSDT));

        vm.stopPrank();

        vm.startPrank(repayer2);

        USDD.approve(address(vUSDD), amount);
        vUSDD.repayBorrowBehalf(repayer, borrowAmount);
        vm.stopPrank();

        vm.startPrank(repayer);
        gComptroller.exitMarket(address(vUSDT));
        
        vm.stopPrank();
    }

    function test_repay_checkAmount() public {
        vm.startPrank(repayer);

        // Core Pool과 달리 Isolated Pool에서 상환금액이 차입금액보다 클 경우, 차입금액만 송금되어 Revert가 발생하지 않음.
        vUSDD.repayBorrow(borrowAmount * 99999);
        vUSDD.repayBorrow(borrowAmount);

        vm.stopPrank();
    }

    function test_repay_simple() public {
        vm.startPrank(repayer);

        vUSDD.repayBorrow(borrowAmount);
        assertEq(USDD.balanceOf(repayer), 0);

        vm.stopPrank();
    }

    function test_repay_simpleBehalf() public {
        vm.startPrank(repayer2);

        USDD.approve(address(vUSDD), amount);
        vUSDD.repayBorrowBehalf(repayer, borrowAmount);
        assertEq(USDD.balanceOf(repayer2), 0);
        
        vm.stopPrank();
    }

    function test_repay_checkPause() public {
        Pause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REPAY), true);
        unPause(address(gComptroller), address(vUSDT));
        assertEq(isPaused(address(gComptroller), address(vUSDT), Action.REPAY), false);
    }
}
