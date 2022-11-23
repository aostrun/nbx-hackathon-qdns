// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;

import "./Locals.sol";
import "@q-dev/contracts/governance/AParameters.sol";
import "@q-dev/contracts/common/Globals.sol";

contract QDNSParameters is AParameters {
  constructor() {}

  function initialize(
    address _registry,
    string[] memory _uintKeys,
    uint256[] memory _uintVals,
    string[] memory _addrKeys,
    address[] memory _addrVals,
    string[] memory _strKeys,
    string[] memory _strVals,
    string[] memory _boolKeys,
    bool[] memory _boolVals
  ) public virtual override {
    AParameters.initialize(
      _registry,
      _uintKeys,
      _uintVals,
      _addrKeys,
      _addrVals,
      _strKeys,
      _strVals,
      _boolKeys,
      _boolVals
    );

    ownerKey = REGISTRY_KEY_QDNS_OWNER;
  }
}