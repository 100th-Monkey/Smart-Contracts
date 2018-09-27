pragma solidity ^0.4.25;

//@testing: check edge case of single user buying entire minigame

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
	uint256 public adminBalance;
	address public adminBank;
	address[] public admins;
	address[] public whiteListedContracts;
	mapping (address => bool) public isAdmin;
	mapping (address => bool) public isWhitelisted;

	//global
	bool public gameActive = false;
	bool public earlyResolveACalled = false;
	bool public earlyResolveBCalled = false;
	uint256 public miniGamesPerRound = 4; //@dev lowered for testing 
	uint256 public miniGamesPerCycle = 1000;
	uint256 public miniGamePotRate = 25; //25%, less seed awards 
	uint256 public progressivePotRate = 25; //25%
	uint256 public roundPotRate = 48; //48% of progressive pot 
	uint256 public miniGameDivRate = 10; //10%
	uint256 public roundDivRate = 20; //20%
	uint256 public miniGameAirdropRate = 5; //5%
	uint256 public adminFeeRate = 5; //5%
	uint256 public referralRate = 10; //10%
	uint256 public precisionFactor = 6; //percentages precise to 0.0001%
	uint256 public seedAreward = 25000000000000000; //0.025 ETH
	uint256 public seedBreward = 25000000000000000; //0.025 ETH
	mapping (uint256 => bool) public miniGameSeedAawarded;
	mapping (uint256 => bool) public miniGameSeedBawarded;
	
	//RNG
    uint256 public salt = 0;
    uint256 public RNGblockDelay = 1;
    bytes32 public hashA;
    bytes32 public hashB;

	//mini-game tracking
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

	//round tracking
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

	//cycle tracking
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

	//tokens
	uint256 public tokenPrice = 0.001 ether;
	uint256 public tokenPriceIncrement = 0.0005 ether;

	//user tracking
	mapping (address => bool) public userCycleChecked;
	mapping (address => uint256) public userTokens;
	mapping (address => uint256) public userBalance;
	mapping (address => uint256) public userLastMiniGameInteractedWith;
	mapping (address => uint256) public userLastRoundInteractedWith;
	mapping (address => uint256) public userLastMiniGameChecked;
	mapping (address => uint256) public userLastRoundChecked;
	mapping (address => mapping (uint256 => uint256)) public userMiniGameTokens;
	mapping (address => mapping (uint256 => uint256)) public userRoundTokens;
	mapping (address => mapping (uint256 => uint256)) public userShareMiniGame;
	mapping (address => mapping (uint256 => uint256)) public userDivsMiniGameTotal;
	mapping (address => mapping (uint256 => uint256)) public userDivsMiniGameClaimed;
	mapping (address => mapping (uint256 => uint256)) public userDivsMiniGameUnclaimed;
	mapping (address => mapping (uint256 => uint256)) public userShareRound;
	mapping (address => mapping (uint256 => uint256)) public userDivsRoundTotal;
	mapping (address => mapping (uint256 => uint256)) public userDivsRoundClaimed;
	mapping (address => mapping (uint256 => uint256)) public userDivsRoundUnclaimed;
	mapping (address => mapping (uint256 => uint256[])) public userMiniGameTokensMin;
	mapping (address => mapping (uint256 => uint256[])) public userMiniGameTokensMax;


//CONSTRUCTOR

	constructor(address _adminBank) public {
		//set dev bank address and admins
		adminBank = _adminBank;
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
		//add other admins here 
	}


//MODIFIERS

	modifier onlyAdmins() {
		require (isAdmin[msg.sender] == true, "you must be an admin");
		_;
	}

	modifier onlyHumans() { 
        require (msg.sender == tx.origin || msg.sender == adminBank || isWhitelisted[msg.sender] == true, "only approved contracts allowed"); 
        _; 
    }

    modifier gameOpen() {
    	require (gameActive == true, "the game must be open");
    	if (miniGameProcessing == true) {
    		require (block.number > miniGameProcessingBegun + RNGblockDelay, "the round is still processing. try again soon");
    	}
    	_;
    }
    

//EVENTS

	//add events for any state change or for other logging purposes 

	event adminWithdrew(
		uint256 _amount,
		address _caller,
		string _message 
	);

	event cycleStarted(
		address _caller,
		string _message
	);

	event adminAdded(
		address _caller,
		address _newAdmin,
		string _message
	);

	event resolvedEarly(
		address _caller,
		uint256 _pot,
		string _message
	);

	event processingRestarted(
		address _caller,
		string _message
	);

	event contractDestroyed(
		address _caller,
		uint256 _balance,
		string _message
	);

	event userBought(
		address _user,
		uint256 _tokensBought,
		uint256 _miniGameID,
		string _message
	);

	event userReinvested(
		address _user,
		uint256 _amount,
		string _message
	);

	event userWithdrew(
		address _user,
		uint256 _amount,
		string _message
	);

	event processingStarted(
		address _caller,
		uint256 _miniGameID,
		uint256 _blockNumber,
		string _message
	);

	event processingFinished(
		address _caller,
		uint256 _miniGameID,
		uint256 _blockNumber,
		string _message
	);

	event newMinigameStarted(
		uint256 _miniGameID,
		uint256 _newTokens,
		string _message
	);

	event miniGamePrizeAwarded(
		uint256 _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event miniGameAirdropAwarded(
		uint256 _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event roundPrizeAwarded(
		uint256 _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event referralAwarded(
		uint256 _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event cyclePrizeAwarded(
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event whitelistAdded(
		address _caller,
		address _contract,
		string _message
	);

	event whitelistRemoved(
		address _caller,
		address _contract,
		string _message
	);

//ADMIN FUNCTIONS

	function adminWithdraw() external onlyAdmins() onlyHumans() {
		uint256 balance = adminBalance;
		adminBalance = 0;

		adminBank.transfer(balance);

		emit adminWithdrew(balance, msg.sender, "an admin just withdrew");
	}

	function startCycle() external onlyAdmins() onlyHumans() {
		require (gameActive == false && cycleCount == 0, "the cycle has already been started");
		gameActive = true;

		cycleStart();
		roundStart();
		miniGameStart();

		emit cycleStarted(msg.sender, "a new cycle just started"); 

	}

	//@dev remove this function?, only add admins during constructor?
	function addAdmin(address _newAdmin) external onlyAdmins() onlyHumans() {
		admins.push(_newAdmin);
		isAdmin[_newAdmin] = true;

		emit adminAdded(msg.sender, _newAdmin, "a new admin was added");
	}

	function earlyResolveA() external onlyAdmins() onlyHumans() gameOpen() {
		require (now > miniGameStartTime[miniGameCount] + 604800, "earlyResolveA cannot be called yet"); //1 week
		gameActive = false;
		earlyResolveACalled = true;
		generateSeedA();
	}

	function earlyResolveB() external onlyAdmins() onlyHumans() {
		require (earlyResolveACalled == true && earlyResolveBCalled == false && miniGameProcessing == true && block.number > miniGameProcessingBegun + RNGblockDelay, "earlyResolveB cannot be called yet"); 
		earlyResolveBCalled = true;
		resolveCycle();

		emit resolvedEarly(msg.sender, cycleProgressivePot, "the cycle was resolved early"); 
	}

	function restartMiniGame() external onlyAdmins() onlyHumans() {
		require (miniGameProcessing == true && block.number > miniGameProcessingBegun + 256, "restartMiniGame cannot be called yet");
		generateSeedA();

		emit processingRestarted(msg.sender, "mini-game processing was restarted");
	}

	function zeroOut() external onlyAdmins() onlyHumans() {
		//admins can close the contract no sooner than 90 days after a full cycle completes 
        require (now >= cycleEnded + 90 days && cycleOver == true, "too early to close the contract"); 
        uint256 balance = address(this).balance;
        //selfdestruct and transfer to dev bank 
        selfdestruct(adminBank);

        emit contractDestroyed(msg.sender, balance, "contract destroyed");
    }

    //admin has ability to whitelist contracts. for example: external game or vetted user multisig 
    function addWhitelistContract (address _address) external onlyAdmins() onlyHumans() {
    	whiteListedContracts.push(_address);
    	isWhitelisted[_address] = true;
    	emit whitelistAdded(msg.sender, _address, "new contract added to whitelist");
    }

    function removeWhitelistContract (address _address) external onlyAdmins() onlyHumans() {
    	isWhitelisted[_address] = false;
    	emit whitelistRemoved(msg.sender, _address, "contract removed from whitelist");
    }


//USER FUNCTIONS

	function () external payable {
		//funds sent directly to contract will trigger buy
		//no refferal on fallback 
		buy(msg.value, 0x0);
	}

	function buy(uint256 _amount, address _referral) public payable onlyHumans() gameOpen() {
		_amount = msg.value;
		//checks
		require (_amount >= tokenPrice, "you must buy at least one token");
		//check to ensure the user will not break the loop when checking for winning prizes; should never be reached under normal circumstances
		require (userMiniGameTokensMin[msg.sender][roundCount].length < 10, "you are buying too often in this round"); 

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
       		// if no referral used, add to progessive pot 
       		cycleProgressivePot += referralShare;
       	}

		//divide msg.value by various percentages and distribute
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

       	//global token accounting 
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
	
	function reinvest(uint256 _amount, address _referral) external onlyHumans() gameOpen() {
		//update userBalance()
		updateUserBalance(msg.sender);

		//checks
		require (_amount <= userBalance[msg.sender], "insufficient balance");
		require (_amount >= tokenPrice, "you must buy at least one token");

		//take funds from user persistent storage and buy
		uint256 remainingBalance = userBalance[msg.sender].sub(_amount);
		userBalance[msg.sender] = remainingBalance;
		
		buy(_amount, _referral);

		emit userReinvested(msg.sender, _amount, "a user reinvested");

	}

	function withdraw() external onlyHumans() {
		//update userBalance()
		updateUserBalance(msg.sender);

		//checks
		require (userBalance[msg.sender] > 0, "no balance to withdraw");
		require (userBalance[msg.sender] <= address(this).balance, "you cannot withdraw more than the contract holds");

		//update user accounting and transfer
		uint256 toTransfer = userBalance[msg.sender];
		userBalance[msg.sender] = 0;
		msg.sender.transfer(toTransfer);

		emit userWithdrew(msg.sender, toTransfer, "a user withdrew");
	}


//VIEW FUNCTIONS
	
	//helper function to return contract balance 
	function contractBalance() external view returns(uint256 _contractBalance) {
        return address(this).balance;
    }

    //helper function for adminBank interface
    function checkAdminBalance() external view returns(uint256 _adminBalance) {
    	return adminBalance;
    }

    //check for user divs available
    function checkUserDivsAvailable(address _user) external /*view*/ returns(uint256 _userDivsAvailable) {
    	//@dev refactor with local variables so it does not cause a state change
    	updateUserBalance(_user);
    	return userBalance[_user];
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


//INTERNAL FUNCTIONS

	function checkDivs(address _user) internal {
		//minigame divs 
		userShareMiniGame[_user][userLastMiniGameChecked[_user]] = userMiniGameTokens[_user][userLastMiniGameChecked[_user]].mul(10 ** (precisionFactor + 1)).div(miniGameTokens[userLastMiniGameChecked[_user]] + 5).div(10);
        userDivsMiniGameTotal[_user][userLastMiniGameChecked[_user]] = miniGameDivs[userLastMiniGameChecked[_user]].mul(userShareMiniGame[_user][userLastMiniGameChecked[_user]]).div(10 ** precisionFactor);
        userDivsMiniGameUnclaimed[_user][userLastMiniGameChecked[_user]] = userDivsMiniGameTotal[_user][userLastMiniGameChecked[_user]].sub(userDivsMiniGameClaimed[_user][userLastMiniGameChecked[_user]]);
        //add to user balance
        if (userDivsMiniGameUnclaimed[_user][userLastMiniGameChecked[_user]] > 0) {
            //sanity check
            assert(userDivsMiniGameUnclaimed[_user][userLastMiniGameChecked[_user]] <= address(this).balance);

            userDivsMiniGameClaimed[_user][userLastMiniGameChecked[_user]] = userDivsMiniGameTotal[_user][userLastMiniGameChecked[_user]];
            uint256 shareTempMg = userDivsMiniGameUnclaimed[_user][userLastMiniGameChecked[_user]];
            userDivsMiniGameUnclaimed[_user][userLastMiniGameChecked[_user]] = 0;
	        
	        userBalance[_user] += shareTempMg;
        }

        //round divs 
		userShareRound[_user][userLastRoundChecked[_user]] = userRoundTokens[_user][userLastRoundChecked[_user]].mul(10 ** (precisionFactor + 1)).div(roundTokens[userLastRoundChecked[_user]] + 5).div(10);
        userDivsRoundTotal[_user][userLastRoundChecked[_user]] = roundDivs[userLastRoundChecked[_user]].mul(userShareRound[_user][userLastRoundChecked[_user]]).div(10 ** precisionFactor);
        userDivsRoundUnclaimed[_user][userLastRoundChecked[_user]] = userDivsRoundTotal[_user][userLastRoundChecked[_user]].sub(userDivsRoundClaimed[_user][userLastRoundChecked[_user]]);
        //add to user balance
        if (userDivsRoundUnclaimed[_user][userLastRoundChecked[_user]] > 0) {
            //sanity check
            assert(userDivsRoundUnclaimed[_user][userLastRoundChecked[_user]] <= address(this).balance);
            userDivsRoundClaimed[_user][userLastRoundChecked[_user]] = userDivsRoundTotal[_user][userLastRoundChecked[_user]];
            uint256 shareTempRnd = userDivsRoundUnclaimed[_user][userLastRoundChecked[_user]];
            userDivsRoundUnclaimed[_user][userLastRoundChecked[_user]] = 0;
	        
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
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGameAirdropNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGameAirdropNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					userBalance[_user] += miniGameAirdropPot[mg];
					miniGameAirdropClaimed[mg] = true;
					miniGameAirdropWinner[mg] = msg.sender;
					break;
				}
			}
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
		if (tokenSupply != 0) {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply + 1;
		} else {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply;
		}
		miniGameTokens[miniGameCount] = generateTokens();
		miniGameTokensLeft[miniGameCount] = miniGameTokens[miniGameCount];
		miniGameTokenRangeMax[miniGameCount] = tokenSupply;
		cycleActiveTokens = 0;
		if (miniGameCount > 1) {
			tokenPrice += tokenPriceIncrement;
		}

		if (miniGameCount % miniGamesPerRound == 0) {
			roundStart();
		}

		emit newMinigameStarted(miniGameCount, miniGameTokens[miniGameCount], "new minigame started");
	}

	function roundStart() internal {
		require (cycleOver == false, "the cycle cannot be over");
		roundCount++;
		roundStartTime[roundCount] = now;
		if (tokenSupply != 0) {
			roundTokenRangeMin[roundCount] = tokenSupply + 1;
		} else {
			roundTokenRangeMax[roundCount] = tokenSupply;
		}
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
		//generate the tokens 
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 randTokens = uint256(hash).mod(1000);
        uint256 newRoundTokens = randTokens + 1000;
		tokenSupply += newRoundTokens;
		salt++;
		return newRoundTokens;
	}

	function generateSeedA() internal {
		//checks 
		//can be called again if generateSeedB is not tiggered within 256 blocks 
		require (miniGameProcessing == false || miniGameProcessing == true && block.number > miniGameProcessingBegun + 256, "seed A cannot be regenerated right now");
		require (miniGameTokensLeft[miniGameCount] == 0 || earlyResolveACalled == true, "active tokens remain in this minigame");
		
		//generate seed 
		miniGameProcessing = true;
		miniGameProcessingBegun = block.number;

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

		emit processingStarted(msg.sender, miniGameCount, block.number, "processing started");
	}

	function generateSeedB() internal {
		hashB = blockhash(miniGameProcessingBegun + RNGblockDelay);

		awardMiniGamePrize();
		awardMiniGameAirdrop();

		if (miniGameCount % miniGamesPerRound - 1 == 0 && miniGameCount > 2) {
			awardRoundPrize();
		}

		if (miniGameCount % miniGamesPerCycle - 1 == 0 && miniGameCount > 2) {
			awardCyclePrize();
			gameActive = false;
		}

		//award processing bounty 
		if (miniGameSeedBawarded[miniGameCount] == false) {
			userBalance[msg.sender] += seedBreward;
			miniGameSeedBawarded[miniGameCount] = true;
		}

		miniGameStart();

		miniGameProcessing = false;

		emit processingFinished(msg.sender, miniGameCount, block.number, "processing finished");
	}

	function awardMiniGamePrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount]);
        miniGamePrizeNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
        salt++;

        miniGamePrizePot[miniGameCount] = miniGamePrizePot[miniGameCount].sub(seedAreward).sub(seedBreward);

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
        salt++;

        //calculate round prize here 
        uint256 roundPrize = cycleProgressivePot.mul(roundPotRate).div(100);
		uint256 adminShare = cycleProgressivePot.mul(4).div(100);
		adminBalance += adminShare;
        roundPrizePot[roundCount] = roundPrize;
        cycleProgressivePot = roundPrize;

		emit roundPrizeAwarded(roundCount, winningNumber, roundPrize, "round prize awarded");
	}

	function awardCyclePrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
        uint256 winningNumber = uint256(hash).mod(tokenSupply);
        cyclePrizeWinningNumber = winningNumber;
        salt++;

		emit cyclePrizeAwarded(winningNumber, cycleProgressivePot, "cycle prize awarded");
	}

	function resolveCycle() internal {
		//generate hashB here in instead of calling generateSeedB
		hashB = blockhash(miniGameProcessingBegun + RNGblockDelay);

		//@dev confirm that the following functions will work correctly when called mid-round
		awardMiniGamePrize();
		awardMiniGameAirdrop();
		awardRoundPrize();
		awardCyclePrize();

		miniGameProcessing = false;
		gameActive = false;
	}

	function narrowRoundPrize(uint256 _ID) internal returns(uint256 _miniGameID) {
		//narrows down the token range of a round to a specific miniGame

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

	function narrowCyclePrize() internal returns(uint256 _miniGameID) {
		//narrows down the token range of a round to a specific miniGame

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

        //set up minigame log accounting 
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

}
