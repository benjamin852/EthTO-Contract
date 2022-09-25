// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISoulFundFactory {
    event NewSoulFundTokenDeployed(
        address indexed tokenAddress,
        address indexed beneficiary,
        uint256 vestingDate,
        uint256 depositedAmount
    );

    function deployNewSoulFund(
        address _beneficiary,
        uint256 _vestingDate,
        address _data,
        address _acceptedMeritTokens
    ) external payable;
}
