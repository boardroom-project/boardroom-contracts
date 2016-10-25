import "Rules.sol";
import "BoardRoom.sol";

// A very simple ruleset, a single account can propose, vote and win a proposal

contract SingleAccountRules is Rules {
  function SingleAccountRules (address _account) {
    account = _account;
  }

  function hasWon(uint _proposalID) constant returns (bool) {
    return true;
  }

  function canVote(address _sender, uint _proposalID) constant returns (bool) {
    if (_sender == account) {
      return true;
    }
  }

  function canPropose(address _sender) constant returns (bool) {
    if (_sender == account) {
      return true;
    }
  }

  function votingWeightOf(address _sender, uint _proposalID) constant returns (uint) {
    if (_sender == account) {
      return 1;
    }
  }

  address public account;
}
