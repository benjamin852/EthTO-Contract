// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/ISoulFund.sol";
import "./interfaces/ITokenRenderer.sol";

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

    uint256 public constant FIVE_PERCENT = 500;

    /*** STORAGE ***/
    CountersUpgradeable.Counter private _tokenIdCounter;

    uint256 public vestingDate;

    //tokenId (soulfundId) => nftAddress => isWhitelisted
    mapping(uint256 => mapping(address => bool)) public whitelistedNfts;

    //tokenId (nftProofId) => nftAddress => isSpent
    mapping(uint256 => mapping(address => bool)) public nftIsSpent;

    //tokenId (soulfundId) => fundsRemaining
    //note: you can only have up to five different currencies
    mapping(uint256 => Balances[5]) public balances;

    //tokenId (soulfundId) => currency address => i where i -1 is the index in the balances array (1-based since 0 is null)
    //soulFund => erc20Address=> indexedTokenId
    mapping(uint256 => mapping(address => uint256)) public currencyIndices;

    //tokenId (soulfundId) => number of currencies in this fund right now
    //number of currencies in this soulfund NFT (max is five)
    mapping(uint256 => uint256) public numCurrencies;

    ITokenRenderer renderer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() payable {
        _disableInitializers();
    }

    function initialize(
        address _beneficiary,
        uint256 _vestingDate,
        address _data
    ) public payable initializer {
        __ERC721_init("SoulFund", "SLF");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(GRANTER_ROLE, msg.sender);
        _grantRole(BENEFICIARY_ROLE, _beneficiary);

        vestingDate = _vestingDate;
        renderer = ITokenRenderer(_data);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function depositFund(
        uint256 soulFundId,
        address currency,
        uint256 amount
    ) external payable override onlyRole(GRANTER_ROLE) {
        // require that currency exists or max has not been reached
        require(
            currencyIndices[soulFundId][currency] >= 0 &&
                numCurrencies[soulFundId] < 5,
            "SoulFund.depositFund: max currency type reached."
        );

        uint256 index = currencyIndices[soulFundId][currency];

        // add currency if needed
        if (index == 0) {
            // increment numCurrencies
            numCurrencies[soulFundId]++;
            // set currency indices
            currencyIndices[soulFundId][currency] = numCurrencies[soulFundId];
            // add currency
            index = currencyIndices[soulFundId][currency];
            balances[soulFundId][index].token = currency;
        }

        // add fund
        if (currency == address(0)) {
            // treat as eth
            require(
                msg.value == amount,
                "SoulFund.depositFund: amount mismatch."
            );
        } else {
            // treat as erc20
            IERC20(currency).transferFrom(msg.sender, address(this), amount);
        }
        balances[soulFundId][index].balance += amount;

        emit FundDeposited(soulFundId, currency, amount, ownerOf(soulFundId));
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

    function whitelistNft(address _newNftAddress, uint256 _tokenId)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            whitelistedNfts[_tokenId][_newNftAddress] == false,
            "SoulFund.whitelistNft: address already added"
        );
        require(
            _newNftAddress != address(0),
            "SoulFund.whitelistNft: cannot add 0 address"
        );

        whitelistedNfts[_tokenId][_newNftAddress] = true;

        emit NewWhitelistedNFT(_newNftAddress);
    }

    //Claim 5% of funds in contract with claimToken (nft)
    function claimFundsEarly(
        address _nftAddress,
        uint256 _soulFundId,
        uint256 _nftId
    ) external payable override {
        require(
            whitelistedNfts[_soulFundId][_nftAddress],
            "SoulFund.claimFundsEarly: NFT not whitelisted"
        );

        address beneficiary = ownerOf(_soulFundId);

        require(
            IERC721(_nftAddress).ownerOf(_nftId) == beneficiary,
            "SoulFund.claimFundsEarly: beneficiary does not own nft required to claim funds"
        );
        require(
            ownerOf(_soulFundId) != address(0),
            "SoulFund.claimFundsEarly: fund does not exist"
        );
        require(
            !nftIsSpent[_nftId][_nftAddress],
            "SoulFund.claimFundsEarly: Claim token NFT has already been spent"
        );

        _transferAllFunds(_soulFundId, FIVE_PERCENT);

        // TODO replace dummy aggregatedAmount with computed aggregation result
        uint256 aggregatedAmount = 1;

        //spend nft
        nftIsSpent[_nftId][_nftAddress] = true;

        payable(beneficiary).transfer(aggregatedAmount);

        emit VestedFundsClaimedEarly(
            _soulFundId,
            aggregatedAmount,
            _nftAddress,
            _nftId
        );
    }

    function claimAllVestedFunds(uint256 _soulFundId)
        external
        payable
        override
    {
        require(
            ownerOf(_soulFundId) != address(0),
            "SoulFund.claimFundsEarly: fund does not exist"
        );

        _transferAllFunds(_soulFundId, 1);

        // TODO replace dummy aggregatedAmount with computed aggregation result
        uint256 aggregatedAmount = 1;

        emit VestedFundClaimed(_soulFundId, aggregatedAmount);
    }

    function _transferAllFunds(uint256 _soulFundId, uint256 percentage)
        internal
    {
        // loop through all currencies
        for (uint256 i = 0; i < numCurrencies[_soulFundId]; i++) {
            address currency = balances[_soulFundId][i].token;
            uint256 amount = balances[_soulFundId][i].balance / percentage;
            if (currency == address(0)) {
                // eth
                payable(ownerOf(_soulFundId)).transfer(amount);
            } else {
                // erc20
                IERC20(currency).transfer(ownerOf(_soulFundId), amount);
            }
        }
    }

    function balancesExt(uint256 _tokenId)
        external
        view
        returns (Balances[5] memory)
    {
        return balances[_tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        return renderer.renderToken(address(this), tokenId);
    }
}
