pragma solidity ^0.4.11;



library RLP {

 uint constant DATA_SHORT_START = 0x80;
 uint constant DATA_LONG_START = 0xB8;
 uint constant LIST_SHORT_START = 0xC0;
 uint constant LIST_LONG_START = 0xF8;

 uint constant DATA_LONG_OFFSET = 0xB7;
 uint constant LIST_LONG_OFFSET = 0xF7;


 struct RLPItem {
     uint _unsafe_memPtr;
     uint _unsafe_length;
 }

 struct Iterator {
     RLPItem _unsafe_item;
     uint _unsafe_nextPtr;
 }



 function next(Iterator memory self) internal constant returns (RLPItem memory subItem) {
     if(hasNext(self)) {
         var ptr = self._unsafe_nextPtr;
         var itemLength = _itemLength(ptr);
         subItem._unsafe_memPtr = ptr;
         subItem._unsafe_length = itemLength;
         self._unsafe_nextPtr = ptr + itemLength;
     }
     else
         throw;
 }

 function next(Iterator memory self, bool strict) internal constant returns (RLPItem memory subItem) {
     subItem = next(self);
     if(strict && !_validate(subItem))
         throw;
     return;
 }

 function hasNext(Iterator memory self) internal constant returns (bool) {
     var item = self._unsafe_item;
     return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
 }


 function toRLPItem(bytes memory self) internal constant returns (RLPItem memory) {
     uint len = self.length;
     if (len == 0) {
         return RLPItem(0, 0);
     }
     uint memPtr;
     assembly {
         memPtr := add(self, 0x20)
     }
     return RLPItem(memPtr, len);
 }


 function toRLPItem(bytes memory self, bool strict) internal constant returns (RLPItem memory) {
     var item = toRLPItem(self);
     if(strict) {
         uint len = self.length;
         if(_payloadOffset(item) > len)
             throw;
         if(_itemLength(item._unsafe_memPtr) != len)
             throw;
         if(!_validate(item))
             throw;
     }
     return item;
 }


 function isNull(RLPItem memory self) internal constant returns (bool ret) {
     return self._unsafe_length == 0;
 }


 function isList(RLPItem memory self) internal constant returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
     }
 }


 function isData(RLPItem memory self) internal constant returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := lt(byte(0, mload(memPtr)), 0xC0)
     }
 }


 function isEmpty(RLPItem memory self) internal constant returns (bool ret) {
     if(isNull(self))
         return false;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
 }


 function items(RLPItem memory self) internal constant returns (uint) {
     if (!isList(self))
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     uint pos = memPtr + _payloadOffset(self);
     uint last = memPtr + self._unsafe_length - 1;
     uint itms;
     while(pos <= last) {
         pos += _itemLength(pos);
         itms++;
     }
     return itms;
 }


 function iterator(RLPItem memory self) internal constant returns (Iterator memory it) {
     if (!isList(self))
         throw;
     uint ptr = self._unsafe_memPtr + _payloadOffset(self);
     it._unsafe_item = self;
     it._unsafe_nextPtr = ptr;
 }


 function toBytes(RLPItem memory self) internal constant returns (bytes memory bts) {
     var len = self._unsafe_length;
     if (len == 0)
         return;
     bts = new bytes(len);
     _copyToBytes(self._unsafe_memPtr, bts, len);
 }


 function toData(RLPItem memory self) internal constant returns (bytes memory bts) {
     if(!isData(self))
         throw;
     var (rStartPos, len) = _decode(self);
     bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
 }


 function toList(RLPItem memory self) internal constant returns (RLPItem[] memory list) {
     if(!isList(self))
         throw;
     var numItems = items(self);
     list = new RLPItem[](numItems);
     var it = iterator(self);
     uint idx;
     while(hasNext(it)) {
         list[idx] = next(it);
         idx++;
     }
 }


 function toAscii(RLPItem memory self) internal constant returns (string memory str) {
     if(!isData(self))
         throw;
     var (rStartPos, len) = _decode(self);
     bytes memory bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
     str = string(bts);
 }


 function toUint(RLPItem memory self) internal constant returns (uint data) {
     if(!isData(self))
         throw;
     var (rStartPos, len) = _decode(self);
     if (len > 32 || len == 0)
         throw;
     assembly {
         data := div(mload(rStartPos), exp(256, sub(32, len)))
     }
 }


 function toBool(RLPItem memory self) internal constant returns (bool data) {
     if(!isData(self))
         throw;
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         throw;
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     if (temp > 1)
         throw;
     return temp == 1 ? true : false;
 }


 function toByte(RLPItem memory self) internal constant returns (byte data) {
     if(!isData(self))
         throw;
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         throw;
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     return byte(temp);
 }


 function toInt(RLPItem memory self) internal constant returns (int data) {
     return int(toUint(self));
 }


 function toBytes32(RLPItem memory self) internal constant returns (bytes32 data) {
     return bytes32(toUint(self));
 }


 function toAddress(RLPItem memory self) internal constant returns (address data) {
     if(!isData(self))
         throw;
     var (rStartPos, len) = _decode(self);
     if (len != 20)
         throw;
     assembly {
         data := div(mload(rStartPos), exp(256, 12))
     }
 }


 function _payloadOffset(RLPItem memory self) private constant returns (uint) {
     if(self._unsafe_length == 0)
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if(b0 < DATA_SHORT_START)
         return 0;
     if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
         return 1;
     if(b0 < LIST_SHORT_START)
         return b0 - DATA_LONG_OFFSET + 1;
     return b0 - LIST_LONG_OFFSET + 1;
 }


 function _itemLength(uint memPtr) private constant returns (uint len) {
     uint b0;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if (b0 < DATA_SHORT_START)
         len = 1;
     else if (b0 < DATA_LONG_START)
         len = b0 - DATA_SHORT_START + 1;
     else if (b0 < LIST_SHORT_START) {
         assembly {
             let bLen := sub(b0, 0xB7)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen)))
             len := add(1, add(bLen, dLen))
         }
     }
     else if (b0 < LIST_LONG_START)
         len = b0 - LIST_SHORT_START + 1;
     else {
         assembly {
             let bLen := sub(b0, 0xF7)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen)))
             len := add(1, add(bLen, dLen))
         }
     }
 }


 function _decode(RLPItem memory self) private constant returns (uint memPtr, uint len) {
     if(!isData(self))
         throw;
     uint b0;
     uint start = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(start))
     }
     if (b0 < DATA_SHORT_START) {
         memPtr = start;
         len = 1;
         return;
     }
     if (b0 < DATA_LONG_START) {
         len = self._unsafe_length - 1;
         memPtr = start + 1;
     } else {
         uint bLen;
         assembly {
             bLen := sub(b0, 0xB7)
         }
         len = self._unsafe_length - 1 - bLen;
         memPtr = start + bLen + 1;
     }
     return;
 }


 function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen) private constant {

     assembly {
         {
                 let i := 0
                 let words := div(add(btsLen, 31), 32)
                 let rOffset := btsPtr
                 let wOffset := add(tgt, 0x20)
             tag_loop:
                 jumpi(end, eq(i, words))
                 {
                     let offset := mul(i, 0x20)
                     mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                     i := add(i, 1)
                 }
                 jump(tag_loop)
             end:
                 mstore(add(tgt, add(0x20, mload(tgt))), 0)
         }
     }
 }


     function _validate(RLPItem memory self) private constant returns (bool ret) {

         uint b0;
         uint b1;
         uint memPtr = self._unsafe_memPtr;
         assembly {
             b0 := byte(0, mload(memPtr))
             b1 := byte(1, mload(memPtr))
         }
         if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
             return false;
         return true;
     }
}
