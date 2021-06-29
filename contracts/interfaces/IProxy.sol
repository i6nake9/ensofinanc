//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

interface IProxy {
    function getImplementation() external view returns (address);
}