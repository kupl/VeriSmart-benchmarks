/* ORIGINAL: pragma solidity 0.5.2; */ /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_

// ----------------------------------------------------------------------------
// 'CENT' Token contract with following features
//      => ERC20 and ERC865 Compliance
//      => Higher degree of control by owner
//      => selfdestruct ability by owner
//      => SafeMath implementation 
//      => Burnable and Minting
//
// Name        : Center Coin
// Symbol      : CENT
// Total supply: 0 (0 Billion)
// Decimals    : 18
//
// Copyright (c) 2019 CENT TOKEN Inc. The MIT Licence.
// ----------------------------------------------------------------------------
*/ 

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address public owner;
    
     constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
       require(msg.sender != owner); // ORIGINAL: require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}



//***************************************************************//
//------------------ ERC20 Standard Template -------------------//
//***************************************************************//
    
contract TokenERC20 {
    // Public variables of the token
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    bool public safeguard = false;  //putting safeguard on will halt all non-owner functions

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    // This notifies client about approval of the allowance for token transfer to third party
    event Approval(address indexed from, address indexed spender, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply.mul(10**decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;            // All the tokens will be sent to owner
        name = tokenName;                               // Set the name for display purposes
        symbol = tokenSymbol;                           // Set the symbol for display purposes
        emit Transfer(address(0), msg.sender, totalSupply);// Emit event to log this transaction
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(!safeguard);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

  
    
    
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value);                   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);              // Update totalSupply
        emit  Burn(_from, _value);
        return true;
    }
    
}

//****************************************************************************//
//---------------------  CENT TOKEN MAIN CODE STARTS HERE ---------------------//
//****************************************************************************//
    
contract CENTTOKEN is owned, TokenERC20 {
    
    
    /***************************************/
    /* Custom Code for the ERC20 CENT TOKEN */
    /***************************************/

    /* Public variables of the token */
    string private tokenName = "Center Coin";
    string private tokenSymbol = "CENT";
    uint256 private initialSupply = 0;  //0 Billion
    
    
    /* Records for the fronzen accounts */
    mapping (address => bool) public frozenAccount;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    
    /**
    * Sell token is enabled
    */
    bool public SellTokenAllowed;
    
    /**
    * Buy token is enabled
    */
    bool public BuyTokenAllowed;
    
    /**
    * This notifies sell token status.
    */
    event SellTokenAllowedEvent(bool isAllowed);
    
    /**
    * This notifies buy token status.
    */
    event BuyTokenAllowedEvent(bool isAllowed);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {
        
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
    
    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
    }


    /****************************************/
    /* Custom Code for the ERC865 CENT TOKEN */
    /****************************************/

     /* Nonces of transfers performed */
    mapping(bytes32 => bool) transactionHashes;
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    
    
      /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount)  public onlyOwner  {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(this), target, mintedAmount);
    }
    
    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintEthToken(address target, address owner,uint mintedAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s)  payable public onlyOwner  {
        require(msg.value > 0);
        
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', owner, mintedAmount,nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == owner, 'Invalid _from address');

        
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(this), target, mintedAmount);
    }
    
     /**
     * @notice Submit a presigned transfer
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0), 'Invalid _to address');
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', address(this), _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == _from, 'Invalid _from address');

        balanceOf[from] = balanceOf[from].sub(_value).sub(_fee);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
	
	
     /**
     * @notice Submit a presigned approval
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('approvePreSigned', address(this), _spender, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = _value;
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }
    
     /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @param _spender address The address which will spend the funds.
     * @param _addedValue uint256 The amount of tokens to increase the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function increaseApprovalPreSigned(
        address _spender,
        uint256 _addedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('increaseApprovalPreSigned', address(this), _spender, _addedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
      address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = allowance[from][_spender].add(_addedValue);
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, allowance[from][_spender]);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowance[from][_spender], _fee);
        return true;
    }
    
     /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender address The address which will spend the funds.
     * @param _subtractedValue uint256 The amount of tokens to decrease the allowance by.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function decreaseApprovalPreSigned(
        address _spender,
        uint256 _subtractedValue,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('decreaseApprovalPreSigned', address(this), _spender, _subtractedValue, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        if (_subtractedValue > allowance[from][_spender]) {
            allowance[from][_spender] = 0;
        } else {
            allowance[from][_spender] = allowance[from][_spender].sub(_subtractedValue);
        }
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _subtractedValue);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, allowance[from][_spender], _fee);
        return true;
    }
     /**
     * @notice Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferFromPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][spender] = allowance[_from][spender].sub(_value);
        balanceOf[spender] = balanceOf[spender].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }
     
     
     /**
    *  function for Buy Token
    */
    
    function buy(address owner,uint tstCount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) payable public returns (uint amount){
          require(msg.value > 0);
          
          bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', owner, tstCount,nonce));
          require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
          address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from == owner, 'Invalid _from address');
	      require(BuyTokenAllowed, "Buy Token is not allowed");   
	      
          amount = tstCount;
          balanceOf[address(this)] -= amount;                        
          balanceOf[msg.sender] += amount; 
          transactionHashes[hashedTx] = true;
          emit Transfer(address(this), from ,amount);
          return amount;
    }
    
      
    /**
    *  function for Sell Token
    */
    function sell(address owner,uint tstCount, uint etherAmount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public returns (uint amount){
        
          bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', owner, tstCount, nonce));
          require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
          address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
          require(from == owner, 'Invalid _from address');
          
          require(balanceOf[msg.sender] >= tstCount,"Checks if the sender has enough to sell");        
          require(SellTokenAllowed,"Sell Token is not allowed");  
                                                                
        
          balanceOf[address(this)] = balanceOf[address(this)].add(tstCount);                          
          balanceOf[msg.sender] = balanceOf[msg.sender].sub(tstCount);                               
        
        
          transactionHashes[hashedTx] = true;
          msg.sender.transfer(etherAmount);                                                        
          emit Transfer(msg.sender, address(this), tstCount);
         
          return etherAmount;
    }
    
     /**
    * Enable Sell Token
    */
    function enableSellToken() onlyOwner public {
        SellTokenAllowed = true;
        emit SellTokenAllowedEvent (true);
    }

    /**
    * Disable Sell Token
    */
    function disableSellToken() onlyOwner public {
        SellTokenAllowed = false;
        emit SellTokenAllowedEvent (false);
    }
    
    /**
    * Enable Buy Token
    */
    function enableBuyToken() onlyOwner public {
        BuyTokenAllowed = true;
        emit BuyTokenAllowedEvent (true);
    }

    /**
    * Disable Buy Token
    */
    function disableBuyToken() onlyOwner public {
        BuyTokenAllowed = false;
        emit BuyTokenAllowedEvent (false);
    }
	    
	    
    function testSender(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        view
        returns (address)
    {
        bytes32 hashedTx = keccak256(abi.encodePacked(address(this), _to, _value, _fee, _nonce));
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
    }





    /********************************/
    /*  Code for helper functions   */
    /********************************/
      
    //Just in case, owner wants to transfer Ether from contract to owner address
    function manualWithdrawEther() public onlyOwner{
        address(owner).transfer(address(this).balance); // <LEAKING_VUL>
    }
    
    //Just in case, owner wants to transfer Tokens from contract to owner address
    //tokenAmount must be in WEI
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
        _transfer(address(this), msg.sender, tokenAmount);
    }
    
    //selfdestruct function. just in case owner decided to destruct this contract.
    function destructContract() public onlyOwner{
        selfdestruct(owner); // <LEAKING_VUL>, <SUICIDAL_VUL>
    }
    
    /**
     * Change safeguard status on or off
     *
     * When safeguard is true, then all the non-owner functions will stop working.
     * When safeguard is false, then all the functions will resume working back again!
     */
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    


}
