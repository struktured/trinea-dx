"""Repo-relative paths shared by the build tools.
The original ROM is never stored in this repository: pass it via TRINEA_ROM (tools/build.sh does this),
or place it at rom/Trinea (Japan).sfc (ignored by git)."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROM = os.environ.get('TRINEA_ROM', os.path.join(ROOT, 'rom', 'Trinea (Japan).sfc'))
BUILD = os.path.join(ROOT, 'build')
GEN = os.path.join(BUILD, 'gen')          # generated asm includes + binary blobs
FONT = os.path.join(BUILD, 'font')        # generated font binaries (from font/ text sources)
JP = os.path.join(BUILD, 'jp')            # JP script dump (regenerated from your ROM, never committed)
for d in (GEN, FONT): os.makedirs(d, exist_ok=True)
