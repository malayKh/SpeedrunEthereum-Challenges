pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;
  event Stake(address indexed, uint256);

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;
  bool public completed;
  bool public deadlineHit = false;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    completed = exampleExternalContract.completed();
  }

  modifier notCompleted() {
    require(completed != true, 'This has already been completed!');
    _;
  }

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    require(deadlineHit == false, 'Deadline has already been hit');
    address staker = msg.sender;
    uint256 amount = msg.value;
    require(amount > 0, 'Non Zero Amount Required');
    balances[staker] = balances[staker] + amount;
    emit Stake(staker, amount);
  }

  function checkBalanceStaked() public view returns (uint256) {
    return balances[msg.sender];
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    require(deadlineHit == false, 'Execute has already been called');
    require(block.timestamp >= deadline, 'Deadline not hit yet!');
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
    deadlineHit = true;
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public notCompleted {
    require(openForWithdraw = true, 'Withdrawal cant be done currrently');
    require(balances[msg.sender] > 0, 'No eth to be withdrawn');
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}('');
    require(success, 'Transfer failed.');
  }

  // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return (deadline - block.timestamp);
    }
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
