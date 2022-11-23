// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.9;

interface IContractRegistry {
    struct Pair {
        string key;
        address addr;
    }

    function upgradeContract(address _proxy, address _newImplementation) external;

    function getImplementation(address _proxy) external returns (address);

    function setAddress(string calldata _key, address _addr) external;

    function setMaintainer(address _maintainer) external;

    function leaveMaintainers() external;

    function removeKey(string calldata _key) external;

    function removeKeys(string[] memory _keys) external;

    function setAddresses(string[] memory _keys, address[] memory _addresses) external;

    function getAddress(string calldata _key) external view returns (address);

    function mustGetAddress(string calldata _key) external view returns (address);

    function getContracts() external view returns (Pair[] memory);

    function getMaintainers() external view returns (address[] memory);

    function contains(string memory _key) external view returns (bool);
}
