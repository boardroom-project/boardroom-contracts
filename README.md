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

## Example Board
An example OpenRules BoardRoom is deployed here, this will allow you to load and interact with the BoardRoom contract on testnet without having to deploy your own.

  TestNet:
    1. OpenRules.sol
    0x59dcac601282ae67042d97c543ff524ec8509911

    2. BoardRoom.sol
    0xd89b8a74c153f0626497bc4a531f702c6a4b285f

## Test
```
npm test
```

## Build
```
npm run build
```
