pragma solidity ^0.4.3;

import "dapple/test.sol";
import "BoardRoom.sol";
import "examples/MultiSigRules.sol";
import "examples/OpenRegistry.sol";
import "OwnedProxy.sol";

contract MemberProxy {
  /// @notice The contract fallback function
  function () payable public {}
    
  function newProposal(address _board, string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (uint proposalID) {
    return BoardRoom(_board).newProposal(_name, _proxy, _debatePeriod, _destination, _value, _calldata);
  }
  function vote(address _board, uint _proposalID, uint _position) returns (uint voteWeight) {
    return BoardRoom(_board).vote(_proposalID, _position);
  }
  function execute(address _board, uint _proposalID, bytes _calldata) {
    return BoardRoom(_board).execute(_proposalID, _calldata);
  }
}

contract MultiSigRulesTest is Test {
  OwnedProxy proxy;
  MultiSigRules rules;
  BoardRoom board;
  address[] signatories;

  function test_ConsensysReached() {

    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    MemberProxy member2 = new MemberProxy();
    MemberProxy member3 = new MemberProxy();
    MemberProxy member4 = new MemberProxy();
    signatories.push(address(member1));
    signatories.push(address(member2));
    signatories.push(address(member3));
    signatories.push(address(member4));

    rules = new MultiSigRules(signatories);
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));

    if (proxy.send(600)) {
    }


    assertEq(member2.newProposal(address(board), "Some Awesome Sauce Proposal", address(proxy), 30, destinationAccount, 400, ""), 0);
    member1.vote(address(board), 0, 1);
    member2.vote(address(board), 0, 1);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);
    assertEq(board.numVoters(0), 4);
    assertEq(board.positionWeightOf(0,1),4);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 200);
    assertEq(destinationAccount.balance, 400);
  }

  function test_ConsensysNotReached() {
    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    MemberProxy member2 = new MemberProxy();
    MemberProxy member3 = new MemberProxy();
    MemberProxy member4 = new MemberProxy();
    signatories.push(address(member1));
    signatories.push(address(member2));
    signatories.push(address(member3));
    signatories.push(address(member4));

    rules = new MultiSigRules(signatories);
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));

    if (proxy.send(600)) {
    }


    assertEq(member2.newProposal(address(board), "Some Awesome Sauce Proposal", address(proxy), 30, destinationAccount, 400, ""), 0);
    member1.vote(address(board), 0, 1);
    member2.vote(address(board), 0, 0);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);
    assertEq(board.numVoters(0), 4);
    assertEq(board.positionWeightOf(0,1),3);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
  }
}
