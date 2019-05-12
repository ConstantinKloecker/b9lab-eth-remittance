pragma solidity ^0.5.0;

contract Ownable {

    address payable private owner;

    event LogNewOwner(address indexed oldOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only executable by owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner must be non zero address");
        emit LogNewOwner(msg.sender, newOwner);
        owner = newOwner;
    }
}