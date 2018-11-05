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

contract FoundationFund {

	using SafeMath for uint256;

	//CONSTANTS

	uint256 public fundsReceived;
	address public masterAdmin;
	address public mainContract;
	bool public mainContractSet = false;

	//note addresses cannot be contracts or funds may be lost on transfer 
	address public teamMemberA = 0x0; //@dev set here, not in constructor 
	address public teamMemberB = 0x0;
	address public teamMemberC = 0x0;
	address public teamMemberD = 0x0;

	uint256 public teamMemberArate = 25; //25% example
	uint256 public teamMemberBrate = 25; //25% example
	uint256 public teamMemberCrate = 25; //25% example
	uint256 public teamMemberDrate = 25; //25% example

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
	event fundsIn(
		uint256 _amount,
		address _sender,
		uint256 _time,
		uint256 _totalFundsReceived
	);

	event fundsOut(
		uint256 _amount,
		address _receiver,
		uint256 _time
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
		}
		
		//update accounting 
		uint256 teamMemberShare = fundsReceived.mul(rate).div(100);
		teamMemberTotal[user] = teamMemberShare;
		teamMemberUnclaimed[user] = teamMemberTotal[user].sub(teamMemberClaimed[user]);
		
		//safe transfer 
		uint256 toTransfer = teamMemberUnclaimed[user];
		teamMemberUnclaimed[user] = 0;
		teamMemberClaimed[user] = teamMemberTotal[user];
		user.transfer(toTransfer);

		emit fundsOut(toTransfer, user, now);
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
		} else {
			return 0;
		}

		uint256 teamMemberShare = fundsReceived.mul(rate).div(100);
		uint256 unclaimed = teamMemberShare.sub(teamMemberClaimed[_user]); 

		return unclaimed;
	}

	function contractBalance() public view returns(uint256 _contractBalance) {
	    return address(this).balance;
	}

	//FALLBACK

	function () public payable {
		fundsReceived += msg.value;
		emit fundsIn(msg.value, msg.sender, now, fundsReceived); 
	}
}
