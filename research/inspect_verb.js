const fs = require('fs');
const base = 'C:/Program Files/WindowsApps/SAMSUNGELECTRONICSCoLtd.SamsungQuickShare_2.3.22.0_x64__wyx1vj98g3asy/ExplorerCommandVerb.dll';
const buf = fs.readFileSync(base);
const utf16 = buf.toString('utf16le');
const latin = buf.toString('latin1');

const rx = /([a-z0-9\-]+:\/\/[^\s"\0]+|[a-z0-9\-]+:[^\s"\0]{2,50})/gi;
const m1 = latin.match(rx) || [];
const m2 = utf16.match(rx) || [];

console.log('URI matches:', [...new Set([...m1, ...m2])]);

// Check registry paths in DLL
const rxReg = /(Software\\[^\s"\0]+|HARDWARE\\[^\s"\0]+)/gi;
const r1 = latin.match(rxReg) || [];
const r2 = utf16.match(rxReg) || [];
console.log('Registry matches:', [...new Set([...r1, ...r2])]);
