//@testing confirm early resolve works correctly
//@testing confirm narrow round and cycle functions are working properly

pragma solidity ^0.4.25;

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

	///////////
	//STORAGE//
	///////////

	//ADMIN
	uint256 public adminBalance;
	address public adminBank;
	address[] public admins;
	mapping (address => bool) public isAdmin;

	//GLOBAL
	bool public gameActive = false;
	bool public earlyResolveACalled = false;
	bool public earlyResolveBCalled = false;
	uint256 public miniGamesPerRound = 5; //@dev lowered for testing 
	uint256 public miniGamesPerCycle = 20; //@dev lowered for testing 
	uint256 public miniGamePotRate = 25; //25%
	uint256 public progressivePotRate = 25; //25%
	uint256 public roundDivRate = 20; //20%
	uint256 public miniGameDivRate = 10; //10%
	uint256 public referralRate = 10; //10%
	uint256 public miniGameAirdropRate = 5; //5%
	uint256 public adminFeeRate = 5; //5%
	uint256 public roundPotRate = 48; //48% of progressive pot 
	uint256 internal precisionFactor = 9; //percentages precise to 0.0000001%
	uint256 public seedAreward = 25000000000000000; //0.025 ETH
	uint256 public seedBreward = 25000000000000000; //0.025 ETH
	mapping (uint256 => bool) public miniGameSeedAawarded;
	mapping (uint256 => bool) public miniGameSeedBawarded;
	
	//RNG
	uint256 internal RNGblockDelay = 1;
    uint256 internal salt = 0;
    bytes32 internal hashA;
    bytes32 internal hashB;

	//MINIGAME TRACKING
	bool public miniGameProcessing;
	uint256 public miniGameCount;
	uint256 public miniGameProcessingBegun;
	mapping (uint256 => bool) public miniGamePrizeClaimed;
	mapping (uint256 => bool) public miniGameAirdropClaimed;
	mapping (uint256 => uint256) public miniGameStartTime;
	mapping (uint256 => uint256) public miniGameEndTime;
	mapping (uint256 => uint256) public miniGameTokens;
	mapping (uint256 => uint256) public miniGameTokensLeft;
	mapping (uint256 => uint256) public miniGameTokensActive;
	mapping (uint256 => uint256) public miniGameTokenRangeMin;
	mapping (uint256 => uint256) public miniGameTokenRangeMax;
	mapping (uint256 => uint256) public miniGamePrizeNumber;
	mapping (uint256 => uint256) public miniGameAirdropNumber;
	mapping (uint256 => uint256) public miniGamePrizePot;
	mapping (uint256 => uint256) public miniGameAirdropPot;
	mapping (uint256 => uint256) public miniGameDivs;
	mapping (uint256 => address) public miniGamePrizeWinner;
	mapping (uint256 => address) public miniGameAirdropWinner;

	//ROUND TRACKING
	uint256 public roundCount;
	mapping (uint256 => bool) public roundPrizeClaimed;
	mapping (uint256 => bool) public roundPrizeTokenRangeIdentified;
	mapping (uint256 => uint256) public roundStartTime;
	mapping (uint256 => uint256) public roundEndTime;
	mapping (uint256 => uint256) public roundTokens;
	mapping (uint256 => uint256) public roundTokensActive;
	mapping (uint256 => uint256) public roundTokenRangeMin;
	mapping (uint256 => uint256) public roundTokenRangeMax;
	mapping (uint256 => uint256) public roundPrizeNumber;
	mapping (uint256 => uint256) public roundPrizePot;
	mapping (uint256 => uint256) public roundDivs;
	mapping (uint256 => uint256) public roundPrizeInMinigame;
	mapping (uint256 => address) public roundPrizeWinner;

	//CYCLE TRACKING
	bool public cycleOver = false;
	bool public cylcePrizeClaimed;
	bool public cyclePrizeTokenRangeIdentified;
	uint256 public tokenSupply;
	uint256 public cycleActiveTokens;
	uint256 public cycleCount;
	uint256 public cycleEnded;
	uint256 public cycleProgressivePot;
	uint256 public cyclePrizeWinningNumber;
	uint256 public cyclePrizeInMinigame;
	uint256 public cyclePrizeInRound;
	uint256 public cycleStartTime;
	address public cyclePrizeWinner;

	//TOKEN TRACKING
	uint256 public tokenPrice = 0.00001 ether; //@dev lowered for testing
	uint256 public tokenPriceIncrement = 0.000005 ether; //@dev lowered for testing 
	uint256 public minTokensPerMiniGame = 10000; //between 1x and 2x this amount of tokens generated each minigame 

	//USER TRACKING PUBLIC
	mapping (address => uint256) public userTokens;
	mapping (address => uint256) public userBalance;
	mapping (address => mapping (uint256 => uint256)) public userMiniGameTokens;
	mapping (address => mapping (uint256 => uint256)) public userRoundTokens;

	//USER TRACKING INTERNAL
	mapping (address => bool) internal userCycleChecked;
	mapping (address => uint256) internal userLastMiniGameInteractedWith;
	mapping (address => uint256) internal userLastRoundInteractedWith;
	mapping (address => uint256) internal userLastMiniGameChecked;
	mapping (address => uint256) internal userLastRoundChecked;
	mapping (address => mapping (uint256 => uint256)) internal userShareMiniGame;
	mapping (address => mapping (uint256 => uint256)) internal userDivsMiniGameTotal;
	mapping (address => mapping (uint256 => uint256)) internal userDivsMiniGameClaimed;
	mapping (address => mapping (uint256 => uint256)) internal userDivsMiniGameUnclaimed;
	mapping (address => mapping (uint256 => uint256)) internal userShareRound;
	mapping (address => mapping (uint256 => uint256)) internal userDivsRoundTotal;
	mapping (address => mapping (uint256 => uint256)) internal userDivsRoundClaimed;
	mapping (address => mapping (uint256 => uint256)) internal userDivsRoundUnclaimed;
	mapping (address => mapping (uint256 => uint256[])) internal userMiniGameTokensMin;
	mapping (address => mapping (uint256 => uint256[])) internal userMiniGameTokensMax;

	
	///////////////
	//CONSTRUCTOR//
	///////////////

	constructor(address _adminBank, address _adminTwo, address _adminThree) public {
		//set dev bank address and admins
		adminBank = _adminBank;
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
		admins.push(_adminTwo);
		isAdmin[_adminTwo] = true; 
		admins.push(_adminThree);
		isAdmin[_adminThree] = true; 
	}

	
	/////////////
	//MODIFIERS//
	/////////////

	modifier onlyAdmins() {
		require (isAdmin[msg.sender] == true, "you must be an admin");
		_;
	}

	modifier onlyHumans() { 
        require (msg.sender == tx.origin || msg.sender == adminBank, "only approved contracts allowed"); 
        _; 
    }

    modifier gameOpen() {
    	require (gameActive == true, "the game must be open");
    	if (miniGameProcessing == true) {
    		require (block.number > miniGameProcessingBegun + RNGblockDelay, "the round is still processing. try again soon");
    	}
    	_;
    }
    
    
    //////////
	//EVENTS//
	//////////

	event adminWithdrew(
		uint256 _amount,
		address indexed _caller,
		string _message 
	);

	event cycleStarted(
		address indexed _caller,
		string _message
	);

	event adminAdded(
		address indexed _caller,
		address indexed _newAdmin,
		string _message
	);

	event resolvedEarly(
		address indexed _caller,
		uint256 _pot,
		string _message
	);

	event processingRestarted(
		address indexed _caller,
		string _message
	);

	event contractDestroyed(
		address indexed _caller,
		uint256 _balance,
		string _message
	);

	event userBought(
		address indexed _user,
		uint256 _tokensBought,
		uint256 indexed _miniGameID,
		string _message
	);

	event userReinvested(
		address indexed _user,
		uint256 _amount,
		string _message
	);

	event userWithdrew(
		address indexed _user,
		uint256 _amount,
		string _message
	);

	event processingStarted(
		address indexed _caller,
		uint256 indexed _miniGameID,
		uint256 _blockNumber,
		string _message
	);

	event processingFinished(
		address indexed _caller,
		uint256 indexed _miniGameID,
		uint256 _blockNumber,
		string _message
	);

	event newMinigameStarted(
		uint256 indexed _miniGameID,
		uint256 _newTokens,
		string _message
	);

	event miniGamePrizeAwarded(
		uint256 indexed _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event miniGameAirdropAwarded(
		uint256 indexed _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event roundPrizeAwarded(
		uint256 indexed _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event referralAwarded(
		uint256 indexed _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event cyclePrizeAwarded(
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);


	///////////////////
	//ADMIN FUNCTIONS//
	///////////////////

	function adminWithdraw() external onlyAdmins() onlyHumans(){
		uint256 balance = adminBalance;
		adminBalance = 0;
		adminBank.transfer(balance);

		//emit adminWithdrew(balance, msg.sender, "an admin just withdrew");
	}

	function startCycle() external onlyAdmins() onlyHumans() {
		require (gameActive == false && cycleCount == 0, "the cycle has already been started");
		
		gameActive = true;
		cycleStart();
		roundStart();
		miniGameStart();

		//emit cycleStarted(msg.sender, "a new cycle just started"); 

	}

	//this function begins resolving the round in the event that the game has stalled
	//can only be called once. can be restarted with restartMiniGame if 256 blocks pass
	function earlyResolveA() external onlyAdmins() onlyHumans() gameOpen() {
		require (now > miniGameStartTime[miniGameCount] + 604800 && miniGameProcessing == false, "earlyResolveA cannot be called yet"); //1 week
		
		gameActive = false;
		earlyResolveACalled = true;
		generateSeedA();
	}

	//this function comlpetes the resolution and ends the game 
	function earlyResolveB() external onlyAdmins() onlyHumans() {
		require (earlyResolveACalled == true && earlyResolveBCalled == false && miniGameProcessing == true && block.number > miniGameProcessingBegun + RNGblockDelay, "earlyResolveB cannot be called yet"); 
		
		earlyResolveBCalled = true;
		resolveCycle();

		emit resolvedEarly(msg.sender, cycleProgressivePot, "the cycle was resolved early"); 
	}

	//resets the first seed in case the processing is not completed within 256 blocks 
	function restartMiniGame() external onlyAdmins() onlyHumans() {
		require (miniGameProcessing == true && block.number > miniGameProcessingBegun + 256, "restartMiniGame cannot be called yet");
		
		generateSeedA();

		emit processingRestarted(msg.sender, "mini-game processing was restarted");
	}

	//admins can close the contract no sooner than 90 days after a full cycle completes 
	//users need to withdraw funds before this date or risk losing them
	function zeroOut() external onlyAdmins() onlyHumans() {
        require (now >= cycleEnded + 90 days && cycleOver == true, "too early to close the contract"); 
        
        uint256 balance = address(this).balance;
        selfdestruct(adminBank);

        emit contractDestroyed(msg.sender, balance, "contract destroyed");
    }


	//////////////////
	//USER FUNCTIONS//
	//////////////////

	function () external payable onlyHumans() gameOpen() {
		//funds sent directly to contract will trigger buy
		//no refferal on fallback 
		buyInternal(msg.value, 0x0);
	}

	function buy(address _referral) public payable onlyHumans() gameOpen() {
		buyInternal(msg.value, _referral);
	}
	
	function reinvest(uint256 _amount, address _referral) external onlyHumans() gameOpen() {
		//update userBalance at beginning of function in case user has new funds to reinvest
		updateUserBalance(msg.sender);

		require (_amount <= userBalance[msg.sender], "insufficient balance");
		require (_amount >= tokenPrice, "you must buy at least one token");

		//take funds from user persistent storage and buy
		uint256 remainingBalance = userBalance[msg.sender].sub(_amount);
		userBalance[msg.sender] = remainingBalance;
		
		buyInternal(_amount, _referral);

		emit userReinvested(msg.sender, _amount, "a user reinvested");

	}

	function withdraw() external onlyHumans() {
		//update userBalance at beginning of function in case user has new funds to reinvest
		updateUserBalance(msg.sender);

		require (userBalance[msg.sender] > 0, "no balance to withdraw");
		require (userBalance[msg.sender] <= address(this).balance, "you cannot withdraw more than the contract holds");

		//update user accounting and transfer
		uint256 toTransfer = userBalance[msg.sender];
		userBalance[msg.sender] = 0;
		msg.sender.transfer(toTransfer);

		emit userWithdrew(msg.sender, toTransfer, "a user withdrew");
	}


	//////////////////
	//VIEW FUNCTIONS//
	//////////////////

	//helper function to return contract balance 
	function contractBalance() external view returns(uint256 _contractBalance) {
        return address(this).balance;
    }

    //check for user divs available
    function checkUserDivsAvailable(address _user) external view returns(uint256 _userDivsAvailable) {
    	return userBalance[_user] + checkDivsMgView(_user) + checkDivsRndView(_user) + checkPrizesView(_user);
    }

    //user chance of winning minigame prize or airdrop
    function userOddsMiniGame(address _user) external view returns(uint256) {
    	//returns percentage precise to two decimal places (eg 1428 == 14.28% odds)
    	return userMiniGameTokens[_user][miniGameCount].mul(10 ** 5).div(miniGameTokensActive[miniGameCount]).add(5).div(10);
    }

    //user chance of winning round prize or airdrop
    function userOddsRound(address _user) external view returns(uint256) {
    	//returns percentage precise to two decimal places (eg 1428 == 14.28% odds)
    	return userRoundTokens[_user][roundCount].mul(10 ** 5).div(roundTokensActive[roundCount]).add(5).div(10);
    }

    //user chance of winning cycle prize
    function userOddsCycle(address _user) external view returns(uint256) {
    	//returns percentage precise to two decimal places (eg 1428 == 14.28% odds)
    	return userTokens[_user].mul(10 ** 5).div(cycleActiveTokens).add(5).div(10);
    }

    //cycle data	
    function cycleInfo() external view returns(
    	bool _cycleComplete,
    	uint256 _currentRound,
    	uint256 _currentMinigame,
    	uint256 _tokenSupply,
    	uint256 _progressivePot,
    	bool _prizeClaimed,
    	uint256 _winningNumber
    	) {
    	bool isActive;
    	if (miniGameCount < 1000) {isActive = true;} else {isActive = false;}
    	return (
    		isActive,
    		roundCount,
    		miniGameCount,
    		tokenSupply,
    		cycleProgressivePot,
    		cylcePrizeClaimed,
    		cyclePrizeWinningNumber
    	);
    }

    
    //////////////////////
	//INTERNAL FUNCTIONS//
	//////////////////////

	function buyInternal(uint256 _amount, address _referral) internal {
		require (_amount >= tokenPrice, "you must buy at least one token");
		require (userMiniGameTokensMin[msg.sender][roundCount].length < 10, "you are buying too often in this round"); //sets up bounded loop 

		//assign tokens
		uint256 tokensPurchased = _amount.div(tokenPrice);
		uint256 ethSpent = _amount;

		//if this is the first tx after processing period is over, call generateSeedB
		if (miniGameProcessing == true && block.number > miniGameProcessingBegun + RNGblockDelay) {
			generateSeedB();
		}

		//if round tokens are all sold, push difference to user balance and call generateSeedA
		if (tokensPurchased > miniGameTokensLeft[miniGameCount]) {
			uint256 tokensReturned = tokensPurchased.sub(miniGameTokensLeft[miniGameCount]);
			tokensPurchased = miniGameTokensLeft[miniGameCount];
			miniGameTokensLeft[miniGameCount] = 0;
			uint256 ethCredit = tokensReturned.mul(tokenPrice);
			ethSpent = _amount.sub(ethCredit);
			userBalance[msg.sender] += ethCredit;
			generateSeedA();
		}

		//update user token accounting
		userTokens[msg.sender] += tokensPurchased;
		userMiniGameTokens[msg.sender][miniGameCount] += tokensPurchased;
		userRoundTokens[msg.sender][roundCount] += tokensPurchased;
		//add min ranges and save in user accounting
		userMiniGameTokensMin[msg.sender][miniGameCount].push(cycleActiveTokens);
		userMiniGameTokensMax[msg.sender][miniGameCount].push(cycleActiveTokens + tokensPurchased);
		//log last eligible rounds for withdraw checking 
		userLastMiniGameInteractedWith[msg.sender] = miniGameCount;
		userLastRoundInteractedWith[msg.sender] = roundCount;	

		//check referral 
		if (_referral != 0x0000000000000000000000000000000000000000 && _referral != msg.sender) {
           // assign refferal
           uint256 referralShare = (ethSpent.mul(referralRate)).div(100);
           userBalance[_referral] += referralShare;
       	} else {
       		//if no referral used, add to progessive pot 
       		cycleProgressivePot += referralShare;
       	}

		//divide amount by various percentages and distribute
		uint256 adminShare = (ethSpent.mul(adminFeeRate)).div(100);
        adminBalance += adminShare;

        uint256 mgDivs = (ethSpent.mul(miniGameDivRate)).div(100);
        miniGameDivs[miniGameCount] += mgDivs;

        uint256 rndDivs = (ethSpent.mul(roundDivRate)).div(100);
        roundDivs[roundCount] += rndDivs;

        uint256 roundDivShare = ethSpent.mul(roundDivRate).div(100);
        roundDivs[roundCount] += roundDivShare;

        uint256 miniGamePrize = ethSpent.mul(miniGamePotRate).div(100);
        miniGamePrizePot[miniGameCount] += miniGamePrize;

        uint256 miniGameAirdrop = ethSpent.mul(miniGameAirdropRate).div(100);
        miniGameAirdropPot[miniGameCount] += miniGameAirdrop;

        uint256 cyclePot = ethSpent.mul(progressivePotRate).div(100);
        cycleProgressivePot += cyclePot;

       	//update global token accounting 
       	if (miniGameTokensLeft[miniGameCount] > 0) {
			miniGameTokensLeft[miniGameCount] = miniGameTokensLeft[miniGameCount].sub(tokensPurchased);
			if (miniGameTokensLeft[miniGameCount] <= 0) {
				miniGameTokensLeft[miniGameCount] = 0;
			}
		}
		cycleActiveTokens += tokensPurchased;
		roundTokensActive[roundCount] += tokensPurchased;
		miniGameTokensActive[miniGameCount] += tokensPurchased;

        //update user balance, if necessary. done here to keep ensure updateUserBalance never has to search through multiple minigames 
		updateUserBalance(msg.sender);

		emit userBought(msg.sender, tokensPurchased, miniGameCount, "a user just bought tokens");
	}

	function checkDivs(address _user) internal {
		//set up local shorthand
		uint256 _mg = userLastMiniGameChecked[_user];
		uint256 _rnd = userLastRoundChecked[_user];

		//calculate minigame divs 
		userShareMiniGame[_user][_mg] = userMiniGameTokens[_user][_mg].mul(10 ** (precisionFactor + 1)).div(miniGameTokens[_mg] + 5).div(10);
        userDivsMiniGameTotal[_user][_mg] = miniGameDivs[_mg].mul(userShareMiniGame[_user][_mg]).div(10 ** precisionFactor);
        userDivsMiniGameUnclaimed[_user][_mg] = userDivsMiniGameTotal[_user][_mg].sub(userDivsMiniGameClaimed[_user][_mg]);
        //add to user balance
        if (userDivsMiniGameUnclaimed[_user][_mg] > 0) {
            //sanity check
            assert(userDivsMiniGameUnclaimed[_user][_mg] <= address(this).balance);
            //update user accounting
            userDivsMiniGameClaimed[_user][_mg] = userDivsMiniGameTotal[_user][_mg];
            uint256 shareTempMg = userDivsMiniGameUnclaimed[_user][_mg];
            userDivsMiniGameUnclaimed[_user][_mg] = 0;
	        userBalance[_user] += shareTempMg;
        }
        //calculate round divs 
		userShareRound[_user][_rnd] = userRoundTokens[_user][_rnd].mul(10 ** (precisionFactor + 1)).div(roundTokens[_rnd] + 5).div(10);
        userDivsRoundTotal[_user][_rnd]  = roundDivs[_rnd].mul(userShareRound[_user][_rnd]).div(10 ** precisionFactor);
        userDivsRoundUnclaimed[_user][_rnd] = userDivsRoundTotal[_user][_rnd].sub(userDivsRoundClaimed[_user][_rnd]);
        //add to user balance
        if (userDivsRoundUnclaimed[_user][_rnd] > 0) {
            //sanity check
            assert(userDivsRoundUnclaimed[_user][_rnd] <= address(this).balance);
            //update user accounting
            userDivsRoundClaimed[_user][_rnd] = userDivsRoundTotal[_user][_rnd];
            uint256 shareTempRnd = userDivsRoundUnclaimed[_user][_rnd];
            userDivsRoundUnclaimed[_user][_rnd] = 0;
	        userBalance[_user] += shareTempRnd;
        }	
	}

	function checkPrizes(address _user) internal {
		//push cycle prizes to persistent storage
		if (cycleOver == true && userCycleChecked[_user] == false) {
			//get minigame cycle prize was in 
			uint256 mg;
			if (cyclePrizeTokenRangeIdentified == true) {
				mg = cyclePrizeInMinigame;
			} else {
				narrowCyclePrize();
				mg = cyclePrizeInMinigame;
			}
			//check if user won cycle prize 
			if (cylcePrizeClaimed == false && userMiniGameTokensMax[_user][mg].length > 0) {
			//check if user won minigame 
			//loop iterations bounded to a max of 10 on buy()
    			for (uint256 i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
    				if (cyclePrizeWinningNumber >= userMiniGameTokensMin[_user][mg][i] && cyclePrizeWinningNumber <= userMiniGameTokensMax[_user][mg][i]) {
    					userBalance[_user] += cycleProgressivePot;
    					cylcePrizeClaimed = true;
						cyclePrizeWinner = msg.sender;				
    					break;
    				}
    			}
			}
			userCycleChecked[_user] = true;
		}
		//push round prizes to persistent storage
		if (userLastRoundChecked[_user] < userLastRoundInteractedWith[_user] && roundCount > userLastRoundInteractedWith[_user]) {
			//get minigame round prize was in 
			uint256 mgp;
			uint256 _ID = userLastRoundChecked[_user];
			if (roundPrizeTokenRangeIdentified[_ID] == true) {
				mgp = roundPrizeInMinigame[_ID];
			} else {
				narrowRoundPrize(_ID);
				mgp = roundPrizeInMinigame[_ID];
			}
			//check if user won round prize
			for (i = 0; i < userMiniGameTokensMin[_user][mgp].length; i++) {
				if (roundPrizeNumber[_ID] >= userMiniGameTokensMin[_user][mgp][i] && roundPrizeNumber[_ID] <= userMiniGameTokensMax[_user][mgp][i]) {
					userBalance[_user] += roundPrizePot[mgp];
					roundPrizeClaimed[_ID] = true;
					roundPrizeWinner[_ID] = msg.sender;		
					break;
				}
			}
			userLastRoundChecked[_user] = userLastRoundInteractedWith[_user];
		}
		//push minigame prizes to persistent storage
		if (userLastMiniGameChecked[_user] < userLastMiniGameInteractedWith[_user] && miniGameCount > userLastMiniGameInteractedWith[_user]) {
			//check if user won minigame 
			mg = userLastMiniGameInteractedWith[_user];
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGamePrizeNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGamePrizeNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					userBalance[_user] += miniGamePrizePot[mg];
					miniGamePrizeClaimed[mg] = true;
					miniGamePrizeWinner[mg] = msg.sender;			
					break;
				}
			}
			//check if user won airdrop
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGameAirdropNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGameAirdropNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					userBalance[_user] += miniGameAirdropPot[mg];
					miniGameAirdropClaimed[mg] = true;
					miniGameAirdropWinner[mg] = msg.sender;
					break;
				}
			}
			//update last mini game checked 
			userLastMiniGameChecked[_user] = userLastMiniGameInteractedWith[_user];
		}
	}

	function updateUserBalance(address _user) internal {
		checkDivs(_user);
		checkPrizes(_user);
	}

	function miniGameStart() internal {
		require (cycleOver == false, "the cycle cannot be over");
		
		miniGameCount++;
		miniGameStartTime[miniGameCount] = now;
		//set up special case for correct token range on first minigame 
		if (tokenSupply != 0) {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply + 1;
		} else {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply;
		}
		//genreate tokens and update accounting 
		miniGameTokens[miniGameCount] = generateTokens();
		miniGameTokensLeft[miniGameCount] = miniGameTokens[miniGameCount];
		miniGameTokenRangeMax[miniGameCount] = tokenSupply;
		cycleActiveTokens = 0;
		//increment token price after 1st minigame 
		if (miniGameCount > 1) {
			tokenPrice += tokenPriceIncrement;
		}
		//start new round if current round is complete 
		if (miniGameCount % miniGamesPerRound == 0) {
			roundStart();
		}

		emit newMinigameStarted(miniGameCount, miniGameTokens[miniGameCount], "new minigame started");
	}

	function roundStart() internal {
		require (cycleOver == false, "the cycle cannot be over");

		roundCount++;
		roundStartTime[roundCount] = now;
		//set up special case for correct token range on first round 
		if (tokenSupply != 0) {
			roundTokenRangeMin[roundCount] = tokenSupply + 1;
		} else {
			roundTokenRangeMin[roundCount] = tokenSupply;
		}
		//log max only when round is complete 
		if (roundCount > 2) {
			roundTokenRangeMax[roundCount.sub(1)] = tokenSupply;
			roundTokens[roundCount.sub(1)] = tokenSupply.sub(roundTokenRangeMin[roundCount.sub(1)]);
		}
	}

	function cycleStart() internal {
		require (cycleOver == false, "the cycle cannot be over");

		cycleCount++;
		cycleStartTime = now;
	}

	function generateTokens() internal returns(uint256 _tokens) {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 randTokens = uint256(hash).mod(minTokensPerMiniGame);
        uint256 newMinGameTokens = randTokens + minTokensPerMiniGame;
		tokenSupply += newMinGameTokens;
		salt++;

		return newMinGameTokens;
	}

	function generateSeedA() internal {
		require (miniGameProcessing == false || miniGameProcessing == true && block.number > miniGameProcessingBegun + 256, "seed A cannot be regenerated right now");
		require (miniGameTokensLeft[miniGameCount] == 0 || earlyResolveACalled == true, "active tokens remain in this minigame");
		
		miniGameProcessing = true;
		miniGameProcessingBegun = block.number;
		//generate seed 
		hashA = blockhash(miniGameProcessingBegun - 1);
		//log end times
		if (miniGameCount > 1) {
			miniGameEndTime[miniGameCount] = now;
		}
		if (miniGameCount % miniGamesPerRound == 0) {
			roundEndTime[roundCount] = now;
		}
		//award processing bounty
		if (miniGameSeedAawarded[miniGameCount] == false) {
			userBalance[msg.sender] += seedAreward;
			miniGameSeedAawarded[miniGameCount] = true;
		}
		salt++;

		emit processingStarted(msg.sender, miniGameCount, block.number, "processing started");
	}

	function generateSeedB() internal {
		//gererate seed 
		hashB = blockhash(miniGameProcessingBegun + RNGblockDelay);
		//awared prizes 
		awardMiniGamePrize();
		awardMiniGameAirdrop();
		//award round price if necessary
		if (miniGameCount % miniGamesPerRound - 1 == 0 && miniGameCount > 2) {
			awardRoundPrize();
		}
		//award cycle price if necessary
		if (miniGameCount % miniGamesPerCycle - 1 == 0 && miniGameCount > 2) {
			awardCyclePrize();
			gameActive = false;
		}
		//award processing bounty 
		if (miniGameSeedBawarded[miniGameCount] == false) {
			userBalance[msg.sender] += seedBreward;
			miniGameSeedBawarded[miniGameCount] = true;
		}
		//start next minigame
		miniGameStart();
		miniGameProcessing = false;
		salt++;

		emit processingFinished(msg.sender, miniGameCount, block.number, "processing finished");
	}

	function awardMiniGamePrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount]);
        miniGamePrizeNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
        miniGamePrizePot[miniGameCount] = miniGamePrizePot[miniGameCount].sub(seedAreward).sub(seedBreward);
        salt++;

        emit miniGamePrizeAwarded(miniGameCount, winningNumber, miniGamePrizePot[miniGameCount], "minigame prize awarded");
	}

	function awardMiniGameAirdrop() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount]);
        miniGameAirdropNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
        salt++;

        emit miniGameAirdropAwarded(miniGameCount, winningNumber, miniGameAirdropPot[miniGameCount], "minigame airdrop awarded");
	}

	function awardRoundPrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 currentRoundTokens = tokenSupply.sub(roundTokenRangeMin[roundCount]);
        uint256 winningNumber = uint256(hash).mod(currentRoundTokens);
        roundPrizeNumber[roundCount] = winningNumber + roundTokenRangeMin[roundCount];
        //calculate round prize here 
        uint256 roundPrize = cycleProgressivePot.mul(roundPotRate).div(100);
		uint256 adminShare = cycleProgressivePot.mul(4).div(100);
		adminBalance += adminShare;
        roundPrizePot[roundCount] = roundPrize;
        cycleProgressivePot = roundPrize;
        salt++;

		emit roundPrizeAwarded(roundCount, winningNumber, roundPrize, "round prize awarded");
	}

	function awardCyclePrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(tokenSupply);
        cyclePrizeWinningNumber = winningNumber;
        gameActive = false;
        salt++;

		emit cyclePrizeAwarded(winningNumber, cycleProgressivePot, "cycle prize awarded");
	}

	function resolveCycle() internal {
		//generate hashB here in instead of calling generateSeedB
		hashB = blockhash(miniGameProcessingBegun + RNGblockDelay);
		//award prizes 
		awardMiniGamePrize();
		awardMiniGameAirdrop();
		awardRoundPrize();
		awardCyclePrize();
		//close game
		miniGameProcessing = false;
		gameActive = false;
	}

	//narrows down the token range of a round to a specific miniGame
	//reduces the search space on user prize updates 
	function narrowRoundPrize(uint256 _ID) internal returns(uint256 _miniGameID) {
		//set up local accounting
		uint256 winningNumber = roundPrizeNumber[_ID];
		uint256 miniGameRangeMin; 
		uint256 miniGameRangeMid;
		uint256 miniGameRangeMax;
		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMid = 100;
			miniGameRangeMax = 50;
		} else if (_ID >= 2 && _ID <= 100) {
			miniGameRangeMin = _ID.mul(100);
			miniGameRangeMid = _ID.mul(100) + 100;
			miniGameRangeMax = _ID.mul(100) + 50;
		}	
		//loop through each minigame to check prize number
		//split in two ranges to save gas on loop
		//log so this only needs to be called once per prize 
        if (winningNumber >= miniGameRangeMid) {
            for (uint i = miniGameRangeMid; i <= miniGameRangeMax; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    roundPrizeInMinigame[_ID] = miniGameRangeMin + (i - 1);
                    roundPrizeTokenRangeIdentified[_ID] = true;
                    return roundPrizeInMinigame[_ID];
                    break;
                }
            }
        } else if (winningNumber < miniGameRangeMid) {
            for (i = 1; i < miniGameRangeMid; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    roundPrizeInMinigame[_ID] = miniGameRangeMin + (i - 1);
                    roundPrizeTokenRangeIdentified[_ID] = true;
                    return roundPrizeInMinigame[_ID];
                    break;
                }
            }
        }		
	}

	//narrows down the token range of a round to a specific miniGame
	//reduces the search space on user prize updates 
	function narrowCyclePrize() internal returns(uint256 _miniGameID) {
		//set up local accounting
		uint256 winningNumber = cyclePrizeWinningNumber;
		//first identify round 
        if (winningNumber >= roundTokenRangeMin[50]) {
            for (uint256 i = 50; i <= roundCount; i++) {
                if (winningNumber >= roundTokenRangeMin[i] && winningNumber <= roundTokenRangeMax[i]) {
                    cyclePrizeInRound = i;
                    break;
                }
            }
        } else if (winningNumber < roundTokenRangeMin[50]) {
            for (i = 1; i < 50; i++) {
                if (winningNumber >= roundTokenRangeMin[i] && winningNumber <= roundTokenRangeMax[i]) {
                    cyclePrizeInRound = i;
                    break;
                }
            }
        }	
        //set up minigame local accounting 
        uint256 miniGameRangeMin; 
		uint256 miniGameRangeMid;
		uint256 miniGameRangeMax;
		uint256 _ID = cyclePrizeInRound;
		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMid = 100;
			miniGameRangeMax = 50;
		} else if (_ID >= 2 && _ID <= 100) {
			miniGameRangeMin = _ID.mul(100);
			miniGameRangeMid = _ID.mul(100) + 100;
			miniGameRangeMax = _ID.mul(100) + 50;
		}
		//then loop through each minigame to check prize number
		//split in two ranges to save gas on loop
		//log so this only needs to be called once per prize 
        if (winningNumber >= miniGameRangeMid) {
            for (i = miniGameRangeMid; i <= miniGameRangeMax; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    cyclePrizeInRound = miniGameRangeMin + (i - 1);
                    cyclePrizeTokenRangeIdentified = true;
                    return cyclePrizeInRound;
                    break;
                }
            }
        } else if (winningNumber < miniGameRangeMid) {
            for (i = 1; i < miniGameRangeMid; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    cyclePrizeInRound = miniGameRangeMin + (i - 1);
                    cyclePrizeTokenRangeIdentified = true;
                    return cyclePrizeInRound;
                    break;
                }
            }
        }		
	}

	//helper function for up to date front end balances without state change
	function checkDivsMgView(address _user) internal view returns(uint256 _divs) {
		//set up local shorthand
		uint256 _mg = userLastMiniGameChecked[_user];
		uint256 mgShare = userShareMiniGame[_user][_mg];
		uint256 mgTotal = userDivsMiniGameTotal[_user][_mg];
		uint256 mgUnclaimed = userDivsMiniGameUnclaimed[_user][_mg];
		//calculate minigame divs 
		mgShare = userMiniGameTokens[_user][_mg].mul(10 ** (precisionFactor + 1)).div(miniGameTokens[_mg] + 5).div(10);
        mgTotal = miniGameDivs[_mg].mul(mgShare).div(10 ** precisionFactor);
        mgUnclaimed = mgTotal.sub(userDivsMiniGameClaimed[_user][_mg]);

        return mgUnclaimed;
	}
	
	//helper function for up to date front end balances without state change
	function checkDivsRndView(address _user) internal view returns(uint256 _divs) {
		//set up local shorthand
		uint256 _rnd = userLastRoundChecked[_user];
		uint256 rndShare = userShareRound[_user][_rnd];
		uint256 rndTotal = userDivsRoundTotal[_user][_rnd];
		uint256 rndUnclaimed = userDivsRoundUnclaimed[_user][_rnd];
        //calculate round divs 
		rndShare = userRoundTokens[_user][_rnd].mul(10 ** (precisionFactor + 1)).div(roundTokens[_rnd] + 5).div(10);
        rndTotal = roundDivs[_rnd].mul(rndShare).div(10 ** precisionFactor);
        rndUnclaimed = rndTotal.sub(userDivsRoundClaimed[_user][_rnd]);

        return rndUnclaimed;
	}

	//helper function for up to date front end balances without state change
	function checkPrizesView(address _user) internal view returns(uint256 _prizes) {
		//local accounting
		uint256 prizeValue;
		//push cycle prizes to persistent storage
		if (cycleOver == true && userCycleChecked[_user] == false) {
			//get minigame cycle prize was in 
			uint256 mg;
			if (cyclePrizeTokenRangeIdentified == true) {
				mg = cyclePrizeInMinigame;
			} else {
				narrowCyclePrizeView();
				mg = cyclePrizeInMinigame;
			}
			//check if user won cycle prize 
			if (cylcePrizeClaimed == false && userMiniGameTokensMax[_user][mg].length > 0) {
			//check if user won minigame 
			//loop iterations bounded to a max of 10 on buy()
    			for (uint256 i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
    				if (cyclePrizeWinningNumber >= userMiniGameTokensMin[_user][mg][i] && cyclePrizeWinningNumber <= userMiniGameTokensMax[_user][mg][i]) {
    					prizeValue += cycleProgressivePot;			
    					break;
    				}
    			}
			}
		}
		//push round prizes to persistent storage
		if (userLastRoundChecked[_user] < userLastRoundInteractedWith[_user] && roundCount > userLastRoundInteractedWith[_user]) {
			//get minigame round prize was in 
			uint256 mgp;
			uint256 _ID = userLastRoundChecked[_user];
			if (roundPrizeTokenRangeIdentified[_ID] == true) {
				mgp = roundPrizeInMinigame[_ID];
			} else {
				narrowRoundPrizeView(_ID);
				mgp = roundPrizeInMinigame[_ID];
			}
			//check if user won round prize
			for (i = 0; i < userMiniGameTokensMin[_user][mgp].length; i++) {
				if (roundPrizeNumber[_ID] >= userMiniGameTokensMin[_user][mgp][i] && roundPrizeNumber[_ID] <= userMiniGameTokensMax[_user][mgp][i]) {
					prizeValue += roundPrizePot[mgp];	
					break;
				}
			}
		}
		//push minigame prizes to persistent storage
		if (userLastMiniGameChecked[_user] < userLastMiniGameInteractedWith[_user] && miniGameCount > userLastMiniGameInteractedWith[_user]) {
			//check if user won minigame 
			mg = userLastMiniGameInteractedWith[_user];
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGamePrizeNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGamePrizeNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					prizeValue += miniGamePrizePot[mg];			
					break;
				}
			}
			//check if user won airdrop
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGameAirdropNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGameAirdropNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					prizeValue += miniGameAirdropPot[mg];
					break;
				}
			}
		}
		return prizeValue;
	}

	//helper function for up to date front end balances without state change
	function narrowRoundPrizeView(uint256 _ID) internal view returns(uint256 _miniGameID) {
		//set up local accounting
		uint256 winningNumber = roundPrizeNumber[_ID];
		uint256 miniGameRangeMin; 
		uint256 miniGameRangeMid;
		uint256 miniGameRangeMax;
		uint256 mg;
		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMid = 100;
			miniGameRangeMax = 50;
		} else if (_ID >= 2 && _ID <= 100) {
			miniGameRangeMin = _ID.mul(100);
			miniGameRangeMid = _ID.mul(100) + 100;
			miniGameRangeMax = _ID.mul(100) + 50;
		}	
		//loop through each minigame to check prize number
		//split in two ranges to save gas on loop
		//log so this only needs to be called once per prize 
        if (winningNumber >= miniGameRangeMid) {
            for (uint i = miniGameRangeMid; i <= miniGameRangeMax; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    mg = miniGameRangeMin + (i - 1);
                    return mg;
                    break;
                }
            }
        } else if (winningNumber < miniGameRangeMid) {
            for (i = 1; i < miniGameRangeMid; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    mg = miniGameRangeMin + (i - 1);
                    return mg;
                    break;
                }
            }
        }		
	}

	//helper function for up to date front end balances without state change
	function narrowCyclePrizeView() internal view returns(uint256 _miniGameID) {
		//set up local accounting
		uint256 winningNumber = cyclePrizeWinningNumber;
		uint256 rnd;
		//first identify round 
        if (winningNumber >= roundTokenRangeMin[50]) {
            for (uint256 i = 50; i <= roundCount; i++) {
                if (winningNumber >= roundTokenRangeMin[i] && winningNumber <= roundTokenRangeMax[i]) {
                    rnd = i;
                    break;
                }
            }
        } else if (winningNumber < roundTokenRangeMin[50]) {
            for (i = 1; i < 50; i++) {
                if (winningNumber >= roundTokenRangeMin[i] && winningNumber <= roundTokenRangeMax[i]) {
                    rnd = i;
                    break;
                }
            }
        }	
        //set up minigame local accounting 
        uint256 miniGameRangeMin; 
		uint256 miniGameRangeMid;
		uint256 miniGameRangeMax;
		uint256 _ID = rnd;
		uint256 mg;

		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMid = 100;
			miniGameRangeMax = 50;
		} else if (_ID >= 2 && _ID <= 100) {
			miniGameRangeMin = _ID.mul(100);
			miniGameRangeMid = _ID.mul(100) + 100;
			miniGameRangeMax = _ID.mul(100) + 50;
		}
		//then loop through each minigame to check prize number
		//split in two ranges to save gas on loop
		//log so this only needs to be called once per prize 
        if (winningNumber >= miniGameRangeMid) {
            for (i = miniGameRangeMid; i <= miniGameRangeMax; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    mg = miniGameRangeMin + (i - 1);
                    return mg;
                    break;
                }
            }
        } else if (winningNumber < miniGameRangeMid) {
            for (i = 1; i < miniGameRangeMid; i++) {
                if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
                    mg = miniGameRangeMin + (i - 1);
                    return mg;
                    break;
                }
            }
        }		
	}
}
