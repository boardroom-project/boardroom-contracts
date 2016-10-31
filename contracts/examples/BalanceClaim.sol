pragma solidity ^0.4.3;

import "owned.sol";

contract BalanceClaimInterface {
  /// @notice use `claimBalance` to selfdestruct this contract and claim all balance to the owner address
  function claimBalance();
}

contract BalanceClaim is owned, BalanceClaimInterface {
  /// @notice The BalanceClaim constructor method
  /// @param _owner the address of the balance claim owner
  function BalanceClaim(address _owner) {
    // specify the balance claim owner
    owner = _owner;
  }

  function claimBalance() onlyowner {
    // self destruct and send all funds to the balance claim owner
    selfdestruct(owner);
  }
}
