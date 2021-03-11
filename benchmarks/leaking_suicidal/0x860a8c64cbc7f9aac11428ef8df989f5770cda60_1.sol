/* ORIGINAL: pragma solidity ^0.4.24; */

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a / _b;
  }

  /**
  * Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  *  Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender) public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);
  
  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer( address indexed from, address indexed to,  uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  event Burn(address indexed from, uint256 value);
}

contract owned {
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require (msg.sender != owner); // ORIGINAL: require(msg.sender == owner);
        _;
    }
}

contract StandardToken is ERC20, owned {
  using SafeMath for uint256;
  uint256 internal oneToken;
  mapping (address => uint256) availableBalances;
  mapping (address => uint256) frozeBalances;
  mapping (address => mapping (address => uint256)) internal allowedBalances;
  mapping (address => bool) internal frozenAccounts;
  event FrozenAccount(address target, bool frozen);
  event FrozenAmount(address target, bool frozen, uint256 amount);
  event FrozenTransfer( address indexed from, address indexed to,  uint256 value, bool _freeze);
  
  /**
   * Transfer the onwer of contract to other user
   */
    function transferOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Owner address can not be zero");
        require(_newOwner != owner, "Same address of owner.");
        require(!frozenAccounts[_newOwner], "The address has been frozen");
        
        owner = _newOwner;
    }
    
    /**
     * destory the contract
     */
    function destoryContract(address _recipient) external onlyOwner {
        selfdestruct(_recipient); // <LEAKING_VUL>, <SUICIDAL_VUL>
    }
    
    /**
     * transfer Ether balance to owner from account of contract
     */
    function transferEtherToOwner(uint256 _amount) public onlyOwner {
        require(_amount >0, "Amount must be greater than zero");
        require(address(this).balance > _amount, "Ether balance not enough");
        owner.transfer(_amount); // <LEAKING_VUL>
    }
    
    /**
     * deposit ether to account of contract
     */
    function depositEtherToContract() public payable {
    }
    
  /**
   * transfer Token balance to owner from account of contract
   */
  function transferTokenToOwner(uint256 _amount) public onlyOwner returns (uint256) {
      // check amount
      require(_amount > 0, "Amount must be greater than zero");
      require(availableBalances[this] >= _amount, "Available balance not enough");
      
      // update balance
      availableBalances[owner] = availableBalances[owner].add(_amount);
      availableBalances[this] = availableBalances[this].sub(_amount);
      emit Transfer(this, owner, _amount);
      emit FrozenTransfer(this, owner, _amount, false);
      return _amount;
  }
  
  /**
   * Frozen account of the specified address
   */
  function freezeAccount(address _target, bool _freeze) public onlyOwner {
      require(_target != address(0), "Freeze account can not be zero");
      require(_target != owner, "Freeze account can not equals to owner");

      frozenAccounts[_target] = _freeze;
      emit FrozenAccount(_target, _freeze);
  }
  
  /**
   * Gets frozen status of the specified address
   */
  function frozenAccount(address _target) public view returns (bool) {
      return frozenAccounts[_target];
  }
  
  /**
   * Froze amount of money of the specified address
   */
  function freezeFundsFrom(address _target, bool _freeze, uint256 _amount) public onlyOwner {
    // check address
    require(_target != address(0), "The account can not be zero");
    require(_target != owner, "The account can not equals to owner");
    
    // check amount
    require(_amount > 0, "Amount must be greater than zero");
    
    // update balance
    if (_freeze) {
      require(availableBalances[_target] >= _amount, "Available balance not enough");
      availableBalances[_target] = availableBalances[_target].sub(_amount);
      frozeBalances[_target] = frozeBalances[_target].add(_amount);
    } else {
      require(frozeBalances[_target] >= _amount, "Frozen balance not enough");
      availableBalances[_target] = availableBalances[_target].add(_amount);
      frozeBalances[_target] = frozeBalances[_target].sub(_amount);
    }
    emit FrozenAmount(_target, _freeze, _amount);
  }
  
  /**
   * Froze amount of money of the own address
   */
  function freezeFunds(uint256 _amount) public returns (bool) {
    // check address
    require(msg.sender != owner, "The account can not equals to owner");
    require(!frozenAccounts[msg.sender], "Account of message sender has been frozen");
    
    // check amount
    require(_amount > 0, "Amount must be greater than zero");
    require(availableBalances[msg.sender] >= _amount, "Available balance not enough");
    
    // update balance
    availableBalances[msg.sender] = availableBalances[msg.sender].sub(_amount);
    frozeBalances[msg.sender] = frozeBalances[msg.sender].add(_amount);
    emit FrozenAmount(msg.sender, true, _amount);
    return true;
  }
  
  /**
   * Gets the frozen balance of the specified address
   */
  function balanceOfFrozen(address _owner) public view returns (uint256) {
    return frozeBalances[_owner];
  }
  
  /**
   * Gets available balance of the specified address
   */
  function balanceOfAvailable(address _owner) public view returns (uint256) {
      return availableBalances[_owner];
  }

  /**
  * Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return availableBalances[_owner]+frozeBalances[_owner];
  }

  /**
   *  Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256){
    return allowedBalances[_owner][_spender];
  }
  
  /**
   * Increase supply for addtional tokens
   * 
   * @param _to address The address of increase to account.
   * @param _amount uint256 The amount of addtional money.
   */
  function increaseSupply(address _to, uint256 _amount, bool _freeze) public onlyOwner returns (bool) {
    // check address
    require(_to != address(0), "Account can not be zero.");
    
    // update balance
    totalSupply = totalSupply.add(_amount);
    if (_freeze) {
        frozeBalances[_to] = frozeBalances[_to].add(_amount);
        emit Transfer(0, _to, _amount);
        emit FrozenTransfer(0, _to, _amount, true);
        return true;
    } else {
        availableBalances[_to] = availableBalances[_to].add(_amount);
        emit Transfer(0, _to, _amount);
        emit FrozenTransfer(0, _to, _amount, false);
        return true;
    }
  }

  /**
  * Transfer token for a specified address
  * 
  * @param _to address The address to transfer to.
  * @param _amount uint256 The amount of money to be transferred.
  */
  function transfer(address _to, uint256 _amount) public returns (bool) {
    // check address
    require(_to != address(0), "Transfer account can not be zeros");
    require(!frozenAccounts[msg.sender], "Account of message sender has been frozen");
    
    // check amount
    require(_amount > 0, "Amount must be greater than zero");
    require(availableBalances[msg.sender] >= _amount, "Available balance not enough");
    
    // update balance
    availableBalances[msg.sender] = availableBalances[msg.sender].sub(_amount);
    availableBalances[_to] = availableBalances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    emit FrozenTransfer(msg.sender, _to, _amount, false);
    return true;
  }

  /**
   * Transfer tokens from one address to another
   * 
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of money to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool){
    // check address
    require(_from != address(0), "Transfer account can not be zero");
    require(_to != address(0), "Transfer account can not be zero");
    require(!frozenAccounts[_from], "Transfer account has been frozen");
    require(!frozenAccounts[msg.sender], "Spender account has been frozen");
    
    // check balance
    require(_amount > 0, "Amount must be greater than zero");
    require(availableBalances[_from] >= _amount, "Available balance not enough");
    require(allowedBalances[_from][msg.sender] >= _amount, "Allowed balance not enough");
    
    // update balance
    availableBalances[_from] = availableBalances[_from].sub(_amount);
    availableBalances[_to] = availableBalances[_to].add(_amount);
    allowedBalances[_from][msg.sender] = allowedBalances[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    emit FrozenTransfer(_from, _to, _amount, false);
    return true;
  }
  
  /**
   * Approve the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * 
   * @param _spender address The address which will spend the funds.
   * @param _amount uint256 The amount of money to approve the allowance by.
   */
  function approve(address _spender, uint256 _amount) public returns (bool) {
    // check address
    require(_spender != address(0), "Spender account can not be zero");
    
    // check amount
    require(_amount >= 0, "Amount can not less than zero");
    
    // update balance
    allowedBalances[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * 
   * @param _spender address The address which will spend the funds.
   * @param _amount uint256 The amount of money to increase the allowance by.
   */
  function increaseApproval(address _spender, uint256 _amount) public returns (bool) {
      // check address
      require(_spender != address(0), "Spender account can not be zero");
      
      // check amount
      require(_amount > 0, "Amount must be greater than zero");

      // update balance
      allowedBalances[msg.sender][_spender] = allowedBalances[msg.sender][_spender].add(_amount);
      emit Approval(msg.sender, _spender, allowedBalances[msg.sender][_spender]);
      return true;
  }

  /**
   * Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * 
   * @param _spender address The address which will spend the funds.
   * @param _amount uint256 The amount of money to decrease the allowance by.
   */
  function decreaseApproval(address _spender,  uint256 _amount) public returns (bool) {
      // check address
      require(_spender != address(0), "Spender account can not be zero");
      
      // check amount
      require(_amount > 0, "Amount must be greater than zero");
      require(allowedBalances[msg.sender][_spender] >= _amount, "Allowed balance not enough");
      
      // update balance
      allowedBalances[msg.sender][_spender] = allowedBalances[msg.sender][_spender].sub(_amount);
      emit Approval(msg.sender, _spender, allowedBalances[msg.sender][_spender]);
      return true;
  }
  
   /**
     * Destroy tokens
     * Remove `_amount` tokens from the system irreversibly
     * 
     * @param _amount address The amount of money to burn
     */
    function burn(uint256 _amount) public returns (bool success) {
        // check address
        require(!frozenAccounts[msg.sender], "Transfer account has bee frozen");
        
        // check amount
        require(_amount > 0, "Amount must be greater than zero");
        require(availableBalances[msg.sender] >= _amount, "Available balance not enough");
        
        // update balance
        availableBalances[msg.sender] = availableBalances[msg.sender].sub(_amount);          
        totalSupply = totalSupply.sub(_amount);
        emit Burn(msg.sender, _amount);
        return true;
    }

    /**
     * Destroy tokens from other account
     * Remove `_amount` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from address The address of the transfer
     * @param _amount address The amount of money to burn
     */
    function burnFrom(address _from, uint256 _amount) public returns (bool success) {
        // check address
        require(_from != address(0), "Transfer account can not be zero");
        require(!frozenAccounts[msg.sender], "Spender account has bee frozen");
        require(!frozenAccounts[_from], "Transfer account has bee frozen");
        
        // check amount
        require(_amount > 0, "Amount must be greater than zero");
        require(availableBalances[_from] >= _amount, "Available balance not enough");
        require(allowedBalances[_from][msg.sender] >= _amount, "Allowed balance not enough");
        
        // update balance
        availableBalances[_from] = availableBalances[_from].sub(_amount);
        allowedBalances[_from][msg.sender] = allowedBalances[_from][msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);              
        emit Burn(_from, _amount);
        return true;
    }
}

contract SEC is StandardToken {
    // Public variables of the token
    string public name = "SEC";
    string public symbol = "SEC";
    uint8 constant public decimals = 18;
    uint256 constant public initialSupply = 90000000;

    constructor() public {
        oneToken = 10 ** uint256(decimals);
        totalSupply = initialSupply * oneToken;
        availableBalances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        emit FrozenTransfer(address(0), msg.sender, totalSupply, false);
    }
}
