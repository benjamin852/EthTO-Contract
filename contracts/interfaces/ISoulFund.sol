// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISoulFund {
    event NewWhitelistedNFT(address newNftAddress);

    function addBeneficiary() external;

    function whitelistNft(address _newNftAddress) external;
}
