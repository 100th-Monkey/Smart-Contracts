pragma solidity ^0.4.25;

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

//CONTRACT INTERFACE

contract OneHundredthMonkey {
 	function adminWithdraw() public {}	
}

//MAIN CONTRACT

contract AdminBank {

	using SafeMath for uint256;

	//CONSTANTS

	uint256 public fundsReceived;
	address public masterAdmin;
	address public mainContract;
	bool public mainContractSet = false;

	address public teamMemberA = 0x2597afE84661669E590016E51f8FB0059D1Ad63e; 
	address public teamMemberB = 0x2E6C1b2B4F7307dc588c289C9150deEB1A66b73d; 
	address public teamMemberC = 0xB3CaC7157d772A7685824309Dc1eB79497839795; 
	address public teamMemberD = 0x87395d203B35834F79B46cd16313E6027AE4c9D4; 
	address public teamMemberE = 0x2c3e0d5cbb08e0892f16bf06c724ccce6a757b1c; 
	address public teamMemberF = 0xd68af19b51c41a69e121fb5fb4d77768711c4979; 
	address public teamMemberG = 0x8c992840Bc4BA758018106e4ea9E7a1d6F0F11e5; 
	address public teamMemberH = 0xd83FAf0D707616752c4AbA00f799566f45D4400A; 
	address public teamMemberI = 0xca4a41Fc611e62E3cAc10aB1FE9879faF5012687; 

	uint256 public teamMemberArate = 20; //20%
	uint256 public teamMemberBrate = 20; //20%
	uint256 public teamMemberCrate = 15; //15%
	uint256 public teamMemberDrate = 15; //15%
	uint256 public teamMemberErate = 7; //7%
	uint256 public teamMemberFrate = 4; //4%
	uint256 public teamMemberGrate = 4; //4%
	uint256 public teamMemberHrate = 5; //5%
	uint256 public teamMemberIrate = 10; //10%

	mapping (address => uint256) public teamMemberTotal;
	mapping (address => uint256) public teamMemberUnclaimed;
	mapping (address => uint256) public teamMemberClaimed;
	mapping (address => bool) public validTeamMember;

	//CONSTRUCTOR

	constructor() public {
		masterAdmin = msg.sender;
		validTeamMember[teamMemberA] = true;
		validTeamMember[teamMemberB] = true;
		validTeamMember[teamMemberC] = true;
		validTeamMember[teamMemberD] = true;
		validTeamMember[teamMemberE] = true;
		validTeamMember[teamMemberF] = true;
		validTeamMember[teamMemberG] = true;
		validTeamMember[teamMemberH] = true;
		validTeamMember[teamMemberI] = true;
	}

	//MODIFIERS
	
	modifier isTeamMember() { 
		require (validTeamMember[msg.sender] == true, "you are not a team member"); 
		_; 
	}

	modifier isMainContractSet() { 
		require (mainContractSet == true, "the main contract is not yet set"); 
		_; 
	}

	modifier onlyHumans() { 
        require (msg.sender == tx.origin, "no contracts allowed"); 
        _; 
    }

	//EVENTS
	event fundsOut(
		uint256 _amount,
		address _receiver
	);

	//FUNCTIONS

	//add main contract address 
	function setContractAddress(address _address) external onlyHumans() {
		require (msg.sender == masterAdmin);
		require (mainContractSet == false);
		mainContract = _address;
		mainContractSet = true;
	}

	//withdrawProxy
	function withdrawProxy() external isTeamMember() isMainContractSet() onlyHumans() {
		OneHundredthMonkey o = OneHundredthMonkey(mainContract);
		o.adminWithdraw();
	}

	//team member withdraw
	function teamWithdraw() external isTeamMember() isMainContractSet() onlyHumans() {
	
		//set up for msg.sender
		address user;
		uint256 rate;
		if (msg.sender == teamMemberA) {
			user = teamMemberA;
			rate = teamMemberArate;
		} else if (msg.sender == teamMemberB) {
			user = teamMemberB;
			rate = teamMemberBrate;
		} else if (msg.sender == teamMemberC) {
			user = teamMemberC;
			rate = teamMemberCrate;
		} else if (msg.sender == teamMemberD) {
			user = teamMemberD;
			rate = teamMemberDrate;
		} else if (msg.sender == teamMemberE) {
			user = teamMemberE;
			rate = teamMemberErate;
		} else if (msg.sender == teamMemberF) {
			user = teamMemberF;
			rate = teamMemberFrate;
		} else if (msg.sender == teamMemberG) {
			user = teamMemberG;
			rate = teamMemberGrate;
		} else if (msg.sender == teamMemberH) {
			user = teamMemberH;
			rate = teamMemberHrate;
		} else if (msg.sender == teamMemberI) {
			user = teamMemberI;
			rate = teamMemberIrate;
		}
		
		uint256 totalFundsIn = address(this).balance.add(fundsWithdrawn);
		uint256 teamMemberShare = totalFundsIn.mul(rate).div(100);
		teamMemberTotal[user] = teamMemberShare;
		teamMemberUnclaimed[user] = teamMemberTotal[user].sub(teamMemberClaimed[user]);
		
		//safe transfer 
		uint256 toTransfer = teamMemberUnclaimed[user];
		teamMemberUnclaimed[user] = 0;
		teamMemberClaimed[user] = teamMemberTotal[user];
		fundsWithdrawn += toTransfer;
		user.transfer(toTransfer);

		emit fundsOut(toTransfer, user);
	}

	//VIEW FUNCTIONS

	function balanceOf(address _user) public view returns(uint256 _balance) {
		address user;
		uint256 rate;
		if (_user == teamMemberA) {
			user = teamMemberA;
			rate = teamMemberArate;
		} else if (_user == teamMemberB) {
			user = teamMemberB;
			rate = teamMemberBrate;
		} else if (_user == teamMemberC) {
			user = teamMemberC;
			rate = teamMemberCrate;
		} else if (_user == teamMemberD) {
			user = teamMemberD;
			rate = teamMemberDrate;
		} else if (_user == teamMemberE) {
			user = teamMemberE;
			rate = teamMemberErate;
		} else if (_user == teamMemberF) {
			user = teamMemberF;
			rate = teamMemberFrate;
		} else if (_user == teamMemberG) {
			user = teamMemberG;
			rate = teamMemberGrate;
		} else if (_user == teamMemberH) {
			user = teamMemberH;
			rate = teamMemberHrate;
		} else if (_user == teamMemberI) {
			user = teamMemberI;
			rate = teamMemberIrate;
		} else {
			return 0;
		}

		uint256 totalFundsIn = address(this).balance.add(fundsWithdrawn);
		uint256 teamMemberShare = totalFundsIn.mul(rate).div(100);
		uint256 unclaimed = teamMemberShare.sub(teamMemberClaimed[_user]); 

		return unclaimed;
	}

	function contractBalance() public view returns(uint256 _contractBalance) {
	    return address(this).balance;
	}

	//FALLBACK

	function () public payable {}
}
