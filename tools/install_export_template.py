"""Fetch only the Windows x64 release member of the official templates ZIP."""
import io
import json
from pathlib import Path
import urllib.request
import zipfile
import hashlib

ROOT = Path(__file__).resolve().parents[1]
URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
SIZE = 1281349702

class RemoteZip(io.RawIOBase):
    def __init__(self):
        self.position = 0
    def seekable(self): return True
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position + offset if whence == 1 else SIZE + offset)
        return self.position
    def tell(self): return self.position
    def read(self, size=-1):
        if size < 0: size = SIZE - self.position
        if not size: return b''
        req = urllib.request.Request(URL, headers={'User-Agent':'Threadrunner-local-setup', 'Range':f'bytes={self.position}-{self.position+size-1}'})
        with urllib.request.urlopen(req, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError('Server did not honor range request; refusing full multi-platform download')
            result = response.read()
        self.position += len(result)
        return result

with zipfile.ZipFile(RemoteZip()) as archive:
    names = [n for n in archive.namelist() if n.endswith('windows_release_x86_64.exe')]
    if len(names) != 1: raise RuntimeError(names)
    name = names[0]
    print(name, archive.getinfo(name).compress_size, flush=True)
    data = archive.read(name)  # zipfile verifies the member CRC.
    target=ROOT/'.tools/templates/windows_release_x86_64.exe'
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
    (target.parent/'provenance.json').write_text(json.dumps({'source':URL,'member':name,'sha256':hashlib.sha256(data).hexdigest(),'archive_crc_verified':True,'full_archive_sha256_verified':False},indent=2))
    print('Windows release template ready',len(data),flush=True)
