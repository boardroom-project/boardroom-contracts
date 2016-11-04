pragma solidity ^0.4.3;

import "dapple/test.sol";
import "BoardRoom.sol";
import "examples/LiquidDemocracyRules.sol";
import "examples/OpenRegistry.sol";
import "OwnedProxy.sol";

import "examples/HumanStandardTokenFactory.sol";
contract BoardMemberProxy {
    /// @notice The contract fallback function
    function () payable public {}
    function createHumanStandardToken(uint256 _initialAmount, string _name, uint8 _decimals, string _symbol) returns (address) {
        HumanStandardToken newToken = (new HumanStandardToken(_initialAmount, _name, _decimals, _symbol));
        newToken.transfer(address(this), _initialAmount); //the factory will own the created tokens. You must transfer them.
        return address(newToken);
    }

    function approve(address _token, address _spender, uint256 _value) returns (bool success) {
        return StandardToken(_token).approve(_spender, _value);
    }

    function freezeAllowance(address _freezer, uint _daysToThaw) returns (uint amountFrozen) {
        return StandardTokenFreezer(_freezer).freezeAllowance(_daysToThaw);
    }

    function newProposal(address _board, string _name, address _proxy, uint _debatePeriod, address _destination, uint _value, bytes _calldata) returns (
        uint proposalID) {
        return BoardRoom(_board).newProposal(_name, _proxy, _debatePeriod, _destination, _value, _calldata);
    }

    function vote(address _board, uint _proposalID, uint _position) returns (uint voteWeight) {
        return BoardRoom(_board).vote(_proposalID, _position);
    }

    function transfer(address _token, address _to, uint256 _value) returns (bool success) {
        return StandardToken(_token).transfer(_to, _value);
    }

    function execute(address _board, uint _proposalID, bytes _calldata) {
        return BoardRoom(_board).execute(_proposalID, _calldata);
    }

    function delegateVote(address _board, address _rules,  address _delegate, uint _proposalID) returns (bool){
       return LiquidDemocracyRules(_rules).delegateVote(_board, _delegate, _proposalID);
    }
    function resignAsCurator (address _board, address _rules){
        return LiquidDemocracyRules(_rules).resignAsCurator(_board);
    }
}
contract LiquidBoardRoom is BoardRoom {
    function LiquidBoardRoom (address _rules) BoardRoom (_rules){
    }

    function addCurator (address _curator) {
        LiquidDemocracyRules(address(rules)).addCurator(_curator);
    }

    function removeCurator(address _curator){
        LiquidDemocracyRules(address(rules)).removeCurator(_curator);
    }
}
contract DeployUser {
    /// @notice The contract fallback function
    function () payable public {}

    function createRules (address _freezer, address[] _curators, uint _minimumBondRequired) returns (address){
        rules = new LiquidDemocracyRules(_freezer, _curators, _minimumBondRequired);
        return address(rules);
    }

    function createBoard (address _rules) returns (address) {
        board = new LiquidBoardRoom(_rules);
        return address(board);
    }

    function setupRules() {
        rules.configureBoard(address(board));
    }

    LiquidDemocracyRules rules;
    LiquidBoardRoom board;
}

contract LiquidDemocracyRulesBoardRoomTest is Test {
    OpenRegistry registry;
    OwnedProxy proxy;

    LiquidDemocracyRules rules;
    LiquidBoardRoom board;

    address [] curators;
    DeployUser duser;

    HumanStandardTokenFactory factory;
    StandardToken token;
    StandardTokenFreezer freezer;


    BoardMemberProxy user;
    address tokenAddr;

    function setUp() {
        user = new BoardMemberProxy();
        registry = new OpenRegistry();
        registry.register(address(user));
        curators.push(address(user));

        duser = new DeployUser();
        if (duser.send(500000)) {
        }

        if(user.send(500000)){
        }
        tokenAddr = user.createHumanStandardToken(4000, "Nicks Token", 8, "NT");
        freezer = new StandardTokenFreezer(tokenAddr);


        rules = LiquidDemocracyRules(duser.createRules(address(freezer), curators, 1));
        address boardAddr = duser.createBoard(address(rules));
        board = LiquidBoardRoom(boardAddr);
        duser.setupRules();
        proxy = new OwnedProxy(address(board));
        if (proxy.send(600)){
        }

        if(board.send(50000)){
        }
    }


    function test_proposalVetoedByCurator() {
        HumanStandardToken tokenObj = HumanStandardToken(tokenAddr);

        address destinationAccount = address(new BoardMemberProxy());


        BoardMemberProxy member2= new BoardMemberProxy();
        BoardMemberProxy member3= new BoardMemberProxy();
        BoardMemberProxy member4= new BoardMemberProxy();

        if(user.send(500000)){
        }

        assertEq(user.approve(tokenAddr, address(freezer), 500), true);
        assertEq(user.freezeAllowance(address(freezer), 60), 500);
        assertEq(freezer.balanceOf(address(user)), 500);
   

        user.newProposal(address(board), "Can I have 14 smarties?", address(proxy), 30, destinationAccount, 400, "");
        rules.depositBond.value(1000)(address(board),0);

        assertTrue(user.transfer(tokenAddr, address(member2), 20));
        assertTrue(member2.approve(tokenAddr, address(freezer), 20));
        assertEq(member2.freezeAllowance(address(freezer), 60), 20);
        assertEq(freezer.balanceOf(address(member2)), 20);

        assertTrue(user.transfer(tokenAddr, address(member3), 200));
        assertTrue(member3.approve(tokenAddr, address(freezer), 200));
        assertEq(member3.freezeAllowance(address(freezer), 60), 200);
        assertEq(freezer.balanceOf(address(member3)), 200);

        assertTrue(user.transfer(tokenAddr, address(member4), 2000));
        assertTrue(member4.approve(tokenAddr, address(freezer), 2000));
        assertEq(member4.freezeAllowance(address(freezer), 60), 2000);
        assertEq(freezer.balanceOf(address(member4)), 2000);

        expectEventsExact(rules);
        user.vote(address(board), 0, 0);
        member2.vote(address(board), 0, 1);
        member3.vote(address(board), 0, 1);
        member4.vote(address(board), 0, 1);

        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        user.execute(address(board), 0, "");
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);

    }
    function test_proposalPassWithConsensys() {
        HumanStandardToken tokenObj = HumanStandardToken(tokenAddr);

        address destinationAccount = address(new BoardMemberProxy());


        BoardMemberProxy member2= new BoardMemberProxy();
        BoardMemberProxy member3= new BoardMemberProxy();
        BoardMemberProxy member4= new BoardMemberProxy();

        if(user.send(500000)){
        }

        assertEq(user.approve(tokenAddr, address(freezer), 20), true);
        assertEq(user.freezeAllowance(address(freezer), 60), 20);
        assertEq(freezer.balanceOf(address(user)), 20);

        user.newProposal(address(board), "Can I have 14 smarties?", address(proxy), 30, destinationAccount, 400, "");
        rules.depositBond.value(1000)(address(board),0);

        assertTrue(user.transfer(tokenAddr, address(member2), 20));
        assertTrue(member2.approve(tokenAddr, address(freezer), 20));
        assertEq(member2.freezeAllowance(address(freezer), 60), 20);
        assertEq(freezer.balanceOf(address(member2)), 20);

        assertTrue(user.transfer(tokenAddr, address(member3), 200));
        assertTrue(member3.approve(tokenAddr, address(freezer), 200));
        assertEq(member3.freezeAllowance(address(freezer), 60), 200);
        assertEq(freezer.balanceOf(address(member3)), 200);

        assertTrue(user.transfer(tokenAddr, address(member4), 2000));
        assertTrue(member4.approve(tokenAddr, address(freezer), 2000));
        assertEq(member4.freezeAllowance(address(freezer), 60), 2000);
        assertEq(freezer.balanceOf(address(member4)), 2000);


        expectEventsExact(rules);
       
        assertEq(user.vote(address(board), 0, 1), 20);
        assertEq(member2.vote(address(board), 0, 1), 20);
        assertEq(member3.vote(address(board), 0, 1), 200);
        assertEq(member4.vote(address(board), 0, 1), 2000);

        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        user.execute(address(board), 0, "");
        assertEq(proxy.balance, 200);
        assertEq(destinationAccount.balance, 400);

    }

    function test_delegateVotePass() {
        HumanStandardToken tokenObj = HumanStandardToken(tokenAddr);

        address destinationAccount = address(new BoardMemberProxy());


        BoardMemberProxy member2= new BoardMemberProxy();
        BoardMemberProxy member3= new BoardMemberProxy();
        BoardMemberProxy member4= new BoardMemberProxy();

        if(user.send(500000)){
        }

        assertEq(user.approve(tokenAddr, address(freezer), 500), true);
        assertEq(user.freezeAllowance(address(freezer), 60), 500);
        assertEq(freezer.balanceOf(address(user)), 500);

        user.newProposal(address(board), "Can I have 14 smarties?", address(proxy), 30, destinationAccount, 400, "");
        rules.depositBond.value(1000)(address(board),0);

        assertTrue(user.transfer(tokenAddr, address(member2), 500));
        assertTrue(member2.approve(tokenAddr, address(freezer), 500));
        assertEq(member2.freezeAllowance(address(freezer), 60), 500);
        assertEq(freezer.balanceOf(address(member2)), 500);

        assertTrue(user.transfer(tokenAddr, address(member3), 1300));
        assertTrue(member3.approve(tokenAddr, address(freezer), 1300));
        assertEq(member3.freezeAllowance(address(freezer), 60), 1300);
        assertEq(freezer.balanceOf(address(member3)), 1300);

        assertTrue(user.transfer(tokenAddr, address(member4), 1500));
        assertTrue(member4.approve(tokenAddr, address(freezer), 1500));
        assertEq(member4.freezeAllowance(address(freezer), 60), 1500);
        assertEq(freezer.balanceOf(address(member4)), 1500);


        assertTrue(member2.delegateVote(address(board), address(rules), address(member3), 0));

        assertEq(user.vote(address(board), 0, 1), 500);
        assertEq(member2.vote(address(board), 0, 1), 0);
        assertEq(member3.vote(address(board), 0, 1),1800);
        assertEq(member4.vote(address(board), 0, 0), 1500);

        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        user.execute(address(board), 0, "");
        assertEq(proxy.balance, 200);
        assertEq(destinationAccount.balance, 400);

    }
    function test_delaegateVoteFail() {
        HumanStandardToken tokenObj = HumanStandardToken(tokenAddr);

        address destinationAccount = address(new BoardMemberProxy());


        BoardMemberProxy member2= new BoardMemberProxy();
        BoardMemberProxy member3= new BoardMemberProxy();
        BoardMemberProxy member4= new BoardMemberProxy();

        if(user.send(500000)){
        }

        assertEq(user.approve(tokenAddr, address(freezer), 100), true);
        assertEq(user.freezeAllowance(address(freezer), 60), 100);
        assertEq(freezer.balanceOf(address(user)), 100);

        user.newProposal(address(board), "Can I have 14 smarties?", address(proxy), 30, destinationAccount, 400, "");
        rules.depositBond.value(1000)(address(board),0);

        assertTrue(user.transfer(tokenAddr, address(member2), 500));
        assertTrue(member2.approve(tokenAddr, address(freezer), 500));
        assertEq(member2.freezeAllowance(address(freezer), 60), 500);
        assertEq(freezer.balanceOf(address(member2)), 500);

        assertTrue(user.transfer(tokenAddr, address(member3), 1300));
        assertTrue(member3.approve(tokenAddr, address(freezer), 1300));
        assertEq(member3.freezeAllowance(address(freezer), 60), 1300);
        assertEq(freezer.balanceOf(address(member3)), 1300);

        assertTrue(user.transfer(tokenAddr, address(member4), 1500));
        assertTrue(member4.approve(tokenAddr, address(freezer), 1500));
        assertEq(member4.freezeAllowance(address(freezer), 60), 1500);
        assertEq(freezer.balanceOf(address(member4)), 1500);


        assertTrue(member2.delegateVote(address(board), address(rules), address(member3), 0));

        assertEq(user.vote(address(board), 0, 1), 100);
        assertEq(member2.vote(address(board), 0, 1), 0);
        assertEq(member3.vote(address(board), 0, 0),1800);
        assertEq(member4.vote(address(board), 0, 1), 1500);

        assertEq(board.numVoters(0), 4);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        user.execute(address(board), 0, "");
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);

    }

    function test_addCurator() {
        HumanStandardToken tokenObj = HumanStandardToken(tokenAddr);

        address destinationAccount = address(new BoardMemberProxy());


        BoardMemberProxy member2= new BoardMemberProxy();
        BoardMemberProxy member3= new BoardMemberProxy();
        BoardMemberProxy member4= new BoardMemberProxy();
        BoardMemberProxy member5= new BoardMemberProxy();

        if(user.send(500000)){
        }

        assertEq(user.approve(tokenAddr, address(freezer), 100), true);
        assertEq(user.freezeAllowance(address(freezer), 60), 100);
        assertEq(freezer.balanceOf(address(user)), 100);

        user.newProposal(address(board), "Can I have 14 smarties?", address(proxy), 30, destinationAccount, 400, "");
        rules.depositBond.value(1000)(address(board),0);

        assertTrue(user.transfer(tokenAddr, address(member2), 500));
        assertTrue(member2.approve(tokenAddr, address(freezer), 500));
        assertEq(member2.freezeAllowance(address(freezer), 60), 500);
        assertEq(freezer.balanceOf(address(member2)), 500);

        assertTrue(user.transfer(tokenAddr, address(member3), 1300));
        assertTrue(member3.approve(tokenAddr, address(freezer), 1300));
        assertEq(member3.freezeAllowance(address(freezer), 60), 1300);
        assertEq(freezer.balanceOf(address(member3)), 1300);

        assertTrue(user.transfer(tokenAddr, address(member4), 1500));
        assertTrue(member4.approve(tokenAddr, address(freezer), 1500));
        assertEq(member4.freezeAllowance(address(freezer), 60), 1500);
        assertEq(freezer.balanceOf(address(member4)), 1500);

        assertTrue(user.transfer(tokenAddr, address(member5), 100));
        assertTrue(member5.approve(tokenAddr, address(freezer), 100));
        assertEq(member5.freezeAllowance(address(freezer), 60), 100);
        assertEq(freezer.balanceOf(address(member5)), 100);

        assertTrue(member2.delegateVote(address(board), address(rules), address(member3), 0));
        board.addCurator(address(member5));

        assertEq(user.vote(address(board), 0, 1), 100);
        assertEq(member2.vote(address(board), 0, 1), 0);
        assertEq(member3.vote(address(board), 0, 1),1800);
        assertEq(member4.vote(address(board), 0, 1), 1500);
        assertEq(member5.vote(address(board), 0, 0), 100);

        assertEq(board.numVoters(0), 5);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        user.execute(address(board), 0, "");
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);

    }
    function test_addCuratorThenRemove() {
        HumanStandardToken tokenObj = HumanStandardToken(tokenAddr);

        address destinationAccount = address(new BoardMemberProxy());


        BoardMemberProxy member2= new BoardMemberProxy();
        BoardMemberProxy member3= new BoardMemberProxy();
        BoardMemberProxy member4= new BoardMemberProxy();
        BoardMemberProxy member5= new BoardMemberProxy();

        if(user.send(500000)){
        }

        assertEq(user.approve(tokenAddr, address(freezer), 100), true);
        assertEq(user.freezeAllowance(address(freezer), 60), 100);
        assertEq(freezer.balanceOf(address(user)), 100);

        user.newProposal(address(board), "Can I have 14 smarties?", address(proxy), 30, destinationAccount, 400, "");
        rules.depositBond.value(1000)(address(board),0);

        assertTrue(user.transfer(tokenAddr, address(member2), 500));
        assertTrue(member2.approve(tokenAddr, address(freezer), 500));
        assertEq(member2.freezeAllowance(address(freezer), 60), 500);
        assertEq(freezer.balanceOf(address(member2)), 500);

        assertTrue(user.transfer(tokenAddr, address(member3), 1300));
        assertTrue(member3.approve(tokenAddr, address(freezer), 1300));
        assertEq(member3.freezeAllowance(address(freezer), 60), 1300);
        assertEq(freezer.balanceOf(address(member3)), 1300);

        assertTrue(user.transfer(tokenAddr, address(member4), 1500));
        assertTrue(member4.approve(tokenAddr, address(freezer), 1500));
        assertEq(member4.freezeAllowance(address(freezer), 60), 1500);
        assertEq(freezer.balanceOf(address(member4)), 1500);

        assertTrue(user.transfer(tokenAddr, address(member5), 1));
        assertTrue(member5.approve(tokenAddr, address(freezer), 1));
        assertEq(member5.freezeAllowance(address(freezer), 60), 1);
        assertEq(freezer.balanceOf(address(member5)), 1);

        assertTrue(member2.delegateVote(address(board), address(rules), address(member3), 0));

        board.addCurator(address(member5));
        board.removeCurator(address(member5));


        assertEq(user.vote(address(board), 0, 1), 100);
        assertEq(member2.vote(address(board), 0, 1), 0);
        assertEq(member3.vote(address(board), 0, 1),1800);
        assertEq(member4.vote(address(board), 0, 1), 1500);
        assertEq(member5.vote(address(board), 0, 0), 1);


        assertEq(board.numVoters(0), 5);
        assertEq(proxy.balance, 600);
        assertEq(destinationAccount.balance, 0);
        user.execute(address(board), 0, "");
        assertEq(proxy.balance, 200);
        assertEq(destinationAccount.balance, 400);

    }
}
