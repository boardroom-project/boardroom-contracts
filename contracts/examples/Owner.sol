pragma solidity ^0.4.3;

contract Owner {
  modifier onlyowner() {
    // only allow a message sender than is the owner
    if (msg.sender == owner) {
      _;
    }
  }

  /// @notice The contract fallback function
  function () payable public {}

  address public owner;
}
