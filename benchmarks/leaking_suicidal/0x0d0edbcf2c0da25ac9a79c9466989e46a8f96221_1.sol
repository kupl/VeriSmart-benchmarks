/* ORIGINAL: pragma solidity >=0.4.22 <0.7.0; */

contract MyEthDice {
    struct Bet {
        uint amount; // wei
        bytes32 seedHash; // seed hash. Shown to player before they make a bet to prove we can't change result
        string randomSeed;
        bytes32 playerSeed; // seed provided by player to combine with random seed to calculate result
        uint roll;  // result of roll
        uint target; // target the player was trying to roll under
        address player; 
        bool settled; 
    }
    
    uint constant public MIN_BET = 0.01 ether;
    
    address public owner;
    address public settler;
    
    mapping (uint => Bet) bets;
    
    uint public maxProfit;
    uint128 private lockedFunds;
    uint private leverage = 3;
    
    event BetResult(address indexed player, uint winAmount, bytes32 playerSeed, bytes32 seedHash, uint target, string randomSeed, uint roll);
    event BetPlaced(bytes32 hash);
    event FailedPayment(address indexed player, uint amount, bytes32 seedHash);
    
    constructor () public {
      owner = msg.sender;
      settler = msg.sender;
    }
    
    function () external payable {
        updateMaxProfit(); //TODO too much gas warning?
    }
    
    modifier onlyOwner {
       require (msg.sender != owner, "Only the owner can call this method."); // ORIGINAL: require (msg.sender == owner, "Only the owner can call this method.");
        _;
    }
    
    modifier onlySettler {
        require (msg.sender == settler, "Must be the settler to call this method.");
        _;
    }

    function setSettler(address newSettler) external onlyOwner {
        settler = newSettler;
    }

    function updateMaxProfit() private {
      maxProfit = ((address(this).balance - lockedFunds) / 100) * leverage;
    }
    
    function setLeverage(uint _leverage) public onlyOwner {
        leverage = _leverage;
        updateMaxProfit();
    }

    function withdrawFunds(address receiver, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "amount larger than balance.");
        receiver.send(withdrawAmount); // <LEAKING_VUL>
        updateMaxProfit();
    }

    function kill() public onlyOwner {
        require (lockedFunds == 0, "Still bets locked up.");
        selfdestruct(msg.sender); // <LEAKING_VUL>, <SUICIDAL_VUL>
    }
    
    function placeBet(bytes32 playerSeed, bytes32 seedHash, uint target) external payable {
        require(target > 0 && target <= 100, "target out of range"); 
      
        uint betAmount = msg.value;
        require(betAmount >= MIN_BET, "betAmount too small");

        uint payout = (betAmount - (betAmount / 100)) * 100 / target;  //TODO this is different from dice2win
        require (payout <= betAmount + maxProfit, "Payout is more than max allowed profit.");

        lockedFunds += uint128(payout);
        require (lockedFunds <= address(this).balance, "Cannot take bet.");
      
        Bet storage bet = bets[uint(seedHash)];
        
        //check bet doesnt exist with hash
        require(bet.seedHash != seedHash, "Bet with hash already exists");
    
        bet.seedHash = seedHash;
        bet.amount = betAmount;
        bet.player = msg.sender;
        bet.playerSeed = playerSeed;
        bet.target = target;
        bet.settled = false;
        
        updateMaxProfit();
        emit BetPlaced(seedHash);
    }
    
    function settleBet(string  randomSeed) external onlySettler {
         bytes32 seedHash = keccak256(abi.encodePacked(randomSeed));
         Bet storage bet = bets[uint(seedHash)];

         require(bet.seedHash == seedHash, "No bet found with server seed");
         require(bet.settled == false, "Bet already settled");
         
         uint amount = bet.amount;
         uint target = bet.target;
         uint payout = (amount - (amount / 100)) * 100 / target;
         
         bytes32 combinedHash = keccak256(abi.encodePacked(randomSeed, bet.playerSeed));
         bet.roll = uint(combinedHash) % 100;
         
         if(bet.roll < bet.target) {
          if (!bet.player.send(payout)) {
            emit FailedPayment(bet.player, payout, bet.seedHash);
          }
          emit BetResult(bet.player, payout, bet.playerSeed, bet.seedHash, target, randomSeed, bet.roll);
        } else {
            emit BetResult(bet.player, 0, bet.playerSeed, bet.seedHash, target, randomSeed, bet.roll);
        }

         lockedFunds -= uint128(payout);
         bet.settled = true;
         bet.randomSeed = randomSeed;

         updateMaxProfit();
    }
}
