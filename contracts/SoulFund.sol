// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/ISoulFund.sol";

contract SoulFund is
    ISoulFund,
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    /*** LIBRARIES ***/
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /*** CONSTANTS ***/
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant GRANTER_ROLE = keccak256("GRANTER_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");

    /*** STORAGE ***/
    CountersUpgradeable.Counter private _tokenIdCounter;

    uint256 vestingDate;

    //nftAdddress => isWhitelisted
    mapping(address => bool) public whitelistedNfts;

    //tokenId => beneficiary
    mapping(uint256 => address) public beneficiaries;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() payable {
        _disableInitializers();
    }

    function initialize(address _beneficiary, uint256 _vestingDate)
        public
        payable
        initializer
    {
        __ERC721_init("SoulFund", "SLF");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(GRANTER_ROLE, _msgSender());
        _grantRole(BENEFICIARY_ROLE, _beneficiary);

        vestingDate = _vestingDate;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(address _to) public onlyRole(GRANTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override whenNotPaused {
        require(
            _from == address(0),
            "SoulFund: soul bound token cannot be transferred"
        );
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function addBeneficiary() external override {}

    function whitelistNft(address _newNftAddress)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            whitelistedNfts[_newNftAddress] == false,
            "SoulFund.whitelistNft: address already added"
        );
        require(
            _newNftAddress != address(0),
            "SoulFund.whitelistNft: cannot add 0 address"
        );

        whitelistedNfts[_newNftAddress] = true;

        emit NewWhitelistedNFT(_newNftAddress);
    }

    function claimVestedFunds(uint256 _tokenId) external payable {
        require(
            block.timestamp > vestingDate,
            "SoulFund.claimVestedFunds: vesting period has not started"
        );

        require(
            beneficiaries[_tokenId] != address(0),
            "SoulFund.claimVestedFunds: new beneficiary corresponds to this token id"
        );

        address beneficiary = beneficiaries[_tokenId];

        payable(beneficiary).transfer(msg.value);

        emit VestedFundClaimed(_tokenId, msg.value);
    }
}
