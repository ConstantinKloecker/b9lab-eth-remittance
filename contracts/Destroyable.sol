pragma solidity ^0.5.0;

import "./Ownable.sol";

contract Destroyable is Ownable {

    uint256 private deadline;
    address payable private beneficiary;

    event LogDestructionInitiated(address indexed admin, uint256 deadline, address beneficiary);
    event LogDestructionCanceled(address indexed admin);
    event LogDestructionCompleted();

    function initiateDestruction(address payable _beneficiary) public onlyOwner {
        require(deadline == 0, "Already initiated");
        require(_beneficiary != address(0), "Beneficiary can not be zero address");
        deadline = block.number + 5760;  // ~ 1 day
        beneficiary = _beneficiary;
        emit LogDestructionInitiated(msg.sender, deadline, beneficiary);
    }

    function cancelDestruction() public onlyOwner {
        require(deadline != 0, "Destruction has not been initiated");
        emit LogDestructionCanceled(msg.sender);
        deadline = 0;
    }

    function completeDestruction() public {
        require(deadline != 0, "Destruction has not been initiated");
        require(block.number > deadline, "Deadline has not yet passed");
        emit LogDestructionCompleted();
        selfdestruct(beneficiary);
    }

    function getDeadline() public view returns (uint256) {
        return deadline;
    }

    function getBeneficiary() public view returns (address) {
        return beneficiary;
    }
}