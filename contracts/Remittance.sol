pragma solidity ^0.5.0;

import {Destroyable} from "./Destroyable.sol";
import {SafeMath} from "./SafeMath.sol";

contract Remittance is Destroyable {

    using SafeMath for uint256;

    /*
     * State Variables
     */

    address private owner;
    uint256 constant public FEE = 100;  // TODO ESTIMATE & ADJUST FEE
    uint256 constant public MAX_DEADLINE = 57600;  // ~10 days
    uint256 constant public MIN_DEADLINE = 5760;   // ~1  day

    struct FxTransfer {
        address sender;
        uint256 amount;
        uint256 deadline;
    }

    mapping(bytes32 => FxTransfer) public transferList;
    mapping(address => uint256) public balances;


    /*
     * Events
     */

    event LogNewTransfer(bytes32 indexed secretHash, address indexed sender, uint256 amount, uint256 deadline);
    event LogTransferCompleted(bytes32 indexed secretHash);
    event LogTransferReverted(bytes32 indexed secretHash);
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

    function getFee() public pure returns (uint256) {
        return FEE;
    }


    /*
     * DAPP Logic Functions
     */

    function startTransfer(uint256 deadline, bytes32 secretHash) public payable {
        require(deadline <= MAX_DEADLINE, "Max deadline is 57600 blocks => ~14 days");
        require(deadline >= MIN_DEADLINE, "Deadline must be at least 5760 blocks => ~1 day");
        require(transferList[secretHash].sender == address(0), "Secret has already been used");

        FxTransfer memory newTransfer;
        newTransfer.sender = msg.sender;
        newTransfer.amount = msg.value.sub(FEE);
        newTransfer.deadline = block.number.add(deadline);

        transferList[secretHash] = newTransfer;
        emit LogNewTransfer(secretHash, msg.sender, msg.value.sub(FEE), block.number.add(deadline));
    }

    function completeTransfer(bytes32 secretHash, bytes32 secret) public {
        FxTransfer storage transaction = transferList[secretHash];
        bytes32 hashValue = createSecretHash(secret, msg.sender);
        require(hashValue == secretHash, "Secret not valid");
        balances[msg.sender] = balances[msg.sender].add(transaction.amount);
        delete transferList[secretHash].amount;
        delete transferList[secretHash].deadline;
        emit LogTransferCompleted(secretHash);
    }

    function resolveTransfer(bytes32 secretHash) public {
        FxTransfer storage transaction = transferList[secretHash];
        require(transaction.sender == msg.sender, "Only the sender can resolve a transfer");
        require(block.number > transaction.deadline, "Transfer deadline has not yet passed");
        balances[msg.sender] = balances[msg.sender].add(transaction.amount);
        delete transferList[secretHash];
        emit LogTransferReverted(secretHash);
    }

    function createSecretHash(bytes32 secret, address exchange) public view returns (bytes32) {
        require(exchange != address(0), "Exchange must be non zero address");
        return keccak256(abi.encode(address(this), secret, exchange));
    }
}