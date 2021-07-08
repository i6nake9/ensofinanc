//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;

import "../ecosystem/openzeppelin/token/ERC20/ERC20.sol";

contract MockStrategy is ERC20 {

    constructor(string memory name_, string memory decimals_) ERC20(name_, decimals_){}

    function mint(address account, uint256 value) 
        public
    {
        _mint(account, value);
    }
}