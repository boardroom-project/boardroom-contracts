# boardroom-contracts
All BoardRoom contracts.

<img src="assets/standardBoardRoomContractDesignDiagram.jpg" />

## Install
```
git clone https://github.com/boardroom-project/boardroom-contracts.git
npm install
```

## Standard Deloyment Flow

The standard BoardRoom contract deployment flow is as follows:

[AnyRulesContractRequirements] => TheRulesContract.sol => BoardRoom.sol

## Example Rules Contract

Here anyone can vote and table proposals. The voting weight is hard coded at 1. Anyone can vote multiple times, and a proposal has won only when people who voted yea is greater than nay.

```
import "Rules.sol";
import "BoardRoom.sol";

contract OpenRules is Rules {
  function hasWon(uint _proposalID) constant returns (bool) {
    BoardRoom board = BoardRoom(msg.sender);
    uint nay = board.positionWeightOf(_proposalID, 0);
    uint yea = board.positionWeightOf(_proposalID, 1);

    if(yea > nay) {
      return true;
    }
  }

  function canVote(address _sender, uint _proposalID) constant returns (bool) {
    return true;
  }

  function canPropose(address _sender) constant returns (bool) {
    return true;
  }

  function votingWeightOf(address _sender, uint _proposalID) constant returns (uint) {
    return 1;
  }
}
```

## Test
```
npm test
```

## Build
```
npm run build
```
