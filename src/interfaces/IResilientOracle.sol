// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

// interface IResilientOracle is OracleInterface {
interface IResilientOracle {
    function updatePrice(address vToken) external;
    function updateAssetPrice(address asset) external;
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface OracleInterface {
    function getPrice(address asset) external view returns (uint256);
}

// interface BoundValidatorInterface {
//     function validatePriceWithAnchorPrice(
//         address asset,
//         uint256 reporterPrice,
//         uint256 anchorPrice
//     ) external view returns (bool);
// }