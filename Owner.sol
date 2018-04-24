/**
 * Owner contract defines the msg.sender as the contract owner.
 * Modifier onlyOwner(): certain peice of code will run only by owner where this modifier is used.
 * Function transferOwnership(): changes the ownership of contract.
 */

pragma solidity ^0.4.8;

contract Owner {
    
    address public owner;

    /**
        constructor
    */    
    constructor() public {
        owner = msg.sender; //making SPV as admin
    }
    
    /** 
        modifier: allows execution by the admin only 
    */    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
        Allows transferring the contract ownership

        @param _newAdmin    new contract owner
    */    
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
