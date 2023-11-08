const leb = require('leb128')

let raw = process.argv[2];
let encoded = leb.unsigned.encode(raw);
console.log('0x' + encoded.toString('hex'));

// let encoded = leb.unsigned.encode('9019283812387')
// console.log(encoded)
// // <Buffer a3 e0 d4 b9 bf 86 02>
//
// let decoded = leb.unsigned.decode(encoded)
// console.log(decoded)
// // 9019283812387
//
// encoded = leb.signed.encode('-9019283812387')
// console.log(encoded)
// // <Buffer dd 9f ab c6 c0 f9 7d>
//
// decoded = leb.signed.decode(encoded)
// console.log(decoded)
// // '-9019283812387'
