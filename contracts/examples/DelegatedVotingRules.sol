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

  function delegateVote(address _board, address _delegate, uint _proposalID) public {
    BoardRoom board = BoardRoom(_board);

    uint created = board.createdOn(_proposalID);
    uint debatePeriod = board.debatePeriodOf(_proposalID);

    if(votingWeightOf(msg.sender, _proposalID) > 0
      && now < (created + debatePeriod)
      && board.hasVoted(_proposalID, msg.sender) == false
      && delegated[_board][_proposalID][msg.sender] == false) {
      delegated[_board][_proposalID][msg.sender] = true;
      delegatedTo[_board][_proposalID][msg.sender] = _delegate;
      delegatedWeight[_board][_proposalID][_delegate] += 1;
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

    if(!board.hasVoted(_proposalID, _sender)
      && delegated[msg.sender][_proposalID][_sender] == false
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
    if (delegated[msg.sender][_proposalID][_sender] == false) {
      return 1 + delegatedWeight[msg.sender][_proposalID][_sender];
    }
  }

  mapping(address => mapping(uint => mapping(address => bool))) public delegated;
  mapping(address => mapping(uint => mapping(address => address))) public delegatedTo;
  mapping(address => mapping(uint => mapping(address => uint))) public delegatedWeight;

  OpenRegistry public registry;
}
