pragma solidity ^0.4.3;

import "dapple/test.sol";
import "examples/StandardToken.sol";
import "examples/HumanStandardTokenFactory.sol";
import "examples/StandardTokenFreezer.sol";

contract FreezerUserProxy {
  /// @notice The contract fallback function
  function () payable public {}
    
  function createHumanStandardToken(address _factory, uint256 _initialAmount, string _name, uint8 _decimals, string _symbol) returns (address) {
    return HumanStandardTokenFactory(_factory).createHumanStandardToken(_initialAmount, _name, _decimals, _symbol);
  }

  function approve(address _token, address _spender, uint256 _value) returns (bool success) {
    return StandardToken(_token).approve(_spender, _value);
  }

  function freezeAllowance(address _freezer, uint _daysToThaw) returns (uint amountFrozen) {
    return StandardTokenFreezer(_freezer).freezeAllowance(_daysToThaw);
  }
}

contract StandardTokenFreezerTests is Test {
  HumanStandardTokenFactory factory;
  StandardToken token;
  StandardTokenFreezer freezer;

  function setUp() {
    factory = new HumanStandardTokenFactory();
  }

  function test_tokenFreeze(){
    FreezerUserProxy user = new FreezerUserProxy();
    address token = user.createHumanStandardToken(address(factory), 490000, "Nicks Token", 8, "NT");
    assertTrue(bool(token != address(0)));
    freezer = new StandardTokenFreezer(token);
    assertTrue(user.approve(token, address(freezer), 5000));
    assertEq(user.freezeAllowance(address(freezer), 30), 5000);
    assertEq(freezer.balanceOf(address(user)), 5000);
    assertTrue(bool(freezer.frozenUntil(address(user)) > 0));
  }

  function test_invalidTokenFreeze(){
  }
}
