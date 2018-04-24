/**
    Current Scenario: Special Purpose Vehicle(SPV) is formed.
    Collateral Account is formed and principle amount is already deposited from Investors.
    No of Bonds is 3
    Number of investors already fixed to 3
    Bonds are issued to Investors. 1 bond per investor
    Number of Sponsors/Insurance Company is kept to 1
    
    Functions/Operations: 
    1) Receive monthly Premeiums from sponsors.
    2) Send monthly Interest/Coupon to investors.
    3) Investor payout
    4) Sponsor payout
    5) Set event trigger

    Predefined Values: Coverage to Sponsor/Insurance Companies, Bond Face Value, Number of bonds to be issued, Number of investors.
*/

pragma solidity ^0.4.8;

contract Admined {
    
    address public admin;

    /**
        constructor
    */    
    constructor() public {
        admin = msg.sender; //making SPV as admin
    }
    
    /** 
        modifier: allows execution by the admin only 
    */    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /**
        Allows transferring the contract ownership

        @param _newAdmin    new contract owner
    */    
    function transferAdminship(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }
}

contract CatBond is Admined {
    
    uint256 public _sponsorCoverage;  // set it to 30000
    uint256 public _collateralAccountBalance; // should be more than or equal to Sponsor Coverage i.e. 30000
    uint _numberOfBondsForSale = 3;
    uint _numberOfInvestors = 3;
    uint _numberOfSponsor = 1; 
    uint256 _bondFaceValue; // set it to 10000
    uint256 public _premiumAmount; // set it to 300
    uint256 public _couponAmount; // set it to 100
    uint _bondValidity = 12; //in months
    bool public _eventTrigger = false; //false - event not yet occured, true - event occured 
    uint256 public _receiverBalance;
        
    mapping(address => uint256) public balanceOf;

    //EVENTS
    // received funds from an address (record how much).
    event receivedFunds(address _from, uint256 _amount);
    // transfer funds from an address
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    
    /**
        constructor
    */  
    constructor(uint256 _spnsrCoverage, uint256 _cltrlAccBalance, uint256 _bndFcValue, uint256 _premiumAmt, uint256 _cpnAmt) public {
        _sponsorCoverage = _spnsrCoverage;
        _collateralAccountBalance = _cltrlAccBalance;
        _bondFaceValue = _bndFcValue;
        _premiumAmount = _premiumAmt;
        _couponAmount = _cpnAmt;
    }

    /**
        Function to maintain address balance records before any other operations
        
        @param _address  address of the account
        @param _value  amount to be stored in an account
    */
    function maintainAddressBalance(address _address, uint256 _value) public {
        balanceOf[_address] = _value;
    }

    /**
        Function to transfer funds between accounts
        
        @param _from  address from which amount is transfered
        @param _to  address to which amount is transfered
        @param _value  amount to be stored in an account
        @param _data  data passed along the transfer
    */    
    function transferFund(address _from, address _to, uint256 _value, bytes _data) public returns (bool success) {
        if(balanceOf[_from] > _value) {
                balanceOf[_from] -= _value;
                balanceOf[_to] += _value;
        }
        emit Transfer(_from,_to,_value,_data);
        return true;
    }    
    
    /**
        Function to set the trigger event to either true or false
        
        @param _setTriggerValue  trigger value i.e. true or false
    */    
    function setEventTrigger(bool _setTriggerValue) public {
        _eventTrigger = _setTriggerValue;
    }
    
    /**
        Function to make regular premium payment from Sponsor to SPV
        
        @param _from  address from which amount is transfered
        @param _to  address to which amount is transfered
        @param _currentAgeOfBond  number of months since bond purchase
        @param _data  data passed along the transfer
    */    
    function monthlyPremiumPayment(address _to, address _from, uint _currentAgeOfBond, bytes _data) public {
        require((!_eventTrigger) && (_currentAgeOfBond <= _bondValidity));
        require(_to != address(0)); //not sending to burn address
        require(_premiumAmount>0); // and the amount is not zero or negative
        transferFund(_from, _to, _premiumAmount, _data);
        _collateralAccountBalance += _premiumAmount;
//        _to.transfer(_premiumAmount); //pay premium
//        _receiverBalance = _to.balance;
    }    

    /**
        Function to make regular coupon/interest payment from SPV to Investors
        
        @param _from  address from which amount is transfered
        @param _to  address to which amount is transfered
        @param _currentAgeOfBond  number of months since bond purchase
        @param _data  data passed along the transfer
    */    
    function monthlyCouponPayment(address _to, address _from, uint _currentAgeOfBond, bytes _data) public onlyAdmin{
        require((!_eventTrigger) && (_currentAgeOfBond <= _bondValidity));
        require(_couponAmount>0 && _couponAmount < _collateralAccountBalance); // and the amount is not zero or negative
        require(_to != address(0)); //not sending to burn address
        transferFund(_from, _to, _couponAmount, _data);
        _collateralAccountBalance -= _couponAmount;
//        _to.transfer(_couponAmount); //pay interest/coupon to investors
//        _receiverBalance = _to.balance;
    }
    
    /**
        Function to perform final settlement with investors
        
        @param _from  address from which amount is transfered
        @param _to  address to which amount is transfered
        @param _currentAgeOfBond  number of months since bond purchase
        @param _data  data passed along the transfer
    */    
    function investorsPayout(address _to, address _from, uint _currentAgeOfBond, bytes _data) public onlyAdmin{
        require((!_eventTrigger) && (_currentAgeOfBond > _bondValidity));
        require(_to != address(0)); //not sending to burn address
        require(_collateralAccountBalance >= _bondFaceValue);
        transferFund(_from, _to, _bondFaceValue, _data);
        _collateralAccountBalance -= _bondFaceValue;
//        _to.transfer(_bondFaceValue); //pay interest/coupon to investors
//        _receiverBalance = _to.balance;
    }
    
    /**
        Function to perform final settlement with Sponsors/Insurance Companies
        
        @param _from  address from which amount is transfered
        @param _to  address to which amount is transfered
        @param _currentAgeOfBond  number of months since bond purchase
        @param _data  data passed along the transfer
    */    
    function sponsorsPayout(address _to, address _from, uint _currentAgeOfBond, bytes _data) public onlyAdmin{
        require((_eventTrigger) && (_currentAgeOfBond <= _bondValidity));
        require(_to != address(0)); //not sending to burn address
        require(_collateralAccountBalance >= _sponsorCoverage); // and the amount is not zero or negative
        transferFund(_from, _to, _sponsorCoverage, _data);
        _collateralAccountBalance -= _sponsorCoverage;
//        _to.transfer(_sponsorCoverage);
//        _receiverBalance = _to.balance;
    }

    /**
        Function to Kill the Contract
    */    
    function kill() public onlyAdmin {
        selfdestruct(admin);
    }    
    
    /**
        gets called when no other function matches
    */    
    function() payable public {
        if (msg.value > 0)
            emit receivedFunds(msg.sender, msg.value);
    }
    
}