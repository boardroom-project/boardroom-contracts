pragma solidity ^0.4.3;

import "BoardRoom.sol";

contract ProposalTypeRegistryInterface {
  function register(address _board, uint256 _proposalId) public {}
  function typeOf(address _board, uint256 _proposalId) public constant returns (uint256) {}
  function isTyped(address _board, uint _proposalId) public constant returns (bool) {}

  event ProposalTypeRegistered(address _board, uint _proposalId);
}

contract ProposalTypeRegistry is ProposalTypeRegistryInterface {
  function register(address _board, uint _proposalId, uint _type) public {
    BoardRoom board = BoardRoom(_board);

    // from address
    address from = board.createdBy(_proposalId);

    // acess restrict
    if (from == msg.sender && !typed[_board][_proposalId]) {
      typed[_board][_proposalId] = true;
      types[_board][_proposalId] = _type;

      ProposalTypeRegistered(_board, _proposalId);
    }
  }

  function isTyped(address _board, uint _proposalId) public constant returns (bool) {
    return typed[_board][_proposalId];
  }

  function typeOf(address _board, uint _proposalId) public constant returns (uint) {
    return types[_board][_proposalId];
  }

  mapping (address => mapping (uint => bool)) public typed;
  mapping (address => mapping (uint => uint)) public types;
}
