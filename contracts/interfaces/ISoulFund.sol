// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISoulFund {
    event NewWhitelistedNFT(address newNftAddress);
    event VestedFundClaimedEarly(uint256 tokenId, uint256 vestedAmount);

    function addBeneficiary() external;

    function whitelistNft(address _newNftAddress, uint256 _tokenId) external;

    function claimFundsEarly(
        address _nftAddress,
        uint256 _soulFundId,
        uint256 _nftId
    ) external payable;
}
