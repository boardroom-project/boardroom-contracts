pragma solidity ^0.4.3;

import "owned.sol";
import "Proxy.sol";

contract OwnedProxy is owned, Proxy {
  modifier onlyowner {
    if (msg.sender == address(this) || msg.sender == owner) {
      _;
    }
  }

  /// @notice The contract fallback function
  function () payable public {}

  function OwnedProxy(address _owner) {
    owner = _owner;
  }

  function forward_transaction(address _destination, uint _value, bytes _calldata) public onlyowner {
    if (!_destination.call.value(_value)(_calldata)) {
      throw;
    }
  }

  function transfer_ownership(address _owner) public onlyowner {
    owner = _owner;
  }
}
