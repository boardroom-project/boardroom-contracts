pragma solidity ^0.4.3;

import "dapple/test.sol";
import "BoardRoom.sol";
import "examples/BondRules.sol";
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

contract BondProxy is MemberProxy {
    function () payable public {}
    function depositBond(address _rules, uint _proposalID) {
        return RequiredBondRules(_rules).depositBond.value(this.balance)(_proposalID);
    }
}

contract BondRulesTest is Test {
  OpenRegistry registry;
  OwnedProxy proxy;
  RequiredBondRules rules;
  BoardRoom board;
  MemberProxy member1;
  BondProxy bondProxy;

  function setUp() {
    member1 = new MemberProxy();
    registry = new OpenRegistry();
    registry.register(address(member1));
    rules = new RequiredBondRules(address(registry));
    board = new BoardRoom(address(rules));
    bondProxy = new BondProxy();
  }

  function test_ShouldPassButNoBondSoFail() {
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));
    if (proxy.send(600)){
    }

    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    registry.register(address(member1));
    MemberProxy member2 = new MemberProxy();
    registry.register(address(member2));
    MemberProxy member3 = new MemberProxy();
    registry.register(address(member3));
    MemberProxy member4 = new MemberProxy();
    registry.register(address(member4));
    assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

    member1.vote(address(board), 0, 1);
    member2.vote(address(board), 0, 1);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);

    assertEq(board.numVoters(0), 0);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
  }


  function test_BondPostedAndOverMajority() {
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));

    if (proxy.send(600)) {
    }

    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    registry.register(address(member1));
    MemberProxy member2 = new MemberProxy();
    registry.register(address(member2));
    MemberProxy member3 = new MemberProxy();
    registry.register(address(member3));
    MemberProxy member4 = new MemberProxy();
    registry.register(address(member4));
    assertEq(member2.newProposal(address(board), "Some Awesome Sauce Proposal", address(proxy), 30, destinationAccount, 400, ""), 0);

    assertEq(bondProxy.balance, 0);
    if(bondProxy.send(4000)){
    }
    assertEq(bondProxy.balance, 4000);
    bondProxy.depositBond(address(rules), 0);

    member1.vote(address(board), 0, 0);
    member2.vote(address(board), 0, 1);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);
    assertEq(board.numVoters(0), 4);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 200);
    assertEq(destinationAccount.balance, 400);
  }
  
  function test_BondPostedButNoMajority() {
    board = new BoardRoom(address(rules));
    proxy = new OwnedProxy(address(board));

    if (proxy.send(600)) {
    }

    address destinationAccount = address(new MemberProxy());
    MemberProxy member1 = new MemberProxy();
    registry.register(address(member1));
    MemberProxy member2 = new MemberProxy();
    registry.register(address(member2));
    MemberProxy member3 = new MemberProxy();
    registry.register(address(member3));
    MemberProxy member4 = new MemberProxy();
    registry.register(address(member4));
    assertEq(member2.newProposal(address(board), "Some Awesome Sauce Proposal", address(proxy), 30, destinationAccount, 400, ""), 0);

    assertEq(bondProxy.balance, 0);
    if(bondProxy.send(4000)){
    }
    assertEq(bondProxy.balance, 4000);
    bondProxy.depositBond(address(rules), 0);

    member1.vote(address(board), 0, 0);
    member2.vote(address(board), 0, 0);
    member3.vote(address(board), 0, 1);
    member4.vote(address(board), 0, 1);
    assertEq(board.numVoters(0), 4);
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
    member1.execute(address(board), 0, "");
    assertEq(proxy.balance, 600);
    assertEq(destinationAccount.balance, 0);
  }
}
