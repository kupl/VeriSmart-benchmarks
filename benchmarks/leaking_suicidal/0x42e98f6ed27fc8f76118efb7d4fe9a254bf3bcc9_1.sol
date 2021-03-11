// ORIGINAL: pragma solidity 0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender != owner); // ORIGINAL: require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool public pause = false;

    modifier whenNotPaused() {
        require(!pause);
        _;
    }

    modifier whenPaused() {
        require(pause);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        pause = true;
        Paused();
    }

    function unpause() onlyOwner whenPaused public {
        pause = false;
        Unpaused();
    }
}

contract Freezable is Ownable {
    mapping (address => bool) public frozenAccount;

    event Frozen(address indexed account, bool freeze);

    function freeze(address _acct) onlyOwner public {
        frozenAccount[_acct] = true;
        Frozen(_acct, true);
    }

    function unfreeze(address _acct) onlyOwner public {
        frozenAccount[_acct] = false;
        Frozen(_acct, false);
    }
}

contract StandardToken is ERC20, Pausable, Freezable {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(!frozenAccount[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(!frozenAccount[_from]);

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract GAWToken is StandardToken {

    string public name = "Galaxy World Coin";
    string public symbol = "GAW";
    uint public decimals = 18;

    uint public constant TOTAL_SUPPLY    = 6000000000e18;
    address public constant WALLET_GAW   = 0x0A97a0aC50386283288518908eC547e0471f8308; 

    mapping(address => uint256) public addressLocked;
    mapping(address => uint256) public addressLockupDate;

    event UpdatedLockingState(address indexed to, uint256 value, uint256 date);

    modifier canTransfer(address _sender, uint256 _value) {
        require(_sender != address(0));

        uint256 remaining = balances[_sender].sub(_value);
        uint256 totalLockAmt = 0;

        if (addressLocked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount(_sender));
        }

        require(remaining >= totalLockAmt);

        _;
    }

    function GAWToken() public {
        balances[msg.sender] = TOTAL_SUPPLY;
        totalSupply = TOTAL_SUPPLY;

        transfer(WALLET_GAW, TOTAL_SUPPLY);
    }

    function getLockedAmount(address _address)
        public
		view
		returns (uint256)
	{
        uint256 lockupDate = addressLockupDate[_address];
        uint256 lockedAmt = addressLocked[_address];


        uint256 diff = (now - lockupDate) / 2592000; // month diff
        uint256 partition = 10;

        if (diff >= partition) 
            return 0;
        else
            return lockedAmt.mul(partition-diff).div(partition);
	
        return 0;
    }

    function setLockup(address _address, uint256 _value, uint256 _lockupDate)
        public
        onlyOwner
    {
        require(_address != address(0));

        addressLocked[_address] = _value;
        addressLockupDate[_address] = _lockupDate;
        UpdatedLockingState(_address, _value, _lockupDate);
    }

    function transfer(address _to, uint _value)
        public
        canTransfer(msg.sender, _value)
		returns (bool success)
	{
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        public
        canTransfer(_from, _value)
		returns (bool success)
	{
        return super.transferFrom(_from, _to, _value);
    }

    function() payable public { }

    function withdrawEther() public {
        if (address(this).balance > 0)
		    owner.send(address(this).balance); // <LEAKING_VUL>
	}

    function withdrawSelfToken() public {
        if(balanceOf(this) > 0)
            this.transfer(owner, balanceOf(this));
    }

    function close() public onlyOwner {
        selfdestruct(owner); // <LEAKING_VUL>, <SUICIDAL_VUL>
    }
}
