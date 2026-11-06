"""Fetch only the pinned official single-threaded Godot Web release template."""
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
SIZE = 1281349702
MEMBER = 'templates/web_nothreads_release.zip'
SHA256 = 'd3ee2f08cef0cf3cf6678a6355a92a8db48ccdd35cbd2e8bfd5f0e8a0b4032a0'


class RemoteZip(io.RawIOBase):
    def __init__(self):
        self.position = 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else SIZE + offset
        return self.position

    def tell(self):
        return self.position

    def read(self, size=-1):
        if size < 0:
            size = SIZE - self.position
        if not size:
            return b''
        request = urllib.request.Request(URL, headers={
            'User-Agent': 'Threadrunner-web-setup',
            'Range': f'bytes={self.position}-{self.position + size - 1}'
        })
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError('Range request not honored; refusing full multi-platform download')
            result = response.read()
        if len(result) != size:
            raise RuntimeError('Incomplete range response')
        self.position += len(result)
        return result


def main():
    target = ROOT / '.tools/templates/web_nothreads_release.zip'
    with zipfile.ZipFile(RemoteZip()) as archive:
        data = archive.read(MEMBER)  # zipfile validates the member's CRC.
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise RuntimeError('Web template SHA-256 differs from the pinned release')
    with zipfile.ZipFile(io.BytesIO(data)) as template:
        if template.testzip() is not None:
            raise RuntimeError('Invalid inner Web template ZIP')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    info = {'source': URL, 'archive_bytes': SIZE, 'member': MEMBER,
            'sha256': hashlib.sha256(data).hexdigest(), 'member_crc_verified': True,
            'full_archive_sha256_verified': False, 'bytes': len(data)}
    (target.parent / 'web-provenance.json').write_text(json.dumps(info, indent=2))
    print(json.dumps(info), flush=True)


if __name__ == '__main__':
    main()
