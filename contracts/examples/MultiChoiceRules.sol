pragma solidity ^0.4.3;

import "Rules.sol";
import "BoardRoom.sol";

contract MultiChoiceRules is Rules {
  modifier boardIsConfigured (address _board) {
      if (isConfigured[_board]) {
        _;
      }
  }

  function hasWon (uint _proposalID) boardIsConfigured(msg.sender) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint voted;

    for(uint i = 0 ; i < positionsAvailable[board] ; i++){
      voted += board.positionWeightOf(_proposalID, i);
      
      // current mechanism for tie breakers is position order
      if (board.positionWeightOf(_proposalID, i) > leadPositionWeight) {
        leadPositionWeight = board.positionWeightOf(_proposalID, i);
        leadPosition = i;
      }
    }

    if(voted > quorumRequirement[board]) {
      return true;
    }
  }

  function canVote(address _sender, uint _proposalID) public constant returns (bool) {
    return true;
  }

  function canPropose(address _sender) public constant returns (bool) {
    return true;
  }

  function votingWeightOf(address _sender, uint _proposalID) public constant returns (uint) {
    return 1;
  }

  function configureBoard (address _board, uint _positions, uint _quorum, uint _members) public {
    if (_quorum > 100) throw;
    if (_members > 250) throw;
    if (_positions > 50) throw;

    // configure Board quorum and number of positions
    quorumRequirement[_board] = _quorum;
    positionsAvailable[_board] = _positions;
    numberMembers[_board] = _members;

    // set board to configured
    isConfigured[_board] = true;
  }

  uint leadPositionWeight;
  uint leadPosition;
  uint memberCount;

  mapping(address => uint) numberMembers;
  mapping(address => bool) isConfigured;
  mapping(address => uint) positionsAvailable;
  mapping(address => uint) quorumRequirement;

}
