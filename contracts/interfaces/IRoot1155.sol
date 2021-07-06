// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "../ecosystem/openzeppelin/token/ERC1155/IERC1155.sol";

interface IRoot1155 is IERC1155 {
    function getMaxTokenID() external returns(uint256);
}