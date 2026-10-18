#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parse Android LP (dynamic partition) metadata from a raw super image."""
import struct, sys, zlib, hashlib

SUPER = r"F:\dev-cache\sprd-unlock\work\backup\super.bin"
SECTOR = 512

def u32(b, o): return struct.unpack_from('<I', b, o)[0]
def u16(b, o): return struct.unpack_from('<H', b, o)[0]
def u64(b, o): return struct.unpack_from('<Q', b, o)[0]

def main():
    f = open(SUPER, 'rb')
    # geometry at 4096
    f.seek(4096); geo = f.read(4096)
    magic, struct_size = u32(geo,0), u32(geo,4)
    print(f"geometry magic=0x{magic:08x} struct_size={struct_size}")
    meta_max = u64(geo,40); slot_count = u32(geo,48); lblock = u32(geo,52)
    print(f"metadata_max_size={meta_max} slot_count={slot_count} logical_block_size={lblock}")
    # scan primary metadata slots at 8192
    slots = []
    for i in range(slot_count):
        f.seek(8192 + i*meta_max); blob = f.read(meta_max)
        m = u32(blob,0)
        print(f"slot {i} @8192+{i*meta_max}: magic=0x{m:08x}", end='')
        if m == 0x414C5030:
            print("  (valid LP header)")
            slots.append((i, blob))
        else:
            print("  (empty)")
    # find backup geometry / backup metadata locations
    size = 6920601600
    f.seek(size-4096); g2 = f.read(4096)
    print(f"backup geo magic=0x{u32(g2,0):08x}")
    # backup metadata: scan backwards for LP header magic in last ~1MB
    f.seek(size - 4096 - meta_max*slot_count); bk = f.read(meta_max*slot_count + 4096)
    off = 0
    for i in range(slot_count):
        b = bk[off:off+meta_max]
        print(f"backup slot {i}: magic=0x{u32(b,0):08x}")
        off += meta_max
    if not slots:
        print("NO VALID SLOT"); return
    idx, blob = slots[0]
    major, minor = u16(blob,4), u16(blob,6)
    hdr_size = u32(blob,8)
    hdr_ck = u32(blob,12)
    tables_size = u32(blob,16)
    tables_ck = u32(blob,20)
    tables_off = u32(blob,24)
    md_ck = blob[28:60]
    print(f"ver={major}.{minor} header_size={hdr_size} tables_size={tables_size} tables_offset={tables_off}")
    print(f"header_checksum=0x{hdr_ck:08x} tables_checksum=0x{tables_ck:08x}")
    print(f"metadata_checksum={md_ck.hex()}")
    # extra header fields after 60
    rest = blob[60:hdr_size]
    print(f"header extra ({len(rest)}B): {rest[:32].hex()} ...")
    tables = blob[tables_off:tables_off+tables_size]
    # checksum hypotheses
    h0 = bytearray(blob[:hdr_size])
    t = bytearray(tables)
    # tables_checksum = crc32(tables)
    print("hyp tables_ck=crc32(tables):", hex(zlib.crc32(t)))
    # header_checksum variants
    for name, mod in [("zero hdr_ck", [(12,4)]), ("zero hdr_ck+md_ck", [(12,4),(28,32)])]:
        x = bytearray(h0)
        for o,n in mod: x[o:o+n] = b'\0'*n
        print(f"hyp header_ck crc32({name}) :", hex(zlib.crc32(x)))
    for name, mod in [("zero md_ck",[(28,32)]), ("zero md_ck+hdr_ck",[(12,4),(28,32)])]:
        x = bytearray(h0)
        for o,n in mod: x[o:o+n] = b'\0'*n
        full = bytes(x) + bytes(t)
        print(f"hyp metadata_ck sha256({name}) :", hashlib.sha256(full).hexdigest())
        print(f"hyp metadata_ck sha256(tables only):", hashlib.sha256(bytes(t)).hexdigest())
        break
    # parse partitions table (first table)
    p = tables_off
    def parse_table_count(fmt_size, total, offset): pass
    # partitions: 52B each (v1.0), extents 24B, groups 48B, block_devices 28/64B, images
    # We need counts: try partitions = N*52, then extents etc. Use known: 5 partitions + 5 cows = 10
    # attempt: locate by assuming order partitions,extents,groups,block_devices,images
    NP = 10
    part_t = tables[0:NP*52]
    print("\n-- partitions (assuming 10) --")
    ext_start = NP*52
    for i in range(NP):
        e = part_t[i*52:(i+1)*52]
        name = e[0:36].rstrip(b'\0').decode()
        attrs, fei, ne, gi = u32(e,36), u32(e,40), u32(e,44), u32(e,48)
        print(f"[{i}] {name:16s} attrs={attrs:#x} first_ext={fei} num_ext={ne} group_idx={gi}")
    # guess extents count = sum num_ext
    tot_ext = sum(u32(part_t[i*52+44:(i+1)*52]) for i in range(NP))
    print("total extents:", tot_ext)
    ext_t = tables[ext_start:ext_start+tot_ext*24]
    for i in range(tot_ext):
        e = ext_t[i*24:(i+1)*24]
        ns = u64(e,0); tt = u32(e,8); td = u64(e,12); ts = u32(e,20)
        print(f"ext[{i}]: sectors={ns} type={tt} data={td} source={ts}")
    g_start = ext_start + tot_ext*24
    # groups: 48B each, guess 2 (group_unisoc_b, cow)
    for NG in (2,3,4):
        gb = tables[g_start:g_start+NG*48]
        names = [gb[i*48:i*48+36].rstrip(b'\0') for i in range(NG)]
        if all(n.isascii() and n for n in names):
            print(f"-- groups (NG={NG}): {names}")
            for i in range(NG):
                e = gb[i*48:(i+1)*48]
                print(f"   {e[0:36].rstrip(b(chr(0),) if False else b'\\0').decode():20s} flags={u32(e,36):#x} max={u64(e,40)}")
            break
    bd_start = g_start + 2*48
    bdb = tables[bd_start:bd_start+64]
    print("block_device first_logical_sector:", u64(bdb,0), "alignment:", u32(bdb,8), "align_off:", u32(bdb,12), "size:", u64(bdb,16), "flags:", u32(bdb,24))

if __name__ == '__main__':
    main()
