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

contract MarceCoin is ERC20Interface{
    string public name = "MarceCoin";
    string public symbol = "MRCC";
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

    function transfer(address to, uint tokens) public override returns(bool success){
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
    
    function transferFrom(address from, address to, uint tokens) public override returns(bool){
        require(allowed[from][msg.sender]>=tokens && tokens>0);
        require(balances[from]>= tokens);
        balances[to] += tokens;
        balances[from] -= tokens;
        allowed[from][msg.sender]-= tokens;
        
        emit Transfer(from, to, tokens);
        return true;
    }
}