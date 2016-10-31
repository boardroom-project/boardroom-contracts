pragma solidity ^0.4.3;

import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

contract OpenRegistryRules is Rules {
  function OpenRegistryRules(address _registry) public {
    registry = OpenRegistry(_registry);
  }

  function hasWon(uint _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint nay = board.positionWeightOf(_proposalID, 0);
    uint yea = board.positionWeightOf(_proposalID, 1);
    uint totalVoters = board.numVoters(_proposalID);

    if(totalVoters > 0 && yea > nay) {
      return true;
    }
  }

  function canVote(address _sender, uint _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint created = board.createdOn(_proposalID);
    uint debatePeriod = board.debatePeriodOf(_proposalID);

    if(registry.isMember(_sender)
      && now < created + debatePeriod
      && !board.hasVoted(_proposalID, _sender)) {
      return true;
    }
  }

  function canPropose(address _sender) public constant returns (bool) {
    if(registry.isMember(_sender)) {
      return true;
    }
  }

  function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
    return 1;
  }

  OpenRegistry public registry;
}
