pragma solidity ^0.4.3;

import "dapple/test.sol";
import "BoardRoom.sol";
import "examples/TorontoRules.sol";
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

contract DeployUser {
    /// @notice The contract fallback function
    function () payable public {}

    function createRules (address _registry, address[] _curators) returns (address){
        rules = new TorontoRules(address(_registry), _curators);
        return address(rules);
    }

    function createBoard (address _rules) returns (address) {
        board = new BoardRoom(_rules);
        return address(board);
    }

    function setupRules() {
        rules.configureBoard(address(board));
    }

    TorontoRules rules;
    BoardRoom board;
}

contract TorontoRulesBoardRoomTest is Test {
    OpenRegistry registry;
    OwnedProxy proxy;
    TorontoRules rules;
    BoardRoom board;
    address [] curators;
    DeployUser duser;

    MemberProxy member1;

    function setUp() {
        member1 = new MemberProxy();
        registry = new OpenRegistry();
        registry.register(address(member1));

        duser = new DeployUser();
        if (duser.send(500000)) {
        }

        curators.push(address(member1));

        rules = TorontoRules(duser.createRules(address(registry), curators));
        address boardAddr = duser.createBoard(address(rules));

        board = BoardRoom(boardAddr);
        duser.setupRules();

        /*
        rules = new CuratorRule(address(registry), curators);
        board = new BoardRoom(address(rules));

        rules.setup(address(board));
        */
    }

    function test_curators() {
        assertEq(curators[0], address(member1));
        assertTrue(rules.isCurator(address(board), address(member1)));
    }

    function test_openRegistry() {
        assertTrue(registry.isMember(address(member1)));
        assertEq(registry.members(0), address(member1));
    }

    function test_TorontoRules() {
        rules.configureBoard(address(this));
        assertTrue(rules.canPropose(address(member1)));
        assertEq(rules.votingWeightOf(address(member1), 0), 1);
    }

    function test_curatorDoesVeto() {
        proxy = new OwnedProxy(address(board));
        if (proxy.send(600)){
        }

        address destinationAccount = address(new MemberProxy());

        MemberProxy member2 = new MemberProxy();
        registry.register(address(member2));
        MemberProxy member3 = new MemberProxy();
        registry.register(address(member3));
        MemberProxy member4 = new MemberProxy();
        registry.register(address(member4));
        assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

        member1.vote(address(board), 0, 0);
        member2.vote(address(board), 0, 1);
        member3.vote(address(board), 0, 1);
        member4.vote(address(board), 0, 1);
        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        member1.execute(address(board), 0, "");
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
    }

    function test_curatorDoesNotVeto() {
        proxy = new OwnedProxy(address(board));
        if (proxy.send(600)){
        }

        address destinationAccount = address(new MemberProxy());
        MemberProxy member2 = new MemberProxy();
        registry.register(address(member2));
        MemberProxy member3 = new MemberProxy();
        registry.register(address(member3));
        MemberProxy member4 = new MemberProxy();
        registry.register(address(member4));
        assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

        member1.vote(address(board), 0, 1);
        member2.vote(address(board), 0, 0);
        member3.vote(address(board), 0, 1);
        member4.vote(address(board), 0, 1);
        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        member1.execute(address(board), 0, "");
        assertEq(proxy.balance, 200);
        assertEq(destinationAccount.balance, 400);
    }
    function test_OverSixtyPercent() {
        proxy = new OwnedProxy(address(board));
        if (proxy.send(600)){
        }

        address destinationAccount = address(new MemberProxy());
        MemberProxy member2 = new MemberProxy();
        registry.register(address(member2));
        MemberProxy member3 = new MemberProxy();
        registry.register(address(member3));
        MemberProxy member4 = new MemberProxy();
        registry.register(address(member4));
        assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

        member1.vote(address(board), 0, 1);
        member2.vote(address(board), 0, 0);
        member3.vote(address(board), 0, 1);
        member4.vote(address(board), 0, 1);
        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        member1.execute(address(board), 0, "");
        assertEq(proxy.balance, 200);
        assertEq(destinationAccount.balance, 400);

    }

    function test_FiftySixPercent() {
        proxy = new OwnedProxy(address(board));
        if (proxy.send(600)){
        }

        address destinationAccount = address(new MemberProxy());
        MemberProxy member2 = new MemberProxy();
        registry.register(address(member2));
        MemberProxy member3 = new MemberProxy();
        registry.register(address(member3));
        MemberProxy member4 = new MemberProxy();
        registry.register(address(member4));
        MemberProxy member5 = new MemberProxy();
        registry.register(address(member5));
        MemberProxy member6 = new MemberProxy();
        registry.register(address(member6));
        MemberProxy member7 = new MemberProxy();
        registry.register(address(member7));
        MemberProxy member8 = new MemberProxy();
        registry.register(address(member8));
        MemberProxy member9 = new MemberProxy();
        registry.register(address(member9));

        assertEq(member1.newProposal(address(board), "Does Jet Fuel Melt Steel Beams?", address(proxy), 30, destinationAccount, 400, ""), 0);

        member1.vote(address(board), 0, 1);
        member2.vote(address(board), 0, 0);
        member3.vote(address(board), 0, 0);
        member4.vote(address(board), 0, 0);
        member5.vote(address(board), 0, 0);
        member6.vote(address(board), 0, 1);
        member7.vote(address(board), 0, 1);
        member8.vote(address(board), 0, 1);
        member9.vote(address(board), 0, 1);
        assertEq(board.numVoters(0), 9);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        member1.execute(address(board), 0, "");
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);

    }

}
