#!/usr/bin/env python3
"""Non-emulated assertions that distinguish the R800-only build from hybrid."""
from pathlib import Path
import hashlib,sys,struct,json
root=Path(__file__).resolve().parents[1]
h=Path(sys.argv[1]).read_bytes();t=Path(sys.argv[2]).read_bytes();b=16384
assert len(h)==len(t)==32*b==524288
assert h[:2]==t[:2]==b'AB'
assert h[:b]!=t[:b], 'independent boot required'
assert all(h[i*b:(i+1)*b]==t[i*b:(i+1)*b] for i in range(1,20)), 'shared assets differ'
assert h[20*b:20*b+4]==b'VEZ\x01'
assert t[20*b:21*b]==b'\xFF'*b, 'dedicated build must not contain Z80 runtime'
assert h[21*b:22*b]==t[21*b:22*b], 'R800 engine differs'
assert t[21*b:21*b+4]==b'VER\x01'
assert b'VOLCABAMBA turboR ONLY' in t[:b]
assert b'R800 DRAM MODE REQUIRED' in t[:b]
assert b'\xcd\x80\x01' in t[:b] and b'\xcd\x83\x01' in t[:b], 'CHGCPU/GETCPU missing'
assert h != t
for label,r in [('hybrid',h),('turbor_only',t)]:
 print(f'{label}: {len(r)} bytes, SHA256 {hashlib.sha256(r).hexdigest()}')
print('TURBOR EXCLUSIVE BUILD: 14 STATIC CHECKS PASSED; runtime/emulator NOT tested')
