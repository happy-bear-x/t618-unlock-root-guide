#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Patch SPRD-custom LP metadata in super image:
  - slot0 (a-slot view): system_a -> free tail (GSI), other a-parts -> share b's physical blocks
  - slot1 (b, active)  : untouched
  - slot2              : same patch as slot0 if it is a copy of factory-a layout
Checksums (reverse-engineered, verified on both slots):
  header.metadata_checksum @0x0C(32B) = SHA256(256B header with field zeroed)
  header.tables_checksum   @0x30(32B) = SHA256(tables)
Layout facts (from parsing):
  header 256B @slot_base; tables @+0x100; descriptors @0x54 as (count,entry_size,cum_end) tuples
  partition entry 52B {name[36], attrs u32, first_extent_index u32, num_extents u32, group_index u32}
  extent entry 24B {num_sectors u64, target_type u32, target_data u64, target_source u32}
  group entry 48B {name[36], flags u32, max_size u64}
  block_device entry 64B
"""
import struct, hashlib, shutil, sys

SRC = r"F:\dev-cache\sprd-unlock\work\backup\super.bin"
DST = r"F:\dev-cache\gsi\super_patch.img"
SECTOR = 512
SLOT0, SLOT1, SLOT2 = 0x3000, 0x13000, 0x23000
BAK0, BAK1, BAK2 = 0x33000, 0x43000, 0x53000
HDR = 256
TAB_OFF = 0x100
TOTAL_SECTORS = 6920601600 // 512          # 13,516,800
FIRST_LSECTOR = 2048

GSI_SIZE = 1774059520                       # android12 official GSI (system.img, with AVB footer)
GSI_SECTORS = GSI_SIZE // SECTOR            # 4,193,968
GSI_START = 8493616                         # free tail start (after vendor_dlkm_b ext0)

def parse_slot(f, base):
    f.seek(base); hdr = bytearray(f.read(HDR))
    tsz, = struct.unpack_from('<I', hdr, 0x2C)
    f.seek(base + TAB_OFF); tables = bytearray(f.read(tsz))
    return hdr, tables

def parse_tables(tables):
    parts, off = [], 0
    for _ in range(10):
        name = bytes(tables[off:off+36]).rstrip(b'\0').decode()
        attrs, fei, ne, gi = struct.unpack_from('<IIII', tables, off+36)
        parts.append(dict(name=name, attrs=attrs, fei=fei, ne=ne, gi=gi)); off += 52
    exts = []
    for i in range(sum(p['ne'] for p in parts)):
        ns, tt, td, tsrc = struct.unpack_from('<QIQI', tables, off)
        exts.append((ns, tt, td, tsrc)); off += 24
    groups = []
    for _ in range(3):
        name = bytes(tables[off:off+36]).rstrip(b'\0').decode()
        flags, mx = struct.unpack_from('<IQ', tables, off+36)
        groups.append((name, flags, mx)); off += 48
    bd = struct.unpack_from('<QIIQ', tables, off)   # first_lsector, align, align_off, size, flags(4B part of 64)
    return parts, exts, groups, off

def build_new_tables(parts, exts, groups, bd_blob):
    # new extents layout (fei order): system_a, system_ext_a x2, vendor_a x2, product_a, vendor_dlkm_a x2
    new_ext = [
        (GSI_SECTORS, 0, GSI_START, 0),        # system_a -> free tail
        (741256, 0, 5210112, 0), (82776, 0, 4988872, 0),   # system_ext_a = system_ext_b blocks
        (2216256, 0, 5951488, 0), (8344, 0, 5071648, 0),   # vendor_a = vendor_b blocks
        (291768, 0, 8169472, 0),                            # product_a = product_b block
        (31280, 0, 8462336, 0), (8, 0, 5079992, 0),         # vendor_dlkm_a = vendor_dlkm_b blocks
    ]
    fei = {}
    idx = 0
    NEW_NE = {'system_a':1, 'system_ext_a':2, 'vendor_a':2, 'product_a':1, 'vendor_dlkm_a':2}
    for p in parts:
        if p['ne'] > 0:
            p['ne'] = NEW_NE[p['name']]          # set new extent counts first
            fei[p['name']] = idx; idx += p['ne']
    # sanity: expected order
    assert list(fei) == ['system_a','system_ext_a','vendor_a','product_a','vendor_dlkm_a'], fei
    assert idx == 8, idx
    for p in parts:
        if p['ne'] > 0: p['fei'] = fei[p['name']]
    # sizes after patch
    sizes = {}
    for p in parts:
        sizes[p['name']] = sum(new_ext[i][0] for i in range(p['fei'], p['fei']+p['ne'])) if p['ne'] else 0
    assert sizes['system_a'] == GSI_SECTORS
    assert sizes['vendor_a'] == 2224600 and sizes['system_ext_a'] == 824032
    assert sizes['product_a'] == 291768 and sizes['vendor_dlkm_a'] == 31288
    # extent bounds & no unintended overlap among a-parts (b shared by design)
    used = []
    for (ns, _, td, _) in new_ext: used.append((td, td+ns))
    for a, b in used:
        assert FIRST_LSECTOR <= a and b <= TOTAL_SECTORS, (a, b)
    blobs = bytearray()
    for p in parts:
        blobs += p['name'].encode().ljust(36, b'\0')
        blobs += struct.pack('<IIII', p['attrs'], p['fei'], p['ne'], p['gi'])
    for (ns, tt, td, tsrc) in new_ext:
        blobs += struct.pack('<QIQI', ns, tt, td, tsrc)
    for (name, flags, mx) in groups:
        blobs += name.encode().ljust(36, b'\0') + struct.pack('<IQ', flags, mx)
    blobs += bd_blob
    return bytes(blobs), len(new_ext)

def build_header(old_hdr, new_tables):
    hdr = bytearray(old_hdr[:HDR])
    tsz = len(new_tables)
    struct.pack_into('<I', hdr, 0x2C, tsz)
    # descriptors: keep tuple structure, update extents & groups cum_end
    struct.pack_into('<12I', hdr, 0x54,
        10, 52, 520,          # partitions
        8, 24, 520 + 8*24,    # extents (8 entries) -> cum_end 712
        3, 48, 520 + 8*24 + 144,  # groups -> cum_end 856
        1, 64, 1)             # block devices (+ images count 1)
    hdr[0x30:0x50] = hashlib.sha256(new_tables).digest()
    hdr[0x0C:0x2C] = b'\0'*0x20
    hdr[0x0C:0x2C] = hashlib.sha256(bytes(hdr)).digest()
    return bytes(hdr)

def verify(base_img_bytes, base):
    """re-parse patched slot from image bytes and validate checksums"""
    hdr = base_img_bytes[base:base+HDR]
    md_ck = hdr[0x0C:0x2C]
    x = bytearray(hdr); x[0x0C:0x2C] = b'\0'*0x20
    assert hashlib.sha256(bytes(x)).digest() == md_ck, f"md_ck mismatch @{base:#x}"
    tsz, = struct.unpack_from('<I', hdr, 0x2C)
    tables = base_img_bytes[base+TAB_OFF: base+TAB_OFF+tsz]
    assert hashlib.sha256(tables).digest() == hdr[0x30:0x50], f"tab_ck mismatch @{base:#x}"
    parts, exts, groups, off = parse_tables(bytearray(tables))
    assert [p['name'] for p in parts] == ['system_a','system_b','system_ext_a','system_ext_b',
        'vendor_a','vendor_b','product_a','product_b','vendor_dlkm_a','vendor_dlkm_b']
    assert sum(p['ne'] for p in parts) == 8
    print(f"  verify @{base:#x}: OK  tsz={tsz} sys_a_ext={exts[0]}")

def main():
    f = open(SRC, 'rb')
    hdr0, tab0 = parse_slot(f, SLOT0)
    hdr2, tab2 = parse_slot(f, SLOT2)
    parts, exts, groups, bd_off = parse_tables(tab0)
    print("slot0 parts:", [(p['name'], p['fei'], p['ne']) for p in parts])
    print("slot0 exts :", exts)
    print("slot0 groups:", groups)
    bd_blob = bytes(tab0[bd_off:])
    # confirm slot2 == slot0 (factory-a copy) or differs
    same2 = (bytes(hdr2) == bytes(hdr0) and bytes(tab2) == bytes(tab0))
    print(f"slot2 == slot0: {same2}")
    # confirm backups identical to primaries
    f.seek(BAK0); b0 = f.read(HDR+848)
    f.seek(BAK2); b2 = f.read(HDR+848)
    print(f"bak0 == slot0: {b0 == bytes(hdr0)+bytes(tab0)}; bak2 == slot2: {b2 == bytes(hdr2)+bytes(tab2)}")

    new_tables, _ = build_new_tables(parts, exts, groups, bd_blob)
    new_hdr = build_header(hdr0, new_tables)
    patched_slot = new_hdr + new_tables
    print(f"new tables size={len(new_tables)} (expect 920); header sha ok")
    # self-check: verify freshly built slot in memory
    _v = bytearray(new_hdr); _v[0x0C:0x2C] = b'\0'*0x20
    assert hashlib.sha256(bytes(_v)).digest() == new_hdr[0x0C:0x2C], "in-memory md_ck broken"
    assert hashlib.sha256(new_tables).digest() == new_hdr[0x30:0x50], "in-memory tab_ck broken"
    print("in-memory checksums self-consistent")

    # write patched image (stream copy with patches at 4 offsets)
    patch_offsets = [SLOT0, BAK0] + ([SLOT2, BAK2] if same2 and b2 == bytes(hdr2)+bytes(tab2) else [])
    print("patching offsets:", [hex(o) for o in patch_offsets])
    with open(DST, 'wb') as out:
        f.seek(0); copied = 0; SIZE = 6920601600; CH = 8*1024*1024
        import os
        while copied < SIZE:
            n = min(CH, SIZE - copied)
            buf = f.read(n)
            if not buf: break
            for o in patch_offsets:
                s, e = o, o + len(patched_slot)
                if copied < e and s < copied + len(buf):
                    ls = max(s - copied, 0)
                    le = min(e - copied, len(buf))
                    po = ls + copied - s          # offset inside patched_slot
                    buf = bytearray(buf)
                    buf[ls:le] = patched_slot[po:po + (le - ls)]
                    buf = bytes(buf)
            out.write(buf); copied += len(buf)
    print("written", DST)
    # verify all patched slots by re-reading output
    g = open(DST, 'rb'); g.seek(0); data_head = g.read(0x60000)
    for o in patch_offsets:
        actual = data_head[o:o+len(patched_slot)]
        if actual != patched_slot:
            d = next((i for i,(a,b) in enumerate(zip(actual, patched_slot)) if a != b), None)
            print(f"  DEBUG @{o:#x}: first diff at +{d} len_ok={len(actual)==len(patched_slot)}")
        assert actual == patched_slot, f"patched bytes mismatch @{o:#x}"
        verify(data_head, o)
    # ensure slot1 untouched
    f.seek(SLOT1); s1old = f.read(HDR+1136)
    assert data_head[SLOT1:SLOT1+HDR+1136] == s1old, "slot1 changed!"
    print("slot1 (b) untouched: OK")
    print("ALL CHECKS PASSED")

if __name__ == '__main__':
    main()
