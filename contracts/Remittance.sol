pragma solidity ^0.5.0;

import {Destroyable} from "./Destroyable.sol";
import {SafeMath} from "./SafeMath.sol";

contract Remittance is Destroyable {

    using SafeMath for uint256;

    /*
     * State Variables
     */

    address private owner;
    uint256 private transferCounter = 0;
    uint256 private FEE = 100;  // TODO ESTIMATE & ADJUST FEE
    uint256 private MAX_DEADLINE = 57600;

    struct FxTransfer {
        address sender;
        address exchange;
        uint256 amount;
        uint256 deadline;
        bytes32 puzzleHash;
    }

    mapping(uint256 => FxTransfer) public transferList;
    mapping(address => uint256) public balances;


    /*
     * Events
     */

    event LogNewTransfer(uint256 indexed id, address indexed sender, address indexed exchange, uint256 amount, uint256 deadline);
    event LogTransferCompleted(uint256 indexed id);
    event LogTransferReverted(uint256 indexed id);
    event LogWithdrawal(address indexed user, uint256 amount);


    /*
     * General Functions
     */

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Balance must be greater than 0");
        balances[msg.sender] = 0;
        emit LogWithdrawal(msg.sender, amount);
        msg.sender.transfer(amount);
    }


    /*
     * DAPP Logic Functions
     */

    function startTransfer(address exchange, uint256 deadline, bytes32 puzzleHash) public payable returns (uint256) {
        require(exchange != address(0), "Exchange must be non zero address");
        require(exchange != msg.sender, "Sender cannot be exchange");
        require(msg.value > 0, "Transfer must be larget than 0");
        require(deadline <= MAX_DEADLINE, "Max deadline is 57600 blocks => ~14 days");
        // TODO check that deadline is not 0
        // TODO check that deadline is larger than current block + min

        FxTransfer memory newTransfer;
        newTransfer.sender = msg.sender;
        newTransfer.exchange = exchange;
        newTransfer.amount = msg.value.sub(FEE);
        newTransfer.deadline = block.number.add(deadline);
        newTransfer.puzzleHash = puzzleHash;

        transferCounter++;
        transferList[transferCounter] = newTransfer;
        emit LogNewTransfer(transferCounter, msg.sender, exchange, msg.value.sub(FEE), deadline);
        return transferCounter;
    }

    function completeTransfer(uint256 id, string memory secret) public {
        FxTransfer storage transaction = transferList[id];
        require(msg.sender == transaction.exchange, "");
        bytes32 hashValue = keccak256(abi.encodePacked(secret));
        require(hashValue == transaction.puzzleHash, "");
        balances[msg.sender] = balances[msg.sender].add(transaction.amount);
        delete transferList[id];
        emit LogTransferCompleted(id);
    }

    function resolveTransfer(uint256 id) public {
        FxTransfer storage transaction = transferList[id];
        require(transaction.sender == msg.sender, "Only the sender can resolve a transfer");
        require(block.number > transaction.deadline, "Transfer deadline has not yet passed");
        balances[msg.sender] = balances[msg.sender].add(transaction.amount);
        delete transferList[id];
        emit LogTransferReverted(id);
    }
}