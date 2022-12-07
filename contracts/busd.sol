// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BusdToken is ERC20, Ownable {
    constructor() ERC20("BUSD", "BUSD") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }
}