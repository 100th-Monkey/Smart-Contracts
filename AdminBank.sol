pragma solidity ^0.4.24;

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

interface OneHundredthMonkey {
 	
 	function checkAdminBalance() public {}
 	function adminWithdraw() public {}
}

contract AdminBank {

	using SafeMath for uint256;

	uint256 public fundsReceived;
	address public masterAdmin;
	address public mainContract;
	bool public mainContractSet = false;

	address public teamMemberA = 0x0;
	address public teamMemberB = 0x0;
	address public teamMemberC = 0x0;
	address public teamMemberD = 0x0;

	uint256 public teamMemberArate = 25; //25% example
	uint256 public teamMemberBrate = 25; //25% example
	uint256 public teamMemberCrate = 25; //25% example
	uint256 public teamMemberDrate = 25; //25% example

	mapping (address => uint256) public teamMemberAtotal;
	mapping (address => uint256) public teamMemberAunclaimed;
	mapping (address => uint256) public teamMemberAcalimed;

	mapping (address => uint256) public teamMemberBtotal;
	mapping (address => uint256) public teamMemberBunclaimed;
	mapping (address => uint256) public teamMemberBcalimed;

	mapping (address => uint256) public teamMemberCtotal;
	mapping (address => uint256) public teamMemberCunclaimed;
	mapping (address => uint256) public teamMemberCcalimed;

	mapping (address => uint256) public teamMemberDtotal;
	mapping (address => uint256) public teamMemberDunclaimed;
	mapping (address => uint256) public teamMemberDcalimed;

	mapping (address => bool) public validTeamMember;

	constructor() public {
		masterAdmin = msg.sender;
		validTeamMember[teamMemberA] = true;
		validTeamMember[teamMemberB] = true;
		validTeamMember[teamMemberC] = true;
		validTeamMember[teamMemberD] = true;
	}

	//add main contract address 
	function setContractAddress(address _address) public {
		require (msg.sender == masterAdmin);
		require (mainContractSet == false);
		mainContract = _address;
		mainContractSet = true;
	}

	//withdrawProxy
	function withdrawProxy() public {
		require (mainContractSet == true);
		OneHundredthMonkey ohm = OneHundredthMonkey(mainContract);
		ohm.adminWithdraw();
	}

	//balanceCheckPrize
	function balanceProxy() public {
		require (mainContractSet == true);
		OneHundredthMonkey ohm = OneHundredthMonkey(mainContract);
		ohm.checkAdminBalance();
	}

	//team member withdraw
	function teamWithdraw() public {
		require (mainContractSet == true);
		require (validTeamMember[msg.sender] == true);

		//update balance and transfer 
		//@dev refactor so this works for any team member 
		if (msg.sender == teamMemberA) {
			uint256 teamMemberShare = (fundsReceived.mul(teamMemberArate)).div(100);
			teamMemberAtotal = teamMemberShare;
			teamMemberAunclaimed = teamMemberAtotal.sub(teamMemberAclaimed);
			uint256 toTransfer = teamMemberAunclaimed;
			teamMemberAunclaimed = 0;
			teamMemberAclaimed = teamMemberAtotal;
			tranfer.teamMemberA(toTransfer);

			//log event
		}
	}

	//add view function for checking team member balance 

	function contractBalance() public view returns(uint256 _contractBalance) {
	    return address(this).balance;
	}

	fallback () public payable {
		//log ETH in
		fundsReceived += msg.value;
	}
}