pragma solidity ^0.4.3;

contract owned {
  function owned() {
    owner = msg.sender;
  }

  modifier onlyowner() {
    if (msg.sender == owner) {
      _;
    }
  }

  address public owner;
}
