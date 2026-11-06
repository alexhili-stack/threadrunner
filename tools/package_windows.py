"""Package only the declared runtime and notices, never export temporary files."""
from pathlib import Path
import zipfile

RUNTIME_FILES = {'Threadrunner.exe', 'Threadrunner.pck', 'manifest.json', 'README.txt'}


def package(root: Path) -> None:
    target = root / 'builds/windows'
    for name in RUNTIME_FILES:
        if not (target / name).is_file():
            raise FileNotFoundError(target / name)
    with zipfile.ZipFile(root / 'builds/Threadrunner-Windows.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(target.rglob('*')):
            relative = path.relative_to(target)
            if path.is_file() and (relative.as_posix() in RUNTIME_FILES or relative.parts[0] == 'third_party'):
                archive.write(path, Path('Threadrunner') / relative)
