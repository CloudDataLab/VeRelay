pragma solidity ^0.4.17;
import "./RLP.sol";
contract Relay {

using RLP for RLP.RLPItem;
using RLP for RLP.Iterator;
using RLP for bytes;

mapping (bytes32 => BlockHeader) blocks;
mapping (bytes32 => Transaction) transactions;

event log(uint[] indexes);

struct BlockHeader {
  uint      prevBlockHash;// 0
  bytes32   stateRoot;    // 3
  bytes32   txRoot;       // 4
}

struct Transaction {
  //data
}


function submitBlock(bytes32 blockHash, uint prevBlockHash, bytes32 stateRoot, bytes32 txRoot){
  BlockHeader memory header;
  header.prevBlockHash=prevBlockHash;
  header.stateRoot = bytes32(stateRoot);
  header.txRoot = bytes32(txRoot);
  //log("txRoot",txRoot);
  blocks[blockHash] = header;


  //TO DO: check validity
}

function checkTxProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes transactionPrefix, bytes rlpTransaction) constant returns (bool) {
  bytes32 txRoot = blocks[blockHash].txRoot;
  if (checkProof(txRoot, rlpStack, indexes, transactionPrefix, rlpTransaction)) {
    return true;
  } else {
    return false;
  }
}


function checkProof(bytes32 rootHash, bytes rlpStack, uint[] indexes, bytes valuePrefix, bytes rlpValue) constant returns (bool) {
 RLP.RLPItem[] memory stack = rlpStack.toRLPItem().toList();
 bytes32 hashOfNode = rootHash;
 bytes memory currNode;
 RLP.RLPItem[] memory currNodeList;

 for (uint i = 0; i < stack.length; i++) {
   if (i == stack.length - 1) {
     log(indexes);
     currNode = stack[i].toBytes();
     if (hashOfNode != sha3(currNode)) {return false;}
     currNodeList = stack[i].toList();
     RLP.RLPItem memory value = currNodeList[currNodeList.length - 1];
     if (sha3(valuePrefix, rlpValue) == sha3(value.toBytes())) {
       return true;
     } else {
       return false;
     }
   }
   currNode = stack[i].toBytes();
   if (hashOfNode != sha3(currNode)) {return false;}
   currNodeList = stack[i].toList();
   hashOfNode = currNodeList[indexes[i]].toBytes32();
 }
}

function getStateRoot(bytes32 blockHash) constant returns (bytes32) {
  return blocks[blockHash].stateRoot;
}

function getTxRoot(bytes32 blockHash) constant returns (bytes32) {
  return blocks[blockHash].txRoot;
}


function getTransactionDetails(bytes rlpTransaction) constant returns (uint) {
  RLP.RLPItem[] memory list = rlpTransaction.toRLPItem().toList();
  return list[2].toUint();

}

}
