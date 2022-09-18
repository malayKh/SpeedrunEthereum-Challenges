pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfETH, uint256 amountOfTokens);
  YourToken public yourToken;

  
uint256 public constant tokensPerEth = 100;


  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() payable public{
    uint tokensTransferable = (tokensPerEth*msg.value);
    yourToken.transfer(msg.sender, tokensTransferable);
    emit BuyTokens(msg.sender, msg.value, tokensTransferable);
  }


  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw () public onlyOwner{
    (bool success,) = msg.sender.call{value: address(this).balance}('');
    require(success == true);
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint _amount) public {
    yourToken.transferFrom(msg.sender, address(this), _amount);
    uint ethTransferable = _amount/tokensPerEth;
    (bool success,) = msg.sender.call{value: ethTransferable}('');
    require(success == true, 'Eth failed to send');
    emit SellTokens(msg.sender, ethTransferable, _amount);
  }
}
