// contract Fallbackable {
//     bool initialized = false;

//     bytes4 constant initializer = bytes4(keccak256("eip420.fallbackable.initializer"));

//     function _initialize() internal {
        
//     }

//     fallback() payable {
//         if(!initialized) {
//             bytes4 sel;
//             assembly {
//                 sel := calldataload(0x20)
//             }
//             require(sel == initializer, "ERR_NOT_INITIALIZED");
//             return address(this).call{value: msg.value}(msg.data);
//         }
        
        
//     }
// }