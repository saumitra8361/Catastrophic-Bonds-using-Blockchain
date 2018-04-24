/**
    Current Scenario: Special Purpose Vehicle(SPV) is formed.
    Investors can now buy bonds from SPV.
    Investor have a choice in buying as many number of bonds they want to buy out of total number of bonds available for sale. So, one investor can have more than 1 bonds.
    List of investors is maintained  who are buying bonds. Containing information like: Investors Address, Valid Investor or not, Number of bonds purchased by investor and Total Value invested.
    Number of investors can vary (as list will hold the information of all the investors and list can grow as the number of investors grow)
    Above will enable in forming Collateral Account(so no need of pre defining Collateral Account Balance).
    Number of Sponsors/Insurance Company is still kept to 1.
    
    Functions/Operations: 
    1) Receive monthly Premeiums from sponsors.
    2) Send monthly Interest/Coupon to investors.
    3) Investor payout
    4) Sponsor payout
    5) Set event trigger
    6) Investros buy Bonds from SPV 

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
    
    uint256 public _sponsorCoverage;  // set it to 5000
    uint256 public _collateralAccountBalance; // should be more than or equal to Sponsor Coverage.
    uint _numberOfBondsForSale;
    uint _numberOfInvestors;
    uint _numberOfSponsor = 1; 
    uint256 public _bondFaceValue; // set it to 1000
    uint256 public _premiumAmount; // set it to 500
    uint256 public _couponAmount; // set it to 100
    uint _bondValidity = 12; //in months
    bool public _eventTrigger = false; //false - event not yet occured, true - event occured 
    uint _mapLength = 0;
    uint _mapCounter = 0;
        
    mapping(address => uint256) public balanceOf;
    mapping (uint => investorList) public myInvestorList;

    struct investorList{
        address _investorAddress;
        bool _isListed;
        uint _noOfBondPurchased;
        uint256 _valueInvested;
    }


    //EVENTS
    // received funds from an address (record how much).
    event receivedFunds(address _from, uint256 _amount);
    // transfer funds from an address
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    
    /**
        constructor
    */  
    constructor(uint256 _spnsrCoverage, uint _noOfBndsSale, uint256 _bndFcValue, uint256 _premiumAmt, uint256 _cpnAmt) public {
        _sponsorCoverage = _spnsrCoverage;
        _numberOfBondsForSale = _noOfBndsSale;
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
        Function to let investors buy bonds from SPV
        
        @param _noOfBondInvestorWantsToBuy  number of bonds purchsed by investor
	    @param _addressInvestor  address of investor
	    @param _addressSPV  address of SPV
	    @param _data  data passed along the transfer
    */    
    function buyBond(uint _noOfBondInvestorWantsToBuy, address _addressInvestor, address _addressSPV, bytes _data) public {
        uint256 _totalPurchaseValue;
        require(_noOfBondInvestorWantsToBuy > 0 && _noOfBondInvestorWantsToBuy <= _numberOfBondsForSale);
        _totalPurchaseValue = _noOfBondInvestorWantsToBuy * _bondFaceValue;
        _mapCounter++;
        myInvestorList[_mapCounter] = investorList(_addressInvestor,true,_noOfBondInvestorWantsToBuy,_totalPurchaseValue); //creation of investors list
        transferFund(_addressInvestor, _addressSPV, _totalPurchaseValue, _data);
        _collateralAccountBalance += _totalPurchaseValue;
        _numberOfBondsForSale -= _noOfBondInvestorWantsToBuy;
        _mapLength++;
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
    }    

    /**
        Function to make regular coupon/interest payment from SPV to Investors
        
        @param _from  address from which amount is transfered
        @param _currentAgeOfBond  number of months since bond purchase
        @param _data  data passed along the transfer
    */    
    function monthlyCouponPayment(address _from, uint _currentAgeOfBond, bytes _data) public onlyAdmin{
        uint256 _netCouponValue;
        require((!_eventTrigger) && (_currentAgeOfBond <= _bondValidity));
        require(_couponAmount>0 && _couponAmount < _collateralAccountBalance); // and the amount is not zero or negative
	    for(uint i = 1; i <= _mapLength; i++)
        {
            require(myInvestorList[i]._isListed); // check if investor is listed or not
            require(myInvestorList[i]._noOfBondPurchased > 0); // check if investor possess bonds or not
            _netCouponValue = _couponAmount * myInvestorList[i]._noOfBondPurchased;
            require(myInvestorList[i]._investorAddress != address(0)); //not sending to burn address
            require(_netCouponValue < _collateralAccountBalance);
            transferFund(_from, myInvestorList[i]._investorAddress, _netCouponValue, _data);
            _collateralAccountBalance -= _netCouponValue;
        }
    }
    
    /**
        Function to perform final settlement with investors
        
        @param _from  address from which amount is transfered
        @param _currentAgeOfBond  number of months since bond purchase
        @param _data  data passed along the transfer
    */    
    function investorsPayout(address _from, uint _currentAgeOfBond, bytes _data) public onlyAdmin{
        require((!_eventTrigger) && (_currentAgeOfBond > _bondValidity));
        for(uint i = 1; i <= _mapLength; i++)
        {
            require(myInvestorList[i]._isListed); // check if investor is listed or not
            require(myInvestorList[i]._noOfBondPurchased > 0); // check if investor possess bonds or not
            require(myInvestorList[i]._investorAddress != address(0)); //not sending to burn address
            require(_collateralAccountBalance >= _bondFaceValue);
            transferFund(_from, myInvestorList[i]._investorAddress, myInvestorList[i]._valueInvested, _data);
            _collateralAccountBalance -= myInvestorList[i]._valueInvested;
        }
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