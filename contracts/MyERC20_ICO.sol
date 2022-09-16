//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------
 
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is ERC20Interface{
    string public name = "PipoCoin";
    string public symbol = "PPC";
    uint public decimals = 0;                                                   //18 most common used
    uint public override totalSupply;
    
    address public founder;
    mapping(address=>uint) public balances;                                     //keeps the balance of coins for each address
    mapping(address=> mapping(address=>uint)) allowed;                   //keeps track of approved account & amount permited to transfer

    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;                                          //lol owner gets all the coins unlocked, squidgamescoin scam incoming
    }

    function balanceOf(address tokenOwner) public view override returns(uint balance){
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns(bool success){
        require(balances[msg.sender]>=tokens);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
   
    function approve(address spender, uint tokens) public override returns(bool){
        require(balances[msg.sender]>=tokens && tokens>0);
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public virtual override returns(bool){
        require(allowed[from][msg.sender]>=tokens && tokens>0);
        require(balances[from]>= tokens);
        balances[to] += tokens;
        balances[from] -= tokens;
        allowed[from][msg.sender]-= tokens;
        
        emit Transfer(from, to, tokens);
        return true;
    }
}

contract CryptosICO is Cryptos{
    address public admin;
    address payable public deposit;
    uint public price = 0.001 ether;
    uint public hardCap = 300 ether;                                                                   // max total investment
    uint public raised;
    uint public startTime=block.timestamp + 3600;                                                      //starts after 1 hour of contract deployment
    uint public endTime=block.timestamp + 604800;                                                      // 1 week ICO
    uint public tradeLock=endTime + 604800;                                                            //lock the trade for 1 week after ICO ends
    uint public minInv= 0.001 ether;
    uint public maxInv= 5 ether;                                                                       // max & min individual investment

    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;

    event Invest(address investor, uint value, uint tokens);

    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin(){
        require(msg.sender==admin);
        _;
    }

    function halt() public onlyAdmin{
        icoState = State.halted;
    }

    function resume() public onlyAdmin{
        icoState = State.running;
    }

    function changeDeposit(address payable _deposit) public onlyAdmin{
        deposit = _deposit;
    }

    function getState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < startTime){
            return State.beforeStart;
        }else if(block.timestamp > endTime){
            return State.afterEnd;
        }else{
            return State.running;
        }
    }
    
    function invest() payable public returns(bool){
        icoState = getState();
        require(icoState == State.running);
        require(msg.value >= minInv && msg.value<= maxInv);
        raised += msg.value;
        require(raised <= hardCap);
        uint tokens = msg.value / price;

        balances[msg.sender]+= tokens;
        balances[founder]  -=tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender,msg.value,tokens);

        return true;                                            
    }

    receive() payable external{
        invest();
    }

    function transfer(address to, uint tokens) public override returns(bool success){
        require(block.timestamp>tradeLock);
        super.transfer(to,tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns(bool){
        require(block.timestamp>tradeLock);
        super.transferFrom(from, to, tokens);
        return true;
    }

    function burnTokens() public onlyAdmin returns(bool){
        icoState = getState();
        require (icoState == State.afterEnd);
        balances[founder] = 0;

        return true;
    }
}