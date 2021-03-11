/* ORIGINAL: pragma solidity ^0.5.1; */


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


contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function transfer(address to, uint value, bytes memory data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


/**
 * @title Contract that will work with ERC223 tokens.
 * source: https://github.com/ethereum/EIPs/issues/223
 */
interface ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param from  Token sender address.
     * @param value Amount of tokens.
     * @param data  Transaction metadata.
     */
    function tokenFallback( address from, uint value, bytes  data ) external;
}


/**
 * @title Ownership
 * @author Prashant Prabhakar Singh
 * @dev Contract that allows to hande ownership of contract
 */
contract Ownership {

    address public owner;
    event LogOwnershipTransferred(address indexed oldOwner, address indexed newOwner);


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    /**
     * @dev Transfers ownership of contract to other address
     * @param _newOwner address The address of new owner
     */
    function transferOwnership(address _newOwner)
        public
        /* ORIGINAL: onlyOwner */
    {
        require(_newOwner != address(0), "Zero address not allowed");
        address oldOwner = owner;
        owner = _newOwner;
        emit LogOwnershipTransferred(oldOwner, _newOwner);
    }

}

/**
 * @title Freezable
 * @author Prashant Prabhakar Singh
 * @dev Contract that allows freezing/unfreezing an address or complete contract
 */
contract Freezable is Ownership {

    bool public emergencyFreeze;
    mapping (address => bool) public frozen;

    event LogFreezed(address indexed target, bool indexed freezeStatus);
    event LogEmergencyFreezed(bool emergencyFreezeStatus);

    modifier unfreezed(address _account) {
        require(!frozen[_account], "Account is unfreezed");
        _;
    }

    modifier noEmergencyFreeze() {
        require(!emergencyFreeze, "Account is freezed");
        _;
    }

    /**
     * @dev Freezes or unfreezes an addreess
     * this does not check for previous state before applying new state
     * @param _target the address which will be feeezed.
     * @param _freeze boolean status. Use true to freeze and false to unfreeze.
     */
    function freezeAccount (address _target, bool _freeze)
        public
        onlyOwner
    {
        require(_target != address(0), "Zero address not allowed");
        frozen[_target] = _freeze;
        emit LogFreezed(_target, _freeze);
    }

   /**
     * @dev Freezes or unfreezes the contract
     * this does not check for previous state before applying new state
     * @param _freeze boolean status. Use true to freeze and false to unfreeze.
     */
    function emergencyFreezeAllAccounts (bool _freeze)
        public
        onlyOwner
    {
        emergencyFreeze = _freeze;
        emit LogEmergencyFreezed(_freeze);
    }
}


/**
 * @title Standard Token
 * @author Prashant Prabhakar Singh
 * @dev A Standard Token contract that follows ERC-223 standard
 */
contract StandardToken is ERC223Interface, Freezable {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    uint public currentSupply;

    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint) ) private  allowed;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor () public {
        name = 'CNEXCHANGE';
        symbol = 'CNEX';
        decimals = 8;
        totalSupply = 400000000 * ( 10 ** decimals ); // 400 million
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     *   Compitable wit ERC-20 Standard
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value)
        public
        unfreezed(_to)
        unfreezed(msg.sender)
        noEmergencyFreeze()
    {
        bytes memory _data;
        _transfer223(msg.sender, _to, _value, _data);
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes memory _data)
        public
        unfreezed(_to)
        unfreezed(msg.sender)
        noEmergencyFreeze()
    {
        _transfer223(msg.sender, _to, _value, _data);
    }

    /**
     * @dev Utility method to check if an address is contract address
     *
     * @param _addr address which is being checked.
     * @return true if address belongs to a contract else returns false
     */
    function isContract( address _addr )
        private
        view
        returns (bool)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return (length > 0);
    }

    /**
     * @dev To change the approve amount you first have to reduce the addresses
     * allowance to zero by calling `approve(_spender, 0)` if it is not
     * already 0 to mitigate the race condition described here
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Recommended is to use increase approval and decrease approval instead
     *
     * Requires either that _value of allwance is 0
     * @param _spender address who is allowed to spend
     * @param _value the no of tokens spender can spend
     * @return true if everything goes well
     */
    function approve(address _spender, uint _value)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success)
    {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0), "Approval needs to be 0 first");
        require(_spender != msg.sender, "Can not approve to self");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev increases current allowance
     *
     * @param _spender address who is allowed to spend
     * @param _addedValue the no of tokens added to previous allowance
     * @return true if everything goes well
     */
    function increaseApproval(address _spender, uint _addedValue)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success)
    {
        require(_spender != msg.sender, "Can not approve to self");
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev decrease current allowance
     * @param _spender address who is allowed to spend
     * @param _subtractedValue the no of tokens deducted to previous allowance
     * If _subtractedValue is greater than prev allowance, allowance becomes 0
     * @return true if everything goes well
     */
    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        unfreezed(_spender)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success)
    {
        require(_spender != msg.sender, "Can not approve to self");
        uint oldAllowance = allowed[msg.sender][_spender];
        if (_subtractedValue > oldAllowance) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldAllowance.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from address The address from which you want to send tokens.
     * @param _to address The address to which you want to transfer tokens.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint _value)
        public
        unfreezed(_to)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success)
    {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        bytes memory _data;
        _transfer223(_from, _to, _value, _data);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from address The address from which you want to send tokens.
     * @param _to address The address to which you want to transfer tokens.
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data bytes Transaction metadata.
     */
    function transferFrom(address _from, address _to, uint _value, bytes memory _data)
        public
        unfreezed(_to)
        unfreezed(msg.sender)
        noEmergencyFreeze()
        returns (bool success)
    {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer223(_from, _to, _value, _data);
        return true;
    }


    /**
     * @dev Function that burns an amount of the token of a sender.
     * reduces total and current supply.
     * only owner is allowed to burn tokens.
     *
     * @param _value The amount that will be burn.
     */
    function burn(uint256 _value)
        public
        unfreezed(msg.sender)
        noEmergencyFreeze()
        onlyOwner
        returns (bool success)
    {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        currentSupply = currentSupply.sub(_value);
        bytes memory _data;
        emit Transfer(msg.sender, address(0), _value, _data);
        return true;
    }

  
    /**
     * @dev Gets the balance of the specified address.
     * @param _tokenOwner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _tokenOwner) public view returns (uint) {
        return balances[_tokenOwner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _tokenOwner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _tokenOwner, address _spender) public view returns (uint) {
        return allowed[_tokenOwner][_spender];
    }

    /**
     * @dev Function to withdraw any accidently sent ERC20 or 223 Token.
     * the value should be pre-multiplied by decimals of token wthdrawan
     * @param _tokenAddress address The contract address of ERC20 token.
     * @param _value uint amount to tokens to be withdrawn
     */
    function transferAnyERC20Token(address _tokenAddress, uint _value)
        public
        onlyOwner
    {
        ERC223Interface(_tokenAddress).transfer(owner, _value);
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _from Sender address.
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function _transfer223(address _from, address _to, uint _value, bytes memory _data)
        private
    {
        require(_to != address(0), "Zero address not allowed");
        require(balances[_from] >= _value, "Insufficient balance");
        uint balBeforeTransfer = balances[_from].add(balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        uint balAfterTransfer = balances[_from].add(balances[_to]);
        assert(balBeforeTransfer == balAfterTransfer);
        emit Transfer(_from, _to, _value, _data); // ERC223-compat version
    }

}

/**
 * @title CNEX Token
 * @author Prashant Prabhakar Singh
 * @dev CNEX implementation of ERC-223 standard token
 */
contract CNEXToken is StandardToken {

    uint public icoFunds;
    uint public consumerProtectionFund;
    uint public ecoSystemDevelopmentAndOperationFund;
    uint public teamAndFounderFund;

    bool public consumerProtectionFundAllocated = false;
    bool public ecoSystemDevelopmentAndOperationFundAllocated = false;
    bool public teamAndFounderFundAllocated = false;

    uint public tokenDeploymentTime;

    constructor() public StandardToken(){
        owner = msg.sender;
        icoFunds = 200000000 * (10 ** decimals); // 200 million
        consumerProtectionFund = 60000000 * (10 ** decimals); // 60 million
        ecoSystemDevelopmentAndOperationFund = 100000000 * (10 ** decimals); // 100 million
        teamAndFounderFund = 40000000 * (10 ** decimals); // 40 million
        tokenDeploymentTime = now;
        _mint(msg.sender, icoFunds);
    }
    
    /**
     * @dev Function to mint tokens allocated for consumer
     * protection to owner address. Owner then sends them
     * to responsible parties
     */
    function allocateConsumerProtectionFund()
        public
        onlyOwner
    {
        require(!consumerProtectionFundAllocated, "Already allocated");
        consumerProtectionFundAllocated = true;
        _mint(owner, consumerProtectionFund);
    }

    /**
     * @dev Function to mint tokens allocated for Ecosystem development
     * and operations to owner address. Owner then sends them
     * to responsible parties
     */
    function allocateEcoSystemDevelopmentAndOperationFund()
        public
        onlyOwner
    {
        require(!ecoSystemDevelopmentAndOperationFundAllocated, "Already allocated");
        ecoSystemDevelopmentAndOperationFundAllocated = true;
        _mint(owner, ecoSystemDevelopmentAndOperationFund);
    }
    
    /**
     * @dev Function to mint tokens allocated for team
     * and founders to owner address. Owner then sends them
     * to responsible parties.
     * Tokens are locked for 1 year and can be claimed after 1 year
     * from date of deployment
     */
    function allocateTeamAndFounderFund()
        public
        onlyOwner
    {
        require(!teamAndFounderFundAllocated, "Already allocated");
        require(now > tokenDeploymentTime + 365 days, "Vesting period not over yet");
        teamAndFounderFundAllocated = true;
        _mint(owner, teamAndFounderFund);
    }

    /**
     * @dev Function to kill the contract. Do transfer all tokens from contract
     * before executing this function.
     * @param _code uint that prevents accidental calling of the function
     */
    function kill(uint _code)
        public
        onlyOwner
    {
        require(_code == 1234567890, "Invalid code");
        selfdestruct(address(uint160(owner))); // <SUICIDAL_VUL>, <LEAKING_VUL>
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _value The amount of tokens to mint.
     */
    function _mint(address _to, uint _value)
        private
        onlyOwner
    {
        require(currentSupply.add(_value) <= totalSupply, "Exceeds total supply");
        balances[_to] = balances[_to].add(_value);
        currentSupply = currentSupply.add(_value);
        bytes memory _data;
        emit Transfer(address(0), _to, _value, _data);
    }
    
}
