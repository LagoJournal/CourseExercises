// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/* 
    Contract of a basic Auction, takes the maximum ammount a bidder is willing to pay for, wont pay the entire amount if is the highestbidder, it will cost him the lastest highestbid plus an incremental
*/

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    
    enum State {Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBid;                                                                          // not the final bid, will take in consideration how much is willing to pay
    address payable public highestBidder;
    
    mapping(address => uint) public bids;
    uint bidIncrement;

    constructor(address eoa){                                                                       //note for myself: eoa == externally owned address
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 40320;                                                              //Set the auction time to 1 week, 1 block per 15 seconds, 604800s in a week, 40320 blocks generated in a week
        ipfsHash = "";
        bidIncrement = 100;                                                                         //Bid increment set to 100 wei
    }

    // This modifiers would be usefull for setting restrictions in later functions
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

    modifier notOwner(){
        require(msg.sender!=owner);
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
  
    function min(uint a, uint b) pure internal returns(uint){
        if (a<=b){
            return a;
        }else{
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running && msg.value >= 100);              //to place a bid, the auction has to be running and cant be less than 100 wei

        uint currentBid = bids[msg.sender] + msg.value;                         //takes msg.sender acumulative bid
        require(currentBid > highestBid);                                       // will pass only if bid is higher than the current one
        if(currentBid <= bids[highestBidder]){                                  // if bid isnt higher than how much the highestBidder is willing to pay
            highestBid = min(currentBid + bidIncrement, bids[highestBidder]);   // will increment the bid of the current highestbBidder by 100 wei
        }else{
            highestBid = min(currentBid, bids[highestBidder] + bidIncrement);   
            highestBidder = payable(msg.sender);                                // if is higher, will change the highestBidder and highestBid
        }
    }
    
    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled;
    }

    function endAuction() public{
        require(auctionState == State.Canceled  || block.number > endBlock);
        require(msg.sender == owner  || bids[msg.sender] > 0);

        address payable target;
        uint value;
        
        //seems that can be optimized, will look into
        if(auctionState == State.Canceled){                                     //Auction canceled, each bidder has to call function to withdraw theirs bids
            target = payable(msg.sender);
            value = bids[msg.sender];
        }else{                                                                  //Auction ended
            if(msg.sender == owner){                                            //Owner closed the auction
                target = owner;
                value = highestBid;
            }else{                                                              //Bidder closed the auction
                if(msg.sender == highestBidder){                                //Highest bidder closed the auction
                    target = highestBidder;
                    value = bids[msg.sender] - highestBid;                      //Highest bidder gets his change back
                }else{
                    target = payable(msg.sender);
                    value = bids[msg.sender];                                   //Loser bidders gets their entire bid back
                }
            }
        }
        bids[target] = 0;                                                       //Clear the bids record of the person claiming to prevent multiple withdrawls
        target.transfer(value);                                                 //Transfers the value
    }
}

// This second contract deploys Auction contracts so multiple ones can be deployed in an auction website for example
contract AuctionDeployer{
    Auction[] public auctions;
  
    function deployAuction() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}