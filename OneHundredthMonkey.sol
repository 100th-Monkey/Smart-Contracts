pragma solidity ^0.4.24;

//@dev: comment thoroughly
//@dev: add any functions I listed in the tech spec
//@dev: integrate the solidity samples in the tech spec
//@dev: later, add div functionality
//@dev: later, add referral functionality
//@dev: later, add events 

//LIBRARIES

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "the SafeMath multiplication check failed");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    	require(b > 0, "the SafeMath division check failed");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "the SafeMath subtraction check failed");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "the SafeMath addition check failed");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
	    require(b != 0, "the SafeMath modulo check failed");
	    return a % b;
	 }
}

contract OneHundredthMonkey {

	using SafeMath for uint256;

//STORAGE

	//admin
	address[] public admins;
	address public adminBank;
	uint256 public adminBalance;
	mapping (address => bool) public isAdmin;
	bool public earlyResolveCalled = false;

	//global
	bool public gameActive = false;
	uint256 public miniGamePotRate = 28; //28%
	uint256 public progressivePotRate = 28; //28%
	uint256 public miniGameDivRate = 10; //10%
	uint256 public roundDivRate = 20; //20%
	uint256 public miniGameAirdropRate = 3; //3%
	uint256 public roundAirdropRate = 3; //3%
	uint256 public referralAirdropRate = 3; //3%
	uint256 public adminFeeRate = 5; //5%
	
	//RNG
	bytes32 public hashA;
    bytes32 public hashB;
    uint256 public salt = 0;
    uint256 public RNGblockDelay = 1;

	//mini-game tracking
	uint256 public miniGameCount;
	uint256 public tokensLeft;
	uint256 public processingBegun;
	bool public miniGameProcessing;
	mapping (uint256 => uint256) public miniGameStartTime;
	mapping (uint256 => uint256) public miniGameTokens;
	mapping (uint256 => uint256) public miniGameTokensLeft;
	mapping (uint256 => uint256) public miniGameTokenRangeMin;
	mapping (uint256 => uint256) public miniGameTokenRangeMax;
	mapping (uint256 => uint256) public miniGamePrizeNumber;
	mapping (uint256 => uint256) public miniGameAirdropNumber;
	mapping (uint256 => uint256) public miniGamePrizePot;
	mapping (uint256 => uint256) public miniGameAirdropPot;
	mapping (uint256 => uint256) public miniGameDivs;

	//round tracking
	uint256 public roundCount;
	mapping (uint256 => uint256) public roundStartTime;
	mapping (uint256 => uint256) public roundTokens;
	mapping (uint256 => uint256) public roundTokenRangeMin;
	mapping (uint256 => uint256) public roundTokenRangeMax;
	mapping (uint256 => uint256) public roundPrizeNumber;
	mapping (uint256 => uint256) public roundAirdropNumber;
	mapping (uint256 => uint256) public roundAirdropPot;
	mapping (uint256 => uint256) public roundReferralAirdropPot;
	mapping (uint256 => uint256) public roundPrizePot;
	mapping (uint256 => uint256) public roundDivs;

	//cycle tracking
	uint256 public cycleCount;
	mapping (uint256 => uint256) public cycleStartTime;
	bool public cycleOver = false;
	uint256 public cycleEnded;
	uint256 public progressivePot;

	//tokens
	uint256 public tokenSupply;
	uint256 public currentToken;
	uint256 public tokenPrice = 0.00001 ether;
	uint256 public tokenPriceIncrement = 0.000005 ether;

	//user tracking
	mapping (address => uint256) public userTokens;
	mapping (address => uint256) public userBalance;
	mapping (address => mapping (uint256 => uint256)) public userMiniGameTokens;
	mapping (address => mapping (uint256 => uint256)) public userRoundTokens;
	//@dev check if I can use arrays nested within mappings like this. If not, refactor to use structs with a counter 
	mapping (address => mapping (uint256 => uint256[])) public userMiniGameTokensMin;
	mapping (address => mapping (uint256 => uint256[])) public userMiniGameTokensMax;
	mapping (address => uint256) public userLastMiniGameInteractedWith;
	mapping (address => uint256) public userLastRoundInteractedWith;
	mapping (address => uint256) public userLastMiniGameChecked;
	mapping (address => uint256) public userLastRoundChecked;
	mapping (address => bool) public userCycleChecked;


//CONSTRUCTOR

	constructor(address _adminBank) public {
		//set dev bank address and admins
		adminBank = _adminBank;
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
	}


//MODIFIERS

	modifier onlyAdmins() {
		require (isAdmin[msg.sender] == true, "you must be an admin");
		_;
	}

	modifier onlyHumans() { 
        require (msg.sender == tx.origin, "you cannot use a contract"); 
        _; 
    }

    modifier gameOpen() {
    	require (gameActive == true);
    	if (miniGameProcessing == true) {
    		require (block.number > processingBegun.add(3));
    	}
    	_;
    }
    

//EVENTS

	//add events for any state change

//ADMIN FUNCTIONS

	function devWithdraw() public onlyAdmins() onlyHumans() {
		uint256 balance = adminBalance;
		adminBalance = 0;
		adminBank.transfer(balance);

		//emit event
	}

	function startCycle() public onlyAdmins() onlyHumans() {
		require (gameActive == false && cycleCount == 0);
		gameActive = true;

		cycleStart();
		roundStart();
		miniGameStart();

		//emit event

	}

	function addAdmin(address _newAdmin) public onlyAdmins() onlyHumans() {
		admins.push(_newAdmin);
		isAdmin[_newAdmin] = true;

		//emit event
	}

	function earlyResolve() public onlyAdmins() onlyHumans() gameOpen() {
		require (now > miniGameStartTime[miniGameCount].add(604800)); //1 week
		gameActive = false;
		earlyResolveCalled = true;
		resolveCycle();

		//emit event
	}

	function restartMiniGame() public onlyAdmins() onlyHumans() gameOpen() {
		require (miniGameProcessing == true && block.number > processingBegun.add(256));
		generateSeedA();

		//emit event
	}

	function zeroOut() public onlyAdmins() onlyHumans() {
		//admins can close the contract no sooner than 90 days after a full cycle completes 
        require (now >= cycleEnded.add(90 days) && cycleOver == true, "too early to close the contract"); 
        //selfdestruct and transfer to dev bank 
        selfdestruct(adminBank);

        //emit event
    }

//USER FUNCTIONS

	function () public payable onlyHumans() gameOpen() {
		//funds sent directly to contract will trigger buy
		buy(msg.value);
	}

	function buy(uint256 _amount) public payable onlyHumans() gameOpen() {
		//add div and last action update

		//checks
		require (msg.value == _amount, "msg.value and _amount must be the same");
		require (_amount >= tokenPrice, "you must buy at least one token");

		//update user accounting 
		uint256 tokensPurchased = _amount.div(tokenPrice);
		uint256 ethSpent = msg.value;
		//if round tokens are all sold, push difference to user balance and call generateSeedA
		if (tokensPurchased > miniGameTokensLeft[miniGameCount]) {
			uint256 tokensReturned = tokensPurchased.sub(miniGameTokensLeft[miniGameCount]);
			tokensPurchased = miniGameTokensLeft[miniGameCount];
			uint256 ethCredit = tokensReturned.mul(tokenPrice);
			ethSpent = msg.value.sub(ethCredit);
			userBalance[msg.sender] = userBalance[msg.sender].add(ethCredit);
			generateSeedA();
		}
		userTokens[msg.sender] = userTokens[msg.sender].add(tokensPurchased);
		userMiniGameTokens[msg.sender][miniGameCount] = userMiniGameTokens[msg.sender][roundCount].add(tokensPurchased);
		userRoundTokens[msg.sender][roundCount] = userRoundTokens[msg.sender][roundCount].add(tokensPurchased);

		//add min ranges and save in user accounting
		userMiniGameTokensMin[msg.sender][miniGameCount].push(currentToken);
		
		//update global token accounting
		miniGameTokensLeft[miniGameCount] = miniGameTokensLeft[miniGameCount].sub(tokensPurchased);
		if (miniGameTokensLeft[miniGameCount] < 0) {
			miniGameTokensLeft[miniGameCount] = 0;
		}
		currentToken = tokenSupply.sub(miniGameTokensLeft[miniGameCount]);

		//add mac ranges and save in user accounting
		userMiniGameTokensMax[msg.sender][miniGameCount].push(currentToken);

		//divide msg.value by various percentages and distribute
		uint256 adminShare = (ethSpent.mul(adminFeeRate)).div(100);
        adminBalance = adminBalance.add(adminShare);

        uint256 miniGamePrizeShare = (ethSpent.mul(miniGamePotRate)).div(100);
        miniGamePrizePot[miniGameCount] = adminBalance.add(miniGamePrizeShare);

        uint256 miniGameAirdropShare = (ethSpent.mul(miniGameAirdropRate)).div(100);
        miniGameAirdropPot[miniGameCount] = adminBalance.add(miniGameAirdropShare);

        uint256 miniGameDivShare = (ethSpent.mul(miniGameDivRate)).div(100);
        miniGameDivs[miniGameCount] = adminBalance.add(miniGameDivShare);

        uint256 roundAirdropShare = (ethSpent.mul(roundAirdropRate)).div(100);
        roundAirdropPot[roundCount] = adminBalance.add(roundAirdropShare);

        uint256 roundReferralShare = (ethSpent.mul(referralAirdropRate)).div(100);
        roundReferralAirdropPot[roundCount] = adminBalance.add(roundReferralShare);

        uint256 roundDivShare = (ethSpent.mul(roundDivRate)).div(100);
        roundDivs[roundCount] = adminBalance.add(roundDivShare);

        //@dev: should round pot also be updated here, as 48% of progressive pot?
        uint256 progressivePotShare = (ethSpent.mul(progressivePotRate)).div(100);
        progressivePot = adminBalance.add(progressivePotShare);

        //log last eligible rounds
        userLastMiniGameInteractedWith[msg.sender] = miniGameCount;
		userLastRoundInteractedWith[msg.sender] = roundCount;

        //sanity check
        assert (ethSpent == adminShare + miniGamePrizeShare + miniGameAirdropShare + miniGameDivShare + roundAirdropShare + roundReferralShare + roundDivShare + progressivePotShare);

        //update user balance, if necessary
		updateUserBalance();

		//emit event
	}

	function reinvest(uint256 _amount) public onlyHumans() gameOpen() {
		//update userBalance()
		updateUserBalance();

		//checks
		require (_amount <= userBalance[msg.sender], "insufficient balance");
		require (_amount >= tokenPrice, "you must buy at least one token");

		//take funds from user persistent storage and buy
		uint256 remainingBalance = userBalance[msg.sender].sub(_amount);
		userBalance[msg.sender] = remainingBalance;
		buy(_amount);

		

		//emit event

	}

	function withdraw() public onlyHumans() {
		//update userBalance()
		updateUserBalance();

		//checks
		require (userBalance[msg.sender] > 0, "insufficient balance");
		require (userBalance[msg.sender] <= address(this).balance, "you cannot withdraw more than the contract holds");

		//update user accounting and transfer
		uint256 toTransfer = userBalance[msg.sender];
		userBalance[msg.sender] = 0;
		msg.sender.transfer(toTransfer);

		//emit event
	}

//VIEW FUNCTIONS
	
	//helper function to return contract balance 
	function contractBalance() public view returns(uint256 _contractBalance) {
        return address(this).balance;
    }

    //check for user divs available

    //separate tracking for prizes, referrals, token divs

    //current mini game info

    //mini game tokens left in roundStartTime

    //mini game prize

    //user chance of winning minigame prize

    //mini game airdrop

    //user chance of winning minigame airdrop

    //round prize

    //user chance of winning round prize

    //round airdrop

    //user chance of winning round airdrop 

    //cycle prize

    //user chance of winning cycle prize

    //referral prize 

    //historic minigame and round data, retreivable by index; consilidates all mapping returns in a single function 

//INTERNAL FUNCTIONS

	function updateUserBalance() internal {
		//update any user divs by logging last minigame interacted with for any user 
		//add intelligent require checks at the start of this function to avoid uncessary gas costs if the user is not eligible for a certain prize 

		//push minigame divs to persistent storage and update accounting
		//push round divs to persistent storage and update accounting

		//push cycle prizes to persistent storage
		if (cycleOver == true && userCycleChecked[msg.sender] == false) {
			//check if user won cycle prize 
		}

		//push round prizes to persistent storage
		if (userLastRoundChecked[msg.sender] < userLastRoundInteractedWith[msg.sender] && roundCount > userLastRoundInteractedWith[msg.sender]) {
			//check if user won round 
			//check if user won round airdrop 
			//check if user won round refferal airdrop
			//move funds to persistent storage and update accounting
			userLastRoundChecked[msg.sender] = userLastRoundInteractedWith[msg.sender];
		}

		//push minigame prizes to persistent storage
		if (userLastMiniGameChecked[msg.sender] < userLastMiniGameInteractedWith[msg.sender] && miniGameCount > userLastMiniGameInteractedWith[msg.sender]) {
			//check if user won minigame 
			//check if user won minigame airdrop 
			//move funds to persistent storage and update accounting
			userLastMiniGameChecked[msg.sender] = userLastMiniGameInteractedWith[msg.sender];
		}
	}

	function miniGameStart() internal {
		require (cycleOver == false);
		miniGameCount = miniGameCount.add(1);
		miniGameStartTime[miniGameCount] = now;
		if (tokenSupply != 0) {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply.add(1);
		} else {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply;
		}
		miniGameTokens[miniGameCount] = generateTokens();
		miniGameTokensLeft[miniGameCount] = miniGameTokens[miniGameCount];
		miniGameTokenRangeMax[miniGameCount] = tokenSupply;
		currentToken = tokenSupply.sub(miniGameTokensLeft[miniGameCount]);
		if (miniGameCount > 1) {
			tokenPrice = tokenPrice.add(tokenPriceIncrement);
		}

		if (miniGameCount % 100 == 0) {
			roundStart();
		}
	}

	function roundStart() internal {
		require (cycleOver == false);
		roundCount = roundCount.add(1);
		roundStartTime[roundCount] = now;
		if (tokenSupply != 0) {
			roundTokenRangeMin[roundCount] = tokenSupply.add(1);
		} else {
			roundTokenRangeMax[roundCount] = tokenSupply;
		}
		if (roundCount > 2) {
			roundTokenRangeMax[roundCount.sub(1)] = tokenSupply;
			roundTokens[roundCount.sub(1)] = tokenSupply.sub(roundTokenRangeMin[roundCount.sub(1)]);
		}
	}

	function cycleStart() internal {
		require (cycleOver == false);
		cycleCount = cycleCount.add(1);
		cycleStartTime[cycleCount] = now;
	}

	function generateTokens() internal returns(uint256 _tokens) {
		//generate the tokens 
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 randTokens = uint256(hash).mod(100000);
        uint256 newRoundTokens = randTokens.add(100000);
        return newRoundTokens;
		tokenSupply = tokenSupply.add(newRoundTokens);
		salt++;
	}

	function generateSeedA() internal {
		//checks 
		//can be called again if generateSeedB is not tiggered within 256 blocks 
		require (miniGameProcessing == false || miniGameProcessing == true && block.number > processingBegun.add(256));
		require (miniGameTokensLeft[miniGameCount] == 0 || earlyResolveCalled == true);
		
		//generate seed 
		miniGameProcessing = true;
		processingBegun = block.number;

		hashA = blockhash(block.number);

		//award person who called this function
	}

	function generateSeedB() internal {
		hashB = blockhash(processingBegun.add(RNGblockDelay));

		awardMiniGamePrize();
		awardMiniGameAirdrop();

		if (miniGameCount % 10 == 0) {
			//do era stuff
		}

		if (miniGameCount % 25 == 0) {
			//do epoch stuff
		}

		if (miniGameCount % 100 == 0) {
			awardRoundPrize();
			awardRoundAirdrop();
		}

		if (miniGameCount % 1000 == 0) {
			resolveCycle();
		}

		miniGameStart();

		//award person who called this function 

		miniGameProcessing = false;
	}

	function awardMiniGamePrize() internal returns(uint256){
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount]);
        miniGamePrizeNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
        salt++;

        //update accounting
	}

	function awardMiniGameAirdrop() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount]);
        miniGameAirdropNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
        salt++;

         //update accounting
	}

	function awardRoundPrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 currentRoundTokens = tokenSupply.sub(roundTokenRangeMin[roundCount]);
        uint256 winningNumber = uint256(hash).mod(currentRoundTokens);
        roundPrizeNumber[roundCount] = winningNumber + roundTokenRangeMin[roundCount];
        salt++;

        //update accounting
	}

	function awardRoundAirdrop() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 currentRoundTokens = tokenSupply.sub(roundTokenRangeMin[roundCount]);
        uint256 winningNumber = uint256(hash).mod(currentRoundTokens);
        roundAirdropNumber[roundCount] = winningNumber + roundTokenRangeMin[roundCount];
        salt++;

        //update accounting
	}

	function awardCyclePrize() internal pure {
		//award mini game prize
	}

	function awardReferralPrize() internal pure{
		//award mini game prize
	}

	function resolveCycle() internal view {
		//resolve cycle  
		require (cycleOver == false);
	}

}
