/**
*Submitted for verification at Etherscan.io on 2019-12-11
* http://blockchainbits.in/
*/

// ORIGINAL: pragma solidity 0.4.18;


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

  contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address _owner)public view returns (uint256 balance);
  function allowance(address _owner, address _spender)public view returns (uint remaining);
  function transferFrom(address _from, address _to, uint _amount)public returns (bool ok);
  function approve(address _spender, uint _amount)public returns (bool ok);
  function transfer(address _to, uint _amount)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _amount);
  event Approval(address indexed _owner, address indexed _spender, uint _amount);
}

contract ERBIUMCOIN is ERC20
{
    using SafeMath for uint256;
    string public constant symbol = "ERB";
    string public constant name = "ErbiumCoin";
    uint8 public constant decimals = 10;
    // 10 million total supply // muliplies dues to decimal precision
    uint256 public _totalSupply = 10000000 * 10 **10;     // 10 million supply           
    // Balances for each account
    mapping(address => uint256) balances;   
    // Owner of this contract
    address public owner;
    
    mapping (address => mapping (address => uint)) allowed;
    
    uint256 public supply_increased;
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    event LOG(string e,uint256 value);
    
    modifier onlyOwner() {
        if (msg.sender == owner) { // ORIGINAL: if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    function ERBIUMCOIN() public
    {
        owner = msg.sender;
        balances[owner] = 2000000 * 10 **10; // 2 million token with company/owner , multiplied due to decimal precision
    
        supply_increased += balances[owner];
    }
    
    // can accept ether
    
    function () public payable {
  
    }

    // to be called by owner after an year review
    function mineToken(uint256 supply_to_increase) public onlyOwner
    {
        require((supply_increased + supply_to_increase) <= _totalSupply);
        supply_increased += supply_to_increase;
        
        balances[owner] += supply_to_increase;
        Transfer(0, owner, supply_to_increase);
    }
    
    
    // total supply of the tokens
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalSupply;
    }
  
    //  balance of a particular account
    function balanceOf(address _owner)public view returns (uint256 balance) {
        return balances[_owner];
    }
  
    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount)public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount 
            && _amount >= 0
            && balances[_to] + _amount >= balances[_to]);
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
    }
  
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )public returns (bool success) {
        require(_to != 0x0); 
        require(balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount >= 0
            && balances[_to] + _amount >= balances[_to]);
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
            }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
  }
  
    //In case the ownership needs to be transferred
  function transferOwnership(address newOwner)public onlyOwner
  {
      require( newOwner != 0x0);
      balances[newOwner] = balances[newOwner].add(balances[owner]);
      balances[owner] = 0;
      owner = newOwner;
  }
  
  // drain ether called by only owner
  function drain() external onlyOwner {
        owner.transfer(this.balance); // <LEAKING_VUL>
    }
    
    // this can be called when there is no furter requirement of contract 
    function kill() external onlyOwner {
        selfdestruct(address(uint160(owner))); // <LEAKING_VUL>, <SUICIDAL_VUL>
    }    
    
    //Below function will convert string to integer removing decimal
  function stringToUint(string s) private pure returns (uint) 
    {
        bytes memory b = bytes(s);
        uint i;
        uint result1 = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if(c == 46)
            {
                // Do nothing --this will skip the decimal
            }
          else if (c >= 48 && c <= 57) {
                result1 = result1 * 10 + (c - 48);
              // usd_price=result;
                
            }
        }
            return result1;
      }
    
}
