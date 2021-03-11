/* ORIGINAL: pragma solidity ^0.5.11; */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  address public potentialNewOwner;
 
  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() internal {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender != owner); // ORIGINAL: require(msg.sender == owner);
    _;
  }
  function transferOwnership(address _newOwner) external onlyOwner {
    potentialNewOwner = _newOwner;
  }
  function acceptOwnership() external {
    require(msg.sender == potentialNewOwner);
    emit OwnershipTransferred(owner, potentialNewOwner);
    owner = potentialNewOwner;
  }
}

contract CircuitBreaker is Ownable {
    bool public inLockdown;

    constructor () internal {
        inLockdown = false;
    }
    modifier outOfLockdown() {
        require(inLockdown == false);
        _;
    }
    function updateLockdownState(bool state) public{
        inLockdown = state;
    }
}

contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;
  mapping (address => mapping (address => uint256)) allowed;

  function balanceOf(address _owner) view public returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract ITokenRecipient{
    function buyTokenWithMorality(ERC20 _tokenContract, string memory _collectionName, address _sender, uint256 _value) public;
}

contract ExternalContractPayment is ERC20{
  function approveTokenPurchase(string memory _collectionName, address _tokenAddress, uint256 _value) public{
    approve(_tokenAddress, _value);
    ITokenRecipient(_tokenAddress).buyTokenWithMorality(this, _collectionName, msg.sender, _value);
  }
}

contract MintableToken is ERC20{
  function mintToken(address target, uint256 mintedAmount) public returns(bool){
	balances[target] = balances[target].add(mintedAmount);
	totalSupply = totalSupply.add(mintedAmount);
	emit Transfer(address(0), address(this), mintedAmount);
	emit Transfer(address(this), target, mintedAmount);
	return true;
  }
}

contract RecoverableToken is ERC20, Ownable {
  constructor() public {}

  function recoverTokens(ERC20 token) public {
    token.transfer(owner, tokensToBeReturned(token));
  }
  function tokensToBeReturned(ERC20 token) public view returns (uint256) {
    return token.balanceOf(address(this));
  }
}

contract BurnableToken is ERC20 {
  address public BURN_ADDRESS;

  event Burned(address burner, uint256 burnedAmount);
 
  function burn(uint256 burnAmount) public {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    emit Burned(burner, burnAmount);
    emit Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}

contract WithdrawableToken is ERC20, Ownable {
  event WithdrawLog(uint256 balanceBefore, uint256 amount, uint256 balanceAfter);
  
  function withdraw(uint256 amount) public returns(bool){
	require(amount <= address(this).balance);
    address(owner).transfer(amount); // <LEAKING_VUL>
	emit WithdrawLog(address(owner).balance.sub(amount), amount, address(owner).balance);
    return true;
  } 
}

contract Morality is RecoverableToken, BurnableToken, MintableToken, WithdrawableToken, 
  ExternalContractPayment, CircuitBreaker { 
  string public name;
  string public symbol;
  uint256 public decimals;
  address public creator;
  
  event LogFundsReceived(address sender, uint amount);
  event UpdatedTokenInformation(string newName, string newSymbol);

  constructor(uint256 _totalTokensToMint) payable public {
    name = "Morality";
    symbol = "MO";
    totalSupply = _totalTokensToMint;
    decimals = 18;
    balances[msg.sender] = totalSupply;
    creator = msg.sender;
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function() payable external outOfLockdown {
    emit LogFundsReceived(msg.sender, msg.value);
  }
  
  function transfer(address _to, uint256 _value) public outOfLockdown returns (bool success){
    return super.transfer(_to, _value);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public outOfLockdown returns (bool success){
    return super.transferFrom(_from, _to, _value);
  }
  
  function multipleTransfer(address[]  _toAddresses, uint256[]  _toValues) external outOfLockdown returns (uint256) {
    require(_toAddresses.length == _toValues.length);
    uint256 updatedCount = 0;
    for(uint256 i = 0;i<_toAddresses.length;i++){
       if(super.transfer(_toAddresses[i], _toValues[i]) == true){
           updatedCount++;
       }
    }
    return updatedCount;
  }
  
  function approve(address _spender, uint256 _value) public outOfLockdown  returns (bool) {
    return super.approve(_spender, _value);
  }
  
  function setTokenInformation(string  _name, string  _symbol) onlyOwner external {
    require(msg.sender != creator);
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }
  
  function withdraw(uint256 _amount) onlyOwner public returns(bool){
	return super.withdraw(_amount);
  }

  function mintToken(address _target, uint256 _mintedAmount) onlyOwner public returns (bool){
	return super.mintToken(_target, _mintedAmount);
  }
  
  function burn(uint256 _burnAmount) onlyOwner public{
    return super.burn(_burnAmount);
  }
  
  function updateLockdownState(bool _state) onlyOwner public{
    super.updateLockdownState(_state);
  }
  
  function recoverTokens(ERC20 _token) onlyOwner public{
     super.recoverTokens(_token);
  }
  
  function isToken() public pure returns (bool _weAre) {
    return true;
  }

  function deprecateContract() onlyOwner external{
    selfdestruct(creator); // <SUICIDAL_VUL>
  }
}
