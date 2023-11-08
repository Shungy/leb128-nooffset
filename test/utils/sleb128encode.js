const leb = require('leb128')

let raw = process.argv[2];
let encoded = leb.signed.encode(raw);
console.log('0x' + encoded.toString('hex'));
