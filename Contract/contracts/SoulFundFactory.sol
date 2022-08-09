// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/ISoulFundFactory.sol";
import "./SoulFund.sol";

contract SoulFundFactory is
    ISoulFundFactory,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _fundCounter;

    //fundId => fundAddress
    mapping(uint256 => address) public funds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function deployNewSoulFund(address _beneficiary, uint256 _vestingDate)
        external
        payable
        override
    {
        require(
            _beneficiary != address(0),
            "SoulFundFactory.deployNewSoulFund: must have at least one beneficiary"
        );
        require(
            _vestingDate > block.timestamp,
            "SoulFundFactory.deployNewSoulFund: vesting must be sometime in the future"
        );
        require(
            msg.value > 0,
            "SoulFundFactory.deployNewSoulFund: no funds deposited"
        );

        _fundCounter.increment();

        SoulFund soulFund = new SoulFund{value: msg.value}();
        soulFund.initialize(_beneficiary, _vestingDate);
        funds[_fundCounter.current()] = address(soulFund);
    }
}
