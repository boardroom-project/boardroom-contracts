import "owned.sol";
import "Proxy.sol";

contract OwnedProxy is owned, Proxy {
  modifier onlyowner {
    if(msg.sender == address(this) || msg.sender == owner) _
  }

  function OwnedProxy(address _owner) {
    owner = _owner;
  }

  function forward_transaction(address _destination, uint _value, bytes _calldata) onlyowner {
    if(!_destination.call.value(_value)(_calldata)) {
      throw;
    }
  }

  function transfer_ownership(address _owner) onlyowner {
    owner = _owner;
  }
}
