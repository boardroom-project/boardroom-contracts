pragma solidity ^0.4.3;

import "BoardRoom.sol";
import "Rules.sol";
import "examples/ProposalTypeRegistry.sol";

// This allows a BoardRoom member to type a propoal
// Once a proposal is typed, the type will access a specific rule set
// all rules are registered in advance
// rules type 0 is reserved for the "base" ruleset
// the base rule set defines who can table proposals
// In other words, MetaRules allows multi-class multi-type proposals
// So if you have a Board that has multiple share types or classes
// you can now register proposals under multiple share classes

contract MetaRules {
  function MetaRules(address _proposalTypeRegisty, address[] _rulesRegistry) public {
    registry = ProposalTypeRegistry(_proposalTypeRegisty);
    rulesRegistry = _rulesRegistry;
  }

  function hasWon(uint _proposalID) public constant returns (bool) {
    Rules selectedRules = Rules(rulesRegistry[registry.typeOf(msg.sender, _proposalID)]);

    if (registry.typeOf(msg.sender, _proposalID) != 0 && registry.isTyped(msg.sender, _proposalID)) {
      return selectedRules.hasWon(_proposalID);
    } else {
      return false;
    }
  }

  function canVote(address _sender, uint _proposalID) public constant returns (bool) {
    Rules selectedRules = Rules(rulesRegistry[registry.typeOf(msg.sender, _proposalID)]);

    return selectedRules.canVote(_sender, _proposalID);
  }

  function canPropose(address _sender) public constant returns (bool) {
    Rules selectedRules = Rules(rulesRegistry[0]);

    // base rules are denoted as 0
    return selectedRules.canPropose(_sender);
  }

  function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
    Rules selectedRules = Rules(rulesRegistry[registry.typeOf(msg.sender, _proposalID)]);

    return selectedRules.votingWeightOf(_sender, _proposalID);
  }

  ProposalTypeRegistry registry;
  address[] public rulesRegistry;
}
