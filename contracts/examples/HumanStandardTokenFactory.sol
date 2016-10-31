pragma solidity ^0.4.3;

import "examples/HumanStandardToken.sol";

contract HumanStandardTokenFactory {

    mapping(address => address[]) public created;
    bytes public humanStandardByteCode;

    function HumanStandardTokenFactory() public {
    }

    function createdByMe() returns (address[]) {
        return created[msg.sender];
    }

    function createHumanStandardToken(uint256 _initialAmount, string _name, uint8 _decimals, string _symbol) returns (address) {

        HumanStandardToken newToken = (new HumanStandardToken(_initialAmount, _name, _decimals, _symbol));
        newToken.transfer(msg.sender, _initialAmount); //the factory will own the created tokens. You must transfer them.
        created[msg.sender].push(address(newToken));
        return address(newToken);
    }
}
