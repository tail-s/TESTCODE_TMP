// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tester} from "../src/utils/Tester.sol";
import {Action} from "../src/interfaces/IComptroller.sol";

contract CollateralSupply is Test, Tester {
    address user = address(0x1234);

    function setUp() public {
        cheat.createSelectFork("bsc_mainnet", BLOCK_NUMBER);
    }

    function test_setPriceOracle() public {
        vm.startPrank(admin);
        comptroller.setPriceOracle(address(0x1));
        assertEq(comptroller.oracle(), address(0x1));
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        comptroller.setPriceOracle(address(0x2));
    }

    function test_admin_checkAccrueBlock() public {
        vm.startPrank(admin);
        vUSDT.reduceReserves(1e18);
        assertEq(vUSDT.accrualBlockNumber(), block.number);
    }

    function test_admin_checkReserveAmount() public {
        vm.startPrank(admin);
        uint reserves = vUSDT.totalReserves();
        
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ReduceReservesCashValidation()"))));
        vUSDT.reduceReserves(reserves + 3.156944 * 1e18);
        reserves = vUSDT.totalReserves();
        vUSDT.reduceReserves(reserves + 3.156943 * 1e18);
    }

    function test_setCloseFactor() public {
        // MIN_CLOSE_FACTOR_MANTISSA = 0.05e18; // 0.05
        // MAX_CLOSE_FACTOR_MANTISSA = 0.9e18; // 0.9

        vm.startPrank(admin);
        comptroller.setCloseFactor(0.5e18);
        assertEq(comptroller.closeFactorMantissa(), 0.5e18);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized(address,address,string)")), address(user), address(comptroller), "setCloseFactor(uint256)"));
        comptroller.setCloseFactor(0.55e18);
        vm.stopPrank();

    }

    function test_setLiquidationIncentive() public {
        vm.startPrank(admin);
        comptroller.setLiquidationIncentive(1e18);
        assertEq(comptroller.liquidationIncentiveMantissa(), 1e18);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized(address,address,string)")), address(user), address(comptroller), "setLiquidationIncentive(uint256)"));
        comptroller.setLiquidationIncentive(1.1e18);
        vm.stopPrank();

    }

    function test_setPause() public {
        vm.startPrank(user);

        address[] memory marketsList = new address[](1);
        marketsList[0] = address(vETH);

        Action[] memory actionsList = new Action[](5);
        actionsList[0] = Action.MINT;
        actionsList[1] = Action.REDEEM;
        actionsList[2] = Action.BORROW;
        actionsList[3] = Action.REPAY;
        actionsList[4] = Action.LIQUIDATE;

        // vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized(address,address,string)")), address(user), address(comptroller), "setActionsPaused(address,address,bool)"));
        // vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized(address,address,string)")), address(user), address(comptroller), "setActionsPaused(address)(address)(bool)"));
        // vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized(address,address,string)")), address(user), address(comptroller), "setActionsPaused(address[],address[],bool)"));
        // vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Unauthorized(address,address,string)")), address(user), address(comptroller), "setActionsPaused(address[])(address[])(bool)"));
        // vm.expectRevert();
        comptroller.setActionsPaused(marketsList, actionsList, true);
        vm.stopPrank();

        Pause(address(comptroller), address(vETH));
        bool success = isPaused(address(comptroller), address(vETH), Action.MINT);
        assertEq(success, true);
    }
    
}
