// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

interface IRiskFund {

    function initialize(
        address pancakeSwapRouter_,
        uint256 minAmountToConvert_,
        address convertibleBaseAsset_,
        address accessControlManager_,
        uint256 loopsLimit_
    ) external;

    function setPoolRegistry(address poolRegistry_) external;

    function setShortfallContractAddress(address shortfallContractAddress_) external;

    function setPancakeSwapRouter(address pancakeSwapRouter_) external;

    function setMinAmountToConvert(uint256 minAmountToConvert_) external;

    function setConvertibleBaseAsset(address _convertibleBaseAsset) external;

    function swapPoolsAssets(
        address[] calldata markets,
        uint256[] calldata amountsOutMin,
        address[][] calldata paths,
        uint256 deadline
    ) external returns (uint256);

    function transferReserveForAuction(
        address comptroller,
        uint256 amount
    ) external returns (uint256);

    function setMaxLoopsLimit(uint256 limit) external;

    function getPoolsBaseAssetReserves(address comptroller) external view returns (uint256);

    function updateAssetsState(address comptroller, address asset) external;
}
