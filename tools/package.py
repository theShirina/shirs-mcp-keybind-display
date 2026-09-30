from pathlib import Path
import zipfile
ROOT = Path(__file__).resolve().parents[1]
FILES = ['Core.lua', 'UI.lua', 'ShirsMCPKeybindDisplay.toc', 'LICENSE']

def build(destination):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix('.tmp')
    with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in sorted(FILES):
            source = ROOT/'runtime'/name if name != 'LICENSE' else ROOT/name
            payload = source.read_text(encoding='utf-8').replace('\r\n', '\n').replace('\r', '\n').encode('utf-8')
            member = zipfile.ZipInfo('ShirsMCPKeybindDisplay/'+name, (2026, 1, 1, 0, 0, 0))
            member.create_system = 3
            member.external_attr = 0o100644 << 16
            member.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(member, payload, compresslevel=9)
    with zipfile.ZipFile(temporary) as archive:
        assert archive.testzip() is None
    temporary.replace(destination)
    return destination

if __name__ == '__main__':
    print(build(ROOT/'dist/ShirsMCPKeybindDisplay-0.1.0-candidate.zip'))
