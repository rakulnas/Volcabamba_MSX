#!/usr/bin/env python3
"""Tiny deterministic two-pass Z80 assembler for VOLCABAMBA MSX2.
It assembles source text from scratch. It never reads or patches a prior ROM.
The supported syntax is intentionally limited and SjASM-like.

HYBRID additions (VOLCABAMBA_MSX2_TURBOR_HYBRID):
  * -D NAME=VALUE command-line defines (one source -> several engine modules)
  * IF expr / ELSE / ENDIF conditional assembly (nestable)
  * ASSERT expr[, "message"] build-time checks (evaluated in pass 2)
  * in a,(n)
  * --sym FILE writes the full symbol table (sorted, deterministic)
"""
from pathlib import Path
import ast,re,sys

class AsmError(Exception): pass

def split_args(s):
    out=[]; cur=''; q=None
    for ch in s:
        if q:
            cur+=ch
            if ch==q:q=None
        elif ch in "\"'": q=ch; cur+=ch
        elif ch==',': out.append(cur.strip()); cur=''
        else: cur+=ch
    if cur.strip(): out.append(cur.strip())
    return out

def strip_comment(s):
    q=None
    for i,ch in enumerate(s):
        if q:
            if ch==q:q=None
        elif ch in "\"'": q=ch
        elif ch==';': return s[:i]
    return s

def safe_eval(expr,syms,pc):
    expr=expr.strip().replace('$',str(pc))
    # Replace 0ABCDh notation if ever used.
    expr=re.sub(r'\b([0-9A-Fa-f]+)h\b',lambda m:'0x'+m.group(1),expr)
    env={k.lower():int(v) for k,v in syms.items()}
    try:
        node=ast.parse(expr,mode='eval')
    except Exception as e: raise AsmError(f'bad expression {expr}: {e}')
    ok=(ast.Expression,ast.Constant,ast.Name,ast.BinOp,ast.UnaryOp,ast.Add,ast.Sub,ast.Mult,ast.FloorDiv,ast.Mod,ast.LShift,ast.RShift,ast.BitOr,ast.BitAnd,ast.BitXor,ast.USub,ast.UAdd,ast.Invert,ast.Load,ast.Compare,ast.Lt,ast.LtE,ast.Gt,ast.GtE,ast.Eq,ast.NotEq,ast.BoolOp,ast.And,ast.Or)
    for n in ast.walk(node):
        if not isinstance(n,ok): raise AsmError(f'unsupported expression {expr}')
        if isinstance(n,ast.Name) and n.id not in env: raise NameError(n.id)
    return int(eval(compile(node,'<expr>','eval'),{'__builtins__':{}},env))

def data_items(arg,syms,pc,word=False,passno=2):
    bs=bytearray()
    for a in split_args(arg):
        if len(a)>=2 and a[0]==a[-1] and a[0] in "\"'":
            txt=ast.literal_eval(a)
            if not isinstance(txt,str): raise AsmError('string expected')
            if word: raise AsmError('string not valid in dw')
            bs.extend(txt.encode('latin-1'))
        else:
            try:v=safe_eval(a.lower(),syms,pc+len(bs))
            except NameError:
                if passno==1:v=0
                else:raise
            if word: bs.extend([v&255,(v>>8)&255])
            else: bs.append(v&255)
    return bytes(bs)

def instr(line,syms,pc,passno):
    s=' '.join(line.strip().split())
    lo=s.lower()
    fixed={
        'di':b'\xF3','ei':b'\xFB','ret':b'\xC9','ret z':b'\xC8','ret nz':b'\xC0',
        'ret c':b'\xD8','ret nc':b'\xD0','xor a':b'\xAF','or a':b'\xB7','inc hl':b'\x23',
        'dec hl':b'\x2B','inc de':b'\x13','dec de':b'\x1B','inc bc':b'\x03','dec bc':b'\x0B',
        'inc a':b'\x3C','dec a':b'\x3D','inc b':b'\x04','dec b':b'\x05','inc c':b'\x0C','dec c':b'\x0D',
        'inc d':b'\x14','dec d':b'\x15','inc e':b'\x1C','dec e':b'\x1D','inc h':b'\x24','dec h':b'\x25',
        'inc l':b'\x2C','dec l':b'\x2D','nop':b'\x00','halt':b'\x76','cpl':b'\x2F',
        'add hl,bc':b'\x09','add hl,de':b'\x19','add hl,hl':b'\x29','add hl,sp':b'\x39',
        'srl a':b'\xCB\x3F','rrca':b'\x0F','rlca':b'\x07','ldir':b'\xED\xB0','sbc hl,bc':b'\xED\x42','sbc hl,de':b'\xED\x52',
        'push bc':b'\xC5','push de':b'\xD5','push hl':b'\xE5','push af':b'\xF5',
        'pop bc':b'\xC1','pop de':b'\xD1','pop hl':b'\xE1','pop af':b'\xF1'
    }
    if lo in fixed:return fixed[lo]
    m=re.match(r'^(call|jp)(?:\s+(z|nz|c|nc),)?\s*(.+)$',lo)
    if m:
        op,cc,expr=m.groups()
        try:v=safe_eval(expr,syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        if op=='call' and cc:
            code={'z':0xCC,'nz':0xC4,'c':0xDC,'nc':0xD4}[cc]
        else:
            code=0xCD if op=='call' else {'z':0xCA,'nz':0xC2,'c':0xDA,'nc':0xD2,None:0xC3}[cc]
        return bytes([code,v&255,(v>>8)&255])
    m=re.match(r'^djnz\s+(.+)$',lo)
    if m:
        try:v=safe_eval(m.group(1),syms,pc)
        except NameError:
            if passno==1:v=pc+2
            else:raise
        disp=v-(pc+2)
        if passno==2 and not -128<=disp<=127: raise AsmError(f'djnz out of range {disp}')
        return bytes([0x10,disp&255])
    # 8-bit arithmetic with registers
    arith_regs={'b':0,'c':1,'d':2,'e':3,'h':4,'l':5,'(hl)':6,'a':7}
    m=re.match(r'^cp\s+(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0xB8+arith_regs[m.group(1)]])
    m=re.match(r'^cp\s+(.+)$',lo)
    if m:
        try:v=safe_eval(m.group(1),syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([0xFE,v&255])
    m=re.match(r'^add a,\s*(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0x80+arith_regs[m.group(1)]])
    m=re.match(r'^sub\s+(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0x90+arith_regs[m.group(1)]])
    m=re.match(r'^and\s+(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0xA0+arith_regs[m.group(1)]])
    m=re.match(r'^xor\s+(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0xA8+arith_regs[m.group(1)]])
    m=re.match(r'^or\s+(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0xB0+arith_regs[m.group(1)]])
    m=re.match(r'^cp\s+(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:return bytes([0xB8+arith_regs[m.group(1)]])
    for opname,opcode in [('add a',0xC6),('sub',0xD6),('and',0xE6),('xor',0xEE),('or',0xF6)]:
        m=re.match(r'^'+re.escape(opname)+r'(?:\s*,?\s+|\s*,\s*)(.+)$',lo)
        if m:
            try:v=safe_eval(m.group(1),syms,pc)
            except NameError:
                if passno==1:v=0
                else:raise
            return bytes([opcode,v&255])
    # ld r,r and ld r,(hl)/(hl),r
    regs={'b':0,'c':1,'d':2,'e':3,'h':4,'l':5,'(hl)':6,'a':7}
    m=re.match(r'^ld\s+(b|c|d|e|h|l|a|\(hl\)),\s*(b|c|d|e|h|l|a|\(hl\))$',lo)
    if m:
        dst,src=m.groups()
        if dst=='(hl)' and src=='(hl)': raise AsmError('ld (hl),(hl) invalid')
        return bytes([0x40+regs[dst]*8+regs[src]])
    # ld 8-bit register, immediate or absolute memory for A
    m=re.match(r'^ld\s+(a|b|c|d|e|h|l),\s*(.+)$',lo)
    if m:
        reg,expr=m.groups()
        if expr.startswith('(') and expr.endswith(')') and reg=='a':
            inner=expr[1:-1]
            if inner=='bc': return b'\x0A'
            if inner=='de': return b'\x1A'
            try:v=safe_eval(inner,syms,pc)
            except NameError:
                if passno==1:v=0
                else:raise
            return bytes([0x3A,v&255,(v>>8)&255])
        try:v=safe_eval(expr,syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([{'a':0x3E,'b':0x06,'c':0x0E,'d':0x16,'e':0x1E,'h':0x26,'l':0x2E}[reg],v&255])
    m=re.match(r'^ld\s+(hl|de|bc|sp),\s*(.+)$',lo)
    if m:
        reg,expr=m.groups()
        # optional absolute indirect loads for HL only
        if expr.startswith('(') and expr.endswith(')') and reg=='hl':
            try:v=safe_eval(expr[1:-1],syms,pc)
            except NameError:
                if passno==1:v=0
                else:raise
            return bytes([0x2A,v&255,(v>>8)&255])
        try:v=safe_eval(expr,syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([{'bc':0x01,'de':0x11,'hl':0x21,'sp':0x31}[reg],v&255,(v>>8)&255])
    m=re.match(r'^ld\s+\((.+)\),\s*a$',lo)
    if m:
        inner=m.group(1)
        if inner=='bc': return b'\x02'
        if inner=='de': return b'\x12'
        try:v=safe_eval(inner,syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([0x32,v&255,(v>>8)&255])
    m=re.match(r'^ld\s+\((.+)\),\s*hl$',lo)
    if m:
        try:v=safe_eval(m.group(1),syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([0x22,v&255,(v>>8)&255])
    m=re.match(r'^in\s+a,\s*\((.+)\)$',lo)
    if m:
        try:v=safe_eval(m.group(1),syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([0xDB,v&255])
    m=re.match(r'^out\s*\((.+)\),\s*a$',lo)
    if m:
        try:v=safe_eval(m.group(1),syms,pc)
        except NameError:
            if passno==1:v=0
            else:raise
        return bytes([0xD3,v&255])
    raise AsmError(f'unsupported instruction: {line}')

def parse_file(path,lines,seen):
    path=path.resolve()
    if path in seen: raise AsmError(f'recursive include {path}')
    seen.add(path)
    for n,raw in enumerate(path.read_text().splitlines(),1):
        s=strip_comment(raw).strip()
        if not s:continue
        m=re.match(r'^include\s+[\"\'](.+)[\"\']$',s,re.I)
        if m:
            yield from parse_file(path.parent/m.group(1),lines,seen.copy());continue
        yield (path,n,s)

def assemble(src,out,defines=None):
    rows=list(parse_file(src,[],set()))
    syms={}
    base=None
    for passno in (1,2):
        pc=0; image=bytearray(); base=None
        for k,v in (defines or {}).items(): syms[k.lower()]=v
        cond=[]  # stack of [active_now, parent_active, already_taken]
        for path,n,s0 in rows:
            s=s0
            m=re.match(r'^(if|else|endif)\b\s*(.*)$',s,re.I)
            if m:
                kw=m.group(1).lower(); parent=all(c[0] for c in cond)
                if kw=='if':
                    v=bool(safe_eval(m.group(2).lower(),syms,pc)) if parent else False
                    cond.append([v,parent,v])
                elif kw=='else':
                    if not cond: raise AsmError(f'{path}:{n}: ELSE without IF')
                    c=cond[-1]; c[0]=c[1] and not c[2]; c[2]=True
                else:
                    if not cond: raise AsmError(f'{path}:{n}: ENDIF without IF')
                    cond.pop()
                continue
            if cond and not all(c[0] for c in cond): continue
            m=re.match(r'^assert\s+(.+)$',s,re.I)
            if m:
                if passno==2:
                    a=split_args(m.group(1))
                    if not safe_eval(a[0].lower(),syms,pc):
                        msg=ast.literal_eval(a[1]) if len(a)>1 else a[0]
                        raise AsmError(f'{path}:{n}: ASSERT failed: {msg}')
                continue
            # equ
            m=re.match(r'^([A-Za-z_][\w.]*)\s+equ\s+(.+)$',s,re.I)
            if m:
                name,expr=m.groups()
                try:v=safe_eval(expr,syms,pc)
                except NameError:
                    if passno==1:v=0
                    else:raise
                if passno==1: syms[name.lower()]=v
                continue
            # label
            if ':' in s:
                lab,rest=s.split(':',1)
                if re.match(r'^[A-Za-z_][\w.]*$',lab.strip()):
                    if passno==1:syms[lab.strip().lower()]=pc
                    s=rest.strip()
                    if not s:continue
            m=re.match(r'^org\s+(.+)$',s,re.I)
            if m:
                v=safe_eval(m.group(1),syms,pc)
                pc=v
                if base is None: base=v
                continue
            if base is None: raise AsmError(f'{path}:{n}: ORG required first')
            try:
                if re.match(r'^db\s+',s,re.I): b=data_items(re.sub(r'^db\s+','',s,flags=re.I),syms,pc,False,passno)
                elif re.match(r'^dw\s+',s,re.I): b=data_items(re.sub(r'^dw\s+','',s,flags=re.I),syms,pc,True,passno)
                elif re.match(r'^ds\s+',s,re.I):
                    args=split_args(re.sub(r'^ds\s+','',s,flags=re.I));
                    try:count=safe_eval(args[0].lower(),syms,pc)
                    except NameError:
                        if passno==1:count=0
                        else:raise
                    fill=safe_eval(args[1],syms,pc) if len(args)>1 else 0
                    b=bytes([fill&255])*count
                elif re.match(r'^incbin\s+',s,re.I):
                    q=re.sub(r'^incbin\s+','',s,flags=re.I).strip(); fn=ast.literal_eval(q); b=(path.parent/fn).read_bytes()
                else:b=instr(s,syms,pc,passno)
            except Exception as e:
                if isinstance(e,AsmError): raise AsmError(f'{path}:{n}: {e}')
                raise AsmError(f'{path}:{n}: {e}')
            if passno==2:
                off=pc-base
                if off<0:raise AsmError('output before base')
                if len(image)<off:image.extend(b'\x00'*(off-len(image)))
                if len(image)==off:image.extend(b)
                else:
                    end=off+len(b)
                    if end>len(image):image.extend(b'\x00'*(end-len(image)))
                    image[off:end]=b
            pc+=len(b)
        if cond: raise AsmError('unterminated IF block')
    out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(image)
    return syms

if __name__=='__main__':
    args=sys.argv[1:]; defines={}; symfile=None; pos=[]
    while args:
        a=args.pop(0)
        if a=='-D':
            k,_,v=args.pop(0).partition('='); defines[k]=int(v or '1',0)
        elif a=='--sym': symfile=Path(args.pop(0))
        else: pos.append(a)
    if len(pos)!=2: raise SystemExit('usage: z80mini.py [-D NAME=VAL]... [--sym FILE] source.asm output.bin')
    try:
        syms=assemble(Path(pos[0]),Path(pos[1]),defines)
    except Exception as e:
        print('ASSEMBLY ERROR:',e,file=sys.stderr);raise SystemExit(1)
    if symfile:
        symfile.parent.mkdir(parents=True,exist_ok=True)
        symfile.write_text(''.join(f'{k} equ 0x{v&0xFFFF:04X}\n' for k,v in sorted(syms.items())))
    sys.argv=[sys.argv[0]]+pos
    print(f'assembled {pos[0]} -> {pos[1]}'+(f' defines={defines}' if defines else ''))
    for k in ('init','title_patterns','title_names','title_colors','title_palette'):
        if k in syms:print(f'{k}=0x{syms[k]:04X}')
