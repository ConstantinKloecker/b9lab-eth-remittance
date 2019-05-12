pragma solidity ^0.5.0;

import "./Destroyable.sol";

contract Remittance is Destroyable {

    /*
     * State Variables
     */

    address private owner;
    uint256 private transferCounter = 0;

    struct fxTransfer {
        address _sender;
        address _exchange;
        uint256 _amount;
        uint256 _deadline;
        bytes32 _puzzleHash;
    }

    mapping(uint256 => fxTransfer) public transferList;
    mapping(address => uint256) public balances;


    /*
     * Events
     */

    event LogNewTransfer(address indexed sender, address indexed exchange, uint256 amount, uint256 deadline, uint256 id);
    event LogTransferCompleted(uint256 indexed id);
    event LogTransferReverted(uint256 indexed id);
    event LogWithdrawal(address indexed user, uint256 amount);


    /*
     * General Functions
     */

    constructor() public {
        owner = msg.sender;
    }


    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Balance must be greater than 0");
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit LogWithdrawal(msg.sender, amount);
    }


    /*
     * DAPP Logic Functions
     */

    function startTransfer(address exchange, uint256 deadline, bytes32 puzzleHash) public payable returns (uint256) {
        require(exchange != address(0), "Exchange must be non zero address");
        require(exchange != msg.sender, "Sender cannot be exchange");

        require(msg.value > 0, "Transfer must be larget than 0");
        require(deadline <= 57600, "Max deadline is xx blocks => ~14 days");
        require(puzzleHash.length != 0, "Transfer must include a valid puzzle");

        fxTransfer memory newTransfer;
        newTransfer._sender = msg.sender;
        newTransfer._exchange = exchange;
        newTransfer._amount = msg.value - 10;               // ADJUST FEE
        newTransfer._deadline = block.number + deadline;
        newTransfer._puzzleHash = puzzleHash;

        transferCounter++;
        transferList[transferCounter] = newTransfer;
        emit LogNewTransfer(msg.sender, exchange, newTransfer._amount, deadline, transferCounter);
        return transferCounter;
    }

    function completeTransfer(uint256 id, string memory secret) public {
        fxTransfer storage transaction = transferList[id];
        require(msg.sender == transaction._exchange, "");
        bytes32 hashValue = keccak256(abi.encodePacked(secret));
        require(hashValue == transaction._puzzleHash, "");
        balances[msg.sender] += transaction._amount;
        delete transferList[id];
        emit LogTransferCompleted(id);
    }

    function resolveTransfer(uint256 id) public {
        fxTransfer storage transaction = transferList[id];
        require(transaction._sender == msg.sender, "Only the sender can resolve a transfer");
        require(block.number > transaction._deadline, "Transfer deadline has not yet passed");
        balances[msg.sender] = transaction._amount;
        delete transferList[id];
        emit LogTransferReverted(id);
    }
}