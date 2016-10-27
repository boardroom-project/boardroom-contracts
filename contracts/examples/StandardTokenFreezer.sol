pragma solidity ^0.4.3;

import "examples/StandardToken.sol";

contract StandardTokenFreezerInterface {
  function freezeAllowance(uint _daysToThaw) returns (uint amountFrozen) {}
  function extendFreezeBy(uint _days) {}
  function withdrawBalance() returns (uint amountWithdrawn) {}
  function balanceOf(address _from) constant returns (uint balance) {}
  function frozenUntil(address _from) constant returns (uint thawDate) {}
}

contract StandardTokenFreezer is StandardTokenFreezerInterface {
  function StandardTokenFreezer(address _token) public {
    token = StandardToken(_token);
  }

  function freezeAllowance (uint _daysToThaw) public returns (uint amountFrozen) {
    amountFrozen = token.allowance(msg.sender, address(this));

    if(amountFrozen > 0
      && _daysToThaw > 0
      && token.transferFrom(msg.sender, address(this), amountFrozen)) {
      thawBy[msg.sender] = now + (_daysToThaw * 1 days);
      balances[msg.sender] += amountFrozen;
      AllowanceFrozen(msg.sender, _daysToThaw, amountFrozen);
    } else {
      throw;
    }
  }

  function extendFreezeBy (uint _days) public {
    if(_days > 0) {
      thawBy[msg.sender] += _days * 1 days;
      FreezeExtended(msg.sender, _days);
    }
  }

  function withdrawBalance () public returns (uint amountWithdrawn) {
    if(now > thawBy[msg.sender]) {
      amountWithdrawn = balances[msg.sender];
      balances[msg.sender] = 0;
      token.transfer(msg.sender, amountWithdrawn);
      BalanceWithdrawn(msg.sender, amountWithdrawn);
    } else {
      return 0;
    }
  }

  function balanceOf (address _from) public constant returns (uint balance) {
    return balances[_from];
  }

  function frozenUntil (address _from) public constant returns (uint thawDate) {
    return thawBy[_from];
  }

  event AllowanceFrozen(address _owner, uint _daysToThaw, uint _amountFrozen);
  event FreezeExtended(address _owner, uint _days);
  event BalanceWithdrawn(address _owner, uint _amountWithdrawn);

  mapping(address => uint) thawBy;
  mapping(address => uint) balances;
  StandardToken public token;
}
