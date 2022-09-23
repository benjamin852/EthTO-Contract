// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/ISoulFundFactory.sol";
import "./SoulFund.sol";

contract SoulFundFactory is ISoulFundFactory, Initializable {
    // bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // using CountersUpgradeable for CountersUpgradeable.Counter;

    // CountersUpgradeable.Counter private _fundCounter;
    uint256 private _fundCounter;

    address dataAddress;
    //fundId => fundAddress
    mapping(uint256 => address) public funds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _data) public initializer {
        // __Pausable_init();
        dataAddress = _data;
    }

    // function pause() public {
    //     _pause();
    // }

    // function unpause() public {
    //     _unpause();
    // }

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

        // _fundCounter.increment();
        _fundCounter += 1;

        // SoulFund soulFund = new SoulFund{value: msg.value}();
        SoulFund soulFund = new SoulFund{value: msg.value}(
            _beneficiary,
            _vestingDate,
            dataAddress
        );
        // soulFund.initialize(_beneficiary, _vestingDate, dataAddress);
        // funds[_fundCounter.current()] = address(soulFund);
        funds[_fundCounter] = address(soulFund);

        emit NewSoulFundTokenDeployed(
            address(this),
            _beneficiary,
            _vestingDate,
            msg.value
        );
    }
}

// 0xc5DcAC3e02f878FE995BF71b1Ef05153b71da8BE  1669014961
