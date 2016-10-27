pragma solidity ^0.4.3;

import "Rules.sol";
import "BoardRoom.sol";

contract OpenRules is Rules {
  function hasWon(uint _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);
    uint nay = board.positionWeightOf(_proposalID, 0);
    uint yea = board.positionWeightOf(_proposalID, 1);

    if(yea > nay) {
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
}
