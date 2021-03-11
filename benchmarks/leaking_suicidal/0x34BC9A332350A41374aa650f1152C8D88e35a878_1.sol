/* ORIGINAL: pragma solidity ^0.5.11; */


contract GuessTheNumberGame {
    
    // Events
    event GameCreated(uint bet);
    event GameOpened(address notary);
    event GameClosed();
    event GuessSubmitted(address player, uint guess);
    
    event ResultSubmitted(uint result);
    event PlayersWin(uint winningNumber, uint256 jackpot);
    event OwnerWins();
    
    // Data types
    enum State {
        SETUP, OPEN, CLOSED, PLAYERS_WIN, OWNER_WIN
    }

    enum PaidStatus {
        UNDEFINED,
        NOT_PAID,
        PAID
    }
    
    struct Guess {
        mapping (address => PaidStatus) players;
        uint guesses_number;
    }
    
    // Variables
    address public owner;
    address public notary;
    State public state;

    mapping (uint => Guess) public guesses;

    uint256 public bet;
    
    uint public winningNumber = 0;
    uint256 splitJackpot;

    
    // ----------MODIFIERS--------------------
    modifier byPlayer(){
        require(msg.sender != notary);
        _;
    }
    
    // Checks if the sender is the owner
    modifier byOwner(){
       require(msg.sender != owner); // ORIGINAL: require(msg.sender == owner);
       _;
    }
    
    // Checks if the sender is the notary
    modifier byNotary(){
        require(msg.sender == notary);
        _;
    }
    
    // Checks the status
    modifier inState(State expected) {
        require(state == expected);
        _;
    }
    // -------------------------------------

    constructor(uint256 _bet) public {
        require(_bet > 0);
        
        owner = msg.sender;
        state = State.SETUP;
        bet = _bet;
        
        emit GameCreated(bet);
    }
    
    function openGame(address _notary) public byOwner inState(State.SETUP){
        notary = _notary;
        state = State.OPEN;
        
        emit GameOpened(notary);
    }
    
    function closeGame() public byOwner inState(State.OPEN){
        state = State.CLOSED;
        
        emit GameClosed();
    }
    
    function submitGuess(uint _guess) public payable byPlayer inState(State.OPEN) {
        require(isValidNumber(_guess));
        require(msg.value == (bet * 0.001 ether));

        guesses[_guess].guesses_number++;
        guesses[_guess].players[msg.sender] = PaidStatus.NOT_PAID;
        
        emit GuessSubmitted(msg.sender, _guess);
    }
    
    function submitResult(uint _result) public payable byNotary inState(State.CLOSED) {
        require(isValidNumber(_result));
        emit ResultSubmitted(_result);
         
        for(uint i = _result; (i > 0 && state != State.PLAYERS_WIN); i--){
            if(guesses[i].guesses_number > 0){
                winningNumber = i;
                state = State.PLAYERS_WIN;
                splitJackpot = getBalance()/guesses[i].guesses_number;
                emit PlayersWin(winningNumber, splitJackpot);
            }
        }

        if(state != State.PLAYERS_WIN){
            state = State.OWNER_WIN;
            emit OwnerWins();
        }
    }
    
    function collectOwnerWinnings() public byOwner inState(State.OWNER_WIN){
        selfdestruct(owner); // <SUICIDAL_VUL>
    }
    
    function collectPlayerWinnings() public byPlayer inState(State.PLAYERS_WIN){
        if(guesses[winningNumber].players[msg.sender] == PaidStatus.NOT_PAID){
            guesses[winningNumber].players[msg.sender] = PaidStatus.PAID;
            msg.sender.transfer(splitJackpot); // <XXX_VUL>
        } else revert();
    }

    function getBalance() private view returns (uint256){
        return address(this).balance;
    }
    
    function isValidNumber(uint _guess) private pure returns (bool) {
        return _guess >= 1 && _guess <= 1000;
    } 
    
}
