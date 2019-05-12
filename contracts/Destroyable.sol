pragma solidity ^0.5.0;

import "./Ownable.sol";

contract Destroyable is Ownable {

    uint256 private deadline;
    address payable private beneficiary;
    
    event LogDestructionInitiated(address indexed admin);
    event LogDestructionCanceled(address indexed admin);
    event LogDestructionCompleted();

    function initiateDestruction(address payable _beneficiary) public onlyOwner {
        require(deadline == 0, "Already initiated");
        require(beneficiary != address(0), "Beneficiary can not be zero address");
        emit LogDestructionInitiated(msg.sender);
        deadline = block.number + 5760;  // ~ 1 day
        beneficiary = _beneficiary;
    }

    function cancelDestruction() public onlyOwner {
        emit LogDestructionCanceled(msg.sender);
        deadline = 0;
    }

    function completeDestruction() public {
        require(deadline != 0, "Destruction has not been initiated");
        require(block.number > deadline, "Deadline has not yet passed");
        emit LogDestructionCompleted();
        selfdestruct(beneficiary);
    }
}