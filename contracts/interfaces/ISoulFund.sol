// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISoulFund {
    struct Balances{
        address token;
        uint256 balance;
    }
    
    event NewWhitelistedNFT(address newNftAddress);

    function balances(uint256 _tokenId) external view returns(Balances[] memory);
    
    function addBeneficiary() external;

    function whitelistNft(address _newNftAddress) external;
}
