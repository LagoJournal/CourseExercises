// SPDX-License-Identifier: GPL-3.0
/* Basic Lottery Smart contract
    anyone can enter by the price of 1 ether, pick random winner which gets the 90% of the pricepool,
    10% goes to owner who also is part of the contestants (lol owner kinda scamer)*/
    
pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address public owner;
    
    constructor(){
        owner = msg.sender;
        
    }

    //Creating modifier for owner only access functions
    modifier onlyOwner{
        require(msg.sender == owner, "Admin access denied");
        _;
    }

    receive() external payable{
        require(msg.value == 1 ether, "Entry price is 0.1 ether");
        require(msg.sender != owner);
        players.push(payable(msg.sender));
    }

    function getBalance() public view onlyOwner returns(uint){
        return address(this).balance;
    }

    function random() public view returns(uint){
        //Not secure way of generate random winner, can be predicted. CHANGE TO GENERATE RAND NUMBER IN CHAINLINK VRF
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }


    function pickWinner() public{
        require(players.length >= 10);
        uint rand = random();
        address payable winner;
        players.push(payable(owner)); //Admin also is part of the lottery 
        uint index = rand % players.length;
        
        payable(owner).transfer((getBalance()*10)/100); //Admin get a 10% fee
        winner = players[index];
        winner.transfer(getBalance()); //Choose the winner & send the price
        
        players = new address payable[](0); //Reset lottery

    }

    
}