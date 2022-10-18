// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
//  CrowdFunding Smart Contract
// This smart contract will try to solve transparency in crowdfunding projects, by making the contributors vote for the money spending decisions
// and be able to withdraw the money if goal is not reached. 
contract CrowdFunding{
    mapping(address => uint) public contributors;
    address public owner;
    uint public numberContr;
    uint public goal;
    uint public minContr;                                                           //min contribution possible 
    uint public deadline;                                                           //needs to be a timestamp
    uint public raised;
    struct Request{
        string description;
        address payable target;
        uint value;
        bool completed;
        uint numberOfVotes;
        mapping(address=>bool) voters;
    }
    mapping(uint=> Request) public requests;
    uint public numRequest;

    constructor(uint _goal, uint _deadline){
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minContr = 100 wei;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _target, uint _value);
    event MakePaymentEvent(address _target, uint _value);

    modifier ended(){
        require(block.timestamp > deadline,"The CrowdFunding is still going on");
        _;
    }

     modifier stillGoing(){
        require(block.timestamp < deadline,"The CrowdFunding has already ended");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    function contribute() public payable stillGoing{
        require(msg.value >= minContr, "Minimum contribution is 100 wei");
        if(contributors[msg.sender]==0){                                            
            numberContr++;
        }
        contributors[msg.sender] += msg.value;
        raised += msg.value;

        emit ContributeEvent (msg.sender, msg.value);
    }

    receive() payable external{
        contribute();                                                              //calls contribute() in case they send money without calling that function
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getRefund() public ended{
       require(raised < goal && contributors[msg.sender] > 0);
       payable(msg.sender).transfer(contributors[msg.sender]);
       raised -= contributors[msg.sender];                                        // raised can be used to control when all the funds were withdraw (raised = 0)
       contributors[msg.sender] = 0;                                              //reset contributor's contribution to avoid multiple withdraws
    }

    function spendingRequest(string memory _description, address payable _target, uint _value) public onlyOwner{
        Request storage newRequest = requests[numRequest];                         
        numRequest++;

        newRequest.description = _description;
        newRequest.target = _target;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numberOfVotes = 0;

        emit CreateRequestEvent(_description, _target, _value);
    }
    
    //this function isnt a yes/no vote, is to accept a request the admin is doing to spend funds
    function acceptRequest(uint _requestNum) public{
        require(contributors[msg.sender]>0, "You're not a contributor");
        Request storage thisRequest = requests[_requestNum];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");    //contributors can vote only once
        thisRequest.voters[msg.sender] == true;
        thisRequest.numberOfVotes++;
    }

    function fulfillRequest(uint _requestNum) public onlyOwner{
        require(raised >= goal);
        Request storage thisRequest = requests[_requestNum];
        require(thisRequest.completed == false, "Request already completed");
        require(thisRequest.numberOfVotes > numberContr / 2);                        // 50% of contributors accepted request condition

        thisRequest.target.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.target, thisRequest.value);
    }
}