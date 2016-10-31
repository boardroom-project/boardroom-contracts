pragma solidity ^0.4.3;

import "Rules.sol";
import "examples/StandardTokenFreezer.sol";
import "BoardRoom.sol";

contract DecayingQuorumRules is Rules {
  function TokenFreezerRules (address _freezer) public {
    token = StandardTokenFreezer(_freezer);
    startBlock = block.number;
  }

  function hasWon (uint _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint nay = board.positionWeightOf(_proposalID, 0);
    uint yea = board.positionWeightOf(_proposalID, 1);
    uint quorum = StandardToken(token.token()).totalSupply();
    uint divisor = 20;

    if (block.number > startBlock + 5000) {
      divisor = 40;
    }

    if (block.number > startBlock + 10000) {
      divisor = 60;
    }

    if((yea + nay) > quorum / divisor && yea > nay) {
      return true;
    }
  }

  function canVote (address _sender, uint _proposalID) public constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);

    uint created = board.createdOn(_proposalID);
    uint debatePeriod = board.debatePeriodOf(_proposalID);

    if(votingWeightOf(_sender, _proposalID) > 0
      && now < (created + debatePeriod)
      && token.frozenUntil(_sender) > (created + debatePeriod)
      && board.hasVoted(_proposalID, _sender) == false) {
      return true;
    }
  }

  function canPropose (address _sender) public constant returns (bool) {
    if(token.balanceOf(_sender) > 0) {
      return true;
    }
  }

  function votingWeightOf (address _sender, uint _proposalID) public constant returns (uint) {
    return token.balanceOf(_sender);
  }

  uint startBlock;
  StandardTokenFreezer public token;
}
