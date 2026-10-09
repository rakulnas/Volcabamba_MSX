#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,struct,re
ROOT=Path(__file__).resolve().parents[1];GEN=ROOT/'generated';OUT=ROOT/'out';VAL=ROOT/'validation';VAL.mkdir(exist_ok=True)
rom=OUT/'VOLCABAMBA_MSX2_NATIVE_BASE12_WORLD1_DEEP_PARITY.rom';data=rom.read_bytes();assert len(data)==524288
assert data[:2]==b'AB'
# bank magics
assert data[0x4000:0x4002]==b'VC'
manifest=json.loads((GEN/'full_manifest.json').read_text())
expected={1:184,2:126,3:145,4:165,5:210,6:0}
allstones=[]
for n in range(1,7):
    gfx=2+(n-1)*3;da=gfx+1;db=gfx+2
    assert data[gfx*0x4000:gfx*0x4000+2]==b'VG'
    assert data[da*0x4000:da*0x4000+2]==b'VD'
    s=manifest['stages'][str(n)]
    assert s['spawn_count']==expected[n]
    assert all(x<=256 for x in s['tiles_by_zone'])
    allstones.extend(s['stone_params'])
    # row directory bank ids/addresses are within this stage's data banks
    hdr=data[da*0x4000:(da+1)*0x4000]
    rowptr=struct.unpack_from('<H',hdr,16)[0]-0x8000
    for r in range(22):
        bank=hdr[rowptr+r*3];addr=struct.unpack_from('<H',hdr,rowptr+r*3+1)[0]
        assert bank in (da,db),(n,r,bank,da,db)
        assert 0x8000<=addr<0xC000
assert sorted(allstones)==list(range(30)),allstones
# Stage-1 exact schedule format: [step16,kind,x,y,hp,param], terminator FFFF.
b3=(GEN/'bank03_stage1_dataA.bin').read_bytes()
sp=struct.unpack_from('<H',b3,8)[0]-0x8000
recs=[];o=sp
while b3[o:o+2]!=b'\xff\xff':
    step=struct.unpack_from('<H',b3,o)[0];kind,x,y,hp,param=b3[o+2:o+7]
    recs.append((step,kind,x,y,hp,param));o+=7
assert len(recs)==184,len(recs)
# First authored wave: eight type-7/chr105 records, followed by eight type-8/chr105.
assert [r[1] for r in recs[:8]]==[3]*8,recs[:8]
assert [r[1] for r in recs[8:16]]==[4]*8,recs[8:16]
assert [r[0] for r in recs[:8]]==[36,38,40,42,44,46,48,50]
# Hidden Volca-Stone triggers: exactly six in World 1; visible stones are created only after death.
stones1=[r for r in recs if r[1]==13]
assert len(stones1)==6 and [r[5] for r in stones1]==list(range(6)),stones1
assert not any(r[1]==23 for r in recs)
# Ocular sentinels are non-droppable dedicated events.
assert len([r for r in recs if r[1]==10])==1
assert len([r for r in recs if r[1]==11])==1
# Collision stream must retain all authored attribute classes, not flatten to boolean.
cr=(GEN/'collision_rle.bin').read_bytes()
assert all(v in cr for v in (1,2,3,4,5))
# mapper signature: LD (7000h),A = 32 00 70 in bank0
assert b'\x32\x00\x70' in data[:0x4000]
# Stage-1 data header must expose the exact 3-zone x 4-phase x 24-byte laser rows.
laser_ptr=struct.unpack_from('<H',b3,34)[0]
assert 0x8000 <= laser_ptr < 0xC000
lo=laser_ptr-0x8000
assert len(b3[lo:lo+288])==288 and len(set(b3[lo:lo+288]))>1
# Build constants must retain dedicated source projectile/hazard patterns.
const=(GEN/'full_constants.inc').read_text()
for sym in ('SPR_CHR131','SPR_CHR132','SPR_CHR143','SPR_CHR159','SPR_CHR163','SPR_CHR185','SPR_CHR196'):
    assert sym in const,sym
# Engine source audit markers for exact requested parity fixes.
asm=(ROOT/'src/main.asm').read_text()
for marker in ('sub 10','mid_laser_draw_line','spawn_enemy_bar','boss_spike_events','boss_tentacle_events','check_boss_hazard14',
               'EN_COUNT       equ 40','BUL_COUNT      equ 20','SHOT_COUNT     equ 6',
               'spawn_find_free40','shot_hits_map_exact','update_midboss2','en_mid2_mine',
               'BOSS_TIMER','boss_death_events'):
    assert marker in asm,marker
# Second Ocular must use the source state-cycle and ID13 mine pattern.
assert 'cp 40\n    jp z,mid2_spawn_mine_top' in asm
assert 'cp 60\n    jp z,mid2_spawn_mine_bottom' in asm
sha=hashlib.sha256(data).hexdigest()
report={'status':'PASS','rom_bytes':len(data),'sha256':sha,'mapper':'ASCII16','banks_16k':32,'stages':manifest['stages'],'stone_ids':sorted(allstones),'notes':['static validation only; C-BIOS/hardware gameplay validation pending','Stage 1 uses exact 184-record FIX23 step schedule; 40 logical enemies, 20 enemy bullets, 3+3 player shots; source damage=10; exact hidden ID99->ID199 stones; Ocular laser/mine phases; distinct ID105 chr131/132 shots; Kraken timer/pattern/death timing', 'stages 2-6 remain the earlier alpha and are outside this WORLD1 parity pass']}
(VAL/'BASE12_VALIDATION.json').write_text(json.dumps(report,indent=2)+'\n')
(VAL/'SHA256SUMS.txt').write_text(f'{sha}  {rom.name}\n')
print(json.dumps(report,indent=2))
