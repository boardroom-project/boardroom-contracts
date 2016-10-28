pragma solidity ^0.4.3;

import "examples/OpenRegistry.sol";
import "Rules.sol";
import "BoardRoom.sol";

// This allows you to delegate your vote from your accont to another
// Multi-board use, you can delegate per proposal

contract DelegatedVotingRules is Rules {
  function OpenRegistryRules(address _registry) public {
    registry = OpenRegistry(_registry);
  }

  function delegateVote(address _board, address _delegate, uint _proposalID) {
    if (!delegated[_board][msg.sender][_proposalID]) {
      delegated[_board][msg.sender][_proposalID] = true;
      delegation[_board][msg.sender][_proposalID] = _delegate;
    }
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

    if(((registry.isMember(_sender) && !delegated[address(board)][msg.sender][_proposalID])
      || (delegated[address(board)][msg.sender][_proposalID]
      && delegation[address(board)][msg.sender][_proposalID] == _sender))
      && !board.hasVoted(_proposalID, _sender)
      && now < created + debatePeriod) {
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

  mapping(address => mapping(address => mapping(uint => bool))) public delegated;
  mapping(address => mapping(address => mapping(uint => address))) public delegation;
  OpenRegistry public registry;
}
