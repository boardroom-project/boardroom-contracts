pragma solidity ^0.4.3;

import "Rules.sol";
import "BoardRoom.sol";

// A very simple ruleset, a single account can propose, vote and win a proposal

contract SingleAccountRules is Rules {
  function SingleAccountRules (address _account) public {
    account = _account;
  }

  function hasWon(uint _proposalID) public constant returns (bool) {
    return true;
  }

  function canVote(address _sender, uint _proposalID) public constant returns (bool) {
    if (_sender == account) {
      return true;
    }
  }

  function canPropose(address _sender) public constant returns (bool) {
    if (_sender == account) {
      return true;
    }
  }

  function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
    if (_sender == account) {
      return 1;
    }
  }

  address public account;
}
