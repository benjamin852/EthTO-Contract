// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISoulFund {

    // reserve zero address for Eth
    struct Balances {
        address token;
        uint256 balance;
    }

    event NewWhitelistedNFT(address newNftAddress);
    event VestedFundsClaimedEarly(
        uint256 tokenId,
        uint256 rewardAmount,
        address nftAddress,
        uint256 nftTokenId
    );
    event VestedFundClaimed(uint256 soulFundId, uint256 vestedAmount);

    function depositFund(uint256 soulFundId, address currency, uint256 amount) external payable;

    function balances(uint256 _tokenId)
        external
        view
        returns (Balances[] memory);

    function whitelistNft(address _newNftAddress, uint256 _tokenId) external;

    function claimFundsEarly(
        address _nftAddress,
        uint256 _soulFundId,
        uint256 _nftId
    ) external payable;

    function claimAllVestedFunds(uint256 _soulFundId) external payable;
}
